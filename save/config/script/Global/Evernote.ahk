
#include EverStyle.ahk

ever_log(Byref string)
{
	log("[evernote]: " string)
}
;==============================================================================================
;==============================================================================================
/*
	global_define_macro()
	set_note("book /note+tag")
	set_note("book/ note")
	set_note("book/ + tag")
	set_note("note +tag")
	set_note("+   tag")
	set_note(" note ")
	set_note("book /")
	set_note("book stadge1 /note stadge2+ tag stadge3")
*/
set_note(Byref type, Byref name, path, assist="")
{
	; should not conflict
	if ((array := dync_name(type, name, -2))) {
		warn("set note, type <" type "> but name [" name "] already registed in type [" array.dync_type "]")
		return 0

	} else if (!path) {
		if (fixkey_type(type, name) || name == "single") {
		} else {
			warn("set note, name [" name "], but path empty")
			return 0
		}
	}
	entry := dync_name(type, name, 1)

	set_option(assist, const("ever", "assist"))
	set_assist(entry, assist)
	; for later switch path
	set_switch(entry, , , "top_front_none_min")

	en_decode_note(entry, path)

	; single note will not regist this
	if (entry.path) {
		record_app("ever", entry)
	}

	if (assist(entry, "single") 
		|| assist(entry, "single_always"))
	{
		; make sure single exist, even only set single_always
		set_assist(entry, "single")
		
		entry.single := entry.clone()
		en_single_handle(entry, 0)
		en_single_handle(entry.single, 1)

		record_app("ever_si", entry.single)
	}
	set_handle(entry, "en_switch", glob_app("ever"), entry)
	
	ever_log("regist note [" entry.path "], flag [" assist "]")
	return entry
}

;========================================================================================
;========================================================================================
; [!r|rm]  +calendar(+single|single_hide)
; regist note list
note_list(Byref arg*)
{
	extend_handle_list("en_parse_handle", arg*)
}

; used in parse_handle
en_parse_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
	; not good here
	; if note path contain /, should set arround with [/]; but when parse handle, the last part will parsed as option
	;if (InStr(option, "/")) {
	;	handle := handle option
	;	option := ""
	;}
	; log(hotkey ", " option ", " handle ", " param[1])
	dync_name := dync_auto_name(hotkey)
	return set_note("note", dync_name, handle, param[1] option)
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
open_note(Byref name, Byref key, Byref path="", Byref assist="")
{
	if (set_note(name, path, assist)) {
		return regist_dync(type, name, key)

	} else {
		return 0
	}
}

dync_note(Byref type, Byref name, path, assist="")
{
	return set_note(type, name, path, assist)
}

;================================================================================
;================================================================================
; update single handle
en_single_handle(Byref run, Byref set)
{
;	if (run == glob_app("ever_si")) {
;		info("en_single_handle, run and obj match, failed")
;		ExitApp, 1
;	} 
	window_handle(run, "find", "find_class_title_handle")

	if (set) {
		set_enum(run, "ever", "single", 1)
		window_handle(run, "match", "en_single_match")

	} else {
		set_enum(run, "ever", "single", 0)
		window_handle(run, "match", "en_note_match")
	}
	;ever_log("set find handle " (set ? "single" : "normal"))
}

en_active_note(Byref type="note")
{
	winid := win_curr()

	if (type == "book") {
		book := en_book_name(winid)

	} else if (type == "tags") {
		tags := en_tags_name(winid)

	} else if (type == "note") {
		book := en_book_name(winid)
		note := en_note_name(winid)
		tags := en_tags_name(winid)
	}

	path := en_encode_note(book, note, tags)
	ever_log("en active note, current path [" path "]")
	return path
}

en_decode_note(Byref entry, Byref path)
{
	help := get_option(path, sep("help"), true)
	; if not set help, use path
	entry.help := help ? help : path

	entry.locate_always := get_option(path, sep("always"), true)

	while (1) {
		data := string_next(path, opt("book") opt("tags"), char, flag("allow_empty"))

		if (!data && !char) {
			;log("no data")
			break
		}
		;log(data ":" char)
		if (char == opt("book")) {
			; replace '/' with ';'
			entry.book := stringer(data)
			;log("book: " entry.book)

		} else if (char == opt("tags")) {
			entry.note := stringer(data) 
			entry.tags := trim(path)
			;log("note [" entry.note "] tag [" entry.tags "]")
			break

		} else {
			entry.note := stringer(data)
			;log("note [" entry.note "]")
		}
	}
	entry.book := en_decode(entry.book)
	entry.note := en_decode(entry.note)
	entry.tags := en_decode(entry.tags)

	if (assist(entry, "single") 
		|| assist(entry, "single_always"))
	{
		if (!entry.note) 
		{
			warn("en decode note, but ever single mode, must set note name, book [" entry.book "] tags [" entry.tags "]")
		}
	}

	entry.query := en_format_query(entry.book, entry.note, entry.tags)
	; use name as path, for later will check in fixkey_dynamic_type
	entry.path  := en_show_note(entry.book, entry.note, entry.tags)
}

en_encode_note(Byref book, Byref note, Byref tags)
{
	return en_show_note(en_encode(book), en_encode(note), en_encode(tags))
}

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
en_show_note(Byref book, Byref note, Byref tag)
{
	return exist_suffix(book, opt("book")) note exist_prefix(tag, opt("tags"))
}

en_encode_test()
{
	ss := "[111/32+23]"
	log(en_encode(ss))
	log(en_decode(ss))
}

en_decode(Byref note)
{
	; erase opt("left") opt("righ")
	;	note := RegExReplace(note, "[\" opt("left") "\" opt("righ") "]")
	note := regex_replace(note, opt("left") opt("righ"))
	return note
}

en_encode(Byref note)
{
	;	note := RegExReplace(note, opt("book"), 	opt("left") opt("book") opt("righ"))
	;	note := RegExReplace(note, "\" opt("tags"), opt("left") opt("tags") opt("righ"))
	
	;	note := regex_replace(note, opt("book"), opt("left") opt("book") opt("righ"))
	;	note := regex_replace(note, opt("tags"), opt("left") opt("tags") opt("righ"))

	note := regex_replace(note, opt("book") opt("tags"), opt("left") "$0" opt("righ"))
	return note
}

en_wrap(Byref note)
{
	if (InStr(note, " ")) {
		return "\""" note "\"""

	} else {
		return note
	}
}

en_format_query(Byref book="", Byref note="", Byref tags="")
{
	if (book) {
		doc := exist_suffix(doc, " ") "notebook:" en_wrap(book)
	}
	
	if (note) {
		list := note
		while ((data := string_next(list, opt("next")))) {
			doc := exist_suffix(doc, " ") "intitle:" en_wrap(data)
		}
	}

	if (word) {
		doc := exist_suffix(doc, " ") "any:" en_wrap(word)
	}

	if (tags) {
		list := tags
		while ((data := string_next(list, opt("next")))) {
			doc := exist_suffix(doc, " ") "tag:" en_wrap(data)
		}
	}

	return """" doc """"
}

en_note_match(Byref winid, Byref run)
{
/*
	class := win_class(winid)
	if (class != glob_app("ever").class 
		&& class != glob_app("ever_si").class)
	{
		ever_log("current class not match, try again")
		return 0
	}
*/
  	if (run.note && !(en_note_name(winid) = run.note)) {
  		ever_log("note not match, " en_note_name(winid) " != " run.note)
    	return 0
	}

	if (run.book && !(en_book_name(winid) = run.book) ) {
		ever_log("book not match, " en_book_name(winid) " != " run.book)
		return 0
	}
	if (run.tags && !InStr(en_tags_name(winid), run.tags)) {
		ever_log("tag not match, " en_tags_name(winid) " != " run.tags) 
		return 0
	}
	ever_log("get match note [" run.path "]")
	return 1
}

; single note match
en_single_match(winid, Byref run)
{
	if (run.note && !(evsi_note_name(winid) = run.note)) {
		ever_log("single not match, " evsi_note_name(winid) " != " run.note)
    	return 0
	}
/*
 	if (run.tags && !InStr(evsi_tags_name(winid), run.tags)) {
		ever_log("single tag not match, " evsi_tags_name(winid) " != " run.tags) 
		return 0
	}
*/
	return 1
}

;=============================================================================
;=============================================================================
en_note_name(Byref winid, type=1, line=3)
{
	full := win_text(winid)
	
	if (type == 0) {
		line := line == 0 ? 2 : line
		text := stri_spec_line(full, line)

	} else if (type == 1) {
		line := line == 0 ? -1 : line
		text := stri_spec_line(full, line)

	} else if (type == 2) {
		text := stri_next_line(full, app_gbk("ever", "sep_note"))
	}
	return text
}

en_tags_name(Byref winid)
{
	return stri_next_line(win_text(winid), app_gbk("ever", "sep_tags"), opt("next"))
}

en_book_name(Byref winid)
{
	text := win_title(winid)
 	
 	if ((pos := InStr(text, " -"))) {
 		book := substr(text, 1, pos - 1)
 	}
 	return book
}

evsi_note_name(Byref winid)
{
	return en_book_name(winid)
}

en_validate_ever(winid=0)
{
	default(winid, win_curr())
	log("==================================== text:")
	log(win_text(winid))
	
	log("==================================== title:")
	log(win_title(winid))

	log("")
	log("try note name: ")
		log("`t type 0 " en_note_name(winid, 0))
		log("`t type 1 " en_note_name(winid, 1))
		log("`t type 2 " en_note_name(winid, 2))
		log("`t type 3 " en_note_name(winid, 0, 3))

	log("note tags name: " en_tags_name(winid))
	log("note book name: " en_book_name(winid))
}

en_validate_evsi(winid=0)
{
	default(winid, win_curr())
	log("==== text: `n" win_text(winid))
	log("==== title: `n" win_title(winid))

	log("evsi note name: " evsi_note_name(winid))
}

en_execute_query(Byref run)
{
	if (init(script, "ever", "query")) {
		script.string := glob_app("ever").script " ShowNotes /q "
	}

/*
	; set book and note, not work well, when locate to note, will hide the notebook view again
	if (run.book && run.note) {
		book := en_book_name(winid)
		if ((book != run.book)) {
			query := "notebook:" en_wrap(run.book)
			ever_log("`t current notebook [" book "], relocate to [" run.book "]")
			RunWait % script.string query, , hide
		}
	}
*/
	query := script.string run.query
	RunWait %query%, , hide

	tips("condition " query, 100)
	ever_log("`t query string: [" query "]")
}

;=============================================================================
;=============================================================================
en_switch(Byref obj, Byref run)
{	
	if (assist(run, "single")) {
		; single note switch, and single note already exist
		if (en_single_note(obj, run)) {
			return 1
		}
	}

	; locate to the note
	if (en_locate_note(obj, run)) {
		return en_single_always(run)
	}
	return 0	
}

en_single_note(Byref obj, Byref run)
{	
	; 1) single match note already exist, attach or not
	; 2) main window exist, match or not
	; 3) main window exist, match or not, and set always single

	;en_single_handle(run, 1)
	; matched single note exist
	if ((winid := switch_window(glob_app("ever_si"), run.single))) {
		ever_log("single note, already exist, switch single success")
		return 1
	}
	ever_log("en single note, single note not exist, try main note")

	if (assist(run, "single_always")) {
		if (run.single.note) {
			ever_log("single note, need always be single, try later")	
		} else {
			warn("single note, need always be single, but not set note name, maybe can't locate single")			
		}
	
	; matched main window exist, can't parse run here, run contain note_match_handle
	} else if ((winid := switch_app("ever", "mode_show"))) {

		if (en_note_match(winid, run)) {
			; set winid as current main window id, fot laster focus ctrl use
			run.winid := default(run.winid, winid)
			; do assist work keeped in run
			en_active_handle(glob_app("ever"), run)
			ever_log("main already exist, switch window success")
			return 1	

		} else {
			ever_log("main current note not match")
		}
	}
	return 0
}

en_single_always(Byref run)
{
	; need force single
	if (assist(run, "single_always")
		&& win_class(run.winid) == glob_app("ever").class) 
	{
		ever_log("current window is main, need front single note") 
		return en_single_front(run)
	}
	return 1
}

en_locate_note(Byref obj, Byref run)
{
	; check if current note is already, in case re-run
    if (!run.locate_always && en_note_match(win_curr(), run)) {
        ever_log("en_note_match, no need locate again, just show")

        switch_app("ever", "mode_show")
        run.winid := win_curr()
        return 1
    }
    en_execute_query(run)

	return en_wait_active(obj, run)
}

en_wait_active(Byref obj, Byref run)
{
	; get active en main frame
	; 	should not use run to find winid, run maybe include single note info
	if (!(winid := app_winid("ever"))) {
		info("can't get winid", 1000)
		return 0
	}
	ever_log("wait to be actived")

	count = 0
	while (++count <= 10) {
		if (en_note_match(winid, run)) {
			find := true
			break
		}
		sleep 200
	}
	if (!find) {
		info("wait locate note timeout", 1000)
		return 0
	}
	
	run.winid := winid
	; must use run param, it contain single info, for later active handle
	switch_app("ever", "mode_show", , run)
	return 1
}

; maybe focus ctrl will excute twice
;	1) regist focus_ctrl on the object 
;	2) do focus_ctrl in en_locate_ctrl
en_active_handle(Byref obj, Byref run)
{
	ever_log("do active handle")
	if (enum(run, "ever", "single")) {
		if (assist(run, "single_max")) {

			win_max(run.winid)
			ever_log("active handle: single maximize")
		}
	} else {
		if (assist(run, "max")) {
			win_max(run.winid)
			ever_log("active handle: maximize")
		}
	}

	if (assist(run, "focus_ctrl")) {
		if (!en_locate_ctrl(obj, run)) {
			return 0
		}
		ever_log("active handle: focus")
	}

	if (assist(run, "goto_end")) {
		if (!en_goto_end(obj, run)) {
			return 0
		}
		ever_log("active handle: goto end")
	}
	return 1
}

en_deactive_handle(Byref obj, Byref run)
{
	ever_log("do deactive handle")
	if (assist(run, "single_hide")) {
		win_hide(run.winid)
		ever_log("deactive handle: hide")
	}
	return 1
}

en_locate_ctrl(Byref obj, Byref run) 
{
    ever_log("try to focus on [" obj.name "]")

    ; fix, new add action, get curretn state before focus
    if (obj.winid && win_ctrl(obj.winid) != obj["ctrl"]) {
    	click := true
    }

	if (!ctrl_focus_handle(obj, run, , "done_check")) {
		ever_log("en active: " if_active(run.winid))
		return 0
	}

	; fix, new add action
	if (click) {
		if (!do_click_ctrl(obj.winid, obj["ctrl"], true)) {
			ever_log("en active, but click ctrl failed")
			return 0
		}
	} else {
		ever_log("en active, no need click")
	}

	en_click_edit(obj.name, obj.ctrl, run.winid)
    return 1
}

en_goto_end(Byref obj, Byref run)
{
	name := enum(run, "ever", "single") ? "ever_si" : "ever"
    entry := glob_app(name)

    do_send_ctrl(run.winid, entry.ctrl, "{ctrl down}{end}{ctrl up}")
    
    ; make sure locate to end
    en_focus_end(run.winid)
    return 1
}

en_focus_end(winid, wait=0)
{
	if (wait) {
		sleep %wait%
	}
	
	if (win_curr() == winid) {
		ever_log("en focus end")

		sendinput {up} 
		sendinput ^{end}
	} else {
		ever_log("current not evernote, class [" win_class() "], ignore focus end")
	}
    ;send {ctrl down}{end}{ctrl up}
}

/*
en_focus_test()
{
	winid := win_winid("evsingleNoteView")
	win_active(winid)

	focus_app("ever_si", "ctrl", , winid)
	;click_app_ctrl("ever_si", "ctrl", winid)
	;send_app_ctrl("ever_si", "{ctrl down}{end}{ctrl up}", "ctrl", winid)
	send_app_ctrl("ever_si", "^{end}", "ctrl", winid)
}
*/

en_click_edit(Byref name, Byref ctrl, Byref winid)
{
	mode := 0
	if (mode == 0) {
		if (once(name winid, "ctrl_init")) {

			ctrl_pos(x, y, w, h, ctrl, winid)
			en_pass_link(x, y)

			mouse_click(x, y, true)
			ever_log("do mouse init for [" name "], ctrl [" ctrl "], winid " winid) 
		}
	} else {
		; should click for the first time
	    if (!enum(run, name, "ctrl_init")) {

	        set_enum(run, "ever", "ctrl_init", winid)
	        do_click_ctrl(winid, ctrl)
	        ever_log("do ctrl init for [" name "], ctrl [" ctrl "], winid " winid)
	    }
	}
}

; makre sure not click any link
en_pass_link(Byref x, Byref y)
{
	x := x + 20
	y := y + 20

	o_x := x
	o_y := y

	step := 10
	count := 0

	while (++count < 30) {
		mouse_move(x, y)
		sleep 10
			
		if (mouse_type()) {
			y := y + step
				
		} else {
			break
		}
	}
	ever_log("en pass link, move mouse along y by [" y - o_y "], move count [" count "]")
}
;=============================================================================
;=============================================================================
en_single_active()
{
	ever_log("active single, try to focus on list")
	; focus on list window
	send, {esc}
	sleep 100

	; focus on list ctrl
	if (!focus_app("ever", "ctrl_list")) {
		return 0
	}		

	send, ^{enter}
	return true
}

en_single_front(Byref run="", keep_main=false)
{	
	if (run) {
		if (win_class(run.winid) != glob_app("ever").class) {
			info("current not evernote, cancel front single", 3000)
			return 0
		}
		winid  := run.winid
		single := run.single

	} else {
		single := {}
		winid := win_curr()
		single.note := en_note_name(winid)

		en_single_handle(single, 1)
		set_assist(single, const("ever", "assist"))
	}
	
	if (!en_single_active()) {
		return false
	}

	if (!keep_main) {	
		switch_app("ever", "mode_hide")
		ever_log("hide main window done")
	}	

	count := 0
	while (count++ < 10) {
		
		ever_log("front single, try [" count "]")
		if ((winid := app_winid("ever_si", single))) {
			move_window_area("origin", true, winid)	
			top_window(winid, 1)

			en_active_handle(glob_app("ever_si"), single)
			return true
		} 
		sleep 50
	}

	info("no single note " run.single.note, 3000)
	return fasle
}

;=============================================================================
;=============================================================================
en_chrome_url()
{
	if (!chrome_link(text, link)) {
		return 
	}

	run := get_note_entry("chrome")

	if (!en_locate_note(glob_app("ever"), run)) {
	    tips("show note failed", 1000, true)
	    return false
	}

	clipboard := ". " text "`r`n" link
	send ^v
    ;sleep 100
    send { enter 2 }
	
	ever_log("pasete with [" clipboard "]")
	en_focus_end(run.winid)
}

en_chrome_link(linked=false, switch=false)
{
    if (!chrome_link(text, link)) {
    	return
    }
    tips(text)

	if (linked) {
		clipboard := text_link(text, link)

	} else {
	    clipboard := ". " text "`r`n" link
    }

    if (switch) {
        switch_app("ever", "mode_show")
    }

    ; record chrome link copy style, used in en_html_paste
    switch("chrome_link", linked)
}

select_note(Byref type, Byref path, Byref error="")
{
	if (if_app_actived("ever")) {

		if ((path := en_active_note(type))) {
			ever_log("select note, current note [" path "]")
			return 1
		}
		error := "nothing selected"

	} else {
		error := "current not " type
	}
	ever_log("select note, " error)
	return 0
}

;==============================================================================================
;==============================================================================================

get_note_entry(Byref name)
{
	if (init(array, "ever_note", name)) {
		if (name == "single") {
			entry := set_note("note", name, "")
			record_app("ever_si", entry)

			; do work like en_single_handle, but match handle should change		
			set_enum(entry, "ever", "single", 1)
			; default match handle still work 
			window_handle(entry, "find", "find_class_title_handle")
			;en_single_auto_match
			ever_log("create single note auto")

		} else if (name == "chrome") {
			entry := set_note("note", "chrome", app_gbk("ever", "record") "/+read")
			ever_log("create chrome note")
		}

		; change single note mode, clear default mode first
		set_assist(entry, const("ever", "assist"), 0)
		set_assist(entry, const("ever_si", "assist"))
		; g_log("single note: check goto_end <" assist(entry, "goto_end") ">")\

		array.entry := entry
	}
	return array.entry
}

/*
en_single_auto_match(winid, Byref run)
{	
	if (run.title) {
		return match_text_handle(winid, run)
	} else {
		return true
	}
}
*/
switch_single_auto()
{	
	run := get_note_entry("single")

	old_winid := run.winid
	if ((winid := switch_window(glob_app("ever_si"), run))) {
		; just do a mode switch
		;if (run.winid == winid) {
		;	ever_log("switch single auto, winid match, just switch")
		;	return
		;}
		if (old_winid != run.winid) {
			run.title := win_title(run.winid)
			if (run.title) {
				ever_log("switch single auto, change title [" run.title "]")
				tips("switch to " run.title, 100)
			}
		}
		
	} else {
		if (run.title) {
			run.title := ""
			ever_log("switch single auto, clear title and try again")

			switch_single_auto()	
		} else {
			tips("no single note")
		}
	}
}

change_single_auto()
{
	if (if_app_actived("ever_si")) {
		run := get_note_entry("single")

		title := win_title()
		winid := win_curr()

		if (winid == run.winid && title == run.title) {
			tips("same single")
		} else {
			run.winid := winid 
			run.title := title
			tips("change note [" title "]")
		}

	} else {
		tips("not single note")
	}
}

en_single_assist_handle(Byref obj, Byref run, Byref winid)
{
	if (obj.class == app_class("ever_si")) {
		change_single_auto()
		ever_log("en single assist, change current instance")
	}
}

;==============================================================================================
;==============================================================================================
en_batch_date(Byref list="")
{
	;switch_app("ever", "mode_show")
	default(list, "0@@Inbox")

	sep := "`n`t"
	while ((book := string_next(list, opt("next")))) {
		default(array)[book] := 1
		string := exist_suffix(string, sep) "[" book "]"
	}
	
	name := en_book_name(app_winid("ever"))
	if (!array[name]) {
		log("batch batch date, but current note is " name)
		tips("book must be one of: " sep string, 3000)
		return 0
	} 

	; first time do more try
	en_focus_list(true, 200)
	en_focus_list(true, 200)

	count := 0
	total := 50
	
	check := 0
	valid := 1

	retry := 0
	while (--total >= 0) {

		; lcoate to  note list
		if (!en_locate_next(title, retry)) {
			break
		}

		ret := en_title_date(false, title, array)
		if (ret == 0) {
			return 0

		} else if (ret == -1) {
			if (++check >= valid) {
				break
			}
			ever_log("en batch date, complete, check cout [" check "]")

		} else {
			count++	
			check := 0
		}
	}
	if (total <= 0) {
		log("en batch date, no ticket, complete count [" count "], retry [" retry "]")
	} else {
		tips("succ [" count "]", 2000)
		log("en batch date, complete count [" count "], retry [" retry "]")
	}
	
}

en_focus_list(raw_end=false, wait=0)
{
	count := 0
	total := 10
	while (count < total) {
		if (focus_app("ever", "ctrl_list", "done_check|none_click")) {
			if (send_app_ctrl("ever", "{end}", "ctrl_list")) {

				if (wait) {
					sleep %wait%
				}

				if (raw_end) {
					send_raw("{end}")
					send_app_ctrl("ever", "{end}", "ctrl_list")
				}
				break
			}
		} 
		count++
		sleep 100
	}
	
	if (count >= 0) {
		if (count == 0) {
			ever_log("en locate list, succ")

		} else if (count < total) {
			ever_log("en locate list, try count [" count "]")

		} else {
			info("en locate list, but focus ctrl list failed", 3000)
			return 0
		}
	}
	return 1
}

en_locate_next(Byref title="", Byref retry=0)
{
	total := 20
	count := 0
	while (++count < total) {

		; focus to note list ctrl
		if (!en_focus_list(true, 100)) {
			return 0
		}
		note_title := en_note_name(app_winid("ever"))

		if (title && InStr(note_title, title)) {

			; title note change, maybe occur two note with same name
			if (note_title == title) {
				log("en locate next, check note, still same [" count "], curr [" win_ctrl() "], note [" title "], maybe two note with same name")
				retry++
				return 1

			; already set name success, current not contain date, maybe set success, but note list not change yet
			} else {
				log("en locate next, note add date, but wait change to next one, check [" note_title "], title " title)
				sleep 200
			}
		} else {
			ever_log("en locate next, title already change, move to next note, check [" note_title "], title " title)
			ever_log("")
			return 1
		}
	}
	
	log("en locate next, but failed [" count "]")
	return 0
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; focus on title and copy
en_copy_title()
{
	; if current ctrl is notebook, should change to ctrl list
	if (InStr(win_ctrl(), "ENNavPaneCtrl")) {
		focus_app("ever", "ctrl_list")
		sleep 100
	}

	count := 0
	while (++count <= 10) {

		sendinput {F2}

		mode := 0
		if (mode == 1) {
			; check if ctrl is focus	
			if (!focus_app("ever", "ctrl_file", "only_check")) {
				info("en copy title, but focus ctrl failed", 3000)
				return 0
			}
		}
		reset_clip(ret)

		if (get_clip(0.1, 20)) {
			if (count > 1) {
				ever_log("en copy data, tried [" count "]")
			}
			break
		}
		sleep 100
	}

	return SubStr(Clipboard, 1)
}

en_paste_title(Byref title, Byref enter=false)
{
	if ((pos := RegexMatch(title, "[`r`n]"))) {
		title := Substr(title, 1, pos)
	} else {
		title := Substr(title, 1)
	}
	focus_app("ever", "ctrl_file")

	mode := 0
	if (mode == 0) {

		reset_clip(count)
		paste(title, 5)
		
		if (enter) {
			sleep 100
			sendinput {enter}
		}
		ever_log("en paste title, name [" title "], reset clip count [" count "]")

	; copy data to title head
	} else {
		sendinput {Home}
		;send {Home}
		copy_date(enter)
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
en_title_date(Byref enter=false, Byref title="", Byref array="")
{
	if ((current := en_copy_title())) {

		; title already prefix with data format, xxxx-xx-xx
		if (RegExMatch(current, "([0-9]{4}-[0-9]{2}-[0-9]{2})")) {
			ever_log("en title data, title already contain date, [" current "]")
			; cancel select state
			send {right}
			return -1

		} else {
			title := current
			ever_log("en title data, get title [" title "]")
		}

	} else {
		info("en title data, but copy title failed", 10000)
		return 0
	}

	if (array) {
		name := en_book_name(app_winid("ever"))
		if (!array[name]) {
			info("WARN: book changed to [" name "]", 3000)
			ever_log("en title data, current book change to [" name "], exit")
			return 0
		}
	}

	en_paste_title(date() " " title, enter)
	return 1
}

en_select_data()
{
	if (get_clip(0.2, "line")) {
		title := Substr(Clipboard, 1)
		
		get_date := false
		; remove date info
		if (RegExMatch(title, "([0-9]{4}-[0-9]{2}-[0-9]{2})", out)) {
			get_date := true
		}
		sleep 100

		if ((current := en_copy_title())) {

			; title already prefix with data format, xxxx-xx-xx
			if (RegExMatch(current, "([0-9]{4}-[0-9]{2}-[0-9]{2})", out)) {
				if (get_date) {
					ever_log("en select data, title already contain date, leave title [" title "]")

				} else {
					title := out1 " " title
					ever_log("en select data, title already contain date, distill it to title [" title "]")
				}
			} else {
				if (get_date) {
				} else {
					title := date() " " title
				}
				ever_log("en select data, get title [" title "]")
			}

		} else {
			info("en select data, but copy title failed", 10000)
			return 0
		}

		if (title == current) {
			ever_log("en select data, title match, no need change")

		} else {
			; sendinput {F2}
			en_paste_title(title, false)
		}
	}
}

;==============================================================================================
;==============================================================================================
copy_note_path(Byref type)
{
	if (if_app_actived("ever")) {
		path := en_active_note(type)
		Clipboard := path
		tips("copy active: [" path "]", 3000, true)
	} else {
		tips("ever not active")
	}
}

;==============================================================================================
;==============================================================================================
regist_evernote()
{
	; when update window assist, check if need update single note instance
	update_global_handle(1, "global", "assist", "en_single_assist_handle")

input_type("ever")

	regist_en_normal()

	regist_en_inner()

	;regist_si_exist()
input_type(0)
}

; single note, show??hide normal type, shoud
regist_en_normal()
{
hotkey_prefix("note", "common")
	; inbox note book; sep("default") use ++
	; 1) main max; single, single hide;  advnace "+max|single_always|single_hide"
	; 2) Nifi/0@Nifi-Install() cancel("goto_end"), if only set default option and cancel part, will also work
	note_list("[i | inbox]		0@@Inbox/"
			, "[t | todo]		1@Todo/Todo+Todo(" sep("default") "max|single|single_hide)"
			, "[n | nfile]		@" app_gbk("ever", "note") "/Note+Note(++single|single_hide)" cancel("goto_end")
			, "[>!n | nbook]	@" app_gbk("ever", "note") "/")

hotkey_prefix("note", "gtd")
	;open_note("", "e", "+everyday")
	note_list("[t | gtd_next]	+next"
		, "[c | gtd_calendar]	+calendar"
		, "[d | daily]			+daily" sep("always")
		, "[i | gtd_project]	1@" app_gbk("ever", "project") "/"
		, "[f | gtd_future]		3@" app_gbk("ever", "future") "/"

		; locate to the first notebook in 1@Project
		, "[p | project]		0 Design/")	

	note_list("[r]				7@" app_gbk("ever", "record") "/" sep("always")	; set locate always
			, "[record]			7@" app_gbk("ever", "record") "/0@Record"
			, "[learning]		7@" app_gbk("ever", "record") "/1@Learning"
			, "[accessing]		7@" app_gbk("ever", "record") "/2@Accessing"
			, "[continue]		7@" app_gbk("ever", "record") "/3@Continue"
			, "[u | unread]		7@" app_gbk("ever", "record") "/4@ReadList")
hotkey_prefix(0)

	note_list("[read]		   	" app_gbk("ever", "record") "/read"
			, "[config] 		0@" app_gbk("ever", "config") "/")
}

regist_en_inner()
{	
	app_active("ever", 	  		"[ever_name]	en_validate_ever")
	app_active("ever_si", 		"[evsi_name]	en_validate_evsi")

	;-------------------------------------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------------------------------------
	app_active("ever"
					, "[F12]  	en_single_front(, false)"
					, "[^F12] 	en_single_front(, true)"
					, "[<^d]	en_title_date(true)"
					, "[<^F1]	en_select_data"
					, "[^!b]	en_batch_date(0@@Inbox" opt("next") app_gbk("ever", "weixin") opt("next") "00test)")

	app_active("ever_si"
					, "[F12] 	top_window"
					, "[^+x] 	change_single_auto")

	app_active("ever|ever_si"
					, "[<!v | <!b]	en_html_paste"
					, "[<#x]	cut_line(false)"
					, "[<^!x]	cut_line(false, true)"
					; sometime ctrl-shift-v not work well
					, "[<^<!v]	paste_plain")

app_active_cond("ever")
	regist_en_style()
app_active_cond("ever_si")
	regist_en_style()
app_active_cond()
}

