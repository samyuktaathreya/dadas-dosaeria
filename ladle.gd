extends Sprite2D

const HOME_POSITION=Vector2(11.0,-59.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#node.signal_name.connect(function_to_call)
	#get_parent().dough_bucket_clicked.connect(_on_dough_bucket_dough_bucket_clicked)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if CookingState.drag_ladle:
		self.global_position = get_global_mouse_position()
	
func _input(event):
	pass

func _on_tawa_controller_return_ladle() -> void:
	CookingState.drag_ladle = false
	CookingState.drag_cooldown = true
	get_parent().get_node("LadleCooldown").start()
	var tween = create_tween()
	tween.tween_property(self, "position", HOME_POSITION, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_tawa_controller_drag_ladle_signal() -> void:
	if not CookingState.drag_cooldown: 
		CookingState.drag_ladle = true

func _on_ladle_cooldown_timeout() -> void:
	CookingState.drag_cooldown = false
