extends Node3D
@export var speed = 0
@export var highlight : Node
@export var leader_banner : Node
@export var sleep : Node
@export var crash_icon : Node
@export var car_length = 3
@export var models : Array
@export var lengths : Array

var leader : Node
var cur_road : Node
var traveled_road : float
var total_traveled : float
var ode_solver : Node
var follower : Node
var last_visible_intersection : Node

var p1 = 1			# driver sensitivity
var p2 = 0		# speed exponent
var p3 = 2		# distance exponent

var p4 = 0		# base acceleration (invented parameter)

var braking_decel = .3
var base_accel = 1.

func is_car ():
	return true
	
func is_node ():
	return false
	
func is_road ():
	return false

# Highlight car and its leader
var highlighted = false
func toggle_highlight():
	highlight.visible = not highlight.visible
	highlighted = not highlighted

	if is_instance_valid(leader):
		leader.leader_banner.visible = not leader.leader_banner.visible

func refresh_highlighting():
	if is_instance_valid(leader):
		leader.leader_banner.visible = highlighted
		

func remove_leader_highlight():
	leader_banner.visible = false

func forget_leader ():
	if is_instance_valid(leader):
		leader.follower = null
		leader.remove_leader_highlight()
	leader = null
	# speed = cur_road.freeflow_speed

func new_leader(c):
	# c cannot be its own leader!
	if c != self:
		leader = c
		c.follower = self

func free_follower():
	if is_instance_valid(follower):
		follower.forget_leader()

func _ready():
	var model_i = randi_range(0, len(models) - 1)
	get_node(models[model_i]).visible = true
	car_length = lengths[model_i]
	pass

func set_heading (delta):
	self.rotation.y = delta

func center_on_node (intersection):
	self.position.x = intersection.position.x
	self.position.z = intersection.position.z
	
func move_fwd (dx):
	var rot = self.rotation.y
	self.position.x += dx * sin(rot)
	self.position.z += dx * cos(rot)

# Modified Gazis-Herman-Rothery (GHR) traffic model
func accel():
	var deltav = leader.speed - speed
	var distance = leader.position.distance_to(self.position) - (car_length + leader.car_length) / 2
	
	if distance < 0:
		crash_icon.visible = true
		return [0, true]
	elif distance < 50:
		crash_icon.visible = false
		# deltav / distance ** 2
		var res = p1 * speed ** p2 * (deltav / (distance ** p3)) + p4
		return [res, false]
	else:
		return [base_accel, false]
	

var stuck_at_intersection = false

func update_leader():
	# leader management
	# If last car entered is still on current road make it leader
	if is_instance_valid(cur_road.last_car_entered) and cur_road.last_car_entered.last_visible_intersection == cur_road.From:
		# Unleader the old leader
		forget_leader()
		# make last car entered new leader
		new_leader(cur_road.last_car_entered)
	else:
		# otherwise be the leader
		forget_leader()

func give_way():
	if !cur_road.To.is_invisible:
		# car adds itself to the waiting car list
		if not cur_road.To.is_in_queue(self):
			print("enqueue")
			cur_road.To.enqueue_waiters(self)
			print("len is: " + str(len(cur_road.To.awaiting_queue)))
		# car waits for its turn before speeding through the intersection
		if cur_road.To.get_index_queue(self) != 0:
			#print(cur_road.To.get_index_queue(self))
			print("car should be stuck")
			stuck_at_intersection = true
			speed = 0
		else:
			stuck_at_intersection = false
			#speed = cur_road.freeflow_speed


func choose_road():
	var ran = randf_range(0, 1)
	for r in cur_road.To.out_arcs:
		if r.alpha > ran:
			return r
		else:
			ran -= r.alpha

	assert(false)

func intersection_is_in_front(node):
	var inters_vec = node.position - position
	var fwd = Vector3(sin(rotation.y), 0, cos(rotation.y))
	return inters_vec.dot(fwd) > 0

func end_of_road():
	# Reaching end of road
	if not intersection_is_in_front(cur_road.To):
		# reset the amount of distance traveled
		cur_road.cur_num_cars -= 1
		cur_road.To.add_car(ode_solver.sim_time)
		traveled_road = 0
		if !cur_road.To.is_invisible:
			free_follower()
			# remove itself from queue
			# cur_road.To.erase_from_queue(self)
			# set last visible intersection
			last_visible_intersection = (cur_road.To)
			
		# choose a road randomly (using weighted choice)
		cur_road = choose_road()
		if(len(cur_road.To.out_arcs) > 0):
			if !cur_road.From.is_invisible:
				update_leader()
			
			# the car is now the last that entered the intersection.
			cur_road.last_car_entered = self
			cur_road.cur_num_cars += 1
			
			
			# align with the road
			if not cur_road.From.is_invisible:
				center_on_node(cur_road.From)
				set_heading(cur_road.rotation.y)
		else:
			# If the road is over, disappear...
			print("erasing car")
			speed = 0
			# ...make sure your followers know...
			if is_instance_valid(follower):
				follower.leader = null
			self.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	refresh_highlighting()

	if !ode_solver.paused:
		sleep.visible = stuck_at_intersection
		# Scheduling at intersections
		give_way()
		
		if not stuck_at_intersection:
			# handles end of road
			end_of_road()
			if cur_road.From.position.distance_to(position) > cur_road.road_length / 2:
				cur_road.From.erase_from_queue(self)
			traveled_road += speed * delta
			total_traveled += speed * delta
			
			
			if is_instance_valid(leader):
				if speed > cur_road.freeflow_speed:
					speed -= braking_decel
				else:
					var a = accel()
					var acceleration = a[0]
					var crash = a[1]
					if not crash:
						if speed + acceleration < cur_road.freeflow_speed:
							speed += acceleration
					else:
						speed = 0
			else:
				if speed + base_accel < cur_road.freeflow_speed:
					speed += base_accel
				
				if speed > cur_road.freeflow_speed:
					speed -= braking_decel
				
			if speed < 0:
				speed = 0
			move_fwd(speed * delta)
	pass
