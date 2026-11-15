extends Node
# Global state: loaded data, player customization, progress (saved to disk).

const SAVE_PATH := "user://save.json"

var actions: Dictionary = {}
var enemies: Dictionary = {}
var rooms: Array = []
var options: Dictionary = {}

var age_confirmed := false
var content_blur := false          # accessibility / safe option: hide explicit art
var room_unlocked := 0             # highest room index reachable
var character := {"style": "normal", "hair": "#2b2118", "body": "athletic", "chest": 1.0}

func _ready() -> void:
	actions = _load_json("res://data/actions.json")
	enemies = _load_json("res://data/enemies.json")
	rooms = _load_json("res://data/stages.json").get("rooms", [])
	options = _load_json("res://data/character_options.json")
	load_game()

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"room_unlocked": room_unlocked, "character": character, "blur": content_blur}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var d = JSON.parse_string(FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text())
	if d is Dictionary:
		room_unlocked = int(d.get("room_unlocked", 0))
		character = d.get("character", character)
		content_blur = bool(d.get("blur", false))

func unlocked_actions() -> Array:
	var out: Array = []
	for id in actions:
		if id.begins_with("_"):
			continue
		if int(actions[id].get("unlock_stage", 0)) <= room_unlocked:
			out.append(id)
	return out
