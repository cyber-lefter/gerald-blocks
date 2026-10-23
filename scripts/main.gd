extends Control
## Screen router. Keeps the animated backdrop and swaps screens on top of it.

var backdrop: Control
var current: Control


func _ready() -> void:
	Shapes.init()
	BlockArt.ensure()
	backdrop = Widgets.Backdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show_menu()


func _swap(screen: Control) -> void:
	if current != null:
		current.queue_free()
	current = screen
	screen.set("router", self)
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.18)


func show_menu() -> void:
	_swap(MainMenu.new())


func show_run_shop() -> void:
	_swap(RunShop.new())


func show_toad_pick() -> void:
	_swap(ToadPick.new())


func show_collection() -> void:
	_swap(CollectionScreen.new())


func show_wardrobe() -> void:
	_swap(WardrobeScreen.new())


func show_settings() -> void:
	_swap(SettingsScreen.new())


func show_credits() -> void:
	_swap(CreditsScreen.new())


func start_game(mode: String) -> void:
	var g := GameScreen.new()
	g.mode = mode
	_swap(g)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if Ads.busy:
			return
		if current is MainMenu:
			get_tree().quit()
		elif current.has_method("go_back"):
			current.call("go_back")
		else:
			show_menu()
