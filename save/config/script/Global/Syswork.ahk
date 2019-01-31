
;==============================================================================
;==============================================================================
select_type(Byref type, Byref path, Byref notify=true)
{
	if (type == "dir" || type =="file") {
		if (select_path(type, path, error)) {
			return 1
		}

	} else if (type == "book" || type == "note" || type == "tags") {
		if (select_note(type, path, error)) {
			return 1
		}

	} else if (type == "link") {
		if (select_url(type, path, error)) {
			return 1
		}

	} else {
		cond_tips(notify, "no match type [" type "]")
		return 0
	}
	cond_tips(notify, error)
	return 0
}

auto_dync_type(Byref type)
{
	if (dir_active(winid)) {
		type := "file | dir"

	} else if (if_app_actived("ever")) {
		type := "note"

	} else if (if_app_actived("chrome")) {
		type := "link"

	} else {
		info("no type match", 1000)
		return 0
	}
	return type
}

;=============================================================================================================
;=============================================================================================================
relocate_dir_item(Byref winid, Byref name)
{
	if (do_click_ctrl(winid, app_ctrl("dir"))) {
		if (try_select_file(winid, name, 10)) {
			return true
		}
	}
	return false
}

get_dir_path(Byref path="", Byref winid=0)
{	
	path := Explorer_GetPath(winid)
	if (path == "ERROR") {
		return 0

	} else {
		return path
	}
}

get_file_path(Byref path="", Byref winid=0)
{
	path := Explorer_GetSelected(winid)
	if (path == "ERROR") {
		return 0

	} else {
		return path
	}
}

try_select_file(winid=0, Byref name="", count=1)
{
	while (--count > 0) {
		sendinput {Esc}
		sendinput %name% 
		
		if (get_file_path(path)) {
			if (file_name(path) == name) {
				return true

			} else {
				app_log("try_select_file, try " count)
				sleep 100
			}
		}
	}
	tips("can't select file")
	return false
}

;------------------------------------------------------------------
;------------------------------------------------------------------
get_dir_path2(winid)
{
	; get current active directory
	if (!if_app_actived("dir", winid)) {
		info("current not dir", 1000)
		return ""
	}
	text := win_text(winid)
	pos1 := InStr(text, ": ") + 2
	pos2 := Instr(text, "`r", , pos1)
	if (pos1 == 0 || pos2 == 0) {
		info("can't get dir path")
		return ""
	}
	return SubStr(text, pos1, pos2 - pos1)
}

get_file_path2()
{	
	if (!if_app_actived("dir", winid)) {
		info("current is not dir")
		return 
	
	} else if (win_ctrl(winid) != app_ctrl("dir")) {
		
		if (mouse_win_ctrl() == app_ctrl("dir")) {
			MouseClick, left
		}
		
		if (win_ctrl(winid) != app_ctrl("dir")) {
			info("not focus on file")
			return 
		}
	}
	
	sendinput {F2}
	sendinput +{end}
	
	get_clip()
	if (!clipboard) {
		info("can't get file name")
		return ""
	}
	
	sendinput {Esc}
;	path := get_dir_path2(winid) "\" clipboard
	return path
}

try_select_file2(Byref name)
{
	count := 0
	
try_select_retry2:	
	;sendinput {Esc} 
 	sendinput %name% 
 	sendinput {F2}
 	
	get_clip()
	
	if (clipboard != name) {
		sendinput {Esc 3}
		 
		if (count++ > 10)
			return false
			
		;tips("locate again", 300)
		sleep 300
		goto try_select_retry2
	}
	return true
}

;===========================================================================
;===========================================================================
mouse_action(Byref action, Byref arg*)
{
	if (once("mouse", "action")) {
		config("mouse", "x_min", 0)
		config("mouse", "y_min", 0)
	}

	; note: when set critical, timer will not work
	Critical
	batch_lines(1)
	mouse_delay(1)

	if (action == "drag") {
		mouse_drag(arg*)

	} else if (action == "step") {
		mouse_step(arg*)

	} else if (action == "dest") {
		mouse_dest(arg*)

	} else {
		warn("mouse action, no action [" action "]")
	}

	batch_lines(0)
	mouse_delay(0)
	Critical off
}

;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
mouse_action_area(Byref ctrl, Byref range, Byref test=false)
{
	winid := win_curr()
	ctrl_pos(x, y, w, h, ctrl)

	default(range)
	range.xmin := x
	range.ymin := y

	range.xmax := x + w 
	range.ymax := y + h

 	if (test) {
		mouse_move(x, y)
		info(x "," y, 1000)

		mouse_move(x + w, y)
		info(x + w "," y, 1000)

		mouse_move(x + w, y + h)
		info(x + w "," y + h, 1000)

		mouse_move(x, y + h)
		info(x "," y + h, 1000)
	}
	sys_log("mouse action area, ctrl " ctrl " x: [" range.xmin "," range.xmax "], y: [" range.ymin "-" range.ymax "]")
}

mouse_exceed_area(Byref sx, Byref cx, Byref range)
{
	bound := 30

	if (cx <= range.xmin || cx >= range.xmax) {
		sx := (cx <= range.xmin) ? (range.xmin + bound) : (range.xmax - bound)

		sys_log("mouse exceed area, curr xpos [" cx "], reset to [" sx "]")
		return 1

	} else {
		return 0
	}
}

;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
mouse_straight(Byref timer, Byref sx=0, Byref sy=0)
{
	if (sx) {
		config("mouse_drag", "sx", sx)
		config("mouse_drag", "sy", sy)

		if (timer) {
			mouse_straight_timer(1)
		} else {
			mouse_straight_handle(1)
		}

	} else {
		if (timer) {
			mouse_straight_timer(0)		
		} else {
			mouse_straight_handle(0)
		}
	}
}

;------------------------------------------------------------------------------------------
mouse_straight_timer(Byref set)
{
	config("mouse_drag", "timer_work", set)
	if (set) {
		SetTimer mouse_check_timer,   1
		SetTimer mouse_check_timer_1, 2
		;SetTimer mouse_check_timer_2, 3
		;SetTimer mouse_check_timer_3, 1
		;SetTimer mouse_check_timer_4, 1
		;SetTimer mouse_check_timer_5, 1

	} else {
		SetTimer mouse_check_timer,   off
		SetTimer mouse_check_timer_1, off
		;SetTimer mouse_check_timer_2, off
		;SetTimer mouse_check_timer_3, off
		;SetTimer mouse_check_timer_4, off
		;SetTimer mouse_check_timer_5, off
	}
	return

mouse_check_timer:
mouse_check_timer_1:
mouse_check_timer_2:
mouse_check_timer_3:
mouse_check_timer_4:
mouse_check_timer_5:
	sx := config("mouse_drag", "sx")
	sy := config("mouse_drag", "sy")
	ymin := config("mouse", "y_min")

	count := 100
	while (--count > 0) {
		; stop right now
		if (!config("mouse_drag", "timer_work")) {
			break
		}
		mouse_pos(cx, cy)

		mouse_fixing(cx, sy, cy, ymin)
	}
	return
}

;------------------------------------------------------------------------------------------
mouse_straight_handle(Byref set)
{
	if (set == 1) {
		mouse_hook_worker("mouse_move_call")

	} else if (set == 0) {
		;mouse_hook_worker("mouse_move_call", "null")
		; remove handle, close system regist
		mouse_hook_worker("mouse_move_call", "null", "close")
	}
}

mouse_move_call(Byref lParam)
{
	sy := config("mouse_drag", "sy")

	dx := NumGet(lParam+0, "Short")
	dy := NumGet(lParam+4, "Short")

	; if (Abs(dy - sy) >= config("mouse", "y_min")) {
	if (Abs(dy - sy) >= 0) {
		mouse_move(dx, sy)
	}
}

mouse_fixing(Byref sx, Byref sy, Byref cy, Byref ymin)
{
	if (abs(cy - sy) > ymin) {

		if (ymin == 0) {
			mouse_move(sx, sy)

		; allow some ajust
		} else {
			if (cy > sy) {
				mouse_move(sx, sy + ymin)

			} else {
				mouse_move(sx, sy - ymin)
			}
		}
	}
}

;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
mouse_drag(Byref handle, Byref timer=0)
{
	if (!(ctrl := handle.())) {
		return false
	}

	if (InStr(A_ThisHotkey, "LButton")) {
		draw_key := "LButton"
	} else {
		split_assist_master(A_ThisHotkey, stop_list, draw_key)
	}

	mouse_action_area(ctrl, range)
	mouse_pos(sx, sy)

	if (mouse_exceed_area(sx, sx, range)) {
		return 0

	} else {
		click_pos(sx, sy, "down")
	}


	xmin := config("mouse", "x_min")
	ymin := config("mouse", "y_min")

	mouse_straight(timer, sx, sy)

	while (GetKeyState(draw_key, "P")) {
		mouse_pos(cx, cy)

		; remove timer mode, set to handle mode
		if (timer && GetKeyState("RButton", "P")) {
			mouse_straight(timer)
			timer := false
			mouse_straight(timer, sx, sy)
		}

		if (mouse_exceed_area(sx, cx, range)) {
			break
		}

		if (cx > sx + xmin || cx < sx - xmin) {
			;click_pos(sx, sy)
		}

		if (cy != sy) {
			mouse_fixing(cx, sy, cy, ymin)
		}

		sx := cx
		;sleep -1
	}
	click_pos(sx, sy, "up")

	mouse_straight(timer)
}

mouse_step(Byref handle, Byref stop_list="", Byref draw_key="")
{
	if (!(ctrl := handle.())) {
		return false
	}
	; not set stop key
	if (!stop_list) {
		; use for fast parse
		if ((stop_list := config("mouse_stop", A_ThisHotkey))) {
			draw_key := config("mouse_draw", A_ThisHotkey)

		} else {
			split_assist_master(A_ThisHotkey, stop_list, draw_key)
			config("mouse_stop", A_ThisHotkey, stop_list)
			config("mouse_draw", A_ThisHotkey, draw_key)
		}
	}

	mouse_action_area(ctrl, range)
	mouse_pos(sx, sy)

	if (mouse_exceed_area(sx, sx, range)) {
		return 0

	} else {
		click_pos(sx, sy, "down")
	}

	smin := 10
	smax := 15
	step := 2

	while (if_list_dw(stop_list)) {
		sleep 1
		
		move := false
		if (draw_key) {
			if (GetKeyState(draw_key, "P")) {
				move := true
			} else {
				; reset speed
				step := smin
			}
		} else {
			move := true
		}

		if (move) {
			if (step < smax) {
				step += 10
			} else {
				step := smax
			}
			
			if (mouse_exceed_area(sx, sx + step, range)) {
				break

			} else {
				sx += step
				click_pos(sx, sy)

				sys_log("mouse step, inc step " step ", x pos " sx)
			}
			;sleep 0

		; check if mouse moved
		} else {
			mouse_pos(cx, cy)

			if (cy == sy) {
				sleep 1

			} else {
				; move back
				mouse_move(cx, sy)
				sys_log("move mouse back")
			}
		}
	}
	click_pos(sx, sy, "up")

	sys_log("mouse step end")
}

mouse_dest(Byref handle)
{
	if (!(ctrl := handle.())) {
		return false
	}

	if (!(stop_list := config("mouse_dest", A_ThisHotkey))) {
		split_assist_master(A_ThisHotkey, stop_list, draw_key)
		config("mouse_dest", A_ThisHotkey, stop_list)
	}

	mouse_action_area(ctrl, range)
	mouse_pos(sx, sy)
	
	;Suspend, on
	while (if_list_dw(stop_list)) {
		sleep 1
	}
	;Suspend, off
	mouse_pos(cx, cy)
	mouse_exceed_area(sx, cx, range)

	; make it move faster to origin point, use mouse move
	mouse_move(sx, sy)
	drag_pos(sx, sy, cx, cy)
}

;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
click_pos(Byref x, Byref y, Byref mode=0)
{
	Click, %x%, %y%, Left, %mode%
}

drag_pos(Byref sx, Byref sy, Byref cx, Byref cy, Byref mode=0)
{
	if (mode == 0) {
		SendEvent {Click %sx%, %sy%, down} {click %cx%, %sy%, up}

	} else if (mode == 1) {
		MouseClickDrag, Left, %sx%, %sy%, %cx%, %sy%

	} else if (mode == 2) {
		click_pos(sx, sy, "down")
		click_pos(cx, sy, "up")
	}
}

;===========================================================================================
;===========================================================================================
; 1-level use prefix, other level use subdir and prefix
batch_rename(Byref path, prefix="", suffix="", mode="", level=0)
{
	count := 0
	; traverse all dirs
	Loop, %path%\*, 2, 1 
	{
		count += batch_rename(A_LoopFileFullPath, prefix, suffix, mode, level + 1)
	}
	
	{
		if (get_option(mode, opt("test"), true)) {
			test := 1	
		}

		if (get_option(mode, sep("precise"), true)) {
			precise := 1	
		}

		if (!mode) {
			prefix := (level == 0 ? "" : (file_name(path) "-")) exist_suffix(prefix, "-")
		}
	}

	default(file_list)
	default(file_move)

	index := 0
	Loop, %path%\*, 0, 0
	{
		if A_LoopFileAttrib contains H,R,S,D,O,C
		{
			app_log("batch rename, ignore file, attr [" A_LoopFileAttrib "]")
			continue
		}

		if (update_file_name(name, index, prefix, suffix, mode, precise)) {
			dest := A_LoopFileDir "\" name

			if (A_LoopFileFullPath = dest) {
				app_log("batch rename, ignore same [" name "]")

			} else {
				file_list.insert(A_LoopFileFullPath)		
				file_move.insert(dest)

				app_log("batch rename, move [" A_LoopFileName "] -> [" name "]")
			}
		}
	}
	
	if (test) {
		app_log("batch rename, just test")

	} else {
		index := 0
		for index, path in file_list
		{
			FileMove, % file_list[index], % file_move[index]
			if (ErrorLevel != 0) {
				tips("move " file_name(file_list[index]) "-> [" file_name(file_move[index]) "] failed", 3000)
				return 0
			}
		}
	}

	count += index
	if (level == 0) {
		app_log("batch rename, total [" count "], mode [" mode "]")
		tips("succ [" count "]", 1000)
	}
	return count
}

update_file_name(Byref name, Byref index, Byref prefix, Byref suffix, Byref mode, Byref precise)
{
	if (mode) {
		if (precise) {
			format := "yyyy-MM-dd HH_mm_ss"
		} else {
			format := "yyyy-MM-dd"
		}

		; prefix only work in date mode, date-prefix-origin
		;	other mode, use origin file name, date-origin
		if (mode = "date") {
			head := date_time(, format) " " prefix	

		} else if (mode = "create") {
			head := date_time(A_LoopFileTimeCreated, format) " " 

		} else if (mode = "modify") {
			head := date_time(A_LoopFileTimeModified, format) " " 

		} else if (mode = "access") {
			head := date_time(A_LoopFileTimeAccessed, format) " " 
		}

		; already the same
		if (if_prefix(A_LoopFileName, head)) {
			; old is precise format, new is normal format
			if (!precise && RegExMatch(A_LoopFileName, "( [0-9]{2}_[0-9]{2}_[0-9]{2})")) {
				app_log("update file name, old is precise format, new is normal format")
					
			} else {
				app_log("update file name, no need update [" A_LoopFileName "]")
				return 0
			}
		} 
		pos := RegExMatch(A_LoopFileName, "([0-9]{4}-[0-9]{2}-[0-9]{2})( [0-9]{2}_[0-9]{2}_[0-9]{2})*", out)
		if (pos == 1) {
			name := head trim(SubStr(A_LoopFileName, pos + StrLen(out1) + StrLen(out2)))
			;app_log("update file name, already have date, update it")

		} else {
			name := head A_LoopFileName	
		}

	} else {
		; use index number
		name := prefix printf(++index, 3, , true) suffix "." A_LoopFileExt		
	}
	return 1
}

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
; prefix only used for date mode
rename_files(Byref prefix="", Byref mode="", Byref suffix="")
{
	if (dir_active()) {
		if (get_dir_path(path)) {
			show := prefix ? (", prefix <" prefix ">") : ""
			tips("rename [" file_name(path) "]" show, 1000, true)
			app_log("rename files, try to rename dir [" path "]" show)

			batch_rename(path, prefix, suffix, mode)

		} else {
			info("rename files, can't get any path")
		}

	} else {
		info("current not dir")
	}
}

dating_files(Byref prefix="")
{
	return rename_files(prefix, "date")
}

;==============================================================================================
;==============================================================================================
import_clip()
{
	global g_clip
	
;	if (!keep_clip()) {
;		tips("no content select or in clipboard")
;		return
;	}
	key := curr_hotkey(true)
	g_clip[key] := clipboard
	tips("[" key "]-" g_clip[key])
}

export_clip()
{
	global g_clip
	
	key := curr_hotkey(true)
	if (!g_clip[key]) {
		tips("no context")
		return
	}
	paste(g_clip[key], , true)
}

regist_clip_pair(Byref key1, Byref key2="", type = 0)
{
	if (!key2) {
	
		; ctrl copy, shift paste
		if (type == 0) {
			clip  := "^"
			paste := "+"
		
		; right ctrl + shift copy, right shift paste
		} else {
			clip  := ">+>^"
			paste := ">+"
		}
		key2 := key1

		handle_list("[" clip key1  	"]	import_clip"
				, 	"[" paste key2 	"]	export_clip")
	} else {
		handle_list("[" key1		"] 	import_clip"
				, 	"[" key2		"] 	export_clip")
	}
}

regist_clip()
{	
	regist_clip_pair("F1")
	regist_clip_pair("F2")
	regist_clip_pair("F3")
	regist_clip_pair("F4")
	regist_clip_pair("F5")

	regist_clip_pair("1")
	regist_clip_pair("2")
	regist_clip_pair("3")
	regist_clip_pair("4")
	regist_clip_pair("5")
	
	regist_clip_pair("F1", , 1)
	regist_clip_pair("F2", , 1)
	regist_clip_pair("F3", , 1)
	regist_clip_pair("F4", , 1)
	regist_clip_pair("F5", , 1)
}