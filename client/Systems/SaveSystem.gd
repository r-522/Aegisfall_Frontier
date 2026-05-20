class_name SaveSystem
extends Node
## セーブ / ロードシステム — ConfigFile を使用して user://save.cfg に永続化する
## セーブデータはセクション単位で整理する:
##   [meta]  — バージョン・タイムスタンプ
##   [player] — レベル・経験値・クラス ID
##   [position] — ワールド座標
##   [inventory] — アイテム ID・数量のスタブ
##   [resources] — ゲーム内通貨・素材

const _SAVE_PATH:    String = "user://save.cfg"
const _SAVE_VERSION: int    = 1

# ========================================================================== #
# パブリック API
# ========================================================================== #

## プレイヤーノードの現在状態をセーブする
## player が null の場合でも resources_data が有れば保存する
func save_game(player: PlayerBase, resources_data: Dictionary = {}) -> void:
	var cfg := ConfigFile.new()

	# --- [meta] ---
	cfg.set_value("meta", "version",   _SAVE_VERSION)
	cfg.set_value("meta", "timestamp", int(Time.get_unix_time_from_system()))
	cfg.set_value("meta", "platform",  OS.get_name())

	# --- [player] ---
	if is_instance_valid(player):
		cfg.set_value("player", "level",          player.get("_level") if player.get("_level") != null else 1)
		cfg.set_value("player", "experience",     player.get("_experience") if player.get("_experience") != null else 0)
		cfg.set_value("player", "player_id",      player.player_id)
		cfg.set_value("player", "character_id",
			player.character_data.character_id if player.character_data else &"")
		cfg.set_value("player", "health_ratio",
			player.health_component.get_health_ratio() if is_instance_valid(player.health_component) else 1.0)

		# --- [position] ---
		var pos := player.global_position
		cfg.set_value("position", "x", pos.x)
		cfg.set_value("position", "y", pos.y)
		cfg.set_value("position", "z", pos.z)
	else:
		cfg.set_value("player", "level",      1)
		cfg.set_value("player", "experience", 0)
		cfg.set_value("player", "player_id",  1)
		cfg.set_value("player", "character_id", &"")
		cfg.set_value("player", "health_ratio", 1.0)
		cfg.set_value("position", "x", 0.0)
		cfg.set_value("position", "y", 0.0)
		cfg.set_value("position", "z", 0.0)

	# --- [resources] ---
	cfg.set_value("resources", "build_material",
		resources_data.get("build_material", GameConfig.STARTING_BUILD_MATERIAL))
	cfg.set_value("resources", "gold",
		resources_data.get("gold", GameConfig.STARTING_GOLD))

	# --- [inventory] スタブ ---
	var inventory_stub: Array = resources_data.get("inventory", [])
	cfg.set_value("inventory", "item_count", inventory_stub.size())
	for i in inventory_stub.size():
		var entry: Dictionary = inventory_stub[i]
		cfg.set_value("inventory", "item_%d_id"    % i, entry.get("id", ""))
		cfg.set_value("inventory", "item_%d_count" % i, entry.get("count", 1))

	# 保存実行
	var err := cfg.save(_SAVE_PATH)
	if err != OK:
		push_error("SaveSystem: 保存に失敗しました (error=%d, path=%s)" % [err, _SAVE_PATH])
	else:
		EventBus.save_requested.emit()

## セーブデータをロードして Dictionary で返す
## ファイルが存在しないか壊れている場合は空の Dictionary を返す
func load_game() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(_SAVE_PATH)
	if err != OK:
		push_warning("SaveSystem: セーブファイルを読み込めませんでした (error=%d)" % err)
		return {}

	# バージョン確認
	var version: int = cfg.get_value("meta", "version", 0)
	if version < _SAVE_VERSION:
		push_warning("SaveSystem: 古いセーブバージョン (%d) です。互換モードで読み込みます。" % version)

	var data: Dictionary = {}

	# [meta]
	data["version"]   = version
	data["timestamp"] = cfg.get_value("meta", "timestamp", 0)

	# [player]
	data["level"]        = cfg.get_value("player", "level",        1)
	data["experience"]   = cfg.get_value("player", "experience",   0)
	data["player_id"]    = cfg.get_value("player", "player_id",    1)
	data["character_id"] = cfg.get_value("player", "character_id", &"")
	data["health_ratio"] = cfg.get_value("player", "health_ratio", 1.0)

	# [position]
	data["position"] = Vector3(
		cfg.get_value("position", "x", 0.0),
		cfg.get_value("position", "y", 0.0),
		cfg.get_value("position", "z", 0.0)
	)

	# [resources]
	data["build_material"] = cfg.get_value("resources", "build_material", GameConfig.STARTING_BUILD_MATERIAL)
	data["gold"]           = cfg.get_value("resources", "gold",           GameConfig.STARTING_GOLD)

	# [inventory]
	var item_count: int = cfg.get_value("inventory", "item_count", 0)
	var inventory: Array = []
	for i in item_count:
		inventory.append({
			"id":    cfg.get_value("inventory", "item_%d_id"    % i, ""),
			"count": cfg.get_value("inventory", "item_%d_count" % i, 1)
		})
	data["inventory"] = inventory

	EventBus.load_requested.emit()
	return data

## セーブファイルを削除する
func delete_save() -> void:
	if FileAccess.file_exists(_SAVE_PATH):
		var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(_SAVE_PATH))
		if err != OK:
			push_error("SaveSystem: 削除に失敗しました (error=%d)" % err)
	else:
		push_warning("SaveSystem: 削除対象のセーブファイルが存在しません")

## セーブファイルが存在するか確認する
func has_save() -> bool:
	return FileAccess.file_exists(_SAVE_PATH)

## セーブデータのタイムスタンプを人間が読める文字列で返す
## セーブが存在しなければ空文字列を返す
func get_save_timestamp_string() -> String:
	if not has_save():
		return ""
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) != OK:
		return ""
	var unix: int = cfg.get_value("meta", "timestamp", 0)
	if unix == 0:
		return ""
	return Time.get_datetime_string_from_unix_time(unix, true)
