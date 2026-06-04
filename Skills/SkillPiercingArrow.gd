extends SkillBase
class_name SkillPiercingArrow


func _execute(target: Node3D = null):
	var dir: Vector3
	var target_pos: Vector3 = Vector3.ZERO
	var is_targeted = false
	
	if target and is_instance_valid(target):
		dir = (target.global_position - player.global_position).normalized()
		dir.y = 0
		target_pos = target.global_position
		is_targeted = true
	else:
		dir = get_shoot_direction()
		target_pos = player.global_position + dir * 10
	
	spawn_projectile(dir, target_pos, is_targeted)
	print("Пронзающая стрела выпущена!")


func _execute_with_direction(dir: Vector3, target_pos: Vector3, is_targeted: bool, target: Node3D = null):
	spawn_projectile(dir, target_pos, is_targeted)
	print("Пронзающая стрела выпущена в сохраненном направлении!")
