extends Node2D
const TIME_INTERVAL = 1.0

signal submit_scene_finished

var customer

const T_MIN = 120.0
const T_MAX = 420.0

func _ready() -> void:
	# hide all score labels initially
	$ScoreLabels/OrderScore.hide()
	$ScoreLabels/CookingScore.hide()
	$ScoreLabels/ChutneyScore.hide()
	$ScoreLabels/DrinkScore.hide()
	$ScoreLabels/TotalScore.hide()
	$Tip.hide()

func _process(delta: float) -> void:
	pass
	
func play_submit_animation():
	var CustomerData = CookingState.customer_of_submitted_order
	
	# fake scores for now
	var order_score = calculateOrderScore()
	var cooking_score = calculate_cooking_score()
	var chutney_score = 100
	var drink_score = 100
	var total_score = (order_score + cooking_score + chutney_score + drink_score) / 4

	# Fade in from black
	var tween = create_tween()
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	await tween.finished

	# show each score with a pause between each
	await show_label_animated($ScoreLabels/OrderScore, str(order_score))
	await show_label_animated($ScoreLabels/CookingScore, str(cooking_score))
	await show_label_animated($ScoreLabels/ChutneyScore, str(chutney_score))
	await show_label_animated($ScoreLabels/DrinkScore, str(drink_score))

	# total score
	await show_label_animated($ScoreLabels/TotalScore, str(total_score))

	# tip
	await show_label_animated($Tip, str(total_score * 0.01 * 5))

	CookingState.customer_of_submitted_order = null
	
	submit_scene_finished.emit()

func show_label_animated(label: Node, text: String) -> void:
	label.text = text
	label.modulate.a = 0.0
	label.show()

	# fade in
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.4)
	await tween.finished

	# pause before next label
	await get_tree().create_timer(TIME_INTERVAL).timeout
	
func calculateOrderScore():
	# check how long the player took to get the customer's order
	var elapsed_time = Time.get_ticks_msec() - customer.order_start_time
	var elapsed_time_seconds = elapsed_time / 1000
	if (elapsed_time_seconds < 2):
		return 100

	var normalized = (T_MAX - elapsed_time_seconds) / (T_MAX - T_MIN)
	normalized = clamp(normalized, 0.0, 1.0)

	return normalized * 100.0
	
func calculate_cooking_score():
	var banana_leaf_items = CookingState.banana_leaf_items
	var dosas = banana_leaf_items.filter(
		func(item): return item.has_meta("item_type") and item.get_meta("item_type") == "dosa"
	)

	var submitted_count = dosas.size()
	var expected_count  = customer.customer_data.order["dosa_count"]

	# Count penalty: deduct proportionally for wrong number
	var count_ratio = 0.0
	if expected_count > 0:
		# e.g. asked for 2, gave 1 → 0.5 ratio; gave 3 → capped at 1.0
		count_ratio = clamp(float(submitted_count) / float(expected_count), 0.0, 1.0)

	# Average the cook quality across submitted dosas
	var avg_dosa_quality = 0.0
	for dosa in dosas:
		avg_dosa_quality += dosa.get_meta("total_score")  # already 0-100
	if submitted_count > 0:
		avg_dosa_quality /= submitted_count

	# Final dosa score: quality × count accuracy
	# If they gave too many dosas, count_ratio is capped at 1.0 (no bonus)
	return avg_dosa_quality * count_ratio
	
func calculate_chutney_score():
	pass
