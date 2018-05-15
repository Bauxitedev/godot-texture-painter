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

var textures_node = null

var active_texture = 0

func set_active_texture(tex):
	active_texture = tex
	textures_node.current_slot = tex
	emit_signal("active_texture_changed", tex)

func _ready():
	pass
