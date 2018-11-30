package com.data.util.schema;

import com.data.util.command.BaseCommand;
import com.data.util.common.Formatter;
import com.data.util.data.generator.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 含义：
 *      () 长度
 *      [] 内容范围
 *      @  生成器
 *      {} 重复：使用相同的配置，共用generator
 *
 *      取消：$索引：使用相同配置，但不共用generator
 *                  设置index，表明从之前的source中选取，这样就不需要后续的
 *
 * integer
 *      ([min,] max / count]), 取值范围：如果选择了count，会预先生成信息并记录在内存中
 *      @ gen ：
 *      {repeat field}
 *
 *      integer[100, 2000, 500] @rand {10}
 *      integer@4
 *
 * string
 *      ([min,] max / count])，长度范围：
 *      [char range]：尚未实现
 *      {repeat field}
 *
 *      string(100)[a-z, 100-200]
 *      string(100) @table {5}
 *      string
 */
public class DataSchema {
    static final Logger log = LoggerFactory.getLogger(DataSchema.class);

    BaseCommand command;

    public enum Type {
        string,
        integer,
        object,
    };

    static public int actualSize(String str) {
        return str.length() + 4;
    }
    static public int actualSize(int data) {
        return 4;
    }
    static public int actualSize(long data) { return 8; }

    static public int stringSize(int len) {
        return len + 4;
    }
    static public int intSize() { return 4; }
    static public int longSize() { return 8; }

    /**
     * schema item
     */
    public class Item {
        public Type type;
        public int index;

        /**
         * integer
         */
        public long min;

        /**
         * integer: max data
         */
        public long max;
        public long count;

        /**
         * string
         */
        public int len;

        public Random gen;

        boolean key;
        public int curr;

        public Item newItem(int index) {
            Item one = new Item();
            one.type = type;
            one.index = index;

            one.min =  min;
            one.max = max;
            one.count = count;

            one.len = len;
            one.gen = gen;

            //one.size = size;
            return one;
        }

        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append(type);

            if (max != 0) {
                sb.append("(");
                if (min != 0) {
                    sb.append(min + ", ");
                }
                sb.append(max);
                if (count != 0) {
                    sb.append("/" + count);
                }
                sb.append(")");
            }

            if (gen != null) {
                sb.append(" @" + gen);
            }
            return sb.toString();
        }

        public boolean isString() {
            return type == Type.string;
        }

        public void set(Random rand) {
            gen = rand;
            gen.set(command);
            gen.set(this);
        }
    }

    public List<Item> list = new ArrayList<>();
    public void set(BaseCommand command) {
        this.command = command;
    }

    public void set(int index, Random random) {
        Item item = list.get(index);
        if (item.gen != null && item.gen.valid) {
            log.info("schema index {} [{}] already have generator", index, item);
            System.exit(-1);

        } else {
            item.set(random);
        }
    }

    public void initialize(BaseCommand command, String schemaString) {
        set(command);
        initialize(schemaString);
    }

    public void initialize(String schemaString) {
        list.clear();

        /**
         * 将括号外的逗号，都踢换成_; 以便能够在()中使用逗号
         */
        StringBuilder sb = new StringBuilder();
        boolean brackets = false;
        for (int i = 0; i < schemaString.length(); i++) {
            char b = schemaString.charAt(i);
            if (b == '(') {
                brackets = true;
            } else if (b == ')') {
                brackets = false;
            }
            if (b == ',' && !brackets) {
                b = '_';
            }
            sb.append(b);
        }
        schemaString = sb.toString();

        String[] itemList = schemaString.split("[_]");
        for (int i = 0; i < itemList.length; i++) {
            String value = itemList[i].trim();
            if (value.isEmpty()) {
                continue;
            } else {
                parse(value.toLowerCase());
            }
        }
    }

    public void dump() {
        log.info("{}", this);
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("schema:\n");

        for (Item item : list) {
            sb.append(String.format("<%-2d  %s\n", item.index, item));
        }
        return sb.toString();
    }

    protected void dump(Matcher match) {
        log.info("group: {}", match.group());

        for (int i = 1; i <= match.groupCount(); i++) {
            log.info("\t\t {} - {}", i, match.group(i));
        }
    }

    public void parse(String line) {
        log.debug("parse: {}", line);
        Item item = new Item();

        String typePartten = "^\\w+";
        Pattern pattern = Pattern.compile(typePartten);
        Matcher match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(0) != null) {
                item.type = Type.valueOf(match.group(0));
            }
        }

        /**
         * 解析range (min, max, count)
         *      integer(56)
         *      String(11, 56)
         *      integer(11, 56 / 29)
         *      integer( 11 , 56 / 29 )
         */
        String rangePartten = "\\((\\W*(\\d+)\\W*,\\W*)?(\\d+)(\\W*/\\W*(\\w+))?\\W*\\)";
        pattern = Pattern.compile(rangePartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(2) != null) {
                item.min = Formatter.parseLong(match.group(2));
            }
            if (match.group(3) != null) {
                item.max = Formatter.parseLong(match.group(3));
            }

            if (match.group(5) != null) {
                item.count = Formatter.parseLong(match.group(5));
            }
        }

        /**
         * 解析generator:
         *      string @fix
         *      string @table
         *      string @numeric
         */
        Random rand = null;
        String genPartten = "@\\W*(\\w+)\\W*";
        pattern = Pattern.compile(genPartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(1) != null) {
                rand = Random.newRandom(match.group(1));
            }
        }
        if (rand == null) {
            rand = Random.defaultRandom(item, command);
        }

        /**
         * 解析{repeat}
         */
        int repeat = 1;
        String repeatPartten = "\\{\\W*(\\d+)\\W*\\}";
        pattern = Pattern.compile(repeatPartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(1) != null) {
                repeat = Integer.valueOf(match.group(1));
            }
        }

        /**
         * $index, not use now
         */
        int indexPointer = -1;
        String indexPartten = "\\$\\W*(\\w+)\\W*";
        pattern = Pattern.compile(indexPartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(1) != null) {
                indexPointer = Integer.valueOf(match.group(1));
                log.info("not support index now, {}", line);
                System.exit(-1);
            }
        }

        invalid(line, repeat, indexPointer, item);
        item.set(rand);

        if (indexPointer >= 0) {
            item.set(list.get(indexPointer).gen);
        }

        for (int i = 0; i < repeat; i++) {
            Item curr = item.newItem(list.size());
            list.add(curr);
        }
    }

    protected void invalid(String line, int repeat, int indexPointer, Item item) {

        if (item.type == Type.integer) {
            if (item.count > item.max - item.min) {
                log.info("parse schema [{}], item count {} exceed [{}, {}]", line, item.count, item.min, item.max);
                System.exit(-1);
            }

            //if (!"numeric".equals(item.gen.toString())) {
            //    log.info("parse schema [{}], integer gen can't be set as {}, only support numeric", line, item.gen);
            //    System.exit(-1);
            //}

        } else if (item.type == Type.string) {
            item.len = (int)item.max;

            //if ("numeric".equals(item.gen.toString())) {
            //    log.info("parse schema [{}], string gen set as {}, only support numeric", line, equals(item.gen));
            //    System.exit(-1);
            //}

            if (item.min != 0) {
                log.info("parse schema [{}], string can't set min", line);
                System.exit(-1);
            }
        }

        if (indexPointer != -1) {
            if (item.min != 0 || item.count != 0) {
                log.info("parse schema [{}], string type not support set max", line);
                System.exit(-1);
            }

            if (indexPointer >= list.size()) {
                log.info("parse schema [{}], indexPointer exceed list size {}", line, list.size());
                System.exit(-1);
            }
        }
    }

    /**
     * reduce schema count if not needed
     */
    public void limit(int count) {
        while (list.size() > count) {
            list.remove(list.size() - 1);
        }
    }

    /**
     * integer,	 String(20)
     * integer(56),	 String(20)
     */
    public static void main(String[] args) {
        DataSchema schema = new DataSchema();
        BaseCommand command = new BaseCommand();
        command.initialize("".split(""));
        schema.set(command);

        schema.initialize("integer(56, 70),\t String[20]{5} @fix ");
        schema.initialize("String(20){5} @fix ");

        /**
         * invalid
         */
        schema.initialize("integer(56, 70), String(20)$0, $0");
        //schema.initialize("integer(100, 200, 5000) ");        // count > max - min
        //schema.initialize("integer(100) @fix ");              // gen
        //schema.initialize("string(100) @numeric ");           // gen
        //schema.initialize("string(100) @111 ");               // gen
        //schema.initialize("String(20, 10){5} @fix ");         // String不能设置 (min, max)，只有max
        //schema.initialize("integer(56, 70), String(20)$2 ");    // index 超过 list size
    }
}
