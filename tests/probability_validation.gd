extends SceneTree

const ProbabilityManager = preload("res://scripts/probability_manager.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_validation")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func run_validation() -> void:
	root.size = Vector2i(832, 704)
	var known: Array[int] = []
	check(ProbabilityManager.get_sample_space_size(known) == 2520, "Espaço inicial")
	for level in range(1, 5):
		check(is_equal_approx(ProbabilityManager.get_level_probabilities(known)[level], 0.25), "Chance inicial por nível")

	known.assign([4])
	check(ProbabilityManager.get_sample_space_size(known) == 630, "Uma revelação deixa 630 distribuições")
	known.assign([4, 4])
	check(ProbabilityManager.get_sample_space_size(known) == 90, "Dois níveis 4 conhecidos deixam 90 distribuições")
	var chances = ProbabilityManager.get_combat_probabilities(3, known)
	check(is_zero_approx(chances["loss_probability"]), "Azul 3 não perde quando ambos os níveis 4 são conhecidos")
	check(is_equal_approx(chances["win_probability"], 2.0 / 3.0), "Azul 3 vence quatro das seis desconhecidas")

	known.assign([1, 1, 2, 2, 3, 3, 4])
	check(ProbabilityManager.get_sample_space_size(known) == 1, "Uma única desconhecida tem uma distribuição")
	check(is_equal_approx(ProbabilityManager.get_level_probabilities(known)[4], 1.0), "Última desconhecida deduzida como nível 4")
	known.append(4)
	check(ProbabilityManager.get_unknown_red_total(known) == 0, "Nenhuma desconhecida")
	check(ProbabilityManager.get_sample_space_size(known) == 1, "Distribuição vazia única")
	for value in ProbabilityManager.get_level_probabilities(known).values():
		check(is_zero_approx(value), "Sem probabilidades quando não há desconhecidas")
	chances = ProbabilityManager.get_combat_probabilities(3, known)
	check(chances["total"] == 0, "Duelo sem universo desconhecido")
	check(is_zero_approx(chances["win_probability"] + chances["draw_probability"] + chances["loss_probability"]), "Duelo vazio sem divisão por zero")

	# Todas as 81 combinações válidas de quantidades conhecidas por nível.
	for a in range(3):
		for b in range(3):
			for c in range(3):
				for d in range(3):
					known.clear()
					var quantities = [a, b, c, d]
					for index in range(4):
						for _unit in range(quantities[index]):
							known.append(index + 1)
					var snapshot = known.duplicate()
					var total = ProbabilityManager.get_unknown_red_total(known)
					check(total + known.size() == 8, "Conservação das oito unidades")
					for blue_level in range(1, 5):
						chances = ProbabilityManager.get_combat_probabilities(blue_level, known)
						check(chances["wins"] + chances["draws"] + chances["losses"] == total, "Resultados cobrem todas as desconhecidas")
						var sum = chances["win_probability"] + chances["draw_probability"] + chances["loss_probability"]
						check(is_equal_approx(sum, 1.0 if total > 0 else 0.0), "Soma das chances de duelo")
					check(known == snapshot, "Cálculos preservam os dados recebidos")

	# Integração real com o tabuleiro e o HUD, incluindo o estado sem desconhecidas.
	var game = load("res://scenes/main.tscn").instantiate()
	game.debug_probabilities = false
	root.add_child(game)
	check(game.calculation_button.disabled, "Ver cálculo indisponível sem seleção")
	check(not game.red_calculation_button.disabled, "Cálculo vermelho disponível sem seleção")
	game.red_calculation_button.pressed.emit()
	check(game.calculation_overlay.visible and game.calculation_levels.visible and not game.calculation_results.visible, "Botão vermelho abre somente os cálculos de nível")
	game.calculation_close.pressed.emit()
	for x in range(8):
		game.handle_setup_click(Vector2i(x, 1))
	game.handle_grid_click(Vector2i(4, 1))
	check(game.probability_outcomes[0].get_node("Value").text == "50,0%", "HUD da azul nível 3")
	check(not game.calculation_button.disabled, "Ver cálculo habilitado com peça selecionada")
	game.calculation_button.pressed.emit()
	check(game.calculation_overlay.visible, "Botão abre o card")
	check(game.calculation_results.visible and not game.calculation_levels.visible, "Botão azul abre somente os cálculos de duelo")
	check(game.calculation_results.text.contains("Vitória: 4/8 = 50%"), "Card mostra a fração sem simplificar o total")
	check(game.calculation_levels.text == "Nível 1: 2/8 = 25%\nNível 2: 2/8 = 25%\nNível 3: 2/8 = 25%\nNível 4: 2/8 = 25%", "Card mostra a distribuição inicial dos níveis vermelhos")
	await process_frame
	await process_frame
	var card = game.get_node("CalculationOverlay/Backdrop/CenterContainer/Card")
	check(Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(card.get_global_rect()), "Card de duelo cabe na janela")
	game.red_calculation_button.pressed.emit()
	await process_frame
	await process_frame
	check(Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(card.get_global_rect()), "Card vermelho cabe na janela")
	var panel = game.get_node("ProbabilityPanel")
	check(Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(panel.get_global_rect()), "Painel com dois botões cabe na janela")
	game.calculation_button.pressed.emit()
	var revealed_for_example: Array[int] = []
	for piece in game.pieces_container.get_children():
		if piece.player_owner == GamePiece.Player.RED and piece.level in [1, 4] and piece.level not in revealed_for_example:
			revealed_for_example.append(piece.level)
			piece.reveal_level()
	game.update_probability_hud()
	check(game.calculation_results.text == "Vitória: 3/6 = 50%\nEmpate: 2/6 = 33,33%\nDerrota: 1/6 = 16,67%", "Card atualiza frações e percentuais do exemplo")
	check(game.calculation_levels.text == "Nível 1: 1/6 = 16,67%\nNível 2: 2/6 = 33,33%\nNível 3: 2/6 = 33,33%\nNível 4: 1/6 = 16,67%", "Cálculo da vermelha acompanha as revelações")
	game.handle_grid_click(Vector2i(0, 1))
	check(game.calculation_title.text.contains("nível 1"), "Card acompanha mudança de seleção")
	check(game.calculation_results.text.contains("Vitória: 0/6 = 0%"), "Card mostra zero casos favoráveis")
	game.calculation_close.pressed.emit()
	check(not game.calculation_overlay.visible, "Fechar oculta o card")
	game.calculation_button.pressed.emit()
	var escape = InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	game._input(escape)
	check(not game.calculation_overlay.visible, "Escape fecha o card")
	game.handle_grid_click(Vector2i(0, 1))
	check(game.calculation_button.disabled, "Desseleção desabilita o cálculo")
	game.red_calculation_button.pressed.emit()
	game.update_probability_hud()
	check(game.calculation_overlay.visible and game.calculation_levels.visible, "Card vermelho continua disponível sem seleção azul")
	game.calculation_close.pressed.emit()
	game.handle_grid_click(Vector2i(4, 1))
	game.calculation_button.pressed.emit()
	var red_pieces: Array[GamePiece] = []
	for piece in game.pieces_container.get_children():
		if piece.player_owner == GamePiece.Player.RED:
			red_pieces.append(piece)
			piece.reveal_level()
	game.update_probability_hud()
	check(game.probability_levels.text.contains("Todos os níveis"), "HUD sem desconhecidas")
	check(game.probability_combat.text.contains("Não há inimigos desconhecidos"), "HUD não estima duelo vazio")
	check(game.calculation_button.disabled and not game.calculation_overlay.visible, "Sem desconhecidas, cálculo fecha e fica indisponível")
	check(game.red_calculation_button.disabled, "Sem desconhecidas, cálculo vermelho fica indisponível")
	await process_frame
	await process_frame
	check(Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(panel.get_global_rect()), "Estado sem desconhecidas cabe no painel")
	for outcome in game.probability_outcomes:
		check(outcome.get_node("Value").text == "—", "Sem duelo estimável, remove percentuais anteriores")
	var eliminated = red_pieces[0]
	game.board[eliminated.grid_position.x][eliminated.grid_position.y] = null
	game.register_eliminated_piece(eliminated)
	check(game.get_known_red_levels().size() == 8, "Revelada eliminada continua conhecida uma única vez")
	game.start_new_game()
	check(game.get_unknown_red_total() == 8, "Reinício limpa o conhecimento")
	check(game.probability_sample_space.text == "2520", "Reinício atualiza o HUD")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PROBABILITY_VALIDATION_OK: cenários extremos, 81 estados e integração com HUD.")
	quit(0 if failures.is_empty() else 1)
