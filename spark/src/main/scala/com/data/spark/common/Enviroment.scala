package com.data.spark.common

import java.io.File

import com.data.util.{Configure, FileUtil}
import org.apache.spark.{SparkConf, SparkContext}

class Enviroment(args: Array[String]=Array(), input: String="README.md", jar: String="", name: String="my app") {

    val master = if (args.length > 0) args(0) else "local[4]"

    // use 1) sample data, 2) large data 3) specific data
    val infile =
      if (args.length > 1) {
        println("using specific data [" + args(1) + "]")
        args(1)
      } else {
        locate(input)
      }

    val output = if (args.length > 2) args(2) else "./output"
    val apname = if (args.length > 3) args(3) else name

    //使用相对路径，自动定位到resource/data目录下
    //  使用绝对路径，则使用最外层的data目录
    def locate(input: String) = {
      // path as ../data or /home/long
      if (input.matches("^[/.\\\\].*")) {
        println("using testing data [" + input + "]")
        input
      } else {
        println("using simple data [" + input + "]")
        Configure.getResource("/data/" + input).getFile()
      }
    }

    def prepare(user: String = "long"): Unit = {
      System.setProperty("HADOOP_USER_NAME", user)

      println("remove old directory: " + output)
      if (infile.contains("hdfs")) {
        FileUtil.hdfsDelete(output)
      } else {
        FileUtil.deleteDir(new File(output))
      }
    }

    def parse(user: String="long") = {
      prepare(user)

      val conf = new SparkConf().setMaster(master).setAppName(apname).set("spark.logConf", "true")
      val sc = new SparkContext(conf)
      //.set("spark.executor.memory", "500m")//.set("spark.executor.cores", "1")//.set("spark.total.executor.cores", "4")
      //.set("spark.submit.deployMode", "cluster")
      depend(sc)

      sc
    }

    def depend(sc: SparkContext) = {
      if (master != "local" && jar != "") {
        //conf.setJars(List("./target/scala-2.11/WordCount.jar"))
        val jar1 = "./target/scala-2.11/" + jar // created by sbt
        val jar2 = "./classes/artifacts/spark_jar/" + jar // created by idea

        if (new File(jar1).exists()) {
          sc.addJar(jar1)
        } else if (new File(jar2).exists()) {
          sc.addJar(jar2)
        }
      }
    }
}

object logger {
  // must set log4j.properties, this will work
  // https://stackoverflow.com/questions/27781187/how-to-stop-messages-displaying-on-spark-console
  // https://stackoverflow.com/questions/14024756/slf4j-class-path-contains-multiple-slf4j-bindings
  def set(start_logger: Boolean = true): Unit = {

    /*
    import org.apache.log4j.{Level, Logger}
    import org.apache.spark.internal.Logging
    if (Logger.getRootLogger.getAllAppenders.hasMoreElements) {
    }
    */
    if (!start_logger) {
      // this method will still output some message, output work before spark context
      //sc.setLogLevel("OFF") // ERROR, DEBUG, ALL, OFF
      import org.apache.log4j.{Level, Logger}
      Logger.getRootLogger().setLevel(Level.ERROR) // Level.ERROR
    }
  }
}
