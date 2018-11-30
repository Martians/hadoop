package com.data.bind;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Semaphore;

/**
 * redis
 *  1. 文档
 *      doc: http://redisdoc.com/
 *      cluster: https://redis.io/clients#scala
 *
 *      综合：http://blog.jobbole.com/114445/
 *
 *  2. 使用
 *      客户端使用：https://blog.csdn.net/syq521125/article/details/50592958
 *
 *
 *  3. 部署
 *      配置部署：https://www.cnblogs.com/it-cen/p/4295984.html
 *      Docker:
 *          docker run --name redis -h redis -d -p 6379:6379 redis
 *          docker exec -it redis redis-cli
 *
 *  4. lib
 *      Lettuce：
 *          https://stackoverflow.com/questions/32857922/jedis-and-lettuce-async-abilities
 *          https://www.baeldung.com/java-redis-lettuce
 *          https://github.com/lettuce-io/lettuce-core/wiki/Getting-started-(5.0)
 *
 *      Jedis:
 *          https://www.cnblogs.com/lxcy/p/8120301.html, 一些限制
 *
 *      Redisson:
 *          https://github.com/redisson/redisson/wiki
 *
 *      对比：
 *          http://www.cnblogs.com/liyan492/p/9858548.html
 *          https://blog.csdn.net/xhpscdx/article/details/79840060
 *
 *  5. 命令
 *      echo flushdb | redis-cli
 *      echo info | redis-cli
 */
public class RedisHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
            /** 不需要专门设置，command中会将prefix设置为bind */
            //setPrefix("kafka");

            addOption("cluster", "single or cluster", true);
            addOption("port", "redis listen port", 6379);
            addOption("action", "redis option, data|list", "key");
            addOption("client", "cluster notify: jedis|lettuce", Client.lettuce);

            addOption("async.open", "async mode", false);
            addOption("async.wait", "async batch and wait", true);
            addOption("async.outstanding", "async outstanding count", 10000);
            addOption("async.notify", "notify mode, 0:semaphore, 1:sleep", 0);
            addOption("async.pool", "pool connect count", 0);
        }
    }

    public enum Action {
        data,
        list,
    };

    enum Client {
        jedis,
        lettuce,
    };
    RedisBase client = null;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @Override
    public void initialize() {
        try {
            resolveParam();

            connecting();

            preparing();

        } catch (Exception e) {
            log.warn("initialize error: {}", e);
            System.exit(-1);
        }
    }

    protected void resolveParam() {
        Client type = command.getEnum("client", Client.class);
        switch(type) {
            case jedis:     client = new JedisClient();
                break;
            case lettuce: {
                if (command.getBool("async.open")) {
                    if (command.getBool("async.wait")) {
                        client = new LettuceAsyncWait();
                    } else {
                        client = new LettuceAsyncAccept();
                    }
                } else {
                    client = new LettuceSync();
                }
            } break;
        }
        client.action = command.getEnum("action", Action.class);
        client.command = command;
        client.source = source;
        client.output = output;
    }

    protected void connecting() {
        client.checkParam();
        client.connecting();
    }

    protected void preparing() {
        client.preparing();
    }

    public void threadWork() {
        client.threadWork();
    }
    public void threadTerm() { 
		client.threadTerm(); 
	}

    @Override
    public void terminate() {
        client.terminate();
    }

    public String dumpLoad() {
        String mode;
        if (command.getBool("async.open")) {
            if (command.getBool("async.wait")) {
                mode = "async_batch_wait";
            } else {
                mode = "async_accept";
            }
        } else {
            mode = "sync";
        }

        return String.format("action: %s, client: [%s], %s%s",
                command.get("action"), command.get("client"), mode, client.dump());
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @Override
    public int write(int[] result, int batch) {
        return client.write(result, batch);
    }

    @Override
    public int read(int[] result, int batch) {
        return client.read(result, batch);
    }
}
