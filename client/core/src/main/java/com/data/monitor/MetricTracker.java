package com.data.monitor;

import com.data.base.Command;
import com.data.util.common.Formatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MetricTracker extends Thread {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static MetricTracker tracker;
    static final ThreadLocal<long[]> local = new ThreadLocal<>();

    static public long incData(int index) {
        long[] array = local.get();
        if (array == null) {
            array = new long[8];
            local.set(array);
        }
        return ++array[index];
    }

    static public long getData(int index) {
        long[] array = local.get();
        if (array == null) {
            array = new long[8];
            local.set(array);
        }
        return array[index];
    }


    Object initLock = new Object();
    Metric total = new Metric();

    Metric[] array;
    long time;
    int count;
    boolean threadFlag;
    Command command;

    static public void initialize(Command command) {
        tracker = new MetricTracker();
        tracker.command = command;

        tracker.startThread();
    }

    static public void terminate() {
        if (tracker != null) {
            tracker.stopThread();
        }
    }

    public void startThread() {
        if (!threadFlag) {
            threadFlag = true;

            array = new Metric[Command.Type.end.ordinal() + 1];
            for (Command.Type e : Command.Type.values()) {
                array[e.ordinal()] = new Metric(e.name());
                array[e.ordinal()].clear();
            }

            /**
             * 只有该线程在运行，程序会退出
             */
            setDaemon(true);
            start();
        }
    }

    public void stopThread() {
        synchronized (initLock) {
            if (threadFlag) {
                threadFlag = false;

                try {
                    join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public Metric get(Command.Type type) {
        return array[type.ordinal()];
    }

    public Metric get(int index) {
        return array[index];
    }

    public void run() {
        time = System.nanoTime();
        setName("metric");

        while (threadFlag) {
            try {
                Thread.sleep(1000);

                if (threadFlag) {
                    sumarry(++count % 30 == 0);
                }

            } catch (InterruptedException e) {

            }
        }
        sumarry(true);
    }

    public void sumarry(boolean last) {
        long elapse = System.nanoTime() - time;

        log.info(typeMetric(command.type, elapse, last));

    }

    String typeMetric(Command.Type type, long elapse, boolean last) {
        Metric metric = get(type);
        metric.reset();

        String message = String.format("[%s] ", Formatter.formatElapse(elapse));

        message += String.format("%s: %5s, latency: %7s, size: %7s, ", command.type,
                    Formatter.formatIOPS(metric.last_iops),
                    Formatter.formatLatency(metric.last_time, metric.last_iops),
                    Formatter.formatSize(metric.last_size));

        if (last == false) {
            long remain_time = metric.total_iops == 0 ? 0 :
                    (command.param.total - metric.total_iops) * (elapse / metric.total_iops);

            message += String.format("count: %5s, size: %s, time: %s, remain: %s",
                    Formatter.formatIOPS(metric.total_iops),
                    Formatter.formatSize(metric.total_size),
                    Formatter.formatElapse(remain_time),
                    Formatter.formatIOPS(command.param.total - metric.total_iops));

        } else {
            long remain_size = metric.total_iops == 0 ? 0 :
                    (command.param.total - metric.total_iops) * (metric.total_size / metric.total_iops);

            message = "======== summary ======== [" +
                    String.format("%s: count: %s, iops: %s, latency: %s, size: %s, remain: %s]",
                            Formatter.formatElapse(elapse),
                            Formatter.formatIOPS(metric.total_iops),
                            Formatter.formatIOPS((long)(metric.total_iops * 1.0 * 1000 / (elapse / 1000000))),
                            Formatter.formatLatency(metric.total_time, metric.total_iops),
                            Formatter.formatSize(metric.total_size),
                            Formatter.formatSize(remain_size));
        }
        return message;
    }
}
