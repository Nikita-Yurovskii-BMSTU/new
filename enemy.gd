extends CharacterBody3D

@export var speed: float = 2.0
@export var max_health: int = 50
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

var current_health: int = 50
var player: Node = null
var can_attack: bool = true


func _ready():
	current_health = max_health
	
	# Визуал
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.8, 0.8, 0.8)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.1, 0.8)
	body.material_override = material
	add_child(body)
	
	var health_bar = create_health_bar()
	add_child(health_bar)
	
	# Только сервер управляет врагами
	if not multiplayer.is_server():
		set_physics_process(false)
		return
	
	player = get_tree().get_first_node_in_group("Player")
	set_physics_process(true)


func create_health_bar() -> Node3D:
	var health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar"
	health_bar_container.position.y = 1.2
	
	var background = MeshInstance3D.new()
	background.mesh = BoxMesh.new()
	background.mesh.size = Vector3(1.0, 0.1, 0.1)
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.3, 0.3, 0.3)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	background.material_override = bg_material
	health_bar_container.add_child(background)
	
	var foreground = MeshInstance3D.new()
	foreground.mesh = BoxMesh.new()
	foreground.mesh.size = Vector3(1.0, 0.1, 0.1)
	var fg_material = StandardMaterial3D.new()
	fg_material.albedo_color = Color(0, 1, 0)
	fg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	foreground.material_override = fg_material
	foreground.position.x = 0
	health_bar_container.add_child(foreground)
	foreground.set_meta("foreground", true)
	
	return health_bar_container


func update_health_bar():
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		for child in health_bar.get_children():
			if child.has_meta("foreground"):
				var percent = float(current_health) / max_health
				child.mesh.size.x = max(0.01, 1.0 * percent)
				child.position.x = -(1.0 - percent) / 2


func take_damage(amount: int):
	if not multiplayer.is_server():
		return
	
	current_health -= amount
	update_health_bar()
	update_enemy_health.rpc(current_health)
	
	if current_health <= 0:
		die()




@rpc("any_peer", "call_local", "reliable")
func update_enemy_health(new_health: int):
	if multiplayer.is_server():
		return
	current_health = new_health
	update_health_bar()


func die():
	die_rpc.rpc()
	queue_free()


@rpc("any_peer", "call_local", "reliable")
func die_rpc():
	if multiplayer.is_server():
		return
	queue_free()


func _physics_process(delta):
	if not multiplayer.is_server():
		return
	
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= 10:
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		move_and_slide()
		
		if direction != Vector3.ZERO:
			look_at(global_position + direction, Vector3.UP)
		
		if distance <= 1.5 and can_attack:
			attack()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
	
	# Синхронизация позиции
	sync_position.rpc(global_position, rotation.y)


@rpc("any_peer", "unreliable", "call_local")
func sync_position(new_pos: Vector3, new_rot: float):
	if multiplayer.is_server():
		return
	global_position = new_pos
	rotation.y = new_rot


func attack():
	if not can_attack:
		return
	
	can_attack = false
	
	if player:
		player.take_damage(damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
func is_enemy() -> bool:
	return true
