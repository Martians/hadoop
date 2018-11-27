package com.data.util.common;

//import org.apache.logging.log4j.LogManager;
//import org.apache.logging.log4j.Logger;
//import org.apache.logging.log4j.core.config.ConfigurationSource;
//import org.apache.logging.log4j.core.config.Configurator;

/**
 * https://stackoverflow.com/questions/21368757/sl4j-and-logback-is-it-possible-to-programmatically-set-the-logging-level-for/21601319
 * https://stackoverflow.com/questions/3837801/how-to-change-root-logging-level-programmatically
 * https://www.programcreek.com/java-api-examples/?class=ch.qos.logback.classic.Logger&method=setLevel
 */

import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.LoggerContext;

public class LogUtil {
    //static final Logger log = LoggerFactory.getLogger(LogUtil.class);
    /**
     * 自动调整日志级别
     */
    static {
        /** log4j2 */
        //Configurator.setLevel(Logger.ROOT_LOGGER_NAME, Level.DEBUG);

        //Logger LOG = (Logger) org.slf4j.LoggerFactory.getLogger(ch.qos.logback.classic.Logger.ROOT_LOGGER_NAME);
    }
//    public static void configureLogLevel(boolean verbose) {
//        // First remove all appenders.
//        Logger.getLogger("com.yugabyte.sample").removeAppender("YBConsoleLogger");
//        Logger.getRootLogger().removeAppender("YBConsoleLogger");;
//
//        // Create the console appender.
//        ConsoleAppender console = new ConsoleAppender();
//        console.setName("YBConsoleLogger");
//        String PATTERN = "%d [%p|%c|%C{1}] %m%n";
//        console.setLayout(new PatternLayout(PATTERN));
//        console.setThreshold(verbose ? Level.DEBUG : Level.INFO);
//        console.activateOptions();
//
//        // Set the desired logging level.
//        if (verbose) {
//            // If verbose, make everything DEBUG log level and output to console.
//            Logger.getRootLogger().addAppender(console);
//            Logger.getRootLogger().setLevel(Level.DEBUG);
//        } else {
//            // If not verbose, allow YB sample app and driver INFO logs go to console.
//            Logger.getLogger("com.yugabyte.sample").addAppender(console);
//            Logger.getLogger("com.yugabyte.driver").addAppender(console);
//            Logger.getLogger("com.datastax.driver").addAppender(console);
//            Logger.getRootLogger().setLevel(Level.WARN);
//        }
//    }

    public static void initialize() {

    }
}
