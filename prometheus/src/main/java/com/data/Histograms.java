package com.data;

import io.prometheus.client.Histogram;
import io.prometheus.client.Summary;

public class Histograms extends Counter {

    /**
     * 落入到每个 bucket 中的value的个数，而不是value具体的值
     */
    static final Histogram histogram = Histogram.build()
            .name("requests_latency_seconds")
            .buckets(.01, .2, .7, .8).help("Request latency in seconds.").register();

    static final Histogram receivedBytes = Histogram.build()
            .name("histogram_size_bytes").help("Request size in bytes.").register();
    static final Histogram requestLatency = Histogram.build()
            .name("histogram_latency_seconds").help("Request latency in seconds.").register();

    void working() {
        Histogram.Timer requestTimer = histogram.startTimer();
        try {
            sleep(rand(1000));
        } finally {
            requestTimer.observeDuration();
        }
    }

    void running() {
        /**
         * 显示的是按照大小划分之后的累加值
         *      requests_latency_seconds_bucket
         *      requests_latency_seconds_count
         *      requests_latency_seconds_sum
         */
        histogram.observe(rand(10));

        /**
         *  求速度，直接用 counter 比较好；这里的例子是，为了用histogram统计的同时，计算下速度
         *
         *  ## 时间维度：
         *  1）查看最近5m的平均延迟：
         *          用的是 _sum, _count；实际也可以通过counter而不是bucket记录（_sum, _count本身就是counter）
         *          rate(histogram_latency_seconds_sum[5m]) / rate(histogram_latency_seconds_count[5m])
         *
         *  2）查看最近5m，延迟小于 750 ms的个数：
         *          histogram_latency_seconds_bucket{le="0.75"}[5m]
         *
         *  3）查看最近5m，延迟小于 750 ms的比例：
         *          用的是 _bucket{le="0.75"}、_count
         *          sum(rate(histogram_latency_seconds_bucket{le="0.75"}[5m])) / sum(rate(histogram_latency_seconds_count[5m]))
         *              使用rate，才能计算最近一段时间内的值，而不是整个历史阶段的值
         *              rate的结果，还保留了label，除法两边label可能不一致（被除数里边包含了label：le=0.75）
         *
         *  4）查看最近5m，达到90%的比例的延迟情况
         *          histogram_quantile(0.90, sum(rate(histogram_latency_seconds_bucket[5m])) by (le))
         *
         *  ## 速度维度
         *  1）最近5min的平均速度：5min内递增的总数据量 / 5min递增用的时间，两个都是 Counter 类型
         *          rate(histogram_size_bytes_sum[5m]) / rate(histogram_latency_seconds_sum[5m])
         */
        Histogram.Timer requestTimer = requestLatency.startTimer();
        try {
            sleep(rand(1000));
        } finally {
            receivedBytes.observe(rand(10));
            requestTimer.observeDuration();
        }
    }

    public static void main(String[] args) {
        Histograms client = new Histograms();
        client.startServer();
    }
}
