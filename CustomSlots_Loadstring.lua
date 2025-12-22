--[[
    CUSTOM SLOTS SYSTEM - VERSÃO LOADSTRING
    Para usar em executores mobile, copie este código ou use:
    loadstring(game:HttpGet("URL_DO_SCRIPT"))()
--]]

-- Verificar se já está carregado
if getgenv and getgenv().CustomSlotsLoaded then
    warn("Custom Slots já está carregado!")
    return
end
if getgenv then getgenv().CustomSlotsLoaded = true end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Configurações
local Config = {
    SlotCount = 4, SlotSize = 60, SlotSpacing = 10, SlotCornerRadius = 12,
    PositionX = 0.5, PositionY = 0.85, Orientation = "Horizontal",
    SlotColor = Color3.fromRGB(40, 40, 50), SlotBorderColor = Color3.fromRGB(80, 80, 100),
    SlotHoverColor = Color3.fromRGB(60, 60, 80), SlotActiveColor = Color3.fromRGB(100, 150, 255),
    BackgroundTransparency = 0.3
}

local SlotData = {}
local MainGui, SlotsContainer, ConfigPanel, ToggleButton

-- Utilitários
local function Tween(obj, props, dur)
    return TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function SaveConfig()
    if writefile then pcall(function() writefile("CustomSlotsConfig.json", HttpService:JSONEncode(Config)) end) end
end

local function LoadConfig()
    if readfile and isfile then
        pcall(function()
            if isfile("CustomSlotsConfig.json") then
                for k, v in pairs(HttpService:JSONDecode(readfile("CustomSlotsConfig.json"))) do Config[k] = v end
            end
        end)
    end
end

-- UI Principal
local function CreateMainUI()
    if PlayerGui:FindFirstChild("CustomSlotsUI") then PlayerGui:FindFirstChild("CustomSlotsUI"):Destroy() end
    
    MainGui = Instance.new("ScreenGui")
    MainGui.Name = "CustomSlotsUI"
    MainGui.ResetOnSpawn = false
    MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainGui.DisplayOrder = 999
    pcall(function() MainGui.Parent = game:GetService("CoreGui") end)
    if not MainGui.Parent then MainGui.Parent = PlayerGui end
    
    SlotsContainer = Instance.new("Frame")
    SlotsContainer.Name = "SlotsContainer"
    SlotsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    SlotsContainer.BackgroundTransparency = Config.BackgroundTransparency
    SlotsContainer.BorderSizePixel = 0
    SlotsContainer.Position = UDim2.new(Config.PositionX, 0, Config.PositionY, 0)
    SlotsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    SlotsContainer.Parent = MainGui
    
    local corner = Instance.new("UICorner", SlotsContainer)
    corner.CornerRadius = UDim.new(0, 16)
    
    local stroke = Instance.new("UIStroke", SlotsContainer)
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    
    -- Botão Config
    ToggleButton = Instance.new("ImageButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 36, 0, 36)
    ToggleButton.Position = UDim2.new(1, -40, 0, 4)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    ToggleButton.BackgroundTransparency = 0.3
    ToggleButton.Image = "rbxassetid://3926305904"
    ToggleButton.ImageRectOffset = Vector2.new(324, 124)
    ToggleButton.ImageRectSize = Vector2.new(36, 36)
    ToggleButton.ImageColor3 = Color3.fromRGB(200, 200, 220)
    ToggleButton.Parent = SlotsContainer
    Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
    
    -- Botão Esconder
    local HideButton = Instance.new("ImageButton")
    HideButton.Name = "HideButton"
    HideButton.Size = UDim2.new(0, 36, 0, 36)
    HideButton.Position = UDim2.new(0, 4, 0, 4)
    HideButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    HideButton.BackgroundTransparency = 0.3
    HideButton.Image = "rbxassetid://3926305904"
    HideButton.ImageRectOffset = Vector2.new(764, 244)
    HideButton.ImageRectSize = Vector2.new(36, 36)
    HideButton.ImageColor3 = Color3.fromRGB(200, 200, 220)
    HideButton.Parent = SlotsContainer
    Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 8)
    
    -- Mini botão mostrar
    local ShowButton = Instance.new("ImageButton")
    ShowButton.Name = "ShowButton"
    ShowButton.Size = UDim2.new(0, 40, 0, 40)
    ShowButton.Position = UDim2.new(0.5, 0, 1, -50)
    ShowButton.AnchorPoint = Vector2.new(0.5, 0)
    ShowButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    ShowButton.BackgroundTransparency = 0.2
    ShowButton.Image = "rbxassetid://3926305904"
    ShowButton.ImageRectOffset = Vector2.new(764, 244)
    ShowButton.ImageRectSize = Vector2.new(36, 36)
    ShowButton.ImageColor3 = Color3.fromRGB(150, 150, 200)
    ShowButton.Visible = false
    ShowButton.Parent = MainGui
    Instance.new("UICorner", ShowButton).CornerRadius = UDim.new(0, 10)
    
    HideButton.MouseButton1Click:Connect(function()
        local tween = Tween(SlotsContainer, {Position = UDim2.new(Config.PositionX, 0, 1.2, 0)}, 0.4)
        tween:Play()
        tween.Completed:Connect(function()
            SlotsContainer.Visible = false
            ShowButton.Visible = true
        end)
    end)
    
    ShowButton.MouseButton1Click:Connect(function()
        SlotsContainer.Visible = true
        ShowButton.Visible = false
        Tween(SlotsContainer, {Position = UDim2.new(Config.PositionX, 0, Config.PositionY, 0)}, 0.4):Play()
    end)
end

-- Criar Slot Individual
local function CreateSlot(index)
    local slot = Instance.new("Frame")
    slot.Name = "Slot_" .. index
    slot.Size = UDim2.new(0, Config.SlotSize, 0, Config.SlotSize)
    slot.BackgroundColor3 = Config.SlotColor
    slot.BorderSizePixel = 0
    
    Instance.new("UICorner", slot).CornerRadius = UDim.new(0, Config.SlotCornerRadius)
    
    local slotStroke = Instance.new("UIStroke", slot)
    slotStroke.Name = "Stroke"
    slotStroke.Color = Config.SlotBorderColor
    slotStroke.Thickness = 2
    
    local slotNumber = Instance.new("TextLabel", slot)
    slotNumber.Name = "SlotNumber"
    slotNumber.Size = UDim2.new(0, 20, 0, 20)
    slotNumber.Position = UDim2.new(0, 4, 0, 4)
    slotNumber.BackgroundTransparency = 1
    slotNumber.Text = tostring(index)
    slotNumber.TextColor3 = Color3.fromRGB(150, 150, 170)
    slotNumber.TextSize = 12
    slotNumber.Font = Enum.Font.GothamBold
    
    local itemIcon = Instance.new("ImageLabel", slot)
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
    itemIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = ""
    
    local itemName = Instance.new("TextLabel", slot)
    itemName.Name = "ItemName"
    itemName.Size = UDim2.new(1, -8, 0, 16)
    itemName.Position = UDim2.new(0, 4, 1, -18)
    itemName.BackgroundTransparency = 1
    itemName.Text = ""
    itemName.TextColor3 = Color3.fromRGB(200, 200, 220)
    itemName.TextSize = 10
    itemName.Font = Enum.Font.Gotham
    itemName.TextTruncate = Enum.TextTruncate.AtEnd
    
    local emptyIndicator = Instance.new("TextLabel", slot)
    emptyIndicator.Name = "EmptyIndicator"
    emptyIndicator.Size = UDim2.new(1, 0, 1, 0)
    emptyIndicator.BackgroundTransparency = 1
    emptyIndicator.Text = "+"
    emptyIndicator.TextColor3 = Color3.fromRGB(80, 80, 100)
    emptyIndicator.TextSize = 28
    emptyIndicator.Font = Enum.Font.GothamBold
    
    local slotButton = Instance.new("TextButton", slot)
    slotButton.Name = "SlotButton"
    slotButton.Size = UDim2.new(1, 0, 1, 0)
    slotButton.BackgroundTransparency = 1
    slotButton.Text = ""
    
    slotButton.MouseEnter:Connect(function()
        Tween(slot, {BackgroundColor3 = Config.SlotHoverColor}, 0.2):Play()
        Tween(slotStroke, {Color = Config.SlotActiveColor}, 0.2):Play()
    end)
    
    slotButton.MouseLeave:Connect(function()
        Tween(slot, {BackgroundColor3 = Config.SlotColor}, 0.2):Play()
        Tween(slotStroke, {Color = Config.SlotBorderColor}, 0.2):Play()
    end)
    
    local pressStart = 0
    slotButton.MouseButton1Down:Connect(function() pressStart = tick() end)
    slotButton.MouseButton1Up:Connect(function()
        if tick() - pressStart > 0.8 then
            SlotData[index] = nil
            UpdateSlotVisual(index)
            Tween(slot, {BackgroundColor3 = Color3.fromRGB(100, 50, 50)}, 0.1):Play()
            task.delay(0.2, function() Tween(slot, {BackgroundColor3 = Config.SlotColor}, 0.3):Play() end)
        end
    end)
    
    slotButton.MouseButton1Click:Connect(function()
        if tick() - pressStart < 0.8 then
            if SlotData[index] then
                local data = SlotData[index]
                local stroke = slot:FindFirstChild("Stroke")
                if stroke then
                    Tween(stroke, {Color = Color3.fromRGB(100, 255, 150)}, 0.1):Play()
                    task.delay(0.2, function() Tween(stroke, {Color = Config.SlotBorderColor}, 0.3):Play() end)
                end
                if data.Tool then
                    local character = Player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid and data.Tool.Parent then humanoid:EquipTool(data.Tool) end
                elseif data.Callback then pcall(data.Callback)
                elseif data.RemoteEvent and data.RemoteArgs then
                    pcall(function() data.RemoteEvent:FireServer(unpack(data.RemoteArgs)) end)
                end
            else
                OpenItemSelector(index)
            end
        end
    end)
    
    return slot
end

function UpdateSlotVisual(index)
    local slot = SlotsContainer:FindFirstChild("Slot_" .. index)
    if not slot then return end
    local data = SlotData[index]
    local itemIcon = slot:FindFirstChild("ItemIcon")
    local itemName = slot:FindFirstChild("ItemName")
    local emptyIndicator = slot:FindFirstChild("EmptyIndicator")
    
    if data then
        if itemIcon then itemIcon.Image = data.Icon or "" end
        if itemName then itemName.Text = data.Name or "" end
        if emptyIndicator then emptyIndicator.Visible = false end
    else
        if itemIcon then itemIcon.Image = "" end
        if itemName then itemName.Text = "" end
        if emptyIndicator then emptyIndicator.Visible = true end
    end
end

local function UpdateSlots()
    for _, child in pairs(SlotsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Slot_") then child:Destroy() end
    end
    
    local padding = 16
    local totalWidth, totalHeight
    
    if Config.Orientation == "Horizontal" then
        totalWidth = (Config.SlotSize * Config.SlotCount) + (Config.SlotSpacing * (Config.SlotCount - 1)) + (padding * 2) + 80
        totalHeight = Config.SlotSize + (padding * 2) + 44
    else
        totalWidth = Config.SlotSize + (padding * 2) + 80
        totalHeight = (Config.SlotSize * Config.SlotCount) + (Config.SlotSpacing * (Config.SlotCount - 1)) + (padding * 2) + 44
    end
    
    SlotsContainer.Size = UDim2.new(0, totalWidth, 0, totalHeight)
    
    for i = 1, Config.SlotCount do
        local slot = CreateSlot(i)
        local xPos, yPos
        if Config.Orientation == "Horizontal" then
            xPos = padding + ((i - 1) * (Config.SlotSize + Config.SlotSpacing))
            yPos = padding + 40
        else
            xPos = padding + 40
            yPos = padding + ((i - 1) * (Config.SlotSize + Config.SlotSpacing))
        end
        slot.Position = UDim2.new(0, xPos, 0, yPos)
        slot.Parent = SlotsContainer
        if SlotData[i] then UpdateSlotVisual(i) end
    end
end

-- Seletor de Itens
local ItemSelectorFrame

function OpenItemSelector(targetSlotIndex)
    if ItemSelectorFrame then ItemSelectorFrame:Destroy() ItemSelectorFrame = nil return end
    
    ItemSelectorFrame = Instance.new("Frame")
    ItemSelectorFrame.Name = "ItemSelector"
    ItemSelectorFrame.Size = UDim2.new(0, 300, 0, 400)
    ItemSelectorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    ItemSelectorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ItemSelectorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    ItemSelectorFrame.BorderSizePixel = 0
    ItemSelectorFrame.Parent = MainGui
    
    Instance.new("UICorner", ItemSelectorFrame).CornerRadius = UDim.new(0, 16)
    local selectorStroke = Instance.new("UIStroke", ItemSelectorFrame)
    selectorStroke.Color = Color3.fromRGB(80, 80, 120)
    selectorStroke.Thickness = 2
    
    local title = Instance.new("TextLabel", ItemSelectorFrame)
    title.Size = UDim2.new(1, -60, 0, 40)
    title.Position = UDim2.new(0, 16, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Selecionar Item - Slot " .. targetSlotIndex
    title.TextColor3 = Color3.fromRGB(220, 220, 240)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", ItemSelectorFrame)
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() ItemSelectorFrame:Destroy() ItemSelectorFrame = nil end)
    
    local scrollFrame = Instance.new("ScrollingFrame", ItemSelectorFrame)
    scrollFrame.Size = UDim2.new(1, -32, 1, -60)
    scrollFrame.Position = UDim2.new(0, 16, 0, 52)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout", scrollFrame)
    listLayout.Padding = UDim.new(0, 8)
    
    local items = {}
    local backpack = Player:FindFirstChild("Backpack")
    local character = Player.Character
    
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, {Name = tool.Name, Icon = tool.TextureId ~= "" and tool.TextureId or "rbxassetid://3926305904", Tool = tool, Type = "Tool"})
            end
        end
    end
    
    if character then
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, {Name = tool.Name .. " (Equipado)", Icon = tool.TextureId ~= "" and tool.TextureId or "rbxassetid://3926305904", Tool = tool, Type = "Tool"})
            end
        end
    end
    
    local abilityFolders = {ReplicatedStorage:FindFirstChild("Abilities"), ReplicatedStorage:FindFirstChild("Skills"), Player:FindFirstChild("Abilities")}
    for _, folder in pairs(abilityFolders) do
        if folder then
            for _, ability in pairs(folder:GetChildren()) do
                local icon = ability:FindFirstChild("Icon")
                table.insert(items, {Name = ability.Name, Icon = icon and icon.Value or "rbxassetid://3926305904", Ability = ability, Type = "Ability"})
            end
        end
    end
    
    if #items == 0 then
        local noItemsLabel = Instance.new("TextLabel", scrollFrame)
        noItemsLabel.Size = UDim2.new(1, 0, 0, 100)
        noItemsLabel.BackgroundTransparency = 1
        noItemsLabel.Text = "Nenhum item encontrado.\n\nVocê pode adicionar itens manualmente."
        noItemsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
        noItemsLabel.TextSize = 14
        noItemsLabel.Font = Enum.Font.Gotham
        noItemsLabel.TextWrapped = true
    end
    
    for _, item in pairs(items) do
        local itemBtn = Instance.new("TextButton", scrollFrame)
        itemBtn.Size = UDim2.new(1, 0, 0, 50)
        itemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        itemBtn.BorderSizePixel = 0
        itemBtn.Text = ""
        Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 10)
        
        local itemIconImg = Instance.new("ImageLabel", itemBtn)
        itemIconImg.Size = UDim2.new(0, 36, 0, 36)
        itemIconImg.Position = UDim2.new(0, 8, 0.5, 0)
        itemIconImg.AnchorPoint = Vector2.new(0, 0.5)
        itemIconImg.BackgroundTransparency = 1
        itemIconImg.Image = item.Icon
        
        local itemNameLabel = Instance.new("TextLabel", itemBtn)
        itemNameLabel.Size = UDim2.new(1, -60, 0, 20)
        itemNameLabel.Position = UDim2.new(0, 52, 0, 8)
        itemNameLabel.BackgroundTransparency = 1
        itemNameLabel.Text = item.Name
        itemNameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
        itemNameLabel.TextSize = 14
        itemNameLabel.Font = Enum.Font.GothamSemibold
        itemNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local itemTypeLabel = Instance.new("TextLabel", itemBtn)
        itemTypeLabel.Size = UDim2.new(1, -60, 0, 16)
        itemTypeLabel.Position = UDim2.new(0, 52, 0, 28)
        itemTypeLabel.BackgroundTransparency = 1
        itemTypeLabel.Text = item.Type
        itemTypeLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
        itemTypeLabel.TextSize = 11
        itemTypeLabel.Font = Enum.Font.Gotham
        itemTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        itemBtn.MouseEnter:Connect(function() Tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 85)}, 0.2):Play() end)
        itemBtn.MouseLeave:Connect(function() Tween(itemBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.2):Play() end)
        
        itemBtn.MouseButton1Click:Connect(function()
            SlotData[targetSlotIndex] = {Name = item.Name, Icon = item.Icon, Tool = item.Tool, Ability = item.Ability, Type = item.Type}
            UpdateSlotVisual(targetSlotIndex)
            ItemSelectorFrame:Destroy()
            ItemSelectorFrame = nil
        end)
    end
    
    -- Botão item customizado
    local customBtn = Instance.new("TextButton", scrollFrame)
    customBtn.Size = UDim2.new(1, 0, 0, 50)
    customBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
    customBtn.BorderSizePixel = 0
    customBtn.Text = ""
    customBtn.LayoutOrder = 999
    Instance.new("UICorner", customBtn).CornerRadius = UDim.new(0, 10)
    
    local customLabel = Instance.new("TextLabel", customBtn)
    customLabel.Size = UDim2.new(1, -16, 1, 0)
    customLabel.Position = UDim2.new(0, 8, 0, 0)
    customLabel.BackgroundTransparency = 1
    customLabel.Text = "+ Adicionar Item Personalizado"
    customLabel.TextColor3 = Color3.fromRGB(150, 220, 150)
    customLabel.TextSize = 14
    customLabel.Font = Enum.Font.GothamSemibold
    customLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    customBtn.MouseButton1Click:Connect(function()
        ItemSelectorFrame:Destroy()
        ItemSelectorFrame = nil
        OpenCustomItemCreator(targetSlotIndex)
    end)
    
    ItemSelectorFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(ItemSelectorFrame, {Size = UDim2.new(0, 300, 0, 400)}, 0.3, Enum.EasingStyle.Back):Play()
    MakeDraggable(ItemSelectorFrame, title)
end

function OpenCustomItemCreator(targetSlotIndex)
    local creatorFrame = Instance.new("Frame")
    creatorFrame.Name = "CustomItemCreator"
    creatorFrame.Size = UDim2.new(0, 280, 0, 280)
    creatorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    creatorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    creatorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    creatorFrame.BorderSizePixel = 0
    creatorFrame.Parent = MainGui
    
    Instance.new("UICorner", creatorFrame).CornerRadius = UDim.new(0, 16)
    local creatorStroke = Instance.new("UIStroke", creatorFrame)
    creatorStroke.Color = Color3.fromRGB(80, 120, 80)
    creatorStroke.Thickness = 2
    
    local title = Instance.new("TextLabel", creatorFrame)
    title.Size = UDim2.new(1, -60, 0, 40)
    title.Position = UDim2.new(0, 16, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Criar Item Personalizado"
    title.TextColor3 = Color3.fromRGB(150, 220, 150)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", creatorFrame)
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() creatorFrame:Destroy() end)
    
    local nameLabel = Instance.new("TextLabel", creatorFrame)
    nameLabel.Size = UDim2.new(1, -32, 0, 20)
    nameLabel.Position = UDim2.new(0, 16, 0, 55)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Nome do Item:"
    nameLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local nameInput = Instance.new("TextBox", creatorFrame)
    nameInput.Size = UDim2.new(1, -32, 0, 36)
    nameInput.Position = UDim2.new(0, 16, 0, 78)
    nameInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    nameInput.BorderSizePixel = 0
    nameInput.Text = ""
    nameInput.PlaceholderText = "Digite o nome..."
    nameInput.TextColor3 = Color3.fromRGB(220, 220, 240)
    nameInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    nameInput.TextSize = 14
    nameInput.Font = Enum.Font.Gotham
    nameInput.ClearTextOnFocus = false
    Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 8)
    
    local iconLabel = Instance.new("TextLabel", creatorFrame)
    iconLabel.Size = UDim2.new(1, -32, 0, 20)
    iconLabel.Position = UDim2.new(0, 16, 0, 125)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "ID do Ícone (rbxassetid):"
    iconLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    iconLabel.TextSize = 12
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local iconInput = Instance.new("TextBox", creatorFrame)
    iconInput.Size = UDim2.new(1, -32, 0, 36)
    iconInput.Position = UDim2.new(0, 16, 0, 148)
    iconInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    iconInput.BorderSizePixel = 0
    iconInput.Text = ""
    iconInput.PlaceholderText = "Ex: 3926305904"
    iconInput.TextColor3 = Color3.fromRGB(220, 220, 240)
    iconInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    iconInput.TextSize = 14
    iconInput.Font = Enum.Font.Gotham
    iconInput.ClearTextOnFocus = false
    Instance.new("UICorner", iconInput).CornerRadius = UDim.new(0, 8)
    
    local createBtn = Instance.new("TextButton", creatorFrame)
    createBtn.Size = UDim2.new(1, -32, 0, 44)
    createBtn.Position = UDim2.new(0, 16, 1, -60)
    createBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
    createBtn.Text = "Criar Item"
    createBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    createBtn.TextSize = 15
    createBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 10)
    
    createBtn.MouseButton1Click:Connect(function()
        local itemName = nameInput.Text ~= "" and nameInput.Text or "Item " .. targetSlotIndex
        local iconId = iconInput.Text
        local iconUrl = iconId ~= "" and (iconId:match("rbxassetid://") and iconId or "rbxassetid://" .. iconId) or ""
        SlotData[targetSlotIndex] = {Name = itemName, Icon = iconUrl, Type = "Custom"}
        UpdateSlotVisual(targetSlotIndex)
        creatorFrame:Destroy()
    end)
    
    creatorFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(creatorFrame, {Size = UDim2.new(0, 280, 0, 280)}, 0.3, Enum.EasingStyle.Back):Play()
    MakeDraggable(creatorFrame, title)
end

-- Painel de Configurações
local function CreateConfigPanel()
    if ConfigPanel then ConfigPanel:Destroy() ConfigPanel = nil return end
    
    ConfigPanel = Instance.new("Frame")
    ConfigPanel.Name = "ConfigPanel"
    ConfigPanel.Size = UDim2.new(0, 320, 0, 480)
    ConfigPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    ConfigPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    ConfigPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    ConfigPanel.BorderSizePixel = 0
    ConfigPanel.Parent = MainGui
    
    Instance.new("UICorner", ConfigPanel).CornerRadius = UDim.new(0, 16)
    local panelStroke = Instance.new("UIStroke", ConfigPanel)
    panelStroke.Color = Color3.fromRGB(100, 100, 140)
    panelStroke.Thickness = 2
    
    local titleBar = Instance.new("Frame", ConfigPanel)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundTransparency = 1
    
    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Configurações dos Slots"
    title.TextColor3 = Color3.fromRGB(220, 220, 240)
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", ConfigPanel)
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -44, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() SaveConfig() ConfigPanel:Destroy() ConfigPanel = nil end)
    
    local scrollFrame = Instance.new("ScrollingFrame", ConfigPanel)
    scrollFrame.Size = UDim2.new(1, -32, 1, -60)
    scrollFrame.Position = UDim2.new(0, 16, 0, 55)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 550)
    
    local yOffset = 0
    
    local function CreateSlider(name, label, min, max, default, callback)
        local container = Instance.new("Frame", scrollFrame)
        container.Size = UDim2.new(1, 0, 0, 60)
        container.Position = UDim2.new(0, 0, 0, yOffset)
        container.BackgroundTransparency = 1
        
        local labelText = Instance.new("TextLabel", container)
        labelText.Size = UDim2.new(0.6, 0, 0, 20)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(180, 180, 200)
        labelText.TextSize = 13
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        
        local valueLabel = Instance.new("TextLabel", container)
        valueLabel.Size = UDim2.new(0.4, 0, 0, 20)
        valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        valueLabel.TextSize = 13
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        
        local sliderBg = Instance.new("Frame", container)
        sliderBg.Size = UDim2.new(1, 0, 0, 24)
        sliderBg.Position = UDim2.new(0, 0, 0, 28)
        sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        sliderBg.BorderSizePixel = 0
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 8)
        
        local sliderFill = Instance.new("Frame", sliderBg)
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(80, 140, 220)
        sliderFill.BorderSizePixel = 0
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 8)
        
        local sliderBtn = Instance.new("TextButton", sliderBg)
        sliderBtn.Size = UDim2.new(1, 0, 1, 0)
        sliderBtn.BackgroundTransparency = 1
        sliderBtn.Text = ""
        
        local dragging = false
        
        local function UpdateSlider(input)
            local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            valueLabel.Text = tostring(value)
            callback(value)
        end
        
        sliderBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                UpdateSlider(input)
            end
        end)
        
        sliderBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                UpdateSlider(input)
            end
        end)
        
        yOffset = yOffset + 70
    end
    
    local function CreateDropdown(name, label, options, default, callback)
        local container = Instance.new("Frame", scrollFrame)
        container.Size = UDim2.new(1, 0, 0, 60)
        container.Position = UDim2.new(0, 0, 0, yOffset)
        container.BackgroundTransparency = 1
        
        local labelText = Instance.new("TextLabel", container)
        labelText.Size = UDim2.new(1, 0, 0, 20)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(180, 180, 200)
        labelText.TextSize = 13
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        
        local dropdownBtn = Instance.new("TextButton", container)
        dropdownBtn.Size = UDim2.new(1, 0, 0, 32)
        dropdownBtn.Position = UDim2.new(0, 0, 0, 24)
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        dropdownBtn.BorderSizePixel = 0
        dropdownBtn.Text = default
        dropdownBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
        dropdownBtn.TextSize = 13
        dropdownBtn.Font = Enum.Font.Gotham
        Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)
        
        local currentIndex = table.find(options, default) or 1
        dropdownBtn.MouseButton1Click:Connect(function()
            currentIndex = currentIndex % #options + 1
            dropdownBtn.Text = options[currentIndex]
            callback(options[currentIndex])
        end)
        
        yOffset = yOffset + 70
    end
    
    -- Seção Slots
    local section1 = Instance.new("TextLabel", scrollFrame)
    section1.Size = UDim2.new(1, 0, 0, 25)
    section1.Position = UDim2.new(0, 0, 0, yOffset)
    section1.BackgroundTransparency = 1
    section1.Text = "SLOTS"
    section1.TextColor3 = Color3.fromRGB(100, 180, 255)
    section1.TextSize = 12
    section1.Font = Enum.Font.GothamBold
    section1.TextXAlignment = Enum.TextXAlignment.Left
    yOffset = yOffset + 30
    
    CreateSlider("SlotCount", "Quantidade de Slots", 1, 12, Config.SlotCount, function(v) Config.SlotCount = v UpdateSlots() end)
    CreateSlider("SlotSize", "Tamanho dos Slots", 30, 100, Config.SlotSize, function(v) Config.SlotSize = v UpdateSlots() end)
    CreateSlider("SlotSpacing", "Espaçamento", 0, 30, Config.SlotSpacing, function(v) Config.SlotSpacing = v UpdateSlots() end)
    CreateSlider("CornerRadius", "Arredondamento", 0, 30, Config.SlotCornerRadius, function(v) Config.SlotCornerRadius = v UpdateSlots() end)
    
    -- Seção Posição
    local section2 = Instance.new("TextLabel", scrollFrame)
    section2.Size = UDim2.new(1, 0, 0, 25)
    section2.Position = UDim2.new(0, 0, 0, yOffset)
    section2.BackgroundTransparency = 1
    section2.Text = "POSIÇÃO"
    section2.TextColor3 = Color3.fromRGB(100, 180, 255)
    section2.TextSize = 12
    section2.Font = Enum.Font.GothamBold
    section2.TextXAlignment = Enum.TextXAlignment.Left
    yOffset = yOffset + 30
    
    CreateDropdown("Orientation", "Orientação", {"Horizontal", "Vertical"}, Config.Orientation, function(v) Config.Orientation = v UpdateSlots() end)
    CreateSlider("PositionX", "Posição Horizontal (%)", 0, 100, math.floor(Config.PositionX * 100), function(v) Config.PositionX = v / 100 SlotsContainer.Position = UDim2.new(Config.PositionX, 0, Config.PositionY, 0) end)
    CreateSlider("PositionY", "Posição Vertical (%)", 0, 100, math.floor(Config.PositionY * 100), function(v) Config.PositionY = v / 100 SlotsContainer.Position = UDim2.new(Config.PositionX, 0, Config.PositionY, 0) end)
    
    -- Seção Aparência
    local section3 = Instance.new("TextLabel", scrollFrame)
    section3.Size = UDim2.new(1, 0, 0, 25)
    section3.Position = UDim2.new(0, 0, 0, yOffset)
    section3.BackgroundTransparency = 1
    section3.Text = "APARÊNCIA"
    section3.TextColor3 = Color3.fromRGB(100, 180, 255)
    section3.TextSize = 12
    section3.Font = Enum.Font.GothamBold
    section3.TextXAlignment = Enum.TextXAlignment.Left
    yOffset = yOffset + 30
    
    CreateSlider("Transparency", "Transparência do Fundo (%)", 0, 100, math.floor(Config.BackgroundTransparency * 100), function(v) Config.BackgroundTransparency = v / 100 SlotsContainer.BackgroundTransparency = Config.BackgroundTransparency end)
    
    -- Botão Reset
    local resetBtn = Instance.new("TextButton", scrollFrame)
    resetBtn.Size = UDim2.new(1, 0, 0, 40)
    resetBtn.Position = UDim2.new(0, 0, 0, yOffset + 20)
    resetBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
    resetBtn.Text = "Resetar Configurações"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.TextSize = 14
    resetBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)
    
    resetBtn.MouseButton1Click:Connect(function()
        Config = {SlotCount = 4, SlotSize = 60, SlotSpacing = 10, SlotCornerRadius = 12, PositionX = 0.5, PositionY = 0.85, Orientation = "Horizontal", SlotColor = Color3.fromRGB(40, 40, 50), SlotBorderColor = Color3.fromRGB(80, 80, 100), SlotHoverColor = Color3.fromRGB(60, 60, 80), SlotActiveColor = Color3.fromRGB(100, 150, 255), BackgroundTransparency = 0.3}
        ConfigPanel:Destroy()
        ConfigPanel = nil
        UpdateSlots()
        CreateConfigPanel()
    end)
    
    ConfigPanel.Size = UDim2.new(0, 0, 0, 0)
    Tween(ConfigPanel, {Size = UDim2.new(0, 320, 0, 480)}, 0.3, Enum.EasingStyle.Back):Play()
    MakeDraggable(ConfigPanel, titleBar)
end

-- Inicialização
local function Initialize()
    LoadConfig()
    CreateMainUI()
    UpdateSlots()
    ToggleButton.MouseButton1Click:Connect(CreateConfigPanel)
    MakeDraggable(SlotsContainer)
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Custom Slots",
            Text = "Sistema carregado! Toque na engrenagem para configurar.",
            Duration = 4
        })
    end)
    
    print("Custom Slots System carregado com sucesso!")
end

Initialize()

-- API Pública
if getgenv then
    getgenv().CustomSlots = {
        SetSlot = function(i, d) SlotData[i] = d UpdateSlotVisual(i) end,
        GetSlot = function(i) return SlotData[i] end,
        ClearSlot = function(i) SlotData[i] = nil UpdateSlotVisual(i) end,
        ClearAllSlots = function() for i = 1, Config.SlotCount do SlotData[i] = nil UpdateSlotVisual(i) end end,
        SetConfig = function(k, v) Config[k] = v UpdateSlots() end,
        GetConfig = function(k) return Config[k] end,
        ToggleVisibility = function() SlotsContainer.Visible = not SlotsContainer.Visible end,
        Destroy = function() if MainGui then MainGui:Destroy() end end
    }
end
