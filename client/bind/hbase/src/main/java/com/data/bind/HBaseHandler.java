package com.data.bind;

import com.data.util.data.source.DataSource;
import com.data.util.schema.DataSchema;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.ConcurrentModificationException;

/**
 * 配置：
 *      本地dns要配置好
 *
 * docker：
 *      https://github.com/HariSekhon/Dockerfiles/tree/master/hbase
 *      cd /mnt/hgfs/local/Dockerfiles/hbase/; docker-compose up
 *      master: http://192.168.10.10:16010
 *      region: http://192.168.10.10:16030
 *
 * shell:
 *      https://learnhbase.wordpress.com/2013/03/02/hbase-shell-commands/
 *      https://blog.csdn.net/qq_806913882/article/details/53556371
 * api：
 *      例子：http://hbase.apache.org/book.html#_examples
 *      教程：https://www.w3cschool.cn/hbase_doc/
 *      https://www.cnblogs.com/liuwei6/p/6842536.html
 *      https://blog.csdn.net/liuwenbo0920/article/details/49951965
 *
 *      1.2 http://hbase.apache.org/1.2/apidocs/index.html
 *
 * ycsb：
 *      bin/ycsb run hbase12 -s -threads 10 -P workloads/workloada -p table=t3 -p columnfamily=cf3 -p durability=ASYNC_WAL -p clientbuffering=true
 */
public class HBaseHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
            /**
             * Hbase
             */
            addOption("cf,column_family", "column family name", "test");
            addOption("wal_sync",  "wal sync mode or async", false);
            addOption("client_buffer",  "client request buffer (M)", 0);
        }
    }

    protected Configuration config = HBaseConfiguration.create();
    private static Connection connection = null;
    private static Admin admin = null;
    private TableName tableName = null;

    /**
     * 必须设置为线程变量，才能利用连接池
     */
    static final ThreadLocal<Table> table = new ThreadLocal<>();

    /**
     * ASYNC_WAL、SYNC_WAL、FSYNC_WAL、SKIP_WAL、USE_DEFAULT
     */
    private Durability durability = null;
    private BufferedMutator bufferedMutator = null;

    /**
     * 保存中间状态数据，减少重复
     */
    private byte[] columnFamilyBytes;

    @Override
    public void initialize() {
        try {
            resolveParam();

            connecting();

            preparing();

            construct();

        } catch (Exception e) {
            log.warn("initialize error: {}", e);
            System.exit(-1);
        }
    }

    public void threadWork() {
        try {
            table.set(connection.getTable(tableName));

        } catch (IOException e) {
            log.warn("thread work error: {}", e);
            System.exit(-1);
        }
    }

    @Override
    public void terminate() {
        try {
            if (bufferedMutator != null) {
                log.info("ternimate, try to close buffer ...");
                bufferedMutator.close();
                bufferedMutator = null;
            }

            if (table.get() != null) {
                table.get().close();
                table.set(null);
            }
            if (connection != null) {
                connection.close();
                connection = null;
            }

        } catch (IOException e) {
            log.warn("terminate error: {}", e);
            System.exit(-1);
        }
    }

    public String dumpLoad() {
        return String.format("tableName: %s.%s", command.get("table.keyspace"), command.get("table.table"));
    }

    protected void resolveParam() {
        config.set("hbase.zookeeper.quorum", command.get("host"));
        //config.command("hbase.zookeeper.property.clientPort", "5181");
        //config.addResource("hbase-site.xml");

        durability = command.getBool("wal_sync") ?
                Durability.SYNC_WAL: Durability.ASYNC_WAL;

        resolveMore();
    }

    /**
     * used in maprdb
     */
    protected void resolveMore() {
    }

    /**
     * 如何设置线程池
     */
    protected void connecting() {

        try {
            connection = ConnectionFactory.createConnection(config);
            admin = connection.getAdmin();

        } catch (IOException e) {
            log.error("connecting failed, {}", e);
            System.exit(-1);
        }
    }

    protected void preparing() {
        tableName = TableName.valueOf(command.get("table.table"));

        try {
            boolean create = false;
            if (admin.tableExists(tableName)) {
                if (command.isRead()) {
                    log.info("current mode is read, ignore clear keyspace");

                } else if (command.getBool("clear")) {
                    log.info("table exist, try to delete table");
                    admin.disableTable(tableName);
                    admin.deleteTable(tableName);
                    create = true;
                }
            } else {
                create = true;
            }

            if (create) {
                HTableDescriptor tableDesc = new HTableDescriptor(tableName);
                tableDesc.setDurability(durability);
                //.setCompressionType(Algorithm.NONE));

                HColumnDescriptor columnDesc = new HColumnDescriptor(command.get("column_family"));
                //.setTimeToLive(5184000)
                //.setMinVersions(5)

                tableDesc.addFamily(columnDesc);
                admin.createTable(tableDesc);
            }

        } catch (IOException e) {
            log.error("preparing failed, {}", e);
            System.exit(-1);
        }
    }

    protected void construct() {
        columnFamilyBytes = Bytes.toBytes(command.get("column_family"));

        try {
            int buffer_size = command.getInt("client_buffer") * 1024;
            if (buffer_size > 0) {
                final BufferedMutatorParams p = new BufferedMutatorParams(tableName);
                p.writeBufferSize(buffer_size);
                bufferedMutator = connection.getBufferedMutator(p);
            }
        } catch (IOException e) {
            log.error("construct failed, {}", e);
            System.exit(-1);
        }
    }

    protected void createIndex() {
        //List<String> list = command.schema.createIndex(command.get("tableName"));
        //int index = 0;
        //for (String statement : list) {
        //    executeStatment(statement,
        //            "create index " + index++);
        //}
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * mutations
     **/
    public int write(int[] result, int batch) {

        for (int i = 0; i < batch; i++) {
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("write get null, completed");
                return -1;
            }

            result[0] += 1;
            result[1] += wrap.size;

            DataSchema schema = command.schema;
            int index = 0;

            Put put = new Put(Bytes.toBytes((String) wrap.array[0]));
            put.setDurability(durability);

            for (DataSchema.Item s : schema.list) {
                if (index > 0) {
                    put.addColumn(columnFamilyBytes,
                            Bytes.toBytes(schema.tableClumnPrefix(index)),
                            Bytes.toBytes((String) wrap.array[index]));
                }
                index++;
            }

            try {

                if (bufferedMutator != null) {
                    bufferedMutator.mutate(put);

                } else {
                    //long start = System.nanoTime();
                    table.get().put(put);
                    //log.info("-- {}", (System.nanoTime() - start)/1000000);
                }

            } catch (IOException e) {
                log.error("write failed, {}", e);
                System.exit(-1);

            } catch (ConcurrentModificationException e) {
                log.error("concurrent write failed, {}", e);
                System.exit(-1);
            }
        }

        return 1;
    }


    public int read(int[] result, int batch) {
        for (int b = 0; b < batch; b++) {

            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("read get null, completed");
                return -1;
            }

            Get get = new Get(Bytes.toBytes((String) wrap.array[0]));
            get.addFamily(columnFamilyBytes);
            Result r = null;

            try {
                r = table.get().get(get);

            } catch (IOException e) {
                log.error("read failed, {}", e);
                System.exit(-1);

            } catch (ConcurrentModificationException e) {
                log.error("concurrent read failed, {}", e);
                System.exit(-1);
            }

            if (r.isEmpty()) {
                log.info("read but recv empty, thread exit, command: {}, data: {}", 0, wrap.array[0]);

                if (command.emptyForbiden()) {
                    return -1;

                } else {
                    continue;
                }
            }

            result[0] += 1;
            result[1] += command.schema.fixedSize();

            while (r.advance()) {
                final Cell c = r.current();
                if (command.param.dump_select) {
                    log.info("recv data, column: {}, data: {}",
                            Bytes.toString(CellUtil.cloneQualifier(c)),
                            CellUtil.cloneValue(c));
                }
            }
        }
        return 1;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void performScan(int[] success) {
        assert (false);
    }
}
