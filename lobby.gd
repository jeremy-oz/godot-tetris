class_name Lobby
extends Control

# First scene of the game: play solo, or host/join a two-player match.
# Hosting opens an ENet server; joining connects to the host's IP. When the
# two players meet, the host picks one random seed and sends it over, so
# both boards deal the identical piece sequence. The guest confirms with
# _start_match, which switches both machines to the versus scene together.

const PORT: int = 8910
const SOLO_SCENE := "res://scenes/solo.tscn"
const VERSUS_SCENE := "res://scenes/versus.tscn"

#carries the agreed bag seed across the scene change into versus mode
static var match_seed: int = 0

@onready var main_menu: VBoxContainer = $MainMenu
@onready var join_menu: VBoxContainer = $JoinMenu
@onready var wait_menu: VBoxContainer = $WaitMenu
@onready var wait_label: Label = $WaitMenu/WaitLabel
@onready var status_label: Label = $StatusLabel
@onready var ip_edit: LineEdit = $JoinMenu/IpEdit

func _ready() -> void:
	#restore the solo-sized canvas and window after a wide versus match
	var window := get_window()
	window.content_scale_size = Vector2i(650, 704)
	window.size = Vector2i(650, 704)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_connection_failed)

func _on_solo_pressed() -> void:
	get_tree().change_scene_to_file(SOLO_SCENE)

func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 1)
	if err != OK:
		status_label.text = "Could not start hosting: " + error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = ""
	wait_label.text = "Waiting for a player to join...\nYour IP: " + _lan_ip()
	main_menu.hide()
	wait_menu.show()

func _on_join_pressed() -> void:
	status_label.text = ""
	main_menu.hide()
	join_menu.show()
	ip_edit.grab_focus()

func _on_connect_pressed() -> void:
	var ip := ip_edit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1" #convenient when testing two instances on one machine
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		status_label.text = "Could not connect: " + error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = ""
	wait_label.text = "Connecting to " + ip + "..."
	join_menu.hide()
	wait_menu.show()

func _on_back_pressed() -> void:
	join_menu.hide()
	main_menu.show()

func _on_cancel_pressed() -> void:
	#stops hosting or abandons a connection attempt
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	wait_menu.hide()
	main_menu.show()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status_label.text = "Connection failed — check the IP and try again"
	wait_menu.hide()
	join_menu.hide()
	main_menu.show()

#fires on both machines once the two players can see each other
func _on_peer_connected(_id: int) -> void:
	#only the host decides the seed, otherwise the players would disagree
	if multiplayer.is_server():
		var bag_seed := randi()
		match_seed = bag_seed
		_receive_seed.rpc(bag_seed)

#host -> guest: here is the seed we will both use
@rpc("authority", "call_remote", "reliable")
func _receive_seed(bag_seed: int) -> void:
	match_seed = bag_seed
	#guest -> both: seed received, start the match everywhere
	_start_match.rpc()

@rpc("any_peer", "call_local", "reliable")
func _start_match() -> void:
	get_tree().change_scene_to_file(VERSUS_SCENE)

#best-effort guess of this machine's LAN address, shown to the host so the
#other player knows what to type
func _lan_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	return "127.0.0.1"
