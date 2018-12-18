package com.data.util.data.generator;

import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.schema.DataSchema;
import com.data.util.test.ThreadTest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * http://www.importnew.com/12460.html
 */
public class Random {
    static final Logger log = LoggerFactory.getLogger(Random.class);
    static final String KeyString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    static final ThreadLocal<java.util.Random> rand = new ThreadLocal<>();

    /**
     * 标记为invalid时，表明 generator 是需要重置的，不需要进行检查了
     */
    protected BaseCommand command;
    public boolean valid = true;
    long threadIndex = 0;

    /**
     * 多个schema共用generator时，防止多次设置seed
     */
    long recordSeed = 0;

    /**
     * 缓存object作为数据集合，后续不需要再重新生成
     */
    List<Object> objectList;

    public static void regist(BaseCommand command) {
        command.regist("gen", new Option());
    }

    public static class Option extends BaseOption {
        protected void initialize() {
            addOption("seed",  "random seed",0);

            addOption("integer.gen",  "integer generator","numeric");
            addOption("integer.min",  "integer default min value", 0);
            addOption("integer.max",  "integer defautl max value",0);
            addOption("string.gen",  "string generator","random");
        }
    }

    public static Random newRandom(String name) {
        if (name.length() < 3) {
            log.info("create new random, but name [{}] too short", name);
            System.exit(-1);
        }

        name = name.toLowerCase();
        if ("random".startsWith(name)) {
            return new Random();

        } else if ("fixed".startsWith(name)) {
            return new Fixed();

        } else if ("sequence".startsWith(name)) {
            return new Sequence();

        } else if ("table".startsWith(name)) {
            return new Table();

        } else if ("uuid".startsWith(name)) {
            return new UUID();

        } else if ("numeric".startsWith(name)) {
            return new Numeric();

        } else if ("null".startsWith(name)) {
            return new Invalid();

        } else {
            log.info("unknown generator: {}, valid: numeric, random, fixed, sequence, table, uuid", name);
            System.exit(-1);
            return null;
        }
    }

    public static Random defaultRandom(DataSchema.Item item, BaseCommand command) {
        if (item.type == DataSchema.Type.integer) {
            return newRandom(command.get("gen.integer.gen"));

        } else if (item.type == DataSchema.Type.string) {
            return newRandom(command.get("gen.string.gen"));

        } else if (item.type == DataSchema.Type.object) {
            return newRandom("null");
        }
        return null;
    }

    final public void set(BaseCommand command) {
        this.command = command;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     *
     * item 注册时进行检查，从item获取信息完善自身配置
     *      进行相关初始化工作
     */
    public void set(DataSchema.Item item) {
        check("integer, string", item);
    }

    /**
     * 作为初始化时提供的工具函数
     */
    protected void check(String support, DataSchema.Item item) {
        if (support.indexOf(item.type.toString()) == -1) {
            log.info("generator [{}] not support schema type [{}], item: {}", this, item.type, item);
            System.exit(-1);
        }
    }

	public void reset() {
    }
	
    /**
     * 使用之前，将需要耗时的大量初始化放在这里
     */
    public void prepare(DataSchema.Item item) {
        if (item.count != 0) {
            if (objectList == null) {

                List<Object> list = new ArrayList<>();
                updateSeed(item.index * 101);
                /**
                 * 后续仍然会在 threadPrepare 根据 thread index 设置 seed
                 */
                //recordSeed = 0;

                log.info("start prepare data set, for schema: {}", item);
                for (int i = 0; i < item.count; i++) {
                    list.add(get(item));

                    if (i % 1000000 == 0 && i > 0) {
                        log.info("\t  ---- prepare: {} w", i/10000);
                    }
                }
                objectList = list;

            } else {
                log.debug("already set, maybe dump item");
            }
        }
    }

    /**
     * every thread command different seed
     */
    public void threadPrepare(int index) {
        threadIndex = index;
        updateSeed(index);
    }

    public void updateSeed(int index) {
        long seed = command.getLong("gen.seed");

        /**
         * recordSeed 确保只设置一次
         */
        if (seed != 0) {
            recordSeed = seed + index;
            getRandom().setSeed(recordSeed);
        }
    }

    /**
     * 每次访问已经cache的object，可以进行一些更新
     */
    protected void cacheUpdate(Object object) {}

    public String toString() {
        return this.getClass().getSimpleName().toLowerCase();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    protected java.util.Random getRandom() {
        /**
         * 此方式速度最快，但是无法设置 seed
         */
        if (recordSeed == 0) {
            return ThreadLocalRandom.current();

        } else {
            java.util.Random random = rand.get();
            if (random == null) {
                rand.set(new java.util.Random());
                random = rand.get();
            }
            return random;
        }
    }

    final public Object get(DataSchema.Item item) {
        Object object = null;

        if (objectList != null) {
            object = objectList.get(getIndex(objectList.size()));
            cacheUpdate(object);
            return object;
        }

        switch (item.type) {
            case string: {
                object = getString(item.len);
                item.curr = DataSchema.stringSize((item.len));
            } break;

            case integer: {
                object = getLong();
                item.curr = item.len != 0 ? item.len : DataSchema.longSize();
            } break;

            case object: {
                object = getObject(item);
                item.curr = item.len;
            } break;

            default:
                log.error("unknown type: {}", item.type);
                System.exit(-1);
                break;
        }
        return object;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public String getString(int length) {
        final int size = KeyString.length();
        java.util.Random random = getRandom();

        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < length; i++) {

            int pos = random.nextInt() % size;
            sb.append(KeyString.charAt(pos < 0 ? size + pos : pos));
        }
        return sb.toString();
    }

    public Long getLong() {
        return getRandom().nextLong();
    }

    public Object getObject(DataSchema.Item item) { return null; }
    
    public char getChar() {
        final int size = KeyString.length();
        int pos = getRandom().nextInt() % size;
        return KeyString.charAt(Math.abs(pos));
    }


    public int getIndex(int max) {
        return Math.abs(getRandom().nextInt() % max);
    }

    public int getIndex(int min, int max) {
        return Math.abs(getRandom().nextInt() % (max - min)) + min;
    }

    /**
     * performance test
     */
    public static void main(String[] args) {

        java.util.Random random = new java.util.Random();
        class Worker extends ThreadTest.TThread {

            java.util.Random random;

            public ThreadTest.TThread newThread() {
                return new Worker();
            }

            public void initialize(Object...args) {
                this.random = (java.util.Random) args[0];
            }

            ///////////////////////////////////////////////////////////////////////////////
            protected java.util.Random getRandom() {
                return random;
            }

            @Override
            public void run() {
                for (long i = 0; i < total; i++) {
                    long data = getRandom().nextLong();
                    log.debug("get {}", data);
                    count++;
                }
            }

            public void output() {
                //log.info("thread {}, range: {} ", index, range);
            }
        }

        long total = 10000000L;
        int  thread = 100;

        ThreadTest test = new ThreadTest();
        test.start(new Worker(),thread, total, random, "normal");
        test.dump();

        /////////////////////////////////////////////////////////////////////////////////////////
        class LocalVar extends Worker {
            final ThreadLocal<java.util.Random> local_random = new ThreadLocal<>();

            public ThreadTest.TThread newThread() {
                return new LocalVar();
            }

            protected java.util.Random getRandom() {
                java.util.Random random = local_random.get();
                if (random == null) {
                    local_random.set(new java.util.Random());
                    random = local_random.get();
                    random.setSeed(index);
                }
                return random;
            }
        }
        test.start(new LocalVar(),thread, total, random, "local variable");
        test.dump();

        /////////////////////////////////////////////////////////////////////////////////////////
        class LocalRandom extends Worker {
            final ThreadLocal<java.util.Random> local_random = new ThreadLocal<>();

            public ThreadTest.TThread newThread() {
                return new LocalRandom();
            }

            protected java.util.Random getRandom() {
                return ThreadLocalRandom.current();
            }
        }
        test.start(new LocalRandom(),thread, total, random, "local random");
        test.dump();
    }
}
