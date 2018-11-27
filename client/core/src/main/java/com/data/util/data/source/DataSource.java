package com.data.util.data.source;

import com.data.base.Command;
import com.data.util.data.generator.*;
import com.data.util.common.Formatter;
import com.data.util.schema.ColumnSchema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/**
 * http://www.importnew.com/12460.html
 */
public class DataSource {
    static final Logger log = LoggerFactory.getLogger(DataSource.class);

    protected Command command;
    ColumnSchema schema;
    Random key;
    Random data;

    private AtomicLong total = new AtomicLong(0);
    private boolean sequence = false;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void set(Command command) {
        this.command = command;
        this.schema = command.schema;
    }

    public void initialize() {
        total.getAndSet(command.param.total);

        key = create(command.get("gen.key_type"));
        key.set(command);

        data = create(command.get("gen.data_type"));
        data.set(command);

        if (command.get("gen.key_type").equals("seq")) {
            sequence = true;
        }
    }

    Random create(String type) {
        if (type.equals("rand")) {
            return new Random();

        } else if (type.equals("uuid")) {
            return new UUID();

        } else if (type.equals("seq")) {
            return new Sequence();

        } else if (type.equals("table")) {
            return new Table();

        } else if (type.equals("fix")) {
            return new Fixed();

        } else {
            assert false: "unknown source [" + type + "]";
            return null;
        }
    }

    public void threadPrepare(int index) {
        if (key != null) {
            key.threadPrepare(index);
        }

        if (data != null) {
            data.threadPrepare(index + 5000);
        }
    }

    /*
     * getInput task range
     */
    public int nextWork(int tryCount) {
        /**
         * when use sequence, stop by itself
         */
        if (sequence) {
            return tryCount;
        }

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

    public boolean ending() {
        final long remain = command.thread * command.param.batch;
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
        Object[] array = new Object[schema.list.size()];

        List<ColumnSchema.Item> list = schema.list;
        array[0] = key.get(list.get(0));

        /**
         * if use sequence, every thread load command.param.total/thread
         */
        if (array[0] == null) {
            return null;
        }

        int size = 0;
        for (int i = 1; i < list.size(); i++) {
            ColumnSchema.Item item = list.get(i);

            array[i] = data.get(item);
            size += item.actual();
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
    //        ColumnSchema.Item s = schema.list.get(p);
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


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}
