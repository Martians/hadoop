

global_input_handy()
{
	; override any hotkey if regist before	
	hotkey_override(1)
	
    ;############################################################################
    ; Note List
input_type("ever")
    note_list("[system]    		0@Config-System/"
            , "[manage]"   		app_gbk("ever", "R&D") "/0@Manage")
 
            ; "[nifi | <!n]     3 Nifi/0@Nifi-Install(++single|single_hide)" cancel("goto_end")
            ;, "[hadoop | <!h] 	1 Hadoop/" sep("always") ;
    note_list("[Common]         0 Common/"
            ;, "[hadoop | <!h] 	1 Hadoop/" sep("always") ; kernel
            ;, "[spark] 	    1 Spark/"  sep("always")
            
            ;, "[Analazy | >!a]  0 Analazy/"
            , "[Design | >!e]   0 Design/"
            , "[TiDB | >!b]     1 TiDB/"
            , "[Ceph | >!c]     5 Ceph/"
            ; , "[Python | >!p]   9 Python/"

            , "[kubernetes | !k] 0@kubernetes/")
    ;-------------------------------------------------------------------------------------------------------------
    ;-------------------------------------------------------------------------------------------------------------

input_type("path")
    link_list("[douban]         movie.douban.com"
            , "[toutiao]        www.toutiao.com")
input_type(0)

	hotkey_override(0)
}

;=============================================================================================================
;=============================================================================================================
global_serial_handy()
{
    ;note_list("[java]       0 Java/")
    
    ;-------------------------------------------------------------------------------------------------------------
    ;-------------------------------------------------------------------------------------------------------------
	link_list("[readme]         readfree.me"
            , "[hortonoworks]   docs.hortonworks.com/index.html"
			, "[hadoop]         hadoop.apache.org"
            , "[kafka]          kafka.apache.org"
            , "[storm]          storm.apache.org"
            , "[flume]          flume.apache.org"
            , "[spark]          spark.apache.org"
            , "[nifi]           nifi.apache.org/docs.html"
            , "[hbase]			hbase.apache.org/book.html"
            , "[cassandra]	    cassandra.apache.org/doc/latest/getting_started/index.html"
            , "[yugabyte]       docs.yugabyte.com/api/cassandra/ddl_create_keyspace"
            , "[scylladb]       docs.scylladb.com/"
            , "[tidb]           pingcap.com/docs-cn/"

            , "[api-scala]		www.scala-lang.org/api/2.11.8/#package"
            , "[api-java]		docs.oracle.com/javase/8/docs/api/"
            , "[api-spark]		spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.rdd.RDD"

            , "[mesos]          mesos.apache.org"
            , "[kubernetes]     kubernetes.io"
            , "[docker hub]		store.docker.com" ; hub.docker.com/explore
            , "[mind]           mubu.com/edit/156775")

	; if contain :port, should use http:// as prefix
	link_list("[jira]           jira.internal.nimblex.cn"
            , "[confluence]     confluence.internal.nimblex.cn"
            , "[rockdata]       confluence.internal.nimblex.cn/display/RDP1")
}








