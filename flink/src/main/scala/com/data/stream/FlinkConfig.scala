package com.data.stream

import com.data.BaseExporter

/**
  * 需要进行传递的配置
  */
class FlinkConfig(command: BaseExporter) extends Serializable {

    val debug_test = command.getBool("debug.test")
    val debug_wait = command.getInt("debug.wait")
    val debug_count = command.getInt("debug.count")
    val debug_task = command.getInt("config.parallelism")


    val unordered = command.getLong("config.unordered")
    val logging = command.getBool("debug.logging")
}
