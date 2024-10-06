extends Node

var player_id: int 
var client_scene

func _ready():
	name = str(multiplayer.get_unique_id())

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

func set_uncut_wire_count(wire_count: int):
	$VBoxContainer/WireNumCon/Count.text = str(wire_count)

func _on_button_pressed() -> void:
	client_scene.rpc("pick_player", player_id)

func _hide_cut_button():
	$VBoxContainer/CutButton.hide()

func _show_cut_button():
	$VBoxContainer/CutButton.show()
