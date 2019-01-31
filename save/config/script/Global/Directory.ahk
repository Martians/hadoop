
dir_active(Byref winid=0)
{
	if (if_app_actived("dir", winid)) {
		return true

	} else {
		return system_class(winid, true)
	}
}

;========================================================================================
;========================================================================================
set_path(Byref type, Byref name, Byref path, Byref handle="", Byref arg*)
{
	; should not conflict
	if ((array := dync_name(type, name, -2))) {
		warn("set type [" type "] path, but name [" name "], already registed in type [" array.dync_type "]")
		return 0
	}
	entry := dync_name(type, name, 1)

	if (path) {
		parse_entry_path(entry, path)

	} else { 
		if (fixkey_type(type, name)) {
		} else {
			warn("set type [" type "] path, name [" name "], but path empty")
			return 0
		}
	}

	if (type == "file") {
		; if set path, must get full path here
		if (path) {
			if (if_path_exist( path)) {
				entry.path := path
			} else {
				warn("set type [" type "] path, name [" name "], but can't find auto path")
				return 0
			}
		}

		if (if_doc(path)) {
			default(handle, "file_open")
		} else {
			default(handle, "execute_path")
		}

		; add second param to execute handle
		if (handle== "execute_path") {
			if (arg[1]) {
			} else {
				; why do this ?
				; arg[1] := true		
			}
		}
		set_handle(entry, handle, entry.path, arg*)

	} else if (type == "dir") {
		; set window run info	
		set_param(entry, "", path, path)
		; active handle
		window_handle(entry, "active", "dir_active_handle")
		; set find handle
		window_handle(entry, "find",  "find_class_title_handle")
		; set find window handle
		window_handle(entry, "match", "dir_match_handle")

		if (arg[1]) {
			entry.locate := arg[1]
		}
		set_handle(entry, "switch_window_mute", glob_app("dir"), entry)		

	} else {
		warn("set path, no type [" type "], given name [" name "]")
	}
	locate := exist_append(entry.locate, ", regist dir locate as [", "]")
	realnm := exist_append(entry.dync_real, ", real name [", "]")

	app_log("set path, type [" type "] name [" name "], help " entry.help locate realnm)
	return entry
}

parse_entry_path(Byref entry, Byref path)
{
	entry.dync_real := get_option(path, sep("real"))
	entry.locate := get_option(path, sep("move"))
	entry.help := get_option(path, sep("help"))
	entry.path := del_option(path)

	if (!entry.help) {

		if (!(entry.help := file_name(path))) {
			warn("entry path, type [" entry.dync_type "] name [" entry.dync_name "], path [" entry.path "], empty file name")
			return 0
		
		} else {
			; have two sep, remove the last one
			sep := "."
			if (InStr(entry.help, sep) != InStr(entry.help, sep, , 0)) {
				entry.help := stri_sepr_prev(entry.help, sep, true)
			}
		}
	}
	entry.help := "[" entry.help "]"
}

;========================================================================================
;========================================================================================
file_list(Byref arg*)
{
	extend_handle_list("file_parse_handle", arg*)
}

dir_list(Byref arg*)
{
	extend_handle_list("dir_parse_handle", arg*)
}

; used in parse_handle
file_parse_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
	dync_name := dync_auto_name(hotkey)
	return set_path("file", dync_name, handle, , param*)
}

dir_parse_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
	dync_name := dync_auto_name(hotkey)
	; maybe set locate path in param[1]
	return set_path("dir", dync_name, handle)	; should pass param*, not param[1]
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
exec_list(Byref arg*)
{
	extend_handle_list("exec_parse_handle", arg*)
}

; used in parse_handle
exec_parse_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
	filter_handle_option(handle, option)

	if (!if_path_exist(handle)) {
		default(handle, const("applic", "not_install"))
		app_log("exec parse handle, name [" hotkey "] path not find")
	}
	return file_parse_handle(hotkey, option, handle, param*)
}

;========================================================================================
;========================================================================================
; for simple regist
open_dir(Byref name, Byref key, Byref path, Byref locate="")
{
	return open_path("dir", name, key, path, "", locate)
}

; regist file, use the hotkey as g_file[key]
open_file(Byref name, Byref key, Byref path, Byref handle="", Byref arg*)
{
	return open_path("file", name, key, path, handle, arg*)
}

;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
open_path(Byref type, Byref name, Byref key, Byref path, Byref handle="", Byref arg*)
{
	if (if_assist(name) && !key) {
		key := name
	} else {
		default(name, key)
	}

	if (set_path(type, name, path, handle, arg*)) {
		return regist_dync(type, name, key)

	} else {
		return 0
	}
}

; add path hotkey for registed name
dir_hotkey(Byref name, key="")
{
	default(key, SubStr(name, 1, 1))
	return regist_dync_hotkey("dir", name, key)
}

;========================================================================================
;========================================================================================
dir_match_handle(winid, Byref run)
{
	text := win_text(winid)
	if (find_exactly(text, run.text)) {
		return 1

	} else if (find_exactly(text, run.dync_real)) {
		return 1
	}
	return 0
}

dir_active_handle(Byref obj, Byref run)
{
	locate := run.locate
	if (locate) {
		if (locate == "home") {
			send_raw("{home}")

		} else if (locate == "end") {
			send_raw("{end}")

		} else { 
			relocate_dir_item(run.winid, locate)
		}
	} else {
		app_log("dir_active_handle: do nothing")
	}
}

;========================================================================================
;========================================================================================
select_path(Byref type, Byref path, Byref error="")
{
	if (dir_active(winid)) {
		if (type == "dir") {
			if (get_dir_path(path)) {

				; current is selecting some file item
				if (get_file_path(newd) && if_dir(newd)) {
					app_log("select path, type " type ", but select dir item, change path to [" newd "]")
					path := newd
				} else {
					app_log("select path, dir path [" path "]")
				}
				return 1
			}
		} else if (type == "file") {
			if (get_file_path(path)) {

				if (if_dir(path)) {
					app_log("select path, change type to dir, path [" path "]")
					type := "dir"
				} else {
					app_log("select path, file path [" path "]")
				}
				return 1
			}
		}
		error := "nothing selected"

	} else {
		error := "current not " type
	}
	app_log("select path, " error)
	return 0
}
;========================================================================================
;========================================================================================
select_rename(winid, Byref name, Byref end=false)
{
	relocate_dir_item(winid, name)

	sendinput {F2}

	if (end) {
		sendinput {end} 
	 	sendinput {space}
	}
	return true
}

create_locate_work(Byref run)  
{	
	time := date()
	path := run.param "\" time

	if (create_dir(path)) {
		switch_app("dir", "mode_show", "switch_mute", run)
			
		if (!select_rename(run.winid, time, true)) {
	 		tips("can't locate new dir")
	 	}
	} 
}

create_locate_dir(Byref type="")
{
	if (!select_type("dir", path)) {
		return
	}
	use_date := type == "date"
	name := use_date ? date() : gbk("dir", "new")
	path := path "\" name

	if (create_dir(path)) {
		select_rename(win_default(), name, use_date)
	}
}

regist_work_dirs()
{
	path := dync_name("dir", "work").path
	open_dir("_work_end",  ">^w", path, "end")

	entry := set_path("dir", "_work_create", path)
	regist_hotkey(">^+w", "create_locate_work", entry)

	path := dync_name("dir", "hadoop").path
	open_dir("_work_home",  ">!w", path, "2017-09-01 Spark")
} 

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
global_system_dir()
{
input_type("path")
	hotkey_prefix("app", "tool")
		regist_work_dirs()  

	    ; direcotry shortcut, use the first letter
	    dir_hotkey("sapp",  "a")
		dir_hotkey("stool", "t")
		dir_hotkey("mind")
		dir_hotkey("read")
		dir_hotkey("info")
		dir_hotkey("download")

	hotkey_prefix(0)
input_type(0)
}
