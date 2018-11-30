package com.data.util.sys;

import com.data.util.command.BaseCommand;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Method;

public class Reflect {
    protected static final Logger log = LoggerFactory.getLogger(Reflect.class);

    static public Object call(Class<?> classType, Object instance, boolean parent, String method, Object ... args) {

        Class<?>[] paramList = new Class<?>[args.length];
        for (int i = 0; i < args.length; i++) {
            paramList[i] = args[i].getClass();

            if (parent) {
                if (!paramList[i].getSuperclass().equals(Object.class)) {
                    paramList[i] = paramList[i].getSuperclass();
                }
            }
        }

        try {
            if (instance == null) {
                instance = classType.newInstance();
            }
            Method addMethod = classType.getMethod(method, paramList);
            return addMethod.invoke(instance, args);

        } catch (Exception e) {
            log.info("call class [{}] method <{}> failed, {}", classType, method, e);
            System.exit(-1);
        }
        return null;
    }

    public static void main(String[] args) {
        BaseCommand command = new BaseCommand();
        call(BaseCommand.class, null,true, "get", "help");
    }
}
