extends StaticBody3D

func _ready():
	# Добавляем коллизию
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = Vector3(50, 1, 50)
	add_child(collision_shape)
	
	# Добавляем визуал
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(50, 0.2, 50)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2)
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(0, -0.5, 0)
	add_child(mesh_instance)
