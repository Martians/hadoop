import java.io.File

import org.apache.spark._
import org.apache.spark.rdd.RDD
import org.apache.spark.serializer.Serializer

/*
val conf = new SparkConf().setMaster("local").setAppName("test")
val sc = new SparkContext(conf)

val input  = sc.parallelize(List((1, 2), (1, 3), (3, 4)))
val input2 = sc.parallelize(List((1, 3), (1, 2), (2, 4), (3, 5)))

sc.stop()
*/