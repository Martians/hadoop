package com.data.bind;

import cn.nimblex.ivylite.Ivylition;
import com.data.util.data.source.DataSource;
import com.data.util.disk.Disk;
import com.data.util.schema.DataSchema;
import cn.nimblex.ivylite.Ivylite;
import cn.nimblex.ivylite.IvyliteCache;
import cn.nimblex.ivylite.cache.CacheMode;
import cn.nimblex.ivylite.client.ClientCache;
import cn.nimblex.ivylite.client.IvyliteClient;
import cn.nimblex.ivylite.configuration.CacheConfiguration;
import cn.nimblex.ivylite.configuration.ClientConfiguration;
import cn.nimblex.ivylite.configuration.IvyliteConfiguration;
import cn.nimblex.ivylite.spi.discovery.tcp.TcpDiscoverySpi;
import cn.nimblex.ivylite.spi.discovery.tcp.ipfinder.vm.TcpDiscoveryVmIpFinder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Method;
import java.util.*;

/**
 * 	clien类型
 * 	    1. useThin：访问端口与normal client不同，默认10800
 * 	         服务配置：<property name="peerClassLoadingEnabled" value="true"/>
 * 	                 不需要专门配置端口，默认已经启动了监听的端口
 * 	         服务启动：直接 bin/ivylite.sh即可
 *
 * 		2. normal：可以指定配置文件，或者通过程序配置
 * 			文件方式
 * 				配置：examples/config/example-cache.xml 作为模板; 并修改ip地址
 * 				启动：bin/ivylite.sh examples/config/example-cache.xml
 * 			    注意：配置文件复制到 main/resources下边
 *
 * 			程序方式：
 * 				配置：可以添加 <property name="peerClassLoadingEnabled" value="true"/>
 * 	     		启动：bin/ivylite.sh examples/config/example-ivylite.xml
 *
 * 	分离融合（normal模式下，client、server是否在一起）
 *      1. 分离模式
 *      	1）client模式：client=true, 本地不启动server，数据发送到远端server
 *          2）远端服务启动：bin/ivylite.sh examples/config/example-cache.xml
 *
 *      2. 融合模式：
 *      	1）server模式：client=false，本地启动server和client，数据存储在本地测试
 *          2）注意：需要关闭远端服务器，否则本地server会和远端server组成集群
 *
 *  类型系统：
 *      1. 使用 IvyliteCache<String, Test> cache
 *      2. 使用 IvyliteCache cache，后续 CacheConfiguration.setTypes
 *
 *      测试时，使用 normal客户端，程序方式配置
 *          bin/ivylite.sh examples/config/example-ivylite.xml
 */
public class IvyliteHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
            addOption("client", "client or server", false);
            addOption("cache", "cache name", "test");
            addOption("file", "server config file", "");
            addOption("class", "dynamic class", "java.lang.String");
            addOption("method", "dynamic method", "toString");

            addOption("thin.open", "use thin client", true);
            addOption("thin.host", "thin client host", "");
        }
    }

    String cacheName = "test";

    /**
     * thin client
     */
    IvyliteClient thinClient;
    ClientCache<String, String>  thinClientCache;

    /**
     * normal
     */
    Ivylite ivylite;
    IvyliteCache cache;

    boolean useThin;

    boolean test = false;
    Class<?> factory = null;
    Method method = null;
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    protected void resolveParam() {
        List<DataSchema.Item> list = command.schema.list;
        if (list.size() != 2
                || list.get(0).type != DataSchema.Type.string
                || list.get(1).type != DataSchema.Type.string)
        {
            log.info("ivylite test, schema must be [string, string], current: {}", command.schema);
            System.exit(-1);
        }

        useThin = command.getBool("thin.open");

        if (!command.get("class").contains("String")) {
            test = true;
        }

        if (useThin && command.param.batch > 1) {
            command.param.batch = 1;
            log.info("resolve param, use thin client, reset batch to 1");
        }
    }

    protected void connecting() {
        loadValueClass(false);
        loadValueMethod();

        command.dynamicLoad("");
        log.info("{}", System.getProperty("java.class.path"));
        if (useThin) {
            /**
             * thin client模式
             *  https://www.cnblogs.com/peppapigdaddy/archive/2018/11/12/9815848.html
             *      https://apacheignite.readme.io/docs/java-thin-client
             *      https://apacheignite.readme.io/docs/ssltls
             */
            String[] servers = command.get("thin.host").split(",");
            ClientConfiguration cfg = new ClientConfiguration().setAddresses(servers);

            thinClient = Ivylition.startClient(cfg);
            thinClientCache = thinClient.getOrCreateCache(cacheName);

        } else {
            Ivylition.setClientMode(command.getBool("client"));

            if (command.exist("file")) {
                String path = command.get("file");
                if (!Disk.fileExist(path, false)) {
                    if (Disk.fileExist(path, true)) {
                        path = Disk.resourcePath(path);
                    } else {
                        log.warn("can't find config file {}", path);
                    }
                }
                ivylite = Ivylition.start(path);

            } else {

                String[] servers;
                if (command.getBool("client")) {
                    servers = command.get("host").split(",");

                } else {
                    servers = "127.0.0.1".split(",");
                    log.info("========== combine mode");
                }

                TcpDiscoveryVmIpFinder ipFinder = new TcpDiscoveryVmIpFinder();
                ipFinder.setAddresses(Arrays.asList(servers));

                TcpDiscoverySpi discoverySpi = new TcpDiscoverySpi();
                discoverySpi.setIpFinder(ipFinder);

                IvyliteConfiguration cfg = new IvyliteConfiguration();
                cfg.setPeerClassLoadingEnabled(true);
                cfg.setDiscoverySpi(discoverySpi);

                ivylite = Ivylition.start(cfg);
            }

            //CacheConfiguration<String, Test> cfg = new CacheConfiguration<>();
            CacheConfiguration cfg = new CacheConfiguration<>();
            cfg.setTypes(String.class, factory);

            cfg.setCacheMode(CacheMode.PARTITIONED);
            cfg.setBackups(0);
            cfg.setName(command.get("cache"));

            cache = ivylite.getOrCreateCache(cfg);
            log.info("connecting complete");
        }
    }

    /**
     * https://blog.csdn.net/qq_32718869/article/details/81288076
     * https://bbs.csdn.net/topics/390077862
     *      https://lorry1113.iteye.com/blog/973903
     *      https://blog.csdn.net/langwang1993/article/details/80536872
     *
     * Object a = Array.newInstance(factory, 1);
     */
    protected Class<?> loadValueClass(boolean retry) {
        try {
            factory = Class.forName(command.get("class"));

        } catch (ClassNotFoundException e) {
            if (retry) {
                log.warn("load class {} failed, {}", command.get("class"), e);
                System.exit(-1);

            } else {
                command.dynamicLoad("");
                return loadValueClass(true);
            }
        }
        return factory;
   }

   protected void loadValueMethod() {
       try {
           method = factory.getMethod(command.get("method"));

       } catch (Exception e) {
           log.warn("load method {}.{} failed, {}", command.get("class"), command.get("method"), e);
           System.exit(-1);
       }
   }

    protected void preparing() {
        if (command.getBool("clear")) {
            ivylite.destroyCache(cacheName);
        }
    }

    @Override
    public void terminate() throws Exception {
        if (thinClient != null) {
            thinClient.close();
        }

        if (ivylite != null) {
            ivylite.close();
        }
    }

    public String dumpLoad() {
        return "";
    }

    /**
     * only for test
     */
    private Object cast(Object object) {
        if (test) {
            try {
                return factory.newInstance();

            } catch (InstantiationException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
        return object;
    }

    private Object callMethod(Object object) {
        try {
            return method.invoke(object);

        } catch (Exception e) {
            log.warn("call method {} failed, {}", command.get("method"), e);
            System.exit(-1);
            return null;
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @Override
    public int write(int[] result, int batch) {

        if (batch == 1) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("write get null, completed");
                return -1;
            }

            if (useThin) {
                thinClientCache.put((String) wrap.array[0], (String) wrap.array[1]);

            } else {
                cache.put((String) wrap.array[0], cast(wrap.array[1]));
            }

            result[0] += 1;
            result[1] += wrap.size;

        } else {
            HashMap<String, Object> map = new HashMap<>();

            for (int i = 0; i < batch; i++) {

                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    break;
                }
                map.put((String) wrap.array[0], cast(wrap.array[1]));

                result[0] += 1;
                result[1] += wrap.size;
            }

            if (map.size() > 0) {
                cache.putAll(map);

            } else {
                log.debug("write get null, completed");
                return -1;
            }
        }

        return 1;
    }

    @Override
    public int read(int[] result, int batch) {
        if (batch == 1) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("read get null, completed");
                return -1;
            }

            Object data;
            if (useThin) {
                data = thinClientCache.get((String) wrap.array[0]);

            } else {
                data = cache.get((String) wrap.array[0]);
            }

            if (data == null) {
                if (command.emptyForbiden()) {
                    return -1;
                }

            } else if (command.table.read_dump) {
                log.info("recv [{}] -> {}", wrap.array[0], callMethod(data));
            }

            result[0] += 1;
            result[1] += wrap.size;

        } else {
            HashSet<String> set = new HashSet<>();

            while (result[0] < batch) {
                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    break;
                }
                set.add((String) wrap.array[0]);

                result[0] += 1;
                result[1] += wrap.size;
            }

            if (set.size() > 0) {
                Map map = cache.getAll(set);

                if (map.size() == 0) {
                    if (command.emptyForbiden()) {
                        result[0] = 0;
                        return -1;
                    }

                } else {
                    for (Object item : map.entrySet()) {
                        result[0] += 1;

                        if (command.table.read_dump) {
                            Map.Entry<String, Object> entry = (Map.Entry<String, Object>) item;
                            log.info("recv [{}] -> {}", entry.getKey(), callMethod(entry.getValue()));
                        }
                    }
                }

            } else {
                log.debug("read get null, completed");
                return -1;
            }
        }
        return 1;
    }
}
