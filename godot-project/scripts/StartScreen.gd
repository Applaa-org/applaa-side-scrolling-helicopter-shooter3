extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var endless_button: Button = $VBoxContainer/EndlessButton
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Reset game state
	Global.reset_game()

func _on_start_pressed():
	Global.current_level = 0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_endless_pressed():
	Global.current_level = -1  # Special value for endless mode
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_close_pressed():
	get_tree().quit()