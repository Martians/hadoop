
;========================================================================================
;========================================================================================
parse_link(Byref link)
{
	FileGetShortcut, %link%, dest
	return dest
}

parse_exec(Byref path)
{
	path := actual_path(path)
	return file_name(path)
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; c:\wintial.lnk
actual_path(Byref path, Byref param="")
{
	if (InStr(path, ".lnk")) {
		return parse_link(path)

	} else {
		return path
	}
}

if_path_exist(Byref path)
{
	if (path == const("applic", "not_install")) {
		;g_log("search path, path [" path "] no need check")
	
	} else if (find_one_of(path, "\\/")) {
		;g_log("search path, path [" path "] is absolute")
		
	} else  {
		path := auto_link_path(path)
		return FileExist(path)
	}
	return 1
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; Todo: param
check_actual_path(Byref path, Byref param="")
{	
	if (path == "explore") {
		; for dir.explore, not a file name, but still as a path
		if (FileExist(param) || InStr(param, "{")) {
			app_log("check actual path, directory [" param "]")
			return 1

		} else {
			app_log("check actual path, directory [" param "] not exist")
			force_tips("[" param "] not exist ")
			return 0
		}
	}

	actual := actual_path(path, param)
	if (actual == path) {
		app_log("check actual path, [" path "] not a link, no need check")
		return 1

	; only check link path
	} else {
		if ((ret := FileExist(actual))) {
			app_log("check actual path, link <" path "> -> <" actual ">")

		} else {
			prefix := SubStr(const("system", "home"), 1, 1)

			; already the same disk
			if (prefix == SubStr(actual, 1, 1)) {
				return 0

			} else {
				actual := prefix SubStr(actual, 2, StrLen(actual))
				app_log("check actual path, path not exist, change prefix, set path <" actual ">")

				if (FileExist(actual)) {
					path := actual
					return 1
					
				} else {
					return 0
				}
			} 
		}
	}
	return 1
}

;========================================================================================
;========================================================================================
execute_path(Byref path, Byref param="", Byref display="") 
{
	if (!path) {
		info("open but no path", 3000)
		return 0

	} else if (InStr(path, const("applic", "not_install"))) {
		tips("not install")
		return 0
	
	} else if (!check_actual_path(path, param)) {
		tips("dest not exist")
		app_log("execute, but not find " path " " param)
		return 0	
	}


	if (0) {
		exec := parse_exec(path)
		; already open, switch it
		if (exec && (winid := win_winid_exec(exec))) {
			tips("already open " exec)
			return 0

		} else {
			tips("open " exec)
		}
	}

	if (display) {
		tips(display, 1000, true)
	}

	if (param) {
		command := path " " param
	} else {
		command := path
	}
	run %command% 

	app_log("try execute, command [" command "]")
	return 1
}

;file_open(Byref path="", Byref name="sublime")
file_open(Byref path="", Byref name="vscode")
{
	type := "file"
	if (!path) {
		if (select_type(type, path)) {
			if (type == "dir") {
				tips("dir selected")
				return
			}
		} else  {
			return
		}
	}

	if (InStr(path, const("applic", "not_install"))) {
		tips("not install")

	} else {
		tips("open file " file_name(path))
		;tips("open file " file_name(path), , true)
		execute_path(app_attr(name, "path"), app_attr(name, "param", true) """" path """")
	}
}

;=============================================================================
;=============================================================================
app_prefix_dir(Byref type)
{
	static s_path := "D:\Program Files\Local\Desktop\"

	if (Instr(type, "system")) {
		path := "D:\Program Files\Local\" type
	} else {
		path := s_path type
	}
	return path
}
;-----------------------------------------------------------------------------
; search exactly name, then do fruzzy search
auto_link_path(list, search="app|tool|common|system", Byref depth=0)
{
	origin := list
	; check for app alias
	while ((name := string_next(list, "|"))) {
		default(origin, name)

		loop_init(search)
		while ((type := loop_next())) {
			prefix := app_prefix_dir(type)
			if ((path := app_auto_link(name, prefix, depth))) {
				app_log("auto path, get <" type "> path: [" path "]")
				return path
			}
		}	
	}

	if (depth == 0) {
		app_log("auto path, try to use match mode, name " name)
		if ((path := auto_link_path(origin, search, 1))) {
			return path
		}
	}

	if (depth == 0) {
		;info("can't find path, for app " origin)
		return ""
	}
}

app_auto_link(Byref name, Byref prefix, Byref depth=0)
{	
	; try lnk first, for we can agrant with administration
	if (depth == 0) {
		if (Instr(name, ".")) {
			path := prefix "\" name

		} else {
			path := prefix "\" name ".lnk"
		}	
		;log("`t check path: [" path "]")

	} else {
		match := prefix "\" name "*"
		loop, %match%, , 1
		{
			path := A_LoopFileLongPath
			app_log("app link path, search [" prefix "\" name "*], get path [" path "]")
			break
		}
		;log("`t check match path: [" match "]")
	}
	return FileExist(path) ? path : 0
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
reg_path(Byref name)
{
	if (!(path := app_reg_path(name, "reg_app"))) {
		path := app_reg_path(name, "reg_user")
	}
	return path
}

app_reg_path(Byref name, Byref type)
{
	if (type == "reg_app") {
		RegRead, path, HKEY_LOCAL_MACHINE
			, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%name%.exe, 
			
	} else if (type == "reg_user") {
		RegRead, path, HKEY_CURRENT_USER
			, Software\%name%, %name%
		
	} else {
		tips("no such reg path, for app " name " type " type)
		return
	}
	return FileExist(path) ? path : 0
}

/*
reg_ahk(Byref key, Byref value="none", type="SZ")
{
	if (value == "none") {
		RegRead, value, HKEY_LOCAL_MACHINE
			, SOFTWARE\AutoHotkey, %key%
	} else {
		;REG_DWORD, REG_SZ
		type := type == "WORD" ? "REG_DWORD" : "REG_SZ"
		RegWrite, %type%, HKEY_LOCAL_MACHINE
			, SOFTWARE\AutoHotkey, %key%, %value%
	}
	if (ErrorLevel == 1) {
		return -1
	}
	return value
}
*/

;==============================================================================================
;==============================================================================================
; regist any app need startup
startup(Byref name, wait=5, check_count=2, Byref hide_handle="")
{
	main := startup_entry("main")
	curr := startup_entry("curr")

	if (check_count >= config("startup", "check_count")) {
		warn("startup app, but hide time " check_count " larger than config " config("startup", "check_count"))
	}

	entry := {}
	entry.name := name
	entry.wait := wait
	entry.check_count := check_count
	entry.hide_handle := hide_handle

	main.insert(entry)
}

startup_entry(name="")
{
	array := glob("glob", "startup")

	if (name) {
		return array[name]
	} else {
		return array
	}
}

;--------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------
startup_app(start_wait=0, serial=false)
{	
	if (once("startup", "init")) {
		config("startup", "check_count", 4)
		config("startup", "check_wait", 3000)

		array := startup_entry()
		array.main := {}
		array.curr := {}

		curr := array.curr
		curr.index := 0
		curr.check := 0
		curr.work  := 0

		regist_startup()
	} 

	; clearn entry
	main := startup_entry("main")
	curr := startup_entry("curr")

	if (curr.work) {
		tips("startup already work")
		return

	} else {
		tips("startup app")

		; reset hide count
		for index, entry in main
		{
			entry.hide := entry.check_count
		}
		curr.index := 0
		curr.check := 0
		curr.work  := 1
		; app start in serial when startup system
		curr.serial := serial
	}
	app_log("startup app, total " main.MaxIndex() ", first wait " start_wait ", serial " curr.serial)
	start_wait *= 1000

	SetTimer, startup_mini_label, off
	SetTimer, startup_next_label, off
	
	SetTimer, startup_next_label, %start_wait%
}

startup_next_label:
	SetTimer, startup_next_label, off
	startup_next_app()
return

startup_mini_label:
	SetTimer, startup_mini_label, off
	startup_minimize()
return

startup_next_app()
{
	app_log("")
	app_log("----->")
	app_log("startup next")

	main := startup_entry("main")
	curr := startup_entry("curr")
	
	if (++curr.index > main.MaxIndex()) {
		app_log("startup next app, already start all app, count [" main.MaxIndex() "], just wait to minimize")
		return
	}
	entry := main[curr.index]
	app_log("startup next app, index [" curr.index "], app name [" entry.name "]")
	
	; start and hide
	switch_app(entry.name, "mode_hide")
	
	; start next app in serial
	if (curr.serial) {
		wait := entry.wait * 1000
		
		app_log("==> start " entry.name ", next app wait " entry.wait)
		SetTimer, startup_next_label, %wait%
		
	} else {
		SetTimer, startup_next_label, 0
	}
	
	startup_reset_minimize()
}

startup_reset_minimize()
{
	curr := startup_entry("curr")
	curr.check := 0
	
	; close last timer, and start new one
	SetTimer, startup_mini_label, off
	SetTimer, startup_mini_label, 0

	app_log("startup reset minimize, reset hide check count")
}

startup_minimize()
{
	main := startup_entry("main")
	curr := startup_entry("curr")
	
	app_log("")
	app_log("----->")
	app_log("startup minimize")
	
	if (curr.index >= main.MaxIndex()) {
		success := true

	} else {
		;app_log("startup minimize, not all start, now [" curr.index "], total [" main.MaxIndex() "]")
	}

	for index, entry in main
	{
		if (!startup_hided(entry)) {
			success := false
		}
	}
	
	if (success) {
		tips("startup success")
		app_log("startup success")

	} else {
		if (++curr.check < config("startup", "check_count")) {
			app_log("startup minimize, check count [" curr.check "]")
			app_log("<-----`n")

			SetTimer, startup_mini_label, % config("startup", "check_wait")
			return 0

		} else {
			if (curr.index < main.MaxIndex()) {
				app_log("startup minimize, try exceed times, but [" main.MaxIndex() - curr.index "] app not start, wait")
				return 0
				
			} else {
				app_log("startup minimize, try exceed times, stop startup")
			}
		}
	}
	startup_end()
}

;-----------------------------------------------------------------------------
startup_hided(Byref entry)
{
	if (!entry.hide) {
		app_log("startup hided, no need check app [" entry.name "], check count 0")
		return true
	}
	
	if ((winid := app_winid(entry.name))) {
		
		if (if_hide(winid)) {
			entry.hide--
			app_log("startup hided, already hide app [" entry.name "], remain check " entry.hide)
			; if the first time for check, not return true
			return entry.hide == 0	
			
		} else {
			app_log("startup hided, minimize app [" entry.name "]")

			if (entry.hide_handle) {
				entry.hide_handle.()

			} else {
				switch_app(entry.name, "mode_hide", "none_start")
			}
		}
	} else {
		app_log("startup hided, but app [" entry.name "] not exist")
	}
	return false
}

startup_end()
{
	main := startup_entry("main")
	for index, entry in main
	{
		if (entry.hide != 0) {
			if ((winid := switch_app(entry.name, "mode_hide", "none_start") )
				&& if_hide(winid))
			{
				log("`t startup, last hide [" entry.name "] success")
				
			} else {
				log("`t startup, [" entry.name "] not hide")
			}
		}
	}

	SetTimer, startup_mini_label, off
	SetTimer, startup_next_label, off
	
	curr := startup_entry("curr")
	curr.work := 0

	; startup any other handle
	startup_last()

	log("startup end")
}

startup_last()
{
	work_env()
}

;==============================================================================================
;==============================================================================================

collect_text_line(Byref file, Byref style="", Byref mode="", Byref clip="")
{
	if (init(data, "collect_line", file)) {

		; default(style, "")
		default(mode, "read")
		default(clip, "click")

		data.style := enum_make("log_style", style)
		data.mode  := enum_make("log_mode",  mode)
		data.clip  := enum_make("clip", clip)
	}
	
	if (filter_clip(0.5, "line", data.clip)) {

		if (StrLen(Clipboard)) {
			file_log(file, Clipboard, data.style, data.mode)	
			tips("[" file ": " StrLen(Clipboard) "]____" SubStr(Clipboard, 1, 30), 2000, true)

		} else {
			tips("[" file ": nothing]", 500)
			; tips(file ": <" Clipboard ">", 500)
		}
		; copy data by click, cancel select stat
		;if (select == "click") {
		; sleep 500
		click 1
		;}

	} else {
		app_log("collect dict file, do nothing")
	}
}

; copy any text in line, then paste and execute in xshell
copy_exec_xshell()
{
	if (app_winid("xshell")) {

		if (filter_clip(0.1, "line", , 1000)) {
			
			switch_app("xshell", "mode_show")

			paste(Clipboard,,, true)
			;send {enter}

		} else {
			tips("nothing")
		}

	} else {
		tips("xshell not exist")
	}
}