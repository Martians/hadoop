package com.data.stream

import org.apache.flink.streaming.api.scala._
import java.util.{Date, Properties}

import com.google.gson.Gson
import org.apache.flink.api.common.functions.RichMapFunction
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.api.scala.DataStream
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer011
import org.slf4j.LoggerFactory

import scala.collection.mutable.ListBuffer

case class Event(gateway_id: Long, device_id: String, real_data: String, timestamp: Long)
case class EventKey(gateway: Long, device: String)

class EventSource(flink: FlinkEnv, config: FlinkConfig) {
    private val log = LoggerFactory.getLogger(this.getClass)

    var stream: DataStream[Event] = null

    if (config.debug_test) {
        val now: Date = new Date()

        var lists = ListBuffer(
            Event(1, "111", "120", now.getTime),

            // 不存在相应的规则
            Event(1, "333", "2", now.getTime)
        )

        val list = ListBuffer(
            // 在范围值内
            Event(1, "111", "120", now.getTime),

            // 超出了范围
            Event(1, "222", "2", now.getTime),

            // 相似的请求
            Event(2, "222", "150", now.getTime),
            Event(3, "333", "150", now.getTime)
        )

        for (i <- 1 to config.debug_count) {
            lists ++= list
        }

        stream = flink.env.fromElements(lists: _*)

    } else {
        val command = flink.command

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
        stream = flink.env.addSource(consumer).map(new RichMapFunction[String, Event] {
            private lazy val log = LoggerFactory.getLogger(this.getClass)
            private lazy val gson = new Gson

            def map(data: String): Event = {
                gson.fromJson(data, classOf[Event])
            }
        })
    }

    def get() = {
        stream.keyBy(new KeySelector[Event, EventKey] {
            override def getKey(value : Event) : EventKey = {
                return EventKey(value.gateway_id, value.device_id)
            }
        })
    }
}
