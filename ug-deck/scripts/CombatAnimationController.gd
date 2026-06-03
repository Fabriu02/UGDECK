extends Node
class_name CombatAnimationController

const CARD_PLACEHOLDER_SIZE := Vector2(84, 118)
const FLOAT_TEXT_RISE := Vector2(0, -42)

var battle_visuals: BattleVisuals
var animation_layer: Control
var draw_pile_area: Control
var discard_pile_area: Control
var hand_container: Control
var card_scene: PackedScene


func setup(
	new_battle_visuals: BattleVisuals,
	new_animation_layer: Control,
	new_draw_pile_area: Control,
	new_discard_pile_area: Control,
	new_hand_container: Control,
	new_card_scene: PackedScene
) -> void:
	battle_visuals = new_battle_visuals
	animation_layer = new_animation_layer
	draw_pile_area = new_draw_pile_area
	discard_pile_area = new_discard_pile_area
	hand_container = new_hand_container
	card_scene = new_card_scene


func play_sequence(events: Array) -> void:
	if events.is_empty():
		return

	for event in events:
		if not event is Dictionary:
			continue
		await _play_event(event)


func _play_event(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"played_card":
			await _animate_played_card(event)
		"death":
			await _animate_death(event)
		"damage":
			await _animate_damage(event)
		"shield":
			await _animate_aura(event, Color(0.2, 0.55, 1.0, 0.9), "+%d Escudo" % int(event.get("value", 0)))
		"heal":
			await _animate_aura(event, Color(0.25, 1.0, 0.42, 0.9), "+%d Vida" % int(event.get("value", 0)))
		"draw":
			await _animate_card_move(_get_control_center(draw_pile_area), _get_hand_target_position(), Color(0.92, 0.86, 0.48, 1.0))
			await _show_float_text(_get_hand_target_position() + Vector2(28, -20), "Robaste %d" % int(event.get("value", 1)), Color(1.0, 0.9, 0.45, 1.0))
		"discard":
			await _animate_card_move(Vector2(event.get("from_position", _get_hand_target_position())), _get_control_center(discard_pile_area), Color(0.8, 0.8, 0.86, 1.0))
		"energy":
			await _animate_aura(event, Color(1.0, 0.9, 0.2, 0.9), "+%d Energia" % int(event.get("value", 0)))
		"buff":
			await _animate_aura(event, Color(1.0, 0.82, 0.25, 0.9), String(event.get("label", "Mejora")))
		"debuff", "status":
			await _animate_aura(event, Color(0.72, 0.28, 1.0, 0.9), String(event.get("label", "Estado")))
		_:
			await get_tree().process_frame


func _animate_played_card(event: Dictionary) -> void:
	if card_scene == null or animation_layer == null:
		return

	var card_data: CardData = event.get("card_data", null)
	if card_data == null:
		return

	var card_ui: CardUI = card_scene.instantiate()
	animation_layer.add_child(card_ui)
	card_ui.setup(card_data)
	card_ui.disabled = true
	card_ui.global_position = Vector2(event.get("from_position", _get_hand_target_position()))
	card_ui.scale = Vector2.ONE
	card_ui.modulate.a = 1.0

	await get_tree().process_frame

	var target_position := _get_viewport_center() + Vector2(-85, 32)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_ui, "global_position", target_position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "scale", Vector2(0.72, 0.72), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "modulate:a", 0.0, 0.16).set_delay(0.12)
	await tween.finished
	card_ui.queue_free()


func _animate_damage(event: Dictionary) -> void:
	var source_actor := String(event.get("source", "player"))
	var target_actor := String(event.get("target", "enemy"))
	var source_index := int(event.get("source_index", -1))
	var target_index := int(event.get("target_index", -1))
	var source := _get_actor_sprite(source_actor, source_index)
	var target := _get_actor_sprite(target_actor, target_index)
	if source == null or target == null:
		return

	if source_actor == target_actor:
		battle_visuals.play_character_animation(target_actor, "hurt", target_index)
		await _flash_and_shake(target, Color(1.0, 0.18, 0.18, 1.0))
		await _show_float_text(target.global_position + Vector2(-12, -70), "-%d" % int(event.get("value", 0)), Color(1.0, 0.18, 0.18, 1.0))
		return

	battle_visuals.play_character_animation(source_actor, "attack", source_index)

	var source_origin := source.position
	var direction := (target.global_position - source.global_position).normalized()
	var lunge_offset := direction * 28.0

	var lunge := create_tween()
	lunge.tween_property(source, "position", source_origin + lunge_offset, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lunge.tween_property(source, "position", source_origin, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await lunge.finished

	await _animate_projectile(source.global_position, target.global_position, Color(1.0, 0.22, 0.16, 1.0))
	battle_visuals.play_character_animation(target_actor, "hurt", target_index)
	await _flash_and_shake(target, Color(1.0, 0.18, 0.18, 1.0))
	await _show_float_text(target.global_position + Vector2(-12, -70), "-%d" % int(event.get("value", 0)), Color(1.0, 0.18, 0.18, 1.0))


func _animate_aura(event: Dictionary, color: Color, text: String) -> void:
	var source_actor := String(event.get("source", "player"))
	var target_actor := String(event.get("target", "player"))
	var source_index := int(event.get("source_index", -1))
	var target_index := int(event.get("target_index", -1))
	var target := _get_actor_sprite(target_actor, target_index)
	if target == null:
		return

	match String(event.get("type", "")):
		"shield":
			battle_visuals.play_character_animation(target_actor, "defend", target_index)
		"buff":
			battle_visuals.play_character_animation(target_actor, "buff", target_index)
		"debuff", "status":
			battle_visuals.play_character_animation(source_actor, "debuff", source_index)

	var ring := ColorRect.new()
	ring.color = color
	ring.size = Vector2(90, 90)
	ring.pivot_offset = ring.size / 2.0
	ring.global_position = target.global_position - ring.size / 2.0
	ring.scale = Vector2(0.35, 0.35)
	ring.modulate.a = 0.0
	animation_layer.add_child(ring)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.18, 1.18), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.55, 0.10)
	tween.tween_property(ring, "modulate:a", 0.0, 0.18).set_delay(0.12)
	await tween.finished
	ring.queue_free()

	await _show_float_text(target.global_position + Vector2(-16, -76), text, color)


func _animate_death(event: Dictionary) -> void:
	var target_actor := String(event.get("target", "enemy"))
	var target_index := int(event.get("target_index", -1))
	var target := _get_actor_sprite(target_actor, target_index)
	if target == null:
		return

	await battle_visuals.play_character_death(target_actor, target_index)


func _animate_projectile(start_position: Vector2, end_position: Vector2, color: Color) -> void:
	var projectile := ColorRect.new()
	projectile.color = color
	projectile.size = Vector2(18, 18)
	projectile.pivot_offset = projectile.size / 2.0
	projectile.global_position = start_position
	animation_layer.add_child(projectile)

	var tween := create_tween()
	tween.tween_property(projectile, "global_position", end_position, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(projectile, "scale", Vector2(1.45, 1.45), 0.06)
	tween.tween_property(projectile, "modulate:a", 0.0, 0.08)
	await tween.finished
	projectile.queue_free()


func _animate_card_move(start_position: Vector2, end_position: Vector2, color: Color) -> void:
	var card := ColorRect.new()
	card.color = color
	card.size = CARD_PLACEHOLDER_SIZE
	card.pivot_offset = card.size / 2.0
	card.global_position = start_position - card.size / 2.0
	animation_layer.add_child(card)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "global_position", end_position - card.size / 2.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(0.76, 0.76), 0.28)
	await tween.finished
	card.queue_free()


func _flash_and_shake(node: Node2D, flash_color: Color) -> void:
	var original_position := node.position
	var original_modulate := node.modulate
	node.modulate = flash_color

	var tween := create_tween()
	tween.tween_property(node, "position", original_position + Vector2(7, 0), 0.035)
	tween.tween_property(node, "position", original_position + Vector2(-7, 0), 0.05)
	tween.tween_property(node, "position", original_position + Vector2(4, 0), 0.04)
	tween.tween_property(node, "position", original_position, 0.04)
	tween.tween_callback(func(): node.modulate = original_modulate)
	await tween.finished


func _show_float_text(position: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = position
	label.size = Vector2(180, 30)
	animation_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", position + FLOAT_TEXT_RISE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.20).set_delay(0.25)
	await tween.finished
	label.queue_free()


func _get_actor_sprite(actor: String, index: int = -1) -> Node2D:
	if battle_visuals == null:
		return null
	return battle_visuals.get_actor_visual_node(actor, index)


func _get_control_center(control: Control) -> Vector2:
	if control == null:
		return _get_viewport_center()
	return control.global_position + control.size / 2.0


func _get_hand_target_position() -> Vector2:
	if hand_container == null:
		return _get_viewport_center()
	return hand_container.global_position + Vector2(hand_container.size.x / 2.0, 40.0)


func _get_viewport_center() -> Vector2:
	return get_viewport().get_visible_rect().size / 2.0
