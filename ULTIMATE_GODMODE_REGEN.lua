--[[
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                          ║
║     ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗                       ║
║     ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝                       ║
║     ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗                         ║
║     ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝                         ║
║     ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗                       ║
║      ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝                       ║
║                                                                                          ║
║                    GOD MODE + REGENERAÇÃO DEFINITIVO v4.0                                ║
║                         Para Executores Mobile Roblox                                    ║
║                                                                                          ║
╠══════════════════════════════════════════════════════════════════════════════════════════╣
║  CARACTERÍSTICAS:                                                                        ║
║  • Múltiplas camadas de proteção                                                         ║
║  • Interceptação de dano em tempo real (cada frame)                                      ║
║  • Anti-morte por qualquer método                                                        ║
║  • Regeneração configurável                                                              ║
║  • Anti-void e Anti-fling                                                                ║
║  • Interface mobile-friendly                                                             ║
║  • SEM teleportes ou bugs                                                                ║
║                                                                                          ║
║  COMPATÍVEL COM: Delta, Fluxus, Arceus X, Hydrogen, Codex e outros                       ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SERVIÇOS DO ROBLOX
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Player = Players.LocalPlayer
local Connections = {}
local ScriptEnabled = true

-- ESTADOS DO SCRIPT
local State = {
    GodMode = false,
    Regeneration = false,
    AntiVoid = false,
    AntiFling = false,
    AntiKillbrick = false
}

-- CONFIGURAÇÕES
local Config = {
    -- Regeneração
    RegenRate = 10,              -- HP regenerado por segundo
    RegenDelay = 1,              -- Delay após tomar dano para começar regen
    
    -- Anti-Void
    VoidThreshold = -150,        -- Altura mínima antes de teleportar de volta
    
    -- Anti-Fling
    MaxVelocity = 200,           -- Velocidade máxima permitida
    
    -- God Mode
    UseInfiniteHealth = true,    -- Usar vida infinita (math.huge)
    HealthValue = 999999999,     -- Valor de vida se não usar infinito
    
    -- Interface
    GuiDraggable = true,
    NotificationsEnabled = true
}

-- Variáveis de controle
local LastHealth = 100
local LastSafePosition = nil
local LastDamageTime = 0
local OriginalMaxHealth = 100

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function Notify(title, text, duration)
    if not Config.NotificationsEnabled then return end
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Ultimate GodMode",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

local function GetCharacter()
    return Player.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    if char then
        return char:FindFirstChildWhichIsA("Humanoid")
    end
    return nil
end

local function GetRootPart()
    local char = GetCharacter()
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE GOD MODE - NÚCLEO PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function ApplyGodModeProtection()
    local humanoid = GetHumanoid()
    if not humanoid then return end
    
    -- Salva MaxHealth original se ainda não foi salvo
    if OriginalMaxHealth == 100 and humanoid.MaxHealth ~= math.huge then
        OriginalMaxHealth = humanoid.MaxHealth
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- CAMADA 1: Desabilitar estados perigosos
    -- ═══════════════════════════════════════════════════════════════════════════════
    SafeCall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- CAMADA 2: Propriedades de proteção
    -- ═══════════════════════════════════════════════════════════════════════════════
    SafeCall(function()
        humanoid.BreakJointsOnDeath = false
        humanoid.RequiresNeck = false
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- CAMADA 3: Definir vida
    -- ═══════════════════════════════════════════════════════════════════════════════
    SafeCall(function()
        if Config.UseInfiniteHealth then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            LastHealth = math.huge
        else
            humanoid.MaxHealth = Config.HealthValue
            humanoid.Health = Config.HealthValue
            LastHealth = Config.HealthValue
        end
    end)
end

local function RemoveGodModeProtection()
    local humanoid = GetHumanoid()
    if not humanoid then return end
    
    SafeCall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        
        humanoid.MaxHealth = OriginalMaxHealth
        humanoid.Health = math.min(humanoid.Health, OriginalMaxHealth)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL DE PROTEÇÃO (HEARTBEAT)
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function MainProtectionLoop()
    local humanoid = GetHumanoid()
    local rootPart = GetRootPart()
    
    if not humanoid then return end
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- GOD MODE: Proteção de vida
    -- ═══════════════════════════════════════════════════════════════════════════════
    if State.GodMode then
        -- Verifica se tomou dano
        if humanoid.Health < LastHealth then
            -- REVERTER DANO INSTANTANEAMENTE
            SafeCall(function()
                if Config.UseInfiniteHealth then
                    humanoid.Health = math.huge
                else
                    humanoid.Health = Config.HealthValue
                end
            end)
            LastDamageTime = tick()
        end
        
        -- Mantém MaxHealth
        SafeCall(function()
            if Config.UseInfiniteHealth then
                if humanoid.MaxHealth ~= math.huge then
                    humanoid.MaxHealth = math.huge
                end
            else
                if humanoid.MaxHealth ~= Config.HealthValue then
                    humanoid.MaxHealth = Config.HealthValue
                end
            end
        end)
        
        -- Previne estado de morte
        SafeCall(function()
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                if Config.UseInfiniteHealth then
                    humanoid.Health = math.huge
                else
                    humanoid.Health = Config.HealthValue
                end
            end
        end)
        
        -- Atualiza LastHealth
        LastHealth = humanoid.Health
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- REGENERAÇÃO: Cura gradual
    -- ═══════════════════════════════════════════════════════════════════════════════
    if State.Regeneration and not State.GodMode then
        if humanoid.Health < humanoid.MaxHealth then
            if tick() - LastDamageTime > Config.RegenDelay then
                SafeCall(function()
                    local healAmount = Config.RegenRate * RunService.Heartbeat:Wait()
                    humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
                end)
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- ANTI-VOID: Previne morte por queda
    -- ═══════════════════════════════════════════════════════════════════════════════
    if State.AntiVoid and rootPart then
        -- Salva posição segura
        if rootPart.Position.Y > Config.VoidThreshold + 50 then
            LastSafePosition = rootPart.CFrame
        end
        
        -- Teleporta de volta se cair no void
        if rootPart.Position.Y < Config.VoidThreshold then
            if LastSafePosition then
                SafeCall(function()
                    rootPart.CFrame = LastSafePosition
                    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end)
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════════
    -- ANTI-FLING: Previne morte por velocidade extrema
    -- ═══════════════════════════════════════════════════════════════════════════════
    if State.AntiFling and rootPart then
        SafeCall(function()
            local velocity = rootPart.AssemblyLinearVelocity
            if velocity.Magnitude > Config.MaxVelocity then
                rootPart.AssemblyLinearVelocity = velocity.Unit * Config.MaxVelocity
            end
            
            local angularVel = rootPart.AssemblyAngularVelocity
            if angularVel.Magnitude > 50 then
                rootPart.AssemblyAngularVelocity = angularVel.Unit * 10
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE ANTI-KILLBRICK
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function SetupAntiKillbrick()
    local char = GetCharacter()
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            SafeCall(function()
                part.Touched:Connect(function(hit)
                    if not State.AntiKillbrick then return end
                    
                    local name = hit.Name:lower()
                    if name:find("kill") or name:find("death") or 
                       name:find("damage") or name:find("lava") or
                       name:find("spike") or name:find("trap") or
                       name:find("hurt") then
                        -- Aplica proteção imediata
                        local humanoid = GetHumanoid()
                        if humanoid and State.GodMode then
                            if Config.UseInfiniteHealth then
                                humanoid.Health = math.huge
                            else
                                humanoid.Health = Config.HealthValue
                            end
                        end
                    end
                end)
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MONITORAMENTO DE MUDANÇAS DE VIDA
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function SetupHealthMonitor()
    local humanoid = GetHumanoid()
    if not humanoid then return end
    
    -- Monitora mudanças de vida
    Connections.HealthChanged = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if not State.GodMode then return end
        
        SafeCall(function()
            if humanoid.Health < LastHealth then
                -- Dano detectado - reverter IMEDIATAMENTE
                task.defer(function()
                    if Config.UseInfiniteHealth then
                        humanoid.Health = math.huge
                    else
                        humanoid.Health = Config.HealthValue
                    end
                end)
            end
        end)
    end)
    
    -- Monitora mudanças de estado
    Connections.StateChanged = humanoid.StateChanged:Connect(function(old, new)
        if not State.GodMode then return end
        
        if new == Enum.HumanoidStateType.Dead then
            SafeCall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                if Config.UseInfiniteHealth then
                    humanoid.Health = math.huge
                else
                    humanoid.Health = Config.HealthValue
                end
            end)
        end
    end)
    
    -- Monitora mudanças de MaxHealth
    Connections.MaxHealthChanged = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if not State.GodMode then return end
        
        SafeCall(function()
            if Config.UseInfiniteHealth then
                if humanoid.MaxHealth ~= math.huge then
                    humanoid.MaxHealth = math.huge
                    humanoid.Health = math.huge
                end
            else
                if humanoid.MaxHealth ~= Config.HealthValue then
                    humanoid.MaxHealth = Config.HealthValue
                end
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- SETUP DO PERSONAGEM
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function SetupCharacter(char)
    if not char then return end
    
    -- Aguarda humanoid carregar
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    
    -- Aguarda um pouco para o personagem estabilizar
    task.wait(0.3)
    
    -- Salva posição inicial como segura
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        LastSafePosition = rootPart.CFrame
    end
    
    -- Salva MaxHealth original
    OriginalMaxHealth = humanoid.MaxHealth
    LastHealth = humanoid.Health
    
    -- Configura monitores
    SetupHealthMonitor()
    SetupAntiKillbrick()
    
    -- Aplica proteções se ativas
    if State.GodMode then
        ApplyGodModeProtection()
        Notify("God Mode", "Proteção reaplicada!", 2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- FUNÇÕES DE CONTROLE
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function ToggleGodMode(enable)
    State.GodMode = enable
    
    if enable then
        ApplyGodModeProtection()
        Notify("God Mode", "ATIVADO - Você está imortal!", 3)
    else
        RemoveGodModeProtection()
        Notify("God Mode", "Desativado", 2)
    end
end

local function ToggleRegeneration(enable)
    State.Regeneration = enable
    Notify("Regeneração", enable and "ATIVADA" or "Desativada", 2)
end

local function ToggleAntiVoid(enable)
    State.AntiVoid = enable
    Notify("Anti-Void", enable and "ATIVADO" or "Desativado", 2)
end

local function ToggleAntiFling(enable)
    State.AntiFling = enable
    Notify("Anti-Fling", enable and "ATIVADO" or "Desativado", 2)
end

local function ToggleAntiKillbrick(enable)
    State.AntiKillbrick = enable
    Notify("Anti-Killbrick", enable and "ATIVADO" or "Desativado", 2)
end

local function ToggleAll(enable)
    ToggleGodMode(enable)
    ToggleAntiVoid(enable)
    ToggleAntiFling(enable)
    ToggleAntiKillbrick(enable)
    
    if enable then
        Notify("PROTEÇÃO TOTAL", "Todas as proteções ATIVADAS!", 3)
    else
        Notify("Proteções", "Todas desativadas", 2)
    end
end

local function HealFull()
    local humanoid = GetHumanoid()
    if humanoid then
        SafeCall(function()
            humanoid.Health = humanoid.MaxHealth
        end)
        Notify("Cura", "Vida restaurada!", 2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INTERFACE GRÁFICA (GUI)
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function CreateGUI()
    -- Remove GUI existente
    local existingGui = Player.PlayerGui:FindFirstChild("UltimateGodModeGUI")
    if existingGui then existingGui:Destroy() end
    
    -- Cria ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UltimateGodModeGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 240, 0, 340)
    MainFrame.Position = UDim2.new(0, 15, 0.5, -170)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Borda com gradiente
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(80, 150, 255)
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    -- Título
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    -- Fix para cantos inferiores do título
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 15)
    TitleFix.Position = UDim2.new(0, 0, 1, -15)
    TitleFix.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, 0, 1, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "⚡ ULTIMATE GODMODE"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.Parent = TitleBar
    
    -- Container de botões
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Size = UDim2.new(1, -20, 1, -55)
    ButtonContainer.Position = UDim2.new(0, 10, 0, 50)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = ButtonContainer
    
    -- Função para criar botões toggle
    local function CreateToggleButton(name, text, order, callback)
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Size = UDim2.new(1, 0, 0, 40)
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 13
        Button.Font = Enum.Font.GothamSemibold
        Button.LayoutOrder = order
        Button.Parent = ButtonContainer
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 8)
        BtnCorner.Parent = Button
        
        local isActive = false
        
        Button.MouseButton1Click:Connect(function()
            isActive = not isActive
            callback(isActive)
            
            if isActive then
                Button.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
                Button.Text = text:gsub("🔴", "🟢")
            else
                Button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
                Button.Text = text:gsub("🟢", "🔴")
            end
        end)
        
        return Button
    end
    
    -- Função para criar botões de ação
    local function CreateActionButton(name, text, order, color, callback)
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Size = UDim2.new(1, 0, 0, 35)
        Button.BackgroundColor3 = color
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 12
        Button.Font = Enum.Font.GothamSemibold
        Button.LayoutOrder = order
        Button.Parent = ButtonContainer
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 8)
        BtnCorner.Parent = Button
        
        Button.MouseButton1Click:Connect(callback)
        
        return Button
    end
    
    -- Criar botões
    CreateToggleButton("GodModeBtn", "🔴 GOD MODE", 1, ToggleGodMode)
    CreateToggleButton("AntiVoidBtn", "🔴 ANTI-VOID", 2, ToggleAntiVoid)
    CreateToggleButton("AntiFlingBtn", "🔴 ANTI-FLING", 3, ToggleAntiFling)
    CreateToggleButton("AntiKillbrickBtn", "🔴 ANTI-KILLBRICK", 4, ToggleAntiKillbrick)
    CreateToggleButton("RegenBtn", "🔴 REGENERAÇÃO", 5, ToggleRegeneration)
    
    -- Botões de ação
    CreateActionButton("HealBtn", "💚 CURAR VIDA", 6, Color3.fromRGB(50, 150, 100), HealFull)
    CreateActionButton("AllOnBtn", "⚡ ATIVAR TUDO", 7, Color3.fromRGB(200, 150, 50), function() ToggleAll(true) end)
    
    -- Drag functionality para mobile
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        dragging = false
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Animação de borda
    spawn(function()
        local hue = 0
        while ScreenGui.Parent do
            hue = (hue + 0.5) % 360
            local color = Color3.fromHSV(hue/360, 0.7, 1)
            
            local tween = TweenService:Create(MainStroke, TweenInfo.new(0.5), {
                Color = color
            })
            tween:Play()
            
            task.wait(0.5)
        end
    end)
    
    ScreenGui.Parent = Player.PlayerGui
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- COMANDOS DE CHAT
-- ═══════════════════════════════════════════════════════════════════════════════════════

Player.Chatted:Connect(function(message)
    local msg = message:lower()
    
    if msg == "/god" or msg == "/godmode" then
        ToggleGodMode(not State.GodMode)
    elseif msg == "/heal" or msg == "/curar" then
        HealFull()
    elseif msg == "/regen" then
        ToggleRegeneration(not State.Regeneration)
    elseif msg == "/antivoid" then
        ToggleAntiVoid(not State.AntiVoid)
    elseif msg == "/antifling" then
        ToggleAntiFling(not State.AntiFling)
    elseif msg == "/all" then
        ToggleAll(true)
    elseif msg == "/off" then
        ToggleAll(false)
    elseif msg == "/help" or msg == "/ajuda" then
        Notify("Comandos", "/god /heal /regen /antivoid /antifling /all /off", 5)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function Initialize()
    -- Configura personagem atual
    if Player.Character then
        SetupCharacter(Player.Character)
    end
    
    -- Monitora novos personagens
    Connections.CharacterAdded = Player.CharacterAdded:Connect(function(char)
        -- Limpa conexões antigas
        for name, conn in pairs(Connections) do
            if name ~= "CharacterAdded" and name ~= "MainLoop" then
                if conn and typeof(conn) == "RBXScriptConnection" then
                    SafeCall(function() conn:Disconnect() end)
                end
            end
        end
        
        SetupCharacter(char)
    end)
    
    -- Loop principal de proteção
    Connections.MainLoop = RunService.Heartbeat:Connect(function()
        if ScriptEnabled then
            MainProtectionLoop()
        end
    end)
    
    -- Cria GUI
    CreateGUI()
    
    -- Notificação inicial
    Notify("Ultimate GodMode v4.0", "Script carregado! Use a GUI ou /help", 4)
end

-- Inicia o script
Initialize()

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- MENSAGEM DE CONSOLE
-- ═══════════════════════════════════════════════════════════════════════════════════════

print([[

╔══════════════════════════════════════════════════════════════════════════════╗
║                     ULTIMATE GODMODE v4.0 CARREGADO                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  FUNCIONALIDADES:                                                            ║
║  • God Mode - Vida infinita + anti-dano                                      ║
║  • Anti-Void - Previne morte por queda                                       ║
║  • Anti-Fling - Previne morte por velocidade extrema                         ║
║  • Anti-Killbrick - Imunidade a killbricks                                   ║
║  • Regeneração - Cura gradual de vida                                        ║
║                                                                              ║
║  COMANDOS DE CHAT:                                                           ║
║  /god - Ativa/desativa God Mode                                              ║
║  /heal - Cura instantânea                                                    ║
║  /regen - Ativa/desativa regeneração                                         ║
║  /antivoid - Ativa/desativa anti-void                                        ║
║  /antifling - Ativa/desativa anti-fling                                      ║
║  /all - Ativa todas as proteções                                             ║
║  /off - Desativa todas as proteções                                          ║
║  /help - Mostra comandos                                                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

]])
