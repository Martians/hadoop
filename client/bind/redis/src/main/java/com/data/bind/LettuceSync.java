package com.data.bind;


import com.data.base.IOPSThread;
import com.data.util.data.source.DataSource;
import io.lettuce.core.KeyValue;
import io.lettuce.core.RedisURI;
import io.lettuce.core.cluster.RedisClusterClient;
import io.lettuce.core.cluster.api.StatefulRedisClusterConnection;
import io.lettuce.core.cluster.api.async.RedisAdvancedClusterAsyncCommands;
import io.lettuce.core.cluster.api.sync.RedisAdvancedClusterCommands;
import io.lettuce.core.resource.ClientResources;
import io.lettuce.core.resource.DefaultClientResources;
import io.lettuce.core.support.ConnectionPoolSupport;
import org.apache.commons.pool2.impl.DefaultPooledObjectInfo;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPoolConfig;

import java.util.*;

/**
 * home: https://lettuce.io/docs/
 *
 * doc: https://github.com/lettuce-io/lettuce-core/wiki/Getting-started-(5.0)
 *      https://lettuce.io/core/snapshot/reference/#asynchronous-api.motivation
 *
 * api: https://lettuce.io/core/release/api/
 */
public class LettuceSync extends RedisBase {
    public LettuceSync() {
    }

    /**
     * 默认情况下，使用单链接
     */
    ClientResources resource = null;
    RedisClusterClient cluster = null;
    StatefulRedisClusterConnection<String, String> connection = null;
    RedisAdvancedClusterCommands<String, String> sync = null;
    RedisAdvancedClusterAsyncCommands<String, String> async = null;

    /**
     * 经测试，使用pool连接，性能几乎没有提升
     */
    GenericObjectPool<StatefulRedisClusterConnection<String, String>> pool = null;
    List<StatefulRedisClusterConnection<String, String>> connList = null;
    List<RedisAdvancedClusterAsyncCommands<String, String>> asyncList = null;
    ThreadLocal<RedisAdvancedClusterAsyncCommands<String, String>> thread_async = new ThreadLocal();

    protected void checkParam() {
        command.advice("batch > 1");

        command.notSupport("cluster", x -> Boolean.valueOf(x) == false, "only support cluster mode now!", true);
        command.notSupport("action", x -> RedisHandler.Action.valueOf(x) == RedisHandler.Action.list
                && command.getInt("work.batch") > 1, "when set as list, will ignore batch", false);

        command.notice("work.batch", x -> Integer.valueOf(x) > 1,
                "> 1, batch mode will get better performance");
    }

    /**
     * cluster: https://github.com/lettuce-io/lettuce-core/wiki/Redis-Cluster
     * config:  https://github.com/lettuce-io/lettuce-core/wiki/Configuring-Client-resources
     * option:  https://github.com/lettuce-io/lettuce-core/wiki/Client-Options
     * connecting pool: https://github.com/lettuce-io/lettuce-core/wiki/Connection-Pooling-5.1
     */
    protected void connecting() {
        ClientResources defaults = DefaultClientResources.create();
        log.info("default iothread: {}, cumpute thread: {}",
                defaults.ioThreadPoolSize(), defaults.computationThreadPoolSize());
        defaults.shutdown();

        resource = DefaultClientResources.builder()
                .ioThreadPoolSize(Math.max(defaults.ioThreadPoolSize(), 32))
                .computationThreadPoolSize(Math.max(defaults.computationThreadPoolSize(), 32))
                .build();

        List<RedisURI> list = new ArrayList<>();
        String[] servers = command.get("host").split("[, ]");
        for (String server : servers) {
            String[] host = server.split("[:]");
            list.add(RedisURI.create(host[0], host.length == 1 ?
                    command.getInt("port") : Integer.valueOf(host[1])));
        }
        cluster = RedisClusterClient.create(resource, list);

        if (command.getBool("async.open")) {

            /**
             * 当前，pool模式仅支持 async 模式
             */
            if (command.getInt("async.pool") > 0) {
                pool = ConnectionPoolSupport.createGenericObjectPool(() -> cluster.connect(), new GenericObjectPoolConfig());
                connList = new ArrayList<>();
                asyncList = new ArrayList<>();

                int count = Math.min(command.thread, command.getInt("async.pool"));
                pool.setMaxTotal(count);
                pool.setMinIdle(count);

                /**
                 * 将连接池中的连接全部取出来
                 */
                try {
                    pool.preparePool();

                    for(int i = 0; i < pool.getMaxTotal(); i++) {
                        connList.add(pool.borrowObject());
                        asyncList.add(connList.get(i).async());
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }

            } else {
                connection = cluster.connect();
                async = connection.async();
            }
        } else {
            connection = cluster.connect();
            sync = connection.sync();
        }
    }

    protected void preparing() {

        if (command.getBool("clear")) {
            if (command.isRead()) {

            } else if (sync != null) {
                sync.flushall();

            } else if (async != null) {
                async.flushall();
            }
        }
    }

    public void threadWork() {
        super.threadWork();

        if (pool != null) {
            thread_async.set(asyncList.get(IOPSThread.index() % asyncList.size()));
        }
    }

    /**
     * 仅用于async模式
     */
    protected RedisAdvancedClusterAsyncCommands<String, String> asyncHandle() {
        if (async == null) {
            return thread_async.get();

        } else {
            return async;
        }
    }

    public void terminate() {
        try {

            if (connection != null) {
                connection.close();
            
			} else {
                for (StatefulRedisClusterConnection<String, String> connection : connList) {
                    connection.close();
                }
            }

            if (pool != null) {
                pool.clear();
            }

            if (cluster != null) {
                cluster.shutdown();
            }

            if (resource != null) {
                resource.shutdown();
            }

        } catch (Exception e) {
            log.warn("terminate error: {}", e);
            System.exit(-1);
        }
    }

    public String dump() {
        if (pool != null) {
            return ", pool: " + pool.getMaxTotal();
        } else {
            return "";
        }
    }

    /**
     * 可测试内容：
     *      1. sync 单个发送
     *      2. sync 批量发送
     */
    @Override
    public int write(int[] result, int batch) {
        /** 有批量操作时才创建 */
        Map<String, String> data = (batch <= 1 || action == RedisHandler.Action.list) ?
                null : new HashMap<>();

        for (int i = 0; i < batch; i++) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("write get null, completed");
                return -1;
            }
            result[0] += 1;
            result[1] += wrap.size;

            switch (action) {
                case data:
                    if (data != null) {
                        data.put((String) wrap.array[0], (String) wrap.array[1]);
                    } else {
                        sync.set((String) wrap.array[0], (String) wrap.array[1]);
                    }
                    break;
                case list:
                    sync.lpush((String) wrap.array[0], (String) wrap.array[1]);
                    break;
            }
        }

        if (data != null) {
            switch (action) {
                case data:
                    sync.mset(data);
                    break;
                default:
                    assert(false);
                    break;
            }
        }
        return 1;
    }

    @Override
    public int read(int[] result, int batch) {

        String[] data = (batch <= 1 || action == RedisHandler.Action.list) ?
                null : new String[batch];

        for (int i = 0; i < batch; i++) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("read get null, completed");
                return -1;
            }

            switch (action) {
                case data:
                    if (data != null) {
                        data[i] = (String) wrap.array[0];

                    } else {
                        String value = sync.get((String) wrap.array[0]);
                    }
                    break;
                case list: {
                    List<String> list = sync.lrange((String) wrap.array[0], 0, -1);
                    if (list.size() == 0) {
                        if (command.emptyForbiden()) {
                            return -1;
                        }
                    }
                } break;
            }

            result[0] += 1;
            result[1] += wrap.size;
        }

        if (data != null) {
            switch (action) {
                case data: {
                    List<KeyValue<String, String>> mlist = sync.mget(data);
                    for (KeyValue<String, String> item : mlist) {
                        if (item == null || !item.hasValue()) {
                            if (command.emptyForbiden()) {
                                return -1;
                            }
                        }
                    }
                }
                break;
                default:
                    assert(false);
                    break;
            }
        }
        return 1;
    }
}
