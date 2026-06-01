extends Control

@onready var health_bar = $HealthBar
@onready var mana_bar = $ManaBar
@onready var skill_panel = $SkillPanel
@onready var skill1 = $SkillPanel/Skill1
@onready var skill2 = $SkillPanel/Skill2
@onready var skill3 = $SkillPanel/Skill3
@onready var skill4 = $SkillPanel/Skill4

var skill_cooldowns = {
	1: 0.0,
	2: 0.0,
	3: 0.0,
	4: 0.0,
}

var player: Node = null


func _ready():
	add_to_group("SkillUI")
	
	setup_ui_style()
	
	if skill1: skill1.pressed.connect(_on_skill_pressed.bind(1))
	if skill2: skill2.pressed.connect(_on_skill_pressed.bind(2))
	if skill3: skill3.pressed.connect(_on_skill_pressed.bind(3))
	if skill4: skill4.pressed.connect(_on_skill_pressed.bind(4))
	
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = 100
	if mana_bar:
		mana_bar.max_value = 100
		mana_bar.value = 100


func setup_ui_style():
	if not skill_panel:
		return
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel_style.set_corner_radius_all(20)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.8, 0.6, 0.2)
	skill_panel.add_theme_stylebox_override("panel", panel_style)
	
	var buttons = [skill1, skill2, skill3, skill4]
	for button in buttons:
		if not button:
			continue
		
		button.custom_minimum_size = Vector2(80, 80)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		btn_style.set_border_width_all(2)
		btn_style.border_color = Color(0.8, 0.6, 0.2)
		btn_style.set_corner_radius_all(10)
		button.add_theme_stylebox_override("normal", btn_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.3, 0.4, 0.9)
		hover_style.set_border_width_all(2)
		hover_style.border_color = Color(0.8, 0.6, 0.2)
		hover_style.set_corner_radius_all(10)
		button.add_theme_stylebox_override("hover", hover_style)
		
		button.add_theme_font_size_override("font_size", 20)
	
	if health_bar:
		var hp_style = StyleBoxFlat.new()
		hp_style.bg_color = Color(0.9, 0.2, 0.2)
		hp_style.set_corner_radius_all(5)
		health_bar.add_theme_stylebox_override("fill", hp_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		bg_style.set_border_width_all(2)
		bg_style.border_color = Color(0.8, 0.6, 0.2)
		bg_style.set_corner_radius_all(5)
		health_bar.add_theme_stylebox_override("background", bg_style)
		
		health_bar.add_theme_font_size_override("font_size", 16)
	
	if mana_bar:
		var mana_style = StyleBoxFlat.new()
		mana_style.bg_color = Color(0.2, 0.4, 0.9)
		mana_style.set_corner_radius_all(5)
		mana_bar.add_theme_stylebox_override("fill", mana_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		bg_style.set_border_width_all(2)
		bg_style.border_color = Color(0.8, 0.6, 0.2)
		bg_style.set_corner_radius_all(5)
		mana_bar.add_theme_stylebox_override("background", bg_style)
		
		mana_bar.add_theme_font_size_override("font_size", 16)


func _on_skill_pressed(skill_id: int):
	if skill_cooldowns[skill_id] > 0:
		print("Скилл ", skill_id, " на перезарядке!")
		return
	
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			print("Игрок не найден!")
			return
	
	# Вызываем скилл у игрока
	if player.has_method("use_skill"):
		player.use_skill(skill_id)


func update_cooldown(skill_id: int, cooldown: float):
	skill_cooldowns[skill_id] = cooldown
	
	var button = get_skill_button(skill_id)
	if not button:
		return
	
	if cooldown > 0:
		button.text = str(int(cooldown) + 1)
		button.disabled = true
	else:
		button.text = get_skill_default_text(skill_id)
		button.disabled = false


func get_skill_default_text(skill_id: int) -> String:
	match skill_id:
		1: return "Q"
		2: return "W"
		3: return "E"
		4: return "R"
	return ""


func get_skill_button(skill_id: int) -> Button:
	match skill_id:
		1: return skill1
		2: return skill2
		3: return skill3
		4: return skill4
	return null


func update_health(value: float, max_value: float):
	if health_bar:
		health_bar.value = value
		health_bar.max_value = max_value
#		health_bar.text = str(int(value)) + " / " + str(int(max_value))


func update_mana(value: float, max_value: float):
	if mana_bar:
		mana_bar.value = value
		mana_bar.max_value = max_value
		#mana_bar.text = str(int(value)) + " / " + str(int(max_value))
