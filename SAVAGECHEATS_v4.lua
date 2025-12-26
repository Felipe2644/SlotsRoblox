--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                           SAVAGECHEATS_ AIMBOT UNIVERSAL                                  ║
    ║                        Otimizado para Mobile Android/iOS                                  ║
    ║                                  Versão 4.0 (CORRIGIDA)                                   ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════╣
    ║  CORREÇÕES APLICADAS:                                                                     ║
    ║  • Disparo automático não trava mais câmera/movimento                                     ║
    ║  • UI com arraste customizado que não move a câmera do jogo                               ║
    ║  • Bala mágica usando hook de __index (não afeta câmera)                                  ║
    ║  • Ignorar paredes com lógica simplificada e correta                                      ║
    ║  • Dropdowns com ZIndex correto (não ficam atrás de outros elementos)                     ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════╝
]]

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SERVIÇOS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        VARIÁVEIS GLOBAIS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Verificar se já existe uma instância rodando
if _G.SAVAGECHEATS_LOADED then
    warn("[SAVAGECHEATS_] Script já está rodando! Reiniciando...")
    if _G.SAVAGECHEATS_DESTROY then
        pcall(_G.SAVAGECHEATS_DESTROY)
    end
    task.wait(0.5)
end
_G.SAVAGECHEATS_LOADED = true

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        CONFIGURAÇÕES
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Config = {
    -- Aimbot Principal
    AimbotAtivo = false,
    BalaMagica = false,
    PularAbatidos = true,
    IgnorarParedes = false,  -- CORRIGIDO: Uma única variável clara
    
    -- Configurações de Mira
    ParteAlvo = "Head",
    EstiloMira = "FOV",
    TaxaHeadshot = 100,
    
    -- FOV
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(200, 40, 40),
    FOVCorTravado = Color3.fromRGB(0, 255, 0),
    
    -- Suavização
    Suavizacao = 0.5,
    SuavizacaoAtiva = true,
    
    -- Sistema de Times
    ModoTime = "Inimigos",
    TimeAlvo = "",
    VerificarTime = true,
    
    -- ESP
    ESPAtivo = false,
    ESPBox = true,
    ESPNome = true,
    ESPVida = true,
    ESPDistancia = true,
    ESPTracer = false,
    ESPCorInimigo = Color3.fromRGB(255, 50, 50),
    ESPCorAliado = Color3.fromRGB(50, 255, 50),
    
    -- Disparo Automático - CORRIGIDO
    DisparoAutomatico = false,
    DelayDisparo = 0.15,  -- Delay maior para evitar problemas
    
    -- Predição
    PredicaoAtiva = false,
    ForcaPredicao = 0.15,
    
    -- Outras
    DistanciaMaxima = 1000,
    AtivarComToque = true,
}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        ESTADO DO SISTEMA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Estado = {
    Mirando = false,
    AlvoAtual = nil,
    ParteAlvoAtual = nil,
    Travado = false,
    UltimoDisparo = 0,
    TimesDisponiveis = {},
    InteragindoComUI = false,  -- NOVO: Flag para saber se está usando a UI
    Arrastando = false,        -- NOVO: Flag para saber se está arrastando
}

local Conexoes = {}
local ElementosUI = {}
local ElementosESP = {}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Criar elemento Drawing com proteção
local function CriarDrawing(tipo, propriedades)
    local sucesso, objeto = pcall(function()
        local obj = Drawing.new(tipo)
        for prop, valor in pairs(propriedades or {}) do
            obj[prop] = valor
        end
        return obj
    end)
    
    if sucesso then
        return objeto
    else
        return nil
    end
end

-- Obter centro da tela CORRIGIDO
local function GetCentroTela()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y / 2) + inset.Y)
end

-- Converter posição 3D para 2D
local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel and pos.Z > 0
end

-- Calcular distância 2D
local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Calcular distância 3D
local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Atualizar times disponíveis
local function AtualizarTimesDisponiveis()
    Estado.TimesDisponiveis = {}
    
    pcall(function()
        for _, time in pairs(Teams:GetTeams()) do
            table.insert(Estado.TimesDisponiveis, time.Name)
        end
    end)
    
    if #Estado.TimesDisponiveis == 0 then
        Estado.TimesDisponiveis = {"Nenhum time detectado"}
    end
end

-- Verificar se jogador é do mesmo time
local function MesmoTime(jogador)
    if not Config.VerificarTime then
        return false
    end
    
    if not LocalPlayer.Team or not jogador.Team then
        return false
    end
    
    return LocalPlayer.Team == jogador.Team
end

-- Verificar se jogador deve ser alvo
local function DeveSerAlvo(jogador)
    if jogador == LocalPlayer then
        return false
    end
    
    if Config.ModoTime == "Todos" then
        return true
    elseif Config.ModoTime == "Inimigos" then
        return not MesmoTime(jogador)
    elseif Config.ModoTime == "TimeEspecifico" then
        if jogador.Team then
            return jogador.Team.Name == Config.TimeAlvo
        end
        return false
    end
    
    return true
end

-- Verificar se personagem está vivo
local function EstaVivo(personagem)
    if not personagem then return false end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if humanoid.Health <= 0 then
        return false
    end
    
    -- Verificar se está abatido (knocked)
    if Config.PularAbatidos then
        local knocked = personagem:FindFirstChild("Knocked")
        local downed = personagem:FindFirstChild("Downed")
        local ragdoll = personagem:FindFirstChild("Ragdoll")
        
        if knocked or downed or ragdoll then
            return false
        end
        
        pcall(function()
            if personagem:GetAttribute("Knocked") or 
               personagem:GetAttribute("Downed") or
               humanoid:GetAttribute("Knocked") then
                return false
            end
        end)
        
        if humanoid:GetState() == Enum.HumanoidStateType.Dead or
           humanoid:GetState() == Enum.HumanoidStateType.Physics then
            return false
        end
    end
    
    return true
end

-- Verificar linha de visão - CORRIGIDO: Lógica simplificada
local function TemLinhaDeVisao(origem, destino)
    -- Se ignorar paredes está ativo, sempre retorna true
    if Config.IgnorarParedes then
        return true
    end
    
    local direcao = (destino - origem).Unit
    local distancia = (destino - origem).Magnitude
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local resultado = Workspace:Raycast(origem, direcao * distancia, params)
    
    if resultado then
        local acertou = resultado.Instance
        if acertou then
            local personagemAcertado = acertou:FindFirstAncestorOfClass("Model")
            if personagemAcertado and personagemAcertado:FindFirstChildOfClass("Humanoid") then
                return true
            end
            return false
        end
    end
    
    return true
end

-- Obter parte do corpo para mirar
local function GetParteAlvo(personagem)
    if not personagem then return nil end
    
    local parteDesejada = Config.ParteAlvo
    
    if Config.TaxaHeadshot < 100 then
        local chance = math.random(1, 100)
        if chance > Config.TaxaHeadshot then
            parteDesejada = "HumanoidRootPart"
        else
            parteDesejada = "Head"
        end
    end
    
    local parte = personagem:FindFirstChild(parteDesejada)
    
    if not parte then
        parte = personagem:FindFirstChild("Head") or
                personagem:FindFirstChild("HumanoidRootPart") or
                personagem:FindFirstChild("Torso") or
                personagem:FindFirstChild("UpperTorso") or
                personagem.PrimaryPart
    end
    
    return parte
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE SELEÇÃO DE ALVO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = math.huge
    local centro = GetCentroTela()
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador == LocalPlayer then continue end
        if not DeveSerAlvo(jogador) then continue end
        
        local personagem = jogador.Character
        if not personagem or not EstaVivo(personagem) then continue end
        
        local parte = GetParteAlvo(personagem)
        if not parte then continue end
        
        local posicaoTela, visivel = WorldToScreen(parte.Position)
        if not visivel then continue end
        
        -- Verificar distância 3D
        local distancia3D = Distancia3D(Camera.CFrame.Position, parte.Position)
        if distancia3D > Config.DistanciaMaxima then continue end
        
        -- Verificar linha de visão (só se não ignorar paredes)
        if not Config.IgnorarParedes then
            if not TemLinhaDeVisao(Camera.CFrame.Position, parte.Position) then
                continue
            end
        end
        
        local distancia2D = Distancia2D(posicaoTela, centro)
        
        if Config.EstiloMira == "FOV" then
            if distancia2D <= Config.FOVRaio and distancia2D < menorDistancia then
                menorDistancia = distancia2D
                melhorAlvo = jogador
                melhorParte = parte
            end
        elseif Config.EstiloMira == "MaisProximo" then
            if distancia3D < menorDistancia then
                menorDistancia = distancia3D
                melhorAlvo = jogador
                melhorParte = parte
            end
        elseif Config.EstiloMira == "Aleatorio" then
            if distancia2D <= Config.FOVRaio then
                if math.random() > 0.5 or not melhorAlvo then
                    melhorAlvo = jogador
                    melhorParte = parte
                end
            end
        end
    end
    
    return melhorAlvo, melhorParte
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE PREDIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not parte then
        return parte.Position
    end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return parte.Position
    end
    
    local velocidade = rootPart.AssemblyLinearVelocity
    local predicao = velocidade * Config.ForcaPredicao
    
    return parte.Position + predicao
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE MIRA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function MirarEm(posicaoAlvo)
    if not posicaoAlvo then return end
    
    -- CORRIGIDO: Não mirar se estiver interagindo com UI
    if Estado.InteragindoComUI or Estado.Arrastando then return end
    
    local posicaoCamera = Camera.CFrame.Position
    local cframeAlvo = CFrame.lookAt(posicaoCamera, posicaoAlvo)
    
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        local fatorLerp = 1 - math.clamp(Config.Suavizacao, 0, 0.95)
        Camera.CFrame = Camera.CFrame:Lerp(cframeAlvo, fatorLerp)
    else
        Camera.CFrame = cframeAlvo
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE DISPARO - CORRIGIDO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local DisparoEmAndamento = false

local function ExecutarDisparo()
    -- Verificações de segurança
    if not Config.DisparoAutomatico then return end
    if not Config.AimbotAtivo then return end
    if not Estado.Travado then return end
    if not Estado.AlvoAtual then return end
    if Estado.InteragindoComUI then return end
    if Estado.Arrastando then return end
    if DisparoEmAndamento then return end
    
    local agora = tick()
    if agora - Estado.UltimoDisparo < Config.DelayDisparo then
        return
    end
    
    Estado.UltimoDisparo = agora
    DisparoEmAndamento = true
    
    -- CORRIGIDO: Executar em thread separada para não bloquear
    task.spawn(function()
        pcall(function()
            -- Tentar mouse1press/release (mais compatível)
            if mouse1press and mouse1release then
                mouse1press()
                task.wait(0.03)
                mouse1release()
            elseif mouse1click then
                mouse1click()
            end
        end)
        
        task.wait(0.05)
        DisparoEmAndamento = false
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE BALA MÁGICA - CORRIGIDO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local HookAtivo = false
local OldIndex = nil

-- CORRIGIDO: Usar hook de __index no Mouse ao invés de __namecall em raycasts
-- Isso não afeta a câmera do jogo
local function AtivarBalaMagica()
    if HookAtivo then return end
    
    local sucesso = pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        
        if oldReadonly then
            setreadonly(mt, false)
        end
        
        OldIndex = mt.__index
        
        mt.__index = newcclosure(function(self, key)
            -- Só modificar se for o Mouse e estiver pedindo Hit ou Target
            if typeof(self) == "Instance" and self:IsA("Mouse") then
                if (key == "Hit" or key == "Target") and Config.BalaMagica and Config.AimbotAtivo then
                    -- Encontrar alvo
                    local alvo, parte = EncontrarMelhorAlvo()
                    
                    if alvo and parte then
                        if key == "Hit" then
                            return parte.CFrame
                        elseif key == "Target" then
                            return parte
                        end
                    end
                end
            end
            
            return OldIndex(self, key)
        end)
        
        if oldReadonly then
            setreadonly(mt, true)
        end
        
        HookAtivo = true
    end)
    
    if not sucesso then
        warn("[SAVAGECHEATS_] Bala Mágica não suportada neste executor")
    end
end

local function DesativarBalaMagica()
    if not HookAtivo or not OldIndex then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        
        if oldReadonly then
            setreadonly(mt, false)
        end
        
        mt.__index = OldIndex
        
        if oldReadonly then
            setreadonly(mt, true)
        end
        
        HookAtivo = false
        OldIndex = nil
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA FOV CIRCLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local FOVCircle = nil

local function CriarFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
    end
    
    FOVCircle = CriarDrawing("Circle", {
        Thickness = 2,
        NumSides = 64,
        Radius = Config.FOVRaio,
        Filled = false,
        Visible = Config.FOVVisivel,
        ZIndex = 999,
        Transparency = 1,
        Color = Config.FOVCor,
        Position = GetCentroTela()
    })
end

local function AtualizarFOVCircle()
    if not FOVCircle then return end
    
    FOVCircle.Position = GetCentroTela()
    FOVCircle.Radius = Config.FOVRaio
    FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
    
    if Estado.Travado and Estado.AlvoAtual then
        FOVCircle.Color = Config.FOVCorTravado
    else
        FOVCircle.Color = Config.FOVCor
    end
end

local function DestruirFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA ESP
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarESPParaJogador(jogador)
    if jogador == LocalPlayer then return end
    
    if ElementosESP[jogador] then
        for _, elemento in pairs(ElementosESP[jogador]) do
            pcall(function() elemento:Remove() end)
        end
    end
    
    ElementosESP[jogador] = {
        Box = CriarDrawing("Square", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Filled = false,
            Visible = false,
            ZIndex = 998
        }),
        Nome = CriarDrawing("Text", {
            Text = jogador.Name,
            Size = 14,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Vida = CriarDrawing("Text", {
            Text = "100 HP",
            Size = 12,
            Color = Color3.new(0, 1, 0),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Distancia = CriarDrawing("Text", {
            Text = "0m",
            Size = 12,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Tracer = CriarDrawing("Line", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Visible = false,
            ZIndex = 997
        })
    }
end

local function AtualizarESPJogador(jogador)
    local esp = ElementosESP[jogador]
    if not esp then return end
    
    local personagem = jogador.Character
    local mostrar = Config.ESPAtivo and personagem and EstaVivo(personagem)
    
    if not mostrar then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    local head = personagem:FindFirstChild("Head")
    
    if not humanoid or not rootPart then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local posRaiz, visivelRaiz = WorldToScreen(rootPart.Position)
    local posCabeca, _ = WorldToScreen(head and head.Position + Vector3.new(0, 0.5, 0) or rootPart.Position + Vector3.new(0, 2, 0))
    local posPes, _ = WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not visivelRaiz then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local cor = MesmoTime(jogador) and Config.ESPCorAliado or Config.ESPCorInimigo
    
    local altura = math.abs(posCabeca.Y - posPes.Y)
    local largura = altura / 2
    
    local boxPos = Vector2.new(posRaiz.X - largura / 2, posCabeca.Y)
    local boxSize = Vector2.new(largura, altura)
    
    if esp.Box and Config.ESPBox then
        esp.Box.Position = boxPos
        esp.Box.Size = boxSize
        esp.Box.Color = cor
        esp.Box.Visible = true
    elseif esp.Box then
        esp.Box.Visible = false
    end
    
    if esp.Nome and Config.ESPNome then
        esp.Nome.Position = Vector2.new(posRaiz.X, posCabeca.Y - 18)
        esp.Nome.Text = jogador.Name
        esp.Nome.Visible = true
    elseif esp.Nome then
        esp.Nome.Visible = false
    end
    
    if esp.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = humanoid.MaxHealth
        local porcentagem = math.floor((vida / vidaMax) * 100)
        
        esp.Vida.Position = Vector2.new(posRaiz.X, posPes.Y + 5)
        esp.Vida.Text = vida .. " HP (" .. porcentagem .. "%)"
        
        if porcentagem > 60 then
            esp.Vida.Color = Color3.new(0, 1, 0)
        elseif porcentagem > 30 then
            esp.Vida.Color = Color3.new(1, 1, 0)
        else
            esp.Vida.Color = Color3.new(1, 0, 0)
        end
        
        esp.Vida.Visible = true
    elseif esp.Vida then
        esp.Vida.Visible = false
    end
    
    if esp.Distancia and Config.ESPDistancia then
        local distancia = math.floor(Distancia3D(Camera.CFrame.Position, rootPart.Position))
        esp.Distancia.Position = Vector2.new(posRaiz.X, posPes.Y + 18)
        esp.Distancia.Text = distancia .. "m"
        esp.Distancia.Visible = true
    elseif esp.Distancia then
        esp.Distancia.Visible = false
    end
    
    if esp.Tracer and Config.ESPTracer then
        local centro = GetCentroTela()
        esp.Tracer.From = Vector2.new(centro.X, Camera.ViewportSize.Y)
        esp.Tracer.To = posRaiz
        esp.Tracer.Color = cor
        esp.Tracer.Visible = true
    elseif esp.Tracer then
        esp.Tracer.Visible = false
    end
end

local function RemoverESPJogador(jogador)
    if ElementosESP[jogador] then
        for _, elemento in pairs(ElementosESP[jogador]) do
            pcall(function() elemento:Remove() end)
        end
        ElementosESP[jogador] = nil
    end
end

local function InicializarESP()
    for _, jogador in pairs(Players:GetPlayers()) do
        CriarESPParaJogador(jogador)
    end
    
    Conexoes.PlayerAdded = Players.PlayerAdded:Connect(function(jogador)
        CriarESPParaJogador(jogador)
    end)
    
    Conexoes.PlayerRemoving = Players.PlayerRemoving:Connect(function(jogador)
        RemoverESPJogador(jogador)
    end)
end

local function DestruirESP()
    for jogador, _ in pairs(ElementosESP) do
        RemoverESPJogador(jogador)
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE UI - CORRIGIDO
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    CORREÇÕES APLICADAS:
    - Arraste customizado que não move a câmera do jogo
    - Dropdowns com ZIndex alto para não ficarem atrás de outros elementos
    - Flag de interação para evitar conflitos com aimbot
]]

local ScreenGui = nil
local MainFrame = nil
local CurrentTab = "Aim"
local DropdownsAbertos = {}
local ZIndexBase = 100
local ZIndexDropdown = 1000  -- ZIndex alto para dropdowns

-- Cores do tema SAVAGECHEATS_
local Cores = {
    Fundo = Color3.fromRGB(25, 25, 25),
    FundoSecundario = Color3.fromRGB(35, 35, 35),
    FundoTerciario = Color3.fromRGB(45, 45, 45),
    Destaque = Color3.fromRGB(200, 40, 40),
    DestaqueHover = Color3.fromRGB(230, 60, 60),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Borda = Color3.fromRGB(60, 60, 60),
    Sucesso = Color3.fromRGB(40, 200, 40),
    Erro = Color3.fromRGB(200, 40, 40),
}

-- CORRIGIDO: Sistema de arraste que não move a câmera
local function TornarArrastavel(frame, handleFrame)
    handleFrame = handleFrame or frame
    
    local arrastando = false
    local inicioArraste = nil
    local posicaoInicial = nil
    
    handleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.Arrastando = true
            Estado.InteragindoComUI = true
            inicioArraste = input.Position
            posicaoInicial = frame.Position
            
            -- Monitorar quando o input termina
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    arrastando = false
                    Estado.Arrastando = false
                    -- Delay antes de liberar a flag de UI
                    task.delay(0.1, function()
                        if not arrastando then
                            Estado.InteragindoComUI = false
                        end
                    end)
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - inicioArraste
            frame.Position = UDim2.new(
                posicaoInicial.X.Scale,
                posicaoInicial.X.Offset + delta.X,
                posicaoInicial.Y.Scale,
                posicaoInicial.Y.Offset + delta.Y
            )
        end
    end)
end

-- Criar botão estilizado
local function CriarBotao(parent, texto, posicao, tamanho, callback)
    local botao = Instance.new("TextButton")
    botao.Name = "Botao_" .. texto
    botao.Parent = parent
    botao.BackgroundColor3 = Cores.Destaque
    botao.BorderSizePixel = 0
    botao.Position = posicao
    botao.Size = tamanho
    botao.Font = Enum.Font.GothamBold
    botao.Text = texto
    botao.TextColor3 = Cores.Texto
    botao.TextSize = 14
    botao.AutoButtonColor = false
    botao.ZIndex = ZIndexBase + 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = botao
    
    botao.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
        TweenService:Create(botao, TweenInfo.new(0.2), {BackgroundColor3 = Cores.DestaqueHover}):Play()
    end)
    
    botao.MouseLeave:Connect(function()
        TweenService:Create(botao, TweenInfo.new(0.2), {BackgroundColor3 = Cores.Destaque}):Play()
        task.delay(0.1, function()
            if not Estado.Arrastando then
                Estado.InteragindoComUI = false
            end
        end)
    end)
    
    botao.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return botao
end

-- Criar checkbox estilizado
local function CriarCheckbox(parent, texto, posicaoY, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Checkbox_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 30)
    container.ZIndex = ZIndexBase + 1
    
    local checkbox = Instance.new("TextButton")
    checkbox.Name = "Box"
    checkbox.Parent = container
    checkbox.BackgroundColor3 = valorInicial and Cores.Destaque or Cores.FundoTerciario
    checkbox.BorderSizePixel = 0
    checkbox.Position = UDim2.new(0, 0, 0.5, -10)
    checkbox.Size = UDim2.new(0, 20, 0, 20)
    checkbox.Text = valorInicial and "✓" or ""
    checkbox.TextColor3 = Cores.Texto
    checkbox.TextSize = 14
    checkbox.Font = Enum.Font.GothamBold
    checkbox.ZIndex = ZIndexBase + 2
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = checkbox
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 1
    
    local ativo = valorInicial
    
    local function atualizar()
        checkbox.BackgroundColor3 = ativo and Cores.Destaque or Cores.FundoTerciario
        checkbox.Text = ativo and "✓" or ""
    end
    
    checkbox.MouseButton1Click:Connect(function()
        ativo = not ativo
        atualizar()
        if callback then callback(ativo) end
    end)
    
    checkbox.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    checkbox.MouseLeave:Connect(function()
        task.delay(0.1, function()
            if not Estado.Arrastando then
                Estado.InteragindoComUI = false
            end
        end)
    end)
    
    return container, function(novoValor)
        ativo = novoValor
        atualizar()
    end
end

-- Criar slider estilizado
local function CriarSlider(parent, texto, posicaoY, min, max, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 50)
    container.ZIndex = ZIndexBase + 1
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 1
    
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Name = "Valor"
    valorLabel.Parent = container
    valorLabel.BackgroundTransparency = 1
    valorLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valorLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.Text = "[" .. tostring(valorInicial) .. "]"
    valorLabel.TextColor3 = Cores.TextoSecundario
    valorLabel.TextSize = 14
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.ZIndex = ZIndexBase + 1
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "Background"
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Cores.FundoTerciario
    sliderBg.BorderSizePixel = 0
    sliderBg.Position = UDim2.new(0, 0, 0, 25)
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.ZIndex = ZIndexBase + 1
    
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 4)
    cornerBg.Parent = sliderBg
    
    local porcentagem = (valorInicial - min) / (max - min)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Cores.Destaque
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
    sliderFill.ZIndex = ZIndexBase + 2
    
    local cornerFill = Instance.new("UICorner")
    cornerFill.CornerRadius = UDim.new(0, 4)
    cornerFill.Parent = sliderFill
    
    local arrastando = false
    
    local function atualizarSlider(inputPos)
        local posRelativa = (inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        posRelativa = math.clamp(posRelativa, 0, 1)
        
        local valor = math.floor(min + (max - min) * posRelativa)
        
        sliderFill.Size = UDim2.new(posRelativa, 0, 1, 0)
        valorLabel.Text = "[" .. tostring(valor) .. "]"
        
        if callback then callback(valor) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.InteragindoComUI = true
            Estado.Arrastando = true
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
            task.delay(0.1, function()
                Estado.Arrastando = false
                Estado.InteragindoComUI = false
            end)
        end
    end)
    
    return container
end

-- CORRIGIDO: Criar dropdown com ZIndex alto
local function CriarDropdown(parent, texto, posicaoY, opcoes, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 55)
    container.ZIndex = ZIndexBase + 10
    container.ClipsDescendants = false  -- IMPORTANTE: Permitir overflow
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 10
    
    local dropButton = Instance.new("TextButton")
    dropButton.Name = "Button"
    dropButton.Parent = container
    dropButton.BackgroundColor3 = Cores.FundoTerciario
    dropButton.BorderSizePixel = 0
    dropButton.Position = UDim2.new(0, 0, 0, 25)
    dropButton.Size = UDim2.new(1, 0, 0, 28)
    dropButton.Font = Enum.Font.Gotham
    dropButton.Text = "  " .. (valorInicial or opcoes[1] or "Selecionar")
    dropButton.TextColor3 = Cores.Texto
    dropButton.TextSize = 13
    dropButton.TextXAlignment = Enum.TextXAlignment.Left
    dropButton.ZIndex = ZIndexBase + 11
    
    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 4)
    cornerBtn.Parent = dropButton
    
    local seta = Instance.new("TextLabel")
    seta.Name = "Seta"
    seta.Parent = dropButton
    seta.BackgroundTransparency = 1
    seta.Position = UDim2.new(1, -25, 0, 0)
    seta.Size = UDim2.new(0, 20, 1, 0)
    seta.Font = Enum.Font.GothamBold
    seta.Text = "▼"
    seta.TextColor3 = Cores.Destaque
    seta.TextSize = 12
    seta.ZIndex = ZIndexBase + 12
    
    -- Lista de opções com ZIndex muito alto
    local listaFrame = Instance.new("Frame")
    listaFrame.Name = "Lista"
    listaFrame.Parent = container
    listaFrame.BackgroundColor3 = Cores.FundoSecundario
    listaFrame.BorderSizePixel = 0
    listaFrame.Position = UDim2.new(0, 0, 0, 55)
    listaFrame.Size = UDim2.new(1, 0, 0, #opcoes * 25)
    listaFrame.Visible = false
    listaFrame.ZIndex = ZIndexDropdown  -- ZIndex muito alto
    listaFrame.ClipsDescendants = true
    
    local cornerLista = Instance.new("UICorner")
    cornerLista.CornerRadius = UDim.new(0, 4)
    cornerLista.Parent = listaFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Cores.Borda
    stroke.Thickness = 1
    stroke.Parent = listaFrame
    
    local aberto = false
    
    for i, opcao in ipairs(opcoes) do
        local opcaoBtn = Instance.new("TextButton")
        opcaoBtn.Name = "Opcao_" .. opcao
        opcaoBtn.Parent = listaFrame
        opcaoBtn.BackgroundColor3 = Cores.FundoSecundario
        opcaoBtn.BackgroundTransparency = 0
        opcaoBtn.BorderSizePixel = 0
        opcaoBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
        opcaoBtn.Size = UDim2.new(1, 0, 0, 25)
        opcaoBtn.Font = Enum.Font.Gotham
        opcaoBtn.Text = "  " .. opcao
        opcaoBtn.TextColor3 = Cores.Texto
        opcaoBtn.TextSize = 13
        opcaoBtn.TextXAlignment = Enum.TextXAlignment.Left
        opcaoBtn.ZIndex = ZIndexDropdown + 1
        
        opcaoBtn.MouseEnter:Connect(function()
            Estado.InteragindoComUI = true
            opcaoBtn.BackgroundColor3 = Cores.Destaque
        end)
        
        opcaoBtn.MouseLeave:Connect(function()
            opcaoBtn.BackgroundColor3 = Cores.FundoSecundario
        end)
        
        opcaoBtn.MouseButton1Click:Connect(function()
            dropButton.Text = "  " .. opcao
            listaFrame.Visible = false
            aberto = false
            seta.Text = "▼"
            if callback then callback(opcao) end
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
            end)
        end)
    end
    
    dropButton.MouseButton1Click:Connect(function()
        aberto = not aberto
        listaFrame.Visible = aberto
        seta.Text = aberto and "▲" or "▼"
        Estado.InteragindoComUI = aberto
        
        -- Fechar outros dropdowns
        for _, outro in pairs(DropdownsAbertos) do
            if outro ~= listaFrame then
                outro.Visible = false
            end
        end
        
        if aberto then
            table.insert(DropdownsAbertos, listaFrame)
        end
    end)
    
    dropButton.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    return container
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        CRIAÇÃO DA UI PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarUI()
    -- Destruir UI existente
    pcall(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)
    
    -- Criar ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    
    -- Tentar colocar no CoreGui, senão no PlayerGui
    local sucesso = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    
    if not sucesso then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Frame Principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Cores.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
    MainFrame.Size = UDim2.new(0, 350, 0, 400)
    MainFrame.Active = true
    MainFrame.ZIndex = ZIndexBase
    MainFrame.ClipsDescendants = false  -- IMPORTANTE: Permitir dropdowns
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Cores.Borda
    mainStroke.Thickness = 1
    mainStroke.Parent = MainFrame
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = MainFrame
    titleBar.BackgroundColor3 = Cores.FundoSecundario
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.ZIndex = ZIndexBase + 1
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Corrigir cantos inferiores do título
    local titleFix = Instance.new("Frame")
    titleFix.Name = "TitleFix"
    titleFix.Parent = titleBar
    titleFix.BackgroundColor3 = Cores.FundoSecundario
    titleFix.BorderSizePixel = 0
    titleFix.Position = UDim2.new(0, 0, 1, -8)
    titleFix.Size = UDim2.new(1, 0, 0, 8)
    titleFix.ZIndex = ZIndexBase + 1
    
    -- Botão minimizar
    local btnMinimizar = Instance.new("TextButton")
    btnMinimizar.Name = "Minimizar"
    btnMinimizar.Parent = titleBar
    btnMinimizar.BackgroundColor3 = Cores.Destaque
    btnMinimizar.BorderSizePixel = 0
    btnMinimizar.Position = UDim2.new(0, 8, 0.5, -10)
    btnMinimizar.Size = UDim2.new(0, 20, 0, 20)
    btnMinimizar.Font = Enum.Font.GothamBold
    btnMinimizar.Text = "−"
    btnMinimizar.TextColor3 = Cores.Texto
    btnMinimizar.TextSize = 16
    btnMinimizar.ZIndex = ZIndexBase + 2
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = btnMinimizar
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Parent = titleBar
    titulo.BackgroundTransparency = 1
    titulo.Position = UDim2.new(0, 35, 0, 0)
    titulo.Size = UDim2.new(1, -70, 1, 0)
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "SAVAGECHEATS_"
    titulo.TextColor3 = Cores.Texto
    titulo.TextSize = 16
    titulo.ZIndex = ZIndexBase + 1
    
    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Name = "Fechar"
    btnFechar.Parent = titleBar
    btnFechar.BackgroundColor3 = Cores.Destaque
    btnFechar.BorderSizePixel = 0
    btnFechar.Position = UDim2.new(1, -28, 0.5, -10)
    btnFechar.Size = UDim2.new(0, 20, 0, 20)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.Text = "×"
    btnFechar.TextColor3 = Cores.Texto
    btnFechar.TextSize = 18
    btnFechar.ZIndex = ZIndexBase + 2
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = btnFechar
    
    -- Tornar arrastável pelo título
    TornarArrastavel(MainFrame, titleBar)
    
    -- Container de abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = MainFrame
    tabContainer.BackgroundTransparency = 1
    tabContainer.Position = UDim2.new(0, 10, 0, 45)
    tabContainer.Size = UDim2.new(1, -20, 0, 35)
    tabContainer.ZIndex = ZIndexBase + 1
    
    -- Botões de aba
    local abas = {"Esp", "Aim", "Config"}
    local botoesAba = {}
    local conteudoAbas = {}
    
    for i, nomeAba in ipairs(abas) do
        local btnAba = Instance.new("TextButton")
        btnAba.Name = "Tab_" .. nomeAba
        btnAba.Parent = tabContainer
        btnAba.BackgroundColor3 = nomeAba == "Aim" and Cores.Destaque or Cores.FundoTerciario
        btnAba.BorderSizePixel = 0
        btnAba.Position = UDim2.new((i - 1) / 3, 5, 0, 0)
        btnAba.Size = UDim2.new(1 / 3, -10, 1, 0)
        btnAba.Font = Enum.Font.GothamBold
        btnAba.Text = nomeAba
        btnAba.TextColor3 = Cores.Texto
        btnAba.TextSize = 14
        btnAba.ZIndex = ZIndexBase + 2
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 4)
        tabCorner.Parent = btnAba
        
        botoesAba[nomeAba] = btnAba
        
        -- Container de conteúdo para cada aba
        local conteudo = Instance.new("ScrollingFrame")
        conteudo.Name = "Conteudo_" .. nomeAba
        conteudo.Parent = MainFrame
        conteudo.BackgroundTransparency = 1
        conteudo.Position = UDim2.new(0, 0, 0, 85)
        conteudo.Size = UDim2.new(1, 0, 1, -90)
        conteudo.ScrollBarThickness = 4
        conteudo.ScrollBarImageColor3 = Cores.Destaque
        conteudo.CanvasSize = UDim2.new(0, 0, 0, 500)
        conteudo.Visible = nomeAba == "Aim"
        conteudo.ZIndex = ZIndexBase + 1
        conteudo.ClipsDescendants = false  -- IMPORTANTE: Permitir dropdowns
        
        conteudoAbas[nomeAba] = conteudo
        
        btnAba.MouseButton1Click:Connect(function()
            CurrentTab = nomeAba
            
            for nome, btn in pairs(botoesAba) do
                btn.BackgroundColor3 = nome == nomeAba and Cores.Destaque or Cores.FundoTerciario
            end
            
            for nome, cont in pairs(conteudoAbas) do
                cont.Visible = nome == nomeAba
            end
        end)
        
        btnAba.MouseEnter:Connect(function()
            Estado.InteragindoComUI = true
        end)
        
        btnAba.MouseLeave:Connect(function()
            task.delay(0.1, function()
                if not Estado.Arrastando then
                    Estado.InteragindoComUI = false
                end
            end)
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA AIM
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaAim = conteudoAbas["Aim"]
    local posY = 5
    
    CriarCheckbox(abaAim, "Aimbot Ativo", posY, Config.AimbotAtivo, function(valor)
        Config.AimbotAtivo = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Bala Mágica (Silent Aim)", posY, Config.BalaMagica, function(valor)
        Config.BalaMagica = valor
        if valor then
            AtivarBalaMagica()
        else
            DesativarBalaMagica()
        end
    end)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Pular Abatidos", posY, Config.PularAbatidos, function(valor)
        Config.PularAbatidos = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Ignorar Paredes", posY, Config.IgnorarParedes, function(valor)
        Config.IgnorarParedes = valor
    end)
    posY = posY + 40
    
    CriarSlider(abaAim, "Taxa Headshot", posY, 0, 100, Config.TaxaHeadshot, function(valor)
        Config.TaxaHeadshot = valor
    end)
    posY = posY + 55
    
    CriarDropdown(abaAim, "Parte Alvo", posY, {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, Config.ParteAlvo, function(valor)
        Config.ParteAlvo = valor
    end)
    posY = posY + 60
    
    CriarSlider(abaAim, "Raio FOV", posY, 50, 500, Config.FOVRaio, function(valor)
        Config.FOVRaio = valor
    end)
    posY = posY + 55
    
    CriarDropdown(abaAim, "Estilo de Mira", posY, {"FOV", "MaisProximo", "Aleatorio"}, Config.EstiloMira, function(valor)
        Config.EstiloMira = valor
    end)
    posY = posY + 60
    
    abaAim.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA ESP
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaEsp = conteudoAbas["Esp"]
    posY = 5
    
    CriarCheckbox(abaEsp, "ESP Ativo", posY, Config.ESPAtivo, function(valor)
        Config.ESPAtivo = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Box", posY, Config.ESPBox, function(valor)
        Config.ESPBox = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Nome", posY, Config.ESPNome, function(valor)
        Config.ESPNome = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Vida", posY, Config.ESPVida, function(valor)
        Config.ESPVida = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Distância", posY, Config.ESPDistancia, function(valor)
        Config.ESPDistancia = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Tracer", posY, Config.ESPTracer, function(valor)
        Config.ESPTracer = valor
    end)
    posY = posY + 35
    
    abaEsp.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA CONFIG
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaConfig = conteudoAbas["Config"]
    posY = 5
    
    CriarCheckbox(abaConfig, "Suavização Ativa", posY, Config.SuavizacaoAtiva, function(valor)
        Config.SuavizacaoAtiva = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Força Suavização", posY, 0, 95, math.floor(Config.Suavizacao * 100), function(valor)
        Config.Suavizacao = valor / 100
    end)
    posY = posY + 55
    
    CriarCheckbox(abaConfig, "Disparo Automático", posY, Config.DisparoAutomatico, function(valor)
        Config.DisparoAutomatico = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Delay Disparo (ms)", posY, 50, 500, math.floor(Config.DelayDisparo * 1000), function(valor)
        Config.DelayDisparo = valor / 1000
    end)
    posY = posY + 55
    
    CriarCheckbox(abaConfig, "Predição de Movimento", posY, Config.PredicaoAtiva, function(valor)
        Config.PredicaoAtiva = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Força Predição", posY, 0, 50, math.floor(Config.ForcaPredicao * 100), function(valor)
        Config.ForcaPredicao = valor / 100
    end)
    posY = posY + 55
    
    CriarCheckbox(abaConfig, "Mostrar FOV", posY, Config.FOVVisivel, function(valor)
        Config.FOVVisivel = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Distância Máxima", posY, 100, 2000, Config.DistanciaMaxima, function(valor)
        Config.DistanciaMaxima = valor
    end)
    posY = posY + 55
    
    AtualizarTimesDisponiveis()
    
    CriarDropdown(abaConfig, "Modo de Time", posY, {"Inimigos", "Todos", "TimeEspecifico"}, Config.ModoTime, function(valor)
        Config.ModoTime = valor
    end)
    posY = posY + 60
    
    if #Estado.TimesDisponiveis > 0 then
        CriarDropdown(abaConfig, "Time Alvo", posY, Estado.TimesDisponiveis, Config.TimeAlvo, function(valor)
            Config.TimeAlvo = valor
        end)
        posY = posY + 60
    end
    
    abaConfig.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- EVENTOS DOS BOTÕES
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local minimizado = false
    local tamanhoOriginal = MainFrame.Size
    
    btnMinimizar.MouseButton1Click:Connect(function()
        minimizado = not minimizado
        
        if minimizado then
            MainFrame.Size = UDim2.new(0, 350, 0, 35)
            btnMinimizar.Text = "+"
        else
            MainFrame.Size = tamanhoOriginal
            btnMinimizar.Text = "−"
        end
        
        for _, conteudo in pairs(conteudoAbas) do
            conteudo.Visible = not minimizado and conteudo.Name == "Conteudo_" .. CurrentTab
        end
        
        tabContainer.Visible = not minimizado
    end)
    
    btnFechar.MouseButton1Click:Connect(function()
        DestruirTudo()
    end)
    
    return ScreenGui
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        LOOP PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function LoopPrincipal()
    Conexoes.RenderStepped = RunService.RenderStepped:Connect(function()
        -- Atualizar FOV Circle
        AtualizarFOVCircle()
        
        -- Atualizar ESP
        for _, jogador in pairs(Players:GetPlayers()) do
            AtualizarESPJogador(jogador)
        end
        
        -- Sistema de Aimbot
        if Config.AimbotAtivo and not Estado.InteragindoComUI and not Estado.Arrastando then
            local alvo, parte = EncontrarMelhorAlvo()
            
            if alvo and parte then
                Estado.AlvoAtual = alvo
                Estado.ParteAlvoAtual = parte
                Estado.Travado = true
                
                -- Calcular posição com predição
                local posicaoAlvo = PreverPosicao(alvo.Character, parte)
                
                -- Mirar (só se não for bala mágica)
                if not Config.BalaMagica then
                    MirarEm(posicaoAlvo)
                end
                
                -- Disparo automático
                if Config.DisparoAutomatico then
                    ExecutarDisparo()
                end
            else
                Estado.AlvoAtual = nil
                Estado.ParteAlvoAtual = nil
                Estado.Travado = false
            end
        else
            Estado.AlvoAtual = nil
            Estado.ParteAlvoAtual = nil
            Estado.Travado = false
        end
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        DESTRUIÇÃO E LIMPEZA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

function DestruirTudo()
    -- Desativar bala mágica
    DesativarBalaMagica()
    
    -- Desconectar todas as conexões
    for nome, conexao in pairs(Conexoes) do
        pcall(function()
            conexao:Disconnect()
        end)
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Destruir UI
    pcall(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
    
    -- Limpar flags globais
    _G.SAVAGECHEATS_LOADED = false
    _G.SAVAGECHEATS_DESTROY = nil
    
    print("[SAVAGECHEATS_] Script descarregado com sucesso!")
end

-- Registrar função de destruição global
_G.SAVAGECHEATS_DESTROY = DestruirTudo

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        INICIALIZAÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    print("╔═══════════════════════════════════════════════════════════════════════════════════════════╗")
    print("║                           SAVAGECHEATS_ AIMBOT UNIVERSAL v4.0                             ║")
    print("║                        Otimizado para Mobile Android/iOS                                  ║")
    print("╚═══════════════════════════════════════════════════════════════════════════════════════════╝")
    
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Inicializar ESP
    InicializarESP()
    
    -- Criar UI
    CriarUI()
    
    -- Iniciar loop principal
    LoopPrincipal()
    
    -- Atualizar times quando mudar
    Conexoes.TeamChanged = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        AtualizarTimesDisponiveis()
    end)
    
    -- Monitorar respawn
    Conexoes.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        Camera = Workspace.CurrentCamera
    end)
    
    print("[SAVAGECHEATS_] Carregado com sucesso!")
    print("[SAVAGECHEATS_] Arraste a UI pelo título para mover")
    print("[SAVAGECHEATS_] Use o botão − para minimizar e × para fechar")
end

-- Executar inicialização
Inicializar()
