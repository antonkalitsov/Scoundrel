extends Node2D

signal hovered
signal hovered_off

@export var rank: String
@export var suit: String
@export var sprite_frames: Dictionary





func set_card_data(_rank: String, _suit: String):
	rank = _rank
	suit = _suit
	update_sprite()

func update_sprite():
	var key = rank + "_of_" + suit
	if sprite_frames.has(key):
		$Sprite2D.texture = sprite_frames[key]
	else:
		print("No sprite found for ", key)

var position_in_room
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#ALL CARDS MUST BE CHILD OF CARD MANAGER
	get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
func face_down():
	var back_texture = preload("res://assets/cards/back.png")
	$cardimage.texture = back_texture
