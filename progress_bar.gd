extends ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1, 0.5, 0, 1)  # orange, fully opaque

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 1)  # dark gray background

	self.add_theme_stylebox_override("fill", fill_style)
	self.add_theme_stylebox_override("background", bg_style)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
