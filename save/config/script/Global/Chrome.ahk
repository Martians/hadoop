
#include Library/UriEncode.ahk

if_url(Byref string)
{
    return RegExMatch(string, "^(https?://|www\.|)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$")
}

chrome_link(ByRef title, Byref link)
{  
    winid := app_winid("chrome")
    if (!if_active(winid)) {
        tips("active chrome")
        winid := switch_app("chrome", "mode_show")
    }

    if (!title := chrome_title(winid)) {
        tips("can't get title")
        return false
    
    } else if (!(link := chrome_url())) {
        tips("can't get url")
        return false
    }

    app_log("chrome title [" title "], url [" link "]")
    return true
}

chrome_title(Byref winid)
{
    entry := glob_app("chrome")
    erase := entry.title
    while (count++ < 5) {
        ; get select text
        if (get_clip(0.2) && !contain_one_line(clipboard, "http")) {
            title := clipboard 
            app_log("chrome title, get select text [" title "]")

        } else {
            title := win_title(winid)
            StringReplace, title, title, %erase%, , All
        }

        if (title) {
            title := trim(title)
            app_log("get chrome title [" title "]")
            return title
        } else {
            sleep 100
            app_log("chrome title, try [" count "]")
        }
    }

    tips("cannt get title")
    return ""
}

chrome_url()
{
    clip_clear()

    count = 0
    while (count++ < 5) {
        SendEvent, {F6}
        SendEvent, ^{l}
        sleep 100
        SendEvent, ^{ins}

        Clipwait, 1

        if (strlen(Clipboard) > 0) {
            break
        }
        app_log("get chrome url, try [" count "]")
    }

    if (strlen(Clipboard) > 0) {
        url := Clipboard
        if (!if_prefix(url, "http")) {
            url := "http://" url
        }
        app_log("chrome url, get url [" url "]")
    }
    return url
}

chrome_focus_handle()
{
    send {^L}
    sendinput {F6}
    send {F6}

    return 1
}
;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
select_url(Byref type, Byref path, Byref error="")
{
    if (if_app_actived("chrome")) {

        if (chrome_link(title, path)) {
            app_log("select url, current url [" path "]")
            return 1
        }
        error := "nothing selected"

    } else {
        error := "current not " type
    }
    app_log("select url, " error)
    return 0
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
chrome_open(Byref url, Byref select=false, Byref prefix="")
{
    ;win_key(0, true)
    if (select && get_clip(0.1, 2)) {
        ;StringReplace, link, Clipboard, `r`n, %A_SPACE%, All
        ;transform, link, html, %Clipboard%
        link := uri_encode(Clipboard)
        link := url "/" prefix link
        
    } else {
        link := url
    }
    execute_path("chrome.exe", link)
}

chrome_open_clip()
{
    if (if_url(Clipboard)) {
        execute_path("chrome.exe", Clipboard)
        app_log("chrome open clip, open clipboard link [" Clipboard "]")

    } else {
        if (get_clip(0.1, "line")) {

            if (if_url(Clipboard)) {
                execute_path("chrome.exe",  Clipboard)
                app_log("chrome open clip, copy link [" Clipboard "]")

            } else {
                tips("not url")
            }
        } else {
            tips("nothing")
        }
    }
    Clipboard := ""
}

;=======================================================================
;=======================================================================
open_url(Byref name, Byref key, Byref url, Byref select=false)
{
    ;regist_hotkey(key, "execute", url)
    default(name, key)

    entry := set_handle(entry, "chrome_open", url, select)
    if (name != Key) {
        regist_serial(name, "", entry)
    }

    if (key) {
        regist_hotkey(key, entry)
    }
}

dync_link(Byref type, Byref name, Byref path)
{
    ; should not conflict
    if ((array := dync_name(type, name, -2))) {
        warn("set type [" type "] path, but name [" name "], already registed in type [" array.dync_type "]")
        return 0
    }
    entry := dync_name(type, name, 1)
    entry.path := path
    entry.help := link_help(path)

    entry := set_handle(entry, "chrome_open", path)
    app_log("set link, type [" type "] name [" name "], help " entry.help)
    return entry
}

link_help(Byref path, Byref suffix=true)
{
    if (RegExMatch(path, "(.*//)*(www.)*([^.]*)(\..*[^./])*", out)) {
        ;log(out1 ", " out2 ", " out3)
        help := out3 (suffix ? out4 : "")

    } else {
        warn("link help, can't get link help, path [" path "]")
        help := path
    }
    return "[" help "]"
}

;------------------------------------------------------------------------
;------------------------------------------------------------------------
link_list(Byref arg*)
{
    extend_handle_list("en_url_handle", arg*)
}

en_url_handle(Byref hotkey, Byref option, Byref handle, Byref param*)
{
    help := link_help(handle)

    set_handle(entry, "chrome_open", handle, param[1], param[2])
    entry.help := help
    return entry
}

;-------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------
open_readme()
{
    ; open readme link every day once
    if (record_config("readme")) {
        chrome_open("http://readfree.me/")
        SetTimer, readme_label, 5000
    }
    return

readme_label:
    chrome_open("http://readfree.me/")
    SetTimer, readme_label, off
    return
}   

;=======================================================================
;=======================================================================
global_applic_urls()
{
input_type("path")
    ;open_url("baidu",   "#b", "www.baidu.com")
    link_list("[#b | #space | baidu] https://www.baidu.com(true, s?wd=)"
            , "[#g | google]         www.google.com.hk(true, search?q=)"
            , "[#t | translate]      translate.google.cn/#en/zh-CN(true)")
    
    handle_list("[#!c]               chrome_open_clip")
input_type(0)
}
