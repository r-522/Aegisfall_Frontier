extends Node
## グローバルシグナルバス — シーンツリーを跨いだ疎結合通信に使用
## 直接ノード参照が不要な場合にのみ使用する

# === プレイヤーイベント ===
signal player_died(player_id: int)
signal player_respawned(player_id: int, position: Vector3)
signal player_took_damage(player_id: int, amount: float, source: Node)
signal player_healed(player_id: int, amount: float)
signal player_skill_used(player_id: int, skill_index: int)
signal player_level_up(player_id: int, new_level: int)
signal player_joined_session(player_id: int)
signal player_left_session(player_id: int)

# === 敵イベント ===
signal enemy_died(enemy: Node, position: Vector3, xp_reward: int)
signal enemy_spawned(enemy: Node)
signal enemy_reached_goal(enemy: Node)
signal enemy_took_damage(enemy: Node, amount: float)
signal elite_enemy_spawned(enemy: Node)
signal boss_spawned(enemy: Node)
signal boss_phase_changed(enemy: Node, new_phase: int)

# === タワーイベント ===
signal tower_placed(tower: Node, cell: Vector3i)
signal tower_destroyed(tower: Node)
signal tower_took_damage(tower: Node, amount: float)
signal tower_upgraded(tower: Node, new_level: int)
signal tower_sold(tower: Node, refund: int)

# === フェーズイベント ===
signal phase_changed(new_phase: int)
signal wave_started(wave_number: int, total_enemies: int)
signal wave_completed(wave_number: int, success: bool)
signal session_started()
signal session_ended(victory: bool, score: int)
signal exploration_phase_started()
signal build_phase_started(duration: float)
signal defense_phase_started(wave_number: int)
signal assault_phase_started()

# === リソースイベント ===
signal resources_changed(build_material: int, gold: int)
signal build_material_changed(new_amount: int)
signal gold_changed(new_amount: int)
signal xp_gained(player_id: int, amount: int)

# === 戦闘イベント ===
signal hit_confirmed(attacker: Node, target: Node, damage: float, is_critical: bool)
signal kill_confirmed(killer: Node, victim: Node)
signal status_effect_applied(target: Node, effect_id: StringName, duration: float)
signal status_effect_removed(target: Node, effect_id: StringName)

# === フィールドイベント ===
signal supply_line_attacked(supply_node: Node)
signal supply_line_destroyed(supply_node: Node)
signal capture_point_captured(point: Node, faction: int)
signal field_event_triggered(event_id: StringName, position: Vector3)
signal npc_rescued(npc: Node)

# === UI/システムイベント ===
signal build_mode_toggled(active: bool)
signal tower_selected_for_build(tower_data: Resource)
signal item_picked_up(item: Resource, picker: Node)
signal item_equipped_signal(item: Resource, slot_category: int)
signal item_dropped(item: Resource, position: Vector3)
signal inventory_opened()
signal inventory_closed()
signal dialog_started(dialog_id: StringName)
signal dialog_ended(dialog_id: StringName)
signal save_requested()
signal load_requested()

# === ネットワークイベント ===
signal connected_to_server()
signal disconnected_from_server()
signal lobby_updated(player_list: Array)
signal match_started()
signal match_ended()
