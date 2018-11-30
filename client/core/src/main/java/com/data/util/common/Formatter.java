package com.data.util.common;

import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Formatter {

    public static Long parseLong(String valud) {
        if (isNumeric(valud)) {
            return Long.parseLong(valud);

        } else {
            return parseSize(valud);
        }
    }

    public static boolean isNumeric(String str) {
        for (int i = 0; i < str.length(); i++) {
            if (!Character.isDigit(str.charAt(i))) {
                return false;
            }
        }
        return true;
    }

    public static Long parseSize(String value) {

        //String primaryPartten = "<(\\(.+\\))?(.+)>";
        Pattern pattern = Pattern.compile("([-0-9]*)(.*)");
        Matcher match = pattern.matcher(value);
        long unit = 1;
        long data = 0;

        if (match.find()) {
            if (match.group(1) != null) {
                data = Long.valueOf(match.group(1));
            }

            if (match.group(2) != null) {
                switch (match.group(2).trim().toLowerCase()) {
                    case "k": unit = 1024; break;
                    case "m": unit = 1024 * 1024; break;
                    case "g": unit = 1024 * 1024 * 1024; break;

                    case "w": unit = 10000; break;
                    case "y": unit = 100000000; break;

                    default:  unit = 1; break;
                }
            }
            return data * unit;

        } else {
            return null;
        }
    }

    public static String formatTime(long data) {
        return String.format("%.1f ms", data *1.0 / 1000000);
    }

    public static String formatElapse(long data) {
        Duration d = Duration.ofNanos(data);
        return String.format("%02d:%02d:%02d", d.toHours() % 24, d.toMinutes() % 60, d.getSeconds() % 60);
    }

    public static String formatLatency(long time, long iops) {
        if (iops == 0) {
            return "0 ms";
        }

        long data = time / 1000 / iops;
        if (data < 1000) {
            return String.format("%.2f ms", data * 1.0 / 1000);
        } else {
            return String.format("%.1f ms", data * 1.0 / 1000);
        }
    }

    public static String formatSize(long data) {
        if (data < 1024) {
            return data + " B";

        } else if (data < 1024 * 1024) {
            return String.format("%.1f K", data * 1.0 / 1024);

        } else if (data < 1024 * 1024 * 1024) {
            return String.format("%.2f M", data * 1.0 / (1024 * 1024));

        } else if (data < 1024L * 1024 * 1024 * 1024) {
            return String.format("%.1f G", data * 1.0 / (1024L * 1024 * 1024));

        } else {
            return String.format("%.1f T", data * 1.0 / (1024L * 1024 * 1024 * 1024));
        }
    }

    public static String formatIOPS(long data) {
        if (data < 10000) {
            return String.valueOf(data);

        } else if (data < 100000000) {
            return String.format("%.1f w", data * 1.0 / 10000);

        } else {
            return String.format("%.2f y", data * 1.0 / 100000000);
        }
    }
}
