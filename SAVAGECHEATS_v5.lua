--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                           SAVAGECHEATS_ AIMBOT UNIVERSAL                                  ║
    ║                        Otimizado para Mobile Android/iOS                                  ║
    ║                                  Versão 5.0 (FINAL)                                       ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════╣
    ║  CORREÇÕES v5:                                                                            ║
    ║  • UI com TextButton transparente para bloquear input (não move câmera)                   ║
    ║  • ScrollingFrame com ClipsDescendants correto                                            ║
    ║  • Sistema de disparo automático inteligente multi-método                                 ║
    ║  • Hitbox Expander (aumenta cabeça dos inimigos)                                          ║
    ║  • Todas as correções anteriores mantidas                                                 ║
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
local VirtualInputManager = game:GetService("VirtualInputManager")

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
                                        CONFIGURAÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]
local Config = {
    -- Aimbot
    AimbotAtivo = false,
    BalaMagica = false,
    PularAbatidos = true,
    IgnorarParedes = false,
    TaxaHeadshot = 100,
    ParteAlvo = "Head",
    
    -- FOV
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(200, 40, 40),
    EstiloMira = "FOV",
    
    -- Suavização
    SuavizacaoAtiva = true,
    Suavizacao = 0.3,
    
    -- Disparo Automático
    DisparoAutomatico = false,
    DelayDisparo = 0.1,
    MetodoDisparo = "Auto",
    
    -- Predição
    PredicaoAtiva = true,
    ForcaPredicao = 0.15,
    
    -- Distância
    DistanciaMaxima = 1000,
    
    -- Times
    ModoTime = "Inimigos",
    TimeAlvo = "",
    
    -- ESP
    ESPAtivo = false,
    ESPBox = true,
    ESPNome = true,
    ESPVida = true,
    ESPDistancia = true,
    ESPTracer = false,
    ESPCorInimigo = Color3.fromRGB(255, 50, 50),
    ESPCorAliado = Color3.fromRGB(50, 255, 50),
    
    -- Hitbox Expander (NOVO)
    HitboxExpanderAtivo = false,
    HitboxTamanho = 5,
    HitboxTransparencia = 0.8,
    HitboxApenasCabeca = true,
}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        ESTADO DO SISTEMA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]
local Estado = {
    AlvoAtual = nil,
    ParteAlvoAtual = nil,
    Travado = false,
    UltimoDisparo = 0,
    InteragindoComUI = false,
    Arrastando = false,
    TimesDisponiveis = {},
    HitboxesOriginais = {},
    BotaoTiroDetectado = nil,
    MetodoDisparoAtivo = nil,
}

local Conexoes = {}
local ElementosESP = {}
local FOVCircle = nil

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarDrawing(tipo, propriedades)
    local sucesso, objeto = pcall(function()
        local obj = Drawing.new(tipo)
        for prop, valor in pairs(propriedades) do
            obj[prop] = valor
        end
        return obj
    end)
    return sucesso and objeto or nil
end

local function GetCentroTela()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y + inset.Y) / 2)
end

local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel and pos.Z > 0
end

local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

local function EstaVivo(personagem)
    if not personagem then return false end
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    
    if Config.PularAbatidos then
        local estado = humanoid:GetState()
        if estado == Enum.HumanoidStateType.Dead then return false end
        
        local knocked = personagem:FindFirstChild("Knocked") or 
                       personagem:FindFirstChild("IsKnocked") or
                       personagem:FindFirstChild("Downed")
        if knocked and (knocked.Value == true or knocked.Value == 1) then
            return false
        end
    end
    
    return true
end

local function MesmoTime(jogador)
    if not LocalPlayer.Team or not jogador.Team then
        return false
    end
    return LocalPlayer.Team == jogador.Team
end

local function AtualizarTimesDisponiveis()
    Estado.TimesDisponiveis = {}
    for _, time in pairs(Teams:GetTeams()) do
        table.insert(Estado.TimesDisponiveis, time.Name)
    end
end

local function DeveAtacar(jogador)
    if jogador == LocalPlayer then return false end
    
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
    
    return not MesmoTime(jogador)
end

local function VerificarLinhaDeVisao(origem, destino)
    if Config.IgnorarParedes then
        return true
    end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignorar = {LocalPlayer.Character, Camera}
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador.Character then
            table.insert(ignorar, jogador.Character)
        end
    end
    rayParams.FilterDescendantsInstances = ignorar
    
    local direcao = (destino - origem)
    local resultado = Workspace:Raycast(origem, direcao, rayParams)
    
    return resultado == nil
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA FOV CIRCLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarFOVCircle()
    FOVCircle = CriarDrawing("Circle", {
        Thickness = 2,
        Color = Config.FOVCor,
        Filled = false,
        NumSides = 64,
        Radius = Config.FOVRaio,
        Visible = Config.FOVVisivel,
        ZIndex = 999,
        Transparency = 1,
        Position = GetCentroTela()
    })
end

local function AtualizarFOVCircle()
    if FOVCircle then
        FOVCircle.Position = GetCentroTela()
        FOVCircle.Radius = Config.FOVRaio
        FOVCircle.Color = Config.FOVCor
        FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
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
                                        SISTEMA DE SELEÇÃO DE ALVO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function ObterParteAlvo(personagem)
    local parteNome = Config.ParteAlvo
    
    if Config.TaxaHeadshot > 0 and math.random(1, 100) <= Config.TaxaHeadshot then
        parteNome = "Head"
    end
    
    local parte = personagem:FindFirstChild(parteNome)
    if not parte then
        parte = personagem:FindFirstChild("HumanoidRootPart") or
                personagem:FindFirstChild("Head") or
                personagem:FindFirstChild("Torso") or
                personagem:FindFirstChild("UpperTorso")
    end
    
    return parte
end

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local melhorValor = math.huge
    
    local centroTela = GetCentroTela()
    local meuPersonagem = LocalPlayer.Character
    local minhaRaiz = meuPersonagem and meuPersonagem:FindFirstChild("HumanoidRootPart")
    
    if not minhaRaiz then return nil, nil end
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if DeveAtacar(jogador) then
            local personagem = jogador.Character
            if personagem and EstaVivo(personagem) then
                local parte = ObterParteAlvo(personagem)
                if parte then
                    local distancia3D = Distancia3D(minhaRaiz.Position, parte.Position)
                    
                    if distancia3D <= Config.DistanciaMaxima then
                        local posicaoTela, visivel = WorldToScreen(parte.Position)
                        
                        if visivel then
                            local distancia2D = Distancia2D(centroTela, posicaoTela)
                            
                            local dentroFOV = Config.EstiloMira ~= "FOV" or distancia2D <= Config.FOVRaio
                            
                            if dentroFOV then
                                local temVisao = VerificarLinhaDeVisao(
                                    Camera.CFrame.Position,
                                    parte.Position
                                )
                                
                                if temVisao or Config.IgnorarParedes then
                                    local valor
                                    if Config.EstiloMira == "FOV" then
                                        valor = distancia2D
                                    elseif Config.EstiloMira == "MaisProximo" then
                                        valor = distancia3D
                                    else
                                        valor = math.random()
                                    end
                                    
                                    if valor < melhorValor then
                                        melhorValor = valor
                                        melhorAlvo = jogador
                                        melhorParte = parte
                                    end
                                end
                            end
                        end
                    end
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

local VelocidadesAnteriores = {}

local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not parte then
        return parte.Position
    end
    
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if not raiz then return parte.Position end
    
    local velocidade = raiz.AssemblyLinearVelocity
    local jogadorId = personagem.Parent and personagem.Parent.Name or "unknown"
    
    VelocidadesAnteriores[jogadorId] = VelocidadesAnteriores[jogadorId] or velocidade
    local velocidadeSuave = VelocidadesAnteriores[jogadorId]:Lerp(velocidade, 0.3)
    VelocidadesAnteriores[jogadorId] = velocidadeSuave
    
    local predicao = velocidadeSuave * Config.ForcaPredicao
    
    return parte.Position + predicao
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE MIRA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function MirarEm(posicaoMundo)
    if Estado.InteragindoComUI or Estado.Arrastando then
        return
    end
    
    local novaCFrame = CFrame.new(Camera.CFrame.Position, posicaoMundo)
    
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        Camera.CFrame = Camera.CFrame:Lerp(novaCFrame, 1 - Config.Suavizacao)
    else
        Camera.CFrame = novaCFrame
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SISTEMA DE DISPARO AUTOMÁTICO INTELIGENTE
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    Sistema multi-método que detecta e usa o melhor método de disparo para cada jogo.
]]

local MetodosDisparo = {}

-- Método 1: mouse1click (mais compatível com executores)
MetodosDisparo.Mouse1Click = function()
    if mouse1click then
        mouse1click()
        return true
    end
    return false
end

-- Método 2: mouse1press/release (controle mais preciso)
MetodosDisparo.Mouse1Press = function()
    if mouse1press and mouse1release then
        mouse1press()
        task.wait(0.03)
        mouse1release()
        return true
    end
    return false
end

-- Método 3: VirtualInputManager
MetodosDisparo.VIM = function()
    local sucesso = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
    return sucesso
end

-- Método 4: Procurar botão de tiro na UI do jogo
MetodosDisparo.TouchButton = function()
    if Estado.BotaoTiroDetectado then
        local sucesso = pcall(function()
            if firetouchinterest then
                firetouchinterest(Estado.BotaoTiroDetectado, Estado.BotaoTiroDetectado, 0)
                task.wait(0.03)
                firetouchinterest(Estado.BotaoTiroDetectado, Estado.BotaoTiroDetectado, 1)
            end
        end)
        return sucesso
    end
    return false
end

-- Detectar botão de tiro do jogo
local function DetectarBotaoTiro()
    local nomesComuns = {
        "shoot", "fire", "attack", "trigger", "shootbutton", "firebutton",
        "attackbutton", "gun", "weapon", "atirar", "disparar", "tiro"
    }
    
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible then
            local nome = gui.Name:lower()
            for _, nomeComum in pairs(nomesComuns) do
                if nome:find(nomeComum) then
                    Estado.BotaoTiroDetectado = gui
                    return gui
                end
            end
        end
    end
    
    return nil
end

-- Detectar melhor método de disparo
local function DetectarMelhorMetodo()
    if mouse1click then
        Estado.MetodoDisparoAtivo = "Mouse1Click"
        return
    end
    
    if mouse1press and mouse1release then
        Estado.MetodoDisparoAtivo = "Mouse1Press"
        return
    end
    
    DetectarBotaoTiro()
    if Estado.BotaoTiroDetectado then
        Estado.MetodoDisparoAtivo = "TouchButton"
        return
    end
    
    Estado.MetodoDisparoAtivo = "VIM"
end

-- Executar disparo com o método detectado
local function ExecutarDisparo()
    if not Config.DisparoAutomatico then return end
    if not Estado.Travado then return end
    if Estado.InteragindoComUI then return end
    
    local agora = tick()
    if agora - Estado.UltimoDisparo < Config.DelayDisparo then
        return
    end
    
    Estado.UltimoDisparo = agora
    
    task.spawn(function()
        if Config.MetodoDisparo == "Auto" then
            if not Estado.MetodoDisparoAtivo then
                DetectarMelhorMetodo()
            end
            
            local metodo = MetodosDisparo[Estado.MetodoDisparoAtivo]
            if metodo then
                metodo()
            end
        else
            local metodo = MetodosDisparo[Config.MetodoDisparo]
            if metodo then
                metodo()
            end
        end
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA BALA MÁGICA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local BalaMagicaHook = nil
local MetatableOriginal = nil

local function AtivarBalaMagica()
    if BalaMagicaHook then return end
    
    local sucesso = pcall(function()
        MetatableOriginal = getrawmetatable(game)
        local indexOriginal = MetatableOriginal.__index
        
        setreadonly(MetatableOriginal, false)
        
        BalaMagicaHook = newcclosure(function(self, propriedade)
            if Config.BalaMagica and Estado.Travado and Estado.ParteAlvoAtual then
                if self == Mouse then
                    if propriedade == "Hit" then
                        return CFrame.new(Estado.ParteAlvoAtual.Position)
                    elseif propriedade == "Target" then
                        return Estado.ParteAlvoAtual
                    elseif propriedade == "X" or propriedade == "Y" then
                        local pos = WorldToScreen(Estado.ParteAlvoAtual.Position)
                        return propriedade == "X" and pos.X or pos.Y
                    end
                end
            end
            return indexOriginal(self, propriedade)
        end)
        
        MetatableOriginal.__index = BalaMagicaHook
        setreadonly(MetatableOriginal, true)
    end)
    
    if not sucesso then
        warn("[SAVAGECHEATS_] Bala Mágica não disponível neste executor")
    end
end

local function DesativarBalaMagica()
    if not BalaMagicaHook or not MetatableOriginal then return end
    
    pcall(function()
        setreadonly(MetatableOriginal, false)
        MetatableOriginal.__index = MetatableOriginal.__index
        setreadonly(MetatableOriginal, true)
    end)
    
    BalaMagicaHook = nil
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA HITBOX EXPANDER
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    Aumenta o tamanho visual das hitboxes dos inimigos para facilitar acertos.
    Funciona modificando o Size das partes do personagem.
]]

local function SalvarHitboxOriginal(personagem)
    local jogadorId = personagem.Parent and personagem.Parent.Name or tostring(personagem)
    
    if Estado.HitboxesOriginais[jogadorId] then return end
    
    Estado.HitboxesOriginais[jogadorId] = {}
    
    local partes = Config.HitboxApenasCabeca and {"Head"} or {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    
    for _, nomePartes in pairs(partes) do
        local parte = personagem:FindFirstChild(nomePartes)
        if parte and parte:IsA("BasePart") then
            Estado.HitboxesOriginais[jogadorId][nomePartes] = {
                Size = parte.Size,
                Transparency = parte.Transparency,
                CanCollide = parte.CanCollide,
            }
        end
    end
end

local function RestaurarHitbox(personagem)
    local jogadorId = personagem.Parent and personagem.Parent.Name or tostring(personagem)
    
    if not Estado.HitboxesOriginais[jogadorId] then return end
    
    for nomeParte, props in pairs(Estado.HitboxesOriginais[jogadorId]) do
        local parte = personagem:FindFirstChild(nomeParte)
        if parte and parte:IsA("BasePart") then
            pcall(function()
                parte.Size = props.Size
                parte.Transparency = props.Transparency
                parte.CanCollide = props.CanCollide
            end)
        end
    end
    
    Estado.HitboxesOriginais[jogadorId] = nil
end

local function ExpandirHitbox(personagem)
    if not Config.HitboxExpanderAtivo then return end
    
    local jogadorId = personagem.Parent and personagem.Parent.Name or tostring(personagem)
    
    SalvarHitboxOriginal(personagem)
    
    local partes = Config.HitboxApenasCabeca and {"Head"} or {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    
    for _, nomeParte in pairs(partes) do
        local parte = personagem:FindFirstChild(nomeParte)
        if parte and parte:IsA("BasePart") then
            pcall(function()
                local tamanho = Config.HitboxTamanho
                parte.Size = Vector3.new(tamanho, tamanho, tamanho)
                parte.Transparency = Config.HitboxTransparencia
                parte.CanCollide = false
            end)
        end
    end
end

local function AtualizarHitboxes()
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Character then
            if Config.HitboxExpanderAtivo and DeveAtacar(jogador) and EstaVivo(jogador.Character) then
                ExpandirHitbox(jogador.Character)
            else
                RestaurarHitbox(jogador.Character)
            end
        end
    end
end

local function RestaurarTodasHitboxes()
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Character then
            RestaurarHitbox(jogador.Character)
        end
    end
    Estado.HitboxesOriginais = {}
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA ESP
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarESP(jogador)
    if jogador == LocalPlayer then return end
    if ElementosESP[jogador] then return end
    
    ElementosESP[jogador] = {
        Box = CriarDrawing("Square", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Filled = false,
            Visible = false,
            ZIndex = 1,
        }),
        Nome = CriarDrawing("Text", {
            Size = 14,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 2,
        }),
        Vida = CriarDrawing("Text", {
            Size = 12,
            Color = Color3.new(0, 1, 0),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 2,
        }),
        Distancia = CriarDrawing("Text", {
            Size = 12,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 2,
        }),
        Tracer = CriarDrawing("Line", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Visible = false,
            ZIndex = 1,
        }),
    }
end

local function RemoverESP(jogador)
    if not ElementosESP[jogador] then return end
    
    for _, elemento in pairs(ElementosESP[jogador]) do
        if elemento then
            pcall(function() elemento:Remove() end)
        end
    end
    
    ElementosESP[jogador] = nil
end

local function AtualizarESP(jogador)
    local esp = ElementosESP[jogador]
    if not esp then return end
    
    local personagem = jogador.Character
    local visivel = Config.ESPAtivo and personagem and EstaVivo(personagem)
    
    if not visivel then
        for _, elemento in pairs(esp) do
            if elemento then elemento.Visible = false end
        end
        return
    end
    
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    local cabeca = personagem:FindFirstChild("Head")
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    
    if not raiz or not cabeca or not humanoid then
        for _, elemento in pairs(esp) do
            if elemento then elemento.Visible = false end
        end
        return
    end
    
    local posicaoTela, naTelaRaiz = WorldToScreen(raiz.Position)
    local posicaoCabeca, naTelaCabeca = WorldToScreen(cabeca.Position + Vector3.new(0, 1, 0))
    local posicaoPes, _ = WorldToScreen(raiz.Position - Vector3.new(0, 3, 0))
    
    if not naTelaRaiz then
        for _, elemento in pairs(esp) do
            if elemento then elemento.Visible = false end
        end
        return
    end
    
    local cor = DeveAtacar(jogador) and Config.ESPCorInimigo or Config.ESPCorAliado
    
    local altura = math.abs(posicaoPes.Y - posicaoCabeca.Y)
    local largura = altura * 0.6
    
    -- Box
    if esp.Box and Config.ESPBox then
        esp.Box.Size = Vector2.new(largura, altura)
        esp.Box.Position = Vector2.new(posicaoTela.X - largura/2, posicaoCabeca.Y)
        esp.Box.Color = cor
        esp.Box.Visible = true
    elseif esp.Box then
        esp.Box.Visible = false
    end
    
    -- Nome
    if esp.Nome and Config.ESPNome then
        esp.Nome.Text = jogador.Name
        esp.Nome.Position = Vector2.new(posicaoTela.X, posicaoCabeca.Y - 18)
        esp.Nome.Visible = true
    elseif esp.Nome then
        esp.Nome.Visible = false
    end
    
    -- Vida
    if esp.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = math.floor(humanoid.MaxHealth)
        esp.Vida.Text = vida .. "/" .. vidaMax .. " HP"
        esp.Vida.Position = Vector2.new(posicaoTela.X, posicaoPes.Y + 5)
        esp.Vida.Color = Color3.fromRGB(
            255 * (1 - humanoid.Health/humanoid.MaxHealth),
            255 * (humanoid.Health/humanoid.MaxHealth),
            0
        )
        esp.Vida.Visible = true
    elseif esp.Vida then
        esp.Vida.Visible = false
    end
    
    -- Distância
    if esp.Distancia and Config.ESPDistancia then
        local meuPersonagem = LocalPlayer.Character
        local minhaRaiz = meuPersonagem and meuPersonagem:FindFirstChild("HumanoidRootPart")
        if minhaRaiz then
            local dist = math.floor(Distancia3D(minhaRaiz.Position, raiz.Position))
            esp.Distancia.Text = dist .. "m"
            esp.Distancia.Position = Vector2.new(posicaoTela.X, posicaoPes.Y + 18)
            esp.Distancia.Visible = true
        end
    elseif esp.Distancia then
        esp.Distancia.Visible = false
    end
    
    -- Tracer
    if esp.Tracer and Config.ESPTracer then
        local viewport = Camera.ViewportSize
        esp.Tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
        esp.Tracer.To = posicaoTela
        esp.Tracer.Color = cor
        esp.Tracer.Visible = true
    elseif esp.Tracer then
        esp.Tracer.Visible = false
    end
end

local function InicializarESP()
    for _, jogador in pairs(Players:GetPlayers()) do
        CriarESP(jogador)
    end
    
    table.insert(Conexoes, Players.PlayerAdded:Connect(function(jogador)
        task.wait(1)
        CriarESP(jogador)
    end))
    
    table.insert(Conexoes, Players.PlayerRemoving:Connect(function(jogador)
        RemoverESP(jogador)
    end))
end

local function DestruirESP()
    for jogador, _ in pairs(ElementosESP) do
        RemoverESP(jogador)
    end
    ElementosESP = {}
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE UI
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    UI customizada no estilo SAVAGECHEATS_ com correções para mobile:
    - TextButton transparente como camada de bloqueio (não move câmera)
    - ScrollingFrame com ClipsDescendants correto
    - Arraste que não interfere com controles do jogo
]]

local ScreenGui = nil
local MainFrame = nil
local CurrentTab = "Aim"
local DropdownsAbertos = {}

-- Cores do tema
local Cores = {
    Fundo = Color3.fromRGB(25, 25, 25),
    FundoSecundario = Color3.fromRGB(35, 35, 35),
    Destaque = Color3.fromRGB(180, 40, 40),
    DestaqueHover = Color3.fromRGB(200, 60, 60),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Borda = Color3.fromRGB(60, 60, 60),
    Toggle = Color3.fromRGB(50, 50, 50),
    ToggleAtivo = Color3.fromRGB(180, 40, 40),
    Slider = Color3.fromRGB(60, 60, 60),
    SliderFill = Color3.fromRGB(180, 40, 40),
}

-- Função para criar UI
local function CriarUI()
    -- Destruir UI anterior se existir
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    
    -- Criar ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    
    -- Tentar colocar no CoreGui, senão no PlayerGui
    local sucesso = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not sucesso then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Frame principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Cores.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 350, 0, 400)
    MainFrame.Active = true
    
    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = MainFrame
    
    -- Borda
    local stroke = Instance.new("UIStroke")
    stroke.Color = Cores.Borda
    stroke.Thickness = 1
    stroke.Parent = MainFrame
    
    --[[
        IMPORTANTE: TextButton transparente como primeira camada
        Isso bloqueia inputs de passarem para o jogo (não move câmera)
    ]]
    local inputBlocker = Instance.new("TextButton")
    inputBlocker.Name = "InputBlocker"
    inputBlocker.Parent = MainFrame
    inputBlocker.BackgroundTransparency = 1
    inputBlocker.Size = UDim2.new(1, 0, 1, 0)
    inputBlocker.Position = UDim2.new(0, 0, 0, 0)
    inputBlocker.Text = ""
    inputBlocker.ZIndex = 1
    inputBlocker.Active = true
    inputBlocker.AutoButtonColor = false
    
    -- Header (barra de título)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = MainFrame
    header.BackgroundColor3 = Cores.FundoSecundario
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 35)
    header.ZIndex = 10
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Parent = header
    titulo.BackgroundTransparency = 1
    titulo.Position = UDim2.new(0, 40, 0, 0)
    titulo.Size = UDim2.new(1, -80, 1, 0)
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "SAVAGECHEATS_"
    titulo.TextColor3 = Cores.Texto
    titulo.TextSize = 16
    titulo.ZIndex = 11
    
    -- Botão minimizar
    local btnMinimizar = Instance.new("TextButton")
    btnMinimizar.Name = "BtnMinimizar"
    btnMinimizar.Parent = header
    btnMinimizar.BackgroundColor3 = Cores.Destaque
    btnMinimizar.BorderSizePixel = 0
    btnMinimizar.Position = UDim2.new(0, 5, 0.5, -10)
    btnMinimizar.Size = UDim2.new(0, 25, 0, 20)
    btnMinimizar.Font = Enum.Font.GothamBold
    btnMinimizar.Text = "−"
    btnMinimizar.TextColor3 = Cores.Texto
    btnMinimizar.TextSize = 18
    btnMinimizar.ZIndex = 12
    btnMinimizar.AutoButtonColor = false
    
    local btnMinCorner = Instance.new("UICorner")
    btnMinCorner.CornerRadius = UDim.new(0, 4)
    btnMinCorner.Parent = btnMinimizar
    
    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Name = "BtnFechar"
    btnFechar.Parent = header
    btnFechar.BackgroundColor3 = Cores.Destaque
    btnFechar.BorderSizePixel = 0
    btnFechar.Position = UDim2.new(1, -30, 0.5, -10)
    btnFechar.Size = UDim2.new(0, 25, 0, 20)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.Text = "×"
    btnFechar.TextColor3 = Cores.Texto
    btnFechar.TextSize = 18
    btnFechar.ZIndex = 12
    btnFechar.AutoButtonColor = false
    
    local btnFechaCorner = Instance.new("UICorner")
    btnFechaCorner.CornerRadius = UDim.new(0, 4)
    btnFechaCorner.Parent = btnFechar
    
    --[[
        SISTEMA DE ARRASTE CUSTOMIZADO
        Usa InputBegan/InputChanged/InputEnded para não interferir com a câmera
    ]]
    local arrastando = false
    local posicaoInicial = nil
    local frameInicial = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.Arrastando = true
            Estado.InteragindoComUI = true
            posicaoInicial = input.Position
            frameInicial = MainFrame.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
            Estado.Arrastando = false
            task.delay(0.1, function()
                if not arrastando then
                    Estado.InteragindoComUI = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - posicaoInicial
            MainFrame.Position = UDim2.new(
                frameInicial.X.Scale,
                frameInicial.X.Offset + delta.X,
                frameInicial.Y.Scale,
                frameInicial.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Container das abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = MainFrame
    tabContainer.BackgroundTransparency = 1
    tabContainer.Position = UDim2.new(0, 10, 0, 40)
    tabContainer.Size = UDim2.new(1, -20, 0, 35)
    tabContainer.ZIndex = 10
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabContainer
    
    -- Content container com ScrollingFrame
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Parent = MainFrame
    contentContainer.BackgroundTransparency = 1
    contentContainer.Position = UDim2.new(0, 10, 0, 80)
    contentContainer.Size = UDim2.new(1, -20, 1, -90)
    contentContainer.ScrollBarThickness = 4
    contentContainer.ScrollBarImageColor3 = Cores.Destaque
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentContainer.ClipsDescendants = true
    contentContainer.Active = true
    contentContainer.ZIndex = 5
    
    --[[
        IMPORTANTE: TextButton dentro do ScrollingFrame para bloquear input
    ]]
    local scrollBlocker = Instance.new("TextButton")
    scrollBlocker.Name = "ScrollBlocker"
    scrollBlocker.Parent = contentContainer
    scrollBlocker.BackgroundTransparency = 1
    scrollBlocker.Size = UDim2.new(1, 0, 1, 0)
    scrollBlocker.Text = ""
    scrollBlocker.ZIndex = 1
    scrollBlocker.Active = true
    scrollBlocker.AutoButtonColor = false
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentContainer
    
    -- Variável para minimizado
    local minimizado = false
    
    btnMinimizar.MouseButton1Click:Connect(function()
        minimizado = not minimizado
        if minimizado then
            MainFrame.Size = UDim2.new(0, 350, 0, 35)
            contentContainer.Visible = false
            tabContainer.Visible = false
            btnMinimizar.Text = "+"
        else
            MainFrame.Size = UDim2.new(0, 350, 0, 400)
            contentContainer.Visible = true
            tabContainer.Visible = true
            btnMinimizar.Text = "−"
        end
    end)
    
    btnFechar.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
    
    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Header = header,
    }
end

-- Função para criar toggle
local function CriarToggle(parent, texto, valorInicial, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 30)
    container.LayoutOrder = layoutOrder or 0
    container.ZIndex = 10
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 35, 0, 0)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 11
    
    local toggleBg = Instance.new("TextButton")
    toggleBg.Name = "ToggleBg"
    toggleBg.Parent = container
    toggleBg.BackgroundColor3 = valorInicial and Cores.ToggleAtivo or Cores.Toggle
    toggleBg.BorderSizePixel = 0
    toggleBg.Position = UDim2.new(0, 0, 0.5, -10)
    toggleBg.Size = UDim2.new(0, 25, 0, 20)
    toggleBg.Text = valorInicial and "✓" or ""
    toggleBg.TextColor3 = Cores.Texto
    toggleBg.TextSize = 14
    toggleBg.Font = Enum.Font.GothamBold
    toggleBg.ZIndex = 12
    toggleBg.AutoButtonColor = false
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleBg
    
    local valor = valorInicial
    
    toggleBg.MouseButton1Click:Connect(function()
        valor = not valor
        toggleBg.BackgroundColor3 = valor and Cores.ToggleAtivo or Cores.Toggle
        toggleBg.Text = valor and "✓" or ""
        if callback then
            callback(valor)
        end
    end)
    
    return container, function() return valor end, function(v)
        valor = v
        toggleBg.BackgroundColor3 = valor and Cores.ToggleAtivo or Cores.Toggle
        toggleBg.Text = valor and "✓" or ""
    end
end

-- Função para criar slider
local function CriarSlider(parent, texto, min, max, valorInicial, callback, layoutOrder, sufixo)
    sufixo = sufixo or ""
    
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 50)
    container.LayoutOrder = layoutOrder or 0
    container.ZIndex = 10
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 11
    
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Parent = container
    valorLabel.BackgroundTransparency = 1
    valorLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valorLabel.Size = UDim2.new(0.4, 0, 0, 20)
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.Text = "[" .. tostring(valorInicial) .. sufixo .. "]"
    valorLabel.TextColor3 = Cores.TextoSecundario
    valorLabel.TextSize = 14
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.ZIndex = 11
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "SliderBg"
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Cores.Slider
    sliderBg.BorderSizePixel = 0
    sliderBg.Position = UDim2.new(0, 0, 0, 25)
    sliderBg.Size = UDim2.new(1, 0, 0, 20)
    sliderBg.ZIndex = 11
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Cores.SliderFill
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((valorInicial - min) / (max - min), 0, 1, 0)
    sliderFill.ZIndex = 12
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    -- Botão invisível para capturar input
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "SliderButton"
    sliderButton.Parent = sliderBg
    sliderButton.BackgroundTransparency = 1
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.Text = ""
    sliderButton.ZIndex = 15
    sliderButton.AutoButtonColor = false
    
    local valor = valorInicial
    local arrastando = false
    
    local function atualizarSlider(inputPos)
        local posRelativa = inputPos.X - sliderBg.AbsolutePosition.X
        local porcentagem = math.clamp(posRelativa / sliderBg.AbsoluteSize.X, 0, 1)
        valor = math.floor(min + (max - min) * porcentagem)
        sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
        valorLabel.Text = "[" .. tostring(valor) .. sufixo .. "]"
        if callback then
            callback(valor)
        end
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.InteragindoComUI = true
            atualizarSlider(input.Position)
        end
    end)
    
    sliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
            task.delay(0.1, function()
                if not arrastando then
                    Estado.InteragindoComUI = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or
                          input.UserInputType == Enum.UserInputType.Touch) then
            atualizarSlider(input.Position)
        end
    end)
    
    return container, function() return valor end, function(v)
        valor = v
        local porcentagem = (valor - min) / (max - min)
        sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
        valorLabel.Text = "[" .. tostring(valor) .. sufixo .. "]"
    end
end

-- Função para criar dropdown
local function CriarDropdown(parent, texto, opcoes, valorInicial, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 50)
    container.LayoutOrder = layoutOrder or 0
    container.ZIndex = 10
    container.ClipsDescendants = false
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.4, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 11
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Name = "DropdownBtn"
    dropdownBtn.Parent = container
    dropdownBtn.BackgroundColor3 = Cores.FundoSecundario
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Position = UDim2.new(0, 0, 0, 22)
    dropdownBtn.Size = UDim2.new(1, 0, 0, 25)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.Text = valorInicial .. "  ▼"
    dropdownBtn.TextColor3 = Cores.Texto
    dropdownBtn.TextSize = 13
    dropdownBtn.ZIndex = 15
    dropdownBtn.AutoButtonColor = false
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = dropdownBtn
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Name = "DropdownList"
    dropdownList.Parent = container
    dropdownList.BackgroundColor3 = Cores.FundoSecundario
    dropdownList.BorderSizePixel = 0
    dropdownList.Position = UDim2.new(0, 0, 0, 50)
    dropdownList.Size = UDim2.new(1, 0, 0, #opcoes * 25)
    dropdownList.Visible = false
    dropdownList.ZIndex = 100
    dropdownList.ClipsDescendants = true
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = dropdownList
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropdownList
    
    local valor = valorInicial
    local aberto = false
    
    for i, opcao in ipairs(opcoes) do
        local opcaoBtn = Instance.new("TextButton")
        opcaoBtn.Name = "Opcao_" .. opcao
        opcaoBtn.Parent = dropdownList
        opcaoBtn.BackgroundColor3 = Cores.FundoSecundario
        opcaoBtn.BackgroundTransparency = 0.3
        opcaoBtn.BorderSizePixel = 0
        opcaoBtn.Size = UDim2.new(1, 0, 0, 25)
        opcaoBtn.Font = Enum.Font.Gotham
        opcaoBtn.Text = opcao
        opcaoBtn.TextColor3 = Cores.Texto
        opcaoBtn.TextSize = 13
        opcaoBtn.LayoutOrder = i
        opcaoBtn.ZIndex = 101
        opcaoBtn.AutoButtonColor = false
        
        opcaoBtn.MouseButton1Click:Connect(function()
            valor = opcao
            dropdownBtn.Text = opcao .. "  ▼"
            dropdownList.Visible = false
            aberto = false
            if callback then
                callback(opcao)
            end
        end)
        
        opcaoBtn.MouseEnter:Connect(function()
            opcaoBtn.BackgroundTransparency = 0
        end)
        
        opcaoBtn.MouseLeave:Connect(function()
            opcaoBtn.BackgroundTransparency = 0.3
        end)
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        aberto = not aberto
        dropdownList.Visible = aberto
        
        -- Fechar outros dropdowns
        for _, dropdown in pairs(DropdownsAbertos) do
            if dropdown ~= dropdownList then
                dropdown.Visible = false
            end
        end
        
        if aberto then
            DropdownsAbertos[texto] = dropdownList
        else
            DropdownsAbertos[texto] = nil
        end
    end)
    
    return container, function() return valor end, function(v)
        valor = v
        dropdownBtn.Text = v .. "  ▼"
    end
end

-- Função para criar separador
local function CriarSeparador(parent, texto, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = "Separador_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 25)
    container.LayoutOrder = layoutOrder or 0
    container.ZIndex = 10
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = "── " .. texto .. " ──"
    label.TextColor3 = Cores.Destaque
    label.TextSize = 12
    label.ZIndex = 11
    
    return container
end


-- Função para criar aba
local function CriarAba(parent, nome, selecionada)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. nome
    btn.Parent = parent
    btn.BackgroundColor3 = selecionada and Cores.Destaque or Cores.FundoSecundario
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(0, 90, 0, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = nome
    btn.TextColor3 = Cores.Texto
    btn.TextSize = 13
    btn.ZIndex = 12
    btn.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    return btn
end

-- Criar interface completa
local function CriarInterfaceCompleta()
    local ui = CriarUI()
    
    -- Criar abas
    local abaEsp = CriarAba(ui.TabContainer, "Esp", false)
    local abaAim = CriarAba(ui.TabContainer, "Aim", true)
    local abaConfig = CriarAba(ui.TabContainer, "Config", false)
    
    -- Containers de conteúdo para cada aba
    local conteudoEsp = Instance.new("Frame")
    conteudoEsp.Name = "ConteudoEsp"
    conteudoEsp.Parent = ui.ContentContainer
    conteudoEsp.BackgroundTransparency = 1
    conteudoEsp.Size = UDim2.new(1, 0, 0, 0)
    conteudoEsp.AutomaticSize = Enum.AutomaticSize.Y
    conteudoEsp.Visible = false
    conteudoEsp.ZIndex = 10
    
    local layoutEsp = Instance.new("UIListLayout")
    layoutEsp.SortOrder = Enum.SortOrder.LayoutOrder
    layoutEsp.Padding = UDim.new(0, 8)
    layoutEsp.Parent = conteudoEsp
    
    local conteudoAim = Instance.new("Frame")
    conteudoAim.Name = "ConteudoAim"
    conteudoAim.Parent = ui.ContentContainer
    conteudoAim.BackgroundTransparency = 1
    conteudoAim.Size = UDim2.new(1, 0, 0, 0)
    conteudoAim.AutomaticSize = Enum.AutomaticSize.Y
    conteudoAim.Visible = true
    conteudoAim.ZIndex = 10
    
    local layoutAim = Instance.new("UIListLayout")
    layoutAim.SortOrder = Enum.SortOrder.LayoutOrder
    layoutAim.Padding = UDim.new(0, 8)
    layoutAim.Parent = conteudoAim
    
    local conteudoConfig = Instance.new("Frame")
    conteudoConfig.Name = "ConteudoConfig"
    conteudoConfig.Parent = ui.ContentContainer
    conteudoConfig.BackgroundTransparency = 1
    conteudoConfig.Size = UDim2.new(1, 0, 0, 0)
    conteudoConfig.AutomaticSize = Enum.AutomaticSize.Y
    conteudoConfig.Visible = false
    conteudoConfig.ZIndex = 10
    
    local layoutConfig = Instance.new("UIListLayout")
    layoutConfig.SortOrder = Enum.SortOrder.LayoutOrder
    layoutConfig.Padding = UDim.new(0, 8)
    layoutConfig.Parent = conteudoConfig
    
    -- Função para trocar aba
    local function trocarAba(nome)
        conteudoEsp.Visible = nome == "Esp"
        conteudoAim.Visible = nome == "Aim"
        conteudoConfig.Visible = nome == "Config"
        
        abaEsp.BackgroundColor3 = nome == "Esp" and Cores.Destaque or Cores.FundoSecundario
        abaAim.BackgroundColor3 = nome == "Aim" and Cores.Destaque or Cores.FundoSecundario
        abaConfig.BackgroundColor3 = nome == "Config" and Cores.Destaque or Cores.FundoSecundario
        
        CurrentTab = nome
    end
    
    abaEsp.MouseButton1Click:Connect(function() trocarAba("Esp") end)
    abaAim.MouseButton1Click:Connect(function() trocarAba("Aim") end)
    abaConfig.MouseButton1Click:Connect(function() trocarAba("Config") end)
    
    --[[
        ═══════════════════════════════════════════════════════════════════════════════════════
                                            ABA ESP
        ═══════════════════════════════════════════════════════════════════════════════════════
    ]]
    
    CriarToggle(conteudoEsp, "ESP Ativo", Config.ESPAtivo, function(v)
        Config.ESPAtivo = v
    end, 1)
    
    CriarSeparador(conteudoEsp, "Elementos", 2)
    
    CriarToggle(conteudoEsp, "Box", Config.ESPBox, function(v)
        Config.ESPBox = v
    end, 3)
    
    CriarToggle(conteudoEsp, "Nome", Config.ESPNome, function(v)
        Config.ESPNome = v
    end, 4)
    
    CriarToggle(conteudoEsp, "Vida", Config.ESPVida, function(v)
        Config.ESPVida = v
    end, 5)
    
    CriarToggle(conteudoEsp, "Distância", Config.ESPDistancia, function(v)
        Config.ESPDistancia = v
    end, 6)
    
    CriarToggle(conteudoEsp, "Tracer", Config.ESPTracer, function(v)
        Config.ESPTracer = v
    end, 7)
    
    --[[
        ═══════════════════════════════════════════════════════════════════════════════════════
                                            ABA AIM
        ═══════════════════════════════════════════════════════════════════════════════════════
    ]]
    
    CriarToggle(conteudoAim, "Aimbot Ativo", Config.AimbotAtivo, function(v)
        Config.AimbotAtivo = v
        if FOVCircle then
            FOVCircle.Visible = v and Config.FOVVisivel
        end
    end, 1)
    
    CriarToggle(conteudoAim, "Bala Mágica", Config.BalaMagica, function(v)
        Config.BalaMagica = v
        if v then
            AtivarBalaMagica()
        end
    end, 2)
    
    CriarToggle(conteudoAim, "Pular Abatidos", Config.PularAbatidos, function(v)
        Config.PularAbatidos = v
    end, 3)
    
    CriarToggle(conteudoAim, "Ignorar Paredes", Config.IgnorarParedes, function(v)
        Config.IgnorarParedes = v
    end, 4)
    
    CriarSeparador(conteudoAim, "Mira", 5)
    
    CriarSlider(conteudoAim, "Taxa Headshot", 0, 100, Config.TaxaHeadshot, function(v)
        Config.TaxaHeadshot = v
    end, 6, "%")
    
    CriarDropdown(conteudoAim, "Parte Alvo", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, Config.ParteAlvo, function(v)
        Config.ParteAlvo = v
    end, 7)
    
    CriarDropdown(conteudoAim, "Estilo Mira", {"FOV", "MaisProximo", "Aleatorio"}, Config.EstiloMira, function(v)
        Config.EstiloMira = v
    end, 8)
    
    CriarSeparador(conteudoAim, "FOV", 9)
    
    CriarToggle(conteudoAim, "FOV Visível", Config.FOVVisivel, function(v)
        Config.FOVVisivel = v
        if FOVCircle then
            FOVCircle.Visible = v and Config.AimbotAtivo
        end
    end, 10)
    
    CriarSlider(conteudoAim, "Raio FOV", 50, 500, Config.FOVRaio, function(v)
        Config.FOVRaio = v
        if FOVCircle then
            FOVCircle.Radius = v
        end
    end, 11)
    
    CriarSeparador(conteudoAim, "Suavização", 12)
    
    CriarToggle(conteudoAim, "Suavização Ativa", Config.SuavizacaoAtiva, function(v)
        Config.SuavizacaoAtiva = v
    end, 13)
    
    CriarSlider(conteudoAim, "Força Suavização", 0, 100, math.floor(Config.Suavizacao * 100), function(v)
        Config.Suavizacao = v / 100
    end, 14, "%")
    
    CriarSeparador(conteudoAim, "Hitbox Expander", 15)
    
    CriarToggle(conteudoAim, "Hitbox Expander", Config.HitboxExpanderAtivo, function(v)
        Config.HitboxExpanderAtivo = v
        if not v then
            RestaurarTodasHitboxes()
        end
    end, 16)
    
    CriarSlider(conteudoAim, "Tamanho Hitbox", 2, 20, Config.HitboxTamanho, function(v)
        Config.HitboxTamanho = v
    end, 17)
    
    CriarSlider(conteudoAim, "Transparência", 0, 100, math.floor(Config.HitboxTransparencia * 100), function(v)
        Config.HitboxTransparencia = v / 100
    end, 18, "%")
    
    CriarToggle(conteudoAim, "Apenas Cabeça", Config.HitboxApenasCabeca, function(v)
        Config.HitboxApenasCabeca = v
    end, 19)
    
    --[[
        ═══════════════════════════════════════════════════════════════════════════════════════
                                            ABA CONFIG
        ═══════════════════════════════════════════════════════════════════════════════════════
    ]]
    
    CriarSeparador(conteudoConfig, "Disparo Automático", 1)
    
    CriarToggle(conteudoConfig, "Disparo Automático", Config.DisparoAutomatico, function(v)
        Config.DisparoAutomatico = v
        if v then
            DetectarMelhorMetodo()
        end
    end, 2)
    
    CriarDropdown(conteudoConfig, "Método Disparo", {"Auto", "Mouse1Click", "Mouse1Press", "VIM", "TouchButton"}, Config.MetodoDisparo, function(v)
        Config.MetodoDisparo = v
        Estado.MetodoDisparoAtivo = v ~= "Auto" and v or nil
    end, 3)
    
    CriarSlider(conteudoConfig, "Delay Disparo", 50, 500, math.floor(Config.DelayDisparo * 1000), function(v)
        Config.DelayDisparo = v / 1000
    end, 4, "ms")
    
    CriarSeparador(conteudoConfig, "Predição", 5)
    
    CriarToggle(conteudoConfig, "Predição Movimento", Config.PredicaoAtiva, function(v)
        Config.PredicaoAtiva = v
    end, 6)
    
    CriarSlider(conteudoConfig, "Força Predição", 0, 50, math.floor(Config.ForcaPredicao * 100), function(v)
        Config.ForcaPredicao = v / 100
    end, 7, "%")
    
    CriarSeparador(conteudoConfig, "Distância", 8)
    
    CriarSlider(conteudoConfig, "Distância Máxima", 100, 2000, Config.DistanciaMaxima, function(v)
        Config.DistanciaMaxima = v
    end, 9, "m")
    
    CriarSeparador(conteudoConfig, "Times", 10)
    
    -- Atualizar times disponíveis
    AtualizarTimesDisponiveis()
    
    CriarDropdown(conteudoConfig, "Modo Time", {"Inimigos", "Todos", "TimeEspecifico"}, Config.ModoTime, function(v)
        Config.ModoTime = v
    end, 11)
    
    if #Estado.TimesDisponiveis > 0 then
        CriarDropdown(conteudoConfig, "Time Alvo", Estado.TimesDisponiveis, Estado.TimesDisponiveis[1], function(v)
            Config.TimeAlvo = v
        end, 12)
    end
    
    return ui
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        LOOP PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function LoopPrincipal()
    local conexaoRender = RunService.RenderStepped:Connect(function()
        -- Atualizar FOV Circle
        AtualizarFOVCircle()
        
        -- Atualizar ESP
        for jogador, _ in pairs(ElementosESP) do
            AtualizarESP(jogador)
        end
        
        -- Aimbot
        if Config.AimbotAtivo and not Estado.InteragindoComUI then
            local alvo, parteAlvo = EncontrarMelhorAlvo()
            
            if alvo and parteAlvo then
                Estado.AlvoAtual = alvo
                Estado.ParteAlvoAtual = parteAlvo
                Estado.Travado = true
                
                -- Calcular posição com predição
                local posicaoMira = PreverPosicao(alvo.Character, parteAlvo)
                
                -- Mirar
                MirarEm(posicaoMira)
                
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
            Estado.Travado = false
        end
    end)
    
    table.insert(Conexoes, conexaoRender)
    
    -- Loop de atualização de hitboxes (menos frequente para performance)
    local conexaoHitbox = RunService.Heartbeat:Connect(function()
        if Config.HitboxExpanderAtivo then
            AtualizarHitboxes()
        end
    end)
    
    table.insert(Conexoes, conexaoHitbox)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        INICIALIZAÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    print("[SAVAGECHEATS_] Iniciando v5.0...")
    
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Inicializar ESP
    InicializarESP()
    
    -- Criar UI
    CriarInterfaceCompleta()
    
    -- Detectar método de disparo
    DetectarMelhorMetodo()
    
    -- Iniciar loop principal
    LoopPrincipal()
    
    -- Ativar bala mágica se configurado
    if Config.BalaMagica then
        AtivarBalaMagica()
    end
    
    print("[SAVAGECHEATS_] Carregado com sucesso!")
    print("[SAVAGECHEATS_] Método de disparo detectado: " .. (Estado.MetodoDisparoAtivo or "Nenhum"))
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        DESTRUIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Destruir()
    print("[SAVAGECHEATS_] Destruindo...")
    
    -- Desconectar todas as conexões
    for _, conexao in pairs(Conexoes) do
        pcall(function() conexao:Disconnect() end)
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Restaurar hitboxes
    RestaurarTodasHitboxes()
    
    -- Desativar bala mágica
    DesativarBalaMagica()
    
    -- Destruir UI
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    
    -- Limpar variáveis globais
    _G.SAVAGECHEATS_LOADED = nil
    _G.SAVAGECHEATS_DESTROY = nil
    
    print("[SAVAGECHEATS_] Destruído com sucesso!")
end

-- Registrar função de destruição globalmente
_G.SAVAGECHEATS_DESTROY = Destruir

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        EXECUTAR
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

Inicializar()
