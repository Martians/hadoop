package com.data;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.*;
import org.apache.hadoop.mapred.OutputLogFilter;
import org.junit.Assert;
import org.junit.Test;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;

public class MaxTemperatureDriverTest {
    @Test
    public void test() throws Exception {
        Configuration conf = new Configuration();
        conf.set("fs.defaultFS", "file:///");
        conf.set("mapreduce.framework.name", "local");
        conf.setInt("mapreduce.task.io.sort.mb", 1);

        Path input = new Path("../data/definitive_guide/ncdc/micro");
        Path output = new Path("output");
        FileSystem fs = FileSystem.getLocal(conf);
        fs.delete(output, true); // delete old output

        MaxTemperatureDriver driver = new MaxTemperatureDriver();
        driver.setConf(conf);
        int exitCode = driver.run(new String[] {
                input.toString(), output.toString() });
        assertThat(exitCode, is(0));
        checkOutput(conf, output);
    }

    private void checkOutput(Configuration conf, Path output) throws IOException {
        FileSystem fs = FileSystem.getLocal(conf);
        Path[] outputFiles = FileUtil.stat2Paths(
                fs.listStatus(output, new OutputLogFilter()));
        Assert.assertThat(outputFiles.length, is(2));

        BufferedReader actual = asBufferedReader(fs.open(outputFiles[0]));
        BufferedReader expected = asBufferedReader(
                getClass().getResourceAsStream("/expected.txt"));
        String expectedLine;
        while ((expectedLine = expected.readLine()) != null) {
            Assert.assertThat(actual.readLine(), is(expectedLine));
        }
        Assert.assertThat(actual.readLine(), nullValue());
        actual.close();
        expected.close();
    }

    private BufferedReader asBufferedReader(InputStream in) throws IOException {
        return new BufferedReader(new InputStreamReader(in));
    }
}
