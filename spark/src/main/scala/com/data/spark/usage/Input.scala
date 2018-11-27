
package com.data.spark.usage

import java.io.StringReader

import au.com.bytecode.opencsv.CSVReader
import com.data.util.Configure
import org.apache.spark._

object Input {

  def read_csv(): Unit = {
    val conf = new SparkConf().setMaster("local").setAppName("test")
    val sc = new SparkContext(conf)

    val path = Configure.getResource("/input.csv").getFile()

    val input = sc.textFile(path)
    val result = input.map {line =>
      val reader = new CSVReader(new StringReader(line));
      reader.readNext();
    }
    println("origin: ")
    input.collect().foreach(x => println("\t" + x))

    println("reader: ")
    result.collect().foreach(x => println("\t" + x))
  }

  def main(args: Array[String]): Unit = {
    read_csv()
  }
}