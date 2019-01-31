
;========================================================================================
;========================================================================================
; wait for some time
wait(Byref string="", Byref time=60000)
{
	default(string, "wait")
	warn(string, time)
}

warn(Byref string, Byref time=60000)
{
	log()
	log("[WARN]: " string)

	; for later change, then do update script
	Suspend off

	force_tips(string, time)
}

info(Byref string, Byref time=0, using_timer=false)
{
	log(string)

	default(time, 2000)

	force_tips(string, time, using_timer)
}

assert(Byref value, Byref string="")
{
	if (!value) {
		default(string, "assert")
		warn(string)
	}
}

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; mark in log
mark(Byref string="")
{
	log(string "+++++++++++++++")
	log()
}

; wait and tips
wait_tips(Byref string, Byref time=0)
{
	info(string, time, true)
	ignore_input(time/1000)
	cancel_tips()
}

;----------------------------------------------------------------------------------------
cond_tips(Byref notify, ByRef string, time=0, using_timer=false)
{
	if (notify) {
		tips(string, time, using_timer)

	} else {
		; save last error message
		config("last", "error", string)
	}
}

tips(ByRef string, time=0, using_timer=false)
{
	if (display()) {
		if (!time) {
			time := const("time", "tips")
		}

		if (using_timer) {   
			SetTimer tips_timer_label, %time%	

			ToolTip, %string%

		} else {
			SetTimer tips_timer_label, off

			if (string) {
				ToolTip, %string%
			   	sleep time
		   	}
		    ToolTip
		}
	}
	Return

tips_timer_label:
	SetTimer tips_timer_label, off
	ToolTip
	return
}

cancel_tips()
{
	SetTimer tips_timer_label, 0
}

force_tips(ByRef string, time=0, using_timer=false)
{
	old := display(1)
	tips(string, time, using_timer)
	display(old)
}

do_sleep(Byref time)
{
	sleep %time%
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
global_tips(ByRef data, time=0, Byref mode=0)
{
	default(time, 5000)

	array := local("global", "tips")
	array.data := data
	array.time := time
	array.mode := mode

	SetTimer global_tips_label, 0
	return

global_tips_label:
	SetTimer global_tips_label, off

	array := local("global", "tips")
	data := array.data
	time := array.time 
	mode := array.mode

	array.data := 0
	if (data) {   
		screen_type(1, sx, sy)
		min := 1

		if (mode == 0 || mode == "LB") {
			x := 0
			y := sy	

		} else if (mode == "MD") {
			x := round(sx/2) - 20
			y := round(sy/2)

		} else if (mode == "RT") {
			x := sx - min
			y := min

		} else if (mode == "RB") {
			x := sx - 1
			y := sy

		} else {
			warn("global tips, no such mode [" mode "]")
		}
		;g_log("global tips, mode [" mode "], (" x "," y ")")

		CoordMode, tooltip, screen
		ToolTip, %data%, x, y, 2
		SetTimer global_tips_label, %time%	

	} else {      
	    ToolTip, , , , 2
	}
	return
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
splash(ByRef string, times = 500, using_timer=true)
{
	SplashTextOn, , , %string%
	if (using_timer) {   
		SetTimer splash_timer_label, %times%
	} else {       
		sleep times
		SplashTextOff
	}
}

splash_timer_label:
	SetTimer splash_timer_label, off
	SplashTextOff
return

;========================================================================================
;========================================================================================
log_time(tick=false, wrap=true)
{
	if (tick) {
		FormatTime, time, A_NOW, MM-dd-yy HH:mm:ss.
		ticktime := (A_TickCount/1000) & 0xFFFFFFFF
		string := time ticktime

	} else {
		FormatTime, time, A_NOW, MM-dd-yy HH:mm:ss
		string = %time% 
	}
	
	if (wrap) {
		return "[" string "]"
	} else {
		return string
	}
}

log_path(Byref wrap=false)
{
	path := "output.log"
	if (wrap) {
		; must set as this, or wintail will fail
		path := """" const("system", "workd") "\" path """"
	} else {
		path := const("system", "workd") path
	}
	return path
}

;----------------------------------------------------------------------------------------
log(Byref info="")
{
	if (logging()) {

		log_file := glob("log")
		if (log_file.__Handle <= 0) {

			log_file := FileOpen(log_path(), "a")
			if (log_file.length > 8 * 1024 * 1024) {
				log_del()
				log_file := FileOpen(log_path(), "a")

				log_file.WriteLine("new log writting")
				log_file.Read(0) 
			}
			set_glob("log", "", "", log_file)
		}
		
		log_file.WriteLine(log_time(true) " " info)
		log_file.Read(0) 
	}
}

log_del()
{	
	; must give time here, or will stub
	tips("clear log", 500)

	log_file := glob("log")
	log_file.close()
 
	path := log_path()
	FileDelete %path%
}

cond_log(Byref notify, Byref info="") {
	if (notify) {
		log(info)
	}
}

g_log(Byref string)
{
	log(string)
}

f_log(Byref string)
{
	stat := logging(1)
	
	log(string)

	logging(stat)
}

timeout(Byref last, Byref wait)
{
	now := system_time()

	if (now - last > wait) {
		return true

	} else {
		return false
	}
}

file_log_path(Byref name)
{
	if (file_path(name)) {
		path := name
		
	} else {
		path := const("system", "workd") "Output\"
		if (!FileExist(path)) {
			create_dir(path)
		}
		path := path name
	}
	return ext_suffix(path, ".log")
}

;=============================================================================================================
;=============================================================================================================
file_log(Byref name, Byref string, Byref style="", Byref mode="")
{
	file := local("file", name)
	if (file.__Handle <= 0) {
		path := file_log_path(name)

		; if use utf-8, it seems that can't share for write
		file := FileOpen(path, "a", "UTF-8")

		;file := FileOpen(path, "a")
		local("file", name, file)
	}

	if (enum(style, "log_style", "date")) {
		prefix := log_time(, false) " "
	}

	if (enum(style, "log_style", "exec")) {
		exec := validate_string(win_exec_winid(), 7)

		; window text
		;if (enum(style, "log_style", "text")) {
		;	text := validate_string(win_title(), 8)
		;}
	}
	prefix := exist_append(prefix, "[", exec "] ")

	if (enum(style, "log_mode", "on_line")) {
		file.Write(prefix string)

	} else {
		file.WriteLine(prefix string)
	}

	if (enum(mode, "log_mode", "close")) {
		file.Close()

	} else if (enum(mode, "log_mode", "read")) {
		file.Read(0)
	}
}

file_log_del(Byref name)
{
	file_log_close(name)

	path := file_log_path(name)
	FileDelete %path%
}

file_log_close(Byref name)
{
	file := local("file", name)

	if (file.__Handle > 0) {
		file.Close()
	}
}

create_dir(Byref path)
{
	FileCreateDir %path%
	if (ErrorLevel != 0) {
		tips("create dir failed " A_LastError, 2000)
		return false

	} else {
		return true
	}
}

;========================================================================================
;========================================================================================
get_input_height(Byref string)
{
	StringReplace, string, string,`n, `n, UseErrorLevel
	height := (ErrorLevel + 1) * 18
	If (height < 40) {
		height += 80
	}
	Return height + 100
}

get_input(Byref input, Byref string="", Byref wait=20)
{
	;win_center(win_curr(), x, y, true)
	InputBox, input, code snippet name:, %string%, 
		, , % get_input_height(string), , , , %wait%

	if (ErrorLevel == 1) {
		return 0

	} else if (input) {
		return 1
	}
}

;========================================================================================
;========================================================================================
if_dir(Byref path)
{
	file := actual_path(path)

	FileGetAttrib attr, %file%
	return InStr(attr, "D")
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------
file_name(Byref path)
{
	SplitPath, path, name, dir
	return name
	/*
	pos1 := Instr(path, "\", , 0)
	pos2 := Instr(path, "/", , 0)
	pos := (pos2 > pos1) ? pos2 : pos1

	if (pos == 0) {
		return ""
	} else {
		return SubStr(path, pos + 1)	
	}
	*/
}

file_path(Byref path)
{
	SplitPath, path, name, dir

	if (find_one_of(path, "\\/")) {
		return dir

	} else {
		return ""
	}
}

ext_suffix(Byref string, Byref suffix=".log")
{
	if (RegExMatch(string, "\.[a-zA-Z0-9]{1,4}$")) {
		return string

	} else {
		return string suffix
	}
}

;========================================================================================
;========================================================================================
date(Byref date_time=0)
{
	default(date_time, A_Now)
	FormatTime, time, %date_time%, yyyy-MM-dd
	return time
}

date_time(Byref date_time=0, Byref format="")
{
	default(date_time, A_Now)
	default(format, "yyyy-MM-dd HH:mm:ss")

	FormatTime, time, %date_time%, %format%
	return time
}

time(type = 0, hour = 0, min = 0
	, Byref mode = 10, Byref elapse = 0)
{
	if (type == 0) {
		FormatTime, time, A_NOW, HH:mm:ss
		return time
	}

	if (hour == 0 && min == 0) {
		hour := A_Hour
		min := A_Min
	}
	
	if (type == "next") {
		min := (Floor(min / mode) + 1) * mode
	
	} else if (type == "prev") {
		min := (Floor(min / mode)) * mode
	
	} else if (type == "inc") {
	
		_hour := Floor(elapse / 60)
		_min  := Mod(elapse, 60)

		;min := (Floor(min / mode) + 1) * mode
		hour := hour - _hour
		min  := min  - _min
	
		return time(4, hour, min)
	}
	
	if (min == 60) {
		hour := hour + 1
		min  := 00
		
	} else if (min < 0) {
		min  := min + 60
		hour := hour - 1
	}
		
	if (strlen(hour) < 2) {
		hour := "0" hour
	}
		
	if (strlen(min) < 2) {
		min := "0" min
	}
	return hour ":" min
}

;=========================================================================
;=========================================================================
sure_item(Byref obj, Byref group="", Byref index="", Byref type="")
{
    if (!obj) {
        obj := {}
    } 
    
    if (group) {
        if (!obj[group]) {
            obj[group] := {}
        }
        
        if (index) {
            if (!obj[group][index]) {
                obj[group][index] := {}
            }

            if (type)  {
                if (!obj[group][index][type]) {
                    obj[group][index][type] := {}
                }
                return obj[group][index][type]

            } else {
                return obj[group][index]
            }

        } else {
            return obj[group]
        }
    } else {
        return obj
    }
}

get_item(Byref obj, Byref group="", Byref index="", Byref type="")
{
	if (group) {
	    if (index) {
	        if (type) {
				return obj[group][index][type]
	        } else {
	            return obj[group][index]
	        }

	    } else {
	        return obj[group]
	    }
	} else {
		return obj
	}
}

last_item(Byref obj, Byref group, Byref index="", Byref type="", Byref name="")
{
    if (index) {
        if (type) {
        	name := type
        	return obj[group][index]
        } else {
        	name := index
            return obj[group]
        }
    } else {
    	name := group
        return obj
    }
}

item_data(Byref obj, Byref group, Byref index="", Byref type="", Byref data="")
{
	array := last_item(obj, group, index, type, name)
	if (data) {
		array[name] := data
	} else {
		last := array.remove(name)
	}
}

item_attr(Byref entry, Byref name)
{
	return entry[name]
}

get_size(Byref list) 
{
	size := 0
	for index, entry in list
	{
		size++		
	}
	return size
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------
ranger(Byref base, Byref min, Byref max, Byref inc)
{
	if (base < min) {
		base := min

	} else if (base > max) {
		base := max

	} else {
		base += inc
		if (base > max) {
			base := max
		}
	}
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------

;============================================================================
;============================================================================
to_list(Byref arg*)
{
	for index, entry in arg
	{
		default(list).insert(entry)
	}
	return list
}

out_list(Byref list, Byref line=true, Byref handle="", Byref arg*)
{
	for index, entry in list
	{
		show := handle ? handle.(index, entry, arg*) : entry
		if (line) {
			string := exist_suffix(string, "`n") show  
		} else {
			string := exist_suffix(string, " ") show
		}
	}
	return string
}

show_index(Byref index, Byref entry)
{
	;return "(" index " " entry.name ""
	return "<" index " [" entry.name "]"
}		

url_request(Byref link, Byref string) 
{
	static whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET", link string, true)
	;whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko)")
	whr.Send()
	whr.WaitForResponse()
	Return RegExReplace(whr.ResponseText, "^.*?""(.*?)"".*$", "$1")
}

