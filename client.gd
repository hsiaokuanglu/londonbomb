extends Node

var multiplayer_peer = WebSocketMultiplayerPeer.new()
#var url = "wss://luraykuang1998.online:80"
var url = "ws://localhost:8765" # change TLSOptions.client()

func _ready():
	pass


func _on_join_pressed() -> void:
	var err = multiplayer_peer.create_client(url) #
	if err == OK:
		print("Connecting to WebSocket server...")

		multiplayer.multiplayer_peer = multiplayer_peer
		multiplayer.connect("connected_to_server", _on_connection_established)	
		multiplayer.connect("connection_failed", _on_connection_error)	

func _on_line_edit_text_submitted(new_text: String) -> void:
	rpc_id(1, "display_message", $LineEdit)

func _on_connection_established():
	print("Connected to server")
	$Label.text = "Connected to server"
	#

func _on_connection_error():
	print("Connection error")
	$Label.text = "Connection error"

@rpc
func display_message():
	pass
