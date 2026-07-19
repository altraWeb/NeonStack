class_name ThemePack
extends Resource

@export var name: String = "Cyberpunk Neon"
@export var void_color: Color = Color(0.04, 0.02, 0.08, 1.0)
@export var grid_color: Color = Color(1.0, 0.2, 0.75, 0.22)
@export var bezel_color: Color = Color(0.2, 0.95, 1.0, 0.55)
@export var accent_hot: Color = Color(1.0, 0.15, 0.55, 1.0)
@export var accent_amber: Color = Color(1.0, 0.85, 0.15, 1.0)
@export var ghost_color: Color = Color(1.0, 0.4, 0.9, 0.35)
@export var hud_text: Color = Color(0.85, 0.95, 1.0, 0.95)
@export var hud_dim: Color = Color(0.7, 0.35, 0.85, 0.75)
@export var glow_outer: Color = Color(1.0, 0.1, 0.65, 0.45)

## Piece colors keyed by PieceType.Id — neon street palette
@export var piece_colors: Dictionary = {
	PieceType.Id.I: Color(0.15, 0.95, 1.0),
	PieceType.Id.O: Color(1.0, 0.9, 0.15),
	PieceType.Id.T: Color(1.0, 0.2, 0.85),
	PieceType.Id.S: Color(0.2, 1.0, 0.55),
	PieceType.Id.Z: Color(1.0, 0.25, 0.4),
	PieceType.Id.J: Color(0.35, 0.45, 1.0),
	PieceType.Id.L: Color(1.0, 0.55, 0.15),
}


static func cyberpunk_default() -> ThemePack:
	return ThemePack.new()


## Kept for older call sites / future theme switching.
static func orbital_default() -> ThemePack:
	return cyberpunk_default()


func color_for_cell(value: int) -> Color:
	if value <= 0:
		return Color(0, 0, 0, 0)
	var id := (value - 1) as PieceType.Id
	return piece_colors.get(id, Color.WHITE)


func color_for_piece(id: PieceType.Id) -> Color:
	return piece_colors.get(id, Color.WHITE)
