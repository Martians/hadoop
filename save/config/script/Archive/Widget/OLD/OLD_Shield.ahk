

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
