extends CharacterBody2D
class_name EnhancedPlayer

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var weapon_point: Marker2D = $WeaponPoint
@onready var shield_sprite: Sprite2D = $Shield
@onready var engine_particles: CPUParticles2D = $EngineParticles
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var aim_line: Line2D = $AimLine

const SPEED: float = 400.0
const BOOST_SPEED: float = 600.0
const GRAVITY: float = 100.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_shoot: bool = true
var shoot_cooldown: float = 0.1
var current_shoot_time: float = 0.0
var auto_target: bool = true
var nearest_enemy: Enemy = null
var boost_energy: float = 100.0
var combo_count: int = 0
var combo_timer: float = 0.0

func _ready():
	Global.health_changed.connect(_on_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	shield_sprite.visible = false
	aim_line.visible = false

func _physics_process(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle movement with boost
	var direction := Vector2.ZERO
	var current_speed = SPEED
	
	# Boost with Shift key
	if Input.is_key_pressed(KEY_SHIFT) and boost_energy > 0:
		current_speed = BOOST_SPEED
		boost_energy -= delta * 20
		# Boost particles
		engine_particles.emission = 200
		trail_particles.emitting = true
	else:
		boost_energy = min(100.0, boost_energy + delta * 10)
		engine_particles.emission = 50
		trail_particles.emitting = false
	
	# Desktop controls - 8-directional movement
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y = -1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y = 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x = -1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x = 1
	
	# Diagonal movement normalization
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.y = move_toward(velocity.y, 0, current_speed)
	
	move_and_slide()
	
	# Find nearest enemy for auto-targeting
	if auto_target:
		_find_nearest_enemy()
	
	# Handle shooting with auto-targeting
	if Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_auto_shoot()
	
	# Show aim line when targeting
	if nearest_enemy and auto_target:
		aim_line.visible = true
		aim_line.points = [weapon_point.global_position, nearest_enemy.global_position]
	else:
		aim_line.visible = false
	
	# Weapon switching
	if Input.is_key_pressed(KEY_1):
		Global.switch_weapon("minigun")
	if Input.is_key_pressed(KEY_2):
		Global.switch_weapon("rocket")
	if Input.is_key_pressed(KEY_3):
		Global.switch_weapon("spread")
	if Input.is_key_pressed(KEY_4):
		Global.switch_weapon("laser")
	if Input.is_key_pressed(KEY_5):
		Global.switch_weapon("flamethrower")
	
	# Special abilities
	if Input.is_key_pressed(KEY_Q):
		_activate_shield()
	if Input.is_key_pressed(KEY_E):
		_airstrike()
	
	# Update shoot cooldown
	if current_shoot_time > 0:
		current_shoot_time -= delta
		if current_shoot_time <= 0:
			can_shoot = true
	
	# Update combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

func _find_nearest_enemy():
	nearest_enemy = null
	var min_distance = 500.0  # Max targeting range
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

func _auto_shoot():
	if not can_shoot:
		return
	
	# Rotate towards nearest enemy
	if nearest_enemy:
		var angle_to_enemy = global_position.angle_to_point(nearest_enemy.global_position)
		rotation = angle_to_enemy
	
	var ammo_cost = 1
	match Global.current_weapon:
		"rocket":
			ammo_cost = 1
		"spread":
			ammo_cost = 2
		"laser":
			ammo_cost = 3
		"flamethrower":
			ammo_cost = 1
	
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
		"laser":
			_shoot_laser()
		"flamethrower":
			_shoot_flamethrower()

func _shoot_minigun():
	var bullet = preload("res://scenes/MinigunBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = weapon_point.global_position
	bullet.rotation = rotation
	bullet.damage = 15

func _shoot_rocket():
	var rocket = preload("res://scenes/HomingRocket.tscn").instantiate()
	get_parent().add_child(rocket)
	rocket.global_position = weapon_point.global_position
	rocket.rotation = rotation
	if nearest_enemy:
		rocket.target = nearest_enemy

func _shoot_spread():
	for i in range(5):
		var bullet = preload("res://scenes/SpreadBullet.tscn").instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = weapon_point.global_position
		bullet.rotation = rotation + deg_to_rad((i - 2) * 12)

func _shoot_laser():
	var laser = preload("res://scenes/LaserBeam.tscn").instantiate()
	get_parent().add_child(laser)
	laser.global_position = weapon_point.global_position
	laser.rotation = rotation

func _shoot_flamethrower():
	var flame = preload("res://scenes/Flame.tscn").instantiate()
	get_parent().add_child(flame)
	flame.global_position = weapon_point.global_position
	flame.rotation = rotation

func _activate_shield():
	if Global.player_shield <= 0:
		Global.add_shield(100)
		# Shield activation effect
		var tween = create_tween()
		shield_sprite.modulate = Color.CYAN
		tween.tween_property(shield_sprite, "modulate", Color(0.5, 0.8, 1, 0.5), 0.5)

func _airstrike():
	# Call airstrike from above
	var airstrike = preload("res://scenes/Airstrike.tscn").instantiate()
	get_parent().add_child(airstrike)
	airstrike.global_position = Vector2(global_position.x, -100)

func _on_health_changed(new_health: int):
	# Enhanced visual feedback
	if new_health <= 20:
		sprite.modulate = Color.RED
		# Critical damage screen shake
		var tween = create_tween()
		tween.tween_property(self, "position", position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.1)
		tween.tween_property(self, "position", position, 0.1)
	elif new_health <= 50:
		sprite.modulate = Color.ORANGE
	else:
		sprite.modulate = Color.WHITE
	
	# Update shield visibility with pulse effect
	if Global.player_shield > 0:
		shield_sprite.visible = true
		var tween = create_tween()
		tween.tween_property(shield_sprite, "modulate:a", 0.8, 0.5)
		tween.tween_property(shield_sprite, "modulate:a", 0.3, 0.5)
		tween.set_loops()
	else:
		shield_sprite.visible = false

func _on_weapon_changed(weapon: String):
	# Update weapon stats
	match weapon:
		"minigun":
			shoot_cooldown = 0.05
		"rocket":
			shoot_cooldown = 0.3
		"spread":
			shoot_cooldown = 0.15
		"laser":
			shoot_cooldown = 0.1
		"flamethrower":
			shoot_cooldown = 0.02

func take_damage(damage: int):
	Global.take_damage(damage)
	# Enhanced screen shake
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.15)
	tween.tween_property(self, "position", position, 0.15)
	
	# Damage particles
	var damage_particles = CPUParticles2D.new()
	add_child(damage_particles)
	damage_particles.position = Vector2(0, 0)
	damage_particles.amount = 20
	damage_particles.lifetime = 0.5
	damage_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	damage_particles.emission_sphere_radius = 20.0
	damage_particles.direction = Vector2(0, -1)
	damage_particles.spread = 180.0
	damage_particles.initial_velocity_min = 50.0
	damage_particles.initial_velocity_max = 150.0
	damage_particles.color = Color.RED
	damage_particles.emitting = true
	
	await get_tree().create_timer(0.5).timeout
	damage_particles.queue_free()

func add_combo():
	combo_count += 1
	combo_timer = 2.0
	Global.add_score(50 * combo_count)