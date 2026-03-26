extends Node2D

class_name TawaController

signal return_ladle
signal drag_ladle_signal

var PLACEHOLDER_VECTOR = Vector2(-1,-1)

var mouse_over_pan = false
var flip_cooldown = 0.0

var mouse_on_banana_leaf = false

var submit_dosa = false

var canvas_image: Image
var canvas_texture: ImageTexture
var brush_tip: Image
var last_pos: Vector2 = PLACEHOLDER_VECTOR

var click_bucket = false

var dosaInPan = false

var dosa_drag_sprite: Sprite2D

const CANVAS_SIZE = Vector2(1920, 1080)
const BRUSH_SIZE = 64
const SPRING_TUNING = 0.001
const BATTER_DAMPING = 0.85

var force_constant = 40

var visible_cook_level = 0.0

var mouse_pos = PLACEHOLDER_VECTOR
var last_mouse_pos = PLACEHOLDER_VECTOR
var batter_pos = PLACEHOLDER_VECTOR
var last_batter_pos = PLACEHOLDER_VECTOR

var tawa_dev = false

var batter_velocity = Vector2.ZERO

const MAX_SPEED = 1000

var dough_spread_triggered = tawa_dev

var DOSA_PAN_COLLISION_CENTER
const PAN_RADIUS = 120.0

var brush_tips

var cook_level = 0.0
const COOK_SPEED = 0.05

var dosa_cooked_amounts = [0,0] # two indices for the two sides of the dosa
var dosa_cooked_amounts_index = 0 # index changes when the dosa is flipped

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dosa_tex = load("res://assets/dosatexture.png")
	$BatterCanvas.material = $BatterCanvas.material.duplicate()
	$BatterCanvas.material.set_shader_parameter("dosa_texture", dosa_tex)
	#get_parent().dough_bucket_clicked.connect(_on_dough_bucket_dough_bucket_clicked)	
	# connect to $DoughBucket.on_mouse_entered
	
	# get_parent().get_node("DoughBucket").mouse_entered.connect(_on_dough_bucket_mouse_entered)
	# get_parent().get_node("DoughBucket").mouse_exited.connect(_on_dough_bucket_mouse_exited)
	$Tawa/DoughSpreadingTimer.timeout.connect(_on_dough_spreading_timer_timeout)

	$BatterCanvas.global_position = CANVAS_SIZE / 2  # (960, 540)
	$BatterCanvas.centered = true  # this is default
	DOSA_PAN_COLLISION_CENTER = $Tawa/TawaCenterMarker.global_position

	$BatterCanvas.material.set_shader_parameter("pan_center", DOSA_PAN_COLLISION_CENTER / CANVAS_SIZE)
	$Tawa/DoughSpreadingTimer.wait_time = 6.0
	
	# create the blank transparent canvas
	canvas_image = Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color(255, 255, 255, 0))

	canvas_texture = ImageTexture.create_from_image(canvas_image)
	$BatterCanvas.texture = canvas_texture
	
	# load your brush tip for dosa dough
	brush_tips = []  # array of brush images at different opacities
	for i in range(5):
		var b = load("res://assets/dosadoughtexture2.png").get_image()
		b.resize(BRUSH_SIZE, BRUSH_SIZE)
		# multiply every pixel's alpha by a fraction
		for py in range(b.get_height()):
			for px in range(b.get_width()):
				var c = b.get_pixel(px, py)
				c.a *= 2.5*(i + 1) / 5.0
				b.set_pixel(px, py, c)
		brush_tips.append(b)

	mouse_pos = DOSA_PAN_COLLISION_CENTER
	batter_pos = DOSA_PAN_COLLISION_CENTER
	last_mouse_pos = mouse_pos
	last_batter_pos = batter_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if submit_dosa and dosa_drag_sprite:
		var offset = Vector2(960, 540) - DOSA_PAN_COLLISION_CENTER
		dosa_drag_sprite.global_position = get_global_mouse_position() + offset
	if flip_cooldown > 0:
		flip_cooldown -= delta
	if mouse_over_pan:
		mouse_pos = get_global_mouse_position()

# case 1: the mouse is clicking down
# case 2: the mouse is not clicking down 
# scratch that lets just have the mouse not have to click down
# when you grab the batter and spread it
# you can only do so for a set amount of time
	if dough_spread_triggered and mouse_over_pan and (CookingState.drag_ladle or tawa_dev):
		if (last_mouse_pos - mouse_pos).length() > 5:
			if force_constant < 80:
				force_constant += 1.0
		if (last_mouse_pos == PLACEHOLDER_VECTOR):
			last_mouse_pos = mouse_pos
			batter_pos = mouse_pos
			last_batter_pos = mouse_pos
			
		var mouse_speed = (mouse_pos - last_mouse_pos).length() / delta
		var spring_strength = 1.0 / (1.0 + mouse_speed * SPRING_TUNING)
		
		var force = (mouse_pos - batter_pos) * spring_strength * force_constant
		batter_velocity += force * delta
		batter_velocity *= BATTER_DAMPING
		batter_pos += batter_velocity * delta
		var batter_speed = batter_velocity.length()
		var speed_normalized = clamp(batter_speed / MAX_SPEED, 0.0, 1.0)
		var brush_index = int((1.0 - speed_normalized) * 4)  # fast = index 0 (thin), slow = index 4 (thick)
		if isInPan(batter_pos):
			stamp_along_path(last_batter_pos, batter_pos, brush_index)
			canvas_texture.update(canvas_image)
			last_batter_pos = batter_pos
	if dosaInPan:
		cook_level = clamp(cook_level + COOK_SPEED * delta, 0.0, 1.0)
	last_mouse_pos = mouse_pos
	$Tawa/CookingProgressUI/ProgressBar.value = cook_level
	$Tawa/CookingProgressUI/FlipLabel.visible = (cook_level >= 1.0)
	
	$Tawa/CookingProgressUI/ProgressBar.visible = mouse_over_pan \
	and not CookingState.drag_ladle and flip_cooldown <= 0.0
	
	
func _on_mouse_entered():
	mouse_over_pan = true

func _on_mouse_exited():
	mouse_over_pan = false

func _input(event):
	# start hovering mouse
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if click_bucket and not CookingState.drag_ladle:
			drag_ladle_signal.emit()
			print("drag ladle signal emitted")
		if dosaInPan and not CookingState.drag_ladle and flip_cooldown <= 0 and mouse_over_pan \
		and CookingState.dragging_dosa == null:
			CookingState.dragging_dosa = self
			start_dragging_dosa()
			
		if mouse_on_banana_leaf and submit_dosa and dosaInPan and not CookingState.drag_ladle:
			get_parent().serve_dosa()
			reset_tawa()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_over_pan and dosaInPan and not CookingState.drag_ladle and flip_cooldown <= 0:
			flip_dosa()
	# stop hovering mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if CookingState.dragging_dosa == self:
			CookingState.dragging_dosa = null
		if not click_bucket and CookingState.drag_ladle and dough_spread_triggered:
			return_ladle.emit()
			dough_spread_triggered = false
			flip_cooldown = 0.5
		elif submit_dosa:
			undrag_dosa()

func stamp_along_path(a: Vector2, b: Vector2, brushIndex: int):
	var dist = a.distance_to(b)
	var steps = max(1, int(dist / 4))  # stamp every 4 pixels
	for i in range(steps + 1):
		# t is the percentage of how far along the line we are
		var t = float(i) / steps
		
		# pos : a 2d vector of the position on the smooth line 
		# that connects point a and b when we are percentage t 
		# through the line
		var pos = a.lerp(b, t)
		
		# brushIndex tells us what opacity brush tip to use
		# based on the mouse speed (calculated in _process function)
		stamp_at(pos, brushIndex)

func stamp_at(pos: Vector2, brushIndex: int):
	var brush_tip = brush_tips[brushIndex]
	
	var x = int(pos.x) - BRUSH_SIZE / 2
	var y = int(pos.y) - BRUSH_SIZE / 2
	
	# blend_rect pastes the brush tip image onto the canvas at this position
	canvas_image.blend_rect(
		brush_tip, 
		Rect2(0, 0, BRUSH_SIZE, BRUSH_SIZE), 
		Vector2i(x, y)
	)

func _on_dough_spreading_timer_timeout() -> void:
	if CookingState.drag_ladle and dough_spread_triggered:
		return_ladle.emit()
		flip_cooldown = 0.5
	dough_spread_triggered = false

func isInPan(position):
	return ((position - DOSA_PAN_COLLISION_CENTER).length() < PAN_RADIUS)

func _on_tawa_mouse_entered() -> void:
	mouse_over_pan = true

func _on_tawa_mouse_exited() -> void:
	mouse_over_pan = false

func _on_tawa_center_mouse_entered() -> void:
	mouse_over_pan = true
	if CookingState.drag_ladle and not dosaInPan:
		dough_spread_triggered = true
		dosaInPan = true
		$Tawa/DoughSpreadingTimer.start()

func _on_dough_bucket_mouse_entered() -> void:
	print("on dough bucket mouse entered signal activated")
	click_bucket = true

func _on_dough_bucket_mouse_exited() -> void:
	click_bucket = false

func flip_dosa():
	dosa_cooked_amounts[dosa_cooked_amounts_index] = cook_level  # save current side
	dosa_cooked_amounts_index = 1 - dosa_cooked_amounts_index    # toggle
	cook_level = dosa_cooked_amounts[dosa_cooked_amounts_index]  # load new side
	
	# show how cooked the bottom was when it gets flipped up
	visible_cook_level = dosa_cooked_amounts[1 - dosa_cooked_amounts_index]
	$BatterCanvas.material.set_shader_parameter("cook_level", visible_cook_level)
	
func start_dragging_dosa():
	if not submit_dosa: 
		submit_dosa = true
		dosa_drag_sprite = Sprite2D.new()
		dosa_drag_sprite.set_meta("item_type", "dosa")
		# snapshot the current canvas as the drag visual
		var drag_texture = ImageTexture.create_from_image(canvas_image)
		dosa_drag_sprite.texture = drag_texture
		dosa_drag_sprite.centered = true
		dosa_drag_sprite.material = $BatterCanvas.material.duplicate()
		# get score of dosa
		var scores = calculate_dosa_score()
		dosa_drag_sprite.set_meta("cook_score", scores.cook_score)
		dosa_drag_sprite.set_meta("shape_score", scores.shape_score)
		dosa_drag_sprite.set_meta("total_score", scores.total)
		dosa_drag_sprite.scale = Vector2(1.0, 1.0)  # scale it down to dosa size
		# make dosa sprite a child of CookingScene
		get_parent().add_child(dosa_drag_sprite)
		# hide the original canvas
		$BatterCanvas.visible = false
func undrag_dosa():
	if submit_dosa:
		submit_dosa = false
		if dosa_drag_sprite:
			dosa_drag_sprite.queue_free()
			dosa_drag_sprite = null
		$BatterCanvas.visible = true
		flip_cooldown = 0.5  # small cooldown so releasing doesn't immediately trigger a flip


func _on_banana_leaf_mouse_entered() -> void:
	mouse_on_banana_leaf = true
	
func reset_tawa():
	mouse_over_pan = false
	flip_cooldown = 0.0

	mouse_on_banana_leaf = false

	submit_dosa = false
	last_pos = PLACEHOLDER_VECTOR

	click_bucket = false

	dosaInPan = false

	force_constant = 40

	visible_cook_level = 0.0

	mouse_pos = DOSA_PAN_COLLISION_CENTER
	batter_pos = DOSA_PAN_COLLISION_CENTER
	last_mouse_pos = mouse_pos
	last_batter_pos = batter_pos
	batter_velocity = Vector2.ZERO

	dough_spread_triggered = tawa_dev

	cook_level = 0.0

	dosa_cooked_amounts = [0,0] # two indices for the two sides of the dosa
	dosa_cooked_amounts_index = 0 # index changes when the dosa is flipped
	submit_dosa = false
	dosaInPan = false
	cook_level = 0.0
	dosa_cooked_amounts = [0, 0]
	dosa_cooked_amounts_index = 0
	visible_cook_level = 0.0
	if dosa_drag_sprite:
		dosa_drag_sprite.queue_free()
		dosa_drag_sprite = null
	canvas_image.fill(Color(0, 0, 0, 0))
	canvas_texture.update(canvas_image)
	$BatterCanvas.visible = true
	$BatterCanvas.material.set_shader_parameter("cook_level", 0.0)
	flip_cooldown = 0.0
	force_constant = 40


func _on_banana_leaf_mouse_exited() -> void:
	mouse_on_banana_leaf = false
	
func calculate_dosa_score() -> Dictionary:
	# COOK SCORE
	var side0 = dosa_cooked_amounts[0]
	var side1 = dosa_cooked_amounts[1]

	# ideal is both sides between 0.7 and 1.0
	var cook_score = 0.0
	for side in [side0, side1]:
		if side >= 0.7 and side <= 1.0:
			cook_score += 50.0  # perfect
		elif side >= 0.4:
			cook_score += 25.0  # undercooked but okay
		else:
			cook_score += 0.0   # raw
	# cook_score is now 0-100

	# SHAPE SCORE
	# count filled pixels and find bounding extents
	var filled_pixels = 0
	var min_x = CANVAS_SIZE.x
	var max_x = 0.0
	var min_y = CANVAS_SIZE.y
	var max_y = 0.0
	var centroid = Vector2.ZERO

	for py in range(int(CANVAS_SIZE.y)):
		for px in range(int(CANVAS_SIZE.x)):
			var pixel = canvas_image.get_pixel(px, py)
			if pixel.a > 0.1:
				filled_pixels += 1
				centroid += Vector2(px, py)
				min_x = min(min_x, px)
				max_x = max(max_x, px)
				min_y = min(min_y, py)
				max_y = max(max_y, py)
	var shape_score = 0.0
	if filled_pixels > 100:
		centroid /= filled_pixels
		# roundness = 4π * area / perimeter²
		# approximate with: how close is the spread to a circle?
		# use pixel count as area, and compare to bounding circle
		var bounding_radius = max((max_x - min_x), (max_y - min_y)) / 2.0
		var bounding_circle_area = PI * bounding_radius * bounding_radius
		var fill_ratio = filled_pixels / bounding_circle_area  # 1.0 = perfect circle

		# also check if centroid is near pan center (well-centered dosa)
		var center_offset = (centroid - DOSA_PAN_COLLISION_CENTER).length()
		var center_score = clamp(1.0 - (center_offset / PAN_RADIUS), 0.0, 1.0)

		shape_score = clamp(fill_ratio, 0.0, 1.0) * 70.0  # up to 70 for roundness
		shape_score += center_score * 30.0                 # up to 30 for centering
	# shape_score is now 0-100

	return {
		"cook_score": cook_score,
		"shape_score": shape_score,
		"total": (cook_score + shape_score) / 2.0
	}
