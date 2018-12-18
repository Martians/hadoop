package com.data.util.command;

import com.data.util.common.Formatter;
import com.data.util.disk.Disk;
import com.data.util.sys.ExtClassPathLoader;
import com.data.util.sys.Reflect;
import org.apache.commons.cli.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

/**
 * 功能：
 *  1. Option设置前缀：每个option中有自己的prefix，查找时必须带 current.key，这个是不可更改的
 *
 *  2. 查找优先级：
 *      1）配置机制：路径越长优先级越高：全局配置 gen.key_type，将被 kafka.gen.key_type 覆盖掉，同时配置两个之后才会其效果
 *      2）启动机制：command（而不是讨论option） 设置了prefix之后，查询时优先查找带 current.key 的值；找不到时再找找 传入的key本身
 *          注意：command current + option current，如，是 kafka.gen.key_type，而不是 kafka.key_type
 *      3）临时取消：在命令行中为了方便，是不需要输入前缀的
 *
 *  3. valid
 *      1) 修改了配置文件，或者增加了 BaseOption，使用 -strict 参数进行一次检查
 *
 * commandline:
 *      doc: http://commons.apache.org/proper/commons-cli/
 *      api: http://commons.apache.org/proper/commons-cli/javadocs/api-release/index.html
 *
 * yaml:
 *      http://www.mamicode.com/info-detail-2344150.html
 *      https://www.zhihu.com/question/41253282\
 */
public class BaseCommand {
    protected final Logger log = LoggerFactory.getLogger(this.getClass());

    protected final String propConfig = "config.properties";
    protected final String yamlConfig = "config.yaml";
    protected final String specConfig = "specific.yaml";

    /**
     * 需要动态注册的parser
     */
    protected List<BaseOption> parserList = new ArrayList<>();

    /**
     * 保存所有解析后的结果
     */
    protected Properties properties = new Properties();
    protected Properties unregisted = new Properties();
    protected Properties movingkeys = new Properties();

    /**
     * 读取配置时，优先在传入的key前增加 current；找不到时再使用原key
     */
    protected String current = "";

    /**
     * when use strict mode, ignore these prefix
     */
    protected String validBind = "";

    public class ClientParam {
        public Long  total = moveLong("work.total");
        public int   thread = moveInt("work.thread");
        public int   batch = Integer.max(moveInt("work.batch"), 1);
    }
    public ClientParam param;

    class Common extends BaseOption {
        Common() {
            /** 实际上，是否输出help，只取决于命令行参数 */
            addOption("h, help", "help message", false);
            addOption("c,config", "config file");
            addOption("strict", "strict mode, never get unknown param", false);
            addOption("prefix", "command line prefix, 0:cancel, 1:convert [.->_]", true);
            addOption("lib", "extra lib path", "");
            addOption("dump", "check effective config", false);

            addOption("host", "server host", "192.168.10.7");
            addOption("clear", "clear data", false);
        }
    }

    /**
     * 这里自动加了前缀，因为这些option经常使用，所以放在基类中
     */
    class Useful extends BaseOption {
        Useful() {
            /**
             * belong to workload, but used always, so put to base command
             */
            addOption("work.total", "request count", 100000);
            addOption("work.thread",  "thread count", 10);
            addOption("work.batch",  "batch request", 100);

            /**
             * schema
             */
            addOption("table.schema", "table schema", "integer, String(4)[10]");
        }
    }

    /**
     * 用于暴露内部执行状态
     */
    public int step = -1;
    protected String stepString = "";

    public void currStep(String str) {
        step++;
        stepString = str;
    }
    public String currStep() {
        return stepString;
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public BaseCommand() {}
    public BaseCommand(String[] args) {
        initialize(args);
    }

    /**
     * 手动强制设置某个选项
     */
    public void set(String key, Object value) {
        set(key, value, false);
    }

    public void set(String key, Object value, boolean force) {
        if (get(key, false) == null && !force) {
            log.info("command set [{}], but have no value before", key);
            System.exit(-1);
        }
        properties.setProperty(key, value.toString());
    }

    public String get(String key, boolean force) {
        String value = get(properties, key);

        /**
         * 非严格模式，允许读取未注册的选项
         */
        if (value == null && allowUnregist()) {
            value = get(unregisted, key);
        }

        if (value == null) {
            if (force) {
                String output = String.format("\n\tcan't parse option %s, maybe removed or not defined!", key);

                new Exception(output).printStackTrace();
                System.exit(-1);
            } else {
                return null;
            }
        }
        return value;
    }

    public String get(String key) { return get(key, true); }
    public String get(String key, String defaultv) {
        String data = get(key, false);
        return data == null ? defaultv : data;
    }
    public boolean exist(String key) {
        return !get(key).isEmpty();
    }

    public Long getLong(String key) { return Formatter.parseLong(get(key)); }
    public Integer getInt(String key) { return getLong(key).intValue(); }

    /**
     * 注册时，bool 设置为0，或者"false"都可以; 最终会用 Boolean.valueOf 解析
     */
    public boolean getBool(String key) {
        return Boolean.parseBoolean(get(key));
    }
    public <E extends Enum<E>> E getEnum(String key, Class<E> clazz) {
        return Enum.valueOf(clazz, get(key));
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void debug(String key) {
        properties.forEach((k,v) -> {
            if (key.length() == 0 || ((String)k).startsWith(key)) {
                log.info("=============== {} -> {}", k, v);
            }
        });
    }

    public void dump(String display, Map map) {
        StringBuffer sb = new StringBuffer();
        sb.append("\n");

        map = getSort(map);
        for (Object key : map.keySet()) {
            if (key.toString().length() < 20) {
                sb.append(String.format("\t%-20s\t: %s\n", String.format("[%s]", key), map.get(key)));
            } else {
                sb.append(String.format("\t%-25s\t: %s\n", String.format("[%s]", key), map.get(key)));
            }
        }
        log.info("{}{}", display, sb);
    }

    public String dump(boolean full) {
        StringBuffer sb = new StringBuffer();
        sb.append("\n");

        Map map = getSort(properties);
        if (allowUnregist()) {
            map.putAll(unregisted);
        }

        for (Object key : map.keySet()) {
            if (!full && properties.getProperty(current + "." + key) != null) {
                continue;
            }
            if (key.toString().length() < 20) {
                sb.append(String.format("\t%-20s\t: %s\n", String.format("[%s]", key), map.get(key)));
            } else {
                sb.append(String.format("\t%-25s\t: %s\n", String.format("[%s]", key), map.get(key)));
            }
        }
        return sb.toString();
    }

    public String toString() {
        return dump(false);
    }

    /**
     * move option to inner member, should never used by outside through get(), but inner member
     */
    protected Long moveLong(String key) {
        Long data = getLong(key);

        moveKey(key);
        moveKey(current + "." + key);
        return data;
    }

    protected int moveInt(String key) {
        return moveLong(key).intValue();
    }

    protected String moveString(String key) {
        String data = get(key, false);

        moveKey(key);
        moveKey(current + "." + key);
        return data;
    }

    protected void moveKey(String key) {
        if (properties.get(key) != null) {
            movingkeys.put(key, properties.get((key)));
            properties.remove(key);
        }
    }

    protected String getMoving(String key) {
        String data = get(key, false);
        if (data == null) {
            return get(movingkeys, key);
        }
        return data;
    }

    /**
     * 定义lamda的函数式接口原型
     */
    public interface ParamCheck {
        boolean check(String value);
    }

    /**
     * 警告：不支持符合 ParamCheck 的参数设置
     */
    public boolean notSupport(String key, ParamCheck param) {
        return notSupport(key, param, "", false);
    }
    public boolean notSupport(String key, ParamCheck param, String display, boolean exit) {
        if (param.check(getMoving(key))) {
            if (display.length() > 0) {
                log.info("{}", display);

            } else {
                log.info("not support config [{}] set as <{}>, will not effect", key, get(key));
            }

            if (exit) {
                System.exit(-1);
                return false;
            }

            notify("", " to be continued ...");
            return true;

        } else {
            return false;
        }
    }

    /**
     * 提醒：不符合 ParamCheck 的参数设置，可能造成性嫩等影响
     */
    public boolean notice(String key, ParamCheck param, String display) { return notice(key, param, display, false); }
    public boolean notice(String key, ParamCheck param, String display, boolean exit) {
        if (!param.check(getMoving(key))) {
            log.info("notice: [{} = {}], set: {}", key, getMoving(key), display);

            if (exit) {
                System.exit(-1);
                return false;
            }

            notify("", " to be continued ...");
            return true;

        } else {
            return false;
        }
    }

    public void notify(String display, String last) {
        if (display.length() > 0) {
            log.info(display);
        }

        try {
            for (int i = 0; i < 5; i++) {
                System.out.print("==============");
                Thread.sleep(500);
            }
        } catch (InterruptedException e) {
        }
        System.out.println(last);
    }

    /**
     * 建议：给出常用用法
     */
    public void advice(String ... display) {
        StringBuilder sb = new StringBuilder();
        sb.append("advice: ");
        int count = 0;

        for (String str : display) {
            sb.append("[" + str +  "]");
            if (count++ > 0) {
                sb.append(", ");
            }
        }
        log.info("{}", sb.toString());
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    protected void registParser() {}
    protected void parseDynamic(String[] args) {}

    protected void validate() {
        param = new ClientParam();

        /**
         * 加载额外的lib库
         */
        if (exist("lib")) {
            ExtClassPathLoader.loadClasspath(get("lib"));
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void initialize(String[] args) {

        construct();

        parseDefault();

        parseCommand(args);

        validate();
    }

    public void setCurrent(String current) {
        this.current = current.toLowerCase();
    }

    protected void allowUnregist(boolean set) {
        set("strict", set ? "false" : "true", true);
    }

    protected boolean allowUnregist() {
        String value = get(properties, "strict");
        return !(value == null ? false
                : Boolean.parseBoolean(value));
    }

    protected String get(Properties props, String key) {
        String value = props.getProperty(current + "." + key);

        if (value == null) {
            value = props.getProperty(key);
        }
        return value;
    }

    public interface SingleHandler {
        void work();
    }
    public Class<?> parseClass(String name, SingleHandler handler, Class<?> parent) {

        Class<?> factory = parseClass(name);

        if (factory == null && handler != null) {
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
            handler.work();
            factory = parseClass(name);
        }

        if (factory == null) {
            log.error("parse class [{}] failed, make sure that bind and dependency in bind/ or lib/", name);
            System.exit(-1);

        } else if (parent != null) {
            factory = factory.asSubclass(parent);
        }

        return factory;
    }

    public Object parseInstance(String name, SingleHandler handler) {
        Class<?> factory = parseClass(name, handler, null);
        try {
            return factory.newInstance();

        } catch (Exception e) {
            log.warn("create instance of [{}] failed, {}", name, e);
            System.exit(-1);
            return null;
        }
    }

    private Class<?> parseClass(String name) {
        try {
            return Class.forName(name);
        } catch (ClassNotFoundException e) {
            return null;
        }
    }

    public void dynamicClassPath(String ... paths) {
        for (String path : paths) {
            ExtClassPathLoader.loadClasspath(path);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * 将多个配置参数分开存放
     */
    protected void construct() {
        regist("", new Common());
        regist("", new Useful());

        registParser();
    }

    public void regist(Class<?> ... args) {
        for (Class<?> classType : args) {
            Reflect.call(classType, null, true, "regist", (BaseCommand) this);
        }
    }

    public void regist(String prefix, BaseOption option) {
        /** reset option current */
        if (option.getPrefix().length() == 0) {
            option.setPrefix(prefix);
        }

        option.distill(properties, false);
        parserList.add(option);
    }

    /**
     * 命令解析1：从默认配置文件，读取配置，加入到 properties 中
     */
    private void parseDefault() {
        parseConfig(propConfig, false);
        parseConfig(yamlConfig, false);
    }

    protected void parseConfig(String path, boolean force) {
        parseConfig(path, force, "global", "");
    }

    protected void parseConfig(String path, boolean force, String cancelPrefix, String appendPrefix) {
        boolean exist = false;
        boolean resource = false;

        if (Disk.fileExist(path, false)) {
            exist = true;

        } else if (Disk.fileExist(path, true)) {
            exist = true;
            resource = true;
        }

        if (!exist) {
            if (force) {
                log.warn("load config [{}], but file not exist!", path);
                System.exit(-1);
            }

        } else {
            parseFile(path, resource, cancelPrefix, appendPrefix);
        }
    }

    private void parseFile(String file, boolean resource, String cancelPrefix, String appendPrefix) {
        Properties props;

        if (file.endsWith("yaml") || file.endsWith("yml")) {
            ParseYAML parser = new ParseYAML();
            props = parser.initialize(file, resource);

        } else {
            ParseProperty parser = new ParseProperty();
            props = parser.initialize(file, resource);
        }

        if (props == null) {
            System.exit(-1);

        } else {
            //dump("props key", props);
            fixPrefix(props, cancelPrefix, appendPrefix);
        }
    }

    /**
     * 取消配置中的前缀，当前只用于取消global，用于简化处理
     *      1）.properties 中，对global部分的配置，没有使用前缀
     *      2）.yaml中，对global部分的配置，是放在global的对象之下，为了统一需要取消
     */
    protected void fixPrefix(Properties props, String cancel, String append) {
        cancel = cancel + ".";
        append = append.length() > 0 ? append + "." : "";
        List<String> moveList = new ArrayList<>();

        for (String key : props.stringPropertyNames()) {
            String fix = key;

            if (cancel.startsWith("*")) {
                int index = key.indexOf('.');
                if (index != -1) {
                    fix = key.substring(index + 1);
                }

            } else if (key.startsWith(cancel)) {
                fix = key.substring(cancel.length());
            }

            if (append.length() > 0) {
                fix = append + fix;
            }

            /**
             * 已经move的key，不能再次加入
             */
            if (movingkeys.get(fix) != null) {
                moveList.add(key);
            }
            properties.put(fix, props.get(key));
        }

        if (moveList.size() > 0) {
            log.info("");
            log.info("detect moved key, later config not effect:");
            for (String key : moveList) {
                log.info("\t\t[{}] -> {}", key, props.get(key));
            }
            System.exit(-1);
        }
    }

    static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp( "client", options, true);
        System.exit(-1);
    }

    private void parseCommand(String[] args) {
        Options options = new Options();
        parseDynamic(args);

        /**
         * 将所有的 option 组合，到命令行解析器中
         */
        for (BaseOption parser : parserList) {
            parser.distill(options, getBool("prefix"));
        }
        unregistOption(options);

        CommandLineParser parser = new DefaultParser();
        CommandLine parsed = null;

        try {
            parsed = parser.parse(options, args);

        } catch (ParseException e) {
            log.info("parse error, {}", e);
            printHelp(options);
        }

        /**
         * 注意：是否输出help，只检查命令行
         */
        if (parsed.hasOption('h')) {
            printHelp(options);
        }

        /**
         * 命令传入的configFile
         */
        if (parsed.hasOption("config")) {
            parseConfig(parsed.getOptionValue("config"), true);

        /**
         * 查找是否存在可以优先级最高的配置文件, specific.yaml
         *      只用于特殊用途：在target目录下调试，mvn package之后，配置文件会被默认的 config.yaml 覆盖
         *                     在此情况下，可以使用此配置
         */
        } else {
            parseConfig(specConfig, false);
        }

        /**
         * 命令行解析的命令，优先级最高
         */
        Properties props = new Properties();
        for (BaseOption option : parserList) {
            option.updateFromCommandLine(parsed, props, current, getBool("prefix"));
        }
        properties.putAll(props);

        /**
         * 重构代码前，先执行的是 unregistCheck()
         */
        unregistParsed(parsed);

        onConfigChange(true, getBool("dump"));
    }

    protected void onConfigChange(boolean strictCheck, boolean dump) {
        /**
         * 重新检查参数是否有未注册的
         */
        if (strictCheck) {
            unregistCheck();
        }

        if (dump) {
            log.info("dump config:");
            log.info(dump(false));
            System.exit(-1);
        }
    }

    protected void unregistOption(Options commandLine) {

        /**
         * 将从当前配置中已经读取了的未注册配置，也加入到option中来
         *      此时只读取了默认配置文件 config.properties、config.yaml
         *
         * 注意：不能添加带 . 的选项
         */
        if (allowUnregist()) {
            unregistCheck();

            for(String key: unregisted.stringPropertyNames()) {
                String value = (String)unregisted.get(key);

                if (key.contains(".")) {
                    log.debug("option  [{} :: {} :: {}] contain ., ignore from commandline", key, "", value);
                    continue;
                }
                commandLine.addOption(key, null, true, "default: " + value);
            }
        }
    }

    protected void unregistCheck() {
        /**
         * 对其他几个，当前没有 load 的 bind 类型，忽略其相关参数
         *      先将需要被忽略的前缀，全部收集起来
         */
        String[] array = validBind.toLowerCase().split("[,\t]");
        List<String> ignore = new ArrayList<>();
        for (String bind : array) {
            bind = bind.trim();
            if (bind.equals(current)) {
                continue;
            }
            ignore.add(bind + ".");
        }

        /**
         * 将已经获取的参数分类，注册、未注册
         */
        Map<String, String> regist = new HashMap<>();
        for (BaseOption option : parserList) {
            option.distill(regist);
        }

        for (String key : properties.stringPropertyNames()) {

            /**
             * 参数未注册
             */
            if (regist.get(key) == null) {
                /**
                 * 即使加了前缀也没找到
                 */
                if (!key.startsWith(current) ||
                        regist.get(key.substring(current.length() + 1)) == null)
                {

                    boolean record = true;
                    for (String prefix : ignore) {
                        if (key.startsWith(prefix)) {
                            record = false;
                            break;
                        }
                    }
                    if (record) {
                        unregisted.put(key, properties.get(key));
                    }
                    properties.remove(key);
                }
            }
        }

        if (!allowUnregist()) {

            if (unregisted.size() > 0) {
                log.warn("in strict mode, should clear unknown params");
                unregisted.forEach((k,v) -> log.info("{} -> {}", k, v));
                log.warn("in strict mode, should clear unknown params");
                System.exit(-1);
            }
        }
    }

    protected void unregistParsed(CommandLine commondParsed) {

        if (allowUnregist()) {

            for(String key: unregisted.stringPropertyNames()) {
                if (commondParsed.hasOption(key)) {
                    String value = commondParsed.getOptionValue(key);
                    unregisted.setProperty(key, value == null ? "true" : value);
                }
            }
        }
    }

    private Map<String, String> getSort(Map map) {
        class MapKeyComparator implements Comparator<String>{
            @Override
            public int compare(String str1, String str2) {
                return str1.compareTo(str2);
            }
        }

        Map sortMap = new TreeMap<String, String>(
                new MapKeyComparator());
        sortMap.putAll(map);
        return sortMap;
    }

    /**
     * 添加额外配置文件
     *      1. 优先级最高，超过命令行
     *      2. 这里的配置内容，无法在dump中显示，需要另外定义dump选项
     */
    public void exctraConfig(BaseOption option, String path) {

        regist(current, option);

        /**
         * 为了使优先级最高
         *      清理提取的配置文件中，自带的前缀
         *      将current的前缀加入到前边，相当于利用了current的机制
         */
        parseConfig(path, true, "*", "");
    }
}

