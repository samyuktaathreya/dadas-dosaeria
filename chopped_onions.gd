extends Area2D

var mouse_over_onions = false

var CHOPPED_ONION_TEXTURE
const CHOPPED_ONION_SCALE = Vector2(0.1,0.1)
var onion_sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CHOPPED_ONION_TEXTURE = load("res://chopped_onions.webp")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if onion_sprite:
		onion_sprite.global_position = get_global_mouse_position()
	pass
	
func spawn_onion():
	# spawn onion to follow the mouse around
	# to give the illusion of holding onions
	var onion = Sprite2D.new()
	onion.texture = CHOPPED_ONION_TEXTURE
	onion.scale = CHOPPED_ONION_SCALE
	add_child(onion)
	onion_sprite = onion
	
func _input(event):
	# change the value of CookingState.dragging_onions
	
	# 1. HANDLE MOUSE MOVEMENT (DRAGGING)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if mouse_over_onions and CookingState.drag_ladle == false \
			and CookingState.dragging_dosa == null:
			# make sure the mouse isn't currently dragging anything else
			CookingState.dragging_onions = true
			if onion_sprite == null:
				spawn_onion()
			
	# 2. HANDLE MOUSE PRESS
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pass
		# 3. HANDLE MOUSE RELEASE
		elif not event.pressed:
			if CookingState.dragging_onions:
				CookingState.dragging_onions = false
				onion_sprite.queue_free()
				onion_sprite = null

func _on_mouse_entered() -> void:
	mouse_over_onions = true

func _on_mouse_exited() -> void:
	mouse_over_onions = false
