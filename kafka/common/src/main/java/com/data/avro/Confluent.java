
package com.data.avro;

import java.io.IOException;

//mvn -q exec:java -Dexec.mainClass=example.avro.AvroExample
// https://unmi.cc/kafka-produce-consume-avro-data/
// https://docs.confluent.io/current/schema-registry/docs/serializer-formatter.html
public class Confluent {

	void producer() throws IOException {

		System.out.println("producer complete");
	}

	void consumer() throws IOException {


		System.out.println("consumer complete");
	}

	public static void main(String[] args) throws IOException {
		Confluent avro = new Confluent();
		avro.producer();
		avro.consumer();
	}
}
