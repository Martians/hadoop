package com.data

import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.scala.StreamExecutionEnvironment
import org.slf4j.LoggerFactory

object TestJob {
    private val log = LoggerFactory.getLogger(this.getClass)

    def main(args: Array[String]) {

        /**
          * getExecutionEnvironment，根据执行环境的不同，决定在 local jvm, 还是在提交到 cluster中执行
          * RemoteEnv
          *
          * 可以用flink提供的ParameterTool读取配置
          */
        val env = StreamExecutionEnvironment.getExecutionEnvironment
        env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

        /**
          *  EventTime：
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/event_time.html
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/event_timestamps_watermarks.html#source-functions-with-timestamps-and-watermarks
          *
          *  1. source 直接产生时间：继承Source Functions
          *     如：kafka AscendingTimestampExtractor
          *
          *  2. 指定Timestamp Assigners / Watermark Generators
          *     1）指定自定义版本：
          *     2）指定系统自带的，https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/event_timestamp_extractors.html
          *
          *     策略举例：
          *     1）定期生成
          *     2）读取create time，等待一个时间后生成
          *     3）读取到 event 中的特定属性匹配后生成
          *
          */

        val result = env.execute("Flink real time test")
        result.getAccumulatorResult("count")

        /**
          * state:
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/state/state.html
          *     1. ValueState、ListState、设置TTL
          *     2. 预制函数：mapWithState
          *     3. 广播状态：https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/state/broadcast_state.html
          **/

        /**
          * checkpoint
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/state/checkpointing.html
          */

        /**
          * KeyedStream
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/api_concepts.html#specifying-keys
          *     1. 使用不同的方式指定key
          *     2. 使用 type指定输入类型
          */

        /**
          * operator：
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/operators/
          *
          *     1. reduce
          */

        /**
          * windows
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/operators/windows.html
          *     1. keyed、non-keyd
          *     2. 聚合处理、自定义process window
          */

        /**
          * async
          *     https://blog.csdn.net/aegeaner/article/details/73105563
          */

        /**
          * side output
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/stream/side_output.html
          */

        /**
          * Type
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/types_serialization.html
          *     1. TypeInformation，TypeSerializer
          *     2. case class
          */

        /**
          * metric
          *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/monitoring/metrics.html
          */

        /**
          * Accumulators & Counters
          *     http://doc.flink-china.org/latest/dev/api_concepts.html#accumulators--counters
          */

        /**
          * 选择key。字符串、key选择器
          * https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/api_concepts.html#define-keys-using-field-expressions
          */

        /**
          * map：lamda、rich function
          */

        /**
          * 可以使用 case class、tuple
          * env.fromElements(("hello", 1), ("world", 2))
          *
          *     flink-examples\flink-examples-batch\src\main\java\org\apache\flink\examples\java\relational\EmptyFieldsCountAccumulator.java
          */
    }
}
