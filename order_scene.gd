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

var ticket_icons = []

var testing_order_scene = false

func _ready():
	SPEECH_BUBBLE_POSITION = $OrderBubble/SpeechBubbleIconPosition.position
	if testing_order_scene:
		show_order(null)
	$OrderBubble/BubbleSprite.hide()

func show_order(customer):
	if testing_order_scene:
		current_order = { "dosa": ["OnionDosa"], "chutney": ["MintChutney"] }
	else:
		current_order = customer.data.order
		customerOrdered = customer
	print(" customer order : ", current_order)
	$TicketCinematic.position = Vector2(1644, 492)
	$TicketCinematic.scale = Vector2(1.,1.)
	show()
	play_order_animation()

func play_order_animation():
	var tween = create_tween()
	
	# Fade in from black
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	await get_tree().create_timer(TIME_INTERVAL).timeout
	
	await show_icons()
	
	on_animation_complete()

func show_icons():
	var ticket_position = $TicketCinematic/IconStartingTicketPosition.global_position
	
	for dosa in current_order.dosa:
		var dosa_texture = load(DOSA_FILE_PATH + dosa + ".png")
		
		$OrderBubble/BubbleSprite.show()
		var speech_bubble_dosa = spawn_icon(dosa_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_DOSA_SCALE)
		await get_tree().create_timer(TIME_INTERVAL).timeout
		ticket_icons.pop_back()		

		spawn_icon(dosa_texture, ticket_position, BIG_TICKET_DOSA_SCALE)
		await get_tree().create_timer(TIME_INTERVAL).timeout
		
		speech_bubble_dosa.queue_free()
		$OrderBubble/BubbleSprite.hide()
		await get_tree().create_timer(TIME_INTERVAL).timeout
		
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET

	for chutney in current_order.chutney:
		var chutney_texture = load(CHUTNEY_FILE_PATH + chutney + ".png")
		
		$OrderBubble/BubbleSprite.show()
		var speech_bubble_chutney = spawn_icon(chutney_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_CHUTNEY_SCALE)
		await get_tree().create_timer(TIME_INTERVAL).timeout
		ticket_icons.pop_back()
		
		spawn_icon(chutney_texture, ticket_position, BIG_TICKET_CHUTNEY_SCALE)
		await get_tree().create_timer(TIME_INTERVAL).timeout
		
		speech_bubble_chutney.queue_free()
		$OrderBubble/BubbleSprite.hide()
		await get_tree().create_timer(TIME_INTERVAL).timeout
		
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET

func on_animation_complete():
	while len(ticket_icons) > 0:
		var icon = ticket_icons.pop_front()
		icon.queue_free()
	print("Order animation finished!")
	# send signal to main that the order is finished
	# main will 
	# animate the cinematic ticket moving to the UI
	# hide the order scene
	order_complete.emit(customerOrdered)

func spawn_icon(icon_texture, icon_position, icon_scale):
	var icon = Sprite2D.new()
	icon.texture = icon_texture
	icon.scale = icon_scale
	icon.visible = true
	print("icon global position: ", icon.global_position)
	add_child(icon)
	icon.global_position = icon_position
	ticket_icons.append(icon)
	return icon

func _on_main_order_scene(customer) -> void:
	show_order(customer)
	
func update_ticket(ticket_position: Vector2) -> void:
	const TICKET_SCALE = 0.3
	const DURATION = 0.4

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property($TicketCinematic, "position", ticket_position, DURATION)
	tween.tween_property($TicketCinematic, "scale", Vector2(TICKET_SCALE, TICKET_SCALE), DURATION)
