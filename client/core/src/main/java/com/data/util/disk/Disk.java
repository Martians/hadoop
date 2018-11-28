package com.data.util.disk;

import com.data.source.OutputSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;

public class Disk {
    static final Logger log = LoggerFactory.getLogger(Disk.class);

    static public List<Path> traversePath(String dir, String prefix) {

        List<Path> pathList = new ArrayList<>();
        class Tranverse extends SimpleFileVisitor<Path> {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                if (file.toString().endsWith(prefix)) {
                    pathList.add(file);
                }
                return FileVisitResult.CONTINUE;
            }
        }

        try {
            Files.createDirectories(Paths.get(dir));
            Path path = Paths.get(dir);
            Files.walkFileTree(path, new Tranverse());

        } catch(IOException e) {
            log.info("traverse path {}, but failed {}", dir, e);
            System.exit(-1);
        }
        return pathList;
    }

    static public List<Path> deletePath(String path, String prefix) {
        List<Path> pathList = traversePath(path, prefix);

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
}
