extends SkillBase
class_name SkillHeal


func _execute(target: Node3D = null):
	player.current_health = min(player.current_health + skill_data.heal_amount, player.max_health)
	player.update_health_bar()
	player.update_ui()
	print("Лечение на ", skill_data.heal_amount, " HP!")
