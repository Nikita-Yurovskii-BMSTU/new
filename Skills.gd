extends Node

var bullet_scene: PackedScene = null
var parent_player: Node = null
var current_target: Node3D = null

var all_skills: Dictionary = {}
var equipped_skills: Array = [null, null, null, null]
var skill_instances: Dictionary = {}

signal skill_shot(skill_id: int, pos: Vector3, dir: Vector3, target_pos: Vector3, is_targeted: bool)


func _ready():
	_load_all_skills()
	_equip_default_skills()


func _load_all_skills():
	all_skills[1] = load("res://Skills/skill_piercing_arrow.tres")
	all_skills[2] = load("res://Skills/skill_hail_arrows.tres")
	all_skills[3] = load("res://Skills/skill_cone.tres")
	all_skills[4] = load("res://Skills/skill_heal.tres")


func _equip_default_skills():
	equipped_skills[0] = 1  # Q
	equipped_skills[1] = 2  # W
	equipped_skills[2] = 3  # E
	equipped_skills[3] = 4  # R


func set_target(target: Node3D):
	current_target = target


func get_target() -> Node3D:
	return current_target


func get_skill_info(skill_id: int) -> Dictionary:
	if not all_skills.has(skill_id):
		return {"name": "Unknown", "mana": 0, "cooldown": 0, "type": "none"}
	
	var skill = all_skills[skill_id]
	return {
		"name": skill.skill_name,
		"mana": skill.mana_cost,
		"cooldown": skill.cooldown,
		"type": skill.skill_type
	}


func get_equipped_skill(slot: int) -> int:
	if slot >= 0 and slot < equipped_skills.size():
		return equipped_skills[slot]
	return 0


func get_skill_instance(skill_id: int) -> SkillBase:
	if skill_instances.has(skill_id):
		return skill_instances[skill_id]
	
	if not all_skills.has(skill_id):
		return null
	
	var skill_data = all_skills[skill_id]
	var skill_instance: SkillBase
	
	match skill_id:
		1:
			skill_instance = SkillPiercingArrow.new()
		2:
			skill_instance = SkillHailArrows.new()
		3:
			skill_instance = SkillCone.new()
		4:
			skill_instance = SkillHeal.new()
		_:
			return null
	
	skill_instance.setup(skill_data, parent_player)
	skill_instances[skill_id] = skill_instance
	add_child(skill_instance)
	
	return skill_instance


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


func execute_shoot(skill_id: int, target: Node3D = null):
	if not parent_player:
		return
	
	var skill_instance = get_skill_instance(skill_id)
	if skill_instance:
		skill_instance.activate(target)


func use_skill(slot: int):
	if parent_player:
		var skill_id = get_equipped_skill(slot)
		if skill_id > 0:
			parent_player.start_attack(skill_id)
