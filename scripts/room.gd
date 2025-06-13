extends Node2D


const CARD_WIDTH = 200
const ROOM_Y_POSITION = 400


var center_screen_x 
var dungeon_room = []


# Called when the node enters the scene tree for the first time.
func _ready():
	center_screen_x = get_viewport().size.x / 2
	update_draw_button_state()



func add_card_to_room(card):
	if card.has_meta("discarded") and card.get_meta("discarded") == true:
		return  # Do NOT re-add discarded cards
	if card not in dungeon_room:
		dungeon_room.insert(0, card)
		update_room_positions()
	else:
		animate_card_to_position(card, card.position_in_room)
	update_draw_button_state()  # Add this line!

func remove_card_from_room(card):
	if card in dungeon_room:
		dungeon_room.erase(card)
		update_room_positions()
	update_draw_button_state()  # Add this line!

	
	
func update_room_positions():
	for i in range(dungeon_room.size()):
		#set position based on index
		var new_position = Vector2 (calculate_card_position(i), ROOM_Y_POSITION) 
		var card = dungeon_room[i]
		card.position_in_room = new_position
		animate_card_to_position(card,new_position)
		
func calculate_card_position(index):
	var total_width = (dungeon_room.size() -1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width/2
	return x_offset
	
	
func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)
# Called every frame. 'delta' is the elapsed time since the previous frame.

func update_draw_button_state():
	print("Cards in room:", dungeon_room.size())
	if dungeon_room.size() <= 1:
		print("Enabling draw button")
		$"../NextRoomButton/Area2D/CollisionShape2D".disabled = false
		$"../NextRoomButton/Sprite2D".modulate = Color(1, 1, 1, 1) 
	else:
		print("Disabling draw button")
		$"../NextRoomButton/Area2D/CollisionShape2D".disabled = true
		$"../NextRoomButton/Sprite2D".modulate = Color(0.3, 0.3, 0.3, 1)  # darker grey

	
