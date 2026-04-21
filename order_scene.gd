extends Control

signal order_complete 

var current_order = {}
const TIME_INTERVAL = 1.0
var customerOrdered
const CUSTOMER_FILE_PATH = "res://assets/customers/"
const DOSA_FILE_PATH = "res://assets/dosas/"
const CHUTNEY_FILE_PATH = "res://assets/chutneys/"
const DRINK_FILE_PATH = "res://assets/drinks/"

var SPEECH_BUBBLE_POSITION
const SPEECH_BUBBLE_DOSA_SCALE = Vector2(0.5, 0.455)
const SPACE_BETWEEN_ICONS_ON_BIG_TICKET = 200
const BIG_TICKET_DOSA_SCALE = Vector2(0.492, 0.419)
var ICON_STARTING_TICKET_POSITION
const SPEECH_BUBBLE_CHUTNEY_SCALE = Vector2(0.4, 0.4)
const BIG_TICKET_CHUTNEY_SCALE = Vector2(0.4, 0.4)

const SPEECH_BUBBLE_DRINK_SCALE = Vector2(0.4, 0.4)
const BIG_TICKET_DRINK_SCALE = Vector2(0.4, 0.4)

var ticket_icons = []

var testing_order_scene = false
var customer_order_sprite 

# --- NEW: Flag to track if we are currently waiting ---
var waiting_for_step = false

func _ready():
	SPEECH_BUBBLE_POSITION = $OrderBubble/SpeechBubbleIconPosition.position
	if testing_order_scene:
		show_order(null)
	$OrderBubble/BubbleSprite.hide()
	
	for child in $CustomerOrderSprites.get_children():
		child.hide()

# --- NEW: Detect clicks to skip the current wait ---
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if waiting_for_step:
			waiting_for_step = false # This breaks the loop in wait_or_skip instantly

# --- NEW: Helper function to wait or skip ---
func wait_or_skip(duration: float):
	waiting_for_step = true
	var timer = get_tree().create_timer(duration)
	
	# Wait until either the timer runs out OR waiting_for_step becomes false via a click
	while waiting_for_step and timer.time_left > 0:
		await get_tree().process_frame
	
	waiting_for_step = false

func show_order(customer):
	if testing_order_scene:
		current_order = { 
			"dosa": ["OnionDosa"], 
			"chutney": ["MintChutney"], 
			"drink": "MangoLassi", 
			"sugar": true, 
			"ice": false
		}
	else:
		current_order = customer.data.order
		customerOrdered = customer
	print(" customer order : ", current_order)
	$TicketCinematic.position = Vector2(1644, 492)
	$TicketCinematic.scale = Vector2(1.,1.)
	show()
	# show the correct customer sprite
	print("customer name: ", customer.name)
	customer_order_sprite = $CustomerOrderSprites.get_node(customer.data.name)
	customer_order_sprite.show()
	
	play_order_animation()

func play_order_animation():
	var tween = create_tween()
	
	# Fade in from black
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	await wait_or_skip(TIME_INTERVAL)
	
	await show_icons()
	
	await on_animation_complete()

func show_icons():
	var ticket_position = $TicketCinematic/IconStartingTicketPosition.global_position
	
	for dosa in current_order.dosa:
		var dosa_texture = load(DOSA_FILE_PATH + dosa + ".png")
		
		$OrderBubble/BubbleSprite.show()
		var speech_bubble_dosa = spawn_icon(dosa_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_DOSA_SCALE)
		await wait_or_skip(TIME_INTERVAL)
		ticket_icons.pop_back()		

		spawn_icon(dosa_texture, ticket_position, BIG_TICKET_DOSA_SCALE)
		await wait_or_skip(TIME_INTERVAL)
		
		speech_bubble_dosa.queue_free()
		$OrderBubble/BubbleSprite.hide()
		await wait_or_skip(TIME_INTERVAL)
		
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET

	for chutney in current_order.chutney:
		var chutney_texture = load(CHUTNEY_FILE_PATH + chutney + ".png")
		
		$OrderBubble/BubbleSprite.show()
		var speech_bubble_chutney = spawn_icon(chutney_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_CHUTNEY_SCALE)
		await wait_or_skip(TIME_INTERVAL)
		ticket_icons.pop_back()
		
		spawn_icon(chutney_texture, ticket_position, BIG_TICKET_CHUTNEY_SCALE)
		await wait_or_skip(TIME_INTERVAL)
		
		speech_bubble_chutney.queue_free()
		$OrderBubble/BubbleSprite.hide()
		await wait_or_skip(TIME_INTERVAL)
		
		ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET
		
	# handle drinks
	var drink = current_order.drink
	var drink_texture
	if current_order.sugar:
		drink_texture = load(DRINK_FILE_PATH + drink + "Sugar.png")
	else:
		drink_texture = load(DRINK_FILE_PATH + drink + "Ice.png")
		
	print("drink texture: ", drink_texture)
	print(DRINK_FILE_PATH + drink + "Sugar.png")
	print(DRINK_FILE_PATH + drink + "Ice.png")
	
	$OrderBubble/BubbleSprite.show()
	var speech_bubble_chutney = spawn_icon(drink_texture, SPEECH_BUBBLE_POSITION, SPEECH_BUBBLE_DRINK_SCALE)
	await wait_or_skip(TIME_INTERVAL)
	ticket_icons.pop_back()
	
	spawn_icon(drink_texture, ticket_position, BIG_TICKET_DRINK_SCALE)
	await wait_or_skip(TIME_INTERVAL)
	
	speech_bubble_chutney.queue_free()
	$OrderBubble/BubbleSprite.hide()
	await wait_or_skip(TIME_INTERVAL)
	
	ticket_position.y -= SPACE_BETWEEN_ICONS_ON_BIG_TICKET

func on_animation_complete():
	while len(ticket_icons) > 0:
		var icon = ticket_icons.pop_front()
		icon.queue_free()
	print("Order animation finished!")
	customer_order_sprite.hide()
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
