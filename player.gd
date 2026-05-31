extends CharacterBody3D

@export var speed: float = 5.0
@export var camera_height: float = 15.0
@export var camera_distance: float = 10.0

var camera: Camera3D = null
var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false


func _ready():
	print("=== ИГРОК СОЗДАН ===")
	
	# Создаём визуал игрока (простой куб)
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.8, 0.8, 0.8)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	body.material_override = material
	add_child(body)
	
	# Добавляем стрелку направления (простой куб сверху)
	var arrow = MeshInstance3D.new()
	arrow.mesh = BoxMesh.new()
	arrow.mesh.size = Vector3(0.4, 0.1, 0.8)
	arrow.position = Vector3(0, 0.5, 0.4)
	var arrow_material = StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1, 1, 0)
	arrow.material_override = arrow_material
	add_child(arrow)
	
	# Создаём камеру
	camera = Camera3D.new()
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.rotation_degrees = Vector3(-35, 0, 0)
	add_child(camera)
	camera.make_current()
	
	# Включаем обработку ввода
	set_process(true)
	set_physics_process(true)


func _input(event):
	# Движение по правой кнопке мыши
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Получаем позицию клика на земле
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 1000
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		var space_state = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = from
		ray_query.to = to
		var result = space_state.intersect_ray(ray_query)
		
		if result:
			target_position = result.position
			is_moving = true
			  # Изменил true на True (Godot 4 использует true)
			
			# Поворачиваем игрока в сторону движения
			var direction_to_target = (target_position - global_position).normalized()
			direction_to_target.y = 0
			if direction_to_target != Vector3.ZERO:
				look_at(global_position + direction_to_target, Vector3.UP)


func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		
		# Проверяем, достигли ли цели
		if global_position.distance_to(target_position) < 0.5:
			velocity = Vector3.ZERO
			is_moving = false
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()


func _process(delta):
	# Обновляем позицию камеры (следует за игроком)
	if camera:
		camera.global_position = global_position + Vector3(0, camera_height, camera_distance)
		camera.look_at(global_position)
