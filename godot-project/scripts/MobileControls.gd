extends Control

@onready var joystick: TextureRect = $Joystick/JoystickBG
@onready var joystick_knob: TextureRect = $Joystick/JoystickKnob
@onready var fire_button: Button = $FireButton
@onready var weapon_button: Button = $WeaponButton
@onready var shield_button: Button = $ShieldButton

var joystick_active: bool = false
var joystick_center: Vector2
var joystick_radius: float = 50.0

func _ready():
	# Only show on mobile
	visible = Global.is_mobile
	
	if Global.is_mobile:
		# Connect button signals
		fire_button.pressed.connect(_on_fire_pressed)
		fire_button.released.connect(_on_fire_released)
		weapon_button.pressed.connect(_on_weapon_pressed)
		shield_button.pressed.connect(_on_shield_pressed)
		
		# Connect joystick signals
		joystick.gui_input.connect(_on_joystick_input)

func _on_joystick_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			joystick_active = true
			joystick_center = event.position
			joystick_knob.global_position = event.position
		else:
			joystick_active = false
			joystick_knob.position = joystick.size / 2
	
	elif event is InputEventScreenDrag and joystick_active:
		var direction = event.position - joystick_center
		var distance = min(direction.length(), joystick_radius)
		var normalized_dir = direction.normalized()
		
		joystick_knob.global_position = joystick_center + normalized_dir * distance
		
		# Apply movement to player
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.velocity = normalized_dir * player.SPEED

func _on_fire_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.shoot()

func _on_fire_released():
	pass

func _on_weapon_pressed():
	# Cycle through weapons
	var weapons = ["minigun", "rocket", "spread"]
	var current_index = weapons.find(Global.current_weapon)
	var next_index = (current_index + 1) % weapons.size()
	Global.switch_weapon(weapons[next_index])

func _on_shield_pressed():
	Global.add_shield(50)