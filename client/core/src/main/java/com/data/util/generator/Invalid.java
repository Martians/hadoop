package com.data.util.generator;

import com.data.util.schema.DataSchema;

public class Invalid extends Random {
    public Invalid() { valid = false; }

    public void set(DataSchema.Item item) {
        check("integer, string, object", item);
        item.type = DataSchema.Type.object;
    }
}
