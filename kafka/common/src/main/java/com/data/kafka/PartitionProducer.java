package com.data.kafka;

import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Partitioner;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.Cluster;

public class PartitionProducer implements Partitioner {
	@Override
	public void configure(Map<String, ?> configs) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster) {
		System.out.println("----");
		return key.hashCode();
	}

	@Override
	public void close() {
		// TODO Auto-generated method stub
		
	}
	
	static Producer<String, String> getProducer(String server) {
		Properties props = new Properties();
		props.put("bootstrap.servers", server);
		props.put("retries", 0);
		props.put("batch.size", 16384);
		props.put("buffer.memory", 33554432);
		props.put("client.id", "test_program");
		props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		props.put("partitioner.class", "com.data.kafka.PartitionProducer");
		props.put("acks", "all");
		props.put("linger.ms", 1);
		
		//partitioner.class
		return new KafkaProducer<>(props);
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


	public static void main(String[] args) throws InterruptedException, ExecutionException {
		String topic = "work";
		
		Producer<String, String> producer = getProducer("192.168.36.10:9092");
		
		sending_topic(producer, topic, 100);
	
		System.out.println("Message sent successfully");
		producer.close();
	}
}
