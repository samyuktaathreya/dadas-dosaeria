extends Control

@export var ticket_scene: PackedScene
signal cooking_button_pressed
signal order_button_pressed
signal drink_button_pressed
signal chutney_button_pressed
signal order_scene_initialized

const EXPANDED_TICKET_POSITION = Vector2(1644.0, 492.0)
const EXPANDED_TICKET_SCALE = Vector2(1.0, 1.0)

const VERTICAL_SCORE_OFFSET = Vector2(125, -100)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var buttons := [
		$OrderButton,
		$CookingButton,
		$ChutneyButton,
		$DrinkButton
	]

	var screen_size = get_viewport_rect().size

	var bar_height = 120
	var padding = 20
	var spacing = 20

	var button_width = (screen_size.x - padding * 2 - spacing * (buttons.size() - 1)) / buttons.size()
	var button_height = 80

	for i in buttons.size():
		var btn = buttons[i]

		btn.anchor_left = 0
		btn.anchor_top = 0
		btn.anchor_right = 0
		btn.anchor_bottom = 0

		btn.position = Vector2(
			padding + i * (button_width + spacing),
			screen_size.y - bar_height + (bar_height - button_height) / 2 + 100
		)

		btn.size = Vector2(button_width, button_height)

		# Optional polish
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_constant_override("corner_radius", 16)
	
	# move scores right above button
	$ScoreLabels/OrderScore.position = $OrderButton.position + VERTICAL_SCORE_OFFSET
	$ScoreLabels/CookingScore.position = $CookingButton.position + VERTICAL_SCORE_OFFSET
	$ScoreLabels/ChutneyScore.position = $ChutneyButton.position + VERTICAL_SCORE_OFFSET
	$ScoreLabels/DrinkScore.position = $DrinkButton.position + VERTICAL_SCORE_OFFSET

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_main_create_ui_ticket(TicketPosition, customer):
	var ticket = ticket_scene.instantiate()
	ticket.load_ticket(TicketPosition, customer)
	add_child(ticket)
	
	return ticket

func _on_cooking_button_pressed() -> void:
	cooking_button_pressed.emit()

func _on_chutney_button_pressed() -> void:
	chutney_button_pressed.emit()

func _on_drink_button_pressed() -> void:
	drink_button_pressed.emit()

func _on_order_button_pressed() -> void:
	order_button_pressed.emit()

func _on_main_order_scene() -> void:
	# move any expanded tickets
	for child in get_children():
		print(child.get_node("BlankOrderTicket"))
		print(child.get_node("BlankOrderTicket").scale)
		if child.get_node("BlankOrderTicket").scale == EXPANDED_TICKET_SCALE:
			child.minimize_ticket()
		pass
