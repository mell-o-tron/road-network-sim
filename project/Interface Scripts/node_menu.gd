extends Panel

@export var close_button : TextureButton
@export var erase_button : TextureButton
@export var solver  : Node
@export var apply_button : Button
@export var graph : Node

var properties : Array
var height_index = 1

var current_node : Node
var current_road : Node

var bool_panel = preload("res://scenes/bool_panel.tscn")
var numeric_panel = preload("res://scenes/menu_item_numeric.tscn")

func _ready():
	close_button.pressed.connect(self._close_button_pressed)
	erase_button.pressed.connect(self._erase_button_pressed)
	apply_button.pressed.connect(self._apply_button_pressed)
	pass # Replace with function body.

func _close_button_pressed():
	self.visible = false

func _erase_button_pressed():
	if current_node:
		graph.set_monitored(null)
		graph.reset()
		current_node.erase_node()
		clear_properties()
		current_node = null
		
func _apply_button_pressed():
	if solver.paused:
		if current_node:
			var is_source_panel = properties[0]
			var flow_panel = properties[1]
			var source_out_panel = properties[2]
			current_node.is_source = is_source_panel.get_value()
			current_node.flow = flow_panel.get_number()
			current_node.source_out = source_out_panel.get_number()
		elif current_road:
			for i in range(len(current_road.properties)):
				current_road.set_property(i, properties[i].get_number())

func add_property(p):
	p.position.y = height_index * 50
	add_child(p)
	height_index += 1
	properties.append (p)
	
func clear_properties():
	height_index = 1
	for p in properties:
		p.queue_free()
	properties = []
	current_node = null
	current_road = null

func setup_node(node):
	clear_properties()
	var is_source_panel = bool_panel.instantiate()
	is_source_panel.set_label("is source")
	add_property(is_source_panel)
	
	var flow_panel = numeric_panel.instantiate()
	flow_panel.set_label("flow")
	add_property(flow_panel)
	
	var source_out_panel = numeric_panel.instantiate()
	source_out_panel.set_label("source out")
	add_property(source_out_panel)
	
	if node:
		flow_panel.set_number(node.flow)
		is_source_panel.set_value(node.is_source)
		source_out_panel.set_number(node.source_out)
	current_node = node
	
func setup_road(road):
	clear_properties()
	
	for r in road.properties:
		var panel = numeric_panel.instantiate()
		panel.set_label(r[1])
		panel.set_number(r[0])
		add_property(panel)
	
	current_road = road
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !solver.paused:
		if current_node:
			var is_source_panel = properties[0]
			var flow_panel = properties[1]
			#print(current_node.is_source)
			flow_panel.set_number(current_node.flow)
			current_node.is_source = is_source_panel.get_value()
		elif current_road:
			for i in range(len(current_road.properties)):
				properties[i].set_number(current_road.properties[i][0])
		
