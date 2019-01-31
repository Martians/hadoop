
#InstallKeybdHook

;send hotkey to itself
;#UseHook

handle_log(Byref string="")
{
	log("[hotkey]: " string)
}

; set main heandle
set_handle(Byref entry, Byref handle, Byref arg*)
{
	default(entry)
	; given handle is the wrapped handle entry
	if (enum(handle, "handle", "init")) {
		entry := handle
		;handle_log("set handle, already initiated, handle " get_handle(entry, "info"))

	} else {
	    set_enum(entry, "handle", "init")
	    handle_init(entry, handle, arg*)
	}
	return entry
}

get_handle(Byref entry, Byref name="")
{
	default(name, "handle")
	; display more info
	if (name == "info") {
		if (entry.help) {
			return entry["proto"] "<" entry.help ">"
		} else {
			return entry["proto"]		
		}

	} else {
		return entry[name]	
	}
}

; only show the main handle
show_handle(Byref entry, Byref prefix="", Byref suffix="")
{
    if (InStr(entry.handle, "switch") && entry.arg[1].name) {
        switch := true
    }

    for index, object in entry.arg
    {
        ;if (IsObject(object)) {
        ; if object is showable, then set it
        if (switch && index == 1) {
            string := exist_suffix(string, ", ") empty """" object.name """"
            empty := ""

        } else if (strlen(object)) {
            string := exist_suffix(string, ", ") empty """" object """"
            empty := ""
        } else {
        	if (object) {
        		empty := empty "[object], "
    		} else {
    			empty := empty ", "	
    		}
        }
    }
    default(prefix, "[") 
    default(suffix, "]")

    entry.proto := prefix entry.handle exist_append(string, "(", ")") suffix
    return entry.proto
}

;====================================================================================
;====================================================================================
handle_init(Byref entry, Byref handle, Byref arg*) {

	if (get_option(handle, sep("tail"), true)) {
		set_enum(entry, "handle", "tail")
	}
	if (get_option(handle, sep("only"), true)) {
		set_enum(entry, "handle", "only")
	}
	set_entry_handle(entry, handle, arg*)
	return entry
}

set_entry_handle(Byref entry, Byref handle, Byref arg*)
{
/*	
	; set entry cond info
    if (handle == -1) {
        entry[arg[1]] := arg[2]

    } else 
*/
    if (IsFunc(handle)) {
        entry.handle := handle
        entry.arg    := arg
        show_handle(entry)

    } else {
        warn("set entry handle, [" handle "] is not a handle")
        return 0
    }
    return 1
}

; notice: if use temply arg, byref dynamic will not get return value again, if you not use sep("tail") 
handle_work(Byref entry, Byref arg*) {

	if (!entry.handle) {
		info("null to do", 300000)
		return -1
	}

	if (enum(entry, "handle", "only")) {
		arg := entry.arg
		handle_log("handle work, use exist param only")

	} else if (enum(entry, "handle", "tail")) {
		if (get_handle(entry, "arg").MaxIndex()) {
			for index, value in entry.arg
			{
				arg.insert(value)
			}
			handle_log("handle work, add exist param to tail")
		} else {
			;handle_log("handle work, no need add empty param to tail")
		}
		
	} else if (entry.arg.MaxIndex()) {
		if (arg.MaxIndex()) {
			old := entry.arg.Clone()
			for index, value in arg
			{
				old.insert(value)
			}
			arg := old
			handle_log("handle work, add exist param to head")
		} else {
			arg := entry.arg			
			;handle_log("handle work, use exist param")
		}
	}
	handle_log("handle work, " entry.proto)
	
	handle_work_list(entry.link_prev)

	ret := entry.handle.(arg*)

	handle_work_list(entry.link_next)
	return ret
}

handle_work_list(Byref list)
{
	for index, next in list
	{
		handle_log("handle work, index " index ", next handle " next.proto)
		handle_work(next)
	}
}

;================================================================================
;================================================================================
hotkey_cond(Byref name="", Byref flag_str="") {
	curr := glob("hotkey", "curr")

	if (!name) {
		if (curr.cond) {
			comm := curr.comm
			Hotkey, %comm%
			handle_log("Hotkey, " comm)
		}
		set_glob("hotkey", "curr")
		return 1
	
	} else if (!(entry := glob_app(name))) {
		warn("hotkey cond, app [" name "] not regist")
		return 0
	
	} else if (!enum_make("cond", flag_str, flag)) {
		warn("hotkey cond, app [" name "] cond flag [" flag_str "] not valid")
		return 0
	}

	curr.param := {}
	if (enum(entry, "cond", "title")) {
		curr.param.insert("title")
	}
	if (enum(entry, "cond", "exec")) {
		curr.param.insert("exec")
	}
	; if cond is empty, automate set as class
	if (enum(entry, "cond", "class")) {
		curr.param.insert("class")
	}
	if (!curr.param.MaxIndex()) {
		if (entry.title) {
			curr.param.insert("title")
		}
		if (entry.class) {
			curr.param.insert("class")
		} else if (entry.exec) {
			curr.param.insert("exec")
		}

		if (!curr.param.MaxIndex()) {
			warn("hotkey cond, app [" name "] find nothing for condition")
			return 0
		}
		handle_log("hotkey cond, app [" name "] auto add cond type [" curr.param[curr.param.MaxIndex()] "]")
	}
	
	if (enum(flag, "cond", "active")) {
		if (enum(flag, "cond", "none")) {
			curr.comm := "IfWinNotActive"
			curr.type := "none_active"
		} else {
			curr.comm := "IfWinActive"
			curr.type := "active"
		}

	} else {
		if (enum(flag, "cond", "none")) {
			curr.comm := "IfWinNotExist"
			curr.type := "none_exist"
		} else {
			curr.comm := "IfWinExist"
			curr.type := "exist"
		}
	} 

	if (hotkey_format(entry, curr.param)) {
		curr.label := curr.type curr.label "_label"

		if (IsLabel(curr.label)) {
			comm := curr.comm
			cond := curr.cond
			Hotkey %comm%, %cond%

			handle_log()
			handle_log("Hotkey, " comm ", " cond ", label [" curr.label "]")
			return 1

		} else {
			; reset, no need reset hotkey cond later
			warn("hotkey cond, but label [" curr.label "] not exist")
		}
	} 

	; clear and reset
	hotkey_cond()
	return 1
}

regist_hotkey(keylist, Byref handle, Byref arg*) {
	
	while ((key := string_next(keylist, opt("next")))) {
		key := current_hotkey(key)

		curr := glob("hotkey", "curr")	
		set_handle(entry, handle, arg*)

		if (curr.cond) {
			;set_entry_handle(entry, -1, "cond", curr.cond)
			entry.cond := curr.cond
			entry.comm := curr.comm

		} else {
			handle_name := get_handle(entry)
			; vim mode is a exception
			if (if_invalid_hotkey(key, handle_name)) {
			;if (!if_assist(key)) {
				warn("regist hotkey, key [" key "] handle [" handle_name "], contain no assist key")
				return 0
			}

			curr.type  := "common"
			curr.label := "hotkey_label"
		}

		set_hotkey(key, entry, show)
		entry.label := curr.label

		label := curr.label
		Hotkey, %key%, %label%, on

		log("regist " curr.type exist_prefix(show, " ") ": [" key "] handle " get_handle(entry, "info") exist_append(curr.cond, "  `t{", "}"))
	}
}

regist_mapkey(Byref key, Byref map="")
{
	update_keymap(key, map, handle)
	regist_hotkey(key, handle, map)

/*
	default(map, key)
	map := LTrim(map, "$~*<>")

	handle_log("map key [" key "] -> [" map "]")
	regist_hotkey(key, "send_raw", map)
*/
	handle_log("map key [" key "] -> [" map "]")
}

;=============================================================================
;=============================================================================
current_hotkey(Byref key, Byref prefix="")
{        
    if (if_assist(key)) {

        if (if_prefix(key, opt("final"))) {
            key := LTrim(key, opt("final"))
            
        } else {
            return key
        }
    }
    default(prefix, hotkey_prefix())
    return prefix key
}

hotkey_override(Byref set=-1)
{
	if (set == -1) {
		return config("hotkey", "override")

	} else {
		config("hotkey", "override", set)
	}
}

hotkey_format(Byref entry, Byref param)
{
	curr := glob("hotkey", "curr")
	if (!param.MaxIndex()) {
		warn("hotkey format, app [" entry.name "] not set any mode")
		return 0
	}
	for index, name in param 
	{
		if (name == "title") {
			if (entry.title) {
				cond := exist_suffix(cond) entry.title
			} else {	
				warn("hotkey format, app [" entry.name "] mode title but empty")
				return 0
			}

		} else if (name == "class") {
			if (entry.class) {
				cond := exist_suffix(cond) "ahk_class " entry.class 

			} else {	
				warn("hotkey format, app [" entry.name "] mode class but empty")
				return 0
			}
		
		} else if (name == "exec") {
			if (entry.exec) {
				cond := exist_suffix(cond) "ahk_exe " entry.exec

			} else {	
				warn("hotkey format, app [" entry.name "] mode exec but empty")
				return 0
			}
		}
		label := label "_" name
	}
	curr.label := label
	curr.cond  := cond
	return 1
}

;=============================================================================
;=============================================================================
set_hotkey(Byref key, Byref entry, Byref show)
{
	curr := glob("hotkey", "curr")

	; if use ~ and only one key item, when trigger, will lost ~ in A_ThisHotkey
	if (InStr(key, "~") && master_count(key) == 2) {
		array := glob_sure("hotkey", curr.type, stri_sepr_next(key, "~"))
	} else {
		array := glob_sure("hotkey", curr.type, key)
	}

	for index, type in curr.param
	{
		array := sure_item(array, type)

		suffix := suffix "[""" type """]"
		show := exist_suffix(show, " & ") type
	}
	
	if (!(index := array.MaxIndex())) {
		index := 0
	}

	if (curr.type == "common") {
		if (index > 0) {
			if (hotkey_override()) {
				handle_log("set hotkey, handle " get_handle(entry, "info") ", override last handle " get_handle(array[1], "info"))
				--index
			} else {
				warn("set hotkey, handle " get_handle(entry, "info") ", but common hotkey [" key "] already regist with handle " get_handle(array[1], "info"))
				return 0
			}
		}
	}
	; record last hotkey
	local("hotkey", "last", entry)
	local("hotkey", "name")[key] := entry

	array[++index] := entry 
	handle_log("set hotkey, entry [" curr.type "][""" key """]" suffix ", index " index ", handle " get_handle(entry, "info"))
}

get_hotkey(Byref type, Byref hotkey="", Byref param1="", Byref param2="")
{
	default(hotkey, A_ThisHotkey)
	entry := glob_item("hotkey", type, hotkey)
	return get_item(entry, param1, param2)
}

; arg[1] -> param1, ex:title ; arg[2] -> param2, ex: class
; arg[3] -> title/class/text actual param
erase_hotkey(Byref hotkey, Byref type="common", Byref arg*)
{
	array := get_hotkey(type, hotkey, arg[1], arg[2])

	if (array) {

		for index, entry in array
		{
			good := true
			; check if every condition is match
			for vi, string in arg
			{
				if (vi < 3) {
					continue
				}
				; entry cond match all of the given param
				if (Instr(entry.cond, string)) {
					handle_log("del hotkey, get matched cond [" string "]")

				} else {
					good := false
					break
				}
			}
			if (good) {
				break
			}
			handle_log("del hotkey, check array, index " index " cond "< entry.cond ">")
		}
	
		if (good) {
			if (entry.cond) {
				Hotkey % entry.comm, % entry.cond
			}
			
			entry := array.remove(index)
			handle_log("del hotkey, type [" type "], label [" entry.label "], hotkey [" hotkey "], cond <" entry.cond ">")

			Hotkey, %hotkey%, % entry.label, Off

			if (entry.cond) {
				hotkey % entry.comm
			}
			return 1
		}
	}
	warn("del hotkey, but type [" type "] hotkey [" hotkey "] param <" param1 param2 "> not exist!", 3000)
	return 0
}

;==================================================================================================
;==================================================================================================
act_handle(Byref type, Byref param1="", Byref param2="")
{
	index := "[""" type """]" "[""" A_ThisHotkey """]" exist_append(param1, "[""", """]") exist_append(param2, "[""", """]")

	if (!(array := get_hotkey(type, "", param1, param2))) {
		warn("act handle, but array " index " not exist")
		return 0
	}

	log()
	if ((entry := hotkey_array(array, type))) {
		handle_log("act handle, trigger " index "")

	} else {
		warn("act handle, but type " index " not exist")
		return 0
	}
	log("--- trigger " type exist_prefix(param1, " ") exist_prefix(param2, " & ") ", hotkey [" A_ThisHotkey "], handle " get_handle(entry, "info"))

	if (entry.dual && master_dual(entry.dual_time)) {
		return handle_work(entry.dual)
	
	} else {
		return handle_work(entry)
	}
}

hotkey_array(Byref array, Byref type)
{
	; common hotkey always have one entry
	if (array.MaxIndex() == 1) {
		handle_log("hotkey entry, only one item")
		return array[1]
	}
	handle := "Win" type

	for index, entry in array 
	{
		handle_log("hotkey array, index " index ", [" handle " " get_handle(entry, "cond") "]")
		if (handle.(get_handle(entry, "cond"))) {
			return entry
		}
	}
}

hotkey_label()   
{
hotkey_label:
	act_handle("common")
    Return

active_class_label:
	act_handle("active", "class")
	Return
exist_class_label:
	 act_handle("exist", "class")
	Return

active_title_label:
	act_handle("active", "title")
	return
exist_title_label:
	 act_handle("exist", "title")
	return

active_exec_label:
	act_handle("active", "exec")
	return
exist_exec_label:
	 act_handle("exist", "exec")
	return

active_title_class_label:
	act_handle("active", "title", "class")
	return
exist_title_class_label:
	 act_handle("exist", "title", "class")
	return

active_title_exec_label:
	act_handle("active", "title", "exec")
	return
exist_title_exec_label:
	 act_handle("exist", "title", "exec")
	return

active_mapkey_label:
	act_handle("active", "mapkey")
	return
exist_mapkey_label:
	 act_handle("exist", "mapkey")
	return
}

;========================================================================================
;========================================================================================
nothing()
{
}

handle_list_test()
{
	handle_list("[!1], 		tips(1)"
			, 	"[!2] 		tips(2) || tips(double 2)" sep("time") 0.5
			, 	"[!7] 		tips(7) || tips(double 7)"
			, 	"[!3|!4] ,	tips(same)"
			,	"[!5|!6] 	tips(n) || send_raw(kk)"
			,	"[!b|good|host]  tips(1) || tips(|goog|) || tips(|host|)")
}

;	[!1] tips(1)
;	[!2] tips(1) || tips(2) sep("time") 0.5
;	[!b|good|host]  tips(1) || tips(2) || tips(3)
handle_list(Byref arg*)
{
	for index, string in arg
	{
		if (parse_list(string, list)) {
			for index, entry in list
			{

				; already have assist key, or only one master key, will regist as hotkey; or regist as serial
				serial := entry.serial || master_count(entry.hotkey) > 1
				
				if (entry.hotkey == config("handle", "rightly")) {
					handle_log("handle list, trigger handle right now, no need regist")
					handle_work(entry)

				} else if (if_assist(entry.hotkey) || entry.usekey || !serial) {
					if (entry.dual_time) {
						last := local("hotkey", "last")
						last.dual := set_handle("", entry)
						last.dual_time := entry.dual_time
						log("set dual_time: " entry.dual_time)
					} else {
						regist_handle_list("hotkey", entry.hotkey, entry)
					}
					
				} else {
					if (input_type()) {
						; help message contain in entry.help, will used later
						regist_handle_list("input", entry.hotkey, entry)	

					} else {
						switch("serial_work", "list") 
						regist_handle_list("serial", entry.hotkey, entry)
						switch("serial_work", 0) 
					}
				}
			}
		}
	} 
}

regist_handle_list(Byref mode, Byref hotkey, Byref entry)
{
	if (switch("erase")) {
		erase_handle(hotkey, mode)

	} else {
	
		if (mode == "hotkey") {
			regist_hotkey(hotkey, entry)		

		} else if (mode == "input") {
			regist_input(hotkey, "", entry)

		} else {
			regist_serial(hotkey, "", entry)
		}
	}
}

; regist handle list with specific handle
extend_handle_list(Byref handle, Byref arg*)
{
    config("parse", "handle", handle)

    handle_list(arg*)

    config("parse", "handle", "")
}

handle_mapkey(Byref arg*)
{
	for index, list in arg
	{
		while ((map := string_next(list, opt("list")))) {
			key := string_next(map, opt("map"))
			regist_mapkey(key, map)
		}
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; display, when trigger, display as tips 
; help, when input, display as help message
delay_handle_list(Byref switch_key, Byref display, Byref help, Byref arg*)
{
	entry := set_handle(entry, "delay_regist_handle", display, help, "handle_list", arg*)
	display := "delay -> " help

	while ((hotkey := string_next(switch_key, opt("next")))) {
		; when trigger hotkey, will load delay_regist_handle(, , "handle_list", arg*)
		;	then the hotkey will registed by handle_list
		serial := master_count(hotkey) > 1
		if (if_assist(hotkey) || !serial) {
			regist_hotkey(hotkey, entry)

		} else {
			if (input_type()) {
				regist_input(hotkey, display, entry)

			} else {
				regist_serial(hotkey, display, entry)
			}
		}
	}
}

delay_regist_handle(Byref display, Byref help, Byref handle, Byref arg*)
{
	; make soure output is not empty
	output := display help
	default(output, "delay")

; if exist input, only use run type
input_type("run")
	; regist hotkey
	stat := local(handle, output)
    ; if (once(handle, output)) {
    if (stat.init != 1) {
    	stat.init := 1
    	tips(exist_prefix(display, "++ delay -> "), 1000)

        handle.(arg*)

    ; cancel hotkey
    } else if (1) {
    	stat.init := 0
		tips(exist_prefix(display, "-- cancel -> "), 1000)

    	switch("erase", 1)
    	handle.(arg*)
    	switch("erase", 0)

	} else {
		; or remove regist current entry
		tips("done")
	}
input_type(0)
}

;==========================================================================================
;==========================================================================================
dync_auto_name(Byref hotkey)
{
	;filter_handle_option(handle, option)
	assist := master_count(hotkey) == 1 && hotkey_prefix()
	if (if_assist(hotkey) || assist) {
		name := hotkey_prefix() hotkey

	} else {
		if (input_type()) {
			name := input_type().name "_" hotkey

		} else {
			name := "serial_" hotkey
		}
	}
	return name
}

;==========================================================================================
;==========================================================================================
; these regist can be replaced by handle_list
regist_handle(Byref name, Byref hotkey, Byref help, Byref handle, Byref arg*)
{
	if (hotkey) {
		regist_hotkey(hotkey, handle, arg*)
	}

	if (name) {
	input_type("run")
		regist_input(name, help, handle, arg*)
	input_type(0)
	}
}

regist_execute(Byref name, Byref hotkey, Byref help, Byref path)
{
	if (!if_path_exist( path)) {
		warn("regist execute, name [" name "] hotkey [" hotkey "], path not find - [" path "]")
		return 0
	}

input_type("run")
	ret := open_file(name, hotkey, path sep("help") help)
input_type(0)
	return ret
}

;========================================================================================
;========================================================================================

/*
#IfWinExist ahk_class Chrome_WidgetWin_1
#IfWinExist ahk_class Chrome_WidgetWin_1
!c::
tips("22")
return
#IfWinExist
*/

handle_test()
{
	if (0) {
		Hotkey, IfWinExist, ahk_class Chrome_WidgetWin_1
		hotkey, !z, c1
		Hotkey, IfWinExist, - Google Chrome ahk_class Chrome_WidgetWin_1
		hotkey, !z, c2
		Hotkey, IfWinExist
	c1:
		tips("1")
		return
	c2:
		tips("2")
		return

	} else {
		regist_applic_mapkey()
		return 1

		regist_mapkey("b", "c")

		hotkey_cond("chrome")
			regist_hotkey("!t", "log", "chrome")
		hotkey_cond("ever")
			regist_hotkey("!t", "log", "ever")
		hotkey_cond()

		app_exists_map("chrome", "b/new, c/old,t/   10")
	
	}
}
