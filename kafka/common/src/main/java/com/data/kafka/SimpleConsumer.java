package com.data.kafka;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Properties;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.common.TopicPartition;

public class SimpleConsumer {

	public static Properties getProperties(Configure config) {
		Properties props = new Properties();
		props.put("bootstrap.servers", config.getProperty("broker"));
		props.put("group.id", config.getProperty("group"));
		props.put("client.id", config.getProperty("client"));

		props.put("enable.auto.commit", "true");
		props.put("auto.commit.interval.ms", "1000");

		boolean testing = true;
		if (testing) {
			props.put("max.poll.records", "5");
			props.put("metadata.max.age.ms", "10");
			//props.put("auto.offset.reset", "earliest");
			//props.put("exclude.internal.topics", "false");
		}

		/** no need check crc */
		props.put("check.crcs", "false");
		props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		return props;
	}
	static Consumer<String, String> getConsumer(Configure config) {
		Properties props = getProperties(config);
	    return new KafkaConsumer<>(props);
	}
	
	static void consume_records(Consumer<String, String> consumer, long time, int total) {
		long last = System.currentTimeMillis();
		int count = 0;
		
		while (true) {
			ConsumerRecords<String, String> records = consumer.poll(100);

			for (ConsumerRecord<String, String> record : records) {
				count++;
				
				if (total > 0 || count % 1000 == 0) {
					System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
				}
			}
			
			if (total > 0 && count >= total) {
				time = 0;
			}
			
			if (last + time < System.currentTimeMillis()) {
				System.out.printf("consume records, process [%d], using [%d]\n", count, System.currentTimeMillis() - last);
				break;
			}
		}
	}
	
	static void manually_commit(Consumer<String, String> consumer, long time, int total) {
		long last = System.currentTimeMillis();
		int count = 0;
		
		while (true) {
			//ConsumerRecords<String, String> records = consumer.poll(Long.MAX_VALUE);
			ConsumerRecords<String, String> records = consumer.poll(100);
			
			for (TopicPartition partition : records.partitions()) {
				List<ConsumerRecord<String, String>> partitionRecords = records.records(partition);
				for (ConsumerRecord<String, String> record : partitionRecords) {
					++count;
					System.out.println(record.offset() + ": " + record.value());
				}
				/** get last offset, commit single value as map */
				long lastOffset = partitionRecords.get(partitionRecords.size() - 1).offset();
				consumer.commitSync(Collections.singletonMap(partition, new OffsetAndMetadata(lastOffset + 1)));
			}
			
			if (total > 0 && count >= total) {
				time = 0;
			}
			
			if (last + time < System.currentTimeMillis()) {
				System.out.printf("manual commit, process [%d]\n", count);
				break;
			}
		}
	}
	
	/** 
	 * we can only get assignment after poll
	 * */
	static void assignment_stat(Consumer<String, String> consumer) {
		System.out.println("subsctiption: " + consumer.subscription());
		System.out.print("assignment state: ");
		consumer.assignment().stream().forEach(System.out::println);
		System.out.println();
	}

	static void committed_stat(Consumer<String, String> consumer) throws InterruptedException {
		Function<String, Integer> handle = (prefix) -> {
		
			System.out.print(prefix + " commited state: ");
			consumer.assignment().stream().forEach((topic_partition) -> {
				OffsetAndMetadata metadata = consumer.committed(topic_partition);
					System.out.println(metadata);
				}
			);
			return 0;
		};
		handle.apply("before wait");
		
		Thread.sleep(1500);
		handle.apply("after  wait");
		System.out.println();
	}
	
	static void endoffset_stat(Consumer<String, String> consumer) {
	
		System.out.print("offset state: ");
		List<TopicPartition> list = consumer.assignment().stream().collect(Collectors.toList());
		consumer.endOffsets(list).forEach((topic_partition, offset) -> 
			System.out.println(topic_partition + ": " + offset)
		);
		System.out.println();
	}
	
	static void topics_stat(Consumer<String, String> consumer, String dest) {
		
		System.out.println("total topic: ");
		consumer.listTopics().forEach((topic, list) -> { 
			if (dest.isEmpty() || dest.equals(topic)) {
				System.out.println("topic " + topic + ": ");
				list.stream().forEach(v -> System.out.println("\t" + v));
			}
		});
		System.out.println();
	}
	
	
	static void manually_partition(Consumer<String, String> consumer) {
		while (true) {
			ConsumerRecords<String, String> records = consumer.poll(Long.MAX_VALUE);

			for (TopicPartition partition : records.partitions()) {
				List<ConsumerRecord<String, String>> partitionRecords = records.records(partition);
				for (ConsumerRecord<String, String> record : partitionRecords) {
					System.out.println(record.offset() + ": " + record.value());
				}
				/** get last offset, commit single value as map */
				long lastOffset = partitionRecords.get(partitionRecords.size() - 1).offset();
				consumer.commitSync(Collections.singletonMap(partition, new OffsetAndMetadata(lastOffset + 1)));
			}
		}
	}
	
	static void seek_beginning(Consumer<String, String> consumer) {
		
		consume_records(consumer, 1, 1);
		consumer.seekToBeginning(consumer.assignment());
		consumer.commitSync();
		
		System.out.print("consumer from beginning, topic " + consumer.assignment() + ": ");
	}
	
	static void consume_offset(Consumer<String, String> consumer) {
		//consumer.unsubscribe();
		
		System.out.print("consumer from sysoffset: ");
		consumer.subscribe(Arrays.asList("test", "__consumer_offsets"));
		consume_records(consumer, 100, 0);
	}
	
	static void listen_rebalance(Consumer<String, String> consumer) {
		consumer.unsubscribe();
		
		consumer.subscribe(Pattern.compile("test[0-9]*"), new ConsumerRebalanceListener() {

		    public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
		    	System.out.println("listener revoked: " + partitions);
		    }
		    
		    public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
		    	System.out.println("listener assigned: " + partitions);
		    }
		});
		
		/** wait change happen, we can create another topic contain name test[n] 
		 *  update time limited by metadata.max.age.ms */
//		consumer.poll(Long.MAX_VALUE);
		consumer.poll(30000);
	}
	
	public static void main(String[] args) throws InterruptedException {
		Configure config = new Configure();
		Consumer<String, String> consumer = getConsumer(config);

		try {
			String topic  = config.getProperty("topic");
			consumer.subscribe(Arrays.asList(topic));
			
			if (false) {
				seek_beginning(consumer);j
				consume_records(consumer, 100000000, 0);
				return;
			}
			
			/** consume message */
			//consume_records(consumer, 200, 10);
			//manually_commit(consumer, 200, 0);
			
			/** get statistic */
			//topics_stat(consumer, "");
			//committed_stat(consumer);
			//endoffset_stat(consumer);
			
			/** change state */
			//seek_beginning(consumer);
			//assignment_stat(consumer);
			
			/** get inner topic: offset */
			//consume_offset(consumer);
			
			/** listen for topic change */
			//listen_rebalance(consumer);
			seek_beginning(consumer);
			consume_records(consumer, 10000, 1000);
			
		} finally {
			System.out.println("done");
			consumer.close();
		}
	}
}
