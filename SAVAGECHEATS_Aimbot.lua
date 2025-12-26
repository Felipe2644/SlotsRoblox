--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                           SAVAGECHEATS_ AIMBOT UNIVERSAL                                  ║
    ║                        Otimizado para Mobile Android/iOS                                  ║
    ║                                  Versão 3.0                                               ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════╣
    ║  • FOV Centralizado Corretamente                                                          ║
    ║  • Suavização Ajustável (Anti-Grude)                                                      ║
    ║  • Sistema de Times Inteligente                                                           ║
    ║  • Bala Mágica (Silent Aim)                                                               ║
    ║  • ESP Completo                                                                           ║
    ║  • UI em Português (Estilo SAVAGECHEATS_)                                                 ║
    ║  • 100% Compatível com Executores Mobile                                                  ║
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
        _G.SAVAGECHEATS_DESTROY()
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
    BalaMagica = false,          -- Silent Aim através de paredes
    PularAbatidos = true,        -- Skip Knocked
    PularVerificacaoParede = false, -- Skip Vischeck
    
    -- Configurações de Mira
    ParteAlvo = "Head",          -- Head, HumanoidRootPart, Torso
    EstiloMira = "FOV",          -- FOV, MaisProximo, Aleatorio
    TaxaHeadshot = 100,          -- Porcentagem de headshots (0-100)
    
    -- FOV
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(200, 40, 40),
    FOVCorTravado = Color3.fromRGB(0, 255, 0),
    
    -- Suavização (Anti-Grude)
    Suavizacao = 0.5,            -- 0 = instantâneo, 1 = muito suave
    SuavizacaoAtiva = true,
    
    -- Sistema de Times
    ModoTime = "Inimigos",       -- Inimigos, Todos, TimeEspecifico
    TimeAlvo = "",               -- Nome do time específico
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
    
    -- Disparo Automático
    DisparoAutomatico = false,
    MetodoDisparo = "Auto",      -- Auto, Mouse1Click, VIM, Touch
    DelayDisparo = 0.1,
    
    -- Predição de Movimento
    PredicaoAtiva = false,
    ForcaPredicao = 0.15,
    
    -- Verificações
    VerificarVivo = true,
    VerificarParede = false,     -- Desativado por padrão (lag)
    DistanciaMaxima = 1000,
    
    -- Mobile
    AtivarComToque = true,       -- Ativar mira ao tocar na tela
    BotaoMiraVisivel = true,
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
}

local Conexoes = {}
local ElementosESP = {}
local ElementosUI = {}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Função segura para criar Drawing
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
        warn("[SAVAGECHEATS_] Erro ao criar Drawing:", objeto)
        return nil
    end
end

-- Centro da tela CORRETO para mobile (sem GuiInset para Drawing)
local function GetCentroTela()
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

-- Centro da tela para UI (com GuiInset)
local function GetCentroTelaUI()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y / 2) + inset.Y)
end

-- Converter posição 3D para 2D na tela
local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel, pos.Z
end

-- Calcular distância 2D na tela
local function Distancia2D(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Calcular distância 3D no mundo
local function Distancia3D(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Verificar se posição está dentro do FOV
local function DentroDoFOV(posicaoTela)
    local centro = GetCentroTela()
    local distancia = Distancia2D(posicaoTela, centro)
    return distancia <= Config.FOVRaio, distancia
end

-- Obter todos os times disponíveis no jogo
local function AtualizarTimesDisponiveis()
    Estado.TimesDisponiveis = {}
    
    pcall(function()
        for _, team in pairs(Teams:GetTeams()) do
            table.insert(Estado.TimesDisponiveis, team.Name)
        end
    end)
    
    -- Adicionar opções padrão
    if #Estado.TimesDisponiveis == 0 then
        Estado.TimesDisponiveis = {"Nenhum time detectado"}
    end
end

-- Verificar se jogador é do mesmo time
local function MesmoTime(jogador)
    if not Config.VerificarTime then
        return false
    end
    
    -- Se não há times no jogo
    if not LocalPlayer.Team or not jogador.Team then
        return false
    end
    
    return LocalPlayer.Team == jogador.Team
end

-- Verificar se jogador deve ser alvo baseado no modo de time
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
    
    if Config.VerificarVivo and humanoid.Health <= 0 then
        return false
    end
    
    -- Verificar se está abatido (knocked)
    if Config.PularAbatidos then
        -- Verificações comuns para estado "knocked"
        local knocked = personagem:FindFirstChild("Knocked")
        local downed = personagem:FindFirstChild("Downed")
        local ragdoll = personagem:FindFirstChild("Ragdoll")
        
        if knocked or downed or ragdoll then
            return false
        end
        
        -- Verificar atributos
        pcall(function()
            if personagem:GetAttribute("Knocked") or 
               personagem:GetAttribute("Downed") or
               humanoid:GetAttribute("Knocked") then
                return false
            end
        end)
        
        -- Verificar estado do humanoid
        if humanoid:GetState() == Enum.HumanoidStateType.Dead or
           humanoid:GetState() == Enum.HumanoidStateType.Physics then
            return false
        end
    end
    
    return true
end

-- Verificar linha de visão (raycast)
local function TemLinhaDeVisao(origem, destino)
    if Config.PularVerificacaoParede then
        return true
    end
    
    if not Config.VerificarParede then
        return true
    end
    
    local direcao = (destino - origem).Unit
    local distancia = (destino - origem).Magnitude
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local resultado = Workspace:Raycast(origem, direcao * distancia, params)
    
    if resultado then
        -- Verificar se acertou o alvo ou uma parede
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
    
    -- Decidir se vai para cabeça baseado na taxa de headshot
    local parteDesejada = Config.ParteAlvo
    
    if Config.TaxaHeadshot < 100 then
        local chance = math.random(1, 100)
        if chance > Config.TaxaHeadshot then
            parteDesejada = "HumanoidRootPart"
        else
            parteDesejada = "Head"
        end
    end
    
    -- Tentar encontrar a parte
    local parte = personagem:FindFirstChild(parteDesejada)
    
    -- Fallbacks
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
                                        SISTEMA DE BUSCA DE ALVOS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = math.huge
    
    local centro = GetCentroTela()
    local posicaoCamera = Camera.CFrame.Position
    
    for _, jogador in pairs(Players:GetPlayers()) do
        -- Pular se não deve ser alvo
        if not DeveSerAlvo(jogador) then
            continue
        end
        
        local personagem = jogador.Character
        if not personagem then continue end
        
        -- Verificar se está vivo
        if not EstaVivo(personagem) then
            continue
        end
        
        -- Obter parte para mirar
        local parte = GetParteAlvo(personagem)
        if not parte then continue end
        
        -- Verificar distância 3D
        local distancia3D = Distancia3D(posicaoCamera, parte.Position)
        if distancia3D > Config.DistanciaMaxima then
            continue
        end
        
        -- Converter para posição na tela
        local posicaoTela, visivel, profundidade = WorldToScreen(parte.Position)
        
        -- Verificar se está visível na tela
        if not visivel or profundidade < 0 then
            continue
        end
        
        -- Verificar linha de visão (se não for bala mágica)
        if not Config.BalaMagica and not Config.PularVerificacaoParede then
            if not TemLinhaDeVisao(posicaoCamera, parte.Position) then
                continue
            end
        end
        
        -- Calcular distância baseado no estilo de mira
        local distanciaCalculo
        
        if Config.EstiloMira == "FOV" then
            local dentroFOV, distanciaFOV = DentroDoFOV(posicaoTela)
            if not dentroFOV then
                continue
            end
            distanciaCalculo = distanciaFOV
        elseif Config.EstiloMira == "MaisProximo" then
            distanciaCalculo = distancia3D
        elseif Config.EstiloMira == "Aleatorio" then
            distanciaCalculo = math.random()
        end
        
        -- Verificar se é o melhor alvo
        if distanciaCalculo < menorDistancia then
            menorDistancia = distanciaCalculo
            melhorAlvo = jogador
            melhorParte = parte
        end
    end
    
    return melhorAlvo, melhorParte
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE PREDIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local VelocidadesAnteriores = {}

local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not parte then
        return parte.Position
    end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then
        return parte.Position
    end
    
    -- Calcular velocidade
    local velocidade = rootPart.AssemblyLinearVelocity
    
    -- Aplicar predição
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
    
    local posicaoCamera = Camera.CFrame.Position
    local direcao = (posicaoAlvo - posicaoCamera).Unit
    
    -- Calcular CFrame alvo
    local cframeAlvo = CFrame.lookAt(posicaoCamera, posicaoAlvo)
    
    -- Aplicar suavização se ativa
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        local fatorLerp = 1 - math.clamp(Config.Suavizacao, 0, 0.95)
        Camera.CFrame = Camera.CFrame:Lerp(cframeAlvo, fatorLerp)
    else
        Camera.CFrame = cframeAlvo
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE DISPARO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function ExecutarDisparo()
    if not Config.DisparoAutomatico then return end
    
    local agora = tick()
    if agora - Estado.UltimoDisparo < Config.DelayDisparo then
        return
    end
    
    Estado.UltimoDisparo = agora
    
    local metodo = Config.MetodoDisparo
    
    -- Auto: tentar múltiplos métodos
    if metodo == "Auto" then
        -- Método 1: mouse1click
        local sucesso1 = pcall(function()
            mouse1click()
        end)
        
        if not sucesso1 then
            -- Método 2: VirtualInputManager
            local sucesso2 = pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                local centro = GetCentroTela()
                VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, true, game, 1)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, false, game, 1)
            end)
        end
    elseif metodo == "Mouse1Click" then
        pcall(function() mouse1click() end)
    elseif metodo == "VIM" then
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            local centro = GetCentroTela()
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, false, game, 1)
        end)
    elseif metodo == "Touch" then
        pcall(function()
            -- Simular toque para mobile
            local VIM = game:GetService("VirtualInputManager")
            local centro = GetCentroTela()
            VIM:SendTouchEvent(centro.X, centro.Y, 0, Enum.TouchType.Begin, "", game)
            task.wait(0.01)
            VIM:SendTouchEvent(centro.X, centro.Y, 0, Enum.TouchType.End, "", game)
        end)
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE BALA MÁGICA (SILENT AIM)
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local OldNamecall = nil
local HookAtivo = false

local function GetAlvoParaBalaMagica()
    if not Config.BalaMagica or not Config.AimbotAtivo then
        return nil
    end
    
    local alvo, parte = EncontrarMelhorAlvo()
    if alvo and parte then
        return parte
    end
    
    return nil
end

local function AtivarBalaMagica()
    if HookAtivo then return end
    
    local sucesso = pcall(function()
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local metodo = getnamecallmethod()
            local args = {...}
            
            -- Verificar se é um método de raycast
            if metodo == "FindPartOnRay" or metodo == "FindPartOnRayWithIgnoreList" or 
               metodo == "FindPartOnRayWithWhitelist" or metodo == "Raycast" then
                
                local alvo = GetAlvoParaBalaMagica()
                
                if alvo then
                    if metodo == "Raycast" then
                        -- Para Workspace:Raycast(origin, direction, params)
                        local origem = args[1]
                        local direcao = (alvo.Position - origem).Unit * 1000
                        args[2] = direcao
                    else
                        -- Para métodos FindPartOnRay
                        local ray = args[1]
                        if typeof(ray) == "Ray" then
                            local origem = ray.Origin
                            local direcao = (alvo.Position - origem).Unit * ray.Direction.Magnitude
                            args[1] = Ray.new(origem, direcao)
                        end
                    end
                end
            end
            
            return OldNamecall(self, unpack(args))
        end)
        
        HookAtivo = true
    end)
    
    if not sucesso then
        warn("[SAVAGECHEATS_] Bala Mágica não suportada neste executor")
    end
end

local function DesativarBalaMagica()
    if not HookAtivo or not OldNamecall then return end
    
    pcall(function()
        hookmetamethod(game, "__namecall", OldNamecall)
        HookAtivo = false
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
    
    -- Atualizar posição para o centro da tela
    FOVCircle.Position = GetCentroTela()
    FOVCircle.Radius = Config.FOVRaio
    FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
    
    -- Mudar cor se travado em alvo
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
    
    -- Remover ESP existente
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
        BoxFill = CriarDrawing("Square", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Filled = true,
            Visible = false,
            ZIndex = 997,
            Transparency = 0.3
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
        }),
        BarraVida = CriarDrawing("Square", {
            Thickness = 1,
            Color = Color3.new(0, 1, 0),
            Filled = true,
            Visible = false,
            ZIndex = 999
        }),
        BarraVidaFundo = CriarDrawing("Square", {
            Thickness = 1,
            Color = Color3.new(0.2, 0.2, 0.2),
            Filled = true,
            Visible = false,
            ZIndex = 998
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
    
    -- Calcular posições na tela
    local posRaiz, visivelRaiz = WorldToScreen(rootPart.Position)
    local posCabeca, visivelCabeca = WorldToScreen(head and head.Position + Vector3.new(0, 0.5, 0) or rootPart.Position + Vector3.new(0, 2, 0))
    local posPes, visivelPes = WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not visivelRaiz then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    -- Determinar cor baseado no time
    local cor = MesmoTime(jogador) and Config.ESPCorAliado or Config.ESPCorInimigo
    
    -- Calcular tamanho da box
    local altura = math.abs(posCabeca.Y - posPes.Y)
    local largura = altura / 2
    
    local boxPos = Vector2.new(posRaiz.X - largura / 2, posCabeca.Y)
    local boxSize = Vector2.new(largura, altura)
    
    -- Atualizar Box
    if esp.Box and Config.ESPBox then
        esp.Box.Position = boxPos
        esp.Box.Size = boxSize
        esp.Box.Color = cor
        esp.Box.Visible = true
    elseif esp.Box then
        esp.Box.Visible = false
    end
    
    -- Atualizar Nome
    if esp.Nome and Config.ESPNome then
        esp.Nome.Position = Vector2.new(posRaiz.X, posCabeca.Y - 18)
        esp.Nome.Text = jogador.Name
        esp.Nome.Visible = true
    elseif esp.Nome then
        esp.Nome.Visible = false
    end
    
    -- Atualizar Vida
    if esp.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = humanoid.MaxHealth
        local porcentagem = math.floor((vida / vidaMax) * 100)
        
        esp.Vida.Position = Vector2.new(posRaiz.X, posPes.Y + 5)
        esp.Vida.Text = vida .. " HP (" .. porcentagem .. "%)"
        
        -- Cor baseada na vida
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
    
    -- Atualizar Distância
    if esp.Distancia and Config.ESPDistancia then
        local distancia = math.floor(Distancia3D(Camera.CFrame.Position, rootPart.Position))
        esp.Distancia.Position = Vector2.new(posRaiz.X, posPes.Y + 18)
        esp.Distancia.Text = distancia .. "m"
        esp.Distancia.Visible = true
    elseif esp.Distancia then
        esp.Distancia.Visible = false
    end
    
    -- Atualizar Tracer
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
    -- Criar ESP para jogadores existentes
    for _, jogador in pairs(Players:GetPlayers()) do
        CriarESPParaJogador(jogador)
    end
    
    -- Conexão para novos jogadores
    Conexoes.PlayerAdded = Players.PlayerAdded:Connect(function(jogador)
        CriarESPParaJogador(jogador)
    end)
    
    -- Conexão para jogadores saindo
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
                                        SISTEMA UI - SAVAGECHEATS_ STYLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local UI = {}
local AbaAtual = "Aim"

-- Cores do tema SAVAGECHEATS_
local Tema = {
    Fundo = Color3.fromRGB(20, 20, 25),
    FundoSecundario = Color3.fromRGB(30, 30, 35),
    Primaria = Color3.fromRGB(200, 40, 40),
    PrimariaClara = Color3.fromRGB(255, 60, 60),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoEscuro = Color3.fromRGB(150, 150, 150),
    Borda = Color3.fromRGB(60, 60, 65),
    Sucesso = Color3.fromRGB(50, 200, 50),
    Slider = Color3.fromRGB(180, 30, 30),
    SliderFundo = Color3.fromRGB(50, 50, 55),
}

local function CriarUI()
    -- Destruir UI existente
    pcall(function()
        if ElementosUI.ScreenGui then
            ElementosUI.ScreenGui:Destroy()
        end
    end)
    
    -- ScreenGui principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Tentar colocar no CoreGui, senão no PlayerGui
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        elseif protectgui then
            protectgui(ScreenGui)
            ScreenGui.Parent = CoreGui
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    ElementosUI.ScreenGui = ScreenGui
    
    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Tema.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    ElementosUI.MainFrame = MainFrame
    
    -- Cantos arredondados
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Borda
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Tema.Borda
    Stroke.Thickness = 1
    Stroke.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Tema.FundoSecundario
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header
    
    -- Botão Minimizar
    local BtnMinimizar = Instance.new("TextButton")
    BtnMinimizar.Name = "Minimizar"
    BtnMinimizar.Size = UDim2.new(0, 25, 0, 25)
    BtnMinimizar.Position = UDim2.new(0, 8, 0.5, -12)
    BtnMinimizar.BackgroundColor3 = Tema.Primaria
    BtnMinimizar.Text = "▼"
    BtnMinimizar.TextColor3 = Tema.Texto
    BtnMinimizar.TextSize = 12
    BtnMinimizar.Font = Enum.Font.GothamBold
    BtnMinimizar.BorderSizePixel = 0
    BtnMinimizar.Parent = Header
    
    local BtnMinCorner = Instance.new("UICorner")
    BtnMinCorner.CornerRadius = UDim.new(0, 4)
    BtnMinCorner.Parent = BtnMinimizar
    
    -- Título
    local Titulo = Instance.new("TextLabel")
    Titulo.Name = "Titulo"
    Titulo.Size = UDim2.new(1, -80, 1, 0)
    Titulo.Position = UDim2.new(0, 40, 0, 0)
    Titulo.BackgroundTransparency = 1
    Titulo.Text = "SAVAGECHEATS_"
    Titulo.TextColor3 = Tema.Texto
    Titulo.TextSize = 16
    Titulo.Font = Enum.Font.GothamBold
    Titulo.Parent = Header
    
    -- Botão Fechar
    local BtnFechar = Instance.new("TextButton")
    BtnFechar.Name = "Fechar"
    BtnFechar.Size = UDim2.new(0, 25, 0, 25)
    BtnFechar.Position = UDim2.new(1, -33, 0.5, -12)
    BtnFechar.BackgroundColor3 = Tema.Primaria
    BtnFechar.Text = "X"
    BtnFechar.TextColor3 = Tema.Texto
    BtnFechar.TextSize = 14
    BtnFechar.Font = Enum.Font.GothamBold
    BtnFechar.BorderSizePixel = 0
    BtnFechar.Parent = Header
    
    local BtnFecharCorner = Instance.new("UICorner")
    BtnFecharCorner.CornerRadius = UDim.new(0, 4)
    BtnFecharCorner.Parent = BtnFechar
    
    -- Container de Abas
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -20, 0, 35)
    TabContainer.Position = UDim2.new(0, 10, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    -- Criar botões de abas
    local abas = {"Esp", "Aim", "Config"}
    local larguraAba = (320 - 20) / 3
    
    for i, nomeAba in ipairs(abas) do
        local BtnAba = Instance.new("TextButton")
        BtnAba.Name = "Tab_" .. nomeAba
        BtnAba.Size = UDim2.new(0, larguraAba - 5, 1, 0)
        BtnAba.Position = UDim2.new(0, (i - 1) * larguraAba, 0, 0)
        BtnAba.BackgroundColor3 = nomeAba == AbaAtual and Tema.Primaria or Tema.FundoSecundario
        BtnAba.Text = nomeAba
        BtnAba.TextColor3 = Tema.Texto
        BtnAba.TextSize = 13
        BtnAba.Font = Enum.Font.GothamBold
        BtnAba.BorderSizePixel = 0
        BtnAba.Parent = TabContainer
        
        local AbaCorner = Instance.new("UICorner")
        AbaCorner.CornerRadius = UDim.new(0, 6)
        AbaCorner.Parent = BtnAba
        
        ElementosUI["Tab_" .. nomeAba] = BtnAba
    end
    
    -- Container de Conteúdo
    local ContentContainer = Instance.new("ScrollingFrame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -20, 1, -100)
    ContentContainer.Position = UDim2.new(0, 10, 0, 90)
    ContentContainer.BackgroundColor3 = Tema.FundoSecundario
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ScrollBarThickness = 4
    ContentContainer.ScrollBarImageColor3 = Tema.Primaria
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentContainer.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 6)
    ContentCorner.Parent = ContentContainer
    
    ElementosUI.ContentContainer = ContentContainer
    
    -- Layout para conteúdo
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.Parent = ContentContainer
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.Parent = ContentContainer
    
    -- Atualizar tamanho do canvas automaticamente
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Botão flutuante para abrir/fechar
    local BtnFlutuante = Instance.new("TextButton")
    BtnFlutuante.Name = "BtnFlutuante"
    BtnFlutuante.Size = UDim2.new(0, 50, 0, 50)
    BtnFlutuante.Position = UDim2.new(0, 10, 0.5, -25)
    BtnFlutuante.BackgroundColor3 = Tema.Primaria
    BtnFlutuante.Text = "🎯"
    BtnFlutuante.TextSize = 24
    BtnFlutuante.Font = Enum.Font.GothamBold
    BtnFlutuante.BorderSizePixel = 0
    BtnFlutuante.Parent = ScreenGui
    BtnFlutuante.Draggable = true
    
    local BtnFlutuanteCorner = Instance.new("UICorner")
    BtnFlutuanteCorner.CornerRadius = UDim.new(0.5, 0)
    BtnFlutuanteCorner.Parent = BtnFlutuante
    
    ElementosUI.BtnFlutuante = BtnFlutuante
    
    -- Status no botão flutuante
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    StatusLabel.Position = UDim2.new(0, 0, 1, 2)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "OFF"
    StatusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.Parent = BtnFlutuante
    
    ElementosUI.StatusLabel = StatusLabel
    
    return ScreenGui
end

-- Função para criar checkbox estilo SAVAGECHEATS_
local function CriarCheckbox(parent, texto, valorInicial, callback, ordem)
    local Container = Instance.new("Frame")
    Container.Name = "Checkbox_" .. texto
    Container.Size = UDim2.new(1, -20, 0, 30)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = ordem or 0
    Container.Parent = parent
    
    local Checkbox = Instance.new("TextButton")
    Checkbox.Name = "Box"
    Checkbox.Size = UDim2.new(0, 22, 0, 22)
    Checkbox.Position = UDim2.new(0, 0, 0.5, -11)
    Checkbox.BackgroundColor3 = valorInicial and Tema.Primaria or Tema.FundoSecundario
    Checkbox.Text = valorInicial and "✓" or ""
    Checkbox.TextColor3 = Tema.Texto
    Checkbox.TextSize = 16
    Checkbox.Font = Enum.Font.GothamBold
    Checkbox.BorderSizePixel = 0
    Checkbox.Parent = Container
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 4)
    BoxCorner.Parent = Checkbox
    
    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Tema.Primaria
    BoxStroke.Thickness = 2
    BoxStroke.Parent = Checkbox
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -35, 1, 0)
    Label.Position = UDim2.new(0, 32, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = texto
    Label.TextColor3 = Tema.Texto
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local valor = valorInicial
    
    Checkbox.MouseButton1Click:Connect(function()
        valor = not valor
        Checkbox.BackgroundColor3 = valor and Tema.Primaria or Tema.FundoSecundario
        Checkbox.Text = valor and "✓" or ""
        if callback then
            callback(valor)
        end
    end)
    
    return Container, function() return valor end, function(v)
        valor = v
        Checkbox.BackgroundColor3 = valor and Tema.Primaria or Tema.FundoSecundario
        Checkbox.Text = valor and "✓" or ""
    end
end

-- Função para criar slider estilo SAVAGECHEATS_
local function CriarSlider(parent, texto, minimo, maximo, valorInicial, callback, ordem, sufixo)
    sufixo = sufixo or ""
    
    local Container = Instance.new("Frame")
    Container.Name = "Slider_" .. texto
    Container.Size = UDim2.new(1, -20, 0, 50)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = ordem or 0
    Container.Parent = parent
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = texto
    Label.TextColor3 = Tema.Texto
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local ValorLabel = Instance.new("TextLabel")
    ValorLabel.Name = "Valor"
    ValorLabel.Size = UDim2.new(0.4, 0, 0, 20)
    ValorLabel.Position = UDim2.new(0.6, 0, 0, 0)
    ValorLabel.BackgroundTransparency = 1
    ValorLabel.Text = "[" .. tostring(math.floor(valorInicial)) .. sufixo .. "]"
    ValorLabel.TextColor3 = Tema.TextoEscuro
    ValorLabel.TextSize = 13
    ValorLabel.Font = Enum.Font.Gotham
    ValorLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValorLabel.Parent = Container
    
    local SliderBG = Instance.new("Frame")
    SliderBG.Name = "SliderBG"
    SliderBG.Size = UDim2.new(1, 0, 0, 20)
    SliderBG.Position = UDim2.new(0, 0, 0, 25)
    SliderBG.BackgroundColor3 = Tema.SliderFundo
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = Container
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 4)
    SliderCorner.Parent = SliderBG
    
    local porcentagemInicial = (valorInicial - minimo) / (maximo - minimo)
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "Fill"
    SliderFill.Size = UDim2.new(porcentagemInicial, 0, 1, 0)
    SliderFill.BackgroundColor3 = Tema.Slider
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 4)
    FillCorner.Parent = SliderFill
    
    local valor = valorInicial
    local arrastando = false
    
    local function AtualizarSlider(input)
        local posX = input.Position.X
        local sliderPos = SliderBG.AbsolutePosition.X
        local sliderSize = SliderBG.AbsoluteSize.X
        
        local porcentagem = math.clamp((posX - sliderPos) / sliderSize, 0, 1)
        valor = minimo + (maximo - minimo) * porcentagem
        valor = math.floor(valor * 100) / 100
        
        SliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
        ValorLabel.Text = "[" .. tostring(math.floor(valor)) .. sufixo .. "]"
        
        if callback then
            callback(valor)
        end
    end
    
    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            AtualizarSlider(input)
        end
    end)
    
    SliderBG.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            AtualizarSlider(input)
        end
    end)
    
    return Container, function() return valor end, function(v)
        valor = v
        local porcentagem = (valor - minimo) / (maximo - minimo)
        SliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
        ValorLabel.Text = "[" .. tostring(math.floor(valor)) .. sufixo .. "]"
    end
end

-- Função para criar dropdown estilo SAVAGECHEATS_
local function CriarDropdown(parent, texto, opcoes, valorInicial, callback, ordem)
    local Container = Instance.new("Frame")
    Container.Name = "Dropdown_" .. texto
    Container.Size = UDim2.new(1, -20, 0, 35)
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = ordem or 0
    Container.ClipsDescendants = false
    Container.Parent = parent
    
    local DropdownBtn = Instance.new("TextButton")
    DropdownBtn.Name = "Button"
    DropdownBtn.Size = UDim2.new(0.55, 0, 0, 30)
    DropdownBtn.Position = UDim2.new(0, 0, 0, 0)
    DropdownBtn.BackgroundColor3 = Tema.FundoSecundario
    DropdownBtn.Text = valorInicial or opcoes[1] or "Selecionar"
    DropdownBtn.TextColor3 = Tema.Texto
    DropdownBtn.TextSize = 12
    DropdownBtn.Font = Enum.Font.Gotham
    DropdownBtn.BorderSizePixel = 0
    DropdownBtn.Parent = Container
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = DropdownBtn
    
    local Seta = Instance.new("TextLabel")
    Seta.Name = "Seta"
    Seta.Size = UDim2.new(0, 20, 1, 0)
    Seta.Position = UDim2.new(1, -25, 0, 0)
    Seta.BackgroundTransparency = 1
    Seta.Text = "▼"
    Seta.TextColor3 = Tema.Primaria
    Seta.TextSize = 12
    Seta.Font = Enum.Font.GothamBold
    Seta.Parent = DropdownBtn
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.4, 0, 1, 0)
    Label.Position = UDim2.new(0.6, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = texto
    Label.TextColor3 = Tema.TextoEscuro
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Right
    Label.Parent = Container
    
    local DropdownList = Instance.new("Frame")
    DropdownList.Name = "List"
    DropdownList.Size = UDim2.new(0.55, 0, 0, #opcoes * 25)
    DropdownList.Position = UDim2.new(0, 0, 1, 5)
    DropdownList.BackgroundColor3 = Tema.Fundo
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.ZIndex = 100
    DropdownList.Parent = Container
    
    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0, 4)
    ListCorner.Parent = DropdownList
    
    local ListStroke = Instance.new("UIStroke")
    ListStroke.Color = Tema.Borda
    ListStroke.Thickness = 1
    ListStroke.Parent = DropdownList
    
    local valor = valorInicial or opcoes[1]
    local aberto = false
    
    -- Criar opções
    for i, opcao in ipairs(opcoes) do
        local OpcaoBtn = Instance.new("TextButton")
        OpcaoBtn.Name = "Opcao_" .. opcao
        OpcaoBtn.Size = UDim2.new(1, 0, 0, 25)
        OpcaoBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
        OpcaoBtn.BackgroundColor3 = Tema.Fundo
        OpcaoBtn.BackgroundTransparency = 0.5
        OpcaoBtn.Text = opcao
        OpcaoBtn.TextColor3 = Tema.Texto
        OpcaoBtn.TextSize = 11
        OpcaoBtn.Font = Enum.Font.Gotham
        OpcaoBtn.BorderSizePixel = 0
        OpcaoBtn.ZIndex = 101
        OpcaoBtn.Parent = DropdownList
        
        OpcaoBtn.MouseButton1Click:Connect(function()
            valor = opcao
            DropdownBtn.Text = opcao
            DropdownList.Visible = false
            aberto = false
            Seta.Text = "▼"
            if callback then
                callback(opcao)
            end
        end)
        
        OpcaoBtn.MouseEnter:Connect(function()
            OpcaoBtn.BackgroundColor3 = Tema.Primaria
        end)
        
        OpcaoBtn.MouseLeave:Connect(function()
            OpcaoBtn.BackgroundColor3 = Tema.Fundo
        end)
    end
    
    DropdownBtn.MouseButton1Click:Connect(function()
        aberto = not aberto
        DropdownList.Visible = aberto
        Seta.Text = aberto and "▲" or "▼"
    end)
    
    return Container, function() return valor end, function(v)
        valor = v
        DropdownBtn.Text = v
    end
end


-- Função para criar conteúdo da aba ESP
local function CriarConteudoESP(parent)
    -- Limpar conteúdo anterior
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    CriarCheckbox(parent, "ESP Ativo", Config.ESPAtivo, function(v)
        Config.ESPAtivo = v
    end, 1)
    
    CriarCheckbox(parent, "Mostrar Box", Config.ESPBox, function(v)
        Config.ESPBox = v
    end, 2)
    
    CriarCheckbox(parent, "Mostrar Nome", Config.ESPNome, function(v)
        Config.ESPNome = v
    end, 3)
    
    CriarCheckbox(parent, "Mostrar Vida", Config.ESPVida, function(v)
        Config.ESPVida = v
    end, 4)
    
    CriarCheckbox(parent, "Mostrar Distância", Config.ESPDistancia, function(v)
        Config.ESPDistancia = v
    end, 5)
    
    CriarCheckbox(parent, "Mostrar Tracer", Config.ESPTracer, function(v)
        Config.ESPTracer = v
    end, 6)
end

-- Função para criar conteúdo da aba AIM
local function CriarConteudoAim(parent)
    -- Limpar conteúdo anterior
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    CriarCheckbox(parent, "AimBot", Config.AimbotAtivo, function(v)
        Config.AimbotAtivo = v
        if ElementosUI.StatusLabel then
            ElementosUI.StatusLabel.Text = v and "ON" or "OFF"
            ElementosUI.StatusLabel.TextColor3 = v and Color3.new(0.3, 1, 0.3) or Color3.new(1, 0.3, 0.3)
        end
    end, 1)
    
    CriarCheckbox(parent, "Pular Abatidos", Config.PularAbatidos, function(v)
        Config.PularAbatidos = v
    end, 2)
    
    CriarCheckbox(parent, "Bala Mágica", Config.BalaMagica, function(v)
        Config.BalaMagica = v
        if v then
            AtivarBalaMagica()
        else
            DesativarBalaMagica()
        end
    end, 3)
    
    CriarCheckbox(parent, "Ignorar Paredes", Config.PularVerificacaoParede, function(v)
        Config.PularVerificacaoParede = v
    end, 4)
    
    CriarSlider(parent, "Taxa Headshot", 0, 100, Config.TaxaHeadshot, function(v)
        Config.TaxaHeadshot = v
    end, 5, "%")
    
    CriarDropdown(parent, "Parte Alvo", {"Head", "HumanoidRootPart", "Torso"}, Config.ParteAlvo, function(v)
        Config.ParteAlvo = v
    end, 6)
    
    CriarSlider(parent, "FOV", 50, 500, Config.FOVRaio, function(v)
        Config.FOVRaio = v
    end, 7)
    
    CriarDropdown(parent, "Estilo Mira", {"FOV", "MaisProximo", "Aleatorio"}, Config.EstiloMira, function(v)
        Config.EstiloMira = v
    end, 8)
    
    CriarSlider(parent, "Suavização", 0, 95, Config.Suavizacao * 100, function(v)
        Config.Suavizacao = v / 100
    end, 9, "%")
end

-- Função para criar conteúdo da aba CONFIG
local function CriarConteudoConfig(parent)
    -- Limpar conteúdo anterior
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Atualizar times disponíveis
    AtualizarTimesDisponiveis()
    
    CriarCheckbox(parent, "Verificar Time", Config.VerificarTime, function(v)
        Config.VerificarTime = v
    end, 1)
    
    CriarDropdown(parent, "Modo Time", {"Inimigos", "Todos", "TimeEspecifico"}, Config.ModoTime, function(v)
        Config.ModoTime = v
    end, 2)
    
    if #Estado.TimesDisponiveis > 0 then
        CriarDropdown(parent, "Time Alvo", Estado.TimesDisponiveis, Config.TimeAlvo, function(v)
            Config.TimeAlvo = v
        end, 3)
    end
    
    CriarCheckbox(parent, "FOV Visível", Config.FOVVisivel, function(v)
        Config.FOVVisivel = v
    end, 4)
    
    CriarCheckbox(parent, "Suavização Ativa", Config.SuavizacaoAtiva, function(v)
        Config.SuavizacaoAtiva = v
    end, 5)
    
    CriarCheckbox(parent, "Disparo Automático", Config.DisparoAutomatico, function(v)
        Config.DisparoAutomatico = v
    end, 6)
    
    CriarDropdown(parent, "Método Disparo", {"Auto", "Mouse1Click", "VIM", "Touch"}, Config.MetodoDisparo, function(v)
        Config.MetodoDisparo = v
    end, 7)
    
    CriarSlider(parent, "Delay Disparo", 50, 500, Config.DelayDisparo * 1000, function(v)
        Config.DelayDisparo = v / 1000
    end, 8, "ms")
    
    CriarCheckbox(parent, "Predição Movimento", Config.PredicaoAtiva, function(v)
        Config.PredicaoAtiva = v
    end, 9)
    
    CriarSlider(parent, "Força Predição", 0, 50, Config.ForcaPredicao * 100, function(v)
        Config.ForcaPredicao = v / 100
    end, 10, "%")
    
    CriarSlider(parent, "Distância Máxima", 100, 2000, Config.DistanciaMaxima, function(v)
        Config.DistanciaMaxima = v
    end, 11, "m")
end

-- Função para trocar de aba
local function TrocarAba(novaAba)
    AbaAtual = novaAba
    
    -- Atualizar visual das abas
    for _, nomeAba in ipairs({"Esp", "Aim", "Config"}) do
        local btn = ElementosUI["Tab_" .. nomeAba]
        if btn then
            btn.BackgroundColor3 = nomeAba == novaAba and Tema.Primaria or Tema.FundoSecundario
        end
    end
    
    -- Atualizar conteúdo
    local content = ElementosUI.ContentContainer
    if content then
        if novaAba == "Esp" then
            CriarConteudoESP(content)
        elseif novaAba == "Aim" then
            CriarConteudoAim(content)
        elseif novaAba == "Config" then
            CriarConteudoConfig(content)
        end
    end
end

-- Configurar eventos da UI
local function ConfigurarEventosUI()
    -- Eventos das abas
    for _, nomeAba in ipairs({"Esp", "Aim", "Config"}) do
        local btn = ElementosUI["Tab_" .. nomeAba]
        if btn then
            btn.MouseButton1Click:Connect(function()
                TrocarAba(nomeAba)
            end)
        end
    end
    
    -- Botão flutuante
    if ElementosUI.BtnFlutuante then
        ElementosUI.BtnFlutuante.MouseButton1Click:Connect(function()
            if ElementosUI.MainFrame then
                ElementosUI.MainFrame.Visible = not ElementosUI.MainFrame.Visible
            end
        end)
    end
    
    -- Botão fechar
    local mainFrame = ElementosUI.MainFrame
    if mainFrame then
        local btnFechar = mainFrame:FindFirstChild("Header") and mainFrame.Header:FindFirstChild("Fechar")
        if btnFechar then
            btnFechar.MouseButton1Click:Connect(function()
                mainFrame.Visible = false
            end)
        end
        
        -- Botão minimizar
        local btnMin = mainFrame:FindFirstChild("Header") and mainFrame.Header:FindFirstChild("Minimizar")
        if btnMin then
            local minimizado = false
            btnMin.MouseButton1Click:Connect(function()
                minimizado = not minimizado
                btnMin.Text = minimizado and "▲" or "▼"
                
                -- Esconder/mostrar conteúdo
                local content = mainFrame:FindFirstChild("ContentContainer")
                local tabs = mainFrame:FindFirstChild("TabContainer")
                
                if content then content.Visible = not minimizado end
                if tabs then tabs.Visible = not minimizado end
                
                mainFrame.Size = minimizado and UDim2.new(0, 320, 0, 45) or UDim2.new(0, 320, 0, 420)
            end)
        end
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        LOOP PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function LoopPrincipal()
    -- Atualizar câmera
    Camera = Workspace.CurrentCamera
    
    -- Atualizar FOV Circle
    AtualizarFOVCircle()
    
    -- Atualizar ESP
    for _, jogador in pairs(Players:GetPlayers()) do
        AtualizarESPJogador(jogador)
    end
    
    -- Se aimbot não está ativo ou não está mirando, resetar
    if not Config.AimbotAtivo or not Estado.Mirando then
        Estado.AlvoAtual = nil
        Estado.ParteAlvoAtual = nil
        Estado.Travado = false
        return
    end
    
    -- Encontrar melhor alvo
    local alvo, parte = EncontrarMelhorAlvo()
    
    if alvo and parte then
        Estado.AlvoAtual = alvo
        Estado.ParteAlvoAtual = parte
        Estado.Travado = true
        
        -- Calcular posição com predição
        local posicaoAlvo = PreverPosicao(alvo.Character, parte)
        
        -- Mirar no alvo
        MirarEm(posicaoAlvo)
        
        -- Executar disparo automático
        ExecutarDisparo()
    else
        Estado.AlvoAtual = nil
        Estado.ParteAlvoAtual = nil
        Estado.Travado = false
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE INPUT
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function ConfigurarInput()
    -- Input começou (toque ou clique)
    Conexoes.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        -- Ignorar se processado pela UI
        if processed then return end
        
        -- Ativar mira com toque ou clique direito
        if Config.AtivarComToque then
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseButton2 then
                Estado.Mirando = true
            end
        end
    end)
    
    -- Input terminou
    Conexoes.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton2 then
            Estado.Mirando = false
            Estado.AlvoAtual = nil
            Estado.ParteAlvoAtual = nil
            Estado.Travado = false
        end
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        INICIALIZAÇÃO E DESTRUIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    print("[SAVAGECHEATS_] Iniciando...")
    
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Criar UI
    CriarUI()
    ConfigurarEventosUI()
    TrocarAba("Aim") -- Começar na aba Aim
    
    -- Inicializar ESP
    InicializarESP()
    
    -- Configurar input
    ConfigurarInput()
    
    -- Atualizar times
    AtualizarTimesDisponiveis()
    
    -- Loop principal usando Heartbeat (mais estável para mobile)
    Conexoes.Loop = RunService.Heartbeat:Connect(LoopPrincipal)
    
    -- Conexão para respawn
    Conexoes.Respawn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        Estado.AlvoAtual = nil
        Estado.ParteAlvoAtual = nil
        Estado.Travado = false
    end)
    
    print([[

    ╔══════════════════════════════════════════════════════════════╗
    ║           🎯 SAVAGECHEATS_ CARREGADO COM SUCESSO! 🎯         ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  COMO USAR:                                                  ║
    ║  1. Toque no botão 🎯 para abrir/fechar o menu               ║
    ║  2. Configure as opções nas abas ESP, Aim e Config           ║
    ║  3. Toque na tela para ativar a mira                         ║
    ║                                                              ║
    ║  DICAS:                                                      ║
    ║  • Ajuste a Suavização para controlar o "grude"              ║
    ║  • Use Bala Mágica para acertar através de paredes           ║
    ║  • Configure o Time Alvo em jogos com times                  ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

    ]])
    
    return true
end

local function Destruir()
    print("[SAVAGECHEATS_] Destruindo...")
    
    -- Desconectar todas as conexões
    for nome, conexao in pairs(Conexoes) do
        if conexao then
            pcall(function() conexao:Disconnect() end)
        end
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Destruir UI
    if ElementosUI.ScreenGui then
        pcall(function() ElementosUI.ScreenGui:Destroy() end)
    end
    ElementosUI = {}
    
    -- Desativar bala mágica
    DesativarBalaMagica()
    
    -- Resetar estado
    Estado.Mirando = false
    Estado.AlvoAtual = nil
    Estado.ParteAlvoAtual = nil
    Estado.Travado = false
    
    _G.SAVAGECHEATS_LOADED = false
    
    print("[SAVAGECHEATS_] Destruído com sucesso!")
end

-- Registrar função de destruição global
_G.SAVAGECHEATS_DESTROY = Destruir

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        AUTO INICIALIZAÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Aguardar jogo carregar
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Aguardar personagem
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

task.wait(0.5)

-- Inicializar
Inicializar()

-- Retornar tabela de controle
return {
    Config = Config,
    Estado = Estado,
    Destruir = Destruir,
    AtualizarTimesDisponiveis = AtualizarTimesDisponiveis,
}
