--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                                   ║
    ║     ███████╗ █████╗ ██╗   ██╗ █████╗  ██████╗ ███████╗ ██████╗██╗  ██╗███████╗ █████╗ ████████╗   ║
    ║     ██╔════╝██╔══██╗██║   ██║██╔══██╗██╔════╝ ██╔════╝██╔════╝██║  ██║██╔════╝██╔══██╗╚══██╔══╝   ║
    ║     ███████╗███████║██║   ██║███████║██║  ███╗█████╗  ██║     ███████║█████╗  ███████║   ██║      ║
    ║     ╚════██║██╔══██║╚██╗ ██╔╝██╔══██║██║   ██║██╔══╝  ██║     ██╔══██║██╔══╝  ██╔══██║   ██║      ║
    ║     ███████║██║  ██║ ╚████╔╝ ██║  ██║╚██████╔╝███████╗╚██████╗██║  ██║███████╗██║  ██║   ██║      ║
    ║     ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝      ║
    ║                                
    ║                              🎯 UNIVERSAL AIMBOT + ESP v3.0 🎯                                    ║
    ║                                                                                                   ║
    ║   • UI Estilo SAVAGECHEATS_ (Tema Vermelho/Preto)                                                 ║
    ║   • FOV Centralizado Corretamente                                                                 ║
    ║   • Sistema de Disparo Inteligente Universal                                                      ║
    ║   • Seleção de Times Inteligente                                                                  ║
    ║   • ESP Completo (Box, Name, Health, Distance, Tracer)                                            ║
    ║   • Compatível com Mobile e PC                                                                    ║
    ║                                                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝
--]]

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         LIMPEZA INICIAL
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

if getgenv and getgenv().SAVAGECHEATS_Loaded then
    pcall(function() getgenv().SAVAGECHEATS_Instance:Destroy() end)
    getgenv().SAVAGECHEATS_Loaded = nil
    getgenv().SAVAGECHEATS_Instance = nil
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                            SERVIÇOS
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Atalhos
local V2 = Vector2.new
local V3 = Vector3.new
local CF = CFrame.new
local C3 = Color3.fromRGB
local UD2 = UDim2.new
local UDim_new = UDim.new

-- Verificações de ambiente
local HasDrawing = pcall(function() return Drawing.new end)
local HasVIM = pcall(function() return VirtualInputManager.SendMouseButtonEvent end)
local HasFireTouch = pcall(function() return firetouchinterest end)
local HasMouse1Click = pcall(function() return mouse1click end)

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         TEMA DE CORES
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

local Theme = {
    Background = C3(18, 18, 22),
    Surface = C3(28, 28, 35),
    SurfaceLight = C3(38, 38, 48),
    Primary = C3(200, 45, 45),
    PrimaryDark = C3(150, 30, 30),
    PrimaryLight = C3(255, 70, 70),
    Accent = C3(255, 85, 85),
    Text = C3(255, 255, 255),
    TextDim = C3(150, 150, 160),
    TextDark = C3(100, 100, 110),
    Border = C3(55, 55, 65),
    Success = C3(80, 200, 80),
    Warning = C3(255, 180, 50),
    Error = C3(255, 80, 80),
    CheckMark = C3(200, 45, 45),
}

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      SISTEMA PRINCIPAL
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

local SAVAGE = {
    Version = "3.0",
    
    -- Estados
    Ativo = false,
    Mirando = false,
    AlvoAtual = nil,
    ParteAlvo = nil,
    
    -- Configurações de Aimbot
    Aim = {
        Enabled = true,
        Mode = "Smooth",           -- "Lock", "Smooth", "Silent", "Assist"
        TargetPart = "Head",       -- "Head", "Torso", "Closest"
        Smoothness = 0.15,
        HeadshotChance = 100,
        
        -- Verificações
        SkipKnocked = true,
        SkipVischeck = false,
        CheckAlive = true,
        
        -- Predição
        Prediction = true,
        PredictionStrength = 0.12,
        
        -- Sticky Aim
        StickyAim = true,
        StickyTime = 0.5,
        
        -- Trigger Bot
        AutoFire = false,
        FireDelay = 0.05,
        FireMethod = "Auto",       -- "Auto", "Mouse1Click", "VIM", "FireTouch"
    },
    
    -- Configurações de FOV
    FOV = {
        Enabled = true,
        ShowCircle = true,
        Radius = 150,
        Sides = 64,
        Thickness = 1.5,
        ColorNormal = C3(255, 255, 255),
        ColorLocked = C3(255, 80, 80),
        Filled = false,
    },
    
    -- Configurações de Time
    Team = {
        Mode = "Enemy",            -- "Enemy", "All", "SelectTeam"
        SelectedTeam = nil,
        AvailableTeams = {},
    },
    
    -- Configurações de ESP
    ESP = {
        Enabled = false,
        Box = true,
        BoxType = "Corner",        -- "Full", "Corner"
        Name = true,
        Health = true,
        Distance = true,
        Tracer = false,
        TracerOrigin = "Bottom",   -- "Bottom", "Center", "Mouse"
        
        -- Cores
        BoxColor = C3(255, 85, 85),
        NameColor = C3(255, 255, 255),
        HealthHigh = C3(80, 255, 80),
        HealthMid = C3(255, 255, 80),
        HealthLow = C3(255, 80, 80),
        TracerColor = C3(255, 85, 85),
        
        -- Distância máxima
        MaxDistance = 1000,
    },
    
    -- Internos
    _connections = {},
    _drawings = {},
    _espCache = {},
    _ui = nil,
    _lastLock = 0,
    _triggerReady = true,
    _currentTab = "Aim",
}

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                    FUNÇÕES UTILITÁRIAS
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

-- Centro da tela CORRIGIDO para mobile
local function GetScreenCenter()
    local viewport = Camera.ViewportSize
    local guiInset = GuiService:GetGuiInset()
    -- Correção: O centro real da tela considerando o inset
    return V2(viewport.X / 2, (viewport.Y / 2) - guiInset.Y / 2)
end

-- Conversão World to Screen
local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return V2(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Distância 2D
local function Distance2D(a, b)
    return (a - b).Magnitude
end

-- Distância 3D
local function Distance3D(a, b)
    return (a - b).Magnitude
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                   DETECÇÃO DE PERSONAGEM
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

local function GetHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid") or character:FindFirstChild("Humanoid")
end

local function GetRootPart(character)
    if not character then return nil end
    local names = {"HumanoidRootPart", "Torso", "UpperTorso", "Head", "LowerTorso"}
    for _, name in ipairs(names) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    -- Fallback: qualquer BasePart
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function GetTargetPart(character, targetType)
    if not character then return nil end
    
    local partMap = {
        ["Head"] = {"Head"},
        ["Torso"] = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
        ["Closest"] = nil,
    }
    
    if targetType == "Closest" then
        local center = GetScreenCenter()
        local bestPart, bestDist = nil, math.huge
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local screen, onScreen = WorldToScreen(part.Position)
                if onScreen then
                    local dist = Distance2D(center, screen)
                    if dist < bestDist then
                        bestDist = dist
                        bestPart = part
                    end
                end
            end
        end
        return bestPart or GetRootPart(character)
    end
    
    local partNames = partMap[targetType] or {"Head", "HumanoidRootPart"}
    for _, name in ipairs(partNames) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return GetRootPart(character)
end

local function IsAlive(character)
    local humanoid = GetHumanoid(character)
    if not humanoid then return false end
    return humanoid.Health > 0
end

-- Detectar se está "knocked" (caído/downed)
local function IsKnocked(character)
    if not character then return false end
    
    local humanoid = GetHumanoid(character)
    if not humanoid then return false end
    
    -- Verificar estados comuns de knocked
    -- 1. Humanoid State
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Dead or 
       state == Enum.HumanoidStateType.Physics or
       state == Enum.HumanoidStateType.FallingDown or
       state == Enum.HumanoidStateType.Ragdoll then
        return true
    end
    
    -- 2. Verificar atributos comuns
    local knockedAttributes = {"Knocked", "Downed", "DBNO", "IsKnocked", "IsDowned", "Incapacitated"}
    for _, attr in ipairs(knockedAttributes) do
        local value = character:GetAttribute(attr)
        if value == true then return true end
    end
    
    -- 3. Verificar valores em humanoid
    for _, attr in ipairs(knockedAttributes) do
        local value = humanoid:GetAttribute(attr)
        if value == true then return true end
    end
    
    -- 4. Verificar BoolValues comuns
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BoolValue") then
            local lowerName = child.Name:lower()
            if lowerName:find("knock") or lowerName:find("down") or lowerName:find("dbno") then
                if child.Value == true then return true end
            end
        end
    end
    
    -- 5. Verificar WalkSpeed muito baixo (comum em knocked)
    if humanoid.WalkSpeed <= 0 and humanoid.Health > 0 then
        -- Pode estar knocked
        local rootPart = GetRootPart(character)
        if rootPart then
            -- Se está deitado (Y rotation muito diferente)
            local _, _, z = rootPart.CFrame:ToEulerAnglesXYZ()
            if math.abs(z) > math.rad(45) then
                return true
            end
        end
    end
    
    return false
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                   SISTEMA DE TIMES INTELIGENTE
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:UpdateAvailableTeams()
    self.Team.AvailableTeams = {}
    
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(self.Team.AvailableTeams, {
            Name = team.Name,
            Color = team.TeamColor,
            Instance = team,
        })
    end
    
    return self.Team.AvailableTeams
end

function SAVAGE:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    
    local mode = self.Team.Mode
    
    if mode == "All" then
        return true
    elseif mode == "Enemy" then
        -- Verificar time
        if LocalPlayer.Team and player.Team then
            return LocalPlayer.Team ~= player.Team
        end
        -- Verificar TeamColor
        if LocalPlayer.TeamColor and player.TeamColor then
            return LocalPlayer.TeamColor ~= player.TeamColor
        end
        -- Verificar atributos de time
        local myTeam = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("team")
        local theirTeam = player:GetAttribute("Team") or player:GetAttribute("team")
        if myTeam and theirTeam then
            return myTeam ~= theirTeam
        end
        -- Se não tem sistema de times, considerar inimigo
        return true
    elseif mode == "SelectTeam" then
        if self.Team.SelectedTeam then
            if player.Team then
                return player.Team.Name == self.Team.SelectedTeam
            end
            if player.TeamColor then
                return player.TeamColor.Name == self.Team.SelectedTeam
            end
        end
        return false
    end
    
    return true
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      VERIFICAÇÃO DE VISÃO
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:CanSee(part, character)
    if not part or not character then return false end
    if self.Aim.SkipVischeck then return true end
    
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {myChar, Camera}
    
    local result = Workspace:Raycast(origin, direction, params)
    
    if result then
        return result.Instance:IsDescendantOf(character)
    end
    return true
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      VERIFICAÇÃO DE ALVO
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:CanTarget(player, character)
    if not player or not character then return false end
    if player == LocalPlayer then return false end
    
    -- Verificar se está vivo
    if self.Aim.CheckAlive and not IsAlive(character) then
        return false
    end
    
    -- Verificar se está knocked
    if self.Aim.SkipKnocked and IsKnocked(character) then
        return false
    end
    
    -- Verificar time
    if not self:IsEnemy(player) then
        return false
    end
    
    return true
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         PREDIÇÃO
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:PredictPosition(character, part)
    if not self.Aim.Prediction then
        return part.Position
    end
    
    local humanoid = GetHumanoid(character)
    local rootPart = GetRootPart(character)
    
    if not humanoid or not rootPart then
        return part.Position
    end
    
    local velocity = rootPart.AssemblyLinearVelocity
    
    -- Se velocidade muito baixa, usar MoveDirection
    if velocity.Magnitude < 1 then
        velocity = humanoid.MoveDirection * (humanoid.WalkSpeed or 16)
    end
    
    local prediction = velocity * self.Aim.PredictionStrength
    return part.Position + prediction
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      ENCONTRAR ALVO
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:FindTarget()
    local center = GetScreenCenter()
    local radius = self.FOV.Radius
    
    -- Sticky Aim - manter alvo
    if self.Aim.StickyAim and self.AlvoAtual then
        local elapsed = tick() - self._lastLock
        if elapsed < self.Aim.StickyTime then
            local char = self.AlvoAtual.Character
            if char and IsAlive(char) then
                local part = GetTargetPart(char, self.Aim.TargetPart)
                if part then
                    local screen, onScreen = WorldToScreen(part.Position)
                    if onScreen and Distance2D(center, screen) < radius * 2 then
                        return self.AlvoAtual, part
                    end
                end
            end
        end
    end
    
    local bestTarget, bestPart = nil, nil
    local bestDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        
        if character and self:CanTarget(player, character) then
            local part = GetTargetPart(character, self.Aim.TargetPart)
            
            if part then
                local screen, onScreen = WorldToScreen(part.Position)
                
                if onScreen then
                    local dist = Distance2D(center, screen)
                    
                    if dist <= radius then
                        if self:CanSee(part, character) then
                            if dist < bestDist then
                                bestDist = dist
                                bestTarget = player
                                bestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget, bestPart
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      SISTEMA DE MIRA
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:AimAt(position)
    if not position then return end
    
    local mode = self.Aim.Mode
    
    -- Headshot chance
    if self.Aim.HeadshotChance < 100 then
        if math.random(1, 100) > self.Aim.HeadshotChance then
            -- Mirar no corpo ao invés da cabeça
            if self.AlvoAtual and self.AlvoAtual.Character then
                local torso = self.AlvoAtual.Character:FindFirstChild("HumanoidRootPart") or
                              self.AlvoAtual.Character:FindFirstChild("Torso") or
                              self.AlvoAtual.Character:FindFirstChild("UpperTorso")
                if torso then
                    position = torso.Position
                end
            end
        end
    end
    
    if mode == "Lock" then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, position)
        
    elseif mode == "Smooth" then
        local current = Camera.CFrame
        local target = CFrame.lookAt(current.Position, position)
        Camera.CFrame = current:Lerp(target, 1 - self.Aim.Smoothness)
        
    elseif mode == "Assist" then
        local current = Camera.CFrame
        local target = CFrame.lookAt(current.Position, position)
        Camera.CFrame = current:Lerp(target, 0.05)
        
    elseif mode == "Silent" then
        -- Silent aim não move a câmera (requer hook de raycast)
        -- Apenas armazena a posição alvo
        self._silentTarget = position
    end
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                               SISTEMA DE DISPARO INTELIGENTE
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:SmartFire()
    if not self.Aim.AutoFire then return end
    if not self._triggerReady then return end
    if not self.ParteAlvo then return end
    
    local center = GetScreenCenter()
    local screen, onScreen = WorldToScreen(self.ParteAlvo.Position)
    
    if not onScreen then return end
    
    -- Verificar se está perto o suficiente do centro
    if Distance2D(center, screen) < 30 then
        self._triggerReady = false
        
        task.delay(self.Aim.FireDelay, function()
            local method = self.Aim.FireMethod
            local success = false
            
            -- Auto: tenta todos os métodos até um funcionar
            if method == "Auto" then
                -- Método 1: mouse1click (mais comum)
                if HasMouse1Click then
                    success = pcall(function()
                        mouse1click()
                    end)
                end
                
                -- Método 2: VirtualInputManager
                if not success and HasVIM then
                    success = pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, true, game, 1)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, false, game, 1)
                    end)
                end
                
                -- Método 3: firetouchinterest (mobile)
                if not success and HasFireTouch then
                    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if gui then
                        local touchGui = gui:FindFirstChild("TouchGui") or gui:FindFirstChildWhichIsA("ScreenGui")
                        if touchGui then
                            success = pcall(function()
                                firetouchinterest(touchGui, V2(screen.X, screen.Y), 0)
                                task.wait(0.01)
                                firetouchinterest(touchGui, V2(screen.X, screen.Y), 1)
                            end)
                        end
                    end
                end
                
                -- Método 4: Simular clique via UserInputService
                if not success then
                    pcall(function()
                        -- Tentar encontrar botão de tiro
                        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                        if playerGui then
                            for _, gui in ipairs(playerGui:GetDescendants()) do
                                if gui:IsA("GuiButton") then
                                    local name = gui.Name:lower()
                                    if name:find("shoot") or name:find("fire") or name:find("attack") then
                                        pcall(function()
                                            gui:Activate()
                                        end)
                                        success = true
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
                
            elseif method == "Mouse1Click" and HasMouse1Click then
                pcall(function() mouse1click() end)
                
            elseif method == "VIM" and HasVIM then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(screen.X, screen.Y, 0, false, game, 1)
                end)
                
            elseif method == "FireTouch" and HasFireTouch then
                pcall(function()
                    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if gui then
                        local touchGui = gui:FindFirstChild("TouchGui")
                        if touchGui then
                            firetouchinterest(touchGui, V2(screen.X, screen.Y), 0)
                            task.wait(0.01)
                            firetouchinterest(touchGui, V2(screen.X, screen.Y), 1)
                        end
                    end
                end)
            end
            
            task.wait(0.05)
            self._triggerReady = true
        end)
    end
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      CÍRCULO FOV
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:CreateFOVCircle()
    if not HasDrawing then return end
    
    self._drawings.fov = Drawing.new("Circle")
    self._drawings.fov.Visible = false
    self._drawings.fov.Filled = self.FOV.Filled
    self._drawings.fov.Thickness = self.FOV.Thickness
    self._drawings.fov.Transparency = 1
    self._drawings.fov.Color = self.FOV.ColorNormal
    self._drawings.fov.NumSides = self.FOV.Sides
    self._drawings.fov.Radius = self.FOV.Radius
end

function SAVAGE:UpdateFOVCircle()
    if not self._drawings.fov then return end
    
    -- Posição centralizada CORRETA
    local center = GetScreenCenter()
    self._drawings.fov.Position = center
    self._drawings.fov.Radius = self.FOV.Radius
    self._drawings.fov.NumSides = self.FOV.Sides
    self._drawings.fov.Thickness = self.FOV.Thickness
    self._drawings.fov.Filled = self.FOV.Filled
    
    -- Cor baseada no estado
    if self.AlvoAtual then
        self._drawings.fov.Color = self.FOV.ColorLocked
    else
        self._drawings.fov.Color = self.FOV.ColorNormal
    end
    
    self._drawings.fov.Visible = self.FOV.Enabled and self.FOV.ShowCircle and self.Aim.Enabled
end

function SAVAGE:DestroyFOVCircle()
    if self._drawings.fov then
        self._drawings.fov:Remove()
        self._drawings.fov = nil
    end
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         SISTEMA ESP
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:CreateESPForPlayer(player)
    if not HasDrawing then return end
    if player == LocalPlayer then return end
    
    local esp = {
        Box = Drawing.new("Quad"),
        BoxOutline = Drawing.new("Quad"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Line"),
        HealthOutline = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
    }
    
    -- Configurar Box
    esp.Box.Visible = false
    esp.Box.Thickness = 1
    esp.Box.Color = self.ESP.BoxColor
    esp.Box.Filled = false
    
    esp.BoxOutline.Visible = false
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Color = C3(0, 0, 0)
    esp.BoxOutline.Filled = false
    
    -- Configurar Nome
    esp.Name.Visible = false
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Size = 13
    esp.Name.Font = 2
    esp.Name.Color = self.ESP.NameColor
    
    -- Configurar Health
    esp.Health.Visible = false
    esp.Health.Thickness = 2
    esp.Health.Color = self.ESP.HealthHigh
    
    esp.HealthOutline.Visible = false
    esp.HealthOutline.Thickness = 4
    esp.HealthOutline.Color = C3(0, 0, 0)
    
    -- Configurar Distance
    esp.Distance.Visible = false
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Size = 12
    esp.Distance.Font = 2
    esp.Distance.Color = self.ESP.NameColor
    
    -- Configurar Tracer
    esp.Tracer.Visible = false
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = self.ESP.TracerColor
    
    self._espCache[player] = esp
end

function SAVAGE:UpdateESPForPlayer(player)
    local esp = self._espCache[player]
    if not esp then
        self:CreateESPForPlayer(player)
        esp = self._espCache[player]
        if not esp then return end
    end
    
    local character = player.Character
    if not character or not self.ESP.Enabled then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local humanoid = GetHumanoid(character)
    local rootPart = GetRootPart(character)
    
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    -- Verificar distância
    local myChar = LocalPlayer.Character
    if not myChar then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local myRoot = GetRootPart(myChar)
    if not myRoot then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local distance = Distance3D(myRoot.Position, rootPart.Position)
    if distance > self.ESP.MaxDistance then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    -- Verificar se é inimigo
    if not self:IsEnemy(player) then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    -- Calcular bounding box
    local head = character:FindFirstChild("Head")
    if not head then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local rootPos = rootPart.Position
    local headPos = head.Position
    
    -- Calcular altura do personagem
    local topPos = headPos + V3(0, 0.5, 0)
    local bottomPos = rootPos - V3(0, 3, 0)
    
    local topScreen, topOnScreen = WorldToScreen(topPos)
    local bottomScreen, bottomOnScreen = WorldToScreen(bottomPos)
    
    if not topOnScreen and not bottomOnScreen then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local height = math.abs(bottomScreen.Y - topScreen.Y)
    local width = height * 0.6
    
    local centerX = (topScreen.X + bottomScreen.X) / 2
    local centerY = (topScreen.Y + bottomScreen.Y) / 2
    
    -- Box
    if self.ESP.Box then
        local x1 = centerX - width / 2
        local y1 = topScreen.Y
        local x2 = centerX + width / 2
        local y2 = bottomScreen.Y
        
        if self.ESP.BoxType == "Corner" then
            -- Corner box style
            local cornerSize = width * 0.25
            
            esp.BoxOutline.PointA = V2(x1, y1)
            esp.BoxOutline.PointB = V2(x2, y1)
            esp.BoxOutline.PointC = V2(x2, y2)
            esp.BoxOutline.PointD = V2(x1, y2)
            esp.BoxOutline.Visible = false -- Desabilitar outline para corner
            
            esp.Box.PointA = V2(x1, y1)
            esp.Box.PointB = V2(x2, y1)
            esp.Box.PointC = V2(x2, y2)
            esp.Box.PointD = V2(x1, y2)
        else
            esp.BoxOutline.PointA = V2(x1, y1)
            esp.BoxOutline.PointB = V2(x2, y1)
            esp.BoxOutline.PointC = V2(x2, y2)
            esp.BoxOutline.PointD = V2(x1, y2)
            esp.BoxOutline.Visible = true
            
            esp.Box.PointA = V2(x1, y1)
            esp.Box.PointB = V2(x2, y1)
            esp.Box.PointC = V2(x2, y2)
            esp.Box.PointD = V2(x1, y2)
        end
        
        esp.Box.Color = self.ESP.BoxColor
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
    end
    
    -- Nome
    if self.ESP.Name then
        esp.Name.Text = player.DisplayName or player.Name
        esp.Name.Position = V2(centerX, topScreen.Y - 15)
        esp.Name.Color = self.ESP.NameColor
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    
    -- Health
    if self.ESP.Health then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthHeight = height * healthPercent
        
        local hx = centerX - width / 2 - 5
        
        -- Cor baseada na vida
        local healthColor
        if healthPercent > 0.6 then
            healthColor = self.ESP.HealthHigh
        elseif healthPercent > 0.3 then
            healthColor = self.ESP.HealthMid
        else
            healthColor = self.ESP.HealthLow
        end
        
        esp.HealthOutline.From = V2(hx, bottomScreen.Y)
        esp.HealthOutline.To = V2(hx, topScreen.Y)
        esp.HealthOutline.Visible = true
        
        esp.Health.From = V2(hx, bottomScreen.Y)
        esp.Health.To = V2(hx, bottomScreen.Y - healthHeight)
        esp.Health.Color = healthColor
        esp.Health.Visible = true
    else
        esp.Health.Visible = false
        esp.HealthOutline.Visible = false
    end
    
    -- Distância
    if self.ESP.Distance then
        esp.Distance.Text = string.format("[%dm]", math.floor(distance))
        esp.Distance.Position = V2(centerX, bottomScreen.Y + 2)
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end
    
    -- Tracer
    if self.ESP.Tracer then
        local viewport = Camera.ViewportSize
        local fromPos
        
        if self.ESP.TracerOrigin == "Bottom" then
            fromPos = V2(viewport.X / 2, viewport.Y)
        elseif self.ESP.TracerOrigin == "Center" then
            fromPos = GetScreenCenter()
        else -- Mouse
            fromPos = UserInputService:GetMouseLocation()
        end
        
        esp.Tracer.From = fromPos
        esp.Tracer.To = V2(centerX, bottomScreen.Y)
        esp.Tracer.Color = self.ESP.TracerColor
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
end

function SAVAGE:RemoveESPForPlayer(player)
    local esp = self._espCache[player]
    if esp then
        for _, drawing in pairs(esp) do
            pcall(function() drawing:Remove() end)
        end
        self._espCache[player] = nil
    end
end

function SAVAGE:UpdateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        self:UpdateESPForPlayer(player)
    end
end

function SAVAGE:DestroyAllESP()
    for player, _ in pairs(self._espCache) do
        self:RemoveESPForPlayer(player)
    end
    self._espCache = {}
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                    INTERFACE - SAVAGECHEATS_ STYLE
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:CreateUI()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    if self._ui then self._ui:Destroy() end
    
    -- ScreenGui principal
    local gui = Instance.new("ScreenGui")
    gui.Name = "SAVAGECHEATS_UI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui
    self._ui = gui
    
    -- Container principal (draggable)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UD2(0, 320, 0, 420)
    mainFrame.Position = UD2(0.5, -160, 0.5, -210)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim_new(0, 8)
    
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UD2(1, 0, 0, 35)
    header.BackgroundColor3 = Theme.Surface
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim_new(0, 8)
    
    -- Fix corners no header (só arredondar em cima)
    local headerFix = Instance.new("Frame")
    headerFix.Size = UD2(1, 0, 0.5, 0)
    headerFix.Position = UD2(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Theme.Surface
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Botão minimizar
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UD2(0, 25, 0, 25)
    minimizeBtn.Position = UD2(0, 5, 0.5, -12)
    minimizeBtn.BackgroundColor3 = Theme.SurfaceLight
    minimizeBtn.Text = "▼"
    minimizeBtn.TextSize = 12
    minimizeBtn.TextColor3 = Theme.Text
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header
    
    local minimizeCorner = Instance.new("UICorner", minimizeBtn)
    minimizeCorner.CornerRadius = UDim_new(0, 4)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UD2(1, -70, 1, 0)
    title.Position = UD2(0, 35, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SAVAGECHEATS_"
    title.TextSize = 16
    title.TextColor3 = Theme.Text
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UD2(0, 25, 0, 25)
    closeBtn.Position = UD2(1, -30, 0.5, -12)
    closeBtn.BackgroundColor3 = Theme.Primary
    closeBtn.Text = "×"
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner", closeBtn)
    closeCorner.CornerRadius = UDim_new(0, 4)
    
    -- Container de Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UD2(1, -20, 0, 35)
    tabContainer.Position = UD2(0, 10, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim_new(0, 5)
    
    -- Criar tabs
    local tabs = {"ESP", "Aim", "Setting"}
    local tabButtons = {}
    local tabContents = {}
    
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UD2(0, 80, 1, 0)
        tabBtn.BackgroundColor3 = i == 2 and Theme.Primary or Theme.SurfaceLight
        tabBtn.Text = "👁 " .. tabName
        if tabName == "Aim" then tabBtn.Text = "🎯 " .. tabName end
        if tabName == "Setting" then tabBtn.Text = "⚙️ " .. tabName end
        tabBtn.TextSize = 12
        tabBtn.TextColor3 = Theme.Text
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner", tabBtn)
        tabCorner.CornerRadius = UDim_new(0, 6)
        
        tabButtons[tabName] = tabBtn
        
        -- Content frame para cada tab
        local content = Instance.new("ScrollingFrame")
        content.Name = tabName .. "Content"
        content.Size = UD2(1, -20, 1, -90)
        content.Position = UD2(0, 10, 0, 80)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = Theme.Primary
        content.CanvasSize = UD2(0, 0, 0, 600)
        content.Visible = tabName == "Aim"
        content.Parent = mainFrame
        
        local contentLayout = Instance.new("UIListLayout", content)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim_new(0, 8)
        
        tabContents[tabName] = content
        
        -- Tab click handler
        tabBtn.MouseButton1Click:Connect(function()
            self._currentTab = tabName
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = name == tabName and Theme.Primary or Theme.SurfaceLight
            end
            for name, cont in pairs(tabContents) do
                cont.Visible = name == tabName
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- FUNÇÕES DE CRIAÇÃO DE ELEMENTOS UI
    -- ═══════════════════════════════════════════════════════════════
    
    local function CreateCheckbox(parent, name, default, callback)
        local container = Instance.new("Frame")
        container.Size = UD2(1, 0, 0, 35)
        container.BackgroundColor3 = Theme.Surface
        container.Parent = parent
        
        local containerCorner = Instance.new("UICorner", container)
        containerCorner.CornerRadius = UDim_new(0, 6)
        
        -- Checkbox
        local checkbox = Instance.new("TextButton")
        checkbox.Size = UD2(0, 24, 0, 24)
        checkbox.Position = UD2(0, 10, 0.5, -12)
        checkbox.BackgroundColor3 = default and Theme.Primary or Theme.SurfaceLight
        checkbox.Text = default and "✓" or ""
        checkbox.TextSize = 16
        checkbox.TextColor3 = Theme.Text
        checkbox.Font = Enum.Font.GothamBold
        checkbox.Parent = container
        
        local checkCorner = Instance.new("UICorner", checkbox)
        checkCorner.CornerRadius = UDim_new(0, 4)
        
        local checkStroke = Instance.new("UIStroke", checkbox)
        checkStroke.Color = default and Theme.PrimaryLight or Theme.Border
        checkStroke.Thickness = 2
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UD2(1, -50, 1, 0)
        label.Position = UD2(0, 45, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextSize = 13
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        
        local state = default
        checkbox.MouseButton1Click:Connect(function()
            state = not state
            checkbox.BackgroundColor3 = state and Theme.Primary or Theme.SurfaceLight
            checkbox.Text = state and "✓" or ""
            checkStroke.Color = state and Theme.PrimaryLight or Theme.Border
            callback(state)
        end)
        
        return {Container = container, Checkbox = checkbox, SetValue = function(v)
            state = v
            checkbox.BackgroundColor3 = state and Theme.Primary or Theme.SurfaceLight
            checkbox.Text = state and "✓" or ""
            checkStroke.Color = state and Theme.PrimaryLight or Theme.Border
        end}
    end
    
    local function CreateSlider(parent, name, min, max, default, suffix, callback)
        local container = Instance.new("Frame")
        container.Size = UD2(1, 0, 0, 55)
        container.BackgroundColor3 = Theme.Surface
        container.Parent = parent
        
        local containerCorner = Instance.new("UICorner", container)
        containerCorner.CornerRadius = UDim_new(0, 6)
        
        -- Slider background
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UD2(0.65, 0, 0, 20)
        sliderBg.Position = UD2(0, 10, 0, 10)
        sliderBg.BackgroundColor3 = Theme.SurfaceLight
        sliderBg.Parent = container
        
        local sliderBgCorner = Instance.new("UICorner", sliderBg)
        sliderBgCorner.CornerRadius = UDim_new(0, 4)
        
        -- Slider fill
        local pct = (default - min) / (max - min)
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UD2(pct, 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.Primary
        sliderFill.Parent = sliderBg
        
        local sliderFillCorner = Instance.new("UICorner", sliderFill)
        sliderFillCorner.CornerRadius = UDim_new(0, 4)
        
        -- Value label
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UD2(0, 60, 0, 20)
        valueLabel.Position = UD2(0.65, 15, 0, 10)
        valueLabel.BackgroundColor3 = Theme.SurfaceLight
        valueLabel.Text = "[" .. tostring(default) .. (suffix or "") .. "]"
        valueLabel.TextSize = 12
        valueLabel.TextColor3 = Theme.Text
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.Parent = container
        
        local valueLabelCorner = Instance.new("UICorner", valueLabel)
        valueLabelCorner.CornerRadius = UDim_new(0, 4)
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UD2(0.35, 0, 0, 20)
        nameLabel.Position = UD2(0.65, 0, 0, 32)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Theme.TextDim
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Right
        nameLabel.Parent = container
        
        -- Dragging
        local dragging = false
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pos = input.Position.X
                local absPos = sliderBg.AbsolutePosition.X
                local absSize = sliderBg.AbsoluteSize.X
                
                local newPct = math.clamp((pos - absPos) / absSize, 0, 1)
                sliderFill.Size = UD2(newPct, 0, 1, 0)
                
                local value = min + (max - min) * newPct
                
                if max <= 1 then
                    value = math.floor(value * 100) / 100
                else
                    value = math.floor(value)
                end
                
                valueLabel.Text = "[" .. tostring(value) .. (suffix or "") .. "]"
                callback(value)
            end
        end)
        
        return container
    end
    
    local function CreateDropdown(parent, name, options, default, callback)
        local container = Instance.new("Frame")
        container.Size = UD2(1, 0, 0, 40)
        container.BackgroundColor3 = Theme.Surface
        container.Parent = parent
        
        local containerCorner = Instance.new("UICorner", container)
        containerCorner.CornerRadius = UDim_new(0, 6)
        
        -- Dropdown button
        local dropBtn = Instance.new("TextButton")
        dropBtn.Size = UD2(0.5, -15, 0, 28)
        dropBtn.Position = UD2(0, 10, 0.5, -14)
        dropBtn.BackgroundColor3 = Theme.SurfaceLight
        dropBtn.Text = default
        dropBtn.TextSize = 12
        dropBtn.TextColor3 = Theme.Text
        dropBtn.Font = Enum.Font.Gotham
        dropBtn.Parent = container
        
        local dropCorner = Instance.new("UICorner", dropBtn)
        dropCorner.CornerRadius = UDim_new(0, 4)
        
        -- Arrow
        local arrow = Instance.new("TextLabel")
        arrow.Size = UD2(0, 20, 1, 0)
        arrow.Position = UD2(1, -25, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextSize = 10
        arrow.TextColor3 = Theme.Primary
        arrow.Font = Enum.Font.GothamBold
        arrow.Parent = dropBtn
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UD2(0.45, 0, 1, 0)
        nameLabel.Position = UD2(0.55, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Theme.TextDim
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Right
        nameLabel.Parent = container
        
        -- Dropdown list
        local dropList = Instance.new("Frame")
        dropList.Size = UD2(0.5, -15, 0, #options * 28)
        dropList.Position = UD2(0, 10, 1, 5)
        dropList.BackgroundColor3 = Theme.Surface
        dropList.Visible = false
        dropList.ZIndex = 10
        dropList.Parent = container
        
        local dropListCorner = Instance.new("UICorner", dropList)
        dropListCorner.CornerRadius = UDim_new(0, 4)
        
        local dropListStroke = Instance.new("UIStroke", dropList)
        dropListStroke.Color = Theme.Border
        
        local dropListLayout = Instance.new("UIListLayout", dropList)
        dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        for i, option in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UD2(1, 0, 0, 28)
            optBtn.BackgroundColor3 = Theme.Surface
            optBtn.BackgroundTransparency = 0.5
            optBtn.Text = option
            optBtn.TextSize = 12
            optBtn.TextColor3 = Theme.Text
            optBtn.Font = Enum.Font.Gotham
            optBtn.ZIndex = 11
            optBtn.Parent = dropList
            
            optBtn.MouseButton1Click:Connect(function()
                dropBtn.Text = option
                dropList.Visible = false
                callback(option)
            end)
        end
        
        dropBtn.MouseButton1Click:Connect(function()
            dropList.Visible = not dropList.Visible
        end)
        
        return container
    end
    
    local function CreateSection(parent, name)
        local section = Instance.new("TextLabel")
        section.Size = UD2(1, 0, 0, 25)
        section.BackgroundColor3 = Theme.SurfaceLight
        section.Text = "  " .. name
        section.TextSize = 12
        section.TextColor3 = Theme.Primary
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.Parent = parent
        
        local sectionCorner = Instance.new("UICorner", section)
        sectionCorner.CornerRadius = UDim_new(0, 4)
        
        return section
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- TAB ESP
    -- ═══════════════════════════════════════════════════════════════
    
    local espContent = tabContents["ESP"]
    
    CreateSection(espContent, "👁 ESP Settings")
    
    CreateCheckbox(espContent, "ESP Enabled", self.ESP.Enabled, function(v)
        self.ESP.Enabled = v
    end)
    
    CreateCheckbox(espContent, "Box ESP", self.ESP.Box, function(v)
        self.ESP.Box = v
    end)
    
    CreateCheckbox(espContent, "Name ESP", self.ESP.Name, function(v)
        self.ESP.Name = v
    end)
    
    CreateCheckbox(espContent, "Health Bar", self.ESP.Health, function(v)
        self.ESP.Health = v
    end)
    
    CreateCheckbox(espContent, "Distance", self.ESP.Distance, function(v)
        self.ESP.Distance = v
    end)
    
    CreateCheckbox(espContent, "Tracer Lines", self.ESP.Tracer, function(v)
        self.ESP.Tracer = v
    end)
    
    CreateSlider(espContent, "Max Distance", 100, 2000, self.ESP.MaxDistance, "m", function(v)
        self.ESP.MaxDistance = v
    end)
    
    CreateDropdown(espContent, "Box Type", {"Full", "Corner"}, self.ESP.BoxType, function(v)
        self.ESP.BoxType = v
    end)
    
    CreateDropdown(espContent, "Tracer Origin", {"Bottom", "Center", "Mouse"}, self.ESP.TracerOrigin, function(v)
        self.ESP.TracerOrigin = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- TAB AIM
    -- ═══════════════════════════════════════════════════════════════
    
    local aimContent = tabContents["Aim"]
    
    CreateSection(aimContent, "🎯 Aimbot Settings")
    
    CreateCheckbox(aimContent, "AimBot", self.Aim.Enabled, function(v)
        self.Aim.Enabled = v
    end)
    
    CreateCheckbox(aimContent, "Skip Knocked", self.Aim.SkipKnocked, function(v)
        self.Aim.SkipKnocked = v
    end)
    
    CreateCheckbox(aimContent, "Skip Vischeck", self.Aim.SkipVischeck, function(v)
        self.Aim.SkipVischeck = v
    end)
    
    CreateCheckbox(aimContent, "Prediction", self.Aim.Prediction, function(v)
        self.Aim.Prediction = v
    end)
    
    CreateCheckbox(aimContent, "Auto Fire", self.Aim.AutoFire, function(v)
        self.Aim.AutoFire = v
    end)
    
    CreateSlider(aimContent, "Headshot %", 0, 100, self.Aim.HeadshotChance, "%", function(v)
        self.Aim.HeadshotChance = v
    end)
    
    CreateDropdown(aimContent, "AimDir", {"Head", "Torso", "Closest"}, self.Aim.TargetPart, function(v)
        self.Aim.TargetPart = v
    end)
    
    CreateSlider(aimContent, "FOV", 50, 500, self.FOV.Radius, "", function(v)
        self.FOV.Radius = v
    end)
    
    CreateDropdown(aimContent, "Style Aim", {"Smooth", "Lock", "Assist", "Silent"}, self.Aim.Mode, function(v)
        self.Aim.Mode = v
    end)
    
    CreateSlider(aimContent, "Smoothness", 0.01, 0.5, self.Aim.Smoothness, "", function(v)
        self.Aim.Smoothness = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- TAB SETTING
    -- ═══════════════════════════════════════════════════════════════
    
    local settingContent = tabContents["Setting"]
    
    CreateSection(settingContent, "⚙️ General Settings")
    
    CreateCheckbox(settingContent, "Show FOV Circle", self.FOV.ShowCircle, function(v)
        self.FOV.ShowCircle = v
    end)
    
    CreateCheckbox(settingContent, "Sticky Aim", self.Aim.StickyAim, function(v)
        self.Aim.StickyAim = v
    end)
    
    CreateSection(settingContent, "👥 Team Settings")
    
    -- Atualizar times disponíveis
    self:UpdateAvailableTeams()
    
    local teamOptions = {"Enemy", "All"}
    for _, team in ipairs(self.Team.AvailableTeams) do
        table.insert(teamOptions, team.Name)
    end
    
    CreateDropdown(settingContent, "Target Team", teamOptions, self.Team.Mode, function(v)
        if v == "Enemy" or v == "All" then
            self.Team.Mode = v
            self.Team.SelectedTeam = nil
        else
            self.Team.Mode = "SelectTeam"
            self.Team.SelectedTeam = v
        end
    end)
    
    CreateSection(settingContent, "🔫 Auto Fire Settings")
    
    local fireOptions = {"Auto", "Mouse1Click", "VIM", "FireTouch"}
    CreateDropdown(settingContent, "Fire Method", fireOptions, self.Aim.FireMethod, function(v)
        self.Aim.FireMethod = v
    end)
    
    CreateSlider(settingContent, "Fire Delay", 0.01, 0.2, self.Aim.FireDelay, "s", function(v)
        self.Aim.FireDelay = v
    end)
    
    CreateSection(settingContent, "📊 Info")
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UD2(1, 0, 0, 60)
    infoLabel.BackgroundColor3 = Theme.Surface
    infoLabel.Text = "SAVAGECHEATS_ v" .. self.Version .. "\n\nToque na tela para ativar mira\nCompatível com Mobile & PC"
    infoLabel.TextSize = 11
    infoLabel.TextColor3 = Theme.TextDim
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.Parent = settingContent
    
    local infoCorner = Instance.new("UICorner", infoLabel)
    infoCorner.CornerRadius = UDim_new(0, 6)
    
    -- ═══════════════════════════════════════════════════════════════
    -- DRAGGING
    -- ═══════════════════════════════════════════════════════════════
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UD2(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- MINIMIZE / CLOSE
    -- ═══════════════════════════════════════════════════════════════
    
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UD2(0, 320, 0, 35)
            minimizeBtn.Text = "▲"
        else
            mainFrame.Size = UD2(0, 320, 0, 420)
            minimizeBtn.Text = "▼"
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Botão para reabrir
    local openBtn = Instance.new("TextButton")
    openBtn.Name = "OpenBtn"
    openBtn.Size = UD2(0, 50, 0, 50)
    openBtn.Position = UD2(0, 10, 0, 150)
    openBtn.BackgroundColor3 = Theme.Primary
    openBtn.Text = "🎯"
    openBtn.TextSize = 24
    openBtn.TextColor3 = Theme.Text
    openBtn.Font = Enum.Font.GothamBold
    openBtn.Visible = false
    openBtn.Parent = gui
    
    local openCorner = Instance.new("UICorner", openBtn)
    openCorner.CornerRadius = UDim_new(0, 12)
    
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        openBtn.Visible = true
    end)
    
    openBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        openBtn.Visible = false
    end)
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UD2(0, 50, 0, 15)
    statusLabel.Position = UD2(0, 0, 1, 2)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ON"
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Theme.Success
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = openBtn
    
    self._uiElements = {
        mainFrame = mainFrame,
        openBtn = openBtn,
        statusLabel = statusLabel,
    }
    
    -- Atualizar canvas sizes
    for _, content in pairs(tabContents) do
        local layout = content:FindFirstChildOfClass("UIListLayout")
        if layout then
            content.CanvasSize = UD2(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end
end

function SAVAGE:UpdateUI()
    if not self._uiElements then return end
    
    local e = self._uiElements
    
    if self.Aim.Enabled then
        if self.AlvoAtual then
            e.statusLabel.Text = "LOCK"
            e.statusLabel.TextColor3 = Theme.Warning
        else
            e.statusLabel.Text = "ON"
            e.statusLabel.TextColor3 = Theme.Success
        end
        e.openBtn.BackgroundColor3 = Theme.Primary
    else
        e.statusLabel.Text = "OFF"
        e.statusLabel.TextColor3 = Theme.Error
        e.openBtn.BackgroundColor3 = Theme.SurfaceLight
    end
end

function SAVAGE:DestroyUI()
    if self._ui then
        self._ui:Destroy()
        self._ui = nil
    end
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      LOOP PRINCIPAL
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:StartLoop()
    if self._connections.mainLoop then
        self._connections.mainLoop:Disconnect()
    end
    
    self._connections.mainLoop = RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera
        
        -- Atualizar FOV
        self:UpdateFOVCircle()
        
        -- Atualizar UI
        self:UpdateUI()
        
        -- Atualizar ESP
        self:UpdateAllESP()
        
        -- Aimbot
        if not self.Aim.Enabled or not self.Mirando then
            self.AlvoAtual = nil
            self.ParteAlvo = nil
            return
        end
        
        local target, part = self:FindTarget()
        
        if target and part then
            if target ~= self.AlvoAtual then
                self._lastLock = tick()
            end
            
            self.AlvoAtual = target
            self.ParteAlvo = part
            
            local character = target.Character
            local position = self:PredictPosition(character, part)
            
            self:AimAt(position)
            self:SmartFire()
        else
            self.AlvoAtual = nil
            self.ParteAlvo = nil
        end
    end)
end

function SAVAGE:StopLoop()
    if self._connections.mainLoop then
        self._connections.mainLoop:Disconnect()
        self._connections.mainLoop = nil
    end
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         INPUT
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:SetupInput()
    self._connections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.Mirando = true
        end
    end)
    
    self._connections.inputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.Mirando = false
            self.AlvoAtual = nil
            self.ParteAlvo = nil
        end
    end)
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                      INIT / DESTROY
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

function SAVAGE:Init()
    print("[SAVAGECHEATS_] Iniciando...")
    
    self:CreateFOVCircle()
    self:CreateUI()
    self:SetupInput()
    self:StartLoop()
    
    -- Player added/removed handlers para ESP
    self._connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        self:CreateESPForPlayer(player)
    end)
    
    self._connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemoveESPForPlayer(player)
    end)
    
    -- Criar ESP para jogadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        self:CreateESPForPlayer(player)
    end
    
    -- Respawn handler
    self._connections.respawn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        self.AlvoAtual = nil
        self.ParteAlvo = nil
    end)
    
    self.Ativo = true
    
    print([[

    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    🎯 SAVAGECHEATS_ CARREGADO! 🎯                          ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  COMO USAR:                                                               ║
    ║  1. Arraste o menu pelo header para mover                                 ║
    ║  2. Configure as opções nas tabs ESP, Aim e Setting                       ║
    ║  3. Toque na tela (fora da UI) para ativar a mira                         ║
    ║  4. Use o botão 🎯 para abrir/fechar o menu                               ║
    ║                                                                           ║
    ║  NOVIDADES:                                                               ║
    ║  • FOV centralizado corretamente                                          ║
    ║  • Sistema de disparo inteligente universal                               ║
    ║  • Seleção de times inteligente                                           ║
    ║  • Detecção de jogadores knocked/downed                                   ║
    ║  • ESP completo com Box, Name, Health, Distance, Tracer                   ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝

    ]])
    
    return true
end

function SAVAGE:Destroy()
    self:StopLoop()
    
    for _, conn in pairs(self._connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self._connections = {}
    
    self:DestroyFOVCircle()
    self:DestroyAllESP()
    self:DestroyUI()
    
    self.Ativo = false
    self.Mirando = false
    self.AlvoAtual = nil
    self.ParteAlvo = nil
end

--═══════════════════════════════════════════════════════════════════════════════════════════════════════
--                                         AUTO INIT
--═══════════════════════════════════════════════════════════════════════════════════════════════════════

SAVAGE:Init()

if getgenv then
    getgenv().SAVAGECHEATS_Loaded = true
    getgenv().SAVAGECHEATS_Instance = SAVAGE
end

return SAVAGE
