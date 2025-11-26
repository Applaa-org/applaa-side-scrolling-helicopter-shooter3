extends Node

signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal weapon_changed(weapon: String)
signal level_changed(level: int)

var score: int = 0
var coins: int = 0
var current_level: int = 0
var current_weapon: String = "minigun"
var player_health: int = 100
var player_max_health: int = 100
var player_armor: int = 50
var player_shield: int = 0
var game_paused: bool = false
var is_mobile: bool = false

var weapons_unlocked: Array[String] = ["minigun", "rocket", "spread"]
var weapon_ammo: Dictionary = {
	"minigun": 999,
	"rocket": 10,
	"spread": 50
}

func add_score(points: int):
	score += points
	coins += points
	score_changed.emit(score)

func take_damage(damage: int):
	if player_shield > 0:
		var shield_damage = min(damage, player_shield)
		player_shield -= shield_damage
		damage -= shield_damage
	
	if player_armor > 0:
		var armor_damage = min(damage, player_armor)
		player_armor -= armor_damage
		damage -= armor_damage
	
	player_health -= damage
	player_health = max(0, player_health)
	health_changed.emit(player_health)
	
	if player_health <= 0:
		get_tree().change_scene_to_file("res://scenes/DefeatScreen.tscn")

func heal(amount: int):
	player_health = min(player_health + amount, player_max_health)
	health_changed.emit(player_health)

func add_shield(amount: int):
	player_shield += amount
	health_changed.emit(player_health)

func switch_weapon(weapon: String):
	if weapon in weapons_unlocked:
		current_weapon = weapon
		weapon_changed.emit(weapon)

func use_ammo(weapon: String, amount: int = 1):
	if weapon_ammo.has(weapon):
		weapon_ammo[weapon] -= amount
		weapon_ammo[weapon] = max(0, weapon_ammo[weapon])

func reset_game():
	score = 0
	coins = 0
	current_level = 0
	current_weapon = "minigun"
	player_health = player_max_health
	player_armor = 50
	player_shield = 0
	game_paused = false
	
	weapon_ammo = {
		"minigun": 999,
		"rocket": 10,
		"spread": 50
	}