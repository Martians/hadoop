package com.data.util.source;

import com.data.util.command.BaseCommand;
import com.data.util.common.Formatter;
import com.data.util.generator.Random;
import com.data.util.schema.DataSchema;
import com.data.util.test.ThreadTest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

import static com.data.util.test.ThreadTest.debugThread;

public class InputSource extends DataSource implements Runnable {
    static final Logger log = LoggerFactory.getLogger(InputSource.class);

    Thread  thread;
    MemCache cache;
    Long total_size = 0L;
    String dataPath = "";
    List<Path> pathList = new ArrayList<>();

    @Override
    public void initialize() {
        super.initialize();

        cache.command = command;

        cache = new MemCache();
        cache.initialize(command.param.thread);

        loadFiles();

        thread = new Thread(this, "InputGen");
        thread.start();
    }

    public void setPath(String path) {
        dataPath = path;
    }

    @Override
    public int nextWork(int tryCount) {
        return tryCount;
    }

    @Override
    public String dumpLoad() {
        return String.format("workload: path [%s], file %d",
                dataPath, pathList.size());
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

        String[] split = line.split(", ");
        Object[] array = null;

        if (schema.list.size() != split.length) {
            log.warn("input source, schema size: {}, split: {}, line: {}",
                    schema.list.size(), split.length, line);
            System.exit(-1);
        }

        List<DataSchema.Item> list = schema.list;
        array = new Object[list.size()];
        System.arraycopy(split, 0, array, 0, list.size());

        for (int i = 0; i < list.size(); i++) {
            DataSchema.Item item = list.get(i);
            if (item.type == DataSchema.Type.integer) {
                array[i] = Long.parseLong(split[i]);
                size += DataSchema.actualSize(0);

            } else {
                size += DataSchema.actualSize(split[i]);
            }
        }

        //} else {
        //    array = new Object[schema.primaryKey.size()];
        //
        //    for (Integer p : schema.primaryKey) {
        //        DataSchema.Item item = schema.list.get(p);
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
        if (dataPath.isEmpty()) {
            log.info("load file, but data path empty");
            System.exit(-1);
        }

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
            Path path = Paths.get(dataPath);
            Files.walkFileTree(path, new MyFileVisitor());

        } catch(IOException e) {
            log.info("I/O Error, current {}, given {} ",
                    System.getProperty("user.dir"),
                    dataPath, e);
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
        String arglist = String.format("-table_schema string(4),string(4){%d} -thread %d", fildNum, thnum);

        BaseCommand command = new BaseCommand();
        command.set("gen.data_path", "test");
        //command.set("dump", "true");
        command.addParser("cache",  new MemCache.BaseOption());
        //command.addParser("table",  new ClientOption.Table());
        command.initialize(arglist.split(" "));

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

        DataSchema schema = new DataSchema();
        schema.set(command);
        schema.initialize(command.get("table.schema"));

        InputSource input = new InputSource();
        input.set(command, schema);

        input.setPath("test");
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
