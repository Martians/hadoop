package com.data.bind;

import com.data.util.command.BaseOption;

public class ClientOption {

    public static class Global extends BaseOption {
        protected void initialize() {
            /**
             * bind type
             */
            addOption("bind",  "working bind", "Cassandra");
        }
    }

    public static class Workload extends BaseOption {
        protected void initialize() {
            /**
             * action
             *      write: random、input
             *      read：
             *          1) same seed with write
             *          2）input file with full data，also used for write
             *          3）input file with keys data，generate by scan
             */
            addOption("type",  "write、read、scan; load、generate", "write");

            addOption("total", "request count", 100000);
            addOption("thread",  "thread count", 10);
            addOption("batch",  "batch request", 100);
            addOption("read_thread",  "specific read thread", 0);

            /**
             * inner work
             */
            addOption("fetch",  "thread loop task count", 1000);
        }
    }

    public static class Generator extends BaseOption {
        protected void initialize() {

            addOption("seed",  "random seed",0);
            addOption("key_type",  "key type：rand、uuid、seq、table、fix", "rand");
            addOption("data_type",  "key type：rand、uuid、seq、table、fix", "rand");

            addOption("data_path", "data file path; if setted, output[generate、scan], input[load、read]", "");
            addOption("output.file_count", "min output file count", 1);
            addOption("output.file_size", "output file size (M)", "-1");
        }
    }

    public static class Table extends BaseOption {
        protected void initialize() {
            addOption("ks,keyspace",  "keyspace name", "test_space");
            addOption("ka,keyspace_auto",  "auto keyspace name to host name", false);
            addOption("tb,table", "table name", "test");

            addOption("replica", "replica count", 3);

            /**
             * read
             */
            addOption("read_empty",  "ignore empty updateFromCommandLine", 1000);
            addOption("dump_select",  "dump select message", false);

            /**
             * schema
             */
            addOption("schema", "table schema", "integer, String(4)[10]");
            //addOption("schema", "table schema", "integer, String(4)[10]<(9)>");
            //addOption("schema", "table schema", "integer, String(4)[10]<5-9>");
            //addOption("schema", "table schema", "integer, String(4)[10]<(1, 3), 5-9>");
            //addOption("schema", "table schema", "integer, String(4)[10]<(1, 3), 5-9>{3, 6-8}");
        }
    }
}
