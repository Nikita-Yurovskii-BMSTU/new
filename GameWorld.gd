extends Node3D

@export var player_scene: PackedScene
@export var spawn_points: Array[Marker3D]


func _ready():
	add_to_group("GameWorld")
	
	print("=== ТЕСТ: СОЗДАНИЕ ИГРОКА ===")
	print("player_scene: ", player_scene)
	
	if player_scene:
		var player = player_scene.instantiate()
		add_child(player)
		player.position = Vector3(0, 0, 0)
		print("Игрок создан и добавлен")
	else:
		print("ОШИБКА: player_scene = null! Перетащите Player.tscn в инспектор")
