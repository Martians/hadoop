
package com.data.spark.sql

import com.data.spark.common._
import org.apache.spark.sql._
import org.apache.spark.sql.functions

object CarMatchingSQL {

  // use class, automate add column name; or use schema
  case class Car(hour: Int, time1: Int, car: String, loc: String)
  case class Tel(hour: Int, time2: Int, tel: String, loc: String)

  def main(args: Array[String]): Unit = {
    val env = new Enviroment(Array(), "outside/car_matching")
    logger.set(false)

    val spark = SparkSession.builder().master("local[4]")
      .appName("Spark SQL basic example")
      .config("spark.some.config.option", "some-value")
      .getOrCreate()

    import spark.implicits._

    // we use rdd to do some transfer first
    val car = spark.sparkContext.textFile(env.infile + "/car/car-2017-11-10.csv")
      .map(line => {
        val date = line.split(",")
        val time = date(0).split("[ :]")
        Car(time(1).toInt, time(1).toInt + time(2).toInt * 60, date(1), date(2))
      }).toDS()

    val tel = spark.sparkContext.textFile(env.infile + "/tel/tel-2017-11-10.csv")
      .map(line => {
        val date = line.split(",")
        val time = date(0).split("[ :]")
        //(date.length, time.length,time(0), time(1), time(2), time(3), date(0), date(1), date(2))
        Tel(time(1).toInt, time(1).toInt + time(2).toInt * 60, date(1), date(2))
      }).toDS()

/*
    +----+----+-------+-----+----+----+---------------+-----+-----+
    |hour|time|    car|  loc|hour|time|            tel|  loc|time2|
    +----+----+-------+-----+----+----+---------------+-----+-----+
*/
    //car.join(tel, car("hour") === tel("hour") && car("loc") === tel("loc")).printSchema()
    val res = car.join(tel, car("hour") === tel("hour") && car("loc") === tel("loc"))
    val data = res.select(res("time1") - res("time2") as "diff", res("car"), res("tel"))

    // Todo: not complete!
    if (false) {
      data.filter(row => {val diff = row.getAs[Int]("diff"); diff >= -60 && diff <= 60})
        .groupBy(res("car"), res("tel"))
        .count().orderBy($"count")
        .show()
    }

    // Todo: not complete!
    // http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.RelationalGroupedDataset
    if (true) {
      data.filter(row => {val diff = row.getAs[Int]("diff"); diff >= -60 && diff <= 60})
        //df.groupBy("department").agg($"department", max("age"), sum("expense"))
        .groupBy(res("car"), res("tel")).count()
        //.groupBy(res("car"), res("tel")).agg(car("car"), avg("count"))  // not work ?
        .groupBy(res("car"), res("tel")).agg("count" -> "sum")            //.sort("sum(count)")
        //.agg(Map("diff" -> "count"))  // in this way, agg not use groupby
        .show()
    }

    // Todo: not complete!
    if (true) {
      data.createOrReplaceTempView("result")
      spark.sql("select car, tel from result ")
    }
  }
}

/*

val format = new java.text.SimpleDateFormat ("yyyy-MM-dd HH:mm:ss")

case class Car(car_rpt: java.sql.Timestamp, car_no: String, car_station: String, car_hour: Integer)
case class Tel(tel_rpt: java.sql.Timestamp, tel_no: String, tel_station: String, tel_hour: Integer)

val carData = sc.textFile("hdfs://192.168.85.101:8020/user/ycq/car-2017-11-10.txt")
                .map(_.split(","))
                .map(attributes => Car(new java.sql.Timestamp(format.parse(attributes(0)).getTime), attributes(1), attributes(2),format.parse(attributes(0)).getHours()))
                .toDF()



val telData = sc.textFile("hdfs://192.168.85.101:8020/user/ycq/tel-2017-11-10.txt")
                .map(_.split(","))
                .map(attributes => Tel(new java.sql.Timestamp(format.parse(attributes(0)).getTime), attributes(1), attributes(2),format.parse(attributes(0)).getHours()))
                .toDF()

import org.apache.spark.sql.functions.udf
import java.sql.Timestamp
val timestamp_diff = udf((startTime: Timestamp, endTime: Timestamp) => {
  (startTime.getTime() - endTime.getTime())
})

val newData = carData.join(telData, carData("car_station") === telData("tel_station") && carData("car_hour") === telData("tel_hour"))
val withTimeDiff = newData.withColumn("timeDiff", timestamp_diff(col("car_rpt"), col("tel_rpt")))
withTimeDiff.select(col("timeDiff") < 300000)
withTimeDiff.show()
//withTimeDiff.write.format("csv").save("/tmp/hotspot.csv")

*
* */
