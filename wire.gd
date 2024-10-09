extends Area2D

var cuttable:= true
var mouse_down := false
var wire_type:= ""
var wire_id: int
var is_cut := false
signal wire_cut


func _on_wire_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if mouse_down and cuttable:
		is_cut = true
		play_cut()
		cuttable = false
		wire_cut.emit(wire_type, wire_id)

func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			mouse_down = true
		else:
			mouse_down = false

func set_wire_uncut_sprite():
	if wire_type == "defuse_wire":
		$Sprite.play("defuse_wire")
	elif wire_type == "safe_wire":
		$Sprite.play("safe_wire")
	else:
		$Sprite.play("default")

func _on_other_wire_cut(_wire_type, _wire_id):
	cuttable = false

func play_cut():
	if wire_type == "defuse_wire":
		$Sprite.play("defuse_wire")
	elif wire_type == "safe_wire":
		$Sprite.play("safe_wire")
	else:
		$Sprite.play("cut")


func _on_button_pressed() -> void:
	$Sprite.play("safe_wire_cut")


func _on_mouse_entered() -> void:
	print("mouse entered")
