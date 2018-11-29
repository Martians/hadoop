package com.data.bind;

import com.data.util.source.DataSource;
import redis.clients.jedis.HostAndPort;
import redis.clients.jedis.JedisCluster;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

import java.util.HashSet;
import java.util.List;

public class JedisClient extends RedisBase {

    public JedisClient() {
    }

    private JedisPoolConfig config = new JedisPoolConfig();
    private JedisPool pool = null;

    private ThreadLocal<JedisCluster> cluster = new ThreadLocal<>();

    protected void checkParam() {
        command.notSupport("cluster", x -> !Boolean.valueOf(x),
                "only support cluster mode now!", true);
        command.notSupport("work.batch", x -> Integer.valueOf(x) > 1);
    }

    protected void connecting() {
        //config.setMaxIdle(100)
        //config.setMaxTotal(500)
        //config.setMinIdle(0)
        //config.setMaxWaitMillis(2000)
        //config.setTestOnBorrow(true)
    }

    protected void preparing() {
        if (command.getBool("clear")) {
            //cluster.flushAll();
        }
    }

    public void threadWork() {
        if (command.getBool("cluster")) {
            HashSet nodes = new HashSet<HostAndPort>();
            String[] servers = command.get("host").split("[, ]");
            for (String server : servers) {
                String[] host = server.split("[:]");
                nodes.add(new HostAndPort(host[0], host.length == 1 ?
                        command.getInt("port") : Integer.valueOf(host[1])));
            }
            cluster.set(new JedisCluster(nodes, config));
        }
    }

    public void terminate() {
        try {
            if (cluster.get() != null) {
                cluster.get().close();
                cluster.set(null);
            }

            if (pool != null) {
                pool.close();
                pool = null;
            }

        } catch (Exception e) {
            log.warn("terminate error: {}", e);
            System.exit(-1);
        }
    }

    @Override
    public int write(int[] result, int batch) {

        /** 有批量操作时才创建 */
        String[] data = (batch <= 1 || action == RedisHandler.Action.list) ?
                null : new String[batch * 2];

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
                        data[i * 2] = (String) wrap.array[0];
                        data[i * 2 + 1] = (String) wrap.array[1];
                    } else {
                        cluster.get().set((String) wrap.array[0], (String) wrap.array[1]);
                    }
                    break;
                case list:
                    cluster.get().lpush((String) wrap.array[0], (String) wrap.array[1]);
                    break;
            }
        }

        if (data != null) {
            switch (action) {
                case data:
                    cluster.get().mset(data);
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

        for (int i = 0; i < batch; i++) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("read get null, completed");
                return -1;
            }

            switch (action) {
                case data: {
                    String data = cluster.get().get((String) wrap.array[0]);
                } break;
                case list: {
                    List<String> list = cluster.get().lrange((String) wrap.array[0], 0, -1);
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
        return 1;
    }
}
