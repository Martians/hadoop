
;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
input_log(Byref string)
{
	log("[input]: " string)
}

glob_input(Byref type, Byref name="", Byref create=true)
{
	if (create) {
		array := glob_sure("glob", "input", type)
	} else {
		array := glob_item("glob", "input", type)		
	}
	
	if (name) {
		return array[name]
	} else {
		return array
	}
}

regist_input_type(Byref char, Byref name, Byref prefix="input")
{
	array := glob_input("group")
	index := glob_input("index")

	input := {}
	input.prefix := prefix
	input.name 	 := name
	; 	input[const("input", "master")] keep origin handle
	; 	input[const("input", "short")] keep define shortcut, and auto shortcut, point to mastr
	;	input[const("input", "auto")][curr_input][prior][name]
	; 	input[const("input", "inst")] keep instruct info, point to entry

	; name entry
	array[name] := input
	; shortcut entry
	index[char] := input

	regist_hotkey(char, "parse_input", name)
}

; switch current type when regist for convenience
input_type(Byref name=-1, Byref origin="")
{
	curr := glob_input("curr")
	; get current value
	if (name != -1) {
		origin := curr.input
		if (!name) {
			curr.input := ""
		} else {
			curr.input := glob_input("group", name, false)
			if (!curr.input) {
				warn("set input type, but type [" name "] not exist")
			}
		}
	}
	return curr.input
}

input_attr(Byref name, Byref attr="")
{
	input := glob_input("group", name, false)
	if (attr) {
		return input[attr]	
	} else {
		return input		
	}
}

; get current stat when trigger by hotmastr handle
input_curr(Byref index="", Byref name="")
{
	curr := glob_input("curr")
	if (index) {
		if (name) {
			return curr[index][name]
		} else {
			return curr[index]
		}
	} else {
		return curr
	}
	;	curr.input  ; input entry
	;	curr.name   ; command name
	;	curr.suffix
	;	curr.param
}

reset_curr(Byref total=true)
{
	curr := input_curr()
	curr.suffix := ""
	curr.match 	:= ""
	curr.param 	:= ""
	curr.index 	:= ""

	; reset command, clear old one
	if (total) {
		curr.name := ""
		hot_tips("reset")
	}
}

;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
input_entry(Byref name="", Byref type="")
{
	if (!name) {
		name := actual_input(-1)
	}

	default(type, const("input", "master"))
	return input_type()[type][name]
}

input_short_entry(Byref name="")
{
	return input_entry(name, const("input", "short"))
}

input_auto_entry(Byref name="")
{
	return input_entry(name, const("input", "auto"))
}

input_instr_entry(Byref name="")
{
	/*
	if (config("input", "instr") == "space") {
		instr := name " "
	} else {
		instr := name
	}
	*/
	return input_entry(name, const("input", "inst"))
}

input_suffix(Byref suffix=-1)
{
	curr := input_curr()
	if (suffix != -1) {
		curr.suffix := suffix
	}
	return curr.suffix
}

;=========================================================================
;=========================================================================
hot_tips(Byref prefix, Byref string="", Byref time=10000, Byref sep="_ ")
{
	prefix :=
	curr := input_curr()
	
	; update info at once, only for small time
	if (time == 0) {
		async := false

	} else {
		async := true
		if (time == -1) {
			
		} else {
			; current input string 
			input := curr.name sep 
		}
	}
	tips(prefix curr.input.prefix ": " input string, time, async)
}

; maybe name != entry.name, name is shortcut or sth
input_single_suffix(Byref entry, Byref string="", Byref square=false)
{
	if (entry.help) {
		end := " -> " entry.help
	}

	if (square) {
		return "[" string "]" end

	} else {
		return string end
	}
}

; set warn if input conflict
hot_warn(Byref string) 
{
	input := input_type()

	log()
	log("<<<<---- regist input [type " input.prefix "]: " string)
	warn(input.prefix " " string)
}

input_entry_help(Byref name, short=false)
{
	if (short) {
		entry := input_short_entry(name)

	} else {
		entry := input_entry(name)
	}
	return entry.help ? entry.help : entry.name
}

;=========================================================================
;=========================================================================
get_input_option(Byref name, Byref help, Byref handle, Byref arg*)
{
	; distill option from help and handle, all move to option string
	move_option(option, help)
	move_option(option, handle)

	if (move_option(option, arg[arg.MaxIndex()])) {
		arg.remove(last)
		input_log("get input option, from last arg, name [" name "], option [" option "]")

	} else {
		input_log("get input option, from help and handle, name [" name "], option [" option "]")
	}
	return option
}

input_option(Byref entry, Byref option)
{
	if (get_option(option, sep("empty"))) {
		entry.allow_empty := 1
	}
}

get_input_prior(Byref name, Byref option)
{
	if ((entry := glob_app(name))) {
		if (entry.prior) {
			input_log("get input prior, from app, name [" name "] prior [" entry.prior "]")
		} else {
			entry.prior := 9
		}
	} 

	if ((prior := get_option(option, opt("prior")))) {
		input_log("get input option, name [" name "] prior [" prior "]")
	}

	if (entry.prior && !prior) {
		prior := entry.prior
	}
	return default(prior, 10)
}

; regist input, mastr can't set as maste mastr | shortcut | shortcut
regist_input(string, Byref help, Byref handle, Byref arg*)
{
	if (!(input := input_type())) {
		name := get_handle(handle) ? get_handle(handle) : handle
		warn("regist input, list [" string "] help: " help ", handle [" name "], not set input type")
		return 0
	}

	; Todo: multi short cut
	;array := StrSplit(name, opt("next"))
	name  := string_next(string, opt("next"))
	short := string_next(string, opt("next"))

	option := get_input_option(name, help, handle, arg*)
	prior  := get_input_prior(name, option)

	if (short && glob_app(short)) {
		; define short, but not define name
		save := name
		name := short
		short := save
	}
	set_handle(entry, handle, arg*)

	if (entry.prior) {
		;if (entry.prior != prior)
		;;g_log("regist input, prior already set as [" entry.prior "]")
	}
	entry.prior := prior
	entry.name 	:= name 
	entry.short := short
	input_option(entry, option)

		; record last hotkey
		local("hotkey", "last", entry)
		local("hotkey", "name")[name] := entry

	if (help) {
		if (entry.help) {
			;g_log("regist input, already set help [" entry.help "]")
		}
		; maybe help messasge already set, override the default one
		entry.help 	:= help
	}

    ;log("regist input, try regist name [" name "-" short "], handle [" get_handle(entry, "info") "]")

	if (switch("instr")) {
		; block directly trigger with name; it will need a blank, then trigger instruct handle
		; set actual value
		
		; add instruct entry, point to mastr entry
		; 	must set this, for regist_input check
		array := sure_item(input, const("input", "inst"))
		array[name] := entry
		entry.type  := "instr"

		if (config("input", "instr") == "space") {
			regist_input_automate(name " ", input, entry)

		} else {
			; used when input the whole command
			if (regist_input_mastr(name, input, entry)) {
				return ""
			}
			regist_input_automate(name, input, entry)
		}

		{
			prior := entry.prior
			entry.prior := 11 

			; set help info, when input const("input", "inst"), will help all instruct
			regist_input_automate("instr " name, input, entry)
			entry.prior := prior 
		}
	} else {
		if (regist_input_mastr(name, input, entry) 
			|| regist_input_short(name, short, input, entry)) 
		{
			return ""
		}

		; no need regist the master name
		if (if_prefix(name, short)) {
	    	input_log("regist input, master name [" name "] prefixed by short [" short "], only regist auto short")
		} else {
			regist_input_automate(name, input, entry)	
		}	    	
	   	regist_input_automate(short, input, entry)
   	}	
	return entry
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
regist_input_instruct(Byref name, Byref help, Byref handle, arg*)
{
	if (!(input := input_type())) {
		warn("no input type for instruct [" name "]")
		return
	}
	
switch("instr", 1)
	; just used for instruct help, add a blocker char, make it never automate trigger, 
	regist_input(name, help " [instr]" prior(1), handle, arg*)
switch("instr", 0)
}

regist_instr_autolist(Byref name, Byref list_type="", Byref list_group="")
{
	if (!(input := input_type())) {
		warn("regist instruct auto list, no input type for instruct [" name "]")
		return ""
	
	} else if (!(entry := get_item(input, const("input", "inst"), name))) {
		warn("regist instruct auto list, input type [" input.name "] have no instr [" name "]")
		return ""
	}

	if (get_option(list_type, sep("handle"), true)) {
	;if (if_function(list_type, option)) {
		entry.auto_list  := list_type

	} else {
		entry.list_type  := list_type
		entry.list_group := input_attr(default(list_group, input.name))
	}
	return entry
}

regist_instr_param_list(Byref group, Byref instr, Byref param_list="")
{
	;regist_instr_autolist(instr, list_type, "param")
	if (!(input := input_attr(group))) {
		warn("regist instr automate, no input type for instruct [" instr "]")
		return ""
	}

	if (!(entry := get_item(input, const("input", "inst"), name))) {
		warn("regist instr automate, input type [" input.name "] have no instr [" instr "]")
		return ""
	}
	
	auto := sure_item(input, "param", instr)
	while ((param := string_next(param_list, opt("next")))) {
		
		if ((prior := stri_sepr_next(param, opt("prior")))) {
			param := stri_sepr_prev(param, opt("prior"))
			input_log("regist instr automate, instr [" instr "] param [" param "] prior [" prior "]")
		}
		default(prior, 10)		
		list := sure_item(auto, prior)

		list.insert(param)
		input_log("regist instr automate, instr [" instr "] param [" param "] prior [" prior "]")
	}
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
; check if key will masked by other master or short, for some key shorter than us, example: set will mask settime
input_check_mask(Byref name, Byref input, Byref entry, Byref type)
{
	while ((prefix := stri_step_prefix(name, index, 0))) {
		; check name prefix override
		if (input_entry(prefix) && input_entry(prefix).name != entry.name) {
			hot_warn("regist " type " [" name "] <" entry.help ">, but prefix [" prefix "] already registed as master, by <" input_entry_help(prefix) ">")
			return 1

		} else if (input_short_entry(prefix) && input_short_entry(prefix).name != entry.name) {
			hot_warn("regist " type " [" name "] <" entry.help ">, but prefix [" prefix "] already registed as short, by <" input_entry_help(prefix, true) ">")
			return 1
		}
	}

	; check the full name, even it is just automate, but it implicitly means that current conflict with previous master or short
	;	input[const("input", "auto")][prefix]
	if ((list := input_auto_entry(name))) {
		for prior, array in list
		{
			for mastr, entry in array
			{
				; only help once
				hot_warn("regist " type " [" name "] <" entry.help ">, but name [" name "] already registed as auto, by <" entry.help ">")	
				return 1
			}
		}		
	}
	return 0		
}

; input[const("input", "master")][sub_key]
regist_input_mastr(Byref name, Byref input, Byref entry)
{
	; check name name conflict
	if (input_check_mask(name, input, entry, const("input", "master"))) {
		return 1

	} else {
		; regist name name
		array := sure_item(input, const("input", "master"))

		if (array[name]) {
			hot_warn("regist master [" name "] <" entry.help ">, but master already registed, by <" get_handle(array[name]) "(" entry.type ")>")
			return 1
		}
		array[name] := entry
		return 0
	}
}

; input[const("input", "short")][sub_key]
regist_input_short(Byref name, Byref short, Byref input, Byref entry)
{
	; regist short cut
	if (short) {
			; check short conflict
		if (input_check_mask(short, input, entry, const("input", "short"))) {
			return 1

		} else {
			array := sure_item(input, const("input", "short"))
		    array[short] := entry
	    }
	}
    log("regist input [" input.name "], entry [" name exist_prefix(short, opt("next")) "] prior [" entry.prior "], help <" entry.help ">")	
	return 0
}

; input[const("input", "auto")][sub_key]
;	array
regist_input_automate(Byref name, Byref input, Byref entry)
{
	auto := sure_item(input, const("input", "auto"))

	; get every prefix of the shortname
	while ((prefix := stri_step_prefix(name, index))) {
		
		; conflict with any name
		if (input_entry(prefix)) {
			log("`t auto regist [" prefix "] for [" name "], but conflict with master [" input_entry(prefix).name "] <" input_entry_help(prefix) ">, ignore remain auto")
			;continue
			break
		
		; conflict with any name
		} else if (input_short_entry(prefix) && input_short_entry(prefix).name != name) {
			log("`t auto regist [" prefix "] for [" name "], but conflict with short [" input_short_entry(prefix).name "] <" input_entry_help(prefix, true) ">, ignore remain auto")
			;continue
			break
		}
		
		; check if already regist in other Priority list
		array := sure_item(auto, prefix)
		for prior, list in array
		{
			; already regist such auto prefix for the name
			;    ez. master name regist its prefix, so short no need regist again
			if (list[name]) {
				exist := true
				input_log("`t ==== auto regist [" prefix "] -> [" name "], entry already exist for same master [" entry.name "], ignore current")
				break
			}
		}
		if (!exist) {	
			list := sure_item(array, entry.prior)
			list[name] := entry
			input_log("`t auto regist [" prefix "-" entry.prior "] -> [" name "],  [master:" entry.name "]")
		}
	}
}

erase_input(Byref group, Byref name)
{
	if (group) {
		if (!(input := input_type(group))) {
			warn("input erase, but input [" group "] not exist")
			return 0
		}
	} else if (!(input := input_type())) {
		warn("input erase, but no current input")
		return 0
	}

	if ((entry := input_entry(name))) {
		short := entry.short

	} else if ((entry := input_short_entry(name))) {
		name  := entry.name
		short := entry.short
	} else {
		warn("input erase, but input [" group "] name [" name "], not master or short entry")
		return 0
	}
	input_log("try to erase name [" name "] short [" short "]")

	item_data(input, const("input", "master"), name)
	count := erase_input_automate(name, input, entry)

	if (short) {
		item_data(input, const("input", "short"), short)
		count += erase_input_automate(short, input, entry)
	}

	log("erase_input, erase name [" name "]" exist_append(short, " short [", "]") ", erase " count " auto entry")
}

; input[const("input", "auto")][sub_key]
;	array
erase_input_automate(Byref name, Byref input, Byref entry)
{
	auto := sure_item(input, const("input", "auto"))

	count := 0
	index := 0
	; get every prefix of the shortname
	while ((prefix := stri_step_prefix(name, index))) {
		
		exist := ""
		; check if already regist in other Priority list
		array := sure_item(auto, prefix)
		for prior, list in array
		{
			; already regist such auto prefix for the name
			;    ez. master name regist its prefix, so short no need regist again
			if (list[name] == entry) {
				exist := true
				list_size  := get_size(list)
				array_size := get_size(array)
			}
		}
		; auto[prefix][piror][name]
		if (exist) {

			if (list_size == 1) {
				if (array_size == 1) {
					item_data(auto, prefix)
					input_log("`t== erase prefix [" prefix "] for [" name "], erase whole prefix [" prefix "]")	
				} else {
					item_data(array, prior)
					input_log("`t-- erase prefix [" prefix "] for [" name "], erase prefix [" prefix "], whole prior list [" prior "]")		
				}
			} else {
				item_data(list, name)
				input_log("`t   erase prefix [" prefix "] for [" name "], erase prefix [" prefix "] prior list [" prior "], remain " list_size - 1)
			}
			count++
		}
	}
	return count
}

;=========================================================================
;=========================================================================
parse_input(Byref name)
{
	batch_lines(1)

	input := input_type(name)
	reset_curr()

	while (parse_input_single()) {

		if ((entry := input_entry()) 
			|| (entry := input_short_entry())) 
		{
		 	input_log("get main or short")
		 	hot_tips("exactly", input_single_suffix(entry, ""),  , "")
			break
		} 

		; update help when update command string
		hot_tips("inc")

		if (list_input_auto(input, input_curr("name"), "", list)) {
			hot_tips("list", list)
			continue

		} else { 
			reset_curr(false)
			hot_tips("reset", " -> none")
		}
		entry := ""
	}

	if (entry) { 
		; input full name, then wait if a space is enteri
		if (entry.name = actual_input(-1)) {
			ignore_input(0.3)
			input_log("wait last space")
		}
		trigger_input(entry)
	}
	input_type(0)

	batch_lines(0)
}

; accumalte record each mastr, until end
parse_input_single()
{
	curr := input_curr()

	count := 0
	while (count-- >= 0) {
		; in this case, can't write Higher char
		; if (wait_input(stat, const_comb("input", "every"))) { 

		; not parse assist now
		If (wait_input(stat, const("input", "most"), , "M")) {   
	    
	 		; specific item in automate list
			if (input_digit(curr.name, stat.char)) {
				if (select_input_auto(curr.input, curr.name, stat.char, entry)) {
					mode := "find"
				}
				break

			} else {
				if (if_assist_dw("ctrl")) {
					; only care about ctrl-v
					if (if_paste()) {
						input_log("parse single input, get [ctrl + v], copy append [" Clipboard "]")
						curr.name := trim(curr.name Clipboard)

					} else {
						input_log("parse single input, ignore ctrl-[x]")
					}

				} else {
					curr.name := trim(curr.name stat.char)
				}
			}
			
		} else if (stat.type == "end") {
			input_log("parse single input, end char [" stat.term "]")

			if (stat.term == "Backspace") {
				curr.name := stri_trim_last(curr.name)

			} else if (stat.term == "Tab") {
				name := actual_input(-1)
				; match the maxmize mach list
				if (name != curr.match 
					&& InStr(curr.match, name)) 
				{
					if (name == curr.name) {
						curr.name := curr.match
					} else {
						curr.name := opt("escape") curr.match
					}
				}

			} else {
				; match struct
				if ((entry := input_instr_entry())) {
					if (stat.term == "Space") {
						mode := "find"
						break
					}
				}

				if (stat.term == "Enter" || stat.term == "Space") {
					; trigger the first automate mastr
					if (select_input_auto(curr.input, curr.name, 1, entry)) {
						mode := "find"
						break
					}

				} else if (if_paste(stat.term)) {
					input_log("fetch single input, get [shift + Insert], copy append [" Clipboard "]")
					curr.name := curr.name Clipboard
					break
				
				} else if (InStr(const("input", "assist"), stat.term)) {
					; loop again
					count++
					continue
				}

				hot_tips("end", "none", 0)
				mode := "exit"
			}
		} else if (stat.type == "timeout") {
			hot_tips("tout", stat, 0)
			mode := "exit"
		}
	}

	if (mode) {
		if (mode == "find") {
			trigger_input(entry)
		}
		return 0
	} else {
		return 1
	}
}

trigger_input(Byref entry)
{
	name := actual_input(-1)

	if (input_instr_entry()) {
		input_log("parse single, get instr [" name "], handle " get_handle(input_instr_entry(), "info"))
		trigger_input_instruct()

	} else {		 
		hot_tips("input", input_single_suffix(entry, name), -1)
		log("`t trigger input: (type " input_type().name "), name [" name "] -> " entry.help)
		
		handle_work(entry)
	}
}

;=========================================================================
;=========================================================================
list_input_auto(Byref input, Byref param, Byref type, Byref list, Byref handle="")
{
	default(handle, "get_input_auto")
	string := actual_input(param)

	if ((list := handle.(input, string, type, match))) {	
		input_log("list input auto, string " string)

		input_suffix("")
		input_curr().match := match 
		return 1
		
	} else {
		input_curr().match := ""
		input_log("list input auto, no auto list - " string)
		return 0
	}
}

select_input_auto(Byref input, Byref param, Byref last, Byref entry, Byref type="", Byref handle="")
{
	default(handle, "get_select_auto")
	string := actual_input(param)

	if ((entry := handle.(input, string, type, last))) {
		; set full name
		if (entry.type == "instr") {
			curr := input_curr()

			; update param string
			if (param == string) {
				curr.name := entry.name	
			} else {
				curr.name := opt("escape") entry.name
			}
		}
		; should use entry.name, not mastr, mastr maybe only partial of the instruct
		input_log("select input auto, try index " last)
		return 1

	} else {
		input_suffix("index " last " exceed range!")
		input_log("select input auto, index " last " exceed range!")
		return 0
	}
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
get_input_auto(Byref input, Byref param, Byref type, Byref match)
{
	index := 0

	if ((auto := input[const("input", "auto")][param])) {	

		for prior, array in auto
		{
			for name, entry in array
			{
				if (type && entry.type != type) {
					continue
				}
				;default(match, name)
				match := stri_max_sub(match, name)	
				; only show help if help string not same as name name
				;list := list "`t<" index++ " " name (name == entry.help ? "" : (": `t" entry.help)) "`n"
				if (name == entry.help) {
					head := name
					help := ""
				} else {
					head := name ":"
					help := "`t" entry.help
					;help := entry.help
				}
				list := list "`t<" ++index " " printf(head, 5, true) help "`n"
				last := entry
			}
		}
	}
	; get any list output or note
	input_curr().index:= index

	if (list) {
		; only one item exist
		if (index == 1) {
			if (InStr(last.name, param)) {
				show := last.name
			} else {
				show := last.short
			}

			; get the remain part of the mastr
			suffix := Substr(show, strlen(param) + 1)
			list := input_single_suffix(last, suffix, true)

		} else {
			list := " " input_suffix() "`n" list
		}
	}
	return list
}

get_select_auto(Byref input, Byref param, Byref type, Byref last)
{
	if ((auto := input[const("input", "auto")][param])) {	
		index := 0
		for prior, array in auto
		{
			for name, entry in array
			{
				if (type && entry.type != type) {
					continue
				}

				if (++index == last) {
					return entry
				}
			}
		}
	}
	return 0
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
get_input_param(Byref input, Byref param, Byref instr, Byref match)
{
	index := 0
	if ((auto := input["param"][instr])) {	

		for prior, array in auto
		{
			for curr, name in array
			{
				if (!param || if_prefix(name, param)) {
					;default(match, name)
					match := stri_max_sub(match, name)	
					; only show help if help string not same as name name
					;list := list "`t<" index++ " " name (name == entry.help ? "" : (": `t" entry.help)) "`n"
					list := list "`t<" ++index " " name "`n"
					last := name
				}
			}
		}
	}

	if ((entry := input_instr_entry()) && (auto := entry.auto_list.(param))) {

		for name, entry in auto 
		{
			if (!param || if_prefix(name, param)) {
				;default(match, name)
				match := stri_max_sub(match, name)	
				; only show help if help string not same as name name
				;list := list "`t<" index++ " " name (name == entry.help ? "" : (": `t" entry.help)) "`n"
				list := list "`t<" ++index " " entry "`n"
				last := name
			}
		}
	}
	; get any list output or note
	input_curr().index:= index

	if (list) {
		; only one item exist
		if (index == 1) {
			; get the remain part of the mastr
			suffix := Substr(last, strlen(param) + 1)
			list := "[" suffix "]"

		} else {
			list := " " input_suffix() "`n" list
		}
	}
	return list
}

get_select_param(Byref input, Byref param, Byref instr, Byref last)
{
	index := 0
	if ((auto := input["param"][instr])) {	

		for prior, array in auto
		{
			for curr, name in array
			{
				if (!param || if_prefix(name, param)) {

					if (++index == last) {
						return name
					}
				}
			}
		}
	}

	if ((entry := input_instr_entry()) && (auto := entry.auto_list.(param))) {
		for name, entry in auto 
		{
			if (!param || if_prefix(name, param)) {

				if (++index == last) {
					return name
				}
			}
		}
	}
	return 0
}

;=========================================================================
;=========================================================================
instr_tips(Byref string, Byref time=10000, Byref suffix="")
{
	hot_tips("instr", string "   [instr]" suffix, time, " ")
}

trigger_input_instruct()
{
	if (fetch_input_param()) {
		entry := input_instr_entry()

		param := trim(actual_param(-1))
 
		instr_tips("[" entry.name "] -> " param, -1)

		log("instruct name [" entry.name "], handle [" entry.handle "] -> <" param ">")
		handle_work(entry, param)
		return 1

	} else {
		input_log("instruct: expect some param")
		return 0
	}
}

;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
; get inst param
fetch_input_param()
{
	instr_tips("") 
	; if instr have own params
	list_auto_param("")

	while (1) { 

		If (wait_input(stat, const("input", "most"), , "M")) {   

			if (input_digit(param, stat.char)) {

				if (fetch_auto_param(param, stat.char)) {
					;g_log("fetch input param, fetch auto name success")
					break

				} else {
					instr_tips(param, , " - index " stat.char " exceed range!")
					input_suffix("")
				}

			} else {
				if (if_assist_dw("ctrl")) {
					; only care about ctrl-v
					if (if_paste()) {
						input_log("fetch input param, get [ctrl + v], copy append [" Clipboard "]")
						param := trim(param Clipboard)

					} else {
						input_log("fetch input param, ignore ctrl-[x]")
					}

				} else {
					param := trim(param stat.char)
				}
				list_auto_param(param)
			}

		} else if (stat.type == "end") {
			input_log("fetch input param, end char [" stat.term "]")

			if (stat.term == "Backspace") {
				char  := stri_trim_last(param, false, false)
				param := stri_trim_last(param)
				list_auto_param(param)
			
			} else if (stat.term == "Tab") {
				name := actual_param(param)
				; match the maxmize mach list
				if (name != input_curr().match 
					&& InStr(input_curr().match, name)) 
				{
					if (name == param) {
						param := input_curr().match
					} else {
						param := opt("escape") input_curr().match
					}
					; replay the auto list
					list_auto_param(param)
				}

			} else if (stat.term == "Escape") {
				hot_tips("Esc", "none", 0)
				return 0

			} else if (stat.term == "Space" || stat.term == "Enter") {
				; only empty after instruct, just help (and no auto list for empty param)
				if (stat.term == "Space" && StrLen(trim(actual_param(param))) == 0 
					&& !input_curr().index)
				{
					input_log("fetch input param, get empty blank, continue")
					param := param " "
					instr_tips(param)

				} else {
					; we expect transfer a digit here
					if (fetch_auto_param(param, 1)) {
						;g_log("fetch input param, auto fetch name index 1")

					} else {
						;g_log("fetch input param, auto fetch name index 1, but failed, use param [" param "]")
						input_curr().param := param
					}
					break
				}

			; find assist key as end key
			} else {
				; if endkey is shift, or shift is down
				if (if_dw("LShift") || if_dw("RShift")) {
					if (if_paste(stat.term)) {
						input_log("fetch input param, get [shift + Insert], copy append [" Clipboard "]")

						param := param Clipboard
						list_auto_param(param)
					}
				} else {
					; use space or enter for confirm
					;	we can set string or shortcut key as param
					if (InStr(const("input", "assist"), stat.term)) {
						if (fetch_input_hotkey(param)) {
							input_curr().param := param
						}
					} 
					break
				}
			}
		
		} else if (stat.type == "timeout") {
			hot_tips("tout", stat, 0)
			return 0
		}
	}

	; get any param
	if (actual_param(-1) || input_instr_entry().allow_empty) {
		log("fetch input param, get param [" actual_param(-1) "]")
		return 1

	} else {
		hot_tips("exit", "none", 0)
		return 0
	}
}

;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
list_auto_param(Byref param)
{
	instr := input_instr_entry()
	; get param from input 
	if (instr.list_group) {
		list_input_auto(instr.list_group, param, instr.list_type, list)

	; get param from parmm list
	} else {
		list_input_auto(input_type(), param, instr.name, list, "get_input_param")		
	}

	if (list) {
		if (InStr(list, "`n")) {
			instr_tips(param, , list)
			; only one line
		} else {
			instr_tips(param list)
		}
		;g_log("list auto param, get list")
		return 1

	} else {
		instr_tips(param)
		;g_log("list auto param, no list")
		return 0
	}
}

fetch_auto_param(Byref param, Byref char)
{
	instr := input_instr_entry()
	if (instr.list_group) {
		; select a list name
		select_input_auto(instr.list_group, param, char, entry, instr.list_type)
		input_curr().param := entry.name

	} else {
		select_input_auto(input_type(), param, char, entry, instr.name, "get_select_param")
		input_curr().param := entry
	}

	if (input_curr().param) {
		input_log("fetch auto name, get param [" input_curr().param "]")
		return 1

	} else {
		input_log("fetch auto name, but not select any, index [" char "]")
	}
	return 0
}

input_digit(Byref param, Byref char)
{
	if (SubStr(param, 1, 1) == opt("escape")) {
		return 0

	} else {
		return if_digit(char)	
	}
}

; we can use digit in input
actual_input(Byref param)
{
	if (param == -1) {
		param := input_curr("name")
	}
	if (SubStr(param, 1, 1) == opt("escape")) {
		return SubStr(param, 2)

	} else {
		return param
	}
}

; we can use digit in param
actual_param(Byref param)
{
	if (param == -1) {
		param := input_curr("param")
	}
	if (SubStr(param, 1, 1) == opt("escape")) {
		return SubStr(param, 2)

	} else {
		return param
	}
}
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
; when set instr, should use a assist key for tigger and be here
fetch_input_hotkey(Byref param)
{
	Suspend on

	time := system_time()
	while (1) {

		if (hotkey_pressed(list, show, last, change)) {
			if (list) {
				if ((master := hotkey_master(list))) {
					
					if (master == list) {
						instr_tips(show ", only master")
					; done
					} else {
						; use input to ignore input key, which will write to active window
						;ignore_input()
						break
					}
				} else {
					instr_tips(show ", only assist")
				}
				input_log("fetch input hotkey, only get master key [" show "]")

			} else {
				break
			}

		} else if (change) {
			instr_tips(show, 20000)
			change := 0
		}

		if (timeout(time, 5)) {
			app_log("fetch input hotkey, exceed wait limit")
			break
		}
	
		wait_input(stat, const("input", "every"), 1)
		;g_log("fetch input hotkey, stat " stat.type (stat.type == "end" ? ", end [" stat.term "]" : "") ", wait " (system_time() - time))
	}
	Suspend off

	if (list) {
		if (IsLabel(list)) {
			info("fetch input hotkey, list [" list "], show [" show "] is already a label", 3000)

		} else if (del_input_hotkey(array, list)) {
			info("fetch input hotkey, list [" list "], show [" show "] is already registed, for handle " get_handle(array[1], "proto") ", should del first", 3000)				

		} else {
			log("fetch input hotkey, get key list [" list "], show [" show "]")
			param := list
			instr_tips(show)
			return 1
		}
	}
	input_log("fetch input hotkey, get nothing")
	param := ""
	return 0
}

del_input_hotkey(Byref array, Byref list)
{
	if ((array := get_hotkey("common", list))) {

		if (InStr(input_instr_entry().name, "del")) {
			input_log("del input hotkey, try to remove key list [" list "]")
			return 0
		}
		return 1
	}
	return 0
}

;==============================================================================================
;==============================================================================================
list_input(Byref type)
{
input := input_type(type)
	for column, group in input
	{
		if (column == const("input", "auto")) {
			log("input group [" column "]:")
			for prefix, array in group
			{
				tab := "`t"
				for prior, list in array
				{
					tab := tab "   "
					;help := "p-" prior
					for dest, entry in list
					{
						log(tab " [" prefix "]   <" entry.name "> ")
					}
				}
			}
		} else if (column == const("input", "master") || column == const("input", "short")) {
			log("input group [" column "]:")
			for name, entry in group
			{
				log("`t [" name "]   <" entry.name ">")
			}
		}
	}
input_type(0)
}

;================================================================================
;================================================================================
input_test()
{

input_type("run")
	type := 5
	if (type <= 1) {
		; master conflict
		regist_input("set", "set working", "log", "set work")
		regist_input("set", "set empty", "log", "set work")
		; conflict with previous master prefix
		regist_input("setwork", "set working", "log", "set work")

		; master conflict with previous short regist
		regist_input("get | getwork", "get working", "log", "set work")
		regist_input("gettime", "get time", "log", "set work")
	}

	;opt("instr") = "#"
	if (type <= 2) {
		;master conflict with previous master auto
		regist_input("getwork", "get working", "log", "set work")
		regist_input("get", "get empty", "log", "set work")

		; master conflict with previous short auto
		regist_input("settime|set", "set empty", "log", "set work")
		regist_input("set", "set working", "log", "set work")	
		; with different prior
		regist_input("se", "se#2", "log", "set 3")
	}

	; auto with prior
	if (type <= 4) {
		regist_input("setwork", "set working-1#1", "log", "set 1")
		regist_input("settime", "set empty-9# 9", "log", "set 2")
		regist_input("setc | setcreate", "set create-2 # 2 ", "log", "set 3")
	}

	if (type <= 5) {
		regist_input("setwork", "set working-1#1", "log", "set 1")
		return
		regist_input("settime", "set empty-9# 1", "log", "set 2")
		regist_input("setc | setcreate", "set create-2 # 2 ", "log", "set 3")
			
		list_input("run")
		erase_input("run", "setwork")	
		;erase_input("run", "setcreate")
		erase_input("run", "setc")
		erase_input("run", "settime")
	}
	;regist_input_instr()
input_type(0)

	list_input("run")
}

