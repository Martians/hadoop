package com.data.realtime;

import com.data.util.data.generator.Random;
import com.data.util.schema.DataSchema;

public class TimeGenerator extends Random implements Runnable  {
    public long time = System.currentTimeMillis();
    Thread thread;
    boolean work = false;

    public void startThread() {
        thread = new Thread(this, "timer");
        thread.setDaemon(true);

        work = true;
        thread.start();
    }

    public void stopThread() {
        work = false;
        try {
            thread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void run() {
        while (work) {
            try {
                Thread.sleep(10);
                //time++;
                time = System.currentTimeMillis();

            } catch (InterruptedException e) {
            }
        }
    }

    public void set(DataSchema.Item item) {
        item.type = DataSchema.Type.integer;
        item.len = 14;
    }

    public Long getLong() {
        return time;
    }
}