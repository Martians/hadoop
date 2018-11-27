package com.data.util.schema;

import com.data.util.data.generator.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 含义：
 *      () 长度
 *      [] 内容范围
 *      {} 重复
 *      @  生成器
 *      $  索引
 *
 * integer
 *      ([min,] max [, count]), 如果选择了count，会预先生成信息并记录在内存中
 *      @ gen ：
 *      {repeat field}
 *      $index：设置index，表明从之前的source中选取，这样就不需要后续的
 *
 *      integer[100, 2000, 500] @rand {10}
 *      integer@4
 *
 * string
 *      ([min,] max [,std])
 *      [char range]：尚未实现
 *      {repeat field}
 *      $index
 *
 *      string(100)[a-z, 100-200]
 *      string(100) @table {5}
 *      string
 */
public class DataSchema {
    static final Logger log = LoggerFactory.getLogger(DataSchema.class);

    public enum Type {
        string,
        integer,
    };

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
        public long max;
        public long count;

        /**
         * string
         */
        public int size;

        Random generator;

        public Item newItem(int index) {
            Item one = new Item();
            one.type = type;
            one.index = index;

            one.min =  min;
            one.max = max;
            one.generator = generator;

            one.size = size;
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
                    sb.append(count);
                }
                sb.append(")");
            }

            if (size != 0) {
                sb.append("(" + size + ")");
            }

            if (generator != null) {
                sb.append(" @" + generator);
            }
            return sb.toString();
        }
    }

    public List<Item> list = new ArrayList<>();

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
        log.info("{}", this);
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("schema:\n");

        for (Item item : list) {
            sb.append(String.format("<%d \t%s\n", item.index, item));
        }
        return sb.toString();
    }

    protected void dump(Matcher match) {
        if (match.find()) {
            log.info("group: {}", match.group());

            for (int i = 1; i <= match.groupCount(); i++) {
                log.info("\t\t {} - {}", i, match.group(i));
            }
        }
    }

    public void parse(String line) {
        log.info("parse: {}", line);
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
         * 解析range ()
         *  integer: (min, max, count)
         *  string:  (max)
         *
         *      integer(56)
         *      String(11, 56)
         *      integer(11, 56, 29)
         *      integer( 11 ,56 , 29 )
         */
        String rangePartten = "\\((\\W*(\\d+)\\W*,\\W*)?(\\d+)(\\W*,\\W*(\\d+)\\W*)?\\)";
        pattern = Pattern.compile(rangePartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(2) != null) {
                item.min = Integer.valueOf(match.group(2));
            }
            if (match.group(3) != null) {
                item.max = Integer.valueOf(match.group(3));
            }

            if (match.group(5) != null) {
                item.count = Integer.valueOf(match.group(5));
            }
        }

        /**
         * 解析generator:
         *      string @fix
         *      string @table
         *      string @numeric
         */
        String genPartten = "@\\W*(\\w+)\\W*";
        pattern = Pattern.compile(genPartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(1) != null) {
                item.generator = Random.newRandom(match.group(1));
            }
        }
        if (item.generator == null) {
            item.generator = Random.newRandom(item.type == Type.integer ? "numeric" : "random");
        }

        /**
         * 解析repeat #
         *
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

        int indexPointer = -1;
        String indexPartten = "\\$\\W*(\\w+)\\W*";
        pattern = Pattern.compile(indexPartten);
        match = pattern.matcher(line);
        if (match.find()) {
            if (match.group(1) != null) {
                indexPointer = Integer.valueOf(match.group(1));
            }
        }

        invalid(line, repeat, indexPointer, item);

        if (indexPointer >= 0) {
            item.generator = list.get(indexPointer).generator;
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

            if (!"numeric".equals(item.generator.toString())) {
                log.info("parse schema [{}], integer generator can't be set as {}, only support numeric", line, item.generator);
                System.exit(-1);
            }

        } else {
            if ("numeric".equals(item.generator.toString())) {
                log.info("parse schema [{}], string generator set as {}, only support numeric", line, equals(item.generator));
                System.exit(-1);
            }

            if (item.min != 0 || item.count != 0) {
                log.info("parse schema [{}], sring can't set min and count", line);
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
     * integer,	 String(20)
     * integer(56),	 String(20)
     */
    public static void main(String[] args) {
        DataSchema schema = new DataSchema();
        schema.initialize("integer(56, 70),\t String[20]{5} @fix ");
        schema.initialize("String(20){5} @fix ");
        schema.initialize("integer(56, 70), String(20)$0, $0");

        /**
         * invalid
         */
        //schema.initialize("integer(100, 200, 5000) ");        // count > max - min
        //schema.initialize("integer(100) @fix ");              // generator
        //schema.initialize("string(100) @numeric ");           // generator
        //schema.initialize("string(100) @111 ");               // generator
        //schema.initialize("String(20, 10){5} @fix ");         // String不能设置 (min, max)，只有max
        //schema.initialize("integer(56, 70), String(20)$2 ");    // index 超过 list size
    }
}
