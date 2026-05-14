extends Node
class_name DeckManager

const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var played_cards: Array[CardData] = []


func create_starting_deck() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	played_cards.clear()

	var loaded_cards := PlayerCardLoader.load_player_cards()
	if loaded_cards.is_empty():
		push_warning("DeckManager: no se pudieron cargar cartas del protagonista desde CSV.")
	else:
		draw_pile.append_array(loaded_cards)

	shuffle_deck()


func _add_card(
	card_name: String,
	cost: int,
	card_type: String,
	value: int,
	description: String,
	effect_id: String
) -> void:
	draw_pile.append(CardData.new().setup(card_name, cost, card_type, value, description, effect_id))


func shuffle_deck() -> void:
	draw_pile.shuffle()


func draw_cards(amount: int) -> Array[CardData]:
	var drawn_cards: Array[CardData] = []

	for i in range(amount):
		if draw_pile.is_empty():
			reshuffle_discard_into_draw_pile()

		if draw_pile.is_empty():
			break

		var card: CardData = draw_pile.pop_back()
		hand.append(card)
		drawn_cards.append(card)

	return drawn_cards


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


func discard_played_cards() -> void:
	discard_pile.append_array(played_cards)
	played_cards.clear()


func discard_specific_card(card: CardData) -> bool:
	if not hand.has(card):
		return false

	hand.erase(card)
	discard_pile.append(card)
	return true


func reshuffle_discard_into_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_deck()

# AGREGADO: Función para descartar cartas de forma aleatoria
func discard_random_cards(amount: int) -> void:
	for i in range(amount):
		if hand.is_empty():
			return
			
		var index := randi() % hand.size()
		var card := hand[index]
		hand.remove_at(index)
		discard_pile.append(card)
