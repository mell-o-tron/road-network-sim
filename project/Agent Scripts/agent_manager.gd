extends Node

@export var ode_solver : Node
@export var road_manager : Node
@export var camera : Camera3D
@export var selected_car : Node
@export var speed_label : Label

var car_scene = preload("res://scenes/car.tscn")

func handle_car_selection (car):
	if not car.highlighted:
		selected_car = car
	else:
		selected_car = null 
		
	car.toggle_highlight()
	camera.follow_car(car)
	return

func spawn_car(inters):
	if(len(inters.out_arcs) == 0):
		return
	var new_node = car_scene.instantiate()
	new_node.last_visible_intersection = inters
	new_node.cur_road = inters.out_arcs[randi_range(0, len(inters.out_arcs) - 1)]
	new_node.set_heading(new_node.cur_road.rotation.y)
	
	var speed = randf_range(new_node.cur_road.freeflow_speed/3, new_node.cur_road.freeflow_speed)
	
	if not is_instance_valid(new_node.cur_road.last_car_entered):
		new_node.speed = speed
	else:
		new_node.speed = speed
		new_node.leader = new_node.cur_road.last_car_entered
		new_node.cur_road.last_car_entered.follower = new_node
	
	new_node.cur_road.last_car_entered = new_node
	
	new_node.position = inters.position
	new_node.position.y = -1
	new_node.ode_solver = ode_solver
	
	add_child(new_node)
	pass # Replace with function body.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(selected_car):
		speed_label.text = "Speed: " + str(selected_car.speed)
	else:
		speed_label.text = "No car selected"
	pass
