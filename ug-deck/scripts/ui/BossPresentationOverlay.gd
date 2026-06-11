extends CanvasLayer
class_name BossPresentationOverlay

signal presentation_finished

var color_rect: ColorRect
var texture_rect: TextureRect

func _ready() -> void:
	layer = 100 # Ensure it's on top of everything
	
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.modulate.a = 0.0 # Start transparent
	add_child(color_rect)
	
	texture_rect = TextureRect.new()
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.modulate.a = 0.0 # Start transparent
	add_child(texture_rect)

func play_presentation(boss_name: String) -> void:
	var path1 := ""
	var path2 := ""
	
	match boss_name:
		"El Oni":
			path1 = "res://assets/Presentaciones/Eloni1.png"
			path2 = "res://assets/Presentaciones/Eloni2.png"
		"Tom Apostol":
			path1 = "res://assets/Presentaciones/Tom apostol 1.png"
			path2 = "res://assets/Presentaciones/Tom apostol 2.png"
		"Pepo":
			path1 = "res://assets/Presentaciones/Pepo 1.png"
			path2 = "res://assets/Presentaciones/Pepo 2.png"
		"Tomás Khum":
			path1 = "res://assets/Presentaciones/Thomas 1.png"
			path2 = "res://assets/Presentaciones/Thomas 2.png"
		_:
			push_error("BossPresentationOverlay: Boss desconocido %s" % boss_name)
			presentation_finished.emit()
			queue_free()
			return
			
	var img1 = load(path1)
	var img2 = load(path2)
	
	if not img1 or not img2:
		push_error("BossPresentationOverlay: No se encontraron imagenes para %s" % boss_name)
		presentation_finished.emit()
		queue_free()
		return

	# Start tween sequence
	var tween = create_tween()
	
	# Step 1: Fade to black
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	
	# Step 2: Show Image 1
	tween.tween_callback(func(): texture_rect.texture = img1)
	tween.tween_property(texture_rect, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.5) # Wait showing image 1
	
	# Step 3: Flash to Image 2
	tween.tween_callback(func(): 
		texture_rect.texture = img2
		# Here we can play the sound effect later
		# AudioManager.play_sfx("impact")
		
		# Quick flash effect using color_rect
		color_rect.color = Color.WHITE
	)
	# Fade flash back to black quickly
	tween.tween_property(color_rect, "color", Color.BLACK, 0.2)
	tween.tween_interval(2.0) # Wait showing image 2
	
	# Step 4: Fade everything out
	tween.tween_property(texture_rect, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(color_rect, "modulate:a", 0.0, 1.0)
	
	# Step 5: Finish
	tween.tween_callback(func():
		presentation_finished.emit()
		queue_free()
	)
