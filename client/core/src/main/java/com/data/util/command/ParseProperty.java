package com.data.util.command;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Properties;

public class ParseProperty extends BaseExporter {
    protected static final Logger log = LoggerFactory.getLogger(ParseYAML.class);

    public Properties initialize(String file, boolean resource) {
        try (InputStream is = resource ? BaseCommand.class.getResourceAsStream("/" + file)
                : new FileInputStream(new File(file)))
        {
            properties.load(is);

            /**
             * 过滤掉类似于 [Hbase] 这样的 section 标志
             */
            for (String key : properties.stringPropertyNames()) {
                if (key.contains("[")) {
                    properties.remove(key);
                }
            }
            return this.properties;

        } catch (Exception e) {
            log.error("load config file {} failed", file);
            return null;
        }
    }
}
