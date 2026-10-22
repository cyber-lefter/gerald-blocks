class_name ToadPortrait
extends Control
## A toad in his nest, for the toad picker, the wardrobe and the menu.

var skin := FmmArt.TOAD
var hat := ""
var mood := "nap"
var dim := false
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	t = randf() * 5.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var u := minf(size.x / 3.4, size.y / 2.2)
	var c := Vector2(size.x / 2.0, size.y * 0.62)
	FmmArt.draw_nest(self, c + Vector2(0, u * 0.42), u * 1.5, u * 0.5)
	FmmArt.draw_toad(self, c, u / 110.0, t, mood, Vector2(0, 1), 0.0, skin, hat)
	if dim:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.05, 0.7))
		draw_string(UI.display_font(), Vector2(0, size.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, int(size.y * 0.4), Color(1, 1, 1, 0.5))
