extends Control
# Turn-based battle. Static scene + animation hooks (see play_anim).
# Rules:
#  - Yellow > Red > Blue > Yellow (x1.5 advantage, x0.6 disadvantage).
#  - After using an action it is on cooldown for N turns.
#  - Player arousal rises each turn and when attacking; at max -> climax: stamina loss, meter resets.
#  - Clothing comes off in steps as arousal rises.
#  - Stamina 0 -> player is defeated (non-explicit placeholder screen; see _on_defeat).

signal finished(won: bool)

const ADV := {"yellow": "red", "red": "blue", "blue": "yellow"}
const CLOTHING_STEPS := ["Jacket/Top", "Bra", "Bottom (pants/skirt)", "Underwear"]
const AROUSAL_MAX := 100

var room_index := 0
var enemies: Array[Fighter] = []
var stamina := 100
var stamina_max := 100
var arousal := 0
var cooldowns := {}                       # action_id -> turns left
var selected_action := ""
var busy := false

var log_label: RichTextLabel
var stats_label: Label
var action_box: HBoxContainer
var enemy_box: HBoxContainer
var avatar: ColorRect
var clothing_label: Label

func setup(room: int) -> void:
	room_index = room

func _ready() -> void:
	_build_ui()
	for id in GameState.rooms[room_index]:
		enemies.append(Fighter.make_enemy(id))
	_log("Room %d begins." % (room_index + 1))
	_refresh()

# ---------- UI (placeholder rectangles; replace with real sprites/AnimationPlayer) ----------
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color(0.08, 0.07, 0.1); bg.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(bg)
	avatar = ColorRect.new(); avatar.position = Vector2(120, 160); avatar.size = Vector2(180, 340)
	avatar.color = Color(GameState.character.hair); add_child(avatar)
	clothing_label = Label.new(); clothing_label.position = Vector2(110, 510); add_child(clothing_label)
	stats_label = Label.new(); stats_label.position = Vector2(20, 20); add_child(stats_label)
	enemy_box = HBoxContainer.new(); enemy_box.position = Vector2(640, 140); enemy_box.add_theme_constant_override("separation", 16); add_child(enemy_box)
	log_label = RichTextLabel.new(); log_label.position = Vector2(20, 560); log_label.size = Vector2(500, 150); add_child(log_label)
	action_box = HBoxContainer.new(); action_box.position = Vector2(540, 600); action_box.size = Vector2(720, 100); add_child(action_box)

func _refresh() -> void:
	stats_label.text = "Stamina %d/%d    Arousal %d/%d" % [stamina, stamina_max, arousal, AROUSAL_MAX]
	var removed := int(float(arousal) / AROUSAL_MAX * (CLOTHING_STEPS.size() + 0.999))
	removed = clamp(removed, 0, CLOTHING_STEPS.size())
	clothing_label.text = "Clothing removed: %d/%d" % [removed, CLOTHING_STEPS.size()]
	avatar.modulate = Color(1, 1 - 0.1 * removed, 1 - 0.1 * removed)  # placeholder; real art swaps layers by `removed`

	for c in enemy_box.get_children(): c.queue_free()
	for e in enemies:
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 220)
		b.text = "%s\n[%s]\nHP %d/%d\nExcite %d/%d%s" % [e.display_name, e.color, e.hp, e.max_hp, e.excite, e.excite_max, "\nOUT" if e.out else ""]
		b.disabled = e.out or selected_action == "" or busy
		b.pressed.connect(_on_enemy_pressed.bind(e))
		enemy_box.add_child(b)

	for c in action_box.get_children(): c.queue_free()
	for id in GameState.unlocked_actions():
		var a: Dictionary = GameState.actions[id]
		var cd: int = cooldowns.get(id, 0)
		var b := Button.new()
		b.text = a.name + ("\n(cd %d)" % cd if cd > 0 else "")
		b.disabled = cd > 0 or busy
		b.pressed.connect(_on_action_pressed.bind(id))
		action_box.add_child(b)

func _log(t: String) -> void:
	log_label.append_text(t + "\n")

# ---------- Player turn ----------
func _on_action_pressed(id: String) -> void:
	selected_action = id
	var a: Dictionary = GameState.actions[id]
	if a.targets == "all":
		_execute(id, _alive_enemies())
	else:
		_log("Choose a target (%s)." % a.name)
		_refresh()

func _on_enemy_pressed(target: Fighter) -> void:
	var a: Dictionary = GameState.actions[selected_action]
	var targets: Array[Fighter] = [target]
	if a.targets == "two":
		for e in _alive_enemies():
			if e != target and targets.size() < 2:
				targets.append(e)
	_execute(selected_action, targets)

func _alive_enemies() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for e in enemies:
		if not e.out: out.append(e)
	return out

func _color_mult(att: String, def: String) -> float:
	if att == "none" or def == "none": return 1.0
	if ADV.get(att, "") == def: return 1.5
	if ADV.get(def, "") == att: return 0.6
	return 1.0

func _execute(id: String, targets: Array[Fighter]) -> void:
	busy = true
	var a: Dictionary = GameState.actions[id]
	play_anim(a.get("anim", ""))
	for t in targets:
		if a.kind == "normal":
			var dmg := int(a.power * _color_mult(a.color, t.color))
			t.take_damage(dmg)
			_log("%s hits %s for %d." % [a.name, t.display_name, dmg])
		else:
			t.add_excite(int(a.enemy_excite))
			_log("%s affects %s." % [a.name, t.display_name])   # write your own text here
			if t.out: _log("%s is out of the fight." % t.display_name)
	_gain_arousal(int(a.get("arousal_gain", 3)))
	cooldowns[id] = int(a.cooldown) + 1   # +1 because it ticks down at end of this turn
	selected_action = ""
	_end_player_turn()

# ---------- Enemy turn + upkeep ----------
func _end_player_turn() -> void:
	if _alive_enemies().is_empty():
		_win(); return
	for e in _alive_enemies():
		var dmg := e.attack
		stamina = max(0, stamina - dmg)
		_log("%s attacks: -%d stamina." % [e.display_name, dmg])
	_gain_arousal(4)  # longer fights => higher meter
	for k in cooldowns.keys():
		cooldowns[k] = max(0, cooldowns[k] - 1)
	busy = false
	_refresh()
	if stamina <= 0:
		_on_defeat()

func _gain_arousal(n: int) -> void:
	arousal += n
	if arousal >= AROUSAL_MAX:
		arousal = 0
		stamina = max(0, stamina - 20)
		play_anim("player_climax")
		_log("Her arousal peaks! Stamina drops.")

func _win() -> void:
	_log("Room cleared!")
	if room_index >= GameState.room_unlocked and room_index + 1 < GameState.rooms.size():
		GameState.room_unlocked = room_index + 1
	GameState.save_game()
	busy = true
	await get_tree().create_timer(1.2).timeout
	finished.emit(true)

# Defeat: placeholder. You decide what scene plays here (see notes in chat).
func _on_defeat() -> void:
	busy = true
	_log("She collapses... Defeat.")
	play_anim("player_defeat")
	await get_tree().create_timer(1.5).timeout
	finished.emit(false)

# Hook for your art: later this will drive an AnimationPlayer / AnimatedSprite2D.
func play_anim(anim_name: String) -> void:
	if anim_name != "":
		print("[anim] ", anim_name)
