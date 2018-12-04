package com.data.util.disk;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;

public class Disk {
    static final Logger log = LoggerFactory.getLogger(Disk.class);

    static public List<Path> traversePath(String path, String prefix, boolean directory) {

        List<Path> pathList = new ArrayList<>();
        List<Path> dirList = new ArrayList<>();
        class Tranverse extends SimpleFileVisitor<Path> {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
                if (file.toString().endsWith(prefix)) {
                    pathList.add(file);
                }
                return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
                dirList.add(dir);
                return super.postVisitDirectory(dir, exc);
            }
        }

        try {
            Path curr = Paths.get(path);
            Files.createDirectories(curr);
            Files.walkFileTree(curr, new Tranverse());

        } catch(IOException e) {
            log.info("traverse path {}, but failed {}", path, e);
            System.exit(-1);
        }
        return directory ? dirList : pathList;
    }

    static public List<Path> deletePath(String path, String prefix) {
        List<Path> pathList = traversePath(path, prefix, false);

        try {
            for (Path file : pathList) {
                Files.delete(file);
                log.info("delete file: {}", file);
            }
        } catch (IOException e) {
            log.info("delete path {}, but failed {}", path, e);
            System.exit(-1);
        }
        return pathList;
    }

    /**
     * 读取默认配置文件，通常会在jar包中
     */
    static public Boolean fileExist(String file, boolean resource) {
        if (resource) {
            URL url = Thread.currentThread().getContextClassLoader().getResource(file);
            return url != null;

        } else {
            return new File(file).exists();
        }
    }

    static public String resourcePath(String file) {
        URL url = Thread.currentThread().getContextClassLoader().getResource(file);
        if (url != null) {
            return url.getPath();

        } else {
            return null;
        }
    }
}
