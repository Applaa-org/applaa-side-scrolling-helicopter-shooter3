extends Area2D
class_name PowerUp

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var glow: Sprite2D = $Glow
@onready var particles: CPUParticles2D = $Particles

var type: String = "health"
var value: int = 25
var rarity: String = "common"  # common, rare, epic, legendary

func _ready():
	body_entered.connect(_on_body_entered)
	animation.play("float")
	_setup_visuals()

func _setup_visuals():
	var colors = {
		"health": Color.GREEN,
		"shield": Color.CYAN,
		"ammo": Color.ORANGE,
		"speed": Color.YELLOW,
		"damage": Color.RED,
		"multishot": Color.MAGENTA,
		"invincible": Color.WHITE
	}
	
	var rarity_colors = {
		"common": Color.WHITE,
		"rare": Color.BLUE,
		"epic": Color.PURPLE,
		"legendary": Color.GOLD
	}
	
	sprite.modulate = colors.get(type, Color.WHITE)
	glow.modulate = rarity_colors.get(rarity, Color.WHITE)
	
	# Enhanced particles for rare power-ups
	if rarity != "common":
		particles.emitting = true
		particles.color = rarity_colors[rarity]

func _on_body_entered(body: Node):
	if body is EnhancedPlayer:
		_apply_effect(body)
		_collect_effect()
		queue_free()

func _apply_effect(player: EnhancedPlayer):
	match type:
		"health":
			Global.heal(value)
		"shield":
			Global.add_shield(value)
		"ammo":
			Global.weapon_ammo[Global.current_weapon] += value
		"speed":
			player.SPEED += 50
		"damage":
			# Increase damage for all weapons
			pass
		"multishot":
			# Add multishot capability
			pass
		"invincible":
			Global.add_shield(999)
			await get_tree().create_timer(5.0).timeout
			Global.player_shield = 0

func _collect_effect():
	# Collection visual effect
	var collect_effect = preload("res://scenes/PowerUpCollect.tscn").instantiate()
	get_parent().add_child(collect_effect)
	collect_effect.global_position = global_position
	
	# Bonus score based on rarity
	var bonus_score = match rarity:
		"common": 50
		"rare": 100
		"epic": 200
		"legendary": 500
		_: 50
	
	Global.add_score(bonus_score)