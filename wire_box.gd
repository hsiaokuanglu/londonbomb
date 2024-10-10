extends Node2D

var wire_box_height = 200
var wire_gap = 100
var wire_scenes = Dictionary()
var cur_player_id:int
var cur_wire_data
var _already_cut: bool
var player_id_names = Dictionary()
signal wire_box_cut
signal hide_wire_box
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#for ch_i in $Wires.get_children():
		#for ch_j in $Wires.get_children():
			#ch_i.wire_cut.connect(ch_j._on_other_wire_cut)

func set_player_names(id_names):
	player_id_names = id_names
	

func connect_wire_cut_signal():
	for ch_i in $Wires.get_children():
		ch_i.wire_cut.connect(on_wire_cut)
		for ch_j in $Wires.get_children():
			ch_i.wire_cut.connect(ch_j._on_other_wire_cut)

func _clear_wire_scenes():
	wire_scenes.clear()
	for ch in $Wires.get_children():
		$Wires.remove_child(ch)
		ch.queue_free()

# wire["type"]
# wire["id"]s
func set_wires(player_id, wires, _already_cut):
	_clear_wire_scenes()
	cur_player_id = player_id
	if player_id in player_id_names:
		$PlayerName.text = player_id_names[player_id]
	cur_wire_data = wires
	var pos_x = 0
	var pos_y = - wire_box_height
	for wire_data in wires:
		var wire_scene = preload("res://wire.tscn").instantiate()
		wire_scene.wire_type = wire_data["type"]
		wire_scene.wire_id = wire_data["id"]
		wire_scene.position = Vector2(pos_x, pos_y)
		wire_scenes[wire_data["id"]] = wire_scene
		if _already_cut:
			wire_scene.cuttable = false
		if wire_data["is_cut"]:
			wire_scene._set_cut_frame()
			wire_scene.cuttable = false
		else:
			wire_scene.set_wire_un_cut_hidden()
		pos_y += wire_gap
		$Wires.add_child(wire_scene)
		
	#for wire in wires:
		#var wire_scene = preload("res://wire.tscn").instantiate()
		#wire_scene.wire_type = wire["type"]
		#wire_scene.wire_id = id
		#wire_scene.position = Vector2(pos_x, pos_y)
		#wire_scenes[id] = wire_scene
		##
		#pos_y += wire_gap
		#$Wires.add_child(wire_scene)
	
	connect_wire_cut_signal()


func new_update_wires(player_id, wire_data):
	for wire in wire_data:
		if wire["id"] in wire_scenes: # Invalid access when cut bomb
			var wire_scene = wire_scenes[wire["id"]]
			if wire["is_cut"]:
				wire_scene.is_cut = true
				wire_scene.play_cut()


func update_wires(wires):
	cur_wire_data = wires
	for wire in wires:
		if wire["is_cut"]:
			var wire_scene = wire_scenes[wire["id"]]
			if not wire_scene.is_cut:
				wire_scene.is_cut = true
				wire_scene._set_cut_frame()

func set_my_box(player_id, wires):
	#$Sprite2D.hide()
	$ExitButton.hide()
	$Frame.hide()
	wire_box_height = 50
	wire_gap = 25
	$Sprite2D.play("my_box")
	wires.shuffle()
	set_wires(player_id, wires, true)
	$PlayerName.text = "My Wires"
	$PlayerName.position = Vector2(0, -150)
	for wire in wire_scenes.values():
		#wire.cuttable = false
		#print(wire.wire_type)
		wire.set_wire_uncut_sprite()
		wire.set_scale(Vector2(0.7, 0.7))


func on_wire_cut(wire_type, wire_id) -> void:
	#print("cut")
	#print(wire_type, wire_id)
	for wire in cur_wire_data:
		if wire["id"] == wire_id:
			wire["is_cut"] = true
	wire_box_cut.emit(cur_player_id, cur_wire_data, wire_type)


func _on_button_pressed() -> void:
	set_my_box(1111, [{"type": "defuse_wire", "id": 0, "is_cut": true},
					{"type": "safe_wire", "id": 1, "is_cut": false},
					{"type": "safe_wire", "id": 2, "is_cut": false},
					{"type": "safe_wire", "id": 3, "is_cut": true},
					{"type": "bomb", "id": 4, "is_cut": false}])


func _on_button_2_pressed() -> void:
	update_wires([{"type": "defuse_wire", "id": 0, "is_cut": true},
					{"type": "safe_wire", "id": 1, "is_cut": false},
					{"type": "safe_wire", "id": 2, "is_cut": false},
					{"type": "safe_wire", "id": 3, "is_cut": true},
					{"type": "bomb", "id": 4, "is_cut": false}])

func _on_button_3_pressed():
	set_wires(1111, 
			[{"type": "defuse_wire", "id": 0, "is_cut": true},
			{"type": "safe_wire", "id": 1, "is_cut": false},
			{"type": "safe_wire", "id": 2, "is_cut": false},
			{"type": "safe_wire", "id": 3, "is_cut": true},
			{"type": "bomb", "id": 4, "is_cut": false}],
			false)

func play_cut_animation(wire_type):
	for wire in wire_scenes.values():
		if wire.wire_type == wire_type:
			if not wire.is_cut:
				wire.is_cut = true
				wire.play_cut()
				return
			
		

func get_wire_data():
	var wire_data_list = []
	var wire_data = Dictionary()
	for wire_scene in wire_scenes.values():
		wire_data["type"] = wire_scene.wire_type
		wire_data["id"] = wire_scene.wire_id
		wire_data["is_cut"] = wire_scene.is_cut
		wire_data_list.append(wire_data)
	return wire_data_list


func _on_exit_button_pressed() -> void:
	hide()
	hide_wire_box.emit()
