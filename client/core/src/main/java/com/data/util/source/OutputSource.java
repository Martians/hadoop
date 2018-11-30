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

import static com.data.util.test.ThreadTest.debugThread;

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

    List<OutputHandler> handlelist = new ArrayList<>();
    Set<Integer> randSet = new HashSet<>();

    long total_size;
    long total_line;

    Thread   thread;
    String dataPath = "";
    public void initialize(BaseCommand command, String path) {
        this.command = command;
        dataPath = path;

        parseParam();

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
            log.info("clear file, but data path empty");
            System.exit(-1);
        }

        List<Path> pathList = Disk.deletePath(dataPath, "csv");
        log.info("try to clear, file range: {}", pathList.size());
    }

    protected void prepare() {
        clearFiles();

        cache = new MemCache();
        cache.initialize(command);

        if (randWrite) {
            int count = command.getInt("gen.output.file_count");
            count = Math.max(1, count);

            for (int i = 0; i < count; i++) {
                handlelist.add(nextFile(createRandIndex()));
            }
        } else {
            handlelist.add(nextFile(0));
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

            randSet.add(index);
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

        /**
         * thread 参数必须放在命令行，command initialize之后，就不会把thread放到 param.thread 中了
         *  或者直接修改 command.param.thread
         */
        String arglist = String.format("-thread %d", thnum);
        BaseCommand command = new BaseCommand(arglist.split(" "));
        command.regist(DataSource.class);

        command.set("gen.data_path", "test");
        command.set("gen.output.file_count", "10");
        command.set("gen.output.file_size", "10M");
        /**
         * 随机和顺序，两种测试
         */
        //command.set("gen.output.file_rand", false);

        OutputSource output = new OutputSource();
        output.initialize(command, "test");

        //debugThread();

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

        try {
            output.waitThread();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("complete");
    }

}
