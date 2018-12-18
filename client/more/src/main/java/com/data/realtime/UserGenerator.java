package com.data.realtime;

import com.data.util.data.generator.Random;
import com.data.util.schema.DataSchema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UserGenerator extends Random {
    static final Logger log = LoggerFactory.getLogger(UserGenerator.class);
    long min = 13000000000L;
    long max = 19000000000L;

    ThreadLocal<User> local = new ThreadLocal<>();

    RealtimeSource create;
    UserGenerator(RealtimeSource create) {
        this.create = create;
    }

    class User {
        String name;
        long   time;
        PositionGenerator.Position pos;
        public String toString() { return name; }
    }

    public void set(DataSchema.Item item) {
        item.len = 18;
        item.type = DataSchema.Type.object;
    }

    protected void cacheUpdate(Object object) {
        local.set((User)object);
    }

    public User user() {
        return local.get();
    }

    Long number() {
        return Math.abs(getRandom().nextLong() % (max - min)) + min;
    }

    @Override
    public Object getObject(DataSchema.Item item) {
        User user = new User();
        //user.name = "(+86) " + number();
        user.name = number().toString();
        user.time = create.timer.time;
        user.pos = create.position.newOne();
        return user;
    }
}
