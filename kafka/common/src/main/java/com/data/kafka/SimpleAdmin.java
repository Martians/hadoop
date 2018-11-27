
package com.data.kafka;

import java.util.Arrays;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeoutException;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.DeleteTopicsResult;
import org.apache.kafka.clients.admin.DescribeClusterResult;
import org.apache.kafka.clients.admin.DescribeTopicsResult;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;

public class SimpleAdmin {
	
	static AdminClient getAdmin(Configure config) {
		Properties props = new Properties();
		props.put("bootstrap.servers", config.getProperty("broker"));
		props.put("client.id", config.getProperty("admin_client"));
	
		return AdminClient.create(props);
	}
	
	static void create_topics(AdminClient client, String name, int partition, short replica) 
			throws InterruptedException, ExecutionException 
	{
		try {
			CreateTopicsResult result = client.createTopics(Arrays.asList(new NewTopic(name, partition, replica)));
			result.all().get();
			
		} catch (Exception e) {
			System.out.println("SimpleAdmin.create_topics exception: " + e);
		} 
		System.out.println("create topic [" + name + "]");
	}
	
	static void delete_topics(AdminClient client, String name) 
			throws InterruptedException, ExecutionException, TimeoutException 
	{
		//config delete.topic.enable in broker first
		try {
			DeleteTopicsResult result = client.deleteTopics(Arrays.asList(name));
			//result.all().get(1000, TimeUnit.MILLISECONDS);
			result.all().get();
			
		} catch (Exception e) {
			System.out.println("SimpleAdmin.delete_topics exception: " + e);
		}
		Thread.sleep(1000);
		System.out.println("delete topic [" + name + "]");
	}
	
	static void discribe_topic(AdminClient client, String topic) throws InterruptedException, ExecutionException, TimeoutException {
		DescribeTopicsResult result = client.describeTopics(Arrays.asList(topic));
		
		System.out.println("discribe topic: ");
		result.all().get().forEach((T,V) -> System.out.println("\t" + V));
	}
	
	static void list_topic(AdminClient client) throws InterruptedException, ExecutionException, TimeoutException {
		ListTopicsResult result = client.listTopics();
		System.out.println("list topic: ");
		result.listings().get().forEach(V -> System.out.println("\t" + V));
	}
	
	/** 
	 * get controller address
	 **/
	static void discribe_cluster(AdminClient client) throws InterruptedException, ExecutionException  {
		DescribeClusterResult result = client.describeCluster();
		System.out.println("cluster stat: controller [" + result.controller().get() + "]");
		System.out.println("cluster node: ");
		result.nodes().get().stream().forEach(v -> System.out.println("\t" + v));
	}
	
	// describeConfigs(Collection<ConfigResource> resources)
	public static void main(String[] args) throws InterruptedException, ExecutionException, TimeoutException {
		Configure config = new Configure();
		AdminClient client = getAdmin(config);
		String topic  = config.getProperty("admin_topic");
		
		/** change topic */
		//delete_topics(client, topic);
		//create_topics(client, topic, 1, (short)1);
		
		/** cluster status */
		discribe_topic(client, topic);
		//list_topic(client);
		discribe_cluster(client);
		
		System.out.println("done");
	}
}
