package com.data.util.data.source;

import com.data.base.Command;
import com.data.util.data.generator.Random;
import com.data.util.schema.DataSchema;
import com.data.util.test.ThreadTest;
import com.data.util.common.Formatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;
import java.util.concurrent.*;

import static com.data.util.Define.CSV_SEP;
import static com.data.util.test.ThreadTest.debugThread;

public class InputSource extends DataSource implements Runnable {
    static final Logger log = LoggerFactory.getLogger(InputSource.class);

    Thread  thread;
    MemCache cache;
    Long total_size = 0L;
    List<Path> pathList = new ArrayList<>();

    @Override
    public void initialize() {
        super.initialize();

        cache.command = command;

        cache = new MemCache();
        cache.initialize(command.thread);

        loadFiles();

        thread = new Thread(this, "InputGen");
        thread.start();
    }

    @Override
    public int nextWork(int tryCount) {
        return tryCount;
    }

    @Override
    public String dumpLoad() {
        return String.format("workload: path [%s], file %d",
                command.dataPath(), pathList.size());
    }

    @Override
    public Wrap next() {
        String line = cache.getInput();
        if (line == null) {
            log.debug("---- getInput next but empty");
            return null;
        }

        int size = 0;
        int nums = 0;
        int index = 0;

        String[] split = line.split(", ");
        Object[] array = null;

        if (command.schema.list.size() != split.length) {
            log.warn("input source, schema size: {}, split: {}, line: {}",
                    command.schema.list.size(), split.length, line);
            System.exit(-1);
        }

        //if (command.type == BaseCommand.Type.write) {
        array = new Object[command.schema.list.size()];
        System.arraycopy(split, 0, array, 0, command.schema.list.size());

        for (DataSchema.Item item : command.schema.list) {
            //test
            //if (item.type == integer) {
            //    array[index] = Long.parseLong(split[index]);
            //}
            //size += item.actual();
            //index++;
        }

        //} else {
        //    array = new Object[command.schema.primaryKey.size()];
        //
        //    for (Integer p : command.schema.primaryKey) {
        //        DataSchema.Item item = command.schema.list.get(p);
        //        if (item.type == integer) {
        //            split[index] = Long.parseLong((String)split[p]);
        //        }
        //        size += item.actual();
        //        index++;
        //    }
        //}
        return new Wrap(array, size);
    }

    public void loadFiles() {
        class MyFileVisitor extends SimpleFileVisitor<Path> {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                if (file.toString().endsWith("csv")) {
                    pathList.add(file);
                    log.debug("get file: {}", file);
                }
                return FileVisitResult.CONTINUE;
            }
        }

        try {
            Path path = Paths.get(command.dataPath());
            Files.walkFileTree(path, new MyFileVisitor());

        } catch(IOException e) {
            log.info("I/O Error, current {}, given {} ",
                    System.getProperty("user.dir"),
                    command.dataPath(), e);
            System.exit(-1);
        }
        log.info("try to load, file range: {}", pathList.size());
    }

    @Override
    public void run() {
        long last = System.nanoTime();

        for (Path p : pathList) {
            String line;

            try (BufferedReader file =
                         new BufferedReader(new FileReader(p.toFile())))
            {
                while ((line = file.readLine()) != null) {
                    cache.addInput(line);
                }
                total_size += p.toFile().length();

            } catch (IOException e) {
                System.out.println("I/O Error: " + e);
            }

        }
        cache.completeInput();

        log.info("load file complete, total line: [{}], size: [{}]",
                Formatter.formatIOPS(cache.total), Formatter.formatSize(total_size));
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////

    public static void main(String[] args) {
        int  thnum = 10;
        long total = 100000L;

        int  fildNum = 10;
        /**
         * command 中设置的 thread 个数，必须大于 thnum
         */
        String arglist = String.format("-schema string(4),string(4)[%d] -thread %d", fildNum, thnum);
        InputSource input = new InputSource();
        Command command = new Command(arglist.split(" "), true);
        command.set("gen.data_path", "test");

        try {
            Files.createDirectories(Paths.get("test"));
        } catch (IOException e) {
            e.printStackTrace();
        }
        Path p = Paths.get("test/file.csv");

        /**
         * 生成测试文件
         */
        Random gen = new Random();
        gen.set(command);
        try (BufferedWriter file =
                     new BufferedWriter(new FileWriter(p.toFile())))
        {
            long value = 100;
            for (long i = 0; i < total; i++) {
                StringBuilder sb = new StringBuilder();
                sb.append(value++);

                for (int c = 0; c < fildNum; c++) {
                    sb.append(",").append(gen.getString(4));
                }
                file.write(sb.append("\n").toString());
            }

        } catch (IOException e) {
            System.out.println("I/O Error: " + e);
        }
        log.info("write data completed");

        input.set(command);
        input.initialize();
        Set<Long> set = new ConcurrentSkipListSet<>();

        class Worker extends ThreadTest.TThread {
            InputSource gen;
            Set<Long> set;
            public int index;

            long count = 0;
            Worker(int index, InputSource gen, Set<Long> set) {
                this.index = index;
                this.gen = gen;
                this.set = set;
            }
            @Override
            public void run() {
                Wrap wrap;
                while (true) {
                    if ((wrap = gen.next()) == null) {
                        break;
                    }
                    set.add((Long)wrap.array[0]);
                    count++;
                }
            }
        }

        List<Worker> threads = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            Worker worker = new Worker(i, input, set);
            threads.add(worker);
            worker.start();
        }

        for (Worker t : threads) {
            try {
                t.join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            log.info("thread {}, range: {} ", t.index, t.count);
        }

        debugThread();
        log.info("size: {}", set.size());
    }
}
