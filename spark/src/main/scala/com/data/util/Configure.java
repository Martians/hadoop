package com.data.util;

import java.io.*;
import java.net.URL;
import java.util.Properties;

public class Configure {

    public static String path = "/config.properties";
    private Properties props;

    public Configure() {
        load(path);
    }

    public Configure(String file) {
        load(file);
    }

    // read config file
    public void load(String file) {
        InputStream is = null;
        boolean resource = true;

        try {
            if (resource) {
                is = Configure.class.getResourceAsStream(file);
            } else {
                is = new FileInputStream(new File(file));
            }
            if (is == null) {
                throw new FileNotFoundException(file);
            }

            props = new Properties();
            props.load(is);

        } catch (Exception e) {
            System.out.println("get resource failed: " + e);

        } finally {
            if (is == null) {
                try{
                    is.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public String getProperty(String key) {
        return props.getProperty(key);
    }

    //http://www.cnblogs.com/alwayswyy/p/6421267.html
    public static URL getResource(String path) {
        try {
            // Class:
            //          1) Configure.class.getResource
            //          2) this.getClass().getResource
            // ClassLoader:
            //          1) Configure.class.getResource.getClassLoader()
            //          2) Thread.currentThread().getContextClassLoader()
            //          3) ClassLoader.getSystemClassLoader()
            // path:    1) class.getResource("/resources/config.properties")
            //          2) getClassLoader().getResource("resources/config.properties")

            // relative path is for .class file or jar
            URL url = Configure.class.getResource(path);
            if (url == null) {
                throw new FileNotFoundException(path);
            }
            return url;

        } catch (Exception e) {
            System.out.println("get resource " + path + ", but failed: " + e);
            return null;
        }
    }

    public static void main(String[] args) {

        String path = Configure.path;
        System.out.println(Configure.getResource(path).getFile());

        Configure res = new Configure(path);
        System.out.println(res.getProperty("topic"));
    }
}
