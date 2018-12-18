package com.data.util.command;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Properties;

public class ParseProperty {

    protected static final Logger log = LoggerFactory.getLogger(ParseYAML.class);

    public Properties initialize(String file) {
        try (InputStream is = new FileInputStream(new File(file))) {
            Properties props = new Properties();
            props.load(is);

            /**
             * 过滤掉类似于 [Hbase] 这样的 section 标志
             */
            for (String key : props.stringPropertyNames()) {
                if (key.contains("[")) {
                    props.remove(key);
                }
            }
            return props;

        } catch (Exception e) {
            log.error("load config file {} failed", file);
            return null;
        }
    }
}
