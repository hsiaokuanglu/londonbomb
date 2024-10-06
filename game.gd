extends Control

var is_dragging = false
var offset = Vector2()
var cutter

func _ready():
	name = str(get_multiplayer_authority())
	#cutter = $Control/TouchArea/Cutter
	#cutter.name += str(multiplayer.get_unique_id())
	#print(cutter.name)
	pass

func _start_game():
	pass

func _on_touch_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		#if is_multiplayer_authority():
		$Control/TouchArea/Cutter.position = event.position
		#rpc("remote_set_position", event.position)
		#if event.pressed and shape_idx != -1:
			#is_dragging = true
			#offset = position - event.position  # Calculate offset
		#elif not event.pressed:
			#is_dragging = false
#
	#if event is InputEventMouseMotion and is_dragging:
		#position = event.position + offset  # Update position

@rpc("any_peer", "unreliable")
func remote_set_position(authority_position):
	$Control/TouchArea/Cutter.position = authority_position
