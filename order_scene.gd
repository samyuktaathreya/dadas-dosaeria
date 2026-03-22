extends Control

signal order_complete 

var current_order = {}
const TIME_INTERVAL = 1.0
var customerOrdered
const DOSA_FILE_PATH = "res://assets/dosas/"
const CHUTNEY_FILE_PATH = "res://assets/chutneys/"
var SPEECH_BUBBLE_POSITION
const SPEECH_BUBBLE_DOSA_SCALE = Vector2(0.5, 0.455)
const SPACE_BETWEEN_ICONS_ON_BIG_TICKET = 200
const BIG_TICKET_DOSA_SCALE = Vector2(0.492, 0.419)
var ICON_STARTING_TICKET_POSITION
const SPEECH_BUBBLE_CHUTNEY_SCALE = Vector2(0.4, 0.4)
const BIG_TICKET_CHUTNEY_SCALE = Vector2(0.4, 0.4)

func _ready():
	SPEECH_BUBBLE_POSITION = $OrderBubble/SpeechBubbleIconPosition.position
	ICON_STARTING_TICKET_POSITION = $TicketCinematic/IconStartingTicketPosition.global_position

func show_order(customer):
	current_order = customer.data.order
	customerOrdered = customer
	$TicketCinematic.position = Vector2(1644, 492)
	$TicketCinematic.scale = Vector2(1.,1.)
	show()
	play_order_animation()

func play_order_animation():
	var tween = create_tween()
	var time = 0.0
	
	# Fade in from black
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	time += TIME_INTERVAL

	show_icons(tween, time)
	
	#hide speech bubble when customer done speaking
	$OrderBubble/BubbleSprite.hide()
	
	# Finished
	tween.tween_callback(on_animation_complete)

func show_food_icon(where, what):
	$OrderBubble/BubbleSprite.show()
	print(where + "/FoodIcons/" + what)
	get_node(where + "/FoodIcons/" + what).show()

func hide_food_icon(where, what):
	get_node(where + "/FoodIcons/" + what).hide()
	$OrderBubble/BubbleSprite.hide()

func on_animation_complete():
	print("Order animation finished!")
	# send signal to main that the order is finished
	# main will 
	# animate the cinematic ticket moving to the UI
	# hide the order scene
	order_complete.emit(customerOrdered)

func spawn_icon(icon_texture, icon_position, icon_scale):
	var icon = Sprite2D.new()
	icon.texture = icon_texture
	icon.global_position = icon_position
	icon.scale = icon_scale
	icon.visible = true
	print("icon global position: ", icon.global_position)
	add_child(icon)
	return icon
	
func show_icons(tween, time):
	var ticket_position = ICON_STARTING_TICKET_POSITION
	
	for dosa in current_order.dosa:
		var dosa_texture = load(DOSA_FILE_PATH + dosa + ".png")
		var speech_bubble_dosa = spawn_icon(dosa_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_DOSA_SCALE)

		tween.tween_interval(TIME_INTERVAL)
		spawn_icon(dosa_texture, ticket_position, BIG_TICKET_DOSA_SCALE)
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET
		tween.tween_callback(speech_bubble_dosa.queue_free)

	for chutney in current_order.chutney:
		var chutney_texture = load(CHUTNEY_FILE_PATH + chutney + ".png")
		var speech_bubble_chutney = spawn_icon(chutney_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_CHUTNEY_SCALE)

		tween.tween_interval(TIME_INTERVAL)
		spawn_icon(chutney_texture, ticket_position, BIG_TICKET_CHUTNEY_SCALE)
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET
		tween.tween_callback(speech_bubble_chutney.queue_free)
func _on_main_order_scene(customer) -> void:
	show_order(customer)
	
func update_ticket(ticket_position: Vector2) -> void:
	const TICKET_SCALE = 0.3
	const DURATION = 0.4

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property($TicketCinematic, "position", ticket_position, DURATION)
	tween.tween_property($TicketCinematic, "scale", Vector2(TICKET_SCALE, TICKET_SCALE), DURATION)
