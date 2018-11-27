package com.data.kafka;

import java.util.List;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.PartitionInfo;

public class SimpleProducer {

	public static Properties getProperties(Configure config) {
		Properties props = new Properties();
		props.put("bootstrap.servers", config.getProperty("broker"));

		props.put("retries", 0);
		props.put("batch.size", 16384);
		props.put("buffer.memory", 33554432);
		props.put("client.id", config.getProperty("client"));

		props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

		props.put("acks", "all");
		props.put("linger.ms", 1);
		return props;
	}
	
	public static Producer<String, String> getProducer(Configure config) {
		Properties props = getProperties(config);
		return new KafkaProducer<>(props);
	}
	
	static void	  display_topic(Producer<String, String> producer, String topic) {
		List<PartitionInfo> list = producer.partitionsFor(topic);
		list.stream().forEach(System.out::print);	
		System.out.println("");
	}
	
	static void	sending_topic(Producer<String, String> producer, String topic, int count) {
		//producer.send(new ProducerRecord<String, String>(topic, "\n<==="));
		for (int i = 0; i < count; i++) {
			if (count < 1000 || i % 1000 == 0) {
				System.out.println("send " + i);
			}
			producer.send(new ProducerRecord<String, String>(topic, Integer.toString(i), Integer.toString(i * 10)));
			//Thread.sleep(1000);
		}
		//producer.send(new ProducerRecord<String, String>(topic, "===>\n"));
	}

	static void	sending_handle(Producer<String, String> producer, String topic) {
		Callback handle = (RecordMetadata metadata, Exception exception) -> {
			System.out.println("call back, " + metadata + ", time " + metadata.timestamp());
		};
		
		for (int i = 0; i < 10; i++) {
			System.out.println("send " + i);
			producer.send(new ProducerRecord<String, String>(topic, Integer.toString(i), Integer.toString(i * 10)), handle);
		}
	}
	
	public static void main(String[] args) throws InterruptedException, ExecutionException {
		Configure config = new Configure();

		Producer<String, String> producer = getProducer(config);
		String topic  = config.getProperty("topic");

		/** get inner state */
		display_topic(producer, topic);
		
		sending_topic(producer, topic, 100);

		if (false) {
			sending_handle(producer, topic);
		}
		
		/** no need, just for test */
		producer.flush();
		producer.close();

		System.out.println("Message sent successfully");
	}
}
