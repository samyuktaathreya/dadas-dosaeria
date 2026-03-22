extends Area2D

@export var walk_speed = 200.0
var is_waiting = false
var already_ordered = false
var data = CustomerData.new()
var order_start_time

signal order_requested
signal waiting_customer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("walk")
	#connect signal when customer is clicked on
	input_event.connect(_on_input_event)
	order_start_time = Time.get_ticks_msec()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_waiting && not already_ordered:
		position.x -= walk_speed * delta
		
func stop_and_wait():
	if already_ordered: return
	$AnimatedSprite2D.play("idle")
	is_waiting = true
	waiting_customer.emit(self)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("stop_and_wait"):
		area.stop_and_wait()
		
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and is_waiting:
		order_requested.emit()  # Fire the signal up!
		
func moveCustomerOutOfLine():
	is_waiting = false
	already_ordered = true
	self.position=Vector2(20, 300)
	self.scale=Vector2(0.1,0.1)

func move_forward_in_line():
	if already_ordered: return
	$AnimatedSprite2D.play("walk")
	is_waiting = false

func _on_area_exited(area: Area2D) -> void:
	if area.has_method("move_forward_in_line"):
		area.move_forward_in_line()
