
#InstallKeybdHook

;˫��ע��

;������һ��ע��ĵȴ�ʱ�䣬ע�⣬��ᵼ����key�ĵȴ�ʱ��䳤
trigger_time(newt="", Byref time=0)
{
	static default := 0.3
	static temp := default
	
	;����ȡʱ��
	time := temp
	temp := default
	
	;��������ʱʱ��	
	if (newt) {
		temp := newt
	}
}

trigger_mode(set=-1)
{
    static value := 0
    return change_bit(value, set)
}

;�򻯴�����ע�᷽ʽ��sleep wait ��ʽ
regist_execute(key1, key2, handle, args*)
{
	trigger_mode(0)
	regist_contin(current_hotkey(key1), key2, handle, args*)
}

;�򻯴�����ע�᷽ʽ��input wait ��ʽ
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
		
	;����regist_hotkey��ߵ�ѡ���Զ�����sequence����
	g_hotkey[key1].g_hotkey := 1

	;��ͬ��key˫���������Ƿ�ʹ�ø�������ʹ����ͬ�Ĵ���
	if (key1 == key2) {
		key2 := main_key(key2)
	}
		
	;key2����������
	if (key2 == main_key(key2))
		return
		
	if (!g_hotkey[key2])
		g_hotkey[key2] := {}
	
	;ȷ��key2�Ѿ���ע���	
	if (!g_hotkey[key2].handle) {
		log("## prepare for key2 " key2)
		regist_hotkey(key2, "nothing")
	}
	
	g_hotkey[key2].g_hotkey := 1
}

;������ע�᷽ʽ��key1��������trigger��key2��ִ�м�execute
regist_contin(key1, key2, handle, args*)
{
	global g_hotkey
	
	;ȷ��ȫ�ּ��Ѿ�����
	if (!g_hotkey[0]) {
		g_hotkey[0] := {}
		g_hotkey[0].lastkey  := ""	;��¼������
		g_hotkey[0].lasttime := 0	;��¼����ʱ��
		g_hotkey[0].waittime := 0	;��¼�������ȴ�ʱ��
		g_hotkey[0].valid 	:= 0	;�������Ƿ���Ч��
		
		;������A_PriorHotkey��A_TimeSincePriorHotkey���
	}
	
	;����ʱ��
	trigger_time("", time)

	;�޸�key1��key2
	prepare_handle(key1, key2)
	
	;ע�ᴥ����, �������ĵȴ�ʱ�䣬��ִ�м���Ҫ�ȴ������ʱ��
	if (!g_hotkey[key1].time) {
		g_hotkey[key1].time	 := (time*1000) & 0xFFFFFFFF
		
		;ʹ����main_key�����ڶ���hotkey����ע�Ƿ��и�����
		g_hotkey[key1].wait	 := main_key(key2)
		g_hotkey[key1].mode   := trigger_mode()
		
	} else {
		if (g_hotkey[key1].time < (time*1000) & 0xFFFFFFFF) {
			g_hotkey[key1].time	 := (time*1000) & 0xFFFFFFFF
			log("new regist key time is larger")
		}
		;��¼key1����Ҫ��ע�ļ�
		key := g_hotkey[key1].wait
		
		;���ظ����룬�� !1��1	
		if (!Instr(key, main_key(key2)))
			g_hotkey[key1].wait := key main_key(key2)
	}
	
	g_hotkey[key1][key2] := {}	
	g_hotkey[key1][key2].handle := Func(handle)
	g_hotkey[key1][key2].time   := (time*1000) & 0xFFFFFFFF
	g_hotkey[key1][key2].args   := args
	
	log("regist " key1 " - " key2 ", wait " g_hotkey[key1].time)
	;����
	;_handle(key1, key2)
}

;ִ�о������
_handle(Byref key1, Byref key2, wakeup=false)
{
	global g_hotkey
	
	g_hotkey[0].valid := 1
	g_hotkey[key1][key2].handle.(g_hotkey[key1][key2].args*)
	
	;������Ч��־�������ѵȴ���
	;	�����������ִ�м���ִ��֮ǰ�����������Ѻ����Ϊtimeout
	;	����������������Ѻ����ΪNewInput
	
	if (wakeup) {
		log("handle wakeup")
		input
	}
}

;���м���ִ�еĲ���
seqence_handle()
{
	if (execute_handle()) {
		return true
	
	} else if (trigger_handle()) {
		return true
	}
	return false
}

;�ҵ�ƥ��key
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

;�����Լ���ִ�м�
execute_handle()
{
	global g_hotkey
	
	;�������һ�����������Լ�û��ע��ִ�м�
	if (!(key := match_execute())) {
		log("not execute key")
		return false
	}
	
	log("execute handle check")
	interval := A_TickCount - g_hotkey[0].lasttime

	;��һ����������Ч���������Ƿ�ʱ
	if (interval > g_hotkey[0].time) {
		log("trigger key timeout, interval " interval ", exceed wait time " g_hotkey[0].time)
		return false
	}
	
	;�Լ���Ϊִ�м���ע���ʱ�䳬ʱ
	else if (interval > g_hotkey[g_hotkey[0].lastkey][key].time) {
		log("execute key timeout, interval " interval ", exceed wait time " g_hotkey[0].time)
		return false
	}
	
	;�Ѿ��������
	else if (g_hotkey[0].valid == 1) {
		log("execute key already handled")
		return false
	}
	
	log("execute key and wakeup, mode " g_hotkey[g_hotkey[0].lastkey].mode)
	_handle(g_hotkey[0].lastkey, key, g_hotkey[g_hotkey[0].lastkey].mode)
	return true
}

;������ִ�в���
trigger_handle()
{
	global g_hotkey

	;��ǰ��hotkey�Ƿ���Ϊ��������ע���
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
;sleep wait ��ʽ
;	���������ε������������

_trigger_mode:
settimer, _trigger_mode, off
trigger_wait()
return

trigger_wait()
{
	global g_hotkey
	;execute key�Ѿ�ִ��
	if (g_hotkey[0].valid == 1) {
		log("trigger suc")
		return
	}
	;û�д����κζ�����ִ��Ĭ�Ϻ���
	else if (g_hotkey[A_ThisHotkey]) {
		g_hotkey[A_ThisHotkey].handle.(g_hotkey[A_ThisHotkey].arg*)
		log("trigger defualt")
		return
	}
	return
}

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;input wait��ʽ
;	�����ڵڶ������������
;	������alt�µĶ����ʽ
;	����ʹ��ctrl������˫���Լ�ʹ�����
input_wait()
{
	log("input wait")
	
	global g_hotkey
	;�������ȴ�һ��ʱ�䣬��������ɹ�������ִ�������߼���
	;	����ֻ�ܵȵ���
	
	wakekey := fetch_keys(1, g_hotkey[curr_hotkey()].time/1000, tout)
	
	;����˳��key��˫����ִ��
	if (wakekey && continue_handle(wakekey)) {
		return true
	}
	
	;input��ʱ��û�л��Ѻ��µ����롣������ִ�и�hotkey�����Ĺ���
	else if (tout) {
		log("timeout, do original work")
		return false
	}
	
	;�����ɹ���ִ�м���ʼִ�в������Լ����Լ��˳�
	else if (g_hotkey[0].valid == 1) {
		log("trigger wakeup " errorlevel)
		return true
	}
	
	;�����������ѣ�ֱ���˳�
	else {
		log("wakup by ignore keys, just exit")
		return true
	}
}

;ִ��˳���
continue_handle(key)
{
	global g_hotkey
	
	work := false

	;��˳��key����
	;	ִ�м�ע�᷽ʽ��regist_contin("!r", "!m", "work1")
	;	˳���ע�᷽ʽ��regist_contin("!r",  "m", "work2")
	if (Instr(g_hotkey[curr_hotkey()].wait, key)) {
		log("continue work, " curr_hotkey() " - " key)
		_handle(curr_hotkey(), key, false)
		work := true
	}
	
	;�Լ�����ִ�м�����doubleClick. ���ﲶ��ļ�����������������˱Ƚ�ʱҪȥ��
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
;ע���ȼ�ӳ��
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
;������Ϣ

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

;ȫ��ע����Ϣ���ƺ�ֻ����������Ч
test_regist_contin()
{
	;1��ȫ���滻��regist_execute2
	key1 := "^1", key2 := "^2"
	
	;2��ȫ���滻��regist_execute2
	;key1 := "^1", key2 := "^2"
	
	;3��ȫ���滻��regist_execute2
	;key1 := "!1", key2 := "!2"
	
	;��������
	regist_hotkey(key1, "test_trigger_normal")
	regist_hotkey(key2, "test_execute_normal")
	
	regist_execute(key1, key1, "test_double", "this is ", "param")
	regist_execute(key1, main_key(key2), "test_continue")
	
	;������ʱ��triggerʱ��
	trigger_time(2)
	regist_execute(key1, key2, "test_execute")
	trigger_time()
}


