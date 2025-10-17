-- SHIFTHUB AUTO LOADER V2 (Autenticação automática por Discord/Roblox ID)
-- Ajuste estes valores para o seu ambiente (ngrok + secret)
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev" -- ex: https://patchily-droopiest-herbert.ngrok-free.dev
local API_SECRET = "Xota321" -- coloque aqui seu API_SECRET (mantenha privado)

-- === CONFIGURAÇÕES ===
local DISCORD_ID = nil -- Será preenchido automaticamente se você usar o sistema de vinculação
local DEBUG_MODE = true -- Ative para ver logs detalhados

-- === FUNÇÃO TRIM ===
local function trim(s)
    if not s then return "" end
    s = s:gsub("^%s+", "")
    return s:gsub("%s+$", "")
end

-- === FUNÇÃO DE LOG ===
local function log(message, level)
    level = level or "INFO"
    local prefix = "[ShiftHub AutoLoader]"
    
    if level == "ERROR" then
        warn(prefix .. " ❌ " .. message)
    elseif level == "SUCCESS" then
        print(prefix .. " ✅ " .. message)
    elseif level == "DEBUG" and DEBUG_MODE then
        print(prefix .. " 🔍 " .. message)
    else
        print(prefix .. " ℹ️ " .. message)
    end
end

-- === FUNÇÃO PARA OBTER HWID ===
local function getHwid()
    local hwid = ""
    local hwid_functions = {gethwid, get_hwid}
    
    for _, func in ipairs(hwid_functions) do
        if func then
            local ok, result = pcall(func)
            if ok and result ~= nil and result ~= "" then
                hwid = tostring(result)
                log("HWID obtido via " .. tostring(func), "DEBUG")
                break
            end
        end
    end
    
    if hwid == "" or hwid == "Unknown" then
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local user_name = Players.LocalPlayer.Name
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
        log("HWID gerado via fallback", "DEBUG")
    end
    
    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

-- === MÉTODO 1: BUSCAR KEY POR DISCORD ID ===
local function getKeyByDiscordId(discordId)
    if not discordId then return nil end
    
    log("Buscando key via Discord ID: " .. discordId, "DEBUG")
    
    local url = string.format("%s/get-key-by-discord?discordId=%s&secret=%s", API_URL_BASE, tostring(discordId), tostring(API_SECRET))
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and result and result ~= "no_key_found" then
        local key = trim(result)
        if #key == 16 then
            log("Key encontrada via Discord ID!", "SUCCESS")
            return key
        end
    end
    
    log("Nenhuma key encontrada para Discord ID: " .. discordId, "DEBUG")
    return nil
end

-- === MÉTODO 2: BUSCAR KEY POR ROBLOX USER ID ===
local function getKeyByRobloxId()
    local Players = game:GetService("Players")
    local userId = tostring(Players.LocalPlayer.UserId)
    
    log("Buscando key via Roblox ID: " .. userId, "DEBUG")
    
    local url = string.format("%s/get-key-by-roblox?robloxId=%s&secret=%s", API_URL_BASE, tostring(userId), tostring(API_SECRET))
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and result and result ~= "no_key_found" then
        local key = trim(result)
        if #key == 16 then
            log("Key encontrada via Roblox ID!", "SUCCESS")
            return key
        end
    end
    
    log("Nenhuma key encontrada para Roblox ID: " .. userId, "DEBUG")
    return nil
end

-- === MÉTODO 3: CACHE LOCAL ===
local function getKeyFromCache()
    if _G.ShiftHub_CachedKey and #_G.ShiftHub_CachedKey == 16 then
        log("Key encontrada no cache!", "SUCCESS")
        return _G.ShiftHub_CachedKey
    end
    return nil
end

-- === MÉTODO 4: INPUT MANUAL (FALLBACK) ===
local function getKeyFromUser()
    log("Solicitando input manual da key...", "DEBUG")
    
    if gettextinput then
        local ok, result = pcall(function()
            return gettextinput("ShiftHub - Primeira Execução", "Insira sua Script Key de 16 caracteres:")
        end)
        if ok and result and #result == 16 then
            local key = trim(result)
            _G.ShiftHub_CachedKey = key -- Salva no cache
            log("Key inserida manualmente!", "SUCCESS")
            return key
        end
    end
    
    log("Não foi possível obter input do usuário", "ERROR")
    return nil
end

-- === FUNÇÃO PRINCIPAL: OBTER KEY AUTOMATICAMENTE ===
local function getScriptKey()
    log("Iniciando busca automática de key...")
    
    -- Método 1: Discord ID (se configurado)
    if DISCORD_ID then
        local key = getKeyByDiscordId(DISCORD_ID)
        if key then return key end
    end
    
    -- Método 2: Roblox User ID
    local key = getKeyByRobloxId()
    if key then return key end
    
    -- Método 3: Cache local
    key = getKeyFromCache()
    if key then return key end
    
    -- Método 4: Input manual (primeira vez)
    log("Nenhuma key automática encontrada. Solicitando input manual...", "INFO")
    key = getKeyFromUser()
    if key then return key end
    
    return nil
end

-- === NOTIFICAÇÃO ===
local function notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- ========================================
-- === INÍCIO DA AUTENTICAÇÃO ===
-- ========================================

log("===========================================")
log("ShiftHub AutoLoader v2.0")
log("===========================================")

-- Obtém a key
local script_key = getScriptKey()

if not script_key or #script_key ~= 16 then
    notify("ShiftHub", "❌ Erro: Nenhuma key encontrada", 10)
    error("[ShiftHub] Não foi possível obter sua key. Resgate uma key no Discord primeiro!")
end

log("Key obtida: " .. script_key:sub(1, 4) .. "************")

-- Obtém o HWID
local user_hwid = getHwid()
log("HWID: " .. user_hwid:sub(1, 20) .. "...")

-- Valida com o servidor (inclui o secret)
log("Validando com servidor...")
local full_url = string.format("%s/verify?key=%s&hwid=%s&secret=%s", API_URL_BASE, script_key, user_hwid, API_SECRET)

local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    notify("ShiftHub", "❌ Erro de conexão", 10)
    error("[ShiftHub] Não foi possível conectar ao servidor de autenticação.")
end

local response = result:gsub("'", ""):gsub('"', ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
log("Resposta do servidor: " .. response, "DEBUG")

local VALIDACAO_SUCESSO = false

if response == "hwid_registrado" then
    log("HWID registrado com sucesso!", "SUCCESS")
    notify("ShiftHub", "✅ Dispositivo registrado!", 5)
    VALIDACAO_SUCESSO = true
    
elseif response == "hwid_valido" then
    log("Autenticação bem-sucedida!", "SUCCESS")
    notify("ShiftHub", "✅ Autenticado com sucesso!", 3)
    VALIDACAO_SUCESSO = true
    
elseif response == "script_key_invalida" then
    notify("ShiftHub", "❌ Key inválida", 10)
    _G.ShiftHub_CachedKey = nil -- Limpa cache
    error("[ShiftHub] Key inválida ou expirada. Use !checkkey no Discord para verificar.")
    
elseif response == "hwid_diferente" then
    notify("ShiftHub", "❌ HWID diferente", 10)
    error("[ShiftHub] Esta key está vinculada a outro dispositivo. Use o botão 'Reset HWID' no Discord.")
    
else
    notify("ShiftHub", "❌ Erro desconhecido", 10)
    error("[ShiftHub] Resposta inesperada: " .. response)
end

-- Carrega o script principal
if VALIDACAO_SUCESSO then
    _G.ShiftHub_Validated = true
    
    log("Carregando Shift Hub...")
    notify("ShiftHub", "🚀 Carregando...", 2)
    
    local GITHUB_SCRIPT_URL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/ShiftHubScript.lua"
    local script_success, script_error = pcall(function()
        loadstring(game:HttpGet(GITHUB_SCRIPT_URL, true))()
    end)
    
    if not script_success then
        log("Erro ao carregar o hub: " .. tostring(script_error), "ERROR")
        notify("ShiftHub", "❌ Erro ao carregar hub", 10)
        error("[ShiftHub] Erro ao carregar: " .. tostring(script_error))
    end
    
    log("Hub carregado com sucesso!", "SUCCESS")
else
    error("[ShiftHub] Falha na autenticação.")
end
