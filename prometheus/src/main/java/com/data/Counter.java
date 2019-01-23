package com.data;

import io.prometheus.client.exporter.HTTPServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Random;

/**
 * 用途：
 *      resource 中有 server 配置样例
 *
 * github:
 *      https://github.com/prometheus/client_java
 *
 * api: http://prometheus.github.io/client_java/
 *      http://prometheus.github.io/client_java/io/prometheus/client/exporter/PushGateway.html
 */
public class Counter {
    static final Logger log = LoggerFactory.getLogger(Counter.class);

    Random random = new Random();
    int rand(int max) { return rand(max, 0); }
    int rand(int max, int min) {
        return Math.abs(random.nextInt() % (max - min) + min);
    }

    void sleep(int ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    /**
     * define collector, Collector是4中类型的基类
     */
    static final io.prometheus.client.Counter counter = io.prometheus.client.Counter.build()
            .name("test_counter").help("Total requests.").register();

    static final io.prometheus.client.Counter counter_iops = io.prometheus.client.Counter.build()
            .name("test_counter_iops")
            /**
             * 这里是labe的名字，后续传入的是label的值
             */
            .labelNames("server")
            .help("for iops").register();

    static final io.prometheus.client.Counter counter_bytes = io.prometheus.client.Counter.build()
            .name("test_counter_bytes")
            /**
             * 这里是labe的名字，后续传入的是label的值
             */
            .labelNames("server")
            .help("for speed").register();

    static final io.prometheus.client.Counter counter_latency = io.prometheus.client.Counter.build()
            .name("test_counter_latency")
            .labelNames("server")
            .help("for latency").register();

    void startServer() {
        try {
            HTTPServer server = new HTTPServer(9090);
            working();

            while (true) {
                sleep(500);
                running();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    void working() {
    }

    /**
     * test_counter_bytes
     *
     *  1. 查看各个server的吞吐：
     *      1）rate(test_counter_bytes[10s])                   # 包含所有的label
     *      2）sum(rate(test_counter_bytes[10s])) by (server)  # label只剩下server：server label data相同的那些label，成为结果的一行
     *
     *  2. 执行速度
     *      1）如果系统只在进行传输，那么所有的时间都是在进行传输的，因此系统的吞吐就是其传输速度
     *      2）如果系统同时还在做其他事情，单独记录每个请求的处理时间，那么就用如下方式计算速度：
     *
     *  ##################################################################################################################################
     *  3. 查看每个server的速度
     *      sum(irate(test_counter_bytes[5m])) by(server) / sum(irate(test_counter_latency[5m])) by(server)
     *          by(server) 是为了按照 server 分组后聚合输出，保留更多记录
     *          因为每个分组只有一个值，这里sum其的作用，仅仅是去掉其他label、保留 server 这个 label
     *
     *  4. 查看所有server速度之和
     *      1）sum(sum(irate(test_counter_bytes[5m])) by(server) / sum(irate(test_counter_latency[5m])) by(server))
     *          将每个server的速度加起来；这里利用了上边的表达式
     *
     *      1）sum(irate(test_counter_bytes[5m]) / irate(test_counter_latency[5m]))
     *          计算各个server的速度，之后相加起来。实际结果同上（因为此处sum(irate(test_counter_bytes[5m])) by(server)的目的仅仅是改变输出label）
     *
     *      2）(sum(irate(test_counter_bytes[5m])) / sum(irate(test_counter_latency[5m]))) * count(test_counter_bytes)
     *          （计算所有server的数据量，除以所有server的时间 = 平均速度） * 个数
     *
     */
    void running() {
        counter.inc();
        counter_iops.labels("server-1").inc(rand(20, 10));
        counter_iops.labels("server-2").inc(rand(50, 30));

        counter_bytes.labels("server-1").inc(rand(1000, 300));
        counter_bytes.labels("server-2").inc(rand(1000, 500));

        counter_latency.labels("server-1").inc(rand(100, 20));
        counter_latency.labels("server-2").inc(rand(100, 50));
    }

    public static void main(String[] args) {
        Counter client = new Counter();
        client.startServer();
    }
}
