extends Control

class_name Ticket

signal ticket_being_dragged

var is_dragging = false

const DOSA_MINIMIZED_SCALE = 0.3
var ICONS_START_POSITION
const SPACE_BETWEEN_TICKET_ICONS = 45.0

const CHUTNEY_MINIMIZED_SCALE = 0.2
const CHUTNEY_POSITION = Vector2(0, 160)

const DRINK_MINIMIZED_SCALE = 0.2

const DOSA_FILE_PATH = "res://assets/dosas/"
const CHUTNEY_FILE_PATH = "res://assets/chutneys/"
const DRINK_FILE_PATH = "res://assets/drinks/"

var customer_of_ticket
var customer_data
var hovering_on_ticket = false

var ticket_icons = []

const UI_BAR_Y_POSITION = 160.0 #previously 280
const VERTICAL_SPACING = 100.0
const EXPANDED_TICKET_POSITION = Vector2(1644.0, 492.0)

const X_THRESHOLD_FOR_EXPANDING_TICKET = 900.0

const MINIMIZED_SCALE = Vector2(0.3, 0.3)
const EXPANDED_SCALE = Vector2(1.0, 1.0)

var ticket_minimized = true
var minimized_position

var og_z_index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ICONS_START_POSITION = $IconsStartPosition.global_position
	og_z_index = z_index
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func spawn_dosa_icon(dosa_texture, icon_position):
	var icon = Sprite2D.new()
	icon.texture = dosa_texture
	icon.scale = Vector2(DOSA_MINIMIZED_SCALE, DOSA_MINIMIZED_SCALE)
	$BlankOrderTicket.add_child(icon)
	icon.global_position = icon_position
	ticket_icons.append(icon)
	return icon
	
func spawn_chutney_icon(chutney_texture, icon_position):
	var icon = Sprite2D.new()
	icon.texture = chutney_texture
	icon.scale = Vector2(CHUTNEY_MINIMIZED_SCALE, CHUTNEY_MINIMIZED_SCALE)
	icon.show()
	$BlankOrderTicket.add_child(icon)
	icon.global_position = icon_position
	ticket_icons.append(icon)
	return icon
	
func spawn_drink_icon(drink_texture, icon_position):
	var icon = Sprite2D.new()
	icon.texture = drink_texture
	icon.scale = Vector2(DRINK_MINIMIZED_SCALE, DRINK_MINIMIZED_SCALE)
	icon.show()
	$BlankOrderTicket.add_child(icon)
	icon.global_position = icon_position
	ticket_icons.append(icon)
	return icon
	

func load_ticket(ticket_position, customer):
	minimized_position = ticket_position  # ADD THIS
	#food_type options: dosa, chutney, drink
	customer_of_ticket = customer
	customer_data = customer.data
	var order = customer_data.order
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
		
	# spawn the drink
	var drink_texture
	if order.sugar:
		drink_texture = load(DRINK_FILE_PATH + order.drink + "Sugar.png")
	else:
		drink_texture = load(DRINK_FILE_PATH + order.drink + "Ice.png")
		
	spawn_drink_icon(drink_texture, icon_position)
	
	icon_position.y -= SPACE_BETWEEN_TICKET_ICONS

func _input(event):
	# Handle dragging movement
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if hovering_on_ticket and not is_dragging and CookingState.dragging_ticket == null:
				is_dragging = true
				minimize_ticket()
				CookingState.dragging_ticket = self
				ticket_being_dragged.emit(self)
			if is_dragging and CookingState.dragging_ticket == self:
				self.global_position = get_global_mouse_position()
				self.z_index = 100

	# Handle mouse button release
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		if is_dragging and CookingState.dragging_ticket == self:
			CookingState.dragging_ticket = null
			self.z_index = og_z_index
		is_dragging = false
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
	$BlankOrderTicket.scale = EXPANDED_SCALE
	if ticket_minimized:
		for icon in ticket_icons:
			icon.scale *= (EXPANDED_SCALE / MINIMIZED_SCALE) * 0.5

	self.global_position = EXPANDED_TICKET_POSITION
	ticket_minimized = false
	
func minimize_ticket():
	# decrease size of ticket
	$BlankOrderTicket.scale = MINIMIZED_SCALE
	
	if not ticket_minimized:
		for icon in ticket_icons:
			icon.scale *= (MINIMIZED_SCALE / EXPANDED_SCALE) * 2
		
	# move position of ticket 
	self.global_position = Vector2(self.global_position.x, UI_BAR_Y_POSITION)
	
	ticket_minimized = true
	
func ticket_submitted():
	queue_free()
	
func order_scene_called():
	if not ticket_minimized:
		self.position.x -= 200
		minimize_ticket()
