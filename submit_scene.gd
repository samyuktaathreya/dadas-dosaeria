extends Node2D
const TIME_INTERVAL = 1.0

signal submit_scene_finished

var customer

const T_MIN = 10.0
const T_MAX = 120.0

var SCORE_LABELS_PATH

func _ready() -> void:
	SCORE_LABELS_PATH = get_parent().get_node("UI").get_node("ScoreLabels")
	
	# increase font sizes
	for child in get_parent().get_node("UI").get_node("ScoreLabels").get_children():
		child.add_theme_font_size_override("font_size", 32)
		child.hide()
	$Tip.add_theme_font_size_override("font_size", 32)
	$Tip.hide()

func hide_score_labels():
	for child in get_parent().get_node("UI").get_node("ScoreLabels").get_children():
		child.add_theme_font_size_override("font_size", 32)
		child.hide()
		
func _process(delta: float) -> void:
	pass
	
func play_submit_animation():
	var CustomerData = CookingState.customer_of_submitted_order
	
	# fake scores for now
	var order_score = calculateOrderScore()
	var cooking_score = calculate_cooking_score()
	var chutney_score = calculate_chutney_score()
	var drink_score = 100
	var total_score = (order_score + cooking_score + chutney_score + drink_score) / 4

	# Fade in from black
	var tween = create_tween()
	tween.tween_property($BlackOverlay, "modulate:a", 0.0, TIME_INTERVAL)
	await tween.finished

	# show each score with a pause between each
	await show_label_animated(SCORE_LABELS_PATH.get_node("OrderScore"), str(order_score))
	await show_label_animated(SCORE_LABELS_PATH.get_node("CookingScore"), str(cooking_score))
	await show_label_animated(SCORE_LABELS_PATH.get_node("ChutneyScore"), str(chutney_score))
	await show_label_animated(SCORE_LABELS_PATH.get_node("DrinkScore"), str(drink_score))

	# total score
	await show_label_animated(SCORE_LABELS_PATH.get_node("TotalScore"), str(total_score))

	# tip
	await show_label_animated($Tip, str(total_score * 0.01 * 5))
	
	# hide the scores when they are done being shown
	hide_score_labels()
	$Tip.hide()

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
	print(banana_leaf_items)
	var dosas = banana_leaf_items.filter(
		func(item): return item.has_meta("item_type") and item.get_meta("item_type") == "dosa"
	)

	var submitted_count = dosas.size()
	print("submitted count : ", submitted_count)
	var expected_count  = len(customer.data.order.dosa)
	print("expected count : ", expected_count)

	# Count penalty: deduct proportionally for wrong number
	var count_ratio = 0.0
	if expected_count > 0:
		# e.g. asked for 2, gave 1 → 0.5 ratio; gave 3 → capped at 1.0
		count_ratio = clamp(float(submitted_count) / float(expected_count), 0.0, 1.0)

	# Average the cook quality across submitted dosas
	var avg_dosa_quality = 0.0
	for dosa in dosas:
		avg_dosa_quality += dosa.get_meta("total_score")  # already 0-100
		print("average dosa quality : ", avg_dosa_quality)
	if submitted_count > 0:
		avg_dosa_quality /= submitted_count

	# Final dosa score: quality × count accuracy
	# If they gave too many dosas, count_ratio is capped at 1.0 (no bonus)
	print("count ratio ", count_ratio)
	return avg_dosa_quality * count_ratio
	
func calculate_chutney_score():
	print("--- CALCULATE CHUTNEY SCORE DEBUG ---")
	var expected_order = customer.data.order
	var expected_chutneys = expected_order.get("chutney", [])
	
	# Get submitted chutneys from banana leaf
	var banana_leaf_items = CookingState.banana_leaf_items
	var submitted_chutneys = banana_leaf_items.filter(
		func(item): return (item is Katori)
	)
	
	print("len submitted chutneys: ", len(submitted_chutneys))
	
	if expected_chutneys.is_empty() and submitted_chutneys.is_empty():
		return 100.0
	
	# Count expected occurrences of each chutney type
	var expected_counts = {}
	for chutney in expected_chutneys:
		expected_counts[chutney] = expected_counts.get(chutney, 0) + 1
	
	# Count submitted occurrences of each chutney type
	var submitted_counts = {}
	for chutney in submitted_chutneys:
		var chutney_type = chutney.get_meta("chutney_type")
		submitted_counts[chutney_type] = submitted_counts.get(chutney_type, 0) + 1
	
	print("expected counts : ", expected_counts)
	print("submitted counts : ", submitted_counts)
	# Score each expected chutney type
	var total_score = 0.0
	for chutney_type in expected_counts:
		var expected = expected_counts[chutney_type]
		var submitted = submitted_counts.get(chutney_type, 0)
		var ratio = clamp(float(submitted) / float(expected), 0.0, 1.0)
		total_score += ratio
		
	print("total score before penalty : ", total_score)
	
	# Penalty for extra wrong chutneys submitted
	for chutney_type in submitted_counts:
		if not expected_counts.has(chutney_type):
			total_score -= 0.5  # tweak this penalty as you see fit
			
	print("total score after penalty : ", total_score)
	
	total_score = clamp(total_score / expected_counts.size(), 0.0, 1.0)
	print("expected counts : ", expected_counts)
	
	return total_score * 100.0
	
func calculate_drink_score():
	var expected_order = customer.data.order
	var expected_drink = expected_order.get("drink", "")
	var wants_sugar = expected_order.get("sugar", false)
	var wants_ice = expected_order.get("ice", false)

	# find cups on the banana leaf
	var banana_leaf_items = CookingState.banana_leaf_items
	var cups = banana_leaf_items.filter(
		func(item): return item is Cup
	)

	# no cup served at all
	if cups.is_empty():
		return 0.0

	# just score the first cup for now
	var cup = cups[0]
	var served_drink = cup.get_meta("drink_name") if cup.has_meta("drink_name") else ""

	# wrong drink type = 0 immediately
	if served_drink != expected_drink:
		return 0.0

	# drink type is correct — now score sugar/ice/ball
	var drink_type_score = 40.0  # base points for correct drink

	# sugar score (30 pts)
	var sugar_score = 0.0
	var served_sugar = cup.has_meta("sugar_or_ice") and cup.get_meta("sugar_or_ice") == "sugar"
	if wants_sugar and served_sugar:
		var ball_score = cup.get_meta("sugar_or_ice_score") if cup.has_meta("sugar_or_ice_score") else 0.0
		sugar_score = (ball_score / 100.0) * 30.0
	elif not wants_sugar and not served_sugar:
		sugar_score = 30.0  # correctly omitted
	elif wants_sugar and not served_sugar:
		sugar_score = 0.0   # forgot sugar
	else:
		sugar_score = 0.0   # added sugar they didn't want

	# ice score (30 pts)
	var ice_score = 0.0
	var served_ice = cup.has_meta("sugar_or_ice") and cup.get_meta("sugar_or_ice") == "ice"
	if wants_ice and served_ice:
		var ball_score = cup.get_meta("sugar_or_ice_score") if cup.has_meta("sugar_or_ice_score") else 0.0
		ice_score = (ball_score / 100.0) * 30.0
	elif not wants_ice and not served_ice:
		ice_score = 30.0
	elif wants_ice and not served_ice:
		ice_score = 0.0
	else:
		ice_score = 0.0

	return drink_type_score + sugar_score + ice_score
