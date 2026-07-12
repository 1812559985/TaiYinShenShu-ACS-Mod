--太阴神术Mod入口脚本
--参照：烛龙阴形态技能（心魔龙息、心魔化形、恶念之渊、玄阴之息）
local tbMod = GameMain:NewMod("TaiYinShenShu");

function tbMod:OnInit()
    self.bEsotericaDropped = false;
    self.xinmoList = {};
end

function tbMod:OnAfterLoad()
    self:TryDropEsoterica();
end

function tbMod:OnStep(dt)
    if world ~= nil and world.DayCount ~= nil then
        if self.nLastDay == nil then
            self.nLastDay = world.DayCount;
        elseif self.nLastDay ~= world.DayCount then
            self.nLastDay = world.DayCount;
            self:TryDropEsoterica();
        end
    end
    
    -- 检查心魔状态
    if self.xinmoList ~= nil then
        for i = #self.xinmoList, 1, -1 do
            local data = self.xinmoList[i];
            local xinmo = ThingMgr:FindThingByID(data.xinmoID);
            local target = ThingMgr:FindThingByID(data.targetID);
            
            if xinmo == nil or xinmo.IsDeath then
                -- 心魔已死亡或被移除
                table.remove(self.xinmoList, i);
            elseif target == nil then
                -- 目标已逃离此图（ThingMgr跨地图查找返回nil），启动计时器
                data.leaveTimer = (data.leaveTimer or 0) + dt;
                if data.leaveTimer > 60 then
                    -- 超过60秒仍未找到目标，心魔自行消散
                    if xinmo ~= nil and not xinmo.IsDeath then
                        WorldLua:AddMsg(XT("目标已逃离，[color=#FF0000]心魔化形[/color]消散于天地之间..."));
                        local ok = pcall(function()
                            xinmo:Die();
                        end);
                        if not ok then
                            pcall(function()
                                xinmo.IsDeath = true;
                            end);
                        end
                    end
                    table.remove(self.xinmoList, i);
                end
            elseif target.IsDeath then
                -- 目标已死亡，移除心魔
                if xinmo ~= nil and not xinmo.IsDeath then
                    local ok = pcall(function()
                        xinmo:Die();
                    end);
                    if not ok then
                        pcall(function()
                            xinmo.IsDeath = true;
                        end);
                    end
                end
                table.remove(self.xinmoList, i);
            else
                -- 目标仍在，重置逃离计时器
                data.leaveTimer = 0;
                
                -- 确保心魔与目标在同一地图
                local ok1, xinmoMap = pcall(function() return xinmo.Map end);
                local ok2, targetMap = pcall(function() return target.Map end);
                if ok1 and ok2 and xinmoMap ~= nil and targetMap ~= nil and xinmoMap ~= targetMap then
                    -- 目标已切换地图，启动计时器
                    data.leaveTimer = (data.leaveTimer or 0) + dt;
                    if data.leaveTimer > 60 then
                        if xinmo ~= nil and not xinmo.IsDeath then
                            WorldLua:AddMsg(XT("目标已逃离此图，[color=#FF0000]心魔化形[/color]消散于天地之间..."));
                            pcall(function() xinmo:Die(); end);
                        end
                        table.remove(self.xinmoList, i);
                    end
                end
            end
        end
    end
end

function tbMod:TryDropEsoterica()
    if self.bEsotericaDropped then
        return;
    end
    
    -- 游戏第49天掉落（DayCount从0开始，第49天是48）
    if world == nil or world.DayCount == nil or world.DayCount < 48 then
        return;
    end
    
    local nowMap = WorldLua:GetNowMap();
    if nowMap == nil then
        return;
    end
    
    local playerNpc = nil;
    if SchoolMgr ~= nil and SchoolMgr.MySchool ~= nil then
        local tbNpcs = SchoolMgr.MySchool:GetAllNpcs();
        if tbNpcs ~= nil and #tbNpcs > 0 then
            playerNpc = tbNpcs[1];
        end
    end
    
    if playerNpc ~= nil then
        playerNpc:DropEsoteric("FightSkillEsoterica_TaiYinShenShu");
        self.bEsotericaDropped = true;
        WorldLua:AddMsg(XT("一道[color=#2F2F2F]太阴之黑光[/color]从天而降，一本散发着幽暗气息的《太阴神术》秘籍降临在门派之中..."));
        WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact", playerNpc.Pos, 5);
    else
        local centerX = math.floor(nowMap.Width / 2);
        local centerY = math.floor(nowMap.Height / 2);
        
        local dropKey = nil;
        for radius = 0, 10 do
            for dx = -radius, radius do
                for dy = -radius, radius do
                    local x = centerX + dx;
                    local y = centerY + dy;
                    if x >= 0 and x < nowMap.Width and y >= 0 and y < nowMap.Height then
                        local key = GridMgr:Pos2Key(x, y);
                        if GridMgr:CanStand(key) and not Map.Things:KeyHasThing(key) then
                            dropKey = key;
                            break;
                        end
                    end
                end
                if dropKey ~= nil then break; end
            end
            if dropKey ~= nil then break; end
        end
        
        if dropKey ~= nil then
            local esoterica = ThingMgr:AddItemThing(dropKey, "Item_Esoterica", nil);
            if esoterica ~= nil then
                esoterica:SetData("Esoterica", "FightSkillEsoterica_TaiYinShenShu");
                self.bEsotericaDropped = true;
                WorldLua:AddMsg(XT("一道[color=#2F2F2F]太阴之黑光[/color]从天而降，一本散发着幽暗气息的《太阴神术》秘籍降临在门派之中..."));
                local dropPos = GridMgr:Key2Pos(dropKey);
                WorldLua:PlayEffect("Effect/A/Prefabs/Beams/Impact/ShadowBeamImpact", dropPos, 5);
            end
        end
    end
end

function tbMod:OnSave()
    return {
        bEsotericaDropped = self.bEsotericaDropped,
        xinmoList = self.xinmoList
    };
end

function tbMod:OnLoad(tbLoad)
    if tbLoad ~= nil then
        self.bEsotericaDropped = tbLoad.bEsotericaDropped or false;
        self.xinmoList = tbLoad.xinmoList or {};
    else
        self.bEsotericaDropped = false;
        self.xinmoList = {};
    end
end
