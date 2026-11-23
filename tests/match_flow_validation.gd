extends SceneTree

# Valida os ajustes da entrega final: briefing, pausa, volumes, música
# adaptativa, tela de resultado e reinício da partida.

var failures: Array[String] = []
var game
var audio

func _initialize():
	call_deferred("run_validation")
	create_timer(30).timeout.connect(func():
		push_error("Fluxo da partida excedeu o tempo de validação")
		quit(1))

func check(condition: bool, description: String):
	if not condition:
		failures.append(description)
		push_error(description)

func frames(count: int = 4):
	for frame in range(count):
		await process_frame

func fits_window(control: Control) -> bool:
	return Rect2(Vector2.ZERO, Vector2(832, 704)).encloses(control.get_global_rect())

func run_validation():
	root.size = Vector2i(832, 704)
	audio = root.get_node("AudioManager")
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames()
	check(audio.current_mood == "menu", "Menu usa trilha abafada")
	menu.get_node("VBoxContainer/JogarButton").pressed.emit()
	await frames()
	game = current_scene
	check(game.scene_file_path == "res://scenes/main.tscn", "Jogar abre a partida")

	# Briefing da missão
	var menus = game.menus
	check(menus.briefing.visible, "Primeira partida mostra o briefing")
	check(fits_window(menus.briefing.get_node("Center/Card")), "Briefing cabe na janela")
	game._input(_click(Vector2i(0, 0)))
	check(game.blue_pieces_to_place.size() == 8, "Clique no tabuleiro é bloqueado pelo briefing")
	menus.briefing_start.pressed.emit()
	check(not menus.is_open(), "Começar missão fecha o briefing")
	check(audio.current_mood == "preparacao", "Preparação usa trilha intermediária")

	# Posicionamento e início da batalha
	for x in [0, 1, 2, 3, 5, 6, 7]:
		game.handle_setup_click(Vector2i(x, 0))
	game.handle_setup_click(Vector2i(0, 1))
	check(game.current_state == game.GameState.PLAYING, "Oito peças iniciam a partida")
	check(audio.current_mood == "batalha", "Batalha abre a trilha")

	# Pausa e volumes
	game._input(_key(KEY_ESCAPE))
	check(menus.pause_screen.visible and paused, "Esc pausa a partida")
	check(fits_window(menus.pause_screen.get_node("Center/Card")), "Pausa cabe na janela")
	menus.music_slider.value = 40
	menus.sfx_slider.value = 0
	check(is_equal_approx(audio.music_volume, 0.4), "Controle de música altera o volume")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Efeitos")), "Efeitos em 0% ficam mudos")
	menus.sfx_slider.value = 100
	menus.music_slider.value = 80
	menus._unhandled_input(_key(KEY_ESCAPE))
	check(not menus.pause_screen.visible and not paused, "Esc retoma a partida")
	game.menu_button.pressed.emit()
	check(menus.pause_screen.visible, "Botão Menu abre a pausa")
	menus.get_node("Pause/Center/Card/Content").get_child(4).pressed.emit()
	check(menus.briefing.visible and menus.briefing_back.visible, "Como jogar reabre as regras")
	menus.briefing_back.pressed.emit()
	check(menus.pause_screen.visible, "Voltar retorna à pausa")
	menus.resume()

	# Batimento de tensão
	audio.set_combat_tension(true)
	await create_timer(0.3).timeout
	check(audio.heartbeat_player.playing, "Combate liga o batimento")
	audio.set_combat_tension(false)

	# Vitória por bandeira e tela de resultado
	var piece = game.board[0][1]
	game.board[0][1] = null
	game.board[game.RED_FLAG.x][game.RED_FLAG.y] = piece
	piece.grid_position = game.RED_FLAG
	game.check_victory_conditions()
	check(game.winner_player == GamePiece.Player.BLUE, "Captura da bandeira dá vitória azul")
	await create_timer(1.0).timeout
	check(menus.result_screen.visible, "Resultado aparece após a jogada final")
	check(menus.result_title.text == "VITÓRIA", "Resultado mostra vitória")
	check(menus.result_reason.text.contains("bandeira"), "Resultado explica o motivo")
	check(fits_window(menus.result_screen.get_node("Center/Card")), "Resultado cabe na janela")
	check(audio.current_mood == "fim", "Fim de jogo abafa a trilha")
	menus.result_play.pressed.emit()
	await frames()
	check(game.current_state == game.GameState.SETUP_AZUL and not menus.is_open(), "Jogar novamente reinicia")
	check(game.blue_pieces_to_place.size() == 8 and game.turn_count == 0, "Reinício repõe o exército")

	# Voltar ao menu e tutorial sem briefing
	game.menu_button.pressed.emit()
	menus.get_node("Pause/Center/Card/Content").get_child(9).pressed.emit()
	await frames()
	check(current_scene.scene_file_path == "res://scenes/menu.tscn", "Voltar ao menu pela pausa")
	check(not paused, "Menu não fica pausado")
	current_scene.get_node("VBoxContainer/TutorialButton").pressed.emit()
	await frames()
	check(not current_scene.menus.is_open(), "Tutorial não mostra briefing")
	check(not current_scene.menu_button.visible, "Tutorial usa o próprio botão Sair")
	current_scene.get_tree().change_scene_to_file("res://scenes/main.tscn")
	await frames()
	check(not current_scene.menus.briefing.visible, "Briefing aparece só uma vez por sessão")

	if failures.is_empty():
		print("MATCH_FLOW_VALIDATION_OK")
	else:
		print("MATCH_FLOW_VALIDATION_FAILED: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _key(code: Key) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _click(cell: Vector2i) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(cell) * 64 + Vector2(32, 32)
	return event
