package com.data.util.data.generator;

import com.data.util.schema.DataSchema;

public class Numeric extends Random {
    long min, max;

    public void set(DataSchema.Item item) {
        check("integer", item);

        if (item.max != 0) {
            min = item.min;
            max = item.max;
        } else {
            min = command.getLong("gen.integer.min");
            max = command.getLong("gen.integer.max");
        }
    }

    @Override
    public Long getLong() {
        if (max == 0) {
            return getRandom().nextLong();

        } else {
            return Math.abs(getRandom().nextLong() % (max - min)) + min;
        }
    }
}
