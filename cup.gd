extends Area2D

class_name Cup

const CUP_OFFSET = 688.0
var can_be_dragged = false
var index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x += CUP_OFFSET


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
