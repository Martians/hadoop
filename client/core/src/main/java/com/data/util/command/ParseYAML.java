package com.data.util.command;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.yaml.snakeyaml.Yaml;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class ParseYAML extends BaseExporter {
    protected static final Logger log = LoggerFactory.getLogger(ParseYAML.class);

    public Properties initialize(String file, boolean resource) {
        Yaml yaml = new Yaml();

        try (InputStream is = resource ? ParseYAML.class.getResourceAsStream("/" + file)
                : new FileInputStream(new File(file)))
        {
            Iterable<Object> ret = yaml.loadAll(is);

            for (Object o : ret) {
                recurse(properties, "", o);
            }
            return properties;

        } catch (Exception e) {
            log.error("load yaml file {} failed, maybe invalid: {}", file, e);
            return null;
        }
    }

    void recurse(Properties properties, String prefix, Object object) {
        if (object instanceof Map) {
            Map map = ((Map) object);

            for (Object key : map.keySet()) {
                String current = prefix + (prefix.length() == 0 ? "" :  ".") + key;
                recurse(properties, current, map.get(key));
            }

        } else if (object instanceof List) {
            log.info("ignore array: {}", object);

        } else if (object != null) {
            properties.put(prefix, object.toString());
            log.trace("get: {} -> {}", prefix, object);
        }
    }

    public static void main(String[] args) {
        ParseYAML parser = new ParseYAML();
        parser.initialize("config.yaml", false);
    }
}
