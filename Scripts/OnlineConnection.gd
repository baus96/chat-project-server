extends Node

const PORT := 7777 # istediğin port numarasını yaz

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	host_server()

func host_server():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Server Created, PORT:" + str(PORT))
	



 
# servera yeni kayıt bilgisi geldi
@rpc("any_peer", "call_remote")
func send_register_data_to_server(Username, Password):
	# 1. GÜVENLİK: Eğer kazara bir client bu fonksiyonu tetiklerse durdur.
	if not multiplayer.is_server(): 
		return
		
	var save_path = "res://ServerUserData.json" # JSON dosyanızın yolu
	var registered_users = {} # Dosyadaki verileri aktaracağımız boş sözlük
	
	# 2. VAR OLAN JSON DOSYASINI OKUMA
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		print("merhaba")
		
		# JSON metnini Godot'nun anlayacağı sözlük yapısına çeviriyoruz
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			registered_users = json.data
		else:
			print("JSON Okuma Hatası: ", json.get_error_message())
			return # Hata varsa işlemi durdur ki var olan veriler bozulmasın

	# 3. YENİ KULLANICIYI EKLEME
	# Güvenlik için şifreyi sha256 ile hash'leyip kaydediyoruz (Düz metin saklamamak için)
	var secure_password = Password.sha256_text()
	
	# Sözlüğe yeni kullanıcı adını anahtar (key) olarak ekliyoruz
	registered_users[Username] = {
		"password": secure_password,
		"register_date": Time.get_datetime_string_from_system()
	}
	
	# 4. GÜNCELLENEN SÖZLÜĞÜ TEKRAR JSON DOSYASINA YAZMA (KAYDETME)
	var write_file = FileAccess.open(save_path, FileAccess.WRITE)
	# "\t" parametresi JSON dosyasının alt alta, düzenli okunabilir yazılmasını sağlar
	var new_json_string = JSON.stringify(registered_users, "\t") 
	write_file.store_string(new_json_string)
	write_file.close()
	
	print("Başarılı: ", Username, " kullanıcısı server tarafındaki JSON dosyasına kaydedildi!")
