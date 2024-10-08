extends Node

var player_id: int 
var client_scene
var cut_one: bool
var wires
var wire_scenes
@onready
var _wire_loc = $WireBoxCon/Wires
func _ready():
	name = str(multiplayer.get_unique_id())
	wires = []
	wire_scenes = []
	$WireBoxCon.hide()
	#$WireBoxCon/Exit.position = Vector2(client_scene.position().x,
										#client_scene.position().y)
	

func set_data(id, c_scene):
	player_id = id
	client_scene = c_scene
	$VBoxContainer/WireNumCon/Count.text = "5"
	

func set_info(p_name):
	$VBoxContainer/Name.text = p_name


func set_claim(claim_info: Dictionary):
	#print(claim_info)
	$VBoxContainer/ClaimUI/BombCon/Count.text = claim_info["bomb"]
	$VBoxContainer/ClaimUI/DWireCon/Count.text = claim_info["defuse_wire"]

func debug_button():
	init_wire_box(["bomb", "defuse_wire", "safe_wire", "safe_wire", "safe_wire"])


func _on_button_2_pressed() -> void:
	set_wire_box(["bomb", "defuse_wire", "safe_wire", "safe_wire", "safe_wire"],
				2)


func init_wire_box(_wires):
	$WireBoxCon.hide()
	remove_wire_box()
	$VBoxContainer/WireNumCon/Count.text = str(_wires.size())
	wires = _wires
	var wire_x = 250
	var pos_x = $WireBoxCon.position.x / 2
	var pos_y = $WireBoxCon.position.y / 2 - _wires.size() / 2 * 120
	#pos_x = 0
	var id = 0
	for _wire in _wires:
		var wire_scene = preload("res://wire.tscn").instantiate()
		wire_scene.position = Vector2(pos_x, pos_y)
		wire_scene.wire_cut.connect(_on_wire_wire_cut)
		wire_scene.wire_type = _wire
		wire_scene.wire_id = id
		_wire_loc.add_child(wire_scene)
		wire_scenes.append(wire_scene)
		pos_y += 120
		id += 1

func remove_wire_box():
	wire_scenes.clear()
	for ch in _wire_loc.get_children():
		_wire_loc.remove_child(ch)
		ch.queue_free()
		

func set_wire_box(_wires, picked_wire_id):
	$VBoxContainer/WireNumCon/Count.text = str(_wires.size())
	for ch in _wire_loc.get_children():
		if ch.wire_id == picked_wire_id:
			if ch.wire_type == "defuse_wire":
				ch.get_node("Sprite").play("defuse_wire")
			elif ch.wire_type == "safe_wire":
				ch.get_node("Sprite").play("safe_wire")
			else:
				ch.get_node("Sprite").play("cut")
			#print(ch.wire_type)
		#
	#var wire_x = 250
	#var pos_x = $WireBoxCon.position.x / 2
	#var pos_y = $WireBoxCon.position.y / 2 - _wires.size() / 2 * 120
	##pos_x = 0
	#for _wire in _wires:
		#var wire_scene = preload("res://wire.tscn").instantiate()
		#wire_scene.position = Vector2(pos_x, pos_y)
		#wire_scene.wire_cut.connect(_on_wire_wire_cut)
		#wire_scene.wire_type = _wire
		#$WireBoxCon.add_child(wire_scene)
		#wire_scenes.append(wire_scene)
		#pos_y += 120
		#
		

func _on_button_pressed() -> void:
	$WireBoxCon.show()
	#$WireBoxCon.position = Vector2(get_viewport().size.x / 2 - $WireBoxCon.position.x /2 - self.position.x,
									#get_viewport().size.y / 2- $WireBoxCon.position.y /2 - self.position.y)
	#$WireBoxCon.position = Vector2.ZERO

func _hide_cut_button():
	$VBoxContainer/CutButton.hide()

func _show_cut_button():
	$VBoxContainer/CutButton.show()


func _on_wire_wire_cut(wire_type, wire_id) -> void:
	print("cut ", wire_type)
	client_scene.cut_wire_player(player_id, wire_type, wire_id)
	for wire in wire_scenes:
		wire.cuttable = false


func _on_exit_pressed() -> void:
	$WireBoxCon.hide()
