-- Junior Hub | LinoriaLib v5
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ========================================
--          REMOTE HELPER
-- ========================================

local function getRF(serviceName)
    local ok, rf = pcall(function()
        return RS.Packages._Index
            :FindFirstChild("leifstout_networker@0.3.1")
            .networker._remotes[serviceName].RemoteFunction
    end)
    return ok and rf or nil
end

local function getRE(serviceName)
    local ok, re = pcall(function()
        return RS.Packages._Index
            :FindFirstChild("leifstout_networker@0.3.1")
            .networker._remotes[serviceName].RemoteEvent
    end)
    return ok and re or nil
end

-- ========================================
--          HELPER FUNCTIONS
-- ========================================

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ========================================
--               NO FOG
-- ========================================

local NoFogEnabled     = false
local FogConn          = nil
local FogDescConn      = nil
local originalFogEnd   = nil
local originalFogStart = nil
local savedAtmosphere  = {}

local function applyNoFog()
    local L = game:GetService("Lighting")
    originalFogEnd = L.FogEnd; originalFogStart = L.FogStart
    L.FogEnd = 100000; L.FogStart = 100000
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") then
            savedAtmosphere = { Density = obj.Density, Offset = obj.Offset, Haze = obj.Haze, Glare = obj.Glare }
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end
    FogConn = L:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if NoFogEnabled then L.FogEnd = 100000 end
    end)
    FogDescConn = L.DescendantAdded:Connect(function(obj)
        if NoFogEnabled and obj:IsA("Atmosphere") then
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end)
end

local function removeNoFog()
    if FogConn     then FogConn:Disconnect();     FogConn     = nil end
    if FogDescConn then FogDescConn:Disconnect(); FogDescConn = nil end
    local L = game:GetService("Lighting")
    if originalFogEnd   then L.FogEnd   = originalFogEnd   end
    if originalFogStart then L.FogStart = originalFogStart end
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") and savedAtmosphere.Density then
            obj.Density = savedAtmosphere.Density; obj.Offset = savedAtmosphere.Offset
            obj.Haze    = savedAtmosphere.Haze;    obj.Glare  = savedAtmosphere.Glare
        end
    end
    savedAtmosphere = {}
end

-- ========================================
--         REMOVE TEXTURES / VISUALS
-- ========================================

local savedShadows = nil; local savedGrassLength = nil; local savedDecorations = nil

local function removeShadows()
    local L = game:GetService("Lighting"); savedShadows = L.GlobalShadows; L.GlobalShadows = false
end
local function restoreShadows()
    local L = game:GetService("Lighting"); if savedShadows ~= nil then L.GlobalShadows = savedShadows end
end

local function removeGrass()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then savedGrassLength = t.GrassLength; savedDecorations = t.Decoration; t.GrassLength = 0; t.Decoration = false end
end
local function restoreGrass()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        if savedGrassLength ~= nil then t.GrassLength = savedGrassLength end
        if savedDecorations ~= nil then t.Decoration  = savedDecorations end
    end
end

local savedMaterials = {}; local savedTextures = {}

local function removeTextures()
    savedMaterials = {}; savedTextures = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then savedMaterials[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic end
        if obj:IsA("Texture") or obj:IsA("Decal") then savedTextures[obj] = obj.Transparency; obj.Transparency = 1 end
    end
end
local function restoreTextures()
    for obj, mat   in pairs(savedMaterials) do if obj and obj.Parent then obj.Material     = mat   end end
    for obj, trans in pairs(savedTextures)  do if obj and obj.Parent then obj.Transparency = trans end end
    savedMaterials = {}; savedTextures = {}
end

local savedEffects = {}
local function removePostFX()
    savedEffects = {}
    for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("PostEffect") then savedEffects[obj] = obj.Enabled; obj.Enabled = false end
    end
end
local function restorePostFX()
    for obj, state in pairs(savedEffects) do if obj and obj.Parent then obj.Enabled = state end end
    savedEffects = {}
end

-- ========================================
--           FULL BRIGHT
-- ========================================

local FullBrightEnabled  = false
local FB_savedAmbient    = nil; local FB_savedOutdoor    = nil
local FB_savedBrightness = nil; local FB_savedColorShift = nil; local FB_Conn = nil

local function applyFullBright()
    local L = game:GetService("Lighting")
    FB_savedAmbient = L.Ambient; FB_savedOutdoor = L.OutdoorAmbient
    FB_savedBrightness = L.Brightness; FB_savedColorShift = L.ColorShift_Bottom
    L.Ambient = Color3.new(1,1,1); L.OutdoorAmbient = Color3.new(1,1,1)
    L.Brightness = 2; L.ColorShift_Bottom = Color3.new(0,0,0)
    FB_Conn = L:GetPropertyChangedSignal("Brightness"):Connect(function()
        if FullBrightEnabled then L.Brightness = 2 end
    end)
end

local function removeFullBright()
    if FB_Conn then FB_Conn:Disconnect(); FB_Conn = nil end
    local L = game:GetService("Lighting")
    if FB_savedAmbient    then L.Ambient           = FB_savedAmbient    end
    if FB_savedOutdoor    then L.OutdoorAmbient    = FB_savedOutdoor    end
    if FB_savedBrightness then L.Brightness        = FB_savedBrightness end
    if FB_savedColorShift then L.ColorShift_Bottom = FB_savedColorShift end
end

-- ========================================
--         TIME OF DAY CONTROL
-- ========================================

local ClockConn = nil

local function lockTime(hour)
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
    local L = game:GetService("Lighting"); L.ClockTime = hour
    ClockConn = RunService.Heartbeat:Connect(function() L.ClockTime = hour end)
end

local function unlockTime()
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
end

-- ========================================
--               FLIGHT
-- ========================================

local FlyEnabled = false; local FlySpeed = 60
local FlyConn = nil; local FlyVel = nil; local FlyAlign = nil
local FlyAtt0 = nil; local FlyAtt1 = nil

local function startFly()
    local root = getRoot(); local hum = getHumanoid()
    if not root or not hum then return end
    hum.PlatformStand = true
    FlyAtt0 = Instance.new("Attachment"); FlyAtt0.Parent = root
    FlyAtt1 = Instance.new("Attachment"); FlyAtt1.Parent = workspace.Terrain
    FlyVel = Instance.new("LinearVelocity")
    FlyVel.Attachment0 = FlyAtt0; FlyVel.MaxForce = math.huge
    FlyVel.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FlyVel.VectorVelocity = Vector3.zero; FlyVel.Parent = root
    FlyAlign = Instance.new("AlignOrientation")
    FlyAlign.Attachment0 = FlyAtt0; FlyAlign.Attachment1 = FlyAtt1
    FlyAlign.MaxTorque = math.huge; FlyAlign.MaxAngularVelocity = math.huge
    FlyAlign.Responsiveness = 200; FlyAlign.RigidityEnabled = true; FlyAlign.Parent = root
    FlyConn = RunService.Heartbeat:Connect(function()
        local r = getRoot(); if not r then return end
        local dir = Vector3.zero; local cf = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis  end
        FlyVel.VectorVelocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * FlySpeed
        local lookDir = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if lookDir.Magnitude > 0 then FlyAtt1.CFrame = CFrame.new(Vector3.zero, lookDir) end
    end)
end

local function stopFly()
    if FlyConn  then FlyConn:Disconnect();  FlyConn  = nil end
    if FlyVel   then FlyVel:Destroy();      FlyVel   = nil end
    if FlyAlign then FlyAlign:Destroy();    FlyAlign = nil end
    if FlyAtt0  then FlyAtt0:Destroy();     FlyAtt0  = nil end
    if FlyAtt1  then FlyAtt1:Destroy();     FlyAtt1  = nil end
    local hum = getHumanoid(); if hum then hum.PlatformStand = false end
end

local function setFly(state)
    FlyEnabled = state; if state then startFly() else stopFly() end
end

LocalPlayer.CharacterAdded:Connect(function()
    setFly(false); task.wait(0.1)
    if Options and Options.FlyToggle then Options.FlyToggle:SetValue(false) end
end)

-- ========================================
--              NOCLIP
-- ========================================

local NoclipEnabled = false; local NoclipConn = nil

local function startNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    local char = LocalPlayer.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local function setNoclip(state)
    NoclipEnabled = state; if state then startNoclip() else stopNoclip() end
end

-- ========================================
--             PLAYER ESP
-- ========================================

local ESPEnabled   = false
local ESPBills     = {}
local ESPMaxDist   = 500

local function removeESP(player)
    if ESPBills[player] then ESPBills[player]:Destroy(); ESPBills[player] = nil end
end

local function createESP(player)
    if player == LocalPlayer then return end
    if ESPBills[player] then return end

    local bill = Instance.new("BillboardGui")
    bill.Name         = "JH_ESP"
    bill.AlwaysOnTop  = true
    bill.Size         = UDim2.new(0, 150, 0, 40)
    bill.StudsOffset  = Vector3.new(0, 3.5, 0)
    bill.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.TextColor3             = Color3.new(0, 0, 0)
    label.TextStrokeColor3       = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.2
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 13
    label.LineHeight             = 1.3
    label.RichText               = false
    label.Parent                 = bill

    ESPBills[player] = bill

    local function attach(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then bill.Adornee = root; bill.Parent = root end
    end

    if player.Character then attach(player.Character) end
    player.CharacterAdded:Connect(function(char) if ESPEnabled then attach(char) end end)

    RunService.Heartbeat:Connect(function()
        if not ESPEnabled then label.Text = ""; return end
        local myRoot    = getRoot()
        local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and theirRoot then
            local dist = math.floor((myRoot.Position - theirRoot.Position).Magnitude)
            if dist <= ESPMaxDist then
                label.Text = player.Name .. "\n" .. dist .. " studs"
                label.Visible = true
            else
                label.Visible = false
            end
        else
            label.Text = player.Name
            label.Visible = true
        end
    end)
end

local function enableESP()
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
end

local function disableESP()
    for _, bill in pairs(ESPBills) do
        local label = bill:FindFirstChildOfClass("TextLabel")
        if label then label.Text = ""; label.Visible = false end
    end
end

Players.PlayerAdded:Connect(function(p) if ESPEnabled then createESP(p) end end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

-- ========================================
--           AUTO EQUIP BEST
-- ========================================

local AutoEquipEnabled = false; local AutoEquipThread = nil

local function startAutoEquip()
    AutoEquipThread = task.spawn(function()
        while AutoEquipEnabled do
            pcall(function()
                local rf = getRF("InventoryService")
                if rf then rf:InvokeServer("requestEquipBest") end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoEquip()
    AutoEquipEnabled = false
    if AutoEquipThread then task.cancel(AutoEquipThread); AutoEquipThread = nil end
end

-- ========================================
--           AUTO REBIRTH
-- ========================================

local AutoRebirthEnabled = false; local AutoRebirthThread = nil

local function startAutoRebirth()
    AutoRebirthThread = task.spawn(function()
        while AutoRebirthEnabled do
            pcall(function()
                local rf = getRF("RebirthService")
                if rf then rf:InvokeServer("requestRebirth") end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoRebirth()
    AutoRebirthEnabled = false
    if AutoRebirthThread then task.cancel(AutoRebirthThread); AutoRebirthThread = nil end
end

-- ========================================
--            FAST ROLL (FIXED)
-- ========================================

local FastRollEnabled = false
local FastRollThread  = nil
local FastRollDelay   = 1.0

local function startFastRoll()
    FastRollThread = task.spawn(function()
        while FastRollEnabled do
            pcall(function()
                RS.Packages._Index
                    :FindFirstChild("leifstout_networker@0.3.1")
                    .networker._remotes.RollService.RemoteFunction
                    :InvokeServer(unpack({"requestRoll"}))
            end)
            task.wait(FastRollDelay)
        end
    end)
end

local function stopFastRoll()
    FastRollEnabled = false
    if FastRollThread then task.cancel(FastRollThread); FastRollThread = nil end
end

-- ========================================
--           AUTO CLAIM INDEX
-- ========================================

local AutoClaimIndexEnabled = false
local AutoClaimIndexThread  = nil
local INDEX_TIERS = { "basic", "big", "huge", "shiny", "inverted" }

local function startAutoClaimIndex()
    AutoClaimIndexThread = task.spawn(function()
        while AutoClaimIndexEnabled do
            pcall(function()
                local rf = getRF("IndexService")
                if rf then
                    for _, tier in ipairs(INDEX_TIERS) do
                        pcall(function()
                            rf:InvokeServer("requestClaimReward", tier)
                        end)
                        task.wait(0.3)
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoClaimIndex()
    AutoClaimIndexEnabled = false
    if AutoClaimIndexThread then task.cancel(AutoClaimIndexThread); AutoClaimIndexThread = nil end
end

-- ========================================
--           REDEEM ALL CODES
-- ========================================

local CODES = {
    "sliming", "goingBananas", "giveMeLuckNOW", "SPARKLEZ",
    "2muchluck", "test", "craftAway", "gullible", "time2Grind",
}

local function redeemAllCodes()
    local rf = getRF("CodeService")
    if not rf then Library:Notify('CodeService remote not found!', 3); return end
    task.spawn(function()
        local success = 0
        for _, code in ipairs(CODES) do
            local ok = pcall(function() rf:InvokeServer("redeem", code) end)
            if ok then success += 1 end
            task.wait(0.4)
        end
        Library:Notify('Codes attempted: ' .. success .. '/' .. #CODES, 4)
    end)
end

-- ========================================
--              LINORIA UI
-- ========================================

local Window = Library:CreateWindow({
    Title    = 'Junior Hub',
    Center   = true,
    AutoShow = true,
})

local Tabs = {
    Main     = Window:AddTab('Main'),
    Flying   = Window:AddTab('Flying'),
    ESP      = Window:AddTab('ESP'),
    Misc     = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings'),
}

-- ===== MAIN TAB =====

local AutoGroup = Tabs.Main:AddLeftGroupbox('Automation')

AutoGroup:AddToggle('AutoEquipToggle', {
    Text     = 'Auto Equip Best',
    Default  = false,
    Tooltip  = 'Equips your best gear every 2 seconds',
    Callback = function(value)
        AutoEquipEnabled = value
        if value then startAutoEquip() else stopAutoEquip() end
    end,
})

AutoGroup:AddToggle('AutoRebirthToggle', {
    Text     = 'Auto Rebirth',
    Default  = false,
    Tooltip  = 'Rebirths every 2 seconds when eligible',
    Callback = function(value)
        AutoRebirthEnabled = value
        if value then startAutoRebirth() else stopAutoRebirth() end
    end,
})

AutoGroup:AddToggle('AutoClaimIndexToggle', {
    Text     = 'Auto Claim Index',
    Default  = false,
    Tooltip  = 'Claims all index rewards (basic, big, huge, shiny, inverted) every cycle',
    Callback = function(value)
        AutoClaimIndexEnabled = value
        if value then startAutoClaimIndex() else stopAutoClaimIndex() end
    end,
})

AutoGroup:AddLabel('Claims: basic → big → huge → shiny → inverted')

local RollGroup = Tabs.Main:AddRightGroupbox('Fast Roll')

RollGroup:AddToggle('FastRollToggle', {
    Text     = 'Fast Roll',
    Default  = false,
    Tooltip  = 'Auto rolls every 1 second',
    Callback = function(value)
        FastRollEnabled = value
        if value then startFastRoll() else stopFastRoll() end
    end,
})

RollGroup:AddLabel('Roll delay fixed at 1.0s.')

local CodesGroup = Tabs.Main:AddRightGroupbox('Codes')

CodesGroup:AddButton('Redeem All Codes', redeemAllCodes)
CodesGroup:AddLabel('Codes:')
for _, code in ipairs(CODES) do
    CodesGroup:AddLabel('  ' .. code)
end

-- ===== FLYING TAB =====

local FlyGroup = Tabs.Flying:AddLeftGroupbox('Flight')

FlyGroup:AddToggle('FlyToggle', {
    Text     = 'Enable Flight',
    Default  = false,
    Tooltip  = 'W/A/S/D + Space/Shift to fly',
    Callback = function(value) setFly(value) end,
}):AddKeyPicker('FlyKeybind', {
    Default  = 'F', Mode = 'Toggle', Text = 'Flight',
    Callback = function()
        local new = not FlyEnabled; setFly(new); Options.FlyToggle:SetValue(new)
    end,
})

FlyGroup:AddSlider('FlySpeedSlider', {
    Text     = 'Flight Speed',
    Default  = 60, Min = 10, Max = 500, Rounding = 0, Suffix = ' studs/s',
    Callback = function(v) FlySpeed = v end,
})

FlyGroup:AddLabel('W/A/S/D = move  |  Space = up  |  Shift = down')

local MovGroup = Tabs.Flying:AddRightGroupbox('Movement')

MovGroup:AddSlider('WalkSpeedSlider', {
    Text     = 'Walk Speed',
    Default  = 16, Min = 1, Max = 300, Rounding = 0, Suffix = ' studs/s',
    Callback = function(value)
        local hum = getHumanoid(); if hum then hum.WalkSpeed = value end
    end,
})

MovGroup:AddSlider('JumpPowerSlider', {
    Text     = 'Jump Power',
    Default  = 50, Min = 0, Max = 300, Rounding = 0,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then hum.UseJumpPower = true; hum.JumpPower = value end
    end,
})

MovGroup:AddToggle('InfiniteJumpToggle', {
    Text     = 'Infinite Jump',
    Default  = false,
    Tooltip  = 'Jump again while airborne',
    Callback = function(value) _G.InfJump = value end,
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

MovGroup:AddToggle('NoclipToggle', {
    Text     = 'Noclip',
    Default  = false,
    Tooltip  = 'Walk through walls',
    Callback = function(value) setNoclip(value) end,
}):AddKeyPicker('NoclipKeybind', {
    Default  = 'N', Mode = 'Toggle', Text = 'Noclip',
    Callback = function()
        local new = not NoclipEnabled; setNoclip(new); Options.NoclipToggle:SetValue(new)
    end,
})

MovGroup:AddButton('Reset to Defaults', function()
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
    Options.WalkSpeedSlider:SetValue(16); Options.JumpPowerSlider:SetValue(50)
    Library:Notify('Movement reset.', 2)
end)

-- ===== ESP TAB =====

local ESPGroup = Tabs.ESP:AddLeftGroupbox('Player ESP')

ESPGroup:AddToggle('ESPToggle', {
    Text     = 'Enable Player ESP',
    Default  = false,
    Tooltip  = 'Shows player name and distance above their head',
    Callback = function(value)
        ESPEnabled = value
        if value then enableESP() else disableESP() end
    end,
})

ESPGroup:AddSlider('ESPDistSlider', {
    Text     = 'Max Visible Distance',
    Default  = 500, Min = 50, Max = 2000, Rounding = 0, Suffix = ' studs',
    Callback = function(value)
        ESPMaxDist = value
    end,
})

ESPGroup:AddLabel('Black bold text with white stroke.')
ESPGroup:AddLabel('Always visible through walls.')
ESPGroup:AddLabel('Hidden beyond max distance.')

-- ===== MISC TAB =====

local MiscFeatGroup = Tabs.Misc:AddLeftGroupbox('Visual Tweaks')

MiscFeatGroup:AddToggle('NoFogToggle', {
    Text     = 'No Fog',
    Default  = false,
    Tooltip  = 'Removes fog and zeroes Atmosphere haze/density',
    Callback = function(value)
        NoFogEnabled = value
        if value then applyNoFog() else removeNoFog() end
    end,
}):AddKeyPicker('NoFogKeybind', {
    Default  = 'None', Mode = 'Toggle', Text = 'No Fog',
    Callback = function()
        local new = not NoFogEnabled; NoFogEnabled = new
        Options.NoFogToggle:SetValue(new)
        if new then applyNoFog() else removeNoFog() end
    end,
})

MiscFeatGroup:AddToggle('NoShadowsToggle', {
    Text     = 'No Shadows',
    Default  = false,
    Tooltip  = 'Disables GlobalShadows — good FPS boost',
    Callback = function(value) if value then removeShadows() else restoreShadows() end end,
})

MiscFeatGroup:AddToggle('NoGrassToggle', {
    Text     = 'No Grass / Decorations',
    Default  = false,
    Tooltip  = 'Sets grass to 0 and disables terrain decorations',
    Callback = function(value) if value then removeGrass() else restoreGrass() end end,
})

MiscFeatGroup:AddToggle('NoTexturesToggle', {
    Text     = 'No Textures',
    Default  = false,
    Tooltip  = 'SmoothPlastic all parts, hide Decals/Textures',
    Callback = function(value) if value then removeTextures() else restoreTextures() end end,
})

MiscFeatGroup:AddToggle('NoPostFXToggle', {
    Text     = 'No Post-Processing FX',
    Default  = false,
    Tooltip  = 'Disables Bloom, Blur, ColorCorrection, SunRays',
    Callback = function(value) if value then removePostFX() else restorePostFX() end end,
})

MiscFeatGroup:AddLabel('Tip: No Shadows + No Grass = big FPS boost.')

local BrightGroup = Tabs.Misc:AddRightGroupbox('Lighting')

BrightGroup:AddToggle('FullBrightToggle', {
    Text     = 'Full Bright',
    Default  = false,
    Tooltip  = 'Max ambient so you can see everywhere',
    Callback = function(value)
        FullBrightEnabled = value
        if value then applyFullBright() else removeFullBright() end
    end,
})

BrightGroup:AddSlider('TimeSlider', {
    Text     = 'Time of Day',
    Default  = 14, Min = 0, Max = 24, Rounding = 1, Suffix = ':00',
    Callback = function(value) lockTime(value) end,
})

BrightGroup:AddButton('Unlock Time', function()
    unlockTime(); Library:Notify('Time unlocked.', 2)
end)

BrightGroup:AddLabel('0 = midnight  |  12 = noon  |  18 = dusk')

-- ===== SETTINGS TAB =====

local UIGroup = Tabs.Settings:AddLeftGroupbox('Menu')

UIGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightShift', NoUI = true, Text = 'Menu keybind',
})
Library.ToggleKeybind = Options.MenuKeybind

UIGroup:AddToggle('ShowKeybindList', {
    Text = 'Show Keybind List', Default = true,
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})

UIGroup:AddToggle('TransparentBGToggle', {
    Text = 'Transparent Background', Default = false,
    Callback = function(value)
        pcall(function() Library.MainFrame.BackgroundTransparency = value and 0.35 or 0 end)
    end,
})

local NotifGroup = Tabs.Settings:AddLeftGroupbox('Notifications')

NotifGroup:AddToggle('NotifEnabled', {
    Text = 'Enable Notifications', Default = true,
    Callback = function(value) Library.NotificationsEnabled = value end,
})

NotifGroup:AddSlider('NotifDuration', {
    Text = 'Notification Duration', Default = 3, Min = 1, Max = 10, Rounding = 0, Suffix = 's',
    Callback = function(value) Library.DefaultNotifDuration = value end,
})

local UtilGroup = Tabs.Settings:AddRightGroupbox('Utilities')

UtilGroup:AddButton('Rejoin', function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

UtilGroup:AddButton('Reset Character', function()
    local hum = getHumanoid(); if hum then hum.Health = 0 end
end)

UtilGroup:AddButton('Copy UserId', function()
    pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
    Library:Notify('UserId: ' .. tostring(LocalPlayer.UserId), 2)
end)

UtilGroup:AddButton('Copy Game ID', function()
    pcall(function() setclipboard(tostring(game.PlaceId)) end)
    Library:Notify('Place ID: ' .. game.PlaceId, 3)
end)

UtilGroup:AddButton('Stop All Features', function()
    _G.InfJump            = false
    NoFogEnabled          = false
    FullBrightEnabled     = false
    NoclipEnabled         = false
    ESPEnabled            = false
    AutoEquipEnabled      = false
    AutoRebirthEnabled    = false
    FastRollEnabled       = false
    AutoClaimIndexEnabled = false

    setFly(false); setNoclip(false); disableESP()
    stopAutoEquip(); stopAutoRebirth(); stopFastRoll(); stopAutoClaimIndex()
    removeNoFog(); restoreShadows(); restoreGrass()
    restoreTextures(); restorePostFX(); removeFullBright(); unlockTime()

    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end

    Options.FlyToggle:SetValue(false)
    Options.InfiniteJumpToggle:SetValue(false)
    Options.NoclipToggle:SetValue(false)
    Options.ESPToggle:SetValue(false)
    Options.AutoEquipToggle:SetValue(false)
    Options.AutoRebirthToggle:SetValue(false)
    Options.FastRollToggle:SetValue(false)
    Options.AutoClaimIndexToggle:SetValue(false)
    Options.NoFogToggle:SetValue(false)
    Options.NoShadowsToggle:SetValue(false)
    Options.NoGrassToggle:SetValue(false)
    Options.NoTexturesToggle:SetValue(false)
    Options.NoPostFXToggle:SetValue(false)
    Options.FullBrightToggle:SetValue(false)
    Options.WalkSpeedSlider:SetValue(16)
    Options.JumpPowerSlider:SetValue(50)

    Library:Notify('All features stopped and reset.', 2)
end)

UtilGroup:AddLabel('"Stop All" resets everything to default.')

-- ========================================
--        THEME / SAVE SETUP
-- ========================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder('JuniorHub')
SaveManager:SetFolder('JuniorHub/configs')
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify('Junior Hub loaded!', 3)
