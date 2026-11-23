extends Node

# Áudio global (autoload): música tema adaptativa, batimento de tensão
# e volumes de Música/Efeitos salvos entre as sessões.

const MUSIC_BUS = "Musica"
const SFX_BUS = "Efeitos"
const SETTINGS_PATH = "user://configuracoes.cfg"

# Cada clima ajusta o volume relativo da trilha e o filtro passa-baixa do canal
# de música. Filtro baixo = som abafado, distante; filtro aberto = som cheio.
const MOODS = {
	"menu": {"db": -17.0, "cutoff": 1200.0},
	"preparacao": {"db": -16.0, "cutoff": 2600.0},
	"batalha": {"db": -13.0, "cutoff": 20000.0},
	"perigo": {"db": -9.0, "cutoff": 20000.0},
	"fim": {"db": -19.0, "cutoff": 900.0}
}

# Batimento cardíaco sintetizado: duas pancadas graves ("tum-tum") por ciclo.
const MIX_RATE = 22050.0
const BEAT_PERIOD = 0.8
const BEAT_GAIN = 0.55

var snd_musica_tema = load("res://assets/sounds/musica_tema.mp3")
var bgm_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var heartbeat_playback: AudioStreamGeneratorPlayback
var heartbeat_time := 0.0
var heartbeat_gain := 0.0
var heartbeat_target := 0.0
var danger_active := false
var combat_active := false
var current_mood := ""
var music_volume := 0.8
var sfx_volume := 1.0
var lowpass: AudioEffectLowPassFilter
var mood_tween: Tween

func _ready():
	# A música continua tocando quando a partida está pausada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_buses()
	_load_settings()

	if snd_musica_tema:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.bus = MUSIC_BUS
		add_child(bgm_player)
		bgm_player.stream = snd_musica_tema
		bgm_player.volume_db = MOODS["menu"]["db"]
		# Garante o loop infinito da música tema
		bgm_player.finished.connect(func(): bgm_player.play())
		bgm_player.play()

	_create_heartbeat()
	set_mood("menu")

# Cria os canais de Música e Efeitos em código, para não depender do editor.
func _create_buses():
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	var music_index = AudioServer.get_bus_index(MUSIC_BUS)
	if AudioServer.get_bus_effect_count(music_index) == 0:
		lowpass = AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(music_index, lowpass)
	else:
		lowpass = AudioServer.get_bus_effect(music_index, 0) as AudioEffectLowPassFilter

func _create_heartbeat():
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.15
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.stream = generator
	heartbeat_player.bus = SFX_BUS
	add_child(heartbeat_player)

func _process(delta):
	# Suaviza a entrada e a saída do batimento.
	heartbeat_gain = move_toward(heartbeat_gain, heartbeat_target, delta * 1.5)
	if heartbeat_gain <= 0.0 and heartbeat_target <= 0.0:
		if heartbeat_player.playing:
			heartbeat_player.stop()
			heartbeat_playback = null
		return
	if not heartbeat_player.playing:
		heartbeat_player.play()
		heartbeat_playback = heartbeat_player.get_stream_playback()
		heartbeat_time = 0.0
	for _frame in range(heartbeat_playback.get_frames_available()):
		heartbeat_playback.push_frame(Vector2.ONE * _heartbeat_sample())

func _heartbeat_sample() -> float:
	heartbeat_time += 1.0 / MIX_RATE
	var t = fmod(heartbeat_time, BEAT_PERIOD)
	var sample = 0.0
	for beat in [[0.0, 1.0], [0.26, 0.7]]:
		var dt = t - beat[0]
		if dt >= 0.0 and dt < 0.22:
			# Tom grave que desce de 60 Hz, com decaimento rápido.
			sample += sin(TAU * (60.0 - dt * 60.0) * dt) * exp(-dt * 20.0) * beat[1]
	return sample * heartbeat_gain * BEAT_GAIN

# Troca o clima da trilha com uma transição suave.
func set_mood(mood: String):
	if not MOODS.has(mood) or mood == current_mood:
		return
	current_mood = mood
	if mood_tween:
		mood_tween.kill()
	mood_tween = create_tween().set_parallel(true)
	if bgm_player:
		mood_tween.tween_property(bgm_player, "volume_db", MOODS[mood]["db"], 1.2)
	if lowpass:
		mood_tween.tween_property(lowpass, "cutoff_hz", MOODS[mood]["cutoff"], 1.2)
	_update_heartbeat()

# Perigo: o inimigo está perto da bandeira azul.
func set_danger(active: bool):
	danger_active = active
	_update_heartbeat()

# Combate: o batimento acompanha o suspense antes do resultado.
func set_combat_tension(active: bool):
	combat_active = active
	_update_heartbeat()

func _update_heartbeat():
	var in_match = current_mood in ["batalha", "perigo"]
	heartbeat_target = 1.0 if combat_active or (danger_active and in_match) else 0.0

func set_music_volume(value: float):
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_save_settings()

func set_sfx_volume(value: float):
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_save_settings()

func _apply_bus_volume(bus_name: String, value: float):
	var index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))

func _load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = config.get_value("audio", "musica", music_volume)
		sfx_volume = config.get_value("audio", "efeitos", sfx_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "musica", music_volume)
	config.set_value("audio", "efeitos", sfx_volume)
	config.save(SETTINGS_PATH)
