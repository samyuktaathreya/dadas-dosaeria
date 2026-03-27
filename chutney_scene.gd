extends Node2D

@export var katori_scene: PackedScene

signal banana_leaf_updated

const CANVAS_SIZE = Vector2(1920,1080)
var mouse_on_dosa_pile = false
var dosa_pile = []
var dosa_pile_positions = []
var dragging_dosa = false
var mouse_on_banana_leaf = false
var mouse_on_katori = false

var dragged_object = null
var dragged_object_original_position = null
var dragging = false

# var dosa_on_banana_leaf = false

var mouse_on_container = null

const KATORI_FILE_PATH = "res://assets/Chutneys/"
const KATORI_SCALE = Vector2(1.0, 0.9)

var z_index_on_banana_leaf = 10

const DOSA_COOKING_SPRITE_OFFSET = Vector2(760, -170) - Vector2(235, -80)


var container_to_katori_texture_dict = {
	"SambarContainer": KATORI_FILE_PATH + "Sambar.png",
	"CoconutChutneyContainer": KATORI_FILE_PATH + "CoconutChutney.png",
	"MintChutneyContainer": KATORI_FILE_PATH + "MintChutney.png"
}

var container_to_katori_name_dict = {
	"SambarContainer": "Sambar",
	"CoconutChutneyContainer": "CoconutChutney",
	"MintChutneyContainer": "MintChutney"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_katori()
	
	for child in $SambarChutneyContainer.get_children():
		child.mouse_entered.connect(_on_container_mouse_entered.bind(child))
		child.mouse_exited.connect(_on_container_mouse_exited.bind(child))
		
	$ContinueButton/WarningLabel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event):
	# start hovering mouse
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if dragged_object and dragging:
			_drag(dragged_object)
			if mouse_on_container and dragged_object is Katori:
				fill_katori(dragged_object)
	
	# click mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if dragged_object:
			dragging = true
			if dragged_object is Katori \
				and dragged_object.empty:
				spawn_katori()

	# stop hovering mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging:
			_drop(dragged_object, dragged_object_original_position)
			dragging = false

func _on_cooking_scene_dosa_submitted() -> void:
	# add dosa to stack
	var s = Sprite2D.new()
	var i = len(CookingState.dosas) - 1
	s.texture = CookingState.dosas[i]
	s.material = CookingState.dosa_materials[i]
	s.set_meta("item_type", "dosa")
	s.set_meta("total_score", CookingState.dosa_scores[i].total_score)
	
	var pan_center_normalized = s.material.get_shader_parameter("pan_center")
	var pan_center = pan_center_normalized * Vector2(1920, 1080)
	s.offset = Vector2(960, 540) - pan_center + DOSA_COOKING_SPRITE_OFFSET
	s.position = Vector2(i * 6, -i * 8) 
	s.z_index = i + 10
	s.visible = true
	$DosaPile.add_child(s)
	dosa_pile.append(s)
	dosa_pile_positions.append(s.global_position)

func _on_banana_leaf_2_mouse_entered() -> void:
	mouse_on_dosa_pile = true
	if dosa_pile.size() > 0:
		change_dragged_object_on_enter("dosa")

func _on_banana_leaf_2_mouse_exited() -> void:
	mouse_on_dosa_pile = false
	change_dragged_object_on_exit("dosa")
	
func _drag(node):
	if node is String and node == "dosa":
		dosa_pile[-1].global_position = get_global_mouse_position()
		dosa_pile[-1].z_index = z_index_on_banana_leaf + 1
	else:
		node.global_position = get_global_mouse_position()
	
func _drop(node, original_position):
	match node:
		"dosa":
			if mouse_on_banana_leaf:
				var dosa = dosa_pile.pop_back()
				z_index_on_banana_leaf += 1
				dosa_pile_positions.pop_back()
				# dosa_on_banana_leaf = true
				CookingState.add_to_banana_leaf_items(dosa)
			else:
				print("dosa pile positions -1 : ", dosa_pile_positions[-1])
				dosa_pile[-1].global_position = dosa_pile_positions[-1]

	if node is Katori:
		# if it lands on the banana leaf, it lands
		if mouse_on_banana_leaf:
			CookingState.add_to_banana_leaf_items(node)
		# otherwise it falls off the screen
		else:
			drop_katori(node)
		
	dragged_object = null
	dragged_object_original_position = null
	
	# THE FIX: If your mouse is still over the pile after dropping, instantly queue up the next dosa!
	if mouse_on_dosa_pile and dosa_pile.size() > 0:
		dragged_object = "dosa"
		

func change_dragged_object_on_enter(node):
	if visible and not dragging:
		# Just assign the node directly, no empty 'pass' logic needed!
		dragged_object = node

func change_dragged_object_on_exit(node):
	if visible:
		if not dragging:
			dragged_object = null

func _on_banana_leaf_mouse_entered() -> void:
	if self.visible:
		mouse_on_banana_leaf = true

func _on_banana_leaf_mouse_exited() -> void:
	mouse_on_banana_leaf = false
	
func spawn_katori():
	#create customer child node
	var katori = katori_scene.instantiate()
	katori.global_position = $KatoriSpawnPoint.global_position
	add_child(katori)
	
	# have the newly spawned katori slide into position
	slide_katori_in(katori)
	
	# detect when katori is clicked on and dragged
	katori.mouse_entered.connect(_on_katori_mouse_entered.bind(katori))
	katori.mouse_exited.connect(_on_katori_mouse_exited.bind(katori))
	
func _on_katori_mouse_entered(katori):
	change_dragged_object_on_enter(katori)

func _on_katori_mouse_exited(katori):
	change_dragged_object_on_exit(katori)
	
func slide_katori_in(katori):
	var tween = create_tween()
	tween.tween_property(katori, "global_position",
		katori.global_position, 0.6)\
		.from(Vector2(CANVAS_SIZE.x + 200, katori.position.y))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
func drop_katori(katori):
	var tween = create_tween()
	tween.tween_property(katori, "global_position",
		Vector2(katori.global_position.x, CANVAS_SIZE.y + 200), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	katori.queue_free()
	
func _on_container_mouse_entered(node):
	mouse_on_container = node
	match node.name:
		"SambarContainer":
			pass
		"CoconutChutneyContainer":
			pass
		"CoconutChutneyContainer":
			pass

func _on_container_mouse_exited(node):
	mouse_on_container = null

func fill_katori(katori):
	if not katori.empty: 
		return
	katori.empty = false
	var katori_sprite = katori.get_node("KatoriSprite")
	katori_sprite.texture = load(container_to_katori_texture_dict[mouse_on_container.name])
	katori_sprite.scale = KATORI_SCALE
	var chutney_type = container_to_katori_name_dict[mouse_on_container.name]
	katori.set_meta("chutney_type", chutney_type)

func _on_continue_button_pressed() -> void:
	# dosa_on_banana_leaf = false
	print("=== CONTINUE PRESSED ===")
	print("order_in_drink_scene: ", CookingState.order_in_drink_scene)
	print("banana_leaf_items: ", CookingState.banana_leaf_items)
	for item in CookingState.banana_leaf_items:
		print("  item: ", item, " | is_instance_valid: ", is_instance_valid(item))
	print("current_scene in main: ")  # you'll need to print this from main somehow
	print("continue button pressed")
	if CookingState.order_in_drink_scene:
		print("order is in drink scene already")
		# there is already an order in the drink scene 
		# so you cannot press continue button
		$ContinueButton/WarningLabel.show()
		$ContinueButton/WarningTimer.start()
	else:
		print("banana leaf updated signal sent")
		CookingState.order_in_drink_scene = true
		banana_leaf_updated.emit()

func _on_warning_timer_timeout() -> void:
	$ContinueButton/WarningLabel.hide()
