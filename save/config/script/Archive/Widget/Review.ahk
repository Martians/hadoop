#SingleInstance Force
;#NoTrayIcon
    
copy_mode := regist("type")
name := regist("name")

get_name()
get_mode()

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
regist(Byref key, Byref value="none", type="SZ")
{
	if (value == "none") {
		RegRead, value, HKEY_LOCAL_MACHINE
			, SOFTWARE\Review, %key%
	} else {
		;REG_DWORD, REG_SZ
		type := type == "WORD" ? "REG_DWORD" : "REG_SZ"
		RegWrite, %type%, HKEY_LOCAL_MACHINE
			, SOFTWARE\Review, %key%, %value%
	}
	if (ErrorLevel == 1) {
		tips("can't regist info")
		return ""
	}
	return value
}

get_mode()
{
	global copy_mode
	
	if (copy_mode == 1 ) 
		return
		
	if (copy_mode != 0) {
		copy_mode := 0
		regist("type", copy_mode, "word")
		;tips("regist mode as windows")
	}
}

get_name(set=false)
{
	global name
		
	if (!set && strlen(name) != 0) {
		;tips("already get name")
		return
	}
		
	InputBox, string, Regist name,,,,110,,,,100,
	if (!string) {
		;tips("no name set", 500)
	 	return true
	}
	
	if (regist("name", string) == -1) {
		tips("set reg failed")
	} else {
		tips("set name as " string, 1000)
	}
	name := string
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;��õ�ǰ��ʱ���ַ�
date()
{
	FormatTime, time, A_NOW, yyyy-MM-dd
	return time
}

time(type = 0, hour = 0, min = 0
	, Byref mode = 10, Byref elapse = 0)
{
	if (type == 0) {
		FormatTime, time, A_NOW, HH:mm:ss
		return time
	}
	
	if (hour == 0 && min == 0) {
		hour := A_Hour
		min := A_Min
	}
	
	;����ȡ��
	if (type == 1) {
		min := (Floor(min / mode) + 1) * mode
	
	;����ȡ��
	} else if (type == 2) {
		min := (Floor(min / mode)) * mode
	
	;���ݾ�����ʱ��ļ������ʼʱ��
	} else if (type == 3) {
	
		_hour := Floor(elapse / 60)
		_min  := Mod(elapse, 60)

		;min := (Floor(min / mode) + 1) * mode
		hour := hour - _hour
		min  := min  - _min
	
		return time(4, hour, min)
	}
	
	if (min == 60) {
		hour := hour + 1
		min  := 00
		
	} else if (min < 0) {
		min  := min + 60
		hour := hour - 1
	}
		
	if (strlen(hour) < 2 )
		hour := "0" hour
		
	if (strlen(min) < 2 )
		min := "0" min

	return hour ":" min
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;��ӳ���ע��
format_review(Byref string)
{
	static prefix :=
	static suffix :=
	global name
	
	if (!prefix) {
		prefix=
(
/**
 * reviewed by %name% 
 *
)
	}
	
	if (!suffix) {
		suffix =
(

 * 
 * FIXME  
 **/
)
	}
	string := prefix " " date() " `n * " suffix  
}

;ִ��review��Ϣ���
send_review()
{
	format_review(string)
	paste(string, true)
	sendinput {up 3}
	;sendinput {end}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
format_comment(Byref string, Byref line="")
{
	static prefix :=
	static suffix :=
	
	if (!prefix) {
		prefix=
(
/**
)
	}
	
	if (!suffix) {
		suffix= 
(
*/
)	 
	}
	string:= prefix " " line " " suffix
}

send_comment()
{
	format_comment(string)
	paste(string, true)
	sendinput {left 3} 
	;sendinput {end}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;�����ǰ�ַ���
paste(ByRef string, keep=false)
{
	if (keep) {
		old := clipboardAll
	}
		
	clipboard := string
	
	if (copy_mode == 0 ) {
		send ^v
	} else {
		send +{insert}
	}
		
	sleep 100
	if (keep) {
		clipboard := old
	}
}

;������ʾ��Ϣ���첽����ͬ����ʽ
Tips(ByRef strings, time = 500)
{
   	ToolTip, %strings%  
    sleep time
    ToolTip
}

;==============================================================================================
;==============================================================================================
;����ע��
<^/::
send_comment()
return

;����review
<^\::
send_review()
return

>^!Home::
get_name(true)
return

>^!End::
tips(regist("name"), 1000)
return

>^!s::
copy_mode := 1 - copy_mode

if (copy_mode == 0) {
	tips("switch to windows mode")
} else {
	tips("switch to xshell mode")
}
regist("type", copy_mode, "word")
return

>^!h::
usage =
(
			[Command]
	���ע��		Ctrl-/
	���review   	Ctrl-\
	��������		��Ctrl-ALT-Home
	�鿴����		��Ctrl-ALT-End
	�鿴����		��Ctrl-ALT-H
	ģʽ�л�		��Ctrl-ALT-S
)

MsgBox %usage%
return
