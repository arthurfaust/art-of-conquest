extends SceneTree

var failures: Array[String] = []
var game

func _initialize():
	call_deferred("run_validation")
	create_timer(45).timeout.connect(func():
		push_error("Tutorial excedeu o tempo de validação")
		quit(1))

func check(condition: bool, description: String):
	if not condition:
		failures.append(description)
		push_error(description)

func settle():
	for frame in range(4):
		await process_frame
	check(game.coach.get_global_rect().end.y <= 152, "Instrução cabe acima das probabilidades: %s" % game.step)
	check(game.coach.get_global_rect().end.x <= 832, "Instrução cabe na largura da janela")

func click_target():
	await game.handle_grid_click(game.expected_cell())
	await settle()

func card(red: bool):
	var before = game.step
	game._on_close_calculation_pressed()
	check(game.step == before, "Fechar sem ler não avança")
	if red:
		game.red_calculation_button.pressed.emit()
	else:
		game.calculation_button.pressed.emit()
	check(game.calculation_overlay.visible, "Card solicitado abre")
	check(game.step == before, "Abrir card aguarda fechamento")
	game.calculation_close.pressed.emit()
	check(game.step == before + 1, "Fechar card lido avança")
	await settle()

func quiz():
	var before = game.step
	var correct = game.QUIZZES[before][1]
	game.answer_buttons[(correct + 1) % 2].pressed.emit()
	check(game.step == before, "Resposta errada mantém a pergunta")
	check(not game.coach_body.text.is_empty(), "Erro apresenta explicação")
	await settle()
	game.answer_buttons[correct].pressed.emit()
	check(game.step == before + 1, "Resposta correta avança")
	await settle()

func run_validation():
	root.size = Vector2i(832, 704)
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.get_node("VBoxContainer/TutorialButton").pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.scene_file_path == "res://scenes/tutorial.tscn", "Menu abre tutorial")
	await settle()
	game.handle_setup_click(Vector2i(7, 0))
	check(game.blue_pieces_to_place.size() == 8, "Posicionamento incorreto não altera o exército")
	for index in range(8):
		game.handle_setup_click(game.expected_cell())
		await settle()
	check(game.step == game.Step.SELECT, "Oito posicionamentos iniciam seleção")
	game.handle_grid_click(Vector2i(0, 1))
	check(game.selected_piece == null, "Seleção fora do alvo é ignorada")
	await click_target()
	check(game.selected_piece.level == 3, "Seleciona N3 real")
	game.handle_grid_click(Vector2i(5, 2))
	check(game.step == game.Step.MOVE, "Movimento diagonal não avança")
	await click_target()
	check(game.board[4][2] != null, "Movimento altera tabuleiro")
	await game.continue_lesson()
	await settle()
	check(game.board[4][5] != null and game.current_turn == GamePiece.Player.BLUE, "Turno vermelho demonstrado")
	await card(true)
	await quiz()
	await click_target()
	await card(false)
	await quiz()
	game.next_button.pressed.emit()
	await settle()
	await click_target()
	await click_target()
	check(game.eliminated_red == [1], "Duelo elimina N1 vermelha")
	check(game.board[2][3].level == 3, "Azul N3 sobrevive ao duelo")
	check(game.get_unknown_red_total() == 7, "Duelo atualiza desconhecidas")
	await card(true)
	await quiz()
	game.next_button.pressed.emit()
	await settle()
	check(game.get_unknown_red_total() == 8, "Novo exercício reinicia informações")
	await click_target()
	await click_target()
	check(game.eliminated_blue == [2] and game.eliminated_red == [2], "Empate elimina ambas N2")
	await quiz()
	game.next_button.pressed.emit()
	await settle()
	await click_target()
	await click_target()
	check(game.eliminated_blue == [4] and game.eliminated_red.is_empty(), "Cerco elimina somente N4 azul")
	check(game.get_unknown_red_total() == 6, "Cerco revela duas vermelhas vivas")
	await quiz()
	game.next_button.pressed.emit()
	await settle()
	await click_target()
	await click_target()
	check(game.step == game.Step.COMPLETE, "Percurso chega ao fim")
	check(game.winner_player == GamePiece.Player.BLUE, "Captura dá vitória azul")
	check(game.correct_answers == 5, "Cinco desafios resolvidos")
	check(game.completion_layer.visible, "Conclusão mostra ações")
	var panel = game.completion_layer.get_node("Backdrop/Center/Card")
	check(Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(panel.get_global_rect()), "Conclusão cabe na janela")
	panel.get_node("Content").get_child(3).pressed.emit()
	await settle()
	check(game.step == game.Step.SETUP and game.correct_answers == 0, "Repetir reinicia tutorial")
	check(game.blue_pieces_to_place.size() == 8 and game.get_unknown_red_total() == 8, "Repetir repõe exércitos")
	game.exit_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/menu.tscn", "Sair retorna ao menu")
	current_scene.get_node("VBoxContainer/JogarButton").pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Jogar mantém partida normal")
	check(current_scene.status_panel.visible, "Partida normal mostra status original")
	if failures.is_empty():
		print("TUTORIAL_VALIDATION_OK")
	else:
		print("TUTORIAL_VALIDATION_FAILED: ", failures.size())
	quit(0 if failures.is_empty() else 1)
