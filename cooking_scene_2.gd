extends Node2D

signal dosa_submitted


var open_trash_texture = load("res://assets/Trashtrashed.png")
var closed_trash_texture = load("res://assets/Trash.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func serve_dosa():
	var BANANA_LEAF_POSITION = $BananaLeaf.position
	var banana_leaf = $BananaLeaf
	var screen_width = get_viewport_rect().size.x

	# find the dosa drag sprite - it's a child of this node added dynamically
	var dosa_sprite = null
	for child in get_children():
		if child is Sprite2D and child != $BananaLeaf:
			dosa_sprite = child
			break
	var scores = {
		"cook_score": dosa_sprite.get_meta("cook_score"),
		"shape_score": dosa_sprite.get_meta("shape_score"),
		"total_score": dosa_sprite.get_meta("total_score"),
		"onion": dosa_sprite.get_meta("onion")
	}
	var pan_center = dosa_sprite.get_meta("pan_center")
	CookingState.add_dosa(dosa_sprite.texture, dosa_sprite.material, scores, pan_center)
	dosa_submitted.emit()
	var tween = create_tween()
	tween.set_parallel(true)

	# slide banana leaf off to the right
	tween.tween_property(banana_leaf, "global_position", 
		Vector2(screen_width + 200, banana_leaf.global_position.y), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# slide dosa sprite off with it
	if dosa_sprite:
		tween.tween_property(dosa_sprite, "global_position",
			Vector2(screen_width + 200, dosa_sprite.global_position.y), 0.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# after slide out, bring in new banana leaf from the right
	tween.chain().tween_callback(func():
		banana_leaf.global_position = Vector2(screen_width + 200, banana_leaf.global_position.y)
		var tween2 = create_tween()
		tween2.tween_property(banana_leaf, "global_position",
			BANANA_LEAF_POSITION, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if dosa_sprite:
			dosa_sprite.queue_free()
	)

func _on_trash_mouse_entered() -> void:
	if visible:
		CookingState.mouse_on_trash = true
		$Trash/TrashSprite.texture = open_trash_texture

func _on_trash_mouse_exited() -> void:
	CookingState.mouse_on_trash = false
	$Trash/TrashSprite.texture = closed_trash_texture
