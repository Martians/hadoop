package com.data.util.generator;
import com.data.util.command.BaseCommand;
import com.data.util.schema.DataSchema;

public class Fixed extends Random {

    private char[] table_array = null;

    public void set(DataSchema.Item item) {
        check("string", item);
        assert(item.len != 0);

        int len = (item.len + 4096 - 1) / 4096 * 4096;
        if (table_array == null || table_array.length < len) {

            table_array = new char[len];

            java.util.Random random = new java.util.Random();
            random.setSeed(System.nanoTime());

            for (int i = 0; i < len; i++) {
                int index = random.nextInt() % KeyString.length();
                table_array[i] = KeyString.charAt(Math.abs(index));
            }
        }
    }

    @Override
    public String getString(int length) {
        return new String(table_array, 0, length);
    }

    public static void main(String[] args) {
        DataSchema schema = new DataSchema();
        DataSchema.Item item = schema.new Item();
        item.len = 20;
        item.type = DataSchema.Type.string;

        Fixed fix = new Fixed();
        fix.set(item);

        for (int i = 0; i < 100; i++) {
            log.info("{}", fix.getString(10));
        }
    }
}
