package com.data.util.generator;

import com.data.util.schema.DataSchema;

public class Numeric extends Random {
    long min, max;

    public void set(DataSchema.Item item) {
        check("integer", item);
        min = item.min;
        max = item.max;
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
