
#include Library/WinTool.ahk

win_log(Byref string)
{
	log("[window]: `t" string)
}

;==============================================================================================
;==============================================================================================
; set or revert window match mode
set_match_mode(Byref cond="", Byref old="", Byref type="")
{
	; the first trigger, set cond, save old option
	if (old) {
		if (old != A_TitleMatchMode) {
			SetTitleMatchMode %old%
		}
	} else {
		old := A_TitleMatchMode
		if (type) {
			SetTitleMatchMode %type%

		; check if cond or text contain *
		} else if (InStr(cond, "*", false, strlen(cond) - 1)) {
			SetTitleMatchMode RegEx
		} 
		;tips(old "-" A_TitleMatchMode)
	}
}

win_default(Byref winid=0) 
{
	if (!winid) {
		winid := win_curr()
	}
	return winid
}

win_min(Byref winid=0)
{
	win_default(winid)

	if (!if_min(winid)) {
    	WinMinimize ahk_id %winid%
    	return true
    }
    return false
}

win_max(Byref winid=0)
{
	win_default(winid)
	if (!if_max(winid)) {
    	WinMaximize ahk_id %winid%
    	return true
    }
    return false
}

win_active(Byref winid=0)
{
	win_default(winid)
	if (!if_active(winid)) {
		WinActivate ahk_id %winid%
		return true
	}
	return false
}

win_hide(Byref winid=0)
{
	win_default(winid)
	if (!if_hide(winid)) {
		WinHide ahk_id %winid%
		return true
	}
	return false
}

win_show(Byref winid=0)
{
	win_default(winid)
	if (if_hide(winid)) {
		WinShow ahk_id %winid%
		return true
	}
	return false
}

win_restore(Byref winid=0)
{
	win_default(winid)
	WinRestore ahk_id %winid%
}

win_close(Byref winid=0)
{
	win_default(winid)
	WinClose, ahk_id %winid%
}
;==============================================================================================
;==============================================================================================
win_exist(Byref winid=0)
{
	win_default(winid)

	return WinExist("ahk_id " winid)
}

win_exist_pid(Byref pid=0)
{
	return WinExist("ahk_pid " pid)
}

win_curr()
{
	WinGet winid, ID, A
	return winid
}

win_winid(Byref class)
{
	set_match_mode(class, old)
	WinGet winid, ID, ahk_class %class%
	set_match_mode(class, old)
	return winid
}

win_winid_title(title)
{
	set_match_mode(title, old)
	WinGet winid, ID, %title% 
	set_match_mode(title, old)
	return winid
}

win_winid_exec(exec)
{
	WinGet winid, ID, ahk_exe %exec% 
	return winid
}

win_winid_pid(pid)
{
	WinGet winid, ID, ahk_pid %pid% 
	return winid
}

win_exec_winid(Byref winid=0)
{
	win_default(winid)

	WinGet exec, ProcessName, ahk_id %winid%
	return exec
}

win_pid_winid(Byref winid=0)
{
	win_default(winid)

	WinGet pid, PID, ahk_id %winid%
	return pid
}

win_pid_exec(Byref exec)
{
	WinGet pid, PID, ahk_exe %exec% 
	return pid
}

win_last(Byref class)
{
	set_match_mode(class, old)
	WinGet winid, IDLast, ahk_class %class%
	set_match_mode(class, old)
	return winid
}

win_title(Byref winid=0)
{
	win_default(winid)

	WinGetTitle, title, ahk_id %winid%
	return title
}

win_text(Byref winid=0)
{
	win_default(winid)

	WinGetText, text, ahk_id %winid%
	return text
}

win_class(Byref winid=0)
{
	win_default(winid)

	WinGetClass, class, ahk_id %winid%
	return class
}

list_win_ctrl(Byref winid=0, Byref mark="", Byref size=0)
{
	array := {}
	win_default(winid)

	WinGet, list, ControlList, ahk_id %winid%
	Loop, Parse, list, `n
	{
		name := A_LoopField

		if (!mark || InStr(name, mark)) {
		    ControlGet, visible, Visible, , %name%, ahk_id %winid%

		  	if (visible) {
			  	item := {}
			  	array[name] := item

			  	if (size) {
				  	ctrl_pos(x, y, w, h, name, winid)
				  	
			        item.x := x
			        item.y := y
			        item.w := w
			        item.h := h
			        item.size := w * h
			        win_log("list win ctrl, loop name [" name "], pos (" x "," y ") size [" w "," h "] = " item.x)

		        } else {
					win_log("list win ctrl, loop name [" name "]")		        	
		        }
		    }
	    }   
	}
	return array
}

win_ctrl(Byref winid=0)
{
	win_default(winid)

	ControlGetFocus, ctrl, ahk_id %winid%
	return ctrl
}

; get mouse position, window winid, current ctrl
mouse_win_ctrl(Byref winid="", Byref x=0, Byref y=0)
{
	MouseGetPos, x, y, winid, ctrl
	return ctrl
}

win_winid_mouse()
{
	mouse_win_ctrl(winid)
	return winid
}

mouse_follow_active(Byref obj="", Byref run="", Byref winid=0)
{
	winid := run.winid
    win_default(winid)

	WinGetPos x, y, w, h, ahk_id %winid%
	mouse_pos(a, b)

	; mouse already included in window
	if (a >= x && a <= x + w 
		&& b >= y && b <= y + h) 
	{
		; log("mouse already included in window")
	} else {
		mouse_move(x + w/2, y + h/2)	
	}
}

win_center_ctrl(Byref winid=0, Byref leave=false)
{
	mouse_pos(sx, sy)

	win_pos(x, y, w, h)	
	mouse_move(x + w/2, y + h/2)
	
	ctrl := mouse_win_ctrl(winid)
	
	if (!leave) {
		mouse_move(sx, sy)
	}

	win_log("window center ctrl, name [" ctrl "]")
	return ctrl
}


;ControlGet, Hwnd, Hwnd, , %ctrl%, ahk_id %winid%
;ControlGet, Exstyle, ExStyle, , %ctrl%, ahk_id %winid%
;ControlGet, LineCount, LineCount, , %ctrl%, ahk_id %winid%
;ControlGetText, text,  %ctrl%, ahk_id %winid%
;==============================================================================================
;==============================================================================================
if_max(winid)
{
	WinGet, S, MinMax, ahk_id %winid%
	return S == 1
}

if_min(winid)
{
	WinGet, S, MinMax, ahk_id %winid%
	return S == -1
	;return DllCall("IsIconic", UInt, winid)
}

if_visible(winid)
{
	return DllCall("IsWindowVisible", uint, winid) == 1	&& !if_hide(winid)
}

class_active(Byref class)
{
	set_match_mode(class, old)
	IfWinActive ahk_class %class% 
	{
		ret := true
	} else  {
		ret := false
	}
	set_match_mode(class, old)
	return ret
}

if_active(winid)
{
	return WinActive("ahk_id " winid)
}

if_top(winid)
{
	;WS_EX_TOPMOST 0x00000008L
	return check_style(winid, 0x8, true)
}

if_hide(winid)
{
	;WS_VISIBLE 0x10000000L
	return !check_style(winid, 0x10000000)
}

check_style(Byref winid, Byref value, extend=false)
{
	if (!extend) {
		WinGet, style, Style, ahk_id %winid%
	} else {
		WinGet, style, ExStyle, ahk_id %winid%
	}

	return ((style & value) == value)
}

;==============================================================================================
;==============================================================================================
;0-active
;1-not minimize, not hide
;2-not minimize, top state
if_front(winid, mode="")
{
	if (if_active(winid)) {
		return !if_min(winid)

	} else {
		if (enum(mode, "switch", "front_none_min")) {
			return !if_min(winid) ;&& !if_hide(winid)
		
		} else if (enum(mode, "switch", "top_front_none_min")) {
			if (if_top(winid)) {
				return !if_min(winid)
			}
		}
	}
	return false	
}

show_window(Byref winid, Byref mode)
{
	if (enum(mode, "switch", "show")) {
		win_show(winid)
	}
	
	if (enum(mode, "switch", "active")) {
		win_active(winid)
	}
		
	if (enum(mode, "switch", "restor")) {
		win_restore(winid)
	}

	if (enum(mode, "switch", "max")) {
		win_max(winid)
	}
}

hide_window(Byref winid, Byref mode)
{
	; if try nothing, and not set hide mode, will fill with default mode "min"
	if (enum(mode, "switch", "none")) {
		; do nothing;
	}

	if (enum(mode, "switch", "min")) {
		win_min(winid)
	}
		
	if (enum(mode, "switch", "hide")) {
		win_hide(winid)
	}

	if (enum(mode, "switch", "close")) {
		win_close(winid)
	}
	;PostMessage, 0x112, 0xF060,,,ahk_id %winid%
}

/*
check_assist_switch_group(Byref obj, Byref run)
{
    if (!switch_status("switch_group")) {
        return
    }
    
 ;   if (check_assist_hotkey("switch_group")) {
  ;      change_switch_state(obj, run) 
  ;      return true
  ;  }
  ;  return false
}
*/
;==============================================================================================
;==============================================================================================

auto_find_handle(Byref obj, Byref run="")
{
	default(run, obj)
	if (get_window_handle(run, "find")) {
		win_log("app [" obj.name "] already have handle, ignore")
		return
	}

	if (obj.class) {
		if (run.title || run.text) {
			handle := "find_class_title_handle"
		} else {
			handle := "find_class_handle"
		}

	} else if (obj.title) {
		handle := "find_title_handle"
	
	} else {
		warn("auto find handle, can't match any, app [" obj.name "]")
		return
	}

	win_log("auto find handle, app [" obj.name "] <" handle ">")
	return handle
}

;----------------------------------------------------------------------------
find_class_handle(Byref obj, Byref run)
{	    
	;find by winid
	if (run.winid && obj.class == win_class(run.winid)) {
		win_log("find_class_handle: old winid match, no need find again")

	} else {
		class := obj.class
		
		if (!obj.last_window) {
			run.winid := win_winid(class)
			
		} else {
			run.winid := win_last(class)
		}
	}
    return run.winid
}

;----------------------------------------------------------------------------
find_class_title_handle(Byref obj, Byref run)
{  
	if (!(entry := get_window_handle(run, "match"))) {	
		if (init(default, "window", "match_class")) {
			set_handle(default, "match_text_handle")
		}
		entry := default
	}

	class := run.class ? run.class : obj.class
	win_log("use [find_class_title_handle] as find handle, match <" get_handle(entry) ">")

	if (run.winid && win_class(run.winid) == obj.class
	    && handle_work(entry, run.winid, run)) 
	{
	    win_log("find class title handle, old winid match, not changed")
		return run.winid
	}
	run.winid := 0	

	set_match_mode(class, old)
	WinGet id, list, ahk_class %class%
	set_match_mode(class, old)

	Loop, %id%
	{
	    winid := id%A_Index%

	    if (handle_work(entry, winid, run)) {
	    	run.winid := winid
	    	win_log("find class title handle, title " win_title(winid))
		    break
	    }
	    ;g_log("find class title handle, check title " win_title(winid))
	}
	;g_log("find class title handle, end")
	return run.winid
}

match_text_handle(winid, Byref run)
{	
	if (run.text) {
		string := win_text(winid)
		match := run.text
		
		win_log("`t match match_text_handle, text [" match "], win text [" string "]")
		
	} else {
		string := win_title(winid)
		match := run.title
		
		win_log("`t match match_text_handle, title [" match "], win title [" string "]")
	}	
	return string ? InStr(string, match) : false
}

/*
win_text_line_match(winid, Byref run)
{
	string := win_text(winid)
	match := run.text "`r`n"
		
	win_log("`t match win_text_line_match, title " match ", win title " string)
	return string ? InStr(string, match) : false
}
*/

;----------------------------------------------------------------------------
find_title_handle(Byref obj, Byref run)
{    
	set_match_mode(run.title, old, 2)

	if (!run.winid || !InStr(win_title(run.winid), run.title)) {
		title := run.title
    	WinGet winid, ID, %title%
    	run.winid := winid
    	
    	win_log("find title handle, title not match, change winid to " run.winid)
    }
  
    set_match_mode(run.title, old)
    return run.winid
}
/*
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
find_class_ctrl_handle(Byref obj, Byref run)
{
    win_log("find handle find_class_ctrl_handle")
    
	class := obj.class
	ctrl  := substr(obj.ctrl, 1, obj.ctrl_match_handle)
	
	set_match_mode(class, old)
	WinGet id_list, list, ahk_class %class%
	set_match_mode(class, old)

	Loop, %id_list%
	{
		if (check_app_ctrl(id_list%A_Index%, ctrl)) {
			run.winid := id_list%A_Index%
			return run.winid
		}
	}
	run.winid := 0
	return run.winid
}
    
check_app_ctrl(Byref winid, Byref ctrl)
{
	WinGet, list, ControlList, ahk_id %winid%
	Loop, Parse, list, `n
	{
		if (InStr(A_LoopField, ctrl)) {
			;tips("find")
			return true
		}
	}
	return false
}
*/

find_exec_handle(Byref obj, Byref run)
{
	run.winid := win_winid_exec(run.exec)
	;log(win_title(run.winid) "|" win_class(run.winid))
	return run.winid
}

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
get_winid(Byref obj, Byref run="")
{
	default(run, obj)
		
	; notice: must be here
	DetectHiddenWindows, on

	if (!run.winid) {
		run.winid := 0
	}

	old_winid := run.winid
	if (!(entry := get_window_handle(run, "find")) 
	 	&& !(entry := get_window_handle(obj, "find"))) 
	{
		warn("get winid, app [" obj.name "] find handle not set")
		return 0
	}

	win_log("get winid, app [" obj.name "] handle [" entry.handle "], old winid " old_winid) 
	handle_work(entry, obj, run)

	if (run.winid) {
		if (old_winid == run.winid) {
			win_log("get winid, app [" obj.name "] state not change")
		} else {
			tips("change id", 300)
			win_log("change id [" old_winid " -> " run.winid "]")
		}
	} else {
		if (old_winid) {
			if (enum(run, "option", "none_start")) {
			    win_log("get winid, app [" obj.name "] still not exist")

			} else {
				tips("no longer exist", 1000)
			    win_log("get winid, app [" obj.name "] no longer exist")
			}
		} else {
			win_log("get winid, app [" obj.name "] old and new is 0")
		}
	}

	DetectHiddenWindows, off
	return run.winid
}

opt_win_group(Byref class, handle)
{
	set_match_mode(class, old)
	WinGet id, list, ahk_class %class%
	set_match_mode(class, old)
	Loop, %id%
	{
	    winid := id%A_Index%
	    handle.(winid)
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
/*
start_param(Byref obj, Byref run)
{
	if (!obj.path && !run.param)
		return
	
	if (obj.path) {
		total := obj.path " " run.param
		
	} else {
		total := run.param
	}
		
	;tips(total, 3000)
	return total
}

wait_app()
{
	if (!obj.wait_class) {
		return 0
	}
		
	static temp := {}
	temp.class := obj.wait_class
	
	winid := get_winid(temp)
	if (!winid) {
		tips("wait window not exist")
		return 0
	}
    tips("wait window in progress")
    return winid
}
*/

none_start(Byref obj, Byref run, Byref opti)
{
    if (enum(obj, "option", "none_start") || enum(opti, "option", "none_start")) {
		win_log("get no_start flag, no need start [" obj.name "]")
		return 1

	} else if (!obj.path && !run.param) {
		tips("no need start window [" obj.name "]")
		return 1

	} else if (obj.path == const("applic", "not_install")) {
		tips("not install")
		return 1
	}
	return 0
}

start_app(Byref obj, Byref run)
{
	if (obj.path) {
		if (obj.param && obj != run) {
			param := obj.param " " run.param
		} else {
			param := run.param
		}

	} else {
		tips("no path, only param <" run.param ">")
		return 0
	}

	tips("app start")
	execute_path(obj.path, param)

	sleep 200
	return 1
}

start_window(Byref obj, Byref run, Byref opti, ByRef new_start)
{
	if (!(winid := get_winid(obj, run))) {

		if (none_start(obj, run, opti)) {
			return 0
		
		} else if (start_app(obj, run)) {

			if ((winid := get_winid(obj, run))) {
				win_log("start window, get winid " winid)
				run.show_state := 1
				
			} else {
				win_log("start window, not get winid yet")
			}
			new_start := true
		}
	}
	return winid
}

close_current()
{
	if (!master_dual(0.3)) {
		return
	}
	winid := win_curr()
	kill_winid(winid)
}

top_window(winid="", mode=0)
{
	if (!winid) {
		winid := win_curr()
	    if (!winid) {
	        tips("no active window", 1000, true)
	        return
	    }
    }

  	curr := win_title(winid)
  	if (mode == 0) {
  		mode := !if_top(winid)
  	}
 
    if (mode == 0) {
    	WinSet, AlwaysOnTop, off, ahk_id %winid%
		tips("Canel top: """ curr """", 700)
		
    } else {
		WinSet, AlwaysOnTop, on, ahk_id %winid%
        tips("Set on top: """ curr """", 700)
	}
	return winid
}

;==============================================================================================
;==============================================================================================
switch_window(Byref obj, Byref run="", Byref mode="mode_switch", Byref opti=0)
{
	if (!obj.init) {
		warn("switch window, obj [" obj.name "] not registed")
		return 0

	} else if (!enum_type("switch", mode, false)) {
		warn("can't parse switch mode " mode)
		return 0
	}
	default(run, obj)

	winid := start_window(obj, run, opti, new_start)

	if (new_start) {
		win_log("new start")
		start_wait(winid, obj, run)
	
	} else {
		if (winid == 0) {
		    win_log("start but not find window")
    		return 0
    	} 
		if (do_switch(winid, obj, run, mode) == -1) {
			return 0
		}
	}
	
	if (do_window_handle(run.show_state ? "active" : "deactive", obj, run) == -1) {
		return 0
	}
	return winid
}

do_switch(Byref winid, Byref obj, Byref run="", mode="mode_switch")
{
    default(run, obj)

    if (do_window_handle("switch", obj, run) == -1) {
    	win_log("global handle: window switch return -1, no need do the left")
    	return -1
    }
 
    ;if (globa_assist("window_active_always") 
    ;    || assist(run, "active_always")) 
    if (assist(run, "active_always")) {
        mode := "mode_show"
        win_log("do switch, keep always active")
    }

	temp := !run.show ? obj : run
	if (mode == "mode_switch") {

		if (if_front(winid, temp.front)) {
			mode := "mode_hide"
		
		} else {
			mode := "mode_show"
		}
	}

	handle_mode := mode == "mode_show" ? "pre_active" : "pre_deactive"
	if (do_window_handle(handle_mode, obj, run) == -1) {
		win_log("global handle: window " handle_mode " return -1, no need do the left")
    	return -1
    }

	if (mode == "mode_show") {

		if (do_window_handle("show", obj, run)) {
			win_log("do switch, excute show handle")
		} else {
			show_window(winid, temp.show)
		}
		run.show_state := 1

	} else {

		if (do_window_handle("hide", obj, run)) {
			win_log("do switch, excute hide handle")
		} else {
			hide_window(winid, temp.show)
		}
		run.show_state := 0
	}

	return run.show_state
}

start_wait(Byref winid, Byref obj, Byref run)
{
	temp := !run.show ? obj : run

	if (obj.start_wait > 0) {
		win_log("new start and wait active")
		count := obj.start_wait * 10
		
		while(1) {
			show_window(winid, temp.show)
		
			if (if_active(winid)) {
				win_log("start wait, total [" obj.start_wait * 10 - count "]")
				return	
				
			} else if (--count <= 0) {
				win_log("start wait, start exceed " obj.start_wait * 10)
				return
			}
			
			if (!winid) {
				winid := get_winid(obj, run)
				win_log("start wait, get winid [" winid "]")
			}
			
			;WinWaitActive ahk_id %winid%
			sleep 100
		}
	
	} else if (obj.start_wait == -1) {
		win_log("new start hide")
		hide_window(winid, temp.show)
	}
}

switch_window_mute(Byref obj, Byref run="", Byref mode="mode_switch", Byref opti=0)
{	
	old := display(0)
	switch_window(obj, run, mode, opti)
	display(old)
}

;==============================================================================================
;==============================================================================================
ctrl_entry_name(Byref name="")
{
	default(name, const("ctrl", "name"))
	return "ctrl_" name
}

update_ctrl_origin(Byref obj, Byref name, Byref recover=false, Byref mutable=0)
{
	present := ctrl_entry_name(name)
	entry := sure_item(obj, present)

	if (recover)  {
    	app_log("====> update ctrl origin, recover ctrl <" name "> name [" obj[name] "] -> [" entry.name "]")

    	if (entry.name) {
    		obj[name] := entry.name 
    	}

    	if (mutable) {
    		;app_log("update ctrl name, always mutable, recover old name [" entry.name "]")

    	} else {
    		any_data(obj, present, "succ", 0)
    	}

    } else {
    	app_log("<==== update ctrl origin, record ctrl <" name "> name [" obj[name] "]")
    	entry.name := obj[name]

    	if (mutable) {
    		;app_log("update ctrl name, always mutable, record name [" entry.name "]")

		} else {
			any_data(obj, present, "succ", 1)
		}
    }
}

update_ctrl_name(Byref obj, Byref run, Byref name)
{
	present := ctrl_entry_name(name)
	if (any_data(obj, present, "succ")) {
		return true

	} else if (!(entry := get_window_handle(obj, present))) {
		if (obj[name]) {
			app_log("  update ctrl name, use preset ctrl name [" obj[name] "]")
			return true
		} else {
			return false
		}
	} else if (!(winid := run.winid)) {
		info("  update ctrl name, but winid 0", 500)
		return false
	}

	if ((mutable := any_data(obj, present, "muttable"))) {
		update_ctrl_origin(obj, name, true, mutable)
	}

	win_log("  update ctrl name, app [" obj.name "] ctrl <" name "> name [" obj[name] "], handle [" entry.handle "]")
	if ((ctrl := handle_work(entry, obj, run, obj[name]))) {
		; record origin ctrl name, if find failed, recover
		update_ctrl_origin(obj, name, false, mutable)		
		
		obj[name] := ctrl
		return true

	} else {
		info("  update ctrl, but find nothing for ctrl [" obj[name] "]", 1000, true)
		return false
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
ctrl_find_match(Byref obj, Byref run, Byref ctrl)
{
	array := list_win_ctrl(run.winid, ctrl)

	for name, item in array 
	{
		if (!entry.handle || handle_work(entry, obj, run, item)) {
            win_log("ctrl find match, base [" ctrl "], handle [" entry.handle "]")
            return name
    	}
	}
	return ""
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
ctrl_find_center_fetch(Byref obj, Byref run, Byref ctrl)
{
	if ((curr := ctrl_find_center(obj, run, ctrl))) {
		ctrl := ctrl_find_fetch(obj, run, curr)
		
	} else {
		ctrl := curr
	}
	return ctrl	
}

ctrl_find_center(Byref obj, Byref run, Byref ctrl)
{
	ctrl := win_center_ctrl(winid)

	; only check if winid not match
	if (run.winid != winid) {

		if (run.winid) {
			win_log("ctrl find center, but current winid [" winid "], title <" win_title(winid) "> not match [" run.winid "]")
			return ""

		} else if (obj.class && InStr(class := win_class(winid), obj.class)) {
			win_log("ctrl find center, but current class [" class "] not match [" obj.class "]")
			return ""
		}
	}	

	win_log("ctrl find center, get ctrl [" ctrl "]")
	return ctrl
}

ctrl_find_fetch(Byref obj, Byref run, Byref ctrl)
{
	; for display
	origin := ctrl

	winid := run ? run.winid : obj.winid
	if (focus_ctrl(winid, ctrl)) {
		log("ctrl find fetch, origin [" origin "], retry and get ctrl [" ctrl "]")
		
	} else {
		log("ctrl find fetch, origin [" origin "], but focus ctrl failed")
	}
	ctrl := win_ctrl(winid)

	log("ctrl find fetch, update ctrl to curr focus [" ctrl "]")
	return ctrl	
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
/*
ctrl_find_sytle_and_center(Byref obj, Byref run, Byref ctrl, Byref match_style)
{
	winid := run.winid
	
    ControlGet, style, Style, , %ctrl%, ahk_id %winid%

    if (style & match_style) {
        win_center(winid, px, py)

		# should check if current window is match
 		ctrl_pos(x, y, w, h, ctrl, winid)
        if (check_include(px, py, x, y, w, h)) {
            ;log("---" ctrl " :" x "," y " - " w "," h " style " style ", hwnd " hwnd)
    	    return ctrl
    	}
    }
    return ""       
}
*/
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
ctrl_find_maxsize(Byref obj, Byref run, Byref ctrl)
{
	array := list_win_ctrl(run.winid, ctrl, 1)

	last := 0
	for name, item in array 
	{
		if (last < item.size) {
			last := item.size 
			data := name
		}
	}
	ctrl := ctrl_find_fetch(obj, run, data)
	log("ctrl find max, name [" ctrl "] size " last)
	return ctrl
}

;=============================================================================================================
;=============================================================================================================
ctrl_focus_handle(Byref obj, Byref run, Byref name="", Byref mode=0, winid=0)
{   
	; make sure we can get ctrl name from winid
	app_attach_winid(obj.name, winid, run)

	if (get_ctrl_name(obj, run, name)) {
		default(winid, run.winid)
		
		if (focus_ctrl(winid, obj[name], mode)) {
			return 1

		} else {
			; if failed, reset to origin ctrl name and search mode
			update_ctrl_origin(obj, name, true)
		}
	}
	return 0
}

ctrl_send_handle(Byref obj, Byref run, Byref key, Byref name="", winid=0)
{   
	; make sure we can get ctrl name from winid
	app_attach_winid(obj.name, winid, run)
	if (get_ctrl_name(obj, run, name)) {

		default(winid, run.winid)
		return do_send_ctrl(winid, obj[name], key)

	} else {
		return 0
	}
}

ctrl_click_handle(Byref obj, Byref run, Byref name="", winid=0)
{   
	; make sure we can get ctrl name from winid
	app_attach_winid(obj.name, winid, run)
	if (get_ctrl_name(obj, run, name)) {

		default(winid, run.winid)
		return do_click_ctrl(winid, obj[name], true)

	} else {
		return 0
	}
}

get_ctrl_name(Byref obj, Byref run, Byref name="")
{
	default(name, const("ctrl", "name"))
	if (obj[name]) {
		;log("get ctrl name, try to focus ctrl [" obj[name] "], maybe name need update")
		if (update_ctrl_name(obj, run, name)) {
			return 1
		}

	} else {
		win_log("get ctrl name, ctrl not set")
	}
	return 0
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
focus_ctrl(Byref winid, Byref ctrl, Byref mode_str=0)
{
	if (!ctrl) {
		return 0
	}
	default(mode_str, "first_check|done_check")
	;default(mode_str, "done_check")
	;default(mode)
	set_enum(mode, "ctrl", mode_str)

    if (enum(mode, "ctrl", "first_check") 
    	|| enum(mode, "ctrl", "only_check")) 
    {
        if (focus_ctrl_check(winid, ctrl)) {
        	win_log("focus ctrl, first check success, curr ctrl [" ctrl "]")
        	return true

        } else if (enum(mode, "ctrl", "only_check")) {
        	win_log("focus ctrl, first check failed, but only check, curr [" win_ctrl(winid) "]")
        	return false

        } else {
        	win_log("focus ctrl, first check, curr ctrl [" win_ctrl(winid) "], winid " winid)
        }
    }

   	if (do_focus_ctrl(winid, ctrl, enum(mode, "ctrl", "done_check"))) {
		focus := true   
    
    } else if (!enum(mode, "ctrl", "none_click")) {
    	focus := do_click_ctrl(winid, ctrl, true)
        ;win_log("focus ctrl, try click [" ctrl "]")
    }
    return focus
}

focus_ctrl_check(Byref winid, Byref ctrl)
{
	return win_ctrl(winid) == ctrl
}

;=============================================================================================================
test_ctrl(Byref winid, Byref ctrl, Byref more, Byref type)
{
	if (win_ctrl(winid) == ctrl || win_ctrl(winid) == more) {
		win_log("test ctrl <" type ">, match [" ctrl "]")
		return true

	} else {
		win_log("test ctrl <" type ">, not on [" ctrl "], but [" win_ctrl(winid) "]")
		return false
	}
}

test_focus_ctrl(Byref ctrl="", Byref more="")
{
	winid := win_curr()
	default(ctrl, mouse_win_ctrl())

	win_log("")
	win_log("test focus ctrl, origin [" win_ctrl(winid) "]")

	ControlFocus, %ctrl%, ahk_id %winid%
	if (test_ctrl(winid, ctrl, more, "focus")) {
		;return true
	}
	
	ControlClick, %ctrl%, ahk_id %winid%
	if (test_ctrl(winid, ctrl, more, "click")) {
		return true
	}

;	win_log("test focus ctrl, failed")
	return false
}

; !a::test_focus_ctrl()

;=============================================================================================================

do_focus_ctrl(Byref winid, Byref ctrl, Byref check=false)
{
	;SetControlDelay 100
	ControlFocus, %ctrl%, ahk_id %winid%

    if (errorlevel != 0) {
        info("do focus ctrl, on [" ctrl "] failed, error: [" ErrorLevel "], current <" win_ctrl(winid) ">", 2000, true)
        return false
    } 

   	if (check) {
   		if (!focus_ctrl_check(winid, ctrl)) {
	   		win_log("do focus ctrl, on [" ctrl "], but check focus failed, current <" win_ctrl(winid) ">")
	   		return false
	   	}

	; for debug, just outpt info
   	} else {
   		if (!focus_ctrl_check(winid, ctrl)) {
   			win_log("`n+++++ do focus ctrl, current active control [" win_ctrl(winid) "], not match ++++++`n")
   		}
   	}

    win_log("do focus ctrl, on [" ctrl "] success")
 	return true
}

do_click_ctrl(Byref winid, Byref ctrl, Byref check=false)
{
	ControlClick, %ctrl%, ahk_id %winid%

	if (errorlevel != 0) {
		info("do click ctrl, but click [" ctrl "] winid [" winid "] failed, error: [" ErrorLevel "], current <" win_ctrl(winid) ">", 2000, true)
		return false
	}
     
    if (check) {
   		if (!focus_ctrl_check(winid, ctrl)) {
	   		win_log("do click ctrl, on [" ctrl "] winid [" winid "], but check focus failed")
	   		return false
	   	}
   	} 
    win_log("do click ctrl, on [" ctrl "] success")
 	return true
}

do_send_ctrl(Byref winid, Byref ctrl, Byref keys)
{
	ControlSend %ctrl%, %keys%, ahk_id %winid%
	if (errorlevel != 0) {
        info("do send ctrl, send to [" ctrl "] failed, error: [" ErrorLevel "]", 2000, true)
        return false
    }
    win_log("do send  ctrl, send [" keys "] to [" ctrl "] success")
    return true
}

/*
ctrl_text(Byref winid, Byref ctrl, Byref text)
{
	Control, EditPaste, %text%, %ctrl%, ahk_id %winid%
	if (errorlevel != 0) {
        tips("set ctrl " ctrl " text failed ", 2000)
        return false
    }
    return true
}

click_for_focus(Byref obj, Byref run)
{
	move_back := false

	if (move_back) {
		mouse_pos(sx, sy)
	}

	win_center(run.winid, x, y, true)
	mouse_move_fast(x, y)

	CoordMode, mouse, window
    MouseClick, left
    CoordMode, mouse, screen

	if (move_back) {
		mouse_move_fast(sx, sy)
	}
}
*/

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
kill_winid(Byref winid)
{
	DetectHiddenWindows, on

	if (win_exist(winid)) {

		WinClose, ahk_id %winid%, , 0.5
		if (win_exist(winid)) {

			WinKill, ahk_id %winid%, , 0.5
			
			if (win_exist(winid)) {
				win_log("kill window, kill winid [" winid "], still exist")
				succ := 0

			} else {
				win_log("kill window, kill winid [" winid "]")
				tips("kill window")
				succ := 1
			}
		} else {
			sleep 10000
			tips("close window")
			succ := 1
		}

	} else {
		win_log("kill window, window not exist")
		succ := 1
	}
	DetectHiddenWindows, off
	return succ
}

;==============================================================================================
;==============================================================================================
restore_window(max=true, time=0.5, hide=false)
{
	if (!master_dual(time)) {
		return
    }
    
	static desktopid := 0
	if (desktopid == 0) {
		;desktopid := win_winid("Progman")
		desktopid := win_winid("WorkerW")
		toolbarid := win_winid("Shell_TrayWnd")
	}
	winid := win_curr()
	
	if (!winid) {
	    tips("no active window", 1000, true)
	    return
	    
	} else if (winid == desktopid 
		|| winid == toolbarid)
	{
		tips("ignore desktop")
		return
	}

	if (max) {
		if (if_max(winid)) {
			win_restore(winid)

		} else {
			win_max(winid)
		}
		
	} else {
		static lastid := 0

		if (lastid != 0 && win_exist(lastid)) {
			winid := lastid
		}
			
		if (if_min(winid)) {

			win_restore(winid)
	    	lastid := 0

	    } else {
	    	win_min(winid)
	    	lastid := winid
	    	
	    }
	}
}

;==============================================================================================
;==============================================================================================
set_switch(Byref obj, show="", hide=""
	, front="", start_wait=0)
{
	default(show, "show|active")
	default(hide, "min")

	obj.show := {}
	obj.front := {}

	set_enum(obj.show,  "switch", show)
	set_enum(obj.show,  "switch", hide)
	set_enum(obj.front, "switch", front)

	assist_match_switch_mode(obj, "hide")
	assist_match_switch_mode(obj, "max")

	obj.winid := 0
	obj.init := 1
	obj.start_wait := start_wait
	return 1
}

; keep entry assist value status, match enum switch status
assist_match_switch_mode(Byref obj, Byref type)
{
	if (enum(obj.show, "switch", type)) {
		set_assist(obj, type)
	}
}


set_param(Byref obj, Byref title="", Byref text="", Byref param="")
{
	default(obj)
		
	obj.title := title
	obj.text  := text
	obj.param := param
}

window_handle(Byref entry, Byref name, Byref handle, Byref arg*)
{
	if (handle) {
		; add tail flag, any exist param move to the end, when execute
    	add_type_handle(entry, "window", name, handle sep("tail"), arg*)
    }
}

del_window_handle(Byref entry, Byref name)
{
	; add tail flag, any exist param move to the end, when execute
	del_type_handle(entry, "window", name)
}

get_window_handle(Byref entry, Byref name, index=1)
{
	return get_type_handle(entry, "window", name, index)
}

do_window_handle(Byref name, Byref obj, Byref run="")
{
    if (do_type_handle("object", obj, "window", name, obj, run) == -1) {
    	return -1
    }
    ;object_handle_print(obj, "window", name)

    if (obj != run) {
	    if (do_type_handle("runtime", run, "window", name, obj, run) == -1) {
	    	return -1
	    }
	    ;object_handle_print(run, "window", name)
	}

	if (do_global_handle("global", "window", name, obj, run) == -1) {
		return -1
	}
	return 0
}
;================================================================================
;================================================================================


