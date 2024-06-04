extends Node

@export var flow = 0.0
@export var is_source = false
@export var source_out = 0.0
@export var is_invisible = false
@export var flow_monitor : Node

var awaiting_queue : Array

var agent_manager : Node
var ode_solver : Node
var game_state : Node
var in_arcs : Array
var out_arcs : Array

var num_cars = 0
var last_time_car_passed = 0
var agent_flow = 0

func add_car(now):
	num_cars += 1
	if last_time_car_passed != 0:
		agent_flow = 1 / (now - last_time_car_passed)
	last_time_car_passed = now
	
func enqueue_waiters(c):
	awaiting_queue.append(c)
	print("done appending")
	
func get_random_waiter():
	var c = awaiting_queue[randi_range(0, len(awaiting_queue)-1)]
	awaiting_queue.erase(c)
	return c

func erase_from_queue(c):
	awaiting_queue.erase(c)

func erase_first_from_queue():
	awaiting_queue.remove_at(0)
	
func is_in_queue (c):
	return (c in awaiting_queue)

func get_index_queue(c):
	return awaiting_queue.find(c)

# used by grapher to plot flow over time
func get_value():
	return flow

func erase_node():
	var nodes_to_be_erased = []
	# LOL
	for i in range(len(in_arcs)):
		var from = in_arcs[0].From
		if from.is_invisible and not (from in nodes_to_be_erased) :
			nodes_to_be_erased.append(from)
		in_arcs[0].erase_arc()
		
	in_arcs = []
	for i in range(len(out_arcs)):
		var to = out_arcs[0].To
		if to.is_invisible and not (to in nodes_to_be_erased) :
			nodes_to_be_erased.append(to)
		out_arcs[0].erase_arc()
	out_arcs = []
	
	for n in nodes_to_be_erased:
		n.erase_node()
	nodes_to_be_erased = []
	game_state.remove_intersection(self)
	self.queue_free()
	
# Used to differentiate between different clicked elements
func is_node ():
	return true

func is_car ():
	return false

# Returns 1 if sink and the sum of (the alphas * their activations) o.w.
func tot_out_alpha():
	# node is a sink
	if len(out_arcs) == 0:
		return 1
	var res = 0.
	for a in out_arcs:
		res += a.alpha * a.alpha_multiplier
	return res
	
# flow = vel * density = m/s * c/m = c/s

var j = 0
var next_period = 0
func _process(delta):
	if next_period == 0:
		next_period = flow + randf_range(-flow / 2, flow/2)
	if is_source and not ode_solver.paused:
		j += 1 * delta
		if j >= 1/(next_period):
			agent_manager.spawn_car(self)
			j = 0
			next_period = flow + randf_range(-flow / 2, flow/2)
	
	if len(in_arcs) == 0 and not ode_solver.paused:
		for r in out_arcs:
			var max_flow = r.get_outflow_d(r.max_density / 2)
			if flow > max_flow:
					flow = max_flow
	pass
	
