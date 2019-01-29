package com.data.stream

import com.google.gson.Gson
import org.apache.flink.api.common.functions.{RichFilterFunction, RichMapFunction}
import org.apache.flink.api.common.state.MapStateDescriptor
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeHint, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.api.scala._
import org.slf4j.LoggerFactory

/**
  * https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/stream/operators/#datastream-transformations
  *
  * Todo：
  *     1. checkpoint
  */
object Monitoring {
    private val log = LoggerFactory.getLogger(this.getClass)

    def main(args: Array[String]): Unit = {
        val flink = new FlinkEnv(args)
        val config = new FlinkConfig(flink.command)

        val ruling = new RuleSource(flink, config)
        val stream = new EventSource(flink, config).get()

        val result = stream.connect(ruling.broadcast())
            .process(new BroadcastProcess(config, ruling))

        result.filter(new NotifyProcess(config))

        //ruling.stream.print()
        //stream.print()
        //result.print()

        flink.env.execute("Flink monitor")
    }

}
