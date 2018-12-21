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
    ThreadLocal<Index> index = new ThreadLocal<>();

    boolean liner;

    class Index {
        int star;
        int data;

        void init(int max) {
            star = Math.abs(getRandom().nextInt() % max);
            data = 0;
        }

        int next(int max) {
            if (data == max) {
                init(max);
            } else {
                data++;
            }
            int next = star + data;
            return next >= max ? next - max : next;
        }
    }

    class User {
        String name;
        long   time;
        //AtomicInteger count = new AtomicInteger(0);
        PositionGenerator.Position pos;

        public String toString() { return name; }
    }

    public void set(DataSchema.Item item) {
        item.len = 18;
        item.type = DataSchema.Type.object;
        liner = command.getBool("liner");
    }

    /**
     * 确保user的生成随机数是固定的
     */
    protected void prepareEnviroment(DataSchema.Item item) {
        recordSeed = 100 + 3 * 101;
        getRandom().setSeed(recordSeed);
    }

    protected void cacheUpdate(Object object) {
        User user = (User)object;
        local.set(user);
    }

    /**
     * 为了使每个user被选中的概率大致相同
     */
    public int getIndex(int max) {
        if (liner) {
            Index curr = index.get();
            if (curr == null) {
                curr = new Index();
                curr.init(max);
                index.set(curr);
            }
            return curr.next(max) % max;
        } else {
            return super.getIndex(max);
        }
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

    //public void display() {
    //    for (Object object : objectList) {
    //        User user = (User)object;
    //        log.info("[user: {}]", user.name, user.count.get());
    //    }
    //}
}
