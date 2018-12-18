package com.data.realtime;

import com.data.base.Command;
import com.data.util.command.BaseCommand;
import com.data.util.command.BaseOption;
import com.data.util.schema.DataSchema;
import com.data.util.data.source.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class RealtimeSource extends DataSource {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    public static class Option extends BaseOption {
        public Option() {
            addOption("position.resolution", "position resolution", 100000);
            addOption("position.speed", "position speed n/s", 100);
            addOption("position.stop", "stop probability", 5);
        }
    }

    DataSchema schema = null;

    public TimeGenerator timer = new TimeGenerator();
    public UserGenerator userGen  = new UserGenerator(this);
    public PositionGenerator position;

    public void initialize(BaseCommand command, DataSchema schema, String path) {
        prepareSchema(command);
        command.advice("use create source, you'd better use [-Xms80g] or even more memory!");

        super.initialize(command, this.schema, path);
        resolveParam();
        preparing();
    }


    /**
     * 重建schema
     *      此时command内部已经初始化完成，需要使用新的
     */
    protected void prepareSchema(BaseCommand command) {
        Command current = ((Command)command);

        schema = current.schema;
        schema.set(command);

        position = new PositionGenerator(this, command);
        if (command.getBool("test")) {
            schema.initialize("integer@null, string(18/2w)@null, integer{2}@null");
            position.prepare(schema.list.get(2));
            schema.set(0, timer);
            schema.set(1, userGen);
            schema.set(2, position);
            schema.set(3, position);

        } else {
            schema.initialize(command.get("schema"));
            position.prepare(schema.list.get(20));
            schema.set(1, timer);
            schema.set(3, userGen);
            schema.set(20, position);
            schema.set(21, position);
        }
        schema.dump();
    }

    protected void resolveParam() {

    }

    protected void preparing() {
        timer.startThread();
    }

    HashMap<String, List<PositionGenerator.Position>> valid = new HashMap<>();
    void addValid(String name, String x, String y) {
        List<PositionGenerator.Position> list = valid.get(name);
        if (list == null) {
            list = new ArrayList();
            valid.put(name, list);
        }
        PositionGenerator.Position pos = position.new Position();
        pos.x = Long.valueOf(x);
        pos.x = Long.valueOf(y);
        list.add(pos);
    }

    public Wrap next() {
        StringBuilder sb = new StringBuilder();
        List<DataSchema.Item> list = schema.list;

        int size = 0;
        for (int i = 0; i < list.size(); i++) {
            DataSchema.Item item = list.get(i);
            if (item.gen.valid) {
                if (i != 0) {
                    sb.append(",");
                }
                sb.append(item.gen.get(item));
                size += item.curr;
            }
        }

        Object[] array = new Object[1];
        array[0] = sb.toString();
        return new Wrap(array, sb.length());
    }
}
