package com.data.stream

import test.Enviroment


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
