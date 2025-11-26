extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var hud: Control = $HUD
@onready var spawn_timer: Timer = $SpawnTimer
@onready var level_end: Area2D = $LevelEnd

var level_data: Dictionary
var scroll_speed: float = 150.0
var enemy_spawn_rate: float = 2.0
var collectible_spawn_rate: float = 3.0
var enemies_spawned: int = 0
var max_enemies: int = 10
var level_distance: float = 0.0
var level_complete: bool = false

func _ready():
	Global.score_changed.connect(_on_score_changed)
	Global.health_changed.connect(_on_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	
	# Check if mobile
	Global.is_mobile = OS.get_name() in ["Android", "iOS"] or DisplayServer.screen_get_dpi() > 150
	
	# Setup level
	_setup_level()
	
	# Start spawning
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()
	
	# Start collectible spawning
	var collectible_timer = Timer.new()
	add_child(collectible_timer)
	collectible_timer.wait_time = collectible_spawn_rate
	collectible_timer.timeout.connect(_spawn_collectible)
	collectible_timer.start()

func _setup_level():
	# Load level data based on current level
	match Global.current_level:
		0:
			level_data = {"theme": "military", "scroll_speed": 150, "enemy_rate": 2.0, "enemy_types": ["Drone"], "boss": false, "target_score": 500}
		1:
			level_data = {"theme": "desert", "scroll_speed": 180, "enemy_rate": 1.5, "enemy_types": ["Drone", "Tank"], "boss": false, "target_score": 1000}
		2:
			level_data = {"theme": "volcano", "scroll_speed": 200, "enemy_rate": 1.0, "enemy_types": ["Drone", "Tank", "Turret"], "boss": true, "target_score": 2000}
		3:
			level_data = {"theme": "arctic", "scroll_speed": 160, "enemy_rate": 1.8, "enemy_types": ["Drone", "Tank", "Turret"], "boss": false, "target_score": 2500}
		4:
			level_data = {"theme": "cyber", "scroll_speed": 200, "enemy_rate": 1.5, "enemy_types": ["Drone", "Tank", "Turret"], "boss": true, "target_score": 3500}
		5:
			level_data = {"theme": "jungle", "scroll_speed": 140, "enemy_rate": 1.3, "enemy_types": ["Drone", "Tank", "Turret"], "boss": false, "target_score": 4000}
		6:
			level_data = {"theme": "ocean", "scroll_speed": 170, "enemy_rate": 1.2, "enemy_types": ["Drone", "Tank", "Turret"], "boss": true, "target_score": 5000}
		7:
			level_data = {"theme": "underground", "scroll_speed": 130, "enemy_rate": 1.0, "enemy_types": ["Drone", "Tank", "Turret"], "boss": false, "target_score": 6000}
		8:
			level_data = {"theme": "sky", "scroll_speed": 220, "enemy_rate": 0.8, "enemy_types": ["Drone", "Tank", "Turret"], "boss": true, "target_score": 8000}
		9:
			level_data = {"theme": "alien", "scroll_speed": 250, "enemy_rate": 0.5, "enemy_types": ["Drone", "Tank", "Turret"], "boss": true, "target_score": 10000}
		_:
			level_data = {"theme": "military", "scroll_speed": 150, "enemy_rate": 2.0, "enemy_types": ["Drone"], "boss": false, "target_score": 500}
	
	scroll_speed = level_data.scroll_speed
	enemy_spawn_rate = level_data.enemy_rate
	
	# Setup parallax background
	_setup_background()

func _setup_background():
	# Create parallax layers based on theme
	match level_data.theme:
		"military":
			parallax_bg.modulate = Color.GREEN
		"desert":
			parallax_bg.modulate = Color.YELLOW
		"volcano":
			parallax_bg.modulate = Color.RED
		"arctic":
			parallax_bg.modulate = Color.CYAN
		"cyber":
			parallax_bg.modulate = Color.MAGENTA
		"jungle":
			parallax_bg.modulate = Color(0.1, 0.4, 0.1)
		"ocean":
			parallax_bg.modulate = Color.BLUE
		"underground":
			parallax_bg.modulate = Color(0.3, 0.2, 0.1)
		"sky":
			parallax_bg.modulate = Color(0.5, 0.7, 0.9)
		"alien":
			parallax_bg.modulate = Color(0.3, 0.0, 0.4)

func _process(delta: float):
	# Auto-scroll the level
	camera.position.x += scroll_speed * delta
	parallax_bg.scroll_offset.x += scroll_speed * delta * 0.5
	
	# Track level distance
	level_distance += scroll_speed * delta
	
	# Keep player in view
	if player.global_position.x < camera.global_position.x - 200:
		player.global_position.x = camera.global_position.x - 200
	if player.global_position.x > camera.global_position.x + 200:
		player.global_position.x = camera.global_position.x + 200
	
	# Check level completion
	if level_distance >= 3000 and not level_complete:
		level_complete = true
		_on_level_complete()

func _spawn_enemy():
	if level_complete or enemies_spawned >= max_enemies:
		return
	
	var enemy_type = level_data.enemy_types[randi() % level_data.enemy_types.size()]
	var enemy_scene = preload("res://scenes/" + enemy_type + ".tscn")
	var enemy = enemy_scene.instantiate()
	
	# Spawn ahead of player
	enemy.global_position = Vector2(
		camera.global_position.x + 600,
		randf_range(100, 500)
	)
	
	add_child(enemy)
	enemies_spawned += 1

func _spawn_collectible():
	if level_complete:
		return
	
	var collectible_types = ["coin", "health", "shield", "ammo"]
	var collectible_type = collectible_types[randi() % collectible_types.size()]
	
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
	
	# Set sprite based on type
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

func _on_score_changed(new_score: int):
	hud.get_node("ScoreLabel").text = "Score: %d" % new_score

func _on_health_changed(new_health: int):
	hud.get_node("HealthBar").value = new_health
	hud.get_node("ArmorBar").value = Global.player_armor
	hud.get_node("ShieldBar").value = Global.player_shield

func _on_weapon_changed(weapon: String):
	hud.get_node("WeaponLabel").text = "Weapon: %s" % weapon.capitalize()
	hud.get_node("AmmoLabel").text = "Ammo: %d" % Global.weapon_ammo[weapon]

func _on_level_complete():
	# Level complete with bonus score
	var completion_bonus = level_data.target_score
	Global.add_score(completion_bonus)
	
	# Check if it's the last level
	if Global.current_level >= 9:
		# Game complete!
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		# Move to next level
		Global.current_level += 1
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_level_end_body_entered(body: Node):
	if body is Player and not level_complete:
		level_complete = true
		_on_level_complete()