

test_chrome_ctrl_and_focus()
{
	SetTitleMatchMode, 2
	WinGet, wHwnds, ControlListHwnd,  Google Chrome
	WinGet, wLists, ControlList,  Google Chrome
	;log(wLists `n wHwnds)
	log("before [" win_ctrl() "]")
	Loop, Parse, wHwnds, `n 
	{
		;ControlFocus, Chrome_RenderWidgetHostHWND1, ahk_id %A_LoopField%
		;ControlFocus, Chrome Legacy Window, ahk_id %A_LoopField%

		;ControlFocus, ahk_id %A_LoopField%, Google Chrome
		;ControlFocus, Chrome_RenderWidgetHostHWND, Google Chrome
		
		; focus success, but not work well for focus
		;ControlFocus, Chrome_RenderWidgetHostHWND1, Google Chrome
		ControlFocus, Chrome Legacy Window, Google Chrome
		log(a_index "-" ErrorLevel ", " win_title(A_LoopField) win_text(A_LoopField)  ", " win_class(A_LoopField) ", [" win_ctrl() "]")
		break
	}
	log("after [" win_ctrl() "]")
}