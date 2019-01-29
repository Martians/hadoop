package com.data.stream

import java.util.Properties

import com.data.ParseYAML
import org.apache.flink.streaming.api.scala.{StreamExecutionEnvironment, _}

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
}
