extends Node
class_name Player

@export var max_hp: int = 80
@export var max_energy: int = 5

var current_hp: int
var current_energy: int
var block: int = 0
var attack_bonus: int = 0
var next_attack_flat_bonus: int = 0
# AGREGADO: Variable para el bonus fijo de defensa
var bonus_defensa: int = 0 
var defense_card_bonus: int = 0
var defense_card_bonus_turns: int = 0
var attack_bonus_turns: int = 0
var next_attack_multiplier: float = 1.0
var approved_with_4_turns: int = 0
var skip_next_player_turn: bool = false
var immune_to_enemy_attack_turns: int = 0
var extra_energy_next_turn: int = 0

# AGREGADO: Variable para guardar los estados (como "estres" o "distraccion")
var estados: Array = []

func _ready() -> void:
	reset_for_new_battle()

func reset_for_new_battle() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = 0
	attack_bonus = 0
	next_attack_flat_bonus = 0
	bonus_defensa = 0 # AGREGADO: Reset del bonus de defensa
	defense_card_bonus = 0
	defense_card_bonus_turns = 0
	attack_bonus_turns = 0
	next_attack_multiplier = 1.0
	approved_with_4_turns = 0
	skip_next_player_turn = false
	immune_to_enemy_attack_turns = 0
	extra_energy_next_turn = 0
	# AGREGADO: Limpiamos los estados al iniciar una batalla
	estados.clear()

func reset_for_new_turn() -> void:
	block = 0
	current_energy = max_energy

	if extra_energy_next_turn > 0:
		current_energy += extra_energy_next_turn
		extra_energy_next_turn = 0

	if tiene_estado("semana_sin_parciales"):
		current_energy += 1
	
	# AGREGADO: Lógica de Cansancio (-1 de energía al inicio del turno)
	if tiene_estado("cansancio"):
		current_energy = max(0, current_energy - 1)

	if attack_bonus_turns > 0:
		attack_bonus_turns -= 1
		if attack_bonus_turns == 0:
			attack_bonus = 0

	if defense_card_bonus_turns > 0:
		defense_card_bonus_turns -= 1
		if defense_card_bonus_turns == 0:
			defense_card_bonus = 0

	if approved_with_4_turns > 0:
		approved_with_4_turns -= 1

# MODIFICADO: Ahora incluye la reducción de daño por el estado "Débil"
func get_attack_damage(base_damage: int) -> int:
	var total_damage := float(base_damage + attack_bonus + next_attack_flat_bonus)
	
	# Si tiene el estado debil, hace 25% menos de daño
	if tiene_estado("debil") or tiene_estado("estres"):
		total_damage *= 0.75
		
	total_damage = ceil(total_damage * next_attack_multiplier)
	next_attack_multiplier = 1.0
	next_attack_flat_bonus = 0
	return int(total_damage)

func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false

	current_energy -= amount
	return true


func get_effective_card_cost(card_data: CardData, cards_played_this_turn: int) -> int:
	var total_cost := card_data.cost

	if cards_played_this_turn == 0 and tiene_estado("trabajo_practico_obligatorio"):
		total_cost += 1

	if cards_played_this_turn == 0 and tiene_estado("panico"):
		total_cost += 1

	if tiene_estado("bibliografia_extra") and (card_data.card_type == "skill" or card_data.card_type == "habilidad"):
		total_cost += 1

	if tiene_estado("habilidad_mas") and (card_data.card_type == "skill" or card_data.card_type == "habilidad"):
		total_cost += 1

	if tiene_estado("final_promocionado"):
		total_cost -= 1

	return max(total_cost, 0)


func get_draw_amount(base_amount: int) -> int:
	var total_draw := base_amount

	if tiene_estado("distraccion"):
		total_draw -= 1

	if tiene_estado("confusion"):
		total_draw -= 1

	if tiene_estado("bibliografia_extra"):
		total_draw -= 1

	if tiene_estado("semana_sin_parciales"):
		total_draw += 1

	return max(total_draw, 0)

# MODIFICADO: Agregada la lógica de Bonus de Defensa y Distracción
func gain_block(amount: int) -> void:
	var escudo_final := float(amount + bonus_defensa)
	
	# Si tiene el estado distraccion, gana 25% menos de escudo
	if tiene_estado("distraccion"):
		escudo_final *= 0.75

	if tiene_estado("defensa_menos"):
		escudo_final *= 0.75

	escudo_final += defense_card_bonus
		
	block += int(escudo_final)

# AGREGADO: Función para curar vida en combate
func curar(cantidad: int) -> void:
	var curacion_final := float(cantidad)
	
	# Si está cansado, se cura un 25% menos
	if tiene_estado("cansancio"):
		curacion_final *= 0.75
		
	current_hp = min(current_hp + int(curacion_final), max_hp)

func lose_hp(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	_apply_approved_with_4_if_needed()

func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp = min(current_hp + amount, max_hp)

# AGREGADO: Nueva lógica para aumentar la energía máxima
func increase_max_energy(amount: int) -> void:
	max_energy += amount
	current_energy += amount

# MODIFICADO: Agregada la lógica de Estrés
func take_damage(amount: int) -> void:
	if immune_to_enemy_attack_turns > 0:
		immune_to_enemy_attack_turns -= 1
		return

	var remaining_damage := amount

	# Si tiene el estado estres, recibe 25% más de daño
	if tiene_estado("estres"):
		remaining_damage = int(remaining_damage * 1.25)

	if tiene_estado("nervios_de_acero"):
		remaining_damage = int(remaining_damage * 0.75)

	if block > 0:
		var blocked_damage = min(block, remaining_damage)
		block -= blocked_damage
		remaining_damage -= blocked_damage

	if remaining_damage > 0:
		current_hp = max(current_hp - remaining_damage, 0)
		_apply_approved_with_4_if_needed()


func take_damage_ignoring_block(amount: int, ignored_block_ratio: float) -> void:
	if immune_to_enemy_attack_turns > 0:
		immune_to_enemy_attack_turns -= 1
		return

	var remaining_damage := amount

	if tiene_estado("estres"):
		remaining_damage = int(remaining_damage * 1.25)

	if tiene_estado("nervios_de_acero"):
		remaining_damage = int(remaining_damage * 0.75)

	if block > 0:
		var ignored_block: int = int(floor(block * ignored_block_ratio))
		var effective_block: int = max(block - ignored_block, 0)
		var blocked_damage: int = min(effective_block, remaining_damage)
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


func has_negative_state() -> bool:
	return not estados.is_empty()


func remove_state(nombre: String) -> bool:
	for index in range(estados.size()):
		if estados[index].nombre == nombre:
			estados.remove_at(index)
			return true
	return false


func remove_one_negative_state() -> bool:
	var removable_states := [
		"debil",
		"cansancio",
		"estres",
		"distraccion",
		"confusion",
		"bibliografia_extra",
		"trabajo_practico_obligatorio",
		"panico",
		"defensa_menos",
		"habilidad_mas",
	]
	for index in range(estados.size()):
		if removable_states.has(estados[index].nombre):
			estados.remove_at(index)
			return true
	return false


func queue_extra_energy_next_turn(amount: int) -> void:
	extra_energy_next_turn += amount

# NUEVAS FUNCIONES BÁSICAS: Para aplicar y consultar estados
func aplicar_estado(nombre: String, valor: int, duracion: int) -> void:
	estados.append({
		"nombre": nombre,
		"valor": valor,
		"duracion": duracion
	})

func tiene_estado(nombre: String) -> bool:
	for estado in estados:
		if estado.nombre == nombre:
			return true
	return false

func reducir_duracion_estados() -> void:
	for estado in estados:
		estado.duracion -= 1
		if estado.duracion <= 0 and estado.nombre == "bonus_defensa_temporal":
			bonus_defensa = max(bonus_defensa - int(estado.valor), 0)
		
	# Filtramos para quedarnos solo con los estados que aún tienen duración
	estados = estados.filter(func(estado): return estado.duracion > 0)
