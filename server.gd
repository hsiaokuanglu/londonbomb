extends Node

var multiplayer_peer = WebSocketMultiplayerPeer.new()
var key_path = "res://ssl/selfsigned.key"
var cert_path = "res://ssl/selfsigned.crt"
var port = 8765
var url = "wss://luraykuang1998.online:80"
var debug = false
#var debug = true
#var url = "ws://localhost:8765" # change TLSOptions.client()
#var connected_peer_ids = []
var local_player_character
var _players = Dictionary()
var _roles = Dictionary()
var _cards = Dictionary()
var _player_cards = Dictionary()
var _round: int
var _hand
var _cut_this_round: int
var _defuse_wire_cut: int
var _new_global_card = Dictionary()
var _already_cut: bool
var _i_have_bomb: bool
var _showing_declare: bool
var role_name_good = "Good guy"
var role_name_bad = "Bad guy"
# UI Elements
@onready
var _ui_playerlist = $NetworkContainer/LobbyContainer/PlayerList
@onready
var _ui_settings_container = $NetworkContainer/SettingsContainer
@onready
var _ui_claim = $ClaimUI

func add_player(client_id):
	#connected_peer_ids.append(client_id)
	_players[client_id] = ""
	#var player_character = preload("res://game.tscn").instantiate()
	#player_character.set_multiplayer_authority(client_id)
	#add_child(player_character)
	#if client_id == multiplayer.get_unique_id():
		#local_player_character = player_character

@rpc	
func add_newly_connected_player_character(new_peer_id):
	add_player(new_peer_id)

@rpc
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		add_player(peer_id)



func _ready():
	print(DisplayServer.get_name())
	if DisplayServer.get_name() == "headless":
		_start_server()
	else:
		print("client mode")

func _start_server():
	print("server mode")
	# SSL
	#var cert = X509Certificate.new()
	#cert.load(cert)
	#var key = CryptoKey.new()
	#key.load(key_path)

	var result = multiplayer_peer.create_server(port,"*")
	if result != OK:
		print("Failed to start WebSocket server: ", result)
	else:
		print("WebSocket server running on port ", port)
		multiplayer.multiplayer_peer = multiplayer_peer
		multiplayer.connect("peer_connected", _on_client_connected)
		multiplayer.connect("peer_disconnected", _on_client_disconnected)

func _on_join_pressed() -> void:
	var err
	if debug == true:
		err = multiplayer_peer.create_client(url) # TLSOptions.client()
	else:
		err = multiplayer_peer.create_client(url, TLSOptions.client()) # TLSOptions.client()
	if err == OK:
		print("Connecting to WebSocket server...")

		multiplayer.multiplayer_peer = multiplayer_peer
		multiplayer.connect("connected_to_server", _on_connection_established)	
		multiplayer.connect("connection_failed", _on_connection_error)	

func _on_client_connected(id):
	print("Client connected: ", id)
	rpc("add_newly_connected_player_character", id)
	rpc_id(id, "add_previously_connected_player_characters", _players.keys())
	add_player(id)
	# add previoulsy connected player names
	rpc_id(id, "_add_previously_connected_player_names", _players)

func _on_client_disconnected(id):
	print("Client disconnected: ", id)
	_remove_player(id) # remove from server
	for c_id in _players.keys():
		rpc_id(c_id, "_remove_player", id)


func _on_connection_established():
	print("Connected to server")
	$NetworkContainer/Join.hide()

	_ui_settings_container.show()
	$NetworkContainer/LobbyContainer.show()
	$NetworkContainer/Label.text = "Connected to server"


func _on_connection_error():
	print("Connection error")
	$NetworkContainer/Label.text = "Connection error"

@rpc
func _add_previously_connected_player_names(p_id_names: Dictionary):
	print(p_id_names)
	for id in p_id_names.keys():
		_update_player_name(id, p_id_names[id])

@rpc
func _remove_player(id):
	_players.erase(id)
	_update_player_list()

func _on_settings_apply_button_pressed() -> void:
	var local_id = multiplayer.get_unique_id()
	var _p_name = _ui_settings_container.get_node("NameCon/EnterName").text
	#local_player_character.rpc("_update_player_name", local_id, $SettingsContainer/EnterName.text)
	_update_player_name(local_id, _p_name)
	for id in _players.keys():
		if id != local_id:
			rpc_id(id, "_update_player_name", local_id, _p_name)
	rpc_id(1, "_update_player_name", local_id, _p_name)
	


@rpc("any_peer", "reliable")
func _update_player_name(id, p_name):
	_players[id] = p_name
	_update_player_list()


func _update_player_list():
	_ui_playerlist.clear()
	for _id in _players.keys():
		_ui_playerlist.add_item(_players[_id])


func _on_start_button_pressed() -> void:
	if _players.keys().size() < 4:
		return
	rpc_id(1, "_set_player_grid_server")
	rpc_id(1, "_server_start_game")

@rpc("authority")
func _client_start_game(role):
	_defuse_wire_cut = 0
	_round = 4
	_i_have_bomb = false
	$DefuseWireCon/Number.text = str(_round)
	$DefuseWireCon.show()
	$RoundCon/CountdownNum.text = str(_round)
	$MyWireBox.show()
	$ScrollContainer.show()
	$Results.hide()
	$NetworkContainer.hide()
	$RoleLabel.text = role
	$RoundCon.show()
	_ui_claim.show()
	$OthersWireBox.set_player_names(_players)

func set_roles(ids) -> Dictionary:
	var rtn_role = Dictionary()
	var role_pool = []
	var num_players = ids.size()
	if 7 <= num_players:
		for _i in range(5):
			role_pool.append(role_name_good)
		for _i in range(3):
			role_pool.append(role_name_bad)
	elif 6 <= num_players:
		for _i in range(4):
			role_pool.append(role_name_good)
		for _i in range(2):
			role_pool.append(role_name_bad)
	elif 4 <= num_players:
		for _i in range(3):
			role_pool.append(role_name_good)
		for _i in range(2):
			role_pool.append(role_name_bad)
	role_pool.shuffle()
	ids.shuffle()
	for i in range(num_players):
		rtn_role[ids[i]] = role_pool[i]

	return rtn_role

func set_cards(ids):
	var num_players = ids.size()
	var num_defuse_wire = num_players
	var num_safe_wire = num_players * 5 - num_defuse_wire - 1
	var num_bomb = 1
	var card_pool = []
	for _i in range(num_defuse_wire):
		card_pool.append("defuse_wire")
	for _i in range(num_safe_wire):
		card_pool.append("safe_wire")
	for _i in range(num_bomb):
		card_pool.append("bomb")
	return card_pool

@rpc("authority")
func new_deal_cards_client(new_global_cards):
	_already_cut = false
	var my_id = multiplayer.get_unique_id()
	_new_global_card = new_global_cards
	var new_wires = new_global_cards["in_play"][my_id]
	for p_scene in _player_cards.values():
		p_scene.update_uncut_wire_count(new_wires.size())
	$MyWireBox.set_my_box(my_id, new_wires)
	$DeclareWindow._set_spinbox_max(new_wires.size())

@rpc("authority")
func deal_cards_client(wires):
	# show cut button
	for card in _player_cards.values():
		card._show_cut_button()
	# reset hand
	$HandCon/Hand.clear()
	# set given cards
	_hand = wires
	#var new_wires = []
	for wire_i in _hand:
		var wire_dic = Dictionary()
		wire_dic["type"] = wire_i
		#new_wires.append(wire_dic)
		$HandCon/Hand.add_item(wire_i)
	#$MyWireBox.set_my_box(new_wires)
	# update uncut count
	for p_card in _player_cards.values():
		wires.shuffle()
		p_card.init_wire_box(wires)
	#print(_hand)

func shuffle_wires():
	var all_cards = []
	for id in _players.keys():
		for wire in _new_global_card["in_play"][id]:
			if not wire["is_cut"]:
				all_cards.append(wire["type"])
	all_cards.shuffle()
	return	all_cards

func deal_cards_server(round_i):
	_cards["pool"].shuffle()
	if _new_global_card["in_play"].size() != 0:
		# if this is not the first round
		_cards["pool"] = shuffle_wires()
	#print(_cards["pool"])
	print(_new_global_card["in_play"])
	for id in _players.keys():
		var hand = []
		var new_hand = []
		for i in range(round_i + 1):
			var card_i = _cards["pool"].pop_front()
			hand.append(card_i)
			new_hand.append(Dictionary({"type": card_i,
										"id": i,
										"is_cut": false}))
		_cards["in_play"][id] = hand
		_new_global_card["in_play"][id] = new_hand
		#rpc_id(id, "deal_cards_client", hand)
	for id in _players.keys():
		rpc_id(id, "new_deal_cards_client", _new_global_card)

@rpc("any_peer")
func _set_player_grid_server():
		#set player grid
	for id in _players.keys():
		rpc_id(id, "_set_player_grid", _players)
	

@rpc("authority")
func _set_player_grid(players):
	$ScrollContainer.show()
	for id in players.keys():
		if id != multiplayer.get_unique_id():
			var player_scene = preload("res://player.tscn").instantiate()
			player_scene.set_multiplayer_authority(id)
			player_scene.set_info(players[id])
			player_scene.set_data(id, self)
			$ScrollContainer/PlayerGrid.add_child(player_scene)
			_player_cards[id] = player_scene

@rpc("authority")
func _next_round_client(round):
	_round = round
	_i_have_bomb = false
	$DeclareWindow._set_spinbox_value(0)
	$ClaimUI/HaveBombButton.text = "No Bomb"
	$RoundCon/CountdownNum.text = str(round)
	#$WireBoxWindow.hide()
	$OthersWireBox.hide()
	for p_scene in _player_cards.values():
		p_scene.show()
	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			update_player_scene_have_bomb(id, false)

# server
func _next_round(): # server
	
	if _round == 1:
		bomb_explodes()
	_round -= 1
	for id in _players.keys():
		rpc_id(id, "_next_round_client", _round)
	$RoundCon/CountdownNum.text = str(_round)
	_cut_this_round = 0
	for cards in _cards["in_play"].values():
		_cards["pool"].append_array(cards)
	_cards["in_play"] = Dictionary()
	deal_cards_server(_round)
	


@rpc("any_peer")
func _server_start_game():
	_new_global_card["in_play"] = Dictionary()
	#_set_player_grid(_players)
	# set roles
	_round = 4
	_cut_this_round = 0
	_defuse_wire_cut = 0
	_roles = set_roles(_players.keys())
	for id in _roles.keys():
		rpc_id(id, "_client_start_game", _roles[id])
	# set cards
	_cards["in_play"] = Dictionary()
	_cards["pool"] = set_cards(_players.keys())
	_cards["grave"] = Dictionary()
	for i in range(4,0,-1):
		_cards["grave"][i] = Dictionary()
		for id in _players.keys():
			_cards["grave"][i][id] = []
	#print(_cards["pool"])
	# deal first hand
	deal_cards_server(_round)

@rpc("any_peer")
func pick_player(id):
	var sender_id = multiplayer.get_remote_sender_id()
	#print(str(multiplayer.get_remote_sender_id(), " picked ", id))
	if id == multiplayer.get_unique_id():
		print("i got picked by ", sender_id)
		rpc_id(1, "cut_wire_from_server", sender_id, id)

# call from the player that cut
func cut_wire_player(selected_id, picked_wire, wire_id):
	var my_id = multiplayer.get_unique_id()
	rpc_id(1, "cut_wire_already_selected", my_id, selected_id, picked_wire, wire_id)
	rpc_id(selected_id, "got_cut", wire_id)

@rpc("any_peer")
func got_cut(wire_id):
	#print(_cards["in_play"][multiplayer.get_unique_id()])
	
	print($HandCon/Hand.get_item_text(wire_id))
	$HandCon/Hand.remove_item(wire_id)

# run in server
@rpc("any_peer")
func cut_wire_already_selected(picking_id, picked_id, picked_wire, wire_id):
	var picked_hand = _cards["in_play"][picked_id]
	picked_hand.erase(picked_wire)
	_cards["grave"][_round][picked_id].append(picked_wire)
	rpc_id(picking_id, "cut_wire_on_client", picked_wire, picked_id)
	rpc("set_uncut_wire_count", picked_id, picked_hand, wire_id)
	check_end_game(picked_wire)

@rpc("any_peer")
func update_history(message):
	#print("recieve history: ", message)
	$HistoryCon/History.add_item(message)

@rpc("authority")
func cut_wire_on_client(picked_wire, picked_from_id):
	#print("I picked ", picked_wire)
	var my_id = multiplayer.get_unique_id()
	var my_name = _players[my_id]
	var msg = str(my_name, " cut ", picked_wire,
					" from ", str(_players[picked_from_id]))
	# remove player card button
	for card in _player_cards.values():
		card._hide_cut_button()
	# update history
	update_history(msg)
	rpc("update_history", msg)

@rpc("any_peer")
func check_end_game(picked_wire):
	print("cut ", picked_wire)
	if picked_wire == "bomb":
		bomb_explodes()
	if _defuse_wire_cut == _players.keys().size():
		bomb_defused()
	_cut_this_round += 1
	if _cut_this_round == _players.keys().size():
		var t = Timer.new()
		t.wait_time = 1
		t.one_shot = true
		t.timeout.connect(next_round_timeout)
		add_child(t)
		t.start()

@rpc("any_peer")
func cut_wire_from_server(picking_id, picked_id):
	var picked_hand = _cards["in_play"][picked_id]
	picked_hand.shuffle()
	var picked_wire = picked_hand.pop_front()
	_cards["grave"].append(picked_wire)
	rpc_id(picking_id, "cut_wire_on_client", picked_wire, picked_id)
	rpc("set_uncut_wire_count", picked_id, picked_hand.size())
	check_end_game(picked_wire)
		#_next_round()
	#print(picked_hand)
	#print(picked_wire)

func next_round_timeout():
	_next_round()


func bomb_defused():
	for id in _players.keys():

		if _roles[id] == role_name_good:
			rpc_id(id, "end_game_client", true)
		else:
			rpc_id(id, "end_game_client", false)

func bomb_explodes():
	for id in _players.keys():
		rpc_id(id, "play_explosion")

@rpc("any_peer")
func show_results(client_id):
	if _roles[client_id] == role_name_good:
		rpc_id(client_id, "end_game_client", false)
	else:
		rpc_id(client_id, "end_game_client", true)
	#$Results.show()
	
@rpc
func play_explosion():
	$Results.show()
	$Results/ExplodeAnimation.play("default")

@rpc
func end_game_client(win):
	$ScrollContainer.hide()
	$OthersWireBox.hide()
	if win:
		$Results/Label.text = "WIN!"
	else:
		$Results/Label.text = "LOSE!"
	$Results/RestartButton.show()
	$Results.show()


# set claim
func _on_button_pressed() -> void:
	var claim = Dictionary({"bomb": _ui_claim.get_node("BombContainer/MenuButton").text,
							"defuse_wire": _ui_claim.get_node("DefuseWireContainer/MenuButton").text})
	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			rpc_id(id, "set_claim", claim)


func _on_declare_window_spinbox_value_change(value) -> void:
	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			rpc_id(id, "set_defuse_claim", value)

@rpc("any_peer")
func set_defuse_claim(value):
	var p_card = _player_cards[multiplayer.get_remote_sender_id()]
	p_card.set_defuse_wire_count(value)

func _on_declare_button_pressed():
	if not _showing_declare:
		$DeclareWindow.show()
		_showing_declare = true
	else:
		$DeclareWindow.hide()
		_showing_declare = false
	

@rpc("any_peer")
func set_claim(claim):
	var p_card = _player_cards[multiplayer.get_remote_sender_id()]
	p_card.set_claim(claim)

@rpc("any_peer")
func set_uncut_wire_count(picked_id, wire_hand, wire_id):
	if multiplayer.get_unique_id() == 1 or multiplayer.get_unique_id() == picked_id:
		return
	var p_card = _player_cards[picked_id]
	p_card.set_wire_box(wire_hand, wire_id)

@rpc
func show_new_wire_box(their_id):

	$OthersWireBox.set_wires(their_id, _new_global_card["in_play"][their_id], _already_cut)
	#$OthersWireBox.update_wires(_new_global_card["in_play"][their_id])
	$OthersWireBox.show()
	for p_scene in _player_cards.values():
		p_scene.hide()

@rpc("any_peer")
func update_global_card_after_cut(player_id, wire_data, wire_type):
	# if my wires got cut
	if player_id == multiplayer.get_unique_id():
		print("i got cut")
		#play the wire but in my wire box
		$MyWireBox.play_cut_animation(wire_type)
	if wire_type == "defuse_wire":
		_defuse_wire_cut += 1
		$DefuseWireCon/Number.text = str(_players.keys().size() - _defuse_wire_cut)
	_new_global_card["in_play"][player_id] = wire_data
	
	# update player_card uncut wire count:
	if player_id != multiplayer.get_unique_id():
		var w_count = 0
		for wire in wire_data:
			if not wire["is_cut"]:
				w_count +=1
		var p_card = _player_cards[player_id]
		p_card.update_uncut_wire_count(w_count)

	if $OthersWireBox.cur_player_id == player_id:
		$OthersWireBox.new_update_wires(player_id, wire_data)

func update_player_scene_uncut_wire_count():
	pass
	

@rpc("any_peer")
func update_server_global_card(player_id, wire_data, wire_type):
	if wire_type == "defuse_wire":
		_defuse_wire_cut += 1
	_new_global_card["in_play"][player_id] = wire_data
	check_end_game(wire_type)

func client_wire_box_cut(cur_player_id, wire_data, wire_type):
	_already_cut = true
	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			rpc_id(id, "update_global_card_after_cut", cur_player_id, wire_data, wire_type)
	update_global_card_after_cut(cur_player_id, wire_data, wire_type)
	rpc_id(1, "update_server_global_card",cur_player_id, wire_data, wire_type)
	#rpc_id(1, "check_end_game", wire_type)
	#print(wire_data)
	#print(cur_player_id, wire_type, wire_data)

func _on_restart_button_pressed() -> void:
	var t = Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.timeout.connect(on_restart_timeout)
	add_child(t)
	t.start()
	wait_for_restart()
	rpc("wait_for_restart")


func on_restart_timeout():
	rpc_id(1, "_set_player_grid_server")
	rpc_id(1, "_server_start_game")

@rpc("any_peer")
func wait_for_restart():
	$Results/RestartButton.hide()
	for ch in $ScrollContainer/PlayerGrid.get_children():
		$ScrollContainer/PlayerGrid.remove_child(ch)
		ch.queue_free()
	

@rpc("any_peer")
func update_player_scene_have_bomb(their_id, they_have_bomb: bool):
	var p_scene = _player_cards[their_id]
	p_scene.update_have_bomb(they_have_bomb)

func _on_have_bomb_button_pressed() -> void:
	if _i_have_bomb:
		_i_have_bomb = false
		$ClaimUI/HaveBombButton.text = "No Bomb"
	else:
		_i_have_bomb = true
		$ClaimUI/HaveBombButton.text = "I Have Bomb"

	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			rpc_id(id, "update_player_scene_have_bomb", multiplayer.get_unique_id(), _i_have_bomb)



func _on_wire_box_exit_button_pressed() -> void:
	$OthersWireBox.hide()


func _on_others_wire_box_hide_wire_box() -> void:
	for p_scene in _player_cards.values():
		p_scene.show()


func _on_explode_animation_animation_finished() -> void:
	rpc_id(1, "show_results", multiplayer.get_unique_id())
