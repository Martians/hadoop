package com.data.base;

import com.data.bind.AppHandler;
import com.data.util.data.source.DataSource;
import com.data.util.data.source.OutputSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class IOPSThread extends Thread {
    final Logger log = LoggerFactory.getLogger(this.getClass());

    int     index;
    boolean finished;

    Command command;
    AppHandler handler;
    DataSource source;
    OutputSource output;

    public static final ThreadLocal<Integer> local = new ThreadLocal<Integer>();

    IOPSThread(int index, Scheduler scheduler) {
        this.index = index;

        this.command = scheduler.command;
        this.handler = scheduler.handler;
        this.source = scheduler.source;
        this.output = scheduler.output;
    }

    void initialize() {
        if (command.param.thread >= 10) {
            setName(String.format("iops-%02d", index));
        } else {
            setName(String.format("iops-%d", index));
        }
        local.set(index);

        source.threadPrepare(index);

        handler.threadWork();
    }

    public static int index() {
        return local.get();
    }

    @Override
    public void run() {
        initialize();

        int[] success = new int[3];
        int fetched = 0;
        Long total = 0L;

        try {
            do {
                /**
                 * 上一次取得的任务尚未完成，继续执行
                 *      不再从source中后去任务数，source的总个数是一定的，取走了就没有了
                 */
                if (success[0] < fetched) {
                    fetched -= success[0];

                    if (fetched < success[0]) {
                        fetched = source.nextWork(command.workp.fetch - fetched) + fetched;
                    }
                } else {
                    fetched = source.nextWork(command.workp.fetch);
                }
                success[2] = command.speedLimit(fetched);

                /**
                 * success[2]：传入参数，本地要执行的次数
                 * success[0]：返回结果，成功的个数
                 * success[1]：返回结构，是否成功
                 */
                success[0] = 0;
                success[1] = 0;

                switch (command.type) {
                    case write:
                    case load:
                        handler.performWrite(success);
                        break;
                    case read:
                        handler.performRead(success);
                        break;
                    case scan:
                        handler.performScan(success);
                        break;
                    case generate:
                        handler.performGen(success);
                        break;
                }
                total += success[0];

                if (success[1] < 0) {
                    break;
                }

            /**
             * success[2] = 0，也会执行一次，通知内部执行已经结束，进行处理
             */
            } while(success[2] > 0 && !finished);

        } catch (Exception e) {
            //handler.terminate();
            log.warn("io thread exception: {}", e);

        } finally {
            handler.threadTerm();
            log.info("thread {} completed [{}] task", index, total);
        }
    }

    public void startThread() {
        start();
    }

    public void stopThread() {
        finished = true;
    }
}
