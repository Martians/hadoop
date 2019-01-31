
global_define_gbk()
{
    set_app_gbk("console",    "C:\windows\system32\cmd.exe")
    set_app_gbk("qq",         "腾讯QQ")
    set_app_gbk("weixin",     "微信")
    set_app_gbk("thunder",    "迅雷")
    set_app_gbk("thunder",    "迅雷", "text")
  
    ;------------------------------------------
    set_app_gbk("nutsync",    "坚果云")
    set_app_gbk("nutsync",    "坚果云", "text")
    set_app_gbk("dingding",   "钉钉")
    set_app_gbk("dingding",   "钉钉",   "text")
    set_app_gbk("baidusync",  "百度网盘")
    set_app_gbk("baidusync",  "网盘",   "text")
    set_app_gbk("youd_note",  "有道云笔记")
    set_app_gbk("youd_dict",  "有道词典")
    set_app_gbk("wiz",        "为知笔记 Wiz")
    
    ;------------------------------------------
    set_app_gbk("xiaoshujiang", "小书匠")
    set_app_gbk("Kugou",      "酷狗音乐",  "text")
    set_app_gbk("netease",    "网易云音乐")
    set_app_gbk("simulator",  "腾讯手游助手", "text")
    set_app_gbk("mumu",       "MuMu模拟器", "text")

    set_app_gbk("freeplane",  "思维导图",  "text")
    set_gbk("dir",  "new",    "新建文件夹")
    set_gbk("dir", "desktop", "桌面")

    ;------------------------------------------
    set_gbk("font", "yahei",  "微软雅黑")
    set_app_gbk("ever",       "点这里添加",   "sep_tags")
    set_app_gbk("ever",       "查看全部笔记", "sep_note")
    set_app_gbk("ever",       "记录",     "record")
    set_app_gbk("ever",       "笔记",     "note")
    set_app_gbk("ever",       "项目",     "project")
    set_app_gbk("ever",       "将来[/]也许", "future")
    set_app_gbk("ever",       "系统",     "config")
    set_app_gbk("ever",       "微信",     "weixin")
    set_app_gbk("ever",       "印象笔记", "title")
    set_app_gbk("ever",       "1@研发管理", "R&D")
}

fix_path(Byref type, Byref suffix) {
	dir := glob_sure("glob",  "const",   "dir")

    if (type == "book") {
        base := dir.book

    } else if (type == "work") {
        base := dir.work

    } else if (type == "mind") {
        base := dir.mind
    
    } else if (type == "code") {
        base := dir.mind
    }
    return base "\" suffix
}

;------------------------------------------------
regist_dir_path()
{
    dir := glob_sure("glob",  "const",   "dir")

    ;-------------------------------------------------------------------------------------------------------------
    ; ahk support
    dir.output  := const("system", "workd") "Output"
    dir.sapp    := const("system", "home") "Desktop\App"
    dir.stool   := const("system", "home") "Desktop\Tool"

    ;-------------------------------------------------------------------------------------------------------------
    ; base directory
    dir.work    := "D:\工作\0 时间"
    dir.book    := "E:\资料\book"
    dir.info    := "E:\资料"

    dir.mind    := "D:\工作\脑图"
    dir.code    := "D:\Workspace\local"

    ;-------------------------------------------------------------------------------------------------------------
    ; work directory
    dir.nimblex := fix_path("work", "1 BigData\2017-09-01 Nimblex")
    dir.project := fix_path("work", "1 BigData\2017-09-05 Project")
    dir.manage  := fix_path("work", "2 管理")
    
    dir.data_mind := fix_path("mind", "0 Data\0 BigData\2016-01-30 Hadoop")

    ;-------------------------------------------------------------------------------------------------------------
    ; book
    dir.hadoop  := fix_path("book", "0 BigData\Ecosystem")
    dir.block   := fix_path("book", "Subjects\BlockChain")


    ;-------------------------------------------------------------------------------------------------------------
    ; application
    dir.tool    := "F:\Tool"
    dir.sync    := "E:\我的坚果云"
    dir.read    := "E:\我的坚果云"
    dir.thunder := "E:\迅雷下载"
    dir.wallpaper := "D:\Program Files\Wallpaper\Local"

    ;-------------------------------------------------------------------------------------------------------------
    ; system
    dir.system  := const("system", "home") "System"
    dir.drivers := "C:\Windows\System32\drivers\etc"

    user_home   := "C:\Users\" A_UserName
    dir.home    := user_home sep("real") "Long"
    dir.desk    := A_Desktop sep("help") gbk("dir", "desktop") sep("real") gbk("dir", "desktop")
    dir.startup := A_Startup
    dir.explore := "`:`:{20D04FE0-3AEA-1069-A2D8-08002B30309D}" sep("real") "此电脑" sep("help") "我的电脑"

    dir.download := user_home "\Downloads" sep("real") "下载"
    dir.document := A_MyDocuments
    dir.recently := user_home "\AppData\Roaming\Microsoft\Windows\Recent"

    dir.local    := "D:\Workspace\local"
}

regist_file_path()
{
    file := glob_sure("glob",   "const",  "file")

    ;-------------------------------------------------------------------------------------------------------------
    ; ahk support
    file.config := global_path("config")
    file.serial := const("system", "config") "Serial.ini"
    file.input  := const("system", "config") "Input.ini"
    file.snippet    := const("system", "config") "Snippet.ini"
    
    ; for fast collect
    fast := sure_item(file, "fast")
    fast.collect := file_log_path("collect")
    fast.record := file_log_path("record")

    ;-------------------------------------------------------------------------------------------------------------
    ; ahk help
    ahk_home    := "F:\Tool\Advance\Efficiency\AutoHotKey\"
    file.help   := ahk_home "AutoHotkey Help 1.1.15.03.chm"
    file.spy    := ahk_home "AU3_Spy.exe"
    file.game_war := "D:\Program Files (x86)\Holdfast\platform 6.0.0\GameClient.exe"

    ;-------------------------------------------------------------------------------------------------------------
    file.dictionary := A_ScriptDir "\Dictionary.ahk"

    ;-------------------------------------------------------------------------------------------------------------    
    ; system
    file.hosts   := "C:\Windows\System32\drivers\etc\hosts"

     ;-------------------------------------------------------------------------------------------------------------
    ; mind file
    file.Promote := fix_path("mind", "1 Person\0 Promote\2017-09-20 Pomote.mm" help("promte mind"))
    file.study   := fix_path("mind", "1 Person\0 Promote\2017-10-31 Study.mm"  help("study method"))
    file.learn   := fix_path("mind", "0 Data\0 BigData\2016-03-28 Concept\2017-02-10 Data-Learn.mm"  help("learn data stack"))
}

global_path(Byref name, Byref sub="")
{
    file := glob_sure("glob", "const", "file")
    default(name, "config")

    ; first config, should hard code
    if (name == "config") {
        return file_path(A_ScriptDir) "\Config.ini"

    } else {
        return get_item(file, name, sub)
    }
}

set_gbk(Byref level, Byref index, Byref value, Byref type="")
{
    gbk := glob_sure("glob",  "const",   "gbk")

    curr := sure_item(gbk, level)
    if (curr[index type]) {
        warn("gbk " level "-" index "-" type " already exist")
    }
    curr[index type] := value
}

gbk(Byref level, Byref index, Byref type="", Byref tip=true) 
{
    gbk := glob_sure("glob",  "const",   "gbk")
    if (type) {
      if (!gbk[level][index type]) {
    		if (tip) {
    			warn("no gbk " level "-" index "-" type)
    		}
    		return 0
    	}
    	return gbk[level][index type]

    } else {
    	if (!gbk[level][index]) {
    		if (tip) {
    			warn("no gbk " level "-" index)
    		}
    		return 0
    	}
    	return gbk[level][index]
    }
}

;------------------------------------------------
set_app_gbk(Byref index, Byref value, Byref type="")
{
	set_gbk("app", index, value, type)
}

app_gbk(Byref index, Byref type="", Byref tip=true)
{
	return gbk("app", index, type, tip)
}

global_code_snippet()
{
    code := glob_sure("glob", "const",  "code")
    
    string=
(
    if () {

    }
)   code.if := string

string=
(
    if () {

    } else {

    }
)   code.ie := string


    string=
(
    if () {

    } else if {

    } else {

    }
)   code.elif := string

}

