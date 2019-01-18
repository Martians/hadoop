package com.data;

import io.prometheus.client.Summary;

public class Summarys extends Counter {

    /**
     * 返回的是，达到这个比例的值，他们的value是多少
     */
    static final Summary receivedBytes = Summary.build()
            .name("requests_size_bytes").help("Request size in bytes.").register();
    static final Summary requestLatency = Summary.build()
            .name("requests_latency_seconds").help("Request latency in seconds.").register();

    static final Summary summary = Summary.build()
            .name("test_summary").help("Request latency in seconds.")
            /**
             * 默认 10min，使用5个bucket（每2min 切换一个bucket）
             */
            //.maxAgeSeconds()
            //.ageBuckets()
            .quantile(0.8, 0.1)
            .quantile(0.2, 0.1).register();

    void working() {
        /**
         * 不使用quantiles时，也自动有
         *      requests_latency_seconds_count
         *      requests_latency_seconds_sum
         */
        requestLatency.time(() -> {
            sleep(rand(2000, 1000));
        });

        /**
         * 可以用来记录：时间、长度
         */
        Summary.Timer requestTimer = requestLatency.startTimer();
        try {
            sleep(rand(2000, 1000));

        } finally {
            receivedBytes.observe(rand(10));
            requestTimer.observeDuration();
        }
    }

    /**
     * test_summary_sum
     * test_summary_count
     *
     * test_summary
     * test_summary[5m]
     *
     * test_summary{quantile="0.2"}
     * test_summary{quantile="0.2"}[5m]
     */
    void running() {
        sleep(500);
        summary.observe(rand(10));
    }

    public static void main(String[] args) {
        Summarys client = new Summarys();
        client.startServer();
    }
}
