package com.data.util.schema;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ColumnSchema extends DataSchema {
    static final Logger log = LoggerFactory.getLogger(DataSchema.class);

    public String tableTypeName(Type type) {
        switch (type) {
            case string:
                return "TEXT";
            case integer:
                return "BIGINT";
            default:
                log.error("unknown type: {}", type);
                System.exit(-1);
                return "";
        }
    }

    public String tableClumnPrefix(int index) {
        if (index == 0) {
            return "c0";
        } else {
            return "c" + index;
        }
    }

    public String prefixColon(int index, String str) {
        if (index == 0) {
            return str;
        } else {
            return ", " + str;
        }
    }
    
    Integer schemaSize = 0;
    //public int fixedSize() {
    //    if (schemaSize == 0) {
    //        synchronized (schemaSize) {
    //            if (schemaSize == 0) {
    //                for (Item item : list) {
    //                    schemaSize += item.actual();
    //                }
    //            }
    //        }
    //    }
    //    return schemaSize;
    //}





//    static public int getSize(Type type, int size) {
//        return type == Type.string ? size + 4 : 8;
//    }

    public List<Item> list = new ArrayList<>();
    public List<Integer> partitionKey;
    public List<Integer> clustringKey;
    public List<Integer> primaryKey;
    public List<Integer> indexKey;

    public void initialize(String value) {
        String primaryString = "", indexString = "";

        String primaryPartten = "<(\\(.+\\))?(.+)>";
        Pattern pattern = Pattern.compile(primaryPartten);
        Matcher match = pattern.matcher(value);
        if (match.find()) {
            log.trace("primary key: {}", value);
            for (int i = 1; i <= match.groupCount(); i++) {
                log.trace("\t\t {} - {}", i, match.group(i));
            }

            if (match.group(1) != null) {
                partitionKey = parseList(match.group(1));
            }
            if (match.group(2) != null) {
                clustringKey = parseList(match.group(2));
            }
            primaryString = value.substring(match.start(0), match.end(0));
            value = value.substring(0, match.start(0)) +
                    value.substring(match.end(0));

            log.trace("remain value: {} ", value);
        }

        String indexPartten = "(\\{(.+)\\})";
        pattern = Pattern.compile(indexPartten);
        match = pattern.matcher(value);
        if (match.find()) {
            log.trace("index key: {}", value);
            for (int i = 1; i <= match.groupCount(); i++) {
                log.trace("\t\t {} - {}", i, match.group(i));
            }
            indexKey = parseList(match.group(1));

            indexString = value.substring(match.start(0), match.end(0));
            value = value.substring(0, match.start(0)) +
                    value.substring(match.end(0));

            log.trace("remain value: {} ", value);
        }

        fixPrimaryKey();

        log.debug("PrimaryKey: {} - p: {}, c: {}", primaryString, partitionKey, clustringKey);
        log.debug("IndexKey: {} - {}", indexString, indexKey);
        //for (Item item : list) {
        //    log.debug("{} - type: {}, size: {} ", item.index, item.type, item.size);
        //}
    }

    List<Integer> parseList(String value) {
        String primaryPartten = "(\\d+)(-(\\d+))?";
        Pattern pattern = Pattern.compile(primaryPartten);
        Matcher match = pattern.matcher(value);
        List<Integer> list = new ArrayList<>();

        while (match.find()) {
            log.trace("parse key: {}", value);
            for (int i = 1; i <= match.groupCount(); i++) {
                log.trace("\t\t {} - {}", i, match.group(i));
            }
            if (match.group(3) == null) {
                list.add(Integer.parseInt(match.group(1)));

            } else {
                int start = Integer.parseInt(match.group(1));
                int end = Integer.parseInt(match.group(3));
                for (int i = start; i < end + 1; i++) {
                    list.add(i);
                }
            }
        }
        return list;
    }

    public void updateKeySchema(String type) {
        Item item = list.get(0);

        if (type.equals("uuid")) {
            item.type = Type.string;
            item.size = 36;

        } else if (type.equals("seq")) {
            item.type = Type.integer;
            item.size = 8;
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    void fixPrimaryKey() {
        primaryKey = new ArrayList<Integer>();

        if (clustringKey == null) {
            clustringKey = new ArrayList<>();
        }

        /** 如果没有设置，默认将第一列作为 partitionkey */
        if (partitionKey == null) {
            partitionKey = new ArrayList<>();
            if (clustringKey.size() == 0) {
                partitionKey.add(0);

            } else {
                partitionKey.add(clustringKey.get(0));
                clustringKey.remove(0);
            }
        }
        primaryKey.addAll(partitionKey);
        primaryKey.addAll(clustringKey);

        for (Integer p : primaryKey) {
            list.get(p).key = true;
        }

        Collections.sort(primaryKey);

        //log.info("p: {}, c: {}", partitionKey, clustringKey);
        //System.exit(0);
    }

    public String primaryKeyPart() {
        StringBuilder sb = new StringBuilder();

        int index = 0;
        if (partitionKey.size() == 1 && clustringKey.size() == 0) {
            sb.append(prefixColon(index, tableClumnPrefix(partitionKey.get(0))));

        } else {
            sb.append("(");
            for (Integer p : partitionKey) {
                sb.append(prefixColon(index, tableClumnPrefix(p)));
                index++;
            }
            sb.append(")");

            for (Integer p : clustringKey) {
                sb.append(prefixColon(index, tableClumnPrefix(p)));
                index++;
            }
        }
        return sb.toString();
    }

    public String tableColumnPart(boolean type) {
        StringBuilder sb = new StringBuilder();

        int index = 0;
        for (Item item : list) {
            sb.append(prefixColon(index, tableClumnPrefix(index)));

            if (type) {
                sb.append(" ").append(tableTypeName(item.type));
            }
            index++;
        }
        return sb.toString();
    }

    public List<String> createIndex(String name) {
        List<String> list = new ArrayList<>();
        if (indexKey != null) {
            for (Integer i : indexKey) {
                list.add(String.format(" create index IF NOT EXISTS on %s (%s);",
                        name, tableClumnPrefix(i)));
            }
        }
        return list;
    }

    public String createTable(String name) {
        return String.format("CREATE TABLE IF NOT EXISTS %s (%s, Primary Key (%s));",
                name, tableColumnPart(true), primaryKeyPart());
    }

    public String insertTable(String name) {
        StringBuilder sb = new StringBuilder();
        sb.append("INSERT INTO ").append(name).append(" (");

        int index = 0;
        for (Item item : list) {
            sb.append(prefixColon(index, tableClumnPrefix(index)));
            index++;
        }

        index = 0;
        sb.append(") VALUES (");
        for (Item item : list) {
            sb.append(prefixColon(index, "?"));
            index++;
        }
        sb.append(");");
        return sb.toString();
    }

    public String selectTable(String name) {
        StringBuilder sb = new StringBuilder();

        int index = 0;
        for (Integer p : partitionKey) {
            if (index > 0) {
                sb.append(" and ");
            }
            sb.append(tableClumnPrefix(p)).append(" = ?");
            index++;
        }

        for (Integer p : clustringKey) {
            if (index > 0) {
                sb.append(" and ");
            }
            sb.append(tableClumnPrefix(p)).append(" = ?");
            index++;
        }

        return String.format("select * from %s where %s",
                name, sb.toString());
    }

    public String scanTable(String name, int limit) {
        StringBuilder sb = new StringBuilder();

        int index = 0;
        for (Integer p : partitionKey) {
            sb.append(prefixColon(index, tableClumnPrefix(p)));
            index++;
        }

        return String.format("select %s, %s from %s where %s >= ? and %s < ? limit %d",
                tableColumnPart(false), tokenColumn(), name, tokenColumn(), tokenColumn(), limit);
        //return String.format("select * from %s where %s >= ? and %s < ? limit %d",
        //        name, tokenColumn(), tokenColumn(), limit);
    }

    public String tokenColumn() {
        StringBuilder sb = new StringBuilder();
        sb.append("token(");

        int index = 0;
        for (Integer p : partitionKey) {
            sb.append(prefixColon(index, tableClumnPrefix(p)));
            index++;
        }

        sb.append(")");
        return sb.toString();
    }

    public static void main(String[] args) {
        /**
         *  schema=integer, String(4)[2]
         *  schema=integer, String(4)[2]<0>
         *  schema=integer, String(4)[2]<(0)>
         *  schema=integer, String(4)[2]<1, 2>
         *  schema=integer, String(4)[2]<(0), 1>
         *  schema=integer, String(4)[2]<(0, 1)>
         */
        DataSchema schema = null;

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<0>");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<(0)>");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<(1, 2)>");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<(0), 1>");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<0, 1>");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<(2), 1, 5>{8-10}");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]<(2, 1), 0, 7-10, 5>{8-10}");

        schema = new DataSchema();
        schema.initialize("integer ,string(2)[10], integer[8]{8-10, 200 }");
//        schema.initialize("integer[8], <1, 5>{8-10}");
    }
}
