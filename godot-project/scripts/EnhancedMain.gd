extends Node2D

@onready var player: EnhancedPlayer = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var hud: Control = $HUD
@onready var spawn_timer: Timer = $SpawnTimer
@onready var level_end: Area2D = $LevelEnd
@onready var environment: Node2D = $Environment

var level_data: Dictionary
var scroll_speed: float = 150.0
var enemy_spawn_rate: float = 2.0
var collectible_spawn_rate: float = 3.0
var wave_number: int = 1
var enemies_in_wave: int = 5
var enemies_spawned: int = 0
var boss_spawned: bool = false
var background_elements: Array[Node2D] = []

func _ready():
	Global.score_changed.connect(_on_score_changed)
	Global.health_changed.connect(_on_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	
	# Check if mobile
	Global.is_mobile = OS.get_name() in ["Android", "iOS"] or DisplayServer.screen_get_dpi() > 150
	
	# Setup level
	_setup_level()
	
	# Create environment
	_create_environment()
	
	# Start spawning
	_start_spawning_system()

func _setup_level():
	# Enhanced level data
	match Global.current_level:
		0:
			level_data = {
				"theme": "military",
				"scroll_speed": 150,
				"enemy_rate": 2.0,
				"background_color": Color.GREEN,
				
				"enemy_types": ["Drone", "Tank"],
				"boss": false
			}
		1:
			level_data = {
				"theme": "desert",
				"scroll_speed": 180,
				"enemy_rate": 1.5,
				"background_color": Color.YELLOW,
				"enemy_types": ["Drone", "Tank", "Turret"],
				"boss": false
			}
		2:
			level_data = {
				"theme": "volcano",
				"scroll_speed": 200,
				"enemy_rate": 1.0,
				"background_color": Color.RED,
				"enemy_types": ["Drone", "Tank", "Turret", "EliteDrone"],
				"boss": true
			}
	
	scroll_speed = level_data.scroll_speed
	enemy_spawn_rate = level_data.enemy_rate
	
	# Setup enhanced parallax background
	_setup_enhanced_background()

func _setup_enhanced_background():
	# Create multiple parallax layers for depth
	var bg_layers = [
		{"name": "FarMountains", "speed": 0.2, "color": Color(0.3, 0.3, 0.4)},
		{"name": "NearMountains", "speed": 0.5, "color": Color(0.5, 0.5, 0.6)},
		{"name": "Clouds", "speed": 0.3, "color": Color(1, 1, 1, 0.3)}
	]
	
	for layer_data in bg_layers:
		var layer = ParallaxLayer.new()
		layer.name = layer_data.name
		layer.motion_scale = Vector2(layer_data.speed, 1.0)
		parallax_bg.add_child(layer)
		
		# Create background sprites
		for i in range(5):
			var sprite = Sprite2D.new()
			sprite.position = Vector2(i * 400, randf_range(-100, 100))
			sprite.scale = Vector2(2, 2)
			layer.add_child(sprite)
			background_elements.append(sprite)

func _create_environment():
	# Create destructible environment elements
	var environment_types = ["building", "barrel", "wall", "rock"]
	
	for i in range(20):
		var env_type = environment_types[randi() % environment_types.size()]
		var env_obj = preload("res://scenes/" + env_type.capitalize() + ".tscn").instantiate()
		env_obj.global_position = Vector2(
			randf_range(-500, 2000),
			randf_range(100, 500)
		)
		environment.add_child(env_obj)

func _start_spawning_system():
	# Enemy spawning
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.timeout.connect(_spawn_enemy_wave)
	spawn_timer.start()
	
	# Collectible spawning
	var collectible_timer = Timer.new()
	add_child(collectible_timer)
	collectible_timer.wait_time = collectible_spawn_rate
	collectible_timer.timeout.connect(_spawn_collectible)
	collectible_timer.start()
	
	# Power-up spawning
	var powerup_timer = Timer.new()
	add_child(powerup_timer)
	powerup_timer.wait_time = 8.0
	powerup_timer.timeout.connect(_spawn_powerup)
	powerup_timer.start()

func _spawn_enemy_wave():
	if enemies_spawned >= enemies_in_wave:
		# Check if boss should spawn
		if level_data.boss and not boss_spawned:
			_spawn_boss()
			boss_spawned = true
		else:
			# Start next wave
			wave_number += 1
			enemies_in_wave = 5 + wave_number * 2
			enemies_spawned = 0
		return
	
	# Spawn enemies based on level data
	var enemy_type = level_data.enemy_types[randi() % level_data.enemy_types.size()]
	var enemy_scene = preload("res://scenes/" + enemy_type + ".tscn")
	var enemy = enemy_scene.instantiate()
	
	# Enhanced spawn positioning
	var spawn_x = camera.global_position.x + 600
	var spawn_y = randf_range(100, 500)
	
	# Spawn in formations for higher waves
	if wave_number > 2:
		var formation_type = randi() % 3
		match formation_type:
			0: # Line formation
				spawn_y = 200 + (enemies_spawned % 3) * 100
			1: # V formation
				var offset = (enemies_spawned % 3 - 1) * 80
				spawn_y = 300 + offset
			2: # Random
				spawn_y = randf_range(100, 500)
	
	enemy.global_position = Vector2(spawn_x, spawn_y)
	add_child(enemy)
	enemies_spawned += 1

func _spawn_boss():
	var boss = preload("res://scenes/BossEnemy.tscn").instantiate()
	boss.global_position = Vector2(camera.global_position.x + 800, 300)
	add_child(boss)
	
	# Boss warning effect
	_show_boss_warning()

func _show_boss_warning():
	var warning = preload("res://scenes/BossWarning.tscn").instantiate()
	add_child(warning)
	
	# Screen shake and effects
	var tween = create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.5)

func _spawn_collectible():
	var collectible_types = ["coin", "health", "shield", "ammo"]
	var weights = [50, 20, 15, 15]  # Weighted random selection
	
	var collectible_type = _weighted_random(collectible_types, weights)
	var collectible = preload("res://scenes/Collectible.tscn").instantiate()
	collectible.type = collectible_type
	
	match collectible_type:
		"coin":
			collectible.value = 10
		"health":
			collectible.value = 25
		"shield":
			collectible.value = 30
		"ammo":
			collectible.value = 20
	
	# Enhanced visual setup
	collectible.get_node("Sprite2D").modulate = match collectible_type:
		"coin": Color.YELLOW
		"health": Color.GREEN
		"shield": Color.CYAN
		"ammo": Color.ORANGE
		_: Color.WHITE
	
	collectible.global_position = Vector2(
		camera.global_position.x + 600,
		randf_range(100, 500)
	)
	
	add_child(collectible)

func _spawn_powerup():
	var powerup_types = ["health", "shield", "ammo", "speed", "damage"]
	var rarities = ["common", "common", "rare", "epic", "legendary"]
	var rarity = rarities[randi() % rarities.size()]
	var powerup_type = powerup_types[randi() % powerup_types.size()]
	
	var powerup = preload("res://scenes/PowerUp.tscn").instantiate()
	powerup.type = powerup_type
	powerup.rarity = rarity
	powerup.value = match rarity:
		"common": 25
		"rare": 50
		"epic": 75
		"legendary": 100
		_: 25
	
	powerup.global_position = Vector2(
		camera.global_position.x + 600,
		randf_range(100, 500)
	)
	
	add_child(powerup)

func _weighted_random(items: Array, weights: Array):
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(items.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return items[i]
	
	return items[0]

func _process(delta: float):
	# Enhanced auto-scroll with smooth camera
	camera.position.x += scroll_speed * delta
	parallax_bg.scroll_offset.x += scroll_speed * delta * 0.5
	
	# Dynamic difficulty scaling
	if Global.score > wave_number * 1000:
		enemy_spawn_rate = max(0.5, enemy_spawn_rate - 0.1)
		spawn_timer.wait_time = enemy_spawn_rate
	
	# Keep player in view with smooth boundaries
	var player_bounds = Rect2(
		camera.global_position.x - 300,
		50,
		600,
		500
	)
	
	if player.global_position.x < player_bounds.position.x:
		player.global_position.x = player_bounds.position.x
	elif player.global_position.x > player_bounds.position.x + player_bounds.size.x:
		player.global_position.x = player_bounds.position.x + player_bounds.size.x
	
	if player.global_position.y < player_bounds.position.y:
		player.global_position.y = player_bounds.position.y
	elif player.global_position.y > player_bounds.position.y + player_bounds.size.y:
		player.global_position.y = player_bounds.position.y + player_bounds.size.y

func _on_score_changed(new_score: int):
	hud.get_node("ScoreLabel").text = "Score: %d" % new_score
	
	# Milestone rewards
	if new_score > 0 and new_score % 1000 == 0:
		_spawn_milestone_reward()

func _on_health_changed(new_health: int):
	hud.get_node("HealthBar").value = new_health
	hud.get_node("ArmorBar").value = Global.player_armor
	hud.get_node("ShieldBar").value = Global.player_shield

func _on_weapon_changed(weapon: String):
	hud.get_node("WeaponLabel").text = "Weapon: %s" % weapon.capitalize()
	hud.get_node("AmmoLabel").text = "Ammo: %d" % Global.weapon_ammo[weapon]

func _spawn_milestone_reward():
	# Spawn special reward for milestones
	var reward = preload("res://scenes/PowerUp.tscn").instantiate()
	reward.type = "invincible"
	reward.rarity = "legendary"
	reward.value = 100
	reward.global_position = Vector2(
		camera.global_position.x + 400,
		300
	)
	add_child(reward)
	
	# Show milestone notification
	var notification = preload("res://scenes/MilestoneNotification.tscn").instantiate()
	add_child(notification)

func _on_level_end_body_entered(body: Node):
	if body is EnhancedPlayer:
		# Level complete with bonus score
		var completion_bonus = 1000 * (Global.current_level + 1)
		Global.add_score(completion_bonus)
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")