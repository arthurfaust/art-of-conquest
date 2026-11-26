extends Node2D

# Trailer narrativo (cerca de 1 minuto) montado com os assets do jogo.
# Cada evento acontece em um segundo fixo da linha do tempo; gravado com o
# Movie Maker da Godot e FPS fixo, o vídeo sai idêntico a cada renderização.
# Como gravar: veja producao/trailer/README.md.

const W = 1920.0
const H = 1080.0
const IMG = "res://assets/images/"
const SND = "res://producao/trailer/sons/"
const GAME_SND = "res://assets/sounds/"
const BLUE = Color("3d8bff")
const RED = Color("ff4a3d")
const GOLD = Color("f0ce80")

var music: AudioStreamPlayer
var fade: ColorRect
var flash: ColorRect
var caption: Label
var caption_font: SystemFont
var scenes = {}

func _ready():
	get_window().content_scale_size = Vector2i(1920, 1080)
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_setup_audio()
	_build_overlay()
	scenes["campo"] = _build_field()
	scenes["pelotao"] = _build_platoon()
	scenes["lonas"] = _build_tarps()
	scenes["decisao"] = _build_decision()
	scenes["travessia"] = _build_crossing()
	scenes["titulo"] = _build_title()
	for scene in scenes.values():
		scene.hide()
	_timeline()

# ---------------------------------------------------------------- linha do tempo
func _timeline():
	# 1. O campo (0–10 s)
	_show_scene("campo", 0.0, 10.0)
	_at(2.0, func(): _caption("A trégua durou até o anoitecer.", 5.0))
	_at(3.2, func(): _boom(0.6))
	_at(7.6, func(): _boom(1.0))

	# 2. O pelotão (10–20 s)
	_show_scene("pelotao", 10.0, 20.0)
	_at(14.6, func(): _caption("O mais fraco do pelotão.", 4.4))

	# 3. As lonas (20–30 s)
	_show_scene("lonas", 20.0, 30.0)
	_at(23.4, func(): _sfx("rajada_lona.wav", -4.0))
	_at(24.6, func(): _caption("Do outro lado, ninguém sabe quem espera sob as lonas.", 4.6))
	_at(26.5, func(): _sfx("batimento_lento.wav", -6.0))

	# 4. A decisão (30–40 s)
	_show_scene("decisao", 30.0, 40.0)
	_at(30.0, func(): _music_to(-4.0, 20000.0, 2.0))
	_at(33.8, func(): _caption("Alguém precisa descobrir.", 4.4))

	# 5. A travessia (40–52 s)
	_show_scene("travessia", 40.0, 52.0)
	_at(40.0, func(): _music_to(-8.0, 20000.0, 1.5))
	_at(41.8, func(): _sfx("batimento_rapido.wav", -3.0))
	_at(48.6, func(): _caption("Ele não voltou. Mas agora todos sabem quem estava ali.", 3.4))

	# 6. Título (52–62 s)
	_show_scene("titulo", 52.0, 62.5)
	_at(52.0, func():
		_music_to(-2.0, 20000.0, 1.0)
		_boom(1.4))
	_at(55.2, func(): _caption("Cada peça revelada muda as chances.", 3.8))
	_at(59.6, func(): _caption("Art of Conquest · disponível para Windows", 2.4, 40))
	_at(60.5, func(): _music_to(-50.0, 20000.0, 2.0))

func _at(seconds: float, callback: Callable):
	get_tree().create_timer(seconds).timeout.connect(callback)

# Mostra a cena com entrada e saída em preto.
func _show_scene(scene_name: String, start: float, end: float):
	_at(start, func():
		for other in scenes.values():
			other.hide()
		scenes[scene_name].show()
		scenes[scene_name].get_meta("play").call()
		var tween = create_tween()
		tween.tween_property(fade, "color:a", 0.0, 0.8))
	_at(end - 0.7, func():
		var tween = create_tween()
		tween.tween_property(fade, "color:a", 1.0, 0.7))

# ---------------------------------------------------------------- áudio
func _setup_audio():
	# O trailer controla a própria trilha; a música global do jogo é reiniciada aqui.
	AudioManager.set_process(false)
	for bus_name in [AudioManager.MUSIC_BUS, AudioManager.SFX_BUS]:
		var index = AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, 0.0)
	music = AudioManager.bgm_player
	music.stop()
	# Cancela a transição de clima do jogo ("menu"), que abaixaria e abafaria a trilha.
	if AudioManager.mood_tween:
		AudioManager.mood_tween.kill()
	# Trilha em destaque desde o início, sem filtro (versão sem o vento de fundo).
	music.volume_db = -5.0
	AudioManager.lowpass.cutoff_hz = 20000.0
	music.play(0.0)

func _music_to(volume_db: float, cutoff: float, seconds: float):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(music, "volume_db", volume_db, seconds)
	tween.tween_property(AudioManager.lowpass, "cutoff_hz", cutoff, seconds)

func _sfx(file: String, volume_db: float = 0.0):
	var path = (GAME_SND if file.begins_with("som_") else SND) + file
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	player.bus = AudioManager.SFX_BUS
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

func _boom(intensity: float):
	_sfx("explosao_distante.wav", -8.0 + intensity * 4.0)
	flash.color = Color(1.0, 0.55, 0.25, 0.18 * intensity)
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.9)
	var shake = create_tween()
	for step in range(6):
		shake.tween_property(self, "position", Vector2(randf_range(-8, 8), randf_range(-5, 5)) * intensity, 0.04)
	shake.tween_property(self, "position", Vector2.ZERO, 0.05)

# ---------------------------------------------------------------- sobreposições
func _build_overlay():
	var layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var vignette = TextureRect.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 0.8))
	gradient.add_point(0.55, Color(0, 0, 0, 0.05))
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	vignette.texture = texture
	vignette.size = Vector2(W, H)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(vignette)
	var band = TextureRect.new()
	var band_gradient = Gradient.new()
	band_gradient.set_color(0, Color(0, 0, 0, 0))
	band_gradient.set_color(1, Color(0, 0, 0, 0.78))
	var band_texture = GradientTexture2D.new()
	band_texture.gradient = band_gradient
	band_texture.fill_from = Vector2(0, 0)
	band_texture.fill_to = Vector2(0, 1)
	band.texture = band_texture
	band.position = Vector2(0, H - 300)
	band.size = Vector2(W, 300)
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(band)
	flash = _rect(layer, Color(1, 1, 1, 0))
	caption_font = SystemFont.new()
	caption_font.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	caption = Label.new()
	caption.position = Vector2(0, 920)
	caption.size = Vector2(W, 100)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.label_settings = _text_settings(58, Color(0.96, 0.95, 0.9))
	caption.modulate.a = 0.0
	layer.add_child(caption)
	fade = _rect(layer, Color(0, 0, 0, 1))

func _caption(text: String, seconds: float, font_size: int = 58):
	caption.text = text
	caption.label_settings.font_size = font_size
	var tween = create_tween()
	tween.tween_property(caption, "modulate:a", 1.0, 0.7)
	tween.tween_interval(maxf(seconds - 1.4, 0.5))
	tween.tween_property(caption, "modulate:a", 0.0, 0.7)

func _text_settings(font_size: int, color: Color) -> LabelSettings:
	var settings = LabelSettings.new()
	settings.font = caption_font
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 10
	settings.outline_color = Color(0, 0, 0, 0.85)
	settings.shadow_size = 6
	settings.shadow_color = Color(0, 0, 0, 0.6)
	return settings

func _rect(parent: Node, color: Color) -> ColorRect:
	var rect = ColorRect.new()
	rect.color = color
	rect.size = Vector2(W, H)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

# ---------------------------------------------------------------- peças e cartões
func _sprite(parent: Node, file: String, pos: Vector2, size: float) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = load(IMG + file)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = Vector2.ONE * size / sprite.texture.get_size().x
	parent.add_child(sprite)
	return sprite

# Cartão de unidade: arte, borda do time, marcador de forma e legenda opcional.
func _card(parent: Node, file: String, center: Vector2, size: float, team_color: Color, title: String = "") -> Node2D:
	var card = Node2D.new()
	card.position = center
	parent.add_child(card)
	var border = ColorRect.new()
	border.name = "Border"
	border.color = team_color
	border.position = Vector2(-size / 2 - 5, -size / 2 - 5)
	border.size = Vector2(size + 10, size + 10)
	card.add_child(border)
	var art = _sprite(card, file, Vector2.ZERO, size)
	art.name = "Art"
	var marker = Polygon2D.new()
	marker.name = "Marker"
	var r = size * 0.07
	if team_color == RED:
		marker.polygon = PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.75), Vector2(-r, r * 0.75)])
	else:
		var points = PackedVector2Array()
		for i in range(16):
			points.append(Vector2.from_angle(TAU * i / 16) * r * 0.8)
		marker.polygon = points
	marker.color = team_color
	marker.position = Vector2(size / 2 - r * 1.8, -size / 2 + r * 1.8)
	card.add_child(marker)
	if title != "":
		var label = Label.new()
		label.text = title
		label.label_settings = _text_settings(int(size * 0.08) + 8, Color.WHITE)
		label.label_settings.font = null
		label.label_settings.outline_size = 6
		label.size = Vector2(size + 120, 40)
		label.position = Vector2(-(size + 120) / 2, size / 2 + 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
	return card

# Vira o cartão (como a revelação do jogo) e troca a arte no meio do giro.
func _flip(card: Node2D, file: String, seconds: float = 0.3) -> Tween:
	var base = card.scale
	var tween = create_tween()
	tween.tween_property(card, "scale:x", 0.02, seconds / 2).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		var art = card.get_node("Art") as Sprite2D
		var size = art.texture.get_size().x * art.scale.x
		art.texture = load(IMG + file)
		art.scale = Vector2.ONE * size / art.texture.get_size().x)
	tween.tween_property(card, "scale:x", base.x, seconds / 2).set_trans(Tween.TRANS_QUAD)
	return tween

func _smoke(parent: Node, amount: int, alpha: float):
	var particles = CPUParticles2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	particles.texture = texture
	particles.amount = amount
	particles.lifetime = 14.0
	particles.preprocess = 14.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(W * 0.7, H * 0.55)
	particles.position = Vector2(W * 0.4, H * 0.5)
	particles.direction = Vector2(1, -0.15)
	particles.spread = 15.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 55.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.color = Color(0.75, 0.72, 0.7, alpha)
	parent.add_child(particles)

func _scene() -> Node2D:
	var scene = Node2D.new()
	add_child(scene)
	move_child(scene, 0)
	return scene

func _board(parent: Node, origin: Vector2, cell: float) -> Node2D:
	var board = Node2D.new()
	board.position = origin
	parent.add_child(board)
	var art = _sprite(board, "tabuleiro_completo.png", Vector2(cell * 4, cell * 4), cell * 8)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var grid = Node2D.new()
	board.add_child(grid)
	grid.draw.connect(func():
		for i in range(9):
			grid.draw_line(Vector2(i * cell, 0), Vector2(i * cell, cell * 8), Color(0.7, 0.9, 1.0, 0.28), 2.0)
			grid.draw_line(Vector2(0, i * cell), Vector2(cell * 8, i * cell), Color(0.7, 0.9, 1.0, 0.28), 2.0))
	_sprite(board, "bandeira_azul.png", Vector2(cell * 4.5, cell * 0.5), cell * 0.95)
	_sprite(board, "bandeira_vermelha.png", Vector2(cell * 4.5, cell * 7.5), cell * 0.95)
	return board

# ---------------------------------------------------------------- cena 1: o campo
func _build_field() -> Node2D:
	var scene: Node2D
	var field: Sprite2D
	var flags: Array = []
	scene = _scene()
	_rect(scene, Color("0c0f12"))
	field = _sprite(scene, "tabuleiro_completo.png", Vector2(W * 0.5, W * 0.5), W)
	field.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	field.modulate = Color(0.88, 0.82, 0.9)
	_smoke(scene, 26, 0.13)
	for data in [["bandeira_azul.png", Vector2(250, 380)], ["bandeira_vermelha.png", Vector2(W - 250, 380)]]:
		var flag = _sprite(scene, data[0], data[1], 380)
		flag.offset = Vector2(0, -60)
		flag.modulate.a = 0.0
		flags.append(flag)
	scene.set_meta("play", func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(field, "position:y", H * 0.5 + 120, 10.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(field, "scale", field.scale * 1.08, 10.0)
		for i in range(flags.size()):
			var flag = flags[i]
			var appear = create_tween()
			appear.tween_interval(4.6 + i * 0.5)
			appear.tween_property(flag, "modulate:a", 1.0, 1.2)
			var sway = create_tween().set_loops()
			sway.tween_property(flag, "rotation", 0.06, 1.3).set_trans(Tween.TRANS_SINE)
			sway.tween_property(flag, "rotation", -0.04, 1.3).set_trans(Tween.TRANS_SINE))
	return scene

# ---------------------------------------------------------------- cena 2: o pelotão
func _build_platoon() -> Node2D:
	var scene: Node2D
	var cards: Array = []
	var agent: Node2D
	var subtitle: Label
	scene = _scene()
	_rect(scene, Color("0b1016"))
	var grid = Node2D.new()
	scene.add_child(grid)
	grid.draw.connect(func():
		for x in range(0, int(W), 80):
			grid.draw_line(Vector2(x, 0), Vector2(x, H), Color(0.3, 0.6, 1.0, 0.05), 1.0)
		for y in range(0, int(H), 80):
			grid.draw_line(Vector2(0, y), Vector2(W, y), Color(0.3, 0.6, 1.0, 0.05), 1.0))
	var units = [
		["4.Atirador de Elite.png", "ATIRADOR · N4", 330.0],
		["3.Lançador de Mísseis.png", "LANÇADOR · N3", 730.0],
		["2.Fuzileiro.png", "FUZILEIRO · N2", 1130.0]
	]
	for unit in units:
		var card = _card(scene, unit[0], Vector2(unit[2], 520), 300, BLUE, unit[1])
		card.modulate.a = 0.0
		cards.append(card)
	agent = _card(scene, "1.Agente Infiltrado.png", Vector2(1560, 530), 300, GOLD, "AGENTE INFILTRADO · N1")
	agent.modulate.a = 0.0
	subtitle = Label.new()
	subtitle.text = "não vence nenhum duelo"
	subtitle.label_settings = _text_settings(28, GOLD)
	subtitle.size = Vector2(500, 40)
	subtitle.position = Vector2(1310, 760)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate.a = 0.0
	scene.add_child(subtitle)
	scene.set_meta("play", func():
		for i in range(cards.size()):
			var card = cards[i]
			var tween = create_tween()
			tween.tween_interval(0.6 + i * 0.9)
			tween.tween_callback(func(): _sfx("som_clique_e_movimento.mp3", -6.0))
			tween.tween_property(card, "modulate:a", 1.0, 0.4)
			tween.parallel().tween_property(card, "position:y", 470.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var focus = create_tween()
		focus.tween_interval(4.0)
		focus.tween_callback(func(): _sfx("som_clique_e_movimento.mp3", -2.0))
		focus.tween_property(agent, "modulate:a", 1.0, 0.5)
		focus.parallel().tween_property(agent, "position:y", 480.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for card in cards:
			focus.parallel().tween_property(card, "modulate", Color(0.35, 0.35, 0.4, 1.0), 0.8)
		focus.tween_property(agent, "scale", Vector2.ONE * 1.18, 1.2).set_trans(Tween.TRANS_SINE)
		focus.parallel().tween_property(subtitle, "modulate:a", 1.0, 0.8)
		focus.tween_property(agent, "scale", Vector2.ONE * 1.24, 4.0))
	return scene

# ---------------------------------------------------------------- cena 3: as lonas
func _build_tarps() -> Node2D:
	var scene: Node2D
	var row: Node2D
	var suspect: Node2D
	scene = _scene()
	_rect(scene, Color("100b0b"))
	var ground = _sprite(scene, "tabuleiro_completo.png", Vector2(W * 0.5, H * 0.15), W * 1.2)
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.modulate = Color(0.75, 0.45, 0.4)
	_smoke(scene, 18, 0.1)
	row = Node2D.new()
	row.position = Vector2(W * 0.5, H * 0.46)
	scene.add_child(row)
	for i in range(6):
		var card = _card(row, "Default.png", Vector2((i - 2.5) * 270, 0), 230, RED)
		if i == 2:
			suspect = card
	scene.set_meta("play", func():
		var zoom = create_tween()
		zoom.tween_property(row, "scale", Vector2.ONE * 1.12, 10.0)
		var glimpse = create_tween()
		glimpse.tween_interval(3.5)
		for step in range(5):
			glimpse.tween_property(suspect, "rotation", 0.03 if step % 2 == 0 else -0.03, 0.06)
		glimpse.tween_property(suspect, "rotation", 0.0, 0.06)
		glimpse.tween_callback(func(): _flip(suspect, "2.Fuzileiro.png", 0.24))
		glimpse.tween_interval(0.55)
		glimpse.tween_callback(func(): _flip(suspect, "Default.png", 0.24)))
	return scene

# ---------------------------------------------------------------- cena 4: a decisão
func _build_decision() -> Node2D:
	var scene: Node2D
	var board: Node2D
	var tanks: Array = []
	var ring: Node2D
	var agent: Node2D
	var commander: Node2D
	scene = _scene()
	_rect(scene, Color("0b1016"))
	var cell = 88.0
	board = _board(scene, Vector2(W * 0.5 - cell * 4, H * 0.5 - cell * 4 - 30), cell)
	for pos in [Vector2(0, 6), Vector2(2, 6), Vector2(3, 7), Vector2(5, 6), Vector2(6, 7), Vector2(7, 6), Vector2(1, 7), Vector2(4, 6)]:
		var tank = _card(board, "Default.png", (pos + Vector2(0.5, 0.5)) * cell, cell - 14, RED)
		tank.modulate.a = 0.0
		tanks.append(tank)
	ring = Node2D.new()
	ring.position = Vector2(4.5, 7.5) * cell
	board.add_child(ring)
	ring.draw.connect(func(): ring.draw_arc(Vector2.ZERO, cell * 0.62, 0, TAU, 40, RED, 4.0))
	commander = _card(scene, "4.Atirador de Elite.png", Vector2(330, 500), 300, BLUE, "COMANDANTE")
	agent = _card(scene, "1.Agente Infiltrado.png", Vector2(1590, 500), 300, BLUE, "AGENTE INFILTRADO")
	scene.set_meta("play", func():
		var tween = create_tween()
		for tank in tanks:
			tween.tween_property(tank, "modulate:a", 1.0, 0.18)
		var pulse = create_tween().set_loops()
		pulse.tween_property(ring, "scale", Vector2.ONE * 1.35, 0.6)
		pulse.tween_property(ring, "scale", Vector2.ONE, 0.6)
		var step = create_tween()
		step.tween_interval(3.4)
		step.tween_callback(func(): _sfx("som_clique_e_movimento.mp3", -2.0))
		step.tween_property(agent, "scale", Vector2.ONE * 1.18, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		step.parallel().tween_property(agent, "position:x", 1560.0, 0.5)
		step.parallel().tween_property(agent.get_node("Border"), "color", GOLD, 0.5)
		step.parallel().tween_property(commander, "modulate", Color(0.5, 0.5, 0.55), 0.8))
	return scene

# ---------------------------------------------------------------- cena 5: a travessia
func _build_crossing() -> Node2D:
	var scene: Node2D
	var board: Node2D
	var agent: Node2D
	var target: Node2D
	var cell = 128.0
	scene = _scene()
	_rect(scene, Color("080b0e"))
	board = _board(scene, Vector2(W * 0.5 - cell * 4, H * 0.5 - cell * 4), cell)
	board.get_child(0).modulate = Color(0.55, 0.55, 0.65)
	for pos in [Vector2(0, 6), Vector2(2, 7), Vector2(3, 6), Vector2(5, 6), Vector2(6, 7), Vector2(7, 6), Vector2(1, 7), Vector2(5, 7)]:
		var tank = _card(board, "Default.png", (pos + Vector2(0.5, 0.5)) * cell, cell - 16, RED)
		if pos == Vector2(3, 6):
			target = tank
	for pos in [Vector2(1, 0), Vector2(6, 0), Vector2(2, 1), Vector2(5, 1)]:
		_card(board, "2.Fuzileiro.png", (pos + Vector2(0.5, 0.5)) * cell, cell - 16, BLUE).modulate = Color(0.7, 0.7, 0.75)
	agent = _card(board, "1.Agente Infiltrado.png", (Vector2(3, 1) + Vector2(0.5, 0.5)) * cell, cell - 16, BLUE)
	scene.set_meta("play", func():
		var path = [Vector2(3, 2), Vector2(3, 3), Vector2(3, 4), Vector2(3, 5)]
		var times = [1.0, 2.2, 4.6, 5.8]
		for i in range(path.size()):
			var destination = (path[i] + Vector2(0.5, 0.5)) * cell
			var tween = create_tween()
			tween.tween_interval(times[i])
			tween.tween_callback(func(): _sfx("som_clique_e_movimento.mp3", -4.0))
			tween.tween_property(agent, "position", destination, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var flare = create_tween()
		flare.tween_interval(2.9)
		flare.tween_callback(func(): _sfx("sinalizador.wav", -10.0))
		flare.tween_interval(1.1)
		flare.tween_callback(func():
			flash.color = Color(1.0, 0.95, 0.85, 0.75))
		flare.tween_property(flash, "color:a", 0.12, 0.5)
		flare.tween_property(flash, "color:a", 0.0, 1.2)
		var combat = create_tween()
		combat.tween_interval(6.6)
		combat.tween_callback(func(): _sfx("som_combate1.mp3", 0.0))
		combat.tween_callback(func(): _flip(target, "4.Atirador de Elite.png", 0.3))
		combat.tween_interval(1.5)
		combat.tween_callback(func():
			_sfx("som_combate2.mp3", -5.0)
			var silence = create_tween()
			for player in get_children():
				if player is AudioStreamPlayer and player.stream.resource_path.ends_with("batimento_rapido.wav"):
					silence.parallel().tween_property(player, "volume_db", -60.0, 0.25))
		combat.tween_property(agent, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		combat.parallel().tween_property(agent, "modulate:a", 0.0, 0.35)
		combat.tween_property(target.get_node("Border"), "color", Color(1.0, 0.35, 0.3), 0.3)
		var zoom = create_tween()
		zoom.tween_property(board, "scale", Vector2.ONE * 1.06, 12.0)
		zoom.parallel().tween_property(board, "position", board.position - Vector2(cell * 4, cell * 4) * 0.06, 12.0))
	return scene

# ---------------------------------------------------------------- cena 6: título
func _build_title() -> Node2D:
	var scene: Node2D
	var cover: Sprite2D
	var backdrop: Sprite2D
	scene = _scene()
	_rect(scene, Color("05070c"))
	backdrop = _sprite(scene, "capa_art_of_conquest.png", Vector2(W * 0.5, H * 0.5), W * 1.05)
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	backdrop.modulate = Color(0.25, 0.25, 0.3, 1.0)
	cover = _sprite(scene, "capa_art_of_conquest.png", Vector2(W * 0.5, H * 0.47), H * 0.9 * 1374.0 / 1145.0)
	cover.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scene.set_meta("play", func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cover, "scale", cover.scale * 1.07, 10.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(backdrop, "scale", backdrop.scale * 1.04, 10.5))
	return scene
