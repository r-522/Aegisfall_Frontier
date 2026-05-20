# Aegisfall Frontier

**侵攻型タワーディフェンス RPG** — 世界「Eldrath」を奪還せよ。

数百年前、人類は魔王軍に敗北。生き残った人々は巨大結界都市に身を寄せている。
プレイヤーは失われた大陸を奪還する「Frontier Legion」の一員として、
**前線拠点を築き、補給線を維持し、タワーを展開しながら、徐々に魔王城へ攻め込む**。

従来のタワーディフェンスと異なり、防衛地点は移動し、プレイヤー自身が戦闘主体となる。

---

## ジャンル

- オープンワールド + サードパーソン3Dアクション
- 協力型オンラインタワーディフェンス
- ハクスラ / RPG / 拠点攻略型PvE

## 技術スタック

| 項目 | 技術 |
|------|------|
| Engine | Godot 4.4+ |
| 言語 | GDScript |
| Multiplayer | ENetMultiplayerPeer (Server Authoritative, 30Hz tick) |
| Rendering | Forward Plus + SDFGI + SSAO |
| Audio | 5層 AudioBus (Master / SFX / Music / Voice / UI / Impact) |

## 環境要件

- Godot Engine 4.4 以上
- OS: Windows / macOS / Linux

---

## 起動方法

### クライアント (ゲーム本体)

```sh
godot --path client/
```

または Godot Editor で `client/project.godot` を開いて F5。

### ヘッドレスサーバー

```sh
godot --headless --path client/ -- --server --port 28960
```

### マルチプレイ参加

1. ホスト側: メインメニューから「ホスト」を選択
2. クライアント側: 「参加」→ IP入力 → 「接続」

---

## 操作

| アクション | キー |
|-----------|------|
| 移動 | WASD |
| ジャンプ | Space |
| ダッシュ | Shift |
| しゃがみ | Ctrl |
| Interact | E |
| 通常攻撃 | LMB |
| 強攻撃 | RMB |
| 回避 | Alt |
| Skill 1 | Q |
| Skill 2 | C |
| Skill 3 | V |
| Ultimate | Z |
| インベントリ | I |
| 建築メニュー | B |
| ポーズ | Escape |

---

## ディレクトリ構成

```
client/
  Autoloads/        EventBus / GameConfig / InputMapper / AudioManager
  Components/       Health / Mana / Skill / Aggro / Tower / HitStop / StatusEffect / Move / AudioReverbZone
  Data/             .tres リソース (Characters / Enemies / Towers / Skills / Waves)
  Scenes/           Main / World / Characters / Enemies / Towers / Projectiles / UI
  AI/               BehaviorTree + Behaviors + Targeting戦略
  Systems/          Phase / Wave / Spawn / Build / Resource / Combat / Camera / Loot / Save / FieldEvent
  Net/              NetworkManager / Lobby / Player/Enemy Synchronizer
  Assets/           UI Theme リソース
server/             ヘッドレスサーバー (ServerGameLoop / ServerAuthority)
shared/             Constants / DamageCalc
docs/               architecture.md / class_reference.md
assets/             テクスチャ / モデル / 音声 (外部制作)
```

詳細は [docs/architecture.md](docs/architecture.md) を参照。

---

## 開発状況

| カテゴリ | 状況 |
|---------|------|
| コア戦闘 (ヒットストップ / カメラシェイク / 部位リアクション) | ✅ 実装済み |
| プレイヤークラス 39体 | ✅ Fighter / Mage / Ranger / Cleric フル実装 + 35体スタブ |
| 敵 11種 (Behavior Tree AI) | ✅ 実装済み |
| タワー 15種 (4カテゴリ) | ✅ 実装済み |
| ゲームフェーズ管理 | ✅ Lobby / Exploration / Build / Wave / Counter / Results |
| ネットワーク (ENet Server Authoritative) | ✅ 実装済み |
| 音響システム (5層 Bus + Reverb Zone) | ✅ 実装済み |
| UI / Diablo IV風テーマ | ✅ 実装済み |
| Steam OAuth / Workshop / Achievement | ⏳ 将来実装 |
| Nakama (マッチメイキング / 永続化) | ⏳ 将来実装 |
| Vivox / WebRTC ボイスチャット | ⏳ 将来実装 |
| 実体アセット (3Dモデル / 音声 / PBR テクスチャ) | ⏳ 外部制作 |

詳細は [docs/class_reference.md](docs/class_reference.md) を参照。

---

## クラスカテゴリ

- **近接系 (9体)**: Fighter, Warrior, Knight, Paladin, Berserker, Monk, Samurai, Dragoon, Barbarian
- **魔法系 (8体)**: Mage, Wizard, Sorcerer, Warlock, Necromancer, Elementalist, Time Mage, Sage
- **支援系 (7体)**: Cleric, Priest, Bishop, Druid, Shaman, Bard, Enchanter
- **敏捷系 (7体)**: Ranger, Thief, Rogue, Assassin, Ninja, Archer, Scout
- **特殊系 (8体)**: Summoner, Beastmaster, Alchemist, Gunner, Machinist, Spellblade, Rune Knight, Trickster

## タワーカテゴリ

- **防壁**: Stone Wall / Holy Barrier / Spike Barricade
- **攻撃塔**: Arrow Tower / Arcane Tower / Cannon Tower / Lightning Obelisk / Ballista
- **支援塔**: Heal Beacon / Mana Relay / Buff Totem
- **特殊塔**: Trap Mine / Frost Field / Gravity Well / Flame Turret

---

## ライセンス

Proprietary — All rights reserved.
