package com.data.util.data.generator;

import com.data.base.Command;
import com.data.util.common.Formatter;
import com.data.util.test.ThreadTest;
import io.netty.util.internal.ConcurrentSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;

public class Table extends Random {
    static final Logger log = LoggerFactory.getLogger(Table.class);


    class TableArray {
        char[] data = new char[TABLE_SIZE];

        void  initialize() {
            java.util.Random random = new java.util.Random(100);

            for (int i = 0; i < TABLE_SIZE; i++) {
                final int size = KeyString.length();
                int pos = random.nextInt() % size;
                data[i] = KeyString.charAt(pos < 0 ? size + pos : pos);
            }
        }
    }
    
    static TableArray table_array;
    final static ThreadLocal<char[]> local = new ThreadLocal<>();

    final int UNIT_LENGTH = 1 * 1024;
    final int UNIT_COUNTS = 256;
    final int TABLE_SIZE  = UNIT_LENGTH * UNIT_COUNTS;
    final int RANDOME_NUM = 4;

    public int waterLevel = 32;
    int threadLen;

    public void set(Command command) {
        super.set(command);

        table_array = new TableArray();
        table_array.initialize();

        /** 每个线程池的缓冲数据大小 */
        threadLen = 256 * 1024;
    }

    private char[] threadArray() {
        char[] array = local.get();

        if (array == null) {
            array = new char[threadLen];
            local.set(array);

            for (int i = 0; i < threadLen / UNIT_LENGTH; i++) {
                System.arraycopy(table_array.data, getIndex(TABLE_SIZE - UNIT_LENGTH),
                        array, i * UNIT_LENGTH,
                        UNIT_LENGTH);
            }
        }
        return array;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * 每 2K 更新4个
     */
    int updateCount(int length) {
        return (length / (2 * 1024) + 1) * RANDOME_NUM;
    }

    @Override
    public String getString(int length) {
        /**
         * 数据量很少的情况下，仍然使用 random 方式
         */
        if (length < waterLevel) {
            return super.getString(length);
        }

        char[] array = threadArray();

        /**
         * 每次最多复制一个 UNIT_LENGTH
         */
        int pos = getIndex(threadLen - length);
        System.arraycopy(table_array.data, getIndex(TABLE_SIZE - UNIT_LENGTH),
                array, pos,
                length < UNIT_LENGTH ? length : UNIT_LENGTH);

        fill(array, pos, length, updateCount(length));
        return new String(array, pos, length);
    }

    public void fill(char[] array, int pos, int size, int count) {
        array[pos] = getChar();

        for (int i = 0; i < count; i++) {
            int index = getIndex(pos, pos + size);
            array[index] = getChar();
        }
    }

    /**
     * java -classpath client-0.0.1-SNAPSHOT.jar com.data.util.source.Table 4096
     */
    public static void main(String[] args) {
        Command command = new Command("".split(""), true);
        Set<String> set = new ConcurrentSet<>();
        AtomicLong conflict = new AtomicLong(0);

        class Worker extends ThreadTest.TThread {
            Random generator;
            int size;

            public ThreadTest.TThread newThread() {
                return new Worker();
            }

            public void initialize(Object...args) {
                generator = (Random)args[0];
                size = (int)args[1];
            }

            @Override
            public void run() {
                Long start = total * index;
                for (long i = 0; i < total; i++) {
                    String line = generator.getString(size);
                    //if (!updateFromCommandLine.add(line.hashCode() + line.substring(0, 4))) {
                    //    conflict.incrementAndGet();
                    //}
                    count++;
                }
            }

            @Override
            public void output() {
            }
        }

        long value_total = 0;
        if (args.length >= 2) {
            value_total = Integer.parseInt(args[1]);
        }

        int value_thread = 0;
        if (args.length >= 3) {
            value_thread = Integer.parseInt(args[2]);
        }

        int  thnum = value_thread == 0 ?
                10 : value_thread;
        long total = value_total == 0 ?
                1000000L : value_total;

        class Test {
            int size = 0;

            Test(int size) {
                this.size = size;
                work();
            }

            void work() {
                conflict.set(0);
                Random table = new Random();
                table.set(command);
                ThreadTest test = new ThreadTest();
                test.start(new Worker(), thnum, total, table, size, "base source");
                long time  = test.elapse();
                long count = conflict.get();

                conflict.set(0);
                table = new Table();
                table.set(command);

                Table local = (Table)table;
                local.waterLevel = size;
                test = new ThreadTest();
                test.start(new Worker(), thnum, total, table, size, "table source");

                log.info("size: {}, \t [{}]  origin: {}, table_array: {}, conflict: {}-{}", size,
                        String.format("%5.2f", time * 1.0 /test.elapse()),
                        Formatter.formatTime(time), Formatter.formatTime(test.elapse()),
                        count, conflict.get());
            }
        }

        log.info("thread: {}, count: {}", thnum, Formatter.formatIOPS(total));
        Test test;
        if (args.length > 0) {
            test = new Test(Integer.parseInt(args[0]));
            System.exit(0);
        }

        for (int i = 8; i <= 4096; i *= 2) {
            test = new Test(i);
        }
    }
}
