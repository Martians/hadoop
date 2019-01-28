package com.data.stream

import com.google.gson.Gson
import org.apache.flink.api.common.functions.RichMapFunction
import org.apache.flink.api.common.state.MapStateDescriptor
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeHint, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.api.scala._
import org.slf4j.LoggerFactory

/**
  * https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/stream/operators/#datastream-transformations
  *
  * json：https://blog.csdn.net/shuaidan19920412/article/details/79356440
  */
case class Event(gateway_id: Long, device_id: String, real_data: Float, timestamp: Long)
case class EventKey(gateway: Long, device: String)

case class Rule(id: Long, device: String, gateway: Long, name: String, dtype: String, status: String, upper: String, lower: String, unit: String, up: String, down: String)
case class RuleKey(gateway: Long, device: String)

object Broadcast {
    private val log = LoggerFactory.getLogger(this.getClass)

    def main(args: Array[String]): Unit = {
        val flink = new FlinkEnv(args)
        val config = new Config(flink.command)

        val stream = flink.stream.map(new RichMapFunction[String, Event] {
            private lazy val log = LoggerFactory.getLogger(this.getClass)
            private lazy val gson = new Gson

            def map(data: String): Event = {
                gson.fromJson(data, classOf[Event])
            }
        }).keyBy(new KeySelector[Event, EventKey] {
            override def getKey(value : Event) : EventKey = {
                return EventKey(value.gateway_id, value.device_id)
            }
        })

        val ruleStateDescriptor = new MapStateDescriptor(
            "RulesBroadcastState",
            TypeInformation.of(new TypeHint[RuleKey]() {}),
            TypeInformation.of(new TypeHint[Rule]() {}))
        val rule = flink.rule.broadcast(ruleStateDescriptor)

//        stream.connect(rule).process()

        stream.print()
        flink.env.execute("Flink monitor")
    }

}
