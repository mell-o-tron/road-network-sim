extends Camera3D

@export var move_speed = 10.0
@export var rotate_speed = 2.0
@export var road_manager : Node
@export var agent_manager : Node

var mouse = Vector2()

func _input (event):
	if event is InputEventMouse:
		mouse = event.position
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_selection()

func get_selection():
	var start = project_ray_origin(mouse)
	var end = project_position(mouse, 200)
	var query = PhysicsRayQueryParameters3D.create(start, end)
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if (collision):
		if collision.collider.get_parent().is_car():
			agent_manager.handle_car_selection(collision.collider.get_parent())
			return
		if collision.collider.get_parent().is_node():
			road_manager.handle_node_selection(collision.collider.get_parent())
		if !collision.collider.get_parent().is_node():
			road_manager.handle_road_selection(collision.collider.get_parent())

var is_following = false
var cur_car = null
var follow_pos = Vector3.ZERO
var car_ini_pos = Vector3.ZERO
func follow_car(car):
	is_following = not is_following
	if is_following:
		cur_car = car
		follow_pos = position
		car_ini_pos = car.position

func _process(delta):
	if(is_following and is_instance_valid(cur_car)):
		position.x = cur_car.position.x - (car_ini_pos.x - follow_pos.x )
		position.z = cur_car.position.z - (car_ini_pos.z - follow_pos.z)
	else:
		is_following = false
		move_camera(delta)
		rotate_camera(delta)
	
		
	
func move_camera(delta):
	var input_vector = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_vector.y += -sin (rotation.x)
		input_vector.z += -cos (rotation.x)
	if Input.is_action_pressed("move_backward"):
		input_vector.y += sin (rotation.x)
		input_vector.z += cos (rotation.x)
		
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y += +cos (rotation.x)
		input_vector.z += -sin (rotation.x)
	if Input.is_action_pressed("move_down"):
		input_vector.y += -cos (rotation.x)
		input_vector.z += +sin (rotation.x)
		
	input_vector = input_vector.normalized()
	
	var camera_transform = global_transform
	var scaled_move_speed = max(move_speed + position.y * 5, 200)
	camera_transform.origin += camera_transform.basis.z * input_vector.z * scaled_move_speed * delta
	camera_transform.origin += camera_transform.basis.x * input_vector.x * scaled_move_speed * delta
	camera_transform.origin += camera_transform.basis.y * input_vector.y * scaled_move_speed * delta
	global_transform = camera_transform
	
	if position.y > 0:
		rotation.x = -PI/2 + (2.71828)**(-(position.y / 100) + .45)
	else:
		rotation.x = 0
		position.y = 0
	
func rotate_camera(delta):
	var rotate_vector = Vector3.ZERO
	if Input.is_action_pressed("rotate_left"):
		rotate_vector.y += 1
	if Input.is_action_pressed("rotate_right"):
		rotate_vector.y -= 1
	
	rotate_y(rotate_vector.y * rotate_speed * delta)
