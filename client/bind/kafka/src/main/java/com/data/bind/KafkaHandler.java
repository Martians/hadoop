package com.data.bind;

import com.data.base.Command;
import com.data.base.IOPSThread;
import com.data.util.data.source.DataSource;

import com.data.util.schema.DataSchema;
import org.apache.kafka.clients.admin.*;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.Node;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.ExecutionException;

import static com.data.base.Command.Type.scan;
import static com.data.base.Command.Type.read;

/**
 * API：http://kafka.apache.org/20/javadoc/index.html?overview-summary.html
 *
 * ## BaseCommand
    1. Topic
      bin/kafka-topics.sh $ZK_HOST --list
      bin/kafka-topics.sh $ZK_HOST --describe

    2. consumer
       bin/kafka-console-consumer.sh $BT_HOST --topic test --from-beginning

    3. group
       bin/kafka-consumer-groups.sh $BT_HOST --list
       bin/kafka-consumer-groups.sh $BT_HOST --describe --group group_test
 *
 *
 * 性能：
 *      ## 自带性能测试：
 *      https://github.com/apache/kafka/blob/trunk/tools/src/main/java/org/apache/kafka/tools/ProducerPerformance.java
 *
 *      1. Producer
 *          acks=1 时有最大性能，ack=2将降低一半
 *          增加client的线程数影响不大
 *
 *          可以考虑用 byte[] 替代 String，查看性能是否有提升
 *
 */
public class KafkaHandler extends AppHandler {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    /**
     * 其他参数：
     *      schema: 只有前两项其效果；如果不是string，发送之前将执行 toString
     *      batch：每执行一个batch，就切换到下一个topic
     */
    public static class Option extends com.data.util.command.BaseOption {
        public Option() {
            /** 不需要专门设置，command中会将prefix设置为bind */
            //setPrefix("kafka");

            addOption("producer.acks", "producer wait ack", "1");
            addOption("producer.batch_k", "producer batch size", 16);
            addOption("producer.linger_ms", "producer linger time", 1);
            addOption("producer.buffer_m", "producer buffer size", 32);

            addOption("consumer.group",  "consumer client group", "group_test");
            addOption("consumer.client",  "consumer client id current", "client_test");
            addOption("consumer.always",  "continuous consumer", false);

            /**
             * bind param
             */
            addOption("topic.loop", "topic change loop", 10000);

            addOption("topic.name",  "topic name", "test");
            addOption("topic.count",  "topic count", 1);
			addOption("topic.replica",  "topic replica", 1);
            addOption("topic.partition",  "topic partition", 5);

            //addOption("command",  "only-once command", false);
            //addOption("consumer_always",  "consumer wait or exit", false);
        }
    }

    private Properties props = new Properties();
    ArrayList<String> topicList = new ArrayList<>();

    private AdminClient admin;

    /**
     * producer
     */
    private Producer<String, String> producer;
    private int topicRecord = 0;
    private int topicIndex = 0;
    private int topicLoop = 0;

    /**
     * consumer
     */
    static final ThreadLocal<Consumer<String, String>> consumer = new ThreadLocal<>();
    static final ThreadLocal<Boolean> consumerInitial = new ThreadLocal<Boolean>();
    private java.time.Duration poolTime = Duration.ofMillis(1000);

    void clusterInfo() {
        DescribeClusterResult result = admin.describeCluster();
        try {
            log.info("cluster info, controller {}", result.controller().get());
            Collection<Node> list = result.nodes().get();
            list.stream().forEach(v -> log.info("\t\t node: " + v));

            if (list.size() < command.getInt("topic.replica")) {
                log.info("get kafka cluster info, node count <{}> lower than replica count <{}>", list.size(), command.getInt("topic.replica"));
                System.exit(-1);
            }

        } catch (InterruptedException e) {
            e.printStackTrace();

        } catch (ExecutionException e) {
            e.printStackTrace();
        }
    }

    Collection<TopicListing> listTopic() {
        Collection<TopicListing> list = null;

        try {
            ListTopicsResult result = admin.listTopics();
            list = result.listings().get();

        } catch (InterruptedException e) {
            log.error("list topic failed, {}", e);
            System.exit(-1);

        } catch (ExecutionException e) {
            log.error("list topic execute failed, {}", e);
            System.exit(-1);
        }
        return list;
    }

    TopicDescription descTopic(String topic) {
        Map<String, TopicDescription> map = null;

        try {
            DescribeTopicsResult result = admin.describeTopics(Arrays.asList(topic));
            map = result.all().get();
            return map.get(topic);

        } catch (InterruptedException e) {
            log.error("desc topic failed, {}", e);
            System.exit(-1);

        } catch (ExecutionException e) {
            log.error("desc topic execute failed, {}", e);
            System.exit(-1);
        }
        return null;
    }

    /**
     * when delete, we delete all topics
     */
    void deleteTopic(ArrayList<String> deleteList, boolean total) {

        if (total) {
            deleteList.clear();

            Collection<TopicListing> topics = listTopic();
            for (TopicListing item : topics) {
                deleteList.add(item.name());
            }
        }

        if (deleteList.size() > 0) {
            try {
                log.info("delete topic：");
                deleteList.forEach(V -> log.info("\t\ttry delete topic {}", V));

                DeleteTopicsResult result = admin.deleteTopics(deleteList);
                result.all().get();

            } catch (InterruptedException e) {
                log.error("delete topic failed, {}", e);
                System.exit(-1);

            } catch (ExecutionException e) {
                log.error("delete topic execute failed, {}", e);
                System.exit(-1);
            }
        }
    }

    void createTopic(Collection<NewTopic> createList) {
        if (createList.size() > 0) {

            int limit = 5;
            for (int i = 0; i < limit; i++) {
                try {
                    Thread.sleep(i * 500);

                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                log.info("create topic retry - {}", i);

                try {
                    createList.forEach(V -> log.info("\t\ttry create topic {}", V.name()));

                    CreateTopicsResult result = admin.createTopics(createList);
                    result.all().get();
                    return;

                } catch (InterruptedException e) {
                    log.error("create topic failed, {}", e);
                    System.exit(-1);

                } catch (ExecutionException e) {
                    /**
                     * 有时候create失败，需要多次执行; 找到没有创建成功的重试
                     */
                    Collection<TopicListing> topics = listTopic();
                    Collection<NewTopic> newList = new ArrayList<>();

                    for (NewTopic topic : createList) {
                        boolean find = false;
                        for (TopicListing item : topics) {
                            if (topic.name().equals(item.name())) {
                                find = true;
                            }
                        }
                        if (!find) {
                            newList.add(topic);
                        }
                    }
                    createList = newList;
                }
            }

            log.error("create topic retry exceed limit {} !", limit);
            System.exit(-1);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void threadWork() {
        createConsumer();
    }

    @Override
    public void terminate() {

        if (admin != null) {
            admin.close();
        }

        if (producer != null) {
            producer.close();
        }

        if (consumer.get() != null) {
            consumer.get().close();
            consumer.set(null);
        }
    }

    public String dumpLoad() {
        return String.format("topic: %s[0-%d] partition %s, group [%s], client id [%s]",
                command.get("topic.name"), command.getInt("topic.count") - 1, command.get("topic.partition"),
                command.get("consumer.group"), command.get("consumer.client"));
    }

    /**
     * http://kafka.apache.org/20/javadoc/index.html?overview-summary.html
     */
    protected void resolveParam() {
        props.put("bootstrap.servers", command.get("host"));

        topicLoop = command.getInt("topic.loop");
    }

    /**
     * producer: https://kafka.apache.org/20/javadoc/overview-summary.html
     */
    protected void connecting() {
        /**
         * org.apache.kafka.clients.admin.AdminClientConfig
         */
        admin = AdminClient.create(props);

        createProducer();

        clusterInfo();
    }

    void createProducer() {
        if (command.type == Command.Type.write || command.type == Command.Type.load) {
            Properties config = new Properties();
            config.putAll(props);

            /**
             * 使用ack = 1，能获得比较好的性能
             *      注：这里是字符串传入，不能使用整形，kafka要求是字符串
             */
            config.put("acks", command.get("producer.acks"));
            config.put("retries", 0);
            /**
             * 如果数据没达到batch size，允许等待的时间
             */
            config.put("linger.ms", command.getInt("producer.linger_ms"));
            config.put("batch.size", command.getInt("producer.batch_k") * 1024);
            config.put("buffer.memory", command.getInt("producer.buffer_m") * 1024 * 1024);
            /**
             * 现不使用压缩
             */
            //config.put("compression.type", "gzip");
            //config.put("partitioner.class", 1); // org.apache.kafka.clients.producer.internals.DefaultPartitioner

            if (true) {
                config.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
                config.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
            } else {
                config.put("key.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
                config.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
            }
            producer = new KafkaProducer<>(config);
        }
    }

    void createConsumer() {
        /**
         * org.apache.kafka.clients.consumer.KafkaConsumer<K,V>
         */
        if (command.isRead()) {
            Properties config = new Properties();
            config.putAll(props);

            config.put("group.id", command.get("consumer.group"));

            if (command.getInt("work.read_thread") == 1) {
                config.put("client.id", command.get("consumer.client"));
            } else {
                config.put("client.id", command.get("consumer.client") + "_" + IOPSThread.index());
            }

            config.put("enable.auto.commit", "true");
            config.put("auto.commit.interval.ms", "1000");

            config.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
            config.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

            if (true) {
                config.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
                config.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

            } else {
                config.put("key.deserializer", "org.apache.kafka.Common.serialization.ByteArrayDeserializer");
                config.put("value.deserializer", "org.apache.kafka.Common.serialization.ByteArrayDeserializer");
            }

            consumer.set(new KafkaConsumer<>(config));

            /**
             * 订购所有的topic
             */
            consumer.get().subscribe(topicList);
        }
    }

    protected void preparing() {
        Collection<NewTopic> createList = new ArrayList<>();
        ArrayList<String> deleteList = new ArrayList<>();
        Collection<TopicListing> topics = listTopic();

        int count = command.getInt("topic.count");
        for (int i = 0; i < count; i++) {
            topicList.add(count <= 1 ? command.get("topic.name")
                    : command.get("topic.name") + "_" + i);
        }

        boolean ignore_clear = false;
        if (command.type.equals(read) || command.type.equals(scan)) {
            log.info("current mode is read, ignore clear");
            ignore_clear = true;
        }
        /**
         * 有任何topic存在，并且需要删除
         */
        for (String topic : topicList) {
            boolean find = false;
            boolean create = false;
            for (TopicListing item : topics) {
                if (topic.equals(item.name())) {
                    find = true;
                }
            }

            if (find) {
                if (command.getBool("clear")) {
                    if (ignore_clear == false) {
                        deleteList.add(topic);
                        create = true;
                    }

                } else {
                    log.info("topic [{}] already exist", topic);
                    //log.info("\t\t\t{}", descTopic(topic));
                }
            } else {
                create = true;
            }

            if (create) {
                createList.add(new NewTopic(topic,
                        command.getInt("topic.partition"), command.getInt("topic.replica").shortValue()));
            }
        }

        /** command clear, and not read or scan, then delete all topic */
        deleteTopic(deleteList,
                command.getBool("clear") && !ignore_clear);

        createTopic(createList);

        initTopic();

        //int max_count = 2;
        //if (command.schema.list.size() > max_count) {
        //    log.info("======> kafka only need 1 field, fix schema");
        //    command.schema.limit(max_count);
        //}
    }

    private void initTopic() {
        Random rand = new Random();
        topicIndex = rand.nextInt() % topicList.size();

        if (topicIndex < 0) {
            topicIndex += topicList.size();
        }
        log.info("init topic index {}", topicIndex);
    }

    /**
     * 向多个topic轮询发送，负载均衡方式执行
     */
    private String nextTopic() {
        if (topicRecord ++ > topicLoop) {
            topicRecord = 0;
            topicIndex = (topicIndex + 1) % topicList.size();
        }
        return topicList.get(topicIndex);
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    public int write(int[] result, int batch) {
        for (int i = 0; i < batch; i++) {

            List<DataSchema.Item> list = command.schema.list;
            DataSource.Wrap wrap = source.next();
            if (wrap == null) {
                log.debug("write get null, completed");
                return -1;
            }

            if (list.size() == 1) {
                producer.send(new ProducerRecord<>(nextTopic(),
                        list.get(0).isString() ? (String) wrap.array[0] : wrap.array[0].toString()));

            } else if (list.size() == 2) {
                producer.send(new ProducerRecord<>(nextTopic(),
                        list.get(0).isString() ? (String) wrap.array[0] : wrap.array[0].toString(),
                        list.get(1).isString() ? (String) wrap.array[1] : wrap.array[1].toString()));

            } else {
                StringBuilder sb = new StringBuilder();
                for (int index = 1; index < wrap.array.length; index++) {
                    if (index > 1) {
                        sb.append(", ");
                    }
                    sb.append(wrap.array[index]);
                }
                producer.send(new ProducerRecord<>(nextTopic(),
                        list.get(0).isString() ? (String) wrap.array[0] : wrap.array[0].toString(),
                        sb.toString()));
            }
            result[0] += 1;
            result[1] += wrap.size;
        }
        /**
         * 促使buffer中的数据立即发送出去
         */
        //producer.flush();
        return 1;
    }


    public int read(int[] result, int batch) {
        try {
            while (result[0] < batch) {
                ConsumerRecords<String, String> records = consumer.get().poll(poolTime);
                if (records.isEmpty()) {
                    break;
                }

                for (ConsumerRecord<String, String> record : records) {
                    result[0] += 1;
                    result[1] += record.serializedKeySize() + record.serializedValueSize();

                    if (command.table.dump_select) {
                        log.info("recv data, {}", record);
                    }
                }
            }
        } catch (Exception e) {
            log.info("read data, failed {}", e);
        }


        if (result[0] == 0) {
            if (consumerInitial.get() == null) {
                consumerInitial.set(true);
                /**
                 * 只有执行一次读取之后，才会分配 partition 下来
                 */
                log.info("thread assignment: {}", consumer.get().assignment());
                consumer.get().seekToBeginning(consumer.get().assignment());

            } else {
                if (command.getBool("consumer.always")) {
                } else {
                    log.info("read get null, completed");
                    return -1;
                }
            }
        }
        return 1;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

}
