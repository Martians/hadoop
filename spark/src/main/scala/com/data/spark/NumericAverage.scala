
package com.data.spark

import com.data.spark.common._
import org.apache.spark._

object NumericAverage {
  def main(args: Array[String]): Unit = {

    //val infile = "../data/numeric.txt"
    val infile = "numeric.txt"

    val env = new Enviroment(args, infile)
    val sc = env.parse()

    val input = sc.textFile(env.infile)
    input.cache()

    // 1) reduce
    if (false) {
      val count = input.map(x => (x.toLong, 1)).reduce((x, y) => (x._1 + y._1, x._2 + y._2))
      println(count._1 + ", " + count._2 + ", avg: " + count._1 / count._2 + " partition: " + input.getNumPartitions)
    }

    // 2) aggregate
    if (true) {
      val count = input.map(_.toLong)
        .aggregate((0L, 0))((acc, value) => (acc._1 + value, acc._2 + 1),
        (acc1, acc2) => (acc1._1 + acc2._1, acc1._2 + acc2._2))
      println("total: " + count._1 + ", count: " + count._2 + ", avg: " + count._1 / count._2 + ", partition: " + input.getNumPartitions)
    }

    println("save and complete ...")
    Thread.sleep(3000000)

    sc.stop()
  }
}
