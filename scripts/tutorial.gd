extends "res://scripts/main.gd"

# O tutorial reutiliza o tabuleiro, os combates e o motor da partida.
# Os cenários de treino são fixos e a IA só age na demonstração de turno.
enum Step {
	SETUP, SELECT, MOVE, RED_TURN, RED_CARD, LEVEL_QUIZ,
	SELECT_FOR_ODDS, BLUE_CARD, WIN_QUIZ, DUEL_READY, DUEL_SELECT,
	DUEL_MOVE, UPDATED_CARD, UNKNOWN_QUIZ, DRAW_READY, DRAW_SELECT,
	DRAW_MOVE, DRAW_QUIZ, SIEGE_READY, SIEGE_SELECT, SIEGE_MOVE,
	SIEGE_QUIZ, FLAG_READY, FLAG_SELECT, FLAG_MOVE, COMPLETE
}

const GOLD = Color("f0ce80")
const LESSONS = {
	Step.SETUP: ["Monte seu exército", ""],
	Step.SELECT: ["Selecione uma unidade", "Clique na azul N3 da casa dourada. A seleção mostra seus movimentos."],
	Step.MOVE: ["Dê o primeiro passo", "Clique na casa dourada. Uma jogada anda uma casa, sem diagonais."],
	Step.RED_TURN: ["Os turnos se alternam", "Na partida, a IA joga após você. Use Continuar para observar um turno."],
	Step.RED_CARD: ["Descubra os níveis", "Abra Cálculo vermelha. Observe as frações e feche o card para continuar."],
	Step.LEVEL_QUIZ: ["Qual é a chance?", "Há 2 peças de cada nível entre 8 ocultas. Qual a chance de uma ser N4?"],
	Step.SELECT_FOR_ODDS: ["Prepare uma estimativa", "Selecione de novo a azul N3 destacada para calcular um duelo."],
	Step.BLUE_CARD: ["Veja a chance de duelo", "Abra Cálculo azul e feche o card. A estimativa é contra uma vermelha oculta."],
	Step.WIN_QUIZ: ["Calcule a vitória", "A azul N3 vence N1 e N2: 4 entre 8 ocultas. Qual é a chance de vitória?"],
	Step.DUEL_READY: ["Agora, um duelo real", "Vamos preparar um confronto: uma azul N3 contra uma vermelha oculta."],
	Step.DUEL_SELECT: ["Escolha quem avança", "Novo cenário de treino: selecione a azul N3 na casa dourada."],
	Step.DUEL_MOVE: ["Aproxime-se do inimigo", "Avance para a casa dourada, ao lado da vermelha. O combate é automático."],
	Step.UPDATED_CARD: ["A informação mudou", "Sua N3 venceu a N1. Veja a baixa vermelha e abra Cálculo vermelha outra vez."],
	Step.UNKNOWN_QUIZ: ["Atualize a contagem", "Uma N1 saiu. Restam 7 ocultas e só 1 N1. Qual é a nova fração de N1?"],
	Step.DRAW_READY: ["Teste o empate", "Correto! Vamos preparar um duelo entre duas peças do mesmo nível."],
	Step.DRAW_SELECT: ["Níveis iguais", "Novo cenário: selecione a azul N2 destacada para experimentar um empate."],
	Step.DRAW_MOVE: ["Provoque um empate", "Avance para a casa dourada e observe o combate e os dois cemitérios."],
	Step.DRAW_QUIZ: ["Quem sai no empate?", "Confira os cemitérios. Quais peças saem quando os dois níveis são iguais?"],
	Step.SIEGE_READY: ["Mais forte também perde", "Vamos treinar cerco. Quem se move perde entre 2 ou mais inimigos."],
	Step.SIEGE_SELECT: ["Escolha a mais forte", "Selecione a azul N4 destacada. Há dois inimigos ao redor do destino."],
	Step.SIEGE_MOVE: ["Experimente o cerco", "Mova para a casa dourada, entre as vermelhas. Observe o resultado."],
	Step.SIEGE_QUIZ: ["O cerco muda a regra", "Em cerco, o que acontece com a N4 que acabou de se mover?"],
	Step.FLAG_READY: ["O objetivo da missão", "Correto! Agora vamos capturar a bandeira vermelha com uma azul N1."],
	Step.FLAG_SELECT: ["Até a mais fraca vence", "Selecione a azul N1 perto da bandeira vermelha, na casa dourada."],
	Step.FLAG_MOVE: ["Capture a bandeira", "Mova para a bandeira vermelha destacada. Ocupar essa casa dá a vitória."],
	Step.COMPLETE: ["Treino concluído", "Você está pronto para uma partida contra a IA."]
}
const QUIZZES = {
	Step.LEVEL_QUIZ: [["12,5%", "25%", "50%"], 1, "Divida as 2 unidades N4 pelas 8 ocultas e tente novamente."],
	Step.WIN_QUIZ: [["25%", "50%", "75%"], 1, "Conte N1 e N2: são 4 resultados favoráveis entre 8 ocultas."],
	Step.UNKNOWN_QUIZ: [["1/8", "1/7", "2/7"], 1, "A eliminada já é conhecida. Sobram 7 ocultas, das quais 1 é N1."],
	Step.DRAW_QUIZ: [["Só azul", "As duas", "Só vermelha"], 1, "Observe que os dois cemitérios receberam uma unidade N2."],
	Step.SIEGE_QUIZ: [["É eliminada", "Vence"], 0, "Cerco não compara níveis: perde a unidade que entrou entre os inimigos."]
}

var step: Step = Step.SETUP
var exercise = "setup"
var busy = false
var card_seen = false
var correct_answers = 0
var coach: PanelContainer
var coach_counter: Label
var coach_title: Label
var coach_body: Label
var exit_button: Button
var next_button: Button
var answers: HBoxContainer
var answer_buttons: Array[Button] = []
var focus_outline: ReferenceRect
var graveyard_outline: ReferenceRect
var completion_layer: CanvasLayer

func _ready():
	_build_tutorial_ui()
	status_panel.hide()
	super._ready()

func start_new_game():
	exercise = "setup"
	step = Step.SETUP
	busy = false
	card_seen = false
	correct_answers = 0
	completion_layer.hide()
	coach.show()
	super.start_new_game()
	_refresh_coach()

func spawn_red_pieces_randomly():
	var positions: Array[Vector2i] = [
		Vector2i(2, 6), Vector2i(0, 7), Vector2i(1, 6), Vector2i(3, 7),
		Vector2i(5, 6), Vector2i(6, 7), Vector2i(4, 6), Vector2i(7, 7)
	]
	if exercise == "duel":
		positions[0] = Vector2i(2, 4)
	elif exercise == "draw":
		positions[2] = Vector2i(2, 4)
	elif exercise == "siege":
		positions[0] = Vector2i(2, 3)
		positions[2] = Vector2i(4, 3)
	elif exercise == "flag":
		positions.assign([
			Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(6, 6),
			Vector2i(7, 6), Vector2i(0, 7), Vector2i(1, 7), Vector2i(7, 7)
		])
	var levels = [1, 1, 2, 2, 3, 3, 4, 4]
	for index in range(levels.size()):
		create_piece_at(GamePiece.Player.RED, levels[index], positions[index])

func handle_setup_click(grid_pos: Vector2i):
	if step != Step.SETUP or busy:
		return
	if grid_pos != expected_cell():
		_hint("Neste treino, use a casa dourada para posicionar a próxima unidade.")
		return
	super.handle_setup_click(grid_pos)
	if blue_pieces_to_place.is_empty():
		_go(Step.SELECT)
	else:
		_refresh_coach()

func handle_grid_click(grid_pos: Vector2i):
	if busy or step == Step.COMPLETE:
		return
	if not _is_selection_step() and not _is_move_step():
		_hint("Siga a orientação acima: use o botão ou responda à pergunta do treino.")
		return
	if grid_pos != expected_cell():
		_hint("Use a casa dourada. Outras jogadas ficam livres na partida normal.")
		return
	if _is_selection_step():
		super.handle_grid_click(grid_pos)
		_go(step + 1)
		return
	if not is_instance_valid(selected_piece):
		return
	var completed_step = step
	busy = true
	exit_button.disabled = true
	coach_body.text = "Observe a jogada. Aguarde o fim da animação e do combate."
	await super.handle_grid_click(grid_pos)
	busy = false
	exit_button.disabled = false
	_go(completed_step + 1)

func switch_turn():
	# O turno vermelho é demonstrado explicitamente; os demais exercícios são guiados.
	current_turn = GamePiece.Player.BLUE
	update_status_msg()

func declare_winner():
	reset_button.hide()

func _is_selection_step() -> bool:
	return step in [Step.SELECT, Step.SELECT_FOR_ODDS, Step.DUEL_SELECT, Step.DRAW_SELECT, Step.SIEGE_SELECT, Step.FLAG_SELECT]

func _is_move_step() -> bool:
	return step in [Step.MOVE, Step.DUEL_MOVE, Step.DRAW_MOVE, Step.SIEGE_MOVE, Step.FLAG_MOVE]

func expected_cell() -> Vector2i:
	match step:
		Step.SETUP: return Vector2i(8 - blue_pieces_to_place.size(), 1)
		Step.SELECT: return Vector2i(4, 1)
		Step.MOVE, Step.SELECT_FOR_ODDS: return Vector2i(4, 2)
		Step.DUEL_SELECT, Step.DRAW_SELECT: return Vector2i(2, 2)
		Step.DUEL_MOVE, Step.DRAW_MOVE: return Vector2i(2, 3)
		Step.SIEGE_SELECT: return Vector2i(3, 2)
		Step.SIEGE_MOVE: return Vector2i(3, 3)
		Step.FLAG_SELECT: return Vector2i(4, 6)
		Step.FLAG_MOVE: return RED_FLAG
	return Vector2i(-1, -1)

func _go(next_step: int):
	step = next_step as Step
	card_seen = false
	_refresh_coach()
	if step == Step.COMPLETE:
		coach.hide()
		completion_layer.show()
		completion_layer.get_node("Backdrop/Center/Card/Content/Play").grab_focus()

func _refresh_coach():
	coach_counter.text = "TREINO %02d/25 · IA GUIADA" % mini(step + 1, 25)
	coach_title.text = LESSONS[step][0]
	coach_body.text = LESSONS[step][1]
	coach_body.add_theme_color_override("font_color", Color("bccbd3"))
	if step == Step.SETUP:
		coach_body.text = "Coloque a N%d na casa dourada (%d/8). As vermelhas começam ocultas." % [blue_pieces_to_place[0], 8 - blue_pieces_to_place.size()]
	next_button.visible = step in [Step.RED_TURN, Step.DUEL_READY, Step.DRAW_READY, Step.SIEGE_READY, Step.FLAG_READY]
	answers.visible = QUIZZES.has(step)
	for index in range(answer_buttons.size()):
		answer_buttons[index].visible = answers.visible and index < QUIZZES[step][0].size() if answers.visible else false
		if answer_buttons[index].visible:
			answer_buttons[index].text = QUIZZES[step][0][index]
	focus_outline.hide()
	graveyard_outline.hide()
	if step in [Step.RED_CARD, Step.UPDATED_CARD]:
		_focus_on(red_calculation_button)
	elif step == Step.BLUE_CARD:
		_focus_on(calculation_button)
	if step in [Step.UPDATED_CARD, Step.UNKNOWN_QUIZ]:
		graveyard_outline.position = red_discard_grid.get_global_rect().position - Vector2(3, 3)
		graveyard_outline.size = red_discard_grid.size + Vector2(6, 6)
		graveyard_outline.show()
	board_texture.queue_redraw()

func _hint(text: String):
	coach_body.text = text
	coach_body.add_theme_color_override("font_color", GOLD)

func _focus_on(control: Control):
	focus_outline.position = control.get_global_rect().position - Vector2(3, 3)
	focus_outline.size = control.size + Vector2(6, 6)
	focus_outline.show()
	control.grab_focus()

func _on_board_texture_draw():
	super._on_board_texture_draw()
	var target = expected_cell()
	if target.x >= 0 and step != Step.COMPLETE:
		var rect = Rect2(Vector2(target) * CELL_SIZE + Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8))
		board_texture.draw_rect(rect, Color(GOLD, 0.2), true)
		board_texture.draw_rect(rect, GOLD, false, 3.0)

func _on_view_red_calculation_pressed() -> void:
	super._on_view_red_calculation_pressed()
	if calculation_overlay.visible and step in [Step.RED_CARD, Step.UPDATED_CARD]:
		card_seen = true

func _on_view_calculation_pressed() -> void:
	super._on_view_calculation_pressed()
	if calculation_overlay.visible and step == Step.BLUE_CARD:
		card_seen = true

func _on_close_calculation_pressed() -> void:
	super._on_close_calculation_pressed()
	if card_seen:
		_go(step + 1)

func answer_question(index: int):
	if busy or not QUIZZES.has(step) or calculation_overlay.visible:
		return
	if index != QUIZZES[step][1]:
		_hint(QUIZZES[step][2])
		return
	correct_answers += 1
	_go(step + 1)

func continue_lesson():
	if busy:
		return
	match step:
		Step.RED_TURN:
			busy = true
			is_animating = true
			exit_button.disabled = true
			next_button.disabled = true
			current_turn = GamePiece.Player.RED
			coach_title.text = "Vez da equipe vermelha"
			coach_body.text = "Neste exemplo, uma vermelha avança. Na partida normal, a IA escolhe a jogada."
			await get_tree().create_timer(0.6).timeout
			await move_piece(board[4][6], Vector2i(4, 5))
			current_turn = GamePiece.Player.BLUE
			is_animating = false
			busy = false
			exit_button.disabled = false
			next_button.disabled = false
			update_status_msg()
			_go(Step.RED_CARD)
		Step.DUEL_READY: _prepare_exercise("duel", 3, Vector2i(2, 2), Step.DUEL_SELECT)
		Step.DRAW_READY: _prepare_exercise("draw", 2, Vector2i(2, 2), Step.DRAW_SELECT)
		Step.SIEGE_READY: _prepare_exercise("siege", 4, Vector2i(3, 2), Step.SIEGE_SELECT)
		Step.FLAG_READY: _prepare_exercise("flag", 1, Vector2i(4, 6), Step.FLAG_SELECT)

func _prepare_exercise(kind: String, blue_level: int, blue_pos: Vector2i, next_step: Step):
	exercise = kind
	super.start_new_game()
	blue_pieces_to_place.clear()
	var used_target = false
	var reserve = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
	for level in [1, 1, 2, 2, 3, 3, 4, 4]:
		if level == blue_level and not used_target:
			create_piece_at(GamePiece.Player.BLUE, level, blue_pos)
			used_target = true
		else:
			create_piece_at(GamePiece.Player.BLUE, level, reserve.pop_front())
	current_state = GameState.PLAYING
	current_turn = GamePiece.Player.BLUE
	update_status_msg()
	_go(next_step)

func _leave_tutorial():
	if not busy and not is_animating:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _build_tutorial_ui():
	coach = PanelContainer.new()
	coach.position = Vector2(528, 8)
	coach.size = Vector2(296, 136)
	var style = status_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	coach.add_theme_stylebox_override("panel", style)
	add_child(coach)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	coach.add_child(content)
	var header = HBoxContainer.new()
	content.add_child(header)
	coach_counter = _label("", 10, GOLD)
	coach_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(coach_counter)
	exit_button = _button("Sair", _leave_tutorial, 11)
	exit_button.custom_minimum_size = Vector2(42, 20)
	header.add_child(exit_button)
	coach_title = _label("", 16, Color.WHITE)
	content.add_child(coach_title)
	coach_body = _label("", 12, Color("bccbd3"))
	coach_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(coach_body)
	next_button = _button("Continuar", continue_lesson, 12)
	content.add_child(next_button)
	answers = HBoxContainer.new()
	answers.add_theme_constant_override("separation", 4)
	content.add_child(answers)
	for index in range(3):
		var button = _button("", answer_question.bind(index), 11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answers.add_child(button)
		answer_buttons.append(button)
	for index in range(2):
		var outline = ReferenceRect.new()
		outline.editor_only = false
		outline.border_color = GOLD
		outline.border_width = 2.0
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.z_index = 10
		outline.hide()
		add_child(outline)
		if index == 0: focus_outline = outline
		else: graveyard_outline = outline
	_build_completion_ui(style)

func _build_completion_ui(style: StyleBoxFlat):
	completion_layer = CanvasLayer.new()
	completion_layer.layer = 20
	add_child(completion_layer)
	var backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.015, 0.025, 0.035, 0.9)
	completion_layer.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	center.name = "Center"
	backdrop.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card = PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(440, 0)
	var card_style = style.duplicate() as StyleBoxFlat
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var content = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	content.add_child(_label("Treinamento concluído!", 24, GOLD))
	var summary = _label("Você praticou posicionamento, turnos e movimento,\nleu probabilidades e resolveu cinco desafios.\n\nDuelo: vence o maior nível.\nEmpate: ambas são eliminadas.\nCerco: perde quem se moveu.\nObjetivo: capturar a bandeira ou eliminar o inimigo.\n\nNa partida normal, a IA joga a cada turno.", 15, Color("bccbd3"))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary)
	var play = _button("Jogar partida", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"), 17)
	play.name = "Play"
	content.add_child(play)
	content.add_child(_button("Repetir tutorial", start_new_game, 15))
	content.add_child(_button("Voltar ao menu", _leave_tutorial, 15))
	completion_layer.hide()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, font_size: int) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 24
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(callback)
	return button
