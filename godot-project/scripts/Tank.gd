extends Enemy

var target: Vector2

func _ready():
	super._ready()
	health = 50
	max_health = 50
	speed = 0
	damage = 20
	score_value = 200

func _update_behavior(delta: float):
	# Tank is stationary but rotates to aim at player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		look_at(player.global_position)
		if can_shoot and global_position.distance_to(player.global_position) < 300:
			shoot()

func shoot():
	var rocket = preload("res://scenes/EnemyRocket.tscn").instantiate()
	get_parent().add_child(rocket)
	rocket.global_position = $WeaponPoint.global_position
	rocket.rotation = rotation
	
	can_shoot = false
	current_shoot_time = 2.0