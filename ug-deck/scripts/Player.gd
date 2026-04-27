extends Node
class_name Player

@export var max_hp: int = 80
@export var max_energy: int = 5

var current_hp: int
var current_energy: int
var block: int = 0
var attack_bonus: int = 0
var attack_bonus_turns: int = 0
var next_attack_multiplier: float = 1.0
var approved_with_4_turns: int = 0
var skip_next_player_turn: bool = false
var immune_to_enemy_attack_turns: int = 0


func _ready() -> void:
	reset_for_new_battle()


func reset_for_new_battle() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = 0
	attack_bonus = 0
	attack_bonus_turns = 0
	next_attack_multiplier = 1.0
	approved_with_4_turns = 0
	skip_next_player_turn = false
	immune_to_enemy_attack_turns = 0


func reset_for_new_turn() -> void:
	block = 0
	current_energy = max_energy

	if attack_bonus_turns > 0:
		attack_bonus_turns -= 1
		if attack_bonus_turns == 0:
			attack_bonus = 0

	if approved_with_4_turns > 0:
		approved_with_4_turns -= 1


func get_attack_damage(base_damage: int) -> int:
	var total_damage := base_damage + attack_bonus
	total_damage = int(ceil(total_damage * next_attack_multiplier))
	next_attack_multiplier = 1.0
	return total_damage


func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false

	current_energy -= amount
	return true


func gain_block(amount: int) -> void:
	block += amount


func lose_hp(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	_apply_approved_with_4_if_needed()


func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp = min(current_hp + amount, max_hp)


func take_damage(amount: int) -> void:
	if immune_to_enemy_attack_turns > 0:
		immune_to_enemy_attack_turns -= 1
		return

	var remaining_damage := amount

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)
		_apply_approved_with_4_if_needed()


func _apply_approved_with_4_if_needed() -> void:
	if current_hp <= 0 and approved_with_4_turns > 0:
		current_hp = 4
		approved_with_4_turns = 0


func is_dead() -> bool:
	return current_hp <= 0
