extends Node2D

signal order_scene

@export var banana_leaf: PackedScene

var totalTickets = 0
const CANVAS_SIZE = Vector2(1920.0,1080.0)
const TICKET_POSITION_Y = 200.0
const TICKET_SPACE = 100 #space between tickets

#the rightmost ticket's x position
const TICKET_START_X = 1773 

var current_scene = "CustomerLineScene"

const NoButtonScenes = ["OrderScene", "SubmitScene", "MenuScene"]

var mouse_on_submit_ticket_area = false
var dragged_ticket = null

var total_score

var dragging = false

const BANANA_LEAF_POSITION_IN_DRINK_SCENE = Vector2(978, 731)

# Called when the node enters the scene tree for the first time.
func _ready():
	$CustomerLineScene.customer_clicked.connect(_on_customer_clicked)
	for child in get_children():
		if child.name != "UI":
			print("child name: ", child.name)
			child.hide()
	showScene("MenuScene")
	$OrderScene.order_complete.connect(_on_order_scene_order_complete)
	
	# connect to mouse_entered signal from $DrinkScene/SubmitTicketHere
	var submit_ticket_area = $DrinkScene/SubmitTicketHere
	submit_ticket_area.mouse_entered.connect(_on_submit_ticket_area_mouse_entered)
	submit_ticket_area.mouse_exited.connect(_on_submit_ticket_area_mouse_exited)
	
	$UI.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.

func _on_customer_clicked(customer):
	showScene("OrderScene")
	order_scene.emit(customer)
	$OrderScene.show_order(customer)
	totalTickets += 1

func _input(event):
	# if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
	#	dragging = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging:
			dragging = false
			if dragged_ticket != null:
				# Manually check if mouse is over the submit area
				var submit_area = $DrinkScene/SubmitTicketHere
				if $DrinkScene.visible and _is_mouse_over_control(submit_area):
					CookingState.customer_of_submitted_order = dragged_ticket.customer_of_ticket
					dragged_ticket.hide()
					showScene("SubmitScene")
					$SubmitScene.customer = dragged_ticket.customer_of_ticket
					$SubmitScene.play_submit_animation()
					
					# delete ticket once order submitted
					dragged_ticket.queue_free()
			dragged_ticket = null
# Helper: checks if the mouse is within a Control node's rect
func _is_mouse_over_control(area: Area2D) -> bool:
	var mouse_pos = to_local(get_viewport().get_mouse_position())
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results = space_state.intersect_point(query)
	for result in results:
		if result.collider == area:
			return true
	return false
	
func _on_order_scene_order_complete(customer) -> void:
	# find the position that the ticket should shrink to
	var raw_x = TICKET_START_X - (TICKET_SPACE * (totalTickets - 1))
	var ticket_position_x = posmod(raw_x, int(CANVAS_SIZE[0]))
	var ticket_position = Vector2(ticket_position_x, TICKET_POSITION_Y)
	
	# tell the order scene to move the ticket there
	$OrderScene.update_ticket(ticket_position)
	$CustomerLineScene._on_order_scene_order_complete()
	
	# spawn a ticket on the UI scene
	var new_ticket = $UI._on_main_create_ui_ticket(ticket_position, customer)
	
	# connect to ticket signal to know when it's being dragged
	# ticket_being_dragged.emit(self)
	new_ticket.ticket_being_dragged.connect(_on_ticket_being_dragged)
	
	totalTickets += 1
	
	showScene("CustomerLineScene")
	
func add_new_banana_leaf_to_drink_scene():
	var new_banana_leaf = banana_leaf.instantiate()

	new_banana_leaf.position = BANANA_LEAF_POSITION_IN_DRINK_SCENE
	new_banana_leaf.z_index = 0
	$DrinkScene.add_child(new_banana_leaf)
	$DrinkScene.connect_signals_to_new_banana_leaf(new_banana_leaf)

func reset_game():
		# reset all values from previous game
		# update total score
		total_score = 0
		update_total_score(0)
		# remove customers from previous game
		for node in $CustomerLineScene.get_children():
			if node in $CustomerLineScene.customerArray:
				node.queue_free()
		
		# remove tickets from previous game
		for node in $UI.get_children():
			if node is Ticket:
				node.queue_free()
				
		# remove dosas
		for obj in $CookingScene.get_children():
			if obj is TawaController:
				obj.reset_tawa()
				
		for obj in $ChutneyScene/DosaPile.get_children():
			if obj is not Area2D:
				obj.queue_free()
				
		# remove chutneys
		for obj in $ChutneyScene.get_children():
			if obj is Katori:
				obj.queue_free()
				
		for obj in $ChutneyScene/DosaPile.get_children():
			if obj in CookingState.banana_leaf_items:
				obj.queue_free()

		# remove cups
		for obj in $DrinkScene/BananaLeaf.get_children():
			if obj in CookingState.banana_leaf_items:
				obj.queue_free()
				
				
		CookingState.reset()
		
func showScene(scene):
	if scene == "MenuScene":
		reset_game()
		pass
		
	if current_scene == "SubmitScene":
		for child in $UI.get_children():
			if child is Ticket:
				child.show()
		$UI/TicketHolder.show()
		# $SubmitScene/BananaLeaf.show()
		$DrinkScene.global_banana_leaf.show()

		# re-add a new banana leaf to the drink scene
		# since the old one gets deleted
		add_new_banana_leaf_to_drink_scene()
			
	if scene == "SubmitScene":
		# hide the ticket bar at the top
		for child in $UI.get_children():
			if child is Ticket:
				child.hide()
		$UI/TicketHolder.hide()
		
		# transfer banana leaf items from drink scene
		# to the drink scene
		var banana_leaf = $DrinkScene.global_banana_leaf
		for child in banana_leaf.get_children():
			var saved_global_pos = child.global_position
			banana_leaf.remove_child(child)
			$SubmitScene/BananaLeaf.add_child(child)
			child.global_position = saved_global_pos

	# hide buttons during order scene
	if scene == "OrderScene":
		for child in $UI.get_children():
			if child.name.ends_with("Button"):
				child.hide()
				
			if child is Ticket:
				child.order_scene_called()
				
	# if previous scene was order scene, then show buttons
	else:
		for child in $UI.get_children():
			if child.name.ends_with("Button"):
				child.show()

	get_node(current_scene).hide()
	get_node(scene).show()
	current_scene = scene

func _on_ui_cooking_button_pressed() -> void:
	if current_scene not in NoButtonScenes:
		showScene("CookingScene")

func _on_ui_chutney_button_pressed() -> void:
	if current_scene not in NoButtonScenes:
		showScene("ChutneyScene")

func _on_ui_drink_button_pressed() -> void:
	if current_scene not in NoButtonScenes:
		showScene("DrinkScene")

func _on_ui_order_button_pressed() -> void:
	if current_scene not in NoButtonScenes:
		showScene("CustomerLineScene")
	if current_scene != "OrderScene" and current_scene != "SubmitScene":
		showScene("CustomerLineScene")

func _on_chutney_scene_banana_leaf_updated() -> void:
	showScene("DrinkScene")
	# showScene("DrinkScene")

func _on_submit_ticket_area_mouse_entered():
	if $DrinkScene.visible:
		mouse_on_submit_ticket_area = true
	
func _on_submit_ticket_area_mouse_exited():
	mouse_on_submit_ticket_area = false
	
func _on_ticket_being_dragged(ticket):
	if ticket.is_dragging:
		dragged_ticket = ticket

func _on_submit_scene_submit_scene_finished() -> void:
	for child in $SubmitScene/BananaLeaf.get_children():
		if child in CookingState.banana_leaf_items:
			child.queue_free()
	CookingState.clear_on_submit()
	showScene("CustomerLineScene")

func _on_button_pressed() -> void:
	$CustomerLineScene/CustomerSpawner.start()
	$MenuScene/GameTimer.start()
	showScene("CustomerLineScene")

func _on_game_timer_timeout() -> void:
	showScene("MenuScene")
	$MenuScene/TotalScore.show()
	
func update_total_score(new_score):
	total_score += new_score
	$UI/TotalScoreLabel.text = "Total Score: " + str(total_score)
	
