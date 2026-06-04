extends MultiMeshInstance3D

func _ready():
	# Размер области, на которой будут деревья
	var area_size = 50.0
	var count = multimesh.instance_count
	var rng = RandomNumberGenerator.new()
	
	for i in count:
		var t = Transform3D()
		# Случайная позиция по X и Z
		t.origin = Vector3(
			rng.randf_range(-area_size, area_size),
			0,
			rng.randf_range(-area_size, area_size)
		)
		# Случайный поворот по Y
		t = t.rotated(Vector3.UP, rng.randf_range(0, PI * 2))
		# Случайный масштаб (необязательно)
		t = t.scaled(Vector3(
			rng.randf_range(0.8, 1.2),
			rng.randf_range(0.8, 1.2),
			rng.randf_range(0.8, 1.2)
		))
		multimesh.set_instance_transform(i, t)
