# PlayerCamera.gd
extends Camera3D

@export var follow_speed: float = 10.0
@export var offset: Vector3 = Vector3(0, 5, 10)

var target: Node3D = null


func _ready():
	# Делаем эту камеру текущей
	current = true
	print("Камера создана и активна")


func _physics_process(delta):
	if target:
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		look_at(target.global_position)


func set_target(player: Node3D):
	target = player
	print("Камера теперь следит за: ", player.name)
