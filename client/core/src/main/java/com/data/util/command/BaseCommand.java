package com.data.util.command;

import org.apache.commons.cli.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.net.URL;
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

    /**
     * 读取配置时，优先在传入的key前增加 current；找不到时再使用原key
     */
    private String current = "";

    /**
     * when use strict mode, ignore these prefix
     */
    protected String validBind = "";

    class Common extends BaseOption {
        Common() {
            /** 实际上，是否输出help，只取决于命令行参数 */
            addOption("h, help", "help message", false);
            addOption("c,config", "config file");
            addOption("strict", "strict mode, never get unknown param", false);
            addOption("prefix", "command line prefix, 0:cancel, 1:convert [.->_]", true);
            addOption("dump", "check effective config", false);

            addOption("host", "server host", "192.168.10.7");
            addOption("clear", "clear data", false);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public BaseCommand() {}

    public BaseCommand(String[] args) {
        initialize(args);
    }

    /**
     * 手动强制设置某个选项
     */
    public void set(String key, String value) {
        properties.setProperty(key, value);
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
                log.error("can't parse option {}", key);
                System.exit(1);
            } else {
                return null;
            }
        }
        return value;
    }

    public boolean has(String key) { return get(key).length() > 0; }
    public String get(String key) { return get(key, true); }

    public boolean exist(String key) {
        return !get(key).isEmpty();
    }

    public long getLong(String key) {
        return Long.parseLong(get(key));
    }

    public int getInt(String key) {
        return Integer.parseInt(get(key));
    }

    /**
     * 注册时，bool 设置为0，或者"false"都可以; 最终会用 Boolean.valueOf 解析
     */
    public boolean getBool(String key) {
        return Boolean.parseBoolean(get(key));
    }

    public <E extends Enum<E>> E getEnum(String key, Class<E> clazz) {
        return Enum.valueOf(clazz, get(key));
    }

    public void debug() {
        properties.forEach((k,v) -> log.info("{} -> {}", k, v));
    }

    public void debug(String key) {
        properties.forEach((k,v) -> {
            if (((String)k).startsWith(key)) {
                log.info("=============== {} -> {}", k, v);
            }
        });
    }

    public String toString() {
        StringBuffer sb = new StringBuffer();
        sb.append("\n");

        Map map = dump();
        for (Object key : map.keySet()) {
            if (properties.getProperty(current + "." + key) != null) {
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
        if (param.check(get(key))) {
            if (display.length() > 0) {
                log.info("{}", display);

            } else {
                log.info("not support config [{}] set as <{}>, will not effect", key, get(key));
            }

            if (exit) {
                System.exit(-1);
                return false;
            }

            try {
                for (int i = 0; i < 5; i++) {
                    System.out.print("==============");
                    Thread.sleep(500);
                }
            } catch (InterruptedException e) {
            }
            System.out.println(" to be continued ...");
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
        if (!param.check(get(key))) {
            log.info("notice: [{} = {}], set: {}", key, get(key), display);

            if (exit) {
                System.exit(-1);
                return false;
            }

            try {
                for (int i = 0; i < 5; i++) {
                    System.out.print("==============");
                    Thread.sleep(500);
                }
            } catch (InterruptedException e) {
            }
            System.out.println(" to be continued ...");
            return true;

        } else {
            return false;
        }
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
    protected void validate() {}

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
        set("strict", set ? "false" : "true");
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

    /**
     * 将多个配置参数分开存放
     */
    protected void construct() {
        addParser("", new Common());

        registParser();
    }

    public void addParser(String prefix, BaseOption option) {
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
        /**
         * 资源目录
         */
        yamlOrProp(true);

        /**
         * 当前目录
         */
        yamlOrProp(false);
    }

    /**
     * 读取默认配置文件，通常会在jar包中
     */
    private boolean resourceExist(String file, boolean resource) {
        if (resource) {
            URL url = Thread.currentThread().getContextClassLoader().getResource(file);
            return url != null;

        } else {
            return new File(file).exists();
        }
    }

    private void yamlOrProp(boolean resource) {
        if (resourceExist(yamlConfig, resource)) {
            parseFile(yamlConfig, resource);

        } else if (resourceExist(propConfig, resource)) {
            parseFile(propConfig, resource);
        }
    }

    private void parseFile(String file, boolean resource) {
        Properties props;
        String fixPrefix = "";

        if (file.endsWith("yaml") || file.endsWith("yml")) {
            ParseYAML parser = new ParseYAML();
            props = parser.initialize(file, resource);
            fixPrefix = "global";

        } else {
            ParseProperty parser = new ParseProperty();
            props = parser.initialize(file, resource);
        }

        if (props == null) {
            System.exit(-1);

        } else {
            fixPrefix(props, fixPrefix);
        }
    }

    /**
     * 取消配置中的前缀，当前只用于取消global，用于简化处理
     *      1）.properties 中，对global部分的配置，没有使用前缀
     *      2）.yaml中，对global部分的配置，是放在global的对象之下，为了统一需要取消
     */
    protected void fixPrefix(Properties props, String prefix) {
        prefix = prefix + ".";

        for (String key : props.stringPropertyNames()) {
            String fix = key;
            if (key.startsWith(prefix)) {
                fix = key.substring(prefix.length());
            }
            properties.put(fix, props.get(key));
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
            parseFile(parsed.getOptionValue("config"), false);

        /**
         * 查找是否存在可以优先级最高的配置文件, specific.yaml
         *      只用于特殊用途：在target目录下调试，mvn package之后，配置文件会被默认的 config.yaml 覆盖
         *                     在此情况下，可以使用此配置
         */
        } else {
            if (resourceExist(specConfig, false)) {
                parseFile(specConfig, false);
            }
        }

        /**
         * 命令行解析的命令，优先级最高
         */
        Properties props = new Properties();
        for (BaseOption option : parserList) {
            option.updateFromCommandLine(parsed, props, current, getBool("prefix"));
        }
        properties.putAll(props);

        unregistCheck();
        unregistParsed(parsed);

        dumpConfig();
    }

    protected void unregistOption(org.apache.commons.cli.Options commandLine) {

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

    private Map<String, String> dump() {
        class MapKeyComparator implements Comparator<String>{
            @Override
            public int compare(String str1, String str2) {
                return str1.compareTo(str2);
            }
        }

        Map sortMap = new TreeMap<String, String>(
                new MapKeyComparator());
        sortMap.putAll(properties);

        if (allowUnregist()) {
            sortMap.putAll(unregisted);
        }
        return sortMap;
    }

    private void dumpConfig() {
        if (getBool("dump")) {
            log.info("dump config:");

            Map map = dump();
            for (Object key : map.keySet()) {
                /**
                 * 如果有更长路径的配置相匹配，较短的配置将被覆盖
                 */
                if (properties.getProperty(current + "." + key) != null) {
                    continue;
                }
                log.info("\t{}\t: {}", String.format("[%6s]", key), map.get(key));
            }
            System.exit(0);
        }
    }

}
