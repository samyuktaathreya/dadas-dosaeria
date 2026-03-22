extends Control

var minigame_activated = "" # equals sugar or ice 
const IDEAL_BALL_POSITION_X = 324.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Bar.hide()
	$Ball.hide()
	$ButtonForMinigame.hide()
	$SugarIceEncouragement.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_sugar_button_pressed() -> void:
	button_pressed("sugar")

func _on_ice_button_pressed() -> void:
	button_pressed("ice")
	
func button_pressed(button_name):
	# hide buttons
	$SugarButton.hide()
	$IceButton.hide()
	# show the bar and ball minigame
	$Bar.show()
	$Ball.show()
	$ButtonForMinigame.show()
	$SugarIceEncouragement.hide()
	minigame_activated = button_name

func _on_button_for_minigame_pressed() -> void:
	# TODO: modify score based on ball
	var cup_under_dispenser = get_parent().get_parent().get_parent().cups[0]
	
	cup_under_dispenser.set_meta("sugar_or_ice", minigame_activated)
	
	# get ball x position
	var ball_x_pos = $Ball.position.x
	
	var score = (abs(IDEAL_BALL_POSITION_X - ball_x_pos) / IDEAL_BALL_POSITION_X) * 100
	cup_under_dispenser.set_meta("sugar_or_ice_score", score)
	
	var label 
	if score < 30: 
		label = "bad"
	elif score < 60:
		label = "meh"
	elif score < 90:
		label = "nice!"
	else:
		label = "excellent!"
	
	$SugarIceEncouragement.text = label
	$SugarIceEncouragement.show()
	$SugarIceEncouragementTimer.start()
	# hide bar and ball
	$Bar.hide()
	$Ball.hide()
	$ButtonForMinigame.hide()
	$SugarButton.show()
	$IceButton.show()
	
	# TODO: trigger animation corresponding to sugar or ice
	
	# reset minigame
	minigame_activated = ""
	
	# hide sugar and ice and show drink collection
	var drink_scene = get_parent().get_parent().get_parent()
	drink_scene.show_drinks()


func _on_sugar_ice_encouragement_timer_timeout() -> void:
	$SugarIceEncouragement.hide()
