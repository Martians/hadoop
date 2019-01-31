
;===============================================================================================
;===============================================================================================
snippet_entry(Byref name="")
{
    array := glob_sure("glob", "Snippet", "code")
    if (name) {
        return array[name]
    } else {
        return array
    }
}

set_snippet(Byref name, Byref code)
{
    if ((entry := get_serial(name))) {
        if (entry.work == "snippet") {
            info("set snippet, but serial [" name "] already exist, del old one", 3000)
            ; del serial will autmotely load del_snippet
            erase_serial(name)

        } else {
            info("set snippet, but serial [" name "] already regist with work <" entry.work ">, ignore", 3000)
            return 0
        }
    }
    move := get_option(code, sep("move"))
    code := del_option(code, sep("move"))

switch("serial_work", "snippet") 
    ; add code snippet to serial
    regist_serial(name, "", "paste_snippet" sep("cycle") "del_snippet", name)
switch("serial_work", 0) 

    array := snippet_entry()
    entry := sure_item(array, name)
    entry.code := code
    entry.move := move_direction(move)

    ;sys_log("set snippet [" name "] `n" array[name])   
}

del_snippet(Byref name)
{
    del_config(name, section("common"), fileini("snippet"))

    sys_log("del snippet, name [" name "]") 
}

move_direction(Byref string)
{
    string := regexreplace(string, "(([LRUD][0-9]))", "{$1}")
    string := regexreplace(string, "L", "left ")
    string := regexreplace(string, "R", "right ")
    string := regexreplace(string, "U", "up ")
    string := regexreplace(string, "D", "down ")
    return string
}

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
copy_snippet()
{
    if (get_clip(0.2)) {
        if (get_input(name, Clipboard)) {
            if (set_snippet(name, Clipboard)) {
                code := convert_line_feed(Clipboard, true)
                set_config(name, code, section("common"), fileini("snippet"))
            }
        }
    } else {
        tips("nothing select")
    }
}

paste_snippet(Byref name)
{
    if ((entry := snippet_entry(name))) {
        paste(entry.code, , true, true)

        if (entry.move) {
            move := entry.move
            sendinput %move%
        }
        sys_log("paste snippet, `n" entry.code)
        return 1

    } else {
        tips("no snippet [" name "]")
        return 0
    }
}

paste_snippet_plus(Byref name, Byref hotkey="{Enter}")   ;{Home}
{
    if (paste_snippet(name)) {
        send_raw(hotkey)
    }
}

;========================================================================
;========================================================================

global_define_snippet()
{
    define_const_snippet()

    load_static_snippet()

    load_dynamic_snippet()

    define_edit_comment()
}

load_dynamic_snippet()
{
    list := list_config(section("common"), fileini("snippet"))
    for name, item in list
    {
        set_snippet(name, convert_line_feed(item, false))
        ;wait()
    }
}

load_static_snippet()
{
    array := glob_sure("glob", "const", "code")
    for name, item in array
    {
        if (item) {
            set_snippet(name, convert_line_feed(item, false))
            ;app_log("load const snippet, name [" name "], item `n" item)

        } else {
            info("load const snippet, name [" name "], but not set", 3000)
        }
    }
}

define_edit_comment()
{
    app_active("sublime"
            ,  "[<^<!L]     paste_snippet_plus(less_line)"
            ,  "[<^<!M]     paste_snippet_plus(more_line)")
}

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
define_const_snippet()
{
    code := glob_sure("glob", "const",  "code")
    
string=
(
    if () {

    }
)  
    code.if := string sep("move") "L1U2R4"
    
    string=
(
    if () {

    } else {

    }
)   
    code.ie := string

    string=
(
    if () {

    } else if {

    } else {

    }
)   
    code.elif := string
;-------------------------------------------------------------------------------------------------------------

    string=
(
export ftp_proxy="ftp://192.168.0.90:1080/"
export http_proxy="http://192.168.0.90:1080/"
export https_proxy="https://192.168.0.90:1080/"
export socks_proxy="socks://192.168.0.90:1080/"
export all_proxy="socks://192.168.0.90:1080/"

)   
    code.proxy := string

    string=
(
export -n ftp_proxy
export -n http_proxy
export -n https_proxy
export -n socks_proxy
export -n all_proxy

)   
    code.cancel_proxy := string

    code.less_line := ";-------------------------------------------------------------------------------------------------------------"
    code.more_line := ";============================================================================================================="
}

;=============================================================================================================
;=============================================================================================================
format_review(Byref string)
{
    static prefix :=
    static suffix :=
    
    if (!prefix) {
        prefix=
(
/**
 * reviewed by liudong 
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

send_review()
{
    format_review(string)
    paste(string, , true)
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
    string := prefix " " line suffix
}

send_python() {
    if (master_dual(0.15)) {
        paste("''' '''", , true)
        sendinput {left 3}
        sendinput {enter}
        sendinput {up} 
        sendinput {right 4}

    } else {
        ; paste("# ", , true)
        paste(""""""" """"""", , true)
        sendinput {left 3}
        sendinput {enter}
        sendinput {up} 
        sendinput {right 4}
    }
}

send_rust() {
    
    if (master_dual(0.15)) {
    
        if (0) {
            ; format_comment(string, " ")
            ; paste(string, , true)
            ; sendinput {left 3}

            ; sendinput {enter}   
            ; sendinput *{space} 
            ; sendinput {enter}   
            ; sendinput {up} 
            ; sendinput {right 2}

            format_comment(string, " * ")
            paste(string, , true)
            sendinput {left 5}

            sendinput {enter}   
            sendinput {right 2}
            sendinput {enter}   
            sendinput {up} 
            sendinput {right 1}

        } else {
            string := "///"
            paste(string, , true)
        }

    } else {
        ; format_comment(string, " ")
        ; paste(string, , true)
        ; sendinput {left 3}
        string := "//"
        paste(string, , true)
    }

    sendinput {alt up} {ctrl up}
}

send_comment(function=false)
{
    if (InStr(win_title(), ".py")) {
        send_python()
        return
    
    } else if (InStr(win_title(), ".rs")) {
        send_rust()
        return
    }
    
    ; other Language, C++ Java ...
    if (master_dual(0.15)) {
        send_one_line()
    } else {
        send_multi()
    }
}

send_one_line() {
    format_comment(string, "")
        log(string)
        paste(string, , true)
        sendinput {left 3} {ctrl up}
        ;sendinput {end}
}

send_multi() {
    if (0) {
        format_comment(string, "`n * `n *")
        paste(string, , true)
        sendinput {up 1} 
    } else {
        ; for idea
        format_comment(string, "`n *`n *")
        paste(string, , true)
        sendinput {left 2}   
        sendinput {delete} 
        sendinput {up} 
        sendinput {space}
    }
}

replace_comment()
{
    if (get_clip(0.2)) {
        line := clipboard
    }
    format_comment(total, line)
    paste(total)
}
