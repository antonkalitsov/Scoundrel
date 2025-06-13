extends Node2D
var card_being_dragged
var screen_size
var is_hovereing_on_card
var dungeon_room_reference
var dragged_card_previous_slot = null


const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	dungeon_room_reference = $"../Room"
	$"../inputManager".connect("left_mb_released", on_left_mb_released)
	
	# Re-enable discard slot collision for manual dragging
	# (no longer disabling it!)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			clamp(mouse_pos.y, 0, screen_size.y)) 



func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1, 1)
	card.get_node("Area2D/CollisionShape2D").disabled = false

	# If the card was in a slot, free up that slot
	if card.has_meta("slot"):
		var previous_slot = card.get_meta("slot")
		if previous_slot.card_in_slot == card:
			previous_slot.card_in_slot = null
		card.remove_meta("slot")

func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	var card_slot_found = raycast_check_for_card_slot()
	var is_diamond = card_being_dragged.suit == "diamonds"
	var was_in_middle = false

	if card_being_dragged.has_meta("slot"):
		var previous_slot = card_being_dragged.get_meta("slot")
		was_in_middle = previous_slot.name == "MiddleSlot"

	if card_slot_found:
		var is_middle = card_slot_found.name == "MiddleSlot"
		var is_discard = card_slot_found.name == "DiscardSlot"

		# Middle slot logic
		if is_middle:
			var existing = card_slot_found.card_in_slot
			if existing:
				if is_diamond:
					# Diamonds can't stack
					reset_card_position(card_being_dragged)
					dungeon_room_reference.add_card_to_room(card_being_dragged)
					card_being_dragged = null
					return
				else:
					# Remove the previous card if placing a new one (non-diamond)
					card_slot_found.card_in_slot = null


		# Discard logic
		# Discard logic
		if is_discard:
			if is_diamond:
				dungeon_room_reference.remove_card_from_room(card_being_dragged)
				send_to_discard_pile(card_being_dragged)
			else:
				# Don't allow discarding non-diamonds directly
				if was_in_middle:
					reset_card_position(card_being_dragged)
				else:
					dungeon_room_reference.add_card_to_room(card_being_dragged)
			card_being_dragged = null
			return


		# Place card in valid slot
		dungeon_room_reference.remove_card_from_room(card_being_dragged)
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = false
		card_slot_found.card_in_slot = card_being_dragged
		card_being_dragged.set_meta("slot", card_slot_found)

		# Only activate if not a diamond
		if is_middle and not is_diamond:
			activate_card(card_being_dragged)
	else:
		# Not placed on a valid slot
		if was_in_middle and is_diamond:
			# Return diamond to MiddleSlot
			var middle_slot = $"../MiddleSlot"
			card_being_dragged.position = middle_slot.position
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = false
			middle_slot.card_in_slot = card_being_dragged
			card_being_dragged.set_meta("slot", middle_slot)
		else:
			if was_in_middle:
				reset_card_position(card_being_dragged)
			else:
				dungeon_room_reference.add_card_to_room(card_being_dragged)




	card_being_dragged = null

func reset_card_position(card):
	if card.has_meta("slot"):
		var slot = card.get_meta("slot")
		card.position = slot.position

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	#assume first card has highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	#checking for highest z index
	for i in range (1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
		
	
func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_hovered_over_card(card):
	if !is_hovereing_on_card:
		is_hovereing_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		#check if hovered card is hovereing another
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered,true)
		else:
			is_hovereing_on_card = false

func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05,1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1.0,1.0)
		card.z_index = 1

func on_left_mb_released():
	if card_being_dragged:
		finish_drag()
		
		
func activate_card(card):
	var suit = card.suit
	var rank = card.rank
	var strength = get_card_strength(rank)

	match suit:
		"hearts":
			heal(strength)
			send_to_discard_pile(card)
		"spades":
			take_damage(strength)
			send_to_discard_pile(card)
		"clubs":
			take_damage(strength)
			send_to_discard_pile(card)
		"diamonds":
			weapon(strength)  # stays in middle until manually discarded
		_:
			print("Unknown suit:", suit)

			
func heal(strength):
	var player = $"../Player"
	var health_label = player.get_node("Health")
	var current_health = int(health_label.text)
	health_label.text = str(current_health + strength)
	if int(health_label.text) >=20:
		health_label.text = str(20)
		
func take_damage(strength):
	var player = $"../Player"
	var health_label = player.get_node("Health")
	var current_health = int(health_label.text)
	health_label.text = str(current_health - strength)
	#SWORD DMG LOGIC!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	if int(health_label.text) <=0:
		health_label.text = str(0)
		#game_over()!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
func weapon(strength):
	#weapon code
	pass

func get_card_strength(rank: String) -> int:
	match rank:
		"A":
			return 1
		"J":
			return 11
		"Q":
			return 12
		"K":
			return 13
		_:
			return int(rank)



func send_to_discard_pile(card):
	if has_node("../Discard"):
		var discard_node = get_node("../Discard")
		discard_node.add_child(card)
	var discard_slot = $"../DiscardSlot"
	card.set_meta("discarded", true)

	# Clean up previous slot
	if card.has_meta("slot"):
		var old_slot = card.get_meta("slot")
		if old_slot.card_in_slot == card:
			old_slot.card_in_slot = null
		card.remove_meta("slot")

	# Move to discard slot position
	card.position = discard_slot.position

	# Make it face down
	card.face_down()

	# Disable the card's interactivity
	card.get_node("Area2D/CollisionShape2D").disabled = true
	card.set_process(false)

	# Mark as occupying the discard slot
	card.set_meta("slot", discard_slot)
	discard_slot.card_in_slot = card

	# ✅ Mark this card as discarded
	card.set_meta("discarded", true)
