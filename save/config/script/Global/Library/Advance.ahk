
;=====================================================================================
;=====================================================================================
set_timer_handle(Byref entry, Byref time, Byref handle, Byref arg*)
{
	entry.time := time
	entry.last := system_time()
	entry.handle := set_handle("", handle, arg*)
}

global_cycle_timer(Byref set)
{
	name := const("cycle_timer", "name")
	array := glob("glob", "timer")

	if (set) {
		if ((entry := array[name]))  {
			entry.last := system_time() 
			app_log("global handle timer, update global timer")
			
		} else {
			entry := sure_item(array, name)
			entry.name := name

			; when timeout, remove itself
			set_timer_handle(entry, round(const("cycle_timer", "timeout")/1000)
				, "global_cycle_timer", 0)

			app_log("global handle timer, start global timer")
			SetTimer handle_timer_label, % const("cycle_timer", "interval")	
		}

	} else {
		if ((entry := array[name]))  {
			; only have global timer
			if (get_size(array) == 1) {
				array.remove(name)			
				app_log("global handle timer, stop global timer")
				SetTimer handle_timer_label, off
			} else {
				app_log("global handle timer, try stop, still have handle timer")
			}
		} else {
			warn("global handle timer, erase global handle, but not exist")
		}
		
	}
	Return

handle_timer_label:
	handle_timeout()
return
}

handle_timeout() 
{
	global := const("cycle_timer", "name")

	array := glob("glob", "timer")
	timer := system_time()

	app_log("")
	app_log("------------->")

timeout_label:
	for name, entry in array 	
	{ 
		if (name == global || entry.last == -1) {
			continue
		}

		point := entry.last + entry.time
		if (entry.last + entry.time < timer) {
			array.remove(name)
			app_log("handle timeout, timer [" entry.name "] already timeout for [" timer - point "]")

			handle_work(entry.handle)
			goto timeout_label
			
		} else {
			app_log("handle timeout, check timer [" entry.name "], left [" point - timer "]")
		}
	}

	if (get_size(array) > 1) {
		global_cycle_timer(1)		

	} else {
		entry := array[global]
		if (entry.last + entry.time < timer) {
			app_log("handle timeout, global timer timeout")
			global_cycle_timer(0)
		}
	}
	app_log("<-------------`n")
}

;==========================================================================================
;==========================================================================================
cycle_timer(Byref time, Byref handle, Byref arg*)
{
	array := glob("glob", "timer")
	default(name, handle)
		
	; clear handle entry
	if (time == 0) {

		if ((entry := array[name])) {
			app_log("handle timer, remove timer [" name "]")
			array.remove(name)

		} else {
			app_log("handle timer, remove timer [" name "], but not exist")		
			return 0
		}

	} else {
		time := round(time / 1000)

		if ((entry := array[name])) {

			if (entry.time == time) {
				entry.last := system_time()
				app_log("handle timer, update timer [" name "]")
				return 0

			} else {
				app_log("handle timer, set timer [" name "], but already exist, update the old one")
			}

		} else {
			app_log("handle timer, set timer [" name "], time [" time "]")
			entry := sure_item(array, name)
			entry.name := name

			; create or update global timer
			global_cycle_timer(1)
		}
		set_timer_handle(entry, time, handle, arg*)	
	}
	return 1
}

update_cycle_timer(Byref handle, Byref name="")
{
	array := glob("glob", "timer")
	default(name, handle)
	
	if ((entry := array[name])) {
		entry.last := system_time()
		app_log("update handle timer, name [" name "]")

	} else {
		app_log("update handle timer, but timer [" name "] not exist")
	}
}

switch_cycle_timer(Byref handle, Byref start)
{
	array := glob("glob", "timer")
	default(name, handle)
	
	if ((entry := array[name])) {
		entry.last := start ? system_time() : -1
		app_log("swtich handle timer, " (start ? "restart" : "pause") " timer for [" name "]")

	} else {
		app_log("swtich handle timer, but timer [" name "] not exist")
	}
}

;=====================================================================================
;=====================================================================================

#if shield()
#if

#if !shield()
#if

shield(Byref class="", Byref name="")
{
	array := glob("glob", "shield")

	if (class) {
		; only regist when used
		if (once("shield", "regist")) {
			global_system_shield()
		}

		if (name != -1) {
			if (array[class]) {
				app_log("set shield, [" name "] already disabled")

			} else {
				array[class] := 1
				app_log("set shield, shield [" name "]")
			}
		} else {
			if (array[class]) {
				array.remove(class)
				app_log("set shield, remove class [" class "]")
				
			} else {
				app_log("set shield, class [" class "] not exist")
			}
		}

	} else {
		return array[win_class()]
	}
}

shield_window(Byref set=-1)
{
	if (set == -1) {
		if (confirm("try to shield or un-shield")) {
			exist := shield()
			set := (exist == NULL)
		} else {
			return 0
		}
	}
	class := win_class()
	
	if (set) {
		shield(class, class)
		tips("add shield [" class "]", 1000)

	} else if (exist) {
		shield(class, -1)
		tips("del shield [" class "]", 1000)

	} else {
		tips("not shield [" class "]")
	}
}
;--------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------
global_system_shield_simple()
{
	hotkey, if, shield()
		hotkey_status(false, 1, 1)
	hotkey, if

	hotkey, if, !shield()
		hotkey_status(true, 1, 1)
	hotkey, if		
}

simple_disable_label:
	if (!A_IsSuspended) {
		Suspend on
		sys_log("simple hotkey disable")
	}
return

; suspend off should never under any {}, or it won't work
simple_enable_label:
	Suspend off
	if (A_IsSuspended) {
		sys_log("simple hotkey enable")
	}
return

;--------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------
global_system_shield()
{
	mode := 0

	if (mode == 0) {
		global_system_shield_simple()

	} else {
		hotkey, if, shield()
			hotkey_status(false, 1)
		hotkey, if

		hotkey, if, !shield()
			hotkey_status(true, 1)
		hotkey, if	
	}
}

; suspend code must never set in any handle
disable_label:
	Suspend on
	hotkey_cancel(true)
return

enable_label:
	Suspend off
	hotkey_cancel(false)
return

hotkey_status(Byref enable, Byref state, Byref simple=0)
{
	if (simple) {
		label := enable ? "simple_enable_label" : "simple_disable_label"

		array := const("keymap", "assist")
		for key, name in array
		{
			hotkey ~%name%, %label%, on
		}

	} else {
		label := enable ? "enable_label" : "disable_label"

		array := const("keymap", "assist")
		for key, name in array
		{
			if (state) {
				hotkey ~%name%, %label%, on
			} else {
				hotkey ~%name%, %label%, off
			}
		}
	}
	g_log(name ", " label ", " state)
}

hotkey_cancel(Byref disable)
{
	if (disable) {
		; disable status no need use
		hotkey, if, shield()
			hotkey_status(false, 0)
		hotkey, if

		hotkey, if, !shield()
			hotkey_status(true, 1)
		hotkey, if
		
	} else {
		; active status no need use
		hotkey, if, !shield()
			hotkey_status(true, 0)
		hotkey, if

		hotkey, if, shield()
			hotkey_status(false, 1)
		hotkey, if
	}
	sys_log("hotkey " (disable ? "disable" : "enable"))
}

