package com.data.client;

import com.datastax.driver.core.Cluster;

import java.text.SimpleDateFormat;
import java.util.List;

/**
 * example: https://github.com/jeffreyscarpenter/cassandra-guide
 *
 * api: https://docs.datastax.com/en/drivers/java/3.4/com/datastax/driver/core/BatchStatement.html
 */
public class A2_YugaByte {

    static void create_index() {

    }

    public static void main(String[] args) {
        try {
            Cluster cluster = Cluster.builder()
                    .addContactPoint("192.168.10.111")
                  //.withInitialListeners(list)
                  //.withPoolingOptions(poolingOptions)
                    .build();

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
        }
    }
}
