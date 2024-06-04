extends TextureButton

@export var paused_normal : Texture2D
@export var paused_hover : Texture2D
@export var playing_normal : Texture2D
@export var playing_hover : Texture2D
var sim_paused = true

func _ready():
	self.pressed.connect(self._button_pressed)

func _button_pressed():
	if sim_paused:	
		print("unpause")
		self.texture_normal = playing_normal
		self.texture_hover = playing_normal
		sim_paused = false
	else:
		print("pause")
		self.texture_normal = paused_normal
		self.texture_hover = paused_hover
		sim_paused = true
