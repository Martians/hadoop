package com.data;

import io.prometheus.client.Counter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * github:
 *      https://github.com/prometheus/client_java
 *
 * api: http://prometheus.github.io/client_java/
 *      http://prometheus.github.io/client_java/io/prometheus/client/exporter/PushGateway.html
 *
 */
public class Client {
    static final Logger log = LoggerFactory.getLogger(Client.class);
    static final Counter requests = Counter.build()
        .name("requests_total").help("Total requests.").register();

    public static void main(String[] args) {
        log.info("client complete");
        requests.inc();
    }
}
