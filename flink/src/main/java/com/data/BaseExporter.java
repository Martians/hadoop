package com.data;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Properties;

public class BaseExporter {
    protected final Logger log = LoggerFactory.getLogger(this.getClass());

    Properties properties = new Properties();
    String _consist = "";
    String _current = "";

    public void consist(String set) {
        _consist = set  + ".";
    }
    public void current(String set) {
        _current = set  + ".";
    }

    private String prefix() {
        return _current.isEmpty() ? _consist : _consist + _current;
    }

    public String get(String name) {
        String value = properties.getProperty(prefix() + name);
        if (value == null) {
            log.info("can't find key {}", prefix() + name);
            System.exit(-1);
        }
        return properties.getProperty(prefix() + name);
    }

    public boolean getBool(String key) {
        return Boolean.parseBoolean(get(key));
    }

    public Long getLong(String name) {
        return Long.parseLong(get(name));
    }

    public Integer getInt(String name) {
        return getLong(name).intValue();
    }
}
