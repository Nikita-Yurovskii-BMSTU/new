extends Node

var bullet_scene: PackedScene = null
var parent_player: Node = null
var current_target: Node3D = null


func _ready():
	pass


func set_target(target: Node3D):
	current_target = target
	print("Skills: цель установлена - ", target.name if target else "null")


func get_target() -> Node3D:
	return current_target


func get_skill_info(skill_id: int) -> Dictionary:
	match skill_id:
		1:
			return {"name": "Пронзающая стрела", "mana": 0, "cooldown": 0.5, "type": "target_or_skillshot"}
		2:
			return {"name": "Град стрел", "mana": 20, "cooldown": 2.0, "type": "aoe"}
		3:
			return {"name": "Конус", "mana": 30, "cooldown": 3.0, "type": "cone"}
		4:
			return {"name": "Лечение", "mana": 40, "cooldown": 8.0, "type": "self"}
		_:
			return {"name": "Unknown", "mana": 0, "cooldown": 0, "type": "none"}


func get_shoot_direction() -> Vector3:
	if not parent_player or not parent_player.camera:
		return Vector3.FORWARD
	
	var camera = parent_player.camera
	var mouse_pos = parent_player.get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var result = parent_player.get_world_3d().direct_space_state.intersect_ray(ray_query)
	
	if result:
		var dir = (result.position - parent_player.global_position).normalized()
		dir.y = 0
		if dir.length() > 0.01:
			return dir
	
	return Vector3.FORWARD


func use_skill(skill_id: int):
	if not parent_player:
		return
	
	var skill_info = get_skill_info(skill_id)
	
	# Проверка маны
	if parent_player.current_mana < skill_info["mana"]:
		print("Недостаточно маны!")
		return
	
	parent_player.current_mana -= skill_info["mana"]
	parent_player.update_ui()
	
	var dir: Vector3
	var target_pos: Vector3 = Vector3.ZERO
	var is_targeted = false
	
	# Для Q (скилл 1) - проверяем таргет
	if skill_id == 1 and current_target and is_instance_valid(current_target):
		# Стрельба по цели
		dir = (current_target.global_position - parent_player.global_position).normalized()
		dir.y = 0
		target_pos = current_target.global_position
		is_targeted = true
		print("Стрельба по цели: ", current_target.name)
	else:
		# Скиллшот в направлении мыши
		dir = get_shoot_direction()
		target_pos = parent_player.global_position + dir * 10
		print("Скиллшот в направлении мыши")
	
	if dir != Vector3.ZERO:
		parent_player.look_at(parent_player.global_position + dir, Vector3.UP)
		pass
	
	# Отправляем RPC
	parent_player.shoot_rpc.rpc(skill_id, parent_player.global_position + Vector3(0, 0.5, 0), dir, parent_player.rotation.y, target_pos, is_targeted)
