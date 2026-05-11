extends Node2D

class_name TawaController

signal return_ladle
signal drag_ladle_signal

var PLACEHOLDER_VECTOR = Vector2(-1,-1)

var click_start_pos = Vector2.ZERO

var mouse_over_pan = false
var flip_cooldown = 0.0

var mouse_on_banana_leaf = false

var onion_on_dosa = false

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

const DOSA_COOKING_SPRITE_OFFSET = Vector2(760, -170) - Vector2(235, -80)

var FOLDED_DOSA_SPRITE_OFFSET
# Vector2(6.0, 38.0)
const FOLDED_DOSA_SPRITE_SCALE = Vector2(0.5, 0.5)

# const DOSA_COOKING_SPRITE_OFFSET = Vector2.ZERO

var DOSA_COOKING_SPRITES_FILE_PATH = "res://assets/DosaCookingSprites/"
var FOLDED_DOSA_SPRITES_FILE_PATH = "res://assets/FoldedDosas/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Flame.play("default")
	
	$Onions.hide()
	var ONION_DOSA_SPRITES_FILE_PATH = "res://assets/OnionDosaCookingSprites/"

	$BatterCanvas.material.set_shader_parameter("dosa_texture_undercooked_onion", load(ONION_DOSA_SPRITES_FILE_PATH + "UndercookedDosa.png"))
	$BatterCanvas.material.set_shader_parameter("dosa_texture_cooked_onion", load(ONION_DOSA_SPRITES_FILE_PATH + "CookedDosa.png"))
	$BatterCanvas.material.set_shader_parameter("dosa_texture_slightly_overcooked_onion", load(ONION_DOSA_SPRITES_FILE_PATH + "SlightlyOvercookedDosa.png"))
	$BatterCanvas.material.set_shader_parameter("dosa_texture_overcooked_onion", load(ONION_DOSA_SPRITES_FILE_PATH + "OvercookedDosa.png"))
	$BatterCanvas.material.set_shader_parameter("onions", false)
	
	$Tawa/CookingProgressUI/ProgressBar.max_value = 2.0
	$BatterCanvas.material = $BatterCanvas.material.duplicate()

	$BatterCanvas.material.set_shader_parameter(
		"dosa_texture_undercooked", 
		load(DOSA_COOKING_SPRITES_FILE_PATH + "UndercookedDosa.png")
	)

	$BatterCanvas.material.set_shader_parameter(
		"dosa_texture_cooked", 
		load(DOSA_COOKING_SPRITES_FILE_PATH + "CookedDosa.png")
	)
	
	$BatterCanvas.material.set_shader_parameter(
		"dosa_texture_slightly_overcooked", 
		load(DOSA_COOKING_SPRITES_FILE_PATH + "SlightlyOvercookedDosa.png")
	)
	
	$BatterCanvas.material.set_shader_parameter(
		"dosa_texture_overcooked", 
		load(DOSA_COOKING_SPRITES_FILE_PATH + "OvercookedDosa.png")
	)
	
	var cooked_tex = load(DOSA_COOKING_SPRITES_FILE_PATH + "CookedDosa.png")
	
	$BatterCanvas.material.set_shader_parameter("canvas_size", CANVAS_SIZE)
	$BatterCanvas.material.set_shader_parameter("sprite_size", cooked_tex.get_size())

	$BatterCanvas.material.set_shader_parameter("cooked_stage", 0.0)

	$Tawa/DoughSpreadingTimer.timeout.connect(_on_dough_spreading_timer_timeout)

	$BatterCanvas.global_position = CANVAS_SIZE / 2  # (960, 540)
	$BatterCanvas.centered = true  # this is default
	DOSA_PAN_COLLISION_CENTER = $Tawa/TawaCenterMarker.global_position
	FOLDED_DOSA_SPRITE_OFFSET = DOSA_PAN_COLLISION_CENTER

	var normalized_offset = (DOSA_COOKING_SPRITE_OFFSET) / CANVAS_SIZE
	$BatterCanvas.material.set_shader_parameter("pan_center", DOSA_PAN_COLLISION_CENTER / CANVAS_SIZE + normalized_offset)

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
	
func trash_dosa():
	reset_tawa()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dosaInPan and mouse_over_pan and CookingState.dragging_onions and not onion_on_dosa:
		drop_onions_on_dosa()
	if submit_dosa and dosa_drag_sprite:
		# var offset = -DOSA_PAN_COLLISION_CENTER
		var offset = Vector2.ZERO
		dosa_drag_sprite.global_position = get_global_mouse_position() + offset
	if flip_cooldown > 0:
		flip_cooldown -= delta
	if mouse_over_pan:
		mouse_pos = get_global_mouse_position()
		
	if CookingState.dragging_dosa == self and CookingState.mouse_on_trash:
		trash_dosa()

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
	if dosaInPan and not dosa_drag_sprite:
		cook_level = clamp(cook_level + COOK_SPEED * delta, 0.0, 2.0)
	last_mouse_pos = mouse_pos
	
	$Tawa/CookingProgressUI/ProgressBar.value = cook_level

	if cook_level < 0.7:
		$Tawa/CookingProgressUI/ProgressBar.modulate = Color.WHITE
	elif cook_level < 1.0:
		$Tawa/CookingProgressUI/ProgressBar.modulate = Color.YELLOW
	elif cook_level < 1.3:
		$Tawa/CookingProgressUI/ProgressBar.modulate = Color.ORANGE
	else:
		$Tawa/CookingProgressUI/ProgressBar.modulate = Color.RED

	$Tawa/CookingProgressUI/FlipLabel.visible = (cook_level >= 1.0)
	
	$Tawa/CookingProgressUI.visible = mouse_over_pan \
	and not CookingState.drag_ladle and flip_cooldown <= 0.0
	
	
func _on_mouse_entered():
	mouse_over_pan = true
	# if cookingstate.dragging_onions and mouse over pan and dosa in pan
	# then drop the onions on the dosa
		
func drop_onions_on_dosa():
	# change sprite texture of dosa
	FOLDED_DOSA_SPRITES_FILE_PATH = "res://assets/OnionFoldedDosas/"
	$BatterCanvas.material.set_shader_parameter("onions", true)
	
	if not onion_on_dosa:
		onion_on_dosa = true
		var visible_cook_level = dosa_cooked_amounts[1 - dosa_cooked_amounts_index]
		$BatterCanvas.material.set_shader_parameter("cook_level", visible_cook_level)

		# pick which sprite to show based on how cooked that side is
		var stage = cook_level_to_stage(visible_cook_level)
		if stage == 0.0:
			$Onions.show()
		else:
			$Onions.hide()
			$BatterCanvas.material.set_shader_parameter("cooked_stage", stage)

func _on_mouse_exited():
	mouse_over_pan = false

func _input(event):
	# 1. HANDLE MOUSE MOVEMENT (DRAGGING)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if click_bucket and not CookingState.drag_ladle:
			drag_ladle_signal.emit()
			
		# Check if they have moved the mouse far enough to count as a "drag" (e.g., 10 pixels)
		if dosaInPan and not CookingState.drag_ladle and mouse_over_pan \
			and CookingState.dragging_dosa == null and click_start_pos.distance_to(event.global_position) > 10.0 \
			and CookingState.dragging_onions == false and CookingState.dragging_ticket == null \
			and flip_cooldown <= 0:
			CookingState.dragging_dosa = self
			start_dragging_dosa()
			
		if mouse_on_banana_leaf and submit_dosa and dosaInPan and not CookingState.drag_ladle:
			get_parent().serve_dosa()
			reset_tawa()
	
	# 2. HANDLE MOUSE PRESS
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Record where the user clicked down
			click_start_pos = event.global_position
			
		# 3. HANDLE MOUSE RELEASE
		elif not event.pressed:
			# If they released the button WITHOUT moving the mouse much, treat it as a FLIP
			if click_start_pos.distance_to(event.global_position) <= 10.0:
				if mouse_over_pan and dosaInPan and not CookingState.drag_ladle and flip_cooldown <= 0:
					flip_dosa()

			# Handle dropping the drag state
			if CookingState.dragging_dosa == self:
				CookingState.dragging_dosa = null
			if not click_bucket and CookingState.drag_ladle and dough_spread_triggered:
				return_ladle.emit()
				dough_spread_triggered = false
				flip_cooldown = 0.5
				CookingState.dragging_ladle = false
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
	if CookingState.drag_ladle and not dosaInPan and not CookingState.dragging_ladle:
		dough_spread_triggered = true
		dosaInPan = true
		$Flame.show()
		CookingState.dragging_ladle = true
		$Tawa/DoughSpreadingTimer.start()

func _on_dough_bucket_mouse_entered() -> void:
	click_bucket = true

func _on_dough_bucket_mouse_exited() -> void:
	click_bucket = false

func flip_dosa():
	if flip_cooldown <= 0:
		flip_cooldown = 0.5
		
		dosa_cooked_amounts[dosa_cooked_amounts_index] = cook_level
		
		# the side now facing UP is the one that was just cooking
		visible_cook_level = cook_level
		$BatterCanvas.material.set_shader_parameter("cook_level", visible_cook_level)
		
		# swap index between 0 and 1
		dosa_cooked_amounts_index = 1 - dosa_cooked_amounts_index
		
		# track cook level of dosa side facing pan
		cook_level = dosa_cooked_amounts[dosa_cooked_amounts_index]

		# pick which sprite to show based on how cooked that side is
		var stage = cook_level_to_stage(visible_cook_level)
		if stage == 0.0 and onion_on_dosa:
			$Onions.show()
		else:
			$Onions.hide()
			
		$BatterCanvas.material.set_shader_parameter("cooked_stage", stage)

func cook_level_to_stage(level: float) -> float:
	if level < 0.4:
		return 0.0
	if level < 1.0:
		return 1.0
	elif level < 1.5:
		return 2.0
	elif level < 1.9:
		return 3.0
	else: 
		return 4.0

func start_dragging_dosa():
	if not submit_dosa: 
		submit_dosa = true
		dosa_drag_sprite = Sprite2D.new()
		dosa_drag_sprite.set_meta("item_type", "dosa")
		dosa_drag_sprite.set_meta("onion", onion_on_dosa)
		# snapshot the current canvas as the drag visual
		'''
		old code: 
		# dosa_drag_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# var drag_texture = ImageTexture.create_from_image(canvas_image)
		# dosa_drag_sprite.texture = drag_texture
		# dosa_drag_sprite.offset = DOSA_COOKING_SPRITE_OFFSET
		# dosa_drag_sprite.scale = Vector2(1.0, 1.0)  # scale it down to dosa size
		
		now switching to folded dosa sprite when dragging dosa
		'''
		# when dragging dosa, switch to a folded dosa sprite
		
		var cooked_dict = {
			0.0: "UndercookedDosa",
			1.0: "UndercookedDosa",
			2.0: "CookedDosa",
			3.0: "SlightlyOvercookedDosa",
			4.0: "OvercookedDosa"
		}
		
		var cooked_amount = cooked_dict[cook_level_to_stage(cook_level)]
		
		# choose texture based on cooked amount
		var folded_texture = load(
			FOLDED_DOSA_SPRITES_FILE_PATH + cooked_amount + ".png"
		)
		
		
		dosa_drag_sprite.texture = folded_texture
		dosa_drag_sprite.visible = true
		# dosa_drag_sprite.offset = FOLDED_DOSA_SPRITE_OFFSET
		dosa_drag_sprite.scale = FOLDED_DOSA_SPRITE_SCALE
		
		dosa_drag_sprite.centered = true
		# dosa_drag_sprite.material = $BatterCanvas.material.duplicate()
		# dosa_drag_sprite.material.set_shader_parameter("pan_center", Vector2(0.5, 0.5))
		# get score of dosa
		var scores = calculate_dosa_score()
		dosa_drag_sprite.set_meta("cook_score", scores.cook_score)
		dosa_drag_sprite.set_meta("shape_score", scores.shape_score)
		dosa_drag_sprite.set_meta("total_score", scores.total)
		
		var normalized_offset = (DOSA_COOKING_SPRITE_OFFSET) / CANVAS_SIZE
		dosa_drag_sprite.set_meta("pan_center", DOSA_PAN_COLLISION_CENTER / CANVAS_SIZE + normalized_offset)
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
	$Onions.hide()
	onion_on_dosa = false
	$BatterCanvas.material.set_shader_parameter("onions", false)
	FOLDED_DOSA_SPRITES_FILE_PATH = "res://assets/FoldedDosas/"
	mouse_over_pan = false
	flip_cooldown = 0.0

	mouse_on_banana_leaf = false

	submit_dosa = false
	last_pos = PLACEHOLDER_VECTOR

	click_bucket = false

	dosaInPan = false
	$Flame.hide()

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
	$Flame.hide()
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
	$BatterCanvas.material.set_shader_parameter("cooked_stage", 0.0)
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

	return {
		"cook_score": cook_score,
		"shape_score": shape_score,
		"total": (cook_score + shape_score) / 2.0
	}
	
func dosa_submitted():
	cook_level = 0.0
