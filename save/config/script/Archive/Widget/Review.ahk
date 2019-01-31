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
;获得当前的时间字符
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
	
	;向上取整
	if (type == 1) {
		min := (Floor(min / mode) + 1) * mode
	
	;向下取整
	} else if (type == 2) {
		min := (Floor(min / mode)) * mode
	
	;根据经过的时间的计算的起始时间
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
;添加程序注释
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

;执行review信息输出
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
;输出当前字符串
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

;给出提示信息，异步或者同步方式
Tips(ByRef strings, time = 500)
{
   	ToolTip, %strings%  
    sleep time
    ToolTip
}

;==============================================================================================
;==============================================================================================
;插入注释
<^/::
send_comment()
return

;插入review
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
	添加注释		Ctrl-/
	添加review   	Ctrl-\
	更改名字		右Ctrl-ALT-Home
	查看名字		右Ctrl-ALT-End
	查看帮助		右Ctrl-ALT-H
	模式切换		右Ctrl-ALT-S
)

MsgBox %usage%
return
