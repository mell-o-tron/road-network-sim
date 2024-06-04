extends Node

@export var line : Line2D
@export var edge : float
@export var monitored_obj : Node
@export var max_height : float
@export var graph_button : TextureButton
@export var max_label : Label
@export var graph_name_label : Label
@export var graph_name : String
@export var solver : Node
@export var value_label : Label
@export var dump_button : Button
var max_value = 1

var t = 0
var j = 1
var values = []

func set_monitored (obj):
	monitored_obj = obj

func reset():
	t = 0
	j = 1
	values = []
	line.points = []

func set_max_value(v):
	max_value = v
	max_label.text = str(v)

# Called when the node enters the scene tree for the first time.
func _ready():
	graph_name_label.text = graph_name
	graph_button.pressed.connect(self._graph_button_pressed)
	dump_button.pressed.connect(self._dump_button_pressed)
	pass # Replace with function body.

func _graph_button_pressed():
	self.visible = !self.visible

func _dump_button_pressed():
	if is_instance_valid(monitored_obj):
		var dump_file = FileAccess.open("res://" + monitored_obj.name + str(Time.get_time_string_from_system()) +  ".dump", FileAccess.WRITE)
		var json_string = JSON.stringify(values)
		dump_file.store_line(json_string)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(monitored_obj) and not solver.paused:
		var current_value = monitored_obj.get_value()
		value_label.text = str(snappedf(current_value, 0.001))
		values.append(current_value)
		
		if current_value > max_value:
			max_value = current_value
			max_label.text = str(max_value)
		
		for i in range(len(line.points)):
			line.points[i].x = (i * edge) / j
			line.points[i].y = -values [i] * (max_height / max_value)
		
		line.add_point(Vector2(edge, -current_value * (max_height / max_value)))
		value_label.position.y = -current_value * (max_height / max_value) + line.position.y
		t += delta
		j += 1
	elif not is_instance_valid(monitored_obj):
		monitored_obj = null
		t = 0
		j = 1
		values = []
