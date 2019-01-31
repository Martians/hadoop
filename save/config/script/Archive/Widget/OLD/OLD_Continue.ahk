
#InstallKeybdHook

;双键注册

;设置下一个注册的等待时间，注意，这会导致主key的等待时间变长
trigger_time(newt="", Byref time=0)
{
	static default := 0.3
	static temp := default
	
	;外界获取时间
	time := temp
	temp := default
	
	;设置了临时时间	
	if (newt) {
		temp := newt
	}
}

trigger_mode(set=-1)
{
    static value := 0
    return change_bit(value, set)
}

;简化触发键注册方式，sleep wait 方式
regist_execute(key1, key2, handle, args*)
{
	trigger_mode(0)
	regist_contin(current_hotkey(key1), key2, handle, args*)
}

;简化触发键注册方式，input wait 方式
regist_execute2(key1, key2, handle, args*)
{
	trigger_mode(1)
	regist_contin(key1, key2, handle, args*)
	trigger_mode(0)
}

nothing()
{
}

prepare_handle(Byref key1, Byref key2)
{
	global g_hotkey
	
	if (!g_hotkey[key1]) {
		g_hotkey[key1] := {}
	}

	if (!g_hotkey[key1].handle) {
		log("## prepare for key1 " key1)
		regist_hotkey(key1, "nothing")
	}
		
	;设置regist_hotkey里边的选项自动设置sequence功能
	g_hotkey[key1].g_hotkey := 1

	;相同的key双击，不管是否使用辅助键，使用相同的处理
	if (key1 == key2) {
		key2 := main_key(key2)
	}
		
	;key2不带辅助键
	if (key2 == main_key(key2))
		return
		
	if (!g_hotkey[key2])
		g_hotkey[key2] := {}
	
	;确保key2已经被注册过	
	if (!g_hotkey[key2].handle) {
		log("## prepare for key2 " key2)
		regist_hotkey(key2, "nothing")
	}
	
	g_hotkey[key2].g_hotkey := 1
}

;触发键注册方式，key1：触发键trigger，key2，执行键execute
regist_contin(key1, key2, handle, args*)
{
	global g_hotkey
	
	;确保全局键已经设置
	if (!g_hotkey[0]) {
		g_hotkey[0] := {}
		g_hotkey[0].lastkey  := ""	;记录触发键
		g_hotkey[0].lasttime := 0	;记录触发时间
		g_hotkey[0].waittime := 0	;记录触发键等待时间
		g_hotkey[0].valid 	:= 0	;触发键是否生效了
		
		;可以用A_PriorHotkey和A_TimeSincePriorHotkey替代
	}
	
	;设置时间
	trigger_time("", time)

	;修复key1和key2
	prepare_handle(key1, key2)
	
	;注册触发键, 触发键的等待时间，是执行键需要等待的最大时间
	if (!g_hotkey[key1].time) {
		g_hotkey[key1].time	 := (time*1000) & 0xFFFFFFFF
		
		;使用了main_key，即第二个hotkey不关注是否有辅助键
		g_hotkey[key1].wait	 := main_key(key2)
		g_hotkey[key1].mode   := trigger_mode()
		
	} else {
		if (g_hotkey[key1].time < (time*1000) & 0xFFFFFFFF) {
			g_hotkey[key1].time	 := (time*1000) & 0xFFFFFFFF
			log("new regist key time is larger")
		}
		;记录key1后续要关注的键
		key := g_hotkey[key1].wait
		
		;不重复加入，如 !1和1	
		if (!Instr(key, main_key(key2)))
			g_hotkey[key1].wait := key main_key(key2)
	}
	
	g_hotkey[key1][key2] := {}	
	g_hotkey[key1][key2].handle := Func(handle)
	g_hotkey[key1][key2].time   := (time*1000) & 0xFFFFFFFF
	g_hotkey[key1][key2].args   := args
	
	log("regist " key1 " - " key2 ", wait " g_hotkey[key1].time)
	;测试
	;_handle(key1, key2)
}

;执行具体操作
_handle(Byref key1, Byref key2, wakeup=false)
{
	global g_hotkey
	
	g_hotkey[0].valid := 1
	g_hotkey[key1][key2].handle.(g_hotkey[key1][key2].args*)
	
	;设置有效标志，并唤醒等待键
	;	这个语句放在在执行键函执行之前，触发键唤醒后错误为timeout
	;	放在这里，触发键唤醒后错误为NewInput
	
	if (wakeup) {
		log("handle wakeup")
		input
	}
}

;所有键都执行的操作
seqence_handle()
{
	if (execute_handle()) {
		return true
	
	} else if (trigger_handle()) {
		return true
	}
	return false
}

;找到匹配key
match_execute()
{
	global g_hotkey
	
	key := curr_hotkey()
	if (g_hotkey[g_hotkey[0].lastkey][key])
		return key
	
	key := curr_hotkey(true)
	if (g_hotkey[g_hotkey[0].lastkey][key])
		return key
	return
}

;假设自己是执行键
execute_handle()
{
	global g_hotkey
	
	;相对于上一个触发键，自己没有注册执行键
	if (!(key := match_execute())) {
		log("not execute key")
		return false
	}
	
	log("execute handle check")
	interval := A_TickCount - g_hotkey[0].lasttime

	;上一个触发键有效，触发键是否超时
	if (interval > g_hotkey[0].time) {
		log("trigger key timeout, interval " interval ", exceed wait time " g_hotkey[0].time)
		return false
	}
	
	;自己作为执行键，注册的时间超时
	else if (interval > g_hotkey[g_hotkey[0].lastkey][key].time) {
		log("execute key timeout, interval " interval ", exceed wait time " g_hotkey[0].time)
		return false
	}
	
	;已经触发完成
	else if (g_hotkey[0].valid == 1) {
		log("execute key already handled")
		return false
	}
	
	log("execute key and wakeup, mode " g_hotkey[g_hotkey[0].lastkey].mode)
	_handle(g_hotkey[0].lastkey, key, g_hotkey[g_hotkey[0].lastkey].mode)
	return true
}

;触发键执行操作
trigger_handle()
{
	global g_hotkey

	;当前的hotkey是否作为触发键，注册过
	if (!g_hotkey[curr_hotkey()]) {
		log("not trigger key")
		return false
	}

	log("trigger handle check")
	g_hotkey[0].lastkey  := curr_hotkey() 	;A_ThisHotkey
	g_hotkey[0].lasttime := A_TickCount
	g_hotkey[0].time		:= g_hotkey[curr_hotkey()].time 
	g_hotkey[0].valid    := 0

	if (!g_hotkey[curr_hotkey()].mode) {
		waketime := g_hotkey[curr_hotkey()].time
		settimer, _trigger_mode, %waketime%
		return true
		
	} else {
		return input_wait()
	}
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;sleep wait 方式
;	适用于两次点击都带辅助键

_trigger_mode:
settimer, _trigger_mode, off
trigger_wait()
return

trigger_wait()
{
	global g_hotkey
	;execute key已经执行
	if (g_hotkey[0].valid == 1) {
		log("trigger suc")
		return
	}
	;没有触发任何动作，执行默认函数
	else if (g_hotkey[A_ThisHotkey]) {
		g_hotkey[A_ThisHotkey].handle.(g_hotkey[A_ThisHotkey].arg*)
		log("trigger defualt")
		return
	}
	return
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;input wait方式
;	多用于第二个键是裸键的
;	可用于alt下的多键方式
;	不能使用ctrl来激发双击以及使用裸键
input_wait()
{
	log("input wait")
	
	global g_hotkey
	;触发键等待一段时间，如果触发成功，不再执行自身逻辑了
	;	这里只能等单键
	
	wakekey := fetch_keys(1, g_hotkey[curr_hotkey()].time/1000, tout)
	
	;触发顺序key、双击的执行
	if (wakekey && continue_handle(wakekey)) {
		return true
	}
	
	;input超时，没有唤醒和新的输入。后续将执行该hotkey本来的功能
	else if (tout) {
		log("timeout, do original work")
		return false
	}
	
	;触发成功，执行键开始执行并唤醒自己，自己退出
	else if (g_hotkey[0].valid == 1) {
		log("trigger wakeup " errorlevel)
		return true
	}
	
	;被其他键唤醒，直接退出
	else {
		log("wakup by ignore keys, just exit")
		return true
	}
}

;执行顺序键
continue_handle(key)
{
	global g_hotkey
	
	work := false

	;被顺序key唤醒
	;	执行键注册方式：regist_contin("!r", "!m", "work1")
	;	顺序键注册方式：regist_contin("!r",  "m", "work2")
	if (Instr(g_hotkey[curr_hotkey()].wait, key)) {
		log("continue work, " curr_hotkey() " - " key)
		_handle(curr_hotkey(), key, false)
		work := true
	}
	
	;自己就是执行键，即doubleClick. 这里捕获的键，不带辅助键，因此比较时要去掉
	else if (key == curr_hotkey(true)) {
		if (g_hotkey[curr_hotkey()][curr_hotkey(true)]) {
			_handle(curr_hotkey(), curr_hotkey(true), false)
			work := true
		}
		
		if (work) {
			log("double click")
		}
	}
	
	return work
}

;==============================================================================================
;==============================================================================================
;注册热键映射
keymap(Byref value)
{
	send %value%
}

regist_keymap(Byref key, Byref map)
{
	regist_hotkey(key, "keymap", map)
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;测试消息

test_trigger_normal()
{
     tips("trigger normal ---", 1000)
}

test_execute_normal()
{
     tips("execute normal ---", 1000)
}

test_double(Byref p1, Byref p2)
{
     tips("trigger double --- " p1 p2, 1000)
}

test_continue()
{
	tips("continue handle---", 1000)
}

test_execute()
{
	tips("execute handle ---", 1000)
}

;全局注册消息，似乎只有在这里有效
test_regist_contin()
{
	;1）全部替换成regist_execute2
	key1 := "^1", key2 := "^2"
	
	;2）全部替换成regist_execute2
	;key1 := "^1", key2 := "^2"
	
	;3）全部替换成regist_execute2
	;key1 := "!1", key2 := "!2"
	
	;测试命令
	regist_hotkey(key1, "test_trigger_normal")
	regist_hotkey(key2, "test_execute_normal")
	
	regist_execute(key1, key1, "test_double", "this is ", "param")
	regist_execute(key1, main_key(key2), "test_continue")
	
	;设置临时的trigger时间
	trigger_time(2)
	regist_execute(key1, key2, "test_execute")
	trigger_time()
}


