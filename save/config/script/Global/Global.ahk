
#include Constant.ahk
#include Evernote.ahk
#include Chrome.ahk
#include Serial.ahk
#include Input.ahk
#include Handy.ahk
#include Library\Testing.ahk

g_array := {}

global_hotkey()

;hotkey_log("")
;enum_log("")	;Define.ahk
handle_log("")	;Handle.ank
win_log("")	;Window.ahk
app_log("")	;Constant.ahk
;ever_log("")	;Evernote.ahk

;input_log("")	;Input.ank
;sys_log("")   	;System.ahk
;vim_log("")	;Vimium.ahk

;===========================================================

;----------------------------------------------------------
;----------------------------------------------------------
global_hotkey()
{	
	Suspend, on
	; regist default enum and setting
	if (global_define()) {
		return 1
	}

	; regist application info
	if (global_applic()) {
		return 1
	}

	; system level hotkey 
	if (global_system()) {
		return 1
	}

	if (global_handle()) {
		return 1
	}
	Suspend, off

	global_last("hotkey")
}

;==============================================================================
;==============================================================================
global_define()
{
	; system mode define
	global_define_system()

	; define macro in define.ahk
		global_define_macro()
		ahk_status(0)

	; define gbk string
		global_define_gbk()

	; assist hotkey
	global_define_assist()
	
	; hotkey group orefix
	global_define_prefix()

	; inpdefineup regist
    global_define_input()	

    ; dynamic type
    global_define_dynamic()
    
    return global_last("define")
}

;------------------------------------------------------------------------
;------------------------------------------------------------------------
global_define_system()
{
	;SendLevel 1
	SetTitleMatchMode, 2
	SetTitleMatchMode, Fast
	DetectHiddenWindows, on
}

global_define_assist()
{    
	; style0, use left key
    regist_assist("switch_group", 	"\", , , 1)
	regist_assist("single_active", 	"a")
    regist_assist("active_always", 	"up")
    regist_assist("goto_end", 	 	"down", "go end", "no end") 
    ;regist_assist("hide_other", "delete")

	; style0, use right key
    regist_assist("max", 			"home",  "win max", "no max")
    regist_assist("hide", 			"end", 	 "hide", "no hide") 
    regist_assist("focus_ctrl",		"insert", "focus ctrl", "cancel focus ctrl") 
    
    regist_assist("single")
    regist_assist("single_always")
    regist_assist("single_hide")
    regist_assist("single_max")

    regist_assist(opt("glob") "follow_active", 	,	"mouse follow active")
    ;regist_assist(opt("glob") "record_switch",  ,	"switch global group")
    ;regist_assist(opt("glob") "track_status",  	,	"window track status")
    ;regist_assist(opt("glob") "record_active",  ,	"track last active")
}

global_define_prefix()
{
	regist_prefix("win", "assist",  "<^<+")	
	;regist_prefix("win", "mouse",   "<+<#")	
	regist_prefix("win", "mouse",   "<!<^<#")	

	regist_prefix("app", "run",  	"<!<+")	
    regist_prefix("app", "common", 	"<!")  	
    regist_prefix("app", "start",  	">!>^") 
    regist_prefix("app", "collect", "<+!<")
    regist_prefix("app", "tool",   	">^")	
    regist_prefix("app", "system", 	">^>+")	
    
    regist_prefix("note", "common", "<!")   
    regist_prefix("note", "gtd",  	">!")   
}

global_define_input()
{
hotkey_prefix("app", "run")
	regist_input_type("",	"param")
	regist_input_type("r",	"run" )
	regist_input_type("d", 	"path",	"path")
	;regist_input_type("e|n",	"ever", 		"note")
	regist_input_type("e",	"ever", "note")
	;regist_input_type("l", 	"link",	"link")
hotkey_prefix(0)
	
	global_define_instr()

	regist_hotkey("!+i", "serial_execute")
}

global_define_instr()
{
	;config("input", "instr", "space")
input_type("run")
	regist_input_instruct("system",	"system", 	 	"system") 

	;-------------------------------------------------------------------------------------------------------------
	; kill apps
	regist_input_instruct("kill",  	"kill applica",  "close_app") 
	regist_input_instruct("close",  "close process", "close_process") 

	regist_instr_autolist("kill", 	"app")
	regist_instr_autolist("close", 	"process_show" sep("handle"))

input_type("path")
	regist_input_instruct("dir",  	"set dynamic dir",  "set_dynamic_type", "dir") 
	regist_input_instruct("file", 	"set dynamic file", "set_dynamic_type", "file") 
	regist_input_instruct("link",  	"set dynamic link", "set_dynamic_type", "link") 

	regist_input_instruct("set",  	"set dynamic path", "set_dynamic_type", "file | dir | link")
	regist_input_instruct("del",  	"del dynamic path", "del_dynamic_type", "file | dir | link")

	;-------------------------------------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------------------------------------

input_type("ever")
	regist_input_instruct("book",  	"set dynamic book", "set_dynamic_type", "book")
	regist_input_instruct("tags",  	"set dynamic tags", "set_dynamic_type", "tags")
	regist_input_instruct("note",  	"set dynamic note", "set_dynamic_type", "note")
	
	regist_input_instruct("set",   	"set dynamic note", "set_dynamic_type", "note")
	regist_input_instruct("del",   	"del dynamic note", "del_dynamic_type", "note")
input_type(0)
}  

global_define_dynamic()
{
	;----------------------------------------------------------
	; hotkey prefix used for regist fixkey type
hotkey_prefix("app", "tool")
	dync_type("dir",  "path", "set_path")

hotkey_prefix("app", "start")
	dync_type("file", "path", "set_path")

hotkey_prefix("note", "gtd")
	dync_type("note", "ever", "dync_note")
hotkey_prefix(0)

	; thees two no need hotkey
	dync_type("book", "ever", "dync_note")
	dync_type("tags", "ever", "dync_note")

	dync_type("link", "path", "dync_link")
	
	;----------------------------------------------------------
	dync_session_config("serial_", "Serial")
	dync_session_config("input_",  "Input")

	regist_fixkey_type()
}

;==============================================================================
;==============================================================================
global_system()
{
	; system window command
	global_system_work()

	; define ahk operation itself
	global_system_ahk()
	
	; system toolkit
	global_system_tool()

	; global dir info
		global_system_dir()
	
	; viminum mode
		global_system_vimium()
	; serial.ahk
		global_system_serial()
	
	; hotkey group switch
	global_system_delay()

	return global_last("system")
}
   
;------------------------------------------------------------------------
;------------------------------------------------------------------------
global_system_work()
{
	regist_instr_param_list("run", "system", enum_list("system"))

input_type("run")
	handle_list("[lock]		system(lock)" 	help("lock system ")
			,	"[saver]	system(saver)" 	help("screen saver")
			,	"[screen]	system(close)" 	help("screen close")
			,	"[sleep]	system(sleep)" 	help("system sleep")
			,	"[halt]		system(halt)" 	help("system halt")
			,	"[shut]		system(shut)" 	help("shutdown")
			,	"[reboot]	system(reboot)" help("reboot"))

	;-------------------------------------------------------------------------
	;-------------------------------------------------------------------------
	regist_volume()
	
	regist_resize_window()
	;regist_movement()
	;regist_transparent()
	;regist_winsize()
input_type(0)

	regist_mouse_move()
}

; should use direct define
;	handle_list("[~RCtrl]	restore_window(true)"
;			 ,	"[~RAlt]	restore_window(false)"
;			 , 	"[~RShift]	focus_curr")
~RCtrl::restore_window(true)
~RAlt::restore_window(false)

; cancel vim mode
; ~LShift::vim_renew_fast()
~RShift::focus_curr()

; when regist LWIN with a unused key, will not trigger winkey pop-up event, when use #b
LWIN & F12::return

; in case LWIN up and trigger windows action
; ~LWIN Up::return

global_system_tool()
{
input_type("run")
	handle_list("[print_position]	print_position" help("position status")
		,	"[print_mouse ]		print_mouse" 	help("mouse status")
		,	"[print_window]		print_window"	help("window status")
		,	"[print_control]	bind_handle_input(input mark, print_control, 0)" help("window control")
		,	"[print_systime]	print_time"		help("system start time"))

	handle_list("[~!F12] 		top_window"
			 ,	"[>^F12]		switch_win"
			 , 	"[~!delete]		close_current")

	handle_list("[>!,]			system(saver)"
			 ,	"[>^/]			system(close)"
			 ,	"[<^;]			copy_date(true, true)"
			 ,	"[<^']			copy_time"
			 ,	"[<!\]			send_comment"
			 , 	"[<![]			replace_comment")

	;-------------------------------------------------------------------------------------------------------------
	handle_list("[rename]		bind_handle_input(batch rename: mode in [date|create|modify|access]`n`t[prefix] [mode], rename_files)" help("batch rename")
			,	"[dating]		bind_handle_input(batch dating: [prefix], dating_files)" help("batch dating"))

	handle_list("[test_rename]	rename_files(," opt("test") ")" help("test batch rename files")
			   ,"[test_date]	dating_files(," opt("test") ")" help("test batch dating files"))
	
input_type(0)
}

global_system_delay()
{
	; window automate switch record
	switch_window_automate(true)

   	;regist_handle("help", "", "delay group help", "display_regist_delay_help")
    delay_handle_list("<+F12", "", "multi screen move [<+`` | Shift [<^<+F1|<^<+F2]]"
    		; handle means config("handle", "rightly"), trigger rightly
    		;	work in handle_list: if (entry.hotkey == config("handle", "rightly")) {
    		,	"[handle]	change_global_assist(follow_active, 1)"
    		,	"[<+``]		switch_screen_move(true, switch to screen)"
			,	"[<^<+F1 | <#1]	screen_mouse_move(1, true)"
			,	"[<^<+F2 | <#2]	screen_mouse_move(2, true)")
    ;change_global_assist("record_switch", 1)
	;change_global_assist("record_active", 1)
	;assist_window_track_status(1)
	
    ;regist_delay("<+F11", "regist_clip", "global clip or paste [[>] {Ctrl|shift} {F1-F5|1-5}]")
    ;regist_delay("<+F10", "regist_consist_window_reserve", "consist switch [use regist_single_locate]")
    ;regist_delay("<+F9", "regist_dynamic_window_reserve", "dynamic reserve [Alt {1-4|Tab} | >+[home|end]]")        
    ;regist_delay("<+F6", "regist_youd_dict_help", "switch youd_dict [F1 | Active => >^+]")
    ;regist_delay("<+Home", "regist_winsize", "start windows resize")

input_type("run")
	; log open with share, but can't modify record.log when file is opened; 
	;		we can use file_log_close(record), this will close file handle, and modify is allowed
    delay_handle_list("<+F11 | fast_record", "record [<!F1 | F1]; collect [<#F1]", "switch recording" prior(8)
    ;handle_list(
    		;,	"[fast_del_record] 	file_log_del(record)" help("remove record file") prior(8)
    		,	"[F1] 			collect_text_line(record)" help("record file line"))
    		;,	"[<^<!F1] 		file_log_close(record) " sep("comb") "file_open(" global_path("fast", "record") ")"	help("open record file"))

    		; start un-common hotkey for record
    handle_list("[handle]		nothing"
    		,	"[<!F1] 		collect_text_line(record)" help("record file line") 
    		,	"[<^<!F1] 		file_log_close(record) " sep("comb") "file_open(" global_path("fast", "record") ")"	help("open record file"))

    handle_list("[handle]		nothing"
    		;,	"[fast_del_collect] file_log_del(collect)" help("remove collect file")
			,	"[<#F1] 		collect_text_line(collect, date  | exec | text)"	help("collect file line")
			,	"[<^<#F1] 		file_log_close(collect)" sep("comb") "file_open(" global_path("fast", "collect") ")"	help("open collect file"))
	;app_active( "chrome", "[F1]		collect_text_line")

	; copy and paste current select or line
	handle_list("[<#c]			filter_clip(0.1, line,, 1000)")
 	handle_list("[<^<#c]		copy_exec_xshell")
input_type(0)
	
}

erase_handle(Byref name, Byref mode="")
{
	if (if_assist(name) || mode == "hotkey") {
    	; hotkey can't erase, only overwrite
        ;app_log("del dynamic " type ", name [" name "] is hotkey, no need erase input")
        erase_hotkey(name)
        
    } else if (input_type()) {
        erase_input("", name)

    } else {
    	erase_serial(name)
    }

}
;==============================================================================
;==============================================================================
global_handle()
{
	;-----------------------------------------------
	global_handle_assist()

    global_handle_system()

    global_handle_fixkey()

    return global_last("handle")
}

;===========================================================================================
;===========================================================================================
global_handle_assist()
{
hotkey_prefix("win", "assist")
    array := glob("glob", "assist")
    for type, obj in array
    {
        if (obj.key) {
            if (obj.glob) {
                regist_hotkey(obj.key, "change_global_assist", type)
            } else {
                regist_hotkey(obj.key, "change_window_assist", type)
            }
            app_log("regist type [" type "] key " obj.key ", info: " obj.open)
        }
    }
hotkey_prefix(0)
} 

global_handle_system()
{
	dir := glob_sure("glob",  "const",   "dir")
	dir_list("[#e] " dir.explore)

input_type("run")
	hotkey_prefix("app", "collect")	
		handle_list("[u | start_app]	startup_app" 		help("startup app")
				,	"[w | work_env]		work_env" 			help("work enviroment prepare")
				,	"[n | work_notify]	work_notify" 		help("work notify")

				,	"[clearlog]			log_del"  			help("clear log")
				
				,	"[explorer_reset]	reset_explorer"		help("reset explorer")
				;,	"[reset_eyefoo | >!>^F12]	reset_eyefoo" help("reset eyefoo")
				,	"[>!>^F12]			reset_eyefoo" 		help("reset eyefoo")

				,	"[shield]			shield_window"		help("shield or un-shield"))

	hotkey_prefix("app", "system")
		exec_list("[desktop_rdp  | >^>!F6] 	R-Desktop" 		help("desktop computer")
	    		, "[notebook_rdp | >^>!F5] 	R-Notebook" 	help("notebook computer")

				, "[network_auto | >^>!F9]	IP-auto.bat" 	help("network auto")
	    		, "[network_fix  | >^>!F10] IP-fix.bat" 	help("network fix")
	    		, "[network_cab_auto]   IP-cab-auto.bat" 	help("network cab auto")
	    		, "[network_cab_fix]	IP-cab-fix.bat"  	help("network cab fix")

	    		, "[volume_share]		share.bat" 		 	help("share volume") 
	    		, "[volume_close]		share_close.bat" 	help("close share")
	    		, "[ftp|filezilla|>!^f]	start_filezilla.bat(, start ftp)" help("filezilla"))
	hotkey_prefix(0)
input_type(0)
}

global_clear()
{
	; clear the record entry for link_prev or link_next
	local("hotkey", "last", 0)
	local("hotkey", "name", 0)
}

;==============================================================================
;==============================================================================
global_last(Byref type)
{
	if (global_testing(type)) {
		Suspend, off
		return 1
	}

	if (type == "define") {

	} else if (type == "applic") {
		global_define_dync()

		global_applic_tool()
    	global_applic_urls()

    	global_define_snippet()

	} else if (type == "system") {
		
	} else if (type == "handle") {

	} else if (type == "hotkey") {
		ahk_status(2)

		global_clear()

	    global_input_handy()

    	global_serial_handy()
	}
	return 0
}

;===========================================================================
;===========================================================================

global_testing(Byref step)
{
	;Suspend, off
	if (step == "define") {
		if (0) {
			;app_input_test()
			input_test()
			return 1
		}
	} else if (step == "applic") {
		if (0) {
			handle_test()
			return 1
		}
	} else if (step == "hotkey") {
		if (0) {
			regist_example()
			shield_app("ever")
			return 1
		}
	}
}

!9::
DetectHiddenWindows, on
return