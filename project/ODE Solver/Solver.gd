extends Node

@export var Roads : Array
@export var paused = true
@export var pause_button : Node

var sim_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	paused = pause_button.sim_paused
	
	if !paused:
		sim_time += delta
		var flow_contrib = []
		var delta_densities = []
		for r in Roads:
			var n = r
			flow_contrib.append(n.get_outflow())
			delta_densities.append(delta * n.dr_dx())

		
		for r in Roads:
			var toflow = r.To.flow
			if !r.To.is_source:
				for r1 in r.To.out_arcs:
					#print([r1.alpha, r1.alpha_multiplier, toflow])
					r.To.flow -= r1.alpha * r1.alpha_multiplier * toflow
			else:
				r.To.flow = r.To.source_out
				
			if r.From.is_source and r.From.flow < r.From.source_out:
				r.From.flow = r.From.source_out
		
		var i = 0
		for r in Roads:
			var n = r
			if len(n.To.out_arcs) != 0:
				n.To.flow += flow_contrib[i]
			n.current_density += delta_densities[i]
	#		print(str(r) + ":\t" + str(n.current_density))
			i += 1
		
		
	pass
