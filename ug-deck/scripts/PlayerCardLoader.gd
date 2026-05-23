extends RefCounted
class_name PlayerCardLoader

const CSV_FILE_NAME := "Cartas iniciales.xlsx - CARTAS PROTA.csv"
const STARTING_RARITY := "Desertor"
const STARTING_COPIES_PER_CARD := 2
const LEGACY_EFFECT_IDS := {
	"resumen": "basic_attack",
	"torta_frita": "basic_block",
	"mate_salvador": "mate_salvador",
	"trasnochar": "trasnochar",
	"usar_ia": "basic_attack",
	"machetearse": "machetearse",
	"aprobado_con_4": "aprobado_con_4",
	"faltazo": "faltazo",
	"senarse_en_el_fondo": "sentarse_fondo",
	"pasar_al_pizarron": "pasar_pizarron",
	"corte_de_luz": "corte_luz",
	"dormir_siesta_lavarse_la_geta": "dormir_siesta",
}


static func load_player_cards() -> Array[CardData]:
	var cards := EnemyCardLoader.load_cards_from_csv(CSV_FILE_NAME)

	for card in cards:
		if LEGACY_EFFECT_IDS.has(card.effect_id):
			card.effect_id = LEGACY_EFFECT_IDS[card.effect_id]

	print("DEBUG PlayerCardLoader: cargadas %d cartas del protagonista." % cards.size())
	return cards


static func load_starting_run_cards() -> Array[CardData]:
	var desertor_cards: Array[CardData] = []
	for card in load_player_cards():
		if card.rareza == STARTING_RARITY:
			desertor_cards.append(card)

	var starting_deck: Array[CardData] = []
	for card in desertor_cards:
		for copy_index in range(STARTING_COPIES_PER_CARD):
			starting_deck.append(_copy_card(card))

	print("Cartas Desertor encontradas: %d" % desertor_cards.size())
	print("Mazo inicial del protagonista: %d cartas" % starting_deck.size())
	return starting_deck


static func load_reward_options_by_rarity(rarity: String, amount: int = 3) -> Array[CardData]:
	return load_reward_options_by_rarities([rarity], amount)


static func load_reward_options_by_rarities(rarities: Array, amount: int = 3) -> Array[CardData]:
	var candidates: Array[CardData] = []
	for card in load_player_cards():
		if rarities.has(card.rareza):
			candidates.append(card)

	if candidates.size() < amount:
		push_warning("PlayerCardLoader: no hay suficientes cartas de rarezas '%s'. Se permitiran repetidas temporalmente." % ", ".join(rarities))

	var options: Array[CardData] = []
	var available := candidates.duplicate()
	for option_index in range(amount):
		if candidates.is_empty():
			break

		if available.is_empty():
			available = candidates.duplicate()

		var selected_index := randi() % available.size()
		options.append(_copy_card(available[selected_index]))
		available.remove_at(selected_index)

	return options


static func _copy_card(card: CardData) -> CardData:
	return CardData.new().setup(
		card.card_name,
		card.cost,
		card.card_type,
		card.value,
		card.description,
		card.effect_id,
		card.rareza,
		card.raw_effect_text,
		card.image_path
	)
