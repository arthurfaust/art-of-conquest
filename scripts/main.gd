extends Node2D

const GRID_SIZE = 8
const CELL_SIZE = 64 # Tamanho em pixels de cada quadrado do tabuleiro

const ProbabilityManager = preload("res://scripts/probability_manager.gd")

# Ative no Inspector do nó Main para validar os cálculos na aba Saída.
@export var debug_probabilities: bool = false

# O tabuleiro começa no topo absoluto (0,0) pois a label superior foi removida
const OFFSET_Y = 0  

# Matriz bidimensional para rastrear onde as peças estão logicamente
var board = []
var current_turn = GamePiece.Player.BLUE
var selected_piece: GamePiece = null
var winner_player = null

# Definição das posições das bandeiras
const BLUE_FLAG = Vector2i(4, 0)
const RED_FLAG = Vector2i(4, 7)

@onready var pieces_container = $PiecesContainer
@onready var board_texture = $TextureRect

# Caminhos atualizados para buscar os nós dentro da Sidebar lateral
@onready var status_label = $Sidebar/StatusLabel
@onready var reset_button = $Sidebar/ResetButton

# Referências dos painéis de descarte/cemitério
@onready var blue_discard_grid = $Sidebar/BlueGraveyard/MarginContainer/VBoxContainer/BlueDiscardGrid
@onready var red_discard_grid = $Sidebar/RedGraveyard/MarginContainer/VBoxContainer/RedDiscardGrid
@onready var blue_discard_title = $Sidebar/BlueGraveyard/MarginContainer/VBoxContainer/BlueDiscardTitle
@onready var red_discard_title = $Sidebar/RedGraveyard/MarginContainer/VBoxContainer/RedDiscardTitle

# Variáveis da fase de posicionamento
enum GameState { SETUP_AZUL, PLAYING, GAME_OVER }
var current_state = GameState.SETUP_AZUL

# Lista de peças que o jogador Azul ainda precisa posicionar
var blue_pieces_to_place = [1, 1, 2, 2, 3, 3, 4, 4]

# Trava de segurança para impedir cliques durante animações/combates
var is_animating = false

# Unidades eliminadas de cada equipe
var eliminated_blue: Array[int] = []
var eliminated_red: Array[int] = []

# --- TEXTURAS DOS OBJETIVOS ---
var tex_bandeira_azul = load("res://assets/images/bandeira_azul.png")
var tex_bandeira_vermelha = load("res://assets/images/bandeira_vermelha.png")

# --- ARQUIVOS DE ÁUDIO (Apenas SFX locais - Música agora é Global) ---
var snd_clique = load("res://assets/sounds/som_clique_e_movimento.mp3")
var snd_movimento = load("res://assets/sounds/som_clique_e_movimento.mp3")
var snd_combate1 = load("res://assets/sounds/som_combate1.mp3")
var snd_combate2 = load("res://assets/sounds/som_combate2.mp3")

func _ready():
	# Conecta o sinal de desenho do TextureRect para renderizar a grade por cima dele
	if board_texture:
		board_texture.draw.connect(_on_board_texture_draw)
		
	start_new_game()

# Função auxiliar para criar efeitos sonoros dinâmicos (Volume padrão mais alto que a BGM)
func play_sfx(stream: AudioStream):
	if not stream:
		return
	var fx_player = AudioStreamPlayer.new()
	add_child(fx_player)
	fx_player.stream = stream
	fx_player.volume_db = 0.0
	fx_player.play()
	fx_player.finished.connect(func(): fx_player.queue_free())

# Limpa o jogo anterior e prepara o novo tabuleiro
func start_new_game():
	for child in pieces_container.get_children():
		child.queue_free()
		
	board.clear()
	init_board()
	current_turn = GamePiece.Player.BLUE
	selected_piece = null
	winner_player = null
	current_state = GameState.SETUP_AZUL
	blue_pieces_to_place = [1, 1, 2, 2, 3, 3, 4, 4]
	is_animating = false

	clear_discard_panel()
	
	reset_button.visible = false
	set_process_input(true)
	
	spawn_red_pieces_randomly()
	
	if board_texture:
		board_texture.queue_redraw()
		
	update_status_msg()

	print_probability_debug()

# Inicializa a matriz do tabuleiro com valores nulos
func init_board():
	board = []
	for x in range(GRID_SIZE):
		board.append([])
		for y in range(GRID_SIZE):
			board[x].append(null)

# Posiciona as vermelhas aleatoriamente nas linhas 6 e 7
func spawn_red_pieces_randomly():
	var red_levels: Array[int] = []
	for level in ProbabilityManager.INITIAL_RED_COUNTS:
		for _unit in range(ProbabilityManager.INITIAL_RED_COUNTS[level]):
			red_levels.append(level)
	red_levels.shuffle()
	
	var possible_positions = []
	for x in range(GRID_SIZE):
		possible_positions.append(Vector2i(x, 6))
		possible_positions.append(Vector2i(x, 7))
	
	for lvl in red_levels:
		var random_index = randi() % possible_positions.size()
		var chosen_pos = possible_positions[random_index]
		
		while chosen_pos == RED_FLAG:
			random_index = randi() % possible_positions.size()
			chosen_pos = possible_positions[random_index]
		
		possible_positions.remove_at(random_index)
		create_piece_at(GamePiece.Player.RED, lvl, chosen_pos)

func create_piece_at(player: GamePiece.Player, level: int, grid_pos: Vector2i):
	var piece_scene = load("res://scenes/piece.tscn")
	var piece = piece_scene.instantiate() as GamePiece
	
	pieces_container.add_child(piece)
	piece.setup(player, level, grid_pos)
	
	piece.position = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE/2.0, 
		grid_pos.y * CELL_SIZE + CELL_SIZE/2.0 + OFFSET_Y
	)
	board[grid_pos.x][grid_pos.y] = piece

# Atualiza os títulos dos cemitérios com a quantidade de unidades eliminadas
func update_discard_titles():
	blue_discard_title.text = "AZUIS: %d" % eliminated_blue.size()
	red_discard_title.text = "VERMELHAS: %d" % eliminated_red.size()

# Limpa os cemitérios ao iniciar/reiniciar uma partida
func clear_discard_panel():
	eliminated_blue.clear()
	eliminated_red.clear()

	for child in blue_discard_grid.get_children():
		child.queue_free()

	for child in red_discard_grid.get_children():
		child.queue_free()

	update_discard_titles()

# Registra visualmente uma unidade eliminada no cemitério do time correspondente
func register_eliminated_piece(piece: GamePiece):
	if not piece:
		return

	var target_grid: GridContainer

	if piece.player_owner == GamePiece.Player.BLUE:
		eliminated_blue.append(piece.level)
		target_grid = blue_discard_grid
	else:
		eliminated_red.append(piece.level)
		target_grid = red_discard_grid

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if GamePiece.TEXTURES.has(piece.level):
		icon.texture = load(GamePiece.TEXTURES[piece.level])

	target_grid.add_child(icon)
	update_discard_titles()

# Controla as mensagens da Label na HUD lateral
func update_status_msg():
	match current_state:
		GameState.SETUP_AZUL:
			if blue_pieces_to_place.size() > 0:
				status_label.text = "Fase de Posicionamento:\nNas casas indicadas, coloque uma peça de nível " + str(blue_pieces_to_place[0])
		GameState.PLAYING:
			var turno_texto = "Sua Vez (AZUL)" if current_turn == GamePiece.Player.BLUE else "Pensando... (VERMELHO)"
			status_label.text = "Status da Partida:\n" + turno_texto
		GameState.GAME_OVER:
			if winner_player == GamePiece.Player.BLUE:
				status_label.text = "Fim de Jogo:\nVitória do AZUL!"
			elif winner_player == GamePiece.Player.RED:
				status_label.text = "Fim de Jogo:\nVitória do VERMELHO!"
			else:
				status_label.text = "Fim de Jogo"

# Detecta cliques do jogador
func _input(event):
	if current_state == GameState.GAME_OVER or is_animating:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.x >= GRID_SIZE * CELL_SIZE:
			return
			
		var adjusted_click_y = event.position.y - OFFSET_Y
		var grid_click = Vector2i(floor(event.position.x / CELL_SIZE), floor(adjusted_click_y / CELL_SIZE))
		
		if grid_click.x >= 0 and grid_click.x < GRID_SIZE and grid_click.y >= 0 and grid_click.y < GRID_SIZE:
			if current_state == GameState.SETUP_AZUL:
				handle_setup_click(grid_click)
			elif current_state == GameState.PLAYING:
				if current_turn == GamePiece.Player.BLUE:
					handle_grid_click(grid_click)

# Gerencia o clique durante o posicionamento inicial
func handle_setup_click(grid_pos: Vector2i):
	if grid_pos.y != 0 and grid_pos.y != 1:
		return
	if grid_pos == BLUE_FLAG:
		return
	if board[grid_pos.x][grid_pos.y] != null:
		return
		
	play_sfx(snd_clique)
	var current_lvl = blue_pieces_to_place.pop_front()
	create_piece_at(GamePiece.Player.BLUE, current_lvl, grid_pos)
	
	if blue_pieces_to_place.size() > 0:
		update_status_msg()
	else:
		current_state = GameState.PLAYING
		update_status_msg()
		
	# MODIFICAÇÃO N3: Força o redesenho após o clique para atualizar ou remover o tom azulado das casas
	if board_texture:
		board_texture.queue_redraw()

func handle_grid_click(grid_pos: Vector2i):
	var clicked_piece = board[grid_pos.x][grid_pos.y]
	
	# Seleciona uma peça azul e redesenha o tabuleiro para mostrar as casas válidas.
	# A própria peça também recebe um contorno/brilho azul.
	# Clicar novamente na mesma peça cancela a seleção.
	if clicked_piece and clicked_piece.player_owner == current_turn:
		if selected_piece == clicked_piece:
			selected_piece.set_selected(false)
			selected_piece = null
		else:
			# Remove o destaque da peça que estava selecionada anteriormente.
			if selected_piece and is_instance_valid(selected_piece):
				selected_piece.set_selected(false)
			
			selected_piece = clicked_piece
			selected_piece.set_selected(true)
			play_sfx(snd_clique)
		
		if board_texture:
			board_texture.queue_redraw()
		print_probability_debug(selected_piece)
		return
		
	if selected_piece:
		if is_valid_move(selected_piece.grid_position, grid_pos):
			var piece_to_move = selected_piece
			piece_to_move.set_selected(false)
			selected_piece = null
			
			# Remove imediatamente o destaque das casas antes da animação.
			if board_texture:
				board_texture.queue_redraw()
			
			is_animating = true
			await move_piece(piece_to_move, grid_pos)
			is_animating = false
			
			check_victory_conditions()
			if current_state != GameState.GAME_OVER:
				switch_turn()

# Retorna todas as casas para as quais a peça selecionada realmente pode se mover.
# A função reutiliza is_valid_move(), evitando duplicar as regras de movimento.
func get_valid_moves_for_piece(piece: GamePiece) -> Array[Vector2i]:
	var valid_moves: Array[Vector2i] = []

	if not piece:
		return valid_moves

	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for direction in directions:
		var target_pos = piece.grid_position + direction

		if target_pos.x < 0 or target_pos.x >= GRID_SIZE:
			continue
		if target_pos.y < 0 or target_pos.y >= GRID_SIZE:
			continue

		if is_valid_move(piece.grid_position, target_pos):
			valid_moves.append(target_pos)

	return valid_moves

func is_valid_move(from: Vector2i, to: Vector2i) -> bool:
	var distance = to - from
	var is_one_step_move = (abs(distance.x) == 1 and distance.y == 0) or (abs(distance.y) == 1 and distance.x == 0)
	
	if not is_one_step_move:
		return false
	if board[to.x][to.y] != null:
		return false
		
	return true

func move_piece(piece: GamePiece, to_pos: Vector2i):
	var from_pos = piece.grid_position
	
	board[from_pos.x][from_pos.y] = null
	board[to_pos.x][to_pos.y] = piece
	piece.grid_position = to_pos
	
	var target_pixel_pos = Vector2(
		to_pos.x * CELL_SIZE + CELL_SIZE/2.0, 
		to_pos.y * CELL_SIZE + CELL_SIZE/2.0 + OFFSET_Y
	)
	
	play_sfx(snd_movimento)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", target_pixel_pos, 0.3)
	await tween.finished
	
	await check_for_combat(piece)
	print_probability_debug()

# Remove a peça individual suavizando escala e opacidade ao mesmo tempo
func remove_piece_with_animation(piece: GamePiece):
	if not piece:
		return
		
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(piece, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	piece.queue_free()

# Lógica de Cerco ajustada com tempo de suspense e remoção animada
func check_for_combat(moved_piece: GamePiece):
	var pos = moved_piece.grid_position
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	var inimigos_adjacentes = []
	
	for dir in directions:
		var target_pos = pos + dir
		if target_pos.x >= 0 and target_pos.x < GRID_SIZE and target_pos.y >= 0 and target_pos.y < GRID_SIZE:
			var neighbor = board[target_pos.x][target_pos.y]
			if neighbor and neighbor.player_owner != moved_piece.player_owner:
				inimigos_adjacentes.append(neighbor)
	
	if inimigos_adjacentes.size() >= 2:
		var time_texto = "AZUL" if moved_piece.player_owner == GamePiece.Player.BLUE else "VERMELHO"
		print("CERCO! A peça ", time_texto, " em ", pos, " entrou em combate com ", inimigos_adjacentes.size(), " inimigos!")
		
		moved_piece.reveal_level()
		for inimigo in inimigos_adjacentes:
			inimigo.reveal_level()
			
		play_sfx(snd_combate1)
		await get_tree().create_timer(1.0).timeout
		play_sfx(snd_combate2)
		
		board[pos.x][pos.y] = null
		register_eliminated_piece(moved_piece)
		await remove_piece_with_animation(moved_piece)
		
	elif inimigos_adjacentes.size() == 1:
		await resolve_proximity_combat(moved_piece, inimigos_adjacentes[0])

# Confronto clássico 1v1 corrigido com Tweens nativos para evitar erros de corrotina
func resolve_proximity_combat(attacker: GamePiece, defender: GamePiece):
	attacker.reveal_level()
	defender.reveal_level()
	
	play_sfx(snd_combate1)
	await get_tree().create_timer(1.5).timeout
	play_sfx(snd_combate2)
	
	if attacker.level > defender.level:
		print("Atacante nível ", attacker.level, " venceu! Defensor nível ", defender.level, " foi eliminado.")
		board[defender.grid_position.x][defender.grid_position.y] = null
		register_eliminated_piece(defender)
		await remove_piece_with_animation(defender)
	elif defender.level > attacker.level:
		print("Defensor nível ", defender.level, " venceu! Atacante nível ", attacker.level, " foi eliminado.")
		board[attacker.grid_position.x][attacker.grid_position.y] = null
		register_eliminated_piece(attacker)
		await remove_piece_with_animation(attacker)
	else:
		print("Empate! Ambos nível ", attacker.level, " foram eliminados.")
		board[attacker.grid_position.x][attacker.grid_position.y] = null
		board[defender.grid_position.x][defender.grid_position.y] = null

		register_eliminated_piece(attacker)
		register_eliminated_piece(defender)
		
		var tween_att = create_tween().set_parallel(true)
		tween_att.tween_property(attacker, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_att.tween_property(attacker, "modulate:a", 0.0, 0.3)
		
		var tween_def = create_tween().set_parallel(true)
		tween_def.tween_property(defender, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_def.tween_property(defender, "modulate:a", 0.0, 0.3)
		
		await tween_att.finished
		await tween_def.finished
		
		attacker.queue_free()
		defender.queue_free()

func get_revealed_red_levels() -> Array[int]:
	var revealed_levels: Array[int] = []

	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var piece = board[x][y]

			if piece == null:
				continue

			if piece.player_owner != GamePiece.Player.RED:
				continue

			if piece.is_revealed:
				revealed_levels.append(piece.level)

	return revealed_levels

func get_known_red_levels() -> Array[int]:
	var known_levels: Array[int] = []

	for level in eliminated_red:
		known_levels.append(level)

	for level in get_revealed_red_levels():
		known_levels.append(level)

	return known_levels

# A cena reúne os dados públicos; o gerenciador executa os cálculos.
func get_unknown_red_counts() -> Dictionary:
	return ProbabilityManager.get_unknown_red_counts(get_known_red_levels())

func get_unknown_red_total() -> int:
	return ProbabilityManager.get_unknown_red_total(get_known_red_levels())

func get_level_probabilities() -> Dictionary:
	return ProbabilityManager.get_level_probabilities(get_known_red_levels())

func get_combat_probabilities(blue_level: int) -> Dictionary:
	return ProbabilityManager.get_combat_probabilities(blue_level, get_known_red_levels())

func get_sample_space_size() -> int:
	return ProbabilityManager.get_sample_space_size(get_known_red_levels())

func get_uncertainty_reduction() -> float:
	return ProbabilityManager.get_uncertainty_reduction(get_known_red_levels())

# Usa apenas informações que o jogador já conhece. Não consulta níveis ocultos.
# As chances abaixo se referem a um duelo contra uma vermelha desconhecida.
func print_probability_debug(blue_piece: GamePiece = null) -> void:
	if not debug_probabilities or not OS.is_debug_build():
		return

	print("\n[Probabilidade] Estado conhecido do exército vermelho")
	print("Reveladas no tabuleiro: ", get_revealed_red_levels())
	print("Eliminadas: ", eliminated_red)
	print("Conhecidas: ", get_known_red_levels())
	print("Desconhecidas por nível: ", get_unknown_red_counts())
	print("Total desconhecido: ", get_unknown_red_total())
	print("Probabilidades por nível: ", get_level_probabilities())
	print("Espaço amostral: ", get_sample_space_size())

	if get_unknown_red_total() == 0:
		print("Nenhuma unidade vermelha desconhecida; não há duelo desconhecido a estimar.")
	elif is_instance_valid(blue_piece) and blue_piece.player_owner == GamePiece.Player.BLUE:
		var chances = get_combat_probabilities(blue_piece.level)
		print("Azul selecionada: nível ", blue_piece.level)
		print("Duelo contra vermelha desconhecida — vitória: %.2f%% | empate: %.2f%% | derrota: %.2f%%" % [
			chances["win_probability"] * 100.0,
			chances["draw_probability"] * 100.0,
			chances["loss_probability"] * 100.0
		])
	else:
		print("Selecione uma peça azul para consultar as chances de duelo.")

func switch_turn():
	current_turn = GamePiece.Player.RED if current_turn == GamePiece.Player.BLUE else GamePiece.Player.BLUE
	update_status_msg()
	
	if current_turn == GamePiece.Player.RED and current_state == GameState.PLAYING:
		await get_tree().create_timer(0.5).timeout
		jogada_simulada()

func jogada_simulada():
	var todas_as_jogadas_possiveis = []
	var direcoes_para_frente_e_lados = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	var todas_as_direcoes = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var peca = board[x][y]
			if peca and peca.player_owner == GamePiece.Player.RED:
				for dir in direcoes_para_frente_e_lados:
					var destino = peca.grid_position + dir
					if destino == RED_FLAG:
						continue
					if destino.x >= 0 and destino.x < GRID_SIZE and destino.y >= 0 and destino.y < GRID_SIZE:
						if is_valid_move(peca.grid_position, destino):
							todas_as_jogadas_possiveis.append({"peca": peca, "destino": destino})
							
	if todas_as_jogadas_possiveis.size() == 0:
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				var peca = board[x][y]
				if peca and peca.player_owner == GamePiece.Player.RED:
					for dir in todas_as_direcoes:
						var destino = peca.grid_position + dir
						if destino == RED_FLAG:
							continue
						if destino.x >= 0 and destino.x < GRID_SIZE and destino.y >= 0 and destino.y < GRID_SIZE:
							if is_valid_move(peca.grid_position, destino):
								todas_as_jogadas_possiveis.append({"peca": peca, "destino": destino})
	
	if todas_as_jogadas_possiveis.size() > 0:
		var jogada_sorteada = todas_as_jogadas_possiveis[randi() % todas_as_jogadas_possiveis.size()]
		var peca_ia = jogada_sorteada["peca"]
		var destino_ia = jogada_sorteada["destino"]
		
		await move_piece(peca_ia, destino_ia)
		
	check_victory_conditions()
	if current_state != GameState.GAME_OVER:
		switch_turn()

func check_victory_conditions():
	var game_should_end = false
	
	if board[BLUE_FLAG.x][BLUE_FLAG.y] != null and board[BLUE_FLAG.x][BLUE_FLAG.y].player_owner == GamePiece.Player.RED:
		game_should_end = true
		winner_player = GamePiece.Player.RED
		print("FIM DE JOGO: O time Vermelho capturou a bandeira Azul!")
		
	elif board[RED_FLAG.x][RED_FLAG.y] != null and board[RED_FLAG.x][RED_FLAG.y].player_owner == GamePiece.Player.BLUE:
		game_should_end = true
		winner_player = GamePiece.Player.BLUE
		print("FIM DE JOGO: O time Azul capturou a bandeira Vermelha!")
		
	if not game_should_end:
		var blue_alive = false
		var red_alive = false
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				var p = board[x][y]
				if p:
					if p.player_owner == GamePiece.Player.BLUE: blue_alive = true
					if p.player_owner == GamePiece.Player.RED: red_alive = true
					
		if not blue_alive:
			game_should_end = true
			winner_player = GamePiece.Player.RED
			print("FIM DE JOGO: Todas as peças azuis foram eliminadas!")
		elif not red_alive:
			game_should_end = true
			winner_player = GamePiece.Player.BLUE
			print("FIM DE JOGO: Todas as peças vermelhas foram eliminadas!")
			
	if game_should_end:
		current_state = GameState.GAME_OVER
		update_status_msg()
		declare_winner()

func declare_winner():
	reset_button.visible = true

# Responde ao sinal de desenho da textura de fundo para pintar overlays por cima dela
func _on_board_texture_draw():
	# 1. MODIFICAÇÃO N3: Se estiver no SETUP, pinta as casas válidas com um tom azul translúcido
	if current_state == GameState.SETUP_AZUL:
		for x in range(GRID_SIZE):
			for y in [0, 1]: # Linhas 1 e 2 do tabuleiro (índices 0 e 1)
				var pos = Vector2i(x, y)
				if pos != BLUE_FLAG and board[x][y] == null:
					var cell_rect = Rect2(x * CELL_SIZE, y * CELL_SIZE + OFFSET_Y, CELL_SIZE, CELL_SIZE)
					# Desenha um quadrado azul preenchido (filled = true) com 25% de opacidade
					board_texture.draw_rect(cell_rect, Color(0.0, 0.4, 1.0, 0.25), true)

	# 2. Desenha a moldura branca sutil em cada célula por cima da imagem
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var cell_rect = Rect2(x * CELL_SIZE, y * CELL_SIZE + OFFSET_Y, CELL_SIZE, CELL_SIZE)
			var border_color = Color(1.0, 1.0, 1.0, 0.25)
			board_texture.draw_rect(cell_rect, border_color, false, 1.0)
			
	# 3. Desenha as bandeiras/objetivos
	var rect_blue_flag = Rect2(BLUE_FLAG.x * CELL_SIZE, BLUE_FLAG.y * CELL_SIZE + OFFSET_Y, CELL_SIZE, CELL_SIZE)
	var rect_red_flag = Rect2(RED_FLAG.x * CELL_SIZE, RED_FLAG.y * CELL_SIZE + OFFSET_Y, CELL_SIZE, CELL_SIZE)
	
	if tex_bandeira_azul:
		board_texture.draw_texture_rect(tex_bandeira_azul, rect_blue_flag, false)
	else:
		board_texture.draw_rect(rect_blue_flag, Color(0.0, 0.6, 1.0, 0.6), false, 2.0)
		
	if tex_bandeira_vermelha:
		board_texture.draw_texture_rect(tex_bandeira_vermelha, rect_red_flag, false)
	else:
		board_texture.draw_rect(rect_red_flag, Color(1.0, 0.3, 0.3, 0.6), false, 2.0)

	# 4. Durante a partida, destaca em azul todas as casas válidas
	# da peça atualmente selecionada.
	if current_state == GameState.PLAYING and selected_piece != null:
		for valid_pos in get_valid_moves_for_piece(selected_piece):
			var valid_rect = Rect2(
				valid_pos.x * CELL_SIZE,
				valid_pos.y * CELL_SIZE + OFFSET_Y,
				CELL_SIZE,
				CELL_SIZE
			)

			# Preenchimento azul translúcido + borda mais forte.
			board_texture.draw_rect(valid_rect, Color(0.0, 0.45, 1.0, 0.32), true)
			board_texture.draw_rect(valid_rect, Color(0.15, 0.70, 1.0, 0.95), false, 3.0)

func _on_reset_button_pressed():
	start_new_game()
