extends Node2D

var canvas_image: Image
var canvas_texture: ImageTexture
var brush_tip: Image
var last_pos: Vector2 = PLACEHOLDER_VECTOR

var drag_ladle = false
var dosaInPan = false

const CANVAS_SIZE = Vector2(1920, 1080)
const BRUSH_SIZE = 64
const SPRING_TUNING = 0.001
const BATTER_DAMPING = 0.85
const PLACEHOLDER_VECTOR = Vector2(-1,-1)

var force_constant = 40

var mouse_over_pan = false
var mouse_pos = PLACEHOLDER_VECTOR
var last_mouse_pos = PLACEHOLDER_VECTOR
var batter_pos = PLACEHOLDER_VECTOR
var last_batter_pos = PLACEHOLDER_VECTOR

var batter_velocity = Vector2.ZERO

const MAX_SPEED = 1000

var dough_spread_triggered = false

var DOSA_PAN_COLLISION_CENTER = Vector2.ZERO
const PAN_RADIUS = 120.0

var brush_tips

var cook_level = 0.0
const COOK_SPEED = 0.01

func _ready():
	# create the blank transparent canvas
	canvas_image = Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color(0, 0, 0, 0))
	
	DOSA_PAN_COLLISION_CENTER = $DosaPan.position + Vector2(-81.0, 72.0)
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
				c.a *= 5.0*(i + 1) / 5.0
				b.set_pixel(px, py, c)
		brush_tips.append(b)

	mouse_pos = DOSA_PAN_COLLISION_CENTER
	batter_pos = DOSA_PAN_COLLISION_CENTER
	last_mouse_pos = mouse_pos
	last_batter_pos = batter_pos
	
func isInPan(position):
	return ((position - DOSA_PAN_COLLISION_CENTER).length() < PAN_RADIUS)
		

func _process(delta):
	if mouse_over_pan:
		mouse_pos = get_global_mouse_position()

# case 1: the mouse is clicking down
# case 2: the mouse is not clicking down 
# scratch that lets just have the mouse not have to click down
# when you grab the batter and spread it
# you can only do so for a set amount of time

	if dough_spread_triggered:
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
		cook_level = clamp(cook_level + COOK_SPEED * delta, 0.0, 1.0)
		$BatterCanvas.material.set_shader_parameter("cook_level", cook_level)
	last_mouse_pos = mouse_pos
	
	if dough_spread_triggered:
		$DoughBucket/Ladle.position = get_global_mouse_position() - $DoughBucket.position
	
func _input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if drag_ladle:
			$DoughBucket/Ladle.position = get_global_mouse_position() - $DoughBucket.position
			
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

func _on_dosa_pan_mouse_entered() -> void:
	mouse_over_pan = true

func _on_dosa_pan_mouse_exited() -> void:
	mouse_over_pan = false

func _on_dough_bucket_dough_bucket_clicked() -> void:
	if not drag_ladle:
		drag_ladle = true
		$DoughBucket/Ladle.show()

func _on_spread_dough_timer_timeout() -> void:
	print("Timer finished")
	dough_spread_triggered = false
	$DoughBucket/Ladle.position = Vector2(0,-100)
	drag_ladle = false


func _on_pour_dough_detector_mouse_entered() -> void:
	if drag_ladle and not dosaInPan:
		dough_spread_triggered = true
		dosaInPan = true
		$SpreadDoughTimer.start()
		print("Timer started")
	if dosaInPan and $SpreadDoughTimer.time_left == 0:
		$DoughBucket/Ladle.position = Vector2(0,-100)
		drag_ladle = false
