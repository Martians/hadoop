
#Include ../Archive/WinClipAPI.ahk
#Include ../Archive/WinClip.ahk

;=============================================================================================================
;=============================================================================================================
; evernote handle api
en_html_paste()
{
	if (Clipboard) {

		; get saved link type 
		link := switch("chrome_link")

		if (link) {
			html := Clipboard
			en_paste(html)
			; if not clear, will be error when past next time
			;clip_clear()
			Clipboard := html
			
		} else {
			send_raw("^v {enter}")
		}
		sleep 100

	} else {
		tips("empty")		
	}
}

en_paste(Byref html)
{
	ever_log("en paste, set html [" html "]")
	
	WinClip.Clear()
	WinClip.SetHTML(html)
	ClipWait, 3, 1

	sleep 100
	Send ^v
	;ever_log("en paste, end")
}

;=============================================================================================================
;=============================================================================================================
en_change(style="", action="", mode="", BYref param="")
{
	if (style) {
		set_en_style(style, mode, param)
	}

	if (action) {
		if (style) {
			sleep 100
		}
		set_en_action(action, mode, param)
	}
}

; if use clipsave, will not work well
set_en_style(style, Byref mode, Byref param)
{
	clip_save(1)
	get_clip(1, "line")

	;if ((html := WinClip.GetText())) {
	if ((html := Clipboard)) {
		en_check_reverse(html, mode, true)

		style.(html, mode, param)
		en_paste(html)

		en_check_reverse(html, mode, false)
		; record last html, wait until work complete
	} else {
		ever_log("get nothing")
	}

	clip_save(0)
	return
}

set_en_action(action, Byref mode, Byref param)
{
	select_line()

	action.()
	sendinput {end} 
	return
}

en_check_reverse(Byref html, Byref mode, Byref start=false)
{
	if (start) {
		; match last html, hotkey, not timeout, and last not reverse
		if (A_PriorHotkey == A_ThisHotkey && local("en_style", "last") != 1
			&& html == local("en_style", "html") 
			&& system_tick() - local("en_style", "time") < 1000) 
		{
			set_enum(mode, "en_style", "reverse")	
			ever_log("set en style, trigger reverse -------")

		} else {
			set_enum(mode, "en_style", "reverse", 0)	
		}
		local("en_style", "last", enum(mode, "en_style", "reverse"))
		local("en_style", "html", html)
	
	} else {
		local("en_style", "time", system_tick())	
	}
}

;===================================================================================================================
;===================================================================================================================
; set font info
; bold: normal、bold、lighter
font_base(Byref html, color="", size=-100, type=0, font="", bold="")
{	
	if (size != -100) {
		text := font_size(size, type)
	}

	text := html
	if (color) {
		text = <span style="color: %color%;">%text%</span>
	}
	
	if (font) {
		text = <span style="font-family: %font%;">%text%</span>
	}

	; not work well
	if (bold) {
		text = <span style="font-weight: %bold%">%text%</span>	
	}
	
	; unbold not work
	;text = <span style="font-family: %font%; color: %color%; ;">%html%</span>
	html := text
}

font_size(Byref size, Byref type = 0)
{
	if (type == 0) {
		static normal0 := 10
		size := normal0 + size
		
		text = %text% style="font-size: %size%pt"
	
	} else if (type == 1) {
		static normal1 := 13
		size := normal1 + size
		
		text = %text% style="font-size: %size%px;"

	} else if (type == 2) {
		static normal2 := 100
		size := normal2 + size * 10
		
		if (size == 100) {
			text = %text% style="font-size: 10pt"
		} else {
			text = %text% style="font-size: %size%`%"	
		}
	}
	return text
}

font_layon(Byref html, bold=true, strike=false)
{
	if (bold) {
		html = <b>%html%</b>
	}
		
	if (strike) {
		html = <strike>%html%</strike>
	}
}

; set background of some text
font_background(Byref html, color)
{
	html = <span style="background-color:%color%;-evernote-highlight:true;">%html%</span>
}

font_underline(Byref html)
{
	html = <u>%html%</u>
}

font_heading(Byref html, Byref param="")
{
	if (param == "") {
		html = <span style="clear: both; font-size: 16px; letter-spacing: normal; orphans: auto; text-indent: 0px; text-transform: none; white-space: normal; widows: auto; word-spacing: 0px; -webkit-text-stroke-width: 0px; color: rgb(0, 154, 73); font-family: verdana, Verdana, Geneva, sans-serif; font-variant: normal; font-weight: bold;">%html%</span>
	} else {
		html = <%param%>%html%</%param%>
	}
}

;=============================================================================================================
;=============================================================================================================
; set line 
text_background(Byref html, Byref color="#D4DDE5")
{
	; html = <div><br/></div><table bgcolor="%color%" border="0" style="width: 1366px;"><colgroup><col style="width: 1352px;"></col></colgroup><tbody><tr><td><h1>%html%</h1></td></tr></tbody></table><div><br/></div>
	html =
(
	<div><br/></div>
	<table bgcolor="%color%" border="0" style="width: 100`%;">
		<colgroup><col></col></colgroup>
		<tbody><tr><td><h1>%html%</h1></td></tr></tbody>
	</table>
	<div><br/></div></div><div><br/>
)
}

;=============================================================================================================
;=============================================================================================================
anchor_src(Byref html, Byref tag)
{
	html = <a name="%tag%">%html%</a>
	return html
}

anchor_dst(Byref tag)
{
	dst = <a href="file:///#%tag%">%tag%</a>
	return dst
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
text_link(Byref html, Byref link)
{
	;html := "<a href=""" link """>" html "</a>"
	html = <a href="%link%">%html%</a>
	return html
}

text_anchor(Byref html, Byref tag="")
{
	default(tag, html)
	anchor_src(html, tag)
	
	font_underline(html)
	dest := anchor_dst(tag)
	html = %html% %dest%
	
	tips("set anchor: " tag)
}

;=============================================================================================================
;=============================================================================================================
; text action
act_bold()
{
	send ^b
	;send {ctrl down} {b} {ctrl up}
}

act_italic()
{
	send {ctrl down} {i} {ctrl up}
}

act_underline()
{
	send ^u
	; send {ctrl down} {u} {ctrl up}
}

act_scratch()
{
	send {ctrl down} {t} {ctrl up}
}

act_checkbox()
{
	send {home}^+c
	;send {ctrl down} {shift down} {c} {shift up} {ctrl up} 
}

act_down()
{
	send {down 2}
}

act_increase()
{
	sendinput ^+.
}

act_decrease()
{
	sendinput ^+,
}

;=============================================================================================================
;=============================================================================================================
; set combination action
text_markit(byref html, Byref mode)
{		
	if (enum(mode, "en_style", "reverse")
	 	|| enum(mode, "en_style", "force_reverse")) 
	{
		act_bold()
		text_normal(html, mode)
		
		if (enum(mode, "en_style", "increase")) {
			sleep 100
			act_decrease()
		}

	} else {
		font_base(html, "rgb(255, 0, 0)")
		font_layon(html, true)

		if (enum(mode, "en_style", "increase")) {
			sleep 100
			act_increase()
		}
	}
	
}

text_normal(Byref html, Byref mode)
{
	; set bold but not work
	; font_base(html, "#000000", 0, 0, gbk("font", "yahei"), "normal")
	font_base(html, "#000000", 0, 0, gbk("font", "yahei"))
}


text_weaken(Byref html, Byref mode)
{
	if (enum(mode, "en_style", "reverse")) {
		text_normal(html, mode)

	} else {
		font_base(html, "#D6D6D6")
	}
}

text_delete(Byref html, Byref mode)
{
	if (enum(mode, "en_style", "reverse")) {
		act_bold()
		act_scratch()
		
		text_normal(html, mode)
	} else {
		font_layon(html, , true)
	}
}

text_stress(byref html, Byref mode)
{
	if (enum(mode, "en_style", "reverse")) {
		act_bold()
		text_normal(html, mode)

	} else {
		font_layon(html, true)

		font_background(html, "rgb(255, 250, 165)")
		font_base(html, "#FF0000", 1)
		;font_background(html, "lightblue")
		;lightblue
		;lightgreen
		;lightgrey
	}
}

text_paragraph(Byref html)
{
	text_background(html)
}

text_heading(Byref html, Byref mode, Byref param)
{
	font_heading(html, param)
}

/*
;=================================================================================
;=================================================================================
text_title1(Byref html)
{
	font_layon(html, true)
	font_base(html, , 11)
}

text_title2(Byref html)
{
	font_layon(html, true)
	font_base(html, , 9)
}

text_title3(Byref html)
{
	font_layon(html, true)
	font_base(html, , 7)
}
;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------

text_change1(Byref html)
{
	font_layon(html, true)	
	font_base(html, "#A600C4", 5, 1)
}

text_change2(Byref html)
{
	font_layon(html, true)
	font_base(html, "#4DCE1D", 3, 1)
}

text_change3(Byref html)
{
	font_layon(html, true)

	font_base(html, "#5898FF", 3, 1, "")
}

text_change4(Byref html)
{
	;font_layon(html, true)

	font_background(html, "rgb(239, 239, 226)")
	font_base(html, "#000000", 6, 1, "")
}
*/

;=====================================================================================
;=====================================================================================
; https://autohotkey.com/boards/viewtopic.php?t=7231
WinClip.GetHtml2 := Func("GetHtml2")
WinClip.GetHtml3 := Func("GetHtml_DOM")

GetHtml_DOM(this, Encoding := "UTF-8")
{
	html := this.GetHtml2(Encoding)
	static doc := ComObjCreate("htmlFile")
	doc.Write(html), doc.Close()
	return doc.all.tags("span")[0].InnerHtml
}

GetHtml2(this, Encoding := "UTF-8")
{
  	if !(clipSize := this._fromclipboard(clipData)) {
		return ""
	} else if !( out_size := this._getFormatData( out_data, clipData, clipSize, "HTML Format")) {
		return ""
	}

  	return strget(&out_data, out_size, Encoding)
}

;==============================================================================================
;==============================================================================================
note_style(Byref key, style="", action="", mode_data=-1, param="")
{
	if (once("ever", "style")) {
		static s_mode := {}
	}

	if (mode_data == -1) {
		mode := s_mode

	} else {
		mode := {}
		set_enum(mode, "en_style", mode_data)
	}

	regist_hotkey(key, "en_change", style, action, mode, param)
}

regist_en_style()
{
	note_style("F1",  "text_markit")
	; set markit, and increase font
	note_style("F5",  "text_markit", , "increase")
	note_style("+F5", "text_markit", , "increase | force_reverse")
	
	; set normal, reverse bold or not
	note_style("F4",  "text_normal")
	note_style("+F4", "text_normal", "act_bold")
	
	note_style("F6",  "text_weaken")
	
	note_style("<+F1", "text_paragraph", "act_down")
	note_style("<+F2", "text_heading")
	note_style("<+1",  "text_heading", , , "h1")
	note_style("<+2",  "text_heading", , , "h4")
	note_style("<+3",  "text_heading", , , "h7")

	;note_style("F5", "text_stress")
	;note_style("F7", , "act_scratch")
	;note_style("F8", , "act_bold")

	; disable anchor
	; note_style(">!a", "text_anchor", mode)
}
