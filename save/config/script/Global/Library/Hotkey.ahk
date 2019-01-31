
;hotkey_log(Byref string)
{
    log("[hotkey]: " string)
}

; only support assist list and one master key
split_assist_master(Byref hotkey, Byref assist_list="", Byref master="")
{
	if (RegExMatch(hotkey, const("regex", "assist"))) {
		pos := RegExMatch(hotkey, "[^" const("string", "assist") "]")

		if (pos == 1 && (pos := InStr(hotkey, "&"))) {
			assist := trim(SubStr(hotkey, 1, pos - 1))
			master := trim(SubStr(hotkey, pos + 1))
			default(assist_list).insert(assist)

		} else {
			assist := SubStr(hotkey, 1, pos - 1)
			master := SubStr(hotkey, pos)

			if (!assist) {
				warn("split key, hotkey [" hotkey "], assist empty, master [" master "]")
				return 0
			}
			assist_list := get_assist_list(assist)
		}

	; hotkey like LAlt & Tab
	} else {
		list := SubStr(hotkey, 1)
		while ((curr := string_next(list, "&"))) {

			if (InStr(const("input", "assist"), curr)) {
				default(assist_list).insert(curr)

			} else {
				if (master) {
					warn("split key, hotkey [" hotkey "], get two master [" master "] and [" curr "]")
				} else {
					master := curr
				}
			}
		}
	}
	app_log("hotkey [" hotkey "], assist [" out_list(assist_list, false) "], master [" master "]")
}

; param = "1p", 2p, 3p
; param = 1p, "2p",3p
; param = 1p, 2p, 3p
; param = "1p", " 2p", 3p
; param = 1p, '2p' "3p"
; param = 1p 2p, 3p
split_param_list(Byref param)
{
	list := {}

	default(pos, 1)
	; 1. ([ ]*) prefix any blank
	; 2. (m1 | m2) match any
	; 3. [""'][^""']*[""'][,]*, surround by "" or '', end with[, ]
	; 4. [^ ]*  not 
	while ((pos := RegExMatch(param, "([ ]*)([""'][^""']*[""']|[^, ]*)([, ]*)", out, pos))) {
		if ((size := strlen(out1) + strlen(out2) + strlen(out3))) {
			;log(pos "," size ":" out2)
			pos := pos + size 
			list.insert(out2)
			
		} else {
			break	
		}
	}
	return list
}

;================================================================================
;================================================================================
if_assist(Byref key)
{
   	if ((pos := RegExMatch(key, const("regex", "assist")))) {

    	; the first char is not assist char, ant the assist char is shift
    	if (pos > 1 && InStr(key, "+") == pos) {
    		return 0
		}
		return 1
    } else {
    	return 0
    }
}

if_dw(Byref key)
{
	return GetKeyState(key, "P")
}

; check keylist status
if_list_dw(Byref list, stat=1)
{
	for index, name in List
	{
		if (GetKeyState(name, "P") != stat) {
			return false
		}
	}
	return true
}

wait_key_dw(key, time=0.5)
{
    Keywait, %key%, D, T%time%
    
    if (errorlevel == 0) {
		;g_log("wait key " key " dw succ")
		return true
	} else {
		;g_log("wait key " key " dw fail" errorlevel)
		return false
	}
}

wait_key_up(key, time = 0.5)
{
	KeyWait, %key%, , T%time% 
	if (errorlevel == 0) {
		;g_log("wait key " key " up succ")
		return true
	} else {
		;g_log("wait key " key " up fail" errorlevel)
		return false
	}
}

if_invalid_hotkey(Byref hotkey, Byref handle="")
{
	if (if_assist(hotkey)) {
		return false

	; vim_mode
	} else if (InStr(handle, "vim")) {
		return false

	; F1-Fn also used as hotkey
	} else if (InStr(const("input", "function"), "{" hotkey "}")) {
		return false
	}
	return true
}
;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
if_paste(Byref hotkey="")
{
	if (hotkey = "Insert" || !hotkey && if_dw("Insert")) {
		if (if_assist_dw("shift")) {
			input_log("if paste, shift + insert")
			return 1
		}

	} else if (hotkey = "v" || !hotkey && if_dw("v")) {
		if (if_assist_dw("ctrl")) {
			input_log("if paste, ctrl + v")
			return 1
		}
	}
	return 0
}

if_assist_dw(Byref name)
{
	return if_dw("L" name) || if_dw("R" name)	
}

; <!F1 -> <!{F1}
hotkey_compound(Byref hotkey, Byref case=false)
{
	; already contain {, no need convert
	if (InStr(hotkey, "{")) {
		return hotkey
	}
	use_case := case ? "" : "i)"
	return RegExReplace(hotkey, use_case "(" const("hotkey", "compound") ")", "{$U1}")
}

;========================================================================================
;========================================================================================
; send with <>
send_level(Byref hotkey)
{
	; must use send here, sendinput not work
	SendLevel 1
		send % hotkey
	SendLevel 0

	;hotkey_log("send level: " hotkey)
}

send_key(Byref key, Byref count=1)
{
	if (count == 1) {
		sendinput { %key% }
	} else {
		sendinput { %key% %count% }
	}
	;hotkey_log("send key: {" key "}")
}

send_raw(Byref key)
{
	sendinput %key%
	;hotkey_log("send raw: " key)
}

; send and trigger assist hotkey, any assist part must contain <>,  <#d
send_hotkey(Byref hotkey)
{
	if (find_one_of(hotkey, "<>")) {
		origin := get_assist_around(hotkey)
		send_level(origin)
		return origin

	} else {
		send % hotkey
		return hotkey
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------`
; convert assist flag to orign assist key list, {<!, >+}
get_assist_list(Byref assist, Byref erase=false)
{
	array := const("keymap", "assist")
	for key, name in array
	{
		if (Instr(assist, key)) {
			default(list).insert(name)
			
			if (erase) {
				StringReplace assist, assist, %key%, , All
			}
		}
	}
	return list
}

get_assist_around(Byref string)
{
	list := get_assist_list(string, true)
	for index, name in list 
	{
		left  := "{" name " down}" left 
		right := right "{" name " up}"
	}

	;convert := left "{" string "}" right
	convert := left string right
	return convert
}

;=============================================================================================================
;=============================================================================================================
; if key = map, should never use this, will trigger itself
	;	if map key contain <>, should use send_level for trigger
	;	if map key not contain, just send_raw
update_keymap(Byref key, Byref map, Byref handle, Byref case=false)
{
	default(map, key)
	;  !9 -> !d,  !9 -> <!d
	; <!9 -> !d, <!9 -> <!d
	;  !d -> !d, <!d -> !d, (<!d -> <!d wrong)
	if (key != map && find_one_of(map, "<>")) {
		map := LTrim(map, "$~*")
		map := get_assist_around(map)
		handle := "send_level"

	; for any <>, just remove the flag, and trigger
	} else {
		map := hotkey_compound(map, case)
		map := RegExReplace(map, "[$~*<>]")
		handle := "send_raw"
	}
}

;==========================================================================================
;==========================================================================================
wait_input(Byref stat, Byref endkey, Byref time=10, Byref flag="")
{
	if (!endkey) {
		endkey := const("input", "execute")
	}
	Input, char, L1 T%time% %flag%, %endkey%

	default(stat).term := ""
	if (InStr(ErrorLevel, "Endkey:")) {
		pos  := Strlen("Endkey:")
		stat.type := "end"
		stat.term := SubStr(ErrorLevel, pos + 1, StrLen(ErrorLevel) - pos)

	} else if (ErrorLevel == "Timeout") {
		stat.type := "timeout"

	} else if (ErrorLevel == "NewInput") {
		stat.type := "Interrupt"

	} else {
		stat.type := ""
	}
	stat.char := char
	return stat.type == ""
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
hotkey_pressed(Byref list, Byref show, Byref last, Byref change)
{
	; cancel input
	if (if_dw("Escape")) {
		list := ""
		show := ""
		app_log("hotkey down, get esc, cancel")
		return 1

	; confirm input
	} else if (if_dw("Enter") || if_dw("Space")) {
		app_log("hotkey down, get enter success")
		return 1

	} else if (if_dw("Backspace")) {
		if (list) {
			list := ""
			show := ""
			change := 1
			app_log("hotkey down, clear current")
		} else {
			change := 0
		}
		return 0

	} else {
		hotkey_group(assist, "", "assist")
		hotkey_group(master, "", const("hotkey", "most"))

		; get key and is the new one
		if (assist || master) {
			; assist changed, or not just master key up
			if (list && assist == last && Instr(list, assist master)) {
				app_log("hotkey down, no change, current [" assist master "]")

			} else {
				; record last assist key group state
				;	if no assist key now, it changed
				change := 1
				last := assist

				hotkey_group(list, show)
				app_log("hotkey down, current key [" show "]")
			}
		} 
		;g_log("hotkey down, no curr key")
		return 0
	}
}

hotkey_group(Byref list, Byref show, index=0)
{
	list := ""
	show := ""
	default(index, const("hotkey", "every"))
	
	while ((type := string_next(index, opt("next")))) {

		if (!(array := const("hotkey", type))) {
			warn("hotkey group wait, but type [" type "] not exist")
			return 0
		}

		if (type == "assist") {
			array := const("keymap", "assist")
			for key, name in array
			{
				if (if_dw(name)) {
					list := list key
					show := exist_suffix(show, " + ") name 
				}
			}

		} else if (type == "function" || type == "direct" || type == "execute") {
			Loop Parse, array, |
			{
				name := A_LoopField
				if (if_dw(name)) {
					;list := list "{" name "}"
					list := list name
					show := exist_suffix(show, " + ") name
					; only get one key
					break
				}
			}

		} else {
			Loop Parse, array, |
			{
				name := A_LoopField
				if (if_dw(name)) {
					list := list name
					show := exist_suffix(show, " + ") name
					; only get one key
					break
				}
			}
		}
	}
	if (list) {
		;g_log("get key down [" show "]")
	}
	return list
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
ignore_input(Byref time=0.5, Byref key="", Byref end="")
{
	if (key) {
		if (key = "Space") {
			; {A_space} ?
			key := A_space
		}
	} else {
		key := const("input", "every")
	}
	wait_input(stat, key, time)

	if (stat.type == "timeout") {
		return false

	} else {
		end := stat.term
		return true
	}
}

; confirm, no input, or enter as input
confirm(Byref string, Byref time=5, byref force=0)
{
	count := 0
	sure := true

	while (++count < time) {
		show := "Are you sure for " string "? [" time - count "]"
		ToolTip %show%
		
		if (ignore_input(1, , end)) {
			; confirm
			if (end == "Enter") {

			} else if (end == "LControl" || end == "RControl") {
				force := 1

			} else {
				tips("cancel")
				sure := false
			}
			break
		}
	}
	if (sure) {
		tips(string " [ok]")
	} else {
		ToolTip
	}
	return sure
}

input_param(Byref prefix, Byref param)
{
	default(prefix, "please input")
	Suspend, on

	while (1) { 
		tips(prefix ": " param exist_prefix(suffix, " - "), 10000, true)
		suffix := ""

		; if set assist as end char, will only get lower char
		;	when set M flag, we can wakeup by ctrl-char
		if (wait_input(stat, const("input", "most"), , "M")) {

			if (if_assist_dw("ctrl")) {
				; only care about ctrl-v
				if (if_paste()) {
					param := trim(param Clipboard)

				} else {
					input_log("input param, ignore ctrl-[x]")
				}
			} else {
				param := trim(param stat.char)
			}

		} else if (stat.type == "end") {
			input_log("input param, end char [" stat.term "]")

			if (stat.term == "Escape") {
				mode := "cancel"
				break

			} else if (stat.term == "Backspace") {
				param := stri_trim_last(param)
				
			} else if (stat.term == "Space") {
				param := param " "

			} else if (stat.term == "Enter") {
				input_log("input param, succ param [" param "]")
				; only empty after instruct, just help (and no auto list for empty param)
				break

			} else if (if_paste(stat.term)) {
				param := param Clipboard

			; find assist key as end key
			} else {
				; when not set assist as end char, will not go here
				; if (InStr(const("input", "assist"), stat.term)) {
				;   input_log("input param, ignore assist end char")
				;	continue
				;}
				suffix := "invalid [" stat.term "]"
			}				
		
		} else if (stat.type == "timeout") {
			mode := "timeout"
			break
		}
	}
	Suspend, off
	tips(mode)

	if (mode) {
		return 0

	} else {
		param := split_param_list(param)
		return 1
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
bind_handle_input(prefix, Byref handle, Byref arg*)
{
	if (input_param(prefix, list)) {
		
		app_log("param handle binder, origin handle " handle ", get param [" param "]")
		for index, param in list
		{
			arg.insert(param)
		}

		handle.(arg*)
		return 1
	}
	return 0
}

; bind last regist handle
bind_last_handle(Byref binding, Byref prev=false, Byref arg*)
{
	set_handle(entry, binding, arg*)

	last := local("hotkey", "last")

	if (prev) {
		sure_item(last, "link_prev").insert(entry)
	} else {
		sure_item(last, "link_next").insert(entry)
	}
	return 1
}

; bind last regist handle by hotkey or input
bind_last_hotkey(Byref hotkey, Byref binding, Byref prev=false, Byref arg*)
{
	set_handle(entry, binding, arg*)

	last := local("hotkey", "name")[hotkey]

	if (last) {
		app_log("bind last hotkey, get entry for hotkey <" hotkey ">, handle " last.proto)

		if (prev) {
			sure_item(last, "link_prev").insert(entry)
		} else {
			sure_item(last, "link_next").insert(entry)
		}
	} else {
		warn("bind last hotkey, but hotkey [" hotkey "] entry not exist")
	}
	return 1
}

;=============================================================================================================
;=============================================================================================================
curr_hotkey(master=false)
{
	if (master) {
		return hotkey_master(A_ThisHotkey)

	} else {
		return A_ThisHotkey
	}
}

; get hotkey main part
hotkey_master(Byref key)
{
	return trim(RegExReplace(key, const("regex", "assist")))
}

hotkey_master_list(Byref hotkey)
{
	pos := 1
	while ((pos := regexmatch(hotkey, "(" const("hotkey", "combine") ")", match, pos))) { 
		pos := pos + strlen(match1)
		default(list).insert(match1)
	}
	return list
}

master_count(Byref hotkey)
{
	return hotkey_master_list(hotkey).MaxIndex()
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
master_dual(time=0.5)
{
	key := curr_hotkey(true)
	return key_dual(key, time)
}

key_dual(Byref key, Byref time=0)
{
	default(time, 0.2)
	return wait_key_up(key, time) 
		&& wait_key_dw(key, time)
}

if_dual_press(ms = 300) 
{
	Return (A_ThisHotKey = A_PriorHotKey) && (A_TimeSincePriorHotkey <= ms)
}

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
/*
match_last_hotkey(Byref key, Byref time=0)
{
	if (A_PriorHotkey == key) {
		if (time == 0 || A_TimeSincePriorHotkey <= time) {
			;tips(time "-" A_TimeSincePriorHotkey, 1000)
			return true
		}
	}
	return false
}
*/
;-------------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
wheel(up=true, count=1)
{
	if (up){
		MouseClick, Wheelup, , , %count%
	} else {
		MouseClick, WheelDown, , , %count%
	}
}
