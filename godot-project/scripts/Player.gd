extends CharacterBody2D
class_name Player

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var weapon_point: Marker2D = $WeaponPoint

const SPEED: float = 300.0
const GRAVITY: float = 200.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_shoot: bool = true
var shoot_cooldown: float = 0.1
var current_shoot_time: float = 0.0

func _ready():
	Global.health_changed.connect(_on_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)

func _physics_process(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle movement
	var direction := Vector2.ZERO
	
	# Desktop controls
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y = -1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y = 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x = -1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x = 1
	
	# Apply movement
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()
	
	# Handle shooting
	if Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot()
	
	# Weapon switching
	if Input.is_key_pressed(KEY_1):
		Global.switch_weapon("minigun")
	if Input.is_key_pressed(KEY_2):
		Global.switch_weapon("rocket")
	if Input.is_key_pressed(KEY_3):
		Global.switch_weapon("spread")
	
	# Update shoot cooldown
	if current_shoot_time > 0:
		current_shoot_time -= delta
		if current_shoot_time <= 0:
			can_shoot = true

func shoot():
	if not can_shoot:
		return
	
	var ammo_cost = 1
	if Global.current_weapon == "rocket":
		ammo_cost = 1
	elif Global.current_weapon == "spread":
		ammo_cost = 2
	
	if Global.weapon_ammo[Global.current_weapon] < ammo_cost:
		return
	
	Global.use_ammo(Global.current_weapon, ammo_cost)
	can_shoot = false
	current_shoot_time = shoot_cooldown
	
	match Global.current_weapon:
		"minigun":
			_shoot_minigun()
		"rocket":
			_shoot_rocket()
		"spread":
			_shoot_spread()

func _shoot_minigun():
	var bullet = preload("res://scenes/MinigunBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = weapon_point.global_position
	bullet.rotation = rotation

func _shoot_rocket():
	var rocket = preload("res://scenes/Rocket.tscn").instantiate()
	get_parent().add_child(rocket)
	rocket.global_position = weapon_point.global_position
	rocket.rotation = rotation

func _shoot_spread():
	for i in range(3):
		var bullet = preload("res://scenes/SpreadBullet.tscn").instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = weapon_point.global_position
		bullet.rotation = rotation + deg_to_rad((i - 1) * 15)

func _on_health_changed(new_health: int):
	# Update visual feedback
	if new_health <= 30:
		sprite.modulate = Color.RED
	elif new_health <= 60:
		sprite.modulate = Color.ORANGE
	else:
		sprite.modulate = Color.WHITE

func _on_weapon_changed(weapon: String):
	# Update weapon visuals
	match weapon:
		"minigun":
			shoot_cooldown = 0.05
		"rocket":
			shoot_cooldown = 0.3
		"spread":
			shoot_cooldown = 0.15

func take_damage(damage: int):
	Global.take_damage(damage)