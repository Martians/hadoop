package com.data.util.data.generator;
import com.data.util.schema.ColumnSchema;

public class UUID extends Random {

    public Object get(ColumnSchema.Item item) {
        return java.util.UUID.randomUUID().toString();
    }
}
