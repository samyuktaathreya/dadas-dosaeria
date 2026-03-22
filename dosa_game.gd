extends Node2D

var canvas_image: Image
var canvas_texture: ImageTexture
var brush_tip: Image
var last_pos: Vector2 = Vector2(-1, -1)

const CANVAS_SIZE = 512
const BRUSH_SIZE = 64

func _ready():
	# create the blank transparent canvas
	canvas_image = Image.create(CANVAS_SIZE, CANVAS_SIZE, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color(0, 0, 0, 0))
	
	canvas_texture = ImageTexture.create_from_image(canvas_image)
	$BatterCanvas.texture = canvas_texture
	
	# load your brush tip image
	brush_tip = load("res://assets/dosadoughtexture.png").get_image()
	brush_tip.resize(BRUSH_SIZE, BRUSH_SIZE)

func _input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var local_pos = $BatterCanvas.to_local(event.position)
		# shift so the stamp is centered on the mouse
		local_pos += Vector2(CANVAS_SIZE / 2, CANVAS_SIZE / 2)
		
		if last_pos == Vector2(-1, -1):
			last_pos = local_pos
		
		stamp_along_path(last_pos, local_pos)
		last_pos = local_pos
		canvas_texture.update(canvas_image)
	
	if event is InputEventMouseButton and not event.pressed:
		last_pos = Vector2(-1, -1)

func stamp_along_path(a: Vector2, b: Vector2):
	var dist = a.distance_to(b)
	var steps = max(1, int(dist / 4))  # stamp every 4 pixels
	for i in range(steps + 1):
		var t = float(i) / steps
		var pos = a.lerp(b, t)
		stamp_at(pos)

func stamp_at(pos: Vector2):
	var x = int(pos.x) - BRUSH_SIZE / 2
	var y = int(pos.y) - BRUSH_SIZE / 2
	# blend_rect pastes the brush tip image onto the canvas at this position
	canvas_image.blend_rect(brush_tip, Rect2(0, 0, BRUSH_SIZE, BRUSH_SIZE), Vector2i(x, y))
