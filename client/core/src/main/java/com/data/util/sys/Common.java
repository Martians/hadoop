package com.data.util.sys;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Common {
    static final Logger log = LoggerFactory.getLogger(Common.class);

    public static void sleep(long time) {
        try {
            Thread.sleep(time);
        } catch (InterruptedException e) {
            log.info("sleep error, {}", e);
        }
    }
}
