extends Node

var multiplayer_peer = WebSocketMultiplayerPeer.new()
var key_path = "res://ssl/selfsigned.key"
var cert_path = "res://ssl/selfsigned.crt"
var port = 8765
#var url = "wss://luraykuang1998.online:80"
var debug = true 
var url = "ws://localhost:8765" # change TLSOptions.client()
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
	var player_character = preload("res://game.tscn").instantiate()
	player_character.set_multiplayer_authority(client_id)
	add_child(player_character)
	if client_id == multiplayer.get_unique_id():
		local_player_character = player_character

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
	$Label.text = "Connected to server"


func _on_connection_error():
	print("Connection error")
	$Label.text = "Connection error"

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
	var _p_name = _ui_settings_container.get_node("EnterName").text
	#local_player_character.rpc("_update_player_name", local_id, $SettingsContainer/EnterName.text)
	_update_player_name(local_id, _p_name)
	for id in _players.keys():
		if id != local_id:
			rpc_id(id, "_update_player_name", local_id, _p_name)
	rpc_id(1, "_update_player_name", local_id, _p_name)
	$NetworkContainer/LobbyContainer.show()


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
	_round = 4
	$PlayerGrid.show()
	$Results.hide()
	$NetworkContainer.hide()
	$RoleLabel.text = role

func set_roles(ids) -> Dictionary:
	var rtn_role = Dictionary()
	var role_pool = []
	var num_players = ids.size()
	if 7 <= num_players:
		for _i in range(5):
			role_pool.append("Sherlock")
		for _i in range(3):
			role_pool.append("Moriarty")
	elif 6 <= num_players:
		for _i in range(4):
			role_pool.append("Sherlock")
		for _i in range(2):
			role_pool.append("Moriarty")
	elif 4 <= num_players:
		for _i in range(3):
			role_pool.append("Sherlock")
		for _i in range(2):
			role_pool.append("Moriarty")
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
func deal_cards_client(wires):
	# show cut button
	for card in _player_cards.values():
		card._show_cut_button()
	# reset hand
	$HandCon/Hand.clear()
	# set given cards
	_hand = wires
	for wire_i in _hand:
		$HandCon/Hand.add_item(wire_i)
	# update uncut count
	for p_card in _player_cards.values():
		p_card.set_uncut_wire_count(wires.size())
	#print(_hand)

func deal_cards_sever(round_i):
	_cards["pool"].shuffle()
	for id in _players.keys():
		var hand = []
		for i in range(round_i + 1):
			var card_i = _cards["pool"].pop_front()
			hand.append(card_i)
		_cards["in_play"][id] = hand
		rpc_id(id, "deal_cards_client", hand)

@rpc("any_peer")
func _set_player_grid_server():
		#set player grid
	for id in _players.keys():
		rpc_id(id, "_set_player_grid", _players)
	

@rpc("authority")
func _set_player_grid(players):
	$PlayerGrid.show()
	for id in players.keys():
		if id != multiplayer.get_unique_id():
			var player_scene = preload("res://player.tscn").instantiate()
			player_scene.set_multiplayer_authority(id)
			player_scene.set_info(players[id])
			player_scene.set_data(id, self)
			$PlayerGrid.add_child(player_scene)
			_player_cards[id] = player_scene

func _next_round():
	_round -= 1
	_cut_this_round = 0
	for cards in _cards["in_play"].values():
		_cards["pool"].append_array(cards)
	_cards["in_play"] = Dictionary()
	deal_cards_sever(_round)


@rpc("any_peer")
func _server_start_game():

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
	_cards["grave"] = []
	#print(_cards["pool"])
	# deal first hand
	deal_cards_sever(_round)

@rpc("any_peer")
func pick_player(id):
	var sender_id = multiplayer.get_remote_sender_id()
	#print(str(multiplayer.get_remote_sender_id(), " picked ", id))
	if id == multiplayer.get_unique_id():
		print("i got picked by ", sender_id)
		rpc_id(1, "cut_wire_from_server", sender_id, id)

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
func cut_wire_from_server(picking_id, picked_id):
	var picked_hand = _cards["in_play"][picked_id]
	picked_hand.shuffle()
	var picked_wire = picked_hand.pop_front()
	_cards["grave"].append(picked_wire)
	rpc_id(picking_id, "cut_wire_on_client", picked_wire, picked_id)
	rpc("set_uncut_wire_count", picked_id, picked_hand.size())
	if picked_wire == "bomb":
		bomb_explodes()
	if picked_wire == "defuse_wire":
		_defuse_wire_cut += 1
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
		#_next_round()
	#print(picked_hand)
	#print(picked_wire)

func next_round_timeout():
	_next_round()

func foo(): # debug
	for id in _players.keys():
		rpc_id(id, "_set_player_grid", _players)

func bomb_defused():
	for id in _players.keys():

		if _roles[id] == "Sherlock":
			rpc_id(id, "end_game_client", true)
		else:
			rpc_id(id, "end_game_client", false)

func bomb_explodes():
	for id in _players.keys():

		if _roles[id] == "Sherlock":
			rpc_id(id, "end_game_client", false)
		else:
			rpc_id(id, "end_game_client", true)
	#$Results.show()

@rpc
func end_game_client(win):
	$PlayerGrid.hide()
	if win:
		$Results/Label.text = "WIN!"
	else:
		$Results/Label.text = "LOSE!"
	$Results.show()

#debug
func _on_button_pressed() -> void:
#debug
	var claim = Dictionary({"bomb": _ui_claim.get_node("BombContainer/MenuButton").text,
							"defuse_wire": _ui_claim.get_node("DefuseWireContainer/MenuButton").text})
	for id in _players.keys():
		if id != multiplayer.get_unique_id():
			rpc_id(id, "set_claim", claim)

@rpc("any_peer")
func set_claim(claim):
	var p_card = _player_cards[multiplayer.get_remote_sender_id()]
	p_card.set_claim(claim)

@rpc("any_peer")
func set_uncut_wire_count(picked_id, wire_count):
	if multiplayer.get_unique_id() == 1 or multiplayer.get_unique_id() == picked_id:
		return
	var p_card = _player_cards[picked_id]
	p_card.set_uncut_wire_count(wire_count)


func _on_restart_button_pressed() -> void:
	rpc_id(1, "_server_start_game")
	$Results.hide()
