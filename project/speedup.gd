extends TextureButton

@export var speedup = 2.0

var active = false
# Called when the node enters the scene tree for the first time.
func _ready():
	self.pressed.connect(self._speedup_pressed)
	pass # Replace with function body.

func _speedup_pressed():
	active = not active
	Engine.time_scale = speedup if active else 1.0
