package com.data.util.source;

import com.data.util.command.BaseCommand;
import com.data.util.common.Formatter;
import com.data.util.disk.Disk;
import com.data.util.test.ThreadTest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.util.*;

public class OutputSource implements Runnable {

    static final Logger log = LoggerFactory.getLogger(OutputSource.class);

    final String prefix = "file";
    final String suffix = ".csv";

    MemCache cache;
    BaseCommand command;

    Random random = new Random();
    boolean randWrite = true;
    int index = 0;
    long maxSize;

    long total_size;
    long total_line;

    Thread   thread;
    String dataPath = "";
    public void initialize(BaseCommand command, String path) {
        this.command = command;
        dataPath = path;

        parseParam();

        clearFiles();

        prepare();

        thread = new Thread(this, "output source");
        thread.start();
    }

    public void waitThread() throws InterruptedException {
        thread.join();
    }

    protected void parseParam() {
        long seed = command.getLong("gen.seed");
        if (seed != 0) {
            random.setSeed(seed);
        }

        maxSize = command.getLong("gen.output.file_size");
        randWrite = command.getBool("gen.output.file_rand");
    }

    protected void clearFiles() {
        if (dataPath.isEmpty()) {
            log.info("load file, but data path empty");
            System.exit(-1);
        }

        List<Path> pathList = Disk.deletePath(dataPath, "csv");
        log.info("try to clear, file range: {}", pathList.size());
    }

    protected void prepare() {
        cache.command = command;
        cache = new MemCache();
        cache.initialize(command.getInt("work.thread"));

        if (randWrite) {
            int count = command.getInt("gen.output.file_count");
            List<OutputHandler> list = new ArrayList<>();
            for (int i = 0; i < count; i++) {
                list.add(nextFile(createRandIndex()));
            }
        }
    }

    public void add(String line) {
        cache.addOutput(line);
    }
    public void complete() {
        cache.completeOutput();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    List<OutputHandler> handlelist = new ArrayList<>();
    Set<Integer> randSet = new HashSet<>();

    class OutputHandler {
        BufferedWriter writer;
        String name;
        long size;
    }

    String fileName(int index) {
        return String.format("%s/%s-%02d%s", dataPath, prefix, index, suffix);
    }

    /**
     * 随机生成文件名
     */
    int createRandIndex() {
        Integer max = 100;

        /** extend file range */
        while (randSet.size() * 10 / 8 >= max) {
            max = max * 10;
        }

        Integer index = 0;
        max = Integer.max(max, command.getInt("gen.output.file_count"));

        /** only one file */
        if (randSet.size() == 0 &&
                command.getInt("gen.output.file_count") == 1)
        {
            index = 0;

        } else if (randSet.size() < max) {
            do {
                index = Math.abs(random.nextInt()) % max;
            } while (randSet.contains(index));

        } else {
            log.warn("file_count only {}, file_size {}, too small to hold file",
                    command.getInt("gen.output.file_count"),
                    Formatter.formatSize(command.getInt("gen.output.file_size")));
            System.exit(-1);
        }

        randSet.add(index);
        return index;
    }

    OutputHandler nextFile(int index) {
        try {
            String name = fileName(index);
            BufferedWriter file = new BufferedWriter(new FileWriter(name));
            OutputHandler out = new OutputHandler();
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

    OutputHandler nextHandle() {
        if (randWrite) {
            int index = Math.abs(random.nextInt()) % handlelist.size();
            return handlelist.get(index);

        } else {
            return handlelist.get(0);
        }
    }

    void switchFile(OutputHandler out) throws IOException {
        out.writer.close();
        handlelist.remove(out);

        if (randWrite) {
            handlelist.add(nextFile(createRandIndex()));

        } else {
            handlelist.add(nextFile(index++));
        }
    }

    @Override
    public void run() {

        try {
            while (true) {
                String line = cache.getOutput();
                if (line == null) {
                    break;
                }

                OutputHandler out = nextHandle();
                out.writer.write(line);
                out.writer.write("\n");

                long size = line.length() + 1;
                out.size += size;

                total_size += size;
                total_line++;

                if (maxSize > 0 && out.size >= maxSize) {
                    switchFile(out);
                }
            }
        } catch (IOException e) {
            System.out.println("write file Error: " + e);
            System.exit(-1);

        } finally {
            for (OutputHandler out : handlelist) {
                try {
                    out.writer.close();

                } catch (IOException e) {
                    System.out.println("close file Error: " + e);
                    System.exit(-1);
                }
            }
            handlelist.clear();
        }

        log.info("write file complete, count: {}, total line: [{}], size: [{}]",
                randSet.size(), Formatter.formatIOPS(total_line), Formatter.formatSize(total_size));
    }

    public static void main(String[] args) {
        int  thnum = 10;
        long total = 10000000L;

        String arglist = "";
        BaseCommand command = new BaseCommand(arglist.split(" "));
        DataSource.regist(command);

        command.set("gen.data_path", "test");
        command.set("gen.output.file_count", "10");
        command.set("gen.output.file_size", "1M");
        command.set("work.thread", Integer.toString(thnum));
        //command.fixSize("gen.output.file_size");

        OutputSource output = new OutputSource();
        output.initialize(command, "test");

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
            output.waitThread();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("complete");
    }

}
