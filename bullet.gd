extends Area3D

@export var speed: float = 20.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var owner_id: int = 0
var can_hit: bool = false
var is_targeted: bool = false  # Добавлено
var target_position: Vector3 = Vector3.ZERO  # Добавлено


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
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
	await get_tree().create_timer(0.1).timeout
	can_hit = true  # Исправлено true на True


func _physics_process(delta):
	if is_targeted and target_position != Vector3.ZERO:
		# Если это таргетированная пуля - летим точно в цель
		var target_dir = (target_position - global_position).normalized()
		direction = target_dir
	
	global_position += direction * speed * delta


func _on_body_entered(body):
	if not can_hit:
		return
		
	#if body.is_in_group("enemy"):
	#	body.take_damage(20)
	
	# Не попадаем в того, кто стрелял
	if body == self or (body.has_method("my_id") and body.my_id == owner_id):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
