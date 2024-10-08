extends Area2D

var cuttable:= true
var mouse_down := false
var wire_type:= ""
var wire_id: int
signal wire_cut

func _on_wire_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if mouse_down and cuttable:
		if wire_type == "defuse_wire":
			$Sprite.play("defuse_wire")
		elif wire_type == "safe_wire":
			$Sprite.play("safe_wire")
		else:
			$Sprite.play("cut")
		wire_cut.emit(wire_type, wire_id)

func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			mouse_down = true
		else:
			mouse_down = false
