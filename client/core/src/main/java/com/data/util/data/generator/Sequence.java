package com.data.util.data.generator;

import com.data.util.command.BaseCommand;
import com.data.util.schema.DataSchema;

import java.nio.CharBuffer;

public class Sequence extends Random {
    static final ThreadLocal<SeqBase> local = new ThreadLocal<>();
    long min;
    long max;

    public void set(DataSchema.Item item) {
        check("integer", item);
        min = item.min;
        max = item.max == 0 ? Long.MAX_VALUE : item.max;
    }

    static class SeqBase {
        SeqBase() {}
        SeqBase(long data, long last) {
            this.min = data;
            this.max = last;
            this.data = data;
        }

        Long next() {
            if (data == max) {
                return null;
            }
            long next = data++;
            return next;
        }
        long min = 0;
        long max = 0;
        long data = 0;
    }

    static class SeqString extends SeqBase {
        SeqString(String start) {
        }
        CharBuffer buffer;

        Long next() {
            return ++max;
        }
    }

    SeqBase getSequence() {
        SeqBase seq = local.get();
        if (seq == null) {
            long total = Math.min(command.param.total, max - min + 1);
            long piece = total / command.param.thread;

            /**
             * 最后一个piece确保执行到 max
             */
            long start = min + piece * threadIndex;
            long end   = start + piece * 2 > max ? max : start + piece;

            seq = new SeqBase(start, end);
            local.set(seq);
        }
        return seq;
    }

    @Override
    public Long getLong() { return getSequence().next(); }

    public static void main(String[] args) {
        String arglist = String.format("-thread 1 -total 100000");
        BaseCommand command = new BaseCommand(arglist.split(" "));
        command.param.thread = 1;

        DataSchema schema = new DataSchema();
        DataSchema.Item item = schema.new Item();

        item.type = DataSchema.Type.integer;
        item.max = 1000;
        item.min = 100;

        Sequence rand = new Sequence();
        rand.set(command);
        rand.set(item);

        for (int i = 0; i < 10000; i++) {
            Long data = rand.getLong();
            log.info("<{} {}", i, data);

            if (data == null) {
                break;
            }
        }
    }
}
