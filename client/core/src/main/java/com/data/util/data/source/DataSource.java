package com.data.util.data.source;

import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.common.Formatter;
import com.data.util.schema.DataSchema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/**
 * http://www.importnew.com/12460.html
 */
public class DataSource {
    static final Logger log = LoggerFactory.getLogger(DataSource.class);

    protected BaseCommand command;
    protected DataSchema schema;
    protected String dataPath = "";
    boolean onlyKey = false;

    /**
     * 用于给各个线程分配刻可执行的工作
     */
    private AtomicLong total = new AtomicLong(0);

    public static class Option extends BaseOption {
        protected void initialize() {
            addOption("data_path", "data file path; if setted, output[generate、scan], input[load、read]", "");

            addOption("output.file_count", "min output file count", 1);
            addOption("output.file_size", "output file size (M)", "-1");
            addOption("output.file_rand", "random write to multi file", true);

            addOption("input.verify", "verify data schema", true);
            addOption("input.source.class", "new input source class", "");
            addOption("input.source.config", "input source config", "");
            addOption("input.source.strict", "source config strict", false);
            addOption("input.source.dump", "source config dump", false);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static void regist(BaseCommand command) {
        command.regist("gen",  new Option());
        command.regist("cache",  new MemCache.Option());
    }

    public void initialize(BaseCommand command, DataSchema schema, String path) {
        this.command = command;
        this.schema = schema;
        dataPath = path;

        total.getAndSet(command.param.total);
        /**
         * 初始化相关的 Generator
         */
        for (DataSchema.Item item : schema.list) {
            item.gen.prepare(item);
        }
    }

    public void threadPrepare(int index) {
        int itemIndex = 0;
        for (DataSchema.Item item : schema.list) {
            item.gen.threadPrepare(index + itemIndex);
            itemIndex++;
        }
    }

    public void onlyKey(boolean set) {
        onlyKey = set;
    }

    /*
     * getInput task range
     */
    public int nextWork(int tryCount) {

        long remain = total.addAndGet(-tryCount);
        if (remain < 0) {
            synchronized (total) {
                total.addAndGet(tryCount);
                remain = total.getAndSet(0);

                if (remain <= 0) {
                    total.addAndGet(remain);
                    remain = 0;

                } else {
                    log.debug("last task: {}", remain);
                }
                return (int)remain;
            }

        } else {
            return tryCount;
        }
    }

    /**
     * 用于判断任务是否快结束了
     */
    public boolean ending() {
        final long remain = command.param.thread * command.param.batch;
        return total.get() <= remain;
    }
    public long total() { return total.get(); }

    public String dumpLoad() {
        return String.format("workload: total %s", Formatter.formatIOPS(command.param.total));
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public static class Wrap {
        public Wrap(Object[] array, int size) {
            this.array = array;
            this.size = size;
        }
        public Object[] array;
        public int size;
    }

    public Wrap next() {
        List<DataSchema.Item> list = schema.list;
        Object[] array = new Object[list.size()];

        int size = 0;
        for (int i = 0; i < array.length; i++) {
            DataSchema.Item item = list.get(i);
            array[i] = item.gen.get(item);

            /**
             * if use sequence, every totalThread load command.param.total/totalThread
             */
            if (array[i] == null) {
                return null;
            }
            size += item.curr;
        }
        return new Wrap(array, size);
    }

    //public Wrap nextRead() {
    //    int index = 0;
    //    int size = 0;
    //
    //    Object[] array = new Object[schema.primaryKey.size()];
    //
    //    if (command.param.sequence) {
    //        array[0] = getSequence().next();
    //        if (array[0] == null) {
    //            return null;
    //        }
    //    }
    //
    //    for (Integer p : schema.primaryKey) {
    //        DataSchema.Item s = schema.handlelist.get(p);
    //
    //        if (array[index] == null) {
    //            switch (s.type) {
    //                case string:
    //                    array[index] = getString(true, s.size);
    //                    break;
    //                case integer:
    //                    array[index] = getLong(true);
    //                    break;
    //                default:
    //                    log.error("unknown type: {}", s.type);
    //                    System.exit(-1);
    //                    break;
    //            }
    //        }
    //        size += s.actual();
    //        index++;
    //    }
    //    return new Wrap(array, size);
    //}
}
