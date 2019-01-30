package com.data.util.command;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Serializable;
import java.util.Properties;

public class BaseExporter implements Serializable {
    protected final Logger log = LoggerFactory.getLogger(this.getClass());

    Properties properties = new Properties();
    String _consist = "";
    String _current = "";

    /**
     * 固定添加的前缀
     */
    public void consist(String set) { _consist = set.isEmpty() ? "" : set  + "."; }

    /**
     * 临时添加的前缀
     */
    public void current(String set) {
        _current = set.isEmpty() ? "" : set  + ".";
    }

    public String get(String name) {
        String prefix = _current.isEmpty() ? _consist : _consist + _current;

        String value = properties.getProperty(prefix + name);
        if (value == null) {
            log.info("can't find key [{}]", prefix + name);
            System.exit(-1);
        }
        return properties.getProperty(prefix + name);
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
