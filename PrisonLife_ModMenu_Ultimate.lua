--[[
╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                  ║
║   ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗    ██╗     ██╗███████╗███████╗                  ║
║   ██╔══██╗██╔══██╗██║██╔════╝██╔═══██╗████╗  ██║    ██║     ██║██╔════╝██╔════╝                  ║
║   ██████╔╝██████╔╝██║███████╗██║   ██║██╔██╗ ██║    ██║     ██║█████╗  █████╗                    ║
║   ██╔═══╝ ██╔══██╗██║╚════██║██║   ██║██║╚██╗██║    ██║     ██║██╔══╝  ██╔══╝                    ║
║   ██║     ██║  ██║██║███████║╚██████╔╝██║ ╚████║    ███████╗██║██║     ███████╗                  ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝╚═╝     ╚══════╝                  ║
║                                                                                                  ║
║                           ███╗   ███╗ ██████╗ ██████╗                                            ║
║                           ████╗ ████║██╔═══██╗██╔══██╗                                           ║
║                           ██╔████╔██║██║   ██║██║  ██║                                           ║
║                           ██║╚██╔╝██║██║   ██║██║  ██║                                           ║
║                           ██║ ╚═╝ ██║╚██████╔╝██████╔╝                                           ║
║                           ╚═╝     ╚═╝ ╚═════╝ ╚═════╝                                            ║
║                                                                                                  ║
║                      ███╗   ███╗███████╗███╗   ██╗██╗   ██╗                                      ║
║                      ████╗ ████║██╔════╝████╗  ██║██║   ██║                                      ║
║                      ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║                                      ║
║                      ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║                                      ║
║                      ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝                                      ║
║                      ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝                                       ║
║                                                                                                  ║
║                              ULTIMATE EDITION v2.0                                               ║
║                           Para Executores Mobile & PC                                            ║
║                                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFICAÇÃO DO JOGO
-- ═══════════════════════════════════════════════════════════════════════════════

if game.PlaceId ~= 155615604 then
    warn("⚠️ Este script é exclusivo para Prison Life!")
    return
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════════════

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Char, HRP, Hum

-- Configurações
local Settings = {
    -- Aimbot
    AimbotEnabled = false,
    AimbotKey = Enum.KeyCode.E,
    AimbotFOV = 150,
    AimbotSmooth = 0.5,
    AimbotTeamCheck = true,
    AimbotVisibleCheck = false,
    TargetPart = "Head",
    
    -- Silent Aim
    SilentAimEnabled = false,
    SilentAimFOV = 200,
    
    -- Triggerbot
    TriggerbotEnabled = false,
    TriggerbotDelay = 0.05,
    
    -- ESP
    ESPEnabled = false,
    ESPBoxes = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealthBars = true,
    ESPTeamCheck = true,
    ESPChams = false,
    ESPRainbowChams = false,
    
    -- Player
    GodModeEnabled = false,
    NoclipEnabled = false,
    FlyEnabled = false,
    FlySpeed = 50,
    SpeedEnabled = false,
    SpeedValue = 32,
    JumpPowerEnabled = false,
    JumpPowerValue = 100,
    InfiniteJumpEnabled = false,
    
    -- Weapons
    InfiniteAmmoEnabled = false,
    NoSpreadEnabled = false,
    RapidFireEnabled = false,
    InstantReloadEnabled = false,
    WallbangEnabled = false,
    DamageMultiplier = 1,
    
    -- Misc
    AntiArrestEnabled = false,
    AutoArrestEnabled = false,
    ClickTPEnabled = false,
    CtrlClickKillEnabled = false,
}

-- Estados
local States = {
    CurrentTarget = nil,
    ESPObjects = {},
    Connections = {},
    FlyBodyVelocity = nil,
    FlyBodyGyro = nil,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
}

-- Cores do tema
local Theme = {
    Primary = Color3.fromRGB(138, 43, 226),      -- Roxo vibrante
    Secondary = Color3.fromRGB(75, 0, 130),       -- Índigo
    Accent = Color3.fromRGB(255, 0, 255),         -- Magenta
    Background = Color3.fromRGB(15, 15, 25),      -- Quase preto
    BackgroundLight = Color3.fromRGB(25, 25, 40), -- Cinza escuro
    Text = Color3.fromRGB(255, 255, 255),         -- Branco
    TextDim = Color3.fromRGB(180, 180, 180),      -- Cinza claro
    Success = Color3.fromRGB(0, 255, 128),        -- Verde neon
    Error = Color3.fromRGB(255, 50, 50),          -- Vermelho
    Warning = Color3.fromRGB(255, 200, 0),        -- Amarelo
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════════════

local function UpdateCharacter()
    Char = LP.Character or LP.CharacterAdded:Wait()
    HRP = Char:WaitForChild("HumanoidRootPart")
    Hum = Char:WaitForChild("Humanoid")
    States.OriginalWalkSpeed = Hum.WalkSpeed
    States.OriginalJumpPower = Hum.JumpPower
end

LP.CharacterAdded:Connect(function()
    wait(0.5)
    UpdateCharacter()
end)
pcall(UpdateCharacter)

local function GetPlayers()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(players, {
                    Player = player,
                    Character = player.Character,
                    HRP = hrp,
                    Humanoid = hum,
                    Team = player.Team
                })
            end
        end
    end
    return players
end

local function IsTeammate(player)
    if not Settings.AimbotTeamCheck then return false end
    return LP.Team and player.Team and LP.Team == player.Team
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToScreenPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function IsVisible(part)
    if not Settings.AimbotVisibleCheck then return true end
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Camera})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function GetClosestPlayer()
    local closest = nil
    local closestDist = Settings.AimbotFOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, data in pairs(GetPlayers()) do
        if not IsTeammate(data.Player) then
            local targetPart = data.Character:FindFirstChild(Settings.TargetPart) or data.HRP
            local screenPos, onScreen = WorldToScreen(targetPart.Position)
            
            if onScreen then
                local dist = (screenPos - screenCenter).Magnitude
                if dist < closestDist and IsVisible(targetPart) then
                    closestDist = dist
                    closest = data
                end
            end
        end
    end
    
    return closest
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE AIMBOT
-- ═══════════════════════════════════════════════════════════════════════════════

local function Aimbot()
    if not Settings.AimbotEnabled then return end
    
    local target = GetClosestPlayer()
    if target then
        States.CurrentTarget = target
        local targetPart = target.Character:FindFirstChild(Settings.TargetPart) or target.HRP
        
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.AimbotSmooth)
    else
        States.CurrentTarget = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE SILENT AIM
-- ═══════════════════════════════════════════════════════════════════════════════

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Settings.SilentAimEnabled and method == "FireServer" then
        if self.Name == "ShootEvent" or self.Name:find("Shoot") or self.Name:find("Fire") then
            local target = GetClosestPlayer()
            if target then
                local targetPart = target.Character:FindFirstChild(Settings.TargetPart) or target.HRP
                -- Modificar argumentos para mirar no alvo
                for i, arg in pairs(args) do
                    if typeof(arg) == "Vector3" then
                        args[i] = targetPart.Position
                    elseif typeof(arg) == "CFrame" then
                        args[i] = CFrame.new(args[i].Position, targetPart.Position)
                    end
                end
            end
        end
    end
    
    return OldNamecall(self, unpack(args))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE TRIGGERBOT
-- ═══════════════════════════════════════════════════════════════════════════════

local function Triggerbot()
    if not Settings.TriggerbotEnabled then return end
    
    local target = Mouse.Target
    if target then
        local player = Players:GetPlayerFromCharacter(target.Parent)
        if player and player ~= LP and not IsTeammate(player) then
            wait(Settings.TriggerbotDelay)
            mouse1click()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE ESP
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateESP(player)
    if States.ESPObjects[player] then return end
    
    local esp = {}
    
    -- Box ESP
    esp.Box = Drawing.new("Square")
    esp.Box.Visible = false
    esp.Box.Color = Theme.Primary
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    
    -- Name ESP
    esp.Name = Drawing.new("Text")
    esp.Name.Visible = false
    esp.Name.Color = Theme.Text
    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.new(0, 0, 0)
    
    -- Distance ESP
    esp.Distance = Drawing.new("Text")
    esp.Distance.Visible = false
    esp.Distance.Color = Theme.TextDim
    esp.Distance.Size = 12
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.OutlineColor = Color3.new(0, 0, 0)
    
    -- Health Bar
    esp.HealthBarBG = Drawing.new("Square")
    esp.HealthBarBG.Visible = false
    esp.HealthBarBG.Color = Color3.new(0, 0, 0)
    esp.HealthBarBG.Filled = true
    
    esp.HealthBar = Drawing.new("Square")
    esp.HealthBar.Visible = false
    esp.HealthBar.Color = Theme.Success
    esp.HealthBar.Filled = true
    
    States.ESPObjects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(States.ESPObjects) do
        if not player or not player.Character or not player.Parent then
            -- Limpar ESP de jogadores que saíram
            for _, drawing in pairs(esp) do
                drawing:Remove()
            end
            States.ESPObjects[player] = nil
        else
            local character = player.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChild("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if hrp and hum and head and Settings.ESPEnabled then
                local screenPos, onScreen = WorldToScreen(hrp.Position)
                
                if onScreen and (not Settings.ESPTeamCheck or not IsTeammate(player)) then
                    local distance = GetDistance(HRP.Position, hrp.Position)
                    local scaleFactor = 1 / (distance / 100)
                    local boxSize = Vector2.new(50 * scaleFactor, 80 * scaleFactor)
                    
                    -- Box
                    if Settings.ESPBoxes then
                        esp.Box.Visible = true
                        esp.Box.Position = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                        esp.Box.Size = boxSize
                        
                        -- Cor baseada no time
                        if player.Team then
                            if player.Team.Name == "Criminals" then
                                esp.Box.Color = Color3.fromRGB(255, 100, 0)
                            elseif player.Team.Name == "Guards" then
                                esp.Box.Color = Color3.fromRGB(0, 100, 255)
                            elseif player.Team.Name == "Inmates" then
                                esp.Box.Color = Color3.fromRGB(255, 150, 0)
                            else
                                esp.Box.Color = Theme.Primary
                            end
                        end
                    else
                        esp.Box.Visible = false
                    end
                    
                    -- Name
                    if Settings.ESPNames then
                        esp.Name.Visible = true
                        esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - boxSize.Y / 2 - 20)
                        esp.Name.Text = player.Name
                    else
                        esp.Name.Visible = false
                    end
                    
                    -- Distance
                    if Settings.ESPDistance then
                        esp.Distance.Visible = true
                        esp.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + boxSize.Y / 2 + 5)
                        esp.Distance.Text = string.format("[%dm]", math.floor(distance))
                    else
                        esp.Distance.Visible = false
                    end
                    
                    -- Health Bar
                    if Settings.ESPHealthBars then
                        local healthPercent = hum.Health / hum.MaxHealth
                        local barHeight = boxSize.Y
                        local barWidth = 4
                        
                        esp.HealthBarBG.Visible = true
                        esp.HealthBarBG.Position = Vector2.new(screenPos.X - boxSize.X / 2 - 8, screenPos.Y - boxSize.Y / 2)
                        esp.HealthBarBG.Size = Vector2.new(barWidth, barHeight)
                        
                        esp.HealthBar.Visible = true
                        esp.HealthBar.Position = Vector2.new(screenPos.X - boxSize.X / 2 - 8, screenPos.Y - boxSize.Y / 2 + barHeight * (1 - healthPercent))
                        esp.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
                        
                        -- Cor baseada na vida
                        if healthPercent > 0.6 then
                            esp.HealthBar.Color = Theme.Success
                        elseif healthPercent > 0.3 then
                            esp.HealthBar.Color = Theme.Warning
                        else
                            esp.HealthBar.Color = Theme.Error
                        end
                    else
                        esp.HealthBarBG.Visible = false
                        esp.HealthBar.Visible = false
                    end
                else
                    -- Fora da tela
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Distance.Visible = false
                    esp.HealthBarBG.Visible = false
                    esp.HealthBar.Visible = false
                end
            else
                -- Sem personagem válido
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBarBG.Visible = false
                esp.HealthBar.Visible = false
            end
        end
    end
end

local function InitESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if States.ESPObjects[player] then
            for _, drawing in pairs(States.ESPObjects[player]) do
                drawing:Remove()
            end
            States.ESPObjects[player] = nil
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CHAMS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ApplyChams(character, color)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local highlight = part:FindFirstChild("ESPHighlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESPHighlight"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Parent = part
            end
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    end
end

local function RemoveChams(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local highlight = part:FindFirstChild("ESPHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

local function UpdateChams()
    local rainbowHue = tick() % 5 / 5
    local rainbowColor = Color3.fromHSV(rainbowHue, 1, 1)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            if Settings.ESPChams and (not Settings.ESPTeamCheck or not IsTeammate(player)) then
                local color = Settings.ESPRainbowChams and rainbowColor or Theme.Primary
                ApplyChams(player.Character, color)
            else
                RemoveChams(player.Character)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE GOD MODE
-- ═══════════════════════════════════════════════════════════════════════════════

local function GodMode()
    if not Settings.GodModeEnabled then return end
    if not Char or not Hum then return end
    
    -- Método 1: Resetar vida constantemente
    pcall(function()
        Hum.Health = Hum.MaxHealth
    end)
    
    -- Método 2: Remover dano
    pcall(function()
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("ForceField") then return end
        end
        
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = Char
        Debris:AddItem(ff, 0.1)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE NOCLIP
-- ═══════════════════════════════════════════════════════════════════════════════

local function Noclip()
    if not Settings.NoclipEnabled then return end
    if not Char then return end
    
    for _, part in pairs(Char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE FLY
-- ═══════════════════════════════════════════════════════════════════════════════

local function StartFly()
    if not HRP then return end
    
    States.FlyBodyVelocity = Instance.new("BodyVelocity")
    States.FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    States.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    States.FlyBodyVelocity.Parent = HRP
    
    States.FlyBodyGyro = Instance.new("BodyGyro")
    States.FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    States.FlyBodyGyro.P = 1000000
    States.FlyBodyGyro.Parent = HRP
end

local function StopFly()
    if States.FlyBodyVelocity then
        States.FlyBodyVelocity:Destroy()
        States.FlyBodyVelocity = nil
    end
    if States.FlyBodyGyro then
        States.FlyBodyGyro:Destroy()
        States.FlyBodyGyro = nil
    end
end

local function UpdateFly()
    if not Settings.FlyEnabled then return end
    if not States.FlyBodyVelocity or not States.FlyBodyGyro then
        StartFly()
    end
    
    local direction = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    
    if direction.Magnitude > 0 then
        direction = direction.Unit * Settings.FlySpeed
    end
    
    States.FlyBodyVelocity.Velocity = direction
    States.FlyBodyGyro.CFrame = Camera.CFrame
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE MODIFICAÇÃO DE ARMAS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ModifyWeapons()
    if not Char then return end
    
    for _, tool in pairs(Char:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function()
                local gunStates = require(tool:FindFirstChild("GunStates", true))
                if gunStates then
                    if Settings.InfiniteAmmoEnabled then
                        gunStates["MaxAmmo"] = math.huge
                        gunStates["CurrentAmmo"] = math.huge
                        gunStates["StoredAmmo"] = math.huge
                    end
                    if Settings.NoSpreadEnabled then
                        gunStates["Spread"] = 0
                    end
                    if Settings.RapidFireEnabled then
                        gunStates["FireRate"] = 0.01
                    end
                    if Settings.InstantReloadEnabled then
                        gunStates["ReloadTime"] = 0
                    end
                    if Settings.WallbangEnabled then
                        gunStates["Range"] = math.huge
                    end
                    if Settings.DamageMultiplier > 1 then
                        gunStates["Damage"] = (gunStates["Damage"] or 10) * Settings.DamageMultiplier
                    end
                end
            end)
        end
    end
    
    -- Também modificar armas no Backpack
    for _, tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function()
                local gunStates = require(tool:FindFirstChild("GunStates", true))
                if gunStates then
                    if Settings.InfiniteAmmoEnabled then
                        gunStates["MaxAmmo"] = math.huge
                        gunStates["CurrentAmmo"] = math.huge
                        gunStates["StoredAmmo"] = math.huge
                    end
                    if Settings.NoSpreadEnabled then
                        gunStates["Spread"] = 0
                    end
                    if Settings.RapidFireEnabled then
                        gunStates["FireRate"] = 0.01
                    end
                    if Settings.InstantReloadEnabled then
                        gunStates["ReloadTime"] = 0
                    end
                    if Settings.WallbangEnabled then
                        gunStates["Range"] = math.huge
                    end
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE KILL ALL
-- ═══════════════════════════════════════════════════════════════════════════════

local function KillAll()
    local meleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
    if not meleeEvent then
        warn("meleeEvent não encontrado!")
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            spawn(function()
                for i = 1, 30 do
                    pcall(function()
                        meleeEvent:FireServer(player)
                    end)
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE ARREST ALL
-- ═══════════════════════════════════════════════════════════════════════════════

local function ArrestAll()
    if LP.Team and LP.Team.Name ~= "Guards" then
        warn("Você precisa ser Guarda para prender!")
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Team and player.Team.Name == "Criminals" then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                spawn(function()
                    -- Teleportar para o criminoso
                    local originalPos = HRP.CFrame
                    HRP.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                    wait(0.3)
                    
                    -- Tentar prender
                    pcall(function()
                        local arrestEvent = ReplicatedStorage:FindFirstChild("arrestEvent")
                        if arrestEvent then
                            arrestEvent:FireServer(player)
                        end
                    end)
                    
                    wait(0.2)
                    HRP.CFrame = originalPos
                end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE GIVE GUNS
-- ═══════════════════════════════════════════════════════════════════════════════

local function GiveGun(gunName)
    pcall(function()
        local give = Workspace["Prison_ITEMS"].giver[gunName].ITEMPICKUP
        local event = Workspace.Remote.ItemHandler
        event:InvokeServer(give)
    end)
end

local function GiveAllGuns()
    local guns = {"M9", "Remington 870", "AK-47", "M4A1"}
    for _, gun in pairs(guns) do
        GiveGun(gun)
        wait(0.3)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE TELEPORT
-- ═══════════════════════════════════════════════════════════════════════════════

local Locations = {
    ["Criminal Base"] = CFrame.new(-920, 95, 2138),
    ["Police Base"] = CFrame.new(835, 98, 2374),
    ["Gun Store"] = CFrame.new(1078, 98, 2227),
    ["Yard"] = CFrame.new(919, 98, 2449),
    ["Prison"] = CFrame.new(917, 98, 2376),
    ["Parking Lot"] = CFrame.new(765, 98, 2507),
    ["Tower"] = CFrame.new(775, 130, 2293),
    ["Helicopter"] = CFrame.new(1050, 140, 2350),
}

local function TeleportTo(location)
    if Locations[location] and HRP then
        HRP.CFrame = Locations[location]
    end
end

local function TeleportToPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        HRP.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE REMOVE DOORS
-- ═══════════════════════════════════════════════════════════════════════════════

local function RemoveDoors()
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence") then
                if obj:IsA("BasePart") then
                    obj:Destroy()
                elseif obj:IsA("Model") then
                    obj:Destroy()
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CLICK TP
-- ═══════════════════════════════════════════════════════════════════════════════

Mouse.Button1Down:Connect(function()
    if Settings.ClickTPEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        if Mouse.Target and HRP then
            HRP.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
    
    if Settings.CtrlClickKillEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if Mouse.Target then
            local player = Players:GetPlayerFromCharacter(Mouse.Target.Parent)
            if player and player ~= LP then
                local meleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
                if meleeEvent then
                    for i = 1, 30 do
                        pcall(function()
                            meleeEvent:FireServer(player)
                        end)
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE INFINITE JUMP
-- ═══════════════════════════════════════════════════════════════════════════════

UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJumpEnabled and Hum then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════════════════════

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Theme.Primary
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.NumSides = 64

local function UpdateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Settings.AimbotFOV
    FOVCircle.Visible = Settings.AimbotEnabled or Settings.SilentAimEnabled
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Aimbot
        if Settings.AimbotEnabled and UserInputService:IsKeyDown(Settings.AimbotKey) then
            Aimbot()
        end
        
        -- Triggerbot
        Triggerbot()
        
        -- ESP
        UpdateESP()
        
        -- Chams
        UpdateChams()
        
        -- God Mode
        GodMode()
        
        -- Noclip
        Noclip()
        
        -- Fly
        if Settings.FlyEnabled then
            UpdateFly()
        elseif States.FlyBodyVelocity then
            StopFly()
        end
        
        -- Speed
        if Settings.SpeedEnabled and Hum then
            Hum.WalkSpeed = Settings.SpeedValue
        end
        
        -- Jump Power
        if Settings.JumpPowerEnabled and Hum then
            Hum.JumpPower = Settings.JumpPowerValue
        end
        
        -- Modificar armas
        ModifyWeapons()
        
        -- FOV Circle
        UpdateFOVCircle()
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUI - INTERFACE PROFISSIONAL
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateGUI()
    -- Remover GUI antiga se existir
    local oldGui = LP.PlayerGui:FindFirstChild("PrisonLifeModMenu")
    if oldGui then oldGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PrisonLifeModMenu"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LP.PlayerGui
    
    -- Container Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Primary
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    -- Efeito de gradiente na borda
    spawn(function()
        local hue = 0
        while MainStroke and MainStroke.Parent do
            hue = (hue + 0.005) % 1
            MainStroke.Color = Color3.fromHSV(hue, 0.8, 1)
            wait(0.03)
        end
    end)
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Theme.BackgroundLight
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    -- Fix para cantos do header
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 15)
    HeaderFix.Position = UDim2.new(0, 0, 1, -15)
    HeaderFix.BackgroundColor3 = Theme.BackgroundLight
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 300, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔫 PRISON LIFE MOD MENU"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Botão de fechar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = Theme.Error
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Header
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Botão de minimizar
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -15)
    MinBtn.BackgroundColor3 = Theme.Warning
    MinBtn.Text = "─"
    MinBtn.TextColor3 = Theme.Background
    MinBtn.TextSize = 16
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = Header
    
    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 6)
    MinBtnCorner.Parent = MinBtn
    
    -- Tabs Container
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.new(0, 100, 1, -50)
    TabsContainer.Position = UDim2.new(0, 0, 0, 50)
    TabsContainer.BackgroundColor3 = Theme.BackgroundLight
    TabsContainer.BorderSizePixel = 0
    TabsContainer.Parent = MainFrame
    
    local TabsList = Instance.new("UIListLayout")
    TabsList.SortOrder = Enum.SortOrder.LayoutOrder
    TabsList.Padding = UDim.new(0, 5)
    TabsList.Parent = TabsContainer
    
    local TabsPadding = Instance.new("UIPadding")
    TabsPadding.PaddingTop = UDim.new(0, 10)
    TabsPadding.PaddingLeft = UDim.new(0, 5)
    TabsPadding.PaddingRight = UDim.new(0, 5)
    TabsPadding.Parent = TabsContainer
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -105, 1, -55)
    ContentContainer.Position = UDim2.new(0, 105, 0, 55)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame
    
    -- Função para criar tabs
    local Tabs = {}
    local CurrentTab = nil
    
    local function CreateTab(name, icon)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Size = UDim2.new(1, 0, 0, 35)
        TabBtn.BackgroundColor3 = Theme.Background
        TabBtn.Text = icon .. " " .. name
        TabBtn.TextColor3 = Theme.TextDim
        TabBtn.TextSize = 12
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.Parent = TabsContainer
        
        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabBtn
        
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Theme.Primary
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 8)
        ContentList.Parent = TabContent
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.Parent = TabContent
        
        Tabs[name] = {
            Button = TabBtn,
            Content = TabContent
        }
        
        TabBtn.MouseButton1Click:Connect(function()
            if CurrentTab then
                Tabs[CurrentTab].Button.BackgroundColor3 = Theme.Background
                Tabs[CurrentTab].Button.TextColor3 = Theme.TextDim
                Tabs[CurrentTab].Content.Visible = false
            end
            
            CurrentTab = name
            TabBtn.BackgroundColor3 = Theme.Primary
            TabBtn.TextColor3 = Theme.Text
            TabContent.Visible = true
        end)
        
        -- Efeito hover
        TabBtn.MouseEnter:Connect(function()
            if CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Secondary}):Play()
            end
        end)
        
        TabBtn.MouseLeave:Connect(function()
            if CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
            end
        end)
        
        return TabContent
    end
    
    -- Função para criar toggle
    local function CreateToggle(parent, text, setting, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
        ToggleFrame.BackgroundColor3 = Theme.BackgroundLight
        ToggleFrame.Parent = parent
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 6)
        ToggleCorner.Parent = ToggleFrame
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = text
        ToggleLabel.TextColor3 = Theme.Text
        ToggleLabel.TextSize = 13
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ToggleFrame
        
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 45, 0, 22)
        ToggleBtn.Position = UDim2.new(1, -55, 0.5, -11)
        ToggleBtn.BackgroundColor3 = Settings[setting] and Theme.Success or Theme.Error
        ToggleBtn.Text = ""
        ToggleBtn.Parent = ToggleFrame
        
        local ToggleBtnCorner = Instance.new("UICorner")
        ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
        ToggleBtnCorner.Parent = ToggleBtn
        
        local ToggleCircle = Instance.new("Frame")
        ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
        ToggleCircle.Position = Settings[setting] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        ToggleCircle.BackgroundColor3 = Theme.Text
        ToggleCircle.Parent = ToggleBtn
        
        local ToggleCircleCorner = Instance.new("UICorner")
        ToggleCircleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCircleCorner.Parent = ToggleCircle
        
        ToggleBtn.MouseButton1Click:Connect(function()
            Settings[setting] = not Settings[setting]
            
            local targetPos = Settings[setting] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            local targetColor = Settings[setting] and Theme.Success or Theme.Error
            
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
            
            if callback then callback(Settings[setting]) end
        end)
        
        return ToggleFrame
    end
    
    -- Função para criar slider
    local function CreateSlider(parent, text, setting, min, max, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 50)
        SliderFrame.BackgroundColor3 = Theme.BackgroundLight
        SliderFrame.Parent = parent
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 6)
        SliderCorner.Parent = SliderFrame
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Size = UDim2.new(1, -60, 0, 20)
        SliderLabel.Position = UDim2.new(0, 10, 0, 5)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = text
        SliderLabel.TextColor3 = Theme.Text
        SliderLabel.TextSize = 13
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        SliderLabel.Parent = SliderFrame
        
        local SliderValue = Instance.new("TextLabel")
        SliderValue.Size = UDim2.new(0, 50, 0, 20)
        SliderValue.Position = UDim2.new(1, -55, 0, 5)
        SliderValue.BackgroundTransparency = 1
        SliderValue.Text = tostring(Settings[setting])
        SliderValue.TextColor3 = Theme.Primary
        SliderValue.TextSize = 13
        SliderValue.Font = Enum.Font.GothamBold
        SliderValue.Parent = SliderFrame
        
        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, -20, 0, 8)
        SliderBG.Position = UDim2.new(0, 10, 0, 32)
        SliderBG.BackgroundColor3 = Theme.Background
        SliderBG.Parent = SliderFrame
        
        local SliderBGCorner = Instance.new("UICorner")
        SliderBGCorner.CornerRadius = UDim.new(1, 0)
        SliderBGCorner.Parent = SliderBG
        
        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((Settings[setting] - min) / (max - min), 0, 1, 0)
        SliderFill.BackgroundColor3 = Theme.Primary
        SliderFill.Parent = SliderBG
        
        local SliderFillCorner = Instance.new("UICorner")
        SliderFillCorner.CornerRadius = UDim.new(1, 0)
        SliderFillCorner.Parent = SliderFill
        
        local SliderKnob = Instance.new("Frame")
        SliderKnob.Size = UDim2.new(0, 16, 0, 16)
        SliderKnob.Position = UDim2.new((Settings[setting] - min) / (max - min), -8, 0.5, -8)
        SliderKnob.BackgroundColor3 = Theme.Text
        SliderKnob.Parent = SliderBG
        
        local SliderKnobCorner = Instance.new("UICorner")
        SliderKnobCorner.CornerRadius = UDim.new(1, 0)
        SliderKnobCorner.Parent = SliderKnob
        
        local dragging = false
        
        SliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        
        SliderBG.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                
                Settings[setting] = value
                SliderValue.Text = tostring(value)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                SliderKnob.Position = UDim2.new(pos, -8, 0.5, -8)
                
                if callback then callback(value) end
            end
        end)
        
        return SliderFrame
    end
    
    -- Função para criar botão
    local function CreateButton(parent, text, callback)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 35)
        Button.BackgroundColor3 = Theme.Primary
        Button.Text = text
        Button.TextColor3 = Theme.Text
        Button.TextSize = 14
        Button.Font = Enum.Font.GothamBold
        Button.Parent = parent
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = Button
        
        Button.MouseButton1Click:Connect(function()
            -- Efeito de clique
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
            wait(0.1)
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Primary}):Play()
            
            if callback then callback() end
        end)
        
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Secondary}):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Primary}):Play()
        end)
        
        return Button
    end
    
    -- Criar Tabs
    local CombatTab = CreateTab("Combat", "🎯")
    local ESPTab = CreateTab("ESP", "👁️")
    local PlayerTab = CreateTab("Player", "🏃")
    local WeaponsTab = CreateTab("Weapons", "🔫")
    local ActionsTab = CreateTab("Actions", "⚡")
    local TeleportTab = CreateTab("Teleport", "📍")
    
    -- Selecionar primeira tab
    Tabs["Combat"].Button.BackgroundColor3 = Theme.Primary
    Tabs["Combat"].Button.TextColor3 = Theme.Text
    Tabs["Combat"].Content.Visible = true
    CurrentTab = "Combat"
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DAS TABS
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Combat Tab
    CreateToggle(CombatTab, "Aimbot (Hold E)", "AimbotEnabled")
    CreateSlider(CombatTab, "Aimbot FOV", "AimbotFOV", 50, 500)
    CreateSlider(CombatTab, "Aimbot Smooth", "AimbotSmooth", 0.1, 1)
    CreateToggle(CombatTab, "Silent Aim", "SilentAimEnabled")
    CreateSlider(CombatTab, "Silent Aim FOV", "SilentAimFOV", 50, 500)
    CreateToggle(CombatTab, "Triggerbot", "TriggerbotEnabled")
    CreateToggle(CombatTab, "Team Check", "AimbotTeamCheck")
    CreateToggle(CombatTab, "Visible Check", "AimbotVisibleCheck")
    
    -- ESP Tab
    CreateToggle(CombatTab, "ESP Enabled", "ESPEnabled")
    CreateToggle(ESPTab, "ESP Boxes", "ESPBoxes")
    CreateToggle(ESPTab, "ESP Names", "ESPNames")
    CreateToggle(ESPTab, "ESP Distance", "ESPDistance")
    CreateToggle(ESPTab, "ESP Health Bars", "ESPHealthBars")
    CreateToggle(ESPTab, "ESP Team Check", "ESPTeamCheck")
    CreateToggle(ESPTab, "Chams", "ESPChams")
    CreateToggle(ESPTab, "Rainbow Chams", "ESPRainbowChams")
    
    -- Player Tab
    CreateToggle(PlayerTab, "God Mode", "GodModeEnabled")
    CreateToggle(PlayerTab, "Noclip", "NoclipEnabled")
    CreateToggle(PlayerTab, "Fly (WASD + Space/Ctrl)", "FlyEnabled", function(enabled)
        if not enabled then StopFly() end
    end)
    CreateSlider(PlayerTab, "Fly Speed", "FlySpeed", 10, 200)
    CreateToggle(PlayerTab, "Speed Hack", "SpeedEnabled")
    CreateSlider(PlayerTab, "Speed Value", "SpeedValue", 16, 200)
    CreateToggle(PlayerTab, "Jump Power", "JumpPowerEnabled")
    CreateSlider(PlayerTab, "Jump Value", "JumpPowerValue", 50, 500)
    CreateToggle(PlayerTab, "Infinite Jump", "InfiniteJumpEnabled")
    
    -- Weapons Tab
    CreateToggle(WeaponsTab, "Infinite Ammo", "InfiniteAmmoEnabled")
    CreateToggle(WeaponsTab, "No Spread", "NoSpreadEnabled")
    CreateToggle(WeaponsTab, "Rapid Fire", "RapidFireEnabled")
    CreateToggle(WeaponsTab, "Instant Reload", "InstantReloadEnabled")
    CreateToggle(WeaponsTab, "Wallbang (Infinite Range)", "WallbangEnabled")
    CreateSlider(WeaponsTab, "Damage Multiplier", "DamageMultiplier", 1, 100)
    CreateButton(WeaponsTab, "🔫 Give All Guns", GiveAllGuns)
    CreateButton(WeaponsTab, "🔫 Give M9", function() GiveGun("M9") end)
    CreateButton(WeaponsTab, "🔫 Give AK-47", function() GiveGun("AK-47") end)
    CreateButton(WeaponsTab, "🔫 Give M4A1", function() GiveGun("M4A1") end)
    CreateButton(WeaponsTab, "🔫 Give Remington", function() GiveGun("Remington 870") end)
    
    -- Actions Tab
    CreateButton(ActionsTab, "☠️ Kill All", KillAll)
    CreateButton(ActionsTab, "🚔 Arrest All", ArrestAll)
    CreateButton(ActionsTab, "🚪 Remove All Doors", RemoveDoors)
    CreateToggle(ActionsTab, "Click TP (Shift + Click)", "ClickTPEnabled")
    CreateToggle(ActionsTab, "Ctrl + Click Kill", "CtrlClickKillEnabled")
    CreateToggle(ActionsTab, "Anti Arrest", "AntiArrestEnabled")
    CreateToggle(ActionsTab, "Auto Arrest", "AutoArrestEnabled")
    
    -- Teleport Tab
    for location, _ in pairs(Locations) do
        CreateButton(TeleportTab, "📍 " .. location, function() TeleportTo(location) end)
    end
    
    -- Adicionar botões de teleport para jogadores
    local function UpdatePlayerTeleports()
        -- Limpar botões antigos de jogadores
        for _, child in pairs(TeleportTab:GetChildren()) do
            if child.Name:find("PlayerTP_") then
                child:Destroy()
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local btn = CreateButton(TeleportTab, "👤 " .. player.Name, function()
                    TeleportToPlayer(player.Name)
                end)
                btn.Name = "PlayerTP_" .. player.Name
            end
        end
    end
    
    UpdatePlayerTeleports()
    Players.PlayerAdded:Connect(UpdatePlayerTeleports)
    Players.PlayerRemoving:Connect(UpdatePlayerTeleports)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- FUNCIONALIDADES DA GUI
    -- ═══════════════════════════════════════════════════════════════════════════
    
    -- Drag
    local dragging = false
    local dragStart, startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Fechar
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Minimizar
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 500, 0, 50)}):Play()
            MinBtn.Text = "+"
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 500, 0, 400)}):Play()
            MinBtn.Text = "─"
        end
    end)
    
    -- Toggle Button (para mobile)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
    ToggleBtn.BackgroundColor3 = Theme.Primary
    ToggleBtn.Text = "🔫"
    ToggleBtn.TextSize = 24
    ToggleBtn.Parent = ScreenGui
    
    local ToggleBtnCorner = Instance.new("UICorner")
    ToggleBtnCorner.CornerRadius = UDim.new(0, 10)
    ToggleBtnCorner.Parent = ToggleBtn
    
    local guiVisible = true
    ToggleBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end)
    
    -- Animação de entrada
    MainFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -250, 0.5, -200)}):Play()
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════════════

print([[
╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
║                         PRISON LIFE MOD MENU - ULTIMATE EDITION                                  ║
║                                                                                                  ║
║  🎯 Combat: Aimbot, Silent Aim, Triggerbot                                                      ║
║  👁️ ESP: Boxes, Names, Distance, Health Bars, Chams                                             ║
║  🏃 Player: God Mode, Noclip, Fly, Speed, Jump                                                  ║
║  🔫 Weapons: Infinite Ammo, No Spread, Rapid Fire, Wallbang                                     ║
║  ⚡ Actions: Kill All, Arrest All, Remove Doors                                                  ║
║  📍 Teleport: Locations + Players                                                                ║
║                                                                                                  ║
║  Pressione INSERT ou clique no botão 🔫 para toggle                                             ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════╝
]])

-- Inicializar ESP
InitESP()

-- Criar GUI
CreateGUI()

-- Toggle GUI com INSERT
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        local gui = LP.PlayerGui:FindFirstChild("PrisonLifeModMenu")
        if gui then
            local mainFrame = gui:FindFirstChild("MainFrame")
            if mainFrame then
                mainFrame.Visible = not mainFrame.Visible
            end
        end
    end
end)

-- Notificação
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🔫 Prison Life Mod Menu",
        Text = "Carregado com sucesso! INSERT para toggle",
        Duration = 5
    })
end)
