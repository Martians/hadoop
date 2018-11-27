
// Learning_Spark
import AssemblyKeys._

name := "spark"

version := "0.1"

scalaVersion := "2.11.8"

// 真正submit时使用此选项
//libraryDependencies += {
//  "org.apache.spark" % "spark-core_2.11" % "2.2.0" % "provided"
//  "org.apache.spark" % "spark-sql_2.11" % "2.2.0" % "provided"
//}
libraryDependencies += {
  "org.apache.spark" % "spark-core_2.11" % "2.2.0"
  "org.apache.spark" % "spark-sql_2.11" % "2.2.0"
}

// https://mvnrepository.com/artifact/au.com.bytecode/opencsv
libraryDependencies += "au.com.bytecode" % "opencsv" % "2.4"

// 这条语句打开了assembly插件的功能
assemblySettings
// 配置assembly插件所使用的JAR
jarName in assembly := "WordCount.jar"
// 一个用来把Scala本身排除在组合JAR包之外的特殊选项，因为Spark
// 已经包含了Scala
assemblyOption in assembly :=
  (assemblyOption in assembly).value.copy(includeScala = false)
