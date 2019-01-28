package com.data.stream

import java.util.Properties

import com.data.BaseExporter
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer011

/**
  * https://blog.csdn.net/mathieu66/article/details/83111644
  */
class RuleSource(command: BaseExporter) {
    
    val properties = new Properties()
    properties.setProperty("bootstrap.servers", command.get("database.server"))
    properties.setProperty("group.id", command.get("database.group"))

    val consumer = new FlinkKafkaConsumer011[String](command.get("database.topic"), new SimpleStringSchema(), properties)
    consumer.setStartFromEarliest()
}
