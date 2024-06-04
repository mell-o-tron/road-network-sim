extends Node

@export var label : Label
@export var button : CheckButton

func set_value (b):
	button.set_pressed_no_signal(b)

func get_value ():
	return button.button_pressed

func set_label (s):
	label.text = s
