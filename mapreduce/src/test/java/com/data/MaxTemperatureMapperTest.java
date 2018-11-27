package com.data;

import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Counter;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mrunit.mapreduce.MapDriver;
import org.junit.Test;

import java.io.IOException;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;


public class MaxTemperatureMapperTest {

    @Test
    public void processesValidRecord() throws IOException, InterruptedException {
        Text value = new Text("0043011990999991950051518004+68750+023550FM-12+0382" +
                "99999V0203201N00261220001CN9999999N9-00111+99999999999");

        new MapDriver<LongWritable, Text, Text, IntWritable>()
            .withMapper(new MaxTemperatureMapper())
            .withInput(new LongWritable(100), value)
            .withOutput(new Text("1950"), new IntWritable(-11))
            .runTest();
    }

    @Test
    public void parsesMissingTemperature() throws IOException,
            InterruptedException {
        Text value = new Text("0043011990999991950051518004+68750+023550FM-12+0382" +
                // Year ^^^^
                "99999V0203201N00261220001CN9999999N9+99991+99999999999");
        // Temperature ^^^^^
        new MapDriver<LongWritable, Text, Text, IntWritable>()
                .withMapper(new MaxTemperatureMapper())
                .withInput(new LongWritable(0), value)
                .runTest();
    }
    //vv MaxTemperatureMapperTestV4Malformed
    @Test
    public void parsesMalformedTemperature() throws IOException,
            InterruptedException {
        Text value = new Text("0335999999433181957042302005+37950+139117SAO  +0004" +
                // Year ^^^^
                "RJSN V02011359003150070356999999433201957010100005+353");
        // Temperature ^^^^^
        Counters counters = new Counters();
        new MapDriver<LongWritable, Text, Text, IntWritable>()
                .withMapper(new MaxTemperatureMapper())
                .withInput(new LongWritable(0), value)
                .withCounters(counters)
                .runTest();
        Counter c = counters.findCounter(MaxTemperatureMapper.Temperature.MALFORMED);
        assertThat(c.getValue(), is(1L));
    }
}