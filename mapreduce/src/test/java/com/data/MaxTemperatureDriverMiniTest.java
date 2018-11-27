package com.data;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileUtil;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.PathFilter;
import org.apache.hadoop.mapred.ClusterMapReduceTestCase;
import org.junit.Ignore;
import org.junit.Test;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.junit.Assert.assertThat;

// A test for MaxTemperatureDriver that runs in a "mini" HDFS and MapReduce cluster
public class MaxTemperatureDriverMiniTest extends ClusterMapReduceTestCase {

  public static class OutputLogFilter implements PathFilter {
    public boolean accept(Path path) {
      return !path.getName().startsWith("_");
    }
  }

  @Override
  protected void setUp() throws Exception {
    if (System.getProperty("test.build.data") == null) {
      System.setProperty("test.build.data", "/tmp");
    }
    if (System.getProperty("hadoop.log.dir") == null) {
      System.setProperty("hadoop.log.dir", "/tmp");
    }
    super.setUp();
  }

  @Ignore
  @Test
  // Not marked with @Test since ClusterMapReduceTestCase is a JUnit 3 test case
  public void test() throws Exception {
    Configuration conf = createJobConf();

    Path localInput = new Path("../data/definitive_guide/ncdc/micro");
    Path input = getInputDir();
    Path output = getOutputDir();

    // Copy input data into test HDFS
    getFileSystem().copyFromLocalFile(localInput, input);

    MaxTemperatureDriver driver = new MaxTemperatureDriver();
    driver.setConf(conf);

    int exitCode = driver.run(new String[] {
        input.toString(), output.toString() });
    assertThat(exitCode, is(0));

    // Check the output is as expected
    Path[] outputFiles = FileUtil.stat2Paths(
        getFileSystem().listStatus(output, new OutputLogFilter()));
    assertThat(outputFiles.length, is(1));

    InputStream in = getFileSystem().open(outputFiles[0]);
    BufferedReader reader = new BufferedReader(new InputStreamReader(in));
    assertThat(reader.readLine(), is("1949\t111"));
    assertThat(reader.readLine(), is("1950\t22"));
    assertThat(reader.readLine(), nullValue());
    reader.close();
  }
}
