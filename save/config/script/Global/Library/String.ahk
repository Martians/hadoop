
;================================================================================
;================================================================================
regex_replace(Byref input, Byref src, Byref dst="", Byref transform=true)
{
	;log(src)
	if (transform) {
		fix := "[" escape_regex(src) "]"
	} else {
		fix := "[" src "]"
	}
	;log("src " src "->" fix ", dst " dst)
	return trim(RegExReplace(input, fix, dst))
}

; reverse search not work!
find_one_of(Byref string, Byref mode, Byref pos=1)
{
	;default(mode, const("string", "bound")) 	
	return RegExMatch(string, "[" mode "]", , pos)
}

find_exactly(Byref string, Byref match, Byref mode="")
{
	; not work porperly
	;return RegExMatch(string, "\b" substr "\b")
	if ((pos := InStr(string, match))) {
		default(mode, const("string", "bound")) 	

		if (pos != 1) {
			;g_log("check start: " SubStr(string, pos - 1, 1))
			if (!InStr(mode, SubStr(string, pos - 1, 1))) {
				return 0
			}
		}

		len := StrLen(match)
		if (pos + len != StrLen(string) + 1) {
			;g_log("check end: " SubStr(string, pos + len, 1))
			if (!InStr(mode, SubStr(string, pos + len, 1))) {
				return 0
			}
		}
		return 1
	}
	return 0
}

;log(RegExReplace("ABCC", "([A-Z])", "[$L1]"))
escape_uppercase(Byref string, Byref wrap=false)
{
	index := 0
	while (++index <= StrLen(String)) {
		curr := SubStr(string, index, 1)
		char := escape_char(curr, wrap)

		if (curr != char) {
			if (!exist) {
				if (index > 1) {
					exist := SubStr(string, 1, index - 1)
				
				; the first char and first time, when set "exist" string
				} else {
					exist := exist char
					continue
				}
			}
		}

		if (exist) {
			exist := exist char
		}
	}	
	return exist ? exist : string
}

escape_char(Byref origin, Byref wrap)
{
	char := const("keymap", "higher")[origin]
	if (wrap) {
		if (char) {
			char := "[" char "]"

		} else {
			; change upper case to [lower]
			;return RegExReplace(origin, "([A-Z])", "[$L0]") also work
			char := RegExReplace(origin, "([A-Z])", "[$L1]")
		}

	} else {
		if (char) {
			char := "+" char

		} else {
			char := RegExReplace(origin, "([A-Z])", "+$L1")
		}
	}
	return char ? char : origin
}

; add escape char before some specific chars
escape_regex(Byref string)
{
	return RegExReplace(string, "[\[\]\.*?+[{|()^$]", "\$0")
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
if_seperator(Byref string)
{
	option := const("single", "seperator")
    return RegExMatch(string, "((" option "))")
}

if_doc(Byref path)
{
	suffix := stri_sepr_next(path, ".", true)
	; match the last part of path, .XXX___ is match
	if (suffix) {
		; return RegExMatch(suffix, "i)\." const("file_type", "doc") ".{0,3}$")
		return RegExMatch(suffix, "i)" const("file_type", "doc") ".{0,3}$")
	} else {
		return 1
	}
}

;=============================================================
;=============================================================
if_digit(Byref char)
{
	if char is Digit 
		return true
	else 
		return false
}

if_prefix(Byref string, Byref sub, erase=false)
{
/*
	; not work if counter some char, as "#*."
	if (RegExMatch(string, "(^" sub ")")) {
		if (erase) {
			size := StrLen(sub)
			string := SubStr(string, size + 1, StrLen(string) - size)
			wait(string)
		}
		return true
	}
	return false
*/
	if (sub) {
		pos := Instr(string, sub)
		if (pos == 1) {
			if (erase) {
				size := StrLen(sub)
				string := SubStr(string, pos + size, StrLen(string) - size)
			}
			return true
		}
	} else {
		return false
	}
}

if_suffix(Byref string, Byref sub, erase=false)
{
	if ((pos := Instr(string, sub, , 0)) && sub) {

		if ((pos == StrLen(string) - StrLen(sub))) {
			if (erase) {
				string := SubStr(string, 1, pos - 1)
			}
			return true
		}
	} else {
		return false
	}
}

; find part in ending, than remve sub flag, get data after sub
if_ending(Byref string, Byref sub, Byref data="")
{
	if ((pos := InStr(string, sub)) && sub) {
		data := SubStr(string, pos + StrLen(sub))
		string := SubStr(string, 1, pos - 1)
		return true

	} else {
		return false
	}
}

; if exist, remove the subkey
if_erase(Byref string, Byref sub)
{
	if ((pos := InStr(string, sub)) && sub) {
		string := SubStr(string, 1, pos - 1) SubStr(string, pos + StrLen(sub))
		return true

	} else {
		return false
	}
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------
if_lower(Byref string)
{
	if string is lower
		return true 
	else 
		return false
}

if_upper(Byref string)
{
	if string is upper 
		return true 
	else 
		return false
}

lower(Byref string)
{
	StringLower, low, string	
	return low
}

; make data as string, if data := 0, value := data, will make value as ""
stringer(Byref data)
{
	return "" data
}

printf(Byref integer, Byref size, Byref blank=0, Byref end=false)
{
	pending := blank ? "          " : 0000000000

	if (StrLen(integer) < size) {

		if (end) {
			return SubStr(pending . integer, -(size - 1)) 

		} else {	
			return SubStr(integer . pending, 1, size) 
		}
	} else {
		return integer
	}
}

print_string(Byref string, Byref size, Byref end=false)
{
	pending := "          "

	if (StrLen(string) < size) {

		if (end) {
			return SubStr(pending string, -(size - 1)) 

		} else {	
			return SubStr(string pending, 1, size) 
		}

	} else {
		return SubStr(string, 1, size)
	}
}

distill_string(Byref string, Byref prefix="", Byref suffix="")
{
	if (prefix) {
		if ((pos := RegExMatch(string, "[^" prefix "]"))) {
			string := SubStr(string, pos) 
		}
	}

	if (suffix) {
		if ((pos := RegExMatch(string, "([" suffix "]*$)", out))) {
			string := SubStr(string, 1, pos - 1)
		}
	}
	return string
}

validate_string(Byref string, Byref size, Byref end=true)
{
	validate := const("string", "valid")

	;count := 0
	;while (++count <= 2) {
	string := print_string(string, size, end)
	string := distill_string(string, validate, validate)

	; in case after distill, size changed and need prinft again
	string := print_string(string, size, end)
	;}
	return string
}

;=============================================================================================================
;=============================================================================================================
convert_line_feed(Byref string, Byref encode)
{
	if (encode) {
		convert := RegExReplace(string, "(`n)", "[n]")
		return RegExReplace(convert, "(`r)", "[r]")
	} else {
		convert := RegExReplace(string, "(\[n\])", "`n")
		return RegExReplace(convert, "(\[r\])", "`r")
	}
}

contain_one_line(ByRef string, ByRef text)
{
    Loop, parse, text, `,   
    {
        if (InStr(string, A_LoopField)) {
            return true
        }
    }
    return false
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; get prev part after sep
stri_sepr_prev(Byref string, Byref sep, Byref end=false)
{
	index := end ? 0 : 1
	pos := InStr(string, sep, , index)
	if (pos) {
		return trim(SubStr(string, 1, pos - strlen(sep)))
	} else {
		return ""
	}
}

; get next part after sep
stri_sepr_next(Byref string, Byref sep, Byref end=false)
{
	index := end ? 0 : 1
	pos := InStr(string, sep, , index)
	if (pos) {
		return trim(SubStr(string, pos + strlen(sep)))
	} else {
		return ""
	}
}

stri_trim_last(Byref string, update=true, origin=true)
{
	if (origin) {
		result := SubStr(string, 1, StrLen(string) - 1)
	} else {
		result := SubStr(string, StrLen(string), 1)	
	}

	if (update) {
		string := result
	}
	return result
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------
stri_prev_line(Byref text, Byref sep)
{
	Loop, parse, text, `n, `r
	{
		if (InStr(A_LoopField, sep)) {
			;log("get prev: " last)
			return last
		}
		last := A_LoopField
		;log("prev: " last)
	}
	return ""
}

stri_next_line(Byref text, Byref sep, connector="")
{
	find := false
	Loop, parse, text, `n, `r
	{
		if (InStr(A_LoopField, sep)) {
			find := true

		} else if (find) {
			if (connector) {
				if (A_LoopField) {
					line := exist_suffix(line, connector) A_LoopField
				}

			} else {
				;log("get next: " A_LoopField)
				return A_LoopField
			}
		}
		;log("next: " A_LoopField)
	}
	return line
}

; can just specific instr occurence ?
stri_spec_line(Byref text, index)
{
	if (index < 0) {
		total := 0
		while (pos != 0) {
			total++	
			pos := InStr(text, "`n",,, total)
		}
		total--
		index := total + index + 1
	}
	pos := InStr(text, "`n",,, index - 1) + 1
	len := InStr(text, "`n",,, index) - pos - 1
	return substr(text, pos, len)
}

stri_max_sub(Byref src, Byref dst)
{
	if (!src || !dst) {
		return src ? src : dst
	}
	
	index := 0
	loop, parse, src
	{
		pos := A_Index
		chr := A_LoopField

		loop, parse, dst
		{	
			if (pos == A_Index) {
				if (chr == A_LoopField) {
					index := pos
					break

				} else {
					return SubStr(src, 1, index)
				}
			}
		}
	}
	; src >= dst
	return SubStr(src, 1, index)
}

; get next prefix
stri_step_prefix(Byref name, Byref index, Byref last=1)
{
	default(index, 0)
	
	if (index < strlen(name) - last) {
		index += 1
		return substr(name, 1, index)
	}
	return 0
}

stri_at(Byref name, byref index=1)
{
	size := StrLen(name)
	if (index <= size) {
		if (index == 0) {
			return SubStr(name, size - 1, 1)
		} else {
			return SubStr(name, index, 1)
		}
	}
	return ""
}

;========================================================================================
;========================================================================================
string_next(Byref string, Byref sep="", Byref char="", Byref opti_str="")
{
	if (opti_str) {
		opti := enum_make("string", opti_str)
		; sub_string define after some const enum_type define, should not use
		size := enum(opti, "string", "sub_string") ? StrLen(sep) : 1

	} else {
		size := 1
	}

	char  := ""
	index := 1
	while (1) {

		if (size > 1) {
			pos := InStr(string, sep)
		} else {
			pos := find_one_of(string, sep, index)
		}
		if (!pos) {
			break
		}

		char := SubStr(string, pos, size)
		; transform meaning for seperator
		if (SubStr(string, pos - 1, size + 2) == opt("left") char opt("righ")) {
			index := pos + size
			continue
		} else {
			index := 1
		}

		curr := SubStr(string, 1, pos - 1)
		string := SubStr(string, pos + size, strlen(string) - (pos + size) + 1)
		;g_log("string next, curr [" curr "] char " char ", string [" string "], pos " pos)

		; get zero param
		if (curr == 0) {
			return "" 0
		}

		curr := trim(curr)
		if (StrLen(curr) > 0) {
			return curr

		} else if (enum(opti, "string", "allow_empty")) {
			;g_log("string next, allow empty, char " char " pos " pos)
			return ""
		}
	}
	;g_log("string next, string [" string "], not find")
	if (!curr) {
		if (string == 0) {
			curr := "" 0

		} else {
			curr := trim(string)
			;g_log("string next, curr [" curr "], string empty")
		}
		char   := ""
		string := ""
	}
	return curr
}

;-----------------------------------------------------------------------------
;----------------------------------------------------------------------------
exist_prefix(Byref type, Byref prefix=" ")
{
	return type ? prefix type : ""
}

exist_suffix(Byref type, Byref suffix=" ")
{
	return type ? type suffix : ""
}

exist_append(Byref type, Byref prefix=" ", Byref suffix=" ")
{
	return type ? prefix type suffix : ""
}

;================================================================================
;================================================================================
;----------------------------------------------------------------------------------
;----------------------------------------------------------------------------------
; fix option, append to or erase from default
set_option(Byref option, Byref default, Byref sep="")
{
	default(sep, opt("next"))

	; distill cancel part in optioin value
	; do it here, when option only have cancel part, distill it first
	if_ending(option, sep("cancel"), data)

    if (option) {
    	; add default, and remove default flag ++
        if (if_prefix(option, sep("default"), true)) {
            option := default sep option
        }

    } else {
        option := default
    }

	; remove canceled flags
	if (data) {
		; log("set option, cancel option: " data)
		while ((str := string_next(data, sep("next"), char))) {
			; log("set option, remove " str ", remain " option)
			if_erase(option, str)
		}
	}
    ; log("set option, last: " option)
    return option
}

; get one option or one seperator
get_option(Byref string, Byref name, Byref erase=false)
{
	; set name, but not seperator
	if (if_seperator(name)) {
		default(type, "sep")

	} else {
		type := "opt"
	}

	if (type == "opt") {
		return next_option(string, name, erase)

	} else {
		return next_seperator(string, name, erase)
	}
}

del_option(Byref string, list="")
{
	; delete all option
	if (list == "opt") {
		type := "opt"
		list := const("single", "option")

	; only delete specific options or one sep or mutli sep which seperated by |
	} else if (list) {
		if (if_seperator(list)) {
			type := "sep"
		} else {
			type := "opt"
		}

	; delete all sep
	} else {
		type := "sep"
		list := const("single", "seperator")
	}
	
	if (type == "opt") {
		; const("single", "option") already transformed
		string := regex_replace(string, list, , false)

	; all seperator must in the end
	} else {
		
		if ((pos := RegExMatch(string, "(" list ")"))) {
			string := trim(SubStr(string, 1, pos - 1))
		}
	}

	return string
}

move_option(Byref option, Byref string, Byref name="")
{
	if (name) {
		if ((data := get_option(string, name, true))) {
			option := option name data
			find := true
		}
	} else {
		list := const("single", "option")
		if ((pos := RegExMatch(string, "[" list "]"))) {
			option := option trim(SubStr(string, pos))
			string := trim(SubStr(string, 1, pos - 1))
			find := true
		}

		list := const("single", "seperator")
		if ((pos := RegExMatch(string, "(" list ")"))) {
			option := option trim(SubStr(string, pos))
			string := trim(SubStr(string, 1, pos - 1))
			find := true
		}
	}
	return find
}

;----------------------------------------------------------------------------------
;----------------------------------------------------------------------------------
; next_option("#12.3 | ||| + #   `t00")
next_option(Byref string, name="", Byref erase=false)
{
	single := name
	option := const("single", "option")
	
	if (name) {
		name := escape_regex(name)
	} else {
		name := option
	}

	default(pos, 1)
	while ((pos := RegExMatch(string, "([" name "])([^" option "]*)", out, pos))) {
		data := trim(out2)
		data := StrLen(data) ? data : "null"
		win_log("pos: " pos "`t option [" out1 "] data [" data "]")

		size := StrLen(out1) + StrLen(out2)
		if (single) {
			if (erase) {
				string := SubStr(string, 1, pos - 1) (pos == 0 ? "" : SubStr(string, pos + size))
			}
			return data
		}
		pos += size
	}
	return 0
}

;next_seperator("|| abcc||;;<>>>>time")
next_seperator(Byref string, name="", Byref erase=false, Byref pos="")
{
	single := name
	option := const("single", "seperator")
	;empty  := const("string", "blank")
	;blank  := const("regex",  "blank")
	
	if (name) {
		name := escape_regex(name)
	} else {
		name := option
	}
	
	default(pos, 1)
	;while ((pos := RegExMatch(string, "((" name "))" blank "([^" option empty "]*)", out, pos))) {
	while ((beg := RegExMatch(string, "(" name ")", out, pos))) {
		size := StrLen(out1)

		if ((pos := RegExMatch(string, "(" option ")", , beg + size))) {
			data := trim(SubStr(string, beg + size, pos - beg - size))
		} else {
			data := trim(SubStr(string, beg + size))
		}
		data := StrLen(data) ? data : "null"
		win_log("next seperator, get option [" out1 "], data [" data "]")

		if (single) {
			if (erase) {
				string := SubStr(string, 1, beg - 1) (pos == 0 ? "" : SubStr(string, pos))
			}
			return data
		}
	}
	return 0
}

option_test()
{
	string := "handle_test"

	if (1) {
		option_next_test(string opt("glob"), opt("glob"))
		option_next_test(opt("glob") string, opt("glob"))

		;----------------------------------------------------------------------------------------
		;----------------------------------------------------------------------------------------
		; erase specific option
		option_next_test(sep("default") string opt("glob") sep("default"), sep("default"))
		; erase all options
		option_next_test(sep("default") string opt("glob") sep("default"), opt("glob"), "opt")
	}
	
	if (1) {
		; only remove sep("next"), no value
		option_next_test(sep("default") string sep("next") sep("time") 25, sep("next"))
		; only remove sep("next"), get value 25
		option_next_test(sep("default") string sep("next") sep("time") 25, sep("time"))
		option_next_test(sep("default") string sep("next") sep("time") 25, sep("time"), -1)

		; only remove sep("default")
		option_next_test(sep("default") string sep("next") sep("time") 25, sep("default"))
	}
}

option_next_test(Byref string, Byref option, Byref erase="")
{
	value := get_option(string, option)
	
	if (erase == -1) {
		erase := ""
	} else {
		default(erase, option)
	}
	result := SubStr(string, 1)
	del_option(result, erase)

	log("origin: " string ", option [" value "], after [" result "]")
}
