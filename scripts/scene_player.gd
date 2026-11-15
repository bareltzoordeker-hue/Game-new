extends Control
# Plays a data-driven scene (beats of image + text). Used when she chooses to give in.
# All explicit content lives in YOUR images and YOUR text in data/scenes.json - nothing explicit is hardcoded.

signal done

var scene: Dictionary
var beat := 0
var pic: TextureRect
var text: Label
var title: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var all: Array = GameState._load_json("res://data/scenes.json").get("scenes", [])
	var avail: Array = all.filter(func(s): return int(s.unlock_stage) <= GameState.room_unlocked)
	if avail.is_empty():
		done.emit(); return
	scene = avail.pick_random()
	var bg := ColorRect.new(); bg.color = Color.BLACK; bg.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(bg)
	pic = TextureRect.new(); pic.position = Vector2(240, 40); pic.size = Vector2(800, 520)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; add_child(pic)
	title = Label.new(); title.position = Vector2(20, 10); title.text = scene.room; add_child(title)
	text = Label.new(); text.position = Vector2(240, 580); text.size = Vector2(800, 100); text.autowrap_mode = TextServer.AUTOWRAP_WORD; add_child(text)
	var next := Button.new(); next.text = "Next"; next.position = Vector2(1100, 640); next.pressed.connect(_next); add_child(next)
	var skip := Button.new(); skip.text = "Skip"; skip.position = Vector2(1100, 600); skip.pressed.connect(func(): done.emit()); add_child(skip)
	_show()

func _show() -> void:
	text.text = scene.beats[beat]
	pic.texture = GameState.scene_texture(scene.id, beat)   # null until you add art

func _next() -> void:
	beat += 1
	if beat >= scene.beats.size():
		done.emit()
	else:
		_show()
