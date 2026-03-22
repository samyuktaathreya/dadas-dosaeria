extends Control

class_name Ticket

signal ticket_being_dragged

var is_dragging = false

const DOSA_SCALE = 0.026
var ICONS_START_POSITION
const SPACE_BETWEEN_TICKET_ICONS = 200.0

const CHUTNEY_SCALE = 0.026
const CHUTNEY_POSITION = Vector2(0, 160)

const DOSA_FILE_PATH = "res://assets/dosas/"
const CHUTNEY_FILE_PATH = "res://assets/chutneys/"
var customer_of_ticket
var customer_data
var hovering_on_ticket = false

const UI_BAR_Y_POSITION = 280.0
const VERTICAL_SPACING = 100.0
const EXPANDED_TICKET_POSITION = Vector2(1644.0, 492.0)

const X_THRESHOLD_FOR_EXPANDING_TICKET = 900.0

const MINIMIZED_SCALE = Vector2(0.3, 0.3)
const EXPANDED_SCALE = Vector2(1.0, 1.0)

var ticket_minimized = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ICONS_START_POSITION = $IconsStartPosition.global_position
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func spawn_dosa_icon(dosa_texture, icon_position):
	var icon = Sprite2D.new()
	icon.texture = dosa_texture
	icon.global_position = icon_position
	icon.scale = Vector2(DOSA_SCALE, DOSA_SCALE)
	add_child(icon)
	print("icon global position : ", icon.global_position)
	return icon
	
func spawn_chutney_icon(chutney_texture, icon_position):
	var icon = Sprite2D.new()
	icon.texture = chutney_texture
	icon.global_position = icon_position
	icon.scale = Vector2(CHUTNEY_SCALE, CHUTNEY_SCALE)
	icon.show()
	add_child(icon)
	print("icon global position : ", icon.global_position)
	return icon

func load_ticket(ticket_position, customer):
	#food_type options: dosa, chutney, drink
	customer_of_ticket = customer
	customer_data = customer.data
	var order = customer_data.order
	print("customer order : ", order)
	self.position = ticket_position
	
	# i have to rewrite this 
	# so that the icons are instantiated into the ticket based on the order
	# iterate through dosas first
	# spawn a dosa 
	var icon_position = $IconsStartPosition.global_position
	for dosa in order.dosa:
		var dosa_texture = load(DOSA_FILE_PATH + dosa + ".png")
		spawn_dosa_icon(dosa_texture, icon_position)
		icon_position.y -= SPACE_BETWEEN_TICKET_ICONS
	
	# spawn the chutneys
	for chutney in order.chutney:
		var chutney_texture = load(CHUTNEY_FILE_PATH + chutney + ".png")
		spawn_chutney_icon(chutney_texture, icon_position)
		icon_position.y -= SPACE_BETWEEN_TICKET_ICONS

func _input(event):
	# start hovering mouse
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if hovering_on_ticket:
			ticket_being_dragged.emit(self)
			is_dragging = true
			self.global_position = get_global_mouse_position()
	else:
		is_dragging = false
	# stop hovering mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if self.global_position.y > UI_BAR_Y_POSITION + VERTICAL_SPACING \
		and self.global_position.x > X_THRESHOLD_FOR_EXPANDING_TICKET:
			expand_ticket()
		else:
			minimize_ticket()

func _on_blank_order_ticket_mouse_entered() -> void:
	hovering_on_ticket = true

func _on_blank_order_ticket_mouse_exited() -> void:
	hovering_on_ticket = false
	
func expand_ticket():
	# increase size of ticket
	$BlankOrderTicket.scale = EXPANDED_SCALE
	# move position of ticket
	self.global_position = EXPANDED_TICKET_POSITION
	ticket_minimized = false
	
func minimize_ticket():
	# decrease size of ticket
	$BlankOrderTicket.scale = MINIMIZED_SCALE
	# move position of ticket 
	self.position = Vector2(self.position.x, UI_BAR_Y_POSITION)
	
	ticket_minimized = true
	
func ticket_submitted():
	queue_free()
