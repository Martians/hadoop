package com.data.spark.stream

import com.data.spark.common.{Enviroment, logger}

import org.apache.spark.SparkConf
import org.apache.spark.streaming._


//API:    http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.streaming.kafka.package
//kafka command
//  bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic test
//  bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic test

//  echo "it is a message" | bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
//  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
//  bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic test --time -1
object StreamKafka {

  //val broker = "192.168.36.10:9092"
  val broker = "192.168.127.129:9092"
  val env = new Enviroment(Array())
  logger.set(false)

  def main(args: Array[String]): Unit = {

    val conf = new SparkConf()
      .setMaster("local[4]")
      .setAppName("spark streaming")
    val ssc = new StreamingContext(conf, Seconds(5))

    if (false) {
      receiver_kafka(ssc)

      direct_kafka(ssc)
    }

    direct_kafka(ssc)

    ssc.start()

    ssc.awaitTermination()
    ssc.stop()
  }

  // 不可靠方式，需要启动 WriteAheadLog
  //    提升并发度，需要创建多个 receiver，然后union
  //    使用zookeeper记录offset
  //doc:  http://spark.apache.org/docs/latest/streaming-kafka-0-8-integration.html
  def receiver_kafka(ssc: StreamingContext): Unit = {
    import org.apache.spark.streaming.kafka._
    import org.apache.spark.storage.StorageLevel

    // Map("test" -> 5)，指示将该topic的数据，写入到5个分区中，并不会提升并行度，只是增加了线程数
    // 如果已经启动了WriteAheadLog，就使用这个存储级别，如下
    val kafka = KafkaUtils.createStream(ssc,
      "192.168.36.10:2181/kafka", "spark_group", Map("test" -> 5),
      StorageLevel.MEMORY_AND_DISK_SER)

    // (null,it is a message)
    kafka.print
  }

  // 没有使用receiver，spark.streaming.receiver.*相关配置对此无效
  // 功能：
  //    1）可以指定每个batch获取的offset的长度；
  // 机制：
  //    1）并发简单：，每个topic的partition对应生成一个RDD
  //    2) 使用checkpoint记录offset，需要开启checkpoint
  // 说明
  //    1）这里使用的是旧api，kafka-consumer-groups.sh 无法查到offset
  //    2）需要使用kafka 0.8.2.1版本中的 StringDecoder
  //doc:      http://spark.apache.org/docs/latest/streaming-kafka-0-8-integration.html
  //example:  https://github.com/apache/spark/blob/v2.2.0/examples/src/main/scala/org/apache/spark/examples/streaming/DirectKafkaWordCount.scala
  def direct_kafka(ssc: StreamingContext): Unit = {
    import org.apache.spark.streaming.kafka._

    //kafka依赖关系：
    //    http://blog.csdn.net/dai451954706/article/details/50457334
    //    https://stackoverflow.com/questions/40076691/cant-acess-kafka-serializer-stringdecoder
    //    https://stackoverflow.com/questions/34145483/spark-streaming-kafka-stream?answertab=votes#tab-top
    //import kafka.serializer.StringDecoder
    import _root_.kafka.serializer.StringDecoder

    val kafkaParams = Map[String, String](
      "metadata.broker.list" -> broker,
      "bootstrap.servers" -> broker,
      "auto.offset.reset" -> "largest",
      "group.id" -> "spark_direct_group"
    )
    val stream = KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder](
      ssc, kafkaParams, Set("test")
    )
    stream.print()


    // 显示当前各partition的offset，这里记录其引用
    //    通常在foreachRDD之前执行转换操作成功后，后边foreachRDD中可以将数据记录在zookeeper中，方便其他工具的查看
    var offsetRanges = Array.empty[OffsetRange]
    stream.transform { rdd =>
      // 这里仅仅是获取 offsetRanges的句柄，而不做任何操作
      //此函数，必须是directKafkaStream中调用的第一个操作，才会生效
      offsetRanges = rdd.asInstanceOf[HasOffsetRanges].offsetRanges
      // 这里是在driver上执行的，输出线程id测试下
      // println(Thread.currentThread())   //Thread[JobGenerator,5,main]
      rdd
    }.foreachRDD { rdd =>
      for (o <- offsetRanges) {
        println(s"${o.topic} ${o.partition} ${o.fromOffset} ${o.untilOffset}")
      }
      // 这里是在driver上执行的
      // println(Thread.currentThread())  //Thread[streaming-job-executor-0,5,main]
    }
  }

  //http://blog.csdn.net/u010454030/article/details/54985740
  //http://blog.csdn.net/stark_summer/article/details/47666337
  //http://blog.csdn.net/a123demi/article/details/74935849
  //http://blog.csdn.net/duan_zhihua/article/details/51288057

  //doc:      http://spark.apache.org/docs/latest/streaming-kafka-0-10-integration.html
  //example:  https://github.com/apache/spark/blob/v2.2.0/examples/src/main/scala/org/apache/spark/examples/streaming/KafkaWordCount.scala
  def direct1_kafka(ssc: StreamingContext): Unit = {
    import org.apache.spark.streaming.kafka010._
    import org.apache.spark.streaming.kafka010.LocationStrategies.PreferConsistent
    import org.apache.spark.streaming.kafka010.ConsumerStrategies.Subscribe

    import org.apache.kafka.common.serialization.StringDeserializer
    val kafkaParams = Map[String, Object](
      "bootstrap.servers" -> broker,
      "key.deserializer" -> classOf[StringDeserializer],
      "value.deserializer" -> classOf[StringDeserializer],
      "group.id" -> "use_a_separate_group_id_for_each_stream",
      "auto.offset.reset" -> "latest",
      "enable.auto.commit" -> (false: java.lang.Boolean)
    )

    val topics = Array("test")
    val stream = KafkaUtils.createDirectStream[String, String](
      ssc, PreferConsistent,
      Subscribe[String, String](topics, kafkaParams)
    )

    stream.map(record => {
      record.value()
    }
    )
    stream.print()
  }
}

//https://community.hortonworks.com/questions/67921/kafka-spark-streaming-application-error-couldnt-fi.html
//https://stackoverflow.com/questions/34288449/spark-streaming-kafka-sparkexception-couldnt-find-leader-offsets-for-set