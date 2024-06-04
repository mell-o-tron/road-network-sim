extends Node

var tot = 0
var nframes = 0
func get_value ():
	#print([tot, nframes])
	if (not get_parent().solver.paused):
		nframes += 1
		tot += (get_parent().cur_num_cars / get_parent().road_length)
		return tot / nframes
	return tot / nframes if nframes > 0 else 0
