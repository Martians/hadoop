package com.data.realtime;

import com.data.util.command.BaseCommand;
import com.data.util.data.generator.Random;
import com.data.util.schema.DataSchema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ThreadLocalRandom;

public class PositionGenerator extends Random {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    RealtimeSource create;

    int resolution = 1000;
    int speed = 0;

    int stopped = 0;
    Random stopRand = new Random();

    ThreadLocal<UserGenerator.User> local = new ThreadLocal<>();

    PositionGenerator(RealtimeSource create, BaseCommand command) {
        this.create = create;
        set(command);
    }

    public void set(DataSchema.Item item) {
        item.len = 12;
        item.type = DataSchema.Type.string;
    }

    public void prepare(DataSchema.Item item) {
        super.prepare(item);

        resolution = command.getInt("create.gen.position.resolution");
        speed = command.getInt("create.gen.position.speed");
        stopped = command.getInt("create.gen.position.stop");
    }

    public class Position {
        long x;
        long y;
    }

    public Position newOne() {
        Position pos = new Position();
        pos.x = getIndex(0, resolution);
        pos.y = getIndex(0, resolution);
        return pos;
    }

    UserGenerator.User getLast() {
        UserGenerator.User last = local.get();
        if (last == null) {
            //last = new UserGenerator.User();
        }
        return last;
    }

    public String getString(int length) {
        UserGenerator.User last = local.get();

        if (last != null && last.name.equals(create.userGen.user.name)) {
            return makeString(last.pos.y);
        }
        last = create.userGen.user;

        if (isStopped() || create.timer.time == last.time) {
            //log.info("=========");
        } else {
            int dist = (int)(speed * (create.timer.time - last.time) / 2);

            last.pos.x = fix(last.pos.x + (long)getIndex(-dist, dist));
            last.pos.y = fix(last.pos.y + (long)getIndex(-dist, dist));
        }
        return makeString(last.pos.x);
    }

    boolean isStopped() {
        return stopRand.getIndex(100) <= stopped;
    }

    long fix(long x) {
        if (x < 0) {
            return x + resolution;
        }
        if (x > resolution) {
            return x - resolution;
        }
        return x;
    }

    public String makeString(Long data) {
        return data.toString();
    }
}