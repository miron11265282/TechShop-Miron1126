extends Node
## Состояние игры + логика компьютеров по эпохам 1995 → 2026.

signal changed
signal logged(line: String)
signal new_era(year: int, text: String)

const SAVE_PATH := "user://techshop_save.json"

var money: int = 300
var rep: int = 0
var day: int = 1
var jobs_done: int = 0
var tools: Array = []
var inventory: Array = []      # [{id, health}]
var owned_games: Array = []
var my_pc: Dictionary = {}
var orders: Array = []
var current_order: Dictionary = {}
var log_lines: Array = []
var pets: int = 0
var treats: int = 3
var keys: Array = []         # купленные ключи (id ОС)
var isos: Array = []         # скачанные ISO
var flash: Dictionary = {}   # что записано на флешку {os, scheme}
# --- бизнес ---
var stage: int = 0           # 0 комната … 4 небоскрёб
var benches: int = 1         # верстаков всего (один — твой)
var workers: Array = []      # [{name, skill, level, xp, salary, mood, jobs}]
var candidates: Array = []
var markup: float = 1.0      # наценка (с магазина)
var last_report: Array = []
var transport: int = 0       # 0 велик, 1 машина, 2 фургон
var visits: Array = []       # выезды на дом
var club: Dictionary = {}    # {level, seats:[pc], extras:[], price, last_tour}


func _ready() -> void:
	randomize()
	if not load_game():
		new_game()


# ============================ общее ============================

func year() -> int:
	return Data.START_YEAR + (day - 1) / Data.DAYS_PER_YEAR


func day_of_year() -> int:
	return (day - 1) % Data.DAYS_PER_YEAR + 1


func say(msg: String) -> void:
	log_lines.append(msg)
	if log_lines.size() > 120:
		log_lines.pop_front()
	logged.emit(msg)


func touch() -> void:
	changed.emit()


func has_tool(id: String) -> bool:
	return tools.has(id)


func av_level() -> int:
	return 2 if has_tool("av_pro") else (1 if has_tool("av_free") else 0)


func new_game() -> void:
	money = 300
	rep = 0
	day = 1
	jobs_done = 0
	tools = ["screwdriver", "av_free", "floppy"]
	inventory = []
	owned_games = ["doom2"]
	pets = 0
	treats = 3
	keys = []
	isos = []
	flash = {}
	my_pc = make_pc({"mobo": "mb_430fx", "cpu": "cpu_p75", "cooler": "cool_box95", "ram": "ram_edo8",
		"gpu": "gpu_trio64", "storage": "hdd_850m", "psu": "psu_at200"})
	my_pc["os"] = "win95"
	my_pc["drivers"] = true
	my_pc["dust"] = 30
	my_pc["junk"] = 0.05
	my_pc["games"] = ["doom2"]
	my_pc["user"] = "miron1126"
	current_order = {}
	orders = []
	log_lines = []
	stage = 0
	benches = 1
	workers = []
	candidates = []
	markup = 1.0
	last_report = []
	transport = 0
	club = {}
	gen_candidates()
	gen_orders()
	gen_visits()
	say("[color=#ff8a1f]1995 год. Добро пожаловать в miron1126 TechShop![/color] У тебя $300, Pentium 75 с Windows 95 и кошка Буся.")
	say(Data.EVENTS[1995])
	touch()


func next_day() -> void:
	var old_year := year()
	day += 1
	my_pc["dust"] = min(100, int(my_pc["dust"]) + 4)
	if my_pc["os"] != "" and pworks(my_pc, "storage"):
		my_pc["junk"] = float(my_pc["junk"]) + float(pdata(my_pc, "storage")["gb"]) * 0.006
		if av_level() < 2 and randf() < 0.1:
			var v: String = viruses_for_year(year(), false).pick_random()
			if not my_pc["viruses"].has(v):
				my_pc["viruses"].append(v)
				my_pc["scanned"] = false
	if year() != old_year:
		var t: String = Data.EVENTS.get(year(), "Наступил %d год. Новое железо уже в магазине!" % year())
		say("[color=#ff8a1f]== Наступил %d год ==[/color] %s" % [year(), t])
		new_era.emit(year(), t)
	business_day()
	club_day()
	gen_orders()
	gen_visits()
	say("[color=#ffb74d]— %d год, день %d —[/color] Новые клиенты ждут!" % [year(), day_of_year()])
	save_game()
	touch()


func viruses_for_year(y: int, include_ransom: bool = true) -> Array:
	var res := []
	for v in Data.viruses:
		if int(Data.viruses[v]["year"]) <= y and (include_ransom or int(Data.viruses[v]["level"]) < 3):
			res.append(v)
	return res


# ============================ компьютер ============================

func make_pc(ids: Dictionary) -> Dictionary:
	var p := {}
	for s in Data.SLOTS:
		p[s] = {"id": ids[s], "health": 100} if ids.has(s) else null
	var pc := {"parts": p, "dust": 0, "paste": 100, "os": "", "os_broken": false, "drivers": false,
		"games": [], "viruses": [], "scanned": false, "junk": 0.0, "known_broken": [], "missed": [],
		"cables": {"atx": true, "cpu": true, "pcie": true, "disk": true, "panel": true}, "ram_seated": true,
		"files": false, "backup": false, "activated": true, "bios": {}}
	pc["bios"] = default_bios(pc)
	return pc


func ensure_pc(pc: Dictionary) -> void:
	## Добавляет новые поля в старые компьютеры (из старых сохранений)
	var d := {"missed": [], "cables": {"atx": true, "cpu": true, "pcie": true, "disk": true, "panel": true},
		"ram_seated": true, "files": false, "backup": false, "activated": true}
	for k in d:
		if not pc.has(k):
			pc[k] = d[k]
	if not pc.has("bios") or pc["bios"].is_empty():
		pc["bios"] = default_bios(pc)


func is_uefi(pc: Dictionary) -> bool:
	var mb := pdata(pc, "mobo")
	return not mb.is_empty() and int(mb["year"]) >= 2012


func default_bios(pc: Dictionary) -> Dictionary:
	var mb := pdata(pc, "mobo")
	if mb.is_empty():
		return {"boot": ["hdd", "cd"], "csm": true, "secure_boot": false, "tpm": false, "xmp": false}
	var y := int(mb["year"])
	var boot := ["hdd", "cd"]
	if y >= 2003:
		boot.append("usb")
	if y < 2012:
		boot.append("floppy")
	var modern := y >= 2021
	return {"boot": boot, "csm": y < 2020, "secure_boot": modern and mb["tpm"], "tpm": modern and mb["tpm"], "xmp": false}


func cables_needed(pc: Dictionary) -> Array:
	## Какие кабели нужны этому ПК
	var res := []
	if pc["parts"]["psu"] == null:
		return res
	if pc["parts"]["mobo"] != null:
		res += ["atx", "panel"]
		if int(pdata(pc, "mobo")["year"]) >= 2001:
			res.append("cpu")
	var gpu := pdata(pc, "gpu")
	if not gpu.is_empty() and int(gpu["watt"]) > 75:
		res.append("pcie")
	var st := pdata(pc, "storage")
	if not st.is_empty() and st["iface"] != "nvme":
		res.append("disk")
	return res


func missing_cables(pc: Dictionary) -> Array:
	ensure_pc(pc)
	return cables_needed(pc).filter(func(k): return not pc["cables"].get(k, false))


func pdata(pc: Dictionary, slot: String) -> Dictionary:
	var p = pc["parts"].get(slot)
	if p == null:
		return {}
	return Data.part(p["id"])


func pworks(pc: Dictionary, slot: String) -> bool:
	var p = pc["parts"].get(slot)
	return p != null and float(p["health"]) > 0.0


func fits(mb: Dictionary, part: Dictionary) -> String:
	## Подходит ли деталь к материнской плате ("" — подходит)
	if mb.is_empty():
		return ""
	match part["slot"]:
		"cpu":
			if part["socket"] != mb["socket"]:
				return "Процессор %s (%s) не влезает в сокет %s" % [part["name"], part["socket"], mb["socket"]]
		"ram":
			if part["ram"] != mb["ram"]:
				return "Память %s не влезает в слоты %s" % [part["ram"], mb["ram"]]
		"gpu":
			if part["bus"] != mb["bus"]:
				return "Видеокарта %s не влезает в слот %s" % [part["bus"], mb["bus"]]
		"storage":
			if not mb["stor"].has(part["iface"]):
				return "Диск %s не подключить к этой плате (есть: %s)" % [part["iface"].to_upper(), "/".join(mb["stor"]).to_upper()]
	return ""


func boot_problems(pc: Dictionary) -> Array:
	var probs := []
	for s in ["psu", "mobo", "cpu", "ram", "gpu"]:
		var p = pc["parts"][s]
		if p == null:
			probs.append({"slot": s, "kind": "missing", "text": "Нет детали: " + Data.SLOT_NAMES[s]})
		elif float(p["health"]) <= 0.0:
			probs.append({"slot": s, "kind": "broken", "text": "Сломано: %s (%s)" % [Data.SLOT_NAMES[s], Data.part(p["id"])["name"]]})
	var mb := pdata(pc, "mobo")
	for s in ["cpu", "ram", "gpu"]:
		var d := pdata(pc, s)
		if not d.is_empty():
			var e := fits(mb, d)
			if e != "":
				probs.append({"slot": s, "kind": "fit", "text": e})
	var miss := missing_cables(pc)
	const CABLE_TEXT := {"atx": "Не подключено питание платы (20/24-pin)", "panel": "Не подключена кнопка Power (передняя панель)",
		"cpu": "Не подключено питание процессора (4/8-pin)", "pcie": "Видеокарте не подключено доп. питание (PCIe)"}
	for k in miss:
		if CABLE_TEXT.has(k):
			probs.append({"slot": "psu" if k in ["atx", "panel"] else ("gpu" if k == "pcie" else "cpu"), "kind": "cable_" + k, "text": CABLE_TEXT[k]})
	if pc["parts"]["ram"] != null and not pc.get("ram_seated", true):
		probs.append({"slot": "ram", "kind": "seat", "text": "Память вставлена не до щелчка"})
	return probs


func os_state(pc: Dictionary) -> String:
	if not pworks(pc, "storage"):
		return "No bootable device — диск не найден"
	if fits(pdata(pc, "mobo"), pdata(pc, "storage")) != "":
		return "Диск не определяется — не тот интерфейс"
	if missing_cables(pc).has("disk"):
		return "Диск не определяется — не подключено питание диска"
	if pc["os"] == "":
		return "No bootable device — ОС не установлена"
	if pc["os_broken"]:
		return "Синий экран смерти (BSOD)"
	if pc["viruses"].has("ransom") or pc["viruses"].has("cry"):
		return "Экран вымогателя: «Плати за свои файлы!»"
	return ""


func temp(pc: Dictionary) -> float:
	var cpu := pdata(pc, "cpu")
	if cpu.is_empty():
		return 0.0
	var cool := pdata(pc, "cooler")
	var c := 5.0
	if not cool.is_empty() and pworks(pc, "cooler"):
		c = float(cool["cool"])
	var dust_f := 1.0 + float(pc["dust"]) / 100.0 * 0.8
	var paste_f := 1.0 + (100.0 - float(pc["paste"])) / 100.0 * 0.6
	var t := 30.0 + float(cpu["tdp"]) * 0.5 * (40.0 / (c + 10.0)) * dust_f * paste_f
	if active_viruses(pc).has("miner"):
		t += 8.0
	return t


func power_need(pc: Dictionary) -> int:
	var need := 40
	var cpu := pdata(pc, "cpu")
	var gpu := pdata(pc, "gpu")
	if not cpu.is_empty():
		need += int(cpu["tdp"])
	if not gpu.is_empty():
		need += int(gpu["watt"])
	return need


func psu_ok(pc: Dictionary) -> bool:
	var psu := pdata(pc, "psu")
	return not psu.is_empty() and int(psu["watt"]) >= power_need(pc)


func used_gb(pc: Dictionary) -> float:
	var u := float(pc["junk"])
	if pc["os"] != "":
		u += float(Data.os_list[pc["os"]]["gb"])
	for g in pc["games"]:
		u += float(Data.games[g]["gb"])
	return u


func free_gb(pc: Dictionary) -> float:
	var st := pdata(pc, "storage")
	if st.is_empty():
		return 0.0
	return float(st["gb"]) - used_gb(pc)


func junk_limit(pc: Dictionary) -> float:
	var st := pdata(pc, "storage")
	return 0.0 if st.is_empty() else float(st["gb"]) * 0.02


func fps(pc: Dictionary, gid: String, quality: float = 1.0) -> float:
	var g: Dictionary = Data.games[gid]
	var cpu := pdata(pc, "cpu")
	var gpu := pdata(pc, "gpu")
	var ram := pdata(pc, "ram")
	if cpu.is_empty() or gpu.is_empty() or ram.is_empty() or pc["os"] == "":
		return 0.0
	var cs := float(cpu["score"]) / float(g["cpu"])
	var gs := float(gpu["score"]) / float(g["gpu"])
	if not pc["drivers"]:
		gs *= 0.25
	var f: float = min(90.0 * cs, 60.0 * gs * quality)
	if float(ram["gb"]) < float(g["ram"]):
		f *= float(ram["gb"]) / float(g["ram"]) * 0.8
	f *= float(Data.os_list[pc["os"]]["fps"])
	for v in active_viruses(pc):
		f *= float(Data.viruses[v]["fps"])
	if float(pc["junk"]) > junk_limit(pc) * 10.0:
		f *= 0.9
	if temp(pc) > 90.0:
		f *= 0.55
	if pc.get("bios", {}).get("xmp", false) and ram["ram"] in ["DDR4", "DDR5"]:
		f *= 1.06
	return clamp(f, 0.0, 999.0)


func bench_score(pc: Dictionary) -> int:
	var cpu := pdata(pc, "cpu")
	var gpu := pdata(pc, "gpu")
	var ram := pdata(pc, "ram")
	var st := pdata(pc, "storage")
	var s := float(cpu["score"]) * 50.0 + float(gpu["score"]) * (80.0 if pc["drivers"] else 20.0)
	s += float(ram["gb"]) * 200.0 + float(st["speed"]) * 50.0
	for v in pc["viruses"]:
		s *= float(Data.viruses[v]["fps"])
	if temp(pc) > 90.0:
		s *= 0.55
	return int(s)


# ---------- проверки ----------

func check_running(pc: Dictionary) -> String:
	if not boot_problems(pc).is_empty():
		return "ПК не запускается. Сначала диагностика."
	if temp(pc) > 100.0:
		return "ПК выключается от перегрева!"
	return os_state(pc)


func power_on(pc: Dictionary) -> String:
	pc["killed"] = []
	var bp := boot_problems(pc)
	if not pworks(pc, "psu"):
		return "Нажимаешь кнопку… тишина. Даже вентиляторы не крутятся."
	for p in bp:
		if p["kind"] in ["cable_atx", "cable_panel"]:
			return "Нажимаешь кнопку… тишина. (%s?)" % ("кнопка не подключена" if p["kind"] == "cable_panel" else "плата без питания")
	for p in bp:
		if p["kind"] == "seat":
			return "Вентиляторы крутятся, спикер пищит длинными гудками — что-то с памятью."
		if p["kind"] == "cable_pcie":
			return "Вентиляторы крутятся, монитор «Нет сигнала», на видеокарте мигает красный диод."
	if not bp.is_empty():
		if bp.size() == 1 and bp[0]["slot"] == "gpu":
			return "Вентиляторы крутятся, но монитор пишет «Нет сигнала»."
		return "Вентиляторы крутятся, спикер пищит, изображения нет. Не проходит POST."
	var t := temp(pc)
	if t > 100.0:
		return "ПК включился и через 10 секунд выключился — перегрев (%d°C)!" % int(t)
	var o := os_state(pc)
	if o != "":
		return "Экран: " + o
	var txt := "Загрузилась %s. Рабочий стол! Температура %d°C." % [Data.os_list[pc["os"]]["name"], int(t)]
	if pc["viruses"].has("adware"):
		txt += " Сразу вылезло 5 окон с рекламой…"
	if pc["viruses"].has("flip"):
		txt += " Экран вверх ногами!"
	if pc["viruses"].has("kitty"):
		txt += " По экрану бегают котики (Буся недовольна)."
	if pc["viruses"].has("loud"):
		txt += " Из колонок орёт музыка!"
	if float(pc["junk"]) > junk_limit(pc) * 10.0:
		txt += " Грузится очень долго."
	if not pc["drivers"]:
		txt += " Разрешение 640×480, 16 цветов — нет драйверов."
	return txt


func diagnose(pc: Dictionary) -> Array:
	var L := []
	var hidden_broken := false
	for p in boot_problems(pc):
		if p["kind"] != "broken":
			L.append("[color=#ef5350]× %s[/color]" % p["text"])
		elif p["slot"] == "psu":
			if has_tool("multimeter"):
				L.append("[color=#ef5350]× Мультиметр: %s[/color]" % p["text"])
				_reveal(pc, "psu")
			else:
				L.append("[color=#ef5350]× Нет питания. Проверь БП мультиметром (магазин).[/color]")
		elif has_tool("postcard"):
			L.append("[color=#ef5350]× POST-карта: %s[/color]" % p["text"])
			_reveal(pc, p["slot"])
		else:
			hidden_broken = true
	if hidden_broken:
		L.append("[color=#ef5350]× ПК не проходит POST. Какая деталь сломана — покажет POST-карта (или меняй по одной).[/color]")
	if pc["parts"]["storage"] != null and not pworks(pc, "storage"):
		if has_tool("postcard"):
			L.append("[color=#ef5350]× Накопитель мёртв[/color]")
			_reveal(pc, "storage")
		else:
			L.append("[color=#ef5350]× Диск не определяется в BIOS[/color]")
	if pc["parts"]["storage"] == null:
		L.append("[color=#ef5350]× Нет накопителя[/color]")
	if pc["parts"]["cooler"] == null:
		L.append("[color=#ef5350]× Нет кулера — процессор сгорит![/color]")
	var psu := pdata(pc, "psu")
	if not psu.is_empty():
		var ok := int(psu["watt"]) >= power_need(pc)
		L.append(("[color=#66bb6a]✓" if ok else "[color=#ef5350]×") + " Питание: нужно ~%d Вт, БП даёт %d Вт[/color]" % [power_need(pc), psu["watt"]])
	var t := temp(pc)
	L.append(("[color=#66bb6a]✓" if t < 80 else ("[color=#ffb74d]!" if t <= 90 else "[color=#ef5350]×")) + " Температура CPU под нагрузкой: %d°C[/color]" % int(t))
	L.append("Пыль: %d%%   Термопаста: %d%%" % [int(pc["dust"]), int(pc["paste"])])
	var o := os_state(pc)
	L.append(("[color=#66bb6a]✓ ОС: " + Data.os_list[pc["os"]]["name"]) if o == "" else ("[color=#ef5350]× " + o))
	L[-1] += "[/color]"
	if pc["os"] != "":
		L.append("Драйверы: " + ("установлены" if pc["drivers"] else "[color=#ffb74d]НЕ установлены[/color]"))
		L.append("Мусор: %s, свободно %s" % [Data.gb_text(float(pc["junk"])), Data.gb_text(max(0.0, free_gb(pc)))])
	L.append("Вирусы: " + virus_text(pc))
	return L


func _reveal(pc: Dictionary, slot: String) -> void:
	if not pc["known_broken"].has(slot):
		pc["known_broken"].append(slot)


func visible_viruses(pc: Dictionary) -> Array:
	var res := []
	for v in pc["viruses"]:
		if pc.get("missed", []).has(v):
			continue
		if int(Data.viruses[v]["level"]) == 3 or int(Data.viruses[v]["level"]) <= av_level():
			res.append(v)
	return res


# ---------- работа за компьютером: процессы, файлы, командная строка ----------

func active_viruses(pc: Dictionary) -> Array:
	## Вирусы, которые сейчас работают (без тех, чей процесс завершили в диспетчере)
	var res := []
	for v in pc["viruses"]:
		if not pc.get("killed", []).has(v):
			res.append(v)
	return res


func pc_user(pc: Dictionary) -> String:
	return String(pc.get("user", "User")) if String(pc.get("user", "")) != "" else "User"


const CRITICAL := ["System", "smss.exe", "csrss.exe", "winlogon.exe", "services.exe", "lsass.exe", "wininit.exe", "KERNEL32.DLL", "MSGSRV32.EXE", "systemd", "Xorg"]


func processes(pc: Dictionary) -> Array:
	## Список процессов, как в диспетчере задач. Вирусы иногда маскируются под системные.
	var o: Dictionary = Data.os_list.get(pc["os"], {})
	var gen := int(o.get("gen", 1))
	var u := pc_user(pc)
	var L := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(pc["parts"]))
	if o.get("linux", false):
		for n in ["systemd", "Xorg", "gnome-shell" if pc["os"] == "ubuntu" else "cinnamon", "NetworkManager", "pulseaudio", "bash"]:
			L.append({"name": n, "user": "root" if n in ["systemd", "Xorg", "NetworkManager"] else u, "cpu": rng.randi_range(0, 3), "mem": rng.randi_range(8, 120), "kind": "sys"})
	elif gen <= 3:
		for n in ["KERNEL32.DLL", "MSGSRV32.EXE", "MPREXE.EXE", "EXPLORER.EXE", "SYSTRAY.EXE"]:
			L.append({"name": n, "user": "", "cpu": rng.randi_range(0, 2), "mem": rng.randi_range(1, 6), "kind": "sys"})
	else:
		var names := ["System", "smss.exe", "csrss.exe", "winlogon.exe", "services.exe", "lsass.exe", "svchost.exe", "svchost.exe", "svchost.exe", "explorer.exe"]
		if gen >= 5:
			names.insert(3, "wininit.exe")
			names.append("dwm.exe")
		if gen >= 8:
			names.append("RuntimeBroker.exe")
		for n in names:
			var usr := u if n in ["explorer.exe", "RuntimeBroker.exe"] else "СИСТЕМА"
			L.append({"name": n, "user": usr, "cpu": rng.randi_range(0, 3), "mem": rng.randi_range(2, 60) * (4 if gen >= 6 else 1), "kind": "sys"})
		if gen >= 4:
			L.append({"name": "ctfmon.exe", "user": u, "cpu": 0, "mem": 3, "kind": "app"})
	for v in active_viruses(pc):
		var vp: Dictionary = Data.VPROC.get(v, {})
		if vp.has("proc"):
			var nm: String = vp["proc"]
			if gen <= 3 and not o.get("linux", false):
				nm = nm.to_upper()
			L.append({"name": nm, "user": u if gen > 3 else "", "cpu": int(vp.get("cpu", 5)), "mem": int(vp.get("mem", 12)), "kind": "virus", "id": v})
	var g: String = pc.get("playing", "")
	if g != "" and Data.games.has(g):
		L.append({"name": g + ".exe", "user": u, "cpu": 45, "mem": 900, "kind": "game"})
	return L


func kill_process(pc: Dictionary, p: Dictionary) -> String:
	## Возвращает: ok, crash, explorer, denied
	match p["kind"]:
		"virus":
			if not pc.has("killed"):
				pc["killed"] = []
			pc["killed"].append(p["id"])
			return "ok"
		"game":
			pc["playing"] = ""
			return "ok"
		"app":
			return "ok"
	if p["name"] in CRITICAL:
		pc["on"] = false
		pc["playing"] = ""
		return "crash"
	if p["name"].to_lower() == "explorer.exe":
		return "explorer"
	if p["name"] == "svchost.exe":
		return "denied"
	return "ok"


func startup_items(pc: Dictionary) -> Array:
	var o: Dictionary = Data.os_list.get(pc["os"], {})
	var L := []
	if int(o.get("gen", 1)) >= 4:
		L.append({"name": "ctfmon.exe", "kind": "app"})
	if has_tool("av_free") or has_tool("av_pro"):
		L.append({"name": "Антивирус.exe", "kind": "app"})
	for v in pc["viruses"]:
		var vp: Dictionary = Data.VPROC.get(v, {})
		if vp.has("proc"):
			L.append({"name": vp.get("file", vp["proc"]), "kind": "virus", "id": v})
	return L


func delete_startup(pc: Dictionary, it: Dictionary) -> String:
	if it["kind"] != "virus":
		return "Убрано из автозагрузки. (Это была нормальная программа.)"
	var v: String = it["id"]
	if not pc.get("killed", []).has(v):
		return "Ошибка: «Файл используется другим процессом». Сначала заверши процесс в диспетчере задач!"
	pc["viruses"].erase(v)
	pc["killed"].erase(v)
	return "Удалён %s — вирус %s побеждён вручную!" % [it["name"], Data.viruses[v]["name"]]


func fix_mbr(pc: Dictionary) -> String:
	if pc["viruses"].has("boot"):
		pc["viruses"].erase("boot")
		return "Загрузочная запись перезаписана. Загрузочный вирус уничтожен!"
	return "Загрузочная запись перезаписана."


func delete_template(pc: Dictionary) -> String:
	if pc["viruses"].has("macro"):
		pc["viruses"].erase("macro")
		return "Заражённый Normal.dot удалён. Макровирус уничтожен! Word создаст чистый шаблон."
	return "Normal.dot удалён — Word создаст новый при запуске."


const USER_FILES := ["Фото_море.jpg", "Курсовая_ФИНАЛ_точно_финал.doc", "Рецепты бабушки.txt", "Отчёт_квартал.xls",
	"Свадьба.avi", "Музыка_в_машину", "Пароли.txt", "Диплом.doc", "Кот на диване.jpg", "Сохранения игр", "Дача_2007.jpg", "Резюме.doc"]


func user_files(pc: Dictionary) -> Array:
	if not pc.get("files", false):
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(pc["parts"])) + 7
	var pool := USER_FILES.duplicate()
	var res := []
	for i in 5:
		res.append(pool.pop_at(rng.randi() % pool.size()))
	return res


func chkdsk_text(pc: Dictionary) -> Array:
	var st := pdata(pc, "storage")
	var h := int(pc["parts"]["storage"]["health"]) if pc["parts"]["storage"] != null else 0
	var L := ["Проверка диска %s…" % st.get("name", "?"), "Объём: %s, свободно: %s" % [Data.gb_text(float(st.get("gb", 0))), Data.gb_text(max(0.0, free_gb(pc)))]]
	if h < 60:
		L.append("ВНИМАНИЕ: найдено %d повреждённых секторов! Диск скоро умрёт — замени его." % ((60 - h) * 37))
	else:
		L.append("Повреждённых секторов не обнаружено.")
	return L


func systeminfo(pc: Dictionary) -> Array:
	var o: Dictionary = Data.os_list.get(pc["os"], {})
	return ["ОС:        " + String(o.get("name", "?")),
		"Процессор: " + String(pdata(pc, "cpu").get("name", "?")),
		"Память:    " + Data.gb_text(float(pdata(pc, "ram").get("gb", 0))),
		"Видео:     " + String(pdata(pc, "gpu").get("name", "?")) + ("" if pc["drivers"] else " (стандартный VGA — нет драйвера)"),
		"Плата:     " + String(pdata(pc, "mobo").get("name", "?")),
		"Активация: " + ("выполнена" if pc.get("activated", true) else "НЕ выполнена"),
		"Темп. ЦП:  %d°C" % int(temp(pc))]


func virus_text(pc: Dictionary) -> String:
	if pc["viruses"].has("ransom") or pc["viruses"].has("cry"):
		return "[color=#ef5350]ВЫМОГАТЕЛЬ на экране![/color]"
	if not pc["scanned"]:
		return "не проверено (запусти антивирус)"
	var vis := visible_viruses(pc)
	if vis.is_empty():
		return "[color=#66bb6a]не найдено[/color]"
	var names := []
	for v in vis:
		names.append("%s (%s)" % [Data.viruses[v]["name"], Data.viruses[v]["desc"]])
	return "[color=#ef5350]" + ", ".join(names) + "[/color]"


# ---------- сборка: строго по порядку ----------

func can_remove(pc: Dictionary, slot: String) -> String:
	if pc["parts"][slot] == null:
		return "Слот пуст."
	for s in Data.NEEDS:
		if Data.NEEDS[s].has(slot) and pc["parts"][s] != null:
			return "Сначала сними: %s" % Data.SLOT_NAMES[s]
	return ""


func can_place(pc: Dictionary, slot: String, part_id: String) -> String:
	var d := Data.part(part_id)
	if d.is_empty() or d["slot"] != slot:
		return "Эта деталь сюда не ставится — это %s." % Data.SLOT_NAMES.get(d.get("slot", ""), "?").to_lower()
	if pc["parts"][slot] != null:
		return "Слот занят — сначала сними старую деталь."
	for need in Data.NEEDS.get(slot, []):
		if pc["parts"][need] == null:
			return "Сначала поставь: %s" % Data.SLOT_NAMES[need]
	if slot == "mobo":
		return ""
	return fits(pdata(pc, "mobo"), d)


func remove_part(pc: Dictionary, slot: String) -> String:
	var e := can_remove(pc, slot)
	if e != "":
		return e
	var p = pc["parts"][slot]
	inventory.append(p)
	pc["parts"][slot] = null
	pc["on"] = false
	pc["playing"] = ""
	pc["known_broken"].erase(slot)
	ensure_pc(pc)
	match slot:
		"psu":
			for k in pc["cables"]:
				pc["cables"][k] = false
		"mobo":
			for k in ["atx", "cpu", "panel"]:
				pc["cables"][k] = false
		"gpu":
			pc["cables"]["pcie"] = false
		"storage":
			pc["cables"]["disk"] = false
	if slot == "storage":
		_wipe(pc)
		pc["files"] = false
	touch()
	return "Снято: %s → на склад." % Data.part(p["id"])["name"]


func place_part(pc: Dictionary, slot: String, inv_index: int) -> String:
	var p = inventory[inv_index]
	var e := can_place(pc, slot, p["id"])
	if e != "":
		return "[color=#ef5350]%s[/color]" % e
	inventory.remove_at(inv_index)
	pc["parts"][slot] = p
	pc["on"] = false
	pc["playing"] = ""
	ensure_pc(pc)
	if slot == "mobo":
		pc["bios"] = default_bios(pc)
	if slot == "ram":
		pc["ram_seated"] = true
	if slot == "storage":
		_wipe(pc)
	if slot == "gpu":
		pc["drivers"] = false
	touch()
	var txt := "Установлено: %s." % Data.part(p["id"])["name"]
	if slot == "cooler" and not has_tool("paste"):
		pc["paste"] = 20
		txt += " Термопасты нет — будет греться!"
	if slot == "psu" and Data.part(p["id"])["cheap"]:
		txt += " (дешёвый БП… будем надеяться)"
	return txt


func _wipe(pc: Dictionary) -> void:
	pc["os"] = ""
	pc["os_broken"] = false
	pc["drivers"] = false
	pc["games"] = []
	pc["viruses"] = []
	pc["junk"] = 0.0
	pc["scanned"] = false


# ---------- ОС ----------

const MEDIA_TOOL := {"floppy": "floppy", "cd": "cdrom", "usb": "usb"}
const MEDIA_NAME := {"floppy": "загрузочные дискеты", "cd": "CD-привод", "usb": "загрузочная флешка"}


func os_hw_check(pc: Dictionary, os_id: String) -> String:
	## Подходит ли железо под ОС (без денег и инструментов)
	var o: Dictionary = Data.os_list[os_id]
	if not boot_problems(pc).is_empty():
		return "ПК не проходит POST — сначала почини железо."
	if not pworks(pc, "storage") or fits(pdata(pc, "mobo"), pdata(pc, "storage")) != "":
		return "Нет рабочего диска."
	if float(pdata(pc, "ram")["gb"]) < float(o["min_ram"]):
		return "Мало памяти для %s (нужно %s)." % [o["name"], Data.gb_text(o["min_ram"])]
	if o.has("min_cpu_year") and int(pdata(pc, "cpu")["year"]) < int(o["min_cpu_year"]):
		return "Процессор слишком старый для %s." % o["name"]
	if o.get("need_w11", false) and (not pdata(pc, "cpu")["w11"] or not pdata(pc, "mobo")["tpm"]):
		return "Этот ПК не поддерживает Windows 11 (нужен новый процессор и TPM 2.0)."
	if pdata(pc, "storage")["iface"] == "nvme" and int(o["gen"]) < 7 and not o["linux"]:
		return "%s не видит NVMe-диски." % o["name"]
	if float(pdata(pc, "storage")["gb"]) < float(o["gb"]):
		return "Не хватает места на диске."
	return ""


func can_install_os(pc: Dictionary, os_id: String) -> String:
	var o: Dictionary = Data.os_list[os_id]
	if int(o["year"]) > year():
		return "%s ещё не вышла!" % o["name"]
	if not has_tool(MEDIA_TOOL[o["media"]]):
		return "Нужна %s (магазин → инструменты)." % MEDIA_NAME[o["media"]]
	var e := os_hw_check(pc, os_id)
	if e != "":
		return e
	if temp(pc) > 100.0:
		return "ПК перегревается и выключается."
	return ""


func boot_media_check(pc: Dictionary, os_id: String) -> String:
	## После BIOS: загрузится ли ПК с установочного носителя
	ensure_pc(pc)
	var o: Dictionary = Data.os_list[os_id]
	var media: String = {"floppy": "floppy", "cd": "cd", "usb": "usb"}[o["media"]]
	var b: Dictionary = pc["bios"]
	if not b["boot"].has(media):
		return "Эта плата не умеет загружаться с %s." % MEDIA_NAME[o["media"]]
	if b["boot"][0] != media:
		return "ПК загрузился с диска, а не с носителя — поставь «%s» первым в BIOS." % {"floppy": "Дисковод", "cd": "CD-привод", "usb": "USB-флешку"}[media]
	if media == "usb":
		if flash.get("os", "") != os_id:
			return "На флешке нет %s — запиши её в Rufus." % o["name"]
		var uefi := is_uefi(pc)
		if flash["scheme"] == "GPT" and not uefi:
			return "Флешка в GPT, а у платы старый BIOS — нужна схема MBR."
		if flash["scheme"] == "MBR" and uefi and not b["csm"]:
			return "Флешка в MBR, а CSM выключен — включи CSM в BIOS или запиши флешку в GPT."
		if o.get("need_w11", false):
			if flash["scheme"] != "GPT" or b["csm"]:
				return "Windows 11 ставится только с GPT-флешки в режиме UEFI (CSM выключен)."
			if not b["tpm"] or not b["secure_boot"]:
				return "«Этот компьютер не соответствует требованиям Windows 11» — включи TPM и Secure Boot в BIOS."
	return ""


func do_backup(pc: Dictionary) -> String:
	if not has_tool("extdisk"):
		return "Нужен внешний диск для бэкапов (магазин → инструменты)."
	if not pc.get("files", false):
		return "Файлов клиента на этом ПК нет."
	pc["backup"] = true
	touch()
	return "Файлы клиента сохранены на внешний диск."


func install_os(pc: Dictionary, os_id: String, pay: bool = true) -> String:
	if pay:
		money -= int(Data.os_list[os_id]["price"])
	_wipe(pc)
	pc["os"] = os_id
	touch()
	return "Установлена %s! Не забудь драйверы." % Data.os_list[os_id]["name"]


func os_install_time(pc: Dictionary, os_id: String) -> float:
	var sp := float(pdata(pc, "storage")["speed"])
	return float(Data.os_list[os_id]["time"]) * (1.4 if sp < 20 else 0.7)


func drivers_possible(pc: Dictionary, os_id: String) -> bool:
	var gen := int(Data.os_list[os_id]["gen"])
	var gy := int(pdata(pc, "gpu")["year"])
	return not (gen <= 4 and gy >= 2016) and not (gen >= 8 and gy < 2006)


func can_drivers(pc: Dictionary) -> String:
	var e := check_running(pc)
	if e != "":
		return e
	if pc["drivers"]:
		return "Драйверы уже стоят."
	var gen := int(Data.os_list[pc["os"]]["gen"])
	var gy := int(pdata(pc, "gpu")["year"])
	if gen <= 4 and gy >= 2016:
		return "Под %s драйверов для этой видеокарты не существует!" % Data.os_list[pc["os"]]["name"]
	if gen >= 8 and gy < 2006:
		return "Под %s нет драйверов для такой старой видеокарты." % Data.os_list[pc["os"]]["name"]
	return ""


# ---------- игры ----------

func can_game(pc: Dictionary, gid: String) -> String:
	var e := check_running(pc)
	if e != "":
		return e
	var g: Dictionary = Data.games[gid]
	var o: Dictionary = Data.os_list[pc["os"]]
	if int(g["year"]) > year():
		return "%s ещё не вышла." % g["name"]
	if pc["games"].has(gid):
		return "Уже установлена."
	if int(o["gen"]) < int(g["min_gen"]):
		return "%s не запускается на %s." % [g["name"], o["name"]]
	if int(o["gen"]) > int(g.get("max_gen", 99)):
		return "%s не работает на %s — слишком новая система." % [g["name"], o["name"]]
	if o["linux"] and g.get("no_linux", false):
		return "Античит %s не работает на Linux." % g["name"]
	if free_gb(pc) < float(g["gb"]):
		return "Не хватает места: нужно %s, свободно %s." % [Data.gb_text(g["gb"]), Data.gb_text(max(0.0, free_gb(pc)))]
	return ""


func game_source() -> String:
	return "Steam / Miron1126 Launcher" if year() >= 2003 else "диск с рынка"


func game_install_time(pc: Dictionary, gid: String) -> float:
	var g: Dictionary = Data.games[gid]
	var t: float = 1.0 + float(g["gb"]) / max(0.05, float(pdata(pc, "storage")["speed"]) * 0.3)
	return clamp(t, 1.0, 6.0)


# ============================ заказы ============================

const BROKEN_TEXT := {
	"psu": "Нажимаю кнопку — вообще ничего, даже вентиляторы не крутятся!",
	"ram": "Включается, шумит, пищит, а картинки нет.",
	"gpu": "Комп гудит, а монитор пишет «Нет сигнала».",
	"storage": "Пишет «No bootable device», а система же была!",
	"mobo": "Вообще мёртвый. Кажется, пахло горелым…",
	"cpu": "Вентиляторы крутятся, но ничего не грузится.",
}


func _pick(slot: String, y: int, cond: Callable, max_age: int = 8) -> Array:
	var res := []
	for id in Data.parts_for_slot(slot):
		var p := Data.part(id)
		if int(p["year"]) <= y and y - int(p["year"]) <= max_age and cond.call(p):
			res.append(id)
	return res


func random_pc(y: int) -> Dictionary:
	for attempt in 40:
		var mbs := _pick("mobo", y, func(_p): return true, 7)
		if mbs.is_empty():
			mbs = [Data.parts_for_slot("mobo")[0]]
		var mb_id: String = mbs.pick_random()
		var mb: Dictionary = Data.part(mb_id)
		var cpus := _pick("cpu", y, func(p): return p["socket"] == mb["socket"], 12)
		var rams := _pick("ram", y, func(p): return p["ram"] == mb["ram"], 12)
		var gpus := _pick("gpu", y, func(p): return p["bus"] == mb["bus"], 9)
		var stors := _pick("storage", y, func(p): return mb["stor"].has(p["iface"]), 10)
		if cpus.is_empty() or rams.is_empty() or gpus.is_empty() or stors.is_empty():
			continue
		var ids := {"mobo": mb_id, "cpu": cpus.pick_random(), "ram": rams.pick_random(), "gpu": gpus.pick_random(), "storage": stors.pick_random()}
		var coolers := _pick("cooler", y, func(_p): return true, 30)
		var pc := make_pc(ids)
		var best_c := ""
		for c in coolers:
			pc["parts"]["cooler"] = {"id": c, "health": 100}
			if temp(pc) < 75.0:
				best_c = c
				if randf() < 0.5:
					break
		if best_c == "":
			best_c = coolers[-1]
		pc["parts"]["cooler"] = {"id": best_c, "health": 100}
		var need := power_need(pc)
		var psus := _pick("psu", y, func(p): return int(p["watt"]) >= need and not p["cheap"], 30)
		if psus.is_empty():
			continue
		pc["parts"]["psu"] = {"id": psus[0] if randf() < 0.6 else psus.pick_random(), "health": 100}
		pc["os"] = best_os(pc, y)
		pc["drivers"] = true
		pc["bios"] = default_bios(pc)
		pc["files"] = randf() < 0.7
		pc["dust"] = randi_range(0, 30)
		pc["junk"] = float(pdata(pc, "storage")["gb"]) * randf_range(0.0, 0.015)
		for gid in Data.games_available(y):
			if randf() < 0.25 and can_game(pc, gid) == "" and free_gb(pc) > float(Data.games[gid]["gb"]) * 2.0:
				pc["games"].append(gid)
		return pc
	return {}


func best_os(pc: Dictionary, y: int) -> String:
	var list := Data.os_available(y)
	list.sort_custom(func(a, b): return int(Data.os_list[a]["year"]) > int(Data.os_list[b]["year"]))
	for id in list:
		if not Data.os_list[id]["linux"] and id != "dos" and os_hw_check(pc, id) == "":
			return id
	return "win95"


func gen_orders() -> void:
	orders = []
	var hi := 4 + stage
	var n := randi_range(2, hi)
	if stage >= 2:
		n = clamp(int(round(n * (1.7 - markup))), 1, hi + 1)
	var tries := 0
	while orders.size() < n and tries < 60:
		tries += 1
		var o := gen_order()
		if not o.is_empty():
			o["reward"] = int(int(o["reward"]) * markup * (1.0 + stage * 0.08))
			orders.append(o)


func gen_order() -> Dictionary:
	var y := year()
	var pc := random_pc(y)
	if pc.is_empty():
		return {}
	var types := ["broken", "broken", "os", "virus", "virus", "slow", "fps", "games"]
	var otype: String = types.pick_random()
	var value := 0
	for s in Data.SLOTS:
		value += Data.price_in(pc["parts"][s]["id"], y)
	var tier: int = clamp(value / 600, 0, 4)
	var o := {"client": Data.CLIENTS.pick_random(), "type": otype, "pc": pc, "tier": tier, "year": y}
	pc["user"] = String(o["client"]).split(" ")[-1].replace("»", "")
	match otype:
		"broken":
			var slot: String = ["psu", "ram", "gpu", "storage", "mobo", "cpu"].pick_random()
			pc["parts"][slot]["health"] = 0
			if slot == "storage":
				pc["files"] = false
			o["text"] = BROKEN_TEXT[slot]
			o["req"] = "ПК включается и загружает ОС"
			o["reward"] = 30 + int(Data.price_in(pc["parts"][slot]["id"], y) * 1.4) + (25 if slot == "storage" else 0)
		"os":
			var choices := []
			for id in Data.os_available(y):
				if os_hw_check(pc, id) == "" and id != "dos" and id != pc["os"] and drivers_possible(pc, id):
					choices.append(id)
			if choices.is_empty():
				return {}
			var want: String = choices.pick_random()
			pc["os"] = ""
			pc["games"] = []
			pc["junk"] = 0.0
			o["want"] = want
			o["text"] = "Поставьте мне %s, пожалуйста!" % Data.os_list[want]["name"]
			o["req"] = "Установлена %s + драйверы" % Data.os_list[want]["name"]
			o["reward"] = 30 + int(Data.os_list[want]["price"]) + 10 * tier
		"virus":
			var pool := viruses_for_year(y, false)
			pool.shuffle()
			var cnt: int = min(pool.size(), randi_range(1, 3))
			for i in cnt:
				pc["viruses"].append(pool[i])
			var ransoms := viruses_for_year(y).filter(func(v): return int(Data.viruses[v]["level"]) == 3)
			if not ransoms.is_empty() and randf() < 0.25:
				pc["viruses"] = [ransoms.pick_random()]
				pc["files"] = false
				o["text"] = "Все файлы зашифровались, на экране требуют выкуп!!!"
			else:
				o["text"] = ["Комп ведёт себя странно, что-то сам делает…", "Тормозит и показывает какую-то ерунду.", "Друзья говорят, с моей почты рассылают письма."].pick_random()
			o["req"] = "Ни одного вируса, ПК загружается"
			o["reward"] = 25 + 20 * pc["viruses"].size() + 10 * tier
		"slow":
			pc["dust"] = randi_range(75, 100)
			pc["paste"] = randi_range(0, 20)
			pc["junk"] = float(pc["junk"]) + max(0.0, free_gb(pc)) * randf_range(0.4, 0.8)
			var t_pc := pc.duplicate(true)
			t_pc["dust"] = 0
			t_pc["paste"] = 100
			var t_best := temp(t_pc)
			for c in Data.available("cooler", y):
				t_pc["parts"]["cooler"] = {"id": c, "health": 100}
				t_best = min(t_best, temp(t_pc))
			o["temp_limit"] = max(80, int(ceil(t_best)) + 3)
			o["text"] = "Комп жутко греется, воет как самолёт и тормозит."
			o["req"] = "Температура < %d°C, пыль < 20%%, мусор < %s" % [o["temp_limit"], Data.gb_text(junk_limit(pc))]
			o["reward"] = 40 + 10 * tier
		"fps":
			if not _make_fps_order(o):
				return {}
		"games":
			var avail := []
			for gid in Data.games_available(y):
				if not pc["games"].has(gid) and can_game(pc, gid) == "" and y - int(Data.games[gid]["year"]) <= 6 and not Data.games[gid].has("miron"):
					avail.append(gid)
			avail.shuffle()
			if avail.size() < 2:
				return {}
			var need := float(Data.games[avail[0]]["gb"]) + float(Data.games[avail[1]]["gb"])
			if need > free_gb(pc) + float(pc["junk"]):
				return {}
			o["want_games"] = [avail[0], avail[1]]
			if randf() < 0.5:
				pc["junk"] = float(pc["junk"]) + max(0.0, free_gb(pc) - need * 0.8)
			o["text"] = "Установите мне %s и %s!" % [Data.games[avail[0]]["name"], Data.games[avail[1]]["name"]]
			o["req"] = "Обе игры установлены"
			o["reward"] = 25 + 5 * tier
	o["had_files"] = pc.get("files", false)
	o["orig"] = {}
	for s in Data.SLOTS:
		o["orig"][s] = {"id": pc["parts"][s]["id"], "broken": float(pc["parts"][s]["health"]) <= 0.0}
	return o


func _make_fps_order(o: Dictionary) -> bool:
	var pc: Dictionary = o["pc"]
	var y: int = o["year"]
	var cands := Data.games_available(y).filter(func(g): return y - int(Data.games[g]["year"]) <= 4 and not Data.games[g].has("miron"))
	cands.shuffle()
	var mb := pdata(pc, "mobo")
	for gid in cands:
		var g: Dictionary = Data.games[gid]
		var test := pc.duplicate(true)
		if can_game(pc, gid) != "" or float(g["gb"]) > free_gb(pc) + float(pc["junk"]) - 0.001:
			continue
		if randf() < 0.3 and fps(pc, gid) >= 60.0:
			pc["drivers"] = false
			o["game"] = gid
			o["text"] = "Хочу играть в %s на 60 FPS, а у меня слайд-шоу!" % g["name"]
			o["req"] = "%s установлена и выдаёт 60+ FPS на средних" % g["name"]
			o["reward"] = 60 + 15 * int(o["tier"])
			return true
		if fps(pc, gid) >= 60.0:
			continue
		var best := ""
		for gpu_id in Data.available("gpu", y):
			if Data.part(gpu_id)["bus"] != mb["bus"]:
				continue
			test["parts"]["gpu"] = {"id": gpu_id, "health": 100}
			if fps(test, gid) >= 60.0 and (best == "" or Data.price_in(gpu_id, y) < Data.price_in(best, y)):
				best = gpu_id
		if best == "":
			continue
		test["parts"]["gpu"] = {"id": best, "health": 100}
		var cost := Data.price_in(best, y)
		if not psu_ok(test):
			cost += 90
		o["game"] = gid
		o["text"] = "Хочу играть в %s хотя бы на 60 FPS на средних! Бюджет есть." % g["name"]
		o["req"] = "%s установлена и выдаёт 60+ FPS на средних" % g["name"]
		o["reward"] = 40 + int(cost * 1.35)
		return true
	return false


func take_order(i: int) -> void:
	current_order = orders[i]
	orders.remove_at(i)
	say("Взят заказ: %s — «%s»" % [current_order["client"], current_order["text"]])
	touch()


func order_failures(o: Dictionary) -> Array:
	var pc: Dictionary = o["pc"]
	var f := []
	var e := check_running(pc)
	if e != "":
		f.append(e)
	elif not psu_ok(pc):
		f.append("Блок питания слабый — ПК выключается под нагрузкой.")
	for s in Data.SLOTS:
		var orig: Dictionary = o["orig"][s]
		var cur = pc["parts"][s]
		if cur == null:
			f.append("Вы сняли деталь: " + Data.SLOT_NAMES[s])
		elif not orig["broken"] and int(Data.part(cur["id"])["price"]) < int(Data.part(orig["id"])["price"]) and int(Data.part(cur["id"])["year"]) <= int(Data.part(orig["id"])["year"]):
			f.append("Клиент: «Где моя %s?! Вы поставили хуже!»" % Data.part(orig["id"])["name"])
	if o.get("had_files", false) and not pc.get("files", true):
		f.append("Клиент: «ГДЕ МОИ ФОТКИ?!» — файлы удалены без бэкапа.")
	if f.is_empty():
		match o["type"]:
			"os":
				if pc["os"] != o["want"]:
					f.append("Установлена не та ОС.")
				elif not pc["drivers"]:
					f.append("Не установлены драйверы.")
				elif not pc.get("activated", true):
					f.append("Клиент: «Почему написано „Активируйте Windows“?»")
			"virus":
				if not pc["viruses"].is_empty():
					f.append("Клиент: «Всё ещё глючит!» — вирусы остались.")
			"slow":
				if temp(pc) >= float(o.get("temp_limit", 80)):
					f.append("Всё ещё греется: %d°C." % int(temp(pc)))
				if int(pc["dust"]) >= 20:
					f.append("Внутри всё в пыли.")
				if float(pc["junk"]) >= junk_limit(pc):
					f.append("На диске куча мусора.")
			"fps":
				if not pc["games"].has(o["game"]):
					f.append("Игра не установлена.")
				elif fps(pc, o["game"]) < 60.0:
					f.append("Только %d FPS — мало!" % int(fps(pc, o["game"])))
			"games":
				for gid in o["want_games"]:
					if not pc["games"].has(gid):
						f.append("Не установлена " + Data.games[gid]["name"])
	return f


func complete_order() -> void:
	var o := current_order
	var f := order_failures(o)
	if not f.is_empty():
		say("[color=#ef5350]Клиент недоволен:[/color] " + " ".join(f))
		return
	var bonus := 0
	if o["type"] != "virus" and o["pc"]["viruses"].is_empty() and o["pc"]["scanned"]:
		bonus = 10
	money += int(o["reward"]) + bonus
	rep += 1
	jobs_done += 1
	treats += 1
	say("[color=#66bb6a]Заказ выполнен! +$%d%s, репутация %d, +1 вкусняшка[/color]" % [o["reward"], (" (+$%d за проверку на вирусы)" % bonus) if bonus > 0 else "", rep])
	current_order = {}
	save_game()
	touch()


func refuse_order() -> void:
	var o := current_order
	var penalty := 0
	for s in Data.SLOTS:
		var orig: Dictionary = o["orig"][s]
		var cur = o["pc"]["parts"][s]
		if not orig["broken"] and (cur == null or cur["id"] != orig["id"]):
			penalty += int(Data.price_in(orig["id"], year()) * 1.5)
	money -= penalty
	rep = max(0, rep - (3 if penalty > 0 else 1))
	if penalty > 0:
		say("[color=#ef5350]Клиент забрал ПК без своих деталей и потребовал компенсацию: −$%d[/color]" % penalty)
	else:
		say("Вы отказались от заказа. Репутация −1.")
	current_order = {}
	touch()


func busya_hint(pc: Dictionary) -> String:
	for p in boot_problems(pc):
		if p["kind"] == "broken":
			_reveal(pc, p["slot"])
			touch()
			return "я понюхала... сломано: %s" % Data.SLOT_NAMES[p["slot"]]
		return p["text"]
	if temp(pc) > 90.0:
		return "горячо лапкам! Почисти пыль, поменяй пасту или поставь кулер получше"
	var o := os_state(pc)
	if o != "":
		return "на экране: " + o
	if not pc["drivers"]:
		return "поставь драйверы, картинка мутная"
	if not pc["viruses"].is_empty():
		for v in pc["viruses"]:
			if v == "boot":
				return "вирус сидит в загрузочной записи! Командная строка → help, там есть команда"
			if v == "macro":
				return "шаблон Word пахнет странно… Проводник → Шаблоны Office"
			if v == "spy":
				return "в диспетчере задач есть svch0st — с нулём вместо «о»! Заверши его и удали из автозагрузки"
			if v == "miner":
				return "кто-то под именем svchost жрёт процессор, и запущен он не от СИСТЕМЫ… Сядь за ПК → Диспетчер задач"
		return "чую вирусы: %d шт. Сканируй антивирусом или ищи их в диспетчере задач" % pc["viruses"].size()
	if not psu_ok(pc):
		return "блок питания слабоват для этого железа"
	if float(pc["junk"]) > junk_limit(pc):
		return "на диске много мусора, почисти"
	return "всё мурчит хорошо! Проверь требование заказа"


func buy_treat() -> void:
	if money < 5:
		return
	money -= 5
	treats += 1
	say("Куплена вкусняшка для Буси (−$5)")
	touch()


# ============================ магазин ============================

func buy_part(id: String) -> void:
	var price := Data.price_in(id, year())
	if money < price:
		say("Не хватает денег.")
		return
	money -= price
	inventory.append({"id": id, "health": 100})
	say("Куплено: %s (−$%d)" % [Data.part(id)["name"], price])
	touch()


func tool_available(id: String) -> bool:
	return int(Data.tools[id].get("year", 1995)) <= year()


func buy_tool(id: String) -> void:
	var price := int(Data.tools[id]["price"])
	if money < price or has_tool(id) or not tool_available(id):
		return
	money -= price
	tools.append(id)
	say("Куплен инструмент: %s" % Data.tools[id]["name"])
	touch()


func buy_game(id: String) -> void:
	var price := int(Data.games[id]["price"])
	if money < price or owned_games.has(id) or int(Data.games[id]["year"]) > year():
		return
	money -= price
	owned_games.append(id)
	say("Куплена игра: %s (%s)" % [Data.games[id]["name"], game_source()])
	touch()


func buy_key(os_id: String) -> void:
	var price := int(Data.os_list[os_id]["price"])
	if money < price:
		return
	money -= price
	keys.append(os_id)
	say("Куплен ключ %s (−$%d)" % [Data.os_list[os_id]["name"], price])
	touch()


func sell_price(item: Dictionary) -> int:
	var price := Data.price_in(item["id"], year())
	return max(1, int(price * (0.5 if float(item["health"]) > 0.0 else 0.05)))


func sell_item(i: int) -> void:
	var item: Dictionary = inventory[i]
	var p := sell_price(item)
	money += p
	inventory.remove_at(i)
	say("Продано: %s (+$%d)" % [Data.part(item["id"])["name"], p])
	touch()


# ============================ сохранение ============================

const SAVE_VERSION := 2


func save_game() -> void:
	var d := {"v": SAVE_VERSION, "money": money, "rep": rep, "day": day, "jobs_done": jobs_done, "tools": tools,
		"inventory": inventory, "owned_games": owned_games, "my_pc": my_pc, "orders": orders,
		"current_order": current_order, "log": log_lines.slice(-30), "pets": pets, "treats": treats, "keys": keys, "isos": isos, "flash": flash,
		"stage": stage, "benches": benches, "workers": workers, "candidates": candidates, "markup": markup,
		"transport": transport, "visits": visits, "club": club}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or int(d.get("v", 1)) != SAVE_VERSION:
		return false
	money = int(d.get("money", 300))
	rep = int(d.get("rep", 0))
	day = int(d.get("day", 1))
	jobs_done = int(d.get("jobs_done", 0))
	tools = d.get("tools", [])
	inventory = d.get("inventory", [])
	owned_games = d.get("owned_games", [])
	my_pc = d.get("my_pc", {})
	orders = d.get("orders", [])
	current_order = d.get("current_order", {})
	log_lines = d.get("log", [])
	pets = int(d.get("pets", 0))
	treats = int(d.get("treats", 3))
	keys = d.get("keys", [])
	isos = d.get("isos", [])
	flash = d.get("flash", {})
	stage = int(d.get("stage", 0))
	benches = int(d.get("benches", 1))
	workers = d.get("workers", [])
	candidates = d.get("candidates", [])
	markup = float(d.get("markup", 1.0))
	transport = int(d.get("transport", 0))
	visits = d.get("visits", [])
	club = d.get("club", {})
	for spc in club.get("seats", []):
		ensure_pc(spc)
	if candidates.is_empty():
		gen_candidates()
	if not my_pc.is_empty():
		ensure_pc(my_pc)
	return not my_pc.is_empty()


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))



# ============================ бизнес: переезды, верстаки, работники ============================

func stage_info(i: int = -1) -> Dictionary:
	return Data.STAGES[clamp(stage if i < 0 else i, 0, Data.STAGES.size() - 1)]


func can_move() -> String:
	if stage >= Data.STAGES.size() - 1:
		return "Ты уже в небоскрёбе — дальше только звёзды!"
	var nx := stage_info(stage + 1)
	if rep < int(nx["rep"]):
		return "Нужна репутация ★%d (сейчас ★%d)." % [nx["rep"], rep]
	if money < int(nx["cost"]):
		return "Нужно $%d на переезд (есть $%d)." % [nx["cost"], money]
	return ""


func move_up() -> String:
	var e := can_move()
	if e != "":
		return e
	var nx := stage_info(stage + 1)
	money -= int(nx["cost"])
	stage += 1
	benches = max(benches, 2 if stage == 1 else benches)
	say("[color=#ff8a1f][b]Переезд![/b] Теперь твоя мастерская — %s.[/color] %s" % [nx["name"], nx["desc"]])
	gen_candidates()
	touch()
	return ""


func bench_price() -> int:
	return int(stage_info()["bench_cost"]) * (1 + int(benches / 3))


func buy_bench() -> String:
	if benches >= int(stage_info()["benches"]):
		return "Больше верстаков сюда не влезет — нужен переезд."
	var pr := bench_price()
	if money < pr:
		return "Нужно $%d." % pr
	money -= pr
	benches += 1
	touch()
	return "Куплен верстак! Теперь их %d." % benches


func worker_expect(w: Dictionary) -> int:
	## Сколько работник хочет получать в день
	return int((12 + int(w["skill"]) * 10 + int(w["level"]) * 4) * (1.0 + (year() - 1995) * 0.06))


func worker_slots() -> int:
	return min(int(stage_info()["workers"]), benches - 1)


func gen_candidates() -> void:
	candidates = []
	if int(stage_info()["workers"]) == 0:
		return
	for i in 3:
		var sk := randi_range(1, min(5, 2 + stage))
		var w := {"name": Data.WORKER_NAMES.pick_random(), "skill": sk, "level": 1, "xp": 0, "mood": 70, "jobs": 0, "fails": 0}
		w["salary"] = worker_expect(w)
		candidates.append(w)


func hire(i: int) -> String:
	if workers.size() >= worker_slots():
		return "Нет свободного верстака — купи ещё один." if workers.size() < int(stage_info()["workers"]) else "Здесь больше нет места — нужен переезд."
	var w: Dictionary = candidates[i]
	candidates.remove_at(i)
	workers.append(w)
	say("Нанят работник [b]%s[/b] (навык %d, $%d в день)." % [w["name"], w["skill"], w["salary"]])
	touch()
	return ""


func fire(i: int) -> void:
	var w: Dictionary = workers[i]
	workers.remove_at(i)
	say("%s уволен(а)." % w["name"])
	touch()


func raise_salary(i: int, amount: int) -> void:
	var w: Dictionary = workers[i]
	w["salary"] = max(5, int(w["salary"]) + amount)
	w["mood"] = clamp(int(w["mood"]) + (8 if amount > 0 else -15), 0, 100)
	touch()


func give_bonus(i: int) -> String:
	var w: Dictionary = workers[i]
	var b := int(w["salary"]) * 2
	if money < b:
		return "Нужно $%d." % b
	money -= b
	w["mood"] = min(100, int(w["mood"]) + 30)
	say("%s получил(а) премию $%d и счастлив(а)!" % [w["name"], b])
	touch()
	return ""


func worker_day_estimate() -> int:
	var sum := 0
	for w in workers:
		var jobs := 1 + int(int(w["skill"]) / 2)
		sum += int(jobs * _job_pay(w) * (1.0 - _fail_chance(w))) - int(w["salary"])
	return sum


func _job_pay(w: Dictionary) -> float:
	return (35.0 + (year() - 1995) * 7.0) * (0.55 + int(w["skill"]) * 0.15) * markup


func _fail_chance(w: Dictionary) -> float:
	return max(0.03, 0.28 - int(w["skill"]) * 0.05)


func business_day() -> void:
	## Работники чинят компьютеры сами, получают зарплату; раз в 5 дней — аренда
	last_report = []
	var income := 0
	var salaries := 0
	var quit := []
	for w in workers:
		if w.get("away", false):
			w["away"] = false
			salaries += int(w["salary"])
			continue
		var jobs := 1 + int(int(w["skill"]) / 2)
		var ok := 0
		for j in jobs:
			if randf() < _fail_chance(w):
				w["fails"] = int(w.get("fails", 0)) + 1
				if randf() < 0.5:
					rep = max(0, rep - 1)
			else:
				ok += 1
				income += int(_job_pay(w))
				w["xp"] = int(w["xp"]) + 1
		w["jobs"] = int(w["jobs"]) + ok
		if ok >= 2 and randf() < 0.35:
			rep += 1
		if int(w["xp"]) >= 8 * int(w["level"]):
			w["xp"] = 0
			w["level"] = int(w["level"]) + 1
			if int(w["skill"]) < 5 and int(w["level"]) % 2 == 0:
				w["skill"] = int(w["skill"]) + 1
			last_report.append("%s повысил(а) уровень до %d!" % [w["name"], w["level"]])
		salaries += int(w["salary"])
		var expect := worker_expect(w)
		if int(w["salary"]) < int(expect * 0.9):
			w["mood"] = int(w["mood"]) - 12
		else:
			w["mood"] = min(100, int(w["mood"]) + 4)
		if int(w["mood"]) <= 0:
			quit.append(w)
	for w in quit:
		workers.erase(w)
		last_report.append("[color=#ef5350]%s уволился(ась): «Мало платите!»[/color]" % w["name"])
	money += income - salaries
	if not workers.is_empty():
		last_report.push_front("Работники починили компы на $%d, зарплаты $%d." % [income, salaries])
	if day % 5 == 0 and int(stage_info()["rent"]) > 0:
		var rent := int(stage_info()["rent"])
		var power := 10 + benches * 6 + workers.size() * 4
		money -= rent + power
		last_report.append("Аренда $%d и свет $%d." % [rent, power])
	if money < 0:
		var pct := int(ceil(-money * 0.04))
		money -= pct
		last_report.append("[color=#ef5350]Ты в минусе! Проценты по кредиту $%d.[/color]" % pct)
	gen_candidates()
	for l in last_report:
		say(l)



# ============================ Техноград: выезды на дом ============================

func districts_open() -> Array:
	var res := []
	for d in Data.DISTRICTS:
		if year() >= int(d["year"]):
			res.append(d)
	return res


func district(id: String) -> Dictionary:
	for d in Data.DISTRICTS:
		if d["id"] == id:
			return d
	return Data.DISTRICTS[0]


func can_reach(dist: int) -> bool:
	return dist <= int(Data.TRANSPORT[transport]["reach"])


func gen_visits() -> void:
	visits = []
	var n: int = clamp(1 + int(stage / 2) + randi_range(0, 1), 1, 4)
	var ds := districts_open()
	var tries := 0
	while visits.size() < n and tries < 30:
		tries += 1
		var d: Dictionary = ds.pick_random()
		var o := gen_order()
		if o.is_empty():
			continue
		o["client"] = d["clients"].pick_random()
		o["pc"]["user"] = String(o["client"]).split(" ")[-1].replace("»", "")
		o["visit"] = true
		o["district"] = d["id"]
		o["reward"] = int(int(o["reward"]) * float(d["mult"]) * (1.0 + float(Data.TRANSPORT[transport]["bonus"])) * markup) + 15 * (int(d["dist"]) + 1)
		o["text"] = "(вызов на дом) " + String(o["text"])
		visits.append(o)


func take_visit(i: int) -> String:
	if not current_order.is_empty():
		return "Сначала закончи текущий заказ."
	var o: Dictionary = visits[i]
	var d := district(o["district"])
	if not can_reach(int(d["dist"])):
		return "На велосипеде до района «%s» не доехать — нужна машина." % d["name"]
	current_order = o
	visits.remove_at(i)
	say("Выезд: %s, %s — «%s»" % [d["name"], o["client"], o["text"]])
	touch()
	return ""


func send_worker(i: int, wi: int) -> String:
	## Работник едет вместо тебя: успех зависит от навыка, работник занят до конца дня
	if wi < 0 or wi >= workers.size():
		return "Нет такого работника."
	var w: Dictionary = workers[wi]
	if w.get("away", false):
		return "%s уже на выезде." % w["name"]
	var o: Dictionary = visits[i]
	var d := district(o["district"])
	if not can_reach(int(d["dist"])):
		return "Нужна машина, чтобы доехать до района «%s»." % d["name"]
	visits.remove_at(i)
	w["away"] = true
	if randf() < _fail_chance(w) + 0.05 * int(d["dist"]):
		rep = max(0, rep - 1)
		say("[color=#ef5350]%s не справился(ась) с выездом в «%s». Клиент недоволен, репутация −1.[/color]" % [w["name"], d["name"]])
	else:
		var pay := int(int(o["reward"]) * 0.8)
		money += pay
		rep += 1
		w["xp"] = int(w["xp"]) + 2
		say("[color=#66bb6a]%s съездил(а) в «%s» и всё починил(а): +$%d, репутация +1.[/color]" % [w["name"], d["name"], pay])
	touch()
	return ""


func buy_transport(t: int) -> String:
	var tr: Dictionary = Data.TRANSPORT[t]
	if t <= transport:
		return "У тебя уже есть транспорт не хуже."
	if year() < int(tr["year"]):
		return "%s появится в %d году." % [tr["name"], tr["year"]]
	if money < int(tr["price"]):
		return "Нужно $%d." % tr["price"]
	money -= int(tr["price"])
	transport = t
	say("Куплен транспорт: [b]%s[/b]! Теперь можно ездить дальше." % tr["name"])
	touch()
	return ""



# ============================ компьютерный клуб ============================

func club_open() -> bool:
	return not club.is_empty()


func club_hit() -> String:
	var g := "doom2"
	for h in Data.CLUB_HITS:
		if year() >= int(h[0]) and Data.games.has(h[1]):
			g = h[1]
	return g


func club_target_fps() -> float:
	return 144.0 if year() >= 2012 else 60.0


func club_next_level() -> Dictionary:
	var lv := int(club.get("level", -1)) + 1
	return {} if lv >= Data.CLUB_LEVELS.size() else Data.CLUB_LEVELS[lv]


func club_upgrade() -> String:
	var nx := club_next_level()
	if nx.is_empty():
		return "Клуб уже максимальный!"
	if stage < int(nx["stage"]):
		return "Нужен этап мастерской: %s." % Data.STAGES[int(nx["stage"])]["name"]
	if money < int(nx["cost"]):
		return "Нужно $%d." % nx["cost"]
	money -= int(nx["cost"])
	if club.is_empty():
		club = {"level": 0, "seats": [], "extras": [], "price": club_default_price(), "last_tour": -99, "visitors": 0, "income": 0}
		say("[color=#ff8a1f][b]Открыт компьютерный клуб![/b][/color] Покупай игровые места и следи, чтобы хит эпохи шёл без лагов.")
	else:
		club["level"] = int(club["level"]) + 1
		say("[color=#ff8a1f]Клуб расширен: %s![/color]" % nx["name"])
	touch()
	return ""


func club_default_price() -> int:
	return 2 + int((year() - 1995) / 6)


func club_seat_build() -> Dictionary:
	## Готовый игровой ПК для клуба (средний для своего года) с хитом эпохи
	var best := {}
	var best_fps := -1.0
	var hit := club_hit()
	for i in 25:
		var pc := random_pc(year())
		if pc.is_empty():
			continue
		pc["files"] = false
		pc["dust"] = 0
		pc["junk"] = 0.0
		pc["games"] = []
		if can_game(pc, hit) == "":
			pc["games"].append(hit)
		var f := fps(pc, hit) if pc["games"].has(hit) else 0.0
		if f > best_fps:
			best_fps = f
			best = pc
	return best


func pc_value(pc: Dictionary) -> int:
	var v := 0
	for s in Data.SLOTS:
		if pc["parts"][s] != null:
			v += Data.price_in(pc["parts"][s]["id"], year())
	return v


func club_seat_price() -> int:
	return 300 + int(60 * (1.0 + (year() - 1995) * 0.12)) * 6


func club_buy_seat() -> String:
	if club.is_empty():
		return "Сначала открой клуб."
	var lv: Dictionary = Data.CLUB_LEVELS[int(club["level"])]
	if club["seats"].size() >= int(lv["seats"]):
		return "Все места заняты — расширь клуб."
	var pr := club_seat_price()
	if money < pr:
		return "Нужно $%d." % pr
	var pc := club_seat_build()
	if pc.is_empty():
		return "Не удалось собрать ПК, попробуй ещё раз."
	money -= pr
	pc["seat"] = club["seats"].size() + 1
	pc["user"] = "Club"
	club["seats"].append(pc)
	say("Куплено игровое место №%d." % pc["seat"])
	touch()
	return ""


func club_buy_extra(id: String) -> String:
	var ex: Dictionary = Data.CLUB_EXTRAS[id]
	if club.is_empty():
		return "Сначала открой клуб."
	if club["extras"].has(id):
		return "Уже есть."
	if year() < int(ex["year"]):
		return "%s появится в %d году." % [ex["name"], ex["year"]]
	if money < int(ex["price"]):
		return "Нужно $%d." % ex["price"]
	money -= int(ex["price"])
	club["extras"].append(id)
	say("В клубе появилось: [b]%s[/b]." % ex["name"])
	touch()
	return ""


func seat_state(pc: Dictionary) -> Dictionary:
	## Состояние места: ok / slow / broken, FPS в хите эпохи
	var hit := club_hit()
	var e := check_running(pc)
	if e != "":
		return {"state": "broken", "text": e, "fps": 0.0}
	if not pc["games"].has(hit):
		return {"state": "slow", "text": "Не установлена %s" % Data.games[hit]["name"], "fps": 0.0}
	if not active_viruses(pc).is_empty():
		return {"state": "slow", "text": "Вирусы!", "fps": fps(pc, hit)}
	var f := fps(pc, hit)
	if f < 30.0:
		return {"state": "slow", "text": "Лагает: %d FPS" % int(f), "fps": f}
	if f < club_target_fps() * 0.5:
		return {"state": "slow", "text": "%d FPS — маловато" % int(f), "fps": f}
	return {"state": "ok", "text": "%d FPS" % int(f), "fps": f}


func club_day() -> void:
	if club.is_empty():
		return
	var price := int(club.get("price", club_default_price()))
	var ok := 0
	var slow := 0
	var broken := 0
	for pc in club["seats"]:
		match seat_state(pc)["state"]:
			"ok":
				ok += 1
			"slow":
				slow += 1
			_:
				broken += 1
	# посетители: зависят от цены, репутации и эпохи
	var demand: float = (6.0 + rep * 0.08 + stage * 3.0) * clamp(1.6 - float(price) / max(1.0, club_default_price()) * 0.6, 0.2, 1.6)
	var hours := 0.0
	hours += min(ok * 8.0, demand * 4.0)
	hours += min(slow * 8.0, max(0.0, demand * 4.0 - hours)) * 0.4
	var visitors := int(hours / 3.0)
	var income := int(hours * price)
	if club["extras"].has("bar"):
		income += visitors * 2
	if club["extras"].has("console"):
		income += 60
	if club["extras"].has("vr"):
		income += 250
	var power: int = club["seats"].size() * (3 + int((year() - 1995) / 8))
	money += income - power
	club["visitors"] = visitors
	club["income"] = income - power
	if broken > 0 and randf() < 0.5:
		rep = max(0, rep - 1)
	# износ: пыль, поломки, вирусы
	for pc in club["seats"]:
		pc["dust"] = min(100, int(pc["dust"]) + randi_range(2, 5))
		pc["junk"] = float(pc["junk"]) + junk_limit(pc) * 0.15
		if randf() < 0.025:
			var sl: String = ["gpu", "ram", "storage", "psu", "cooler"].pick_random()
			if pc["parts"][sl] != null:
				pc["parts"][sl]["health"] = 0
		if not club["extras"].has("av") and randf() < 0.06:
			var vv: Array = viruses_for_year(year(), false)
			if not vv.is_empty():
				var v: String = vv.pick_random()
				if not pc["viruses"].has(v):
					pc["viruses"].append(v)
					pc["scanned"] = false
	last_report.append("Клуб: %d посетителей, доход $%d (рабочих мест %d, тормозят %d, сломано %d)." % [visitors, income - power, ok, slow, broken])
	say(last_report[-1])


func club_tournament() -> String:
	if club.is_empty():
		return "Нет клуба."
	if day - int(club.get("last_tour", -99)) < 5:
		return "Следующий турнир можно провести через %d дн." % (5 - (day - int(club["last_tour"])))
	var target := club_target_fps()
	var good := 0
	for pc in club["seats"]:
		var st := seat_state(pc)
		if st["state"] == "ok" and float(st["fps"]) >= target:
			good += 1
	if good < 4:
		return "Для турнира нужно 4 места, где %s идёт от %d FPS. Сейчас таких: %d." % [Data.games[club_hit()]["name"], int(target), good]
	club["last_tour"] = day
	var prize := 200 + (year() - 1995) * 40 + good * 30
	money += prize
	rep += 4
	say("[color=#ff8a1f][b]Турнир по %s проведён![/b][/color] Пришли зрители и стримеры: +$%d, репутация +4." % [Data.games[club_hit()]["name"], prize])
	touch()
	return ""
