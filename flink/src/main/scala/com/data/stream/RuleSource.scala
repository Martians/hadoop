package com.data.stream

import java.util.Properties

import com.data.BaseExporter
import com.google.gson.Gson
import org.apache.flink.api.common.functions.RichMapFunction
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.common.state.MapStateDescriptor
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer011
import org.apache.flink.streaming.api.scala._
import org.slf4j.LoggerFactory

/**
  * mysql: https://blog.csdn.net/mathieu66/article/details/83111644
  *
  * 无法进行等待：
  *     https://stackoverflow.com/questions/51020395/flinks-broadcast-state-behavior
  */
//case class Rule(id: Long, device: String, gateway: Long, name: String, dtype: String, status: String, upper: String, lower: String, unit: String, up: String, down: String)
case class Rule(id: Long, gateway: Long, device: String, upper: String, lower: String)
case class RuleKey(gateway: Long, device: String)

class RuleSource(flink: FlinkEnv, config: FlinkConfig) {
    var stream: DataStream[Rule] = null

    if (config.debug_test) {
        val list = Array(
            Rule(1, 1, "111", "100", "200"),
            Rule(1, 1, "222", "50", "100"),
            Rule(2, 2, "222", "100", "200"),
            Rule(3, 3, "333", "100", "200")
        )
        stream = flink.env.fromElements(list: _*)

    } else {
    }

    val ruleStateDescriptor = new MapStateDescriptor(
        "RulesBroadcastState",
        TypeInformation.of(new TypeHint[RuleKey]() {}),
        TypeInformation.of(new TypeHint[Rule]() {}))

    def broadcast() = {
        stream.broadcast(ruleStateDescriptor)
    }
}
