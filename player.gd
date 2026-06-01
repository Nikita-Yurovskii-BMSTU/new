extends CharacterBody3D

@export var speed: float = 5.0
@export var camera_height: float = 15.0
@export var camera_distance: float = 10.0
@export var bullet_scene: PackedScene

# Гравитация
@export var gravity: float = 20.0

var camera: Camera3D = null
var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var current_health: int = 100
var current_mana: int = 100
var max_health: int = 100
var max_mana: int = 100
var skills_library = null


func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("=== ИГРОК: ", name)
	print("is_multiplayer_authority(): ", is_multiplayer_authority())
	
	skills_library = preload("res://Skills.gd").new()
	skills_library.bullet_scene = bullet_scene
	skills_library.parent_player = self
	add_child(skills_library)
	
	if is_multiplayer_authority():
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.position = Vector3(0, camera_height, camera_distance)
		camera.rotation_degrees = Vector3(-40, 0, 0)
		add_child(camera)
		camera.make_current()
		print("✅ Камера создана")
	
	# Визуал
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.8, 0.8, 0.8)
	var material = StandardMaterial3D.new()
	
	if is_multiplayer_authority():
		material.albedo_color = Color(0.8, 0.2, 0.2)
		print("Это МОЙ игрок - красный")
	else:
		material.albedo_color = Color(0.2, 0.2, 0.8)
		print("Это ЧУЖОЙ игрок - синий")
	
	body.material_override = material
	add_child(body)
	
	if is_multiplayer_authority():
		var arrow = MeshInstance3D.new()
		arrow.mesh = BoxMesh.new()
		arrow.mesh.size = Vector3(0.4, 0.1, 0.8)
		arrow.position = Vector3(0, 0.5, 0.4)
		var arrow_material = StandardMaterial3D.new()
		arrow_material.albedo_color = Color(1, 1, 0)
		arrow.material_override = arrow_material
		add_child(arrow)
	
	var health_bar = create_health_bar()
	add_child(health_bar)
	
	add_to_group("Player")
	update_ui()
	set_physics_process(true)


func set_target(target: Node3D):
	if skills_library:
		skills_library.set_target(target)


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


func update_ui():
	var ui = get_tree().get_first_node_in_group("SkillUI")
	if ui and is_multiplayer_authority():
		ui.update_health(current_health, max_health)
		ui.update_mana(current_mana, max_mana)


func _input(event):
	if not is_multiplayer_authority():
		return
	
	var ui = get_tree().get_first_node_in_group("UI")
	if ui and ui.visible:
		return
	
	# Только ПКМ блокирует обработку
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		move_to_click()
		#get_viewport().set_input_as_handled()
	
	# Клавиши скиллов НЕ блокируют мышь
	if event is InputEventKey:
		if event.is_action_pressed("skill_1"):
			print("=== Нажата Q, режим мыши: ", Input.get_mouse_mode())
			use_skill(1)
			print("=== После use_skill, режим мыши: ", Input.get_mouse_mode())
		if event.is_action_pressed("skill_2"):
			use_skill(2)
		if event.is_action_pressed("skill_3"):
			use_skill(3)
		if event.is_action_pressed("skill_4"):
			use_skill(4)


func use_skill(skill_id: int):
	if not skills_library:
		return
	skills_library.use_skill(skill_id)


@rpc("any_peer", "call_local", "reliable")
func shoot_rpc(skill_id: int, pos: Vector3, dir: Vector3, rot: float, target_pos: Vector3 = Vector3.ZERO, is_targeted: bool = false):
	rotation.y = rot
	
	match skill_id:
		1:
			if bullet_scene:
				var bullet = bullet_scene.instantiate()
				bullet.global_position = pos
				bullet.direction = dir
				bullet.is_targeted = is_targeted
				if is_targeted and target_pos != Vector3.ZERO:
					bullet.target_position = target_pos
				get_tree().root.add_child(bullet)
		
		2:
			if bullet_scene:
				var bullet1 = bullet_scene.instantiate()
				bullet1.global_position = pos
				bullet1.direction = dir
				get_tree().root.add_child(bullet1)
				await get_tree().create_timer(0.1).timeout
				var bullet2 = bullet_scene.instantiate()
				bullet2.global_position = pos
				bullet2.direction = dir
				get_tree().root.add_child(bullet2)
		
		3:
			if bullet_scene:
				var dirs = [dir, dir.rotated(Vector3.UP, 0.3), dir.rotated(Vector3.UP, -0.3)]
				for d in dirs:
					var bullet = bullet_scene.instantiate()
					bullet.global_position = pos
					bullet.direction = d
					get_tree().root.add_child(bullet)
		
		4:
			# Хил или другой скилл
			pass


func move_to_click():
	if not camera:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	
	if result:
		target_position = result.position
		is_moving = true
		var dir = (target_position - global_position).normalized()
		dir.y = 0
		if dir != Vector3.ZERO:
			look_at(global_position + dir, Vector3.UP)


func take_damage(amount: int):
	if not is_multiplayer_authority():
		return
	
	current_health -= amount
	update_health_bar()
	update_ui()
	print("❤️ HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()


func die():
	rpc("die_rpc")
	queue_free()


@rpc("any_peer", "call_local", "reliable")
func die_rpc():
	if is_multiplayer_authority():
		return
	queue_free()


func _physics_process(delta):
	# Применяем гравитацию всегда (для всех)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0
	
	# Движение для своего игрока
	if is_multiplayer_authority():
		if is_moving:
			var direction = (target_position - global_position).normalized()
			direction.y = 0
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if global_position.distance_to(target_position) < 0.5:
				velocity.x = 0
				velocity.z = 0
				is_moving = false
		else:
			velocity.x = 0
			velocity.z = 0
		
		move_and_slide()
		sync_position.rpc(global_position, rotation.y)
	else:
		move_and_slide()


@rpc("any_peer", "unreliable", "call_local")
func sync_position(new_pos: Vector3, new_rot: float):
	if is_multiplayer_authority():
		return
	global_position = new_pos
	rotation.y = new_rot


func _process(delta):
	if camera and is_multiplayer_authority():
		camera.global_position = global_position + Vector3(0, camera_height, camera_distance)
		camera.look_at(global_position)
