extends SceneTree

# Grava as cenas de jogo do vídeo de apresentação com o Movie Maker da Godot.
# Um cursor visível envia cliques e teclas de verdade ao jogo; cada take tem
# uma marca de tempo salva em JSON para o corte (veja producao/video-apresentacao/README.md).
#
# Uso: godot --path . --write-movie saida.avi --fixed-fps 30 -s res://producao/video-apresentacao/gravador.gd -- roteiro=partida marcas=marcas.json semente=7
# Roteiros: intro, tutorial, partida, n2 (rodar dentro da cópia da versão N2) e busca (sem gravar).

const CELL = 64
const BLUE = 0
const SETUP_CELLS = [
	Vector2i(3, 1), Vector2i(4, 1), Vector2i(2, 1), Vector2i(5, 1),
	Vector2i(1, 1), Vector2i(6, 1), Vector2i(3, 0), Vector2i(5, 0)
]

var roteiro = "intro"
var marcas_path = ""
var semente = 1
var tempo = 0.0
var marcas = []
var cursor: Node2D
var anel: Node2D
var cursor_pos = Vector2(416, 380)
var game
var audio
var musica_original := -1.0
var efeitos_original := -1.0

func _initialize():
	for arg in OS.get_cmdline_user_args():
		var partes = arg.split("=", true, 1)
		if partes.size() == 2:
			match partes[0]:
				"roteiro": roteiro = partes[1]
				"marcas": marcas_path = partes[1]
				"semente": semente = int(partes[1])
	audio = root.get_node_or_null("AudioManager")
	if audio and "music_volume" in audio:
		musica_original = audio.music_volume
		efeitos_original = audio.sfx_volume
	_criar_cursor()
	call_deferred("_executar")

func _process(delta):
	tempo += delta
	return false

func _executar():
	match roteiro:
		"intro": await _intro()
		"tutorial": await _tutorial()
		"partida": await _partida()
		"n2": await _n2()
		"busca": await _busca()
	_finalizar()

# ------------------------------------------------------------------ roteiros
func _intro():
	var menu = await _abrir("res://scenes/menu.tscn")
	_marca("T01")
	await _esperar(3.0)
	var jogar = menu.get_node("VBoxContainer/JogarButton")
	for alvo in [Vector2(300, 250), Vector2(520, 160), Vector2(416, 470), _centro(jogar)]:
		await _mover(alvo, 1.6)
		await _esperar(5.0)
	await _esperar(8.0)
	_marca("T02")
	await _clicar(_centro(jogar))
	await _esperar(2.0)
	game = current_scene
	var card = game.menus.briefing.get_node("Center/Card")
	var rect = card.get_global_rect()
	for fracao in [0.18, 0.3, 0.42, 0.55, 0.64, 0.72, 0.8]:
		await _mover(Vector2(rect.position.x + 60, rect.position.y + rect.size.y * fracao), 1.2)
		await _esperar(5.5)
	await _mover(_centro(game.menus.briefing_start), 1.0)
	await _esperar(4.0)

func _tutorial():
	var menu = await _abrir("res://scenes/menu.tscn")
	_marca("T04")
	await _esperar(2.0)
	await _clicar(_centro(menu.get_node("VBoxContainer/TutorialButton")))
	await _esperar(2.5)
	game = current_scene
	var S = game.Step
	var marcou_parte2 = false
	while game.step != S.COMPLETE:
		var passo = game.step
		if passo == S.DUEL_READY and not marcou_parte2:
			marcou_parte2 = true
			await _esperar(1.0)
			_marca("T05")
		if game.QUIZZES.has(passo):
			await _esperar(3.5)
			var certa = game.QUIZZES[passo][1]
			if passo == S.LEVEL_QUIZ:
				var errada = (certa + 1) % game.QUIZZES[passo][0].size()
				await _clicar(_centro(game.answer_buttons[errada]))
				await _esperar(5.0)
			await _clicar(_centro(game.answer_buttons[certa]))
			await _esperar(2.5)
		elif passo in [S.RED_CARD, S.UPDATED_CARD, S.BLUE_CARD]:
			await _esperar(2.5)
			var botao = game.calculation_button if passo == S.BLUE_CARD else game.red_calculation_button
			await _clicar(_centro(botao))
			await _esperar(6.0)
			await _clicar(_centro(game.calculation_close))
			await _esperar(2.0)
		elif game.next_button.visible:
			await _esperar(3.0)
			await _clicar(_centro(game.next_button))
			await _aguardar_tutorial()
			await _esperar(2.0)
		else:
			await _clicar(_celula(game.expected_cell()), 0.45)
			await _aguardar_tutorial()
			await _esperar(1.2 if passo == S.SETUP else 2.5)
	await _esperar(9.0)

func _partida():
	var menu = await _abrir("res://scenes/menu.tscn")
	await _esperar(1.0)
	seed(semente)
	await _clicar(_centro(menu.get_node("VBoxContainer/JogarButton")))
	await _esperar(1.0)
	game = current_scene
	_marca("T06")
	if game.menus.briefing.visible:
		await _esperar(1.5)
		await _clicar(_centro(game.menus.briefing_start))
	await _esperar(2.0)
	for celula in SETUP_CELLS:
		await _clicar(_celula(celula), 0.4)
		await _esperar(0.8)
	await _esperar(8.0)

	_marca("T07")
	var agente = SETUP_CELLS[0]
	await _clicar(_celula(agente))
	await _esperar(3.0)
	await _clicar(_centro(game.calculation_button))
	await _esperar(7.0)
	await _clicar(_centro(game.calculation_close))
	await _esperar(2.0)
	await _clicar(_centro(game.red_calculation_button))
	await _esperar(6.0)
	await _clicar(_centro(game.calculation_close))
	await _esperar(1.5)
	await _clicar(_celula(agente))
	await _esperar(1.0)

	var baixas = 0
	var marcou_t08 = false
	var marcou_pausa = false
	var turnos_desde_t08 = 0
	var perigo_visto = false
	while game.current_state == game.GameState.PLAYING:
		await _jogada_visivel()
		await _aguardar_vez()
		var total = game.eliminated_blue.size() + game.eliminated_red.size()
		if total > baixas:
			baixas = total
			await _esperar(3.0)
			if not marcou_t08:
				marcou_t08 = true
				_marca("T08")
		elif marcou_t08:
			turnos_desde_t08 += 1
		if audio.danger_active and not perigo_visto and game.current_state == game.GameState.PLAYING:
			perigo_visto = true
			await _esperar(5.0)
		if marcou_t08 and not marcou_pausa and turnos_desde_t08 >= 4 and game.current_state == game.GameState.PLAYING:
			marcou_pausa = true
			_marca("T09")
			await _pausa()
			_marca("T10")
	await _esperar(11.0)

func _pausa():
	await _esperar(1.0)
	_tecla(KEY_ESCAPE)
	await _esperar(3.0)
	var menus = game.menus
	await _clicar(_ponto_slider(menus.music_slider, 0.35))
	await _esperar(2.5)
	await _clicar(_ponto_slider(menus.sfx_slider, 0.8))
	await _esperar(2.5)
	await _clicar(_centro(menus.get_node("Pause/Center/Card/Content").get_child(4)))
	await _esperar(7.0)
	await _clicar(_centro(menus.briefing_back))
	await _esperar(2.0)
	await _clicar(_centro(menus.get_node("Pause/Center/Card/Content/Continue")))
	await _esperar(1.5)

func _n2():
	var menu = await _abrir("res://scenes/menu.tscn")
	_marca("N2_menu")
	await _esperar(3.0)
	await _mover(Vector2(256, 300), 1.2)
	await _esperar(3.0)
	seed(semente)
	await _clicar(_centro(menu.get_node("VBoxContainer/JogarButton")))
	await _esperar(1.0)
	game = current_scene
	_marca("N2_posicionamento")
	await _esperar(4.0)
	for celula in SETUP_CELLS:
		await _clicar(_celula(celula), 0.6)
		await _esperar(1.2)
	await _esperar(3.0)
	_marca("N2_partida")
	for turno in range(6):
		if game.current_state != game.GameState.PLAYING:
			break
		await _jogada_visivel()
		await _aguardar_vez()
		await _esperar(0.8)
	await _esperar(2.0)
	_marca("N2_fim")
	# Leva uma peça azul à bandeira vermelha para mostrar como era o fim de jogo.
	for peca in game.pieces_container.get_children():
		if peca.player_owner == BLUE and not peca.is_queued_for_deletion():
			var destino = Vector2i(4, 7)
			var ocupante = game.board[destino.x][destino.y]
			if ocupante:
				ocupante.queue_free()
			game.board[peca.grid_position.x][peca.grid_position.y] = null
			game.board[destino.x][destino.y] = peca
			peca.grid_position = destino
			await _mover(_celula(destino), 0.8)
			peca.position = _celula(destino)
			game.check_victory_conditions()
			break
	await _esperar(8.0)

# Joga várias sementes em velocidade alta e imprime um resumo de cada partida.
func _busca():
	Engine.time_scale = 20.0
	cursor.hide()
	for s in range(1, 41):
		seed(s)
		change_scene_to_file("res://scenes/main.tscn")
		await process_frame
		await process_frame
		game = current_scene
		if game.menus.briefing.visible:
			game.menus.briefing_start.pressed.emit()
		for celula in SETUP_CELLS:
			game.handle_setup_click(celula)
		var turnos = 0
		var perigo = -1
		var cercos = 0
		while game.current_state == game.GameState.PLAYING and turnos < 70:
			var jogada = _escolher_jogada()
			if jogada.is_empty():
				break
			game.handle_grid_click(jogada[0])
			await game.handle_grid_click(jogada[1])
			turnos += 1
			await _aguardar_vez()
			if audio.danger_active and perigo < 0:
				perigo = turnos
		print("BUSCA semente=%d vencedor=%s turnos=%d baixas_azuis=%d baixas_vermelhas=%d perigo_turno=%d" % [
			s, "azul" if game.winner_player == BLUE else ("vermelho" if game.winner_player != null else "nenhum"),
			turnos, game.eliminated_blue.size(), game.eliminated_red.size(), perigo])

# ------------------------------------------------------------------ estratégia
# Usa só o que o jogador vê: peças reveladas e as probabilidades do painel.
func _escolher_jogada() -> Array:
	var melhor = []
	var melhor_nota = -INF
	var bandeira = Vector2i(4, 7)
	for peca in game.pieces_container.get_children():
		if peca.is_queued_for_deletion() or peca.player_owner != BLUE:
			continue
		for destino in game.get_valid_moves_for_piece(peca):
			var nota = 0.0
			if destino == bandeira:
				nota += 10000.0
			var vizinhos = _vermelhas_ao_lado(destino)
			if vizinhos.size() >= 2:
				nota -= 5000.0
			elif vizinhos.size() == 1:
				var inimiga = vizinhos[0]
				if inimiga.is_revealed:
					var diferenca = peca.level - inimiga.level
					nota += 400.0 + inimiga.level * 20.0 if diferenca > 0 else (-150.0 if diferenca == 0 else -3000.0)
				elif peca.level == 1:
					nota += 150.0
				else:
					var chances = game.get_combat_probabilities(peca.level)
					nota += chances["win_probability"] * 300.0 - chances["loss_probability"] * 450.0 - chances["draw_probability"] * 60.0
			var antes = abs(peca.grid_position.x - bandeira.x) + abs(peca.grid_position.y - bandeira.y)
			var depois = abs(destino.x - bandeira.x) + abs(destino.y - bandeira.y)
			nota += (antes - depois) * (5 - peca.level) * 10.0
			nota += destino.x * 0.01 + peca.level * 0.001
			if nota > melhor_nota:
				melhor_nota = nota
				melhor = [peca.grid_position, destino]
	return melhor

func _vermelhas_ao_lado(celula: Vector2i) -> Array:
	var lista = []
	for direcao in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var alvo = celula + direcao
		if alvo.x >= 0 and alvo.x < 8 and alvo.y >= 0 and alvo.y < 8:
			var peca = game.board[alvo.x][alvo.y]
			if peca and peca.player_owner != BLUE:
				lista.append(peca)
	return lista

func _jogada_visivel():
	var jogada = _escolher_jogada()
	if jogada.is_empty():
		return
	await _clicar(_celula(jogada[0]), 0.45)
	await _esperar(0.7)
	await _clicar(_celula(jogada[1]), 0.35)

# ------------------------------------------------------------------ utilidades
func _abrir(caminho: String):
	change_scene_to_file(caminho)
	for i in range(3):
		await process_frame
	return current_scene

func _aguardar_vez():
	await process_frame
	while game.current_state == game.GameState.PLAYING and (game.current_turn != BLUE or game.is_animating):
		await process_frame

func _aguardar_tutorial():
	await process_frame
	while game.busy or game.is_animating:
		await process_frame

func _esperar(segundos: float):
	await create_timer(segundos).timeout

func _marca(nome: String):
	marcas.append({"nome": nome, "t": tempo})
	print("MARCA ", nome, " ", snappedf(tempo, 0.01))

func _finalizar():
	_marca("fim")
	if audio and musica_original >= 0.0:
		audio.set_music_volume(musica_original)
		audio.set_sfx_volume(efeitos_original)
	if marcas_path != "":
		var arquivo = FileAccess.open(marcas_path, FileAccess.WRITE)
		arquivo.store_string(JSON.stringify(marcas, "  "))
	quit()

func _celula(celula: Vector2i) -> Vector2:
	return Vector2(celula) * CELL + Vector2(CELL / 2.0, CELL / 2.0)

func _centro(controle: Control) -> Vector2:
	return controle.get_global_rect().get_center()

func _ponto_slider(slider: Range, fracao: float) -> Vector2:
	var rect = slider.get_global_rect()
	return Vector2(rect.position.x + rect.size.x * fracao, rect.get_center().y)

# ------------------------------------------------------------------ cursor e entrada
func _criar_cursor():
	var camada = CanvasLayer.new()
	camada.layer = 100
	root.add_child.call_deferred(camada)
	anel = Node2D.new()
	anel.draw.connect(func(): anel.draw_arc(Vector2.ZERO, 14.0, 0, TAU, 32, Color(1, 0.85, 0.4, 0.9), 3.0))
	anel.modulate.a = 0.0
	camada.add_child(anel)
	cursor = Node2D.new()
	cursor.position = cursor_pos
	cursor.draw.connect(func():
		var seta = PackedVector2Array([Vector2(0, 0), Vector2(0, 19), Vector2(5, 14), Vector2(8.5, 21.5), Vector2(11.5, 20), Vector2(8, 13), Vector2(14, 13)])
		cursor.draw_colored_polygon(seta, Color.WHITE)
		seta.append(Vector2(0, 0))
		cursor.draw_polyline(seta, Color.BLACK, 1.6, true))
	camada.add_child(cursor)

func _mover(alvo: Vector2, duracao: float = 0.5):
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_posicionar_cursor, cursor_pos, alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _posicionar_cursor(posicao: Vector2):
	cursor_pos = posicao
	cursor.position = posicao
	var evento = InputEventMouseMotion.new()
	evento.position = posicao
	evento.global_position = posicao
	root.push_input(evento, true)

func _clicar(alvo: Vector2, duracao: float = 0.5):
	await _mover(alvo, duracao)
	await _esperar(0.12)
	_botao(true)
	await _esperar(0.08)
	_botao(false)
	anel.position = alvo
	anel.scale = Vector2.ONE * 0.6
	anel.modulate.a = 1.0
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(anel, "scale", Vector2.ONE * 1.6, 0.35)
	tween.tween_property(anel, "modulate:a", 0.0, 0.35)
	await _esperar(0.25)

func _botao(pressionado: bool):
	var evento = InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = pressionado
	evento.position = cursor_pos
	evento.global_position = cursor_pos
	root.push_input(evento, true)

func _tecla(codigo: Key):
	for pressionada in [true, false]:
		var evento = InputEventKey.new()
		evento.keycode = codigo
		evento.physical_keycode = codigo
		evento.pressed = pressionada
		root.push_input(evento, true)
