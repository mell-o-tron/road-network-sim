extends Node

@export var camera : Camera3D 
@export var height_offset = -1
@export var road_button : TextureButton
@export var node_button : TextureButton
@export var ode_solver : Node
@export var node_menu : Node
@export var graph : Node
@export var agent_manager : Node
@export var agent_graph : Node
@export var target_len = 5.0
@export var game_state = Node
@export var mode_label : Label

var intersection_scene = preload("res://scenes/intersection.tscn")
var inv_intersection_scene = preload("res://scenes/invisible_intersection.tscn")
var road_scene = preload("res://scenes/road.tscn")

var graph_scene = preload("res://scenes/graph.tscn")

var cur_mode = ''
var selected_node : Node = null

func _ready():
	road_button.pressed.connect(self._road_button_pressed)
	node_button.pressed.connect(self._node_button_pressed)

func _road_button_pressed():
	cur_mode = 'road'
	selected_node = null
	mode_label.text = "Mode: road - no node selected"
	
func _node_button_pressed():
	cur_mode = 'node'
	mode_label.text = "Mode: selection / node construction"

func handle_node_selection(obj):
	if cur_mode == 'node':
		node_menu.visible = true
		node_menu.setup_node(obj)
		graph.reset()
		graph.set_max_value(3)	# TODO change 
		graph.set_monitored(obj)
		
		agent_graph.reset()
		agent_graph.set_max_value(3) # TODO change
		agent_graph.set_monitored(obj.flow_monitor)
		
	if cur_mode == 'road':
		# await next selection to construct road
		if !selected_node:
			mode_label.text = "Mode: road - node: \"" + str(obj) + "\" selected"
			selected_node = obj
		elif selected_node != obj:
			var divisions = 2 + floor(selected_node.position.distance_to(obj.position) / target_len)
			construct_roads(selected_node, obj, divisions)
			selected_node = null 
			mode_label.text = "Mode: road constructed"
		else:
			mode_label.text = "Mode: road - no node selected"
			selected_node = null 

func handle_road_selection(obj):
	if cur_mode == 'node':
		node_menu.visible = true
		node_menu.setup_road(obj)
		graph.reset()
		graph.set_max_value(obj.max_density)
		graph.set_monitored(obj)

		agent_graph.reset()
		agent_graph.set_max_value(obj.max_density)
		agent_graph.set_monitored(obj.density_monitor)
	pass

func construct_road (from, to):
	var new_node = road_scene.instantiate()
	new_node.solver = ode_solver
	new_node.game_state = game_state
	new_node.From = from
	new_node.To = to
	new_node.setup_road()
	ode_solver.Roads.append(new_node)
	game_state.add_road(new_node)
	add_child(new_node)
	
func construct_roads (from, to, n):
	var intersections = []
	for i in range(1,n):
		var road = road_scene.instantiate()

		if i != n-1:
			var intermediate = inv_intersection_scene.instantiate()
			var fp = from.position
			var tp = to.position
			
			intermediate.position = fp + (tp - fp).normalized() * i * (tp.distance_to(fp))/(n-1)
			intersections.append(intermediate)
			game_state.add_intersection(intermediate)
			intermediate.game_state = game_state
			road.To = intermediate
		else:
			road.To = to
		if i == 1:
			road.From = from
		else:
			road.From = intersections[i-2]
			
		road.solver = ode_solver
		road.game_state = game_state
		road.setup_road()
		ode_solver.Roads.append(road)
		game_state.add_road(road)
		add_child(road)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and cur_mode == 'node':
			var d = camera.position.y * acos(camera.rotation.x)
			var c = camera.project_position(event.position, d)
			
			# binary search for zero height
			var failed = false 
			var iterations = 0
			var max_iterations = 5000
			while true:
				if iterations > max_iterations:
					failed = true
					break
				
				c = camera.project_position(event.position, d)
				if abs(c.y - height_offset) < .05:
					break
				elif c.y > height_offset:
					d += d/2
				else:
					d -= d/2
					
				#print(d)
				iterations += 1
	
			if not failed:
				print(c)
				var new_node = intersection_scene.instantiate()
				new_node.position = c
				new_node.position.y = height_offset
				new_node.agent_manager = agent_manager
				new_node.ode_solver = ode_solver
				add_child(new_node)
				game_state.add_intersection(new_node)
				new_node.game_state = game_state
			else:
				print("failed")
			
		
