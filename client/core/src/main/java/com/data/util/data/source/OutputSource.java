package com.data.util.data.source;

import com.data.base.Command;
import com.data.util.common.Formatter;
import com.data.util.test.ThreadTest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;

public class OutputSource extends Thread {

    static final Logger log = LoggerFactory.getLogger(OutputSource.class);
    Thread   thread;
    MemCache cache;
    Command command;
    Random random = new Random();

    long total_size;
    long total_line;

    public void initialize(Command command) {
        this.command = command;
        cache.command = command;

        cache = new MemCache();
        cache.initialize(command.getInt("work.thread"));

        clearFiles();

        long seed = command.getLong("gen.seed");
        if (seed != 0) {
            random.setSeed(seed);
        }

        thread = new Thread(this, "output stream");
        thread.start();
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    protected void clearFiles() {
        List<Path> pathList = new ArrayList<>();
        class DeleteFileVisitor extends SimpleFileVisitor<Path> {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                if (file.toString().endsWith("csv")) {
                    Files.delete(file);
                    pathList.add(file);
                    log.info("delete file: {}", file);
                }
                return FileVisitResult.CONTINUE;
            }
        }

        try {
            Files.createDirectories(Paths.get(command.dataPath()));
            Path path = Paths.get(command.dataPath());
            Files.walkFileTree(path, new DeleteFileVisitor());

        } catch(IOException e) {
            System.out.println("I/O Error: " + e);
        }
        log.info("try to clear, file range: {}", pathList.size());
    }

    Set<Integer> fileset = new HashSet<>();

    class Output {
        BufferedWriter writer;
        String name;
        long size;
    }
    /**
     * 随机生成文件名
     */
    String nextFileName() {

        final String prefix = "file";
        final String suffix = ".csv";
        Integer max = 100;

        /** extend file range */
        while (fileset.size() * 10 / 8 >= max) {
            max = max * 10;
        }

        Integer index = 0;
        max = Integer.max(max, command.getInt("gen.output.file_count"));

        /** only one file */
        if (fileset.size() == 0 &&
                command.getInt("gen.output.file_count") == 1)
        {
            index = 0;

        } else if (fileset.size() < max) {
            do {
                index = Math.abs(random.nextInt()) % max;
            } while (fileset.contains(index));

        } else {
            log.warn("file_count only {}, file_size {}, too small to hold file",
                    command.getInt("gen.output.file_count"),
                    Formatter.formatSize(command.getInt("gen.output.file_size")));
            System.exit(-1);
        }

        fileset.add(index);
        return String.format("%s/%s-%02d%s",
                command.dataPath(), prefix, index, suffix);
    }

    Output nextFile() {
        try {
            String name = nextFileName();
            BufferedWriter file = new BufferedWriter(new FileWriter(name));
            Output out = new Output();
            out.writer = file;
            out.name = name;
            out.size = 0;

            log.info("next file: {}", name);
            return out;

        } catch (IOException e) {
            System.out.println("open file Error: " + e);
            System.exit(-1);
            return null;
        }
    }

    public void add(String line) {
        cache.addOutput(line);
    }
    public void complete() {
        cache.completeOutput();
    }

    @Override
    public void run() {

        long maxSize = command.getLong("gen.output.file_size");

        int count = command.getInt("gen.output.file_count");
        List<Output> list = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            list.add(nextFile());
        }

        try {
            while (true) {
                String line = cache.getOutput();
                if (line == null) {
                    break;
                }

                int index = Math.abs(random.nextInt()) % list.size();
                Output out = list.get(index);

                if (out.size >= maxSize) {
                    out.writer.close();
                    list.remove(out);

                    out = nextFile();
                    list.add(out);
                }

                out.writer.write(line);
                out.writer.write("\n");

                long size = line.length() + 1;
                out.size += size;
                total_size += size;
                total_line++;
            }
        } catch (IOException e) {
            System.out.println("write file Error: " + e);
            System.exit(-1);

        } finally {
            for (Output out : list) {
                try {
                    out.writer.close();
                    log.info("--------------");
                } catch (IOException e) {
                    System.out.println("close file Error: " + e);
                    System.exit(-1);
                }
            }
            list.clear();
        }

        log.info("write file complete, count: {}, total line: [{}], size: [{}]",
                fileset.size(), Formatter.formatIOPS(total_line), Formatter.formatSize(total_size));
    }

    public static void main(String[] args) {
        int  thnum = 10;
        long total = 10000000L;

        String arglist = String.format("-thread %d", thnum);
        Command command = new Command(arglist.split(" "), true);

        command.set("gen.data_path", "test");
        command.set("gen.output.file_count", "10");
        command.set("gen.output.file_size", "1M");
        command.set("work.thread", Integer.toString(thnum));
        command.fixSize("gen.output.file_size");

        OutputSource output = new OutputSource();
        output.initialize(command);

        class Worker extends ThreadTest.TThread {
            OutputSource output;

            public ThreadTest.TThread newThread() {
                return new Worker();
            }

            public void initialize(Object...args) {
                output = (OutputSource)args[0];
            }

            @Override
            public void run() {
                Long start = total * index;
                for (long i = 0; i < total; i++) {
                    Long data = start + i;
                    output.add(data.toString());
                    count++;
                }
                output.complete();
            }

            @Override
            public void output() {
            }
        }

        ThreadTest test = new ThreadTest();
        test.start(new Worker(), thnum, total, output, "output cache");
        test.dump();
        //debugThread();

        try {
            output.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("complete");
    }

}
