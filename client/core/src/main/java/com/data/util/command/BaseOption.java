package com.data.util.command;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class BaseOption {
    final Logger log = LoggerFactory.getLogger(this.getClass());
    private String prefix = "";

    static class SingleOption {
        String option;
        String longOpt;

        boolean hasArgs;
        String descrip;
        Object defaultv;

        /**
         * 优先使用 long name
         */
        public String name() {
            return longOpt == null ? option : longOpt;
        }
    }
    List<SingleOption> optionList = new ArrayList<>();

    public BaseOption() {
        initialize();
    }

    protected void initialize() {}

    public void setPrefix(String prefix) {
        this.prefix = prefix.toLowerCase();
    }

    public String getPrefix() {
        return prefix;
    }


    /**
     * bool option, no args
     */
    public void addOption(String opt, String desc, boolean defaultv) {
        addOption(opt, desc, defaultv, false);
    }

    /**
     * need option, but default is empty
     */
    public void addOption(String opt, String desc) {
        addOption(opt, desc, "", true);
    }

    /**
     * need option, has default value
     */
    public void addOption(String opt, String desc, Object value) {
        addOption(opt, desc, value, true);
    }

    private void addOption(String opt, String desc, Object value, boolean hasArgs) {
        SingleOption option = new SingleOption();

        String[] optArray = opt.split(",");
        if (optArray.length > 1) {
            if (optArray[0].length() > optArray[1].length()) {
                option.option = optArray[1].trim();
                option.longOpt = optArray[0].trim();
            } else {
                option.option = optArray[0].trim();
                option.longOpt = optArray[1].trim();
            }
        } else {
            option.option = optArray[0].trim();
        }
        option.hasArgs = hasArgs;
        option.descrip = desc;
        option.defaultv = value;

        optionList.add(option);
    }

    private String name(SingleOption single) {
        if (prefix.length() == 0) {
            return single.name();

        } else {
            return prefix + "." + single.name();
        }
    }

    /**
     * 提取所有已经注册的 key
     */
    public void distill(Map<String, String> map) {
        for (SingleOption opt : optionList) {
            map.put(name(opt), "");
        }
    }

    /**
     * 将所有选项、默认值提取到 Properties
     */
    public void distill(Properties properties, boolean override) {
        for (SingleOption opt : optionList) {

            /**
             * properties中已经存在这些值，如果需要override就填充默认值
             */
            if (properties.containsKey(name(opt))) {
                if (!override) {
                    continue;
                }
            }
            properties.setProperty(name(opt), opt.defaultv.toString());
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * org.apache.commons.cli
     */

    /**
     * 将内部存储的option提取出来, 准备用于解析命令行
     *
     *      注意：用于命令行时，不使用每个命令的 prefix (.是命令中的无效字符)
     *      1. 同时注册的多个 OptionParser之间，去掉前缀后，不能有冲突，否则会被覆盖掉
     *
     *      2. 这里注册的带一个prefix的命令，prefix将被直接取消, kafka.host -> host
     *      3. 这里注册的带两个prefix的命令，命令将无法注册成功，这些参数只能在配置文件中使用
     *         或者将无效字符进行转换 kafka.host.port -> host-port
     */
    public void distill(org.apache.commons.cli.Options commandLine, boolean prefix) {
        for (SingleOption opt : optionList) {

            Option exist = commandLine.getOption(opt.option);
            if (exist != null) {
                log.warn("regist option parser, but {} already exist, \n\twhen regist [{} :: {} :: {}]", exist,
                        opt.option, opt.descrip, opt.defaultv);
                System.exit(-1);
            }

            //if (opt.option.contains(".")) {
            //    log.debug("option  [{} :: {} :: {}] contain ., ignore from commandline", opt.option, opt.descrip, opt.defaultv);
            //    continue;
            //}

            if (opt.longOpt == null) {
                commandLine.addOption(convertCommandLine(opt.option, prefix),
                        opt.hasArgs, opt.descrip);

            } else {
                commandLine.addOption(convertCommandLine(opt.option, prefix),
                        opt.longOpt, opt.hasArgs, opt.descrip);
            }
        }
    }

    /**
     * 允许带.的命令，需要先将.转换为_
     */
    private String convertCommandLine(String option, boolean prefix) {
        if (prefix) {
            return option.replace(".", "_");

        } else {
            int index = option.lastIndexOf(".");
            return option.substring(index + 1);
        }
    }

    /**
     * 从命令行解析出来的选项，合并到 properties
     *      1）因为没有遍历 commondParsed 的接口，所有遍历自己注册的所有 BaseOption
     *      2）使用 command.current前缀存入，使得命令行接收到的命令的优先级最高
     */
    public void updateFromCommandLine(CommandLine commondParsed, Properties properties, String current, boolean prefix) {

        if (current.length() > 0) {
            current = current + ".";
        }
        for (SingleOption opt : optionList) {

            /**
             * 在命令行中，传入了该命令
             */
            String convert = convertCommandLine(opt.option, prefix);
            String origin = name(opt);

            if (commondParsed.hasOption(convert)) {
                String data = commondParsed.getOptionValue(convert);
                properties.setProperty(origin.startsWith(current) ? origin : current + origin,
                        data == null ? "true" : data);
            }
        }
    }
}
