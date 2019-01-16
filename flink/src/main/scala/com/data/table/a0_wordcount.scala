package com.data.table

import test.Enviroment

object DataSet {
    val WORDS = Array(
        "To be, or not to be,--that is the question:--",
        "Whether 'tis nobler in the mind to suffer",
        "The slings and arrows of outrageous fortune"
    )
}

object a0_wordcount {
    def main(args: Array[String]): Unit = {

        val work = new Enviroment(args)

        val stream = DataSet.WORDS
            .flatMap(_.split("\\W+"))
            .filter(_.nonEmpty)
            .map((_, 1))
//            .keyBy(0)
            .sum(1)

        work.print(stream)

        work.env.execute("Streaming WordCount")
    }
}
