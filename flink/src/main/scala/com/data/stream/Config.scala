package com.data.stream

import com.data.BaseExporter

class Config(command: BaseExporter) extends Serializable {

    case class Working(maxRecord: Int, loop: Int, dump: Boolean)
    val working = new Working(5,
        command.getInt("debug.loop"),
        command.getBool("debug.dump"))

}
