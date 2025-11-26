extends CharacterBody2D
class_name SmartEnemy

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var weapon_point: Marker2D = $WeaponPoint

var health: int = 30
var max_health: int = 30
var speed: float = 100.0
var damage: int = 10
var score_value: int = 100
var can_shoot: bool = true
var shoot_cooldown: float = 1.0
var current_shoot_time: float = 0.0
var detection_range: float = 300.0
var attack_range: float = 200.0
var state: String = "patrol"
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var player: EnhancedPlayer
var dodge_cooldown: float = 0.0

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	player = get_tree().get_first_node_in_group("player")
	
	# Generate patrol points
	_generate_patrol_points()

func _generate_patrol_points():
	var base_pos = global_position
	for i in range(3):
		var offset = Vector2(randf_range(-100, 100), randf_range(-50, 50))
		patrol_points.append(base_pos + offset)

func _physics_process(delta: float):
	# Update cooldowns
	if current_shoot_time > 0:
		current_shoot_time -= delta
		if current_shoot_time <= 0:
			can_shoot = true
	
	if dodge_cooldown > 0:
		dodge_cooldown -= delta
	
	# State machine
	match state:
		"patrol":
			_patrol_state(delta)
		"chase":
			_chase_state(delta)
		"attack":
			_attack_state(delta)
		"dodge":
			_dodge_state(delta)
		"retreat":
			_retreat_state(delta)

func _patrol_state(delta: float):
	if patrol_points.is_empty():
		return
	
	var target_point = patrol_points[current_patrol_index]
	var direction = (target_point - global_position).normalized()
	
	if global_position.distance_to(target_point) < 20:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	
	velocity = direction * speed * 0.5
	move_and_slide()
	
	# Check for player
	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chase"

func _chase_state(delta: float):
	if not player:
		state = "patrol"
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Look at player
	look_at(player.global_position)
	
	# Check attack range
	if global_position.distance_to(player.global_position) < attack_range:
		state = "attack"
	
	# Check if player is too far
	if global_position.distance_to(player.global_position) > detection_range * 1.5:
		state = "patrol"

func _attack_state(delta: float):
	if not player:
		state = "patrol"
		return
	
	# Keep distance but face player
	var direction = (player.global_position - global_position).normalized()
	look_at(player.global_position)
	
	# Move sideways to dodge
	var dodge_dir = Vector2(-direction.y, direction.x)
	velocity = dodge_dir * speed * 0.3
	move_and_slide()
	
	# Shoot at player
	if can_shoot:
		shoot()
	
	# Check if player is out of range
	if global_position.distance_to(player.global_position) > attack_range * 1.2:
		state = "chase"
	
	# Dodge incoming projectiles
	if dodge_cooldown <= 0:
		_check_projectiles()

func _dodge_state(delta: float):
	# Quick dodge movement
	var dodge_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity = dodge_dir * speed * 2.0
	move_and_slide()
	
	await get_tree().create_timer(0.3).timeout
	state = "chase"

func _retreat_state(delta: float):
	if not player:
		state = "patrol"
		return
	
	# Move away from player
	var direction = (global_position - player.global_position).normalized()
	velocity = direction * speed * 1.5
	move_and_slide()
	
	# Check if safe distance
	if global_position.distance_to(player.global_position) > detection_range:
		state = "patrol"

func shoot():
	var bullet = preload("res://scenes/SmartBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = weapon_point.global_position
	bullet.rotation = rotation
	bullet.target = player
	
	can_shoot = false
	current_shoot_time = shoot_cooldown

func _check_projectiles():
	var projectiles = get_tree().get_nodes_in_group("projectile")
	for projectile in projectiles:
		if projectile.is_player_projectile:
			var distance = global_position.distance_to(projectile.global_position)
			var future_pos = projectile.global_position + projectile.velocity * 0.5
			var future_distance = global_position.distance_to(future_pos)
			
			if future_distance < 50 and distance < 100:
				state = "dodge"
				dodge_cooldown = 2.0
				break

func take_damage(damage: int):
	health -= damage
	health_bar.value = health
	
	# Enhanced damage feedback
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Knockback
	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 200
	move_and_slide()
	
	# State change on damage
	if health <= max_health * 0.5:
		state = "retreat"
		dodge_cooldown = 1.0
	
	if health <= 0:
		die()

func die():
	Global.add_score(score_value)
	
	# Enhanced explosion
	var explosion = preload("res://scenes/BigExplosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# Drop power-up chance
	if randf() < 0.3:  # 30% chance
		_drop_powerup()
	
	queue_free()

func _drop_powerup():
	var powerup_types = ["health", "shield", "ammo"]
	var powerup_type = powerup_types[randi() % powerup_types.size()]
	
	var powerup = preload("res://scenes/PowerUp.tscn").instantiate()
	powerup.type = powerup_type
	powerup.global_position = global_position
	get_parent().add_child(powerup)