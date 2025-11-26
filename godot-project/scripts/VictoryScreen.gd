extends Control

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var next_button: Button = $VBoxContainer/NextButton
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var menu_button: Button = $VBoxContainer/MenuButton
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready():
	score_label.text = "Final Score: %d" % Global.score
	
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Hide next button if on last level
	if Global.current_level >= 9:
		next_button.visible = false

func _on_next_pressed():
	Global.current_level += 1
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_menu_pressed():
	Global.reset_game()
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _on_close_pressed():
	get_tree().quit()