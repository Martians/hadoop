 
;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
serial_log(Byref string)
{
	log("[serial]: " string)
}

serial_tips(Byref string, Byref entry="", Byref time=0)
{
	mode := 0
	if (entry) {
		if (entry.bottom) {

		} else {
			mode := "MD"
		}
	} 

	global_tips(string, time, mode)
}

serial_mode(Byref mode=-1)
{
	return config("serial", "mode", mode)	
}

; check if current mode is match
if_serial_mode(Byref mode)
{
	return config("serial", "mode") == mode
}

serial_entry(Byref type, Byref name="")
{
	item := glob_sure("glob", "serial", serial_mode())
	array := sure_item(item, type)

	if (name || name == 0) {
		return array[name]

	} else {
		return array
	}
}

serial_data(Byref type, Byref set=-1)
{
	array := glob_sure("glob", "serial", "stat")

	if (set == -1) {
		return array[type]

	} else {
		array[type] := set
	}
}

serial_time_extend(Byref set=-1)
{
	return serial_data("extend", set)
}

; get next prefix
serial_next_prefix(Byref name, Byref index)
{
	default(index, 0)
	
	if (index < strlen(name) - 1) {
		index++
		pos := RegExMatch(name, "[^" const("string", "assist") "]", key, index)

		; if prefix with assist key, pass them
		if (index != pos) {
			index := pos 
		} 

		if (substr(name, index, 1) == "{") {
			if (RegExMatch(name, "({.*})", out)) {
				index += StrLen(out1) - 1
			}
		}
		
		; till the end
		if (index >= StrLen(name)) {
			return 0
		}
		; use the whole as prefix
		return SubStr(name, 1, index)
	}
	return 0
}

;=============================================================================================
;=============================================================================================
regist_serial(Byref name, Byref help, Byref handle, Byref arg*)
{
	if (0 && StrLen(name) <= 1) {
		warn("serial handle, name [" name "], but not support length [" StrLen(name) "]")
		return 0
	}
	cycle := get_option(handle, sep("cycle"), true)

	set_handle(entry, handle, arg*)
	entry.name  := name
	entry.cycle := cycle

	; instr, snippet, dync and so on
	entry.work := switch("serial_work") 
	entry.extend := switch("serial_extend")
	entry.bottom := switch("bottom")

		; record last hotkey
		local("hotkey", "last", entry)
		local("hotkey", "name")[name] := entry

	if (help) {
		entry.help := help
	} else {
		entry.help := regex_replace(name, "{}")
	}

	auto := serial_entry("auto")
	main := serial_entry("main")
	
	; save upper case with +lower as one item in array
	serial := escape_uppercase(name)
	if (main[serial] || auto[serial]) {
		exist := main[serial] ? main[serial] : auto[serial][1]
		alias := (serial != name) ? "(" serial ")" : ""
		warn("serial handle, regist [" name alias "], but conflict with work <" exist.work "> name [" exist.name "] <" get_handle(exist) ">", 3000)
		return false
	}
	
	; get every prefix of the shortname
	while ((prefix := serial_next_prefix(serial, index))) {

		; conflict with any name
		if (serial_entry("main", prefix)) {
			exist := serial_entry("main", prefix)
			warn("serial handle, prefix [" prefix "] for [" serial "], but conflict with name [" exist.name "] handle <" get_handle(exist) ">")
			return false
		}

		array := sure_item(auto, prefix)
		array.insert(entry)
		serial_log("`t serial handle, auto prefix [" prefix "] -> [" serial "]")
	}
	entry.serial := serial
	serial_entry("main")[serial] := entry
	local("hotkey", "last", entry)
	
	serial_log("serial handle, regist [" entry.name "] handle [" get_handle(entry) "] succ")
	return true
}

get_serial(Byref name, Byref type="")
{
	default(type, "main")

	array := serial_entry(type)
	return array[name]
}

erase_serial(Byref name, Byref type="")
{
	if (!get_serial(name, type)) {
		info("erase serial, name [" name "] not exist")
		return 0
	}

	main := serial_entry(type)
	auto := serial_entry("auto")
	serial := escape_uppercase(name)
	
	; get every prefix of the shortname
	while ((prefix := serial_next_prefix(serial, index))) {

		array := auto[prefix]
		for tindex, item in array
		{
			if (item.name == name) {
				serial_log("`t erase serial, remove auto prefix [" prefix "] -> [" serial "]")
				array.remove(tindex)
				break
			}
		}	

		if (get_size(array) == 0) {
			auto.remove(prefix)
			serial_log("`t erase serial, auto prefix [" prefix "] empty, erase array")
		}	
	}

	entry := main.remove(serial)
	if (entry.cycle) {
		entry.cycle.(entry.name)
	}

	serial_log("erase serial, remove name [" name "], serial [" serial "]")
}

serial_instr(Byref name, Byref handle, Byref arg*)
{
switch("serial_work", "instr")
	regist_serial(name, "instr", handle, arg*)
switch("serial_work", 0)
}

;======================================================================================
;======================================================================================
serial_mapkey(Byref arg*)
{
	switch("serial_work", "list")
	for index, list in arg
	{
		while ((map := string_next(list, opt("list")))) {
			name := string_next(map, opt("map"))

			update_keymap(name, map, handle)
			regist_serial(name, "", handle, map)
			serial_log("map serial [" name "] -> [" map "], handle " handle)
		}
	}
	switch("serial_work", 0)
	return 1
}

serial_status(Byref param, Byref stat)
{
	if (if_serial_mode("vim")) {

		if (vim_serial_window() || serial_time_extend()) {
			; check if need close vim mode
			if (clos_vim(stat.char)) {
				return 1
			}

		} else {
			serial_notify_origin()
			return 1
		}
	}
	return 0
}

serial_execute()
{	
	if (config("serial", "succ")) {
		config("serial", "succ", 0)
	} else {
		serial_tips(": ")
	}
	ret := batch_lines(1)

	status("serial", 1)
	while (!mode) {

		wait_input(stat, const("input", "every"), 5)

		; status changed
		if (serial_status(param, stat)) {
			mode := "exit"
		
		; get any char
		} else if (stat.type == "") {
			param := param stat.char

			serial_handle(param, mode)

		} else {
			if (stat.type == "end") {
				; serial_log("serial exit, end char [" stat.term "]")

				; have param, BackSpace will remove param
				if (param && stat.term == "Backspace") {
					param := stri_trim_last(param)
					serial_handle(param, mode)

				} else if ((stat.term == "Enter" || stat.term == "Space")
					&& serial_first(param))
				{
					serial_handle(param, mode)

				; mark the valid key as down\up 
				} else if (InStr(config("serial", "transf"), stat.term)) {
					param := param "{" stat.term "}"

					; not regist such transform key, do origin work
					if (serial_handle(param, mode) == 0) {
						send_raw("{" stat.term "}")
						serial_log("serial execute, no handle, send single [" stat.term "]")
					}

				; assist key
				} else if (InStr(config("serial", "assist"), stat.term)) {
					if (InStr(stat.term, "Shift")) {
						g_log("serial execute, get assist [" stat.term "], keep param, try combine")
						
					} else {
						param := ""
						g_log("serial execute, get assist [" stat.term "], cancel exist, wait common key")
					}
					
				} else {
					mode := "term"
					g_log("serial execute, exit type [" stat.type "], end char [" stat.term "]")
				}
				
			} else {
				if (stat.type == "timeout") {
					mode := "tout"
					;g_log("serial exit, wait timeout")
				} else {
					mode := "exit"
					serial_log("serial execute, exit [" ErrorLevel "]")
				}
			}
		}		
	}
	status("serial", 0)

	if (ret) {
		batch_lines(0)
	}
	
	if (mode == "find" || mode == "exit") {
		return 1

	} else {
		; clear exist info
		if (param) {
			global_tips("")
		}
		return 0
	}
}

serial_handle(Byref param, Byref mode)
{
	; check registed assist keys
	if ((ret := serial_combine(param, mode))) {
		return ret
	}

	if ((entry := serial_entry("auto", param))) {
		serial_log("serial handle, param [" param "] auto list " entry.MaxIndex())
		if (entry.MaxIndex() == 1) {
			serial_tips(param " -> [" entry[1].name "]", entry[1])

		; if param length small, only show count
		} else if (StrLen(param) <= 2) {
			serial_tips(param ": " entry.MaxIndex(), entry[1])

		} else {
			if (entry.MaxIndex() > 3) {
				serial_tips(param ": `n" out_list(entry, true, "show_index"), entry[1])	
			} else {
				serial_tips(param ":  " out_list(entry, false, "show_index"), entry[1])
			}
		}

		mode := ""
		return 1

	} else if ((entry := serial_entry("main", param))) {
		serial_log("serial handle, execute [" param "], handle [" get_handle(entry) "]")
		handle_serial(entry)

		mode := "find"
		return 1

	} else {
		serial_log("serial handle, param [" param "] match noting, exit")

		mode := "none"
		return 0
	}
}

serial_first(Byref param)
{
	if ((entry := serial_entry("auto", param))) {
		if (entry.MaxIndex() >= 1) {
			param := entry[1].serial
			serial_log("seiral first, confirm first, auto set as first candinate [" param "]")
			return 1
		}
	}
	return 0
}

serial_combine(Byref param, Byref mode)
{
	; assit key down
	if (hotkey_group(assist, "", "assist")) {

		if ((entry := serial_combine_hotkey(assist, param))) {
			serial_log("serial handle, assist combine [" name "], execute handle [" entry.name "]")

			handle_serial(entry)
			mode := "find"
			
		} else if (serial_combine_shift(assist, param)) {
			return 0

		} else {
			name := assist param
			serial_log("serial handle, assist combine [" name "] not match, origin [" origin "]")

			; wait_input will get assist key with <>, should remove it before trigger]
			origin := send_hotkey(name)
			mode := "assist"	
		}
		return 1
	
	} else {
		return 0
	}
}

serial_combine_hotkey(Byref assist, Byref param)
{
	name := assist param

	if ((entry := serial_entry("main", name))) {
		return entry
	}

	; maybe regist not include <>			
	name := regex_replace(assist, "<>") param
	if ((entry := serial_entry("main", name))) {
		serial_log("serial combine entry, filter <>, combine [" name "]")
		return entry
	}
	return 0
}

serial_combine_shift(Byref assist, Byref param)
{
	; only have shift assist
	if (assist == "<+" || assist == ">+") {
		char := stri_trim_last(param, false, false)
		data := stri_trim_last(param, false)
		name := data "+" char

		if (serial_entry("main", name) 
			|| serial_entry("auto", name))
		{
			param := name
			serial_log("serial combine shift, attach shift, combine [" name "]")
			return 1
		}
	}
	return 0
}

;=============================================================================================
;=============================================================================================
handle_serial(Byref entry)
{
	serial_tips(entry.help ": ok", entry, 1000)
	config("serial", "succ", 1)

	; focus on current window ctrl
	if (serial_data("vim_init")) {
		serial_data("vim_init", 0)
		serial_log("handle serial, do vim init, try to focus [" win_class() "]")
	}

	if (entry.work == "instr") {
		if (serial_param_list(entry, param)) {
			handle_work(entry, param)
		}

	} else {
		handle_work(entry)
	}

	; extend timer
	if (entry.extend || serial_time_extend()) {
		vim_renew(true)
	}
}

serial_param_show(Byref entry, Byref param, Byref string="", Byref time=0)
{
	default(time, 10000)
	tips(entry.name ": " param (string ? " -> " string : ""), time, true)
}

serial_param_list(Byref entry, Byref param)
{
	while (1) {
		serial_param_show(entry, param)

		if (wait_input(stat, const_comb("input", "execute|assist"))) {
			param := param stat.char

		} else {
			if (stat.type == "end") {
				; serial_log("serial exit, end char [" stat.term "]")

				; have param, BackSpace will remove param
				if (stat.term == "Backspace") {
					param := stri_trim_last(param)

				} else if (stat.term == "Enter") {
					serial_log("serial param list, exit [" ErrorLevel "]")
					mode := "find"
					break

				} else {
					serial_log("serial param list, exit type [" stat.type "], term [" stat.term "]")
					mode := "exit"
					break
				}
			}
		}
	}
	if (mode == "find") {
		serial_param_show(entry, param, "ok", 1000)
		return 1
	} else {

		serial_param_show(entry, "none", , 1000)
		return 0		
	}
} 

;--------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------
serial_notify_origin()
{
	serial_log("==== serial notify origin, current window not vim mode, change it ====")
	serial_viming(0)

	if (stat.type == "end") {

		if (InStr(config("serial", "transf"), stat.term)) {
			send_raw("{" stat.term "}")
			serial_log("serial notify origin, send transfer hotkey [" stat.term "]")

		} else if (InStr(config("serial", "assist"), stat.term)) {
			hotkey_group(assist, "", "assist")
			origin := send_hotkey(assist stat.char)

			serial_log("serial notify origin, send assist hotkey [" origin "]")

		} 
	} else if (stat.char) {
		send_raw(stat.char)
		serial_log("serial notify origin, send origin raw [" stat.char "]")
	}
}

;===========================================================================================
;===========================================================================================
enter_vim()
{
	if (master_dual(0.2)) {
		open_vim()
	}
}

open_vim()
{	
	vim_mode_fast()

	log()
	log("======================================================================================")
	log("====> vim mode                                                                        ")
	tips("vim mode", 300, true)

	; stop vim renew if exist
	vim_renew(false)

	vim_serial_window(win_curr(), true)
	serial_viming(1)
	;global_tips("")
}

clos_vim(Byref char)
{
	if (char && InStr("aio", char)) {

		tips("vim exit", 300, true)
		vim_exit_work(char)

		serial_tips(char ": exit", , 500)
		log("<==== vim mode                                                                        ")
		log("======================================================================================")
		log()

		; stop vim renew if exist
		vim_renew(false)

		vim_serial_window(win_curr(), false)
		serial_viming(0)
		return 1
	}
	return 0
}

vim_exit_work(Byref char)
{
}

vim_mode_fast()
{
	if (config("serial", "vim_esc_open")) {
		if (once("serial", "vim_init")) {
			regist_hotkey("~Esc", "enter_vim")
		}
	}
}

; for dual LShift
vim_renew_fast()
{
	if (!status("serial") && master_dual(0.1)) {
		vim_renew(true)
	}
	return
}

serial_viming(Byref status)
{
	if (status) {
		serial_log(" ------------->>>>>>>>>>>>>>>>>>>> serial viming, active vim mode ------------->>>>>>>>>>>>>>>>>>>> ")
		serial_mode("vim")	

		serial_working(true)

		while (if_serial_mode("vim")) {
			serial_execute()
		}
		serial_log("vim loop exit")
		return 1

	} else {

		if (if_serial_mode("vim")) {
			serial_log(" <<<<<<<<<<<<<<<<<<<<------------- serial viming, stop vim mode <<<<<<<<<<<<<<<<<<<<------------- ")
			serial_mode("")
			cancel_input()

			serial_working(false)
			global_tips("")
			return 1

		} else {
			serial_log("serial viming, do nothing")
			return 0
		}
	}
}

; update system status, for vim mode
serial_working(Byref active)
{
	; Esc,	 for [~Esc]		open_vim
	; Shift, for [~Shift]  	vim_renew
	if (active) {
		batch_lines(1)
		; we can to some work for vim init, in handle_entry
		serial_data("vim_init", 1)

		;-------------------------------------------------------------------------------------------------------------
		if (config("serial", "vim_esc_open")) {
			; cancel hotkey function
			hotkey ~Esc, hotkey_label, off
		}
		;hotkey ~LShift, hotkey_label, off

	} else {
		batch_lines(0)
		serial_data("vim_init", 0)

		;-------------------------------------------------------------------------------------------------------------
		if (config("serial", "vim_esc_open")) {
			hotkey ~Esc, hotkey_label, on
		}
		;hotkey ~LShift, hotkey_label, on
	}
}

; cancel input in another thread
cancel_input()
{
	settimer, cancel_input_lable, 10
	return

cancel_input_lable:
	serial_log("cancel input label")
	settimer cancel_input_lable, off 

	input
	;Send {Escape}
return
}

;=============================================================================================
;=============================================================================================
vim_serial_window(Byref winid=0, Byref set=-1)
{
	array := glob_sure("glob", "vim", "active")

	; if use integer as index, save hex integer but get dec, so sometime not works well, convert to string
	if (set == -1) {
		return array["" (winid ? winid : win_curr())]

	} else {
		if (set) {
			array["" winid] := 1
			serial_log("vim serial window, set winid [" winid "] to active mode")

			vim_window_status(1)

		} else {
			array.remove("" winid)
			;array.remove(winid)
			serial_log("vim serial window, del winid [" winid "] deactive mode")

			vim_window_status(0)
		}
	}
}

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
vim_window_active(Byref winid, Byref active=true)
{
	if (serial_time_extend()) {
		serial_log("vim window active, current extend, no need check vim active")
		return 0
	}

	if (vim_serial_window(winid)) {

		if (active) {
			if (!if_serial_mode("vim")) {
				SetTimer vim_timer_active, 0
				return 1 
			}

		} else {
			if (if_serial_mode("vim")) {
				serial_log(" <---------------------------- vim window active, deactive winid [" winid "] cancel vim")

				serial_viming(0)
				return 1
			}
		}

	} else {
		if (if_serial_mode("vim")) {
			serial_viming(0)
			return 1
		}
	}

	return 0
}

serial_window_call()
{
	vim_window_active(win_curr(), true)
}

vim_window_status(Byref open)
{
	if (config("serial", "use_window_timer")) {
		return vim_window_timer_update(open)
	}

	array := glob_sure("glob", "vim", "active")
	list_size := get_size(array)

	if (open) {
		if (list_size == 1) { 
			serial_log("vim window status, regist window active handle")
			active_hook_worker("serial_window_call")

		} else {
			serial_log("vim window status, array size " list_size)
		}

	} else {
		if (list_size == 0) { 
			log("vim window status, cancel window active handle")
			active_hook_worker("serial_window_call", "null")

		} else {
			serial_log("vim window status, array size still " list_size)
		}
	}
	return

; switch_vim will occupy a thread, so work in a new thread
vim_timer_active:
	SetTimer vim_timer_active, off
	serial_viming(1)
	return
}

;-----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------
; not used now
vim_window_timer_update(Byref open)
{
	array := glob_sure("glob", "vim", "active")
	list_size := get_size(array)

	if (open) {
		if (list_size == 1) { 
			SetTimer vim_window_label, 1000
			log("vim window timer update, start vim timer")

		} else {
			serial_log("vim window timer update, array size " list_size)
		}

	} else {
		if (list_size == 0) { 
			log("vim window timer update, cancel vim timer ()()()()()()()()()()()()()()")
			SetTimer, vim_window_label, off

		} else {
			serial_log("vim window timer update, array size still " list_size)
		}
	}
	return

vim_window_label:
	if (vim_window_active(win_curr(), true)) {
		serial_log("vim window label, timer worked")

		vim_window_timer_clear()
	}
	return
}

; clear closed window entry
vim_window_timer_clear()
{
	array := glob_sure("glob", "vim", "active")
	for winid, value in array 
	{
		if (!win_exist(winid)) {
			serial_log("vim clear, remove winid [" winid "] ++++++++++++++++++")
			vim_serial_window(winid, 0)
		}
	} 
}

;-----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------
; renew vim time
vim_renew(Byref work)
{
	if (work) {
		if (if_serial_mode("vim")) {
			serial_log("vim renew, set renew but current is vim mode, ignore")
			return
		}

		; just update timer
		if (serial_time_extend()) {
			serial_log("vim renew, reset timer")
			update_cycle_timer("vim_cancel_renew")
			;SetTimer vim_renew_label, 10000

		; start timer
		} else {
			serial_time_extend(1)
			vim_mode_fast()
			
			tips("vim", 200)
			serial_log("vim renew, reset timer, start vim mode") 
			SetTimer vim_timer_active, 0

			cycle_timer(10000, "vim_cancel_renew")
		}

	} else {

		if (serial_time_extend()) {
			serial_time_extend(0)
			serial_log("vim renew, stop vim renew timer")
			; no need timer now
			cycle_timer(0, "vim_cancel_renew")
			;SetTimer vim_renew_label, off
		}
	}
	return

vim_renew_label:
	vim_cancel_renew()
	return
}

vim_cancel_renew()
{
	vim_renew(false)
	serial_viming(0)
}

;======================================================i====================================
;===========================================================================================
global_serial_vimium()
{
	if (config("serial", "use_window_timer")) {
		update_global_handle(1, "window", "active", "vim_window_active" sep("tail"), true)
		update_global_handle(1, "window", "deactive", "vim_window_active" sep("tail"), false)
	}
	; G = +g
	; cancel vim mode
	; handle_list("[+!v|vim]	open_vim"
	; 		,	"[<!;]		vim_renew(true)")
			;,	"[~LShift]	" sep("next") "vim_renew(true)")
switch("bottom", 1)
	; these serial input will do its work, then put serail into vim mode, for 10s
	;	any consequence key input will extend the time
switch("serial_extend", 1)
	serial_mapkey("G/^end, gg/^home, 0/home, $/end")
switch("serial_extend", 0)
	; test if we can send <!d in serial mode
	;serial_mapkey("!2/<!d") 

serial_mode("vim") 
	serial_mapkey("G/^end, gg/^home, 0/home, $/end"
				, "h/left, j/down, k/up, l/right, enter/down"
				, "u/^z, y/^y, J/^+Tab, K/^Tab"
				, "D/{wheeldown 15}, U/{wheelup 15}, {space}/{wheeldown 20}, +{space}/{wheelup 20}"
				, "{up}/{wheelup}, {down}/{wheeldown}, {left}/{wheelleft}, {right}/{wheelright}"
				, "x/delete, b/backspace")

	handle_list("[dd]	cut_line(false)",
			,	"[cc] 	cut_line(true)")
serial_mode("")

switch("bottom", 0)
}

;============================================================================================
;============================================================================================
global_system_serial()
{
	; mark the valid key as down\up 
	config("serial", "transf", const_comb("input", "function|direct|execute"))
	config("serial", "assist", const("input", "assist"))
	
	; disable global vim
	; global_serial_vimium()

	;======================================================================================
	;======================================================================================
	; erase any exist serial
		; note: regist serial and dync entry in group serial, here not set any input_type
	; 	in dictionary, we also regist file.path for input and serial
	file_list("[<^!i] 	" config_path("Input") sep("comb") config_path("Serial") sep("comb") A_ScriptDir "\Handy.ahk"
			, "[input]	" config_path("Input")
			, "[serial]	" config_path("Serial"))

	serial_instr("erase", "erase_serial")

	;-------------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------------
	serial_instr("dir",  "set_dynamic_type", "dir")
	serial_instr("file", "set_dynamic_type", "file")
	serial_instr("link", "set_dynamic_type", "link")

	serial_instr("note", "set_dynamic_type", "note")
	serial_instr("book", "set_dynamic_type", "book")
	serial_instr("tags", "set_dynamic_type", "tags")

	serial_instr("set",  "set_dynamic_type", "")
	serial_instr("del",  "del_dynamic_type", "dir|file|note|book|tags|link")

	;======================================================================================
	;======================================================================================
	; copy current path to 
	handle_list("[code] 		copy_snippet"
			,	"[copy-note]	copy_note_path(note)"
			,	"[copy-book]	copy_note_path(book)"
			,	"[copy-tags]	copy_note_path(tags)")
	;======================================================================================
}
