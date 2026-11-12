extends Control

func _ready():
	# Garante que o menu ocupe a tela toda perfeitamente
	set_anchors_preset(LayoutPreset.PRESET_FULL_RECT)
	$VBoxContainer/JogarButton.grab_focus()

func _on_jogar_button_pressed():
	# Muda da tela de menu para a tela do jogo tático
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_sair_button_pressed():
	# Fecha o jogo
	get_tree().quit()
