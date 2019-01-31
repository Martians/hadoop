;==============================================================================================
;==============================================================================================


g_windows := {}
/*
check_assist_focus_ctrl(Byref run)
{
    if (check_assist_hotkey("focus_ctrl")) {        
        switch_obj(run, assist_name("focus_ctrl"), "focus", "no focus")
        return true
    }
	return false
}

check_assist_hide_mode_other(Byref run)
{
    if (check_assist_hotkey("hide_other")) {   
        switch_obj(run, assist_name("hide_other"), "hide other", "not hide other")       
        return true
    }
	return false
}

switch_reserve_window(Byref run)
{
	global g_windows
	
	refresh := 0
	;强制切换窗口,up/down，left/right, home/end
	if (check_assist_hide_mode("", run) || check_assist_focus_ctrl(run) 
		|| check_assist_hide_mode_other(run))
	{
		refresh := 1
		tips("refresh reserve key")
	}
	
	;之前快捷键记录的窗口不存在
	if (run.saveid == 0 || refresh ||
		!Win_Exist(run.saveid))
	{
		if (!refresh && run.saveid != 0) {
			tips( run.title " not exist, switch to new one")
			run.saveid := 0
		}
		
		winid := win_curr()
		;标题不一致，需要进行切换
		if (run.saveid != winid) {
			run.saveid := winid
			run.title := win_title(winid)     		
			tips("switch to " run.title)
		}
		
		;需要定位到控件
		;  即使窗口未变换，也可以切换控件
		if (assist(run, "focus_ctrl")) {
			;ControlGetFocus, ctrl, A
 			;获取当前鼠标下的控件，而不是激活控件
 			run.ctrl := mouse_win_ctrl()
 			
 			focus_ctrl(run.ctrl, run.saveid)
 		}		
		return
	}

	;选择窗口时进行了设置，或者设置了全局隐藏窗口
	if (assist(run, hide_other) || g_windows.hide_other == 1) {
		;隐藏其他窗口	
		hide_other(run)
	}
	
	if (do_switch(run.saveid, run, run) 
	    && assist(run, "focus_ctrl")) 
	{
		;激活状态下，定位到窗口控件上
		focus_ctrl(run.ctrl, run.saveid)
	}
}

hide_other(Byref except)
{
	global g_windows
	
	;next窗口不需要激活，就不隐藏其他窗口
	if (if_front(except.saveid, except.front)) {
		return
	}
			
	index := 0
	while( true) {   
		if (++index > g_windows.MaxIndex()) {
			;tips("index " index)
			break
		}
			
		run := g_windows[index]
		if (run.saveid == 0 || run == except)
			continue
	
		else if (if_front(run.saveid, run.front)) {
			;tips("hide " index)
			hide_window(run.saveid, run.hide)	
		}
	}
}

next_reserve(prev)
{
	 global g_windows
	 ;初始化last必须是一个有效的index值
	 static last := 1
    
     if (!g_windows.MaxIndex()) {
		;tips("no window to switch")
		return
     }

	 index := last
	 
	 while(true) {   
		last := Mod(last + 1, g_windows.MaxIndex()) + 1
		;tips(index " - " last)	 
				
	 	run := g_windows[last]
     	if (win_exist(run.saveid)) {
     		;tips(" exist index " last)
     		active_reserve(g_windows[last])
     		break
     	
		;已经循环了一遍，还没找到
		} else if (index == last) {
			tips("no window alloc ")
			break
		}
     }
}

active_reserve(Byref run)
{
	win_active(run.saveid)
	
	if (assist(run, "focus_ctrl")) {
		focus_ctrl(run.ctrl, run.saveid)
    }
}

;注册window的切换，hide和focus可以在后续更改
window_reserve(Byref key, Byref hide=false, Byref focus=false)
{	
	global g_windows
    if (!g_windows)
    	g_windows := {}
          
	;此句必须加上
	set_param(run)
	
	;记录注册进来的title名称
	run.title := 1
	run.saveid := 0
	
    set_assist(run, "focus_ctrl", focus)
    
	set_switch(run, "show|active"
	    , hide ? "hide" : "min", "front_active")
	    
	g_windows.insert(run)
	;run.index := g_windows.MaxIndex()
	
	regist_hotkey(key, "switch_reserve_window", run)
}

;设置全局切换模式
switch_hide_other(hide)
{
	global g_windows
	
	g_windows.hide_other := hide
	tips("set hide other " hide)
}
*/
;==============================================================================
;==============================================================================
; 使用switch group机制
/*
1. 没有注册
2. 注册A，可以只切换A
3. 注册A, 并删除A，与1一致
4. 注册A，再注册b，可以轮流切换
5. 注册A，注册B, 删除A，可以切换B
6. 注册A，注册B, 删除B，可以切换A
7. 注册A，注册B，删除A、B，与1一致
8. 注册A，注册B，注册C，挤掉A
9. 注册A，注册B，切换A，注册C，挤掉B

注：
1. 不使用切换键，直接用其他快捷键进行了切换，也会修改index

使用：
1. 前提是某个窗口已经注册了switch_window 命令
*/

g_switch_group := {}

;如果已经满员了，就替换下一个位置；否则使用空位置
alloc_switch_index()
{
    static g_switch_count := 2
    global g_switch_group
  
    ;未达到指定个数
    if (g_switch_group.MaxIndex() < g_switch_count) {
       index := g_switch_group.MaxIndex() + 1
       
    } else {
       ;替换下一个窗口
       index := next_switch_index()
       
       ;替换当前的窗口
       ;index := g_switch_group[0].curr_index
    }
    return index
}

;在新增或者删除之后，调整窗口的index
reset_switch_index()
{
    global g_switch_group
    for index, v in g_switch_group
    {
        if (!index)
            continue
       
        ;log("move " v.run.switch_group_index " to " index)
        v.run.switch_group_index := index   
    }
}

;更新到下一个有效index
next_switch_index()
{
    global g_switch_group
    index := g_switch_group[0].curr_index
    ;log("------- next switch ------- ")
    
    ;还存在元素时，进行循环
    while (g_switch_group.MaxIndex() > 0) {
        ;循环到最后了，回到第一个
        if (++index > g_switch_group.MaxIndex()) {
            index := 1
        }
        ;log("loop index " index)
        
        ;验证窗口，如果窗口关闭, 或者winid改变了，就删除
        if (g_switch_group[index].run.winid 
            && win_exist(g_switch_group[index].run.winid)) 
        {
            ;log("check index " index " good")
            break
            
        ;删除无效索引
        } else {
            ;log("loop remove index " index)
            g_switch_group.Remove(index)
            
            ;一会儿要index++
            index--
        }              
    }
    
    if (!g_switch_group.MaxIndex())
        index := 0
        
    g_switch_group[0].curr_index := index
    ;log("swtich index to " index)
    return index
}

;更新切换状态
update_switch_state()
{
    ;如果没有注册，或者关闭了该功能，就触发原始功能
    ;if (!switch_status("switch_group")) {
    if (0) {
        send {Alt down}{tab}
        return true
    
    ;使用alt-tab-\方式，将当前窗口加入到切换中来
    } else if (0 ) {
        /*
        check_assist_hotkey("switch_group")
        */
        curr := find_switch_info()
        ;使用当前窗口作为处理
        if (curr) {
            index := change_switch_state(curr.obj, curr.run, curr.handle, true)
            
            ;执行一次切换，确保run.winid有值，否则执行切换时，检查到此index，会被删除
            do_switch_index(index)
        }
        return true
    }
    return false
}

;这里不用检查switch开关, 因为不注册的话, 不会执行到这里来
do_switch_group()
{
    ;log("")
    ;log("do_switch")

    if (update_switch_state())
        return
   
    ;如果此时窗口已经关闭，就不进行切换了
    index := next_switch_index()
    
    if (index != 0) {
        ;在切换之前，记录之前窗口位置
        ;save_curr_state()
    
        do_switch_index(index)
    
        ;切换之后，更新当前窗口位置
        ;load_last_state()
        
    } else {
        ;tips("switch group empty")

        ;这里自动激活上一次active的window，需要打开 assist_window_record_active
        active_last_window()
    }
}

;根据index，激活相应窗口
do_switch_index(Byref index)
{
    global g_switch_group
    curr := g_switch_group[index]

    curr.run.switching_now := 1    
    curr.handle.(curr.obj, curr.run, "mode_show")
}

;根据快捷键调整窗口的switch状态
;   两种方式切换：1）使用alt-tab-/来固定 2）在执行切换时，增加辅助键盘/
change_switch_state(Byref obj, Byref run, Byref handle="switch_window", Byref current=false)
{
    ;log("")
    global g_switch_group
    
    ;加入到switch group中去
    ;   或者是直接关闭了窗口，没有来得及清理run中记录的信息
    if (!run.switch_group_index
        || g_switch_group[run.switch_group_index].run != run) 
    {
        ;找到下一个将要切换的窗口
        index := alloc_switch_index()

        g_switch_group[index] := {}
        g_switch_group[index].obj := obj
        g_switch_group[index].run := run
        g_switch_group[index].handle := handle
        
        ;更新记录的索引
        run.switch_group_index := index
        g_switch_group[0].curr_index := index
        
        ;表明是刚切换，执行do_switch之后，不需要立即next index
        run.switching_now := 1
        ;log("add new index " index)
                
     ;从switch group中删除
     } else {
        index := run.switch_group_index
        
        g_switch_group.Remove(index)
        run.switch_group_index := 0
       
        reset_switch_index()
        ;log("remove index " index) 
    }
    
    if (run.switch_group_index) {
        display := "add " obj.name " to switch group"
    } else {
        display := "del " obj.name " from switch group"
    }
    
    ;注意，不能写run.winid == 0, 可能变量还不存在
    if (current && !run.winid) {
        title := win_title(win_curr())
    } else {
        title := win_title(run.winid)
    }
    if (title)
        title := "`n    " title
        
    tips(display title, 1000)
    return index
}

;当前窗口完成切换后，更新group index
update_switch_group(Byref obj, Byref run)
{
	;检查switch group是否需要调整index
    if (run.switch_group_index) {
        ;表明是在do_switch_group，或者刚切换到此窗口
        if (run.switching_now) {
            run.switching_now := 0
            
        ;表明不是用的switch_group进行的切换，也更新index
        } else {
            ;找到当前窗口所在的index进行
            next_switch_index()
            ;run.switch_group_index
        }
    }
}

;记录最近的、用命令激活的两个window
;上上个：A，上一个：B，当前：C
record_active_window(Byref obj, Byref run)
{
    stat := glob("window", "stat")

    ;A与C不同，A与B也不同
    if (stat.last_active == obj.class) {
        ;log("last " stat.last_active ", now " obj.class)
        stat.last_active := stat.curr_active
    
    ;A、B、C三个都不相同，替换掉A之前的记录，不再需要
    } else if (stat.curr_active != obj.class) {
        ;log("curr " stat.last_active ", now " obj.class)
        stat.last_active := stat.curr_active
    }

    keep := stat.curr_active
    stat.curr_active := obj.class
}

active_last_window()
{
    stat := glob("window", "stat")
    
    ;log("active------------------")
    ;log("last   : " stat.last_active)
    ;log("active : " stat.curr_active)
    ;log("")

    class := win_class()

    ;当前窗口是刚刚激活的，这里激活 last active
    if (class == stat.curr_active) {
        if (stat.last_active) {
            curr := stat.last_active
            ;log("set as last active")
        } else {
            curr := stat.curr_active
        }

    } else {
        if (stat.curr_active) {
            curr := stat.curr_active
            ;log("set as curr active ")

        } else {
            curr := stat.curr_active
        }
    }

    if (!curr) {
        tips("no window actived yet")
        ;log("no window actived yet")
        return

    } else if (class == curr) {
        tips("last and curr same, do nothing")
        ;log("last and curr same, do nothing")
        return 
    }

;    window := find_switch_info(false, curr)
    if (window) {
        ;这里实际上也可以更新window的状态，当前处于激活状态的这个window
        ;   设置为current active

        window.handle.(window.obj, window.run, "mode_show")
        ;log("active window " window.name)

    } else {
        tips("assert, no window to active " curr)
    }

    ;执行之后，会调用 record_active_window，更新记录
}

;记录当前窗口的焦点状态, 通常用在两个窗口都是全屏时比较好
save_curr_state(Byref obj, Byref run)
{
    ;此句是否执行无关紧要, 如果不开启开关，就不会调用这个函数
    ;if (!switch_status("window_track_status")) {
    if (0) {
        return
        
    } else if (!(curr := find_switch_info(false))) {
        return
    }

    ;鼠标在窗口内
    if (mouse_include(x, y)) {
        ctrl := mouse_win_ctrl()
        log("record class " ctrl ", pos " x "-" y)
        
        curr.run.last_x := x
        curr.run.last_y := y
        curr.run.last_ctrl := ctrl
    
    } else {
        log("save but outside")
    }
}

;装载上次记录的窗口位置
load_last_state(Byref obj, Byref run)
{
    ;此句是否执行无关紧要, 如果不开启开关，就不会调用这个函数
    ;if (!switch_status("window_track_status")) {
    if (0) {
        return
        
    } else if (!(curr := find_switch_info(false)) 
       || !curr.run.last_x) {
       return
    }
    
    if (mouse_include(x, y)) {
        ;log("load app" curr.obj.name ", ctrl " ctrl ", pos" curr.run.last_x "-" curr.run.last_x)
        
        mouse_move(curr.run.last_x, curr.run.last_y)
        focus_ctrl(curr.run.winid, curr.run.last_ctrl)
        
    } else {
        tips("load but already moved")
    }
    
    curr.run.last_x := 0
    curr.run.last_y := 0
    curr.run.last_ctrl := 0
}

;================================================================================================
;================================================================================================
regist_dynamic_window_reserve()
{
    ;trigger_group("window_reserve")
    
    regist_hotkey("!Tab", "next_reserve", false)
;   window_reserve("!1")
;   window_reserve("!2")
;   window_reserve("!3")
;   window_reserve("!4")
    
    regist_hotkey(">+Home", "switch_hide_other", 1)
    regist_hotkey(">+End",  "switch_hide_other", 0)
    
    ;trigger_group()
}

