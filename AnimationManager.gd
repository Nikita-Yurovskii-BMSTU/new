extends Node

enum AnimState { IDLE, RUN, ATTACK, DRAW, HIT, DIE }

var current_state: AnimState = AnimState.IDLE
var anim_tree: AnimationTree = null
var anim_state = null
var is_playing_attack: bool = false
var _draw_finished_emitted: bool = false
var _recoil_finished_emitted: bool = false

signal animation_finished
signal recoil_finished


func setup(animation_tree: AnimationTree):
	anim_tree = animation_tree
	if anim_tree:
		anim_tree.active = true
		anim_state = anim_tree.get("parameters/playback")
		print("AnimationManager: установлен")


func play(state: AnimState, force: bool = false):
	if not anim_state:
		return
	
	if current_state == state and not force:
		return
	
	current_state = state
	
	match state:
		AnimState.IDLE:
			anim_state.travel("Idle")
		AnimState.RUN:
			anim_state.travel("Run")
		AnimState.ATTACK:
			anim_state.travel("Attack")
		AnimState.DRAW:
			is_playing_attack = true
			_draw_finished_emitted = false
			_recoil_finished_emitted = false
			anim_state.travel("Draw")
		AnimState.HIT:
			anim_state.travel("Hit")
		AnimState.DIE:
			anim_state.travel("Die")


func idle():
	if is_playing_attack:
		return
	play(AnimState.IDLE)

func run():
	if is_playing_attack:
		return
	play(AnimState.RUN)

func attack(): 
	play(AnimState.ATTACK)

func aim():
	is_playing_attack = true
	_draw_finished_emitted = false
	_recoil_finished_emitted = false
	play(AnimState.DRAW, true)
	_start_draw_timer()

func hit(): 
	play(AnimState.HIT)

func die(): 
	play(AnimState.DIE)


func get_current_state() -> AnimState:
	return current_state


func _start_draw_timer():
	var old_timer = get_node_or_null("DrawTimer")
	if old_timer:
		old_timer.queue_free()
	
	var timer = Timer.new()
	timer.name = "DrawTimer"
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(_on_draw_finished)
	add_child(timer)
	timer.start()
	
	print("Таймер Draw запущен на ", timer.wait_time, " сек")


func _on_draw_finished():
	if _draw_finished_emitted:
		return
	
	_draw_finished_emitted = true
	print("Draw закончился - выстрел!")
	animation_finished.emit()


func _process(delta):
	if not anim_tree or not anim_state:
		return
	
	if not is_playing_attack:
		return
	
	if not is_inside_tree():
		return
	
	var current_anim = anim_state.get_current_node()
	
	# Отправляем сигнал Draw только ОДИН раз
	if current_anim != "Draw" and not _draw_finished_emitted:
		_on_draw_finished()
	
	# Отправляем сигнал Recoil только ОДИН раз
	if current_anim != "Draw" and current_anim != "Recoil" and current_anim != "" and not _recoil_finished_emitted:
		_recoil_finished_emitted = true
		print("Recoil закончился - можно двигаться")
		is_playing_attack = false
		recoil_finished.emit()
