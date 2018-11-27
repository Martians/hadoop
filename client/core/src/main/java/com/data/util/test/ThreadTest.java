package com.data.util.test;

import com.data.util.common.Formatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class ThreadTest {
    final static Logger log = LoggerFactory.getLogger(ThreadTest.class);

    long start = 0;
    long total = 0;
    long count = 0;
    String name;

    /**
     * 用于在程序卡主时，提供一个中断点
     *      这里继承Thread，只是为了调用时方便
     */
    public static void debugThread() {
        new Thread() {
            public void run() {
                while(true) {
                    try {
                        Thread.sleep(1000);
                        log.info("----");
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        }.start();
    }

    public static class TThread extends Thread {
        public long index;
        public long total;
        public long count;

        public void set(long index, long total) {
            this.index = index;
            this.total = total;
        }

        ////////////////////////////////////////////////////////////////////////
        public TThread newThread() {
            log.error("not impletement initialize method");
            System.exit(-1);
            return null;
        }

        public void initialize(Object...args) {
            log.error("not impletement initialize method");
            System.exit(-1);
        }

        public void output() {
            log.info("thread {}, count: {} ", index, count);
        }
    }

    /**
     *  其他方法：使用 newInstance，传入 Class<?> TYPE
     *  worker = (TThread) type.newInstance();
     *  1. 继承的子类，必须是有 public 的构造函数
     *  2. 继承TThread的类，子类不能放在main函数中，至少是static inner class
     *          这就导致继承的TThread代码，与测试程序的逻辑，不能放在一块儿
     */
    //for (int i = 0; i < count; i++) {
    //    TThread worker = null;
    //
    //    try {
    //        worker = (TThread) type.newInstance();
    //        worker.initialize(args);
    //
    //    } catch (InstantiationException e) {
    //        e.printStackTrace();
    //    } catch (IllegalAccessException e) {
    //        e.printStackTrace();
    //    }
    //    threads.addInput(worker);
    //    worker.start();
    //}

    /**
     * 这里使用的方法，是在sub class中实现newThread方法
     */
    public <Type extends TThread> void start(Type type, int thn, long total, Object...args) {
        start = System.nanoTime();
        this.total = total;
        this.count = 0;

        if (args[args.length - 1] instanceof String) {
            name = (String)args[args.length - 1];
        }

        List<TThread> threads = new ArrayList<>();
        for (int i = 0; i < thn; i++) {
            TThread worker = type.newThread();
            worker.set(i, total / thn);
            worker.initialize(args);

            threads.add(worker);
            worker.start();
        }

        for (TThread worker : threads) {
            try {
                worker.join();

            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            worker.output();
            count += worker.count;
        }
    }

    public long elapse() {
        return System.nanoTime() - start;
    }

    public void dump() {
        log.info("{}complete: {}, using: {}", name != null ? "type：[" + name + "], ": "",
                Formatter.formatIOPS(count),
                Formatter.formatTime(System.nanoTime() - start));

        if (total != count) {
            log.info("not completed， total {}, count {}", total, count);
        }
    }

    public static void main(String[] args) {

        class NewThread extends TThread {
            int data;

            public ThreadTest.TThread newThread() {
                return new NewThread();
            }

            public void initialize(Object...args) {
                data = (int)args[0];
            }

            public void output() {
                log.info("thread {}, count: {}, data: {}", index, total, data);
            }

            public void run() {
                for (long i = 0; i < total; i++) {
                    count++;
                }
            }
        }

        long total = 10000;
        ThreadTest test = new ThreadTest();
        test.start(new NewThread(), 5, total, 100, "just test");
        test.dump();
    }
}
