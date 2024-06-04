extends Node

var mode = 1

func get_value ():
	if mode == 0:
		return get_parent().agent_flow
	else:
		if get_parent().ode_solver.sim_time == 0:
			return 0
		return get_parent().num_cars / get_parent().ode_solver.sim_time
