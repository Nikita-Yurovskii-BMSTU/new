extends Area3D

@export var speed: float = 20.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var owner_id: int = 0
var is_targeted: bool = false
var target_position: Vector3 = Vector3.ZERO


func _ready():
	# Визуал
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0)
	mesh.material_override = material
	add_child(mesh)
	
	# Коллизия
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 0.2
	add_child(collision)
	
	body_entered.connect(_on_body_entered)
	
	# Жизнь пули
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	if is_targeted and target_position != Vector3.ZERO:
		var target_dir = (target_position - global_position).normalized()
		direction = target_dir
	
	global_position += direction * speed * delta


func _on_body_entered(body):
	print("Пуля попала в: ", body.name)
	
	# Игнорируем всех игроков (по группе)
	if body.is_in_group("Player"):
		print("Это игрок, пропускаем")
		return
	
	var parent = body.get_parent()
	if parent and parent.is_in_group("Player"):
		print("Это игрок (родитель), пропускаем")
		return
	
	# Ищем врага
	var enemy = body
	while enemy and not enemy.has_method("take_damage"):
		enemy = enemy.get_parent()
		if enemy:
			print("Проверяем родителя: ", enemy.name)
	
	if not enemy:
		if body.is_in_group("Enemy"):
			enemy = body
		elif body.get_parent() and body.get_parent().is_in_group("Enemy"):
			enemy = body.get_parent()
		else:
			print("Не удалось найти врага")
			return
	
	print("Попали во врага: ", enemy.name)
	enemy.take_damage(damage)
	queue_free()
