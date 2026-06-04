extends Area3D

@export var speed: float = 40.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var owner_id: int = 0
var is_targeted: bool = false
var target_position: Vector3 = Vector3.ZERO

# Общий материал для всех пуль
#static var shared_material: StandardMaterial3D


func _ready():
	# Создаем материал только один раз для всех пуль
	#if not shared_material:
		#shared_material = StandardMaterial3D.new()
		#shared_material.albedo_color = Color(1, 0.5, 0)
		#shared_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	
	# Коллизия
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 0.2
	add_child(collision)
	
	# Подключаем сигнал только если еще не подключен
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Жизнь пули
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	if is_targeted and target_position != Vector3.ZERO:
		var target_dir = (target_position - global_position).normalized()
		direction = target_dir
	
	# Поворот снаряда к направлению движения
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	
	global_position += direction * speed * delta


func _on_body_entered(body):
	print("Пуля попала в: ", body.name)
	
	# Игнорируем всех игроков
	if body.is_in_group("Player"):
		return
	
	var parent = body.get_parent()
	if parent and parent.is_in_group("Player"):
		return
	
	# Ищем врага
	var enemy = body
	while enemy and not enemy.has_method("take_damage"):
		enemy = enemy.get_parent()
	
	if not enemy:
		if body.is_in_group("Enemy"):
			enemy = body
		elif body.get_parent() and body.get_parent().is_in_group("Enemy"):
			enemy = body.get_parent()
		else:
			return
	
	print("Попали во врага: ", enemy.name)
	enemy.take_damage(damage)
	queue_free()
