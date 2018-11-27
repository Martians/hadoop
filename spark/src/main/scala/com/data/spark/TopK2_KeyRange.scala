
package com.data.spark

import com.data.spark.common._

//https://stackoverflow.com/questions/30164865/spark-get-top-n-by-key
// get topk by key
object TopK2_KeyRange {
  def main(args: Array[String]): Unit = {

    val env = new Enviroment(args)
    val sc = env.parse()
    logger.set(false)

    // (K, V), sort V by Key -> (K, (V1,C1), (V2, C2), (V3, C3))
    val array = List(("a", 2), ("a", 3), ("a", 2), (2, 1), (3, 2)
      , (2, 1), (2, 2), (2, 1), ("a", 5), (2, 2)
      , (3, 1), (3, 2), (3, 3), (2, 4))
    var input = sc.parallelize(array)

    val count = input.map(x => (x, 1)).reduceByKey((x, y) => x + y)
      .map(x => (x._1._1, (x._1._2, x._2)))

/*
(a,List((2,2), (3,1), (5,1)))
(2,List((1,3), (2,2), (4,1)))
(3,List((2,2), (1,1), (3,1)))*/
    implicit val sortTuple = new Ordering[(Int, Int)] {
      override def compare(a: (Int, Int), b: (Int, Int)) = b._2.compare(a._2)
    }

    // handle topK
    if (true) {
      // 1) (K, list(v)) -> (K, sorted list(v)), must use {} here, not ()
      count.groupByKey().map {
        // convert to a map item, key -> list, in map handle, sort ths list;
        //  Ordering[(Int, Int)] or sortTuple is ok
        case (k, values) => k -> values.toList.sorted(Ordering[(Int, Int)])
        //{ case (k, values) => k -> values.toList.sorted(sortTuple)}
      }.collect().foreach(println)

      // 2) use mapValues is also ok
      if (false) {
        count.groupByKey().mapValues(
          values => values.toList.sorted(sortTuple)
        ).collect().foreach(println)
      }

      // 3) use map is also ok
      if (false) {
        count.groupByKey().map(x => {
          {
            (x._1, x._2.toList.sorted(sortTuple))
          }
        }).collect().foreach(println)
      }

      // 4) use map is also ok
      if (false) {
        count.groupByKey().map({
          case (k, v) => (k, v.toList.sorted(sortTuple))
        }).collect().foreach(println)
      }
    }

  }
}
