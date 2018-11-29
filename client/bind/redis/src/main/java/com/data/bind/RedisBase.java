package com.data.bind;

import com.data.base.Command;
import com.data.util.source.DataSource;
import com.data.util.source.OutputSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RedisBase {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    Command   command;
    DataSource source;
    OutputSource output;
    RedisHandler.Action action = RedisHandler.Action.data;

    protected void checkParam() {}
    protected void connecting() {}
    protected void preparing() {}
    public void threadWork() {}
    public void threadTerm() {}
    public void terminate() {}
    public String dump() { return ""; }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public int write(int[] result, int batch) { return 1; }
    public int read(int[] result, int batch) { return 1; }
}
