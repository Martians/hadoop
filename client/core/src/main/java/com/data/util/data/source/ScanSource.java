package com.data.util.data.source;

import com.data.util.common.Formatter;

import java.util.concurrent.ConcurrentLinkedDeque;

/**
 * https://github.com/nblair/code-examples/blob/master/datastax-java-driver-examples/src/main/java/examples/datastax/FullTableScan.java
 * http://www.myhowto.org/bigdata/2013/11/04/scanning-the-entire-cassandra-column-family-with-cql/
 */
public class ScanSource extends DataSource {

    ConcurrentLinkedDeque<Long> list = new ConcurrentLinkedDeque<>();
    long middle;
    long range = 100;
    static public long piece;

    @Override
    public void initialize() {
        super.initialize();

        /** 每个线程至少取1次, 最多 100次 */
        range = command.getLong("scan_range");
        range = Long.max(command.thread * 1, range);
        range = Long.min(command.thread * 1000, range);

        piece = Math.abs((Long.MIN_VALUE / range - 1) * 2);
        middle = Long.MIN_VALUE + piece * (range / 2);

        for (long index = 0; index < range; index ++) {
            list.addLast(index);
        }

        //log.info("{}, {}, {}", Long.MIN_VALUE, Long.MAX_VALUE, Long.MIN_VALUE + Long.MAX_VALUE);
        //log.info("piece: {}, middle: {}, {}, {}", piece, middle, Long.MIN_VALUE + piece * (range/2), Math.pow(2, 63));
        //System.exit(-1);
    }

    @Override
    public int nextWork(int tryCount) {
        return tryCount;
    }

    public String dumpLoad() {
        return String.format("workload: total %s, range %s", Formatter.formatIOPS(command.param.total), range);
    }

    @Override
    public Wrap next() {
        Long data = list.poll();
        if (data == null) {
            return null;
        }

        Object[] array = new Object[2];
        if (data <= range / 2) {
            array[0] = Long.MIN_VALUE + data * piece;
        } else {
            array[0] = middle + (data - range / 2) * piece;
        }

        if (data == range - 1) {
            array[1] = Long.MAX_VALUE;
        } else {
            array[1] = (Long) array[0] + piece;
        }
        return new Wrap(array, 0);
    }
}

