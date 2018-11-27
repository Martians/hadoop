package com.data;

import com.data.base.Command;

import com.data.base.Scheduler;
import com.data.util.common.LogUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Todo: mvn plugin, maven-dependency-plugin、maven-assembly-plugin
 *      https://maven.apache.org/plugins/maven-dependency-plugin/index.html
 *
 * ref：https://github.com/YugaByte/yugabyte-db.git  /java/yb-loadtester
 */

/**
 * 功能完善
 * 1. 代码参考
 *      参考ycsb、cassandra-stress的代码
 *
 * 2. 随机数生成
 *      随机数的分布设置，uniform等
 *      设置数据随机大小可变
 *      文件导入，断点方式
 *      timeseriamode
 *
 * 3. 功能完善
 *      解析：YAML
 *      发送限速 target
 *      读写比例
 *      单独请求等待时间延长
 *      强制执行压缩过程
 *      .setConsistencyLevel(ConsistencyLevel.ONE)
 *      记录失败的key
 *      生成不同的日志文
 *
 * 4. 自动检查
 *      client自动检测table模式进行数据清理
 *      create index放到bind语句
 *      设置副本策略，根据远端的机器个数，字段选择
 *      数据verify
 *
 * 5. Global API
 *      查看DataStax关于dirver的文档
 *      redis api测试
 *      测试数据都在一个分区的情况
 *
 * 6. 多进程
 *      合并通讯，消息中间件
 *      远程控制
 *
 *      百分比对应的延迟等
 *
 *      记录大的请求延迟
 *
 *      读写比例
 */

/**
 * 使用方式：
 *
 * 1. type说明
 *      读取数据：write（随机生成）、load（文件读取）、read（随机生成）
 *      生成数据：generate（随机生成）、read 附带（请求的返回）、scan 附带（请求的返回）
 *
 *  2. 数据生成、读取
 *      1）生成数据
 *          a. 在内存生成
 *          read：random：seed=100，或者不设置seed，将会使用随机
 *
 *          b. 写入到本地文件
 *          直接生成 ：type=generate, data_path=, file_count=10,file_size=-1
 *          read 附带：type=read, data_path=, file_count=10,file_size=-1
 *          scan 附带：type=scan, data_path=, file_count=10,file_size=-1
 *
 *      2）读取数据
 *          write 数据：random方式生成
 *          read 数据：random方式生成
 *          load 数据：会从文件中读取
 *
 *      3）随机数生成策略（与上述策略并行）
 *          a. table_gen=true，加快随机数产生
 *          b. uuid、sequence
 *          c. key、value使用不同的随机种子（read时只需要产生key）
 *          d. 如果必须有 data_path，默认使用 output 目录
 *  example：
 *      1）随机生成数据，完成后读取这些数据
 *      type=write read, seed=100
 *
 *      2）先生成文件到本地，然后写入到系统中
 *      type=generate load
 *
 *      3）从系统中 scan 数据到文件中，然后进行读取
 *      type=scan load, data_path=
 *
 *  2. 不同lib
 *      bind=   [subbind=]
 *
 */

/**
 * 依赖库
 *  ## debug：
 *      1）打开pom中，依赖module的开关，可以直接对module进行 debug
 *      2）调试时，使用的是工程最外层的 config.properties
 *
 *  ## 正常模式
 *      1）
 */
public class Client {
    final static Logger log = LoggerFactory.getLogger(Client.class);

    public static void main(String[] args) {

        LogUtil.initialize();

        Command command = new Command(args, false);

        Scheduler schedual = new Scheduler(command);
        schedual.handle();

        log.info("client complete");
        System.exit(0);
    }
}
