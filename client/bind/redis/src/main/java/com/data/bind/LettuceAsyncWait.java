package com.data.bind;


import com.data.util.data.source.DataSource;
import io.lettuce.core.LettuceFutures;
import io.lettuce.core.RedisFuture;
import io.lettuce.core.cluster.api.async.RedisAdvancedClusterAsyncCommands;

import java.util.concurrent.TimeUnit;

/**
 * https://github.com/lettuce-io/lettuce-core/wiki/Asynchronous-API
 *
 * 异步编程模式：
 *      1. Pull模式
 *          1）当做同步使用：future.get()、future.get(1, TimeUnit.MINUTES)
 *          2）批量等待：LettuceFutures.awaitAll
 *          3）自行开启线程，进行同步等待 thenRun
 *
 *      2. Push模式
 *          1）在默认线程执行回调：thenAccept、thenAccept
 *          2）另起线程执行回调，block或者长时间的操作：thenAcceptAsync
 */
public class LettuceAsyncWait extends LettuceSync {
    public LettuceAsyncWait() {
    }

    @Override
    public int write(int[] result, int batch) {
        RedisAdvancedClusterAsyncCommands<String, String> handle = asyncHandle();

        RedisFuture<String>[] array = new RedisFuture[batch];
        try {
            for (int i = 0; i < batch; i++) {
                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    log.debug("write get null, completed");
                    return -1;
                }

                RedisFuture<String> future = handle.set((String) wrap.array[0], (String) wrap.array[1]);
                array[i] = future;

                result[0] += 1;
                result[1] += wrap.size;
            }
            LettuceFutures.awaitAll(1, TimeUnit.MINUTES, array);

        } catch (Exception e) {
            log.info("write error, {}", e);
            System.exit(-1);
        }

        return 1;
    }

    @Override
    public int read(int[] result, int batch) {
        RedisAdvancedClusterAsyncCommands<String, String> handle = asyncHandle();

        RedisFuture<String>[] array = new RedisFuture[batch];
        try {
            for (int i = 0; i < batch; i++) {
                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    log.debug("read get null, completed");
                    return -1;
                }

                RedisFuture<String> future = handle.get((String) wrap.array[0]);
                array[i] = future;

                result[0] += 1;
                result[1] += wrap.size;
            }
            LettuceFutures.awaitAll(1, TimeUnit.MINUTES, array);

            for (RedisFuture<String> item : array) {
                if (item.get() == null) {
                    if (command.emptyForbiden()) {
                        return -1;
                    }
                }
            }

        } catch (Exception e) {
            log.info("read error, {}", e);
            System.exit(-1);
        }
        return 1;
    }
}
