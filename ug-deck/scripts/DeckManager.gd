extends Node
class_name DeckManager

const PlayerCardLoader := preload("res://scripts/PlayerCardLoader.gd")

signal deck_counts_changed

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var played_cards: Array[CardData] = []


func create_starting_deck() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	played_cards.clear()

	var loaded_cards := GameState.get_run_deck_copies()
	if loaded_cards.is_empty():
		push_warning("DeckManager: el mazo persistente de la run esta vacio.")
	else:
		draw_pile.append_array(loaded_cards)

	shuffle_deck()
	print_deck_debug_counts()


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

	print_deck_debug_counts()
	return drawn_cards


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	print_deck_debug_counts()


func discard_played_cards() -> void:
	discard_pile.append_array(played_cards)
	played_cards.clear()
	print_deck_debug_counts()


func discard_specific_card(card: CardData) -> bool:
	if not hand.has(card):
		return false

	hand.erase(card)
	discard_pile.append(card)
	print_deck_debug_counts()
	return true


func reshuffle_discard_into_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_deck()
	print_deck_debug_counts()

# AGREGADO: Función para descartar cartas de forma aleatoria
func discard_random_cards(amount: int) -> void:
	for i in range(amount):
		if hand.is_empty():
			return
			
		var index := randi() % hand.size()
		var card := hand[index]
		hand.remove_at(index)
		discard_pile.append(card)
	print_deck_debug_counts()


func print_deck_debug_counts() -> void:
	print("Mano actual: %d cartas" % hand.size())
	print("Mazo de robo: %d cartas" % draw_pile.size())
	print("Descarte: %d cartas" % discard_pile.size())
	deck_counts_changed.emit()
