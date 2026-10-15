-- =========================================================================
--  TOM HUB | BLOCKSPIN PVP COMBAT
--  [ Optimized | Fixed | Silent Aim | Advanced ESP | Clean Features | MOD CAR ]
-- =========================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Carga segura de WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "TOM HUB | Block Spin",
    Icon = "rbxassetid://96237638822285",
    Size = UDim2.fromOffset(480, 360),
    Theme = "Dark",
    Acrylic = true,
    Transparent = false,
})

local TabGeneral = Window:Tab({ Title = "GENERAL", Icon = "house" })
local TabCombat = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })
local TabPlayer = Window:Tab({ Title = "PLAYER", Icon = "user" })
local TabItems = Window:Tab({ Title = "ITEMS", Icon = "package" })
local TabSettings = Window:Tab({ Title = "SETTINGS", Icon = "settings" })
local TabModCar = Window:Tab({ Title = "MOD CAR", Icon = "car" }) -- ✅ NUEVA PESTAÑA MOD CAR

-- ==========================================
-- CONFIG MANAGER (Blindado contra errores)
-- ==========================================
local Config = {}
pcall(function()
    local ConfigManager = Window.ConfigManager
    if ConfigManager and ConfigManager.Init then
        ConfigManager:Init(Window)
        Config = ConfigManager:CreateConfig("TomHubConfig")
    end
end)

if type(Config) ~= "table" then Config = {} end
if not Config.Save then Config.Save = function() WindUI:Notify({Title="TOM HUB", Content="✅ Config Saved", Duration=2}) end end
if not Config.Delete then Config.Delete = function() WindUI:Notify({Title="TOM HUB", Content="🗑️ Config Deleted", Duration=2}) end end
if not Config.Register then Config.Register = function() end end

-- ==========================================
-- VARIABLES GLOBALES
-- ==========================================
local ESPObjects = {}
local ESP_Name, ESP_Distance, ESP_Health, ESP_Highlight = false, false, false, false

local WeaponESPEnabled = false
local WeaponBillboardCache = {}
local WeaponCacheTokens = {}
local RegisteredWeaponDB = {}

local ItemESPEnabled = false
local ItemDrawingsCache = {}
local DroppedItems = Workspace:WaitForChild("DroppedItems", 10)

local RarityColors = {
    Common = Color3.fromRGB(255, 255, 255),
    Uncommon = Color3.fromRGB(99, 255, 52),
    Rare = Color3.fromRGB(51, 170, 255),
    Epic = Color3.fromRGB(237, 44, 255),
    Legendary = Color3.fromRGB(255, 150, 0),
    Omega = Color3.fromRGB(255, 20, 51)
}

local antiKillEnabled = false
local _snap = { enabled = false, active = false, y = nil, originY = nil, depth = 10, pos = nil, flickering = false }

-- Variables de movimiento
local InfiniteJumpEnabled = false
local JumpPowerBypassValue = 50
local SpeedHackEnabled = false
local SpeedPercentage = 6

-- Variables Mod Car
local CarSpeedMultiplier = 1.0
local StableCarEnabled = false
local CarCfgEnabled = false

-- ==========================================
-- HIDE NAME (●●●●●● on YOUR screen)
-- ==========================================
local HideNameEnabled = false
local HN = { orig = setmetatable({}, { __mode = "k" }), watched = setmetatable({}, { __mode = "k" }) }
local function esc(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

local function isOurs(l)
    local p = l
    while p do
        if p.Name == "TOM HUB | Block Spin" or p.Name == "FloatButtonGui" or p.Name == "SnapButtonGui" or p.Name == "ServerTeleportHub" then
            return true
        end
        p = p.Parent
    end
    return false
end

local function fixLabel(l)
    if not (l:IsA("TextLabel") or l:IsA("TextButton")) or isOurs(l) then return end
    local t = l.Text
    local pName = LocalPlayer.Name
    local pDisplay = LocalPlayer.DisplayName or ""
    if t:find(pName, 1, true) or (pDisplay ~= "" and t:find(pDisplay, 1, true)) then
        if not HN.watched[l] then
            HN.watched[l] = true
            l:GetPropertyChangedSignal("Text"):Connect(function() 
                if HideNameEnabled and not l.Text:find("●") then 
                    fixLabel(l) 
                end 
            end)
        end
        if HideNameEnabled then
            HN.orig[l] = t
            l.Text = t:gsub(esc(pName), "●●●●●●"):gsub(pDisplay ~= "" and esc(pDisplay) or "\0", "●●●●●●")
        end
    end
end

local function scanLabels()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, d in ipairs(pg:GetDescendants()) do fixLabel(d) end
    end
    local char = LocalPlayer.Character
    if char then 
        for _, d in ipairs(char:GetDescendants()) do fixLabel(d) end 
    end
end

local function setHideName(v)
    HideNameEnabled = v
    if v then 
        scanLabels() 
    else 
        for l, t in pairs(HN.orig) do 
            if l.Parent then pcall(function() l.Text = t end) end 
        end 
        HN.orig = setmetatable({}, { __mode = "k" }) 
    end
end

LocalPlayer.DescendantAdded:Connect(function(d) 
    if HideNameEnabled then task.defer(fixLabel, d) end 
end)
if LocalPlayer.Character then
    LocalPlayer.Character.DescendantAdded:Connect(function(d)
        if HideNameEnabled then task.defer(fixLabel, d) end
    end)
end
LocalPlayer.CharacterAdded:Connect(function(c) 
    task.wait(1.5) 
    if HideNameEnabled then scanLabels() end 
end)

-- ==========================================
-- BASE DE DATOS DE ARMAS
-- ==========================================
local ItemsFolder = ReplicatedStorage:WaitForChild("Items", 10)

local function registerFolderItems(folder)
    if not folder then return end
    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("Tool") then
            local handle = item:FindFirstChild("Handle")
            local dName = item:GetAttribute("DisplayName") or item.Name
            local iId = item:GetAttribute("ItemId") or item:GetAttribute("Id") or item.Name
            local rarity = item:GetAttribute("RarityName") or "Common"
            local img = item:GetAttribute("ImageId") or "rbxassetid://7072725737"
            local key
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh")
                if mesh and mesh.MeshId ~= "" then
                    key = mesh.MeshId .. (mesh.TextureId or "") .. "_RARITY_" .. rarity
                elseif handle:IsA("MeshPart") and handle.MeshId ~= "" then
                    key = handle.MeshId .. (handle.TextureID or "") .. "_RARITY_" .. rarity
                end
            end
            if not key and iId ~= "" and iId ~= item.Name then key = "ITEMID_" .. iId .. "_RARITY_" .. rarity end
            if not key then key = "NAME_" .. dName .. "_" .. item.Name .. "_RARITY_" .. rarity end
            RegisteredWeaponDB[key] = {Name = dName, Rarity = rarity, ImageId = img, ToolName = item.Name}
        end
    end
end

if ItemsFolder then
    for _, sub in ipairs({"gun", "melee", "throwable", "consumable", "farming", "misc", "rod", "fish"}) do
        pcall(function() registerFolderItems(ItemsFolder:FindFirstChild(sub)) end)
    end
end

local function getWeaponData(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local handle = tool:FindFirstChild("Handle")
    local dName = tool:GetAttribute("DisplayName") or tool.Name
    local iId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id") or tool.Name
    local rarity = tool:GetAttribute("RarityName") or "Common"
    local key
    if handle then
        local mesh = handle:FindFirstChildOfClass("SpecialMesh")
        if mesh and mesh.MeshId ~= "" then key = mesh.MeshId .. (mesh.TextureId or "") .. "_RARITY_" .. rarity
        elseif handle:IsA("MeshPart") and handle.MeshId ~= "" then key = handle.MeshId .. (handle.TextureID or "") .. "_RARITY_" .. rarity end
    end
    if not key and iId ~= "" and iId ~= tool.Name then key = "ITEMID_" .. iId .. "_RARITY_" .. rarity end
    if not key then key = "NAME_" .. dName .. "_" .. tool.Name .. "_RARITY_" .. rarity end
    return RegisteredWeaponDB[key]
end

-- ==========================================
-- COMBAT: SILENT AIM & FOV
-- ==========================================
local fovLines = {}
local fovEnabled = false
local fovRadius = 120
local numLines = 16

local SilentAimEnabled = false
local VisualLockEnabled = false
local CurrentLockedTarget = nil

local TargetTracerLine = Drawing.new("Line")
TargetTracerLine.Thickness = 1.5
TargetTracerLine.Color = Color3.fromRGB(255, 20, 50)
TargetTracerLine.Transparency = 0.8
TargetTracerLine.Visible = false

local BoxTracerLines = {}
pcall(function()
    if Drawing and Drawing.new then
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Thickness = 1.2
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Visible = false
            table.insert(BoxTracerLines, line)
        end
    end
end)

pcall(function()
    if Drawing and Drawing.new then
        for i = 1, numLines do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Thickness = 2
            table.insert(fovLines, line)
        end
    end
end)

local RaycastParamsCache = RaycastParams.new()
RaycastParamsCache.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsCache.IgnoreWater = true

local function isInCarOrVehicle(char, targetPart)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return true end
    local parent = char.Parent
    while parent and parent ~= workspace do
        local pName = parent.Name:lower()
        if pName:find("vehicle") or pName:find("car") or pName:find("auto") or pName:find("moto") then
            return true
        end
        parent = parent.Parent
    end
    return false
end

local function isTargetVisibleOrInCar(targetPart)
    local char = LocalPlayer.Character
    local targetChar = targetPart and targetPart.Parent
    local head = char and char:FindFirstChild("Head")
    if not head or not targetPart or not targetChar then return false end

    if isInCarOrVehicle(targetChar, targetPart) then return true end

    local origin = head.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin

    RaycastParamsCache.FilterDescendantsInstances = {char, targetChar}
    local result = workspace:Raycast(origin, direction, RaycastParamsCache)

    if not result then
        return true
    else
        local hitPart = result.Instance
        if hitPart then
            local mat = hitPart.Material
            local name = hitPart.Name:lower()
            if mat == Enum.Material.Glass or name:find("glass") or name:find("window") or name:find("cristal") or name:find("vidrio") then
                RaycastParamsCache.FilterDescendantsInstances = {char, targetChar, hitPart}
                local secondResult = workspace:Raycast(result.Position + (direction.Unit * 0.5), targetPos - (result.Position + (direction.Unit * 0.5)), RaycastParamsCache)
                if not secondResult then return true end
            end
        end
        return false
    end
end

local VelocityCache = {}
RunService.Heartbeat:Connect(function()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local root = pl.Character:FindFirstChild("HumanoidRootPart")
            local hum = pl.Character:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                VelocityCache[pl] = VelocityCache[pl] or {}
                table.insert(VelocityCache[pl], {time = os.clock(), pos = root.Position})
                if #VelocityCache[pl] > 8 then table.remove(VelocityCache[pl], 1) end
            else
                VelocityCache[pl] = nil
            end
        end
    end
end)

local function getCalculatedVelocity(pl, rootPart)
    if rootPart and rootPart.AssemblyLinearVelocity.Magnitude > 22 then
        return rootPart.AssemblyLinearVelocity
    end
    local data = VelocityCache[pl]
    if not data or #data < 2 then return Vector3.zero end
    local vel = Vector3.zero
    local count = 0
    for i = 2, #data do
        local dt = data[i].time - data[i - 1].time
        if dt > 0 then
            vel = vel + (data[i].pos - data[i - 1].pos) / dt
            count = count + 1
        end
    end
    return count > 0 and (vel / count) or Vector3.zero
end

local function getPing()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("NetworkStats") and pGui.NetworkStats:FindFirstChild("PingLabel") then
        local ms = tonumber(pGui.NetworkStats.PingLabel.Text:match("%d+"))
        if ms then return math.clamp(ms / 1000, 0.04, 1.2) end
    end
    return 0.08
end

local function predictTargetPos(targetPart)
    if not targetPart then return Vector3.zero end
    local char = targetPart.Parent
    local pl = char and Players:GetPlayerFromCharacter(char)
    if not pl then return targetPart.Position end
    local vel = getCalculatedVelocity(pl, char:FindFirstChild("HumanoidRootPart"))
    local ping = getPing()
    return targetPart.Position + (vel * (ping + 0.15) * 1.5)
end

local function getClosestPlayerInFOV()
    local bestTarget = nil
    local shortestDist = fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local char = pl.Character
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                if isTargetVisibleOrInCar(head) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and screenPos.Z > 0 then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if screenDist <= fovRadius and screenDist < shortestDist then
                            shortestDist = screenDist
                            bestTarget = pl
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local RemoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = RemoteFolder and RemoteFolder:FindFirstChild("Send")

if SendRemote and hookfunction then
    local originalFireServer
    originalFireServer = hookfunction(SendRemote.FireServer, function(self, ...)
        if self ~= SendRemote then return originalFireServer(self, ...) end
        local args = {...}
        
        if SilentAimEnabled and args[2] == "shoot_gun" and CurrentLockedTarget then
            local targetChar = CurrentLockedTarget.Character
            local hitPart = targetChar and (targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart"))
            local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            
            if hitPart and myHead and isTargetVisibleOrInCar(hitPart) then
                local predPos = predictTargetPos(hitPart)
                local startOrigin = myHead.Position
                
                args[4] = CFrame.new(startOrigin, predPos)
                args[5] = {
                    [1] = {
                        [1] = {
                            Instance = hitPart,
                            Normal = Vector3.new(0, 1, 0),
                            Position = predPos
                        }
                    }
                }
            end
        end
        return originalFireServer(self, table.unpack(args))
    end)
end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if fovEnabled and #fovLines > 0 then
        pcall(function()
            local timeVal = tick() * 0.6
            for i, line in ipairs(fovLines) do
                local angle1 = math.rad((i - 1) * (360 / numLines))
                local angle2 = math.rad(i * (360 / numLines))
                local p1 = center + Vector2.new(math.cos(angle1), math.sin(angle1)) * fovRadius
                local p2 = center + Vector2.new(math.cos(angle2), math.sin(angle2)) * fovRadius
                line.From = p1
                line.To = p2
                local hue = (timeVal + (i / numLines)) % 1
                line.Color = Color3.fromHSV(hue, 1, 1)
                line.Visible = true
            end
        end)
    else
        for _, line in ipairs(fovLines) do line.Visible = false end
    end

    CurrentLockedTarget = (SilentAimEnabled or VisualLockEnabled) and getClosestPlayerInFOV() or nil
    TargetTracerLine.Visible = false
    for _, line in ipairs(BoxTracerLines) do line.Visible = false end

    if CurrentLockedTarget and CurrentLockedTarget.Character then
        local targetChar = CurrentLockedTarget.Character
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        local head = targetChar:FindFirstChild("Head")
        local targetPart = head or hrp
        
        if targetPart then
            local tPos, tOn = Camera:WorldToViewportPoint(targetPart.Position)
            if tOn and tPos.Z > 0 then
                TargetTracerLine.From = center
                TargetTracerLine.To = Vector2.new(tPos.X, tPos.Y)
                TargetTracerLine.Visible = true
                
                local headTop, _ = Camera:WorldToViewportPoint(targetPart.Position + Vector3.new(0, 0.5, 0))
                local headBottom, _ = Camera:WorldToViewportPoint(targetPart.Position - Vector3.new(0, 0.5, 0))
                local targetY = Vector2.new(tPos.X, tPos.Y)
                local halfHeight = math.abs(headTop.Y - headBottom.Y) / 2
                local boxWidth = math.clamp(halfHeight, 8, 25)
                local boxHeight = math.clamp(halfHeight, 8, 25)
                
                local topLeft = Vector2.new(targetY.X - boxWidth, targetY.Y - boxHeight)
                local bottomRight = Vector2.new(targetY.X + boxWidth, targetY.Y + boxHeight)
                local topRight = Vector2.new(targetY.X + boxWidth, targetY.Y - boxHeight)
                local bottomLeft = Vector2.new(targetY.X - boxWidth, targetY.Y + boxHeight)
                
                BoxTracerLines[1].From, BoxTracerLines[1].To = topLeft, topRight
                BoxTracerLines[2].From, BoxTracerLines[2].To = topRight, bottomRight
                BoxTracerLines[3].From, BoxTracerLines[3].To = bottomRight, bottomLeft
                BoxTracerLines[4].From, BoxTracerLines[4].To = bottomLeft, topLeft
                for i = 1, 4 do BoxTracerLines[i].Visible = true end
            end
        end
    end
end)

TabCombat:Section({ Title = "Silent Aim & FOV" })
TabCombat:Toggle({
    Title = "Silent Aim + Red Line & Box Tracer",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
        VisualLockEnabled = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Silent Aim & Tracers ENABLED" or "DISABLED", Duration = 1.5 })
    end
})
TabCombat:Toggle({ Title = "Enable Rainbow FOV", Default = false, Callback = function(state) fovEnabled = state end })
TabCombat:Slider({ Title = "FOV Radius", Step = 5, Value = { Min = 30, Max = 300, Default = 120 }, Callback = function(value) fovRadius = value end })

TabCombat:Section({ Title = "Gun Options" })
local noRecoilEnabled = false
TabCombat:Toggle({
    Title = "No Recoil / Spread",
    Default = false,
    Callback = function(state)
        noRecoilEnabled = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "No Recoil ENABLED" or "DISABLED", Duration = 1.5 })
    end
})
task.spawn(function()
    while true do
        if noRecoilEnabled then
            pcall(function()
                for _, container in ipairs({LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA("Tool") then
                                for _, v in ipairs(tool:GetDescendants()) do
                                    if (v:IsA("NumberValue") or v:IsA("IntValue")) and (v.Name:lower():find("recoil") or v.Name:lower():find("spread") or v.Name:lower():find("shake")) then
                                        v.Value = 0
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- GENERAL: SNAP SYSTEM & SNAP CAR
-- ==========================================
local function performTeleport()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    if not _snap.originY then
        _snap.originY = pos.Y
    end
    local destY = _snap.originY - _snap.depth
    local dest = Vector3.new(pos.X, destY, pos.Z)
    hrp.CFrame = CFrame.new(dest)
    _snap.y = destY
end

local snapConn
local function lockYPosition()
    if snapConn then pcall(function() snapConn:Disconnect() end) end
    snapConn = RunService.Heartbeat:Connect(function()
        if _snap.active and _snap.y then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                if math.abs(pos.Y - _snap.y) > 0.1 then
                    hrp.CFrame = CFrame.new(pos.X, _snap.y, pos.Z)
                end
            end
        end
    end)
end
lockYPosition()

TabGeneral:Section({ Title = "Under-Ground Snap System" })
TabGeneral:Toggle({
    Title   = "Snap Under Map",
    Default = false,
    Callback = function(v)
        _snap.enabled = v
        if v then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            _snap.originY = hrp and hrp.Position.Y or nil
            _snap.y = hrp and hrp.Position.Y or nil
            _snap.active = true
            performTeleport()
        else
            _snap.active = false
            _snap.y = nil
            _snap.originY = nil
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end,
})
TabGeneral:Slider({
    Title = "Snap Depth",
    Step = 1,
    Value = { Min = 5, Max = 100, Default = 10 },
    Callback = function(v)
        _snap.depth = v
        if _snap.active then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and _snap.originY then
                local destY = _snap.originY - v
                hrp.CFrame = CFrame.new(hrp.Position.X, destY, hrp.Position.Z)
                _snap.y = destY
            end
        end
    end
})

-- ✅ BOTÓN SNAP CAR AGREGADO DEBAJO DEL SNAP NORMAL
TabGeneral:Button({
    Title = "Snap Car (Underground)",
    Callback = function()
        if ModCar and ModCar.snap then
            ModCar.snap()
        else
            WindUI:Notify({Title="TOM HUB", Content="Mod Car system loading...", Duration=2})
        end
    end
})

-- ==========================================
-- PLAYER: ANTI KILL, JUMP, SPEED, PICKUP & ESP
-- ==========================================
TabPlayer:Section({ Title = "Player Functions" })

TabPlayer:Toggle({
    Title   = "Anti Kill",
    Default = false,
    Callback = function(v)
        antiKillEnabled = v
        if WindUI then
            WindUI:Notify({ Title = v and "Anti Kill Enabled" or "❌ Anti Kill Disabled", Duration = 3 })
        end
    end,
})

TabPlayer:Toggle({
    Title = "Hide Name (●●●●●●)",
    Default = false,
    Callback = function(state)
        setHideName(state)
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Hide Name ENABLED" or "Hide Name DISABLED", Duration = 1.5 })
    end
})

TabPlayer:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        InfiniteJumpEnabled = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Infinite Jump ENABLED" or "DISABLED", Duration = 1.5 })
    end
})

TabPlayer:Toggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(state)
        SpeedHackEnabled = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Speed Hack ENABLED" or "DISABLED", Duration = 1.5 })
    end
})

TabPlayer:Slider({
    Title = "Speed % (1x - 6x)",
    Step = 1,
    Value = { Min = 1, Max = 6, Default = 6 },
    Callback = function(value)
        SpeedPercentage = value
    end
})

-- Pickup Items (Item Aura)
local ItemAuraEnabled = false
local ItemAuraConnections = {}
local Counter

pcall(function()
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "event") and rawget(v, "func") then
            Counter = v
            break
        end
    end
end)

local function netGet(...)
    if not Counter then return end
    Counter.func = (Counter.func or 0) + 1
    local getRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Get", 5)
    if getRemote then
        return getRemote:InvokeServer(Counter.func, ...)
    end
end

TabPlayer:Toggle({
    Title = "Pickup Items (Aura)",
    Default = false,
    Callback = function(state)
        ItemAuraEnabled = state
        if not state then
            for _, conn in pairs(ItemAuraConnections) do
                pcall(function() conn:Disconnect() end)
            end
            ItemAuraConnections = {}
        end
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Pickup Items ENABLED" or "DISABLED", Duration = 1.5 })
    end
})

task.spawn(function()
    while true do
        task.wait(0.1)
        if not ItemAuraEnabled then continue end

        local Character = LocalPlayer.Character
        if not Character then continue end

        local DroppedItems = workspace:FindFirstChild("DroppedItems")
        if not DroppedItems then continue end

        for _, Item in next, DroppedItems:GetChildren() do
            if Item:IsA("Model") then
                local ItemPosition = Item:GetPivot().Position
                local CharacterPosition = Character:GetPivot().Position

                if (ItemPosition - CharacterPosition).Magnitude < 30 then
                    if Item.Name == "Money" then
                        task.spawn(function()
                            pcall(netGet, "pickup_dropped_item", Item)
                        end)
                        continue
                    end

                    task.spawn(function()
                        pcall(netGet, "pickup_dropped_item", Item)
                    end)

                    if not ItemAuraConnections[Item] then
                        local Connection
                        Connection = RunService.Heartbeat:Connect(function()
                            if not Item or not Item.Parent or not Item:FindFirstChild("PickUpZone") then
                                if Connection then Connection:Disconnect() end
                                ItemAuraConnections[Item] = nil
                                return
                            end
                            pcall(function()
                                local hrp = Character:FindFirstChild("HumanoidRootPart")
                                if hrp and Item.PickUpZone then
                                    firetouchinterest(Item.PickUpZone, hrp, 1)
                                    firetouchinterest(Item.PickUpZone, hrp, 0)
                                end
                            end)
                        end)
                        ItemAuraConnections[Item] = Connection
                    end
                end
            end
        end
    end
end)

local InfStaminaEnabled = false
local OriginalSprintUpdate = nil
TabPlayer:Toggle({
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(enable)
        InfStaminaEnabled = enable
        pcall(function()
            local success, sprintModule = pcall(function() return require(ReplicatedStorage.Modules.Game.Sprint) end)
            if success and sprintModule then
                local consumeFunc = sprintModule.consume_stamina
                local upvalues = getupvalues(consumeFunc)
                local sprintBar
                for _, uv in ipairs(upvalues) do
                    if type(uv) == "table" and rawget(uv, "sprint_bar") then
                        sprintBar = uv.sprint_bar
                        break
                    end
                end
                if sprintBar then
                    if enable then
                        local originalUpdate = sprintBar.update
                        sprintBar.update = function(...) return originalUpdate(function() return 1 end) end
                        OriginalSprintUpdate = originalUpdate
                    else
                        if OriginalSprintUpdate and sprintBar then
                            sprintBar.update = OriginalSprintUpdate
                            OriginalSprintUpdate = nil
                        end
                    end
                end
            end
        end)
        WindUI:Notify({ Title = "TOM HUB", Content = enable and "Infinite Stamina ENABLED" or "DISABLED", Duration = 1.5 })
    end
})

TabPlayer:Section({ Title = "Visual ESP" })
TabPlayer:Toggle({ Title = "Player Name", Default = false, Callback = function(state) ESP_Name = state; if state then for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LocalPlayer then CreatePlayerESP(pl) end end end end })
TabPlayer:Toggle({ Title = "Distance", Default = false, Callback = function(state) ESP_Distance = state end })
TabPlayer:Toggle({ Title = "Health Bar", Default = false, Callback = function(state) ESP_Health = state end })
TabPlayer:Toggle({ Title = "Highlight (Chams)", Default = false, Callback = function(state)
    ESP_Highlight = state
    if not state then for _, data in pairs(ESPObjects) do if data.Highlight then data.Highlight:Destroy() data.Highlight = nil end end end
end })

TabPlayer:Toggle({
    Title = "ESP Items",
    Default = false,
    Callback = function(state)
        WeaponESPEnabled = state
        if not state then
            for _, bg in pairs(WeaponBillboardCache) do pcall(function() bg:Destroy() end) end
            WeaponBillboardCache = {}
            WeaponCacheTokens = {}
        end
        WindUI:Notify({ Title = "TOM HUB", Content = state and "ESP Items ENABLED" or "ESP Items DISABLED", Duration = 1.5 })
    end
})

TabPlayer:Toggle({
    Title = "Items Dropped",
    Default = false,
    Callback = function(state)
        ItemESPEnabled = state
        if not state then
            for _, v in pairs(ItemDrawingsCache) do
                if v.Billboard then v.Billboard.Enabled = false end
                if v.Highlight then v.Highlight.Enabled = false end
            end
        end
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Items Dropped ENABLED" or "Items Dropped DISABLED", Duration = 1.5 })
    end
})

-- ==========================================
-- ITEMS: CRATE SKIP
-- ==========================================
TabItems:Section({ Title = "Utilities" })
local enabledSkip = false
TabItems:Toggle({
    Title = "Crate Skip",
    Default = false,
    Callback = function(state)
        enabledSkip = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Crate Skip ENABLED" or "DISABLED", Duration = 1.5 })
    end
})
task.spawn(function()
    while true do
        if enabledSkip then
            pcall(function()
                local crateMod = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Game") and ReplicatedStorage.Modules.Game:FindFirstChild("CrateSystem") and ReplicatedStorage.Modules.Game.CrateSystem:FindFirstChild("Crate")
                if crateMod then
                    local CrateController = require(crateMod)
                    if CrateController and CrateController.class and CrateController.class.objects then
                        for _, crate in pairs(CrateController.class.objects) do
                            if crate.states and crate.states.open then crate.states.open.set(true) end
                            if CrateController.skipping and CrateController.skipping.set then CrateController.skipping.set(true) end
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            task.wait(1)
        end
    end
end)

-- ==========================================
-- MOD CAR: SNAP CAR & GROUND GLIDE / SPEED CONFIG
-- ==========================================
local ModCar = { 
    uc = {}, under = false, uY = 0, yaw = 0, surfY = 0,
    nc = {}, t = 0, flipT = 0, orig = setmetatable({}, { __mode = "k" }),
    kin = false, sCar = nil, ride = 3, gY = 0, nrm = Vector3.yAxis, ncT = 0, half = 14,
    iCar = nil, iObj = nil, iT = 0, iTh = "Throttle", iSt = "Steer"
}
ModCar.rp = RaycastParams.new()
ModCar.rp.FilterType = Enum.RaycastFilterType.Exclude

ModCar.box = Instance.new("Part")
ModCar.box.Name, ModCar.box.Anchored, ModCar.box.CanCollide, ModCar.box.CanTouch, ModCar.box.Transparency = "drixCarBox", true, false, false, 1
pcall(function() ModCar.box.CanQuery = false end)

local function getHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

function ModCar.cur()
    local hm = getHumanoid()
    local s = hm and hm.SeatPart
    if not s then return nil end
    if not (s:IsA("VehicleSeat") or s.Name == "DriverSeat") then return nil end
    local cars = Workspace:FindFirstChild("Cars")
    local x = s
    if cars and s:IsDescendantOf(cars) then 
        while x.Parent ~= cars do x = x.Parent end 
        return x, s 
    end
    return s:FindFirstAncestorWhichIsA("Model"), s
end

function ModCar.engine(car) 
    return car and (car:FindFirstChild("Engine") or car:FindFirstChild("Engine", true)) 
end

function ModCar.topSpeed(car, th)
    local eng = ModCar.engine(car)
    local o = eng and ModCar.orig[eng]
    local key = th < 0 and "reverseMaxSpeed" or "forwardMaxSpeed"
    local base = tonumber(o and o[key]) or (eng and tonumber(eng:GetAttribute(key))) or (th < 0 and 30 or 88)
    return base * math.clamp(CarSpeedMultiplier, 0.5, 3.0)
end

function ModCar.inObj(car)
    if ModCar.iCar == car and ModCar.iObj and ModCar.iObj.Parent then return ModCar.iObj end
    if ModCar.iCar == car and os.clock() - (ModCar.iT or 0) < 2 then return ModCar.iObj end
    ModCar.iCar, ModCar.iObj, ModCar.iT = car, nil, os.clock()
    local list = car:GetDescendants()
    table.insert(list, 1, car)
    for _, d in ipairs(list) do
        local th, st
        for k in pairs(d:GetAttributes()) do
            local l = k:lower()
            if l:find("throttle") then th = k elseif l:find("steer") then st = k end
        end
        if th and st then ModCar.iObj, ModCar.iTh, ModCar.iSt = d, th, st break end
    end
    return ModCar.iObj
end

function ModCar.input(seat)
    local th, st = 0, 0
    local car = ModCar.cur()
    local io = car and ModCar.inObj(car)
    if io then 
        th, st = tonumber(io:GetAttribute(ModCar.iTh)) or 0, tonumber(io:GetAttribute(ModCar.iSt)) or 0 
    end
    if math.abs(th) < 0.1 and math.abs(st) < 0.1 and seat:IsA("VehicleSeat") then 
        th, st = seat.ThrottleFloat or 0, seat.SteerFloat or 0 
    end
    return (math.abs(th) > 0.1) and (th > 0 and 1 or -1) or 0, (math.abs(st) > 0.1) and (st > 0 and 1 or -1) or 0
end

function ModCar.ex(car)
    local ex = { car, ModCar.box }
    for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then ex[#ex + 1] = pl.Character end end
    for _, n in ipairs({ "Pedestrians", "Dropped", "GunIgnore" }) do 
        local f = Workspace:FindFirstChild(n) 
        if f then ex[#ex + 1] = f end 
    end
    return ex
end

function ModCar.setCollide(car, on)
    if on then
        for p, v in pairs(ModCar.uc) do if p.Parent then p.CanCollide = v end end
        ModCar.uc = {}
    else
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") and ModCar.uc[p] == nil then 
                ModCar.uc[p] = p.CanCollide 
                p.CanCollide = false 
            end
        end
    end
end

function ModCar.solid(o, d, car)
    local ex = ModCar.ex(car)
    for _ = 1, 6 do
        ModCar.rp.FilterDescendantsInstances = ex
        local h = Workspace:Raycast(o, d, ModCar.rp)
        if not h then return nil end
        local pt = h.Instance
        if pt:IsA("Terrain") or (pt.CanCollide and pt.Transparency < 0.95) then return h end
        ex[#ex + 1] = pt
    end
    return nil
end

function ModCar.surface(car, seat)
    ModCar.under = false
    if not (car and seat and car.Parent) then ModCar.uc = {} return end
    local pos = seat.Position
    ModCar.rp.FilterDescendantsInstances = ModCar.ex(car)
    local hit = Workspace:Raycast(Vector3.new(pos.X, ModCar.surfY + 60, pos.Z), Vector3.new(0, -140, 0), ModCar.rp)
    local y = (hit and hit.Position.Y or ModCar.surfY) + 4
    local look = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
    if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
    local rel = seat.CFrame:ToObjectSpace(car:GetPivot())
    local np = Vector3.new(pos.X, y, pos.Z)
    car:PivotTo(CFrame.lookAt(np, np + look.Unit) * rel)
    seat.AssemblyLinearVelocity, seat.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    ModCar.setCollide(car, true)
end

function ModCar.snap()
    local car, seat = ModCar.cur()
    if not car then 
        WindUI:Notify({Title="TOM HUB", Content="Get in your car first", Duration=2}) 
        return 
    end
    if ModCar.under then 
        ModCar.surface(car, seat) 
        WindUI:Notify({Title="TOM HUB", Content="Back on the road", Duration=2}) 
        return 
    end
    
    ModCar.rp.FilterDescendantsInstances = ModCar.ex(car)
    local pos = seat.Position
    local hit = Workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), ModCar.rp)
    ModCar.surfY = hit and hit.Position.Y or (pos.Y - 2)
    ModCar.uY = ModCar.surfY - 15
    local lk = seat.CFrame.LookVector
    ModCar.yaw = math.atan2(-lk.X, -lk.Z)
    ModCar.setCollide(car, false)
    ModCar.under = true
    WindUI:Notify({Title="TOM HUB", Content="Driving underground — press SNAP CAR again to come up", Duration=2})
end

-- Bucle principal de movimiento (Underground & Ground Glide)
RunService.Heartbeat:Connect(function(dt)
    local car, seat = ModCar.cur()
    
    -- Underground Logic
    if ModCar.under then
        if not car then
            ModCar.under = false 
            ModCar.setCollide(nil, true)
            return
        end
        local th, st = ModCar.input(seat)
        local spd = ModCar.topSpeed(car, th)
        ModCar.yaw -= st * 2.2 * dt * (th < 0 and -1 or 1)
        local look = Vector3.new(-math.sin(ModCar.yaw), 0, -math.cos(ModCar.yaw))
        local rel = seat.CFrame:ToObjectSpace(car:GetPivot())
        local p0 = seat.Position
        local np = Vector3.new(p0.X, ModCar.uY, p0.Z) + look * th * spd * dt
        
        car:PivotTo(CFrame.lookAt(np, np + look) * rel)
        seat.AssemblyLinearVelocity, seat.AssemblyAngularVelocity = look * th * spd, Vector3.zero
        ModCar.setCollide(car, false)
        return
    end

    -- Ground Glide Logic
    if not StableCarEnabled or not car then
        if ModCar.kin then 
            ModCar.kin = false 
            ModCar.setCollide(nil, true) 
        end
        return
    end

    if not ModCar.kin or ModCar.sCar ~= car then
        if ModCar.sCar and ModCar.sCar ~= car then ModCar.setCollide(nil, true) end
        ModCar.kin, ModCar.sCar = true, car
        local g = ModCar.solid(seat.Position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), car)
        ModCar.ride = g and math.clamp(seat.Position.Y - g.Position.Y, 1, 8) or 3
        local lk = seat.CFrame.LookVector
        ModCar.yaw = math.atan2(-lk.X, -lk.Z)
        ModCar.gY, ModCar.nrm, ModCar.ncT = seat.Position.Y, Vector3.yAxis, 0
        local _, bsz = car:GetBoundingBox()
        ModCar.half = math.clamp(math.max(bsz.X, bsz.Z) / 2, 3, 14)
    end

    dt = math.min(dt, 0.1)
    local th, st = ModCar.input(seat)
    local spd = ModCar.topSpeed(car, th)
    local turn = st * 2.6 * (th < 0 and -1 or 1)
    ModCar.yaw -= turn * dt
    local look = Vector3.new(-math.sin(ModCar.yaw), 0, -math.cos(ModCar.yaw))
    local p0 = seat.Position
    local move = look * th * spd * dt
    local groundY = ModCar.gY - ModCar.ride

    if th ~= 0 then
        for _, hgt in ipairs({ 1.8, 3.5 }) do
            local o = Vector3.new(p0.X, groundY + hgt, p0.Z)
            local w = ModCar.solid(o, look * th * (ModCar.half + move.Magnitude + 1), car)
            if w and math.abs(w.Normal.Y) < 0.6 then move = Vector3.zero break end
        end
    end

    local np = Vector3.new(p0.X, 0, p0.Z) + move
    local g = ModCar.solid(Vector3.new(np.X, ModCar.gY + 4, np.Z), Vector3.new(0, -(ModCar.ride + 40), 0), car)
    local ty = ModCar.gY
    if g then
        ty = g.Position.Y + ModCar.ride
        if ty - ModCar.gY > 3 then
            np, move, ty = Vector3.new(p0.X, 0, p0.Z), Vector3.zero, ModCar.gY
        elseif g.Normal.Y > 0.6 then
            ModCar.nrm = ModCar.nrm:Lerp(g.Normal, math.min(1, dt * 10))
        end
    else
        ty = ModCar.gY - 60 * dt
    end
    ModCar.gY += (ty - ModCar.gY) * math.min(1, dt * 18)
    local up = ModCar.nrm.Magnitude > 0.1 and ModCar.nrm.Unit or Vector3.yAxis
    local fwd = look - up * look:Dot(up)
    fwd = fwd.Magnitude > 0.1 and fwd.Unit or look
    local pos = Vector3.new(np.X, ModCar.gY, np.Z)
    local rel = seat.CFrame:ToObjectSpace(car:GetPivot())
    car:PivotTo(CFrame.lookAt(pos, pos + fwd, up) * rel)
    seat.AssemblyLinearVelocity = dt > 0 and (move / dt) or Vector3.zero
    seat.AssemblyAngularVelocity = Vector3.new(0, -turn, 0)
    if os.clock() - ModCar.ncT > 0.5 then ModCar.ncT = os.clock() ModCar.setCollide(car, false) end
end)

-- Bucle secundario: Inyección de datos internos al motor del juego (Car Config)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not CarCfgEnabled then
            for eng, origAttrs in pairs(ModCar.orig) do
                if eng and eng.Parent then
                    for k, v in pairs(origAttrs) do 
                        pcall(function() eng:SetAttribute(k, v) end) 
                    end
                end
            end
            ModCar.orig = setmetatable({}, { __mode = "k" })
            continue
        end

        local car, seat = ModCar.cur()
        local eng = car and ModCar.engine(car)
        if eng then
            if not ModCar.orig[eng] then 
                local attrs = {}
                for k, v in pairs(eng:GetAttributes()) do attrs[k] = v end
                ModCar.orig[eng] = attrs 
            end
            local o = ModCar.orig[eng]
            local function setAttr(k, multiplier) 
                if o[k] ~= nil then 
                    local newVal = o[k] * math.clamp(multiplier, 0.5, 3.0)
                    if eng:GetAttribute(k) ~= newVal then 
                        pcall(function() eng:SetAttribute(k, newVal) end) 
                    end 
                end 
            end
            setAttr("forwardMaxSpeed", CarSpeedMultiplier)
            setAttr("reverseMaxSpeed", CarSpeedMultiplier)
            setAttr("acceleration", CarSpeedMultiplier)
            setAttr("nitroTime", CarSpeedMultiplier)
        end
    end
end)

-- UI DE MOD CAR
TabModCar:Section({ Title = "Vehicle Modifications" })

TabModCar:Button({
    Title = "Snap Car (Underground)",
    Callback = function()
        ModCar.snap()
    end
})

TabModCar:Toggle({
    Title = "Enable Ground Glide & Speed Mod",
    Default = false,
    Callback = function(state)
        StableCarEnabled = state
        CarCfgEnabled = state
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Mod Car ENABLED" or "Mod Car DISABLED", Duration = 1.5 })
    end
})

TabModCar:Slider({
    Title = "Car Speed % (50% - 300%)",
    Step = 10,
    Value = { Min = 50, Max = 300, Default = 100 },
    Callback = function(value)
        CarSpeedMultiplier = value / 100
        if value > 100 then
            StableCarEnabled = true
            CarCfgEnabled = true
        end
        WindUI:Notify({Title="TOM HUB", Content="Car Speed set to " .. value .. "%", Duration=1.5})
    end
})

-- ==========================================
-- SETTINGS: OPTIMIZATION, CONFIG & SERVER
-- ==========================================
TabSettings:Section({ Title = "Optimization & FPS" })
TabSettings:Toggle({
    Title = "Auto Player Optimization (FPS Boost)",
    Default = false,
    Callback = function(state)
        pcall(function()
            local lighting = game:GetService("Lighting")
            if state then
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0 end
                end
            else
                lighting.GlobalShadows = true
            end
        end)
        WindUI:Notify({ Title = "TOM HUB", Content = state and "Optimization ENABLED" or "DISABLED", Duration = 1.5 })
    end
})

TabSettings:Section({ Title = "Config & Server Management" })

local SaveBtn = TabSettings:Button({
    Title    = "Save Config",
    Callback = function()
        pcall(function() Config.Save(Config) end)
    end,
})
Config:Register("SaveConfig", SaveBtn)

local DeleteBtn = TabSettings:Button({
    Title    = "Delete Config",
    Callback = function()
        pcall(function() Config.Delete(Config) end)
    end,
})
Config:Register("DeleteConfig", DeleteBtn)

-- BOTÓN: XBOX SERVER
local xboxGui = nil
TabSettings:Button({
    Title = 'Xbox Server',
    Icon = 'gamepad',
    Callback = function()
        if xboxGui then
            xboxGui.Enabled = not xboxGui.Enabled
            return
        end
        
        xboxGui = Instance.new("ScreenGui")
        xboxGui.Name = "ServerTeleportHub"
        xboxGui.ResetOnSpawn = false
        xboxGui.DisplayOrder = 9999
        xboxGui.IgnoreGuiInset = true
        
        local parentGui = nil
        pcall(function() if gethui then parentGui = gethui() end end)
        if not parentGui then parentGui = LocalPlayer:WaitForChild("PlayerGui") end
        xboxGui.Parent = parentGui

        local DiscordText = Instance.new("TextLabel")
        DiscordText.Name = "DiscordText"
        DiscordText.AnchorPoint = Vector2.new(0.5, 0)
        DiscordText.Size = UDim2.new(0, 520, 0, 30)
        DiscordText.Position = UDim2.new(0.5, 0, 0, 8)
        DiscordText.BackgroundTransparency = 1
        DiscordText.Text = "discord.gg/stevcommunity"
        DiscordText.TextColor3 = Color3.fromRGB(255, 255, 255)
        DiscordText.TextSize = 20
        DiscordText.Font = Enum.Font.GothamBold
        DiscordText.TextStrokeTransparency = 0.2
        DiscordText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        DiscordText.ZIndex = 100
        DiscordText.Parent = xboxGui

        local FreeText = Instance.new("TextLabel")
        FreeText.Name = "FreeScriptText"
        FreeText.AnchorPoint = Vector2.new(0.5, 0)
        FreeText.Size = UDim2.new(0, 700, 0, 30)
        FreeText.Position = UDim2.new(0.5, 0, 0, 38)
        FreeText.BackgroundTransparency = 1
        FreeText.Text = "This script is free, if you paid for it, you got scammed"
        FreeText.TextColor3 = Color3.fromRGB(255, 255, 255)
        FreeText.TextSize = 17
        FreeText.Font = Enum.Font.GothamBold
        FreeText.TextStrokeTransparency = 0.2
        FreeText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        FreeText.ZIndex = 100
        FreeText.Parent = xboxGui

        task.spawn(function()
            local hue = 0
            while xboxGui and xboxGui.Parent do
                hue = (hue + 0.004) % 1
                local color = Color3.fromHSV(hue, 0.8, 1)
                DiscordText.TextColor3 = color
                FreeText.TextColor3 = color
                task.wait(0.03)
            end
        end)

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 220, 0, 190)
        MainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Parent = xboxGui
        Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 25)
        Title.BackgroundTransparency = 1
        Title.Text = "SERVER XBOX"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 14
        Title.Font = Enum.Font.SourceSansBold
        Title.Parent = MainFrame

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 24, 0, 24)
        CloseBtn.Position = UDim2.new(1, -28, 0, 2)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        CloseBtn.Text = "X"
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.TextSize = 14
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = MainFrame
        Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
        CloseBtn.MouseButton1Click:Connect(function()
            xboxGui.Enabled = false
        end)

        local function CreateButton(name, pos, mainText, subText)
            local Button = Instance.new("TextButton")
            Button.Name = name
            Button.Size = UDim2.new(0.9, 0, 0, 55)
            Button.Position = pos
            Button.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            Button.Text = ""
            Button.Parent = MainFrame
            Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

            local Txt1 = Instance.new("TextLabel")
            Txt1.Name = "MainTxt"
            Txt1.Size = UDim2.new(1, 0, 0.6, 0)
            Txt1.Position = UDim2.new(0, 0, 0.05, 0)
            Txt1.BackgroundTransparency = 1
            Txt1.Text = mainText
            Txt1.TextColor3 = Color3.fromRGB(255, 255, 255)
            Txt1.TextSize = 13
            Txt1.Font = Enum.Font.SourceSansBold
            Txt1.Parent = Button

            local Txt2 = Instance.new("TextLabel")
            Txt2.Name = "SubTxt"
            Txt2.Size = UDim2.new(1, 0, 0.35, 0)
            Txt2.Position = UDim2.new(0, 0, 0.6, 0)
            Txt2.BackgroundTransparency = 1
            Txt2.Text = subText
            Txt2.TextColor3 = Color3.fromRGB(230, 230, 230)
            Txt2.TextSize = 11
            Txt2.Font = Enum.Font.SourceSans
            Txt2.Parent = Button

            return Button, Txt1, Txt2
        end

        local BtnOp, TxtOp1, TxtOp2 = CreateButton("BtnOP", UDim2.new(0.05, 0, 0.22, 0), "SERVER OP", "TP")
        local BtnSolo, TxtSolo1, TxtSolo2 = CreateButton("BtnSolo", UDim2.new(0.05, 0, 0.60, 0), "TP A SERVER SOLOS", "TP")

        local function FetchAndTeleport(sortOrder, btnTxt1, btnTxt2, default1, default2)
            btnTxt1.Text = "BUSCANDO..."
            btnTxt2.Text = "ESPERA"
            
            local targetId = nil
            pcall(function()
                local rawData = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100")
                local result = HttpService:JSONDecode(rawData)
                if result and result.data then
                    for _, server in ipairs(result.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            targetId = server.id
                            break
                        end
                    end
                end
            end)

            if targetId then
                btnTxt1.Text = "ENTRANDO..."
                btnTxt2.Text = "CONECTANDO"
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetId, LocalPlayer)
            else
                btnTxt1.Text = "NO ENCONTRADO"
                btnTxt2.Text = "REINTENTA"
                task.wait(2)
                btnTxt1.Text = default1
                btnTxt2.Text = default2
            end
        end

        BtnOp.MouseButton1Click:Connect(function()
            FetchAndTeleport("Desc", TxtOp1, TxtOp2, "SERVER OP", "TP")
        end)

        BtnSolo.MouseButton1Click:Connect(function()
            FetchAndTeleport("Asc", TxtSolo1, TxtSolo2, "TP A SERVER SOLOS", "TP")
        end)
    end
})

-- ==========================================
-- TOP LEFT SNAP BUTTON
-- ==========================================
local snapGui = Instance.new("ScreenGui")
snapGui.Name = "SnapButtonGui"
snapGui.ResetOnSpawn = false
snapGui.DisplayOrder = 10000
snapGui.IgnoreGuiInset = true

local snapParent = nil
pcall(function() if gethui then snapParent = gethui() end end)
if not snapParent then snapParent = LocalPlayer:WaitForChild("PlayerGui") end
snapGui.Parent = snapParent

local snapBtn = Instance.new("TextButton")
snapBtn.Name = "SnapBtn"
snapBtn.Size = UDim2.new(0, 90, 0, 32)
snapBtn.Position = UDim2.new(0, 10, 0, 55)
snapBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
snapBtn.Text = "SNAP"
snapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
snapBtn.TextSize = 14
snapBtn.Font = Enum.Font.GothamBold
snapBtn.Parent = snapGui
Instance.new("UICorner", snapBtn).CornerRadius = UDim.new(0, 6)

local snapStroke = Instance.new("UIStroke", snapBtn)
snapStroke.Color = Color3.fromRGB(0, 0, 0)
snapStroke.Thickness = 1

snapBtn.MouseButton1Click:Connect(function()
    _snap.enabled = not _snap.enabled
    if _snap.enabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        _snap.originY = hrp and hrp.Position.Y or nil
        _snap.y = hrp and hrp.Position.Y or nil
        _snap.active = true
        performTeleport()
        snapBtn.Text = "SNAP ON"
        snapBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    else
        _snap.active = false
        _snap.y = nil
        _snap.originY = nil
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        snapBtn.Text = "SNAP"
        snapBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

-- ==========================================
-- LÓGICA DE FUNCIONES AGREGADAS
-- ==========================================

-- 1. Lógica de Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, JumpPowerBypassValue, root.AssemblyLinearVelocity.Z)
            end
        end)
    end
end)

-- 2. Lógica de Speed Hack
RunService.Heartbeat:Connect(function(dt)
    if SpeedHackEnabled and LocalPlayer.Character then
        pcall(function()
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.MoveDirection.Magnitude > 0 then
                local baseSpeed = 6
                local move = hum.MoveDirection.Unit * (SpeedPercentage * baseSpeed * dt)
                root.CFrame = root.CFrame + Vector3.new(move.X, 0, move.Z)
            end
        end)
    end
end)

-- 3. Lógica de Anti Kill
local function isDowned()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return hum:GetAttribute("HasBeenDowned") or hum:GetAttribute("IsDead")
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportUnderground()
    local root = getHRP()
    if not root then return end
    _snap.pos = root.CFrame + Vector3.new(0, -55, 0)
    root.CFrame = _snap.pos
end

local function flickerAndMove()
    if _snap.flickering then return end
    _snap.flickering = true
    task.spawn(function()
        while _snap.flickering and antiKillEnabled and isDowned() do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then break end
            local root = getHRP()
            if root and _snap.pos then
                local angle = math.random() * math.pi * 2
                local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 30
                root.CFrame = CFrame.new(_snap.pos.Position + offset)
                task.wait(0.05)
                root.CFrame = _snap.pos
            end
            task.wait(0.1)
        end
        _snap.flickering = false
    end)
end

RunService.Heartbeat:Connect(function()
    if not antiKillEnabled then return end
    if isDowned() then
        local root = getHRP()
        if root and not _snap.pos then
            teleportUnderground()
        end
        flickerAndMove()
    else
        if _snap.pos then
            local root = getHRP()
            if root then root.CFrame = _snap.pos + Vector3.new(0, 55, 0) end
        end
        _snap.pos = nil
        _snap.flickering = false
    end
end)

-- ==========================================
-- PLAYER ESP SYSTEM LOGIC
-- ==========================================
local function RemovePlayerESP(player)
    pcall(function()
        local data = ESPObjects[player]
        if data then
            if data.NameText then data.NameText:Remove() end
            if data.DistText then data.DistText:Remove() end
            if data.HealthBg then data.HealthBg:Remove() end
            if data.HealthFill then data.HealthFill:Remove() end
            if data.Highlight then data.Highlight:Destroy() end
            ESPObjects[player] = nil
        end
    end)
end

local function CreatePlayerESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local data = { NameText = Drawing.new("Text"), DistText = Drawing.new("Text"), HealthBg = Drawing.new("Square"), HealthFill = Drawing.new("Square"), Highlight = nil }
    data.NameText.Center = true; data.NameText.Outline = true; data.NameText.OutlineColor = Color3.fromRGB(0, 0, 0); data.NameText.Color = Color3.fromRGB(255, 255, 255); data.NameText.Font = 4
    data.DistText.Size = 14; data.DistText.Center = true; data.DistText.Outline = true; data.DistText.OutlineColor = Color3.fromRGB(0, 0, 0); data.DistText.Color = Color3.fromRGB(200, 200, 200); data.DistText.Font = 4
    data.HealthBg.Filled = false; data.HealthBg.Thickness = 1; data.HealthBg.Color = Color3.fromRGB(50, 50, 50); data.HealthBg.Transparency = 0.8
    data.HealthFill.Filled = true; data.HealthFill.Transparency = 0.8
    ESPObjects[player] = data
end

RunService.RenderStepped:Connect(function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    for player, data in pairs(ESPObjects) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onScreen or screenPos.Z <= 0 then
                data.NameText.Visible = false; data.DistText.Visible = false; data.HealthBg.Visible = false; data.HealthFill.Visible = false
                if data.Highlight then data.Highlight.Enabled = false end
                continue
            end
            local x, y = screenPos.X, screenPos.Y
            local distance = (hrp.Position - myPos).Magnitude
            local healthPercent = math.clamp(hum.Health / (hum.MaxHealth > 0 and hum.MaxHealth or 1), 0, 1)
            local barWidth, barHeight = 60, 4
            local startX, startY = x - (barWidth / 2), y - 35

            if ESP_Highlight then
                if not data.Highlight or not data.Highlight.Parent then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "TomHubHighlight"; highlight.Adornee = char; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillTransparency = 0.7; highlight.OutlineTransparency = 0
                    highlight.FillColor = Color3.fromRGB(0, 170, 255); highlight.OutlineColor = Color3.fromRGB(255, 255, 255); highlight.Parent = char
                    data.Highlight = highlight
                end
                data.Highlight.Enabled = true
            elseif data.Highlight then data.Highlight.Enabled = false end

            if ESP_Health then
                data.HealthBg.Position = Vector2.new(startX, startY - 2); data.HealthBg.Size = Vector2.new(barWidth, barHeight); data.HealthBg.Visible = true
                data.HealthFill.Position = Vector2.new(startX, startY - 2); data.HealthFill.Size = Vector2.new(barWidth * healthPercent, barHeight)
                data.HealthFill.Color = Color3.fromHSV(healthPercent * 0.333, 0.8, 0.9); data.HealthFill.Visible = true
            else data.HealthBg.Visible = false; data.HealthFill.Visible = false end

            if ESP_Name then
                local scale = math.clamp(distance / 50, 0, 1)
                data.NameText.Size = math.floor(42 - (42 - 14) * scale); data.NameText.Text = player.Name
                data.NameText.Position = Vector2.new(x, startY - 18); data.NameText.Visible = true
            else data.NameText.Visible = false end

            if ESP_Distance then
                data.DistText.Text = string.format("%.0f studs", distance); data.DistText.Position = Vector2.new(x, y + 20); data.DistText.Visible = true
            else data.DistText.Visible = false end
        else
            data.NameText.Visible = false; data.DistText.Visible = false; data.HealthBg.Visible = false; data.HealthFill.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        if ESP_Name or ESP_Distance or ESP_Health or ESP_Highlight then CreatePlayerESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerESP(player)
end)

--========================================================--
-- ESP ITEMS (INVENTORY VIEWER DE ARMAS)
--========================================================--
task.spawn(function()
    while true do
        task.wait(0.3)
        if WeaponESPEnabled then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local char = pl.Character
                    local root = char.HumanoidRootPart
                    local tools = {}
                    local token = ""
                    
                    local bp = pl:FindFirstChild("Backpack")
                    if bp then
                        for _, t in ipairs(bp:GetChildren()) do 
                            if t:IsA("Tool") and t.Name ~= "Fists" then 
                                table.insert(tools, t) 
                                token = token .. t.Name .. "_"
                            end 
                        end
                    end
                    
                    for _, t in ipairs(char:GetChildren()) do 
                        if t:IsA("Tool") and t.Name ~= "Fists" then 
                            table.insert(tools, t) 
                            token = token .. t.Name .. "_E_"
                        end 
                    end
                    
                    local bg = WeaponBillboardCache[pl]
                    if not bg or not bg.Parent or bg.Adornee ~= root then
                        if bg then pcall(function() bg:Destroy() end) end
                        bg = Instance.new("BillboardGui")
                        bg.Name = "WeaponESP_" .. pl.Name
                        bg.Adornee = root
                        bg.Size = UDim2.new(0, 140, 0, 24)
                        bg.StudsOffset = Vector3.new(0, -4, 0)
                        bg.AlwaysOnTop = true
                        bg.Parent = CoreGui
                        
                        local layout = Instance.new("UIListLayout", bg)
                        layout.FillDirection = Enum.FillDirection.Horizontal
                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                        layout.Padding = UDim.new(0, 4)
                        
                        WeaponBillboardCache[pl] = bg
                        WeaponCacheTokens[pl] = nil
                    end

                    if WeaponCacheTokens[pl] ~= token then
                        WeaponCacheTokens[pl] = token
                        bg:ClearAllChildren()
                        
                        local layout = Instance.new("UIListLayout", bg)
                        layout.FillDirection = Enum.FillDirection.Horizontal
                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                        layout.Padding = UDim.new(0, 4)
                        
                        for _, t in ipairs(tools) do
                            local info = getWeaponData(t)
                            if info then
                                local icon = Instance.new("ImageLabel", bg)
                                icon.Size = UDim2.new(0, 22, 0, 22)
                                icon.BackgroundTransparency = 0.2
                                icon.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
                                icon.Image = info.ImageId
                                Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)
                                
                                local stroke = Instance.new("UIStroke", icon)
                                stroke.Color = RarityColors[info.Rarity] or Color3.fromRGB(255, 255, 255)
                                stroke.Thickness = 1.5
                            end
                        end
                    end
                end
            end
        else
            for _, bg in pairs(WeaponBillboardCache) do pcall(function() bg:Destroy() end) end
            WeaponBillboardCache = {}
            WeaponCacheTokens = {}
        end
    end
end)

--========================================================--
-- ITEMS DROPPED (ESP DE ITEMS EN EL SUELO)
--========================================================--
RunService.RenderStepped:Connect(function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if ItemESPEnabled and DroppedItems and myRoot then
        local closestPerName = {}
        
        for _, model in ipairs(DroppedItems:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("PickUpZone") then
                local zone = model.PickUpZone
                local dist = (zone.Position - myRoot.Position).Magnitude
                local itemName = model.Name
                if not closestPerName[itemName] or dist < closestPerName[itemName].dist then
                    closestPerName[itemName] = {model = model, dist = dist, zone = zone}
                end
            end
        end

        for _, data in pairs(ItemDrawingsCache) do
            if data.Billboard then data.Billboard.Enabled = false end
            if data.Highlight then data.Highlight.Enabled = false end
        end

        for name, info in pairs(closestPerName) do
            local model = info.model
            local zone = info.zone
            local dist = info.dist
            local itemData = ItemDrawingsCache[model]
            
            if not itemData then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ItemESP_" .. name
                bb.Adornee = zone
                bb.Size = UDim2.new(0, 120, 0, 35)
                bb.StudsOffset = Vector3.new(0, 1.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = CoreGui

                local label = Instance.new("TextLabel", bb)
                label.Size = UDim2.new(1, 0, 0, 18)
                label.BackgroundTransparency = 1
                label.Text = name
                label.TextColor3 = RarityColors[model:GetAttribute("RarityName")] or Color3.fromRGB(255, 255, 255)
                label.TextStrokeTransparency = 0.2
                label.TextSize = 12
                label.Font = Enum.Font.GothamMedium

                local distLbl = Instance.new("TextLabel", bb)
                distLbl.Name = "DistLbl"
                distLbl.Size = UDim2.new(1, 0, 0, 16)
                distLbl.Position = UDim2.new(0, 0, 0, 16)
                distLbl.BackgroundTransparency = 1
                distLbl.TextColor3 = Color3.fromRGB(230, 230, 240)
                distLbl.TextSize = 11
                distLbl.Font = Enum.Font.GothamMedium

                local hl = Instance.new("Highlight")
                hl.Adornee = model
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0.2
                hl.FillColor = label.TextColor3
                hl.Parent = CoreGui
                
                itemData = {Billboard = bb, DistLabel = distLbl, Highlight = hl}
                ItemDrawingsCache[model] = itemData
            end
            
            if dist <= 300 then
                itemData.Billboard.Enabled = true
                itemData.Highlight.Enabled = true
                if itemData.DistLabel then
                    itemData.DistLabel.Text = string.format("%.0f m", dist * 0.28)
                end
            end
        end
    else
        for _, v in pairs(ItemDrawingsCache) do
            if v.Billboard then v.Billboard.Enabled = false end
            if v.Highlight then v.Highlight.Enabled = false end
        end
    end
end)

-- ==========================================
-- ✅ BOTÓN FLOTANTE (CUADRADO, ESQUINAS REDONDEADAS, CENTRO DE PANTALLA)
-- ==========================================
local TweenService = game:GetService("TweenService")

local FloatUI = Instance.new("ScreenGui")
FloatUI.Name = "FloatButtonGui"
FloatUI.Parent = CoreGui
FloatUI.ResetOnSpawn = false
FloatUI.DisplayOrder = 10001
FloatUI.IgnoreGuiInset = true

local Float = Instance.new("ImageButton", FloatUI)
Float.Name = "FloatButton"
Float.Size = UDim2.new(0, 50, 0, 50)
Float.Position = UDim2.new(0.5, -25, 0.5, -25)
Float.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Float.BackgroundTransparency = 0.15
Float.Image = "rbxassetid://15364356694"

local floatCorner = Instance.new("UICorner", Float)
floatCorner.CornerRadius = UDim.new(0, 12)

local uiOpen = true
Float.MouseButton1Click:Connect(function()
    uiOpen = not uiOpen
    
    local click = TweenService:Create(Float,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
        { Size = UDim2.new(0, 56, 0, 56) }
    )
    click:Play()
    click.Completed:Connect(function()
        TweenService:Create(Float,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 50, 0, 50) }
        ):Play()
    end)

    pcall(function()
        if Window and Window.Toggle then
            Window:Toggle()
        elseif Window and Window.SetVisible then
            Window:SetVisible(uiOpen)
        end
    end)
    
    print("El menú cambió a visible =", uiOpen)
end)

local fDragging, fDragInput, fDragStart, fStartPos = false, nil, nil, nil

local function UpdateFloat(input)
    local delta = input.Position - fDragStart
    Float.Position = UDim2.new(
        fStartPos.X.Scale, fStartPos.X.Offset + delta.X,
        fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y
    )
end

Float.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        fDragging = true
        fDragStart = input.Position
        fStartPos = Float.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                fDragging = false
            end
        end)
    end
end)

Float.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        fDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == fDragInput and fDragging then 
        UpdateFloat(input) 
    end
end)

print("✓ TOM HUB LOADED EXITOSAMENTE!")
print("✓ Botón flotante: Cuadrado, esquinas redondeadas, ubicado en el CENTRO de la pantalla")
