
package com.data.spark

import com.data.spark.common._
import org.apache.spark._

/**
   prepare：hadoop fs -put ~/AFINN-111.txt /

1. spark-submit --class com.data.spark.WordCount target/scala-2.11/WordCount.jar
2. spark-submit --class com.data.spark.WordCount target/scala-2.11/WordCount.jar local\
      hdfs://192.168.36.10:9000/AFINN-111.txt hdfs://192.168.36.10:9000/output
3. spark-submit --class com.data.spark.WordCount target/scala-2.11/WordCount.jar spark://192.168.36.10:7077 \
      hdfs://192.168.36.10:9000/AFINN-111.txt hdfs://192.168.36.10:9000/output
  **/
/*
(pre-built,1)
(YARN,,1)
(locally,2)
(changed,1)
*/
object WordCount {
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
        .reduceByKey(_ + _)
        //.reduceByKey{case (x, y) => x + y}
    //val count = input.flatMap(x => x.split(" ")).countByValue()

    count.saveAsTextFile(env.output)
    println(count.toDebugString)

    println("total: " + count.count())
    println("save and complete ...")
    Thread.sleep(100000)

    sc.stop()
  }
}
