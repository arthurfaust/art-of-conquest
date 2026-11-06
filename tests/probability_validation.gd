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
	for x in range(8):
		game.handle_setup_click(Vector2i(x, 1))
	game.handle_grid_click(Vector2i(4, 1))
	check(game.probability_combat.text.contains("Vitória: 50.0%"), "HUD da azul nível 3")
	var red_pieces: Array[GamePiece] = []
	for piece in game.pieces_container.get_children():
		if piece.player_owner == GamePiece.Player.RED:
			red_pieces.append(piece)
			piece.reveal_level()
	game.update_probability_hud()
	check(game.probability_levels.text.contains("Todos os níveis"), "HUD sem desconhecidas")
	check(game.probability_combat.text.contains("Não há inimigos desconhecidos"), "HUD não estima duelo vazio")
	var eliminated = red_pieces[0]
	game.board[eliminated.grid_position.x][eliminated.grid_position.y] = null
	game.register_eliminated_piece(eliminated)
	check(game.get_known_red_levels().size() == 8, "Revelada eliminada continua conhecida uma única vez")
	game.start_new_game()
	check(game.get_unknown_red_total() == 8, "Reinício limpa o conhecimento")
	check(game.probability_summary.text.contains("2520"), "Reinício atualiza o HUD")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PROBABILITY_VALIDATION_OK: cenários extremos, 81 estados e integração com HUD.")
	quit(0 if failures.is_empty() else 1)
