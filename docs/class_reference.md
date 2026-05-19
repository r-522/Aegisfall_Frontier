# Aegisfall Frontier — クラスリファレンス

## プレイヤークラス一覧

### 近接系 (class_melee)
| クラス | 特徴 | 実装状態 |
|--------|------|---------|
| Fighter | コンボ攻撃・前線維持 | ✅ フル実装 |
| Warrior | バランス型近接 | スタブ |
| Knight | 防御特化・タワー強化 | スタブ |
| Paladin | 近接+回復ハイブリッド | スタブ |
| Berserker | 低HP強化・攻撃型 | スタブ |
| Monk | 素手高速攻撃 | スタブ |
| Samurai | 居合・カウンター | スタブ |
| Dragoon | ジャンプ攻撃・槍 | スタブ |
| Barbarian | 超高火力・低防御 | スタブ |

### 魔法系 (class_magic)
| クラス | 特徴 | 実装状態 |
|--------|------|---------|
| Mage | 属性コンボ・タワー強化 | ✅ フル実装 |
| Wizard | AoE範囲制圧 | スタブ |
| Sorcerer | 高倍率一撃 | スタブ |
| Warlock | DoT/デバフ特化 | スタブ |
| Necromancer | アンデッド召喚 | スタブ |
| Elementalist | 属性切替 | スタブ |
| Time Mage | スロー/ヘイスト | スタブ |
| Sage | 魔法+支援ハイブリッド | スタブ |

### 支援系 (class_support)
| クラス | 特徴 | 実装状態 |
|--------|------|---------|
| Cleric | 回復オーラ・蘇生 | ✅ フル実装 |
| Priest | 聖なる守護 | スタブ |
| Bishop | 強化回復・範囲バフ | スタブ |
| Druid | 自然魔法・変身 | スタブ |
| Shaman | トーテム設置 | スタブ |
| Bard | 音楽バフ | スタブ |
| Enchanter | タワー強化特化 | スタブ |

### 敏捷系 (class_agile)
| クラス | 特徴 | 実装状態 |
|--------|------|---------|
| Ranger | 弓・罠・索敵 | ✅ フル実装 |
| Thief | 素早いDPS・回避 | スタブ |
| Rogue | 毒・ステルス | スタブ |
| Assassin | 一撃必殺 | スタブ |
| Ninja | 忍術・複数攻撃 | スタブ |
| Archer | 精密射撃 | スタブ |
| Scout | 索敵・マップ制御 | スタブ |

### 特殊系 (class_special)
| クラス | 特徴 | 実装状態 |
|--------|------|---------|
| Summoner | 召喚獣操作 | スタブ |
| Beastmaster | 野獣制御 | スタブ |
| Alchemist | 爆弾・ポーション | スタブ |
| Gunner | 銃火器 | スタブ |
| Machinist | 機械仕掛け | スタブ |
| Spellblade | 魔法近接 | スタブ |
| Rune Knight | ルーン刻印 | スタブ |
| Trickster | 幻影・トリック | スタブ |

## タワー一覧

### 防壁 (TowerCategory.DEFENSE)
| タワー | コスト | HP | 特徴 |
|--------|--------|-----|------|
| Stone Wall | 50 | 1000 | 通路遮断 |
| Holy Barrier | 80 | 600 | 近傍プレイヤー回復オーラ |
| Spike Barricade | 60 | 400 | 接触敵ダメージ |

### 攻撃塔 (TowerCategory.ATTACK)
| タワー | コスト | ダメージ | 射程 | 特徴 |
|--------|--------|---------|------|------|
| Arrow Tower | 100 | 45 | 12m | 高速連射 |
| Arcane Tower | 130 | 60 | 10m | AoE+デバフ |
| Cannon Tower | 180 | 100 | 9m | 大AoE爆発 |
| Lightning Obelisk | 200 | 55 | 11m | 連鎖雷 |
| Ballista | 220 | 120 | 18m | 貫通矢 |

### 支援塔 (TowerCategory.SUPPORT)
| タワー | コスト | 効果 | 半径 |
|--------|--------|------|------|
| Heal Beacon | 120 | HP回復+MP回復 | 8m |
| Mana Relay | 150 | MP回復+タワー速度UP | 10m |
| Buff Totem | 140 | 移動速度+20% | 7m |

### 特殊塔 (TowerCategory.SPECIAL)
| タワー | コスト | 特徴 |
|--------|--------|------|
| Trap Mine | 40 | 踏んだ敵に大爆発・使い捨て |
| Frost Field | 160 | 範囲内敵を継続スロー |
| Gravity Well | 180 | 敵を中心に引き寄せ |
| Flame Turret | 170 | 連続ビームダメージ+燃焼 |

## 敵一覧

| 敵 | HP | 速度 | AI戦略 |
|----|-----|------|--------|
| Swarm | 50 | 5 | 最近傍ターゲット |
| Tank | 400 | 2 | タワー優先 |
| Siege | 250 | 2.5 | 構造物のみターゲット |
| Flying | 120 | 4 | 空中直線移動 |
| Assassin | 150 | 4.5 | 支援塔/Cleric優先 |
| Elite Swarm | 200 | 4.5 | 仲間スウォームを引き連れる |
| Elite Tank | 900 | 1.8 | HP再生付き |
| Goblin Scout | 60 | 4.5 | 仲間に警告 |
| Orc Warrior | 300 | 3 | 低HPでバーサーク |
| Dark Mage | 180 | 2.5 | 遠距離魔法+ミニオン召喚 |
| Boss | 3000 | 2.5 | 3フェーズで行動変化 |
