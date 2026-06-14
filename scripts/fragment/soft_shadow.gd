extends RefCounted

const TEXTURE_SIZE := 64
const SHADOW_WIDTH_RATIO := 0.7
const SHADOW_OFFSET := Vector2(0.0, -4.0)

const SHADOW_SHADER_CODE := """
shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float softness : hint_range(0.01, 1.0) = 0.85;

void fragment() {
	vec2 centered_uv = (UV - vec2(0.5)) * 2.0;
	float distance_from_center = length(centered_uv);
	float alpha = 1.0 - smoothstep(1.0 - softness, 1.0, distance_from_center);
	COLOR = vec4(shadow_color.rgb, alpha * shadow_color.a);
}
"""


static func apply_to(shadow_sprite: Sprite2D, visual_sprite: Sprite2D) -> void:
	if shadow_sprite == null:
		return

	shadow_sprite.texture = _create_white_texture()
	shadow_sprite.material = _create_shadow_material()
	shadow_sprite.z_index = -1
	shadow_sprite.position = SHADOW_OFFSET
	shadow_sprite.scale = _get_shadow_scale(visual_sprite)


static func _create_white_texture() -> Texture2D:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


static func _create_shadow_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADOW_SHADER_CODE

	var material := ShaderMaterial.new()
	material.shader = shader
	return material


static func _get_shadow_scale(visual_sprite: Sprite2D) -> Vector2:
	var visual_width := float(TEXTURE_SIZE)
	if visual_sprite != null and visual_sprite.texture != null:
		visual_width = maxf(
			visual_sprite.texture.get_size().x * absf(visual_sprite.scale.x),
			float(TEXTURE_SIZE)
		)

	var scale_value := visual_width * SHADOW_WIDTH_RATIO / float(TEXTURE_SIZE)
	return Vector2(scale_value, scale_value)
