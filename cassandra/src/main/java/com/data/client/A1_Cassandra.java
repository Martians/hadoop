package com.data.client;

import com.datastax.driver.core.*;
import com.datastax.driver.core.querybuilder.BuiltStatement;
import com.datastax.driver.core.querybuilder.QueryBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.SimpleDateFormat;
import java.util.List;

import static com.datastax.driver.core.querybuilder.QueryBuilder.eq;

/**
 *
 * github： https://github.com/datastax/java-driver
 * doc:     https://github.com/datastax/java-driver/tree/3.x/manual
 * api:     https://docs.datastax.com/en/drivers/java/3.4/com/datastax/driver/core/BatchStatement.html
 *
 * example: https://github.com/datastax/java-driver/tree/3.x/driver-examples/src/main/java/com/datastax/driver/examples
 *          book：https://github.com/jeffreyscarpenter/cassandra-guide
 *
 *          yuga：https://github.com/YugaByte/yugabyte-db/blob/master/java/yb-loadtester/src/main/java/com/yugabyte/sample/apps/AppBase.java
 *          ycsb: https://github.com/brianfrankcooper/YCSB/tree/master/cassandra
 *
 * Note:
 *      1. 这里的语句执行，都应该放在 try catch 中
 *      2. schema不能lazy方式创建，多个client同时创建可能导致不一致发生 171 P
 *
 * Todo：
 *      https://github.com/datastax/java-driver/tree/3.x/manual/load_balancing
 */
public class A1_Cassandra {
    static final Logger log = LoggerFactory.getLogger(A1_Cassandra.class);

    static String host = "192.168.10.7";

    static Cluster cluster;
    static Session session;

    static String createKeyspace = "CREATE KEYSPACE IF NOT EXISTS example WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}";
    static String createTable = "CREATE TABLE IF NOT EXISTS items(supplier_id INT, supplier_name TEXT STATIC, item_id INT, item_name TEXT, PRIMARY KEY((supplier_id), item_id))";
    static String useKeySpace = "use example";

    static class ConnectionListener implements Host.StateListener {

        public ConnectionListener() {
            super();
        }

        public String getHostString(Host host) {
            return new StringBuilder("Data Center: " + host.getDatacenter() +
                    " Rack: " + host.getRack() +
                    " Host: " + host.getAddress()).toString() +
                    " Version: " + host.getCassandraVersion() +
                    " State: " + host.getState();
        }

        @Override
        public void onUp(Host host) {
            System.out.printf("\t\t-------- Node is up: %s\n", getHostString(host));
        }

        @Override
        public void onAdd(Host host) {
            System.out.printf("\t\t-------- Node added: %s\n", getHostString(host));
        }

        @Override
        public void onDown(Host host) {
            System.out.printf("\t\t-------- Node is down: %s\n", getHostString(host));
        }

        @Override
        public void onRemove(Host host) {
            System.out.printf("\t\t-------- Node removed: %s\n", getHostString(host));
        }

        @Override
        public void onRegister(Cluster cluster) {
            // do nothing
        }

        @Override
        public void onUnregister(Cluster cluster) {
            // do nothing
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////


    /**
     * https://github.com/datastax/java-driver/tree/3.x/manual/load_balancing
     */
    static void policySetting() {
        /**
         * LoadBalancingPolicy
         *      1. 默认：RoundRobinPolicy，其他：DCAwareRoundRobinPolicy
         *         新client，默认 new TokenAwarePolicy(DCAwareRoundRobinPolicy.builder().build());
         *      2. 必须提供一个distance函数，将node分类成：local、remote、ignored
         *      3. 路由查询请求：newQueryPlan 会返回查询将涉及到的一些node，从其中选择一些出来
         *      4. 会收到node上下线的通知; 对要选择的节点进行判断
         *
         *      可以将policy放在TokenAwarePolicy中，
         *          TokenAwarePolicy, 尽量少的选择query需要涉及到的node
         *
         *      https://github.com/YugaByte/yugabyte-db/blob/master/java/yb-loadtester/src/main/java/com/yugabyte/sample/apps/AppBase.java
         */

        /**
         * Retry policy， 166 P
         *      1. DefaultRetryPolicy
         *      2. FallthroughRetryPolicy， 不进行任何重试
         *      3. DowngradingConsistencyRetryPolicy，为了请求成功，会试图降低一致性级别
         *
         *      可以在执行语句时，使用 setRetryPolicy 来替换默认策略
         */

        /**
         * Speculative execution
         *      推测执行，如果发生GC等停顿，导致请求长时间不回应，可以允许执行该机制，将请求发送到其他节点上去
         *
         *      1. NoSpeculativeExecutionPolicy
         *      2. ConstantSpeculativeExecutionPolicy
         *      3. PercentileSpeculativeExecutionPolicy
         */

        /**
         * Address translator
         *      1. 用于node不知道自己ip的情况，云上
         */
    }

    static void connect() {
        /**
         * connect pool
         *      MaxRequestsPerConnection：每个链接可以inflight的最大请求
         *      setMaxQueueSize：该host的所有链接都已经达到maxRequest之后，全局等待队列的大小；超过此大小的请求直接拒绝
         *      setPoolTimeoutMillis：请求在队列中的最大等待时间
         *
         *      如果都满了，就选择下一个host
         */
        PoolingOptions pooling = new PoolingOptions();
        pooling.setConnectionsPerHost(HostDistance.LOCAL, 16, 24);
        pooling.setMaxRequestsPerConnection(HostDistance.LOCAL,32768);

        log.info("origin: {}-{}-{}-{}, core connection: {}, max: {}, queue: {}, request: {}",
                (new PoolingOptions()).getCoreConnectionsPerHost(HostDistance.LOCAL),
                (new PoolingOptions()).getMaxConnectionsPerHost(HostDistance.LOCAL),
                (new PoolingOptions()).getMaxQueueSize(),
                (new PoolingOptions()).getMaxRequestsPerConnection(HostDistance.LOCAL),
                pooling.getCoreConnectionsPerHost(HostDistance.LOCAL),
                pooling.getMaxConnectionsPerHost(HostDistance.LOCAL),
                pooling.getMaxQueueSize(), pooling.getMaxRequestsPerConnection(HostDistance.LOCAL));

        /**
         * socket
         */
        SocketOptions socket = new SocketOptions();
        socket.setConnectTimeoutMillis(30000);
        /** 读请求最大等待时间 */
        socket.setReadTimeoutMillis(60000);
        log.info("origin: {}-{}, connection timeout: {}, read timeout: {}",
                (new SocketOptions()).getConnectTimeoutMillis(),
                (new SocketOptions()).getReadTimeoutMillis(),
                socket.getConnectTimeoutMillis(),
                socket.getReadTimeoutMillis());

        try {
            /**
             * 如果配置从配置文件中导入，可以用 Cluster.buildFrom(Initializer initializer)
             */
            cluster = Cluster.builder()
                    //.addContactPoints
                    .addContactPoint(host)
                    /** Listener 测试，开关1） */
                    //.withInitialListeners(Collections.singletonList(new ConnectionListener()))
                    .withPoolingOptions(pooling)
                    .withSocketOptions(socket)
                    /** 可以设置一个别名，默认是 cluster1 */
                    .withClusterName("cluster_my")
                    /** 负载均衡策略 */
                    //.withLoadBalancingPolicy
                    //.withQueryOptions()
                    /** 指定与服务器通讯使用的版本 */
                    //.withProtocolVersion()
                    /** 指定与服务器通讯时，是否压缩，会增加CPU开销 */
                    //.withCompression()
                    .build();

            /**
             * 每个session保存了上述设置，会有一个连接池
             */
            session = cluster.connect();

            /**
             * Listener 测试，开关2）
             *  用来等待关闭部分服务，查看listener的状态
             */
            //Thread.sleep(30000);

        } catch (Exception e) {
            log.info("connect failed: {}", e);
            System.exit(1);
        }
    }

    static void metaState() {
        log.info("\n====================\nmetaState: ");
        Metadata metadata = cluster.getMetadata();

        /**
         * cluster.getClusterName 是默认名字，如果不设置就是 cluster1、cluster2
         *
         * 用于在client连接多个cluster时设置的别名，方便本地管理
         */
        System.out.printf("Connected to cluster: %s, %s\n", metadata.getClusterName(), cluster.getClusterName());
        /**
         * 获取各种配置
         */
        System.out.printf("Protocol Version: %s\n",
                cluster.getConfiguration()
                        .getProtocolOptions()
                        .getProtocolVersion());
        /**
         * 系统内所有配置的节点
         *      即使节点不在线，只有尚未被踢除，仍然会显示
         */
        for (Host host : metadata.getAllHosts()) {
            System.out.printf("DataCenter: %s; Rack: %s; Host: %s\n",
                    host.getDatacenter(), host.getRack(), host.getAddress());
        }

        /**
         * 获取schema
         *      这里会输出所有的表信息，包括系统表
         *      等价于执行：DESCRIBE FULL SCHEMA
         */
        log.info("Schema:");
        log.info(metadata.exportSchemaAsString());
        log.info("");

        System.out.printf("Schema agreement : %s\n", metadata.checkSchemaAgreement());
        System.exit(0);
    }

    static void sessioinState() {
        Session.State state = session.getState();
        System.out.printf("New session created for keyspace: %s\n", session.getLoggedKeyspace());

        /**
         * 只显示当前已经连接到的host
         */
        for (Host host : state.getConnectedHosts()) {
            System.out.printf("DataCenter: %s; Rack: %s; Host: %s; Open Connections: %s\n",
                    host.getDatacenter(), host.getRack(), host.getAddress(),
                    state.getOpenConnections(host));
        }
    }

    /**
     * 此方式问题：
     *      1. 构造过程复杂，容易出错
     *      2. 语句暴露出来，会受到注入攻击
     */
    static void commonExecute() {
        log.info("\n====================\ncommon execute: ");

        ResultSet result;
        session.execute(createKeyspace);
        session.execute(useKeySpace);

        /**
         * wasApplied 检测条件更新的结果（每个返回结果中，实际都有这一列）
         *      某些操作不返回任何列 create keyspace ... IF NOT EXISTS}, CREATE TABLE... IF NOT EXISTS
         *
         *      等价于：rs.one().getBool("[applied]");
         */
        result = session.execute(createTable);
        log.info("{}, applied： {}", result, result.wasApplied());

        result = session.execute("INSERT INTO items(supplier_id, item_id, supplier_name, item_name) VALUES (1, 1, 'Unknown', 'Wrought Anvil')");
        result = session.execute("INSERT INTO items(supplier_id, item_id, supplier_name, item_name) VALUES (1, 2, 'Acme Corporation', 'Giant Rubber Band');");
        result = session.execute("INSERT INTO items(supplier_id, item_id, supplier_name, item_name) VALUES (1, 3, 'Acme ', 'ubber Band');");
        log.info("{}", result);

        /**
         * 获得返回值的状态，列定义等
         */
        result = session.execute("select * from items");
        log.info("select: {}, applied：{}", result, result.wasApplied());
        log.info("column: {}", result.getColumnDefinitions());
        log.info("execute info: {}", result.getExecutionInfo());
        log.info("execute info, in coming payload: {}", result.getExecutionInfo().getIncomingPayload());

        /**
         * 解析返回结果
         *      1. 根据结果的index、列的名字等获取
         *      2. 提供了class的转换接口
         *
         * 也可以使用
         *      List<Row> rows = result.all();
         */
        for (Row row : result) {
            System.out.format("\t --row： supplier_id: %d, item_id: %d, supplier_name: %s, item_name: %s\n",
                    row.getInt("supplier_id"), row.getInt(1),
                    row.getString("supplier_name"), row.getString("item_name"));
        }
    }

    /**
     * 方便构造参数化语句
     *      https://github.com/datastax/java-driver/tree/3.x/manual/statements/simple
     *
     *      1. 用于 ad-hoc 查询; 只执行一次的操作
     *      2. 可以设置 setConsistencyLevel(ConsistencyLevel.ONE)
     *      3. 可以使用名字参数导入：更清晰；不需要转换成字符串，直接使用二进制格式发送出去
     */
    static void simpleStatement() {
        log.info("\n====================\nsimple statement: ");

        session.execute(createKeyspace);
        session.execute(useKeySpace);
        session.execute(createTable);

        SimpleStatement state = new SimpleStatement(
                "INSERT INTO items(supplier_id, item_id, supplier_name, item_name) VALUES (?, ?, ?, ?)",
                5, 9, "Super Hotel at WestWorld", "1-888-999-9999");
        //state.setConsistencyLevel()
        ResultSet result = session.execute(state);
        log.info("result: {}", result);

        state = new SimpleStatement("SELECT * FROM items WHERE supplier_id=?", 5);
        /** 打开调试开关 */
        state.enableTracing();
        result = session.execute(state);

        /**
         * 显示调试信息
         *      cassandra 中有此信息;
         *      yugabyte 无效
         */
        QueryTrace queryTrace = result.getExecutionInfo().getQueryTrace();
        if (queryTrace == null) {
            log.info("no tracing info");

        } else {
            SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss.SSS");

            System.out.printf("Trace id: %s\n\n", queryTrace.getTraceId());
            System.out.printf("%-42s | %-12s | %-10s \n", "activity", "timestamp", "source");
            log.info("-------------------------------------------+--------------+------------");

            for (QueryTrace.Event event : queryTrace.getEvents()) {
                System.out.printf("%42s | %12s | %10s\n",
                        event.getDescription(),
                        dateFormat.format((event.getTimestamp())),
                        event.getSource());
            }
        }
    }

    /**
     * 提升查询效率，每次执行语句，只需要发送handle和param即可
     *      https://github.com/datastax/java-driver/tree/3.x/manual/statements/prepared
     *
     *      1. PreparedStatement 相当于是一个创建查询语句的模板；可以有效防止注入攻击
     *      2. bind之后，数据是按照其二进制形式存储的
     *      3. 可以设置一致性级别、跟踪、重试策略等
     *      4. 可以使用命名参数，设置参数内容
     *      5. 可以不设置，或者unset参数，server端会忽略这个值
     *
     *  注意：
     *      如果使用哦prepareStatement，如果table发生改变，那么后续就无法执行成功
     *      这种情况下不使用 select *，而要手动指明select的列名
     */
    static void preparedStatement() {
        log.info("\n====================\nsimple statement: ");

        session.execute(createKeyspace);
        session.execute(useKeySpace);
        session.execute(createTable);

        /**
         * 发送给服务器后，返回语句的句柄
         */
        PreparedStatement prepared = session.prepare(
                "INSERT INTO items(supplier_id, item_id, supplier_name, item_name) VALUES (?, ?, ?, ?)");
        log.info("get prepared id: {}", prepared.getPreparedId());

        /**
         * 一次性bind
         *
         *  也可以只绑定前N个value
         */
        BoundStatement state = prepared.bind(6, 20, "Hotel", "long long");
        ResultSet result = session.execute(state);
        log.info("{}", result);

        /**
         * 一个个bind
         */
        state = prepared.bind(7);
        /**
         * bind时指定index和类型
         */
        state.setInt(1, 39);
        state.setString(2, "work")
             .setString("item_name", "next");
        result = session.execute(state);
    }

    /**
     * https://github.com/datastax/java-driver/tree/3.x/manual/async
     */
    static void futureStatement() {
        log.info("\n====================\nfuture statement: ");

        try {
            ResultSetFuture result = session.executeAsync("select * from items");
            result.wait();

        } catch (Exception e) {
            System.err.println("async failed, " + e.getMessage());
        }

        /**
         * 使用Google’s Guava，定义回调函数
         */
//        static class CallBack implements ListenableFuture {
//
//        }
    }

    /**
     * 提供流式API
     *      1. 使用已经编译好的结构
     *      2. 可用于参数是可选的情况
     *
     *      https://github.com/brianfrankcooper/YCSB/blob/master/cassandra/src/main/java/com/yahoo/ycsb/db/CassandraCQLClient.java
     */
    static void builtStatement() {
        log.info("\n====================\nbuilt statement: ");

        session.execute(createKeyspace);
        session.execute(useKeySpace);
        session.execute(createTable);

        BuiltStatement state =
                QueryBuilder.insertInto("items")
                        .value("supplier_id", 10)
                        .value("item_id", 8)
                        .value("supplier_name", "22222")
                        .value("item_name", "11111");

        ResultSet result = session.execute(state);
        log.info("{}", result);

        /**
         * select
         *      也可以选择 select().column
         */
        state = QueryBuilder.select().all()
                    .from("items").where(eq("supplier_id", 10));
        result = session.execute(state);
        log.info("{}", result.getAvailableWithoutFetching());
        log.info("{}", result.all().size());
    }

    /**
     * https://github.com/datastax/java-driver/tree/3.x/manual/paging
     *
     * 注意：
     *      cassandra不完全遵守page的个数
     *
     * 设置fetch大小
     *      1. 启动cluster时：withQueryOptions(new QueryOptions().setFetchSize(2000))
     *      2. 查询时单独设置：statement.setFetchSize(2000);
     *      3. 默认值是5000
     *
     * 状态查看
     *      getAvailableWithoutFetching、isFullyFetched
     *
     * 执行优化
     *      1. fetchMoreResults：没有数据后，会自动卡主；
     *         可以检查状态后，提前强制获取，后台异步执行
     *
     *      2. setPagingState：记录之前状态（转换为不透明字符串）；之后用字符串，重设page状态；
     *              相当于一个书签功能，不透明字符串记录的是内部状态
     *              案例：可以应用搜索结果的浏览，paging example 中有个很好的例子
     *         还有一种，返回byte[]记录状态的不安全api
     *
     *        这里并不支持offset，使用offset需要遍历，性能比较低
     */
    static void paging() {

    }

    /**
     * string 只支持ascii？需要先序列化
     *      https://github.com/datastax/java-driver/tree/3.x/manual/statements/simple
     *
     */
    static void writing() {

    }

    /**
     * 集合类型：
     *      https://github.com/datastax/java-driver/tree/3.x/manual#collection-types
     *
     *      1. 要给出具体类型
     *      2. 嵌套集合，使用 Guva 中的TypeToken
     */
    static void reading() {

    }


    public static void main(String[] args) {
        try {

            if (false) {
                policySetting();

                metaState();

                sessioinState();

                commonExecute();

                simpleStatement();

                preparedStatement();

                futureStatement();

                paging();

                writing();

                reading();
            }
            connect();

            metaState();

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
        }

        session.close();
        cluster.close();
    }
}
