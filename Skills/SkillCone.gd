extends SkillBase
class_name SkillCone


func _execute(target: Node3D = null):
	var base_dir = get_shoot_direction(target)
	
	var dirs = [
		base_dir,
		base_dir.rotated(Vector3.UP, 0.3),
		base_dir.rotated(Vector3.UP, -0.3)
	]
	
	for d in dirs:
		spawn_projectile(d)
	
	print("Конус выпущен!")


func _execute_with_direction(dir: Vector3, target_pos: Vector3, is_targeted: bool, target: Node3D = null):
	var dirs = [
		dir,
		dir.rotated(Vector3.UP, 0.3),
		dir.rotated(Vector3.UP, -0.3)
	]
	
	for d in dirs:
		spawn_projectile(d)
	
	print("Конус выпущен в сохраненном направлении!")
