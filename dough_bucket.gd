extends Area2D
signal doughBucketClicked

var dragging_mouse = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event):
	# drag mouse
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		pass
		
	# click mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pass
		
	# stop hovering mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# if ladle being dragged and click on bucket
		# return ladle
		if CookingState.drag_ladle:
			$Ladle._on_tawa_controller_return_ladle()
