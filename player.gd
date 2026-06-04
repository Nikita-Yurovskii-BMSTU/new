extends CharacterBody3D

# =============================================================================
#  1. ПЕРЕМЕННЫЕ И СВОЙСТВА
# =============================================================================

# ---------------------- Узлы ----------------------
@onready var anim_tree = $body/AnimationTree
@onready var anim_manager = $AnimationManager

# ---------------------- Экспорт ----------------------
@export var speed: float = 10.0
@export var camera_height: float = 12.0
@export var camera_distance: float = 8.0
@export var bullet_scene: PackedScene
@export var gravity: float = 20.0

# ---------------------- Камера ----------------------
var camera: Camera3D = null

# ---------------------- Передвижение ----------------------
var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var _last_anim: String = ""

# ---------------------- Здоровье и мана ----------------------
var current_health: int = 100
var current_mana: int = 100
var max_health: int = 100
var max_mana: int = 100

# ---------------------- Библиотека скиллов ----------------------
var skills_library = null

# ---------------------- Состояние атаки ----------------------
var is_attacking: bool = false
var attack_target: Node3D = null
var pending_skill_id: int = 0
var _attack_in_progress: bool = false
var _attack_id: int = 0

# ---------------------- Кеш для RPC ----------------------
var _saved_dir: Vector3 = Vector3.ZERO
var _saved_target_pos: Vector3 = Vector3.ZERO
var _saved_is_targeted: bool = false

# ---------------------- Защита от спама ----------------------
var _last_shot_time: float = 0.0
var _min_shot_interval: float = 0.5

# ---------------------- Служебные ----------------------
var _is_authority: bool = false


# =============================================================================
#  2. ИНИЦИАЛИЗАЦИЯ
# =============================================================================

func _ready():
	call_deferred("_setup_player")


func _setup_player():
	print("=== ИГРОК: ", name)
	
	_is_authority = is_multiplayer_authority()
	print("is_multiplayer_authority(): ", _is_authority)
	
	_setup_animations()
	_setup_skills()
	_setup_camera()
	_setup_health_bar()
	
	add_to_group("Player")
	update_ui()
	set_physics_process(true)


func _setup_animations():
	if anim_tree and anim_manager:
		anim_manager.setup(anim_tree)
		anim_manager.idle()


func _setup_skills():
	skills_library = preload("res://Skills.gd").new()
	skills_library.bullet_scene = bullet_scene
	skills_library.parent_player = self
	add_child(skills_library)


func _setup_camera():
	if _is_authority:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.position = Vector3(0, camera_height, camera_distance)
		camera.rotation_degrees = Vector3(-40, 0, 0)
		add_child(camera)
		camera.make_current()
		print("✅ Камера создана")


func _setup_health_bar():
	var health_bar = create_health_bar()
	add_child(health_bar)


# =============================================================================
#  3. ЗДОРОВЬЕ И МАНА
# =============================================================================

func take_damage(amount: int):
	if not _is_authority:
		return
	
	current_health -= amount
	update_health_bar()
	update_ui()
	
	if current_health <= 0:
		die()


func die():
	rpc("die_rpc")
	queue_free()


func update_ui():
	var ui = get_tree().get_first_node_in_group("SkillUI")
	if ui and _is_authority:
		ui.update_health(current_health, max_health)
		ui.update_mana(current_mana, max_mana)


# ---------------------- Health Bar (над головой) ----------------------

func create_health_bar() -> Node3D:
	var health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar"
	health_bar_container.position.y = 1.2
	
	var background = MeshInstance3D.new()
	background.mesh = BoxMesh.new()
	background.mesh.size = Vector3(1.0, 0.1, 0.1)
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.3, 0.3, 0.3)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	background.material_override = bg_material
	health_bar_container.add_child(background)
	
	var foreground = MeshInstance3D.new()
	foreground.mesh = BoxMesh.new()
	foreground.mesh.size = Vector3(1.0, 0.1, 0.1)
	var fg_material = StandardMaterial3D.new()
	fg_material.albedo_color = Color(0, 1, 0)
	fg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	foreground.material_override = fg_material
	foreground.position.x = 0
	health_bar_container.add_child(foreground)
	foreground.set_meta("foreground", true)
	
	return health_bar_container


func update_health_bar():
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		for child in health_bar.get_children():
			if child.has_meta("foreground"):
				var percent = float(current_health) / max_health
				child.mesh.size.x = max(0.01, 1.0 * percent)
				child.position.x = -(1.0 - percent) / 2


# =============================================================================
#  4. ТАРГЕТ ДЛЯ СКИЛЛОВ
# =============================================================================

func set_target(target: Node3D):
	if skills_library:
		skills_library.set_target(target)


# =============================================================================
#  5. ПЕРЕДВИЖЕНИЕ
# =============================================================================

func move_to_click():
	if not camera or is_attacking:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	
	if result:
		target_position = result.position
		is_moving = true
		var dir = (target_position - global_position).normalized()
		dir.y = 0
		if dir != Vector3.ZERO:
			look_at(global_position + dir, Vector3.UP)


func _physics_process(delta):
	_apply_gravity(delta)
	
	if _is_authority:
		_physics_authority()
	else:
		move_and_slide()


func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0


func _physics_authority():
	# Атакуем — стоим на месте
	if is_attacking:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		sync_position.rpc(global_position, rotation.y)
		return
	
	# Двигаемся к цели
	if is_moving:
		var direction = target_position - global_position
		direction.y = 0
		var distance = direction.length()
		
		# Пришли
		if distance < 0.8:
			is_moving = false
			velocity.x = 0
			velocity.z = 0
			_set_animation("idle")
			move_and_slide()
			sync_position.rpc(global_position, rotation.y)
			return
		
		# Бежим
		var move_dir = direction.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		_set_animation("run")
	else:
		# Стоим
		_set_animation("idle")
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()
	sync_position.rpc(global_position, rotation.y)


# =============================================================================
#  6. АНИМАЦИИ
# =============================================================================

func _set_animation(anim_name: String):
	if _last_anim != anim_name:
		_last_anim = anim_name
		sync_animation.rpc(anim_name)
	if anim_manager:
		match anim_name:
			"idle": anim_manager.idle()
			"run": anim_manager.run()


# =============================================================================
#  7. ВВОД
# =============================================================================

func _input(event):
	if not _is_authority:
		return
	
	var ui = get_tree().get_first_node_in_group("UI")
	if ui and ui.visible:
		return
	
	# ПКМ — движение
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not is_attacking:
			move_to_click()
	
	# Клавиши скиллов
	if event is InputEventKey and event.pressed and not event.is_echo():
		var skill_id = 0
		match event.keycode:
			KEY_Q: skill_id = 1
			KEY_W: skill_id = 2
			KEY_E: skill_id = 3
			KEY_R: skill_id = 4
		
		if skill_id > 0:
			start_attack(skill_id)


# =============================================================================
#  8. АТАКА
# =============================================================================

func start_attack(skill_id: int):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Защита от спама
	if current_time - _last_shot_time < _min_shot_interval:
		return
	if _attack_in_progress or is_attacking:
		return
	if not is_inside_tree():
		return
	
	# Получаем скилл
	var skill_instance = skills_library.get_skill_instance(skill_id)
	if not skill_instance:
		return
	if not skill_instance.can_activate():
		return
	
	# Начинаем
	_last_shot_time = current_time
	_attack_id += 1
	var my_attack_id = _attack_id
	
	# Определяем цель и направление
	var attack_data = _get_attack_direction(skill_instance)
	attack_target = attack_data.target
	
	# Блокируем
	_attack_in_progress = true
	is_attacking = true
	pending_skill_id = skill_id
	
	# Тратим ресурсы
	_consume_mana(skill_instance)
	_start_cooldown(skill_instance, skill_id)
	
	# Останавливаем движение
	is_moving = false
	velocity.x = 0
	velocity.z = 0
	
	# Поворот
	if attack_data.dir != Vector3.ZERO:
		look_at(global_position + attack_data.dir, Vector3.UP)
	
	# Анимация
	if anim_manager:
		anim_manager.aim()
	
	# RPC
	_send_attack_rpc(skill_id, attack_data)
	
	# Ждём Draw
	await _wait_for_draw()
	if not _validate_attack(my_attack_id):
		return
	
	# Выстрел
	if _is_authority:
		if attack_data.dir != Vector3.ZERO:
			look_at(global_position + attack_data.dir, Vector3.UP)
		skill_instance._execute_with_direction(attack_data.dir, attack_data.target_pos, attack_data.is_targeted, attack_target)
	
	# Ждём Recoil
	await _wait_for_recoil()
	if not _validate_attack(my_attack_id):
		return
	
	# Завершаем
	_reset_attack_state()


# ---------------------- Вспомогательные методы атаки ----------------------

class AttackData:
	var dir: Vector3 = Vector3.ZERO
	var target_pos: Vector3 = Vector3.ZERO
	var is_targeted: bool = false
	var target: Node3D = null


func _get_attack_direction(skill_instance) -> AttackData:
	var data = AttackData.new()
	
	if skill_instance.skill_data.skill_type == "targeted" and skills_library.current_target and is_instance_valid(skills_library.current_target):
		data.target = skills_library.current_target
		data.dir = (data.target.global_position - global_position).normalized()
		data.dir.y = 0
		data.target_pos = data.target.global_position
		data.is_targeted = true
	else:
		data.target = null
		data.dir = skills_library.get_shoot_direction()
		data.target_pos = global_position + data.dir * 10
		data.is_targeted = false
	
	return data


func _consume_mana(skill_instance):
	current_mana -= skill_instance.skill_data.mana_cost
	update_ui()


func _start_cooldown(skill_instance, skill_id: int):
	skill_instance.cooldown_timer = skill_instance.skill_data.cooldown
	var ui = get_tree().get_first_node_in_group("SkillUI")
	if ui:
		ui.start_cooldown(skill_id)


func _send_attack_rpc(skill_id: int, data: AttackData):
	if data.target:
		rpc("start_attack_rpc", skill_id, rotation.y, data.dir, data.target_pos, data.is_targeted, data.target.get_path())
	else:
		rpc("start_attack_rpc", skill_id, rotation.y, data.dir, data.target_pos, data.is_targeted, NodePath())


func _wait_for_draw():
	if anim_manager:
		await anim_manager.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout


func _wait_for_recoil():
	if anim_manager:
		await anim_manager.recoil_finished
	else:
		await get_tree().create_timer(0.3).timeout


func _validate_attack(my_attack_id: int) -> bool:
	if my_attack_id != _attack_id:
		return false
	if not is_inside_tree():
		_attack_in_progress = false
		is_attacking = false
		return false
	return true


func _reset_attack_state():
	is_attacking = false
	attack_target = null
	pending_skill_id = 0
	_attack_in_progress = false


# =============================================================================
#  9. RPC МЕТОДЫ
# =============================================================================

# ---------------------- Начало атаки (reliable) ----------------------
@rpc("any_peer", "call_local", "reliable")
func start_attack_rpc(skill_id: int, rot: float, dir: Vector3, target_pos: Vector3, is_targeted: bool, target_path: NodePath):
	if _is_authority:
		return
	
	is_attacking = true
	pending_skill_id = skill_id
	rotation.y = rot
	
	_saved_dir = dir
	_saved_target_pos = target_pos
	_saved_is_targeted = is_targeted
	
	if not target_path.is_empty():
		attack_target = get_node_or_null(target_path)
	else:
		attack_target = null
	
	if anim_manager:
		anim_manager.aim()
	
	_play_attack_sequence(skill_id)


func _play_attack_sequence(skill_id: int):
	await _wait_for_draw()
	
	if not is_inside_tree():
		is_attacking = false
		return
	
	if _saved_dir != Vector3.ZERO:
		look_at(global_position + _saved_dir, Vector3.UP)
	
	var skill_instance = skills_library.get_skill_instance(skill_id)
	if skill_instance:
		skill_instance._execute_with_direction(_saved_dir, _saved_target_pos, _saved_is_targeted, attack_target)
	
	await _wait_for_recoil()
	
	is_attacking = false
	attack_target = null
	pending_skill_id = 0


# ---------------------- Позиция (unreliable — 60 раз/сек) ----------------------
@rpc("any_peer", "unreliable", "call_local")
func sync_position(new_pos: Vector3, new_rot: float):
	if _is_authority:
		return
	global_position = new_pos
	rotation.y = new_rot


# ---------------------- Анимация (reliable — только при смене) ----------------------
@rpc("any_peer", "reliable", "call_local")
func sync_animation(anim_name: String):
	if _is_authority:
		return
	if is_attacking:
		return
	if not anim_manager:
		return
	
	match anim_name:
		"idle": anim_manager.idle()
		"run": anim_manager.run()
		"attack": anim_manager.attack()
		"aim": anim_manager.aim()
		"hit": anim_manager.hit()
		"die": anim_manager.die()


# ---------------------- Смерть ----------------------
@rpc("any_peer", "call_local", "reliable")
func die_rpc():
	if _is_authority:
		return
	queue_free()


# =============================================================================
# 10. КАМЕРА (_process)
# =============================================================================

func _process(delta):
	if camera and _is_authority:
		camera.global_position = global_position + Vector3(0, camera_height, camera_distance)
		camera.look_at(global_position)
