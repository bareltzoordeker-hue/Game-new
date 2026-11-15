class_name Fighter
extends RefCounted
# A combatant. For the player, "arousal" is the meter that fills as the fight drags on.
# For enemies, "excite" is the meter filled by special actions.

var display_name := ""
var color := "none"            # yellow / red / blue / none
var max_hp := 100
var hp := 100
var attack := 8
var excite := 0
var excite_max := 100
var out := false               # defeated or "finished"
var look := 0

func take_damage(n: int) -> void:
	hp = max(0, hp - n)
	if hp == 0:
		out = true

func add_excite(n: int) -> void:
	excite = min(excite_max, excite + n)
	if excite >= excite_max:
		out = true

static func make_enemy(id: String) -> Fighter:
	var d: Dictionary = GameState.enemies[id]
	var f := Fighter.new()
	f.display_name = d.name
	f.color = d.color
	f.max_hp = int(d.hp)
	f.hp = f.max_hp
	f.excite_max = int(d.excite_max)
	f.attack = int(d.attack)
	f.look = int(d.look)
	return f
