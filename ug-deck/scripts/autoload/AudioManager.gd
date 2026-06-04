extends Node

# Cuántos sonidos pueden sonar a la misma vez sin cortarse
const NUM_SFX_PLAYERS = 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer

# Aquí es donde vas a arrastrar tus audios en el futuro
var sounds: Dictionary = {
	"ganar_escudo": preload("res://assets/sfx/ganar escudo.wav"),
	"romper_escudo": preload("res://assets/sfx/romper escudo.wav"),
	"abrir_casillero": preload("res://assets/sfx/item casillero.wav"),
	"comprar_item": preload("res://assets/sfx/comprar item.wav"),
	"descarte": preload("res://assets/sfx/Descarte mazo sonido.wav"),
	"buff_jugador": preload("res://assets/sfx/BUFF jugador.wav"),
	"debuff_jugador": preload("res://assets/sfx/DEBUFF JUGADOR.wav"),
	"curarse": preload("res://assets/sfx/curarse.wav"),
	"hit_jugador": preload("res://assets/sfx/hit jugador.wav"),
	"hit_integral": preload("res://assets/sfx/hit integral.wav"),
	"hit_tom_apostol": preload("res://assets/sfx/hit tom apostol 1.wav"),
}

var music: Dictionary = {
	"pencils_down": preload("res://assets/musica/Pencils_Down.mp3"),
}

func _ready() -> void:
	# 1. Crear reproductores de Efectos (SFX)
	for i in range(NUM_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		# Aquí le indicamos que vaya al canal de Efectos.
		# Más adelante podremos configurar este canal en el editor.
		# p.bus = "SFX" 
		add_child(p)
		_sfx_players.append(p)

	# 2. Crear reproductor de Música
	_music_player = AudioStreamPlayer.new()
	# _music_player.bus = "Music"
	add_child(_music_player)


# --- FUNCIÓN PARA EFECTOS DE SONIDO (CORTOS) ---
func play_sfx(sound_name: String, vol_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		push_warning("AudioManager: Efecto no encontrado -> " + sound_name)
		return

	# Buscar un reproductor que esté libre y no esté sonando
	for p in _sfx_players:
		if not p.playing:
			p.stream = sounds[sound_name]
			p.volume_db = vol_db
			p.play()
			return
			
	# Si todos están sonando a la vez, agarramos el primero a la fuerza
	var p = _sfx_players[0]
	p.stream = sounds[sound_name]
	p.volume_db = vol_db
	p.play()


# --- FUNCIÓN PARA MÚSICA DE FONDO (LARGA) ---
func play_music(music_name: String, vol_db: float = 0.0) -> void:
	if not music.has(music_name):
		push_warning("AudioManager: Música no encontrada -> " + music_name)
		return

	# Si ya está sonando esta misma canción, no la reiniciamos
	if _music_player.stream == music[music_name] and _music_player.playing:
		return 
		
	_music_player.stream = music[music_name]
	_music_player.volume_db = vol_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
