package com.data.util.data.generator;
import com.data.base.Command;
import com.data.util.schema.ColumnSchema;

public class Fixed extends Random {

    private char[] table_array = null;

    public void set(Command command) {
        super.set(command);

        int len = (command.schema.maxField() + 4096 - 1) / 4096 * 4096;
        table_array = new char[len];

        java.util.Random random = new java.util.Random();
        random.setSeed(System.nanoTime());

        for (int i = 0; i < len; i++) {
            int index = random.nextInt() % KeyString.length();
            table_array[i] = KeyString.charAt(Math.abs(index));
        }
    }

    public Object get(ColumnSchema.Item item) {
        return new String(table_array, 0, item.size);
    }

    @Override
    public String getString(int length) {
        return new String(table_array, 0, length);
    }
}
