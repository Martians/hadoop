package com.data.bind;


import com.data.source.DataSource;
import com.data.monitor.MetricTracker;
import io.lettuce.core.LettuceFutures;
import io.lettuce.core.RedisFuture;
import io.lettuce.core.cluster.api.async.RedisAdvancedClusterAsyncCommands;

import java.util.ArrayList;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

public class LettuceAsyncAccept extends LettuceSync {
    public LettuceAsyncAccept() {
    }

    ThreadLocal<ArrayList<RedisFuture<String>>> waiting = new ThreadLocal<ArrayList<RedisFuture<String>>>();

    int notify = 0;
    /**
     * notify = 0，使用信号量
     */
    Semaphore semaphore = null;

    /**
     * notify = 1，忙等待模式，似乎性能更好一些
     */
    public AtomicLong count = new AtomicLong(0);
    public Long total;

    protected void checkParam() {
        command.notSupport("cluster", x -> Boolean.valueOf(x) == false, "only support cluster mode now!", true);
        command.notSupport("action", x -> RedisHandler.Action.valueOf(x) == RedisHandler.Action.list
                && command.getInt("work.batch") > 1, "when set as list, will ignore batch", false);
    }

    protected void preparing() {
        super.preparing();

        notify = command.getInt("async.notify");
        if (notify == 0) {
            semaphore = new Semaphore(command.getInt("async.outstanding") * command.param.thread);
        } else {
            total = command.getLong("async.outstanding") * command.param.thread;
        }
    }

    public void threadTerm() {
        if (waiting.get() != null) {
            log.debug("try to wait, future count {} ", waiting.get().size());
            LettuceFutures.awaitAll(1, TimeUnit.MINUTES,
                    waiting.get().toArray(new RedisFuture[waiting.get().size()]));
        }
    }

    public String dump() {
        return super.dump() + String.format(" - [outstanding: %d, notify: %s]",
                command.getLong("async.outstanding"),
                command.getInt("async.notify") == 0 ? "Semaphore" : "sleep");
    }

    void createWaitList() {
        if (command.source.ending() && waiting.get() == null) {
            log.debug("thread try to collect ending future, remain {}", command.source.total());
            waiting.set(new ArrayList<>());
        }
    }

    void addWaitList(RedisFuture<String> future) {
        if (waiting.get() != null) {
            waiting.get().add(future);
        }
    }

    void acquire() throws InterruptedException {

        if (notify == 0) {
            semaphore.acquire();

        } else if (notify == 1) {
            if (count.addAndGet(1) > total) {
                while (count.get() > total) {
                    com.data.util.sys.Common.sleep(10);
                }
            }
        }
    }

    void release() {
        if (notify == 0) {
            semaphore.release();

        } else if (notify == 1) {
            count.addAndGet(-1);
        }
    }


    @Override
    public int write(int[] result, int batch) {
        createWaitList();
        RedisAdvancedClusterAsyncCommands<String, String> handle = asyncHandle();

        try {
            long start = System.nanoTime();
            for (int i = 0; i < batch; i++) {
                acquire();

                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    log.debug("write get null, completed");
                    return -1;
                }
                final long size = wrap.size;

                RedisFuture<String> future = handle.set((String) wrap.array[0], (String) wrap.array[1]);
                future.thenAccept(x -> {
                    release();

                    MetricTracker.tracker.get(command.type)
                            .add(1, size, System.nanoTime() - start);
                });

                addWaitList(future);
                /**
                 * 使用负数，外部只增加thread的计数，不计入tracker
                 */
                result[0]--;
            }
        } catch (Exception e) {
            log.info("write error, {}", e);
            System.exit(-1);
        }

        return 0;
    }

    @Override
    public int read(int[] result, int batch) {
        createWaitList();
        RedisAdvancedClusterAsyncCommands<String, String> handle = asyncHandle();

        try {
            long start = System.nanoTime();
            for (int i = 0; i < batch; i++) {
                acquire();

                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    log.debug("read get null, completed");
                    return -1;
                }
                final long size = wrap.size;

                RedisFuture<String> future = handle.get((String) wrap.array[0]);
                future.thenAccept(x -> {
                    release();

                    if (x == null || x.length() == 0) {
                        if (command.emptyForbiden()) {
                            log.info("can't find key {}", (String) wrap.array[0]);
                            System.exit(-1);
                        }
                    } else {
                        MetricTracker.tracker.get(command.type)
                                .add(1, size, System.nanoTime() - start);
                    }
                });

                addWaitList(future);
                result[0]--;
            }

        } catch (Exception e) {
            log.info("read error, {}", e);
            System.exit(-1);
        }
        return 1;
    }
}
