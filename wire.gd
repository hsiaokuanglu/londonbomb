extends Area2D

var cuttable:= true
var mouse_down := false
var wire_type:= ""
var wire_id: int
var is_cut := false
var wire_random_look = 1
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
	wire_random_look = randi_range(1,2)
	if wire_type == "defuse_wire":
		$Sprite.play("defuse_wire")
	elif wire_type == "safe_wire":
		var x = str("safe_wire", str(wire_random_look))
		$Sprite.play(x)
	elif wire_type == "bomb":
		$Sprite.play("bomb")
	else:
		$Sprite.play("default")



func set_wire_un_cut_hidden():
	wire_random_look = randi_range(1,2)
	var x = str("safe_wire", str(wire_random_look))
	$Sprite.play(x)


func _on_other_wire_cut(_wire_type, _wire_id):
	cuttable = false

func play_cut():
	if wire_type == "defuse_wire":
		$Sprite.play("defuse_wire_cut")
	elif wire_type == "safe_wire":
		#$Sprite.play("safe_wire_cut2")
		$Sprite.play(str("safe_wire_cut", str(wire_random_look)))
	elif wire_type == "bomb":
		$Sprite.play("bomb_cut")
	else:
		$Sprite.play("cut")


func _on_button_pressed() -> void:
	wire_type = "safe_wire"
	#set_wire_uncut_sprite()
	#play_cut()
	$Sprite.set_frame(3)

func _set_cut_frame():
	if wire_type == "defuse_wire":
		$Sprite.set_frame(3)
	elif wire_type == "safe_wire":
		#$Sprite.play("safe_wire_cut2")
		$Sprite.set_frame(3)
	elif wire_type == "bomb":
		$Sprite.set_frame(3)
	else:
		$Sprite.set_frame(0)

func _on_mouse_entered() -> void:
	print("mouse entered")
