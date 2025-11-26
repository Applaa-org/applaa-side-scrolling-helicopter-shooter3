extends Node

signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal weapon_changed(weapon: String)

var score: int = 0
var player_health: int = 100
var player_max_health: int = 100
var player_armor: int = 50
var player_shield: int = 0
var current_weapon: String = "minigun"
var weapon_ammo: Dictionary = {
	"minigun": 999,
	"rocket": 50,
	"spread": 100
}
var current_level: int = 0
var is_mobile: bool = false

func add_score(points: int):
	score += points
	score_changed.emit(score)

func take_damage(damage: int):
	if player_shield > 0:
		var shield_damage = min(damage, player_shield)
		player_shield -= shield_damage
		damage -= shield_damage
	
	player_health -= damage
	player_health = max(0, player_health)
	health_changed.emit(player_health)
	
	if player_health <= 0:
		get_tree().change_scene_to_file("res://scenes/DefeatScreen.tscn")

func heal(amount: int):
	player_health = min(player_max_health, player_health + amount)
	health_changed.emit(player_health)

func add_shield(amount: int):
	player_shield = min(100, player_shield + amount)
	health_changed.emit(player_health)

func switch_weapon(weapon: String):
	current_weapon = weapon
	weapon_changed.emit(weapon)

func use_ammo(weapon: String, amount: int):
	weapon_ammo[weapon] -= amount
	weapon_ammo[weapon] = max(0, weapon_ammo[weapon])

func reset_game():
	score = 0
	player_health = player_max_health
	player_shield = 0
	current_weapon = "minigun"
	weapon_ammo = {
		"minigun": 999,
		"rocket": 50,
		"spread": 100
	}
	current_level = 0