extends Node2D
const CARD_SCENE_PATH = "res://scenes/card.tscn"
const MAX_DECK_SIZE = 52

var suits = ["hearts", "diamonds", "clubs", "spades"]
var ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
var card_sprites = {}  # key: "A_of_Hearts", value: Texture2D
var dungeon_deck = []

func make_deck():
	for suit in suits:
		for rank in ranks:
			var card_info = {
				"rank": rank,
				"suit": suit,
				"sprite_key": rank + "_of_" + suit
			}
			dungeon_deck.append(card_info)

func load_card_sprites():
	for suit in suits:
		for rank in ranks:
			var key = rank + "_of_" + suit
			var path = "res://assets/cards/individual/%s.png" % key  # adjust path
			card_sprites[key] = load(path)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_card_sprites()
	make_deck()
	dungeon_deck.shuffle()
	print(dungeon_deck)
	

	
func draw_card():
	if dungeon_deck.is_empty():
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		return  # Nothing to draw

	var card_scene = preload(CARD_SCENE_PATH)
	
	# Get access to the dungeon room node
	var room_node = $"../Room"
	var cards_in_room = room_node.dungeon_room.size()
	var cards_needed = 4 - cards_in_room
	if cards_needed <= 0:
		return  # Room is already full

	var draw_count = min(cards_needed, dungeon_deck.size())

	for i in range(draw_count):
		var card_data = dungeon_deck.pop_front()

		var new_card = preload(CARD_SCENE_PATH).instantiate()
		new_card.name = "card"

		# Set card rank and suit
		new_card.set_card_data(card_data.rank, card_data.suit)

		# Set sprite texture
		var sprite_key = card_data.sprite_key
		if card_sprites.has(sprite_key):
			new_card.get_node("cardimage").texture = card_sprites[sprite_key]
		else:
			print("Missing texture for", sprite_key)

		# Add to scene
		$"../cardManager".add_child(new_card)
		room_node.add_card_to_room(new_card)


	# Update label AFTER drawing
	$RichTextLabel.text = str(dungeon_deck.size()) + "/" + str(MAX_DECK_SIZE)
	print(dungeon_deck.size())

	# If deck is empty after drawing, disable
	if dungeon_deck.is_empty():
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		
		
