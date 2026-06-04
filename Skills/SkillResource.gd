extends Resource
class_name SkillResource

@export var id: int = 0
@export var skill_name: String = "Unknown"
@export var description: String = ""
@export var mana_cost: int = 0
@export var cooldown: float = 0.0
@export var skill_type: String = "skillshot"  # "targeted", "skillshot", "cone", "aoe", "self"
@export var animation_name: String = "Draw"
@export var effect_scene: PackedScene
@export var damage: int = 10
@export var speed: float = 40.0
@export var lifetime: float = 3.0
@export var icon: Texture2D
@export var key_binding: String = ""

# Дополнительные параметры
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0
@export var heal_amount: int = 0
@export var aoe_radius: float = 0.0
