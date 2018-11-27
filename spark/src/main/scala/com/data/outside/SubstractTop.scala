
package com.data.outside

import com.data.spark.common._

object SubstractTop {
  def main(args: Array[String]): Unit = {

    val infile = "outside/p_sort"
    //val infile = "../data/outside/p_sort"
    val env = new Enviroment(args, infile)
    val sc = env.parse()

    val a11 = sc.textFile(env.infile + "/a.txt")
    val a21 = sc.textFile(env.infile + "/b.txt")

    val data1 = a11.filter(x => x.charAt(0) == 'A').map(x => x.replaceAll("[^0-9]", "").toLong) //.sample(false, 0.2)
    val data2 = a11.filter(x => x.charAt(0) == 'A').map(x => x.replaceAll("[^0-9]", "").toLong) //.sample(false, 0.2)

    //val result = data1.cartesian(data2).map(x => (x._1 - x._2, 1)).reduceByKey(_ + _).sortBy(x => x._2).top(1)
    val result = data1.cartesian(data2).map(x => (x._1 - x._2, 1))
    val cc = result.reduceByKey(_ + _).sortBy(x => x._2).top(1)

    //val data = a11.filter(x => x.charAt(0) == 'A') //.map(x => x.replaceAll("[^0-9]", "")) //.flatMap(line => line.split(":"))
    result.foreach(println)
  }
}
