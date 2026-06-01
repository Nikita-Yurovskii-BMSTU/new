extends Camera3D

func _ready():
	# Принудительно делаем камеру активной
	current = true
	print("Камера принудительно активна")
	
	# Ставим камеру на высоту
	position = Vector3(0, 10, 15)
	rotation_degrees = Vector3(-45, 0, 0)
