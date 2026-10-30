extends Sprite2D
class_name GamePiece

enum Player { BLUE, RED }

@export var player_owner: Player = Player.BLUE
@export var level: int = 1
var grid_position: Vector2i = Vector2i.ZERO
var is_revealed: bool = false

# Controla o destaque visual da peça selecionada
var is_selected: bool = false

# Dicionário com as imagens reais de cada nível
const TEXTURES = {
	1: "res://assets/images/1.Agente Infiltrado.png",
	2: "res://assets/images/2.Fuzileiro.png",
	3: "res://assets/images/3.Lançador de Mísseis.png",
	4: "res://assets/images/4.Atirador de Elite.png",
	5: "res://assets/images/5.General.png"
}

# Caminho da imagem misteriosa (névoa de guerra)
const DEFAULT_TEXTURE = "res://assets/images/Default.png"

func setup(player: Player, lvl: int, start_pos: Vector2i):
	player_owner = player
	level = lvl
	grid_position = start_pos
	
	# Mantém a peça com sua cor original (sem pintar o soldado todo de azul/vermelho)
	modulate = Color.WHITE
	
	# REGRA DE REVELAÇÃO INICIAL:
	if player == Player.RED:
		is_revealed = false
		texture = load(DEFAULT_TEXTURE)
	else:
		is_revealed = true

		if TEXTURES.has(level):
			texture = load(TEXTURES[level])
	
	_adjust_scale()
	
	if has_node("Label"):
		$Label.text = str(level)
		if player == Player.RED:
			$Label.visible = false
			
	# Avisa o Godot para desenhar a borda colorida imediatamente
	queue_redraw()

# Ativa/desativa o destaque visual da peça
func set_selected(active: bool):
	is_selected = active
	queue_redraw()

func _adjust_scale():
	if texture:
		var target_size = 64.0 # Baseado no CELL_SIZE do tabuleiro
		var current_size = texture.get_size().x
		scale = Vector2(target_size / current_size, target_size / current_size)

# Função modificada para revelar a identidade do inimigo com um efeito suave de transição
func reveal_level():
	# Peças azuis já são conhecidas desde o início.
	if player_owner == Player.BLUE:
		is_revealed = true

		if has_node("Label"):
			$Label.visible = true

		return

	# Evita revelar/animação novamente caso a peça vermelha
	# já tenha sido descoberta anteriormente.
	if is_revealed:
		return

	is_revealed = true

	# Se for uma peça Vermelha oculta, fazemos a animação de revelação.
	var tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.15
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		if has_node("Label"):
			$Label.visible = true

		if TEXTURES.has(level):
			texture = load(TEXTURES[level])
			_adjust_scale()

		queue_redraw()
	)

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.15
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# Função nativa do Godot usada para desenhar a moldura ao redor da peça
func _draw():
	if texture:
		var tex_size = texture.get_size()
		
		# Destaque extra quando a peça está selecionada.
		# Duas bordas sobrepostas criam um efeito simples de brilho.
		if is_selected:
			var glow_thickness = 7.0 / scale.x
			var glow_offset = glow_thickness / 2.0
			var glow_rect = Rect2(
				-tex_size / 2.0 + Vector2(glow_offset, glow_offset),
				tex_size - Vector2(glow_thickness, glow_thickness)
			)
			draw_rect(
				glow_rect,
				Color(0.10, 0.70, 1.0, 0.45),
				false,
				glow_thickness
			)
			
			var selection_thickness = 4.0 / scale.x
			var selection_offset = selection_thickness / 2.0
			var selection_rect = Rect2(
				-tex_size / 2.0 + Vector2(selection_offset, selection_offset),
				tex_size - Vector2(selection_thickness, selection_thickness)
			)
			draw_rect(
				selection_rect,
				Color(0.25, 0.85, 1.0, 1.0),
				false,
				selection_thickness
			)
		
		# Borda normal que identifica o time.
		var thickness = 2.0 / scale.x
		var offset = thickness / 2.0
		var rect = Rect2(
			-tex_size / 2.0 + Vector2(offset, offset),
			tex_size - Vector2(thickness, thickness)
		)
		
		var border_color = Color(0.0, 0.5, 1.0) if player_owner == Player.BLUE else Color(1.0, 0.2, 0.2)
		draw_rect(rect, border_color, false, thickness)
