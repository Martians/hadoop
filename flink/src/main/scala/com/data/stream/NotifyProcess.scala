package com.data.stream

import org.apache.flink.api.common.accumulators.LongCounter
import org.apache.flink.api.common.functions.RichFilterFunction
import org.apache.flink.configuration.Configuration
import org.slf4j.LoggerFactory

class NotifyProcess(config: FlinkConfig) extends RichFilterFunction[(Event, Rule)] {
    private val log = LoggerFactory.getLogger(this.getClass)

    var count = 0

    @throws[Exception]
    override def open(parameters: Configuration): Unit = {
        super.open(parameters)
    }

    override def filter(t: (Event, Rule)): Boolean = {
        if (config.debug_test) {

            if (config.debug_wait > 0) {
                count = count + 1
                if (count >= config.debug_wait) {
                    Thread.sleep(10000)
                }
            }
        }
        true
    }
}
