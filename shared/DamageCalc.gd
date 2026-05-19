## ダメージ計算ユーティリティ — クライアント・サーバー共通

static func physical_damage(raw: float, defense: float, level_diff: int = 0) -> float:
	var reduced := maxf(1.0, raw - defense)
	if level_diff > 0:
		reduced *= 1.0 + level_diff * 0.05
	return reduced

static func magical_damage(raw: float, magic_resist: float) -> float:
	var resist_mult := 1.0 - clampf(magic_resist / 100.0, 0.0, 0.75)
	return maxf(1.0, raw * resist_mult)

static func critical_hit(base_damage: float, crit_chance: float, crit_multiplier: float = 2.0) -> Dictionary:
	var is_crit := randf() < crit_chance
	return {
		"damage": base_damage * crit_multiplier if is_crit else base_damage,
		"is_crit": is_crit
	}

static func distance_falloff(damage: float, distance: float, falloff_start: float = 10.0, falloff_end: float = 30.0) -> float:
	if distance <= falloff_start:
		return damage
	if distance >= falloff_end:
		return damage * 0.5
	var t := (distance - falloff_start) / (falloff_end - falloff_start)
	return damage * lerp(1.0, 0.5, t)

static func tower_damage_with_buffs(base: float, tower_buff: float, player_bonus: float) -> float:
	return base * (1.0 + tower_buff) * (1.0 + player_bonus)
