extends Node

var drag_ladle = false

# prevents dragging dough on multiple dosa pans in one go
var dragging_ladle = false 

var drag_cooldown = false
var banana_leaf_items = []  # Array of dicts with node info
var order_in_drink_scene = false

var dosas: Array[Texture2D] = []
var dosa_materials = []
var dosa_scores = []

var customer_of_submitted_order = null

# prevent user from dragging multiple tickets at once
var dragging_ticket = null

# prevent user from dragging multiple dosas at once
var dragging_dosa = null

func add_dosa(tex: Texture2D, material, scores):
	dosas.append(tex)
	dosa_materials.append(material)
	dosa_scores.append(scores)

func clear():
	banana_leaf_items = []
	
func add_to_banana_leaf_items(new_item):
	banana_leaf_items.push_back(new_item)
	
func clear_on_submit():
	banana_leaf_items = []
	customer_of_submitted_order = null
	order_in_drink_scene = false
