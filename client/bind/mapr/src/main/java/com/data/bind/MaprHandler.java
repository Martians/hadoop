package com.data.bind;

        import com.data.bind.HBaseHandler;

public class MaprHandler extends HBaseHandler {

    protected void resolveMore() {

        /**
         * for mapr 6.0.1
         *
         *  https://maprdocs.mapr.com/home/MapR-DB/UsingMaven.html
         *  http://repository.mapr.com/nexus/content/groups/mapr-public/org/apache/hbase/hbase-client/
         */
        config.set("mapr.hbase.default.db", "maprdb");
    }
}
