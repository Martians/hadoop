package com.data.spark.stream

import com.data.spark.common.{Enviroment, logger}
import org.apache.spark._
import org.apache.spark.sql.SparkSession
import org.apache.spark.storage.StorageLevel
import org.apache.spark.streaming.{Seconds, StreamingContext, Time}


//  http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.StreamingContext
//  http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.dstream.DStream
//  http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.dstream.PairDStreamFunctions
//  http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.flume.FlumeUtils$
object StreamExample {

  val env = new Enviroment(Array())
  logger.set(false)

  val checkpoint = "checkpoint_tmp"

  //for sql_stream
  case class Record(word: String)

  def thread_info(): String = {
    Thread.currentThread().getName() + ", id " + Thread.currentThread().getId
  }

  def main(args: Array[String]): Unit = {

    val conf = new SparkConf()
      .setMaster("local[4]")
      .setAppName("spark streaming")

    if (false) {
      operate_stateful_recover(conf)
    }

    val ssc = new StreamingContext(conf, Seconds(5))
    if (false) {
      source_queue(ssc)
      source_network(ssc)
      //source_network(ssc, true)

      source_text(ssc)
      source_filestream(ssc)
    }

    if (false) {
      operate_unstate(ssc)
      operate_stateful(ssc)

      operate_window(ssc)
      operate_join(ssc)
    }

    if (false) {
      rdd_share_handle(ssc)
    }

    rdd_share_handle(ssc)
    ssc.stop()
  }

  // 仅用于测试目的，内存中生成
  def source_queue(ssc: StreamingContext): Unit = {

    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue
    val rddQueue = Queue[RDD[Int]]()

    val input = ssc.queueStream(rddQueue)
      .map(x => (x % 10, 1)).reduceByKey(_ + _)
    input.print()
    // 这里会启动一个新的线程
    ssc.start()

    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue.synchronized {
        rddQueue += ssc.sparkContext.makeRDD(1 to 1200, 10)
      }
      Thread.sleep(1000)
    }
  }

  def source_network(ssc: StreamingContext, save: Boolean = false) {
    val lines = ssc.socketTextStream("192.168.36.10", 9999, StorageLevel.MEMORY_AND_DISK_SER)
    val count = lines.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_ + _)
    println("before print:")

    if (save) {
      count.saveAsTextFiles("../data/output", "")
    } else {
      count.print()
    }

    ssc.start()
    ssc.awaitTermination()
    println("end work")
  }

  // 必须使用新文件，启动时已经存在的文件不分析;
  def source_text(ssc: StreamingContext): Unit = {
    val input = "hdfs://192.168.36.10:9000/data"

    //本地路径有时候不起作用？？？？
    //val input = System.getProperty("user.dir") + "\\src\\main\\resources\\data\\stream"
    val lines = ssc.textFileStream(input)

    val count = lines.flatMap(_.split(" "))
      .map(x => (x, 1)).reduceByKey(_ + _)
    count.print()

    ssc.start()
    ssc.awaitTermination()
  }

  def source_filestream(ssc: StreamingContext): Unit = {
    val input = "hdfs://192.168.36.10:9000/data"

  }

  // Kafka\HBase
  def output_external(ssc: StreamingContext): Unit = {

  }


  def operate_unstate(ssc: StreamingContext): Unit = {
    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue
    val rddQueue = Queue[RDD[Int]]()

    // 1) 无状态操作
    //    1.1) 相当于对DStream中的每个RDD，单独进行处理，RDD之间不干扰
    val input = ssc.queueStream(rddQueue)
      .map(x => (x % 10, 1)).reduceByKey(_ + _)
    if (false) {
      //    1.2) transform
      input.transform(rdd => rdd.map(x => (x, x._2 + 1))).print()
    }

    //  2) 使用sql方式解析
    //example: https://github.com/apache/spark/blob/v2.2.0/examples/src/main/scala/org/apache/spark/examples/streaming/SqlNetworkWordCount.scala
    if (true) {
      import org.apache.spark.rdd.RDD
      // foreachRDD 是在driver上执行的，因此可以用外部的变量spark
      val spark = SparkSession
        .builder
        .config(ssc.sparkContext.getConf)
        .getOrCreate()

      import spark.implicits._
      input.foreachRDD { (rdd: RDD[(Int, Int)], time: Time) => {
        //val frame = rdd.map(x => Record(x._2.toString)).toDF("word")
        val frame = rdd.toDF("word", "count")
        frame.createOrReplaceTempView("words")

        println(s"========= $time =========")
        spark.sql("select word, count(*) as total from words group by word").show
      }
      }
    }


    // 这里会启动一个新的线程
    ssc.start()
    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue.synchronized {
        rddQueue += ssc.sparkContext.makeRDD(1 to 1200, 10)
      }
      Thread.sleep(1000)
    }
    ssc.awaitTermination()

  }

  //blog：   http://blog.csdn.net/jiangpeng59/article/details/53316592    http://blog.csdn.net/stark_summer/article/details/47666337
  //api：    http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.dstream.PairDStreamFunctions
  //example:  https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/streaming/StatefulNetworkWordCount.scala
  def operate_stateful(ssc: StreamingContext): Unit = {
    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue

    // state操作，必须设置
    ssc.checkpoint(checkpoint)

    val rddQueue = Queue[RDD[Int]]()
    val input = ssc.queueStream(rddQueue)
      .map(x => (x % 10, 1)).reduceByKey(_ + _)

    // 1) updateStateByKey
    def aggregate_count(newv: Seq[Int], exist: Option[Int]): Option[Int] = {
      //Some(if (newv.length > 0) newv.reduce(_ + _) else 0 //累加所有的 count
      //  + exist.getOrElse(0))
      Some(newv.sum + exist.getOrElse(0))
    }

    //  1.1) 每个key都会调用一次该函数：a.传入当前RDD中，当前Key对应的多个value  b. 传入上次聚合的结果
    if (true) {
      input.updateStateByKey[Int](aggregate_count _).print()
    }
    //  1.2) 同上，参见updateStateByKey源码，上述调用是对这里的封装，这里是原始调用
    if (false) {
      // 此函数更加灵活，可以改变Key，使用一个新的Key，而不是原始的Key
      def aggregate_iter(iterator: Iterator[(Int, Seq[Int], Option[Int])]): Iterator[(Int, Int)] = {
        iterator.flatMap(t => aggregate_count(t._2, t._3).map(s => (t._1, s)))
      }

      input.updateStateByKey[Int](aggregate_iter _, new HashPartitioner(2), true).print
    }

    // 这里会启动一个新的线程
    ssc.start()
    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue.synchronized {
        rddQueue += ssc.sparkContext.makeRDD(1 to 1000, 10)
      }
      Thread.sleep(1000)
    }
    ssc.awaitTermination()
  }

  //example:  https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/streaming/RecoverableNetworkWordCount.scala
  // 查看Checkpoint.scala  StreamingContext.getOrCreate -> CheckpointReader.read   https://www.cnblogs.com/dt-zhw/p/5664663.html
  def operate_stateful_recover(conf: SparkConf): Unit = {

    // 这里不能使用queueStream，queue不能写入checkpoint
    //    测试方式：启动后，写入数据，等待一段时间写入检查点成功；再次重启，可以看到之前的数据已经记录下来
    //    执行代码，必须写入在createContext中，否则重启后无法恢复检查点
    def createContext(): StreamingContext = {
      println("Creating new context")

      val ssc = new StreamingContext(conf, Seconds(5))
      val origin = ssc.socketTextStream("192.168.36.10", 9999, StorageLevel.MEMORY_AND_DISK_SER)
      val input = origin.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_ + _)

      ssc.checkpoint(checkpoint)
      if (true) {
        origin.checkpoint(Seconds(100)) // 修改chekcpoint的时间，似乎无效？
        //input.checkpoint(Seconds(100))
      }

      def aggregate_count(newv: Seq[Int], exist: Option[Int]): Option[Int] = {
        Some(newv.sum + exist.getOrElse(0))
      }

      input.updateStateByKey[Int](aggregate_count _).print()
      ssc
    }

    val ssc = StreamingContext.getOrCreate(checkpoint, createContext _)

    // 这里会启动一个新的线程
    ssc.start()
    ssc.awaitTermination()
  }


  def operate_window(ssc: StreamingContext): Unit = {
    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue

    val rddQueue = Queue[RDD[Int]]()
    val origin = ssc.queueStream(rddQueue)
      .map(x => (x % 10, 1))

    // 1) window 操作
    if (false) {
      // 这里 window 30s / batch 5s = 6，每次执行操作会有6个RDD整合在一起
      //     sliding 10s, 每10s执行一次dstream的操作
      // window:  聚合大小，多少个之前的RDD，构成一个新的rdd；相当于将这些周期的RDD进行了union？
      // sliding：执行周期，若少个周期，进行一次下列的操作，
      val input = origin.reduceByKey(_ + _)
      input.window(Seconds(30), Seconds(10)).count().print
    }

    // 2) 带window的reduce操作
    if (false) {
      // 周期为ssc中设置的5s，聚合的RDD长度为 30s/5s = 6 RDD, 这里最高数值可以达到600 例如：(3,600)
      val input = origin.reduceByKeyAndWindow(_ + _, Seconds(30)).print
    }

    // 2) 带window的reduce操作，以及反向操作，提高计算效率，这个必须设置检查点
    //    这里会一致保持这个dstream中的信息，一直输出；如：在没有数据时，仍会输出(4,0)
    if (true) {
      ssc.checkpoint(checkpoint)
      // 第一个函数是将多个RDD累加起来，第二个函数，将超过了window的rdd，从结果集中反向相加（减去）
      val input = origin.reduceByKeyAndWindow(_ + _, _ - _, Seconds(30)).print
    }

    // 这里会启动一个新的线程
    ssc.start()
    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue.synchronized {
        rddQueue += ssc.sparkContext.makeRDD(1 to 1000, 10)
      }
      Thread.sleep(1000)
    }
    ssc.awaitTermination()
  }

  def operate_join(ssc: StreamingContext): Unit = {
    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue

    val rddQueue1 = Queue[RDD[Int]]()
    val rddQueue2 = Queue[RDD[Int]]()

    val input1 = ssc.queueStream(rddQueue1).map(x => (x % 10, 1)).reduceByKey(_ + _)
    val input2 = ssc.queueStream(rddQueue2).map(x => (x % 10, 1)).reduceByKey(_ + _)

    // 注意，此注释只会显示一次
    println("-------------")
    input1.join(input2).print


    // 这里会启动一个新的线程
    ssc.start()
    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue1.synchronized {
        rddQueue1 += ssc.sparkContext.makeRDD(1 to 1000, 10)
      }
      rddQueue2.synchronized {
        rddQueue2 += ssc.sparkContext.makeRDD(1 to 1000 by 2, 5)
      }
      Thread.sleep(1000)
    }
    ssc.awaitTermination()
  }

  //example: https://github.com/apache/spark/blob/v2.2.0/examples/src/main/scala/org/apache/spark/examples/streaming/SqlNetworkWordCount.scala
  def rdd_share_handle(ssc: StreamingContext): Unit = {

    // will
    object SparkSessionSingleton {
      @transient private var instance: SparkSession = _

      def getInstance(sparkConf: SparkConf): SparkSession = {
        if (instance == null) {
          instance = SparkSession
            .builder
            .config(sparkConf)
            .getOrCreate()
        }
        instance
      }
    }

    import org.apache.spark.rdd.RDD
    import scala.collection.mutable.Queue
    val rddQueue = Queue[RDD[Int]]()

    val input = ssc.queueStream(rddQueue)
      .map(x => (x % 10, 1)).reduceByKey(_ + _)
      .repartition(5)   // use more executor

    import org.apache.spark.rdd.RDD
    // 这里的输出，每次只针对一个RDD
    if (false) {
      // foreachRDD，都是在Driver上执行的
      input.foreachRDD { (rdd: RDD[(Int, Int)]) =>
        println("\nnew batch: " + thread_info)

        // foreachPartition，在Executor上执行一个partition
        rdd.foreachPartition { partition =>
          println("========= partition: " + thread_info)
        }
        rdd.foreach(println)
      }
    }

    if (false) {
      // foreachRDD，都是在Driver上执行的
      input.foreachRDD { (rdd: RDD[(Int, Int)]) =>
        // foreach，在dirver上执行，从每个分区获得了数据后
        rdd.foreach(println)
      }
    }

    // 这里的输出，每次只有一个RDD
    if (true) {
      // foreachRDD，都是在Driver上执行的
      input.window(Seconds(10), Seconds(10)).foreachRDD { (rdd: RDD[(Int, Int)]) =>
        println("\nnew batch: " + thread_info)

        // foreachPartition，在Executor上执行一个partition
        rdd.foreachPartition { partition =>

          for (element <- partition) {
            println("========= partition: " + thread_info)
            println(element._2)
          }
        }
        rdd.foreach(println)
      }
    }

    ssc.start()
    // 这里讲每batch时间，从中取出一个rdd来，与rdd的生成间隔无关
    for (i <- 1 to 10) {
      rddQueue.synchronized {
        rddQueue += ssc.sparkContext.makeRDD(1 to 1000, 10)
      }
      Thread.sleep(1000)
    }
    ssc.awaitTermination()
  }
}



