extends Node
class_name PlayerStats

onready var invencibility_timer: Timer = get_node("InvencibilityTimer")

var shielding: bool = false

var base_health: int = 15
var base_mana: int = 10
var base_attack: int = 1
var base_magic_attack: int = 3
var base_defense: int = 1

var bonus_health: int = 0
var bonus_mana: int = 0
var bonus_attack: int = 0
var bonus_magic_attack: int = 0
var bonus_defense: int = 0

var current_mana: int
var current_health: int

var max_mana: int
var max_health: int

var current_exp: int = 0

var level: int = 1
var level_dict: Dictionary = {
	"1": 25,
	"2": 33,
	"3": 49,
	"4": 66,
	"5": 93,
	"6": 135,
	"7": 186,
	"8": 351,
	"9": 356,
}

export(PackedScene) var floating_text

export(NodePath) onready var player = get_node(player) as KinematicBody2D
export(NodePath) onready var collision_area = get_node(collision_area) as Area2D

func _ready() -> void:
	current_mana = base_mana + bonus_mana
	max_mana = current_mana
	
	current_health = base_health + bonus_health
	max_health = current_health
	
	get_tree().call_group("bar_container", "init_bar", max_health, max_mana, level_dict[str(level)])
	

func update_exp(value: int) -> void:
	current_exp += value
	spawn_floating_text("+", "Exp", value)
	get_tree().call_group("bar_container", "update_bar", "ExpBar", current_exp)
	if current_exp >= level_dict[str(level)] and level < 9:
		var leftover: int = current_exp - level_dict[str(level)]
		current_exp = leftover
		on_level_up()
		level += 1
		
	elif current_exp >= level_dict[str(level)] and level == 9:
		current_exp = level_dict[str(level)]

func on_level_up() -> void:
	current_mana = base_mana + bonus_mana
	current_health = base_health + bonus_health
	
	get_tree().call_group("bar_container", "update_bar", "ManaBar", current_mana)
	get_tree().call_group("bar_container", "update_bar", "HealthBar", current_health)
	
	yield(get_tree().create_timer(0.2), "timeout")
	get_tree().call_group("bar_container", "reset_exp_bar", level_dict[str(level)], current_exp)
	
	
func update_health(type: String, value: int) -> void:
	match type:
		"Increase":
			current_health += value
			spawn_floating_text("+", "Heal", value)
			if current_health >= max_health:
				current_health = max_health
			
		"Decrease":
			verify_shield(value)
			if current_health <= 0:
				player.dead = true
			else:
				player.on_hit = true
				player.attacking = false
				
	get_tree().call_group("bar_container", "update_bar", "HealthBar", current_health)

func verify_shield(value: int) -> void:
	if shielding:
		if (base_defense + bonus_defense) >= value:
			return
			
		var damage = abs((base_defense + bonus_defense) - value)
		spawn_floating_text("-", "Damage", damage)
		current_health -= damage
		
	else:
		spawn_floating_text("-", "Damage", value)
		current_health -= value

func update_mana(type: String, value: int) -> void:
	match type:
		"Increase":
			current_mana += value
			spawn_floating_text("+", "Mana", value)
			if current_mana >= max_mana:
				current_mana = max_mana
				
		"Decrease":
			current_mana -= value
			spawn_floating_text("-", "Mana", value)
			
	get_tree().call_group("bar_container", "update_bar", "ManaBar", current_mana)

func _process(_delta) -> void:
#	if Input.is_action_just_pressed("ui_select"):
#		update_health("Decrease", 5)
	pass
	




func on_collision_area_entered(area):
	if area.name == "EnemyAttackArea":
		update_health("Decrease", area.damage)
		collision_area.set_deferred("monitoring", false)
		invencibility_timer.start(area.invencibility_timer)


func on_invencibility_timeout():
	collision_area.set_deferred("monitoring", true)
	
func spawn_floating_text(type_sign: String, type: String, value: int) -> void:
	var text: FloatText = floating_text.instance()
	text.rect_global_position = player.global_position
	
	text.type = type
	text.value = value
	text.type_sign = type_sign
	
	get_tree().root.call_deferred("add_child", text)
