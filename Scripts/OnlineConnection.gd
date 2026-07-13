extends Node

const PORT := 7777 
const SAVE_PATH := "user://ServerUserData.json" # 'res://' yerine güvenli olan 'user://' yaptık

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	# --- SİNYALLER ---
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	host_server()

func host_server():
	var error = peer.create_server(PORT)
	if error != OK:
		print("Sunucu başlatılamadı! Hata kodu: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Server Created, PORT: " + str(PORT))

func _on_peer_connected(id: int):
	print("Yeni bir oyuncu ağa katıldı! Benzersiz ID: ", id)

func _on_peer_disconnected(id: int):
	print("Bir oyuncu ağdan ayrıldı. Benzersiz ID: ", id)

func _on_connected_to_server():
	print("BAŞARILI: Sunucuya bağlandım! Benim ID'm: ", multiplayer.get_unique_id())

func _on_connection_failed():
	print("HATA: Sunucuya bağlanılamadı.")

func _on_server_disconnected():
	print("BİLGİ: Sunucu kapandı veya bağlantınız kesildi!")

# --- GİRİŞ YAPMA (LOGIN) ---
@rpc("any_peer")
func send_login_data_to_server(Username, Password):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id() 
	var data = get_user_data(Username) 
	
	if data == null:
		print("Giriş Başarısız: ", Username, " bulunamadı.")
		return_login_result.rpc_id(sender_id, false, "Kullanıcı adı bulunamadı!")
		return
		
	var input_password_hash = Password.sha256_text()
	
	if data["password"] == input_password_hash:
		print("Giriş Başarılı! ", Username, " sisteme girdi.")
		return_login_result.rpc_id(sender_id, true, "Giriş başarılı! Yönlendiriliyorsunuz...")
	else:
		print("Giriş Başarısız: ", Username, " için hatalı şifre girildi.")
		return_login_result.rpc_id(sender_id, false, "Hatalı şifre girdiniz!")

@rpc("authority")
func return_login_result(success: bool, message: String):
	pass

# --- YENİ KAYIT (REGISTER) ---
@rpc("any_peer")
func send_register_data_to_server(Username, Password):
	if not multiplayer.is_server(): 
		return
		
	var registered_users = {} 
	
	# VAR OLAN JSON DOSYASINI OKUMA
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		if json_string.strip_edges() != "":
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK and json.data is Dictionary:
				registered_users = json.data
			else:
				print("JSON formatı bozuk veya boş, yeni sözlük açılıyor.")

	# YENİ KULLANICIYI EKLEME
	var secure_password = Password.sha256_text()
	registered_users[Username] = {
		"password": secure_password,
		"register_date": Time.get_datetime_string_from_system()
	}
	
	# JSON DOSYASINA YAZMA
	var write_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var new_json_string = JSON.stringify(registered_users, "\t") 
	write_file.store_string(new_json_string)
	write_file.close()
	
	print("Başarılı: ", Username, " kullanıcısı server tarafındaki JSON dosyasına kaydedildi!")

# --- JSON VERİ OKUMA ---
func get_user_data(username_to_find: String):
	if not FileAccess.file_exists(SAVE_PATH):
		return null
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	if json_string.strip_edges() == "":
		return null
		
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK or not json.data is Dictionary:
		return null
		
	var registered_users = json.data 
	
	if registered_users.has(username_to_find):
		return registered_users[username_to_find]
	return null

# --- CHAT ---
@rpc("any_peer")
func send_chat_message_to_all(Username, message):
	pass
