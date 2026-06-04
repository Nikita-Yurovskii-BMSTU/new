extends SkillBase
class_name SkillHailArrows


func _execute(target: Node3D = null):
	var dir = get_shoot_direction(target)
	
	spawn_projectile(dir)
	await player.get_tree().create_timer(0.1).timeout
	spawn_projectile(dir)
	print("Град стрел выпущен!")


func _execute_with_direction(dir: Vector3, target_pos: Vector3, is_targeted: bool, target: Node3D = null):
	spawn_projectile(dir)
	await player.get_tree().create_timer(0.1).timeout
	spawn_projectile(dir)
	print("Град стрел выпущен в сохраненном направлении!")
