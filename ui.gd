extends Control

@onready var ip_input = $VBoxContainer/LineEdit
@onready var host_button = $VBoxContainer/Host
@onready var join_button = $VBoxContainer/Join

var game_world: Node = null


func _ready():
	add_to_group("UI")
	
	await get_tree().process_frame
	game_world = get_tree().get_first_node_in_group("GameWorld")
	
	if game_world:
		print("UI: GameWorld найден")
	else:
		print("UI: GameWorld НЕ НАЙДЕН!")
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)


func _on_host_pressed():
	print("UI: Нажата кнопка Host")
	if game_world and game_world.has_method("start_host"):
		game_world.start_host()
		hide()


func _on_join_pressed():
	print("UI: Нажата кнопка Join")
	var ip = ip_input.text
	if ip == "":
		ip = "127.0.0.1"
	
	if game_world and game_world.has_method("start_client"):
		game_world.start_client(ip)
		hide()
