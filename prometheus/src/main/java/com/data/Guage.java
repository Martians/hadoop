package com.data;

import io.prometheus.client.Gauge;

public class Guage extends Counter {

    static final Gauge gauge = Gauge.build()
            .name("test_gauge").help("Inprogress requests.").register();

    static final Gauge gauge_duration = Gauge.build()
            .name("test_gauge_duration").help("Inprogress requests.").register();

    static final Gauge gauge_speed = Gauge.build()
            .name("test_gauge_speed")
            .labelNames("speed")
            .help("Inprogress requests.").register();

    void working() {
        /**
         * 记录持续时间，用于批量任务
         */
        Gauge.Timer timer = gauge_duration.startTimer();
        sleep(500);
        timer.setDuration();

        timer = gauge_duration.startTimer();
        sleep(1000);
        timer.setDuration();
    }

    /**
     * test_gauge_speed
     */
    void running() {

        /**
         * 经常用于记录时间
         */
        gauge.setToCurrentTime();

        gauge_speed.labels("server").set(rand(10));
    }

    public static void main(String[] args) {
        Counter client = new Guage();
        client.startServer();
    }
}
