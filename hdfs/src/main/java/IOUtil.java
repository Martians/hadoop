
package com.data.hadoop;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

import org.apache.hadoop.fs.FsUrlStreamHandlerFactory;
import org.apache.hadoop.io.IOUtils;

public class IOUtil {

    static {
        URL.setURLStreamHandlerFactory(new FsUrlStreamHandlerFactory());
    }

    static void read(String path) throws IOException {
        InputStream in = null;
        try {
            in = new URL(path).openStream();
            IOUtils.copyBytes(in, System.out, 4096, false);
        } finally {
            IOUtils.closeStream(in);
        }
    }

    public static void main(String[] args) throws Exception {
        read(args[0]);
    }
}
