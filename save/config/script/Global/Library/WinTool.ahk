

;===============================================================================================

;==============================================================================================
;==============================================================================================
win_move(Byref winid, Byref x, Byref y, Byref w="", Byref h="")
{
	if (winid == 0) {
		WinMove A, ,%x%, %y%, %w%, %h%
	} else {
		WinMove ahk_id %winid%, ,%x%, %y%, %w%, %h%
	}
}

win_pos(Byref x, Byref y, Byref w="", Byref h="", Byref winid=0)
{	
	if (winid == 0) {
		WinGetPos, x, y, w, h, A
	} else {
		WinGetPos, x, y, w, h, ahk_id %winid%
	}
}

ctrl_pos(Byref x, Byref y, Byref w="", Byref h="", Byref ctrl="", Byref winid=0)
{
	if (winid == 0) {
		ControlGetPos x, y, w, h, %ctrl%, A
	} else {
		ControlGetPos x, y, w, h, %ctrl%, ahk_id %winid%
	}
	win_pos(wx, wy, ww, wh, winid)
	
	x := x + wx
	y := y + wy
	;sys_log("ctrl pos, ctrl [" ctrl "], pos (" x "," y "), size [" w "," h "], window size [" ww "-" wh "]")
}

; get window info
print_position()
{
	winid := win_curr()
	win_pos(x, y, w, h, winid)
	
	log()
	log("window pos: (" x  "," y  "), width: " w "-" h ", class: " win_class(winid) ", winid: " winid ", active ctrl [" win_ctrl() "]")
	
	mouse_pos(mx, my)
	log("mouse  pos: (" mx "," my "), ctrl under mouse: " mouse_win_ctrl())
}

print_window(Byref winid=0)
{
	win_default(winid)
	
	log("win current state:")
	log("`t state: max min visiable [" if_max(winid) "-" if_min(winid) "-" if_visible(winid) "], top hide [" if_top(winid) "-" if_hide(winid) "]")
}

print_control(Byref winid=0, Byref mark="")
{
	win_default(winid)
	
	log("win current control:")
	array := list_win_ctrl(winid, mark, 1)

	last := 0
	for name, item in array 
	{
		if (last < item.size) {
			last := item.size 
			data := name
		}
	}

	center := win_center_ctrl(winid)
	for name, item in array 
	{
		if (item.size == last) {
			log("`t state: maxsize ctrl [" name "] , pos (" item.x "," item.y ") size [" item.w "," item.h "] = " item.size)	
		}
	}
	log("`t state: center ctrl [" center "]")		
}

print_time()
{
	log("system start:  [" system_time() "]s")
}

app_print(Byref name)
{
	winid := app_winid(name)
	print_window(winid)
}

;-------------------------------------------------------------
;-------------------------------------------------------------
mouse_move(Byref x, Byref y, Byref fast=false)
{
	if (fast) {
		MouseMove, x, y, 0

	} else {
		DllCall("SetCursorPos", int, x, int, y)
	}
}

; use mechanism like mouse_action will work better
mouse_direction(Byref mode)
{
	if (init(stat, "mouse", "direction")) {
		stat.min := 1
		stat.max := 10
		stat.inc := 1

		stat.time := 0
		stat.mode := ""
		stat.last := stat.min
		stat.loop := 5
	}	

/*
	time := A_TickCount
	if (mode == stat.mode) {

		if (time - stat.time < 1000) {
			step := stat.last + stat.inc
			if (step > stat.max) {
				step := stat.max
			}
		} else {
			step := stat.min
		}

	} else {
		step := stat.min		
	}

	stat.time := time
	stat.mode := mode
	stat.last := step
*/

	key := hotkey_master(A_ThisHotkey)
	mouse_pos(x, y)

	count := 0	
	while (if_dw(key)) {

		if (mode == "up") {
			y -= step

		} else if (mode == "down") {
			y += step

		} else if (mode == "left") {
			x -= step
		
		} else if (mode == "right") {
			x += step
		}
		mouse_move(x, y)
		
		if (++count >= stat.loop) {
			count := 0
			ranger(step, stat.min, stat.max, stat.inc)
		}
		sleep 1
	}

	mouse_move(x, y)	
}

mouse_pos(Byref x, Byref y)
{
	;if (once("mouse", "coord_mode")) {
	;	coord_mode(true)
	;}
    coord_mode(true)
	MouseGetPos, x, y
}

coord_mode(screen=false)
{
    if (screen) {
		CoordMode, mouse, Screen
	} else {
		CoordMode, mouse, window
		tips("coord mode window")
	}
}

mouse_click(Byref x, Byref y, back=false)
{
	if (back) {
		mouse_pos(a, b)		
	}

	MouseClick left, x, y, , 0
	sys_log("mouse click, pos (" x "," y ")")

	if (back) {
		mouse_move(a, b, true)		
	}
}

mouse_type(Byref type = "Unknown")
{
	return A_Cursor == type
}

print_mouse()
{
	time := system_time() + 10
	local("mouse", "print", time)
	SetTimer print_mouse_label, 100
	return 

print_mouse_label:
	if (system_time() >= local("mouse", "print")) {
		SetTimer print_mouse_label, off
		tips("mouse print end")
		return
	}
	mouse_pos(x, y)
	tips(x "," y, , true)
	return
}

;-------------------------------------------------------------
;-------------------------------------------------------------
check_include(Byref a, Byref b, Byref x, Byref y
    , Byref w, Byref h)
{
    return a >= x && a <= x + w 
        && b >= y && b <= y + h
}

mouse_include(Byref a, Byref b)
{
    mouse_pos(a, b)
    win_pos(x, y, w, h)
    
    return check_include(a, b, x, y, w, h)
}

win_center(Byref winid, Byref x, Byref y, Byref global=false)
{
    WinGetPos, x, y, w, h, ahk_id %winid%
    
    if (global) {
	    x := x + w/2
	    y := y + h/2
    } else {
   	    x := w/2
	    y := h/2 	
    }
}

;==============================================================================================
;==============================================================================================
display_transp()
{
	v := get_transp()
	splash("transparent:  " v)
}

get_transp()
{
	WinGet, V, Transparent, A

	if (errorlevel != 0) {
		return -1
	}
	
	if (!V) {
		return 255
	}
	return V
}

set_transp(V)
{
	WinSet, Transparent, %V%, A
}

transparent(up)
{
	static v_step = 2
	v := get_transp()
		
	if (v == -1) {
		tips("can't get transparent")
		return
	}

	if (up) {
		v := v + v_step
		
	} else {
		v := v - v_step
	}
	
	if (v >= 255)
		v := "off"
	set_transp(v)
	
	display_transp()
}

reset_transparent()
{
	if (0 && master_dual()) {
		return
	}
	set_transp("off")
	splash("transparent off")
}

;==============================================================================================
;==============================================================================================
;1-max
;2-work
;3-whole
screen_type(Byref type, Byref w, Byref h, dump=false)
{
	static sysset
	if (!sysset) {
		sysset := {}
		; resolution Rx Ry

		; CXFULLSCREEN workspace, x = RX, y = RY - m
		sysset[1] := {}
		sysset[1].x := 16
		sysset[1].y := 17
			
		; SM_CXMAXIMIZED, x = RX + 2 * n, y = Ry - m, , 2
		sysset[2] := {}
		sysset[2].x := 61
		sysset[2].y := 62
		
		; SM_CXVIRTUALSCREEN, virtual resolution, 2 screen
		sysset[3] := {}
		sysset[3].x := 78
		sysset[3].y := 79	

		; CXMAXTRACK max window size, 2 screen
		sysset[4] := {}
		sysset[4].x := 59
		sysset[4].y := 60

		; SM_CXSCREEN resolution, x = Rx, y = Ry
		sysset[5] := {}
		sysset[5].x := 0
		sysset[5].y := 1
	}
	x := sysset[type].x
	y := sysset[type].y

	SysGet, w, %x%
	SysGet, h, %y%
	
	if (dump) {
		log("type: " type ", x: " w ", y: " h)
	}
	/*
	for i in [1,2,3,4]
	{
		i, w, h)
		v = %v%%w% - %h%`n
	}
	tips(v, 3000)	
	*/
}

sys_get(Byref type, Byref dump=false)
{
	sysget d, %type%

	if (dump) {
		log("type: " type ", v: " d)	
	}
}

dump_screen_type()
{
	screen_type(1, w, h, true)
	screen_type(2, w, h, true)
	screen_type(3, w, h, true)
	screen_type(4, w, h, true)
	screen_type(5, w, h, true)

	; SM_CYFIXEDFRAME
	sys_get(7, true)
	sys_get(8, true)

	; SM_CXFOCUSBORDER
	sys_get(83, true)
	sys_get(84, true)

	; SM_CXMINSPACING
	sys_get(47, true)
	sys_get(48, true)

	; SM_CXSIZEFRAME
	sys_get(32, true)
	sys_get(33, true)

	; SM_CYCAPTION 
	sys_get(4, true)

	; SM_CYKANJIWINDOW
	sys_get(18, true)

	; SM_CYMENU
	sys_get(15, true)
}

; get maxmize screen size
screen_index(Byref index, Byref x, Byref y, Byref w=0, Byref h=0)
{
	static s_x1 := 0
	static s_y1 := 0
	static s_w1 := 0
	static s_h1 := 0

	static s_x2 := 0
	static s_y2 := 0
	static s_w2 := 0
	static s_h2 := 0
	
	if (!s_x1) {
		screen_type(1, w1, h1)
		screen_type(2, w2, h2)
		screen_type(3, w3, h3)
		screen_type(4, w4, h4)

		s_x1 := -((w2 - w1) /2 & 0xFFFFFFFF)
		s_y1 := s_x1
		;-((h2 - h1) /2 & 0xFFFFFFFF)
		
		s_x2 := 0
		s_y2 := 0

	}
	
	if (index == 1) {
		x := s_x1 
		y := s_y1 

		w := s_w1 
		h := s_h1 
	} else {
		x := s_x1 
		y := s_y1 
		w := s_w2 
		h := s_h2 
	}
	sys_log("screen size: " x "," y " " w "-" h)
}

;get window area
next_window_area(type="origin", dock_right=true, winid=0)
{	
	obj := {}
	; current axis offset
	screen_index(1, o_x, o_y)
	
	; get current virtual
	screen_type(2, w, h)
	
	; current window size
	win_pos(cx, cy, cw, ch, winid)

	; screen-2
	if (cx >= w + o_x * 3) {
		
		screen_type(1, w1, h)
		screen_type(3, w3, h)
		; change offset to screen-2
		w := w3 - w1 - o_x * 2
		o_x := w1 + o_x
	}

	static step := 50
	level1 := floor(w/4)
	level2 := floor(w/3)
	mode := 0

	; restore window to origin size
	if (type == "origin") {
		obj.x := o_x
		obj.y := o_y

		obj.w := level1
		obj.h := h

	; move left
	} else {
	 	if (type == "left") {
	 		mode := dock_right ? 1 : 2

		} else if (type == "right") {
			mode := dock_right ? 2 : 1
		}
		obj.h := ch
		obj.y := cy
	}
	
	; inc width
	if (mode == 1) {
		if (cw >= level2) {
			obj.w := cw + step
			sys_log("add step " step)

		} else {
			obj.w := level2
			sys_log("fix level2 " w2)
		}

	; decrease width
	} else if (mode == 2) {
		; much far from level2
		if (cw > level2 + step) {
			obj.w := cw - step
			sys_log("dec step " step)

		; close to level2
		} else if (cw > level2) {
			obj.w := level2
			sys_log("fix level2 ")

		; level2 > w > levle1
		} else {
			obj.w := level1
			sys_log("fix level1")
		}	
	}

	if (dock_right) {
		; move window to left, for axis start from o_x
		obj.x := w - obj.w + o_x

	} else {
		obj.x := o_x
	}
	/*
	log("current window: " cx "," cy " " cw "-" ch)
	log("current screen: " o_x "," o_y " " w "-" h)
	log("moved window: " obj.x "," obj.y " " obj.w "-" obj.h ", pos: " obj.x - cx ", size " obj.w - cw)
	*/
	return obj
}

move_window_area(type, right, winid=0)
{	
	default(winid, win_curr())
	obj := next_window_area(type, right, winid)

	x := obj.x
	y := obj.y
	w := obj.w
	h := obj.h
	sys_log("move: " x "," y " - " w "," h)
	win_move(winid, x, y, w, h)
}

; get next window in z-order
win_next(Byref winid, prev=true) 
{
	Loop
	{
		winid := DllCall("GetWindow", uint, winid, int, prev ? 3 : 2) ; 2 = GW_HWNDNEXT

		; GetWindow() returns a decimal value, so we have to convert it to hex
		SetFormat,integer,hex
		winid += 0
		SetFormat,integer,d

		if (winid == 0) {
			sys_log("win next, but winid 0")
			break
		}
		; GetWindow() processes even hidden windows, so we move down the z oder until the next visible window is found
		if (if_visible(winid)) {
			sys_log("get window " win_title(winid))
			return winid
		}
	}

	/*
	; loop all window
	!e::
	winid := win_winid_mouse()
	while (winid != 0) {
		old := winid
		win_next(winid)
		log(win_title(old) " | "  win_title(winid))	
	}
	*/
	return 0
}

; get window z-order
win_order(winid)
{
	index := 0
	while (win_next(winid)) {
		index++
	}
	return index
}

; along the y midle, find any window not 
sample_class(Byref prev, Byref array, left = true)
{
	screen_type(1, w, h)	
	step = 0.05

	if (left) {
		beg = 0
		end = 0.49999
	} else {
		end = 0.50001
		step := -step
		beg = 1
	}

	curr := beg
	y := floor(h/2)

	while (1) {
		; -1 means move forward, for 0 start
		x := floor(w * curr - 1)
		mouse_move(x, y)
		winid := win_winid_mouse()

		if (!system_class(winid)) {
			new_window := true

			; already get this window
			loop % array.MaxIndex()  {
				if (winid == array[A_index]) {
					new_window := false
				}
			}

			if (new_window) {
				array.insert(winid)

				; not change from last time
				if (prev == winid && array.MaxIndex() == 1) {
					sys_log("sample last: " curr ", " x "," y " " win_class(winid))
					return

				} else {
					sys_log("sample new:" curr ", " x "," y " " win_class(winid) " - " array.MaxIndex())

				}
			}
		}

		last := curr
		curr += step
		if ((left && curr >= end) || (!left && curr <= end)) {
			if (!array.MaxIndex()) {
				sys_log("not find, until" last)

			} else {
				sys_log("total find " array.MaxIndex())
			}
			break

		} else {
			sys_log("check " last)
		}
	} 
}

keep_one_side(Byref ra, Byref rb)
{
	Loop % rb.MaxIndex() {
		if (rb[A_index] == ra[1]) {
			rb.remove(A_index)
			log("remove " A_Index)
		}
	}

}

get_window_attach()
{
	static s_last := {}
	left := {}
	right := {}

	sample_class(s_last.win_1, left,  true)
	sample_class(s_last.win_2, right, false)

	; less than one
	if (!left.MaxIndex() || !right.MaxIndex()) {
		log("less than 2, ignore")
		s_last := {}
		return 0

	; more than 1
	} else if (left.MaxIndex() > 1 || right.MaxIndex() > 1) {
		if (left.MaxIndex() == 1) {
			sys_log("try keep large one as left")
			keep_one_side(left, right)

		} else if (right.MaxIndex() == 1) {
			sys_log("try keep large one as right")
			keep_one_side(right, left)
		}
		
	; only have two
	} else if (left[1] == right[1]) {
		log("only one class " win_class(left[1]) ", ignore")
		s_last := {}
		return 0
	}

	if (s_last.win_1 != left[1] || s_last.win_2 != right[1]) {
		s_last.first := true
	}
	s_last.win_1 := left[1]
	s_last.win_2 := right[1]

	return s_last
}

; first time, two window meadn splitted
move_window_attach(move_left=false, switch = false)
{
	if (!(s_last := get_window_attach())) {
		return
	}

	if (switch) {
		winid := s_last.win_1
		s_last.win_1 := s_last.win_2
		s_last.win_2 := winid
		s_last.first := true
		log("switch window attach")
	}

	static s_step := 50 
	if (move_left) {
		step := -s_step
	} else {
		step := s_step
	}
	; current offset
	screen_index(1, o_x, o_y)
	screen_type(2, w, h)

	distance := o_x*2 + 5

	; move mouse to center
	mouse_move(w/2, h/2)
	
	if (s_last.first) {
		s_last.first := false
		w1 := w/2 - distance/2
		w2 := w/2 - distance/2
		sys_log("first time")
		
	} else {
		win_pos(x1, y1, w1, h1, s_last.win_1)
		win_pos(x2, y2, w2, h2, s_last.win_2)

		w1 += step
		w2 := w - w1 - distance
 	}

	sys_log("win1: " o_x "," o_y " " w1 "-" h "   " win_class(s_last.win_1))
	sys_log("win2: " w1 + o_x "," o_y " " w2 "-" h "   " win_class(s_last.win_2))

	win_move(s_last.win_1, o_x, o_y, w1, h)
	win_move(s_last.win_2, w - w2 + o_x, o_y, w2, h)
}

;===================================================================================
screen_center(Byref index, Byref x, Byref y)
{
	static c_x1 := 0
	static c_y1 := 0

	static c_x2 := 0
	static c_y2 := 0

	if (c_x1 == 0) {
		screen_type(1, w1, h1)
		screen_type(3, w2, h2)

		c_x1 := w1/2 & 0xFFFFFFFF
		c_y1 := h1/2 & 0xFFFFFFFF
		
		c_x2 := w1 + (w2 - w1)/2 & 0xFFFFFFFF
		c_y2 := h1/2 & 0xFFFFFFFF
	}
	if (index == 1) {
		x := c_x1
		y := c_y1
	} else {
		x := c_x2
		y := c_y2
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
next_step(Byref default, Byref Accelerate)
{
	static v_time := 0
	static v_last := 0
	
	curr := A_TickCount
	if (curr >= v_time && curr - v_time < 200) {
		v_last := v_last + Accelerate
	} else {
		v_last := default
	}
	
	sys_log(curr "-" v_time ":" (curr - v_time) "-" v_last)
	v_time := curr
	return v_last
}

movement(up=-1, left=-1)
{
	static v_step := 10

	step := next_step(v_step, 15)
			
	win_pos(x, y)
	
	if (up != -1) {
		if (up)
			y := y + step
		else
			y := y - step
	}
	
	if (left != -1) {
		if (left)
			x := x + step
		else
			x := x - step
	}
	WinMove A, ,%x%, %y%
}

screen_mouse_move(index, focus=false, display="")
{
	screen_center(index, x, y)
	;log(w "-" h ", " x "-" y)
	;mousemove, x, y, 0

	mouse_move(x, y)

	if (focus) {
		ctrl := mouse_win_ctrl(winid) 
		
		win_active(winid)
		focus_ctrl(winid, ctrl)
	}
	
	if (display) {
		tips(display " " index, ,true)
	}
}

double_screen_move(Byref index, display="")
{
	if (!master_dual(0.5)) {
		return
	}
		
	screen_mouse_move(index, true, display)
}

switch_screen_move(focus=false, display="", Byref current=false)
{
	screen_type(2, w_origin, h_origin)
	mouse_pos(x, y)
	
	if (x < w_origin) {
		if (current) {
			index := 1
		} else {
			index := 2
		}
	} else {
		if (current) {
			index := 2
		} else {
			index := 1
		}
	}

	screen_mouse_move(index, focus, display)
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
expand(up=-1, left=-1)
{
	static v_step := 10
	
	win_pos(x, y, w, h)
	if (up != -1) {
		if (up)
			y := y - v_step
		h := h + v_step	
	}
	
	if (left != -1) {
		if (left)
			x := x - v_step

		w := w + v_step			
	}
	win_move(0, x, y, w, h)
}

shrink(up=-1, left=-1)
{
	static v_step := 10
	
	win_pos(x, y, w, h)
	if (up != -1) {
		if (up)
			y := y + v_step
		h := h - v_step	
	}
	
	if (left != -1) {
		if (left) {
			x := x + v_step
		}

		w := w - v_step			
	}
	win_move(0, x, y, w, h)
}

stay_resize(up=-1, left=-1)
{
	static v_step := 10
	
	win_pos(x, y, w, h)
	if (up != -1) {
		if (up) {
			y := y - v_step/2
			h := h + v_step
		
		} else {
			y := y + v_step/2
			h := h - v_step
		}
	}
	
	if (left != -1) {
		if (left) {
			x := x - v_step/2
			w := w + v_step	
		} else {
			x := x + v_step/2
			w := w - v_step	
		}
				
	}
	win_move(0, x, y, w, h)
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
leftup_resize(up=-1, left=-1)
{
	static v_step := 10
	
	win_pos(x, y, w, h)
	if (up != -1) {
		if (up) {
			y := y - v_step
			h := h + v_step	
		} else {
			y := y + v_step
			h := h - v_step
		}
	}
	
	if (left != -1) {
		if (left) {
			x := x - v_step
			w := w + v_step			
		} else {
			x := x + v_step
			w := w - v_step	
		}
	}

	win_move(0, x, y, w, h)
}

rightdown_resize(up=-1, left=-1)
{
	static v_step := 10
	
	win_pos(x, y, w, h)
	if (up != -1) {
		if (up) {
			h := h - v_step	
		} else {
			h := h + v_step
		}
	}
	
	if (left != -1) {
		if (left) {
			w := w - v_step			
		} else {
			w := w + v_step	
		}
	}

	win_move(0, x, y, w, h)
}

regist_transparent()
{
	handle_list("[>^+-]	transparent(false)"
			,	"[>^+=]	transparent(true)"
			,	"[>^+Backspace]	reset_transparent")
}

regist_movement()
{
	handle_list("[<^!up]	movement(false)"
			,	"[<^!down]	movement(true)"
			,	"[<^!left]	movement(, false)"
			,	"[<^!right]	movement(, true)")
}

regist_winsize()
{
	expand := "<^#"    ; <Ctrl + Shift
	shrink := "<!#"    ; <Alt  + Shift
	leftup := ">!"     ; >Alt
	righdw := ">^"     ; >Ctrl
	stayrs := ">^!"    ; >Ctrl + Alt

	handle_list("[" expand "up",   "expand(true)"
			, 	"[" expand "down", "expand(false)"
			, 	"[" expand "left", "expand(, true)"
			, 	"[" expand "right","expand(, false)"
	
			, 	"[" shrink "up", "shrink(true)"
			, 	"[" shrink "down", "shrink(false)"
			, 	"[" shrink "left", "shrink(, true)"
			, 	"[" shrink "right", "shrink(, false)"

			, 	"[" leftup "up",   "leftup_resize(true)"
			, 	"[" leftup "down", "leftup_resize(false)"
			, 	"[" leftup "left", "leftup_resize(, true)"
			, 	"[" leftup "right","leftup_resize(, false)"
	
			, 	"[" righdw "up",   "rightdown_resize(true)"
			, 	"[" righdw "down", "rightdown_resize(false)"
			, 	"[" righdw "left", "rightdown_resize(, true)"
			, 	"[" righdw "right","rightdown_resize(, false)"
	
			, 	"[" stayrs "up",   "stay_resize(true)"
			, 	"[" stayrs "down", "stay_resize(false)"
			, 	"[" stayrs "left", "stay_resize(, true)"
			, 	"[" stayrs "right","stay_resize(, false)")
}

;----------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------
regist_mouse_move()
{
	;batch_lines(1)
hotkey_prefix("win", "mouse")
	handle_list("[<^<!>+ | ~Lshift & ~RShift ]	send_key(click)"
			,  	"[<+<!Enter]	switch_screen_move(false, center, true)"

			,	"[j | down]		mouse_direction(down)" 	sep("usekey")
			,	"[k | up]		mouse_direction(up)" 	sep("usekey")
			,	"[h | left]		mouse_direction(left)" 	sep("usekey")
			,	"[l | right]	mouse_direction(right)" sep("usekey"))
hotkey_prefix(0)
}


regist_resize_window()
{
	; shrink or extend one side
	handle_list("[!#left]	move_window_area(left, true)"
			,	"[!#right]	move_window_area(right, true)"

			,	"[^#left]	move_window_area(left, false)"
			,	"[^#right]	move_window_area(right, false)"

			,	"[^#Up]		move_window_area(origin, false)"
			,	"[!#Up]		move_window_area(origin, true)")

	handle_list("[^+Left]	move_window_attach(true)"
			,	"[^+Right]	move_window_attach(false)"
			,	"[^+Enter]	move_window_attach(true, true)")
}

;=============================================================================================
;=============================================================================================
change_window_assist(Byref type)
{
	; for some type, even not find info, still work
	if (init(array, "assist", "mute")) {
		array["switch_group"] := 1
	}
	notify := !array[type]
	
	; depend on switch info
	if ((curr := find_switch_info(notify))) {
		update_window_assist_check(curr, type)

	} else {
		if (!notify) {
			update_window_assist_check("", type)
		}
	}
}

update_window_assist_check(Byref curr, Byref type)
{
	if (curr && !curr.run.show 
		&& !(curr.run.show := curr.obj.show)) 
	{
		warn("update window assist, run show empty")
		return 0
	}
	return update_window_assist(curr.obj, curr.run, type)
}

update_window_assist(Byref obj, Byref run, Byref type)
{
	if (!update_assist(run, type)) {
		/*
		handle := "check_assist_" type
	    if (IsFunc(handle)) {
	    	return handle.(obj, run)
	    } else {
	    	log("change window sytle, but handle [" handle "] not exist")
	    }
	    */
	    app_log("update window assist, value no change")
	    return 0
	}

	; some type no need switch info, so run empty still ok
	if (run) {
		data := assist(run, type)
		app_log("update window assist, change [" type "] to " data)
	}

	if (type == "switch_group") {
		; cancel automate mode
		switch_window_automate(false)
		switch_window_record(obj, run)

	} else if (type == "single_active") {
		update_type_handle(run, data, "window", "active", "mouse_follow_active")

	} else if (type == "focus_ctrl") {
		update_type_handle(run, data, "window", "active", "ctrl_focus_handle")
	
	} else if (type == "max" || type == "hide") {
		set_enum(run.show, "switch", type, data)

	} else {
		; goto_end: do nothing, only active in evernote
		; active always: work in do_switch`
		if (type == "goto_end" || type == "active_always") {
			
		} else {
			warn("no match type <" type ">")
			return 0
		}
	}

	; it is a time to check if we need update something
	do_global_handle("update", "global", "assist", obj, run, type)
	return 1
}

change_global_assist(Byref type, Byref set=-1)
{
	; patch: when remove handle_list, trigger this, just reverse
	;	see delay_regist_handle
	if (set != -1 && switch("erase"))  {
		set := 1 - set
	}

	if (!(change := set_global_assist(type, set))) {
		return 0
	}

	value := global_assist(type)

	if (type == "follow_active") {
		update_global_handle(value, "window", "active", "mouse_follow_active")
		update_global_handle(value, "window", "active", "ctrl_focus_handle")
	/*
	} else if (type == "record_switch") {
	    if (once("app", type)) {
	        regist_hotkey("Alt & tab", "change_global_switch")
	        app_log("regist switch group hotkey")
	    }
   	 	update_global_handle(value, "window", "active", "record_global_switch")
	*/
	} else if (type == "track_status") {
		update_global_handle(value, "window", "active", "load_last_state")
		update_global_handle(value, "window", "switch", "save_curr_state")

	} else if (type == "record_active") {
		update_global_handle(value, "window", "active", "record_last_active")

	} else if (type == active_always) {

	} else {
		warn("no match type <" type ">")
		return 0
	}
	return 1
}

focus_curr()
{
	if (status("serial")) {
		return
	}

	if (master_dual(0.1)) {
	    if ((curr := find_switch_info(false))) {
	    	if ((handle := get_window_handle(curr.obj, "focus_ctrl"))) {
	    		ret := handle_work(handle)

	    	} else {
	    		ret := ctrl_focus_handle(curr.obj, curr.run)
	    	}
	    }

	    if (!ret) {
	    	; get winid from win_center_ctrl
	    	if ((ctrl := win_center_ctrl(winid, true))) {
	    		focus_ctrl(winid, ctrl)
	    		log("focus curr, window main ctrl [" ctrl "]")

	    	} else {
			    ;MouseClick, left
	    		log("focus curr, but no ctrl name")
	    	}
	    }
	}
}

;=============================================================================================================
;=============================================================================================================
; automte regist activer window switch
switch_window_automate(Byref set)
{
	active := local("window", "active_last")
	if (active.automote == set) {
		return false
	}
	active.automote := set
	active.array := {}
	
	; if (once("switch", "group")) {
	; 	handle_list("[Alt & Tab]	switch_window_recover()")
	; }

	if (set) {
		active.count := 2
		log("switch window automte, set automate mode, max record 2 window")

	} else {
		active.count := 0
		log("switch window automte, cancel mode")
	}
	update_global_handle(set, "window", "active", "switch_window_record")
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
packing_stat(Byref entry="", Byref clear=false) 
{
	if (clear) {
		entry.winid := 0
		entry.ctrl  := ""
		entry.class := ""
		entry.title := ""

	} else {
		default(entry)

		entry.winid := win_curr()
		entry.ctrl  := win_ctrl()
		entry.class := win_class()
		entry.title := win_title()
	}
	return entry
}

unpacking_stat(Byref entry, Byref follow=false, Byref notify=true)
{
	win_active(entry.winid)
	focus_ctrl(entry.winid, entry.ctrl)

	if (follow) {
		; mouse already in window area
		if (mouse_include(a, b)) {

		} else {
			;if not set global, active window right now
			;if (!global_assist("follow_active")) {
			; always follow active

			if (get_global_handle("window", "active", "mouse_follow_active")) {
				mouse_follow_active("", "", entry.winid)	
			}
		}

		cond_tips(notify, "switch [" entry.class "]", 250, true)
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
window_record_check(Byref array, Byref winid, Byref last=false)
{
	for index, entry in array
	{
		if (winid == entry.winid) {
			array.remove(index)

			if (last) {
				array.insert(entry)
			}
			return entry
		}
	}
	return 0
}

switch_window_record(Byref obj="", Byref run="")
{
	active := local("window", "active_last")
	array  := sure_item(active, "array")
	; automate mode no need notify
	notify := !(active.count > 0)

	winid := win_curr()
	; use automate mode, make sure note exceed count
	if (active.count > 0) {
		; current window already in array, remove it
		if ((entry := window_record_check(array, winid))) {
			log("automate switch window record, already exsit, remove entry [" entry.class "]")
		}

		if (array.MaxIndex() >= active.count) {
			entry := array.remove(1)
			log("automate switch window record, exceed count, remove head entry [" entry.class "]")
		}
	}
	
	if ((entry := window_record_check(array, winid))) {
		cond_log(notify, "switch window record, winid " entry.winid " already exist, remove it")
		cond_tips(notify, "-- del switch [" entry.class "]")
		
	} else {
		entry := packing_stat()
		active.array.insert(entry)

		cond_log(notify, "==> switch window record, winid " entry.winid ", class " entry.class ", ctrl " entry.ctrl)
		cond_tips(notify, "++ add switch [" entry.class "]")
	}
}

switch_window_recover()
{
	active := local("window", "active_last")
	array  := sure_item(active, "array")
	; automate mode no need notify
	; noitfy := !(active.count > 0)
	notify := true

	if (!array.MaxIndex()) {
		win_log("switch window recover, but array empty, ignore")
		return
	}

	winid := win_curr()
	if (window_record_check(array, winid, true)) {
		log("switch window recover, change current window index to last")
	}

	entry := array[1]
	; active last window
	if (win_exist(entry.winid)) {
		unpacking_stat(entry, true, notify)

		log("<== switch window recover, winid " entry.winid ", ctrl " entry.ctrl ", title [" entry.title "]")
	
	} else {
		window_record_check(array, entry.winid)
		log("switch window recover, winid " entry.winid " title [" entry.title "] not exist now, try next one")

		switch_window_recover()
	}
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
; record last window, before active current window
win_recover_record(Byref obj="", Byref run="")
{
	entry := local("window", "recover_last")
	packing_stat(entry)

	win_log("win recover record, winid " entry.winid ", class " win_class ", ctrl " entry.ctrl)
}

; recover last window, after deactive current window
win_recover_last(Byref obj="", Byref run="")
{
	entry := local("window", "recover_last")

	if (entry.winid) {
		unpacking_stat(entry)

		win_log("win recover last, winid " entry.winid ", ctrl " entry.ctrl)

		packing_stat(entry, true)
	}
}
