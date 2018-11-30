package com.data.util.source;

import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.test.ThreadTest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayDeque;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.atomic.AtomicInteger;

import static com.data.util.test.ThreadTest.debugThread;

public class MemCache {
    static final Logger log = LoggerFactory.getLogger(MemCache.class);
    BaseCommand command;

    public static class Option extends BaseOption {
        public Option() {
            addOption("chunk_size", "cache chunk size", 64);
            addOption("chunk_count", "cache chunk range", 1000000);
        }
    }

    /**
     * 基本配置
     */
    class Config {
        int thread = command.param.thread;
        int chunkSize  = command.getInt("cache.chunk_size");
        int chunkCount = command.getInt("cache.chunk_count");
        long dump_time = 30 * 1000000000L;
    }
    Config config;

    /**
     * 保存状态信息
     */
    class Status {
        boolean completed;
        long last = 0L;
        long total = 0L;
    }
    Status status;

    /** output 模式使用 */
    protected AtomicInteger finishCounter = new AtomicInteger(0);

    public long getTotal() { return status.total; }

    /**
     * 每个client使用的临时缓冲
     */
    public static final ThreadLocal<LineChunk> local = new ThreadLocal<LineChunk>();

    /**  循环使用的阻塞队列 */
    public ArrayBlockingQueue<LineChunk> dataList;

    /** 主线程中，用来保存临时数据，组成chunk后加入到队列中 */
    static class LineChunk extends ArrayDeque<String> {
        LineChunk(int cap) {
            super(cap);
        }
    }
    /**
     * 用于单线程的一方
     */
    LineChunk current;

    public void initialize(BaseCommand command) {
        this.command = command;

        config = new Config();
        status = new Status();

        parseParam();
    }

    void parseParam() {

        dataList = new ArrayBlockingQueue<>(config.chunkCount / config.chunkSize);
    }

    void incTotal() {
        ++status.total;

        if (status.total % 10000 == 0) {
            long time = System.nanoTime();
            if (time - status.last >= config.dump_time) {
                status.last = time;
                log.info("cache status: data chunk {}, current chunk {} ",
                        dataList.size(), current.size());
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * 用于从文件中读取，分发到各个thread
     *      单线程 add 到list，多线程从list访问
     */
    public void addInput(String line) {
        if (current == null) {
            current = new LineChunk(config.chunkSize);
        }
        current.add(line);

        incTotal();

        if (current.size() == config.chunkSize) {
            moveInput();
        }
    }

    protected void moveInput() {
        if (current != null) {
            try {
                dataList.put(current);
                log.debug("moveInput data handlelist: {}", dataList.size());

            } catch (InterruptedException e) {
                log.warn("move input err, {}", e);
                //System.exit(-1);
            }
            current = null;
        }
    }

    public String getInput() {
        /**
         * 每个线程使用自己的临时缓存
         */
        LineChunk list = local.get();
        if (list == null || list.size() == 0) {
            try {
                /**
                 * 该线程已经收到过了完成通知，但是又再次请求
                 *      这里直接检查，防止阻塞
                 */
                if (status.completed && dataList.size() == 0) {
                    log.debug("request again, cache already completed");
                    return null;
                }

                list = dataList.take();
                /**
                 * 收到了完成通知
                 */
                if (status.completed && list.size() == 0) {
                    local.set(null);
                    log.debug("recv notify, cache already completed");
                    return null;
                }
                local.set(list);

            } catch (InterruptedException e) {
                log.warn("get input err, {}", e);
            }
        }
        String line = list.poll();
        log.debug(" ---> getInput {}, local_sequence: {} ", line, list.size());
        return line;
    }

    public void completeInput() {
        moveInput();

        status.completed = true;
        log.info("cache input completed, notify all");

        /**
         * 无法用notify方式唤醒，dataList内部有自己的 condition、lock
         *      向每个线程发送一个空list
         */
        for (int i = 0; i < config.thread; i++) {
            try {
                dataList.put(new LineChunk(0));

            } catch (InterruptedException e) {
                log.warn("complete input err, {}", e);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * 用于从各个Thread中读取，写入到文件中
     *      多线程add，单线程get
     */
    public void addOutput(String line) {
        LineChunk list = local.get();
        if (list == null || list.size() == config.chunkSize) {
            moveOutput();

            list = new LineChunk(config.chunkSize);
            local.set(list);
        }
        list.add(line);
    }

    public String getOutput() {
        if (current == null || current.size() == 0) {
            try {
                current = dataList.take();
                if (status.completed && current.size() == 0) {
                    current = null;
                    log.info("cache get output, recv empty size, already completed");
                    return null;
                }

            } catch (InterruptedException e) {
                log.warn("get output err, {}", e);
            }
        }
        incTotal();

        return current.poll();
    }

    protected void moveOutput() {
        LineChunk list = local.get();

        if (list != null) {
            try {
                if (list.size() > 0) {
                    dataList.put(list);
                }
                log.debug("move output, data handlelist: {}", dataList.size());

            } catch (InterruptedException e) {
                log.warn("move output err, {}", e);
            }
            local.set(null);
        }
    }

    public void completeOutput() {
        moveOutput();

        if (finishCounter.addAndGet(1) == config.thread) {
            status.completed = true;
            log.debug("client complete output, range {}", config.thread);

            try {
                dataList.put(new LineChunk(0));

            } catch (InterruptedException e) {
                log.warn("complete output err, {}", e);
            }
        } else {
            if (finishCounter.get() > config.thread) {
                log.info("thread complete output, but complete {} exceed total {}", finishCounter.get(), config.thread);
                System.exit(-1);

            } else {
                log.info("thread complete output, complete {}/{}", finishCounter.get(), config.thread);
            }
        }
    }

    public static void main(String[] args) {
        int  thnum = 25;
        long total = 1000000;

        String arglist = String.format("-total %d -thread %d", total, thnum);
        BaseCommand command = new BaseCommand(arglist.split(" "));
        DataSource.regist(command);

        MemCache cache = new MemCache();
        Set<Long> set = new ConcurrentSkipListSet<>();
        ThreadTest test;

        //debugThread();
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        cache.initialize(command);
        set.clear();

        class Worker1 extends ThreadTest.TThread {
            MemCache cache;
            Set<Long> set;

            public ThreadTest.TThread newThread() {
                return new Worker1();
            }

            public void initialize(Object...args) {
                cache = (MemCache)args[0];
                set = (Set<Long>)args[1];
            }

            @Override
            public void run() {
                while (true) {
                    String line = cache.getInput();
                    if (line == null) {
                        break;
                    }
                    set.add(Long.valueOf(line));
                    count++;
                }
            }
        }

        Thread read = new Thread(new Runnable() {
            @Override
            public void run() {
                for (Long v = 0L; v < total; v++) {
                    cache.addInput(v.toString());
                }
                cache.completeInput();
            }
        });
        read.start();

        test = new ThreadTest();
        test.start(new Worker1(), thnum, total, cache, set, "input cache");
        test.dump();
        log.info("size: {}, {}", set.size(), set.size() != total ? "not match!" : "command good");

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        cache.initialize(command);
        set.clear();

        class Worker2 extends ThreadTest.TThread {
            MemCache cache;
            Set<Long> set;

            public ThreadTest.TThread newThread() {
                return new Worker2();
            }

            public void initialize(Object...args) {
                cache = (MemCache)args[0];
                set = (Set<Long>)args[1];
            }

            @Override
            public void run() {
                Long start = total * index;
                for (long i = 0; i < total; i++) {
                    Long data = start + i;
                    cache.addOutput(data.toString());
                    count++;
                }
                cache.completeOutput();
            }
        }

        Thread writ = new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    String line = cache.getOutput();
                    if (line == null) {
                        break;
                    }
                    set.add(Long.valueOf(line));
                }
            }
        });
        writ.start();

        test = new ThreadTest();
        test.start(new Worker2(), thnum, total, cache, set, "output cache");
        test.dump();
        try {
            writ.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("size: {}, {}", set.size(), set.size() != total ? "not match!" : "command good");
    }
}