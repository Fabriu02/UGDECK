extends CanvasLayer

var color_rect: ColorRect
var shader_material: ShaderMaterial
var is_transitioning := false

func _ready() -> void:
	layer = 120 # Por encima de toda la UI
	
	color_rect = ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_pixel_size = 128.0;

void fragment() {
	if (progress <= 0.0) {
		COLOR.a = 0.0;
	} else {
		float current_pixel_size = mix(1.0, max_pixel_size, progress);
		vec2 screen_size = vec2(textureSize(screen_texture, 0));
		vec2 pixelated_uv = floor(SCREEN_UV * screen_size / current_pixel_size) * current_pixel_size / screen_size;
		
		vec4 tex_color = texture(screen_texture, pixelated_uv);
		
		// Desvanecer a negro hacia el final de la transicion (progress=1.0)
		float fade = smoothstep(0.4, 1.0, progress);
		COLOR = mix(tex_color, vec4(0.0, 0.0, 0.0, 1.0), fade);
	}
}
"""
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	color_rect.material = shader_material
	
	add_child(color_rect)

func change_scene(path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Bloquear clicks
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.tween_method(_set_shader_progress, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	get_tree().change_scene_to_file(path)
	
	var tween2 = create_tween()
	tween2.tween_method(_set_shader_progress, 1.0, 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	
	await tween2.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

func _set_shader_progress(value: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("progress", value)
