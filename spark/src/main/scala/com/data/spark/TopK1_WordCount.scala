
package com.data.spark

import com.data.spark.common._

// get word count topK
object TopK1_WordCount {
  def main(args: Array[String]): Unit = {

    val env = new Enviroment(args)
    val sc = env.parse()
    logger.set(false)

    val string = """Hello World Bye World
      Hello Hadoop
      Bye Hadoop Bye Hadoop
      Hello Hadoop
      Hadoop
      Hadoop
      good
    """
    val input = if (args.length > 1) sc.textFile(env.infile) else sc.parallelize(string.split("\n"))

    // val count = input.map(line => { val pos = line.indexOf("\t"); line.substring(0, pos)})
    //val count = input.map(line => line.split(" ")(0))
    val count = input.flatMap(line => line.split("\\s+"))
      .filter(_!="")  //.filter(x => x.matches(".*[a-zA-Z]+.*"))    // filter more
      .map(word => (word, 1))
      .reduceByKey(_ + _)

    // notify, we must repartition to 1, or order will not ascending globally, when collect from different partition？

    // RDD method
    if (false) {
      // repartiton to 1, for only output to one file
      val sort = count.sortBy(x => x._2, false, 1).foreach(println)
    }

    // RDD method, use multi partition, then result will not globally ordered, unless use collect ?
    if (false) {
      // repartiton to 1, for only output to one file
      val sort = count.sortBy(x => x._2, false, 5).foreach(println)
    }

    // PairRDD method, sort by key (the first element)
    if (false) {
      val sort = count.map(x => (x._2, x._1))
        .sortByKey(false).foreach(println)
    }

    // PairRDD method, use implicit comparer, reverse order
    if (true) {
      implicit val sortIntegersByString = new Ordering[Int] {
        override def compare(a: Int, b: Int) = b.compare(a)
      }
      val sort = count.map(x => (x._2, x._1))
          .sortByKey(false, 1).foreach(println)
    }

    // PairRDD method, switch pos, and use sortbykey (word, count) -> (count, word)
    if (false) {
        val count = input.flatMap(_.split(" "))
          // reduceByKey 转换为1个分区，然后交换key和value，按照之前的value排序，使用降序排列
          .map((_, 1)).reduceByKey(_ + _, 1).map(x => (x._2, x._1)).filter(_ != "")
          .sortByKey(false)
          // 将key和value再交换过来
          .map(x => (x._2, x._1))
          .collect().foreach(println)
    }

    //sort.saveAsTextFile(env.output)
    //val topk = count.mapPartitions(iter => {
  }
}
