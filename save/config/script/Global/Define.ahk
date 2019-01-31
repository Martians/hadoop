
;enum_log(Byref string)
{
    log("[enum]: " string)
}

global_define_macro()
{
    ;======================================================================================
    ;======================================================================================
    ; single key - data, only check type and name, not check data value, can exist in any where

    ;------------------------------------
    ; normal sperator, used in string param, represent some means
    ; seperator char
    opt("next",  "|")   ; split multi item flag
    opt("list",  ",")   ; split multi param, seprerated with ,

    opt("final", "%")   ; last item, no need add or do later work; no need search path with prefix;
    opt("glob",  "'")   ; glob assist value, the option is global
    opt("test", """")   ; used for test
    ;======================================================================================    
    ;------------------------------------
    opt("left", "[")    ; transform seperator
    opt("righ", "]")
    opt("escape", "/")
    ;------------------------------------
    opt("book", "/")    ; evernote
    opt("tags", "+")

    ;======================================================================================   
    ; follow some param, but purpose is very explicit
    opt("map",   "/")   ; key map data, in one string 
    
    ;======================================================================================    
    ;======================================================================================   
    ; multi key, most of them follow some data, should always at the end
    opt("prior", "#")   ; prior in list
    sep("empty","<>")   ; instr with empty param

    ; option define
    sep("default", "++") ; function have default param, pend to default param
    sep("cancel" , "--") ; cancel some flag from given one

    sep("logon", "]]")  ; logon class
    sep("next", "||")   ; next handle
    sep("comb", "&&")   ; comb handle
    sep("help", "??")   ; input help message
    ; sep("before", "<-") ; handle before actual handle work
    ; sep("after",  "->") ; handle after actual handle work
    sep("time", ";;")   ; dual wait time
    sep("real", "<<")   ; dir real name
    sep("handle", "()") ; is a handle
    
    sep("cycle",  "~~") ; entry cycle handle
    sep("serial", ">>") ; confirm input as serial
    sep("usekey", "<<") ; confirm input as hotkey
    sep("move", ">>>>") ; move direct

    sep("head", "^^")   ; add to list head
    sep("tail", "$$")   ; add to list tail, used for exist param, and dynamic param order
    sep("only", "%%")   ; only use this param, no need add others

    sep("precise", "..") ; more precise, such as time
    sep("always", "++") ; evernote always locate query, no check
    collect_option()    ; collect option and seperator, used for regex

    ;======================================================================================    
    ;====================================================================================== 
    ;------------------------------------    
    ;------------------------------------    
    ; for config.ini section
    section("dir",      "directory")
    section("file",     "filelink")
    section("link",     "link_url")

    section("book",     "evernote")
    section("note",     "evernote")
    section("tags",     "evernote")
    section("common",   "name")

    fileini("snippet",  "Snippet")

    ;======================================================================================
    ;======================================================================================
    const("system",     "home",     file_path(file_path(A_ScriptDir)) "\")
    const("system",     "workd",    file_path(A_ScriptDir) "\")
    const("system",     "config",   A_ScriptDir "\Config\")

    ;--------------------------------------------------------------------------------------
    ;--------------------------------------------------------------------------------------
    const("string",     "blank",    " \s")
    ; word bounder
    const("string",     "bound",    " `t`r`n|,.") 
    const("string",     "valid",    const("string", "bound") "_-") 
    const("string",     "assist",   "~<>!#&\$\^\+")
    
    ;\.*?+[{|()^$ 
    ;--------------------------------------------------------------------------------------
    ;--------------------------------------------------------------------------------------
    const("regex",      "blank",    "[" const("string", "blank") "]*")
    const("regex",      "assist",   "[" const("string", "assist") "]")
    ;--------------------------------------------------------------------------------------
    ;--------------------------------------------------------------------------------------
    const("ctrl",       "name",     "ctrl")           ; ctrl name
    ;--------------------------------------------------------------------------------------
    ;--------------------------------------------------------------------------------------
    const("time",       "tips",     500)
    const("time",       "dual",     0.15)
    ;------------------------------------
    ;------------------------------------ 
    ; input group name
    const("input",      "master",   "master")
    const("input",      "inst",     "instr")
    const("input",      "auto",     "auto")
    const("input",      "short",    "short")

    const("input",      "assist",   "{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}")
    const("input",      "direct",   "{Left}{Right}{Up}{Down}{Home}{End}{Del}{Ins}{PgUp}{PgDn}")
    const("input",      "execute",  "{Escape}{Enter}{BackSpace}{Space}{Tab}")    
    const("input",      "system",   "{Capslock}{Numlock}{PrintScreen}{Pause}{AppsMaster}")
    const("input",      "function", "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}")
    const("input",      "most",     const_comb("input", "direct|execute|system|function"))
    const("input",      "every",    const_comb("input", "most|assist"))

    ;------------------------------------
    ;------------------------------------   
    const("keymap",     "assist",  {"<^": "LCtrl",  ">^": "RCtrl"
                                ,   "<!": "LAlt",   ">!": "RAlt"
                                ,   "<+": "LShift", ">+": "RShift"
                                ,   "<#": "LWin",   ">#": "RWin"})

    const("keymap",     "higher",   {"!": "1",  "@": "2", "#": "3", "$": "4", "%": "5"
                                ,    "^": "6",  "&": "7", "*": "8", "(": "9", ")": "0"
                                ,    "_": "-",  "+": "="})

    ; set F10 F11 F12 before others, when search master list, get max match
    const("hotkey",     "function", "F10|F11|F12|F1|F2|F3|F4|F5|F6|F7|F8|F9")
    const("hotkey",     "direct",   "Left|Right|Up|Down|Home|End|Delete|Ins|PgUp|PgDn")
    const("hotkey",     "execute",  "Esc|Enter|BackSpace|Space|Tab")
    const("hotkey",     "common",   "``|1|2|3|4|5|6|7|8|9|0|-|=|[|]\|;|'|,|.|/|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z")
    const("hotkey",     "combine",  const_comb("hotkey", "function|direct|execute|common", "|"))
    const("hotkey",     "compound", const_comb("hotkey", "function|direct|execute", "|"))
    const("hotkey",     "assist",   "LCtrl|RCtrl|LAlt|RAlt|LShift|RShift|LWin|RWin")
    ; only record hotkey type, not value
    const("hotkey",     "most",     "function|direct|execute|common")
    const("hotkey",     "every",    "assist|function|direct|execute|common")

    ;------------------------------------    
    ;------------------------------------  
    const("file_type",  "doc",      "(txt|ahk|ini|log)")
    ;======================================================================================
    ;======================================================================================
    ; multi flag can set in one entry, check type and name, while data is 0 or 1
    enum_type("system", "lock | saver | close | sleep | halt | shut | reboot")
    ;-------------------------------------------
    ;-------------------------------------------
    enum_type("option", "none_start | alias_only")    
    enum_type("option", "close_only | hide_only")    
    enum_type("option", "switch_mute| close_pid")    
    ;-------------------------------------------
    enum_type("string", "sub_string | allow_empty")
    ;-------------------------------------------
    ; not add dynamic param later
    ; add exist param to tail, behind dynamic param
    enum_type("handle", "init | only | tail")    
    ;-------------------------------------------
    ;-------------------------------------------
    enum_type("cond",   "title | class | exec | none")          
    enum_type("cond",   "active| exist")         
    ;-------------------------------------------
    ;-------------------------------------------
    enum_type("switch", "show | max | active | restor")
    enum_type("switch", "hide | min | close  | none | top_front_none_min | front_none_min")
    enum_type("switch", "mode_switch | mode_show | mode_hide")

    ;-------------------------------------------
    ;-------------------------------------------
    enum_type("ctrl",   "only_check | first_check | done_check | none_click")
    enum_type("ever",   "single")         ; evernote single note flag     

    enum_type("log_style", "date | exec | text")
    enum_type("log_mode",  "read | close | on_line")

    enum_type("clip",   "click")

    enum_type("en_style", "increase | reverse | force_reverse")  
    ;======================================================================================
    ;======================================================================================
    ; set name and value set, valid name and data types, only set one data at the same time
    data_type("dating", "mode", "date | create | modify | access")

    ;======================================================================================
    ;======================================================================================
    const("cycle_timer", "name", "global")
    const("cycle_timer", "timeout",  60000)         ; global cycle timer timeout 
    const("cycle_timer", "interval", 10000)

    const("hook_timer", "active_window", 60000)
    const("hook_timer", "mouse_move",    60000)

    const("applic",     "not_install", "not_install")
    ;-------------------------------------------------------------------------------------
    ;-------------------------------------------------------------------------------------
    ; when regist, do work right now, not regist as hotkey or input
    config("handle",    "rightly", "handle")
    ; use system key for volume
    config("system",    "volume",   1)
    ; serial not use timer for window acitve change
    config("serial",    "use_window_timer", 0)
    config("serial",    "vim_esc_open", 0)

    ; used for alloc increase index number
    config("global",    "unique", 0)
}

;======================================================================================
;======================================================================================
; set value
default(Byref data, Byref value="")
{
    if (!data) {
        if (value) {
            data := value
        } else {
            data := {}
        }
    }
    return data
}

alloc(Byref data, Byref handle)
{
    if (!data) {
        data := handle.()
    }
    return data
}

; set data into obj, and get data laster
init(Byref entry, Byref type, Byref name)
{
    array := glob_sure("glob", "init", type)

    ; already exist    
    if ((entry := get_item(array, name))) {
        return 0

    } else {
        entry := sure_item(array, name)
        return 1  
    }
}

; do some work only once in a handle
once(Byref type, Byref name)
{
    return init(entry, type, name)
}

;------------------------------------------------------------------
;------------------------------------------------------------------
; just a wrapper, mark it is a flag
flag(Byref list)
{
    return list
}

prior(Byref index=20)
{
    return opt("prior") index
}

help(Byref string)
{
    return sep("help") string
}

cancel(Byref string)
{
    return sep("cancel") string
}
;------------------------------------------------------------------
;------------------------------------------------------------------
collect_option()
{
    {
        string := ""
        array := glob_item("glob", "single", "option")
        for name, data in array
        {
            string := exist_suffix(string, "") data
        }
        const("single", "option", escape_regex(string))
    }

    {
        string := ""
        array := glob_item("glob", "single", "seperator")
        for name, data in array
        {
            string := exist_suffix(string, "|") escape_regex(data)
        }
        const("single", "seperator", string)
    }
}

;==============================================================================================
; create or get global entry, for advance use
;   never directly change value, should add sub member, like curr := glob(), curr.time := ..
glob(Byref index, Byref name="")
{
    global g_array
    return sure_item(g_array, index, name)
}

; create or get global entry, one more depth
glob_sure(Byref index, Byref name, Byref item)
{
    array := glob(index, name)
    return sure_item(array, item) 
}

; get global entry, never create
glob_item(Byref index, Byref name="", Byref item="")
{
    global g_array
    if (name) {
        if (item) {
            return g_array[index][name][item]
        } else {
            return g_array[index][name]
        }
    } else {
        return g_array[index]
    }
}

;----------------------------------------------------------------------
; set toplevel value,
;   used for g_array.log
set_glob(Byref group, Byref index="", Byref type="", Byref data="")
{
    global g_array
    item_data(g_array, group, index, type, data)
}

;----------------------------------------------------------------------
;----------------------------------------------------------------------
; set and get data, from ["glob"][group][type][name] := data
;   data != -1, set data, to some data or or 0 
;   data == -1, get data
;   valid means data must exist before read
glob_data(Byref group, Byref type, Byref name, Byref data=-1, valid=false)
{
    if (data == -1) {
        array := glob_item("glob", group, type)

    } else {
        array := glob_sure("glob", group, type)
            if (valid && array[name]) {
                warn("set glob data, but group [" group "] type [" type "] name [" name "] already have data [" array[name] "], when set data [" data "]")
                return 0
            }
        array[name] := data
    }

    if (valid) {
        if (data == -1 && !array[name]) {
            warn("get glob data, but group [" group "] type [" type "] name [" name "] not exist")
        }
    }
    return array[name]
}

glob_comb(Byref group, Byref type, Byref list, Byref sep="")
{
    while ((name := string_next(list, opt("next")))) {
        ; check if exist
        if (!(curr := glob_data(group, type, name))) {
            warn("glob data comb, but group [" group "] type [" type "] not have such data [" name "]")
            return 0
        }
        data := exist_suffix(data, sep) curr
    }
    return data
}

glob_data_sure(Byref group, Byref type, Byref name)
{
    array := glob_sure("glob", group, type)
    sure_item(array, name)
}

;----------------------------------------------------------------------
;----------------------------------------------------------------------
; regist glob type, for later check, group
inst_type(Byref group, Byref type, Byref name, Byref create=true)
{
    if (create) {
        array := glob_sure("inst", group, type)
        array.type_list := exist_suffix(array.type_list, opt("next")) name
        
        list := SubStr(name, 1)
        while ((next := string_next(list, opt("next")))) {
            array[next] := 1
        }
        return 1

    } else {
        array := glob_item("inst", group, type)      
        return array[name]
    }
}

; check if type value 
inst_type_valid(Byref group, Byref type, Byref name)
{
    if (inst_type(group, type, name, false)) {
        return name
    } else {
        warn("inst type valid, but group [" group "] type [" type "] not have such data [" name "]")
        return 0
    }
}

inst_list_valid(Byref group, Byref type, Byref list)
{
    if (list) {
        origin := list
        while ((name := string_next(list, opt("next")))) {
            ; check if exist
            if (!inst_type(group, type, name, false)) {
                warn("inst list valid, but group [" group "] type [" type "] not have such data [" name "]")
                return 0
            }
        }
    }
    return origin
}

inst_type_list(Byref group, Byref type)
{
     array := glob_sure("inst", group, type)
     return array.type_list
}

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------
; set inst with object
set_inst_type(Byref group, Byref entry, Byref type, Byref list, Byref set=1) 
{
    ; should not just return, create here if empty ?
    default(entry)

    if (!entry) {
        return 0

    ; clear all
    } else if (!list) {
        entry[group].remove(type)
        return 0
    }

    while ((name := string_next(list, opt("next")))) {
        ; check if exist
        if (inst_type(group, type, name, false)) {
            array := sure_item(entry, group, type)
            array[name] := set

        } else {
            warn("set inst, but group [" group "] type [" type "] name [" name "] not exist")
            return 0
        }
    }
    return array
}

get_inst_type(Byref group, Byref entry, Byref type, Byref name)
{
    if (inst_type(group, type, name, false)) {
        return entry[group][type][name]

    } else {
        warn("get inst, but group [" group "] type [" type "] name [" name "] not exist")
        return 0
    }
}

; notice: list here, not use Byref, if not success, we can display
inst_type_make(Byref group, Byref type, list, Byref entry)
{
    if (!list) {
        return 1
    }
    ; maybe list == entry when call func, so use some
    default(entry)

    if (set_inst_type(group, entry, type, list)) {
        return entry

    } else {
        return 0
    }
}

/*
; maybe not work well, sometimes need deep copy
copy_inst_data(Byref dst, Byref src, Byref group, Byref type="", Byref name="")
{
    sure_item(dst, group, type)
    if (type) {
        if (name) {
            dst[group][type][name] := src[group][type][name] 
        } else {
            dst[group][type] := src[group][type]
        }

    } else {
        dst[group] := src[group]
    }
}
*/

;==========================================================================
;==========================================================================
; set and get const data, will never reset, have key -> get value
;   opt("next", "|")
;   string_next(line, opt("next"))
opt(Byref name, Byref data=-1)
{
    ;collect_define("global", "option", data)
    return glob_data("single", "option", name, data, true)
}

sep(Byref name, Byref data=-1)
{
    ;collect_define("global", "seperator", data)
    return glob_data("single", "seperator", name, data, true)
}
; set section name for convention, have key -> get value
;   section("dir, "dir")
;   set_config(key, data, section("dir"))
section(Byref name, Byref data=-1)
{
    return glob_data("single", "section", name, data, true)
}

fileini(Byref name, Byref data=-1)
{
    return glob_data("single", "fileini", name, data, true)
}

switch(Byref name, Byref data=-1)
{
    return glob_data("single", "switch", name, data)
}

status(Byref name, Byref data=-1)
{
    return glob_data("single", "status", name, data)
}

;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; set and get const data, have key -> get value
const(Byref type, Byref name, Byref data=-1)
{
    return glob_data("const", type, name, data, true)
}

const_comb(Byref type, Byref list, Byref sep="")
{
    return glob_comb("const", type, list, sep)
}

; config constant data, only used by one app
config(Byref type, Byref name, Byref data=-1)
{
    return glob_data("config", type, name, data)
}

; get local used variable
local(Byref type, Byref name, Byref data=-1)
{
    glob_data_sure("local", type, name)
    return glob_data("local", type, name, data)
}

/*
collect_define(Byref type, Byref name, Byref data)
{
    if (data != -1) {
        curr := config(type, name)
        if (!InStr(curr, data)) {
            config(type, name, exist_suffix(curr, "|") data)
        }
    }
}
*/
;========================================================================================
;========================================================================================
; temply used, juse used for keep param in one struct, no key -> just get value
;   1) set
;           set_path(, , flag("hide_only|close"))    ; keep flag in global entry, and put as param
;   2) use: 
;           void set_path(p1, p2, flag) {
;               a := enum("hide_only", flag)     ; check if some item is setted
;               b := enum("close", flag)
;           }
; type set keep in glob["glob"]["flag"]["type"][...]
; current value keep in glob["glob"]["flag"]["data"] :=

; set key bitmaps -> fetch laster
;   set key bitmaps in entry

; regist enum
; glob["glob"]["enum"]
enum_type(Byref type, Byref list, Byref create=true)
{
    return inst_type("enum", type, list, create)
}

; set entry enum value
set_enum(Byref entry, Byref type, Byref list, Byref set=1) 
{
    return set_inst_type("enum", entry, type, list, set)
}

; check entry enum value
enum(Byref entry, Byref type, Byref name)
{
    return get_inst_type("enum", entry, type, name)
}

; check if enum name in list is valid, and return list again
enum_valid(Byref type, Byref list)
{
    return inst_list_valid("enum", type, list)
}

; make string to enum, return 0 or 1; if list is "", return 1
enum_make(Byref type, Byref list, Byref entry="")
{
    return inst_type_make("enum", type, list, entry)
}

enum_list(Byref type)
{
    return inst_type_list("enum", type)
}

;========================================================================================
;========================================================================================
; regist data type
data_type(Byref type, Byref name, Byref data, create=true)
{
    if (create) {
        list := SubStr(data, 1)

        array := glob_sure("data", type, name)
        while ((next := string_next(list, opt("next")))) {
            array[next] := 1
        }
        return 1

    } else {
        array := glob_item("data", type, name)
        if (array) {
            ; get current data, or set as null, only check array is ok
            if (data == -1 || data == 0) {
                return array != NULL

            } else if (array[data]) {
                return 1

            } else {
                warn("data type, but type [" type "] name [" name "] not have data [" data "]")
            }
        } else {
            warn("data type, but type [" type "] name [" name "] not exist")
        }
        return 0
    }
}

;----------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------
; set data into entry, and get data laster, set name, set data -> later fetch
any_data(Byref entry, Byref type, Byref name, Byref value=-1)
{
    if (value != -1) {
        array := sure_item(entry, "data", type)
        array[name] := value
    }
    return entry["data"][type][name]
}

; set or get data in entry, check if the name and data is valid
data(Byref entry, Byref type, Byref name, Byref data=-1)
{
    if (data_type(type, name, data, false)) {
        return any_data(entry, type, name, data)

    } else {
        return 0
    }
}

; used for set data and check
;   check_data(data) {
;       value := valid(data)
;   }
; regist valid type, which saved in data entry, used for unique type
data_type_valid(Byref type, Byref name, Byref data, Byref only_check=false)
{
    if (data) {
        array := glob_item("data", type, name)
        if (array) {
            if (array[data]) {
                return data

            } else {
                if (only_check) {
                    return 0

                } else {
                    warn("data type valid, but type [" type "] name [" name "] not have data [" data "]")
                }
            }
        } else {
            warn("data type valid, but type [" type "] name [" name "] not exist")
        }
        return 0
    }
    return data
}

;========================================================================================
;========================================================================================
display(set=-1)
{
    static value := 1
    return change_bit(value, set)
}

logging(set=-1)
{
    static value := 1
    return change_bit(value, set)
}

;======================================================================================
;======================================================================================
; get current bit, or set new one, and get the old value
change_bit(Byref entry, Byref set)
{
    if (set == -1) {
        return entry
        
    } else {
        old := entry
        update_bit(entry, set)
        return old
    }
}

; update data
update_bit(Byref value, Byref set=-1)
{
    bit_wise(value)
    ; need switch value
    if (bit_wise(set, 1)) {
        value := 1 - value
    
    } else {
         if (value == set) {
            return 0
        } else {
            value := set
        }
    }
    return 1
}

; like update bit
switch_bit(Byref value, Byref set=-1)
{
    update_bit(value, set)
    return value
}

; make it a bit wise value
bit_wise(Byref value, set=0)
{
    if (value == 0 || value == 1) {

    } else {
        if (set && value == -1) {
        } else {
            value := 0     
        }
    } 
    ; switch or set value
    return value == -1
}

;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
update_display(Byref value, Byref set=-1, Byref show="", notify=1)
{
    if (update_bit(value, set)) {

        if (show.open && show.close) {
            cond_tips(notify, value ? show.open : show.close)

        ; just display show itself拢禄
        } else {
            display := show.open ? show.open : show
            if (value == 1) {
                cond_tips(notify, "++ " display " on")
            } else {
                cond_tips(notify, "-- " display " off")
            }   
        }
        return 1

    } else {
        cond_tips(notify, "not change")
        return 0
    }
}

switch_display(ByRef value, Byref display)
{
    update_display(value, , display)
    return value
}

;========================================================================================
;========================================================================================
loop_init(Byref list, Byref Delimiters="|")
{
    curr := glob_sure("glob", "loop", "curr")
    curr.max := 0
    curr.pos := 1
    
    curr.list := StrSplit(list, Delimiters, A_Space)
    curr.max := curr.list.MaxIndex()
}

loop_next(Byref check="")
{   
    curr := glob_sure("glob", "loop", "curr")

    while (curr.pos <= curr.max) {
        key := curr.list[curr.pos]
        curr.pos++
        
        ; check if it is registed
        if (check && !check[key]) {
            continue
        }
        return key
    }
    return 0
}

;=============================================================================
;=============================================================================
; set key bitmaps -> fetch laster
;   set bitmaps in entry
regist_assist(Byref type, Byref key="", Byref open="", Byref close="", Byref mute=0)
{
     ; global handle
    if (if_prefix(type, opt("glob"), true)) {
        glob := 1
    }

    ; regist assist type valid entry
    if (!assist_type(type, true)) {
        return 0
    }

    ; use another place to store item info
    array := glob("glob", "assist")

    if (array[type]) {
        warn("regist assist, type " type " already exist")
        return
    }
    ; add assist type info entry
    curr := sure_item(array, type)
    curr.key   := key

    curr.open  := open
    curr.close := close
    curr.mute  := mute
    curr.glob  := glob
}

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
assist_type(Byref type, create=false)
{
    return inst_type("assist", "name", type, create)
}

set_assist(Byref entry, list, Byref set=1)
{
    return set_inst_type("assist", entry, "name", list, set)
}

assist(Byref entry, Byref name)
{
    return get_inst_type("assist", entry, "name", name)
}

update_assist(Byref entry, Byref type, Byref set=-1)
{   
    if (!assist_type(type)) {
        warn("update assist, but type [" type "] not valid")
        return 0
    }
    item := glob_item("glob", "assist", type)

    value := assist(entry, type)
    IF (update_display(value, set, item.open ? item : type, !item.mute)) {
        set_assist(entry, type, value)
        return 1

    } else {
        return 0
    }
}

;------------------------------------------------------------------------
;------------------------------------------------------------------------
; save in global entry
;   glob["glob"]["assist"][type]    [........] := 1/0   origin
;   glob["glob"]["assist"]["assist"][type] := 1/0       glob assist
set_global_assist(Byref type, Byref set=-1)
{
    array := glob_sure("glob", "assist", "global")
    return update_assist(array, type, set)
}   

global_assist(Byref type)
{
    array := glob_item("glob", "assist", "global")
    return assist(array, type)
}

;------------------------------------------------------------------------
;------------------------------------------------------------------------
; keep data for temply use in a small scope, set key, data -> set curr, fetch curr
regist_prefix(Byref type, Byref name, Byref prefix)
{
    return glob_data("prefix", type, name, prefix)
}

hotkey_prefix(Byref type=-1, Byref name=-1)
{
    static s_type := 
    static s_name := 

    if (type == -1) {
        return glob_data("prefix", s_type, s_name)

    } else {
        s_type := type 
        s_name := name

        if (s_type) {
			; check if item exist
            return glob_data("prefix", s_type, s_name, , true)
        }
    }
}

;========================================================================================
;========================================================================================
update_global_handle(Byref set, Byref type, Byref name, Byref handle="", arg*)
{
    entry := glob_sure("glob", "type_handle", "entry")
    update_type_handle(entry, set, type, name, handle, arg*)
}

do_global_handle(Byref string, Byref type, Byref name, Byref arg*)
{
    entry := glob_sure("glob", "type_handle", "entry")
    return do_type_handle(string, entry, type, name, arg*)
}

get_global_handle(Byref type, Byref name, Byref handle)
{
    entry := glob_sure("glob", "type_handle", "entry")
    return get_type_handle(entry, type, name, , handle)
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
update_type_handle(Byref entry, Byref set, Byref type, Byref name, Byref handle="", arg*)
{
    if (set) {
        add_type_handle(entry, type, name, handle, arg*)
    } else {
        del_type_handle(entry, type, name, handle)
    }   
}

get_type_handle(Byref entry, Byref type, Byref name, Byref index=1, Byref handle="")
{
    if ((array := get_item(entry, "type_handle", type, name))) {

        if (handle) {
            for index, item in array
            {
                if (get_handle(item) == handle) {
                    return item
                }
            }
            return 0

        } else if (index <= array.MaxIndex()) {
            return array[index]

        } else {
            warn("get entry handle, but type [" type "] name [" name "], index [" index "] > size [" array.MaxIndex() "], or handle <" handle "> not exist")
        }
    }
    return 0
}

add_type_handle(Byref entry, Byref type, Byref name, Byref handle, Byref arg*)
{
    array := sure_item(entry, "type_handle", type, name)

    for index, item in array
    {
        if (handle == get_handle(item)) {
            exist := true 
            break
        }
    }

    if (exist) {
        warn("add entry handle, type [" type "] name [" name "] handle [" handle "], but already exist")

    } else {

        if (array.MaxIndex()) {
            index := array.MaxIndex() + 1
            if (!index) {
                warn("error entry handle")
            }
        } else {
            index := 1
        }
        item := sure_item(array, index)
        handle_init(item, handle, arg*)

        win_log("add entry handle, type [" type "] name [" name "] handle [" item.handle "], index " index)
    }
}

del_type_handle(Byref entry, Byref type, Byref name, Byref handle="")
{
    if (!(array := get_item(entry, "type_handle", type, name))) {
        warn("del entry handle, type [" type "] name [" name "] handle [" handle "], but array not exist")
        return false

    } else if (handle) {
        for index, item in array
        {
            win_log("loop entry handle, " get_handle(item))
            if (handle == get_handle(item)) {
            
                if (array.MaxIndex() > 1) {
                    array.Remove(index)
                    win_log("del entry handle, type [" type "] name [" name "] handle [" handle "]")

                } else {
                    entry.type_handle[type].Remove(name)
                    win_log("del entry handle, type [" type "] name [" name "] handle [" handle "], only one item, del entry")
                }
                return
            }
        }
        warn("del entry handle, type [" type "] name [" name "] handle [" handle "], but not exist")

    } else {
        entry.type_handle[type].remove(name)
        win_log("del entry handle, type [" type "] name [" name "], no handle name, del entry")
    }
    return true
}

do_type_handle(Byref string, Byref entry, Byref type, Byref name, Byref arg*)
{
    if (!(array := get_item(entry, "type_handle", type, name))) {
        return 0
    }

    count := 0
    for index, item in array
    {
        if (index > 0) {
            if (++count == 1) {
                win_log("do " string " handle")
            }
            win_log("`t ==> handle: " get_handle(item) " <== ")

            if (handle_work(item, arg*) == -1) {
                win_log("`t handle: " get_handle(item) ", pass left")
                return -1
            }
        }
    }
    return count > 0
}

/**
dync_global_handle("a", "b", "tips", 1)
dync_global_handle("a", "b", "log", 1)
dync_global_handle("a", "b", "tips", "work")
dync_global_handle("a", "b", "tips", "null")
*/
dync_global_handle(Byref type, Byref name, Byref handle, Byref arg*)
{
    entry := config(type, name)

    ; do type handle
    if (arg[1] == "work") {
        do_type_handle("work", entry, type, name)

    ; del type handle
    } else if (arg[1] == "null") {

        if (entry) {
            del_type_handle(entry, type, name, handle)

            array := get_item(entry, "type_handle", type, name)

            if ((size := get_size(array)) == 0) {
                win_log("config global handle, type [" type "] name [" name "] clear handles")
                config(type, name, 0)
                return 0

            } else {
                win_log("config global handle, remove type [" type "] name [" name "] handle [" handle "], left " size)
            }

        } else {
            win_log("config global handle, but type [" type "] name [" name "] not exist")
        }

    ; add type handle
    } else {
        if (entry) {
            win_log("config global handle, add type [" type "] name [" name "], handle [" handle "]")
            add_type_handle(entry, type, name, set_handle(handle, handle, arg*))

        } else {
            default(entry)
            win_log("config global handle, create new type [" type "] name [" name "], handle [" handle "]")

            add_type_handle(entry, type, name, set_handle(handle, handle, arg*))
            config(type, name, entry)   
        }
    }
    return 1
}

dync_handle_work(Byref type, Byref name, Byref arg*)
{
    old := logging(0)
    
    entry := config(type, name)
    ret := do_type_handle("work", entry, type, name, arg*)

    logging(old)

    return ret
}
