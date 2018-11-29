package com.data.bind;

import com.data.source.DataSource;
import com.data.util.monitor.MetricTracker;
import com.data.util.schema.DataSchema;
import com.datastax.driver.core.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Iterator;
import java.util.List;

import static com.data.base.Command.Type.read;
import static com.data.base.Command.Type.scan;

/**
    docker rm -f cassandra scylla

    docker run --name cassandra -d -p 9042:9042 cassandra
    docker exec -it cassandra cqlsh

    docker run --name scylla -d -p 9042:9042 scylla
    docker exec -it scylla cqlsh
 */
public class CassandraHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class BaseOption extends com.data.util.command.BaseOption {
        public BaseOption() {
            addOption("sub_bind",  "working bind sub type", "");

            addOption("conn_min",  "min conn per host", 16);
            addOption("conn_max",  "max conn per host", 24);
            addOption("consistency",  "consistency level", "");

            /**
             * each scan, get limit count
             * split into range count
             **/
            addOption("scan_limit",  "scan fetch limit", 1000);
            addOption("scan_range",  "scan range count", 100);
        }
    }

    class CassendraStatement {
        String dropKeyspace = String.format("DROP KEYSPACE IF EXISTS %s", command.get("table.keyspace"));
        String createKeyspace = String.format("CREATE KEYSPACE IF NOT EXISTS %s WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor' : %d};",
                command.get("table.keyspace"), command.getInt("table.replica"));
        String useKeyspace = String.format("use %s", command.get("table.keyspace"));
        String createTable = command.schema.createTable(command.get("table.table"));

        String insert = command.schema.insertTable(command.get("table.table"));
        String select = command.schema.selectTable(command.get("table.table"));
        String scan = command.schema.scanTable(command.get("table.table"), command.getInt("scan_limit"));
        String token  = "system." + command.schema.tokenColumn();
    }
    CassendraStatement statement;

    private volatile PreparedStatement preparedInsert;
    private volatile PreparedStatement preparedSelect;
    private volatile PreparedStatement preparedScan;
    private final Object prepareInitLock = new Object();

    Cluster cluster;
    Session session;

    @Override
    public void initialize() {
        try {
            resolveParam();

            connecting();

            preparing();

        } catch (Exception e) {
            log.warn("terminate error: {}", e);
            System.exit(-1);
        }
    }

    @Override
    public void terminate() {
        if (session != null) {
            session.close();
            session = null;
        }
        if (cluster != null) {
            cluster.close();
            cluster = null;
        }
    }

    public String dumpLoad() {
        return String.format("table: %s.%s", command.get("table.keyspace"), command.get("table.table"));
    }

    protected void resolveParam() {
        statement = new CassendraStatement();
        log.info("create space: \n\t{}", statement.createKeyspace);
        log.info("create table: \n\t{}", statement.createTable);
        //log.info("insert table: \n\t{}", statement.insert);
        //log.info("select table: \n\t{}", statement.select);
        //log.info("scan   table: \n\t{}", statement.scan);
        //System.exit(-1);
    }

    protected void connecting() {
        PoolingOptions pooling = new PoolingOptions();
        pooling.setConnectionsPerHost(HostDistance.LOCAL, command.getInt("conn_min"), command.getInt("conn_max"));
        pooling.setMaxRequestsPerConnection(HostDistance.LOCAL,32768);

        log.info("origin: {}-{}-{}, core connection: {}, max: {}, queue: {}, inflight: {}",
                (new PoolingOptions()).getCoreConnectionsPerHost(HostDistance.LOCAL),
                (new PoolingOptions()).getMaxConnectionsPerHost(HostDistance.LOCAL),
                (new PoolingOptions()).getMaxQueueSize(),
                pooling.getCoreConnectionsPerHost(HostDistance.LOCAL),
                pooling.getMaxConnectionsPerHost(HostDistance.LOCAL),
                pooling.getMaxQueueSize(),
                pooling.getMaxRequestsPerConnection(HostDistance.LOCAL));

        SocketOptions socket = new SocketOptions();
        socket.setConnectTimeoutMillis(30000);
        socket.setReadTimeoutMillis(60000);
        log.info("origin: {}-{}, connection timeout: {}, read timeout: {}",
                (new SocketOptions()).getConnectTimeoutMillis(),
                (new SocketOptions()).getReadTimeoutMillis(),
                socket.getConnectTimeoutMillis(),
                socket.getReadTimeoutMillis());

        //builder.withLoadBalancingPolicy(new PartitionAwarePolicy(
        //        DCAwareRoundRobinPolicy.builder()
        //                .withUsedHostsPerRemoteDc(Integer.MAX_VALUE)
        //                .build()

        cluster = Cluster.builder()
                .addContactPoint(command.get("host"))
                .withPoolingOptions(pooling)
                .withSocketOptions(socket)
                //.withQueryOptions()
                .build();

        Metadata metadata = cluster.getMetadata();
        log.debug("Connected to cluster: {}", metadata.getClusterName());

        for (Host discoveredHost : metadata.getAllHosts()) {
            log.debug("discover Host: {}; Rack: {}", discoveredHost.getAddress(), discoveredHost.getRack());
        }

        log.debug("try to connect");
        session = cluster.connect();

        Session.State state = session.getState();
        for (Host host : state.getConnectedHosts()) {
            log.info("  \tconnected host: {}", host.getAddress());
        }
        log.info("connecte to server success, total {}",
                state.getConnectedHosts().size(),
                state.getConnectedHosts().size() == metadata.getAllHosts().size() ? "" :
                    ", [" + (metadata.getAllHosts().size() - state.getConnectedHosts().size()) + "] not connected !!!");
    }

    protected void preparing() {
        if (command.getBool("clear")) {
            clearKeySpace();
        }

        executeStatment(statement.createKeyspace,
                "create keyspace");

        executeStatment(statement.useKeyspace,
                "use keyspace");

        executeStatment(statement.createTable,
                "create table");

        createIndex();
    }

    protected void clearKeySpace() {
        if (command.type.equals(read) || command.type.equals(scan)) {
            log.info("current mode is read, ignore clear keyspace");
            return;
        }
        if (command.get("sub_bind").equals("yugabyte")) {
            String dropTable = String.format("DROP Table IF EXISTS %s.%s", command.get("table.keyspace"), command.get(("table.table")));
            executeStatment(dropTable, "drop table");
        }
        executeStatment(statement.dropKeyspace, "drop keyspace");
    }

    protected void createIndex() {
        List<String> list = command.schema.createIndex(command.get("table.table"));
        int index = 0;
        for (String statement : list) {
            executeStatment(statement,
                    "create index " + index++);
        }
    }

    void executeStatment(String statement, String desc) {
        log.info("execute: [{}]", desc);

        Statement state = session.prepare(statement)
                .setConsistencyLevel(ConsistencyLevel.ONE)
                .bind();

        state.setReadTimeoutMillis(60000);
        session.execute(state);
    }

    protected Session getSession() {
        return session;
    }

    public PreparedStatement getPreparedInsert() {
        if (preparedInsert == null) {
            synchronized (prepareInitLock) {
                if (preparedInsert == null) {
                    log.info("insert table: \n\t{}", statement.insert);
                    preparedInsert = getSession().prepare(statement.insert);
                    setConsistencyLevel(preparedInsert);
                }
            }
        }
        return preparedInsert;
    }

    public PreparedStatement getPreparedSelect() {
        if (preparedSelect == null) {
            synchronized (prepareInitLock) {
                if (preparedSelect == null) {
                    log.info("select table: \n\t{}", statement.select);
                    preparedSelect = getSession().prepare(statement.select);
                    setConsistencyLevel(preparedSelect);
                }
            }
        }
        return preparedSelect;
    }

    public PreparedStatement getPreparedScan() {
        if (preparedScan == null) {
            synchronized (prepareInitLock) {
                if (preparedScan == null) {
                    log.info("scan   table: \n\t{}", statement.scan);
                    preparedScan = getSession().prepare(statement.scan);
                    setConsistencyLevel(preparedScan);
                }
            }
        }
        return preparedScan;
    }

    void   setConsistencyLevel(PreparedStatement statement) {
        if (command.exist("consistency")) {
            ConsistencyLevel level = ConsistencyLevel.valueOf(command.get("consistency"));
            statement.setConsistencyLevel(level);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////



    /////////////////////////////////////////////////////////////////////////////////////////////////
    private BoundStatement bind_write(int[] result) {

        DataSource.Wrap wrap = source.next();
        if (wrap == null) {
            log.debug("write get null, completed");
            return null;
        }
        result[0] += 1;
        result[1] += wrap.size;

        return getPreparedInsert().bind(wrap.array);
    }

    @Override
    public int write(int[] result, int batch) {

        try {
            Statement state;

            if (batch <= 1) {
                state = bind_write(result);

            } else {
                BatchStatement bind = new BatchStatement();
                for (int i = 0; i < batch; i++) {
                    state = bind_write(result);
                    if (state == null) {
                        break;

                    } else {
                        bind.add(state);
                    }
                }
                if (bind.size() == 0) {
                    state = null;
                } else {
                    state = bind;
                    log.debug("write batch, size: {}", batch);
                }
            }

            if (state == null) {
                return -1;
            }

            ResultSet results = session.execute(state);
//            List<Row> pathList = updateFromCommandLine.all();
//            if (pathList.size() != 1) {
//                log.error("write failed");
//                System.exit(-1);
//            }
        } catch (Exception e) {
            log.error("write failed, {}", e);
            System.exit(-1);
        }
        return 1;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * convert row data to line
     */
    void processRow(Row row) {
        if (output != null || command.param.dump_select) {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < command.schema.list.size(); i++) {
                if (i > 0) {
                    sb.append(", ");
                }
                sb.append(row.getObject(i));
            }

            if (output != null) {
                output.add(sb.toString());
            } else {
                log.info("updateFromCommandLine: {}", sb.toString());
            }
        }
    }

    private BoundStatement bind_read(int[] result, Object[] preserve) {

        DataSource.Wrap wrap = source.next();
        if (wrap == null) {
            log.debug("read get null, completed");
            return null;
        }

        Object[] array = new Object[command.schema.primaryKey.size()];
        int index = 0;
        for (Integer p : command.schema.primaryKey) {
            DataSchema.Item item = command.schema.list.get(p);
            array[index] = wrap.array[p];
            index++;
        }
        preserve[0] = array;
        return getPreparedSelect().bind(array);
    }

    public int read(int[] result, int batch) {
        Object[] preserve = new Object[1];

        try {
            for (int b = 0; b < batch; b++) {
                Statement state = bind_read(result, preserve);
                if (state == null) {
                    return -1;
                }
                ResultSet results = session.execute(state);

                if (results.getAvailableWithoutFetching() != 1) {
                    String data = formatArray((Object[]) preserve[0]);
                    //LoggerFactory.getLogger("data").info(data);

                    log.info("read but recv empty, thread exit, updateFromCommandLine: {}, data: {}",
                            results.getAvailableWithoutFetching(), data);

                    if (command.emptyForbiden()) {
                        return -1;

                    } else {
                        continue;
                    }
                }
                processRow(results.one());

                result[0] += 1;
                result[1] += command.schema.fixedSize();
            }

        } catch (Exception e) {
            log.error("read failed, {}", e);
            System.exit(-1);
        }
        return 1;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public void performScan(int[] success) {
        DataSource.Wrap wrap = source.next();
        if (wrap == null) {
            log.debug("get next scan data null, completed");
            success[1] = -1;
            processDone();
            return;
        }
        Long[] array = new Long[2];
        array[0] = (Long)wrap.array[0];
        array[1] = (Long)wrap.array[1];

        int result[] = new int[2];
        while (true) {

            long start = System.nanoTime();
            long end = 0;
            result[0] = 0;
            result[1] = 0;

            try {
                BoundStatement state = getPreparedScan().bind(array);
                ResultSet results = session.execute(state);
                Iterator<Row> rows = results.iterator();
                if (!rows.hasNext()) {
                    success[1] = 0;
                    break;
                }
                end = System.nanoTime() - start;

                Row row = null;
                while (rows.hasNext()) {
                    row = rows.next();

                    result[0] += 1;
                    result[1] += command.schema.fixedSize();

                    processRow(row);
                }

                Long currentToken = row.getLong(statement.token) + 1;
                if (currentToken >= array[1]) {
                    log.debug("range exceed, next loop");
                    break;
                }
                array[0] = currentToken;
                //log.info("{}, {}", updateFromCommandLine[0], array[0]);

            } catch (Exception e) {
                log.error("scan failed, {}", e);
                System.exit(-1);
            }

            if (result[0] > 0) {
                MetricTracker.tracker.get(command.step)
                        .add(result[0], result[1], end);
                success[0] += result[0];
            }
            //checkResult(success, result, start);

            //if (updateFromCommandLine[1] < command.param.scan_limit) {
            //    log.info("get updateFromCommandLine: {}, less than required: {}", updateFromCommandLine[1], command.param.scan_limit);
            //    break;
            //}
        }
    }
}
