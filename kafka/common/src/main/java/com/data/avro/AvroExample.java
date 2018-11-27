
package com.data.avro;

import com.data.kafka.Configure;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.*;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.avro.specific.SpecificDatumWriter;

//import org.apache.commons.codec.DecoderException;
//import org.apache.commons.codec.binary.Hex;

import org.apache.avro.file.DataFileReader;
import org.apache.avro.file.DataFileWriter;

import java.io.File;
import java.io.IOException;


//mvn -q exec:java -Dexec.mainClass=example.avro.AvroExample
public class AvroExample {

	static void avroCodeExample() throws IOException {
		User user1 = new User();
		user1.setName("Alyssa");
		user1.setFavoriteNumber(256);
		User user2 = new User("Ben", 7, "red");
		User user3 = User.newBuilder()
				.setName("Charlie")
				.setFavoriteColor("blue")
				.setFavoriteNumber(null)	// should not omit, or failed
				.build();
		System.out.println("user1: " + user1);

		String path = "common/target/users.avro";
		// Serialize user1, user2 and user3 to disk
		// distill schema, from generated class, store as in-memory
		DatumWriter<User> userDatumWriter = new SpecificDatumWriter<User>(User.class);
		DataFileWriter<User> dataFileWriter = new DataFileWriter<User>(userDatumWriter);
		// write schema and data to file
		dataFileWriter.create(user1.getSchema(), new File(path));
		dataFileWriter.append(user1);
		dataFileWriter.append(user2);
		dataFileWriter.append(user3);
		dataFileWriter.close();

		System.out.println("loading ...... ");
		// Deserialize Users from disk
		DatumReader<User> userDatumReader = new SpecificDatumReader<User>(User.class);
		DataFileReader<User> dataFileReader = new DataFileReader<User>(new File(path), userDatumReader);
		User user = null;

		while (dataFileReader.hasNext()) {
			// Reuse user object by passing it to next(). This saves us from
			// allocating and garbage collecting many objects for files with
			// many items.
			user = dataFileReader.next(user);
			System.out.println(user);
		}
		//for (User user : dataFileReader)
	}

	public static void avroDataExample() throws IOException {
		// schema with json format
		Schema schema = new Schema.Parser().parse(new File(Configure.getResource("/user.avsc").getFile()));

		// use unique record type
		GenericRecord user1 = new GenericData.Record(schema);
		user1.put("name", "Alyssa");
		user1.put("favorite_number", 256);
		// Leave favorite color null

		GenericRecord user2 = new GenericData.Record(schema);
		user2.put("name", "Ben");
		user2.put("favorite_number", 7);
		user2.put("favorite_color", "red");

		// Serialize user1 and user2 to disk
		File file = new File("users.avro");
		DatumWriter<GenericRecord> datumWriter = new GenericDatumWriter<GenericRecord>(schema);
		DataFileWriter<GenericRecord> dataFileWriter = new DataFileWriter<GenericRecord>(datumWriter);
		dataFileWriter.create(schema, file);
		dataFileWriter.append(user1);
		dataFileWriter.append(user2);
		dataFileWriter.close();

		// Deserialize users from disk
		DatumReader<GenericRecord> datumReader = new GenericDatumReader<GenericRecord>(schema);
		DataFileReader<GenericRecord> dataFileReader = new DataFileReader<GenericRecord>(file, datumReader);
		GenericRecord user = null;
		while (dataFileReader.hasNext()) {
			// Reuse user object by passing it to next(). This saves us from
			// allocating and garbage collecting many objects for files with
			// many items.
			user = dataFileReader.next(user);
			System.out.println(user);
		}
	}

	public static void main(String[] args) throws IOException {
		Configure config = new Configure();

		System.out.println("Message sent successfully");
		avroCodeExample();
		avroDataExample();
	}
}
