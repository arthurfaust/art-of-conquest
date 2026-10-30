extends Node

# Carrega a música tema globalmente
var snd_musica_tema = load("res://assets/sounds/musica_tema.mp3")
var bgm_player: AudioStreamPlayer

func _ready():
	if snd_musica_tema:
		bgm_player = AudioStreamPlayer.new()
		add_child(bgm_player)
		bgm_player.stream = snd_musica_tema
		
		# AJUSTE N3: Define o volume da música mais baixo (ex: -14 decibéis)
		# 0.0 é o volume original. Valores negativos deixam o som mais suave.
		bgm_player.volume_db = -15.0
		
		# Garante o loop infinito da música tema
		bgm_player.finished.connect(func(): bgm_player.play())
		bgm_player.play()
