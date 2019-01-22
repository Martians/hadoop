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

    static final io.prometheus.client.Counter counter_speed = io.prometheus.client.Counter.build()
        .name("test_counter_speed")
        /**
         * 这里是labe的名字，后续传入的是label的值
         */
        .labelNames("speed")
        //.labelNames("speed2")
        .help("help").register();

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
     * test_counter_speed
     *
     *  查看各个server的速度：
     *      1）rate(test_counter_speed[10s])
     *      2）sum(rate(test_counter_speed[10s])) by (speed)  # name=speed，label data相同的那些label，成为结果的一行
     *
     *  查看所有server速度和：sum(rate(test_counter_speed[10s]))
     *
     */
    void running() {
        counter.inc();
        counter_speed.labels("server-1").inc(rand(100));
        counter_speed.labels("server-2").inc(rand(100));
    }

    public static void main(String[] args) {
        Counter client = new Counter();
        client.startServer();
    }
}
