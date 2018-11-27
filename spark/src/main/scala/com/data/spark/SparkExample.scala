
package com.data.spark

import com.data.spark.common._

// http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.rdd.RDD
// http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.rdd.PairRDDFunctions
object SparkExample {
  def main(args: Array[String]): Unit = {

    val infile = "README.md"
    val env = new Enviroment(args, infile)
    val sc = env.parse()
    logger.set(false)

    val input = sc.textFile(env.infile)
    // val count = input.map(line => { val pos = line.indexOf("\t"); line.substring(0, pos)})
    //val count = input.map(line => line.split(" ")(0))
    val count = input.flatMap(line => line.split(" "))
        .map(word => (word, 1))
        .reduceByKey(_ + _, 5)
        //.reduceByKey{case (x, y) => x + y}

    // mapPartitions, 每个分区提供一个iterator
    if (true) {
      count.mapPartitionsWithIndex{ (index, iter) =>
        //一个奇怪的问题，如果此时println iter.siz了，那么res的长度为0
        //println("partition " + index + ", size " + iter.size)
        println("partition " + index)   // 多个分区是同时开始执行的

        val res = for (x <- iter) yield {(x._2, -x._2 - 100)}
        res.toIterator
      }.collect.foreach(println)

      if (false) {
        count.mapPartitions{ iter =>
          val res = for (x <- iter) yield {(x._2, -x._2 - 100)}
          res.toIterator
        }.collect.foreach(println)
      }

      if (false) {
        def mapPart(value: Iterator[(String, Int)]): Iterator[(Int, Int)] = {
          val res = for (x <- 1 to 10) yield {(x, x + 10)}
          res.toIterator
        }
        // mapPartitions[(Int, Int)]，指定了返回者的类型
        count.mapPartitions[(Int, Int)](mapPart).collect.foreach(println)
      }
    }


    println("save and complete ...")
    Thread.sleep(100000)

    sc.stop()
  }
}

/*
      val res = for (x <- iter) yield {
        println(x._1)
        (x._1, 1)
      }
      //
      //res
      res
*/
/*

def mapPart(value: (Int, Iterator[(String, Int)])): Iterator[(Int, Int)] = {
val res = for (x <- 1 to 10) yield { (x, x + 10) }
res.toIterator
}
//http://wanshi.iteye.com/blog/2183906
count.mapPartitionsWithIndex[(Int, Int)](mapPart).collect.foreach(println)*/
