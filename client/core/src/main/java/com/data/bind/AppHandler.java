package com.data.bind;

import com.data.base.Command;
import com.data.base.Scheduler;
import com.data.util.data.source.DataSource;
import com.data.util.data.source.OutputSource;
import com.data.util.command.BaseOption;
import com.data.util.monitor.MetricTracker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AppHandler {

    final Logger log = LoggerFactory.getLogger(this.getClass());

    Command   command;
    DataSource source;
    OutputSource output;

    private static String methodName() {
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        StackTraceElement e = stackTrace[2];
        return e.getMethodName();
    }

    public Command getCommand() { return command; }

    public DataSource getSource() { return source; }

    public void set(Scheduler scheduler) {
        this.command = scheduler.command;
        this.source = scheduler.source;
        this.output = scheduler.output;
    }

    public void initialize() {
    }
    public void threadWork() {
    }
    public void threadTerm() {
    }
    public void terminate() {
    }

    public BaseOption getOption() { return null; }

    public String dumpLoad() {
        log.error("not impletement: {}", methodName());
        System.exit(-1);
        return "";
    }

    public void performWrite(int[] success) {
        int count = success[2];
        int loops = (count + command.param.batch - 1) / command.param.batch;
        boolean exit = false;

        int result[] = new int[2];
        for (int i = 0; i < loops; i++) {
            long start = System.nanoTime();
            result[0] = 0;
            result[1] = 0;

            int curr = Integer.min(command.param.batch, count);
            count -= curr;

            if ((write(result, curr)) < 0) {
                success[1] = -1;
                exit = true;
            }

            checkResult(success, result, start);

            if (exit) {
                break;
            }
        }
    }

    public void performRead(int[] success) {
        int count = success[2];
        int loops = (count + command.param.batch - 1) / command.param.batch;
        boolean exit = false;

        int result[] = new int[2];
        for (int i = 0; i < loops; i++) {
            long start = System.nanoTime();
            result[0] = 0;
            result[1] = 0;

            int curr = Integer.min(command.param.batch, count);
            count -= curr;

            if ((read(result, curr)) < 0) {
                success[1] = -1;
                exit = true;
            }
            checkResult(success, result, start);

            if (exit) {
                break;
            }
        }
    }

    public void performScan(int[] success) { assert (false); }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    protected void checkResult(int[] success, int[] result, long start) {
        if (result[0] > 0) {
            MetricTracker.tracker.get(command.step)
                    .add(result[0], result[1], System.nanoTime() - start);
            success[0] += result[0];

        } else if (result[0] < 0) {
            /**
             * maybe async request, not cal to tracker, but still add to thread work
             */
            success[0] += -result[0];
        }
    }

    /**
     * convert local data to line
     */
    String formatArray(Object[] array) {
        StringBuffer sb = new StringBuffer();
        int index = 0;
        for (Object object : array) {
            if (index++ > 0) {
                sb.append(", ");
            }
            sb.append(object);
        }
        return sb.toString();
    }

    void processDone() {
        if (output != null) {
            output.complete();
        }
    }

    public void performGen(int[] success) {
        int count = success[2];
        int loops = (count + command.param.batch - 1) / command.param.batch;
        boolean exit = false;

        if (count == 0) {
            processDone();
            return;
        }

        int result[] = new int[2];
        for (int i = 0; i < loops; i++) {
            long start = System.nanoTime();
            result[0] = 0;
            result[1] = 0;

            int curr = Integer.min(command.param.batch, count);
            count -= curr;

            for (int b = 0; b < curr; b++) {
                DataSource.Wrap wrap = source.next();
                if (wrap == null) {
                    output.complete();
                    success[1] = -1;
                    exit = true;
                }

                String line = formatArray(wrap.array);
                output.add(line);

                result[0] += 1;
                result[1] += wrap.size + 3;
            }

            checkResult(success, result, start);

            if (exit) {
                break;
            }
        }
    }

    public int write(int[] result, int batch) {
        return 0;
    }

    public int read(int[] result, int batch) {
        return 0;
    }
}
