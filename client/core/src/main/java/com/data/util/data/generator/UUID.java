package com.data.util.data.generator;
import com.data.util.schema.DataSchema;

public class UUID extends Random {

    public Object get(DataSchema.Item item) {
        return java.util.UUID.randomUUID().toString();
    }
}
