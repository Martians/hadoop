package com.data;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Client {
    static final Logger log = LoggerFactory.getLogger(Client.class);

    public static void main(String[] args) {
        log.info("client complete");
        System.exit(0);
    }
}
