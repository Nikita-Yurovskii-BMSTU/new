extends Camera3D

var target: Node3D = null
@export var follow_speed: float = 10.0
@export var offset: Vector3 = Vector3(0, 5, 10)


func _ready():
	add_to_group("GameCamera")
	print("=== КАМЕРА ГОТОВА ===")
	print("Позиция камеры: ", global_position)
	
	# Принудительно ставим камеру на высоту
	global_position = Vector3(0, 10, 15)
	look_at(Vector3(0, 0, 0))


func _physics_process(delta):
	if target:
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		look_at(target.global_position)
		print("Камера следит за ", target.name, " на позиции ", target.global_position)
	else:
		print("Камера: нет цели")


func set_target(new_target: Node3D):
	target = new_target
	print("=== КАМЕРА: ЦЕЛЬ УСТАНОВЛЕНА ===")
	print("Цель: ", target.name)
	print("Позиция цели: ", target.global_position)
