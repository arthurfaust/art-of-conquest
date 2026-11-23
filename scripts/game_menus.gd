extends CanvasLayer

# Telas sobrepostas da partida: briefing da missão, pausa e resultado final.
# A cena principal só escuta os sinais; esta camada não conhece as regras.

signal start_requested
signal tutorial_requested
signal restart_requested
signal menu_requested

const GOLD = Color("dfbf7a")
const TEXT = Color("d4dde2")
const MUTED = Color("a3b3bc")
const BLUE = Color("78c2ff")
const RED = Color("ff8c7d")

const STORY = "A trégua acabou. Durante a noite, o exército Vermelho cavou trincheiras do outro lado do campo e escondeu suas tropas sob lonas de blindados. Ninguém sabe quem está em cada posição.\n\nVocê é o comandante Azul. Com oito unidades e muita dedução, precisa tomar a bandeira inimiga antes que o Vermelho alcance a sua."
const RULES = [
	["Objetivo", "Leve uma peça até a bandeira vermelha ou elimine todo o exército inimigo."],
	["Preparação", "Clique nas casas destacadas para posicionar suas 8 unidades."],
	["Turno", "Clique em uma peça azul e depois em uma casa iluminada. Anda 1 casa, sem diagonal."],
	["Combate", "Parou ao lado de um inimigo? Vence o maior nível; empate elimina os dois."],
	["Cerco", "Entre 2 ou mais inimigos, a peça que se moveu é eliminada."],
	["Dedução", "Use o painel de probabilidades para escolher quem arriscar."]
]

var briefing: Control
var briefing_start: Button
var briefing_tutorial: Button
var briefing_back: Button
var pause_screen: Control
var result_screen: Control
var result_card: PanelContainer
var result_title: Label
var result_reason: Label
var result_stats: Label
var result_play: Button
var music_slider: HSlider
var sfx_slider: HSlider

func _ready():
	layer = 30
	# Continua respondendo enquanto a árvore está pausada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	briefing = _build_briefing()
	pause_screen = _build_pause()
	result_screen = _build_result()
	hide_all()

func is_open() -> bool:
	return briefing.visible or pause_screen.visible or result_screen.visible

func hide_all():
	briefing.hide()
	pause_screen.hide()
	result_screen.hide()
	get_tree().paused = false

# from_pause = true reabre as regras a partir da pausa, com botão de voltar.
func show_briefing(from_pause: bool = false):
	pause_screen.hide()
	briefing_start.visible = not from_pause
	briefing_tutorial.visible = not from_pause
	briefing_back.visible = from_pause
	briefing.show()
	(briefing_back if from_pause else briefing_start).grab_focus()

func show_pause():
	music_slider.set_value_no_signal(AudioManager.music_volume * 100.0)
	sfx_slider.set_value_no_signal(AudioManager.sfx_volume * 100.0)
	_refresh_slider_labels()
	briefing.hide()
	pause_screen.show()
	get_tree().paused = true
	pause_screen.get_node("Center/Card/Content/Continue").grab_focus()

func resume():
	pause_screen.hide()
	briefing.hide()
	get_tree().paused = false

func show_result(blue_won: bool, reason: String, stats: String):
	var accent = BLUE if blue_won else RED
	result_title.text = "VITÓRIA" if blue_won else "DERROTA"
	result_title.add_theme_color_override("font_color", accent)
	result_reason.text = reason
	result_stats.text = stats
	var style = result_card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = accent
	result_card.add_theme_stylebox_override("panel", style)
	result_screen.show()
	result_play.grab_focus()

func _unhandled_input(event):
	# Com a árvore pausada, só esta camada recebe a tecla Esc.
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if pause_screen.visible:
			resume()
			get_viewport().set_input_as_handled()
		elif briefing.visible and briefing_back.visible:
			show_pause()
			get_viewport().set_input_as_handled()

func _build_briefing() -> Control:
	var content = _screen("Briefing", 600)
	content.add_child(_label("BRIEFING DA MISSÃO", 12, GOLD))
	content.add_child(_label("Operação Bandeira Vermelha", 26, TEXT))
	var story = _label(STORY, 14, MUTED)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(story)
	content.add_child(HSeparator.new())
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for rule in RULES:
		grid.add_child(_label(rule[0].to_upper(), 12, GOLD))
		var line = _label(rule[1], 13, TEXT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = 440
		grid.add_child(line)
	content.add_child(_label("Esc abre o menu de pausa durante a partida.", 12, MUTED))
	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	briefing_start = _button("Começar missão", _on_start_pressed, 17)
	briefing_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(briefing_start)
	briefing_tutorial = _button("Fazer o tutorial", func(): tutorial_requested.emit(), 15)
	buttons.add_child(briefing_tutorial)
	briefing_back = _button("Voltar", show_pause, 15)
	briefing_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(briefing_back)
	return content.get_parent().get_parent().get_parent()

func _build_pause() -> Control:
	var content = _screen("Pause", 360)
	content.add_child(_label("PARTIDA PAUSADA", 12, GOLD))
	content.add_child(_label("Menu", 24, TEXT))
	var continue_button = _button("Continuar", resume, 17)
	continue_button.name = "Continue"
	content.add_child(continue_button)
	content.add_child(_button("Reiniciar partida", _on_restart_pressed, 15))
	content.add_child(_button("Como jogar", show_briefing.bind(true), 15))
	content.add_child(HSeparator.new())
	music_slider = _volume_row(content, "Música", func(value): AudioManager.set_music_volume(value / 100.0))
	sfx_slider = _volume_row(content, "Efeitos", func(value): AudioManager.set_sfx_volume(value / 100.0))
	content.add_child(HSeparator.new())
	content.add_child(_button("Voltar ao menu", _on_menu_pressed, 15))
	return content.get_parent().get_parent().get_parent()

func _build_result() -> Control:
	var content = _screen("Result", 400)
	result_card = content.get_parent()
	content.add_child(_label("PARTIDA ENCERRADA", 12, GOLD))
	result_title = _label("", 36, TEXT)
	content.add_child(result_title)
	result_reason = _label("", 15, TEXT)
	result_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(result_reason)
	result_stats = _label("", 13, MUTED)
	content.add_child(result_stats)
	result_play = _button("Jogar novamente", _on_restart_pressed, 17)
	content.add_child(result_play)
	content.add_child(_button("Ver o tabuleiro", func(): result_screen.hide(), 15))
	content.add_child(_button("Voltar ao menu", _on_menu_pressed, 15))
	return content.get_parent().get_parent().get_parent()

func _on_start_pressed():
	briefing.hide()
	start_requested.emit()

func _on_restart_pressed():
	hide_all()
	restart_requested.emit()

func _on_menu_pressed():
	hide_all()
	menu_requested.emit()

# Fundo escurecido + cartão centralizado. Retorna o VBox de conteúdo do cartão.
func _screen(screen_name: String, width: float) -> VBoxContainer:
	var backdrop = ColorRect.new()
	backdrop.name = screen_name
	backdrop.color = Color(0.015, 0.025, 0.035, 0.88)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	center.name = "Center"
	backdrop.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card = PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(width, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.085, 0.98)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var content = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	return content

func _volume_row(parent: Control, title: String, on_change: Callable) -> HSlider:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var caption = _label(title, 14, TEXT)
	caption.custom_minimum_size.x = 64
	row.add_child(caption)
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	slider.value_changed.connect(func(_value): _refresh_slider_labels())
	row.add_child(slider)
	var value_label = _label("", 13, MUTED)
	value_label.name = "Value"
	value_label.custom_minimum_size.x = 44
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return slider

func _refresh_slider_labels():
	for slider in [music_slider, sfx_slider]:
		slider.get_parent().get_node("Value").text = "%d%%" % slider.value

func _label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, font_size: int) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 34
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(callback)
	return button
