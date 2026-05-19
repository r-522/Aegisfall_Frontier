# Aegisfall Frontier — アーキテクチャドキュメント

## ゲーム概要
「Aegisfall Frontier」は世界「Eldrath」を舞台にした**侵攻型タワーディフェンスRPG**。
プレイヤーは「Frontier Legion」の一員として、魔王城への侵攻を指揮する。

## 技術スタック

| 項目 | 技術 |
|------|------|
| Engine | Godot 4.4+ |
| 言語 | GDScript (主) + 将来C# |
| Multiplayer | ENetMultiplayerPeer |
| Backend | Nakama (将来実装) |
| Auth | Steam OAuth (将来実装) |

## ディレクトリ構成

```
/client/          Godotプロジェクトルート
  Autoloads/      グローバルサービス (EventBus, GameConfig, InputMapper)
  Data/           .tres Resourceデータファイル
  Components/     再利用可能Nodeコンポーネント
  Scenes/         シーンファイル (.tscn + .gd)
  Systems/        ゲームシステム (PhaseManager, WaveSystem等)
  AI/             敵AI (BehaviorTree + Behaviors + Targeting)
  Net/            ネットワーク (NetworkManager, Sync)
/server/          ヘッドレスサーバー
/shared/          共通定数・計算ロジック
/docs/            このドキュメント
/assets/          テクスチャ・モデル・音声 (別途追加)
```

## アーキテクチャ方針

### コンポーネントパターン
全エンティティはNodeコンポーネントを組み合わせて構成:

```
PlayerBase (CharacterBody3D)
├── HealthComponent    HP管理・死亡シグナル
├── ManaComponent      MP管理・再生
├── SkillComponent     スキルCD・発動管理
├── HitStopComponent   ヒットストップ演出
├── StatusEffectComponent バフ/デバフ管理
└── MoveComponent      移動・ダッシュ・重力
```

### シグナルアーキテクチャ
```
┌─────────────────────────────────────────┐
│                EventBus                  │
│   (Autoload — 全シグナルの中継ハブ)       │
└─────────────────────────────────────────┘
       ↑ emit              ↓ connect
  [Player/Enemy/Tower]   [HUD/System/Net]
```

**原則**: シーンツリー境界を超える通知はEventBus経由。同一シーン内は直接シグナル接続。

### Autoload (3つのみ)
| 名前 | 役割 |
|------|------|
| EventBus | グローバルシグナル中継 |
| GameConfig | 読み取り専用定数・ユーザー設定 |
| InputMapper | 全入力の抽象化レイヤー |

## ゲームフェーズ

```
LOBBY → EXPLORATION(90s) → BUILD(60s) → WAVE_DEFENSE → COUNTER_ATTACK(120s) → RESULTS
                                              ↓
                                        (全ウェーブクリア)
                                              ↓
                                          VICTORY
```

## 衝突レイヤー設計

| Layer | 名称 | 用途 |
|-------|------|------|
| 1 | World | 地形・静的物体 |
| 2 | Players | プレイヤーCharacterBody3D |
| 4 | Enemies | 敵CharacterBody3D |
| 8 | Towers | タワーStaticBody3D |
| 16 | Projectiles | 投射物Area3D |
| 32 | Hitboxes | 近接攻撃Area3D |
| 64 | Detection | AggroComponent検知Area3D |

## ネットワーク設計

- **方式**: Server Authoritative
- **Tick**: Server 30Hz / Client 60fps補間
- **同期対象**: プレイヤー位置・敵位置・タワー状態
- **Transport**: ENet (UDP)

## ファイル制約

- 500行/ファイル厳守
- Singleton乱用禁止 (Autoload 3つまで)
- God Object禁止
- 全機能コンポーネント分離

## 戦闘感触設計

| 要素 | 実装方法 |
|------|---------|
| ヒットストップ | HitStopComponent — AnimationPlayer速度0制御 |
| カメラシェイク | CameraSystem.shake() |
| 部位リアクション | アニメーション予備動作 (AnimationTree) |
| 重量感SE | AudioManager (将来実装) |
