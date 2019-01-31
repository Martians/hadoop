; IMPORTANT INFO ABOUT GETTING STARTED: Lines that start with a
; semicolon, such as this one, are comments.  They are not executed.

; This script has a special filename and path because it is automatically
; launched when you run the program directly.  Also, any text file whose
; name ends in .ahk is associated with the program, which means that it
; can be launched simply by double-clicking it.  You can have as many .ahk
; files as you want, located in any folder.  You can also run more than
; one .ahk file simultaneously and each will get its own tray icon.

; SAMPLE HOTKEYS: Below are two sample hotkeys.  The first is Win+Z and it
; launches a web site in the default browser.  The second is Control+Alt+N
; and it launches a new Notepad window (or activates an existing one).  To
; try out these hotkeys, run AutoHotkey again, which will load this file.

#z::Run www.autohotkey.com

^!n::
IfWinExist Untitled - Notepad
	WinActivate
else
	Run Notepad
return


; Note: From now on whenever you run AutoHotkey directly, this script
; will be loaded.  So feel free to customize it to suit your needs.

; Please read the QUICK-START TUTORIAL near the top of the help file.
; It explains how to perform common automation tasks such as sending
; keystrokes and mouse clicks.  It also explains more about hotkeys.

#NoEnv  
SendMode Input  
SetWorkingDir %A_ScriptDir%  

#Include WinClipAPI.ahk
#Include WinClip.ahk

^!1::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="font-size:160`%"><b>%t%</b></span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
 
 ^!2::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="font-size:140`%"><b>%t%</b></span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
 
  ^!3::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="font-size:120`%"><b>%t%</b></span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
 
 
 ^!4::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="background-color: lightgreen;">%t%&nbsp;</span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
 
  ^!5::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="background-color: lightblue;">%t%&nbsp;</span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
 
  ^!6::
 Send ^c
 Sleep, 100
 t := WinClip.GetText()
 html = <span style="background-color: lightgrey;">%t%&nbsp;</span>
 WinClip.Clear()
 WinClip.SetHTML( html )
 Send ^v
 return
