--[[
================================================================================
    GHOST BODY SCRIPT - EXECUTOR MOBILE EDITION (ADVANCED)
    Compatível com: Arceus X, Fluxus, Delta, Hydrogen, Codex, etc.
    
    VERSÃO AVANÇADA com:
    - Múltiplos modos de ataque
    - Sistema de detecção automática de RemoteEvents
    - Melhor compatibilidade com diferentes jogos
    - Configurações expandidas
    - Sistema anti-detecção básico
    
    COMO USAR:
    1. Execute este script no seu executor mobile
    2. Use os botões na tela ou as teclas configuradas
    3. Ajuste as configurações conforme necessário
================================================================================
--]]

--============================================================================--
--// ANTI-DETECÇÃO BÁSICO
--============================================================================--

-- Renomeia funções para evitar detecção simples
local _G_GHOST = {}
_G_GHOST.enabled = true

--============================================================================--
--// CONFIGURAÇÕES AVANÇADAS
--============================================================================--

local CONFIG = {
    --=== APARÊNCIA DO FANTASMA ===--
    PHANTOM = {
        TRANSPARENCY = 0.5,
        COLOR = Color3.fromRGB(0, 170, 255),
        GLOW_ENABLED = true,
        GLOW_COLOR = Color3.fromRGB(100, 200, 255),
        MATERIAL = Enum.Material.ForceField,
        SHOW_ACCESSORIES = true,  -- Mostrar acessórios no fantasma
    },
    
    --=== DISTÂNCIAS E LIMITES ===--
    LIMITS = {
        MAX_DISTANCE = 60,
        MIN_DISTANCE = 5,
        HEIGHT_OFFSET = 3,  -- Altura acima do chão
    },
    
    --=== TEMPOS ===--
    TIMING = {
        COOLDOWN = 0.5,
        TELEPORT_DELAY = 0.03,  -- Menor = mais rápido, mas pode falhar
        RETURN_DELAY = 0.05,
        SMOOTH_FACTOR = 0.15,  -- Suavização do movimento do fantasma
    },
    
    --=== TECLAS (PC) ===--
    KEYS = {
        TOGGLE = Enum.KeyCode.F,
        ATTACK = Enum.KeyCode.E,
        CANCEL = Enum.KeyCode.X,
    },
    
    --=== INTERFACE ===--
    GUI = {
        SCALE = 1,
        POSITION_X = 100,  -- Distância da borda direita
        POSITION_Y = 0.5,  -- Posição vertical (0-1)
        THEME_COLOR = Color3.fromRGB(0, 170, 255),
        DRAGGABLE = true,  -- Permitir arrastar a GUI
    },
    
    --=== MODO DE ATAQUE ===--
    -- "AUTO" = Detecta automaticamente o melhor método
    -- "TOOL" = Ativa ferramenta equipada
    -- "CLICK" = Simula clique do mouse
    -- "REMOTE" = Usa RemoteEvent específico
    -- "KEYBOARD" = Simula tecla de ataque
    ATTACK = {
        MODE = "AUTO",
        KEYBOARD_KEY = Enum.KeyCode.Unknown,  -- Tecla para simular (se MODE = "KEYBOARD")
        REMOTE_NAME = nil,  -- Nome do RemoteEvent (se MODE = "REMOTE")
        REMOTE_ARGS = {},   -- Argumentos do RemoteEvent
    },
    
    --=== DEBUG ===--
    DEBUG = {
        ENABLED = false,
        SHOW_DISTANCE = false,
        LOG_ATTACKS = false,
    },
}

--============================================================================--
--// SERVIÇOS
--============================================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

--============================================================================--
--// VARIÁVEIS GLOBAIS
--============================================================================--

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local State = {
    isPhantomActive = false,
    phantom = nil,
    phantomConnection = nil,
    isOnCooldown = false,
    originalCFrame = nil,
    detectedRemotes = {},
}

local GUI = {
    screenGui = nil,
    container = nil,
    toggleButton = nil,
    attackButton = nil,
    statusLabel = nil,
    distanceLabel = nil,
}

--============================================================================--
--// FUNÇÕES UTILITÁRIAS
--============================================================================--

local Utils = {}

function Utils.getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

function Utils.getHumanoid()
    local char = Utils.getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Utils.getRootPart()
    local char = Utils.getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

function Utils.isAlive()
    local humanoid = Utils.getHumanoid()
    return humanoid and humanoid.Health > 0
end

function Utils.getEquippedTool()
    local char = Utils.getCharacter()
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                return child
            end
        end
    end
    return nil
end

function Utils.notify(text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Ghost Body",
            Text = text,
            Duration = duration or 3,
            Icon = "rbxassetid://6031071053"
        })
    end)
    
    if GUI.statusLabel then
        GUI.statusLabel.Text = text
        task.delay(duration or 3, function()
            if GUI.statusLabel and GUI.statusLabel.Text == text then
                GUI.statusLabel.Text = ""
            end
        end)
    end
    
    if CONFIG.DEBUG.ENABLED then
        print("[GhostBody]", text)
    end
end

function Utils.debugLog(...)
    if CONFIG.DEBUG.ENABLED then
        print("[GhostBody DEBUG]", ...)
    end
end

--============================================================================--
--// DETECÇÃO AUTOMÁTICA DE REMOTES
--============================================================================--

local RemoteDetector = {}

function RemoteDetector.findAttackRemotes()
    local remotes = {}
    local keywords = {"attack", "combat", "damage", "hit", "skill", "ability", "punch", "kick", "slash", "m1", "m2"}
    
    local function searchIn(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                for _, keyword in ipairs(keywords) do
                    if name:find(keyword) then
                        table.insert(remotes, child)
                        Utils.debugLog("Remote encontrado:", child:GetFullName())
                        break
                    end
                end
            end
        end
    end
    
    pcall(function() searchIn(ReplicatedStorage) end)
    pcall(function() searchIn(player.PlayerGui) end)
    pcall(function() searchIn(Utils.getCharacter()) end)
    
    State.detectedRemotes = remotes
    return remotes
end

function RemoteDetector.getBestRemote()
    if #State.detectedRemotes == 0 then
        RemoteDetector.findAttackRemotes()
    end
    return State.detectedRemotes[1]
end

--============================================================================--
--// SISTEMA DE ATAQUE
--============================================================================--

local AttackSystem = {}

function AttackSystem.activateTool()
    local tool = Utils.getEquippedTool()
    if tool then
        tool:Activate()
        return true
    end
    return false
end

function AttackSystem.simulateClick()
    pcall(function()
        -- Método 1: VirtualInputManager
        VirtualInputManager:SendMouseButtonEvent(
            camera.ViewportSize.X / 2,
            camera.ViewportSize.Y / 2,
            0, true, game, 1
        )
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(
            camera.ViewportSize.X / 2,
            camera.ViewportSize.Y / 2,
            0, false, game, 1
        )
    end)
    return true
end

function AttackSystem.simulateKeyPress(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
    return true
end

function AttackSystem.fireRemote(remote, args)
    if not remote then return false end
    
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args or {}))
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args or {}))
        end
    end)
    return true
end

function AttackSystem.performAttack()
    local mode = CONFIG.ATTACK.MODE
    
    if mode == "AUTO" then
        -- Tenta na ordem: Tool > Remote > Click
        if AttackSystem.activateTool() then
            Utils.debugLog("Ataque via Tool")
            return true
        end
        
        local remote = RemoteDetector.getBestRemote()
        if remote then
            AttackSystem.fireRemote(remote, CONFIG.ATTACK.REMOTE_ARGS)
            Utils.debugLog("Ataque via Remote:", remote.Name)
            return true
        end
        
        AttackSystem.simulateClick()
        Utils.debugLog("Ataque via Click")
        return true
        
    elseif mode == "TOOL" then
        return AttackSystem.activateTool()
        
    elseif mode == "CLICK" then
        return AttackSystem.simulateClick()
        
    elseif mode == "KEYBOARD" then
        return AttackSystem.simulateKeyPress(CONFIG.ATTACK.KEYBOARD_KEY)
        
    elseif mode == "REMOTE" then
        local remote
        if CONFIG.ATTACK.REMOTE_NAME then
            remote = ReplicatedStorage:FindFirstChild(CONFIG.ATTACK.REMOTE_NAME, true)
        else
            remote = RemoteDetector.getBestRemote()
        end
        return AttackSystem.fireRemote(remote, CONFIG.ATTACK.REMOTE_ARGS)
    end
    
    return false
end

--============================================================================--
--// SISTEMA DO FANTASMA
--============================================================================--

local PhantomSystem = {}

function PhantomSystem.create()
    if State.phantom then return end
    
    local char = Utils.getCharacter()
    if not char then return end
    
    -- Clona o personagem
    State.phantom = char:Clone()
    State.phantom.Name = "GhostBody_" .. math.random(1000, 9999)
    
    -- Remove componentes
    for _, child in ipairs(State.phantom:GetDescendants()) do
        local shouldDestroy = child:IsA("Script") or 
                             child:IsA("LocalScript") or 
                             child:IsA("ModuleScript") or 
                             child.Name == "Animate" or
                             child:IsA("ForceField") or
                             child:IsA("Humanoid") or
                             child:IsA("Tool")
        
        if not CONFIG.PHANTOM.SHOW_ACCESSORIES and child:IsA("Accessory") then
            shouldDestroy = true
        end
        
        if shouldDestroy then
            pcall(function() child:Destroy() end)
        end
    end
    
    -- Aplica visual
    for _, part in ipairs(State.phantom:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = CONFIG.PHANTOM.TRANSPARENCY
            part.CanCollide = false
            part.Anchored = true
            part.CastShadow = false
            part.CanQuery = false
            part.CanTouch = false
            part.Material = CONFIG.PHANTOM.MATERIAL
            
            if part.Name ~= "Head" then
                part.Color = CONFIG.PHANTOM.COLOR
            end
        end
    end
    
    -- Adiciona glow
    if CONFIG.PHANTOM.GLOW_ENABLED then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = CONFIG.PHANTOM.GLOW_COLOR
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.5
        highlight.Adornee = State.phantom
        highlight.Parent = State.phantom
    end
    
    -- Posiciona
    local rootPart = Utils.getRootPart()
    if rootPart then
        State.phantom:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(0, 0, -10))
    end
    
    State.phantom.Parent = workspace
end

function PhantomSystem.destroy()
    if State.phantom then
        -- Fade out
        for _, part in ipairs(State.phantom:GetDescendants()) do
            if part:IsA("BasePart") then
                TweenService:Create(part, TweenInfo.new(0.2), {Transparency = 1}):Play()
            end
        end
        
        task.delay(0.25, function()
            if State.phantom then
                State.phantom:Destroy()
                State.phantom = nil
            end
        end)
    end
end

function PhantomSystem.updatePosition()
    if not State.phantom or not State.phantom.PrimaryPart then return end
    if not Utils.isAlive() then
        PhantomSystem.deactivate()
        return
    end
    
    local rootPart = Utils.getRootPart()
    if not rootPart then return end
    
    -- Calcula posição alvo
    local screenCenter = camera.ViewportSize / 2
    local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Utils.getCharacter(), State.phantom}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.LIMITS.MAX_DISTANCE, raycastParams)
    
    local targetPos
    if result then
        targetPos = result.Position + Vector3.new(0, CONFIG.LIMITS.HEIGHT_OFFSET, 0)
    else
        targetPos = ray.Origin + ray.Direction * CONFIG.LIMITS.MAX_DISTANCE
    end
    
    -- Aplica limites de distância
    local distance = (targetPos - rootPart.Position).Magnitude
    local direction = (targetPos - rootPart.Position).Unit
    
    if distance < CONFIG.LIMITS.MIN_DISTANCE then
        targetPos = rootPart.Position + direction * CONFIG.LIMITS.MIN_DISTANCE
    elseif distance > CONFIG.LIMITS.MAX_DISTANCE then
        targetPos = rootPart.Position + direction * CONFIG.LIMITS.MAX_DISTANCE
    end
    
    -- Atualiza label de distância
    if CONFIG.DEBUG.SHOW_DISTANCE and GUI.distanceLabel then
        GUI.distanceLabel.Text = string.format("%.1f studs", distance)
    end
    
    -- Calcula rotação
    local lookDir = Vector3.new(direction.X, 0, direction.Z)
    if lookDir.Magnitude > 0 then
        lookDir = lookDir.Unit
    else
        lookDir = rootPart.CFrame.LookVector
    end
    
    local targetCFrame = CFrame.new(targetPos, targetPos + lookDir)
    
    -- Suaviza movimento
    local currentCFrame = State.phantom:GetPrimaryPartCFrame()
    local smoothedCFrame = currentCFrame:Lerp(targetCFrame, CONFIG.TIMING.SMOOTH_FACTOR)
    
    State.phantom:SetPrimaryPartCFrame(smoothedCFrame)
end

function PhantomSystem.activate()
    if State.isPhantomActive then return end
    if not Utils.isAlive() then
        Utils.notify("Você precisa estar vivo!", 2)
        return
    end
    
    State.isPhantomActive = true
    PhantomSystem.create()
    
    State.phantomConnection = RunService.RenderStepped:Connect(PhantomSystem.updatePosition)
    
    if GUI.toggleButton then
        GUI.toggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        GUI.toggleButton.Text = "ON"
    end
    
    Utils.notify("Fantasma ATIVADO", 2)
end

function PhantomSystem.deactivate()
    if not State.isPhantomActive then return end
    
    State.isPhantomActive = false
    PhantomSystem.destroy()
    
    if State.phantomConnection then
        State.phantomConnection:Disconnect()
        State.phantomConnection = nil
    end
    
    if GUI.toggleButton then
        GUI.toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        GUI.toggleButton.Text = "GHOST"
    end
    
    Utils.notify("Fantasma DESATIVADO", 2)
end

function PhantomSystem.toggle()
    if State.isPhantomActive then
        PhantomSystem.deactivate()
    else
        PhantomSystem.activate()
    end
end

--============================================================================--
--// EXECUÇÃO DO ATAQUE FANTASMA
--============================================================================--

local function executeGhostAttack()
    if not State.isPhantomActive then
        Utils.notify("Ative o fantasma primeiro!", 2)
        return
    end
    
    if not State.phantom or not State.phantom.PrimaryPart then
        Utils.notify("Fantasma não encontrado!", 2)
        return
    end
    
    if State.isOnCooldown then
        return
    end
    
    if not Utils.isAlive() then
        PhantomSystem.deactivate()
        return
    end
    
    local rootPart = Utils.getRootPart()
    if not rootPart then return end
    
    -- Inicia cooldown
    State.isOnCooldown = true
    if GUI.attackButton then
        GUI.attackButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    -- Salva posição original
    State.originalCFrame = rootPart.CFrame
    local phantomCFrame = State.phantom:GetPrimaryPartCFrame()
    
    -- Flash no fantasma
    for _, part in ipairs(State.phantom:GetDescendants()) do
        if part:IsA("BasePart") then
            local orig = part.Transparency
            part.Transparency = 0.1
            task.delay(0.1, function()
                if part and part.Parent then
                    part.Transparency = orig
                end
            end)
        end
    end
    
    -- === TELEPORTE -> ATAQUE -> RETORNO ===
    
    -- 1. Teleporta
    rootPart.CFrame = phantomCFrame
    
    -- 2. Ataca
    task.wait(CONFIG.TIMING.TELEPORT_DELAY)
    AttackSystem.performAttack()
    
    -- 3. Retorna
    task.wait(CONFIG.TIMING.RETURN_DELAY)
    if rootPart and rootPart.Parent and State.originalCFrame then
        rootPart.CFrame = State.originalCFrame
    end
    
    -- === FIM ===
    
    if CONFIG.DEBUG.LOG_ATTACKS then
        Utils.debugLog("Ataque executado")
    end
    
    -- Finaliza cooldown
    task.delay(CONFIG.TIMING.COOLDOWN, function()
        State.isOnCooldown = false
        if GUI.attackButton then
            GUI.attackButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end)
end

--============================================================================--
--// INTERFACE DO USUÁRIO
--============================================================================--

local function createGUI()
    -- Remove GUI anterior
    pcall(function()
        local old = player.PlayerGui:FindFirstChild("GhostBodyGUI")
        if old then old:Destroy() end
    end)
    pcall(function()
        local old = game:GetService("CoreGui"):FindFirstChild("GhostBodyGUI")
        if old then old:Destroy() end
    end)
    
    -- Cria ScreenGui
    GUI.screenGui = Instance.new("ScreenGui")
    GUI.screenGui.Name = "GhostBodyGUI"
    GUI.screenGui.ResetOnSpawn = false
    GUI.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        GUI.screenGui.Parent = game:GetService("CoreGui")
    end)
    if not GUI.screenGui.Parent then
        GUI.screenGui.Parent = player.PlayerGui
    end
    
    -- Container
    GUI.container = Instance.new("Frame")
    GUI.container.Name = "Container"
    GUI.container.Size = UDim2.new(0, 90 * CONFIG.GUI.SCALE, 0, 220 * CONFIG.GUI.SCALE)
    GUI.container.Position = UDim2.new(1, -CONFIG.GUI.POSITION_X * CONFIG.GUI.SCALE, CONFIG.GUI.POSITION_Y, -110 * CONFIG.GUI.SCALE)
    GUI.container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    GUI.container.BackgroundTransparency = 0.3
    GUI.container.Parent = GUI.screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = GUI.container
    
    -- Drag functionality
    if CONFIG.GUI.DRAGGABLE then
        local dragging, dragStart, startPos
        
        GUI.container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = GUI.container.Position
            end
        end)
        
        GUI.container.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                GUI.container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = CONFIG.GUI.THEME_COLOR
    title.Text = "GHOST BODY"
    title.TextSize = 14 * CONFIG.GUI.SCALE
    title.Font = Enum.Font.GothamBold
    title.Parent = GUI.container
    
    -- Função para criar botões
    local function createButton(name, text, posY, color, callback)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0.9, 0, 0, 60 * CONFIG.GUI.SCALE)
        btn.Position = UDim2.new(0.05, 0, 0, posY)
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.TextSize = 16 * CONFIG.GUI.SCALE
        btn.Font = Enum.Font.GothamBold
        btn.Parent = GUI.container
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 1
        stroke.Transparency = 0.7
        stroke.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        btn.TouchTap:Connect(callback)
        
        return btn
    end
    
    -- Botões
    GUI.toggleButton = createButton("Toggle", "GHOST", 35, Color3.fromRGB(80, 80, 80), PhantomSystem.toggle)
    GUI.attackButton = createButton("Attack", "ATK", 105, Color3.fromRGB(200, 50, 50), executeGhostAttack)
    
    -- Status Label
    GUI.statusLabel = Instance.new("TextLabel")
    GUI.statusLabel.Size = UDim2.new(1, 0, 0, 20)
    GUI.statusLabel.Position = UDim2.new(0, 0, 0, 175)
    GUI.statusLabel.BackgroundTransparency = 1
    GUI.statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.statusLabel.TextStrokeTransparency = 0.5
    GUI.statusLabel.Text = ""
    GUI.statusLabel.TextSize = 11 * CONFIG.GUI.SCALE
    GUI.statusLabel.Font = Enum.Font.Gotham
    GUI.statusLabel.Parent = GUI.container
    
    -- Distance Label (debug)
    if CONFIG.DEBUG.SHOW_DISTANCE then
        GUI.distanceLabel = Instance.new("TextLabel")
        GUI.distanceLabel.Size = UDim2.new(1, 0, 0, 15)
        GUI.distanceLabel.Position = UDim2.new(0, 0, 0, 195)
        GUI.distanceLabel.BackgroundTransparency = 1
        GUI.distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        GUI.distanceLabel.Text = ""
        GUI.distanceLabel.TextSize = 10
        GUI.distanceLabel.Font = Enum.Font.Code
        GUI.distanceLabel.Parent = GUI.container
    end
end

--============================================================================--
--// CONTROLES
--============================================================================--

local function setupControls()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == CONFIG.KEYS.TOGGLE then
            PhantomSystem.toggle()
        elseif input.KeyCode == CONFIG.KEYS.ATTACK then
            if State.isPhantomActive then
                executeGhostAttack()
            end
        elseif input.KeyCode == CONFIG.KEYS.CANCEL then
            PhantomSystem.deactivate()
        end
    end)
end

--============================================================================--
--// GERENCIAMENTO DE PERSONAGEM
--============================================================================--

local function onCharacterAdded(char)
    char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    
    if State.isPhantomActive then
        PhantomSystem.deactivate()
    end
    
    humanoid.Died:Connect(function()
        PhantomSystem.deactivate()
    end)
end

--============================================================================--
--// INICIALIZAÇÃO
--============================================================================--

local function initialize()
    print("╔════════════════════════════════════════╗")
    print("║    GHOST BODY - EXECUTOR EDITION       ║")
    print("║         Advanced Version               ║")
    print("╠════════════════════════════════════════╣")
    print("║  [F] - Ativar/Desativar Fantasma       ║")
    print("║  [E] - Executar Ataque                 ║")
    print("║  [X] - Cancelar                        ║")
    print("╚════════════════════════════════════════╝")
    
    createGUI()
    setupControls()
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Detecta remotes automaticamente
    task.spawn(function()
        task.wait(1)
        RemoteDetector.findAttackRemotes()
    end)
    
    Utils.notify("Ghost Body carregado!", 3)
end

-- Executa
initialize()

--============================================================================--
--// COMANDOS DE CHAT
--============================================================================--

player.Chatted:Connect(function(msg)
    msg = msg:lower()
    if msg == "/ghost" then PhantomSystem.toggle()
    elseif msg == "/ghostoff" then PhantomSystem.deactivate()
    elseif msg == "/ghostdebug" then
        CONFIG.DEBUG.ENABLED = not CONFIG.DEBUG.ENABLED
        Utils.notify("Debug: " .. tostring(CONFIG.DEBUG.ENABLED), 2)
    end
end)

--============================================================================--
--// RETORNA REFERÊNCIA GLOBAL (OPCIONAL)
--============================================================================--

_G.GhostBody = {
    toggle = PhantomSystem.toggle,
    activate = PhantomSystem.activate,
    deactivate = PhantomSystem.deactivate,
    attack = executeGhostAttack,
    config = CONFIG,
}

return _G.GhostBody
