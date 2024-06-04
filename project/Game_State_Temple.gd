extends Node

@export var save_button : TextureButton
@export var agent_manager : Node
@export var ode_solver : Node
@export var load_button : TextureButton

var intersection_scene = preload("res://scenes/intersection.tscn")
var inv_intersection_scene = preload("res://scenes/invisible_intersection.tscn")
var road_scene = preload("res://scenes/road.tscn")

var intersections : Array
var roads : Array

func add_intersection(n):
	intersections.append(n)

func remove_intersection(n):
	intersections.erase(n)

func add_road(r):
	roads.append(r)

func remove_road(r):
	roads.erase(r)

func _ready():
	save_button.pressed.connect(self._save_button_pressed)
	load_button.pressed.connect(self._load_button_pressed)
	
func _save_button_pressed():
	save_game()

func _load_button_pressed():
	load_game()

func save_game():	
	var save_file = FileAccess.open("res://savegame.save", FileAccess.WRITE)
	var game = {"nodes" : [], "roads" : []}
	for a in intersections:
		var dict = {}
		dict["pos"] = [a.position.x, a.position.y, a.position.z]
		dict["rot"] = [a.rotation.x, a.rotation.y, a.rotation.z]
		dict["flow"] = a.flow 
		dict["src?"] = a.is_source 
		dict["src_o"] = a.source_out 
		dict["inv?"] = a.is_invisible 
		# dict["flow_monitor"] = a.flow_monitor 
		# dict["awaiting_queue"] = []
		# dict["agent_manager"] = null 
		# dict["ode_solver"] = null 
		# dict["in_arcs"] = []
		# dict["out_arcs"] = []
		# dict["num_cars"] = 0
		# dict["last_time_car_passed"] = 0
		# dict["agent_flow"] = 0
		
		game["nodes"].append(dict)

	for r in roads:
		var dict = {}
		dict["pos"] = [r.position.x, r.position.y, r.position.z]
		dict["rot"] = [r.rotation.x, r.rotation.y, r.rotation.z]
		dict["From"] = intersections.find(r.From)
		dict["To"] = intersections.find(r.To) 
		dict["alpha"] = r.alpha
		dict["len"] = r.road_length
		dict["ffs"] = r.freeflow_speed
		dict["maxd"] = r.max_density 
		# dict["current_density"] = 0
		# dict["outflow"] = 0
		dict["a"] = r.a 
		# dict["properties"] = r.properties 
		#dict["material"] = r.material 
		# dict["solver"] =  null
		dict["amul"] = r.alpha_multiplier 
		# dict["last_car_entered"] = null
		dict["czs"] = r.get_children()[0].size.z
		
		game["roads"].append(dict)
		
	var json_string = JSON.stringify(game)
	#print(json_string)
	save_file.store_line(json_string)


func load_game():
	if not FileAccess.file_exists("res://savegame.save"):
		print("no file found")
		return # Error! We don't have a save to load.
	
	print("file found")
	# Open the save file
	var save_file = FileAccess.open("res://savegame.save", FileAccess.READ)
	var json_string = save_file.get_line()
	save_file.close()

	# Parse the JSON string
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	# Get the data from the JSON object
	var game_data = json.get_data()
	#print(game_data)

	# Restore intersections
	for node_data in game_data["nodes"]:
		var new_intersection = intersection_scene.instantiate() if not node_data["inv?"] else inv_intersection_scene.instantiate()
		new_intersection.position = Vector3(node_data["pos"][0], node_data["pos"][1], node_data["pos"][2])
		new_intersection.rotation = Vector3(node_data["rot"][0], node_data["rot"][1], node_data["rot"][2])
		new_intersection.flow = node_data["flow"]
		new_intersection.is_source = node_data["src?"]
		new_intersection.source_out = node_data["src_o"]
		new_intersection.is_invisible = node_data["inv?"]
		new_intersection.awaiting_queue = []
		new_intersection.agent_manager = agent_manager
		new_intersection.ode_solver = ode_solver
		new_intersection.in_arcs = []
		new_intersection.out_arcs = []
		new_intersection.num_cars = 0
		new_intersection.last_time_car_passed = 0
		new_intersection.agent_flow = 0
		new_intersection.game_state = self
		add_child(new_intersection)
		intersections.append(new_intersection)

	# Restore roads
	for road_data in game_data["roads"]:
		var new_road = road_scene.instantiate()
		new_road.loaded = true
		new_road.position = Vector3(road_data["pos"][0], road_data["pos"][1], road_data["pos"][2])
		new_road.rotation = Vector3(road_data["rot"][0], road_data["rot"][1], road_data["rot"][2])
		new_road.From = intersections[road_data["From"]] # Restore reference to intersection
		new_road.To = intersections[road_data["To"]] # Restore reference to intersection
		new_road.alpha = float(road_data["alpha"])
		new_road.road_length = road_data["len"]
		new_road.freeflow_speed = road_data["ffs"]
		new_road.max_density = road_data["maxd"]
		new_road.current_density = 0
		new_road.outflow = 0
		new_road.a = road_data["a"]
		#new_road.properties = road_data["properties"]
		new_road.solver = ode_solver
		new_road.alpha_multiplier = road_data["amul"]
		new_road.last_car_entered = null
		new_road.get_children()[0].size.z = road_data["czs"]
		new_road.game_state = self
		add_child(new_road)
		roads.append(new_road)

		new_road.To.in_arcs.append(new_road)
		new_road.From.out_arcs.append(new_road)
		ode_solver.Roads.append(new_road)
	
