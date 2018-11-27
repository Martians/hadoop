
package com.data.language

object Collection {

  def map_work() {
      val a = Map("a" -> 1, "2" -> 3, "b" -> 5)
      val d = a - "a" + ("b" -> 3)
      println("map dec inc: ")
      d.foreach(x => println("\t" + x))

      if (a.contains("2")) {
        val c = a.get("2").get
        val b = a - "2" + ("2" -> (c + 1))
        println("map inc value: ")
        b.foreach(x => println("\t" + x))

      } else {
        println("nothing")
      }
  }

  def yield_iterator() {
    val res = for (x <- 1 to 10) yield {
      (x, x + 10)
    }
    res.foreach(println)
    res.getClass.getName
  }

  def main(args: Array[String]): Unit = {
    //map_work()

    yield_iterator()

  }
}
