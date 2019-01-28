package com.data.stream

import java.util.Properties

import com.data.ParseYAML
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.streaming.api.scala.{StreamExecutionEnvironment, _}
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer011

class FlinkEnv(args: Array[String]) {

    val command = new ParseYAML
    command.initialize("config.yaml", false)
    command.consist("flink")

    /**
      * env
      */
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    if (command.getInt("config.parallelism") > 0) {
        env.setParallelism(command.getInt("config.parallelism"))
    }

    /**
      * kafka：
      *     https://ci.apache.org/projects/flink/flink-docs-release-1.6/dev/connectors/kafka.html
      */
    val properties = new Properties()
    properties.setProperty("bootstrap.servers", command.get("kafka.server"))
    properties.setProperty("group.id", command.get("kafka.group"))

    val consumer = new FlinkKafkaConsumer011[String](command.get("kafka.topic"), new SimpleStringSchema(), properties)
    if (command.getBool("kafka.Earliest")) {
        consumer.setStartFromEarliest()
    }

    val stream = env.addSource(consumer)

    val database = new RuleSource(command)
    val rule = env.addSource(database.consumer)
}
