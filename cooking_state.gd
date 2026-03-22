extends Node

var drag_ladle = false
var drag_cooldown = false
var banana_leaf_items = []  # Array of dicts with node info
var order_in_drink_scene = false

var dosas: Array[Texture2D] = []
var dosa_materials = []

var customer_of_submitted_order = null

func add_dosa(tex: Texture2D, material):
	dosas.append(tex)
	dosa_materials.append(material)

func clear():
	banana_leaf_items = []
	
func add_to_banana_leaf_items(new_item):
	banana_leaf_items.push_back(new_item)
	
func clear_on_submit():
	banana_leaf_items = []
	customer_of_submitted_order = null
