class_name PhaseManager
extends Node
## ゲームフェーズのステートマシン
## LOBBY → EXPLORATION → BUILD → WAVE_DEFENSE → COUNTER_ATTACK → RESULTS

enum Phase {
	LOBBY,
	EXPLORATION,
	BUILD,
	WAVE_DEFENSE,
	COUNTER_ATTACK,
	RESULTS
}

signal phase_changed(old_phase: Phase, new_phase: Phase)

var current_phase: Phase = Phase.LOBBY
var _phase_timer: float = 0.0
var _wave_system: WaveSystem  # found via get_node

func _ready() -> void:
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.session_started.connect(func(): transition_to(Phase.EXPLORATION))

func _process(delta: float) -> void:
	if _phase_timer <= 0.0:
		return
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_on_phase_timer_expired()

func transition_to(new_phase: Phase) -> void:
	var old := current_phase
	current_phase = new_phase
	_phase_timer = _get_phase_duration(new_phase)
	_on_phase_entered(new_phase)
	phase_changed.emit(old, new_phase)
	EventBus.phase_changed.emit(int(new_phase))

func _get_phase_duration(phase: Phase) -> float:
	match phase:
		Phase.EXPLORATION: return GameConfig.EXPLORATION_PHASE_DURATION
		Phase.BUILD:       return GameConfig.BUILD_PHASE_DURATION
		Phase.COUNTER_ATTACK: return GameConfig.COUNTER_ATTACK_PHASE_DURATION
	return 0.0

func _on_phase_entered(phase: Phase) -> void:
	match phase:
		Phase.EXPLORATION:
			EventBus.exploration_phase_started.emit()
		Phase.BUILD:
			EventBus.build_phase_started.emit(GameConfig.BUILD_PHASE_DURATION)
		Phase.WAVE_DEFENSE:
			_wave_system = get_node_or_null("../WaveSystem")
			if _wave_system:
				_wave_system.start_wave()
			EventBus.defense_phase_started.emit(1)
		Phase.COUNTER_ATTACK:
			EventBus.assault_phase_started.emit()
		Phase.RESULTS:
			# WaveSystem is responsible for emitting the definitive victory flag;
			# here we emit a neutral fallback so the Results screen always fires.
			EventBus.session_ended.emit(false, 0)

func _on_phase_timer_expired() -> void:
	match current_phase:
		Phase.EXPLORATION:    transition_to(Phase.BUILD)
		Phase.BUILD:          transition_to(Phase.WAVE_DEFENSE)
		Phase.COUNTER_ATTACK: transition_to(Phase.RESULTS)

func _on_wave_completed(wave_number: int, success: bool) -> void:
	if current_phase == Phase.WAVE_DEFENSE:
		if success:
			transition_to(Phase.COUNTER_ATTACK)
		else:
			transition_to(Phase.RESULTS)

## 残り時間を 0.0〜1.0 の比率で返す
func get_phase_timer_ratio() -> float:
	var max_dur := _get_phase_duration(current_phase)
	if max_dur <= 0.0:
		return 0.0
	return _phase_timer / max_dur

## 残り時間を秒で返す
func get_phase_timer_seconds() -> float:
	return maxf(0.0, _phase_timer)

## デバッグ / UI 用: 探索・ビルドフェーズをスキップしてウェーブへ
func skip_to_wave() -> void:
	if current_phase in [Phase.EXPLORATION, Phase.BUILD]:
		transition_to(Phase.WAVE_DEFENSE)
