

;===============================================================================================
;===============================================================================================
word_obj(Byref obj, Byref path)
{
	if (!obj) {
		if (!Instr(path, ".doc")) {
			path = %path%.docx
		}
		title := file_name(path)

		set_param(obj, title, "", path)
	}
}

regist_word(Byref key, Byref path)
{
	word_obj(obj, path)	
	regist_hotkey(key, "switch_window", glob_app("word"), obj)
}

;==============================================================================================
;==============================================================================================
; automately trigger qq
remind_qq(timer = -1)
{
	if (timer == -1) {
		timer := 30 * 60
	}
	if (timer == 0) {
		SetTimer, reminder_qq_label, Off
		tips("cancel remainder")

	} else {
		actrual := timer * 1000
		SetTimer, reminder_qq_label, %actrual%
		tips("add qq remainder " (timer > 60 ? (timer/60 & 0xFFFFFFFF " min") : (timer " second"))) 
	}
}

reminder_qq_label:
	idle := 60000
	; idle including mouse and keyboard; IdlePhysical not including blue-teath mouse
	if (A_TimeIdle > idle * 2 || A_TimeIdlePhysical > idle * 10) {
		;log("idle time " A_TimeIdle ", Physical " A_TimeIdlePhysical ", ignore")
		return
	}

	winid := get_winid(glob_app("qq"))
	if (winid) {
		waittime := 5
		tips("try to trigger qq in " waittime " second", waittime * 1000)

		;WinActivate, "qq"
		; or test if_active
		count := 0
		while (count++ < 5 && if_hide(winid)) {
			send ^!z	
			sleep 500
		}
		sleep 1000

		if (!if_hide(winid)) {
			tips("minimize")
			win_min(winid)	
		}
	}
return

;==============================================================================================
;==============================================================================================
; left alt minimize foxmail
foxmail_minimize(key="")
{
	old := display(0)
	if (key) {
		sendinput %key%
	}	

	winid := app_winid("foxmail")
	if (winid && if_visible(winid)) {
		switch_app("foxmail", "mode_hide")

	} else {
		app_log("foxmail already hide")
	}
	display(old)
	return
}

foxmail_hide_self()
{
	send_raw("^+!o")
}

;==============================================================================================
;==============================================================================================
switch_youd_dict(copy=false, clean=false)
{
	if (copy) {

		if (if_app_actived("youd_dict")) {
			; for double shift, when active, do clean
			if (clean) {
				youd_dict_clean()
				return
			}

		} else {
			if (get_clip(0.2, "line")) {
				line := RTrim(Clipboard, " ")
			}
		}
	}
	switch_app("youd_dict")
		
	if (glob_app("youd_dict").show_state) {

		if (copy && line != "") {
			sendinput {delete}

			paste(line)
			; sleep 100
			sendinput {Enter}
		}
	}
}

youd_dict_esc()
{
	; sendinput {Esc}
	sendinput ^{A}
	sendinput {delete}
}

youd_dict_clean()
{
	sendinput {Esc}
}

;----------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------
foxit_focus_handle(click=false)
{
	entry := glob_app("foxit")
	if (entry.winid == 0) {
		entry.winid := win_curr()
	}
	if (click) {
		ctrl_click_handle(entry, entry)
	} else {
		ctrl_focus_handle(entry, entry)
	}
	;sendinput {esc 2}
	return 0
}

foxit_mouse(Byref action, Byref arg*)
{
	mouse_action(action, "foxit_mouse_handle", arg*)
}

foxit_mouse_handle()
{
	if (once("foxit", "get_ctrl")) {
		foxit_focus_handle()
	}

	; in select mode, do nothing
	if (!mouse_type()) {
		; IBeam, Arrow or other type
		log("foxit mouse handle, mouse type [" A_Cursor "], do nothing")
		return false
	
	} else if ((ctrl := win_ctrl()) && !InStr(ctrl, "BCGPTab") && !InStr(ctrl, "AfxWnd")) {
		log("foxit mouse handle, mouse drag ctrl " ctrl " not match, do nothing")
		return false

	} else if (status("mouse_drag_close")) {
		log("foxit mouse handle, mouse drag closed, do nothing")
		return false
	}

	return app_attr("foxit", const("ctrl", "name"))
}

; just use LButton for underline
foxit_single_underline(Byref notify=true)
{
	; must use ~, if not when foxit is active, try to focus on other window by click will fail
	origin := "LALT & LButton"
	switch := "~LButton"
	class  := app_class("foxit")

	;=====================================================
	; when trigger these keys, change close status
	if (once("foxit", "single")) {
		app_active_map("foxit", 	"^y/^+{z}")
		; automate open mouse drag when use F1 -> pencil, close when use highlight mark
		;	map F1 -> ^F12, change to pencil
		app_active("foxit",	"[F1]	foxit_mouse_close(0, ^{F12})"
			,	"[F2]				foxit_mouse_close(1)"
			,	"[F3]				foxit_mouse_close(1, !6)"
			,	"[<^F1 | <^F2]		foxit_mouse_close(1, , 1)")
	}
	;=====================================================

	; recored swtich status
	curr := local("foxit", "single")
	if (curr == 1) {
		cond_tips(notify, "cancel single")

		erase_hotkey(switch, "active", "class", , class)
		app_active("foxit", "[" origin "] foxit_mouse(drag, true)" sep("usekey"))

	; enable single underline, disable LAlt & LButton, when use highlight mark mode, not trigger mouse_drag
	} else {	
		cond_tips(notify, "using single")
		
		app_active("foxit", "[" switch "] foxit_mouse(drag, true)" sep("usekey"))
		erase_hotkey(origin, "active", "class", , class)
	}

	local("foxit", "single", curr == 1 ? 0 : 1)
}

; key hook, when key trigger, enable/disable mouse drag
foxit_mouse_close(Byref drag, Byref hotkey="", Byref vim=0)
{
	status("vim_close", vim)	

	status("mouse_drag_close", drag)

	if (!hotkey) {
		hotkey := hotkey_compound(A_ThisHotkey)
	}
	send_raw(hotkey)
}

foxit_mouse_vim_switch(Byref set=-1) {
	if (set == -1) {
		if (status("vim_close") || status("mouse_drag_close")) {
			set = 0
			tips("open switch")
		} else {
			set = 1
			tips("close switch")
		}
	}

	status("vim_close", set)	

	status("mouse_drag_close", set)
}

;----------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------
reset_eyefoo()
{
	tips("reset eyefoo", 300)
	old := display(0)

	if (close_app("eyefoo")) {
		force_tips("close succ")

	; not start now	
	} else if (!app_winid("eyefoo")) {
		force_tips("restart")
	}
	switch_app("eyefoo")
	sleep 500

	count=0
	while (!app_winid("eyefoo") && count++ < 5) {
		win_log("retry start eyefoo, retry " count)
		switch_app("eyefoo")
		sleep 500
	}
	win_log("retry start eyefoo, total " count)
	display(old)
}

reset_explorer() {
	name := "explorer.exe"
	kill_exec(name)

	find := false
	count := 0
	while (count++ < 5) {
		sleep 100

		if (win_winid_exec(name)) {
			find = true
			break
		}
	}

	if (!find) {
		run %name%
	}
}

;----------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------

;==============================================================================================
;==============================================================================================
;prepare_work
work_env()
{
	switch_app("vpn")
	switch_app("shadowsocks")
}

work_notify()
{
	remind_qq()
}

regist_startup()
{
	;----------------------------------------------
	startup("foxmail", 20, , "foxmail_hide_self")
	startup("weixin", 3, 0)
	startup("qq", 20)
	;startup("dingding", 20)
	;----------------------------------------------
}

global_applic_tool()
{   
hotkey_prefix("app", "tool")
	handle_list("[u]	file_open(, UltraEdit)"
			  , "[s]	file_open(, sublime)"
			  , "[v]	file_open(, vscode)")
hotkey_prefix(0)	

	app_active("dir",	"[>^n]		create_locate_dir"
					,	"[>^>+n]	create_locate_dir(date)")
}
