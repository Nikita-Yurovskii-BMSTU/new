extends Node

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_send_move_command(event.position)


func _send_move_command(screen_position: Vector2):
	var camera = get_tree().current_scene.get_node_or_null("Camera3D")
	if not camera:
		return
	
	var from = camera.project_ray_origin(screen_position)
	var to = from + camera.project_ray_normal(screen_position) * 1000.0
	
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # слой земли
	
	var result = space_state.intersect_ray(query)
	if result:
		var my_player = _get_my_player()
		if my_player:
			my_player.request_move.rpc(result.position)


func _get_my_player() -> Node:
	var my_id = multiplayer.get_unique_id()
	var players_node = get_tree().current_scene.get_node_or_null("Players")
	if not players_node:
		return null
	
	for child in players_node.get_children():
		if child.get_multiplayer_authority() == my_id:
			return child
	return null
