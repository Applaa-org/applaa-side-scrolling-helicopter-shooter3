extends CharacterBody2D
class_name BossEnemy

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_point_1: Marker2D = $WeaponPoint1
@onready var weapon_point_2: Marker2D = $WeaponPoint2
@onready var weapon_point_3: Marker2D = $WeaponPoint3

var health: int = 500
var max_health: int = 500
var speed: float = 80.0
var damage: int = 30
var score_value: int = 1000
var phase: int = 1
var attack_pattern: String = "circle"
var pattern_timer: float = 0.0
var player: EnhancedPlayer

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	player = get_tree().get_first_node_in_group("player")
	
	# Start attack patterns
	_start_attack_patterns()

func _start_attack_patterns():
	var pattern_timer = Timer.new()
	add_child(pattern_timer)
	pattern_timer.wait_time = 3.0
	pattern_timer.timeout.connect(_change_attack_pattern)
	pattern_timer.start()

func _change_attack_pattern():
	var patterns = ["circle", "spiral", "burst", "laser"]
	attack_pattern = patterns[randi() % patterns.size()]
	pattern_timer = 0.0

func _physics_process(delta: float):
	# Update phase based on health
	if health <= max_health * 0.33 and phase != 3:
		phase = 3
		speed = 120.0
	elif health <= max_health * 0.66 and phase != 2:
		phase = 2
		speed = 100.0
	
	# Movement pattern
	_boss_movement(delta)
	
	# Attack patterns
	pattern_timer += delta
	_execute_attack_pattern(delta)

func _boss_movement(delta: float):
	if not player:
		return
	
	# Sinusoidal movement
	var time = Time.get_time_dict_from_system().second
	var offset = Vector2(sin(time * 2.0) * 100, cos(time * 1.5) * 50)
	var target_pos = player.global_position + offset + Vector2(200, 0)
	
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Face player
	look_at(player.global_position)

func _execute_attack_pattern(delta: float):
	match attack_pattern:
		"circle":
			if pattern_timer > 0.5:
				_circle_attack()
				pattern_timer = 0.0
		"spiral":
			if pattern_timer > 0.2:
				_spiral_attack()
				pattern_timer = 0.0
		"burst":
			if pattern_timer > 1.0:
				_burst_attack()
				pattern_timer = 0.0
		"laser":
			if pattern_timer > 2.0:
				_laser_attack()
				pattern_timer = 0.0

func _circle_attack():
	for i in range(8):
		var bullet = preload("res://scenes/BossBullet.tscn").instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.rotation = deg_to_rad(i * 45)
		bullet.speed = 200.0

func _spiral_attack():
	var angle = pattern_timer * 100
	var bullet = preload("res://scenes/BossBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = deg_to_rad(angle)
	bullet.speed = 300.0

func _burst_attack():
	var weapon_points = [weapon_point_1, weapon_point_2, weapon_point_3]
	for point in weapon_points:
		var rocket = preload("res://scenes/HomingRocket.tscn").instantiate()
		get_parent().add_child(rocket)
		rocket.global_position = point.global_position
		rocket.target = player
		rocket.is_player_projectile = false

func _laser_attack():
	var laser = preload("res://scenes/BossLaser.tscn").instantiate()
	get_parent().add_child(laser)
	laser.global_position = weapon_point_2.global_position
	laser.rotation = rotation

func take_damage(damage: int):
	health -= damage
	health_bar.value = health
	
	# Screen shake on hit
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.1)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
	
	# Flash effect
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if health <= 0:
		die()

func die():
	Global.add_score(score_value)
	
	# Massive explosion
	var explosion = preload("res://scenes/MegaExplosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# Victory trigger
	get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	
	queue_free()