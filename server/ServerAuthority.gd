class_name ServerAuthority
extends Node
## サーバー権限チェックユーティリティ

static func is_authority() -> bool:
	return not Engine.is_editor_hint() and (
		not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	)

static func validate_damage(raw_damage: float, source_player_id: int) -> float:
	if raw_damage < 0.0:
		push_warning("ServerAuthority: 負のダメージ値 source=%d" % source_player_id)
		return 0.0
	if raw_damage > 99999.0:
		push_warning("ServerAuthority: 異常なダメージ値 %.1f source=%d" % [raw_damage, source_player_id])
		return 99999.0
	return raw_damage

static func validate_position(pos: Vector3) -> bool:
	if not pos.is_finite():
		return false
	if pos.length() > 10000.0:
		return false
	return true
