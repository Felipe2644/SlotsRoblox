--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║           CUSTOM SLOTS SYSTEM - ROBLOX MOBILE                   ║
    ║                    Versão 1.0.0                                  ║
    ║         Sistema de Slots Adicionais Personalizáveis             ║
    ╚══════════════════════════════════════════════════════════════════╝
    
    Funcionalidades:
    - Criar slots dinâmicos (usuário escolhe quantidade)
    - A cada 10 slots, nova linha é adicionada acima
    - Menu de configuração completo
    - Backup de configurações por jogador
    - UI totalmente personalizável
    - Suporte a habilidades e itens do inventário
    - Compatível com executors mobile
--]]

-- ═══════════════════════════════════════════════════════════════════
-- SERVIÇOS E VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES PADRÃO
-- ═══════════════════════════════════════════════════════════════════

local DefaultConfig = {
    -- Configurações Gerais
    SlotCount = 0,
    MaxSlotsPerRow = 10,
    
    -- Aparência dos Slots
    SlotSize = UDim2.new(0, 50, 0, 50),
    SlotSpacing = 5,
    SlotCornerRadius = UDim.new(0, 8),
    SlotBackgroundColor = Color3.fromRGB(40, 40, 40),
    SlotBorderColor = Color3.fromRGB(80, 80, 80),
    SlotBorderSize = 2,
    SlotTransparency = 0.2,
    
    -- Cores de Estado
    SlotHoverColor = Color3.fromRGB(60, 60, 60),
    SlotActiveColor = Color3.fromRGB(80, 120, 200),
    SlotEmptyColor = Color3.fromRGB(30, 30, 30),
    
    -- Texto dos Slots
    SlotTextColor = Color3.fromRGB(255, 255, 255),
    SlotTextSize = 12,
    SlotTextFont = Enum.Font.GothamBold,
    ShowSlotNumbers = true,
    ShowAbilityNames = true,
    
    -- Posição do Container
    ContainerPosition = UDim2.new(0.5, 0, 1, -120),
    ContainerAnchorPoint = Vector2.new(0.5, 1),
    
    -- Menu de Configuração
    MenuPosition = UDim2.new(0, 10, 0.5, 0),
    MenuAnchorPoint = Vector2.new(0, 0.5),
    MenuMinimized = false,
    MenuVisible = true,
    
    -- Botão Minimizar
    MinimizeButtonPosition = UDim2.new(0, 10, 0, 10),
    
    -- UI Lock
    UILocked = false,
    
    -- Slots Data (habilidades/itens atribuídos)
    SlotsData = {}
}

-- ═══════════════════════════════════════════════════════════════════
-- SISTEMA DE BACKUP/SAVE
-- ═══════════════════════════════════════════════════════════════════

local SaveSystem = {}

function SaveSystem:GetSaveKey()
    return "CustomSlots_" .. Player.UserId
end

function SaveSystem:Save(config)
    local success, err = pcall(function()
        -- Converter UDim2 e outros tipos para formato serializável
        local saveData = {}
        for key, value in pairs(config) do
            if typeof(value) == "UDim2" then
                saveData[key] = {
                    Type = "UDim2",
                    XScale = value.X.Scale,
                    XOffset = value.X.Offset,
                    YScale = value.Y.Scale,
                    YOffset = value.Y.Offset
                }
            elseif typeof(value) == "Vector2" then
                saveData[key] = {
                    Type = "Vector2",
                    X = value.X,
                    Y = value.Y
                }
            elseif typeof(value) == "Color3" then
                saveData[key] = {
                    Type = "Color3",
                    R = value.R,
                    G = value.G,
                    B = value.B
                }
            elseif typeof(value) == "UDim" then
                saveData[key] = {
                    Type = "UDim",
                    Scale = value.Scale,
                    Offset = value.Offset
                }
            elseif typeof(value) == "EnumItem" then
                saveData[key] = {
                    Type = "Enum",
                    EnumType = tostring(value.EnumType),
                    Name = value.Name
                }
            else
                saveData[key] = value
            end
        end
        
        local jsonData = HttpService:JSONEncode(saveData)
        
        -- Tentar salvar usando diferentes métodos (compatibilidade com executors)
        if writefile then
            writefile(SaveSystem:GetSaveKey() .. ".json", jsonData)
        elseif syn and syn.write_file then
            syn.write_file(SaveSystem:GetSaveKey() .. ".json", jsonData)
        end
    end)
    
    if not success then
        warn("[CustomSlots] Erro ao salvar: " .. tostring(err))
    end
    
    return success
end

function SaveSystem:Load()
    local success, result = pcall(function()
        local jsonData = nil
        
        -- Tentar carregar usando diferentes métodos
        if readfile and isfile and isfile(SaveSystem:GetSaveKey() .. ".json") then
            jsonData = readfile(SaveSystem:GetSaveKey() .. ".json")
        elseif syn and syn.read_file then
            jsonData = syn.read_file(SaveSystem:GetSaveKey() .. ".json")
        end
        
        if jsonData then
            local saveData = HttpService:JSONDecode(jsonData)
            local config = {}
            
            -- Converter de volta para tipos Roblox
            for key, value in pairs(saveData) do
                if type(value) == "table" and value.Type then
                    if value.Type == "UDim2" then
                        config[key] = UDim2.new(value.XScale, value.XOffset, value.YScale, value.YOffset)
                    elseif value.Type == "Vector2" then
                        config[key] = Vector2.new(value.X, value.Y)
                    elseif value.Type == "Color3" then
                        config[key] = Color3.new(value.R, value.G, value.B)
                    elseif value.Type == "UDim" then
                        config[key] = UDim.new(value.Scale, value.Offset)
                    elseif value.Type == "Enum" then
                        config[key] = Enum[value.EnumType][value.Name]
                    else
                        config[key] = value
                    end
                else
                    config[key] = value
                end
            end
            
            return config
        end
        
        return nil
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- CLASSE PRINCIPAL - CUSTOM SLOTS SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local CustomSlotsSystem = {}
CustomSlotsSystem.__index = CustomSlotsSystem

function CustomSlotsSystem.new()
    local self = setmetatable({}, CustomSlotsSystem)
    
    -- Carregar configurações salvas ou usar padrão
    local savedConfig = SaveSystem:Load()
    if savedConfig then
        self.Config = savedConfig
        -- Mesclar com padrões para garantir todas as propriedades
        for key, value in pairs(DefaultConfig) do
            if self.Config[key] == nil then
                self.Config[key] = value
            end
        end
    else
        self.Config = {}
        for key, value in pairs(DefaultConfig) do
            self.Config[key] = value
        end
    end
    
    self.Slots = {}
    self.UIElements = {}
    self.Dragging = {}
    self.Connections = {}
    
    return self
end

-- ═══════════════════════════════════════════════════════════════════
-- CRIAÇÃO DA UI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateMainUI()
    -- Destruir UI existente se houver
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    -- ScreenGui Principal
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "CustomSlotsUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = PlayerGui
    
    -- Container Principal dos Slots
    self:CreateSlotsContainer()
    
    -- Menu de Configuração
    self:CreateConfigMenu()
    
    -- Botão de Minimizar/Menu
    self:CreateMinimizeButton()
    
    -- Aplicar estado inicial
    self:UpdateUIVisibility()
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTAINER DOS SLOTS
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateSlotsContainer()
    self.SlotsContainer = Instance.new("Frame")
    self.SlotsContainer.Name = "SlotsContainer"
    self.SlotsContainer.Size = UDim2.new(0, 0, 0, 0) -- Será calculado dinamicamente
    self.SlotsContainer.Position = self.Config.ContainerPosition
    self.SlotsContainer.AnchorPoint = self.Config.ContainerAnchorPoint
    self.SlotsContainer.BackgroundTransparency = 1
    self.SlotsContainer.Parent = self.ScreenGui
    
    self.UIElements.SlotsContainer = self.SlotsContainer
    
    -- Criar slots existentes
    self:RecreateAllSlots()
end

function CustomSlotsSystem:CalculateContainerSize()
    local slotCount = self.Config.SlotCount
    if slotCount == 0 then return UDim2.new(0, 0, 0, 0) end
    
    local maxPerRow = self.Config.MaxSlotsPerRow
    local slotWidth = self.Config.SlotSize.X.Offset
    local slotHeight = self.Config.SlotSize.Y.Offset
    local spacing = self.Config.SlotSpacing
    
    local rows = math.ceil(slotCount / maxPerRow)
    local cols = math.min(slotCount, maxPerRow)
    
    local totalWidth = (cols * slotWidth) + ((cols - 1) * spacing)
    local totalHeight = (rows * slotHeight) + ((rows - 1) * spacing)
    
    return UDim2.new(0, totalWidth, 0, totalHeight)
end

function CustomSlotsSystem:GetSlotPosition(index)
    local maxPerRow = self.Config.MaxSlotsPerRow
    local slotWidth = self.Config.SlotSize.X.Offset
    local slotHeight = self.Config.SlotSize.Y.Offset
    local spacing = self.Config.SlotSpacing
    
    -- Calcular linha e coluna (linhas de baixo para cima)
    local row = math.floor((index - 1) / maxPerRow)
    local col = (index - 1) % maxPerRow
    
    -- Calcular total de linhas para posicionar de baixo para cima
    local totalRows = math.ceil(self.Config.SlotCount / maxPerRow)
    local invertedRow = totalRows - 1 - row
    
    local x = col * (slotWidth + spacing)
    local y = invertedRow * (slotHeight + spacing)
    
    return UDim2.new(0, x, 0, y)
end

-- ═══════════════════════════════════════════════════════════════════
-- CRIAÇÃO E GERENCIAMENTO DE SLOTS
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateSlot(index)
    local slot = Instance.new("Frame")
    slot.Name = "Slot_" .. index
    slot.Size = self.Config.SlotSize
    slot.Position = self:GetSlotPosition(index)
    slot.BackgroundColor3 = self.Config.SlotBackgroundColor
    slot.BackgroundTransparency = self.Config.SlotTransparency
    slot.BorderSizePixel = 0
    slot.Parent = self.SlotsContainer
    
    -- Borda
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Config.SlotBorderColor
    stroke.Thickness = self.Config.SlotBorderSize
    stroke.Parent = slot
    
    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.SlotCornerRadius
    corner.Parent = slot
    
    -- Container para imagem/ícone
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, -8, 1, -20)
    imageContainer.Position = UDim2.new(0, 4, 0, 4)
    imageContainer.BackgroundTransparency = 1
    imageContainer.Parent = slot
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "Icon"
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = imageContainer
    
    -- Label do número do slot
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Name = "NumberLabel"
    numberLabel.Size = UDim2.new(0, 16, 0, 16)
    numberLabel.Position = UDim2.new(0, 2, 0, 2)
    numberLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    numberLabel.BackgroundTransparency = 0.5
    numberLabel.Text = tostring(index)
    numberLabel.TextColor3 = self.Config.SlotTextColor
    numberLabel.TextSize = 10
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.Visible = self.Config.ShowSlotNumbers
    numberLabel.Parent = slot
    
    local numberCorner = Instance.new("UICorner")
    numberCorner.CornerRadius = UDim.new(0, 4)
    numberCorner.Parent = numberLabel
    
    -- Label do nome da habilidade/item
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -4, 0, 14)
    nameLabel.Position = UDim2.new(0, 2, 1, -16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ""
    nameLabel.TextColor3 = self.Config.SlotTextColor
    nameLabel.TextSize = self.Config.SlotTextSize
    nameLabel.Font = self.Config.SlotTextFont
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Visible = self.Config.ShowAbilityNames
    nameLabel.Parent = slot
    
    -- Botão invisível para interação
    local button = Instance.new("TextButton")
    button.Name = "InteractionButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = slot
    
    -- Eventos do slot
    self:SetupSlotEvents(slot, index, button)
    
    -- Aplicar dados salvos se existirem
    local slotData = self.Config.SlotsData[tostring(index)]
    if slotData then
        self:UpdateSlotDisplay(slot, slotData)
    end
    
    self.Slots[index] = {
        Frame = slot,
        Stroke = stroke,
        Corner = corner,
        ImageLabel = imageLabel,
        NumberLabel = numberLabel,
        NameLabel = nameLabel,
        Button = button,
        Data = slotData or {}
    }
    
    return slot
end

function CustomSlotsSystem:SetupSlotEvents(slot, index, button)
    -- Hover effect
    button.MouseEnter:Connect(function()
        if not self.Config.UILocked then
            TweenService:Create(slot, TweenInfo.new(0.15), {
                BackgroundColor3 = self.Config.SlotHoverColor
            }):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        local slotData = self.Slots[index] and self.Slots[index].Data
        local targetColor = (slotData and slotData.AbilityName) 
            and self.Config.SlotBackgroundColor 
            or self.Config.SlotEmptyColor
        
        TweenService:Create(slot, TweenInfo.new(0.15), {
            BackgroundColor3 = targetColor
        }):Play()
    end)
    
    -- Click para ativar habilidade
    button.MouseButton1Click:Connect(function()
        self:ActivateSlot(index)
    end)
    
    -- Long press para configurar (mobile)
    -- Tempo necessário: 1.0 segundo de toque contínuo
    local pressTime = 0
    local pressing = false
    local longPressTime = 1.0 -- Tempo em segundos para ativar configuração
    
    button.MouseButton1Down:Connect(function()
        pressing = true
        pressTime = tick()
        
        delay(longPressTime, function()
            if pressing and (tick() - pressTime) >= longPressTime then
                self:OpenSlotConfigMenu(index)
            end
        end)
    end)
    
    button.MouseButton1Up:Connect(function()
        pressing = false
    end)
end

function CustomSlotsSystem:UpdateSlotDisplay(slot, data)
    local imageLabel = slot:FindFirstChild("ImageContainer"):FindFirstChild("Icon")
    local nameLabel = slot:FindFirstChild("NameLabel")
    
    if data.IconId then
        imageLabel.Image = "rbxassetid://" .. data.IconId
    elseif data.IconUrl then
        imageLabel.Image = data.IconUrl
    else
        imageLabel.Image = ""
    end
    
    if data.AbilityName then
        nameLabel.Text = data.AbilityName
        slot.BackgroundColor3 = self.Config.SlotBackgroundColor
    else
        nameLabel.Text = ""
        slot.BackgroundColor3 = self.Config.SlotEmptyColor
    end
end

function CustomSlotsSystem:ActivateSlot(index)
    local slotInfo = self.Slots[index]
    if not slotInfo or not slotInfo.Data or not slotInfo.Data.AbilityName then
        return
    end
    
    -- Efeito visual de ativação
    local slot = slotInfo.Frame
    TweenService:Create(slot, TweenInfo.new(0.1), {
        BackgroundColor3 = self.Config.SlotActiveColor
    }):Play()
    
    delay(0.2, function()
        TweenService:Create(slot, TweenInfo.new(0.1), {
            BackgroundColor3 = self.Config.SlotBackgroundColor
        }):Play()
    end)
    
    -- Executar ação da habilidade
    local data = slotInfo.Data
    
    if data.ActionType == "Tool" and data.ToolName then
        -- Equipar ferramenta
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        if backpack and character then
            local tool = backpack:FindFirstChild(data.ToolName) or character:FindFirstChild(data.ToolName)
            if tool and tool:IsA("Tool") then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:EquipTool(tool)
                end
            end
        end
    elseif data.ActionType == "RemoteEvent" and data.RemotePath then
        -- Disparar RemoteEvent
        local remote = game
        for _, part in ipairs(string.split(data.RemotePath, ".")) do
            remote = remote:FindFirstChild(part)
            if not remote then break end
        end
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(data.RemoteArgs or {})
        end
    elseif data.ActionType == "RemoteFunction" and data.RemotePath then
        -- Invocar RemoteFunction
        local remote = game
        for _, part in ipairs(string.split(data.RemotePath, ".")) do
            remote = remote:FindFirstChild(part)
            if not remote then break end
        end
        if remote and remote:IsA("RemoteFunction") then
            pcall(function()
                remote:InvokeServer(data.RemoteArgs or {})
            end)
        end
    elseif data.ActionType == "CustomFunction" and data.CustomCode then
        -- Executar código customizado
        pcall(function()
            local func = loadstring(data.CustomCode)
            if func then func() end
        end)
    elseif data.ActionType == "KeyPress" and data.KeyCode then
        -- Simular pressionamento de tecla
        local VirtualInputManager = game:GetService("VirtualInputManager")
        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, data.KeyCode, false, game)
                delay(0.1, function()
                    VirtualInputManager:SendKeyEvent(false, data.KeyCode, false, game)
                end)
            end)
        end
    end
    
    -- Callback customizado
    if self.OnSlotActivated then
        self.OnSlotActivated(index, data)
    end
end

function CustomSlotsSystem:RecreateAllSlots()
    -- Limpar slots existentes
    for _, slotInfo in pairs(self.Slots) do
        if slotInfo.Frame then
            slotInfo.Frame:Destroy()
        end
    end
    self.Slots = {}
    
    -- Atualizar tamanho do container
    self.SlotsContainer.Size = self:CalculateContainerSize()
    
    -- Criar novos slots
    for i = 1, self.Config.SlotCount do
        self:CreateSlot(i)
    end
end

function CustomSlotsSystem:AddSlots(count)
    local newCount = self.Config.SlotCount + count
    self.Config.SlotCount = newCount
    self:RecreateAllSlots()
    self:SaveConfig()
end

function CustomSlotsSystem:RemoveSlots(count)
    local newCount = math.max(0, self.Config.SlotCount - count)
    
    -- Limpar dados dos slots removidos
    for i = newCount + 1, self.Config.SlotCount do
        self.Config.SlotsData[tostring(i)] = nil
    end
    
    self.Config.SlotCount = newCount
    self:RecreateAllSlots()
    self:SaveConfig()
end

function CustomSlotsSystem:SetSlotCount(count)
    count = math.max(0, count)
    
    -- Limpar dados dos slots removidos se diminuindo
    if count < self.Config.SlotCount then
        for i = count + 1, self.Config.SlotCount do
            self.Config.SlotsData[tostring(i)] = nil
        end
    end
    
    self.Config.SlotCount = count
    self:RecreateAllSlots()
    self:SaveConfig()
end

-- ═══════════════════════════════════════════════════════════════════
-- MENU DE CONFIGURAÇÃO
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateConfigMenu()
    -- Frame principal do menu
    self.ConfigMenu = Instance.new("Frame")
    self.ConfigMenu.Name = "ConfigMenu"
    self.ConfigMenu.Size = UDim2.new(0, 320, 0, 500)
    self.ConfigMenu.Position = self.Config.MenuPosition
    self.ConfigMenu.AnchorPoint = self.Config.MenuAnchorPoint
    self.ConfigMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.ConfigMenu.BorderSizePixel = 0
    self.ConfigMenu.Visible = self.Config.MenuVisible and not self.Config.MenuMinimized
    self.ConfigMenu.Parent = self.ScreenGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = self.ConfigMenu
    
    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Color3.fromRGB(60, 60, 60)
    menuStroke.Thickness = 1
    menuStroke.Parent = self.ConfigMenu
    
    -- Header do menu
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    header.BorderSizePixel = 0
    header.Parent = self.ConfigMenu
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Corrigir cantos inferiores do header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚙️ Custom Slots"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    -- Botão fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:ToggleMenu(false)
    end)
    
    -- Scroll Frame para conteúdo
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Content"
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = self.ConfigMenu
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = scrollFrame
    
    -- Padding para o scroll
    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingBottom = UDim.new(0, 20)
    scrollPadding.Parent = scrollFrame
    
    -- Seções do menu
    self:CreateMenuSection(scrollFrame, "Quantidade de Slots", function(container)
        self:CreateSlotCountControls(container)
    end)
    
    self:CreateMenuSection(scrollFrame, "Aparência dos Slots", function(container)
        self:CreateAppearanceControls(container)
    end)
    
    self:CreateMenuSection(scrollFrame, "Posição e Layout", function(container)
        self:CreatePositionControls(container)
    end)
    
    self:CreateMenuSection(scrollFrame, "Configurar Slots", function(container)
        self:CreateSlotConfigControls(container)
    end)
    
    self:CreateMenuSection(scrollFrame, "Opções Gerais", function(container)
        self:CreateGeneralControls(container)
    end)
    
    -- Habilitar arrastar o menu
    self:MakeDraggable(self.ConfigMenu, header)
    
    self.UIElements.ConfigMenu = self.ConfigMenu
end

function CustomSlotsSystem:CreateMenuSection(parent, title, contentBuilder)
    local section = Instance.new("Frame")
    section.Name = title:gsub(" ", "")
    section.Size = UDim2.new(1, 0, 0, 0) -- Auto size
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionPadding = Instance.new("UIPadding")
    sectionPadding.PaddingTop = UDim.new(0, 10)
    sectionPadding.PaddingBottom = UDim.new(0, 10)
    sectionPadding.PaddingLeft = UDim.new(0, 10)
    sectionPadding.PaddingRight = UDim.new(0, 10)
    sectionPadding.Parent = section
    
    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.Parent = section
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SectionTitle"
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = section
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 0, 0)
    contentContainer.AutomaticSize = Enum.AutomaticSize.Y
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = section
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.Parent = contentContainer
    
    contentBuilder(contentContainer)
    
    return section
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTROLES DO MENU - QUANTIDADE DE SLOTS
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateSlotCountControls(container)
    -- Display atual
    local currentLabel = self:CreateLabel(container, "Slots atuais: " .. self.Config.SlotCount)
    currentLabel.Name = "CurrentSlotsLabel"
    
    -- Input para definir quantidade
    local inputRow = self:CreateRow(container)
    
    local inputLabel = self:CreateLabel(inputRow, "Definir quantidade:")
    inputLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "SlotCountInput"
    inputBox.Size = UDim2.new(0.3, 0, 0, 30)
    inputBox.Position = UDim2.new(0.5, 0, 0, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inputBox.Text = tostring(self.Config.SlotCount)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.TextSize = 14
    inputBox.Font = Enum.Font.Gotham
    inputBox.PlaceholderText = "0-100"
    inputBox.Parent = inputRow
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBox
    
    local applyButton = self:CreateButton(inputRow, "OK", function()
        local count = tonumber(inputBox.Text)
        if count and count >= 0 and count <= 100 then
            self:SetSlotCount(count)
            currentLabel.Text = "Slots atuais: " .. self.Config.SlotCount
        else
            inputBox.Text = tostring(self.Config.SlotCount)
        end
    end)
    applyButton.Size = UDim2.new(0.15, 0, 0, 30)
    applyButton.Position = UDim2.new(0.82, 0, 0, 0)
    
    -- Botões rápidos
    local quickRow = self:CreateRow(container)
    
    local add1 = self:CreateButton(quickRow, "+1", function()
        self:AddSlots(1)
        currentLabel.Text = "Slots atuais: " .. self.Config.SlotCount
        inputBox.Text = tostring(self.Config.SlotCount)
    end)
    add1.Size = UDim2.new(0.23, 0, 0, 30)
    add1.Position = UDim2.new(0, 0, 0, 0)
    
    local add5 = self:CreateButton(quickRow, "+5", function()
        self:AddSlots(5)
        currentLabel.Text = "Slots atuais: " .. self.Config.SlotCount
        inputBox.Text = tostring(self.Config.SlotCount)
    end)
    add5.Size = UDim2.new(0.23, 0, 0, 30)
    add5.Position = UDim2.new(0.25, 0, 0, 0)
    
    local rem1 = self:CreateButton(quickRow, "-1", function()
        self:RemoveSlots(1)
        currentLabel.Text = "Slots atuais: " .. self.Config.SlotCount
        inputBox.Text = tostring(self.Config.SlotCount)
    end)
    rem1.Size = UDim2.new(0.23, 0, 0, 30)
    rem1.Position = UDim2.new(0.5, 0, 0, 0)
    rem1.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
    
    local rem5 = self:CreateButton(quickRow, "-5", function()
        self:RemoveSlots(5)
        currentLabel.Text = "Slots atuais: " .. self.Config.SlotCount
        inputBox.Text = tostring(self.Config.SlotCount)
    end)
    rem5.Size = UDim2.new(0.23, 0, 0, 30)
    rem5.Position = UDim2.new(0.75, 0, 0, 0)
    rem5.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
    
    -- Slots por linha
    local perRowRow = self:CreateRow(container)
    
    local perRowLabel = self:CreateLabel(perRowRow, "Slots por linha:")
    perRowLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local perRowInput = Instance.new("TextBox")
    perRowInput.Name = "SlotsPerRowInput"
    perRowInput.Size = UDim2.new(0.3, 0, 0, 30)
    perRowInput.Position = UDim2.new(0.5, 0, 0, 0)
    perRowInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    perRowInput.Text = tostring(self.Config.MaxSlotsPerRow)
    perRowInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    perRowInput.TextSize = 14
    perRowInput.Font = Enum.Font.Gotham
    perRowInput.Parent = perRowRow
    
    local perRowCorner = Instance.new("UICorner")
    perRowCorner.CornerRadius = UDim.new(0, 6)
    perRowCorner.Parent = perRowInput
    
    local perRowApply = self:CreateButton(perRowRow, "OK", function()
        local count = tonumber(perRowInput.Text)
        if count and count >= 1 and count <= 20 then
            self.Config.MaxSlotsPerRow = count
            self:RecreateAllSlots()
            self:SaveConfig()
        else
            perRowInput.Text = tostring(self.Config.MaxSlotsPerRow)
        end
    end)
    perRowApply.Size = UDim2.new(0.15, 0, 0, 30)
    perRowApply.Position = UDim2.new(0.82, 0, 0, 0)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTROLES DO MENU - APARÊNCIA
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateAppearanceControls(container)
    -- Tamanho dos slots
    local sizeRow = self:CreateRow(container)
    local sizeLabel = self:CreateLabel(sizeRow, "Tamanho do slot:")
    sizeLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local sizeInput = Instance.new("TextBox")
    sizeInput.Size = UDim2.new(0.3, 0, 0, 30)
    sizeInput.Position = UDim2.new(0.5, 0, 0, 0)
    sizeInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sizeInput.Text = tostring(self.Config.SlotSize.X.Offset)
    sizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeInput.TextSize = 14
    sizeInput.Font = Enum.Font.Gotham
    sizeInput.Parent = sizeRow
    
    local sizeCorner = Instance.new("UICorner")
    sizeCorner.CornerRadius = UDim.new(0, 6)
    sizeCorner.Parent = sizeInput
    
    local sizeApply = self:CreateButton(sizeRow, "OK", function()
        local size = tonumber(sizeInput.Text)
        if size and size >= 30 and size <= 150 then
            self.Config.SlotSize = UDim2.new(0, size, 0, size)
            self:RecreateAllSlots()
            self:SaveConfig()
        end
    end)
    sizeApply.Size = UDim2.new(0.15, 0, 0, 30)
    sizeApply.Position = UDim2.new(0.82, 0, 0, 0)
    
    -- Espaçamento
    local spacingRow = self:CreateRow(container)
    local spacingLabel = self:CreateLabel(spacingRow, "Espaçamento:")
    spacingLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local spacingInput = Instance.new("TextBox")
    spacingInput.Size = UDim2.new(0.3, 0, 0, 30)
    spacingInput.Position = UDim2.new(0.5, 0, 0, 0)
    spacingInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    spacingInput.Text = tostring(self.Config.SlotSpacing)
    spacingInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    spacingInput.TextSize = 14
    spacingInput.Font = Enum.Font.Gotham
    spacingInput.Parent = spacingRow
    
    local spacingCorner = Instance.new("UICorner")
    spacingCorner.CornerRadius = UDim.new(0, 6)
    spacingCorner.Parent = spacingInput
    
    local spacingApply = self:CreateButton(spacingRow, "OK", function()
        local spacing = tonumber(spacingInput.Text)
        if spacing and spacing >= 0 and spacing <= 30 then
            self.Config.SlotSpacing = spacing
            self:RecreateAllSlots()
            self:SaveConfig()
        end
    end)
    spacingApply.Size = UDim2.new(0.15, 0, 0, 30)
    spacingApply.Position = UDim2.new(0.82, 0, 0, 0)
    
    -- Transparência
    local transpRow = self:CreateRow(container)
    local transpLabel = self:CreateLabel(transpRow, "Transparência:")
    transpLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local transpInput = Instance.new("TextBox")
    transpInput.Size = UDim2.new(0.3, 0, 0, 30)
    transpInput.Position = UDim2.new(0.5, 0, 0, 0)
    transpInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    transpInput.Text = tostring(self.Config.SlotTransparency)
    transpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    transpInput.TextSize = 14
    transpInput.Font = Enum.Font.Gotham
    transpInput.Parent = transpRow
    
    local transpCorner = Instance.new("UICorner")
    transpCorner.CornerRadius = UDim.new(0, 6)
    transpCorner.Parent = transpInput
    
    local transpApply = self:CreateButton(transpRow, "OK", function()
        local transp = tonumber(transpInput.Text)
        if transp and transp >= 0 and transp <= 1 then
            self.Config.SlotTransparency = transp
            self:UpdateAllSlotsAppearance()
            self:SaveConfig()
        end
    end)
    transpApply.Size = UDim2.new(0.15, 0, 0, 30)
    transpApply.Position = UDim2.new(0.82, 0, 0, 0)
    
    -- Cor de fundo
    self:CreateColorPicker(container, "Cor de fundo:", "SlotBackgroundColor", function(color)
        self.Config.SlotBackgroundColor = color
        self:UpdateAllSlotsAppearance()
        self:SaveConfig()
    end)
    
    -- Cor da borda
    self:CreateColorPicker(container, "Cor da borda:", "SlotBorderColor", function(color)
        self.Config.SlotBorderColor = color
        self:UpdateAllSlotsAppearance()
        self:SaveConfig()
    end)
    
    -- Arredondamento
    local radiusRow = self:CreateRow(container)
    local radiusLabel = self:CreateLabel(radiusRow, "Arredondamento:")
    radiusLabel.Size = UDim2.new(0.5, 0, 1, 0)
    
    local radiusInput = Instance.new("TextBox")
    radiusInput.Size = UDim2.new(0.3, 0, 0, 30)
    radiusInput.Position = UDim2.new(0.5, 0, 0, 0)
    radiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    radiusInput.Text = tostring(self.Config.SlotCornerRadius.Offset)
    radiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    radiusInput.TextSize = 14
    radiusInput.Font = Enum.Font.Gotham
    radiusInput.Parent = radiusRow
    
    local radiusCorner = Instance.new("UICorner")
    radiusCorner.CornerRadius = UDim.new(0, 6)
    radiusCorner.Parent = radiusInput
    
    local radiusApply = self:CreateButton(radiusRow, "OK", function()
        local radius = tonumber(radiusInput.Text)
        if radius and radius >= 0 and radius <= 25 then
            self.Config.SlotCornerRadius = UDim.new(0, radius)
            self:UpdateAllSlotsAppearance()
            self:SaveConfig()
        end
    end)
    radiusApply.Size = UDim2.new(0.15, 0, 0, 30)
    radiusApply.Position = UDim2.new(0.82, 0, 0, 0)
end

function CustomSlotsSystem:CreateColorPicker(container, labelText, configKey, callback)
    local row = self:CreateRow(container)
    local label = self:CreateLabel(row, labelText)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 30, 0, 30)
    colorPreview.Position = UDim2.new(0.5, 0, 0, 0)
    colorPreview.BackgroundColor3 = self.Config[configKey]
    colorPreview.Parent = row
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = colorPreview
    
    -- RGB inputs
    local rInput = Instance.new("TextBox")
    rInput.Size = UDim2.new(0, 40, 0, 30)
    rInput.Position = UDim2.new(0.5, 35, 0, 0)
    rInput.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
    rInput.Text = tostring(math.floor(self.Config[configKey].R * 255))
    rInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    rInput.TextSize = 12
    rInput.Font = Enum.Font.Gotham
    rInput.PlaceholderText = "R"
    rInput.Parent = row
    
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 4)
    rCorner.Parent = rInput
    
    local gInput = Instance.new("TextBox")
    gInput.Size = UDim2.new(0, 40, 0, 30)
    gInput.Position = UDim2.new(0.5, 80, 0, 0)
    gInput.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    gInput.Text = tostring(math.floor(self.Config[configKey].G * 255))
    gInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    gInput.TextSize = 12
    gInput.Font = Enum.Font.Gotham
    gInput.PlaceholderText = "G"
    gInput.Parent = row
    
    local gCorner = Instance.new("UICorner")
    gCorner.CornerRadius = UDim.new(0, 4)
    gCorner.Parent = gInput
    
    local bInput = Instance.new("TextBox")
    bInput.Size = UDim2.new(0, 40, 0, 30)
    bInput.Position = UDim2.new(0.5, 125, 0, 0)
    bInput.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    bInput.Text = tostring(math.floor(self.Config[configKey].B * 255))
    bInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    bInput.TextSize = 12
    bInput.Font = Enum.Font.Gotham
    bInput.PlaceholderText = "B"
    bInput.Parent = row
    
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = bInput
    
    local function updateColor()
        local r = tonumber(rInput.Text) or 0
        local g = tonumber(gInput.Text) or 0
        local b = tonumber(bInput.Text) or 0
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b = math.clamp(b, 0, 255)
        local color = Color3.fromRGB(r, g, b)
        colorPreview.BackgroundColor3 = color
        callback(color)
    end
    
    rInput.FocusLost:Connect(updateColor)
    gInput.FocusLost:Connect(updateColor)
    bInput.FocusLost:Connect(updateColor)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTROLES DO MENU - POSIÇÃO
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreatePositionControls(container)
    -- Botão para mover container de slots
    local moveBtn = self:CreateButton(container, "📍 Mover Slots (Arrastar)", function()
        self:EnableDragMode("SlotsContainer")
    end)
    moveBtn.Size = UDim2.new(1, 0, 0, 35)
    
    -- Presets de posição
    local presetsLabel = self:CreateLabel(container, "Posições predefinidas:")
    
    local presetsRow = self:CreateRow(container)
    
    local bottomCenter = self:CreateButton(presetsRow, "Baixo", function()
        self.Config.ContainerPosition = UDim2.new(0.5, 0, 1, -120)
        self.Config.ContainerAnchorPoint = Vector2.new(0.5, 1)
        self:UpdateContainerPosition()
        self:SaveConfig()
    end)
    bottomCenter.Size = UDim2.new(0.32, 0, 0, 30)
    bottomCenter.Position = UDim2.new(0, 0, 0, 0)
    
    local topCenter = self:CreateButton(presetsRow, "Cima", function()
        self.Config.ContainerPosition = UDim2.new(0.5, 0, 0, 120)
        self.Config.ContainerAnchorPoint = Vector2.new(0.5, 0)
        self:UpdateContainerPosition()
        self:SaveConfig()
    end)
    topCenter.Size = UDim2.new(0.32, 0, 0, 30)
    topCenter.Position = UDim2.new(0.34, 0, 0, 0)
    
    local leftSide = self:CreateButton(presetsRow, "Esquerda", function()
        self.Config.ContainerPosition = UDim2.new(0, 10, 0.5, 0)
        self.Config.ContainerAnchorPoint = Vector2.new(0, 0.5)
        self:UpdateContainerPosition()
        self:SaveConfig()
    end)
    leftSide.Size = UDim2.new(0.32, 0, 0, 30)
    leftSide.Position = UDim2.new(0.68, 0, 0, 0)
    
    local presetsRow2 = self:CreateRow(container)
    
    local rightSide = self:CreateButton(presetsRow2, "Direita", function()
        self.Config.ContainerPosition = UDim2.new(1, -10, 0.5, 0)
        self.Config.ContainerAnchorPoint = Vector2.new(1, 0.5)
        self:UpdateContainerPosition()
        self:SaveConfig()
    end)
    rightSide.Size = UDim2.new(0.48, 0, 0, 30)
    rightSide.Position = UDim2.new(0, 0, 0, 0)
    
    local resetPos = self:CreateButton(presetsRow2, "Resetar", function()
        self.Config.ContainerPosition = DefaultConfig.ContainerPosition
        self.Config.ContainerAnchorPoint = DefaultConfig.ContainerAnchorPoint
        self:UpdateContainerPosition()
        self:SaveConfig()
    end)
    resetPos.Size = UDim2.new(0.48, 0, 0, 30)
    resetPos.Position = UDim2.new(0.52, 0, 0, 0)
    resetPos.BackgroundColor3 = Color3.fromRGB(180, 100, 60)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTROLES DO MENU - CONFIGURAR SLOTS INDIVIDUAIS
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateSlotConfigControls(container)
    local infoLabel = self:CreateLabel(container, "Toque longo em um slot para configurá-lo, ou selecione abaixo:")
    infoLabel.TextWrapped = true
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    
    -- Seletor de slot
    local selectRow = self:CreateRow(container)
    local selectLabel = self:CreateLabel(selectRow, "Slot nº:")
    selectLabel.Size = UDim2.new(0.3, 0, 1, 0)
    
    local slotSelector = Instance.new("TextBox")
    slotSelector.Name = "SlotSelector"
    slotSelector.Size = UDim2.new(0.3, 0, 0, 30)
    slotSelector.Position = UDim2.new(0.3, 0, 0, 0)
    slotSelector.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slotSelector.Text = "1"
    slotSelector.TextColor3 = Color3.fromRGB(255, 255, 255)
    slotSelector.TextSize = 14
    slotSelector.Font = Enum.Font.Gotham
    slotSelector.Parent = selectRow
    
    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = UDim.new(0, 6)
    selectorCorner.Parent = slotSelector
    
    local configSlotBtn = self:CreateButton(selectRow, "Configurar", function()
        local slotNum = tonumber(slotSelector.Text)
        if slotNum and slotNum >= 1 and slotNum <= self.Config.SlotCount then
            self:OpenSlotConfigMenu(slotNum)
        end
    end)
    configSlotBtn.Size = UDim2.new(0.35, 0, 0, 30)
    configSlotBtn.Position = UDim2.new(0.62, 0, 0, 0)
    
    -- Limpar todos os slots
    local clearAllBtn = self:CreateButton(container, "🗑️ Limpar Todos os Slots", function()
        self.Config.SlotsData = {}
        for _, slotInfo in pairs(self.Slots) do
            slotInfo.Data = {}
            self:UpdateSlotDisplay(slotInfo.Frame, {})
        end
        self:SaveConfig()
    end)
    clearAllBtn.Size = UDim2.new(1, 0, 0, 35)
    clearAllBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTROLES DO MENU - OPÇÕES GERAIS
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateGeneralControls(container)
    -- Toggle mostrar números
    self:CreateToggle(container, "Mostrar números dos slots", self.Config.ShowSlotNumbers, function(enabled)
        self.Config.ShowSlotNumbers = enabled
        for _, slotInfo in pairs(self.Slots) do
            slotInfo.NumberLabel.Visible = enabled
        end
        self:SaveConfig()
    end)
    
    -- Toggle mostrar nomes
    self:CreateToggle(container, "Mostrar nomes das habilidades", self.Config.ShowAbilityNames, function(enabled)
        self.Config.ShowAbilityNames = enabled
        for _, slotInfo in pairs(self.Slots) do
            slotInfo.NameLabel.Visible = enabled
        end
        self:SaveConfig()
    end)
    
    -- Toggle fixar UI
    self:CreateToggle(container, "🔒 Fixar UI (impedir movimento)", self.Config.UILocked, function(enabled)
        self.Config.UILocked = enabled
        self:SaveConfig()
    end)
    
    -- Botões de backup
    local backupRow = self:CreateRow(container)
    
    local exportBtn = self:CreateButton(backupRow, "📤 Exportar Config", function()
        self:ExportConfig()
    end)
    exportBtn.Size = UDim2.new(0.48, 0, 0, 35)
    exportBtn.Position = UDim2.new(0, 0, 0, 0)
    
    local importBtn = self:CreateButton(backupRow, "📥 Importar Config", function()
        self:ImportConfig()
    end)
    importBtn.Size = UDim2.new(0.48, 0, 0, 35)
    importBtn.Position = UDim2.new(0.52, 0, 0, 0)
    
    -- Reset total
    local resetBtn = self:CreateButton(container, "⚠️ Resetar Tudo", function()
        self.Config = {}
        for key, value in pairs(DefaultConfig) do
            self.Config[key] = value
        end
        self:CreateMainUI()
        self:SaveConfig()
    end)
    resetBtn.Size = UDim2.new(1, 0, 0, 35)
    resetBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end

-- ═══════════════════════════════════════════════════════════════════
-- MENU DE CONFIGURAÇÃO DE SLOT INDIVIDUAL
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:OpenSlotConfigMenu(slotIndex)
    -- Remover menu existente se houver
    if self.SlotConfigMenu then
        self.SlotConfigMenu:Destroy()
    end
    
    local slotData = self.Config.SlotsData[tostring(slotIndex)] or {}
    
    -- Frame do menu
    self.SlotConfigMenu = Instance.new("Frame")
    self.SlotConfigMenu.Name = "SlotConfigMenu"
    self.SlotConfigMenu.Size = UDim2.new(0, 300, 0, 400)
    self.SlotConfigMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.SlotConfigMenu.AnchorPoint = Vector2.new(0.5, 0.5)
    self.SlotConfigMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.SlotConfigMenu.Parent = self.ScreenGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = self.SlotConfigMenu
    
    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Color3.fromRGB(80, 120, 200)
    menuStroke.Thickness = 2
    menuStroke.Parent = self.SlotConfigMenu
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    header.BorderSizePixel = 0
    header.Parent = self.SlotConfigMenu
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ Configurar Slot " .. slotIndex
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self.SlotConfigMenu:Destroy()
        self.SlotConfigMenu = nil
    end)
    
    -- Conteúdo
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 6
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = self.SlotConfigMenu
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingBottom = UDim.new(0, 20)
    contentPadding.Parent = content
    
    -- Nome da habilidade
    local nameLabel = self:CreateLabel(content, "Nome da habilidade/item:")
    local nameInput = Instance.new("TextBox")
    nameInput.Size = UDim2.new(1, 0, 0, 35)
    nameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    nameInput.Text = slotData.AbilityName or ""
    nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameInput.TextSize = 14
    nameInput.Font = Enum.Font.Gotham
    nameInput.PlaceholderText = "Ex: Fireball, Sword, etc."
    nameInput.Parent = content
    
    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 6)
    nameCorner.Parent = nameInput
    
    -- ID do ícone
    local iconLabel = self:CreateLabel(content, "ID do ícone (Roblox Asset ID):")
    local iconInput = Instance.new("TextBox")
    iconInput.Size = UDim2.new(1, 0, 0, 35)
    iconInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    iconInput.Text = slotData.IconId or ""
    iconInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconInput.TextSize = 14
    iconInput.Font = Enum.Font.Gotham
    iconInput.PlaceholderText = "Ex: 12345678"
    iconInput.Parent = content
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconInput
    
    -- Tipo de ação
    local actionLabel = self:CreateLabel(content, "Tipo de ação:")
    
    local actionTypes = {"Tool", "RemoteEvent", "RemoteFunction", "KeyPress", "CustomFunction"}
    local currentAction = slotData.ActionType or "Tool"
    
    local actionDropdown = Instance.new("Frame")
    actionDropdown.Size = UDim2.new(1, 0, 0, 35)
    actionDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    actionDropdown.Parent = content
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 6)
    actionCorner.Parent = actionDropdown
    
    local actionText = Instance.new("TextLabel")
    actionText.Size = UDim2.new(1, -40, 1, 0)
    actionText.Position = UDim2.new(0, 10, 0, 0)
    actionText.BackgroundTransparency = 1
    actionText.Text = currentAction
    actionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionText.TextSize = 14
    actionText.Font = Enum.Font.Gotham
    actionText.TextXAlignment = Enum.TextXAlignment.Left
    actionText.Parent = actionDropdown
    
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(0, 30, 0, 30)
    actionBtn.Position = UDim2.new(1, -32, 0, 2)
    actionBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    actionBtn.Text = "▼"
    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.TextSize = 12
    actionBtn.Parent = actionDropdown
    
    local actionBtnCorner = Instance.new("UICorner")
    actionBtnCorner.CornerRadius = UDim.new(0, 4)
    actionBtnCorner.Parent = actionBtn
    
    local actionIndex = 1
    for i, v in ipairs(actionTypes) do
        if v == currentAction then actionIndex = i break end
    end
    
    actionBtn.MouseButton1Click:Connect(function()
        actionIndex = actionIndex % #actionTypes + 1
        actionText.Text = actionTypes[actionIndex]
    end)
    
    -- Campo específico baseado no tipo
    local specificLabel = self:CreateLabel(content, "Valor específico:")
    local specificInput = Instance.new("TextBox")
    specificInput.Size = UDim2.new(1, 0, 0, 35)
    specificInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    specificInput.Text = slotData.ToolName or slotData.RemotePath or slotData.KeyCode or slotData.CustomCode or ""
    specificInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    specificInput.TextSize = 14
    specificInput.Font = Enum.Font.Gotham
    specificInput.PlaceholderText = "Nome da tool / Caminho do remote / Tecla / Código"
    specificInput.Parent = content
    
    local specificCorner = Instance.new("UICorner")
    specificCorner.CornerRadius = UDim.new(0, 6)
    specificCorner.Parent = specificInput
    
    -- Botão detectar ferramentas do inventário
    local detectBtn = self:CreateButton(content, "🔍 Detectar Tools do Inventário", function()
        self:ShowToolSelector(slotIndex, nameInput, specificInput)
    end)
    detectBtn.Size = UDim2.new(1, 0, 0, 35)
    
    -- Botão salvar
    local saveBtn = self:CreateButton(content, "💾 Salvar Configuração", function()
        local newData = {
            AbilityName = nameInput.Text ~= "" and nameInput.Text or nil,
            IconId = iconInput.Text ~= "" and iconInput.Text or nil,
            ActionType = actionText.Text
        }
        
        if actionText.Text == "Tool" then
            newData.ToolName = specificInput.Text
        elseif actionText.Text == "RemoteEvent" or actionText.Text == "RemoteFunction" then
            newData.RemotePath = specificInput.Text
        elseif actionText.Text == "KeyPress" then
            newData.KeyCode = specificInput.Text
        elseif actionText.Text == "CustomFunction" then
            newData.CustomCode = specificInput.Text
        end
        
        self.Config.SlotsData[tostring(slotIndex)] = newData
        
        if self.Slots[slotIndex] then
            self.Slots[slotIndex].Data = newData
            self:UpdateSlotDisplay(self.Slots[slotIndex].Frame, newData)
        end
        
        self:SaveConfig()
        self.SlotConfigMenu:Destroy()
        self.SlotConfigMenu = nil
    end)
    saveBtn.Size = UDim2.new(1, 0, 0, 40)
    saveBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
    
    -- Botão limpar
    local clearBtn = self:CreateButton(content, "🗑️ Limpar Slot", function()
        self.Config.SlotsData[tostring(slotIndex)] = nil
        
        if self.Slots[slotIndex] then
            self.Slots[slotIndex].Data = {}
            self:UpdateSlotDisplay(self.Slots[slotIndex].Frame, {})
        end
        
        self:SaveConfig()
        self.SlotConfigMenu:Destroy()
        self.SlotConfigMenu = nil
    end)
    clearBtn.Size = UDim2.new(1, 0, 0, 35)
    clearBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    
    -- Tornar arrastável
    self:MakeDraggable(self.SlotConfigMenu, header)
end

function CustomSlotsSystem:ShowToolSelector(slotIndex, nameInput, specificInput)
    local backpack = Player:FindFirstChild("Backpack")
    local character = Player.Character
    
    local tools = {}
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if #tools == 0 then
        return
    end
    
    -- Criar seletor
    local selector = Instance.new("Frame")
    selector.Name = "ToolSelector"
    selector.Size = UDim2.new(0, 250, 0, math.min(#tools * 35 + 10, 200))
    selector.Position = UDim2.new(0.5, 0, 0.5, 0)
    selector.AnchorPoint = Vector2.new(0.5, 0.5)
    selector.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    selector.Parent = self.ScreenGui
    
    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = UDim.new(0, 8)
    selectorCorner.Parent = selector
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -10)
    scroll.Position = UDim2.new(0, 5, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, #tools * 35)
    scroll.Parent = selector
    
    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.Padding = UDim.new(0, 5)
    scrollLayout.Parent = scroll
    
    for _, tool in ipairs(tools) do
        local toolBtn = Instance.new("TextButton")
        toolBtn.Size = UDim2.new(1, 0, 0, 30)
        toolBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toolBtn.Text = tool.Name
        toolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toolBtn.TextSize = 14
        toolBtn.Font = Enum.Font.Gotham
        toolBtn.Parent = scroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = toolBtn
        
        toolBtn.MouseButton1Click:Connect(function()
            nameInput.Text = tool.Name
            specificInput.Text = tool.Name
            selector:Destroy()
        end)
    end
    
    -- Fechar ao clicar fora
    local closeArea = Instance.new("TextButton")
    closeArea.Size = UDim2.new(1, 0, 1, 0)
    closeArea.BackgroundTransparency = 0.8
    closeArea.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    closeArea.Text = ""
    closeArea.ZIndex = selector.ZIndex - 1
    closeArea.Parent = self.ScreenGui
    
    closeArea.MouseButton1Click:Connect(function()
        selector:Destroy()
        closeArea:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- BOTÃO MINIMIZAR
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateMinimizeButton()
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Name = "MinimizeButton"
    self.MinimizeButton.Size = UDim2.new(0, 50, 0, 50)
    self.MinimizeButton.Position = self.Config.MinimizeButtonPosition
    self.MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    self.MinimizeButton.Text = "⚙️"
    self.MinimizeButton.TextSize = 24
    self.MinimizeButton.Parent = self.ScreenGui
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 25)
    btnCorner.Parent = self.MinimizeButton
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(100, 150, 255)
    btnStroke.Thickness = 2
    btnStroke.Parent = self.MinimizeButton
    
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:ToggleMenu(not self.Config.MenuVisible)
    end)
    
    -- Tornar arrastável
    self:MakeDraggable(self.MinimizeButton, self.MinimizeButton, function(newPos)
        self.Config.MinimizeButtonPosition = newPos
        self:SaveConfig()
    end)
    
    self.UIElements.MinimizeButton = self.MinimizeButton
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES DE UI
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:CreateLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function CustomSlotsSystem:CreateRow(parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundTransparency = 1
    row.Parent = parent
    return row
end

function CustomSlotsSystem:CreateButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.new(
                math.min(button.BackgroundColor3.R + 0.1, 1),
                math.min(button.BackgroundColor3.G + 0.1, 1),
                math.min(button.BackgroundColor3.B + 0.1, 1)
            )
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(60, 100, 180)
        }):Play()
    end)
    
    return button
end

function CustomSlotsSystem:CreateToggle(parent, text, initialState, callback)
    local row = self:CreateRow(parent)
    
    local label = self:CreateLabel(row, text)
    label.Size = UDim2.new(0.75, 0, 1, 0)
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 50, 0, 26)
    toggleFrame.Position = UDim2.new(0.78, 0, 0.5, -13)
    toggleFrame.BackgroundColor3 = initialState and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(80, 80, 80)
    toggleFrame.Parent = row
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 13)
    toggleCorner.Parent = toggleFrame
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 22, 0, 22)
    toggleCircle.Position = initialState and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.Parent = toggleFrame
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 11)
    circleCorner.Parent = toggleCircle
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.Parent = toggleFrame
    
    local enabled = initialState
    
    toggleButton.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(80, 80, 80)
        }):Play()
        
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
        }):Play()
        
        callback(enabled)
    end)
    
    return row
end

-- ═══════════════════════════════════════════════════════════════════
-- SISTEMA DE DRAG
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:MakeDraggable(frame, handle, onDragEnd)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    handle = handle or frame
    
    handle.InputBegan:Connect(function(input)
        if self.Config.UILocked then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if onDragEnd then
                onDragEnd(frame.Position)
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function CustomSlotsSystem:EnableDragMode(elementName)
    if self.Config.UILocked then return end
    
    local element = self.UIElements[elementName]
    if not element then return end
    
    -- Visual feedback
    local originalColor = element.BackgroundColor3
    element.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local connection1, connection2, connection3
    
    connection1 = element.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = element.Position
        end
    end)
    
    connection2 = element.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            
            -- Salvar nova posição
            if elementName == "SlotsContainer" then
                self.Config.ContainerPosition = element.Position
            end
            self:SaveConfig()
            
            -- Restaurar cor e desconectar
            element.BackgroundColor3 = originalColor
            connection1:Disconnect()
            connection2:Disconnect()
            connection3:Disconnect()
        end
    end)
    
    connection3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            element.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNÇÕES DE ATUALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:UpdateAllSlotsAppearance()
    for _, slotInfo in pairs(self.Slots) do
        local slot = slotInfo.Frame
        slot.BackgroundColor3 = (slotInfo.Data and slotInfo.Data.AbilityName) 
            and self.Config.SlotBackgroundColor 
            or self.Config.SlotEmptyColor
        slot.BackgroundTransparency = self.Config.SlotTransparency
        
        slotInfo.Stroke.Color = self.Config.SlotBorderColor
        slotInfo.Stroke.Thickness = self.Config.SlotBorderSize
        slotInfo.Corner.CornerRadius = self.Config.SlotCornerRadius
        
        slotInfo.NumberLabel.Visible = self.Config.ShowSlotNumbers
        slotInfo.NameLabel.Visible = self.Config.ShowAbilityNames
    end
end

function CustomSlotsSystem:UpdateContainerPosition()
    self.SlotsContainer.Position = self.Config.ContainerPosition
    self.SlotsContainer.AnchorPoint = self.Config.ContainerAnchorPoint
end

function CustomSlotsSystem:UpdateUIVisibility()
    if self.ConfigMenu then
        self.ConfigMenu.Visible = self.Config.MenuVisible and not self.Config.MenuMinimized
    end
end

function CustomSlotsSystem:ToggleMenu(visible)
    self.Config.MenuVisible = visible
    self:UpdateUIVisibility()
    self:SaveConfig()
end

-- ═══════════════════════════════════════════════════════════════════
-- BACKUP E EXPORTAÇÃO
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:SaveConfig()
    SaveSystem:Save(self.Config)
end

function CustomSlotsSystem:ExportConfig()
    local success, jsonData = pcall(function()
        return HttpService:JSONEncode(self.Config)
    end)
    
    if success then
        if setclipboard then
            setclipboard(jsonData)
            print("[CustomSlots] Configuração copiada para a área de transferência!")
        else
            print("[CustomSlots] Configuração exportada:")
            print(jsonData)
        end
    end
end

function CustomSlotsSystem:ImportConfig()
    -- Criar diálogo de importação
    local importDialog = Instance.new("Frame")
    importDialog.Name = "ImportDialog"
    importDialog.Size = UDim2.new(0, 300, 0, 200)
    importDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    importDialog.AnchorPoint = Vector2.new(0.5, 0.5)
    importDialog.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    importDialog.Parent = self.ScreenGui
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = importDialog
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "📥 Importar Configuração"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = importDialog
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 80)
    inputBox.Position = UDim2.new(0, 10, 0, 45)
    inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inputBox.Text = ""
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.TextSize = 12
    inputBox.Font = Enum.Font.Gotham
    inputBox.PlaceholderText = "Cole o JSON aqui..."
    inputBox.TextWrapped = true
    inputBox.MultiLine = true
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = importDialog
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBox
    
    local importBtn = self:CreateButton(importDialog, "Importar", function()
        local success, newConfig = pcall(function()
            return HttpService:JSONDecode(inputBox.Text)
        end)
        
        if success and newConfig then
            self.Config = newConfig
            self:CreateMainUI()
            self:SaveConfig()
            print("[CustomSlots] Configuração importada com sucesso!")
        else
            warn("[CustomSlots] Erro ao importar configuração")
        end
        
        importDialog:Destroy()
    end)
    importBtn.Size = UDim2.new(0.45, 0, 0, 35)
    importBtn.Position = UDim2.new(0.025, 0, 1, -45)
    
    local cancelBtn = self:CreateButton(importDialog, "Cancelar", function()
        importDialog:Destroy()
    end)
    cancelBtn.Size = UDim2.new(0.45, 0, 0, 35)
    cancelBtn.Position = UDim2.new(0.525, 0, 1, -45)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
end

-- ═══════════════════════════════════════════════════════════════════
-- DESTRUTOR
-- ═══════════════════════════════════════════════════════════════════

function CustomSlotsSystem:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════

local function Initialize()
    -- Remover instância anterior se existir
    if _G.CustomSlotsSystem then
        _G.CustomSlotsSystem:Destroy()
    end
    
    -- Criar nova instância
    local system = CustomSlotsSystem.new()
    system:CreateMainUI()
    
    -- Armazenar globalmente para acesso externo
    _G.CustomSlotsSystem = system
    
    print("═══════════════════════════════════════════════════")
    print("   CUSTOM SLOTS SYSTEM - Carregado com sucesso!")
    print("═══════════════════════════════════════════════════")
    print("   • Clique no botão ⚙️ para abrir o menu")
    print("   • Adicione slots e configure habilidades")
    print("   • Toque longo em um slot para configurá-lo")
    print("   • Suas configurações são salvas automaticamente")
    print("═══════════════════════════════════════════════════")
    
    return system
end

-- Executar
return Initialize()
