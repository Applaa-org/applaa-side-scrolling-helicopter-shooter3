extends Area2D
class_name Collectible

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation: AnimationPlayer = $AnimationPlayer

var type: String = "coin"
var value: int = 10

func _ready():
	body_entered.connect(_on_body_entered)
	animation.play("float")

func _on_body_entered(body: Node):
	if body is Player:
		match type:
			"coin":
				Global.add_score(value)
			"health":
				Global.heal(value)
			"shield":
				Global.add_shield(value)
			"ammo":
				Global.weapon_ammo[Global.current_weapon] += value
		
		# Collection effect
		var collect_effect = preload("res://scenes/CollectEffect.tscn").instantiate()
		get_parent().add_child(collect_effect)
		collect_effect.global_position = global_position
		
		queue_free()