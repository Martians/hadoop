
package com.data.cassendra

import com.data.spark.common._
import org.apache.spark.{SparkConf, SparkContext}
import com.datastax.spark.connector.cql.CassandraConnector

object cassandra {

  def prepared(sc: SparkContext) = {
    /**
      * 纯 Cassandra client 操作
      *
      * withSessionDo 安全的全局使用的 session，是一个单例的代理，无人使用时会自动回收
      * 对应于存在一个Cluster、一个Session
      */
    CassandraConnector(sc.getConf).withSessionDo { session =>
      session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1 }")
      session.execute("CREATE TABLE IF NOT EXISTS test.words (key INT PRIMARY KEY, value VARCHAR)")
      session.execute("TRUNCATE test.words")
      session.execute("INSERT INTO test.words(key, value) VALUES (1, 'first row')")
      session.execute("INSERT INTO test.words(key, value) VALUES (2, 'second row')")
      session.execute("INSERT INTO test.words(key, value) VALUES (3, 'third row')")
    }
  }

  def command(sc: SparkContext) = {
    import com.datastax.spark.connector._
    println("wait to get cassandra table: ")

    /**
      * rdd类型是 CassandraRDD[CassandraRow]
      */
    val rdd = sc.cassandraTable("test", "words").select("key", "value")
    rdd.collect().foreach(row => println(s"Existing data: $row"))

    /**
      * 解析返回值
      *
      * 使用 Option：
      *   firstRow.getIntOption("count")
      *   firstRow.get[Option[Int]]("count")
      *
      * 类型是集合
      *   row.get[List[String]]("emails")
      */
    val first = rdd.first()
    //http://docs.scala-lang.org/zh-cn/overviews/core/string-interpolation.html
    println(s"type: ${first.columnValues}, ${first.getInt("key")} -> ${first.get[String](1)}")

    println("\nwait to get cassandra table and convert: ")
    /**
      * 转换为 tuple 类型来使用
      * https://github.com/datastax/spark-cassandra-connector/blob/master/doc/4_mapper.md
      *
      * 甚至可以：
      *   case class WordCount(word: String, count: Int)
      *   sc.cassandraTable[WordCount]("test", "words").toArray
      *
      * 可以获得 TTL、write time:
      */
    //val rdd2 = sc.cassandraTable[(String, Int)]("test", "words").select("key", "value")
  }

  def joinTable(sc: SparkContext): Unit = {
    import com.datastax.spark.connector._
    println("\nwait to join table: ")
    /**
      * Join相关：
      *   repartitionByCassandraReplica，数据重分布，满足 Table 策略，更好的支持join
      *   有相同两个PartitonKey的Table可以Join，
      *       sc.cassandraTable("test","customer_info").joinWithCassandraTable("test","shopping_history")
      */

    /**
      * 指定隐含的read策略：implicit val readConf = ReadConf(100,100)
      */
  }

  def selectClause(sc: SparkContext): Unit = {
    import com.datastax.spark.connector._
    println("\nwait to select clause: ")

    /**
      * 带有where条件: https://github.com/datastax/spark-cassandra-connector/blob/master/doc/3_selection.md
      *
      *  withAscOrder or withDescOrder
      *  perPartitionLimit
      *
      *  Grouping rows by partition key，必须按照PrimaryKey的连续前缀进行分组
      *     Cassandra partition不会跨越多个 Spark partition
      *     spanBy or spanByKey
      */
    println("\nwait select and where: ")
    val rdd3 = sc.cassandraTable("test", "words")
      .select("key", "value")
      .where("key = ?", "1")

    println(s"size: ${rdd3.collect().size}")
  }

  /**
    * https://github.com/datastax/spark-cassandra-connector/blob/master/doc/5_saving.md
    */
  def saveData(sc: SparkContext): Unit = {
    import com.datastax.spark.connector._
    println("\nwait to save data: ")

    /**
      * 存储的必须是tuple，或者有class属性与表的列一致
      *
      * 下边演示的是存储tuple
      */
    val collection1 = sc.parallelize(Seq((30, "cat"), (40, "fox")))
    collection1.saveToCassandra("test", "words", SomeColumns("key", "value"))

    val collection2 = sc.parallelize(Seq(("cat2", 35), ("fox2", 46)))
    collection2.saveToCassandra("test", "words", SomeColumns("key" as "_2", "value" as "_1"))

    /**
      * 存储class, 假设列名为：workd、num
      *   case class WordCount(word: String, count: Long)
      *   val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
      *   collection.saveToCassandra("test", "words2", SomeColumns("word", "num" as "count"))
      */

    /**
      * 将rdd存储到，某一个row对应的一个类型为 collection 的 column 中
      * 使用集合，存储到list之前、之后
      *   listElements.saveToCassandra("ks", "collections_mod", SomeColumns("key", "lcol" append))
      */

    /**
      * 存储Table中的 UDT：
      *   CREATE TYPE test.address (city text, street text, number int);
      *   CREATE TABLE test.companies (name text PRIMARY KEY, address FROZEN<address>);
      *
      * 新建一个class与之对应起来
      *   case class Address(city: String, street: String, number: Int)
      */

    /**
      * 指定TTL、WriteTime
      *   rdd.saveToCassandra("test", "tab", writeConf = WriteConf(ttl = TTLOption.constant(100)))
      *   rdd.saveToCassandra("test", "tab", writeConf = WriteConf(timestamp = TimestampOption.constant(ts)))
      **/

    /**
      * 列不存在时存储
      *   rdd.saveToCassandra("test", "tab", writeConf = WriteConf(ifNotExists = true))
      */

    /**
      * 直接保存到新的Table中去
      *
      * 注意：
      *     这里类 WordCount 的定义，必须在函数之外
      *     默认 word 是 PrimaryKey
      *
      * 使用 saveAsCassandraTableEx，可以另外定义表结构
      */
    val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
    collection.saveAsCassandraTable("test", "words_new", SomeColumns("word", "count"))
  }
  case class WordCount(word: String, count: Long)

  def deleteData(sc: SparkContext): Unit = {
    import com.datastax.spark.connector._
    println("\nwait to delete data: ")

    /**
      * 根据where条件，选择要删除的行
      *
      * sc.cassandraTable("test", "word_groups")
          .where("count < 10")
          .deleteFromCassandra("test", "word_groups")
      */

    /**
      * 根据传入的rdd对应的数据，选择要删除的行
      *
      * sc.parallelize(Seq(("animal", "trex"), ("animal", "mammoth")))
          .deleteFromCassandra("test", "word_groups")
      */

    /**
      * 删除指定的列
      *
      * sc.parallelize(Seq(("animal", "mammoth")))
          .deleteFromCassandra("test", "word_groups", SomeColumns("count"))
      */
  }

  def streaming(sc: SparkContext): Unit = {
    /**
      * https://github.com/datastax/spark-cassandra-connector/blob/master/doc/8_streaming.md
      */
  }

  def dataset(sc: SparkContext): Unit = {
    /**
      * https://github.com/datastax/spark-cassandra-connector/blob/master/doc/14_data_frames.md
      */
  }




  def main(args: Array[String]): Unit = {

    import org.apache.log4j.{Level, Logger}
    Logger.getRootLogger().setLevel(Level.ERROR) // Level.ERROR

    /**
      * readme: https://github.com/datastax/spark-cassandra-connector/blob/master/doc/1_connecting.md
      * config: https://github.com/datastax/spark-cassandra-connector/blob/master/doc/reference.md#cassandra-connection-parameters
      */
    val conf = new SparkConf(true).setMaster("local[4]").setAppName("cassandra_test").set("spark.logConf", "false")
            .set("spark.cassandra.connection.host", "192.168.10.111")
            //.set("spark.cassandra.auth.username", "cassandra")
            //.set("spark.cassandra.auth.password", "cassandra")

    val sc = new SparkContext(conf)

    if (true) {
      prepared(sc)

      command(sc)

      joinTable(sc)

      selectClause(sc)

      saveData(sc)
    }

    deleteData(sc)

    streaming(sc)

    dataset(sc)

    sc.stop()
  }
}
