package com.data.monitor;

import java.util.concurrent.atomic.AtomicLong;

public class Metric {

    String name;

    public AtomicLong iops = new AtomicLong(0);
    public AtomicLong size = new AtomicLong(0);
    public AtomicLong time = new AtomicLong(0);

    public Long total_iops = 0L;
    public Long total_size = 0L;
    public Long total_time = 0L;

    public  Long last_iops;
    public  Long last_size;
    public  Long last_time;

    public long record;

    public Metric() {}
    public Metric(String name) {
        this.name = name;
    }

    public void clear() {

        iops.getAndSet(0);
        size.getAndSet(0);
        time.getAndSet(0);

        total_iops = 0L;
        total_size = 0L;
        total_time = 0L;

        last_iops = 0L;
        last_size = 0L;
        last_time = 0L;

        update();
    }

    public void add(long iops, long size, long time) {
        this.iops.addAndGet(iops);
        this.size.addAndGet(size);
        this.time.addAndGet(iops * time);
    }

    public void reset() {
        //long current = System.nanoTime();
        //long elapse = current - record;

        last_iops = iops.getAndSet(0);
        last_size = size.getAndSet(0);
        last_time = time.getAndSet(0);

        total_iops += last_iops;
        total_size += last_size;
        total_time += last_time;
    }

    public long update() {
        long nows = System.nanoTime();
        long last = System.nanoTime() - record;
        record = nows;
        return last;
    }
}
