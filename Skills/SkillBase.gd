extends Node
class_name SkillBase

var skill_data: SkillResource
var player: CharacterBody3D
var cooldown_timer: float = 0.0

signal skill_activated(skill_id: int)
signal skill_finished(skill_id: int)


func _ready():
	pass


func setup(data: SkillResource, player_node: CharacterBody3D):
	skill_data = data
	player = player_node


func can_activate() -> bool:
	if cooldown_timer > 0.01:
		print("Скилл ", skill_data.skill_name, " на кулдауне: ", ceil(cooldown_timer))
		return false
	
	if player.current_mana < skill_data.mana_cost:
		print("Недостаточно маны для ", skill_data.skill_name)
		return false
	
	return true


func activate(target: Node3D = null):
	if not can_activate():
		return
	
	player.current_mana -= skill_data.mana_cost
	player.update_ui()
	
	cooldown_timer = skill_data.cooldown
	
	_update_ui_cooldown()
	
	emit_signal("skill_activated", skill_data.id)
	
	await _wait_for_animation()
	_execute(target)
	
	await _wait_for_recoil()
	
	emit_signal("skill_finished", skill_data.id)


func _update_ui_cooldown():
	var ui = player.get_tree().get_first_node_in_group("SkillUI")
	if ui:
		ui.start_cooldown(skill_data.id)


func _wait_for_animation():
	if player.anim_manager:
		await player.anim_manager.animation_finished
	else:
		await player.get_tree().create_timer(0.3).timeout


func _wait_for_recoil():
	while player.anim_manager and player.anim_manager.is_playing_attack:
		await player.get_tree().process_frame


func _execute(target: Node3D = null):
	pass


func _execute_with_direction(dir: Vector3, target_pos: Vector3, is_targeted: bool, target: Node3D = null):
	_execute(target)


func get_shoot_direction(target: Node3D = null) -> Vector3:
	if target and is_instance_valid(target):
		var dir = (target.global_position - player.global_position).normalized()
		dir.y = 0
		return dir
	else:
		if player.skills_library:
			return player.skills_library.get_shoot_direction()
		return Vector3.FORWARD


func spawn_projectile(direction: Vector3, target_pos: Vector3 = Vector3.ZERO, is_targeted: bool = false):
	var projectile_scene = skill_data.effect_scene
	if not projectile_scene:
		print("Нет effect_scene для скилла ", skill_data.skill_name)
		return
	
	var projectile = projectile_scene.instantiate()
	
	if "direction" in projectile:
		projectile.direction = direction
	if "damage" in projectile:
		projectile.damage = skill_data.damage
	if "speed" in projectile:
		projectile.speed = skill_data.speed
	if "lifetime" in projectile:
		projectile.lifetime = skill_data.lifetime
	if "is_targeted" in projectile:
		projectile.is_targeted = is_targeted
	if is_targeted and target_pos != Vector3.ZERO and "target_position" in projectile:
		projectile.target_position = target_pos
	
	player.get_tree().root.add_child(projectile)
	projectile.global_position = player.global_position + Vector3(0, 0.5, 0)
	
	print("Снаряд создан: ", projectile.name)


func get_cooldown_percent() -> float:
	if skill_data.cooldown <= 0:
		return 0.0
	return cooldown_timer / skill_data.cooldown


func is_on_cooldown() -> bool:
	return cooldown_timer > 0


func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if cooldown_timer <= 0:
			cooldown_timer = 0.0  # Обнуляем точно
