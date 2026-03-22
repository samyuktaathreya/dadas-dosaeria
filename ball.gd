extends Sprite2D

const END_OF_BAR = 736.0
var direction = "right"
const BALL_SPEED = 1000.0
var ball_rolling = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	roll_ball(delta)
	
func roll_ball(delta):
	if position.x > END_OF_BAR:
		direction = "left"
	if position.x < 0:
		direction = "right"
		
	if direction == "right":
		position.x += delta * BALL_SPEED
	else:
		position.x -= delta * BALL_SPEED
		
