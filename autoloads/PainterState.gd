extends Node

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

func _ready():
	pass
