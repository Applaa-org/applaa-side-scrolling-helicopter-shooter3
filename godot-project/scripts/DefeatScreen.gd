extends Control

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var menu_button: Button = $VBoxContainer/MenuButton
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready():
	score_label.text = "Final Score: %d" % Global.score
	
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_restart_pressed():
	Global.reset_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu_pressed():
	Global.reset_game()
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _on_close_pressed():
	get_tree().quit()