# 太阴神术 (TaiYinShenShu) - 《了不起的修仙模拟器》模组

> **Steam版《了不起的修仙模拟器》大型模组**  
> 源自烛龙阴形态的极致阴行术法，向目标释放黑色光束，附带多重DEBUFF与心魔化形机制。

---

## 模组信息

| 项目 | 内容 |
|------|------|
| 模组名称 | TaiYinShenShu |
| 中文名称 | 太阴神术 |
| 游戏版本 | 0.95 (Steam版) |
| 模组版本 | 1 |
| 作者 | Millennium |
| 排序 | 200 |

---

## 术法：太阴神术

### 基本属性

| 属性 | 数值 |
|------|------|
| 所属类型 | 术法技能（非神通） |
| 境界要求 | 元神期 |
| 目标阵营 | 敌方 |
| 目标类型 | 手选单位 |
| 施法间隔 | 1秒 |
| 施法时间 | 瞬发（0秒） |
| 灵气消耗 | 1000点 |
| 灵气伤害 | 1000点 |
| 弹道速度 | 50（极快） |
| 射程 | 无限（锁敌跟踪） |

### 五大特性

#### 特性一：五行阴阳伤害加成
- 对五行属阴（金、水）的目标 **+2倍伤害**
- 对五行属阳（火、木）的目标 **正常伤害**
- 对土属性和无属性的目标 **-0.5倍伤害**

#### 特性二：太阴之息叠加 + 属性内伤
- 每次命中叠加 **1层太阴之息**标记
- 同时附加 **金属性** 或 **水属性** 的DEBUFF内伤（随机或同时触发）
- 金属性内伤：降低金属性抗性、护盾转化率
- 水属性内伤：降低水属性抗性、护盾转化率

#### 特性三：心境压制 + 伤害倍增
- 每次命中强制 **-2点心境**
- 伤害与目标心境 **成反比**（心境越低，伤害越高）
- 心境0时伤害翻倍

#### 特性四：暴走重伤（心境低于50）
- 目标心境低于50时，下一次命中触发 **暴走**
- 造成 **10%最大生命值** 的 **无视灵气护盾** 伤害
- 强制目标 **重伤昏迷**（FLAG_MINDHOLD）、**沉默**（FLAG_SILENT）、**禁用法宝**（FLAG_FORBID_FABAO）
- 强制 **装备/物品掉落**
- 额外叠加 **20层太阴之息**
- 属于真气/灵气类暴走DEBUFF，无保底伤害设定

#### 特性五：心魔化形（50层太阴之息）
- 太阴之息达到 **50层**时，在目标身边生成 **心魔化形** 黑色幻影实体
- 太阴之息层数 **归零** 重新开始叠加
- 心魔化形会释放与目标相同的术法和法宝，进行 **无止休攻击**
- 心魔化形消失条件：目标本体死亡、心魔被打死、目标逃离此图
- 目标境界越高，心魔化形 **越强**，使用的法宝 **越多**

### 获取方式

秘籍《太阴神术》在 **游戏第49天** 自动掉落在玩家门派地图上（**仅掉落一次**）。

---

## 文件结构

```
TaiYinShenShu/
├── Info.json                                    # 模组元信息
├── Scripts/
│   ├── TaiYinShenShu.lua                        # 入口脚本（第49天掉落秘籍 + 心魔跟踪）
│   └── Skill/
│       └── class/
│           └── taiyinshenshu.lua                # 术法核心战斗逻辑
├── Settings/
│   ├── Esoterica/
│   │   └── Esoterica_TaiYinShenShu.xml          # 秘籍定义
│   ├── Fight/
│   │   └── FightSkillTemplate/
│   │       └── FightSkill_TaiYinShenShu.xml     # 术法战斗模板
│   └── Modifiers/
│       └── Modifier_TaiYinShenShu.xml           # 所有Modifier（太阴之息/内伤/暴走）
└── Language/
    └── Chinese.txt                              # 本地化文本
```

---

## 安装方法

1. 将 `TaiYinShenShu` 文件夹复制到游戏目录下的 `Mods/` 文件夹中：
   ```
   F:/SteamLibrary/steamapps/common/AmazingCultivationSimulator/Mods/
   ```
2. 启动游戏，在模组管理器中启用 **太阴神术** 模组
3. 开始新游戏或继续已有存档（第49天自动掉落秘籍）

---

## 技术参考

- 烛龙阴形态技能：`Scripts/SkillAction/class/zhulong/`
- 心魔化形机制：`GameUlt.CallENian()` 参照 `zhulong_xinmohuaxing.lua`
- 黑色光束特效：`Effect/A/Prefabs/Beams/Beam/Shadow Beam`
- 暗影命中特效：`Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact`

---

## 闭环验证

| 验证项 | 状态 |
|--------|------|
| Info.json → Mod名称 | ✅ `TaiYinShenShu` |
| 入口Lua → 掉落秘籍ID | ✅ `FightSkillEsoterica_TaiYinShenShu` |
| 秘籍XML → 技能ID | ✅ `DamageSkill_TaiYinShenShu` |
| 术法XML → ClassName | ✅ `taiyinshenshu` |
| 术法Lua → GetSkill | ✅ `taiyinshenshu` |
| 术法Lua → Modifier ID | ✅ 4个Modifier全部匹配 |
| 天数掉落 | ✅ 第49天（DayCount >= 48） |
| 境界要求 | ✅ 元神期（YuanShen） |
| 灵气消耗 | ✅ 1000点 |
| 施法间隔 | ✅ 1秒 |
| 心魔化形 | ✅ 使用 `CallENian` + 暗之幻影Modifier |

---

*模组制作完成，闭环验证通过，可直接使用。*
