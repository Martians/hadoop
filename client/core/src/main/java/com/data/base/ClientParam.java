package com.data.base;

/**
 * 针对要经常读取的参数，提取出来
 */
public class ClientParam {
    static Command command;

    public Long  total = command.getLong("work.total");
    public int   batch = Integer.max(command.getInt("work.batch"), 1);

    public int   fetch = command.getInt("work.fetch");
    public long  seed = command.getLong("gen.seed");

    public boolean dump_select = command.getBool("table.dump_select");
    public long read_empty = command.getLong("table.read_empty");
}