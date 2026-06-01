extends Node

var current_target: Node3D = null
var highlight_material: ShaderMaterial = null
var default_material: StandardMaterial3D = null


func _ready():
	# Пытаемся загрузить шейдер
	var shader = load("res://shaders/highlight.gdshader")
	if shader:
		highlight_material = ShaderMaterial.new()
		highlight_material.shader = shader
		highlight_material.set_shader_parameter("outline_color", Color(1, 0, 0))
	else:
		highlight_material = null
		print("Шейдер не найден, подсветка не будет работать")


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		select_target()


func select_target():
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("Таргетинг: камера не найдена")
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collision_mask = 0xFFFFFFFF  # Все слои
	
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_query)
	
	# Снимаем подсветку со старой цели
	clear_target()
	
	if result:
		var hit = result.collider
		print("Таргетинг: попали в ", hit.name)
		
		# Ищем родителя-врага
		var enemy = find_enemy_parent(hit)
		
		if enemy and enemy.has_method("is_enemy"):
			current_target = enemy
			highlight_target(current_target)
			
			# Передаём цель в Skills через игрока
			var player = get_parent()
			if player and player.has_method("set_target"):
				player.set_target(current_target)
			
			print("✅ Выбрана цель: ", current_target.name)
		else:
			print("❌ Не враг или нет метода is_enemy")
			current_target = null
	else:
		print("Таргетинг: не попали ни во что")
		current_target = null


func find_enemy_parent(node: Node) -> Node:
	var current = node
	while current:
		if current.has_method("is_enemy"):
			return current
		current = current.get_parent()
	return null


func clear_target():
	if current_target:
		remove_highlight(current_target)
		current_target = null


func highlight_target(target: Node3D):
	var mesh_instance = find_mesh_instance(target)
	if mesh_instance:
		if highlight_material:
			default_material = mesh_instance.material_override as StandardMaterial3D
			mesh_instance.material_override = highlight_material
		else:
			# Временная подсветка сменой цвета
			var material = mesh_instance.get_surface_override_material(0)
			if not material:
				material = mesh_instance.material_override
			
			if material and material is StandardMaterial3D:
				material.set_meta("original_color", material.albedo_color)
				material.albedo_color = Color(1, 0.5, 0.5)
		
		print("Подсветка включена")


func remove_highlight(target: Node3D):
	var mesh_instance = find_mesh_instance(target)
	if mesh_instance:
		if highlight_material:
			mesh_instance.material_override = default_material
		else:
			var material = mesh_instance.get_surface_override_material(0)
			if not material:
				material = mesh_instance.material_override
			
			if material and material is StandardMaterial3D and material.has_meta("original_color"):
				material.albedo_color = material.get_meta("original_color")
		
		print("Подсветка выключена")


func find_mesh_instance(node: Node3D) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
	return null


func get_target() -> Node3D:
	return current_target
