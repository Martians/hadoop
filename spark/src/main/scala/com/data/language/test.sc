
val input = "./data"
val input2 = "/data"
val input3 = "\\data"

input.matches("^[/.\\\\].*")
input2.matches("^[.\\\\].*")
input3.matches("^[/.\\\\].*")

val res = for (x <- 1 to 10) yield {
  (x, x + 10)
}
res.foreach(println)
Iterator(res).getClass.getName