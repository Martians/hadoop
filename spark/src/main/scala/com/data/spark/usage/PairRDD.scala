
package com.data.spark.usage

import org.apache.spark._
import org.apache.spark.rdd.RDD

object PairRDD {

  def simple(input: RDD[(Int, Int)], input2: RDD[(Int, Int)]): Unit = {
    val data = input.reduceByKey((x, y) => x + y)
    data.collect().foreach(println)

    // lose partitioner
    println("origin partitioner: " + data.partitioner)
    val lost = data.map(x => x)
    println("partitioner after map: " + lost.partitioner)
  }

  def multi(input: RDD[(Int, Int)], input2: RDD[(Int, Int)]): Unit = {
    /*
    ((1,2),(1,2))
    ((1,2),(1,3))
    ((1,2),(3,4))
    ((1,3),(1,2))
    ((1,3),(1,3))
    ((1,3),(3,4))
    ((3,4),(1,2))
    ((3,4),(1,3))
    ((3,4),(3,4))
    */
    println("multi: cartesian")
    input.cartesian(input).collect().foreach(x => println("\t" + x))

    println("multi: cogroup")
    /*
    (1, (CompactBuffer(2, 3), CompactBuffer(3, 2)))
    (3, (CompactBuffer(4), CompactBuffer(5)))
    (2, (CompactBuffer(), CompactBuffer(4)))
    */
    input.cogroup(input2).collect().foreach(x => println("\t" + x))
    //input.cogroup(input2).collect().map(println(_))
    // data.collectAsMap().map(println(_))

    println("multi: join:")
    /*
    (1,(2,3))
    (1,(2,2))
    (1,(3,3))
    (1,(3,2))
    (3,(4,5))
    */
    input.join(input2).collect().foreach(x => println("\t" + x))
  }

  def combine(input: RDD[(Int, Int)], input2: RDD[(Int, Int)]): Unit = {
    //  (1,(a,6))
    //  (3,(a,5))
    println("combine: aggregateByKey, set value as \"a\" -> count:")
    input.aggregateByKey(("a", 1))(   // U is a new type
      (U, V) => (U._1, U._2 + V),     // merge U and value
      (U, W) => (U._1, U._2 + W._2))  // merge two U
      .collect().foreach(x => println("\t" + x))

    println("combine: combineByKey, set value as Map[Value, count]")
    //  (1,Map(2 -> 1, 3 -> 1))
    //  (3,Map(4 -> 1))
    // add a value to map whose type is Map[Value, Count]
    val comb = (C: Map[Int, Int], V: Int) => {
      if (C.contains(V)) {
        val c = C.get(V).get
        C - V + (V -> (c + 1))
      } else {
        C + (V -> 1)
      }
    }
    input.combineByKey((V: Int) => Map(V -> 1),   // fist add a value, set as map(value, 1)
      (C: Map[Int, Int], V: Int) => comb(C, V),   // combine Combiner and a Value
      (C: Map[Int, Int], W: Map[Int, Int]) => C)  // combine two Combimer
      .collect().foreach(x => println("\t" + x))

  }

  def main(args: Array[String]): Unit = {

    val conf = new SparkConf().setMaster("local").setAppName("test")
    val sc = new SparkContext(conf)

    //val input = sc.parallelize(List(1, 2, 3, 4))
    val input = sc.parallelize(List((1, 2), (1, 3), (3, 4)))
    val input2 = sc.parallelize(List((1, 3), (1, 2), (2, 4), (3, 5)))

    simple(input, input2)
    multi(input, input2)

    combine(input, input2)
  }
}
