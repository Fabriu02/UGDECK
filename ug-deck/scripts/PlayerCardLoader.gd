extends RefCounted
class_name PlayerCardLoader

const CSV_FILE_NAME := "Cartas iniciales.xlsx - CARTAS PROTA.csv"
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
