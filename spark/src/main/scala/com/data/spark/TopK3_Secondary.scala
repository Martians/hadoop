
package com.data.spark

import com.data.spark.common._

//https://stackoverflow.com/questions/30164865/spark-get-top-n-by-key
// get topk by key
object TopK3_Secondary {
  def main(args: Array[String]): Unit = {

    val env = new Enviroment(args)
    val sc = env.parse()
    logger.set(false)

    // (K, V), sort V by Key -> (K, (V1,C1), (V2, C2), (V3, C3))
    val array = List((1, 100), (2, 300), (2, 100), (2, 120), (3, 208)
      , (2, 122), (2, 289), (2, 141), (1, 544), (2, 233)
      , (3, 134), (3, 293), (3, 344), (2, 4233))
    var input = sc.parallelize(array)

    // sort by tuple, default is tuple._1, tuple._2
    if (true) {
      val count = input.sortBy(x => (x._1, x._2)).collect().foreach(println)
    }

    // sort by object
    if (true) {
      class SecondSortKey(val first: Int, val second: Int)
        extends Ordered[SecondSortKey] with Serializable {
        override def compare(that: SecondSortKey): Int = {
          if (this.first == that.first) {
            this.second - that.second

          } else {
            this.first - that.first
          }
        }
      }
      val count = input.map(x => (new SecondSortKey(x._1, x._2), x))
        .sortByKey(true)  // sort by SecondSortKey
        .map(x => x._2)   // remove key
        .collect().foreach(println)
    }
  }
}
