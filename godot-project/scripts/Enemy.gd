extends CharacterBody2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = 30
var max_health: int = 30
var speed: float = 100.0
var damage: int = 10
var score_value: int = 100
var can_shoot: bool = true
var shoot_cooldown: float = 1.0
var current_shoot_time: float = 0.0

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta: float):
	# Update shoot cooldown
	if current_shoot_time > 0:
		current_shoot_time -= delta
		if current_shoot_time <= 0:
			can_shoot = true
	
	# Enemy-specific behavior
	_update_behavior(delta)

func _update_behavior(delta: float):
	# Basic patrol behavior
	velocity.x = -speed
	move_and_slide()
	
	# Enemy shooting
	if can_shoot and randf() < 0.01:
		shoot()

func shoot():
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = $WeaponPoint.global_position
	bullet.rotation = rotation
	
	can_shoot = false
	current_shoot_time = shoot_cooldown

func take_damage(damage: int):
	health -= damage
	health_bar.value = health
	
	# Flash effect
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if health <= 0:
		die()

func die():
	Global.add_score(score_value)
	# Create explosion effect
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	queue_free()

func _on_body_entered(body: Node):
	if body is Player:
		body.take_damage(damage)
		die()