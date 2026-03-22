extends Resource
class_name CustomerData

@export var id: int
@export var name: String
@export var appearance_id: int
# structure of order
# dictionary of lists
# key   : value
# "dosa": [dosa1, dosa2...]
# "chutney": [chutney1, chutney2, ...]
# "drink": [drink] (drink is limited to 1)
@export var order: Dictionary 
@export var state: CustomerState = CustomerState.IN_LINE

enum CustomerState {
	IN_LINE,
	IN_ORDER_SCENE,
	WAITING_FOR_FOOD,
	DONE
}
