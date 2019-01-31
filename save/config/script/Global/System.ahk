
#include Syswork.ahk

sys_log(Byref string)
{
	log("[system]: " string)
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
system_class(Byref winid, directory=false)
{
	class := win_class(winid)
	if (directory) {
		return class == "WorkerW" || class == "Progman"
	} else {
		return class == "WorkerW" || class == "Progman" 
			|| class == "Windows.UI.Core.CoreWindow"
	}
}

system_time()
{
	return (A_TickCount/1000) & 0xFFFFFFFF
}

system_tick()
{
	return A_TickCount
}

system_start(Byref wait=0)
{
	default(wait, 60)
	time := system_time()

	if (time <= wait) {
		log("system start, still in start range [" system_time() "]")
		return true

	} else {
		log("system start, already start time [" system_time() "]s , do nothing")
		return false
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
batch_lines(Byref set=0)
{
	static s_batch_lines := A_BatchLines
	batch_lines := A_BatchLines

	if (set) {
		if (batch_lines == -1) {
			return 0
		}
		SetBatchLines, -1

	} else {
		if (batch_lines != -1) {
			return 0
		}
		SetBatchLines %s_batch_lines%
	}
	;g_log("batch lines ========== " set)
	return 1
}

mouse_delay(Byref set=0)
{
	static s_mouse_delay := A_MouseDelay
	if (set) {
		SetMouseDelay, -1

	} else {
		SetMouseDelay %s_mouse_delay%
	}
}
	
ime_chs(winid=0)  
{
	if (winid) {
		winid := win_curr()
	}
	ControlGet, hwnd, HWND, , , ahk_id %winid%
 
	ptrSize := !A_PtrSize ? 4 : A_PtrSize
    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint, &stGTI)
             ? NumGet(stGTI, 8+PtrSize, "UInt") : hwnd

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  Int, 0)      ;lParam  : 0
}

;=====================================================================================
;=====================================================================================
system(Byref mode_str, Byref force=false)
{
	group := "system"
	mode := enum_make(group, mode_str)

	if (enum(mode, group, "shut") && confirm("shutdown", , force)) { 
		code := 1 + (force ? 4 : 0)
		shutdown %code%

	} else if (enum(mode, group, "reboot") && confirm("reboot", , force)) {
		code := 2 + (force ? 4 : 0)
		shutdown %code%

	} else if (enum(mode, group, "halt") && confirm("halt", , force)) {
		DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

	} else if (enum(mode, group, "sleep") && confirm("sleep", , force)) {
		DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)
	}

	if (enum(mode, group, "lock")) {
		; %A_WinDir%\System32\rundll32.exe user32.dll,LockWorkStation
		Run rundll32.exe user32.dll`, LockWorkStation
	}
	; screen_saver
	if (enum(mode, group, "saver")) {
		SendMessage, 0x112, 0xF140, 0, , Program Manager
	}
	if (enum(mode, group, "close")) {
		SendMessage, 0x112, 0xF170, 2, , Program Manager
	}
	sys_log("system, execute [" mode_str "]")
	;info("system command [" mode "] not exist")
}

;==============================================================================================
;==============================================================================================
display_volume()
{
	SoundGet, volume 
	;volume := volume&0xFF
	volume := floor(volume)
	splash("volume:  "volume, , true)
}

stat_volume()
{
	SoundGet, curr, MASTER, MUTE 
	return curr = "off"
}

set_volume(up)
{
	if (config("system", "volume") && stat_volume()) {
		if (up) {
			send_raw("{Volume_Up}")

		} else {
			send_raw("{Volume_Down}")
		}

	} else {
		static v_step = 2
		if (up) {
			SoundSet,  +%v_step%
			;SoundSet, +%v_step%, wave 
		} else {
			SoundSet,  -%v_step%
			;SoundSet, -%v_step%, wave 
		}
		display_volume()
	}
}

reset_volume(mute)
{
	if (!master_dual()) {
		return
	}

	if (config("system", "volume")) {
		send_raw("{Volume_Mute}")

	} else {
		mute := !stat_volume()

		if (switch_bit(mute)) {
			SoundSet, 1, MASTER, mute
			
		} else {	
			SoundSet, 0, MASTER, mute 
		}
	}

	SoundGet, curr, MASTER, MUTE 
	if (curr = "on") {
		splash("volume on")

	} else {
		splash("volume mute")
	}
}

regist_volume()
{
	handle_list("[<^!-]		set_volume(false)"
			,	"[<^!=]		set_volume(true)"
			,	"[<^!Backspace]	reset_volume(true)")
}

;==============================================================================================
;==============================================================================================
copy_date(Byref enter=true, Byref suffix_blank=false)
{
	if (suffix_blank) {
		If master_dual(0.1) {
			string := date()
			paste(string, , true)
			return
		}
	}

	string := date() " "
	paste(string, , true)
	if (enter) {
		sendinput {enter}
	}
}

copy_time()
{
	If master_dual(0.1) {
	;	elapse_inbox()
	} else {
		string := time("next")
		paste(string, , true)
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
switch_win()
{
	static disable := 0
	if (!master_dual(0.3))  {
		return
	}
		
	if (disable == 1) {
		tips("Enable Win")
		disable = 0 
		hotkey, LWin, off
		
	} else {
		tips("Disable Win")
		disable = 1
		hotkey, LWin, nowin
		hotkey, LWin, on
	}
}

nowin:
return                        	

win_key(Byref open, Byref timer=false)
{
	if (once("win", "key")) {
		regist_hotkey("~LWin Up", "nothing")
	}

	if (open) {
		hotkey ~LWin Up, hotkey_label, off
	} else {
		hotkey ~LWin Up, hotkey_label, on
		if (timer) {
			SetTimer, win_key_open_label, 3000
		}
	}
	sys_log("win key, status [" (open ? "open" : "mute") "]")
}

win_key_open_label:
	SetTimer, win_key_open_label, off
	win_key(1)
return

;~LAlt Up:: return
;*LAlt::LCtrl
process_list(Byref renew=false)
{
	array := local("global", "process")

	if (renew) {
		array.time := 0
	}
	; reget system process list every 10 second
	if (!array.time || system_time() - array.time > 10) {
		sys_log("process list, renew process list")

		array.list := ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
		array.time := system_time()

	} else {
		sys_log("process list, using exist list, time [" system_time() - array.time "]")
	}

	return array.list
}

;=============================================================================================================
;=============================================================================================================
process_id(Byref exec="", Byref arg*)
{
	; https://msdn.microsoft.com/en-us/library/aa394372(v=vs.85).aspx
	; https://autohotkey.com/boards/viewtopic.php?t=13649
	batch_lines(1)
	process := process_list()
	
	for index, item in arg 
	{
		if (InStr(item, ".exe")) {
			name := item
		} else {
			name := item ".exe"
		}
		default(exec_list)[name] := 1
	}

	; get parent pid list
	if (exec) {

		if ((pid := win_pid_exec(exec))) {
			default(parent)[pid] := 1
			sys_log("process id, master <" pid ">")

		} else {

			for entry in process
			{
				if (if_prefix(entry.Name, exec) || exec_list[entry.Name]) {
					default(parent)[entry.ProcessID] := 1
					sys_log("process id, master [" entry.name "], parent <" entry.ParentProcessId ">, pid " pid "<" entry.ProcessID ">")
				}
			}

			if (get_size(parent) == 0) {
				batch_lines(0)
				sys_log("process id, can't find pid for [" exec "]")
				return 0
			}
		}
	}

	default(list)
	; get child pid list
	for entry in process
	{
		if (entry.ProcessID == pid) {
			continue
		}

		If (exec) {
			if (parent[entry.ProcessId]) {
				continue

			} else if (parent[entry.ParentProcessId]) {
				list.insert(entry.ProcessID)
				sys_log("process id, child - [" entry.name "], parent <" entry.ParentProcessId "> pid <" entry.ProcessID ">")
			}
		; get all process info
		} else {
			list.insert(entry.ProcessID)
		}
	}

	for pid, entry in parent 
	{
		list.insert(pid)
	}

	batch_lines(0)
	return list
}

kill_exec(Byref exec, failed=0)
{
	; used for win_pid_exec in process_id
	DetectHiddenWindows, on

	count := 0
	sys_log("kill exec, try to kill [" exec "]")

	list := process_id(exec)
	for index, pid in list 
	{
		; waitclose, gracefully close, only wait; still need call process close first
		; Process, WaitClose, % pid, 2
		Process, Close, % pid

		if (ErrorLevel == pid) {
			sys_log("kill exec, pid <" pid ">")
			++count

		} else {
			++failed
			sys_log("kill exec, pid <" pid ">, failed: " ErrorLevel)
		}
	}
	DetectHiddenWindows, off
	return count
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
close_process(Byref exec)
{
	count := kill_exec(exec)
	if (count) {
		info("close [" count "]")

	} else {
		info("nothing killed")
	}
}

process_show(Byref prefix)
{
	if (StrLen(prefix) < 1) {
		return ""
	
	} else {
		batch_lines(1)

		list := {}
		process := process_list()

		for entry in process
		{
			if (if_prefix(entry.name, prefix)) {
				if (list[entry.name]) {

				} else {
					list[entry.name] := entry.name "`t[" entry.ProcessID "]"
				}
			}
		}
		batch_lines(0)
		return list
	}
}