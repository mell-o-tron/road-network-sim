extends Node

@export var label : Label
@export var number : SpinBox

func set_number (n):
	number.value = n
	
func get_number ():
	return number.value

func set_label (s):
	label.text = s
