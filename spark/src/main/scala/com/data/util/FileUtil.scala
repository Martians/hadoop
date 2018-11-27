package com.data.util

import java.io.{File, FileSystem => _}

import org.apache.hadoop.fs._

object FileUtil {

  def deleteDir(dir: File): Unit = {
    if (dir.exists()) {
      val files = dir.listFiles()
      files.foreach(f => {
        if (f.isDirectory) {
          deleteDir(f)
        } else {
          f.delete()
          println("delete file " + f.getAbsolutePath)
        }
      })
      dir.delete()
      println("delete dir " + dir.getAbsolutePath)
    }
  }

  def hdfsDelete(path: String) {
    val master = """hdfs://[^/]*""".r
    val hdfs = org.apache.hadoop.fs.FileSystem.get(new java.net.URI(master.findFirstIn(path).get),
      new org.apache.hadoop.conf.Configuration())

    val dir = new Path(path)
    if (hdfs.exists(dir)) {
      hdfs.delete(dir, true)
      println("remove " + dir)
    }
  }
}