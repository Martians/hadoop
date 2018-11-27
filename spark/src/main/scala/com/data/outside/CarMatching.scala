package com.data.outside

import com.data.spark.common._

//$SPARK_HOME/bin/spark-submit --class com.data.spark.CarMatching ./spark-0.0.1-SNAPSHOT.jar local file:///home/long/car_matching/

object CarMatching {

  def main(args: Array[String]): Unit = {
    // config time line abs range, which will be considered as match record pair
    val range = 10
    val mode = "join"
    //val sample = if (args.length > 5) false else true
    val sample = false

    val env = new Enviroment(args, "outside/car_matching")
    val sc = env.parse()
    logger.set(false)

    if (false) {
      if (mode == "cartesian") {
        //2017-11-10 17:14:49,鄂A834Q1,街道口
        var car = sc.textFile(env.infile + "/car/car-2017-11-10.csv")
          // convert 2017-11-10 10:16:16 to (hour * 60 + min)
          .map(line => {
          val date = line.split(",")
          val time = date(0).split("[ :]")
          (time(2).toInt * 60 + time(3).toInt, date(1), date(2))
        })

        var tel = sc.textFile(env.infile + "/tel/tel-2017-11-10.csv")
          .map(line => {
            val date = line.split(",")
            val time = date(0).split("[ :]")
            (time(2).toInt * 60 + time(3).toInt, date(1), date(2))
          })
        //car.take(10).foreach(println)
        //tel.take(10).foreach(println)

        if (sample) {
          car = car.sample(false, 0.01)
          tel = tel.sample(false, 0.01)
        }
        //.map(x => (x._1._1, x._1._2, x._1._3, x._2._1, x._2._2, x._2._3)).take(100).foreach(println)

        // filter
        //val pair = car.cartesian(tel).filter(x => (x._1._1 - x._2._1).abs <= range && x._1._3 == x._2._3)
        // .map(x => (x._1._2, x._2._2))  //.foreach(println)

        val data = car.cartesian(tel)
          .filter(x => (x._1._1 - x._2._1).abs <= range && x._1._3 == x._2._3) //.takeSample(false, 1000)
          .map(x => ((x._1._2, x._2._2), 1)).reduceByKey((x, y) => x + y)
        data.foreach(println)
      }
    }

    //2017-11-10 17:14:49,鄂A834Q1,街道口 -> (hour, time, car, location)
    var car = sc.textFile(env.infile + "/car/car-2017-11-10.csv")
      // convert 2017-11-10 10:16:16 to (hour * 60 + min)
      .map(line => {
        val date = line.split(",")
        val time = date(0).split("[ :]")
        //(date.length, time.length,time(0), time(1), time(2), time(3), date(0), date(1), date(2))
        (time(1).toInt, (time(1).toInt + time(2).toInt * 60, date(1), date(2)))
      })

    //2017-11-10 17:15:49,460003361231522,街道口 -> (hour, time, id, location)
    var tel = sc.textFile(env.infile + "/tel/tel-2017-11-10.csv")
      .map(line => {
        val date = line.split(",")
        val time = date(0).split("[ :]")
        (time(1).toInt, (time(1).toInt + time(2).toInt * 60, date(1), date(2)))
      })
    //car.take(10).foreach(println)
    //tel.take(10).foreach(println)
    if (sample) {
      car = car.sample(false, 0.01)
      tel = tel.sample(false, 0.01)
    }

    if (false) {
      // h, ((time, car, location), (time, id, location))
      car.join(tel).filter(x => (x._2._1._1 - x._2._2._1).abs <= range && x._2._1._3 == x._2._2._3)
        .map(x => (x._2._1._2, x._2._2._2))
        //.combineByKey(V => Map(V -> 1),
        //.map(x => (x, Map(x._2 -> 1)))
        .collect().foreach(println)
    }

    // h, ((time, car, location), (time, id, location))
    val data = car.join(tel)
      // time1 - time2 < 10s, loc1 = loc2
      .filter(x => (x._2._1._1 - x._2._2._1).abs <= range && x._2._1._3 == x._2._2._3)
      // ((car, id), 1) -> ((car, id), n)
      .map(x => ((x._2._1._2, x._2._2._2), 1)).reduceByKey((x, y) => x + y)

    //data.saveAsTextFile(env.output)
    data.foreach(println)
    sc.stop()
  }
}
