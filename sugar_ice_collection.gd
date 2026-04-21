extends Control

var minigame_activated = "" # equals sugar or ice 
const IDEAL_BALL_POSITION_X = -138.0

signal received_ball_score

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
	# 1. SAFETY CHECK: Ignore the click if the minigame is already resetting
	if minigame_activated == "":
		return
		
	# 2. HIDE IMMEDIATELY: Prevent the player from clicking it again
	$ButtonForMinigame.hide()

	var cup_under_dispenser = get_parent().get_parent().get_parent().cups[0]
	cup_under_dispenser.set_meta("sugar_or_ice", minigame_activated)
	
	# get ball x position
	var ball_x_pos = $Ball.position.x
	
	var raw_error = abs((abs(IDEAL_BALL_POSITION_X - ball_x_pos) / IDEAL_BALL_POSITION_X) * 100)
	var score = clamp(100.0 - raw_error, 0.0, 100.0)  # now higher = better, capped at 100
	cup_under_dispenser.set_meta("sugar_or_ice_score", score)
	
	var label 
	if score > 90:
		label = "excellent!"
	elif score > 60:
		label = "nice!"
	elif score > 30:
		label = "meh"
	else:
		label = "bad"
		
	received_ball_score.emit(score)
	print(cup_under_dispenser.get_meta("sugar_or_ice_score"))
	
	$SugarIceEncouragement.text = label
	$SugarIceEncouragement.show()
	$SugarIceEncouragementTimer.start()
	
	if minigame_activated == "sugar":
		cup_under_dispenser.get_node("SugarOverlay").show()
	elif minigame_activated == "ice":
		cup_under_dispenser.get_node("IceOverlay").show()
	else:
		assert(1 == 2) # This is safe to leave now, as the code above prevents it!
	# reset minigame
	minigame_activated = ""


func _on_sugar_ice_encouragement_timer_timeout() -> void:
	$SugarIceEncouragement.hide()
	# hide bar and ball
	$Bar.hide()
	$Ball.hide()
	$ButtonForMinigame.hide()
	$SugarButton.show()
	$IceButton.show()
	var drink_scene = get_parent().get_parent().get_parent()
	drink_scene.show_drinks()
