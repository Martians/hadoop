package com.data.spark.sql

import com.data.spark.common._
import org.apache.spark.sql._
import org.apache.spark.sql.types._

// api:     http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.Dataset
//          http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.functions$
//          http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.Column
//          http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.Row
// reader:  http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.DataFrameReader
// example: https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/sql/SparkSQLExample.scala
//          https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/sql/SQLDataSourceExample.scala
object SQLExample {

  val env = new Enviroment(Array(), "sql")
  val path = env.infile + "/people.json"
  val path_txt = env.infile + "/people.txt"
  logger.set(false)

  case class Person(name: String, age: Long, id: Long = 0)
  case class Salary(name: String, salary: Long, id: Long = 0)

  def main(args: Array[String]): Unit = {
    logger.set(false)

    val spark = SparkSession.builder().master("local[4]")
      .appName("Spark SQL basic example")
      .config("spark.some.config.option", "some-value")
      .getOrCreate()
    //spark.sparkContext.setLogLevel("OFF") // ERROR, ALL, OFF

    f1_operation(spark)
    if (false) {
      f0_dataframe(spark) // normal
      Thread.sleep(10000)

      f0_frame_stat(spark)
      Thread.sleep(10000)
    }

    if (false) {
      f1_column_row(spark)  // column and row
      Thread.sleep(10000)

      f0_data_source(spark) // load data source
      f0_data_schema(spark) // show data schema
    }

    if (false) {
      f1_operation(spark)
    }

    println("save and complete ...")
    Thread.sleep(10000)
  }

  def f0_dataframe(spark: SparkSession) {
    import spark.implicits._

    val df = spark.read.json(path)
    //    root
    //    |-- age: long (nullable = true)
    //    |-- name: string (nullable = true)
    df.printSchema()
    df.show()

    println("\n" + "first row:")
    val row = df.first()
    println(row(0) + "," + row.getAs[String]("name"))
    // 显示生成一个，包括显示统计信息的RDD
    if (false) {
      //    +-------+------------------+-------+
      //    |summary|               age|   name|
      //    +-------+------------------+-------+
      //    |  count|                 2|      3|
      //    |   mean|              24.5|   null|
      //    | stddev|7.7781745930520225|   null|
      //    |    min|                19|   Andy|
      //    |    max|                30|Michael|
      //    +-------+------------------+-------+
      df.describe().show()
    }

    // 1）指定显示多个column的信息，实际上内部调用的是 select(cols: Column*)，string转换为column
    println("\n" + "select (name, age + 2):")
    df.select($"name", $"age" + 2).show()

    // 显示单个column
    println("\n" + "show column:")
    df.select("name").show

    // 2) 使用转换、行动语句
    println("\n" + "groupBy name, use count:")
    df.groupBy("name").count().show()
    df.filter($"age" > 21).show()


    // 3) 执行sql语句
    println("\n" + "create view, select *")
    df.createOrReplaceTempView("people")
    val sqlDF = spark.sql("select * from people")
    sqlDF.show()

    println("\n" + "create global view, select *")
    df.createGlobalTempView("people2")
    spark.sql("select * from global_temp.people2").show()

    println("\n" + "create new session:")
    spark.newSession().sql("SELECT * FROM global_temp.people2").show()
  }

  def f1_column_row(spark: SparkSession) {
    import spark.implicits._

    val df = spark.read.json(path)
    // 返回column类型：df.col("name") df("name")
    println("\n" + "print select column：")
    df.select(df("name"), df.col("age") + 2).show()

    // 转换row
    println("\n" + "DataFrame map, each is a row:")
    df.map(row => "name: " + row(1)).show
    // 使用name索引列
    df.map(row => "name: " + row.getAs[String]("name")).show

    // 列改名，增加列
    df.withColumnRenamed("name", "ppp").withColumn("createed", $"ppp").show()
  }

  def f0_frame_stat(spark: SparkSession) {
    import spark.implicits._

    val df = spark.read.json(path)
    //StructType(StructField(age,LongType,true), StructField(name,StringType,true))
    println(".shcema: \n" + df.schema)
/*
    root
    |-- age: long (nullable = true)
    |-- name: string (nullable = true)
    */
    println("print shcema")
    df.printSchema

    println(".column: \n")
    df.columns.foreach(println)
/*
    (age,LongType)
    (name,StringType)
    */
    println(".dtypes: \n")
    df.dtypes.foreach(println)

    println(".stat: \n")
    //df.stat
  }

  def f0_data_source(spark: SparkSession) {
    import spark.implicits._

    // 1) get DataSet[String]
    val data = spark.read.format("json").load(path)
    data.select("*").show()

    // 2) shortcut for read.format("json")
    val data2 = spark.read.json(path)
    data.select("*").show()

    // 3) load and show data directly from file
    spark.sql("select * from json.`" + path + "`").show
  }

  def f0_data_schema(spark: SparkSession) {
    import spark.implicits._

    // 1) 1.1从内存中的集合，创建DataSet
    Seq(Person("long", 35), Person("mate", 11)).toDS().show()
    //    1.2 方式
    Seq(("long", 35), ("mate", 11)).toDF("name", "age").show()
    //    1.3 连接在一起
    spark.createDataset(Seq(
      ("aaa",1,2),("bbb",3,4),("ccc",3,5),("bbb",4, 6))).toDF("key1","key2","key3").show()

    // 2) create dataset, use “as” to convert to a new DataSet
    val data2 = spark.read.format("json").load(path).as[Person]
    data2.select("*").show()

    // 3) create from RDD, RDD[Person]
    val peopleDF = spark.sparkContext.textFile(path_txt)
      .map(_.split(",")).map(x => Person(x(0), x(1).trim().toInt))
      .toDS()    //toDF() is ok
    peopleDF.createOrReplaceTempView("people")
    val teeangers = spark.sql("select * from people where age between 12 and 19")
    teeangers.map(x => "name: " + x(0)).show()

    // 4) specific schema, first get RDD[row], row
    val peopleRDD = spark.sparkContext.textFile(path_txt)
      .map(_.split(",")).map(x => Row(x(0), x(1).trim()))

    val schemaString = "name age"
    val fields = schemaString.split(" ").map(x => StructField(x, StringType, true)) // create struct fileds array
    val schema = StructType(fields)
    val peopleDF2 = spark.createDataFrame(peopleRDD, schema)  // attach rdd with schema

    // 5) assign dataset
    val data3 = Seq(Person("long", 35), Person("mate", 11)).toDS()
    val peopleDF3 = data3.toDF("name", "age").show()

  }

  //https://www.cnblogs.com/hadoop-dev/p/6742677.html
  def f1_operation(spark: SparkSession) {
    val data = spark.read.format("json").load(path)
    import spark.implicits._

    println("using condition:")
    data.filter(row => row.getAs[Long]("age") > 20).show()
    data.filter("age > 20 and name='Andy'").show()      // sql like
    data.where("age > 20").show()       // sql like

    // 连接的时候，不能对字段重命名
    println("join example:")
    val person = Seq(Person("long", 35, 1),  Person("tom", 40, 2), Person("mate", 11, 3)).toDS()
    val salary = Seq(Salary("long", 100, 1), Salary("mate", 50, 3), Salary("nick", 70, 2), Salary("long", 50, 3), Salary("mate", 90, 4)).toDS()

    if (false) {
      // 1) 连接测试
      // 使用一个字段连接
      /*
      +----+---+---+------+---+
      |name|age| id|salary| id|
      +----+---+---+------+---+
      |long| 35|  1|   100|  1|
      |mate| 11|  3|    50|  2|
      +----+---+---+------+---+*/
      person.join(salary, "name").show()

      // 使用两个个字段连接
      /*
      +----+---+---+------+
      |name| id|age|salary|
      +----+---+---+------+
      |long|  1| 35|   100|
      |mate|  3| 11|    50|
      +----+---+---+------+*/
      person.join(salary, Seq("name", "id")).show()

      // 设置多个连接条件
      val ps = person.join(salary,
        person("name") === salary("name") && person("id") === salary("id")).show()
    }

    import org.apache.spark.sql.functions._
    val df = person.join(salary, person("name") === salary("name"))
    df.show()

    // 2）进行聚合操作, groupBy相当于Key，并且会在结果列中显示出来
    //http://blog.csdn.net/coding_hello/article/details/75136902
    if (true) {
      println("groupBy and agg: ")
      df.groupBy(person("name")).agg("salary" -> "avg", "age" -> "max").show
      df.groupBy(person("id"), person("name")).agg("salary" -> "avg", "age" -> "max").show
      df.groupBy(person("id"), person("name")).agg(Map("salary" -> "avg", "age" -> "max")).show
      //df.groupBy(person("id")).agg(max("age"), sum("expense"))

      //  2.2 聚合时，为了在结果显示的原始列（如：salary，但是不进行相关聚合操作的列），必须是前边groupBy已经指定的列
      //    expression '`salary`' is neither present in the group by, nor is it an aggregate function. Add to group by or wrap in first() (or first_value) i
      df.groupBy(person("name"), $"salary").agg($"salary", max("salary"), count("salary")).show

      //  2.3 group后排序 ！！！！
      println("groupBy and sort: ")
      df.groupBy(person("name"), $"salary").agg($"salary", max("salary"), count("salary"))
        .sort(person("name").desc, $"salary".desc).show

      println("groupBy and simple sort: ")
      df.groupBy(person("name"), $"salary").agg($"salary", max("salary"), count("salary"))
        .sort("salary").show

      // 2.4 group、count、别名
      println("groupBy and count as: ")
      df.groupBy(person("name")).agg(count("salary").as("money")).show()
    }

    if (false) {
      // 3）select 更多操作
      //    3.1 简单操作
      df.select(person("name"), salary("salary") as "cctv").show
      //    3.2 表达式操作
      df.select(expr("salary"), salary("salary") as "cctv", expr("abs(salary)")).show
      df.selectExpr("age", "salary as cctv", "abs(salary)").show
    }
  }
}
