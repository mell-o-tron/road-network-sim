extends Node

@export var From : Node
@export var To : Node
@export var alpha : float = 0.5
@export var road_length = 1
@export var freeflow_speed = 13.9	# 50 km/h
@export var max_density = .33333	# 1/3 car per meter
@export var current_density : float
@export var outflow : float
@export var a = 1# 1.225	# multiplier for fundamental diagram
@export var density_monitor : Node

var properties : Array

var material : StandardMaterial3D

var solver : Node
var game_state : Node

var alpha_multiplier = 1

var last_car_entered : Node
var cur_num_cars = 0

var loaded = false

func get_value():
	return current_density

func get_inflow():
	return From.flow * alpha * alpha_multiplier

# using Greenshields model
func get_outflow_g_d (d):
	return a * freeflow_speed * d * (1 - (d / max_density))

# linear
func get_outflow_lin_d (d):
	return d * freeflow_speed

func get_outflow():
	return get_outflow_d(current_density)
	
var linear_flow = false
func get_outflow_d(d):
	if linear_flow:
		return get_outflow_lin_d(d)
	else:
		return get_outflow_g_d(d)

func dr_dx ():
	var in_f = get_inflow()
	var out_f = get_outflow()
	#print(str(self) + ":\t in: " + str(in_f) + "\tout: " + str(out_f))
	return (in_f - out_f) / road_length

func recompute_alphas():
	for ar in From.out_arcs:
			ar.alpha = 1.0 / len(From.out_arcs)

func _ready():
	if not loaded:
		To.in_arcs += [self]
		From.out_arcs += [self]

	material = StandardMaterial3D.new()
	material.albedo_color = Color(0.92, 0.69, 0, 1.0)
	self.get_children()[0].material_override = material
	
	if not loaded:
		recompute_alphas()
	
	properties.append([alpha, "alpha"])
	properties.append([road_length, "road length"])
	properties.append([freeflow_speed, "freeflow speed"])
	properties.append([max_density, "max density"])
	properties.append([current_density, "density"])
		
	pass

var road_highlight = false
func toggle_road_highlight():
	if !road_highlight:
		material.albedo_color.b = 1.
		road_highlight = true
	else:
		material.albedo_color.b = 0.
		road_highlight = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	material.albedo_color.r = current_density / max_density
	material.albedo_color.g = 1 - (current_density / max_density)
	
	properties[0] = [alpha, "alpha"]
	properties[1] = [road_length, "road length"]
	properties[2] = [freeflow_speed, "freeflow speed"]
	properties[3] = [max_density, "max density"]
	properties[4] = [current_density, "density"]

	pass

func set_property(i, v):
	match i:
		0:
			alpha = v
		1:
			road_length = v
		2:
			freeflow_speed = v
		3:
			max_density = v
		4:
			current_density = v
		_:
			print("property not found")

func erase_arc():
	print("erasing arc")
	if To:
		To.in_arcs.erase(self)
	if From:
		From.out_arcs.erase(self)
	
	recompute_alphas()
	solver.Roads.erase(self)
	game_state.remove_road(self)
	self.queue_free()

func is_node ():
	return false

func is_car ():
	return false
	
func setup_road():
	self.position = (From.position + To.position) / 2
	var difference = To.position - From.position
	var delta = acos(Vector3(0, 0, 1).dot(difference.normalized()))
	self.rotation.y = delta * sign(difference.x)
	self.get_children()[0].size.z = From.position.distance_to(To.position)
	
	self.road_length = From.position.distance_to(To.position)
