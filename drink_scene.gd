extends Node2D

@export var cup_scene: PackedScene

const CANVAS_SIZE = Vector2(1920,1080)
const DOSAPILE_POSITION = Vector2(246.0, 665.0)
var cup_spawned = false
var dragged_object = null
var dragging = false
var mouse_on_banana_leaf = false
var cup_on_leaf = false
var cup_count = 0
const MAX_CUPS = 3
const CUP_DISTANCE = 200.0 # distance between cups
var cups = [] # array of cups spawned
var drink_is_pouring = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show_drinks()
	$TooManyCupsWarning.hide()
	$CantPourNowWarning.hide()
	for child in get_children():
		if child is BananaLeaf:
			child.mouse_entered.connect(_on_banana_leaf_mouse_entered)
			child.mouse_exited.connect(_on_banana_leaf_mouse_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event):
	# Drag in progress
	if event is InputEventMouseMotion:
		if dragging and dragged_object:
			_drag(dragged_object)

	# Start drag on click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if dragged_object:
			dragging = true

	# End drag on release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging and dragged_object:
			_drop(dragged_object)
		dragging = false

func _on_chutney_scene_banana_leaf_updated() -> void:
	var starting_z_index = $BananaLeaf.z_index + 5
	for item in CookingState.pending_items:
		var global_pos = item.global_position
		var prev_parent = item.get_parent()
		if prev_parent:
			prev_parent.remove_child(item)
		$BananaLeaf.add_child(item)
		item.z_index = starting_z_index + 1
		starting_z_index += 1
		item.global_position = global_pos
		CookingState.banana_leaf_items.append(item)
	CookingState.pending_items.clear()

func show_drinks():
	$DrinkDispenser/EmptyDrinkDispenser/DrinkCollection.show()
	$DrinkDispenser/EmptyDrinkDispenser/SugarIceCollection.hide()

func show_sugar_and_ice():
	print("show sugar and ice called")
	$DrinkDispenser/EmptyDrinkDispenser/SugarIceCollection.show()
	$DrinkDispenser/EmptyDrinkDispenser/DrinkCollection.hide()

func _on_mango_lassi_pressed() -> void:
	drink_requested("MangoLassi")
	

func _on_filter_coffee_pressed() -> void:
	drink_requested("FilterCoffee")
	
func cant_pour_now_error():
	$CantPourNowWarning.show()
	$CantPourNowTimer.start()
	
func drink_requested(drink_name):
	if drink_is_pouring:
		cant_pour_now_error()
		return
		
	var cup = spawn_cup()
	cup.set_meta("drink_name", drink_name)
	
	if cup == null: return

	# animate the drink pouring in cup
	drink_is_pouring = true
	var CupSprite = cup.get_node("CupSprite")
	CupSprite.play(drink_name)
	await CupSprite.animation_finished
	drink_is_pouring = false
	CupSprite.play("idle")

	# switch drink dispenser to show sugar/ice
	show_sugar_and_ice()
	
func spawn_cup():
	# if there are too many cups, do not spawn cup
	if len(cups) >= MAX_CUPS: 
		spawn_cup_error()
		return
	
	# create customer child node
	var cup = cup_scene.instantiate()
	$BananaLeaf.add_child(cup)
	cup.global_position = $DrinkDispenser/CupSpawnPoint.global_position
	# detect when katori is clicked on and dragged
	cup.mouse_entered.connect(_on_cup_mouse_entered.bind(cup))
	cup.mouse_exited.connect(_on_cup_mouse_exited.bind(cup))
	
	# shift all the cups to the right
	shift_cups_right()
	
	# return cup
	cup_spawned = true
	for iterated_cup in cups:
		iterated_cup.index += 1
	cup.index = 0
	cups.push_front(cup)
	return cup

func shift_cups_right():
	# for each cup in the cup array
	# move its position to the right by CUP_DISTANCE
	for cup in cups:
		cup.position.x += CUP_DISTANCE

func shift_cups_left(index):
	for cup in cups.slice(index):
		cup.position.x -= CUP_DISTANCE
	
func _on_cup_mouse_entered(cup):
	if visible:
		# make sure the cup is eligible for dragging
		if cup.can_be_dragged and not dragging:
			dragged_object = cup
		print("cup info: ")
		print("cup can be dragged ", cup.can_be_dragged)
		print("cup index: ", cup.index)

func _on_cup_mouse_exited(cup):
	if not dragging and dragged_object == cup:
		dragged_object = null
		
func _drag(obj):
	obj.global_position = get_global_mouse_position()

func _drop(obj):
	# for each node, we need to check if it reached the position successfully
	# if it didn't, it must return to the original position
	if obj is Cup:
		if mouse_on_banana_leaf:
			cup_spawned = false
			cup_on_leaf = true 
			obj.can_be_dragged = false
			# pop cup from the cups array
			drag_cup_to_banana_leaf(obj)
			CookingState.banana_leaf_items.append(obj)
			# reset drink dispenser
			show_drinks()
		else:
			# return cup to below the dispenser
			obj.global_position = $DrinkDispenser/CupSpawnPoint.global_position
	dragged_object = null

func _on_banana_leaf_mouse_entered() -> void:
	if visible:
		mouse_on_banana_leaf = true

func _on_banana_leaf_mouse_exited() -> void:
	mouse_on_banana_leaf = false

func spawn_cup_error():
	# TODO: if there are too many cups, show the player a warning
	# when the player tries to spawn more cups 
	$TooManyCupsWarning.show()
	$TooManyCupsWarningTimer.start()

func _on_button_for_minigame_pressed() -> void:
	# when the button for minigame is pressed
	# it means sugar/ice has been dispensed into the current cup
	# current cup = cups[0]
	print("on button for minigame pressed called")
	cups[0].can_be_dragged = true
	
func drag_cup_to_banana_leaf(cup):
	var cup_index = cup.index
	print("cup index: ", cup_index)
	
	# remove cup from cups array
	cups.remove_at(cup_index)
	
	# shift every cup after it to the left
	shift_cups_left(cup_index)

func _on_too_many_cups_warning_timer_timeout() -> void:
	$TooManyCupsWarning.hide()

func _on_cant_pour_now_timer_timeout() -> void:
	$CantPourNowWarning.hide()
