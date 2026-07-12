--太阴神术 - 源自烛龙阴形态的极致阴行术法
--参照：烛龙阴形态（心魔龙息、心魔化形、恶念之渊、玄阴之息）
local tbTable = GameMain:GetMod("_SkillScript");
local tbSkill = tbTable:GetSkill("taiyinshenshu");

local BREATH_MAX = 50;          -- 太阴之息最大层数
local MIND_THRESHOLD = 50;    -- 心境暴走阈值
local RAMPAGE_HP_RATIO = 0.1;   -- 暴走伤害比例（10%最大生命值）

-- 获取目标的五行属性
function tbSkill:GetTargetElementKind(npc)
    if npc == nil or npc.PropertyMgr == nil or npc.PropertyMgr.Practice == nil or npc.PropertyMgr.Practice.Gong == nil then
        return g_emElementKind.None;
    end
    local ok, result = pcall(function()
        return npc.PropertyMgr.Practice.Gong.ElementKind;
    end);
    if ok and result ~= nil then
        return result;
    end
    return g_emElementKind.None;
end

-- 获取目标的心境值
function tbSkill:GetTargetMindState(npc)
    if npc == nil or npc.Needs == nil then
        return 100;
    end
    local ok, result = pcall(function()
        return npc.Needs:GetNeedValue("MindState");
    end);
    if ok and result ~= nil then
        return result;
    end
    return 100;
end

-- 获取目标的最大灵气值（作为生命值近似）
function tbSkill:GetTargetMaxLing(npc)
    if npc == nil or npc.PropertyMgr == nil then
        return 1000;
    end
    local ok, result = pcall(function()
        return npc.PropertyMgr.Practice.MaxLing;
    end);
    if ok and result ~= nil and result > 0 then
        return result;
    end
    ok, result = pcall(function()
        return npc.PropertyMgr.LingMaxValue;
    end);
    if ok and result ~= nil and result > 0 then
        return result;
    end
    return 1000;
end

-- 尝试使目标掉落装备
function tbSkill:ForceDropEquip(npc)
    if npc == nil or npc.Equip == nil then
        return;
    end
    local ok, result = pcall(function()
        local equips = npc.Equip:GetAllEquip();
        if equips ~= nil then
            for i = 0, equips.Count - 1, 1 do
                local equip = equips[i];
                if equip ~= nil then
                    local dropOk = pcall(function()
                        npc.Equip:DropEquip(equip);
                    end);
                end
            end
        end
    end);
end

-- 技能命中目标时调用（核心）
function tbSkill:FightBodyApply(skilldef, fightbody, from)
    if fightbody == nil or fightbody.Npc == nil or fightbody.Npc.IsDeath then
        return;
    end
    
    local npc = fightbody.Npc;
    local caster = from ~= nil and from.Npc or nil;
    
    -- 1. 添加太阴之息标记 (+1层)
    npc:AddModifier("Modifier_TaiYinShenShu_Breath");
    
    -- 获取当前层数
    local currentStack = 1;
    local modifier = npc.PropertyMgr:FindModifier("Modifier_TaiYinShenShu_Breath");
    if modifier ~= nil then
        currentStack = modifier.Stack;
    end
    
    -- 2. 附加金属性或水属性内伤（随机或同时）
    local rand = math.random(1, 3);
    if rand == 1 then
        npc:AddModifier("Modifier_TaiYinShenShu_MetalInjury");
    elseif rand == 2 then
        npc:AddModifier("Modifier_TaiYinShenShu_WaterInjury");
    else
        npc:AddModifier("Modifier_TaiYinShenShu_MetalInjury");
        npc:AddModifier("Modifier_TaiYinShenShu_WaterInjury");
    end
    
    -- 3. 强制-2点心境（通过Modifier的Properties已实现，每次添加都-2）
    -- 特性三：伤害与心境成反比在GetValueAddv中实现
    
    -- 4. 检测心境是否低于50，触发暴走重伤
    local mindState = self:GetTargetMindState(npc);
    local bRampage = false;
    if mindState < MIND_THRESHOLD then
        bRampage = true;
        -- 触发暴走重伤
        local maxLing = self:GetTargetMaxLing(npc);
        local rampageDamage = maxLing * RAMPAGE_HP_RATIO;
        
        -- 无视灵气护盾伤害（真气/灵气类暴走DEBUFF）
        npc:ReduceLingDamage(rampageDamage, g_emElementKind.None, true, XT("太阴暴走"), from);
        
        -- 添加暴走Modifier（强制昏迷、沉默、禁用法宝）
        npc:AddModifier("Modifier_TaiYinShenShu_Rampage");
        
        -- 尝试强制装备掉落
        self:ForceDropEquip(npc);
        
        -- 额外叠加20层太阴之息
        for i = 1, 20 do
            npc:AddModifier("Modifier_TaiYinShenShu_Breath");
        end
        
        -- 更新层数
        currentStack = currentStack + 20;
        if modifier ~= nil then
            currentStack = modifier.Stack + 20;
        end
        
        -- 播放暴走特效和消息
        WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact", npc.Pos, 3);
        WorldLua:CameraShake(1, 0.5);
        WorldLua:AddMsg(XT(string.format("[color=#2F2F2F]太阴神术[/color]触发[color=#FF0000]暴走[/color]！[color=#FF6347]%s[/color]心境崩溃，受到%.0f点无视护盾伤害，陷入昏迷，装备掉落！",
            npc.Name, rampageDamage)));
    end
    
    -- 5. 检测太阴之息是否达到50层，触发心魔化形
    if currentStack >= BREATH_MAX then
        -- 移除所有太阴之息层数
        npc:RemoveModifier("Modifier_TaiYinShenShu_Breath");
        
        -- 生成心魔化形
        self:SummonXinMoHuaXing(npc, caster);
        
        WorldLua:AddMsg(XT(string.format("[color=#FF6347]%s[/color]身上[color=#2F2F2F]太阴之息[/color]达到50层，[color=#FF0000]心魔化形[/color]降临！",
            npc.Name)));
    end
    
    -- 播放黑色光束特效和消息
    if not bRampage then
        WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Beam/Shadow Beam", npc.Pos, 2);
        WorldLua:AddMsg(XT(string.format("[color=#2F2F2F]太阴神术[/color]命中[color=#FF6347]%s[/color]，叠加[color=#4169E1]太阴之息[/color]！",
            npc.Name)));
    end
end

-- 生成心魔化形
-- 参照烛龙心魔化形：使用GameUlt.CallENian创建心魔
function tbSkill:SummonXinMoHuaXing(target, caster)
    if target == nil or target.IsDeath then
        return;
    end
    
    -- 使用CallENian创建心魔（参照烛龙心魔化形）
    local xinmo = GameUlt.CallENian(target);
    if xinmo ~= nil then
        -- 设置心魔名称
        xinmo:SetName(XT("心魔化形"));
        
        -- 根据目标境界设置心魔属性
        local targetGLevel = 0;
        if target.PropertyMgr ~= nil and target.PropertyMgr.Practice ~= nil then
            local ok, result = pcall(function()
                return target.PropertyMgr.Practice.GLevel;
            end);
            if ok then
                targetGLevel = result or 0;
            end
        end
        
        -- 给心魔添加属性（境界越高越强，使用的法宝越多）
        -- 使用烛龙的暗之幻影Modifier作为基础
        for i = 1, math.min(targetGLevel + 1, 5) do
            local ok = pcall(function()
                xinmo:AddModifier("Boss_Zhulong_YinShadow");
            end);
            if not ok then
                break;
            end
        end
        
        -- 根据境界额外添加属性
        if targetGLevel >= 4 then
            -- 高境界目标：心魔更强
            local ok = pcall(function()
                xinmo:AddModifier("Boss_Zhulong_ShadowFight");
            end);
        end
        
        -- 尝试复制目标的技能和法宝（增强心魔战斗力）
        self:CopyTargetSkillsToXinMo(target, xinmo);
        self:CopyTargetFabaoToXinMo(target, xinmo);
        
        -- 播放心魔化形特效
        WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact", xinmo.Pos, 5);
        WorldLua:CameraShake(1, 0.5);
        
        -- 记录心魔信息（通过Mod入口跟踪）
        local mod = GameMain:GetMod("TaiYinShenShu");
        if mod ~= nil and mod.xinmoList ~= nil then
            table.insert(mod.xinmoList, {
                xinmoID = xinmo.ID,
                targetID = target.ID,
                createTime = world ~= nil and world.DayCount or 0
            });
        end
        
        WorldLua:AddMsg(XT(string.format("[color=#FF0000]心魔化形[/color]在[color=#FF6347]%s[/color]身边凝聚成形，开始无止休攻击！",
            target.Name)));
    end
end

-- 复制目标的技能给心魔
function tbSkill:CopyTargetSkillsToXinMo(target, xinmo)
    if target == nil or xinmo == nil then
        return;
    end
    
    -- 尝试复制目标的功法/技能
    local ok, targetSkills = pcall(function()
        if target.PropertyMgr ~= nil and target.PropertyMgr.Skills ~= nil then
            return target.PropertyMgr.Skills;
        end
        return nil;
    end);
    
    if ok and targetSkills ~= nil then
        pcall(function()
            for i = 0, targetSkills.Count - 1, 1 do
                local skill = targetSkills[i];
                if skill ~= nil and skill.Name ~= nil then
                    pcall(function()
                        if xinmo.PropertyMgr ~= nil then
                            xinmo.PropertyMgr:LearnSkill(skill.Name);
                        end
                    end);
                end
            end
        end);
    end
    
    -- 尝试复制术法技能
    local ok2, targetFightSkills = pcall(function()
        if target.PropertyMgr ~= nil and target.PropertyMgr.FightSkills ~= nil then
            return target.PropertyMgr.FightSkills;
        end
        return nil;
    end);
    
    if ok2 and targetFightSkills ~= nil then
        pcall(function()
            for i = 0, targetFightSkills.Count - 1, 1 do
                local skill = targetFightSkills[i];
                if skill ~= nil and skill.Name ~= nil then
                    pcall(function()
                        if xinmo.PropertyMgr ~= nil then
                            xinmo.PropertyMgr:LearnSkill(skill.Name);
                        end
                    end);
                end
            end
        end);
    end
end

-- 复制目标的法宝给心魔
function tbSkill:CopyTargetFabaoToXinMo(target, xinmo)
    if target == nil or xinmo == nil or target.Equip == nil or xinmo.Equip == nil then
        return;
    end
    
    -- 获取目标的法宝列表
    local ok, targetFabaos = pcall(function()
        return target.Equip:FindFabao(nil);
    end);
    
    if ok and targetFabaos ~= nil then
        local copyCount = 0;
        for i = 0, targetFabaos.Count - 1, 1 do
            if copyCount >= 3 then
                break; -- 最多复制3个法宝
            end
            local fabao = targetFabaos[i];
            if fabao ~= nil then
                -- 尝试创建法宝并装备给心魔
                pcall(function()
                    local newFabao = ThingMgr:CreateThing(fabao.defName);
                    if newFabao ~= nil then
                        if fabao.Rate ~= nil then
                            newFabao.Rate = fabao.Rate;
                        end
                        if fabao.MaxLing ~= nil and fabao.MaxLing > 0 then
                            newFabao.MaxLing = fabao.MaxLing;
                            newFabao:AddLing(newFabao.MaxLing);
                        end
                        xinmo.Equip:AddEquip(newFabao);
                        copyCount = copyCount + 1;
                    end
                end);
            end
        end
    end
end

-- 伤害数值加成（特性一 + 特性三）
-- 特性一：对五行属阴（金、水）+2倍，对五行属阳（火、木）正常，对土/无-0.5倍
-- 特性三：伤害与目标心境成反比（心境越低，伤害越高）
function tbSkill:GetValueAddv(skilldef, fightbody, from)
    if fightbody == nil or fightbody.Npc == nil then
        return 0;
    end
    
    local npc = fightbody.Npc;
    local baseValue = skilldef.Value;
    
    -- 获取目标五行属性
    local elementKind = self:GetTargetElementKind(npc);
    
    -- 特性一：五行伤害加成
    local elementMultiplier = 1;
    if elementKind == g_emElementKind.Jin or elementKind == g_emElementKind.Shui then
        -- 阴属性（金、水）+2倍伤害
        elementMultiplier = 2;
    elseif elementKind == g_emElementKind.Tu or elementKind == g_emElementKind.None then
        -- 土属性和无属性 -0.5倍伤害
        elementMultiplier = 0.5;
    end
    -- 阳属性（火、木）正常伤害，不调整
    
    -- 特性三：伤害与目标心境成反比
    local mindState = self:GetTargetMindState(npc);
    local mindMultiplier = 1;
    if mindState < 100 and mindState > 0 then
        -- 心境越低，伤害越高
        -- 心境0时伤害翻倍，心境100时正常
        mindMultiplier = 1 + (1 - mindState / 100);
    end
    
    -- 计算总加成
    local totalMultiplier = elementMultiplier * mindMultiplier;
    local addValue = math.floor(baseValue * (totalMultiplier - 1));
    
    return addValue;
end

-- 弹道爆炸效果
function tbSkill:MissileBomb(skilldef, pos, from)
    -- 在爆炸点播放黑色光束特效
    WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact", pos, 2);
end
