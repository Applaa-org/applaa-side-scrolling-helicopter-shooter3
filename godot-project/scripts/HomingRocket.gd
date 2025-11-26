extends Area2D
class_name HomingRocket

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var trail: CPUParticles2D = $Trail

var speed: float = 300.0
var damage: int = 50
var lifetime: float = 5.0
var is_player_projectile: bool = true
var target: Node = null
var turn_speed: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)
	trail.emitting = true
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float):
	# Homing behavior
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		var target_angle = direction.angle()
		var angle_diff = target_angle - rotation
		
		# Normalize angle difference
		while angle_diff > PI:
			angle_diff -= 2 * PI
		while angle_diff < -PI:
			angle_diff += 2 * PI
		
		# Turn towards target
		rotation += angle_diff * turn_speed * delta
	
	# Move forward
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	global_position += velocity * delta

func _on_body_entered(body: Node):
	if is_player_projectile and body is SmartEnemy:
		body.take_damage(damage)
		_create_explosion()
		queue_free()
	elif not is_player_projectile and body is EnhancedPlayer:
		body.take_damage(damage)
		_create_explosion()
		queue_free()

func _create_explosion():
	var explosion = preload("res://scenes/SmallExplosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position