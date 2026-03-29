extends Node2D

signal customer_clicked(customer)

@export var customer_scene: PackedScene
var customerCount
var customerArray = []
var next_customer_id

var customer_at_order_spot = false

# structure of order
# dictionary of lists
# key   : value
# "dosa": [dosa1, dosa2...]
# "chutney": [chutney1, chutney2, ...]
# "drink": [drink] (drink is limited to 1)

func generate_random_order(dosa_cap: int = 1, chutney_cap: int = 1):
	const DOSA_OPTIONS = ["PlainDosa", "OnionDosa"]
	const CHUTNEY_OPTIONS = ["CoconutChutney", "MintChutney", "Sambar"]
	const DRINK_OPTIONS = ["MangoLassi", "FilteredCoffee"]
	
	const SUGAR_ICE_OPTIONS = [true, false]

	var dosa_count = randi_range(1, dosa_cap)
	var chutney_count = randi_range(1, chutney_cap)

	var dosas = []
	for i in dosa_count:
		dosas.append(DOSA_OPTIONS.pick_random())

	var chutneys = []
	for i in chutney_count:
		chutneys.append(CHUTNEY_OPTIONS.pick_random())
		
	var drink = DRINK_OPTIONS.pick_random()
	var sugar = SUGAR_ICE_OPTIONS.pick_random()
	var ice = not sugar

	return {
		"dosa": dosas,
		"chutney": chutneys,
		"drink": drink,
		"ice": ice,
		"sugar": sugar
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$OrderArrow.hide()
	$CustomerSpawner.start()
	$CustomerSpawner.wait_time = randf_range(8.0, 16.0)
	next_customer_id = 0 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_order_spot_area_entered(area: Area2D) -> void:
	if area.has_method("stop_and_wait"):
		$OrderArrow.show()
		area.stop_and_wait()
	

func spawn_customer():
	next_customer_id += 1
	
	#set up customer data
	#name, appearance, order
	var data := CustomerData.new()
	data.id = next_customer_id
	data.name = "GirlyPop"
	data.order = generate_random_order()
	data.state = CustomerData.CustomerState.IN_LINE
	#create customer child node
	var customer = customer_scene.instantiate()
	
	#attach the CustomerData to the customer node
	customer.data = data
	
	#spawn the customer at the spawn position
	customer.position = $CustomerSpawnPoint.position
	add_child(customer)
	
	#add customer to array
	customerArray.append(customer)
	
	#connect signal to customer
	customer.order_requested.connect(_on_customer_order_requested.bind(customer))
	customer.waiting_customer.connect(_on_customer_waiting_customer)

func _on_customer_spawner_timeout() -> void:
	spawn_customer()
	$CustomerSpawner.wait_time = randf_range(100.0, 200.0)
	
func _on_customer_order_requested(customer):
	#we only want to register click on customer
	#if the customer is the first in line
	if customer == customerArray[0]:
		# Pass signal up to main scene
		customer_clicked.emit(customer)

func order_arrow():
	$OrderArrow.show()
	$OrderArrow.get_node("AnimatedSprite2D").play("bobbing")


func _on_order_scene_order_complete() -> void:
	#move the first customer out of line
	#they wait somewhere else
	var customer = customerArray.pop_front()
	if not customer_at_order_spot: # or customer not colliding with order spot
		$OrderArrow.hide()

	customer.moveCustomerOutOfLine()


func _on_customer_waiting_customer(customer) -> void:
	#when a customer is waiting, check if they
	#should have a green arrow on their head

	if customerArray[0].data.id == customer.data.id:
		order_arrow()


func _on_order_spot_area_exited(area: Area2D) -> void:
	if area.has_method("stop_and_wait"):
		$OrderArrow.hide()
