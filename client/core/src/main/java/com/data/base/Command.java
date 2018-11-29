package com.data.base;

import com.data.bind.ClientOption;
import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.common.Formatter;
import com.data.util.generator.Random;
import com.data.util.schema.DataSchema;
import com.data.util.source.DataSource;
import com.data.util.source.InputSource;
import com.data.util.source.MemCache;
import com.data.util.source.ScanSource;
import com.data.util.monitor.MetricTracker;
import com.data.util.sys.ExtClassPathLoader;
import com.data.bind.AppHandler;
import java.net.InetAddress;
import java.util.*;


import static com.data.base.Command.Type.read;
import static com.data.base.Command.Type.scan;

public class Command extends BaseCommand {

    public static enum Type {
        write,
        read,
        scan,
        load,
        generate,
        end,
    };

    /**
     * 外部访问
     */
    public DataSource source;
    public Type type;
    public DataSchema schema = new DataSchema();

    public class WorkParam {
        public int   fetch = getInt("work.fetch");
    }
    public WorkParam workp;

    public class TableParam {
        public boolean dump_select = getBool("table.dump_select");
        public long read_empty = getLong("table.read_empty");
    }
    public TableParam table;

    /**
     * 内部状态
     */
    boolean isTesting = false;
    List<Type> stepList = new ArrayList<>();
    private Class<?> appHandlerFactory;

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
        addParser("",       new ClientOption.Global());
        addParser("work",   new ClientOption.Workload());
        addParser("table",  new ClientOption.Table());

        DataSource.regist(this);
        Random.regist(this);

        validBind = "kafka, cassandra, hbase, redis, create";
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

    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    public String dumpLoad() {
        List<DataSchema.Item> list = schema.list;
        assert(list.size() >= 2);

        return String.format("type: [%s] gen <%s %s>, clear: %s",
                type, list.get(0).gen, list.get(1).gen, get("clear"));
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
    }

    void checkParam() {
        if (containStep(Type.load) || containStep(Type.generate)) {
            if (!exist("gen.data_path")) {
                log.info("generate data, but not updateFromCommandLine path, updateFromCommandLine default");
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
        return type.equals(read) || type.equals(scan);
    }

    public boolean emptyForbiden() {
        if (MetricTracker.incData(0) >= table.read_empty) {
            //System.exit(-1);
            log.info("read empty exceed: {}, thread exit", MetricTracker.getData(0));
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

        fixSize("gen.output.file_size");

    }

    public void fixSize(String key) {

        Long data = Formatter.parseSize(get(key));
        if (data < 0) {
            data = Long.MAX_VALUE;
        }
        if (data != null) {
            set(key, data.toString());

        } else {
            log.info("fix size, but failed: {}", get(key));
            System.exit(-1);
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

            param.thread = getInt("work.thread");
            if (type == Type.read && exist("gen.data_path")) {
                int read_thread = getInt("work.read_thread");
                if (read_thread != 0) {
                    param.thread = read_thread;
                    log.info("change next step. read step use thread {}", param.thread);
                }
            }

        }
        return type != null;
    }

    public boolean containStep(Type type) {
        return stepList.indexOf(type) != -1;
    }

    /**
     * 重置消耗性 param
     */
    public void resetStep() {
        table.read_empty = getLong("table.read_empty");
    }

    private void parseHandler(String bind) {
        appHandlerFactory = parseClass(bind,"Handler", AppHandler.class, false);

        BaseOption option = createOptionParser(bind);
        addParser(bind, option);
    }

    Class<?> parseClass(String bind, String suffix, Class<?> clazz, Boolean retry) {
        String name = "com.data.bind." + bind + suffix;
        Class<?> factory = null;

        try {
                factory = Class.forName(name).asSubclass(clazz);
            /**
             *  方法2）只能找到单一类，而不是整个jar
                 URL url = new URL("file:hbase-0.0.1-SNAPSHOT.jar");
                        URLClassLoader loader = new URLClassLoader(new URL[]{url},
                 Thread.currentThread().getContextClassLoader());
                 factory = loader.loadClass(name).asSubclass(clazz);
             */

        } catch (ClassNotFoundException e) {
            if (retry) {
                log.error("parse class {} failed", name);
                System.exit(-1);

            } else {
                /** 启动动态加载
                 * IDE debug模式
                 *      1. 方式1：执行 mvn package，各个库生成 jar 包；
                 *              当前路径是工程根目录，从根目录下搜索jar包位置
                 *              后来maven将bind lib的生成位置移动到 main/target/bind 下
                 *
                 *      2. 方式2：将 bind 库加入到 dependency 中去，不需要动态加载；此方式也可以找到符号表；但是每次需要执行 compile
                 *
                 * 正常模式下
                 *      1. 导入lib路径，包括lib下的子目录；可以给每个礼拜建一个自己的路径
                 *
                 * Todo:
                 *      ExtClassPathLoader 增加对 class file 的 load，而不仅仅是 jar
                 **/
                ExtClassPathLoader.loadClasspath("bind/" + bind.toLowerCase() + "/target");
                ExtClassPathLoader.loadClasspath("main/target/bind/" + bind.toLowerCase());

                ExtClassPathLoader.loadClasspath("lib");
                return parseClass(bind, suffix, clazz,true);
            }
        }
        return factory;
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
        Class<?> factory = parseClass(bind, "Handler$BaseOption", BaseOption.class, false);

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

    DataSource createGenerator() {
        DataSource source = null;

        switch (type) {
            case read:
                break;
            case write:
            case generate: source = new DataSource();
                break;

            case load:  source = new InputSource();
                break;
            case scan:  source = new ScanSource();
                break;
            default:
                log.info("err type: {}", type);
                System.exit(-1);
                break;
        }

        if (source == null) {
            if (exist("gen.data_path")) {
                source = new InputSource();
            } else {
                source = new DataSource();
            }
        }

        if (source instanceof InputSource) {
        }

        source.initialize(this, schema, dataPath());
        return source;
    }

    public void lastFixed() {
        /**
         * use random read mode, will not ignore any empty updateFromCommandLine
         */
        if (type == Type.read && !exist("gen.data_path")) {
            table.read_empty = 0;
        }
    }
}

