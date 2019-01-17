package com.data;

import io.prometheus.client.Gauge;
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
 *      https://github.com/prometheus/client_java/blob/master/simpleclient/src/main/java/io/prometheus/client/Histogram.java
 *      https://github.com/prometheus/client_java/blob/master/simpleclient/src/main/java/io/prometheus/client/Summary.java
 *
 * api: http://prometheus.github.io/client_java/
 *      http://prometheus.github.io/client_java/io/prometheus/client/exporter/PushGateway.html
 */
public class Counter {
    static final Logger log = LoggerFactory.getLogger(Counter.class);

    Random random = new Random();
    int rand(int max) {
        return Math.abs(random.nextInt() % max);
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
        .labelNames("speed")
        .help("help").register();

    void startServer() {
        try {
            HTTPServer server = new HTTPServer(9090);

            while (true) {
                sleep(1000);
                working();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    /**
     * test_counter_speed
     * rate(test_counter_speed[10s])
     */
    void working() {
        counter.inc();
        counter_speed.labels("speed").inc(rand(10));
    }

    public static void main(String[] args) {
        Counter client = new Counter();
        client.startServer();
    }
}
