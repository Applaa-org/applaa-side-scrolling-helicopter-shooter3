extends Enemy

var patrol_direction: Vector2 = Vector2.LEFT
var patrol_timer: float = 0.0
var patrol_duration: float = 2.0

func _ready():
	super._ready()
	health = 20
	max_health = 20
	speed = 100
	damage = 10
	score_value = 100

func _update_behavior(delta: float):
	patrol_timer += delta
	
	if patrol_timer >= patrol_duration:
		patrol_direction = -patrol_direction
		patrol_timer = 0.0
	
	velocity = patrol_direction * speed
	move_and_slide()
	
	# Shoot at player if in range
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 200:
		look_at(player.global_position)
		if can_shoot:
			shoot()

func shoot():
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = $WeaponPoint.global_position
	bullet.rotation = rotation
	
	can_shoot = false
	current_shoot_time = shoot_cooldown