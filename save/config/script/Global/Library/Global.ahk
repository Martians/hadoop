;========================================================================================
;========================================================================================
if_function(Byref handle, Byref option="")
{
	if (IsFunc(handle)) {
		return 1

	} else {
		; if not function, maybe handle contain help
		filter_handle_option(handle, option)
		return IsFunc(handle)
	}
}

;========================================================================================
;========================================================================================
config_path(Byref name)
{		
	if ((path := global_path(name))) {
		name := path

	} else {

		if (!InStr(name, ".ini")) {
			name := name ".ini"
		}

		if (!InStr(name, "Config")) {
			path := "Config/" name
		} else {
			path := name
		}
	}
	return path
}

set_config(Byref key, Byref value, Byref section, Byref path="")
{
	config_path(path)
	IniWrite, %value%, %path%, %section%, %key%
	return ErrorLevel
}

get_config(Byref key, Byref section, Byref path="", Byref default=" ")
{
	config_path(path)
	IniRead, value, %path%, %section%, %key%, %default%
;	if (value == default) {
;		return -1
;	}
	return value
}

list_config(Byref section, Byref path="")
{
	config_path(path)

	array := {}
	IniRead, value, %path%, %section%
	Loop, parse, value, `n, `r
	{
		pos := Instr(A_LoopField, "=")
		if (pos) {
			name := SubStr(A_LoopField, 1, pos - 1)
			data := SubStr(A_LoopField, pos + 1)
			; dupplicate key
			if (array[name]) {
				reset := true
			} else {
				array[name] := data
			}
		} else {
			reset := true
		}
	}
	
	if (reset) {
		reset_config(section)
	}
	return array
}

del_config(Byref key, Byref section, Byref path="")
{
	config_path(path)

	if (key) {
		IniDelete, %path%, %section%, %key%
	} else {
		IniDelete, %path%, %section%
	}
	if (ErrorLevel != 0) {
		info("del config, but failed, " ErrorLevel)
	}
	return ErrorLevel
}

reset_config(Byref section)
{
	del_config("", section, path)

	for name, data in array
	{
		set_config(name, data, section, path)
	}
	log("reset section [" section "]")
}

record_config(Byref name, Byref value="")
{
	if (init(entry, "record", name)) {
		default(value, date())
		exist := get_config(name, "record")

		if (exist == value) {
			sys_log("record config, name [" name "] already match, data <" value ">")

		} else {
			set_config(name, value, "record")
			sys_log("record config, name [" name "] exist but overdue, update data from <" exist "> to <" value ">")
			return 1
		}
	}
	
	return 0
}
;========================================================================================
;========================================================================================
; create session and config name
dync_session_config(Byref session="", Byref config="")
{
	array := glob_sure("glob", "dync", "session") 

	if (session) {
		entry := sure_item(array, session)
		entry.config := config

	} else {
		entry := array[dync_session()]
		return entry.config
	}
}

; get current dync session
dync_session()
{
	if (input_type()) {
		if (status("serial")) {
			warn("dync session, but still serial")
			return 0
		}
		return "input_"

	} else {
		if (input_type()) {
			warn("dync session, but still input type [" input_type().name "]")
			return 0
		}
		return "serial_"
	}
}

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
; regist global dync type
dync_type(Byref type, Byref dync_input="", Byref dync_create="")
{
	; dync_input is a conflict domain
    array := glob_sure("glob", "dync", "type") 

    if (dync_input) {
    	entry := sure_item(array, type)
    	; used as main input group
    	entry.dync_input := dync_input
    	entry.dync_type  := type

        entry.dync_create := dync_create
        entry.dync_prefix := hotkey_prefix()

    } else {
    	return array[type]
    }
}

; regist dynamic type item
dync_name(Byref type, Byref name, Byref mode=-1)
{
	global := glob_sure("glob", "dync", "item")
    array := sure_item(global, type)

    ; just get
    if (mode == -1) {
        return array[name]
    
    } else {
        ; check if conflict with same group
        if (!array[name]) {
        	curr_input := dync_type(type).dync_input
        	for other, list in global
        	{
                if (other != type && list[name]) {
                	dync_input := dync_type(other).dync_input
                	; in same input, should never conflict
	                if (dync_input == curr_input) {
	                    exist := list
	                    app_log("dync name, get name <" name "> in type [" other "], same input group [" dync_input "]")
	                    break
	                }
                }
			}
        }

        ; add 
        if (mode == 1) {
            if (array[name] || exist[name]) {
            	warn("dync name, type <" type "> name [" name "] already exist")
                return 0
            }
            entry := sure_item(array, name)
            entry.dync_type := type
            entry.dync_name := name

        ; del
        } else if (mode == 0) {
            array.remove(name)

        ; only check, get exist array
        } else if (mode == -2) {
            if (array[name]) {
                return array[name]
            } else {
                return exist[name]
            }
        }
    }
    return array[name]
}

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
set_dynamic_type(Byref list, Byref name) {

	if (list || auto_dync_type(list)) {
		origin := list
	} else {
		return 0
	}

    while ((type := string_next(origin, opt("next")))) {

        if (select_type(type, path, false)) {

            ; check if exist in same dync session
            ;	remove the ones of same type; if note registed dync and conflict, will left it
            if ((entry := dync_name(type, name, -2))) {
                info("set dync <" type "> name [" name "], remove exist one in type [" entry.dync_type "]", entry.path ? 1000 : 10)
                del_dynamic_type(entry.dync_type, name)
            }

            entry := dync_type(type)
            if (entry.dync_create) {
            	entry.dync_create(type, name, path)

            } else {
                warn("set dync <" type "> name [" name "], but handle not exist")
                return 0
            }

            if (regist_dync(type, name)) {
	            set_config(name, path, section(type), dync_session_config())
	            wait_tips("config <" type "> name [" name "] -> [" path "]", 3000)
	            return 1
 
	        } else {
	        	return 0
	        }

        } else {
            app_log("set dync <" type "> name [" name "], select failed")
        }
    }
    if ((error := config("last", "error"))) {
        info(error, 1000)
    }
    return 0
}

del_dynamic_type(Byref list, Byref name) {
    origin := list

    while ((type := string_next(origin, opt("next")))) {

        if ((entry := dync_name(type, name))) {
            del_config(name, section(type), dync_session_config())
            dync_name(type, name, 0)

            return erase_dync(type, name, entry.path)
        }
    } 

    info("del dynamic type, but name [" name "] not exist")
    return 0
}

;-----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------
regist_dync(Byref type, Byref name, Byref key="")
{
	if (if_assist(name) && !key) {
		key := name
	} else { 
		default(name, key)
	}

	if (name != key) {
		if (!regist_dync_input(type, name)) {
			return 0
		}
	}

	if (key) {
		if (!regist_dync_hotkey(type, name, key)) {
			return 0
		}
	}
	return 1
}

erase_dync(Byref type, Byref name, Byref path="")
{
	erase_handle(name)
    info("del dync <" type "> name [" name "]", path ? 1000 : 10)
}

regist_dync_input(Byref type, Byref name)
{
	if (!(entry := dync_name(type, name))) {
		info("regist dync input, but dync <" type "> name [" name "] not exist", 3000)
		return 0
	}

	; regist input or serial
	if (InStr(dync_session(), "serial")) {

		switch("serial_work", "dync") 
		if (regist_serial(name, "", entry)) {
			app_log("regist dync serial, config <" type "> name [" name "] to <" entry.path ">")
			succ := true
		}
		switch("serial_work", 0) 

	} else {
		if (regist_input(name, "", entry)) {
			app_log("regist dync input, config <" type "> name [" name "] to <" entry.path ">")
			succ := true
		}
	}

	if (succ) {
		return 1
	
	} else {
		info("regist <" type ">, input [" name "] confict", 3000)

		; note del_dynamic_type here, only del dync_name; conflict with some one that not dync
		;del_dynamic_type(type, name)
		dync_name(type, name, 0)
		return 0
	}
}

regist_dync_hotkey(Byref type, Byref name, Byref key)
{
	if (!(entry := dync_name(type, name))) {
		info("regist <" type ">, but name [" name "] not exist", 3000)
		return 0
	}

	if (fixkey_type(type, key)) {
		regist_hotkey(key, "fixkey_dynamic_type", type)
	} else {
		regist_hotkey(key, entry)	
	}
	return 1
}

;========================================================================================
;========================================================================================
global_define_dync()
{
    ; regist default path
    regist_dir_path()
    ; regist default file
    regist_file_path()
 
 	array := glob_item("glob", "dync", "type")
 	; loop group
    for type, entry in array
    {
    	; load hotkey or input
input_type(entry.dync_input)
    	load_const_dync(type)
        load_dynamic_dync(type)
input_type(0)
    }

    ; load serial, no need load const
    for type, entry in array
    {
        load_dynamic_dync(type)
    }
}

load_dync(Byref type, Byref name, Byref path)
{
	if (!(dync := dync_type(type))) {
	    warn("load dync, but type <" type "> not exist")
	    return 0

    } else if (!dync.dync_create) {
    	warn("load dync, but type <" type "> not have create handle")
	    return 0
    }
/*
    if (dync.check_type && dync.check_type(path, atype)) {
    	app_log("load sync, but type <" type "> path [" path "], is actually <" atype ">")
    	return 1
    }
*/
	while ((next := string_next(name, "|"))) {

	    if (dync.dync_create(type, next, path)) {
		    if (regist_dync(type, next)) {
		        ret := 1

		    } else {
		    	ret := 0
		        info("load dync, type <" type "> name [" name "], but not set", 3000)
		    }
		}
	}

	return ret
}

load_const_dync(Byref type)
{
    array := glob_sure("glob", "const", type)
    for name, item in array
    {
    	; item contain sub-item
    	if (IsObject(item)) {
	    	for sub, data in item
	    	{
	    		if (!load_dync(type, name "_" sub, data)) {
		    		break
		    	}
	    	}
	    } else {
	    	if (!load_dync(type, name, item)) {
	    		break
	    	}
	    }
	}
}

load_dynamic_dync(Byref type)
{
	config := dync_session_config()
    array  := list_config(section(type), config)

	check  := config "-" section(type)
	if (local("dync", "load")[check]) {
		app_log("load dynamic dync, check [" check "] already loaded")
		return
	}
	local("dync", "load")[check] := 1

	app_log("load dynamic dync, load [" check "]")
    for name, item in array
    {
    	if (load_dync(type, name, item)) {
    		app_log("load dynamic, type <" type "> name [" name "]")
    	} else {
    		break
    	}
    }
    
    return 1
}

;========================================================================================
;========================================================================================
fixkey_type(Byref type, Byref key, create=false)
{
    array := sure_item(local("dync", "fixkey"), type)

    if (create) {
        if (array[key]) {
            warn("fixkey type <" type ">, [" key "] already regist")
            return 0
        }
        array[key] := 1
    }
    return array[key]
}

regist_fixkey_type()
{
	hotkey := "F1, F2, F3, F4"

	; regist hotkey for each type
	for type, array in glob_item("glob", "dync", "type")
	{
		if (array.dync_prefix) {
			; use , as seperator, ignore space and tab
			loop parse, hotkey, `,, %A_Space%%A_Tab%
		    {
		    	key := current_hotkey(A_LoopField, array.dync_prefix)
		        fixkey_type(type, key, true)
		    }
		}
	}
}

global_handle_fixkey()
{
	; here set input_type, will effect fixkey regist dync session
input_type("run")
    list := local("dync", "fixkey")
    for type, array in list 
    {
        for name, item in array
        {
            if ((entry := dync_name(type, name, -2))) {
                app_log("regist fixkey handle, key [" name "] already load from config, path [" entry.path "]")

            } else {
            	if ((entry := dync_type(type))) {
            		; regist fixed hotkey
	                if (entry.dync_create.(type, name, "")) {
	               		if (regist_dync(type, name)) {
	               			continue
	               		}
	               }
	            }
	            warn("global handle fixkey, but failed to regist <" type "> name [" name "]")
            }
        }
    }
 input_type(0)
   ; wait()
}

; wrapper the origin handle
fixkey_dynamic_type(Byref type)
{
input_type("run")

    key := A_ThisHotkey
    if (master_dual(0.15)) { 

    	group := ""
    hotkey_override(1)
        set_dynamic_type(type, key)
    hotkey_override(0)

    } else {
    	; here set input_type, will effect fixkey regist dync session
    	
        if ((entry := dync_name(type, key))) {
        	if (!entry.path) {
            	tips("item not set")
            } else {
        		succ := true
        	}
        } else {
            tips("fixkey dynamic " type ", but hotkey [" key "] not exist")
        }
    }
input_type(0)

    if (succ) {
    	return handle_work(entry)
    } else {
    	return 0
    }
}

;==========================================================================================
;==========================================================================================
record_app(Byref name, Byref run="", Byref handle="", Byref arg*)
{
    if (!(entry := glob_app(name))) {
    	warn("record app, but app [" name "] not exist")
    	return 0

    ; we can use path, exec name and so on ...
    } else if (!(entry.class && !half_class(entry)) && !entry.title) {
		app_log("record entry, but app [" entry.name "] not have any class or title")
		return 0
	}

    ; add class entry
    curr := record_entry(entry, "applic")
    curr.run := default(run, entry)
}

; glob["record"][class]["runinfo"][index]
; glob["record"][class]["winid"][index]
record_entry(Byref entry, Byref type, Byref name="")
{
	item := glob_sure("glob", "record", type)

	if (entry.class && !half_class(entry)) {
    	array := sure_item(item, entry.class, name) 
	} else {
		array := sure_item(item, "title", name)
	}

    if (name) {
    	curr := sure_item(array, name)

    } else {
		if (!(index := array.MaxIndex())) {
	        index := 1
	    } else {
	        index++
	    }
	    curr := sure_item(array, index)
    }
    curr.obj := entry
    return curr
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
find_switch_info(notify=true)
{
	class := win_class()
	winid := win_curr()
	item  := glob_sure("glob", "record", "applic")

	while (1) {
		if ((array := get_item(item, class))) {

			if ((curr := search_winid_record(array, winid))) {
				;g_log("find switch info, get record by winid")

		    } else if ((curr := search_app_record(array, winid))) {
		    	;g_log("find switch info, get record by class")
		    }

	    } else {
	    	array := get_item(item, "title")
	    	title := win_title()
	
	    	if ((curr := search_title_record(array, title))) {
	    		;g_log("fetch switch info, search by title")
	    	}
	    }
	    break
	}

    if (curr) {
    	if (!curr.run.winid) {
	        curr.run.winid := winid
	        app_log("find switch info, set run winid as [" winid "]")
    	}
    } else {
    	app_log("fetch switch info, no entry find")
    	cond_tips(notify, "can't find switch info [" class "]")
    }
    return curr
}

search_app_record(Byref array, Byref acitve_winid)
{
	if (array.MaxIndex() == 1) {
		app_log("search app record, only one item")
		return array[1]

	} else {
	    for index, curr in array
	    {
	    	; if can't find math winid, maybe you can switch window with hotkey first
	       	if (curr.run.winid == acitve_winid) {
	       		app_log("search app record, match app record, winid [" acitve_winid "]")
	       		return curr
	       	}
	        app_log("search app record, check index <" index ">, winid [" curr.run.winid "]")
	    }
	    return ""
    }
}

search_title_record(Byref array, Byref title)
{
	for index, curr in array
    {
    	; if can't find math winid, maybe you can switch window with hotkey first
       	if (InStr(title, curr.obj.title)) {
       		app_log("search title record, match title, origin [" curr.obj.title "], current [" title "]")
       		return curr
       	}
        app_log("search title record, check index <" index ">, title [" curr.obj.title "]")
    }
    return ""
}

search_winid_record(Byref array, Byref acitve_winid)
{
	return 0

	for winid, curr in array
	{
		if (acitve_winid == winid) {
			app_log("winid switch info, match record, winid [" acitve_winid "]")
			wait()
			return curr
		}
		app_log("winid switch info, check index " index ", winid [" winid "]")
	}
	return 0
}

record_entry_print(Byref name)
{
	if (!(entry := glob_app(name))) {
    	warn("record app, but app [" name "] not exist")
    	return 0
    }

    item := glob_item("glob", "record", entry.class)
    array := sure_item(item, type, name) 
}

;========================================================================================
;========================================================================================
/*
	[ key1 | key2 | ...]   handle1 opt || handle2 opt || ....
	config("parse", "handle", "1")
	parse_handle("  [ss!]		   abce 		(,c)  " opt("time") "12" , , , , opti)
	parse_handle("[ss!] ccef()")
	parse_handle("[ss!] 	ccef(	abc, 		  ss)")
	config("parse", "handle", 0)
*/
parse_list(Byref string, Byref list)
{
	list := ""
	; parse hotkey list
	if ((left := parse_hotkey(string, hotkey))) {

		index := 0
		while (1) {
			next := string_next(left, sep("next"), char, flag("sub_string | allow_empty"))
			; log("left: " left ", next: " next ", char: " char)
			if (!next) {
				if (!char) {
					break

				} else {
					; not set any handle before seperator, mostly sep("next")
					next := "nothing"	
				}
			}
			++index

			if (index <= hotkey.MaxIndex()) {
				key := hotkey[index]

			} else {
				; twice hotkey
				if (index == 2 && hotkey.MaxIndex()) {
					/*
					if (!if_assist(hotkey[1])) {
						tips(hotkey[1])
					}
					*/
					key := hotkey[1]
					dual := true
				} else {
					warn("parse list, string [" string "], handle count exceed hotkey count, hotkey count [" hotkey.MaxIndex() "] while handle count [" index "]")
					return 0
				}
			}

			while ((comb := get_option(next, sep("comb"), true))) {
				default(comb_list).insert(comb)
			}

			; parse next handle
			if ((entry := parse_handle(next, key, dual ? "dual" : ""))) {
				last := entry

				parse_option(entry)
				default(list).insert(entry)

			} else {
				warn("parse list, parse handle failed")
			}

			if (dual) {
				if (!entry.dual_time) {
					entry.dual_time := const("time", "dual")
				}
				dual := false
			}

			for index, comb in comb_list
			{
				index := config("global", "unique") + 1
				config("global", "unique", index)

				handle := parse_handle(comb, key "_" index)
				parse_option(handle)

				sure_item(entry, "link_next").insert(handle)
				app_log("parse list, get combine handle [" comb "]")
			}
		}
		
		; input or hotkey more than handle, set the left input or hotkeys attach with last handle
		if (index < hotkey.MaxIndex()) {

			; [!1|!2]   tips("same")
			; multi hotkey, only one handle, do the same thing, auto insert new entry
			if (list.MaxIndex() == 1) {

				while (index++ < hotkey.MaxIndex()) {
					entry := last.clone()
					entry.hotkey := hotkey[index]

					if (entry.hotkey == last.hotkey) {
						warn("fatal, hotkey same")
					}
					list.insert(entry)

					win_log("parse list, attach hotkey [" entry.hotkey "] with last handle [" get_handle(entry) "]")
				}

			; handle_list("[!1|!2|!3]   tips(same1) || tips(same2)")
			} else {
				warn("parse list, string [" string "], hotkey count exceed handle count, hotkey count [" hotkey.MaxIndex() "] while handle count [" index "]")
			}
		}
		return 1
	}
	return 0
}

parse_hotkey(Byref string, Byref hotkey)
{
	blank := const("regex", "blank")

	if (RegExMatch(string, blank "\[([^\]]*)\](.*)" , out)) {

		while ((subkey := string_next(out1, opt("next")))) {
			default(hotkey).insert(subkey)
		}

		if (out2) {
			return out2

		} else {
			warn("parse hotkey, no handle left, string [" string "]")	
		}
	} else {
		warn("parse hotkey, no hotkey exist, string [" string "]")
	}
	return ""
}

; if handle not contain "()", option will contain in handle string
parse_handle(Byref string, Byref hotkey, Byref mode="")
{
	blank := const("regex", "blank")

	; can't seperate option very precisely
	;	1) have param, option will parse out
	;	2) no param, option will attached with handle
	if (RegExMatch(string, blank "([^\(]*)" blank "(\((.*)\))*" blank "(.*)" , out)) {
		handle := trim(out1, " `t,")
		option := trim(out4)
		param  := trim(out3)
		; g_log("handle [" handle "], param [" param "], option [" option "]")

		if ((update := config("parse", "handle"))
			|| if_function(handle, option)) 
		{
			list := {}
			index := 0

			while (++index) {
				next := string_next(param, ",", char, flag("allow_empty"))
				; maybe param is empty, or just 0
				if (next != 0 && !next && !char) {
					break
				}

				; empty param
				show := exist_suffix(show, ", ") next

				if (next = "true" || next == "false") {
					next := (next = "true") ? true : false
				}
				list.insert(next)
			}
			show := exist_append(show, "(", ")")

			param := list
			; update handle info
			if (update) {
				entry := update.(hotkey, option, handle, param*)
				app_log("parse handle, get hotkey [" hotkey "], handle [" get_handle(entry) "], option [" option "]")

			} else {
				set_handle(entry, handle, param*)
				app_log("parse handle, get hotkey [" hotkey "], " exist_suffix(mode, " ") "handle [" handle show "], option [" option "]")
			}
			entry.hotkey := hotkey
			entry.option := option
			return entry

		} else if (handle) {
			warn("parse handle, hotkey [" hotkey "], [" handle "] not a handle" )	

		}  else {
			warn("parse handle, hotkey [" hotkey "], handle empty" )	
		}
	} else {
		warn("parse handle, can't parse [" string "]")
	}
	return 0
}

; filter common options
; if not set handle param, then option will attach to handle
filter_handle_option(Byref handle, Byref option)
{
	move_option(option, handle, sep("serial"))
	move_option(option, handle, sep("time"))
	move_option(option, handle, sep("help"))
}

; these option only used in handle list
;	other option leave to the applic itself, no need parse
parse_option(Byref entry)
{
	if ((dual_time := get_option(entry.option, sep("time")))) {
		entry.dual_time := default(dual_time, const("time", "dual"))
	}

	if (get_option(entry.option, sep("serial"))) {
		entry.serial := 1
	}

	if (get_option(entry.option, sep("usekey"))) {
		entry.usekey := 1
	}

	if ((help := get_option(entry.option, sep("help")))) {
		entry.help := help
	}
}
