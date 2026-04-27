extends Node
class_name DeckManager

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var played_cards: Array[CardData] = []


func create_starting_deck() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	played_cards.clear()

	_add_card("Resumen", 1, "attack", 16, "Inflinge 16 de dano. Tiene lagrimas y mate encima.", "basic_attack")
	_add_card("Torta frita", 1, "block", 2, "Otorga 2 de escudo. 900 pesos de pura gloria.", "basic_block")
	_add_card("Mate salvador", 2, "buff", 3, "Ganas +3 de ataque en los siguientes 2 turnos.", "mate_salvador")
	_add_card("Trasnochar", 1, "debuff", 5, "Pierdes 5 de vida, aumenta x2 tu proximo ataque.", "trasnochar")
	_add_card("Usar IA", 3, "attack", 9, "Inflinge 9 de dano. Un gran poder conlleva una gran cantidad de tokens.", "basic_attack")
	_add_card("Machetearse", 4, "attack", 0, "Inflige 80% de la vida actual del enemigo. Riesgo de expulsion.", "machetearse")
	_add_card("Aprobado con 4", 4, "skill", 4, "Si tu salud llega a 0 en los proximos 2 turnos, sobrevives con 4 de salud.", "aprobado_con_4")
	_add_card("Faltazo", 3, "debuff", 0, "Perdes el siguiente turno, pero sos inmune a cualquier ataque enemigo.", "faltazo")
	_add_card("Sentarse en el fondo", 2, "buff", 10, "Ganas 10 de escudo. Si conservas la carta al final del turno ganas 5 mas.", "sentarse_fondo")
	_add_card("Pasar al pizarron", 2, "buff", 10, "+10 de vida maxima.", "pasar_pizarron")
	_add_card("Corte de luz", 3, "skill", 0, "Descarta toda tu mano e invalida el turno actual del enemigo.", "corte_luz")
	_add_card("Dormir siesta", 1, "skill", 0, "Descartas una carta y robas otra del mazo de robo.", "dormir_siesta")

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


func reshuffle_discard_into_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_deck()
