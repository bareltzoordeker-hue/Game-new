extends Control
# Flow: Age gate -> Menu (creator / room select) -> Battle -> back to menu.

var box: VBoxContainer

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR   # keep layout left-to-right even if the editor is Hebrew
	box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(440, 160)
	box.custom_minimum_size = Vector2(400, 0)
	add_child(box)
	if GameState.age_confirmed:
		_menu()
	else:
		_age_gate()

func _clear() -> void:
	for c in box.get_children(): c.queue_free()
	for c in get_children():
		if c != box: c.queue_free()

func _label(t: String) -> void:
	var l := Label.new(); l.text = t; l.autowrap_mode = TextServer.AUTOWRAP_WORD; box.add_child(l)

func _button(t: String, cb: Callable) -> void:
	var b := Button.new(); b.text = t; b.pressed.connect(cb); box.add_child(b)

func _age_gate() -> void:
	_clear()
	_label("This game contains adult content (nudity, sexual themes, violence) and is for adults aged 18+ only. All characters are adults.")
	_button("I am 18 or older - Enter", _confirm_age)
	_button("Exit", func(): get_tree().quit())

func _confirm_age() -> void:
	GameState.age_confirmed = true
	_menu()

func _menu() -> void:
	_clear()
	_label("TOWER OF DESIRE (working title)")
	_button("Character Creator", _creator)
	_button("Play / Select Room", _room_select)
	var cb := CheckButton.new(); cb.text = "Hide explicit art (blur mode)"; cb.button_pressed = GameState.content_blur
	cb.toggled.connect(_on_blur_toggled); box.add_child(cb)
	_button("Quit", func(): get_tree().quit())

func _on_blur_toggled(v: bool) -> void:
	GameState.content_blur = v
	GameState.save_game()

func _creator() -> void:
	_clear()
	var o: Dictionary = GameState.options
	_label("Character Creator (all characters are 18+)")
	var style := OptionButton.new()
	for s in o.styles: style.add_item(s)
	style.selected = max(0, o.styles.find(GameState.character.style))
	style.item_selected.connect(func(i): GameState.character.style = o.styles[i]); box.add_child(style)
	var body := OptionButton.new()
	for s in o.body_types: body.add_item(s)
	body.selected = max(0, o.body_types.find(GameState.character.body))
	body.item_selected.connect(func(i): GameState.character.body = o.body_types[i]); box.add_child(body)
	var hair := OptionButton.new()
	for s in o.hair_colors: hair.add_item(s)
	hair.item_selected.connect(func(i): GameState.character.hair = o.hair_colors[i]); box.add_child(hair)
	_label("Chest size")
	var sl := HSlider.new(); sl.min_value = o.chest_size.min; sl.max_value = o.chest_size.max; sl.step = 0.05
	sl.value = GameState.character.chest
	sl.value_changed.connect(func(v): GameState.character.chest = v); box.add_child(sl)
	_button("Save & Back", _save_and_back)

func _save_and_back() -> void:
	GameState.save_game()
	_menu()

func _room_select() -> void:
	_clear()
	_label("Select room")
	for i in range(GameState.room_unlocked + 1):
		if i >= GameState.rooms.size(): break
		_button("Room %d%s" % [i + 1, " (BOSS)" if i == GameState.rooms.size() - 1 else ""], _start_battle.bind(i))
	_button("Back", _menu)

func _start_battle(i: int) -> void:
	_clear()
	var battle := Control.new()
	battle.set_script(load("res://scripts/battle.gd"))
	battle.setup(i)
	battle.finished.connect(func(_won, willing):
		battle.queue_free()
		if willing: _play_scene()
		else: _room_select())
	add_child(battle)

func _play_scene() -> void:
	_clear()
	var sp := Control.new()
	sp.set_script(load("res://scripts/scene_player.gd"))
	sp.done.connect(_scene_done.bind(sp))
	add_child(sp)

func _scene_done(sp: Control) -> void:
	sp.queue_free()
	_room_select()
