extends Control

@onready var health_bar: ProgressBar = $TopPanel/HBoxContainer/HealthBar
@onready var armor_bar: ProgressBar = $TopPanel/HBoxContainer/ArmorBar
@onready var shield_bar: ProgressBar = $TopPanel/HBoxContainer/ShieldBar
@onready var boost_bar: ProgressBar = $TopPanel/HBoxContainer/BoostBar
@onready var score_label: Label = $TopPanel/HBoxContainer/ScoreLabel
@onready var weapon_label: Label = $TopPanel/HBoxContainer/WeaponLabel
@onready var ammo_label: Label = $TopPanel/HBoxContainer/AmmoLabel
@onready var combo_label: Label = $TopPanel/HBoxContainer/ComboLabel
@onready var level_label: Label = $TopPanel/HBoxContainer/LevelLabel

@onready var weapon_icons: HBoxContainer = $WeaponPanel/WeaponIcons
@onready var minimap: TextureRect = $MinimapPanel/Minimap
@onready var crosshair: TextureRect = $Crosshair

var weapon_icons_dict: Dictionary = {}

func _ready():
	Global.score_changed.connect(_on_score_changed)
	Global.health_changed.connect(_on_health_changed)
	Global.weapon_changed.connect(_on_weapon_changed)
	
	# Setup weapon icons
	_setup_weapon_icons()
	
	# Setup animations
	_setup_animations()
	
	# Initialize UI
	_update_all_ui()

func _setup_weapon_icons():
	var weapons = ["minigun", "rocket", "spread", "laser", "flamethrower"]
	var colors = {
		"minigun": Color.YELLOW,
		"rocket": Color.RED,
		"spread": Color.ORANGE,
		"laser": Color.CYAN,
		"flamethrower": Color.MAGENTA
	}
	
	for weapon in weapons:
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.modulate = colors[weapon]
		icon.name = weapon.capitalize()
		weapon_icons.add_child(icon)
		weapon_icons_dict[weapon] = icon

func _setup_animations():
	# Health bar pulse animation
	var health_tween = create_tween()
	health_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.5)
	health_tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 0.8), 0.5)
	health_tween.set_loops()

func _on_score_changed(new_score: int):
	score_label.text = "Score: %d" % new_score
	# Score popup animation
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_health_changed(new_health: int):
	health_bar.value = new_health
	armor_bar.value = Global.player_armor
	shield_bar.value = Global.player_shield
	
	# Health warning animation
	if new_health <= 20:
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color.RED, 0.2)
		tween.tween_property(health_bar, "modulate", Color.WHITE, 0.2)
		tween.set_loops()

func _on_weapon_changed(weapon: String):
	weapon_label.text = "Weapon: %s" % weapon.capitalize()
	ammo_label.text = "Ammo: %d" % Global.weapon_ammo[weapon]
	
	# Highlight active weapon icon
	for w in weapon_icons_dict:
		if w == weapon:
			weapon_icons_dict[w].modulate.a = 1.0
			weapon_icons_dict[w].scale = Vector2(1.2, 1.2)
		else:
			weapon_icons_dict[w].modulate.a = 0.5
			weapon_icons_dict[w].scale = Vector2(1.0, 1.0)

func _update_all_ui():
	_on_score_changed(Global.score)
	_on_health_changed(Global.player_health)
	_on_weapon_changed(Global.current_weapon)
	level_label.text = "Level: %d" % (Global.current_level + 1)

func _process(delta: float):
	# Update boost bar
	var player = get_tree().get_first_node_in_group("player")
	if player:
		boost_bar.value = player.boost_energy
	
	# Update combo display
	if player and player.combo_count > 0:
		combo_label.text = "Combo x%d" % player.combo_count
		combo_label.visible = true
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		combo_label.visible = false
	
	# Update crosshair position
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		crosshair.global_position = get_global_mouse_position()
		crosshair.visible = true
	else:
		crosshair.visible = false