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
	;ǿ���л�����,up/down��left/right, home/end
	if (check_assist_hide_mode("", run) || check_assist_focus_ctrl(run) 
		|| check_assist_hide_mode_other(run))
	{
		refresh := 1
		tips("refresh reserve key")
	}
	
	;֮ǰ��ݼ���¼�Ĵ��ڲ�����
	if (run.saveid == 0 || refresh ||
		!Win_Exist(run.saveid))
	{
		if (!refresh && run.saveid != 0) {
			tips( run.title " not exist, switch to new one")
			run.saveid := 0
		}
		
		winid := win_curr()
		;���ⲻһ�£���Ҫ�����л�
		if (run.saveid != winid) {
			run.saveid := winid
			run.title := win_title(winid)     		
			tips("switch to " run.title)
		}
		
		;��Ҫ��λ���ؼ�
		;  ��ʹ����δ�任��Ҳ�����л��ؼ�
		if (assist(run, "focus_ctrl")) {
			;ControlGetFocus, ctrl, A
 			;��ȡ��ǰ����µĿؼ��������Ǽ���ؼ�
 			run.ctrl := mouse_win_ctrl()
 			
 			focus_ctrl(run.ctrl, run.saveid)
 		}		
		return
	}

	;ѡ�񴰿�ʱ���������ã�����������ȫ�����ش���
	if (assist(run, hide_other) || g_windows.hide_other == 1) {
		;������������	
		hide_other(run)
	}
	
	if (do_switch(run.saveid, run, run) 
	    && assist(run, "focus_ctrl")) 
	{
		;����״̬�£���λ�����ڿؼ���
		focus_ctrl(run.ctrl, run.saveid)
	}
}

hide_other(Byref except)
{
	global g_windows
	
	;next���ڲ���Ҫ����Ͳ�������������
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
	 ;��ʼ��last������һ����Ч��indexֵ
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
     	
		;�Ѿ�ѭ����һ�飬��û�ҵ�
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

;ע��window���л���hide��focus�����ں�������
window_reserve(Byref key, Byref hide=false, Byref focus=false)
{	
	global g_windows
    if (!g_windows)
    	g_windows := {}
          
	;�˾�������
	set_param(run)
	
	;��¼ע�������title����
	run.title := 1
	run.saveid := 0
	
    set_assist(run, "focus_ctrl", focus)
    
	set_switch(run, "show|active"
	    , hide ? "hide" : "min", "front_active")
	    
	g_windows.insert(run)
	;run.index := g_windows.MaxIndex()
	
	regist_hotkey(key, "switch_reserve_window", run)
}

;����ȫ���л�ģʽ
switch_hide_other(hide)
{
	global g_windows
	
	g_windows.hide_other := hide
	tips("set hide other " hide)
}
*/
;==============================================================================
;==============================================================================
; ʹ��switch group����
/*
1. û��ע��
2. ע��A������ֻ�л�A
3. ע��A, ��ɾ��A����1һ��
4. ע��A����ע��b�����������л�
5. ע��A��ע��B, ɾ��A�������л�B
6. ע��A��ע��B, ɾ��B�������л�A
7. ע��A��ע��B��ɾ��A��B����1һ��
8. ע��A��ע��B��ע��C������A
9. ע��A��ע��B���л�A��ע��C������B

ע��
1. ��ʹ���л�����ֱ����������ݼ��������л���Ҳ���޸�index

ʹ�ã�
1. ǰ����ĳ�������Ѿ�ע����switch_window ����
*/

g_switch_group := {}

;����Ѿ���Ա�ˣ����滻��һ��λ�ã�����ʹ�ÿ�λ��
alloc_switch_index()
{
    static g_switch_count := 2
    global g_switch_group
  
    ;δ�ﵽָ������
    if (g_switch_group.MaxIndex() < g_switch_count) {
       index := g_switch_group.MaxIndex() + 1
       
    } else {
       ;�滻��һ������
       index := next_switch_index()
       
       ;�滻��ǰ�Ĵ���
       ;index := g_switch_group[0].curr_index
    }
    return index
}

;����������ɾ��֮�󣬵������ڵ�index
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

;���µ���һ����Чindex
next_switch_index()
{
    global g_switch_group
    index := g_switch_group[0].curr_index
    ;log("------- next switch ------- ")
    
    ;������Ԫ��ʱ������ѭ��
    while (g_switch_group.MaxIndex() > 0) {
        ;ѭ��������ˣ��ص���һ��
        if (++index > g_switch_group.MaxIndex()) {
            index := 1
        }
        ;log("loop index " index)
        
        ;��֤���ڣ�������ڹر�, ����winid�ı��ˣ���ɾ��
        if (g_switch_group[index].run.winid 
            && win_exist(g_switch_group[index].run.winid)) 
        {
            ;log("check index " index " good")
            break
            
        ;ɾ����Ч����
        } else {
            ;log("loop remove index " index)
            g_switch_group.Remove(index)
            
            ;һ���Ҫindex++
            index--
        }              
    }
    
    if (!g_switch_group.MaxIndex())
        index := 0
        
    g_switch_group[0].curr_index := index
    ;log("swtich index to " index)
    return index
}

;�����л�״̬
update_switch_state()
{
    ;���û��ע�ᣬ���߹ر��˸ù��ܣ��ʹ���ԭʼ����
    ;if (!switch_status("switch_group")) {
    if (0) {
        send {Alt down}{tab}
        return true
    
    ;ʹ��alt-tab-\��ʽ������ǰ���ڼ��뵽�л�����
    } else if (0 ) {
        /*
        check_assist_hotkey("switch_group")
        */
        curr := find_switch_info()
        ;ʹ�õ�ǰ������Ϊ����
        if (curr) {
            index := change_switch_state(curr.obj, curr.run, curr.handle, true)
            
            ;ִ��һ���л���ȷ��run.winid��ֵ������ִ���л�ʱ����鵽��index���ᱻɾ��
            do_switch_index(index)
        }
        return true
    }
    return false
}

;���ﲻ�ü��switch����, ��Ϊ��ע��Ļ�, ����ִ�е�������
do_switch_group()
{
    ;log("")
    ;log("do_switch")

    if (update_switch_state())
        return
   
    ;�����ʱ�����Ѿ��رգ��Ͳ������л���
    index := next_switch_index()
    
    if (index != 0) {
        ;���л�֮ǰ����¼֮ǰ����λ��
        ;save_curr_state()
    
        do_switch_index(index)
    
        ;�л�֮�󣬸��µ�ǰ����λ��
        ;load_last_state()
        
    } else {
        ;tips("switch group empty")

        ;�����Զ�������һ��active��window����Ҫ�� assist_window_record_active
        active_last_window()
    }
}

;����index��������Ӧ����
do_switch_index(Byref index)
{
    global g_switch_group
    curr := g_switch_group[index]

    curr.run.switching_now := 1    
    curr.handle.(curr.obj, curr.run, "mode_show")
}

;���ݿ�ݼ��������ڵ�switch״̬
;   ���ַ�ʽ�л���1��ʹ��alt-tab-/���̶� 2����ִ���л�ʱ�����Ӹ�������/
change_switch_state(Byref obj, Byref run, Byref handle="switch_window", Byref current=false)
{
    ;log("")
    global g_switch_group
    
    ;���뵽switch group��ȥ
    ;   ������ֱ�ӹر��˴��ڣ�û�����ü�����run�м�¼����Ϣ
    if (!run.switch_group_index
        || g_switch_group[run.switch_group_index].run != run) 
    {
        ;�ҵ���һ����Ҫ�л��Ĵ���
        index := alloc_switch_index()

        g_switch_group[index] := {}
        g_switch_group[index].obj := obj
        g_switch_group[index].run := run
        g_switch_group[index].handle := handle
        
        ;���¼�¼������
        run.switch_group_index := index
        g_switch_group[0].curr_index := index
        
        ;�����Ǹ��л���ִ��do_switch֮�󣬲���Ҫ����next index
        run.switching_now := 1
        ;log("add new index " index)
                
     ;��switch group��ɾ��
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
    
    ;ע�⣬����дrun.winid == 0, ���ܱ�����������
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

;��ǰ��������л��󣬸���group index
update_switch_group(Byref obj, Byref run)
{
	;���switch group�Ƿ���Ҫ����index
    if (run.switch_group_index) {
        ;��������do_switch_group�����߸��л����˴���
        if (run.switching_now) {
            run.switching_now := 0
            
        ;���������õ�switch_group���е��л���Ҳ����index
        } else {
            ;�ҵ���ǰ�������ڵ�index����
            next_switch_index()
            ;run.switch_group_index
        }
    }
}

;��¼����ġ�������������window
;���ϸ���A����һ����B����ǰ��C
record_active_window(Byref obj, Byref run)
{
    stat := glob("window", "stat")

    ;A��C��ͬ��A��BҲ��ͬ
    if (stat.last_active == obj.class) {
        ;log("last " stat.last_active ", now " obj.class)
        stat.last_active := stat.curr_active
    
    ;A��B��C����������ͬ���滻��A֮ǰ�ļ�¼��������Ҫ
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

    ;��ǰ�����Ǹոռ���ģ����Ｄ�� last active
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
        ;����ʵ����Ҳ���Ը���window��״̬����ǰ���ڼ���״̬�����window
        ;   ����Ϊcurrent active

        window.handle.(window.obj, window.run, "mode_show")
        ;log("active window " window.name)

    } else {
        tips("assert, no window to active " curr)
    }

    ;ִ��֮�󣬻���� record_active_window�����¼�¼
}

;��¼��ǰ���ڵĽ���״̬, ͨ�������������ڶ���ȫ��ʱ�ȽϺ�
save_curr_state(Byref obj, Byref run)
{
    ;�˾��Ƿ�ִ���޹ؽ�Ҫ, ������������أ��Ͳ�������������
    ;if (!switch_status("window_track_status")) {
    if (0) {
        return
        
    } else if (!(curr := find_switch_info(false))) {
        return
    }

    ;����ڴ�����
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

;װ���ϴμ�¼�Ĵ���λ��
load_last_state(Byref obj, Byref run)
{
    ;�˾��Ƿ�ִ���޹ؽ�Ҫ, ������������أ��Ͳ�������������
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

