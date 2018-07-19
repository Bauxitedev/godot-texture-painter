extends Node

signal active_texture_changed(tex)


var brush = {
	"softness_slider": null,
	"size": 4,
	
	"color": Color(1.0, 1.0, 1.0, 1.0),
	"color_picker": null,
	"hardness": 0
}

var viewports = {
	"albedo": null,
	"roughness": null,
	"metalness": null,
	"emission": null,
}

var utility_viewports = {
	"position": null,
	"normal": null,
}

enum TextureType {
	Albedo,
	Roughness,
	Metalness,
	Emission,
}

var paint_viewport = {
	"cursor_node": null,
	"colorpicker_node": null,
}

var main = null

var active_texture = 0

func set_active_texture(tex):
	active_texture = tex
	Textures.current_slot = tex
	emit_signal("active_texture_changed", tex)

func _ready():
	pass

func store_textures_on_disk(base_path):
	for vp in utility_viewports:
		var viewport = utility_viewports[vp]
		viewport.get_texture().get_data().save_png(base_path + "/" + vp + ".png")

	for vp in viewports:
		var viewport = viewports[vp]
		viewport.get_texture().get_data().save_png(base_path + "/" + vp + ".png")