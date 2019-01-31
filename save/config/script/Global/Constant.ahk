app_log(Byref string)
{
	log("[app]: " string)
}
;==============================================================================================
;==============================================================================================
glob_app(Byref name="")
{
	array := glob("app")
	if (name) {
		return array[name]
		
	} else {
		return array
	}
}

; name contain 1) master name 2) alias and onlyer flag
;	the flag part will save in global entry
app(Byref name="", Byref option="", Byref alias="")
{
	curr := glob("app", "curr")

	if (name) {
		array := glob_app()
		if (array[name]) {
			warn("app: app [" name "] already registed")
			return 0
		}
		curr.name := name

		entry := sure_item(array, name)
		entry.type  := "app"
		entry.name  := name 
		entry.alias := alias

		if (option) {
			if ((prior := get_option(option, opt("prior"), true))) {
				entry.prior := prior
			}
			set_enum(entry, "option", option)
		}
	}
	return curr.name
}

;-----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------
app_switch(show="", hide="", front="", start_wait=0)
{
	if (!(entry := glob_app(app()))) {
		warn("app_switch, but app [" app() "] not regist")
		return 0
	}

	set_switch(entry, show, hide, front, start_wait)
	return 1
}

; set current app param
app_param(show="", hide="", Byref link="", Byref exec="", Byref option="")
{
	return app_switch(show, hide) 
		&& app_path(link, exec, option)
}

; set path and flag, will over write exist flag
app_path(Byref link="", Byref exec="", Byref option="")
{
	if (!(entry := glob_app(app()))) {
		warn("app_path, but app [" app() "] not regist")
		return 0
	}
	entry.link := link

	if (exec) {
		if (InStr(exec, ".exe")) {
			entry.exec := exec	
		} else {
			entry.exec := exec ".exe"
		}
	}

	if (option) {
		set_enum(entry, "option", option)
		window_handle(entry, "switch", "exec_switch_handle")
	}
	return 1
}

app_assist(Byref assist="", Byref cond_opti="")
{
	if (!(entry := glob_app(app()))) {
		warn("app_event_handle, but app [" app() "] not regist")
		return 0
	}
	app_log("app assist, assist [" assist "], flag [" cond_opti "]")

	display(0)
	while ((name := string_next(assist, opt("next")))) {
		if (!update_window_assist(entry, entry, name)) {
			warn("app assist, but update assist failed")
			break
		}
	}
	display(1)

	if (cond_opti) {
		set_enum(entry, "cond", cond_opti)
	}
	return 1
}

app_find_handle(Byref handle="", Byref arg*)
{
	entry := glob_app(app())
	if (!handle) {
		handle := auto_find_handle(entry)
	}

	window_handle(entry, "find", handle, arg*)
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
app_ctrl_handle(Byref handle="", Byref name="", Byref arg*)
{
	if (!(entry := glob_app(app()))) {
		warn("app ctrl handle, but app [" app() "] not regist")
		return 0
	}
	default(name, const("ctrl", "name"))

	present := ctrl_entry_name(name)
	if (get_window_handle(entry, present)) {
		del_window_handle(entry, present)
	}

	window_handle(entry, present, handle, arg*)
}

; auto set ctrl find handle by ctrl name
auto_ctrl_handle(Byref name="")
{
	if (!(entry := glob_app(app()))) {
		warn("auto ctrl handle, but app [" app() "] not regist")
		return
	}
	default(name, const("ctrl", "name"))

	if (find_one_of(entry[name], "|*$")) {
		entry[name] := stri_trim_last(entry[name])

		present := ctrl_entry_name(name)
		if (get_window_handle(entry, present)) {
			app_log("auto ctrl handle, auto set app [" app() "], ctrl <" name "> name [" entry[name] "], already have handle [" entry.handle "], ignore")

		} else {
			handle := "ctrl_find_match"
			app_ctrl_handle(handle, name)
			app_log("auto ctrl handle, auto set app [" app() "], ctrl <" name "> name [" entry[name] "], handle [" handle "]")
		}
	}
}

; ctrl name maybe always change
app_ctrl_muttable(Byref name="")
{
	if (!(entry := glob_app(app()))) {
		warn("app ctrl always, but app [" app() "] not regist")
		return 0
	}
	default(name, const("ctrl", "name"))
	present := ctrl_entry_name(name)

	any_data(entry, present, "muttable", 1)
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
app_handle(Byref type, Byref handle, arg*)
{
	if (!(entry := glob_app(app()))) {
		warn("app handle, but app [" app() "] not regist")
		return 0
	}
	window_handle(entry, type, handle, arg*)
}

;-----------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------
regist_app(Byref class="", Byref ctrl="", Byref title="", Byref param="")
{
	if (!(entry := glob_app(app()))) {
		warn("regist_app, but app [" app() "] not regist")
		return
	}
	entry.logon := get_option(class, sep("logon"))
	entry.class	:= del_option(class, sep("logon"))

	entry.ctrl := ctrl
	auto_ctrl_handle()

	entry.title	:= title
	entry.param := param

	app_default()

	app_input(entry.name, entry.alias)
}

app_default()
{
	if (!(entry := glob_app(app()))) {
		warn("app_default, but app [" app() "] not regist")
		return 0
	}

	; get global link path using gbk
	if (app_gbk(entry.name, , false)) {
		entry.link := app_gbk(entry.name)
	}

	; means no need path
	if (enum(entry, "option", "none_start")) {
		entry.path := 
	
	; use full path
	} else if (find_one_of(entry.link, "\\/")) {
		entry.path := entry.link 

	} else if (get_option(entry.link, opt("final"))) {
		entry.path := del_option(entry.link, opt("final"))

	; search app with name and link name	
	} else {
		path := auto_link_path(entry.name opt("next") entry.link)
		entry.path := default(path, const("applic", "not_install"))
	}

	if (!entry.init) {
		set_switch(entry)
	}
	; set default find handle if not exist
	app_find_handle()

	return 1
}

; regist sub-class
regist_sub(Byref name, Byref class=""
	, Byref ctrl="", Byref title="")
{
	curr := glob("app", "curr")
	origin := curr.name
		app(name, flag("none_start|alias_only"))
		regist_app(class, ctrl, title)
	curr.name := origin
}

exec_switch_handle(Byref obj, Byref run)
{
	default(run, obj)

	if (enum(run, "option", "hide_only")) {
		tips(obj.name " already exist")
		return -1

	} else if (enum(run, "option", "close_only")) {
		kill_winid(run.winid)
		return -1

	} else {

	}
	return 0
}

;==============================================================================================================
;==============================================================================================================
app_input(Byref name, Byref alias)
{
	if (!(entry := glob_app(name))) {
		warn("app input: app [" name "] not regist")
		return 
	}

	input_type("run", origin)
		handle := enum(entry, "option", "switch_mute") 
			? "switch_window_mute" : "switch_window"

		set_handle(entry, handle, entry)
		; 	if set flag("alias_only") or flag("alias_only"), not set input; 
		;	if input with #, not set default app name as input
		; not set with app
		if (enum(entry, "option", "alias_only")) {
			; maybe input just have flag("alias_only")
			input := alias

		} else {
			input := name opt("next") alias
		}

		if (input) {
			regist_input(input, name, entry)
		} else {
			log("input empty, no need set input for " name)
		}
		; do record app here
		record_app(name)
	input_type(origin)
}

app_hotkey(Byref name, Byref key)
{
	if (!(entry := glob_app(name))) {
		warn("app hotkey: app [" name "] not regist")
		return 
	}

	regist_hotkey(key, entry)
}

;===============================================================================
;===============================================================================
; not directly used now
app_exist_cond(Byref name="")
{
	return hotkey_cond(name)
}

app_active_cond(Byref name="")
{
	return hotkey_cond(name, enum_valid("cond", "active"))
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
; app condition hotkey list
app_cond_hotkey(Byref key, Byref flag, Byref app_list)
{
	while ((name := string_next(app_list, opt("next")))) {
		
		if (hotkey_cond(name, flag)) {
			app_hotkey(name, key)
		} else {
			failed := true
			break
		}
	}
	hotkey_cond()
	return failed ? 0 : 1
}

app_exist_switch(Byref key, Byref app_list)
{
	return app_cond_hotkey(key, "", app_list)
}

app_active_key(Byref key, Byref app_list)
{
	return app_cond_hotkey(key, enum_valid("cond", "active"), app_list)
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
app_cond_mapkey(Byref name, Byref flag, Byref arg*)
{
	if (hotkey_cond(name, flag)) {
		handle_mapkey(arg*)
		hotkey_cond()
		return 1
	}
	return 0
}

app_exists_map(Byref name, Byref arg*)
{
	return app_cond_mapkey(name, "", arg*)
}

app_active_map(Byref name, Byref arg*)
{
	return app_cond_mapkey(name, enum_valid("cond", "active"), arg*)
}

;===============================================================================
;===============================================================================
app_exists(Byref name, Byref arg*)
{
	while ((next := string_next(name, opt("next")))) {
		app_exist_cond(next)

		handle_list(arg*)
	}
	app_exist_cond()
}

app_active(Byref name, Byref arg*)
{
	while ((next := string_next(name, opt("next")))) {
		app_active_cond(next)

		handle_list(arg*)
	}
	app_active_cond()
}

;===============================================================================
;===============================================================================
switch_app(Byref name, Byref mode="mode_switch", Byref opti_str="", Byref run="")
{
	if (!(entry := glob_app(name))) {
		warn("switch app, but app [" name "] not regist")
		return 0
	}
	opti := enum_make("option", opti_str)

	if (enum(opti, "option", "switch_mute")) {
		return switch_window_mute(entry, run, mode, opti)

	} else {
		return switch_window(entry, run, mode, opti)
	}
}

close_app(Byref name)
{
	if (!(entry := glob_app(name))) {
		tips("no app [" name "]", 1000, true)
		return 0
	}

	count := 0
	if ((winid := get_winid(entry))) {
		; get window app if not set
		exec := win_exec_winid(winid)

		if (!exec) {
			info("close app, name [" name "], can't get acutal exec name, winid [" winid "]", 2000, true)
			;log(winid ", " win_exec_winid(winid))

		} else if (entry.exec && entry.exec != exec) {
			info("close app, name [" name "], acutal exec [" exec "], but registed as [" entry.exec "]")
		}
		; send close message, only one window
		count += kill_winid(winid)
	}

	if (default(exec, entry.exec)) {
		; kill process tree
		count += kill_exec(exec, failed)

		if (win_pid_winid(winid)) {
			info("kill app [" name "] failed", 1000, true)
			return 0
		}
	}
	
	if (count == 0) {
		info("app [" name "] not start", 1000, true)

	} else {
		info("close [" count "]", , true)
	}
	return count
}

shield_app(Byref name)
{
	if (!(class := app_attr(name, "class"))) {
		return 0
	}
	shield(class, name)
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
focus_app(Byref name, Byref ctrl_name="", Byref mode=0, Byref winid=0)
{
	if (!(entry := glob_app(name))) {
		warn("focus app, but app [" name "] not regist")
		return 0
	}

	return ctrl_focus_handle(entry, entry, ctrl_name, mode, winid)
}

send_app(Byref name, Byref key, Byref winid=0)
{
	if (!winid && !(winid := app_winid(name))) {
		info("send app key, but get app [" name "] failed")
		return 0
	}

	count := 10
	while (--count > 0) {

		if (if_active(winid)) {
			app_log("send app key, app [" name "] active, send key [" key "]")
			send_raw(key)
			break
		}
		
		win_active(winid)
		app_log("send app key, app [" name "] active, send key [" key "]")

		sleep 100
	}
}

; only move ctrl, maybe mouse focus not change
;	send_app_ctrl("ever", "^{home}")
send_app_ctrl(Byref name, Byref key, Byref ctrl_name="", Byref winid=0)
{
	if (!(entry := glob_app(name))) {
		warn("app send ctrl key, but app [" name "] not regist")
		return 0
	}
	return ctrl_send_handle(entry, entry, key, ctrl_name, winid)
}

click_app_ctrl(Byref name, Byref ctrl_name="", Byref winid=0) 
{
	if (!(entry := glob_app(name))) {
		warn("app send ctrl key, but app [" name "] not regist")
		return 0
	}
	return ctrl_click_handle(entry, entry, ctrl_name, winid)
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
app_attr(Byref name, Byref item, Byref notip=false)
{
	if (!(entry := glob_app(name))) {
		warn("get app attr [" item "], but app [" name "] not regist")
		return 0

	} else if (!entry[item]) {
		if (notip) {
			return ""

		} else {
			warn("get app attr [" item "], but app [" name "] attr [" item "] not exist")
			return ""
		}
	}
	return entry[item]
}

app_stat(Byref name, Byref handle)
{
	if (!(winid := app_winid(name))) {
		app_log("get app stat by handle [" handle "], but app [" name "] not exist")
		return 0
	}
	return handle.(winid)
}

app_winid(Byref name, Byref run="")
{
	entry := glob_app(name)
	return get_winid(entry, run)
}

app_attach_winid(Byref name, Byref winid, Byref run="")
{
	if (!(entry := glob_app(name))) {
		warn("app attach winid, but app [" name "] not regist")
		return 0
	}
	default(run, entry)

	if (!run.winid) {
		run.winid := winid
		app_log("app attach winid, set winid as " winid)
		get_winid(entry, run)
	}
	return 1
}

half_class(Byref entry)
{
	return InStr(entry.class, "*")
}

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
app_class(Byref name)
{
	return app_attr(name, "class")
}

app_exec(Byref name, Byref exec="") 
{
	return app_attr(name, "exec")
}

app_ctrl(Byref name, Byref ctrl="")
{
	entry := glob_app(name)
	default(ctrl, const("ctrl", "name"))
	return entry[ctrl]
}

;--------------------------------------------------------------------------------------
if_app_actived(Byref name, Byref winid=0)
{
	default(winid, win_curr())
	return win_class(winid) == app_class(name)
}

;==============================================================================================================
;==============================================================================================================
global_applic()
{
	regist_applic_system()

	regist_applic_common()

	regist_applic_working()

	regist_applic_program()

	regist_applic_ahead()

	regist_applic_hotkey()

	regist_applic_cond()

	regist_applic_mapkey()
	
	return global_last("applic")
}

app_input_test()
{
	if (app("dir", "ddn")) {
		app_param(, "close", opt("final") "explore")
		app_assist("focus_ctrl")
	    regist_app("CabinetWClass", "DirectUIHWND3")
	}

	if (app("process", flag("alias_only")"pr")) {
		app_param(, , "procexp")
		regist_app("PROCEXPL")
	}

	if (app("vpn", flag("alias_only"))) {
		app_param(, , "OpenVPN", "openvpn-gui")
		regist_app(, , "OpenVPN - ")
	}
}

;==============================================================================================================
;==============================================================================================================
regist_applic_system()
{
	if (app("dir", flag("alias_only"))) {
		app_param(, "close", opt("final") "explore")
	    app_assist(flag("focus_ctrl"))
	    regist_app("CabinetWClass", "DirectUIHWND3")
	}

	if (app("console")) {
		app_path(, "C:\windows\system32\cmd.exe")
		regist_app("ConsoleWindowClass", , app_gbk("console"))
	}

	if (app("process")) {
		app_path("procexp", , flag("close_only"))
		regist_app("PROCEXPL")
	}

	if (app("dexpot")) {
		regist_app("ThunderRT6FormDC")
	}

	if (app("eyefoo", flag("alias_only"))) {
		app_path(, "eyefoo", flag("hide_only"))
		app_find_handle("find_exec_handle")
		regist_app()
	}

	if (app("idm")) {
		app_path("idm")
		regist_app(, , "Internet Download Manager")
	}

	;-----------------------------------------------------------------------------------
	; not work well 
;	if (app("netlimiter", flag("none_start"))) {
;		regist_app(, , "NetLimiter ")
;		app_switch("show|active", "hide|min")
;	}

	if (app("vpn", , "openvpn")) {
		app_path("OpenVPN", "openvpn-gui", flag("hide_only"))
		; use exec name, or title "OpenVPN" is ok
		app_find_handle("find_exec_handle")
		regist_app(, , "OpenVPN")
	} 

	if (app("shadowsocks")) {
		app_path(, "ShadowsocksR-dotnet4.0", flag("hide_only"))
		app_find_handle("find_exec_handle")
		regist_app()
	}

	;-----------------------------------------------------------------------------------
	if (app("goodsync", , "good")) {
		app_param(, "hide|min")
		regist_app(, , "GoodSync -")
 	}

	if (app("farr", , "find")) {
		app_param(, "hide|min", "Find and Run Robot")
		regist_app("TMainForm")
	}

	if (app("everything", flag("alias_only"), "search")) {
		app_param("show|active|max", "hide|min", "Search Everything")
		regist_app("EVERYTHING")
	}

	if (app("wintail", , "log")) {
		app_switch("show | max", "hide|min")
		app_assist(flag("active_always"))
		
		app_handle("active", "send_raw" sep("only"), "^{end}")
		regist_app(, "Afx:*", "Hoo WinTail -", log_path(true)) 
	}
}

;==============================================================================================================
;==============================================================================================================
regist_applic_common()
{
	if (app("notepad")) {
		;regist_app("Notepad", "notepad")
	}

	if (app("calc")) {
		app_param("show|active", "min|hide|close", A_WinDir "\\system32\\calc.exe")
		regist_app("ApplicationFrameWindow", , "Calculator")
	}
 
	if (app("simulator")) {
		app_param(, "hide|min")
		regist_app(, , app_gbk("simulator", "text"))
	}

	if (app("mumu")) {
		app_param("show|active", "min|hide|close") 
		regist_app("Qt5QWindowIcon", , app_gbk("mumu", "text"))
	}

	;---------------------------------------------------------------
	if (app("qq")) { 
	    regist_app("TXGuiFoundation", , "QQ")
	}

	if (app("weixin")) {
		app_param("show|active", "min|hide|close")
		regist_app("WeChatMainWndForPC" sep("logon") "WeChatLoginWndForPC")
	}

	if (app("thunder", , "download")) {
		app_param(, "hide|close")
		regist_app("XLUEFrameHostWnd", , app_gbk("thunder", "text"), "-StartType:PinStartMenu")
	}

	;flag("none_start|alias_only")
	if (app("foxit")) {
		app_path(reg_path("foxitreader"))
		app_assist(flag("focus_ctrl"))

		mode := 0
		if (mode == 0) {
			; we can set mode as match, or just ignore, in ctrl_find_mode, it will work
			app_ctrl_handle("ctrl_find_center_fetch")
			; classFoxitPhantomPersonal
			regist_app("classFoxitReader", "AfxWnd*")
			
		} else {
			; not work well, find AfxWnd003, but actual is AfxWnd006, focus success, but check focus failed
			;	should focus and retry
			app_ctrl_handle("ctrl_find_maxsize")
			regist_app("classFoxitReader", "AfxWnd")
		}
	}

	if (app("bazaar")) {
		;Book Bazaar Reader
		app_param("show|active", "none")
		app_assist(, "title|class")
		regist_app("ApplicationFrameWindow", "ApplicationFrameInputSinkWindow1", "Book Bazaar Reader")
	}

	if (app("chrome")) {
		app_path(opt("final") "chrome.exe", "chrome")
		app_assist(, "title|class")
		app_handle("focus_ctrl", "chrome_focus_handle")
		regist_app("Chrome_WidgetWin_1", "Chrome_RenderWidgetHostHWND*", "- Google Chrome") 
	}
	;---------------------------------------------------------------
	
	if (app("nutsync", prior(1))) {
		app_param(, "hide|min", , "NutstoreClient")
		regist_app("WindowsForms10.Window.8.app.0.134c08f_r6_ad1", , app_gbk("nutsync", "text"))
	}
	
	if (app("baidusync", , "sync")) {
		app_param(, "hide|min")
		regist_app("BaseGui", , app_gbk("baidusync", "text"))
	}

	if (app("360cloud")) {
		app_param(, "hide|min", "360WangPan")
		regist_app("360WangPanMainDlg")
	}
	;---------------------------------------------------------------

	if (app("ever")) {
		entry := glob_app(app())
	    ; entry.script := reg_path("YXScript")
	    path := parse_link(auto_link_path("ever" opt("next") "evernote"))
	    entry.script := file_path(path) "\ENScript.exe"
	    ; tips(entry.script, 5000)

	    entry.ctrl_list := "ENSnippetListCtrl*"
	    entry.ctrl_file := "ENAutoCompleteEditCtrl2"
	    auto_ctrl_handle("ctrl_list")

		const("ever", "assist", "goto_end" opt("next") "focus_ctrl")
		const("ever_si", "assist", "focus_ctrl")
		; set main frame as the default assist value; 
		;	no want to do this now
		;	set_assist(entry, const("en_flag"))
		set_assist(entry, "focus_ctrl")
		
		app_param("show|active", "min|hide", reg_path("Evernote"))
	    app_handle("active", "en_active_handle")
	    app_handle("deactive", "en_deactive_handle")

	    ; =========================================================
		mode := 1
		if (mode == 0) {	; old mode
			regist_app("ENMainFrame", "WebViewHost*")
			; ctrl math mode, only use default is mostly ok, but sometimes locate to WebViewHost1, not WebViewHost3
	    	app_ctrl_handle("ctrl_find_center_fetch")

		} else {
			;regist_app("ENMainFrame", "Intermediate D3D Window3")

			; actual is Chrome_WidgetWin_03, display "Intermediate D3D Window3"
			; regist_app("YXMainFrame", "Chrome_WidgetWin_03")	
			; regist_app("ENMainFrame", "Chrome_WidgetWin_03")
			;app_ctrl_handle("ctrl_find_center_fetch")
			; regist_app("YXMainFrame", "Chrome_RenderWidgetHostHWND2")	
			regist_app("YXMainFrame", "Chrome_WidgetWin_03")
			; regist_app("YXMainFrame", "Intermediate D3D Window3")
		}
		; =========================================================

	    if (app("ever_si", flag("none_start|alias_only"))) {
	    	; set this in all run 
			;app_switch(, , "top_front_none_min")
			app_handle("active", "en_active_handle")
			app_handle("deactive", "en_deactive_handle")
			;regist_app("ENSingleNoteView", "WebViewHost*")

			regist_app("ENSingleNoteView", "Chrome_RenderWidgetHostHWND1")
			; regist_app("ENSingleNoteView", "Chrome_WidgetWin_01")
		}
	}

	if (app("youd_note")) {
	    app_switch(, "hide")
	    regist_app("NeteaseYoudaoYNoteMainWnd", "Chrome_RenderWidgetHost*")
	}

	if (app("wiz")) {
	    app_param(, "hide|min")
	    regist_app("WizNoteMainFrame", "ATL:*")
	}

	if (app("youd_dict")) {
		app_switch(, "hide")
		app_handle("pre_active", "win_recover_record")
		app_handle("deactive", "win_recover_last")
		regist_app("YodaoMainWndClass", "RICHEDIT50W1")
	}

	;-----------------------------------------------------------------------------------
	if (app("netease", prior(2), "music")) {
		app_param(, "hide|min")
		regist_app("OrpheusBrowserHost", "Chrome_WidgetWin_01")	
	}

	if (app("foobar")) {
		app_param(, "hide", "foobar2000")
		regist_app(, , "foobar2000")
	}

	if (app("Kugou")) {
		app_param("", "hide|min")
		regist_app("kugou_ui", , app_gbk("kugou", "text"))
	}
	;-----------------------------------------------------------------------------------
}

;==============================================================================================================
regist_applic_working()
{
	if (app("word", flag("none_start|alias_only"))) {
		regist_app("OpusApp", "_WwG1")
	}

	if (app("ppt", flag("none_start|alias_only"))) {
		regist_app("PPTFrameClass", "- PowerPoint")
	}

	if (app("visio", flag("none_start|alias_only"))) {
		regist_app("VISIOA")
	}

	if (app("excel", flag("none_start|alias_only"))) {
		regist_app("XLMAIN")
	}

	if (app("outlook")) {
		app_param("show|max|active", "min", opt("final") "outlook.exe")
		app_assist(, "class|title")
		regist_app("rctrl_renwnd32", , "- Outlook")
	}

	if (app("dingding")) {
		app_param(, "min|hide")
		regist_app("StandardFrame", , app_gbk("dingding", "text"))
	}

	if (app("foxmail", flag("switch_mute"))) {
		app_param("show|max|active", "hide")
		;app_path(, "Foxmail")
		; if we hide and min foxmail, it will state in task bar, for the first time
		;	regist this, for when try to hide foxmail, use the system global hotkey for foxmail
		;app_hotkey("foxmail", "!f")
		regist_app("TFoxMainFrm.UnicodeClass")

	    ; start foxmail when not exist
	    if (0) {
	    	if (config("foxmail", "switch") == "mix") {
				app_handle("hide", "foxmail_hide_key")
			} 

		   	Hotkey, IfWinNotExist, ahk_class TFoxMainFrm.UnicodeClass
		    	app_hotkey("foxmail", "!o")
		 	Hotkey, IfWinNotExist
		 }
	}
}

	   
;==============================================================================================================
regist_applic_program()
{
	if (app("vmware")) {
		app_path("VMware Workstation")
		;app_assist(flag("focus_ctrl"))
		regist_app("VMUIFrame", "MKSEmbedded2")
	}

	if (app("UltraEdit")) {
		regist_app(, "EditControl5", "UltraEdit") 
	}

	if (app("sublime")) {
		app_path("sublime_text")
		regist_app("PX_WINDOW_CLASS")
	}

	if (app("vscode")) {
		app_path("code")
		; regist_app("Chrome_WidgetWin_1", "Chrome_RenderWidgetHostHWND1", "- Visual Studio Code", "--extensions-dir ""D:\Workspace\Cache\.vscode\extensions"" ")
		regist_app("Chrome_WidgetWin_1", "Intermediate D3D Window1", "- Visual Studio Code", "--extensions-dir ""D:\Workspace\Cache\.vscode\extensions"" ")
	}

	if (app("freeplane")) {
		app_param("show|active", "hide|min")
		regist_app("SunAwtFrame", , app_gbk("freeplane", "text")) 
		regist_sub("freeplane_dialog", "SunAwtDialog") 	
	}

	if (app("xiaoshujiang")) {
		regist_app("Chrome_WidgetWin_0", "Chrome_RenderWidgetHostHWND1")
	    ;app_switch(, "hide")
	}

	;-------------------------------------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------------------------------------
	if (app("eclipse", , "java")) {
		regist_app("SWT_Window0", "SWT_Window", "- Eclipse")
		app_ctrl_handle("ctrl_find_center")
	}

	if (app("cpp")) {
		app_path("eclipse_c++")
		regist_app("SWT_Window0", "SWT_Window", "- Eclipse")
		app_ctrl_handle("ctrl_find_center")
	}

	if (app("scala")) {
		app_path("eclipse_scala")
		regist_app("SWT_Window0", "SWT_Window", "- Scala IDE")
		app_ctrl_handle("ctrl_find_center")
	}

	;-------------------------------------------------------------------------------------------------------------
	;-------------------------------------------------------------------------------------------------------------
	if (app("idea", , "intellij idea")) {
		app_path("IntelliJ IDEA")
		regist_app("SunAwtFrame", , "- IntelliJ IDEA")
	}

	if (app("pycharm", prior(1))) {
		app_path("pycharm")
		regist_app("SunAwtFrame", , "- PyCharm")
	}

	if (app("clion")) {
		regist_app("SunAwtFrame", , "- CLion")
	}

	if (app("goland")) {
		regist_app("SunAwtFrame", , "- GoLand")
	}

	if (app("git")) {
		; app_path("Git Bash")
		; regist_app("ConsoleWindowClass", , "MINGW32") 
		app_path("git-bash")
		regist_app("mintty", , "MINGW64") 
	}

	if (app("gitbook", flag("alias_only"), "gbook")) {
		app_path("GitBook Editor")
		app_assist(, "title")
		regist_app(, , "GitBook Editor")
	}

	if (app("compare", , "BeyongCompare")) {
		app_path("BCompare")
		regist_app("TViewForm.UnicodeClass")
	}

	if (app("xshell")) {
		app_path(reg_path("xshell"))

		; set start wait
		app_switch(, , , 2)
		app_assist(flag("focus_ctrl"), flag("title"))

		; note: main ctrl chanage for different tab
		;regist_app("Xshell::MainFrame*", "AfxFrameOrView*", "- Xshell 5")
		regist_app(, "AfxFrameOrView*", "Xshell 5")
		; force use find center, if use auto match, sometimes failed
		app_ctrl_handle("ctrl_find_center_fetch")
		; ctrl name maybe change
		app_ctrl_muttable()

		assert(assist(glob_app(app()), "focus_ctrl"), A_ThisFunc ":" A_LineNumber)
	}

	if (app("heidisql")) {
		app_path("heidisql")
		regist_app("TMainForm!dx", "TSynMemo1")
	}

}

;===================================================================================================================================
;===================================================================================================================================

; some must set ahead
regist_applic_ahead()
{
	; do this before regist foxmail app_exist_switch
	app_active_map("xshell", "<!o, >!o")
}

regist_applic_hotkey()
{	
hotkey_prefix("app", "start")	
	app_hotkey("process", "p")
	app_hotkey("wintail", "l")
	app_hotkey("thunder", "t")
	
	;app_hotkey("netlimiter", "n")
	app_hotkey("sublime", "s")
	app_hotkey("vscode",  "v")
	app_hotkey("eclipse", "e")
	app_hotkey("compare", "b")
	app_hotkey("xshell",  "x")
	app_hotkey("git", 	  "g")
	app_hotkey("foxmail", "o")
	app_hotkey("dingding","i")
	app_hotkey("heidisql","h")
	app_hotkey("everything","<#f")

	handle_list("[n] switch_app(nutsync) || close_app(nutsync)" sep("time") 0.3)

	;app_hotkey("nutsync", "n")
	;app_exist_switch("v", "vmware")
hotkey_prefix(0)	

;=============================================
hotkey_prefix("app", "common")
	app_hotkey("ever", 		"d")
	app_hotkey("chrome", 	"c")
	bind_last_handle("open_readme")

	; app_exist_switch("#c",	"console")
	app_exist_switch("x", 	"xshell")
	app_exist_switch("r", 	"foxit | bazaar")
	app_exist_switch("<!o|>!o", "outlook | foxmail")

	app_exist_switch("m", 	"netease| kugou | mumu")
	app_exist_switch("w", 	"word | ppt | visio | excel | dir | wiz")
	app_exist_switch("v", 	"visio")
	app_exist_switch("s", 	"vscode | sublime | baidusync")
	app_exist_switch("f", 	"freeplane")

	app_exist_switch("e", 	"eclipse | clion | idea | goland | pycharm | scala")
	app_exist_switch("g", 	"goodsync | git | gitbook")
	app_exist_switch("i", 	"dingding")
	app_exist_switch("h", 	"heidisql")
	;app_exist_switch("n",	"nutsync")
	;app_exist_switch("b",	"baidusync")
hotkey_prefix(0)
}

;===================================================================================================================================
;===================================================================================================================================
regist_applic_cond()
{
	regist_evernote()

	; use [^+x] -> change_single_auto to change another single note
	app_exists("ever_si", 	"[<!z | <!x] 	switch_single_auto")
	app_exists("xshell", 	"[<!z] 			switch_single_auto")

	;-----------------------------------------------------------
	app_exists("foxmail",	"[#d]  	foxmail_minimize(#d)")
	app_active("foxmail", 	"[Esc] 	foxmail_minimize")
	
	;-----------------------------------------------------------
	;-----------------------------------------------------------
	app_exists("foxit",  	"[<!^r] en_chrome_url") 
	app_exists("chrome", 	"[<!r]  en_chrome_url")
	app_active("chrome", 	"[<!v]  en_chrome_link(false, true)"

					   , 	"[<!b]  en_chrome_link(true, true)"
					   , 	"[<!+b] en_chrome_link(true, false)")
	;-----------------------------------------------------------
	;-----------------------------------------------------------
	; use control-space, will copy text to youd_dict 
	;	when youd_dict active, control-space will clear text in youd_dict
				handle_list("[>!L]	switch_youd_dict")
	app_exists("youd_dict", "[<!Y] 	switch_youd_dict(true)"
						; fast entry for copy current text and translate in youd_dict
				  		  , "[LCtrl & space]	switch_youd_dict(true, true)"
						  ;, "[~LShift] " sep("next") " switch_youd_dict(true, true)" sep("time") 0.15

						  ,	"[<^!\] tips(switch dictionary) " sep("comb") " send_raw(^+8^+9)")

	; app_active("youd_dict", "[Esc] 	switch_app(youd_dict)"
	; 					  ; clean the input
	; 					  , "[LCtrl & Space] youd_dict_clean" 
	; 					  , "[~LShift]	" sep("next") " youd_dict_clean")
	;-----------------------------------------------------------
	;-----------------------------------------------------------
	app_exists("visio", 	"[^+v] paste_plain")

	app_active("freeplane", "[^+v] paste_plain"
						  , "[F1]  tips(nothing)")
	app_active("freeplane_dialog", "[^+v] paste_plain")

	;-----------------------------------------------------------
	;-----------------------------------------------------------
	; usage:
	; 	1. defualt: foxit_mouse force straight line, use vim mode
	; 	2. comment: ^F1, ^F2, (seed foxit_single_underline), will close vim mode for enter any text
	; 	3. draw: use F1, will resume straight line mode
	;
	; switch:
	; 	1. straight line: F1 open; other close;
	; 	2. vim mode pause: ^F1, ^F2 pause; other open (when complete comment, use F1 or other to reopen)
	;   3. switch two: <+F1 
	app_active("foxit",  	"[LALT & LButton] 	foxit_mouse(drag, true)"
					  ,  	"[LWIN & LButton] 	foxit_mouse(drag)"
					  ,		"[LShift & LButton] foxit_mouse(dest)"

					  ; this will Interrupt space function of page down, ignore
					  ;,	"[Space & LButton] 	foxit_mouse(step)"
					  ,		"[<!v] 	 			foxit_mouse(step)"
					 	
					  ; switch straight line and vim mode, these two will be the same status
					  ;		always use this for switch
					  ,		"[<+F1]				foxit_mouse_vim_switch")
					  ; no need this, which will make it more complex
					  ;,		"[F7]				foxit_single_underline"

					  ; sometimes, just focus not work, focus send click to ctrl
					  ; 	not use this, or j will not continuous triggered
					  ; ,		"[j & k]			foxit_focus_handle(true)")
	foxit_single_underline(false)
}

regist_applic_mapkey()
{
	; use win + 1 for change desktop, override windows shortcut
	app_exists_map("dexpot", 	"#1/^+{1}, #2/^+{2}")

	app_active_map("xshell", 	"<^L, !1, !2, !3, !4, !5, !6, !7, !8, !9")
	app_active_map("xshell", 	"<!U/sh push`n, <!L/sh pull`n, !^f/^+f")
	app_active_map("git", 		"<!U/sh push`n, <!L/sh pull`n")

	app_active_map("foxit", 	"F1/^{F1}, ^F11/{F11} {F5} !6")	; full screan, two page, then use select mode
	app_active_map("freeplane", "<^<!c, <!<+E, <^!left, <^!right, <^<!up, <^!down")
	app_active_map("freeplane_dialog", "!o, <!c")

	app_active_map("ever", 	  	"<^Tab/^m, <^<+Tab/^+m, <+F10/{F10} {F11}")
	app_active_map("ever_si", 	"<^Tab/^m, <^<+Tab/^+m")

	app_active_map("bazaar", 	"space/right, +space/left, ctrl/right, alt/left")
}

;====================================================================
;====================================================================
regist_example()
{
	; left side use <> or not, right side use <> or note
	app_active_map("dir", 	"<!1/<^{end},  !2/^{home}")
	app_exists_map("dir", 	"<!1/<^{home}, !2/^{end}")
	
	;=========================================================================
	;=========================================================================
	; regist hotkey and serial
	handle_list("[!3 | work] tips(hotkey and serial)"
			; use dual, and handle count < htokey count
			,	"[!4]		tips(4) || tips(double 4)" sep("time") 0.7)

hotkey_prefix("app", "common")
	handle_list("[8]		tips(single hotkey)"
			; even single char, also use serial mode, that is use ctrl-shift-r
			,	"[q]		tips(single serial) " sep("serial")
			,	"[111]		tips(use digit that input can't use, 3000)"
			,	"[H]		tips(use Upper case)" sep("serial")
			,	"[Pi]		tips(use Upper case)"
			,	"[po+-pp]	tips(use shift in the middle)" sep("serial"))
	serial_mapkey("U/^{end}")
hotkey_prefix(0)

	; regist hotkey and inpput
input_type("run")
	handle_list("[example]	tips(example)" sep("help") "it is a help message")
	; here contain digital, should use /t1 /t2 to triggers
	handle_list("[t1 | t2]	tips(example)" sep("help") "t1 help " sep("next") " tips(t2, 5000)" sep("help") "t2 help")

	; more than one input, mapped to same handle
	handle_list("[aa3 | aa4 | aa5] tips(many)" sep("help") "many")

	; one input, trigger more than one handle
	handle_list("[multi] 	tips(multi1)" sep("help") "three handle" sep("comb") "tips(multi2)" sep("comb") "tips(multi3)")
input_type(0)

	;=========================================================================
	;=========================================================================
input_type("ever")
	; help messasge set in set_note to entry.help, then in regist_input, param help will empty, keep help message in entry.help
	note_list("[ibn] 	 	0@@Inbox/" sep("help") "help message")
	; help message split in parse_handle, and set help message in handle_list/regist_input()
	;note_list("[abc|ddc|bb] +calendar(+single|single_hide)" sep("help") "help message")
input_type(0)

	;------------------------------------------------------------------------
	;------------------------------------------------------------------------	
	note_list("[!g|ibn] 	0@@Inbox/" sep("help") "help message")
	note_list("[abc|ddc|bb] Read+read(+single|single_hide|single_always)")

	;=========================================================================
	;=========================================================================
	; when input more than 3 char, will show option
	link_list("[mdouban]	movie.douban.com"
			, "[douban]     movie.douban.com"
			, "[doubenben]  www.toutiao.com"	
			, "[doubset]    www.toutiao.com"	
            , "[toutiao]    www.toutiao.com")

input_type("path")
	user_home := "C:\Users\" A_UserName
	dir_list("[long1] 		" user_home sep("real") "Long" sep("help") "my home1" sep("real") "lOnG")
	; locate to appdata, set help messasge like this
	dir_list("[!5 | long2] 	" user_home sep("real") "Long" help("my home2") sep("move") "AppData")
input_type(0)

input_type("run")
	; set help messasge like this
	exec_list("[remote]		R-Desktop" help("desktop computer"))
input_type(0)

	;=============================================================================================================
	;=============================================================================================================
	; batch rename file, if want set with gbk, use shift + insert for copy
	;dating_files("create" opt("test"))

	; add hour min secode
	;dating_files("create" sep("precise") opt("test"))

	;rename_files("heads", sep("precise"))

	;=============================================================================================================
	;=============================================================================================================
	; dync set types
	; dir  input: dir file link, or set/del
	; ever input: note book tags, or set/del
	; serial    : dir file link note book tags, or set/del

	; we can set more than item as key, !k and serial "kafka" will tirgger note
	; [evernote]
	; kafka | <!k=1 Kafka/

	;=============================================================================================================
	;=============================================================================================================
	; bind to last regist hotkey, input, serial
	bind_last_handle("tips", , "start remote")		

	; bind more with exist handle, locate it by hotkey, input, serial. prev or next
	bind_last_hotkey("chrome", 	"tips", , "111")

input_type("run")
	; bind handle with param instruct
	regist_hotkey("!u", 		"bind_handle_input", "input string", "tips")

	; bind a new handle with bind_handle_input
	handle_list("[tips_input]	bind_handle_input(input string, tips)" help("tips input value"))
input_type(0)

	;=============================================================================================================
	;=============================================================================================================
	; 1) regist delay regist handle; used when handle param contain ',', while can't use delay_handle_list
input_type("run")			  
	; 1. regist with abc_test, 2. active foxit, enter !b, 3. move mouse 
	regist_input("abc_test", "", "app_active", "foxit", "[<!b] mouse_action(drag, true)")

	; 2) see delay_handle_list
	delay_handle_list("abc_delay", "display delay info when trigger", "show in help"
    		; handle means config("handle", "rightly"), trigger rightly
    		,	"[handle]	tips(right now)",
    		,	"[bbq_test]	tips(delay registed success)")
input_type(0)


	;=============================================================================================================
	;=============================================================================================================
	; erase input
	; erase_input(Byref group, Byref name)
	; erase_hotkey

	key1 := "!7"
	regist_hotkey(key1, "tips", "1")
	erase_hotkey(key1)

	key2 := "!8"
	app_active("foxit", "[" key2 "] tips(8)")
	erase_hotkey(key2, "active", "class", , "FoxitReader")

	key3 := "!9"
	app_exists("foxit", "[" key3 "] tips(9)")
	erase_hotkey(key3, "exist", "class", , "FoxitReader")
}
