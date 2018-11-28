package com.data.util.data.generator;

import com.data.base.IOPSThread;
import com.data.util.schema.DataSchema;

import java.nio.CharBuffer;

public class Sequence extends Random {
    final static ThreadLocal<SeqBase> local = new ThreadLocal<>();

    static class SeqBase {
        SeqBase() {}
        SeqBase(long data, long last) {
            this.start = data;
            this.data = data;
            this.last = last;
        }

        Object next() {
            if (data == last) {
                return null;
            }
            long next = data++;
            return next;
        }
        long start = 0;
        long data = 0;
        long last = 0;
    }

    static class SeqString extends SeqBase {
        SeqString(String start) {
        }
        CharBuffer buffer;

        Object next() {
            return ++last;
        }
    }

    SeqBase getSequence() {
        SeqBase seq = local.get();
        if (seq == null) {
            long piece = command.param.total / command.thread;
            long data = piece * IOPSThread.index();
            seq = new SeqBase(data, data + piece);
            local.set(seq);
        }
        return seq;
    }

    public Object get(DataSchema.Item item) {
        return getSequence().next();
    }
}
