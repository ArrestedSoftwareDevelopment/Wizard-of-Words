class_name PremiumGlyph
extends TextureRect

const GLYPH_SHADER := preload("res://shaders/glyph_alpha.gdshader")
const ATLAS_COLUMNS := 3
const ATLAS_ROWS := 2
const ATLAS_POSITIONS := {
	"d": Vector2i(0, 0),
	"t": Vector2i(1, 0),
	"*": Vector2i(2, 0),
	"D": Vector2i(0, 1),
	"T": Vector2i(1, 1),
}


func configure(atlas_path: String, premium_key: String) -> bool:
	var source := UiFactory.load_texture_any(atlas_path)
	if source == null or not ATLAS_POSITIONS.has(premium_key):
		return false
	var cell_size := Vector2(
		float(source.get_width()) / float(ATLAS_COLUMNS),
		float(source.get_height()) / float(ATLAS_ROWS)
	)
	var atlas_position: Vector2i = ATLAS_POSITIONS[premium_key]
	var region_texture := AtlasTexture.new()
	region_texture.atlas = source
	region_texture.region = Rect2(Vector2(atlas_position) * cell_size, cell_size)
	texture = region_texture
	set_anchors_preset(Control.PRESET_FULL_RECT)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = GLYPH_SHADER
	material = shader_material
	return true
