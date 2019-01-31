
#ClipboardTimeout 1000

; check if we can get clipboard now
; while DllCall("GetOpenClipboardWindow", "ptr") 

; winclip page
; http://www.apathysoftworks.com/ahk/index.html
; https://autohotkey.com/board/topic/74670-class-winclip-direct-clipboard-manipulations/

;========================================================================================
;========================================================================================
clip_data()
{
	;return Clipboard != "" && strlen(Clipboard)
	return Clipboard != ""
}

clip_clear()
{
	clipboard =
}

clip_save(Byref save)
{
	static s_last

	if (save) {
		s_last := ClipboardAll

	} else {
		Clipboard := s_last
		s_last =
	}
}

reset_clip(Byref count=0, Byref total=0)
{
	default(total, 100)
	count := 0
	
	while (++count <= total) {
		if (Clipboard) {
			Clipboard =
			sleep 20
		} else {
			break
		}
	}

	valid := 2
	if (count == total) {
		info("reset clip, but failed for [" count "]")

	} else if (count > valid) {
		app_log("reset clip, try count [" count "]")
	}
	; first time, set Clipboard =, second time, check
	return count - valid
}

; get_clip, then filter invalid char
filter_clip(wait=0, mode=1, option="", time=0, filter=true)
{
	if (get_clip(wait, mode, option)) {

		if (filter) {
			validate := const("string", "valid")
			if (RegExMatch(clipboard, "[" validate "]*(.*)[" validate "]*", out)) {
				clipboard := out1
			}
		}
	}
	; maybe after filter, Clipboard will be empty
	if (StrLen(Clipboard)) {
		; if set time, then display
		if (time) {
			tips(Clipboard, time, true)
		}
		return true

	} else {
		if (time) {
			tips("nothing")
		}
		return false
	}
}

get_clip(wait=0, mode=1, option="", Byref select="")
{
	default(wait, 0.2)
	clip_clear()

	; fast get data, in case need select line and wait too long
	Send ^c
	ClipWait 0.02, 1

	; copy success
	if (clip_data()) {
		return true
	}

	; use as try count
	if (if_digit(mode)) {
		count := 0
		while (++count <= mode) {
			Send ^c
			ClipWait %wait%, 1

			if (clip_data()) {
				if (count > 1) {
					app_log("get clip, must mode succ, tried [" count "]")
				}
				return true
			}
		}
		app_log("get clip, must mode fail, tried [" count "]")

	} else if (mode == "line") {

		ClipWait 0.2, 1
		if (clip_data()) {
			return true
		}

		; copy by click
		click_select := enum(option, "clip", "click")
		if (click_select) {
			click, 3

		} else {
			select_line(true)
		}
		Send ^c
		ClipWait %wait%, 1
		;Click 1
		; cancel select state
		if (click_select && clip_data()) {
			select := "click"
		}

	} else {
		ClipWait %wait%, 1
	}
	return clip_data()
}

select_line(whole=true)
{
	if (whole) {
		;sendinput {end} 
		;sendinput +{home}

		SendInput {End}+{Home}
	
	} else {
		sendinput +{end} 
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
paste(ByRef string, Byref retry=0, Byref save=false, Byref insert=false)
{
	if (save) {
		clip_save(1)
	}
		
	default(retry, 3)
	count := 0
	while (++count < retry) {
		Clipboard := string

		if (Clipboard == string) {
			break

		} else {
			sleep 200
		}
	}
	if (count > 1) {
		sys_log("paste, try count [" count "]")
	}

	if (insert) {
		send +{Insert}
	} else {
		send ^v
	}	
	sleep 100

	if (save) {
		clip_save(0)
	}
}

paste_plain()
{
	paste(clipboard)
}

;=============================================================================================================
;=============================================================================================================
cut_line(Byref empty=false, forward=false)
{
	; select the whole line
	select_line()
	get_clip(0.005)

	if (forward) {
		sendinput {BackSpace}	

	} else {
		if (empty && clip_empty_line()) {
			return 0
		}
		sendinput {delete}	
	}
}

clip_empty_line()
{
	if (StrLen(Clipboard) == 2) {
		; empty line, do nothing
		if (regex_replace(Clipboard, "`r`n") == "") {
			return 1
		}
	}
	return 0
}

;=============================================================================================================
;=============================================================================================================
; https://autohotkey.com/board/topic/70404-clip-send-and-retrieve-text-using-the-clipboard/
; https://gist.github.com/exnius/7275718
; do faster copy and paste
Clip(Text="", Reselect="") ; http://www.autohotkey.com/forum/viewtopic.php?p=467710 , modified February 19, 2013
{
	Static BackUpClip, Stored, LastClip

	If (A_ThisLabel = A_ThisFunc) {
		If (Clipboard == LastClip) {
			Clipboard := BackUpClip
		}
		BackUpClip := LastClip := Stored := ""

	} Else {
		If !Stored {
			Stored := True
			BackUpClip := ClipboardAll ; ClipboardAll must be on its own line
		} Else {
			SetTimer, %A_ThisFunc%, Off
		}

		LongCopy := A_TickCount, Clipboard := "", LongCopy -= A_TickCount ; LongCopy gauges the amount of time it takes to empty the clipboard which can predict how long the subsequent clipwait will need
		If (Text = "") {
			SendInput, ^c
			ClipWait, LongCopy ? 0.6 : 0.2, True
		} Else {
			Clipboard := LastClip := Text
			ClipWait, 10
			SendInput, ^v
		}

		SetTimer, %A_ThisFunc%, -700
		Sleep 20 ; Short sleep in case Clip() is followed by more keystrokes such as {Enter}
		If (Text = "") {
			Return LastClip := Clipboard
		} Else If (ReSelect = True) or (Reselect and (StrLen(Text) < 3000)) {
			StringReplace, Text, Text, `r, , All
			SendInput, % "{Shift Down}{Left " StrLen(Text) "}{Shift Up}"
		}
	}
	Return
Clip:
	Return Clip()
} 

clip_Indent()
{
;$Tab::
;$+Tab::
	TabChar := A_Tab ; this could be something else, say, 4 spaces
	NewLine := "`r`n"
	If ("" <> Text := Clip()) {
		@ := ""
		Loop, Parse, Text, `n, `r
		{
			@ .= NewLine (InStr(A_ThisHotkey, "+") ? SubStr(A_LoopField, (InStr(A_LoopField, TabChar) = 1) * StrLen(TabChar) + 1) : TabChar A_LoopField)
		}
		Clip(SubStr(@, StrLen(NewLine) + 1), 2)

	} Else {
		Send % (InStr(A_ThisHotkey, "+") ? "+" : "") "{Tab}"
	}
}
