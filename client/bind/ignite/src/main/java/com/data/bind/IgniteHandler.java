package com.data.bind;

import com.data.util.data.source.DataSource;
import com.data.util.disk.Disk;
import com.data.util.schema.DataSchema;
import org.apache.ignite.Ignite;
import org.apache.ignite.IgniteCache;
import org.apache.ignite.Ignition;
import org.apache.ignite.cache.CacheMode;
import org.apache.ignite.client.ClientCache;
import org.apache.ignite.client.IgniteClient;
import org.apache.ignite.configuration.CacheConfiguration;
import org.apache.ignite.configuration.ClientConfiguration;
import org.apache.ignite.configuration.IgniteConfiguration;
import org.apache.ignite.spi.discovery.tcp.TcpDiscoverySpi;
import org.apache.ignite.spi.discovery.tcp.ipfinder.vm.TcpDiscoveryVmIpFinder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Array;
import java.util.*;


/**
 *
 * 两种client
 *      1. useThin：访问端口与normal client不同，默认10800
 *              配置：<property name="peerClassLoadingEnabled" value="true"/>
 *                    不需要专门配置端口，默认已经启动了监听的端口
 *
 *              启动：直接 bin/ignite.sh即可
 *
 *      2. normal：必须指定配置文件
 *              配置：examples/config/example-cache.xml 作为模板，修改ip地址
 *              启动：bin/ignite.sh examples/config/example-cache.xml
 *
 * 两种模式：（normal client下）
 *      1. client模式：数据发送到远端server
 *              1）远端服务启动：bin/ignite.sh examples/config/example-cache.xml，配置文件同本地
 *              2）本地 setClientMode 设置为 true
 *
 *      2. server模式：数据存储在本地测试
 *              1）关闭远端服务器，否则本地server会和远端server组成集群
 *              2）本地 setClientMode 设置为 false
 *
 * 使用
 *      1. 本地测试：client=false，本地启动server和client
 *      2. 远端测试：client=true， 本地指启动client
 *
 *      bin/ignite.sh examples/config/example-ignite.xml
 *
 */
public class IgniteHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
            addOption("client", "client or server", false);
            addOption("cache", "cache name", "test");
            addOption("file", "server config file", "");

            addOption("thin.open", "use thin client", true);
            addOption("thin.host", "thin client host", "");
        }
    }

    String cacheName = "test";

    /**
     * thin client
     */
    IgniteClient thinClient;
    ClientCache<String, String>  thinClientCache;

    /**
     * normal
     */
    Ignite ignite;
    IgniteCache cache;

    boolean useThin;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    protected void resolveParam() {
        List<DataSchema.Item> list = command.schema.list;
        if (list.size() != 2
                || list.get(0).type != DataSchema.Type.string
                || list.get(1).type != DataSchema.Type.string)
        {
            log.info("ignite test, schema must be [string, string], current: {}", command.schema);
            System.exit(-1);
        }

        useThin = command.getBool("thin.open");

        if (useThin && command.param.batch > 1) {
            command.param.batch = 1;
            log.info("resolve param, use thin client, reset batch to 1");
        }
    }

    protected void connecting() {
        if (useThin) {
            /**
             * thin client模式
             *  https://www.cnblogs.com/peppapigdaddy/archive/2018/11/12/9815848.html
             *      https://apacheignite.readme.io/docs/java-thin-client
             *      https://apacheignite.readme.io/docs/ssltls
             */
            String[] servers = command.get("thin.host").split(",");
            ClientConfiguration cfg = new ClientConfiguration().setAddresses(servers);

            thinClient = Ignition.startClient(cfg);
            thinClientCache = thinClient.getOrCreateCache(cacheName);

        } else {
            Ignition.setClientMode(command.getBool("client"));

            if (command.exist("file")) {
                String path = command.get("file");
                if (!Disk.fileExist(path, false)) {
                    if (Disk.fileExist(path, true)) {
                        path = Disk.resourcePath(path);
                    } else {
                        log.warn("can't find config file {}", path);
                    }
                }
                ignite = Ignition.start(path);

            } else {
                String[] servers;
                if (command.getBool("client")) {
                    servers = command.get("host").split(",");

                } else {
                    servers = "127.0.0.1".split(",");
                }

                TcpDiscoveryVmIpFinder ipFinder = new TcpDiscoveryVmIpFinder();
                ipFinder.setAddresses(Arrays.asList(servers));

                TcpDiscoverySpi discoverySpi = new TcpDiscoverySpi();
                discoverySpi.setIpFinder(ipFinder);

                IgniteConfiguration cfg = new IgniteConfiguration();
                cfg.setPeerClassLoadingEnabled(true);
                cfg.setDiscoverySpi(discoverySpi);

                ignite = Ignition.start(cfg);
            }

            CacheConfiguration cfg = new CacheConfiguration<>();
            cfg.setTypes(String.class, String.class);

            cfg.setCacheMode(CacheMode.PARTITIONED);
            cfg.setBackups(0);
            cfg.setName(command.get("cache"));

            cache = ignite.getOrCreateCache(cfg);
            log.info("connecting complete");
        }
    }

    protected void preparing() {
        if (command.getBool("clear")) {
            ignite.destroyCache(cacheName);
        }
    }

    @Override
    public void terminate() throws Exception {
        if (thinClient != null) {
            thinClient.close();
        }

        if (ignite != null) {
            ignite.close();
        }
    }

    public String dumpLoad() {
        return "";
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
                cache.put((String) wrap.array[0], (String) wrap.array[1]);
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
                map.put((String) wrap.array[0], (Object) wrap.array[1]);

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
                int x = 1;

            } else {
                log.debug("read get null, completed");
                return -1;
            }
        }
        return 1;
    }
}
