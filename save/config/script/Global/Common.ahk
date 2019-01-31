
#SingleInstance Force
#NoTrayIcon
#NoEnv

;#KeyHistory 1
;SendMode Input

#Include Global.ahk
#include Define.ahk
#Include System.ahk
#Include Window.ahk
#Include Handle.ahk
#Include Toolkit.ahk
#Include Program.ahk
#include Directory.ahk
#include Dictionary.ahk

#include Library/Vimium.ahk
#Include Library/Global.ahk
#Include Library/String.ahk
#Include Library/Hotkey.ahk
#include Library/Snippet.ahk
#Include Library/Windows.ahk
#Include Library/Advance.ahk
#Include Library/Clipboard.ahk
#include Library/Application.ahk
#Include ../Archive/Explorer.ahk

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
global_system_ahk()
{
	open_dir("",  "<^!E", 	A_ScriptDir)
	open_file("", "<^!H", 	A_ScriptDir "\Handy.ahk")

	handle_list("[<^<!<#F1]	ahk_config(Startup)"
			,	"[<^<!<#F2]	ahk_config(Locking)"
			,	"[<^<!<#F3]	ahk_config(AutoApp)"
			,	"[<^<!<#F4]	ahk_logging")
	
	handle_list("[<^!s]		ahk_system(switch)")

	system_lock_switch()
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
<^<!c::
	;RunAs, Long
	tips("Update script")
	execute_path(A_ScriptFullPath)
	;RunAs, 
return

ahk_system(Byref type)
{
	; only used for the first time, later its label change Top follow
	if (type == "switch") {
		goto ahk_switch
		
	} else if (type == "suspend") {
		goto ahk_suspend

	} else if (type == "resume") {
		goto ahk_resume

	} else {
		warn("ahk system, do nothing for type [" type "]")
	}
	return

	;A_IsSuspended
ahk_switch:
	if (master_dual(0.15)) {
		tips("suspend")
		goto ahk_suspend
	}
	return

ahk_suspend:
	Hotkey <^!s, ahk_resume
	Suspend on
	return

ahk_resume:
	Suspend off
	tips("resume")
	Hotkey <^!s, ahk_switch
	return
}

;==========================================================================================
;==========================================================================================
if_status(Byref type)
{
	if (type == "startup") {
		; not set, or set as 0, means need disable
		ret := (get_config("Startup", "System") == 1)
		;ret := (get_config("Startup", "System") != 0)

	} else if (type == "logging") {
		ret := (get_config("Logging", "System") != 0)

	} else if (type == "autoapp") {
		ret := (get_config("AutoApp", "System") == 1)

	} else if (type == "locking") {
		ret := (get_config("Locking", "System") == 1)

	} else {
		warn("no status type [" type "]")
	}
	return ret
}

ahk_status(Byref type)
{
	if (type == 0) {
		ahk_source()
		
		if (!if_status("logging")) {
			logging(0)
		}

		ahk_status(1)

	; do this after system regist complete
	} else if (type == 1) {
		; not set, or set as 1
		if (if_status("locking")) {
		    if (system_start(120)) {
			    system("lock")

			} else {
				; if not locker, check if we start from startup folder
				SetTimer, checker_label, 0
			}
	    }

	} else if (type == 2) {

		;if not set, default use start
		if (if_status("startup")) {

			if (if_status("autoapp")) {
				
				if (system_start() || config("ahk", "startup")) {
					startup_app(20, true)
				}
			}
		} else {
			ahk_system("suspend")
		}
	}
}

; directly get input param will failed, so use a timer
checker_label:
	SetTimer, checker_label, off

	var=%1%
	; always lock, if start from startup folder
	if (var = "startup") {
		config("ahk", "startup", 1)
		system("lock")
	}
return

;----------------------------------------------------------------------------------
;----------------------------------------------------------------------------------
ahk_config(name, Byref value=0, Byref default=0)
{
	if ((value := get_config(name, "System")) == "") {
		value := default
	}

	if (master_dual(0.15)) {
		switch_display(value, name)
		set_config(name, value, "System")
		return 1
		
	} else {
		tips(name " " (value ? "on" : "off"))
		return 0
	}
}

ahk_source()
{
	link := A_Startup "\Common.ahk.lnk"

	if (!FileExist(link)) {
		tips("create for startup")
		FileCreateShortCut, %A_ScriptFullPath%, %link%, %A_ScriptDir%, startup
	}

	config := const("system", "config")
	if (!FileExist(config)) {
		if (create_dir(path)) {
			tips("create config path")
		}
	}

	debug := A_ScriptDir "\debug.log"
	if (FileExist(debug)) {
		FileDelete %debug%
		log("remove debug file [" debug "]")
	}
}

ahk_logging()
{
	if (ahk_config("Logging", value, 1)) {
		logging(value)

		if (value == 0) {
			logging(1)
			log_del()
			logging(0)
		}
	}
}

/*
	HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run
	New -> String Value
	Name = AutoHotkey
	Value = "AutoHotkey\AutoHotkey.exe"

	All of the following locations did not work, but the one above did.
	HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
	HKCU\Software\Microsoft\Windows\CurrentVersion\Run
	C:\Users\(username)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
	C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup

	SetNumlockState, AlwaysOn
	SetCapsLockState, AlwaysOff
	SetScrollLockState, AlwaysOff
*/
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
system_lock_switch()
{
	num_lock(true)
	cap_lock(false)

	SetNumLockState on
	SetCapsLockState off
}

num_lock(set)
{
	if (GetKeyState("Numlock", "T") == set) {
		; tips("no need - " GetKeyState("Numlock", "T"), 10000)
		return 

	} else {
		; tips("need - " GetKeyState("Numlock", "T"), 10000)
		stat := set ? "on" : "off"
		SetNumLockState %stat%
	}
}

cap_lock(set)
{
	if (GetKeyState("CapsLock", "T") == set) {
		return 
	} else {
		stat := set ? "on" : "off"
		SetCapsLockState %stat%
	}
}


