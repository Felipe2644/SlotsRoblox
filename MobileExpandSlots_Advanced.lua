--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              MOBILE EXPAND SLOTS - VERSÃO AVANÇADA v2.0                  ║
    ║                                                                          ║
    ║  • Interface interativa para personalização                              ║
    ║  • Ajuste de tamanho, posição e espaçamento                             ║
    ║  • Slots adicionais com seleção de itens                                ║
    ║  • UI estruturada com opção de esconder                                 ║
    ║  • Opção de fixar tamanho dos slots                                     ║
    ║                                                                          ║
    ║  Compatível com: Delta, Fluxus, Arceus X, Codex, Wave, etc.            ║
    ╚══════════════════════════════════════════════════════════════════════════╝
]]--

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES SALVAS (Persistentes durante a sessão)
-- ═══════════════════════════════════════════════════════════════════════════

local SavedConfig = getgenv and getgenv().MobileSlotsSavedConfig or nil

local CONFIG = SavedConfig or {
    -- Slots
    NUMERO_SLOTS = 6,
    TAMANHO_SLOT = 52,
    ESPACAMENTO = 5,
    
    -- Posição
    POSICAO_X = 0.5,  -- 0-1 (porcentagem da tela)
    POSICAO_Y = 1,    -- 0-1 (porcentagem da tela)
    OFFSET_Y = -90,   -- Offset em pixels do fundo
    
    -- Visual
    COR_FUNDO = Color3.fromRGB(35, 35, 35),
    COR_EQUIPADO = Color3.fromRGB(90, 142, 233),
    COR_ADICIONAL = Color3.fromRGB(60, 45, 80),
    TRANSPARENCIA = 0.25,
    CANTOS_ARREDONDADOS = 8,
    
    -- Comportamento
    MOSTRAR_NUMEROS = true,
    TAMANHO_FIXO = false,
    UI_VISIVEL = true,
    MENU_ABERTO = false,
    
    -- Slots Adicionais (índice do item no inventário)
    SLOTS_ADICIONAIS = {}
}

-- Salva config globalmente
if getgenv then
    getgenv().MobileSlotsSavedConfig = CONFIG
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════════

local ScreenGui, MainFrame, HotbarFrame, SlotContainer
local SettingsFrame, SettingsButton, HideButton
local Slots = {}
local SlotsAdicionais = {}
local SlotsByTool = {}
local EquippedSlot = nil
local Connections = {}
local IsDragging = false
local DragStart = nil
local StartPos = nil

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════════

local function Tween(obj, props, duration)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), props)
    tween:Play()
    return tween
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or CONFIG.CANTOS_ARREDONDADOS)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(60, 60, 60)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

local function GetAllTools()
    local tools = {}
    local char = Player.Character
    local backpack = Player:FindFirstChild("Backpack")
    
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    return tools
end

local function DisableDefaultHotbar()
    for i = 1, 10 do
        local ok = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if ok then break end
        task.wait(0.3)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRIAÇÃO DA INTERFACE PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateMainUI()
    -- Remove GUI antiga
    local oldGui = PlayerGui:FindFirstChild("MobileExpandSlotsAdvanced")
    if oldGui then oldGui:Destroy() end
    
    -- ScreenGui principal
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MobileExpandSlotsAdvanced"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = PlayerGui
    
    -- Frame principal da hotbar
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundTransparency = 1
    MainFrame.AnchorPoint = Vector2.new(0.5, 1)
    MainFrame.Position = UDim2.new(CONFIG.POSICAO_X, 0, CONFIG.POSICAO_Y, CONFIG.OFFSET_Y)
    MainFrame.AutomaticSize = Enum.AutomaticSize.XY
    MainFrame.Parent = ScreenGui
    
    -- Container dos slots normais
    HotbarFrame = Instance.new("Frame")
    HotbarFrame.Name = "HotbarFrame"
    HotbarFrame.BackgroundTransparency = 1
    HotbarFrame.AutomaticSize = Enum.AutomaticSize.XY
    HotbarFrame.Parent = MainFrame
    
    SlotContainer = Instance.new("Frame")
    SlotContainer.Name = "SlotContainer"
    SlotContainer.BackgroundTransparency = 1
    SlotContainer.AutomaticSize = Enum.AutomaticSize.XY
    SlotContainer.Parent = HotbarFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, CONFIG.ESPACAMENTO)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = SlotContainer
    
    -- Botão de configurações (engrenagem)
    SettingsButton = Instance.new("ImageButton")
    SettingsButton.Name = "SettingsButton"
    SettingsButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    SettingsButton.BackgroundTransparency = 0.3
    SettingsButton.Size = UDim2.new(0, 32, 0, 32)
    SettingsButton.Position = UDim2.new(0, -40, 0, 0)
    SettingsButton.Image = "rbxassetid://6031154871" -- Ícone de engrenagem
    SettingsButton.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SettingsButton.Parent = MainFrame
    CreateCorner(SettingsButton, 6)
    
    -- Botão de esconder/mostrar
    HideButton = Instance.new("ImageButton")
    HideButton.Name = "HideButton"
    HideButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    HideButton.BackgroundTransparency = 0.3
    HideButton.Size = UDim2.new(0, 32, 0, 32)
    HideButton.Position = UDim2.new(1, 8, 0, 0)
    HideButton.Image = "rbxassetid://6035047409" -- Ícone de olho
    HideButton.ImageColor3 = Color3.fromRGB(200, 200, 200)
    HideButton.Parent = MainFrame
    CreateCorner(HideButton, 6)
    
    -- Eventos dos botões
    SettingsButton.MouseButton1Click:Connect(function()
        ToggleSettings()
    end)
    
    HideButton.MouseButton1Click:Connect(function()
        ToggleHotbarVisibility()
    end)
    
    -- Permite arrastar a hotbar
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not CONFIG.TAMANHO_FIXO then
                IsDragging = true
                DragStart = input.Position
                StartPos = MainFrame.Position
            end
        end
    end)
    
    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if IsDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - DragStart
            local screenSize = workspace.CurrentCamera.ViewportSize
            
            local newX = StartPos.X.Scale + (delta.X / screenSize.X)
            local newY = StartPos.Y.Scale + (delta.Y / screenSize.Y)
            
            newX = math.clamp(newX, 0.1, 0.9)
            newY = math.clamp(newY, 0.1, 1)
            
            MainFrame.Position = UDim2.new(newX, 0, newY, CONFIG.OFFSET_Y)
            CONFIG.POSICAO_X = newX
            CONFIG.POSICAO_Y = newY
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRIAÇÃO DO MENU DE CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateSettingsUI()
    -- Frame de configurações
    SettingsFrame = Instance.new("Frame")
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    SettingsFrame.BackgroundTransparency = 0.1
    SettingsFrame.Size = UDim2.new(0, 320, 0, 480)
    SettingsFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
    SettingsFrame.Visible = false
    SettingsFrame.Parent = ScreenGui
    CreateCorner(SettingsFrame, 12)
    CreateStroke(SettingsFrame, Color3.fromRGB(80, 80, 100), 2, 0.3)
    
    -- Título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.Parent = SettingsFrame
    CreateCorner(titleBar, 12)
    
    -- Corrige cantos inferiores do título
    local titleFix = Instance.new("Frame")
    titleFix.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.BackgroundTransparency = 1
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.Text = "⚙️ Configurações"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 7)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    CreateCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        ToggleSettings()
    end)
    
    -- ScrollingFrame para conteúdo
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Content"
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, -20, 1, -55)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 650)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scrollFrame.Parent = SettingsFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = scrollFrame
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SEÇÃO: SLOTS
    -- ═══════════════════════════════════════════════════════════════════
    
    CreateSectionHeader(scrollFrame, "📦 Slots", 1)
    
    CreateSlider(scrollFrame, "Número de Slots", 3, 10, CONFIG.NUMERO_SLOTS, 2, function(value)
        CONFIG.NUMERO_SLOTS = value
        RecreateSlots()
    end)
    
    CreateSlider(scrollFrame, "Tamanho dos Slots", 30, 80, CONFIG.TAMANHO_SLOT, 3, function(value)
        CONFIG.TAMANHO_SLOT = value
        UpdateSlotSizes()
    end)
    
    CreateSlider(scrollFrame, "Espaçamento", 0, 20, CONFIG.ESPACAMENTO, 4, function(value)
        CONFIG.ESPACAMENTO = value
        UpdateSpacing()
    end)
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SEÇÃO: POSIÇÃO
    -- ═══════════════════════════════════════════════════════════════════
    
    CreateSectionHeader(scrollFrame, "📍 Posição", 5)
    
    CreateSlider(scrollFrame, "Posição Horizontal", 0, 100, math.floor(CONFIG.POSICAO_X * 100), 6, function(value)
        CONFIG.POSICAO_X = value / 100
        MainFrame.Position = UDim2.new(CONFIG.POSICAO_X, 0, CONFIG.POSICAO_Y, CONFIG.OFFSET_Y)
    end)
    
    CreateSlider(scrollFrame, "Distância do Fundo", 50, 300, math.abs(CONFIG.OFFSET_Y), 7, function(value)
        CONFIG.OFFSET_Y = -value
        MainFrame.Position = UDim2.new(CONFIG.POSICAO_X, 0, CONFIG.POSICAO_Y, CONFIG.OFFSET_Y)
    end)
    
    CreateToggle(scrollFrame, "🔒 Fixar Posição/Tamanho", CONFIG.TAMANHO_FIXO, 8, function(value)
        CONFIG.TAMANHO_FIXO = value
    end)
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SEÇÃO: VISUAL
    -- ═══════════════════════════════════════════════════════════════════
    
    CreateSectionHeader(scrollFrame, "🎨 Visual", 9)
    
    CreateSlider(scrollFrame, "Transparência", 0, 80, math.floor(CONFIG.TRANSPARENCIA * 100), 10, function(value)
        CONFIG.TRANSPARENCIA = value / 100
        UpdateSlotVisuals()
    end)
    
    CreateSlider(scrollFrame, "Cantos Arredondados", 0, 20, CONFIG.CANTOS_ARREDONDADOS, 11, function(value)
        CONFIG.CANTOS_ARREDONDADOS = value
        UpdateSlotVisuals()
    end)
    
    CreateToggle(scrollFrame, "🔢 Mostrar Números", CONFIG.MOSTRAR_NUMEROS, 12, function(value)
        CONFIG.MOSTRAR_NUMEROS = value
        UpdateSlotVisuals()
    end)
    
    -- ═══════════════════════════════════════════════════════════════════
    -- SEÇÃO: SLOTS ADICIONAIS
    -- ═══════════════════════════════════════════════════════════════════
    
    CreateSectionHeader(scrollFrame, "➕ Slots Adicionais", 13)
    
    local addSlotBtn = Instance.new("TextButton")
    addSlotBtn.Name = "AddSlotBtn"
    addSlotBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
    addSlotBtn.Size = UDim2.new(1, 0, 0, 40)
    addSlotBtn.LayoutOrder = 14
    addSlotBtn.Text = "+ Adicionar Slot Extra"
    addSlotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    addSlotBtn.TextSize = 14
    addSlotBtn.Font = Enum.Font.GothamBold
    addSlotBtn.Parent = scrollFrame
    CreateCorner(addSlotBtn, 8)
    
    addSlotBtn.MouseButton1Click:Connect(function()
        OpenItemSelector()
    end)
    
    -- Lista de slots adicionais
    local additionalSlotsFrame = Instance.new("Frame")
    additionalSlotsFrame.Name = "AdditionalSlotsList"
    additionalSlotsFrame.BackgroundTransparency = 1
    additionalSlotsFrame.Size = UDim2.new(1, 0, 0, 0)
    additionalSlotsFrame.AutomaticSize = Enum.AutomaticSize.Y
    additionalSlotsFrame.LayoutOrder = 15
    additionalSlotsFrame.Parent = scrollFrame
    
    local addLayout = Instance.new("UIListLayout")
    addLayout.Padding = UDim.new(0, 5)
    addLayout.Parent = additionalSlotsFrame
    
    -- Atualiza canvas size
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMPONENTES DE UI
-- ═══════════════════════════════════════════════════════════════════════════

function CreateSectionHeader(parent, text, order)
    local header = Instance.new("Frame")
    header.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    header.Size = UDim2.new(1, 0, 0, 30)
    header.LayoutOrder = order
    header.Parent = parent
    CreateCorner(header, 6)
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    return header
end

function CreateSlider(parent, labelText, min, max, default, order, callback)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 50)
    container.LayoutOrder = order
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBg.Size = UDim2.new(1, 0, 0, 20)
    sliderBg.Position = UDim2.new(0, 0, 0, 25)
    sliderBg.Parent = container
    CreateCorner(sliderBg, 10)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Color3.fromRGB(90, 142, 233)
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Parent = sliderBg
    CreateCorner(sliderFill, 10)
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg
    
    local dragging = false
    
    local function UpdateSlider(inputPos)
        local relativeX = math.clamp((inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * relativeX)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        valueLabel.Text = tostring(value)
        callback(value)
    end
    
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input.Position)
        end
    end)
    
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            UpdateSlider(input.Position)
        end
    end)
    
    return container
end

function CreateToggle(parent, labelText, default, order, callback)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 35)
    container.LayoutOrder = order
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.BackgroundColor3 = default and Color3.fromRGB(90, 142, 233) or Color3.fromRGB(60, 60, 70)
    toggleBg.Size = UDim2.new(0, 50, 0, 26)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -13)
    toggleBg.Parent = container
    CreateCorner(toggleBg, 13)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.Size = UDim2.new(0, 22, 0, 22)
    toggleCircle.Position = default and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    toggleCircle.Parent = toggleBg
    CreateCorner(toggleCircle, 11)
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.Text = ""
    toggleBtn.Parent = toggleBg
    
    local isOn = default
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Tween(toggleBg, {BackgroundColor3 = isOn and Color3.fromRGB(90, 142, 233) or Color3.fromRGB(60, 60, 70)}, 0.2)
        Tween(toggleCircle, {Position = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)}, 0.2)
        callback(isOn)
    end)
    
    return container
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SELETOR DE ITENS PARA SLOTS ADICIONAIS
-- ═══════════════════════════════════════════════════════════════════════════

local ItemSelectorFrame = nil

function OpenItemSelector()
    if ItemSelectorFrame then
        ItemSelectorFrame:Destroy()
    end
    
    ItemSelectorFrame = Instance.new("Frame")
    ItemSelectorFrame.Name = "ItemSelector"
    ItemSelectorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ItemSelectorFrame.Size = UDim2.new(0, 280, 0, 350)
    ItemSelectorFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
    ItemSelectorFrame.Parent = ScreenGui
    CreateCorner(ItemSelectorFrame, 12)
    CreateStroke(ItemSelectorFrame, Color3.fromRGB(100, 80, 150), 2, 0.3)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.BackgroundColor3 = Color3.fromRGB(60, 45, 80)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "📦 Selecione um Item"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = ItemSelectorFrame
    CreateCorner(title, 12)
    
    local titleFix = Instance.new("Frame")
    titleFix.BackgroundColor3 = Color3.fromRGB(60, 45, 80)
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = title
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = title
    CreateCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        ItemSelectorFrame:Destroy()
        ItemSelectorFrame = nil
    end)
    
    -- Lista de itens
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, -20, 1, -55)
    scrollFrame.Position = UDim2.new(0, 10, 0, 48)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = ItemSelectorFrame
    
    local itemLayout = Instance.new("UIListLayout")
    itemLayout.Padding = UDim.new(0, 5)
    itemLayout.Parent = scrollFrame
    
    -- Popula com ferramentas disponíveis
    local tools = GetAllTools()
    
    for i, tool in ipairs(tools) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        itemBtn.Size = UDim2.new(1, 0, 0, 45)
        itemBtn.Text = ""
        itemBtn.Parent = scrollFrame
        CreateCorner(itemBtn, 8)
        
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 35, 0, 35)
        icon.Position = UDim2.new(0, 5, 0.5, -17)
        icon.Image = tool.TextureId ~= "" and tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = itemBtn
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, -50, 1, 0)
        nameLabel.Position = UDim2.new(0, 45, 0, 0)
        nameLabel.Text = tool.Name
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = itemBtn
        
        itemBtn.MouseButton1Click:Connect(function()
            AddAdditionalSlot(tool)
            ItemSelectorFrame:Destroy()
            ItemSelectorFrame = nil
        end)
    end
    
    if #tools == 0 then
        local noItems = Instance.new("TextLabel")
        noItems.BackgroundTransparency = 1
        noItems.Size = UDim2.new(1, 0, 0, 50)
        noItems.Text = "Nenhum item no inventário"
        noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
        noItems.TextSize = 14
        noItems.Font = Enum.Font.Gotham
        noItems.Parent = scrollFrame
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLOTS ADICIONAIS
-- ═══════════════════════════════════════════════════════════════════════════

function AddAdditionalSlot(tool)
    local slotData = {
        ToolName = tool.Name,
        Tool = tool
    }
    table.insert(CONFIG.SLOTS_ADICIONAIS, slotData)
    
    CreateAdditionalSlotUI(slotData, #CONFIG.SLOTS_ADICIONAIS)
    CreateAdditionalSlotInHotbar(slotData, #CONFIG.SLOTS_ADICIONAIS)
end

function CreateAdditionalSlotUI(slotData, index)
    local listFrame = SettingsFrame:FindFirstChild("Content"):FindFirstChild("AdditionalSlotsList")
    if not listFrame then return end
    
    local slotEntry = Instance.new("Frame")
    slotEntry.Name = "AdditionalSlot_" .. index
    slotEntry.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
    slotEntry.Size = UDim2.new(1, 0, 0, 40)
    slotEntry.Parent = listFrame
    CreateCorner(slotEntry, 6)
    
    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 5, 0.5, -15)
    icon.Image = slotData.Tool and (slotData.Tool.TextureId ~= "" and slotData.Tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png") or ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slotEntry
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, -80, 1, 0)
    nameLabel.Position = UDim2.new(0, 40, 0, 0)
    nameLabel.Text = slotData.ToolName
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = slotEntry
    
    local removeBtn = Instance.new("TextButton")
    removeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    removeBtn.Size = UDim2.new(0, 30, 0, 30)
    removeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    removeBtn.Text = "✕"
    removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeBtn.TextSize = 12
    removeBtn.Font = Enum.Font.GothamBold
    removeBtn.Parent = slotEntry
    CreateCorner(removeBtn, 6)
    
    removeBtn.MouseButton1Click:Connect(function()
        RemoveAdditionalSlot(index)
        slotEntry:Destroy()
    end)
end

function CreateAdditionalSlotInHotbar(slotData, index)
    local slot = CreateSlot(CONFIG.NUMERO_SLOTS + index, true)
    slot.Tool = slotData.Tool
    slot.IsAdditional = true
    slot.AdditionalIndex = index
    
    if slotData.Tool then
        slot.Icon.Image = slotData.Tool.TextureId ~= "" and slotData.Tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
    end
    
    SlotsAdicionais[index] = slot
end

function RemoveAdditionalSlot(index)
    if SlotsAdicionais[index] then
        SlotsAdicionais[index].Frame:Destroy()
        SlotsAdicionais[index] = nil
    end
    table.remove(CONFIG.SLOTS_ADICIONAIS, index)
    
    -- Recria slots adicionais para reordenar
    for i, slot in pairs(SlotsAdicionais) do
        if slot.Frame then
            slot.Frame:Destroy()
        end
    end
    SlotsAdicionais = {}
    
    for i, slotData in ipairs(CONFIG.SLOTS_ADICIONAIS) do
        CreateAdditionalSlotInHotbar(slotData, i)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRIAÇÃO E GERENCIAMENTO DE SLOTS
-- ═══════════════════════════════════════════════════════════════════════════

function CreateSlot(index, isAdditional)
    local slot = {
        Index = index,
        Tool = nil,
        IsAdditional = isAdditional or false
    }
    
    slot.Frame = Instance.new("Frame")
    slot.Frame.Name = "Slot" .. index
    slot.Frame.BackgroundColor3 = isAdditional and CONFIG.COR_ADICIONAL or CONFIG.COR_FUNDO
    slot.Frame.BackgroundTransparency = CONFIG.TRANSPARENCIA
    slot.Frame.Size = UDim2.new(0, CONFIG.TAMANHO_SLOT, 0, CONFIG.TAMANHO_SLOT)
    slot.Frame.LayoutOrder = index
    slot.Frame.Parent = SlotContainer
    CreateCorner(slot.Frame, CONFIG.CANTOS_ARREDONDADOS)
    
    slot.Stroke = CreateStroke(slot.Frame, Color3.fromRGB(60, 60, 60), 1, 0.5)
    
    slot.Icon = Instance.new("ImageLabel")
    slot.Icon.Name = "Icon"
    slot.Icon.BackgroundTransparency = 1
    slot.Icon.Size = UDim2.new(0.82, 0, 0.82, 0)
    slot.Icon.Position = UDim2.new(0.09, 0, 0.09, 0)
    slot.Icon.ScaleType = Enum.ScaleType.Fit
    slot.Icon.Parent = slot.Frame
    
    if CONFIG.MOSTRAR_NUMEROS and not isAdditional then
        slot.Number = Instance.new("TextLabel")
        slot.Number.Name = "Number"
        slot.Number.BackgroundTransparency = 1
        slot.Number.Size = UDim2.new(0, 14, 0, 14)
        slot.Number.Position = UDim2.new(0, 3, 0, 2)
        slot.Number.Text = index <= 9 and tostring(index) or (index == 10 and "0" or "")
        slot.Number.TextColor3 = Color3.fromRGB(180, 180, 180)
        slot.Number.TextSize = 11
        slot.Number.Font = Enum.Font.GothamBold
        slot.Number.TextXAlignment = Enum.TextXAlignment.Left
        slot.Number.Parent = slot.Frame
    end
    
    if isAdditional then
        local addIndicator = Instance.new("TextLabel")
        addIndicator.Name = "AddIndicator"
        addIndicator.BackgroundTransparency = 1
        addIndicator.Size = UDim2.new(0, 14, 0, 14)
        addIndicator.Position = UDim2.new(0, 3, 0, 2)
        addIndicator.Text = "★"
        addIndicator.TextColor3 = Color3.fromRGB(255, 200, 100)
        addIndicator.TextSize = 10
        addIndicator.Font = Enum.Font.GothamBold
        addIndicator.Parent = slot.Frame
    end
    
    slot.Button = Instance.new("TextButton")
    slot.Button.Name = "Button"
    slot.Button.BackgroundTransparency = 1
    slot.Button.Size = UDim2.new(1, 0, 1, 0)
    slot.Button.Text = ""
    slot.Button.Parent = slot.Frame
    
    slot.Button.MouseButton1Click:Connect(function()
        OnSlotClicked(slot)
    end)
    
    return slot
end

function OnSlotClicked(slot)
    if slot.Tool then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if EquippedSlot == slot then
                    hum:UnequipTools()
                    SetSlotEquipped(slot, false)
                    EquippedSlot = nil
                else
                    hum:EquipTool(slot.Tool)
                end
            end
        end
    end
end

function SetSlotEquipped(slot, equipped)
    if equipped then
        slot.Frame.BackgroundColor3 = CONFIG.COR_EQUIPADO
        slot.Stroke.Color = CONFIG.COR_EQUIPADO
        slot.Stroke.Thickness = 2
        slot.Stroke.Transparency = 0
    else
        slot.Frame.BackgroundColor3 = slot.IsAdditional and CONFIG.COR_ADICIONAL or CONFIG.COR_FUNDO
        slot.Stroke.Color = Color3.fromRGB(60, 60, 60)
        slot.Stroke.Thickness = 1
        slot.Stroke.Transparency = 0.5
    end
end

function RecreateSlots()
    -- Remove slots antigos
    for _, slot in ipairs(Slots) do
        if slot.Frame then
            slot.Frame:Destroy()
        end
    end
    Slots = {}
    
    -- Cria novos slots
    for i = 1, CONFIG.NUMERO_SLOTS do
        Slots[i] = CreateSlot(i, false)
    end
    
    -- Recria slots adicionais
    for i, slot in pairs(SlotsAdicionais) do
        if slot.Frame then
            slot.Frame:Destroy()
        end
    end
    SlotsAdicionais = {}
    
    for i, slotData in ipairs(CONFIG.SLOTS_ADICIONAIS) do
        CreateAdditionalSlotInHotbar(slotData, i)
    end
    
    UpdateHotbar()
end

function UpdateSlotSizes()
    for _, slot in ipairs(Slots) do
        slot.Frame.Size = UDim2.new(0, CONFIG.TAMANHO_SLOT, 0, CONFIG.TAMANHO_SLOT)
    end
    for _, slot in pairs(SlotsAdicionais) do
        if slot.Frame then
            slot.Frame.Size = UDim2.new(0, CONFIG.TAMANHO_SLOT, 0, CONFIG.TAMANHO_SLOT)
        end
    end
end

function UpdateSpacing()
    local layout = SlotContainer:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout.Padding = UDim.new(0, CONFIG.ESPACAMENTO)
    end
end

function UpdateSlotVisuals()
    local function updateSlot(slot)
        slot.Frame.BackgroundTransparency = CONFIG.TRANSPARENCIA
        
        local corner = slot.Frame:FindFirstChildOfClass("UICorner")
        if corner then
            corner.CornerRadius = UDim.new(0, CONFIG.CANTOS_ARREDONDADOS)
        end
        
        if slot.Number then
            slot.Number.Visible = CONFIG.MOSTRAR_NUMEROS
        end
    end
    
    for _, slot in ipairs(Slots) do
        updateSlot(slot)
    end
    for _, slot in pairs(SlotsAdicionais) do
        if slot.Frame then
            updateSlot(slot)
        end
    end
end

function UpdateHotbar()
    local char = Player.Character
    if not char then return end
    
    local backpack = Player:FindFirstChild("Backpack")
    local tools = {}
    
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    SlotsByTool = {}
    EquippedSlot = nil
    
    -- Atualiza slots normais
    for i, slot in ipairs(Slots) do
        local tool = tools[i]
        slot.Tool = tool
        
        if tool then
            slot.Icon.Image = tool.TextureId ~= "" and tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
            SlotsByTool[tool] = slot
            
            if tool.Parent == char then
                SetSlotEquipped(slot, true)
                EquippedSlot = slot
            else
                SetSlotEquipped(slot, false)
            end
        else
            slot.Icon.Image = ""
            SetSlotEquipped(slot, false)
        end
    end
    
    -- Atualiza slots adicionais
    for i, slot in pairs(SlotsAdicionais) do
        if slot.Tool then
            -- Verifica se a ferramenta ainda existe
            local toolExists = false
            for _, t in ipairs(tools) do
                if t.Name == slot.Tool.Name then
                    slot.Tool = t
                    toolExists = true
                    break
                end
            end
            
            if toolExists then
                slot.Icon.Image = slot.Tool.TextureId ~= "" and slot.Tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
                SlotsByTool[slot.Tool] = slot
                
                if slot.Tool.Parent == char then
                    SetSlotEquipped(slot, true)
                    EquippedSlot = slot
                else
                    SetSlotEquipped(slot, false)
                end
            else
                slot.Icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                SetSlotEquipped(slot, false)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TOGGLE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function ToggleSettings()
    CONFIG.MENU_ABERTO = not CONFIG.MENU_ABERTO
    
    if CONFIG.MENU_ABERTO then
        SettingsFrame.Visible = true
        Tween(SettingsFrame, {Position = UDim2.new(0.5, -160, 0.5, -240)}, 0.3)
    else
        Tween(SettingsFrame, {Position = UDim2.new(0.5, -160, 1.5, 0)}, 0.3)
        task.delay(0.3, function()
            SettingsFrame.Visible = false
        end)
    end
end

function ToggleHotbarVisibility()
    CONFIG.UI_VISIVEL = not CONFIG.UI_VISIVEL
    
    if CONFIG.UI_VISIVEL then
        Tween(HotbarFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
        HideButton.Image = "rbxassetid://6035047409" -- Olho aberto
    else
        Tween(HotbarFrame, {Position = UDim2.new(0, 0, 2, 0)}, 0.3)
        HideButton.Image = "rbxassetid://6035067857" -- Olho fechado
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONEXÕES DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════

function ConnectEvents()
    local char = Player.Character
    if not char then return end
    
    local backpack = Player:FindFirstChild("Backpack")
    
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    Connections = {}
    
    if backpack then
        table.insert(Connections, backpack.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                task.wait(0.1)
                UpdateHotbar()
            end
        end))
        
        table.insert(Connections, backpack.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then
                task.wait(0.1)
                UpdateHotbar()
            end
        end))
    end
    
    table.insert(Connections, char.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then
            local slot = SlotsByTool[c]
            if slot then
                if EquippedSlot and EquippedSlot ~= slot then
                    SetSlotEquipped(EquippedSlot, false)
                end
                SetSlotEquipped(slot, true)
                EquippedSlot = slot
            else
                UpdateHotbar()
            end
        end
    end))
    
    table.insert(Connections, char.ChildRemoved:Connect(function(c)
        if c:IsA("Tool") then
            local slot = SlotsByTool[c]
            if slot then
                SetSlotEquipped(slot, false)
                if EquippedSlot == slot then
                    EquippedSlot = nil
                end
            end
            task.wait(0.1)
            UpdateHotbar()
        end
    end))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ATALHOS DE TECLADO
-- ═══════════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyCode = input.KeyCode.Value
    
    if keyCode >= Enum.KeyCode.One.Value and keyCode <= Enum.KeyCode.Nine.Value then
        local slotIndex = keyCode - Enum.KeyCode.One.Value + 1
        if Slots[slotIndex] and Slots[slotIndex].Tool then
            OnSlotClicked(Slots[slotIndex])
        end
    elseif keyCode == Enum.KeyCode.Zero.Value then
        if Slots[10] and Slots[10].Tool then
            OnSlotClicked(Slots[10])
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════════

local function Initialize()
    DisableDefaultHotbar()
    CreateMainUI()
    CreateSettingsUI()
    
    -- Cria slots iniciais
    for i = 1, CONFIG.NUMERO_SLOTS do
        Slots[i] = CreateSlot(i, false)
    end
    
    -- Restaura slots adicionais salvos
    for i, slotData in ipairs(CONFIG.SLOTS_ADICIONAIS) do
        -- Tenta encontrar a ferramenta pelo nome
        local tools = GetAllTools()
        for _, tool in ipairs(tools) do
            if tool.Name == slotData.ToolName then
                slotData.Tool = tool
                break
            end
        end
        CreateAdditionalSlotInHotbar(slotData, i)
        CreateAdditionalSlotUI(slotData, i)
    end
    
    if Player.Character then
        ConnectEvents()
        UpdateHotbar()
    end
    
    Player.CharacterAdded:Connect(function()
        task.wait(1)
        ConnectEvents()
        UpdateHotbar()
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✅ Mobile Expand Slots v2.0 - AVANÇADO")
    print("📱 Slots configurados: " .. CONFIG.NUMERO_SLOTS)
    print("⚙️ Clique na engrenagem para configurar")
    print("👁️ Clique no olho para esconder/mostrar")
    print("═══════════════════════════════════════════════════")
end

Initialize()

-- Retorna referência para controle externo
if getgenv then
    getgenv().MobileExpandSlots = {
        Config = CONFIG,
        Slots = Slots,
        SlotsAdicionais = SlotsAdicionais,
        ToggleSettings = ToggleSettings,
        ToggleVisibility = ToggleHotbarVisibility,
        UpdateHotbar = UpdateHotbar,
        RecreateSlots = RecreateSlots
    }
end

return CONFIG
