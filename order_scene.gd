extends Control

signal order_complete 

var current_order = {}
const TIME_INTERVAL = 1.0
var customerOrdered

func _ready():
	for icon in $OrderBubble/FoodIcons.get_children():
		icon.hide()
	for icon in $TicketCinematic/FoodIcons.get_children():
		icon.hide()


func show_order(customer):
	current_order = customer.data.order
	customerOrdered = customer
	$TicketCinematic.position = Vector2(1644, 492)
	$TicketCinematic.scale = Vector2(1.,1.)
	for icon in $OrderBubble/FoodIcons.get_children():
		icon.hide()
	for icon in $TicketCinematic/FoodIcons.get_children():
		icon.hide()
	show()
	play_order_animation()

func play_order_animation():
	var tween = create_tween()
	var time = 0.0
	
	# Fade in from black
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	time += TIME_INTERVAL
	
		
	# Show dosa
	tween.tween_callback(show_food_icon.bind("OrderBubble", current_order.dosa))
	tween.tween_interval(TIME_INTERVAL)  # Wait 0.5s
	time += TIME_INTERVAL
	
	tween.tween_callback(show_food_icon.bind("TicketCinematic", current_order.dosa))
	tween.tween_interval(TIME_INTERVAL)
	time += TIME_INTERVAL
	
	#Hide dosa
	tween.tween_callback(hide_food_icon.bind("OrderBubble", current_order.dosa))
	
	# Show chutney if ordered
	if current_order.chutney != "None":
		tween.tween_callback(show_food_icon.bind("OrderBubble", current_order.chutney))
		tween.tween_interval(TIME_INTERVAL)  # Wait 0.5s
		time += TIME_INTERVAL
		
		tween.tween_callback(show_food_icon.bind("TicketCinematic", current_order.chutney))
		tween.tween_interval(TIME_INTERVAL)
		time += TIME_INTERVAL
		
		#Hide chutney
		tween.tween_callback(hide_food_icon.bind("OrderBubble", current_order.chutney))
	
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

func _on_main_order_scene(customer) -> void:
	show_order(customer)
	
func update_ticket(ticket_position: Vector2) -> void:
	const TICKET_SCALE = 0.3
	const DURATION = 0.4

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property($TicketCinematic, "position", ticket_position, DURATION)
	tween.tween_property($TicketCinematic, "scale", Vector2(TICKET_SCALE, TICKET_SCALE), DURATION)
