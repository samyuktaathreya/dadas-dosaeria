extends RigidBody2D

func _ready():
	self.mass = 0.1 #light, like a fluid
	self.gravity_scale = 1.0 #full gravity
	self.linear_damp = 0.5 #some air resistance
	
	

	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	pass
