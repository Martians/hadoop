package com.data.util.data.generator;
import com.data.util.schema.DataSchema;

public class UUID extends Random {

    public void set(DataSchema.Item item) {
        check("string", item);
        item.len = 36;
    }

    @Override
    public String getString(int length) {
        return java.util.UUID.randomUUID().toString();
    }
}
