extends Area2D
class_name Projectile

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var speed: float = 500.0
var damage: int = 10
var lifetime: float = 3.0
var is_player_projectile: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float):
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	global_position += velocity * delta

func _on_body_entered(body: Node):
	if is_player_projectile and body is Enemy:
		body.take_damage(damage)
		queue_free()
	elif not is_player_projectile and body is Player:
		body.take_damage(damage)
		queue_free()