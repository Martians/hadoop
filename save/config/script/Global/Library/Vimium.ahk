
; set system hotkey label for enable vim
#if vim_window() && vim_mode()

; test with default hotstring
:*:gg::
sendinput ^{home}
return

#if

; set system hotkey label for disable vim
;#if vim_window()
#if vim_window() && !vim_mode()
#if

/*
; this will not work, it will effect all window
global_vim_advance()
{
	hotkey, if, vim_advance(glob_app("foxit"))
	regist_hotkey("j", "foxit_focus_handle", "down")
	hotkey, if
}
#if vim_advance(glob_app("foxit"))
#if
*/

vim_log(Byref string)
{
	;log("[vim]: " string)
}

;================================================================================
;================================================================================
vim_window(class="")
{
	if (!class) {
		class := win_class()
	}

	;g_log("check in window [" class "], " (glob_item("glob", "vim", class) != NULL))
	array := glob_item("glob", "vim")
	array["curr"] := array[class]
	return array["curr"]
}

vim_entry(Byref type="curr", Byref entry="")
{
	array := glob_item("glob", "vim")
	if (entry) {
		array[type] := entry
	}
	return array[type]
}

;================================================================================
;================================================================================
;  -1) get vim mode
; 0/1) set vim mode
vim_mode(set=-1)
{
	curr := vim_entry()
	value := curr.stat

	notify := 1
	if (set != -1) {
		update_display(value, , vim_entry("show"), notify)
	 	curr.stat := value
	 	vim_log("==> set app [" curr.name "] vim mode as [" curr.stat "]")

	} else {
		if (input_type() || status("serial")) {
			vim_log("vim mode, but in input group [" input_type().name "]")
			return 0
		}
		; when other switch trigger, close this
		if (status("vim_close", set)) {
			vim_log("do nothing")
			return 0
		}
		vim_log("get app [" curr.name "] vim mode [" curr.stat "]")
	} 
	return value
}

vim_active(Byref name, stat=0)
{	
	if (!(entry := glob_app(name))) {
		warn("set vim window, but app [" name "] not exist")
		return 0
	}

	curr := {}
	curr.name := entry.name
	curr.stat := stat

	vim_entry(entry.class, curr)
	vim_log("regist vim effect app [" name "]")
}

;===========================================================================
;===========================================================================
vim_advance(Byref name, Byref key, Byref handle)
{
	if (!(entry := glob_app(name))) {
		warn("vim advance, but app [" name "] not exist")
		return 0

	} else if (!(curr := vim_entry(entry.class))) {
		warn("vim advance, but app [" name "] not regist as vim window")
		return 0
	}
	curr[key] := set_handle("", handle)

	vim_log("vim advance, app [" name "] handle [" handle "]")
}

vim_send_key(Byref key, Byref count=1, Byref raw=false)
{
	vim_log("vim send key, trigger handle")

	if ((work := vim_entry()[A_ThisHotkey])) {
		; if handle return 1, returen right now
		if (handle_work(work)) {
			return
		}
	}

	if (raw) {
		send_raw(key)
	} else {
		send_key(key, count)
	}
	vim_log("vim send key, map [" A_ThisHotkey "] -> [" key "]")
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
vim_hotkey(Byref key, Byref convert, Byref handle="", Byref arg*)
{
	default(handle, "vim_send_key")
	regist_hotkey(key, handle, convert, arg*)
}

vim_list(Byref arg*)
{
	extend_handle_list("vim_parae_handle", arg*)
}

vim_parae_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
	vim_hotkey(hotkey, handle, , param*)
	return 1
}

;==========================================================================
;==========================================================================
global_system_vimium()
{		
	global_vim_label()
	
	reigst_vim_hotkey()

	global_vim_window()
	
	global_vim_advance()
}

global_vim_label()
{
	array := glob("glob", "vim")
	curr := sure_item(array, "curr")
	show := sure_item(array, "show")
	show.open  := "vim mode"
	show.close := "vim exit"

	hotkey, if, vim_window() && vim_mode()
	vim_cond_hotkey()
	hotkey, if
	
	hotkey, if, vim_window() && !vim_mode()
	regist_hotkey("Shift & esc", "vim_mode", 1)
	hotkey, if	
}

;==========================================================================
;==========================================================================
vim_cond_hotkey()
{
	;handle_list("[i|a|o] vim_mode(""0"")")
	handle_list("[i|a|o] vim_mode(0)")

	vim_list("[j]		down"
		,	 "[k]		up"
		,	 "[h]		left"
		,	 "[l]		right"
		
		; in foxit, when active, if mouse locate at other window, will not work well
		,	 "[up]		wheelup"
		,	 "[down]	wheeldown"
		,	 "[left]	wheelup"
		,	 "[right]	wheeldown"
		;,	 "[space]	space"
	
		,	 "[d]		down(15)"
		,	 "[u]		up(15)"
		,	 "[+g]		^{end}(1, true)"

		,	 "[$]		end"
		,	 "[x]		delete")

	;---------------------------------------------
	; 0 can't be parse in handle_list
	vim_hotkey("0",	"home")	
}

reigst_vim_hotkey()
{
hotkey_prefix("app", "run")
	handle_list("[j] send_key(down)"
			, 	"[k] send_key(up)"
			, 	"[h] send_key(left)"
			, 	"[l] send_key(right)"
			, 	"[,] send_raw({home})" sep("next") "send_raw(^{home})"
			, 	"[.] send_raw({end})" sep("next") "send_raw(^{end})")
hotkey_prefix("")
}

global_vim_window()
{
	vim_active("foxit", 1)
	;vim_active("ever", 0)
}

global_vim_advance()
{
	vim_advance("foxit", "j", "foxit_focus_handle")
	vim_advance("foxit", "l", "foxit_focus_handle")
	
	; in order to use wheelup akka.
	vim_advance("foxit", "up", "mouse_follow_active")
	vim_advance("foxit", "down", "mouse_follow_active")
	vim_advance("foxit", "left", "mouse_follow_active")
	vim_advance("foxit", "right", "mouse_follow_active")
	;vim_advance("foxit", "space", "foxit_focus_handle")
}

