extends Node
class_name Enemy

@export var max_hp: int = 50

var current_hp: int
var block: int = 0
var current_intent: String = "attack"
var intent_value: int = 8


func _ready() -> void:
	reset_for_new_battle()


func reset_for_new_battle() -> void:
	current_hp = max_hp
	block = 0
	current_intent = "attack"
	intent_value = 8


func take_damage(amount: int) -> void:
	var remaining_damage := amount

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)


func choose_next_intent() -> void:
	var roll := randi_range(0, 2)

	if roll == 0:
		current_intent = "attack"
		intent_value = 8
	elif roll == 1:
		current_intent = "attack"
		intent_value = 12
	else:
		current_intent = "block"
		intent_value = 6


func execute_intent(player: Player) -> void:
	if current_intent == "attack":
		player.take_damage(intent_value)
	elif current_intent == "block":
		block += intent_value


func get_intent_text() -> String:
	if current_intent == "attack":
		return "Intencion: Atacar %d" % intent_value
	if current_intent == "block":
		return "Intencion: Defenderse %d" % intent_value

	return "Intencion: Desconocida"


func is_dead() -> bool:
	return current_hp <= 0
