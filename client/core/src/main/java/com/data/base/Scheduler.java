package com.data.base;

import com.data.bind.AppHandler;
import com.data.source.DataSource;
import com.data.source.OutputSource;
import com.data.util.monitor.MetricTracker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class Scheduler {

    final Logger log = LoggerFactory.getLogger(this.getClass());

    public Command command;
    public AppHandler handler;
    public DataSource source;
    public OutputSource output;

    List<IOPSThread> iopsThreads = new ArrayList<>();

    public Scheduler(Command command) {
        this.command = command;
    }

    void createInstance() {
        source = command.createGenerator();

        if (command.type == Command.Type.generate
                || command.type == Command.Type.scan && command.exist("gen.data_path"))
        {
            output = new OutputSource();
            output.initialize(command);

        } else {
            output = null;
        }

        handler = command.createAppHandler();
        handler.set(this);
        handler.initialize();

        command.source = source;
        command.lastFixed();
    }

    public void handle() {
        int count = command.stepCount();

        while (command.nextStep()) {
            if (count > 0) {
                log.info("");
                log.info("");
                log.info("*****************************************************************************");
                log.info("step [{}], type: {}  ", count - command.stepCount(), command.type);
                log.info("*****************************************************************************");
            }
            nextStep();
        }
    }

    public void nextStep() {
        createInstance();
        command.resetStep();

        log.info("========================================================================");
        log.info("{}, {}", command.dumpLoad(), handler.dumpLoad());
        log.info("  \t{}, thread {}, batch {}",
                source.dumpLoad(), command.param.thread, command.param.batch);
        log.info("========================================================================");

        try {
            startThread(handler);

            waitThread();

        } finally {
            terminate();
        }
    }

    public void startThread(AppHandler handler) {

        MetricTracker.initialize(command, Command.Type.end.ordinal() + 1);

        for (int index = 0; index < command.param.thread; index++) {
            iopsThreads.add(new IOPSThread(index, this));
        }

        for (IOPSThread iopsThread : iopsThreads) {
            iopsThread.startThread();
        }
    }

    void waitThread() {
        try {
            for (int index = 0; index < iopsThreads.size(); index++) {
                iopsThreads.get(index).join();
            }

            if (output != null) {
                output.waitThread();
            }

        } catch (InterruptedException e) {
            log.error("wait thread join error, {}", e);
        }
    }

    void terminate() {

        handler.terminate();

        iopsThreads.clear();

        MetricTracker.terminate();
    }

}
