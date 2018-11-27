
package com.data.avro;

import com.data.kafka.Configure;
import com.data.kafka.*;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.*;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.avro.specific.SpecificDatumWriter;

import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;

//mvn -q exec:java -Dexec.mainClass=example.avro.AvroExample
// https://unmi.cc/kafka-produce-consume-avro-data/
public class AvroKafka {

	void producer() throws IOException {
		// create object
		Schema schema = User.getClassSchema();
		GenericRecord payload1 = new GenericData.Record(schema);
		payload1.put("name", "Ben");
		payload1.put("favorite_number", 7);
		payload1.put("favorite_color", "red");
		System.out.println("Original Message : "+ payload1);

		// create byte value
		DatumWriter<GenericRecord> writer = new SpecificDatumWriter<GenericRecord>(schema);
		// bind encoder with output stream
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);
		writer.write(payload1, encoder);
		encoder.flush();
		out.close();
		byte[] bytes = out.toByteArray();
		System.out.println("convert bytes: "+ bytes);

		Configure config = new Configure();
		Properties props = SimpleProducer.getProperties(config);
		props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
		Producer<String, byte[]> producer = new KafkaProducer<>(props);
		producer.send(new ProducerRecord<>(config.getProperty("avro_topic"),
				"avro_key_string", bytes));
		producer.close();

		System.out.println("producer complete");
	}

	void consumer() throws IOException {

		Configure config = new Configure();
		Properties props = SimpleConsumer.getProperties(config);
		props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArrayDeserializer");
		Consumer<String, String> consumer = new KafkaConsumer<>(props);
		consumer.subscribe(Arrays.asList(config.getProperty("avro_topic")));
		consumer.seekToBeginning(consumer.assignment());
		consumer.commitSync();

		Schema schema = User.getClassSchema();
		DatumReader<GenericRecord> reader = new SpecificDatumReader<>(schema);

		ConsumerRecords<String, String> records = consumer.poll(10000);
		for (TopicPartition partition : records.partitions()) {
			List<ConsumerRecord<String, String>> partitionRecords = records.records(partition);
			for (ConsumerRecord<String, String> record : partitionRecords) {

				Decoder decoder = DecoderFactory.get().binaryDecoder(record.value().getBytes(), null);
				//Decoder decoder = DecoderFactory.get().binaryDecoder(record.value(), null);
				//BinaryDecoder decoder = DecoderFactory.get().directBinaryDecoder(new ByteArrayInputStream(record.value()), null);
				GenericRecord payload2 = reader.read(null, decoder);
				System.out.println("get item: " + payload2);
				//System.out.println("get item: " + record.key() + "," + record.value());
			}
		}

		consumer.close();

		System.out.println("consumer complete");
	}

	public static void main(String[] args) throws IOException {
		AvroKafka avro = new AvroKafka();
		avro.producer();
		avro.consumer();
	}
}
