package com.data.bind;

import com.data.util.data.source.DataSource;
import com.data.util.schema.DataSchema;
import org.apache.ignite.Ignite;
import org.apache.ignite.IgniteCache;
import org.apache.ignite.Ignition;
import org.apache.ignite.cache.CacheMode;
import org.apache.ignite.client.ClientCache;
import org.apache.ignite.client.IgniteClient;
import org.apache.ignite.client.SslMode;
import org.apache.ignite.configuration.CacheConfiguration;
import org.apache.ignite.configuration.ClientConfiguration;
import org.apache.ignite.ssl.SslContextFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;


/**
 *
 * 配置：
 *      1. 使用 examples/config/example-cache.xml 作为模板，修改ip地址
 *      2. <property name="peerClassLoadingEnabled" value="true"/>
 *
 * 两种模式：
 *      1. client模式：数据发送到远端server
 *              1）远端服务启动：bin/ignite.sh examples/config/example-cache.xml，配置文件同本地
 *              2）本地 setClientMode 设置为 true
 *
 *      2. server模式：数据存储在本地测试
 *              1）关闭远端服务器，否则本地server会和远端server组成集群
 *              2）本地 setClientMode 设置为 false
 *
 */
public class IgniteHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
        }
    }

    String cacheName = "test";

    IgniteClient thinClient;
    ClientCache<String, String> thinClientCache;

    String configFile = "example-cache.xml";
    IgniteCache<String, String> cache;
    Ignite ignite;
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
    }

    protected void connecting() {
        if (true) {
            Ignition.setClientMode(true);

            ignite = Ignition.start(configFile);
            CacheConfiguration<String, String> cfg = new CacheConfiguration<>();
            cfg.setCacheMode(CacheMode.PARTITIONED);
            cfg.setBackups(0);
            cfg.setName("test");

            cache = ignite.getOrCreateCache(cfg);
            log.info("connecting complete");

        } else {
            /**
             * thin client模式，以下尝试都没有成功；似乎必须配置ssl相关内容
             *      https://apacheignite.readme.io/docs/java-thin-client
             *      https://apacheignite.readme.io/docs/ssltls
             */
            String[] servers = command.get("host").split(",");
            ClientConfiguration cfg = new ClientConfiguration().setAddresses(servers);

            //cfg.setSslMode(SslMode.REQUIRED)
            //        .setSslClientCertificateKeyStorePath("client.jks")
            //        .setSslClientCertificateKeyStoreType("JKS")
            //        .setSslClientCertificateKeyStorePassword("123456")
            //        .setSslTrustCertificateKeyStorePath("trust.jks")
            //        .setSslTrustCertificateKeyStoreType("JKS")
            //        .setSslTrustCertificateKeyStorePassword("123456")
            //        .setSslKeyAlgorithm("SunX509")
            //        .setSslTrustAll(false)
            //        .setSslProtocol(SslProtocol.TLS);
            SslContextFactory factory = new SslContextFactory();
            factory.setTrustManagers(SslContextFactory.getDisabledTrustManager());
            cfg.setSslContextFactory(factory);
            cfg.setSslTrustAll(true).setSslMode(SslMode.DISABLED);

            thinClient = Ignition.startClient(cfg);
            thinClientCache = thinClient.getOrCreateCache(cacheName);
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
        for (int i = 0; i < batch; i++) {

            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("write get null, completed");
                return -1;
            }
            cache.put((String)wrap.array[0], (String)wrap.array[1]);

            result[0] += 1;
            result[1] += wrap.size;
        }
        return 1;
    }

    @Override
    public int read(int[] result, int batch) {
        while (result[0] < batch) {

            DataSource.Wrap wrap = source.next();
            String data = cache.get((String)wrap.array[0]);
            if (data == null) {
                if (command.emptyForbiden()) {
                    return -1;
                }
            }

            result[0] += 1;
            result[1] += wrap.size;
        }
        return 1;
    }
}
