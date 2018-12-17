package com.data.base;

import com.data.bind.ClientOption;
import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.data.generator.Random;
import com.data.util.schema.DataSchema;
import com.data.util.data.source.DataSource;
import com.data.util.data.source.InputSource;
import com.data.util.data.source.ScanSource;
import com.data.util.monitor.MetricTracker;
import com.data.bind.AppHandler;
import com.google.common.util.concurrent.RateLimiter;

import java.net.InetAddress;
import java.util.*;


import static com.data.base.Command.Type.*;

public class Command extends BaseCommand {

    public static enum Type {

        /** 内存生成数据，写入到系统 */
        write,
        /** 文件读取数据，写入到系统 */
        load,
        /** 内存生成数据，写入到文件 */
        generate,

        /** 内存生成数据，从系统读取 */
        read,
        /** 文件读取数据，从系统读取 */
        fetch,
        /** 从系统读取所有数据 */
        scan,
        end,
    };

    /**
     * 外部访问
     */
    public DataSource source;
    public Type type;
    public DataSchema schema = new DataSchema();

    public class WorkParam {
        public int   fetch = moveInt("work.fetch");
        public int throttle = moveInt("work.throttle");
    }
    public WorkParam workp;

    public class TableParam {
        public boolean read_dump = getBool("table.read_dump");
        public long read_empty = getLong("table.read_empty");
    }
    public TableParam table;

    /**
     * 内部状态
     */
    boolean isTesting = false;
    List<Type> stepList = new ArrayList<>();
    private Class<?> appHandlerFactory;

    public RateLimiter rate;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public Command() {}
    public Command(String[] args, boolean test) {
        isTesting = test;

        /**
         * 不允许有未注册的参数
         */
        allowUnregist(false);

        initialize(args);
    }

    @Override
    protected void registParser() {
        regist("",       new ClientOption.Global());
        regist("work",   new ClientOption.Workload());
        regist("table",  new ClientOption.Table());

        regist(DataSource.class, Random.class);

        registBind();
    }

    protected void registBind() {
        //File file = new File("bind");
        //if (file.exists()) {
        //    for (File curr : file.listFiles()) {
        //        if (curr.isDirectory()) {
        //        }
        //    }
        //}
        validBind = "cassandra, hbase, ignite, kafka, redis, ivylite";
    }

    protected void parseDynamic(String[] args) {
        if (isTesting) {
            log.info("is testing now, ignore bind load");

        } else {
            /**
             * 将当前需要的 BaseOption 中的选项，统一合成一个
             *      根据 bind 显示出不同的 option
             * 注意：只影响显示的 option 的help，不影响 dump_param
             */
            String bind = getBind(args);
            setCurrent(bind);
            parseHandler(bind);
        }
    }

    /**
     * 判断bind的类型
     */
    private String getBind(String[] args) {
        /**
         * 从当前已经解析过的配置文件中
         */
        String bind = get("bind");

        /**
         * 从当前命令行中读取
         */
        for (int index = 0; index < args.length; index++) {
            if (args[index].matches("-bind")) {
                if (index == args.length - 1) {
                    log.error("loop bind option, but no param");
                    System.exit(-1);

                } else {
                    bind = args[index + 1];
                }
            }
        }
        return bind;
    }

    protected void validate() {
        super.validate();

        table = new TableParam();
        workp = new WorkParam();

        resolveParam();

        checkParam();

        fixingParam();
    }

    /**
     * http://ifeve.com/guava-ratelimiter/
     */
    public int speedLimit(int limit) {
        if (workp.throttle != 0 && limit > 0) {
            boolean hit = false;
            for (int i = 0; i < 2; i++) {
                if (rate.tryAcquire(limit)) {
                    hit = true;
                    break;
                }
                if ((limit /= 2) == 0) {
                    break;
                }
            }

            if (hit == false) {
                rate.acquire();
                limit = 1;
            }
        }
        return limit;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    public String dumpLoad() {
        List<DataSchema.Item> list = schema.list;
        assert(list.size() >= 2);

        return String.format("type: [%s] gen <%s %s>, clear: %s",
                type, list.get(0).gen, list.size() > 1 ? list.get(1).gen : "", get("clear"));
    }

    /**
     * 解析参数的合法性
     */
    void resolveParam() {

        parseAction();

        parseSchema();
    }

    void parseAction() {
        String[] array = get("work.type").split("[\t, ]");
        try {
            for (String data : array) {
                Type type = Type.valueOf(data);
                stepList.add(type);
            }
            //for (Type type : stepList) {
            //    log.info("steps: {}", type);
            //}

        } catch (Exception e) {
            log.info("parse action failed: {}", e);

            StringBuilder sb = new StringBuilder();
            for (Type t : Type.values()) {
                sb.append(t).append(" ");
            }
            log.info("parse mode, [{}] not valid, should be one of [{}]", get("work.type"), sb.toString());
            System.exit(1);
        }
    }

    void parseSchema() {
        schema.set(this);
        schema.initialize(get("table.schema"));
        schema.dump();
    }

    void checkParam() {
        if (containStep(Type.load) || containStep(Type.generate) || containStep(Type.fetch)) {
            if (!exist("gen.data_path")) {
                log.info("generate data, but not command path, command default");
            }
        }
    }

    public String dataPath() {
        if (!exist("gen.data_path")) {
            return "output";

        } else {
            return get("gen.data_path");
        }
    }

    public boolean isRead() {
        return type.equals(read) || type.equals(scan) || type.equals(fetch);
    }

    public boolean isWrite() {
        return type.equals(write) || type.equals(load);
    }

    public boolean emptyForbiden() {
        if (MetricTracker.incLocal(0) >= table.read_empty) {
            //System.exit(-1);
            log.info("read empty exceed: {}, thread exit", MetricTracker.getLocal(0));
            return true;

        } else {
            return false;
        }
    }

    void fixingParam() {

        if (param.batch > 0) {
            workp.fetch = Math.max(workp.fetch, param.batch);
        }

        if (param.thread > 1000) {
            log.error("thread count should lower than 1000");
            System.exit(-1);
        }

        if (getBool("table.keyspace_auto")) {
            String host = getHost();
            set("table.keyspace", host);
        }

        if (workp.throttle > 0) {
            if (workp.fetch * param.thread > param.total) {
                int fetch = Math.max(param.total.intValue() / param.thread, 1);
                log.info("throttle {}, set fetch {} -> {}", workp.throttle, workp.fetch, fetch);
                workp.fetch = fetch;
            }
            rate = RateLimiter.create(workp.throttle);
        }
    }

    static String getHost() {
        try {
            return (InetAddress.getLocalHost()).getHostName();

        } catch (Exception uhe) {
            String host = uhe.getMessage(); // host = "hostname: hostname"
            if (host != null) {
                int colon = host.indexOf(':');
                if (colon > 0) {
                    return host.substring(0, colon);
                }
            }
            return "UnknownHost";
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public int stepCount() {
        return stepList.size();
    }

    public boolean nextStep() {
        if (type != null) {
            type = null;
            stepList.remove(0);
        }
        if (stepList.size() > 0) {
            type = stepList.get(0);

            currStep(type.toString());

            if (isRead()) {
                param.thread = getInt("work.read_thread");
                log.info("change next step. read step use thread {}", param.thread);
            }
        }
        return type != null;
    }

    public boolean containStep(Type type) {
        return stepList.indexOf(type) != -1;
    }

    /**
     * 进入下一个step时进行重置
     */
    public void resetStep() {
        schema.reset();

        table.read_empty = getLong("table.read_empty");
    }

    private void parseHandler(String bind) {
        appHandlerFactory = parseClass("com.data.bind." + bind + "Handler",
                ()-> dynamicLoad(bind), AppHandler.class);

        BaseOption option = createOptionParser(bind);
        regist(bind, option);
    }

    public void dynamicLoad(String bind) {
        if (bind.length() > 0) {
            /**
             *  当前方法，只能导入jar包，不能导入class
             *
             *  方法2）只能找到单一类，而不是整个jar
             *      URL url = new URL("file:hbase-0.0.1-SNAPSHOT.jar");
             *      URLClassLoader loader = new URLClassLoader(new URL[]{url},
             *      Thread.currentThread().getContextClassLoader());
             *      factory = loader.loadClass(name).asSubclass(clazz);
             *
             *  这里的执行，实际是无效的，除非bind对应的目录有jar包存在
             */
            dynamicClassPath("bind/" + bind.toLowerCase() + "/target",
                    "main/target/bind/" + bind.toLowerCase());
        }

        /**
         * runtime
         */
        dynamicClassPath("lib", "bind");
    }

    AppHandler createAppHandler() {

        AppHandler handler = null;
        try {
            handler = (AppHandler)appHandlerFactory.newInstance();

        } catch (InstantiationException e) {
            e.printStackTrace();
            log.error("create app handler error: {}", e);

        } catch (IllegalAccessException e) {
            e.printStackTrace();
            log.error("create app handler error: {}", e);
        }
        return handler;
    }

    BaseOption createOptionParser(String bind) {
        Class<?> factory = parseClass("com.data.bind." + bind + "Handler$Option",
                ()-> dynamicLoad(bind), BaseOption.class);

        try {
            BaseOption option = (BaseOption)factory.newInstance();
            return option;

        } catch (InstantiationException e) {
            e.printStackTrace();
            log.error("create option parser error: {}", e);

        } catch (IllegalAccessException e) {
            e.printStackTrace();
            log.error("create option parser error: {}", e);
        }
        return null;
    }

    private DataSource createSourceConfig() {
        DataSource source = null;

        if (exist("gen.input.source.class")) {
            source = (DataSource) parseInstance(get("gen.input.source.class"),
                    () -> dynamicLoad(""));

            if (exist("gen.input.source.config")) {
                BaseOption option = (BaseOption) parseInstance(get("gen.input.source.class") + "$Option",
                        () -> dynamicLoad(""));
                exctraConfig(option, get("gen.input.source.config"));

                /**
                 * 重新检查参数是否有未注册的
                 */
                onConfigChange(getBool("gen.input.source.strict"), getBool("gen.input.source.dump"));
            }
        }
        return source;
    }

    DataSource createSource() {
        DataSource source = createSourceConfig();
        /**
         * 创建默认 source
         */
        if (source == null) {
            switch (type) {
                case read:
                    source = new DataSource();
                    break;
                case write:
                case generate:
                    source = new DataSource();
                    break;

                case load:
                case fetch:
                    source = new InputSource();
                    break;

                case scan:
                    source = new ScanSource();
                    break;
                default:
                    log.info("err type: {}", type);
                    System.exit(-1);
                    break;
            }
        }

        //if (source == null) {
        //    if (exist("gen.data_path")) {
        //        source = new InputSource();
        //    } else {
        //        source = new DataSource();
        //    }
        //    log.warn("no need add source");
        //    System.exit(-1);
        //}
        source.initialize(this, schema, dataPath());

        if (type == fetch) {
            source.onlyKey(true);
        }
        return source;
    }

    public void lastFixed() {
        /**
         * use random read mode, will not ignore any empty command
         */
        if (isRead()) {
            table.read_empty = 0;
        }
    }
}

