

set_window_hook(Byref hook, Byref handle="")
{
    if (handle) {
        if (config("window_hook", hook)) {
            sys_log("window hook, but type [" hook "] already regist")
            return 0

        } else {
            ret := DllCall("SetWindowsHookEx", "int", hook
                , "Ptr", RegisterCallback(handle, "fast")
                , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
                , "uint", 0)

            if (ret == 0) {
            	 sys_log("window hook, hook type [" hook "] with handle [" handle "], but failed [" ErrorLevel "]")
            	 return 0

            } else {
	            sys_log("window hook, hook type [" hook "] with handle [" handle "], ptr " ret)
	            config("window_hook", hook, ret)
	            return 1
	        }
        }
    } else {

        if ((hhook := config("window_hook", hook))) {
            ret := DllCall("UnhookWindowsHookEx", "uint", hHook)
            sys_log("window hook, hook type [" hook "] unregist")
            config("window_hook", hook, 0)
            return 1

        } else {
            sys_log("window hook, but type [" hook "] not regist")
            return 0
        }
    }
}

next_hook(Byref nCode, Byref wParam, Byref lParam, Byref hHook=0)
{
    Return DllCall("CallNextHookEx", "uint", hHook, "int", nCode, "uint", wParam, "uint", lParam)
}

;-------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------
set_event_hook(Byref hook, Byref handle="")
{
    if (handle) {
        if (config("event_hook", hook)) {
            sys_log("event hook, but type [" hook "] already regist")
            return 0

        } else {
            DllCall("CoInitialize", "uint", 0)
            ret := DllCall("SetWinEventHook"
                    , "uint", hook, "uint", hook, "uint", 0
                    , "uint", RegisterCallback(handle, "F")
                    , "uint", 0, "uint", 0, "uint", 0)

            if (ret == 0) {
            	 sys_log("event hook, hook type [" hook "] with handle [" handle "], but failed [" ErrorLevel "]")
            	 return 0
            } else {
	            sys_log("event hook, hook type [" hook "] with handle [" handle "], ptr " ret)
	            config("event_hook", hook, ret)
	            return 1
	        }
        }

    } else {
        if ((hhook := config("event_hook", hook))) {
            ret := DllCall("UnhookWinEvent", "uint", hHook)
            sys_log("event hook, hook type [" hook "] unregist")
            config("event_hook", hook, 0)
            return 1

        } else {
            sys_log("event hook, but type [" hook "] not regist")
            return 0
        }
    }
}

;-------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------
WH_KEYBOARD_LL := 13
WH_MOUSE_LL := 14

keyboard_hook(nCode, wParam, lParam)
{
    Critical
    SetFormat, Integer, H
    If ((wParam = 0x100)  ; WM_KEYDOWN
        || (wParam = 0x101))  ; WM_KEYUP
    {
        KeyName := GetKeyName("vk" NumGet(lParam+0, 0))
        Tooltip, % (wParam = 0x100) ? KeyName " Down" : KeyName " Up"
    }
    Return next_hook(nCode, wParam, lParam)
}

mouse_hook(nCode, wParam, lParam)
{
    Critical
    SetFormat, Integer, D
    If ( wParam = 0x200) {
        Tooltip, % " X: " . NumGet(lParam+0, 0, "int")
            . " Y: " . NumGet(lParam+0, 4, "int")
    }
    Return next_hook(nCode, wParam, lParam)
}

hook_test()
{
    if (0) {
        set_window_hook(14, "mouse_hook")
        sleep 10000
        set_window_hook(14)
        ToolTip,
    } 

    active_hook_worker("tips", "change active")
	sleep 10000
	active_hook_worker("tips", "null")
}

;==================================================================================================
;==================================================================================================
/*
https://stackoverflow.com/questions/9176757/autohotkey-window-appear-event

DllCall( "RegisterShellHookWindow", uint,hWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )
Return

ShellMessage( wParam,lParam )
{
    If ( wParam = 1 ) ;  HSHELL_WINDOWCREATED := 1
    {
        WinGetTitle, Title, ahk_id %lParam%
        If  ( Title = "WorkRest" )
            WinClose, ahk_id %lParam% ; close it immideately

    }
}
*/

/*
https://autohotkey.com/board/topic/56697-hook-window-destruction/
https://stackoverflow.com/questions/24568759/how-to-hook-a-window-focused-event-in-win7

#Persistent ; Don't close when the auto-execute ends

SetTitleMatchMode, 2 ; Partial title matching
WinGet, myHwnd, ID, AutoHotKeys; Get the handle to the your window

; Listen for activation messages to all windows
DllCall("CoInitialize", "uint", 0)
if (!hWinEventHook := DllCall("SetWinEventHook", "uint", 0x3, "uint",     0x3, "uint", 0, "uint", RegisterCallback("HookProc"), "uint", 0, "uint", 0,     "uint", 0))
{
    MsgBox, Error creating shell hook
    Exitapp
}

;MsgBox, Hook made
;DllCall("UnhookWinEvent", "uint", hWinEventHook) ; Remove the     message listening hook
return

; Handle the messages we hooked on to
HookProc(hWinEventHook, event, hwnd, idObject, idChild,     dwEventThread, dwmsEventTime)
{
    global myHwnd
    static lastHwnd
    WinGetTitle, title, ahk_id %hwnd%

    if (hwnd == myHwnd) ; If our window was just activated
    {
        tooltip, Gained focus
    }
    else if (lastHwnd == myHwnd) ; If our window was just     deactivated
    {
        tooltip, Lost focus
    }

    lastHwnd := hwnd
}
*/

;=============================================================================================
;=============================================================================================
; set mouse move handler
mouse_hook_worker(Byref handle, Byref arg*)
{
    main_handle := "set_window_hook"
    work_handle := "mouse_move_message"

    if (arg[1] == "null") {
        if (dync_global_handle("mouse_hook", "handle", handle, "null")) {
            sys_log("mouse hook worker, remove hook handle [" handle "]")

        } else {
            sys_log("mouse hook worker, set global hook remove timer")
            ;set_event_hook(0x03)   
            ; remove all the handle in list, start global handle for check removing
            switch_cycle_timer(main_handle, 1)
        }

        ; just remove regist right now
        if (arg[2] == "close") {
            cycle_timer(0, main_handle)

            main_handle.(14)
        }

    } else {
        sys_log("mouse hook worker, set hook handle [" handle "]")
        dync_global_handle("mouse_hook", "handle", handle)

        ; not set yet
        if (main_handle.(14, work_handle)) {
            ; set cycle timer
            cycle_timer(const("hook_timer", "mouse_move"), main_handle, 14)    
        }
        ; some worker run, no need global check now
        switch_cycle_timer(main_handle, 0)    
    }
}

; registed handle for mouse_hook_worker
mouse_move_message(nCode, wParam, lParam) 
{
    If (wParam = 0x200) {
        if (dync_handle_work("mouse_hook", "handle", lParam)) {
            Critical 
            
        } else {
            Critical off
        }
    }
    Return next_hook(nCode, wParam, lParam)
}

;--------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------
; window active, main handle is win_active_message, it will load other worker handle
active_hook_worker(Byref handle, Byref arg*)
{
    main_handle := "set_event_hook"
    work_handle := "win_active_message"

	if (arg[1] == "null") {
        if (dync_global_handle("active_hook", "handle", handle, "null")) {
            sys_log("active hook worker, remove hook handle [" handle "]")

        } else {
            sys_log("active hook worker, set global hook remove timer")
            ;set_event_hook(0x03)    
            switch_cycle_timer(main_handle, 1)
        }

	} else {
        sys_log("active hook worker, set hook handle [" handle "]")
        dync_global_handle("active_hook", "handle", handle)

        if (main_handle.(0x03, work_handle)) {
            ; set cycle timer
            cycle_timer(const("hook_timer", "active_window"), main_handle, 0x03)    
        }
        switch_cycle_timer(main_handle, 0)    
	}
}

win_active_message(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
    dync_handle_work("active_hook", "handle")
}

