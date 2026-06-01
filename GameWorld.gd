extends Node3D

@export var player_scene: PackedScene
@export var spawn_points: Array[Marker3D]

var players: Dictionary = {}
var players_node: Node3D = null


func _ready():
	add_to_group("GameWorld")
	
	players_node = Node3D.new()
	players_node.name = "Players"
	add_child(players_node)
	print("GameWorld готов")


func start_host(port: int = 10567):
	print("=== ЗАПУСК ХОСТА ===")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Сервер запущен")
	
	var ui = get_tree().get_first_node_in_group("UI")
	if ui: ui.hide()
	
	# Создаём игрока хоста
	create_player(1, Vector3(0, 20, 0))


func start_client(address: String = "127.0.0.1", port: int = 10567):
	print("=== ЗАПУСК КЛИЕНТА ===")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	print("Клиент подключается")
	
	var ui = get_tree().get_first_node_in_group("UI")
	if ui: ui.hide()
	
	await get_tree().create_timer(0.5).timeout
	print("Подключено")


func _on_peer_connected(id: int):
	print("Подключился игрок: ", id)
	
	# Отправляем новому игроку команду создать себя
	rpc_id(id, "create_your_player", id)
	
	# Отправляем новому игроку всех ОСТАЛЬНЫХ существующих игроков
	for peer_id in players:
		if peer_id != id:
			rpc_id(id, "create_other_player", peer_id, players[peer_id].global_position)
	
	# Создаём игрока для нового клиента на сервере
	create_player(id, Vector3(0, 1, 0))


@rpc("any_peer", "call_local", "reliable")
func create_your_player(peer_id: int):
	if multiplayer.is_server():
		return
	
	# Проверяем, не создан ли уже этот игрок
	if players.has(peer_id):
		print("Игрок ", peer_id, " уже существует, пропускаем")
		return
	
	print("Клиент создаёт своего игрока: ", peer_id)
	create_player(peer_id, Vector3(0, 1, 0))


@rpc("any_peer", "call_local", "reliable")
func create_other_player(peer_id: int, pos: Vector3):
	if multiplayer.is_server():
		return
	
	# Проверяем, не создан ли уже этот игрок
	if players.has(peer_id):
		print("Игрок ", peer_id, " уже существует, пропускаем")
		return
	
	print("Клиент создаёт чужого игрока: ", peer_id)
	create_player(peer_id, pos)


func create_player(peer_id: int, pos: Vector3):
	if not players_node or not player_scene:
		return
	
	# Проверяем, не существует ли уже
	if players.has(peer_id):
		print("Игрок ", peer_id, " уже в словаре, пропускаем")
		return
	
	var player = player_scene.instantiate()
	player.name = "Player_" + str(peer_id)
	player.global_position = pos
	player.set_multiplayer_authority(peer_id)
	
	players_node.add_child(player)
	players[peer_id] = player
	print("✅ Создан игрок: ", player.name, " authority: ", player.get_multiplayer_authority())


func _on_peer_disconnected(id: int):
	print("Отключился игрок: ", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
