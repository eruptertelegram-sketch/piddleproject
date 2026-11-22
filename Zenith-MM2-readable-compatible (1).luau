-- Zenith MM2 readable source with local key UI removed and executor capability checks.
-- Resolve executor capabilities without changing global executor functions.
local function createCompatibility()
    local C = {}
    local environment = type(getgenv) == "function" and getgenv() or getfenv(0)
    local function functionFrom(...)
        for index = 1, select("#", ...) do
            local value = select(index, ...)
            if type(value) == "function" then return value end
        end
    end
    local function member(object, key)
        if type(object) == "table" then return object[key] end
    end
    local function native(name)
        return functionFrom(environment[name], getfenv(0)[name])
    end
    C.getgenv = function() return environment end
    C.gethui = function()
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    C.request = functionFrom(native("request"), native("http_request"), native("httprequest"), native("httpRequest"),
        member(syn, "request"), member(http, "request"), member(fluxus, "request"))
    C.http_request = C.request
    C.setclipboard = functionFrom(native("setclipboard"), native("toclipboard"), native("writeclipboard"))
    C.queue_on_teleport = functionFrom(native("queue_on_teleport"), native("queueonteleport"),
        member(syn, "queue_on_teleport"), member(fluxus, "queue_on_teleport"))
    C.queueonteleport = C.queue_on_teleport
    for _, name in ipairs({"hookmetamethod", "getnamecallmethod", "checkcaller", "newcclosure", "setnamecallmethod",
        "getconnections", "firesignal", "firetouchinterest", "fireproximityprompt", "setfpscap", "sethiddenproperty"}) do
        C[name] = native(name)
    end

    local drawing = environment.Drawing or Drawing
    if drawing ~= nil then
        local ok = pcall(function()
            assert(type(drawing.new) == "function")
            for _, class in ipairs({"Text", "Square", "Line", "Circle"}) do
                local object = drawing.new(class)
                assert(object ~= nil, "Drawing.new returned nil")
                object:Remove()
            end
        end)
        if ok then C.Drawing = drawing end
    end

    -- Sessions without file APIs can still use the configuration UI in memory.
    local files, folders = {}, {}
    local read, write, exists = native("readfile"), native("writefile"), native("isfile")
    local remove, list = native("delfile"), native("listfiles")
    C.readfile = function(path)
        if (not read or not write) and files[path] ~= nil then return files[path] end
        if read then return read(path) end
        assert(files[path] ~= nil, "File not found: " .. tostring(path))
        return files[path]
    end
    C.writefile = function(path, value)
        if write then write(path, value) end
        files[path] = value
    end
    C.isfile = function(path)
        if (not read or not write) and files[path] ~= nil then return true end
        if exists then return exists(path) end
        if read then
            local ok, value = pcall(read, path)
            return ok and type(value) == "string"
        end
        return files[path] ~= nil
    end
    C.makefolder = native("makefolder") or function(path) folders[path] = true end
    C.isfolder = native("isfolder") or function(path) return folders[path] == true end
    C.listfiles = list or function(path)
        local result = {}
        local prefix = path:gsub("[/\\]+$", "") .. "/"
        for name in pairs(files) do
            if name:sub(1, #prefix) == prefix then table.insert(result, name) end
        end
        table.sort(result)
        return result
    end
    C.delfile = remove and function(path)
        remove(path)
        files[path] = nil
    end
    if not remove and not read and not write then
        C.delfile = function(path) files[path] = nil end
    end
    C.capabilities = {drawing = C.Drawing ~= nil, namecall = C.hookmetamethod ~= nil and C.getnamecallmethod ~= nil and C.checkcaller ~= nil,
        http = C.request ~= nil, persistentFiles = read ~= nil and write ~= nil}
    return C
end
local Compat = createCompatibility()

local function showStartupError(message)
    local detail = tostring(message)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        detail = debug.traceback(detail, 2)
    end
    warn("[Zenith startup] " .. detail)
    pcall(function()
        if Compat.writefile then Compat.writefile("Zenith-startup-error.txt", detail) end
        local gui = Instance.new("ScreenGui")
        gui.Name = "ZenithStartupError"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1000000
        gui.Parent = Compat.gethui()
        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.fromScale(0.5, 0.5)
        panel.Size = UDim2.new(0.9, 0, 0.5, 0)
        panel.BackgroundColor3 = Color3.fromRGB(28, 29, 36)
        panel.Parent = gui
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -20, 1, -62)
        text.Position = UDim2.fromOffset(10, 8)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.new(1, 1, 1)
        text.TextSize = 14
        text.TextWrapped = true
        text.Text = "Zenith: ошибка запуска\n" .. detail:sub(1, 1800)
        text.Parent = panel
        local copy = Instance.new("TextButton")
        copy.Size = UDim2.new(1, -20, 0, 42)
        copy.Position = UDim2.new(0, 10, 1, -50)
        copy.Text = "Скопировать ошибку"
        copy.Parent = panel
        copy.Activated:Connect(function()
            if Compat.setclipboard then
                local ok = pcall(Compat.setclipboard, detail)
                copy.Text = ok and "Скопировано" or "Не удалось скопировать"
            else
                copy.Text = "Смотри Zenith-startup-error.txt или консоль"
            end
        end)
    end)
    return detail
end


local function runZenith(...)
    if not game:IsLoaded() then game.Loaded:Wait() end
    local players = game:GetService("Players")
    while not players.LocalPlayer do players:GetPropertyChangedSignal("LocalPlayer"):Wait() end
    while not workspace.CurrentCamera do task.wait() end
local ZENITH_SELF = ...
local ZENITH_PLACES = {[142823291] = true}
local function isMM2Place()
    return game.PlaceId == 142823291
end
if not isMM2Place() then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Zenith | MM2",
            Text = "This script only works in Murder Mystery 2",
            Duration = 6,
        })
    end)
    return
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local lp = Players.LocalPlayer

-- Local key prompt and verification removed.
local ZLoad = {done = function() end, gone = true}

local function sig(name, fallback)
    local ok, v = pcall(function() return RunService[name] end)
    if ok and v then return v end
    return RunService[fallback]
end
local PRE_RENDER = sig("PreRender", "RenderStepped")
local PRE_SIM = sig("PreSimulation", "Stepped")
local cam = workspace.CurrentCamera

local genv = (Compat.getgenv and Compat.getgenv()) or _G
for _, k in ipairs({"ZenithWind", "SwagaWind", "NyxWind", "NyxSE", "NyxFull", "NyxFarm", "NyxAll", "NyxESP", "NyxSA", "NyxKA", "NyxFling"}) do
    if genv[k] then pcall(genv[k]) end
end

local CFG = {
    esp = true, box = false, skeleton = false, highlight = true, name = false, dist = false,
    tracer = false, health = false, gun = true, showInnocent = true, maxDist = 800, skelDist = 300, avatar = false, arrows = false, arrowRadius = 140,
    optimize = true, fpsUnlock = false, sky = "Default", skyId = "",
    silent = true, wallbang = true, wbRange = 12, wbHold = 0.12, silentMethod = "Silent", burst = false, predMul = 1, aimHeight = 0.2, silentHud = false,
    knifeSilent = true, knifeWB = false, knifeAssist = true, knifeLead = 0.03, knifeSpeed = 100, knifeFov = 70, knifeMode = "Crosshair",
    farm = false, coinEsp = false, wbStyle = "Attachment", shotColor = "#FFFFFF", roundTimer = false, fakeKorblox = false, fakeHeadless = false, crosshair = false, crossSize = 40, crossColor = "#FFFFFF", killTool = false, autoSheriff = false, autoMurder = false,
    espGrad = false, gradA = "#FF4D6D", gradB = "#7B5CFF", gradAnim = true, selfChams = false, selfMode = "Highlight",
    selfColor = "#7B5CFF", voteDupe = false, voteCopies = 25, flingSheriffAuto = false, flingMurderAuto = false,
    aaDesync = false, aaMode = "Chaos", aaHeight = 60, aaSpin = true, boxStyle = "Corners", wepChams = false, wepMode = "Highlight", wepColor = "#00E5FF", infSilent = false, infPart = "Torso", infFov = 0, farmMode = "Walk", farmMethod = "Basic", shaderPreset = "Off", pixelSurf = false, surfFall = 0.5, wallHop = false, menuBg = "Space",
    farmDash = false, chatFrame = "None", uiSound = true, shootChance = 100, invis = false, shotFx = "Neon", avoidMurder = true, avoidSheriff = false,
    bfReset = false, bfKillMurder = false, bfKillAll = false, bfInfKillAll = false, bfInfKillZombies = false, autoRejoin = true,
    flingAfterMurd = false, flingAfterSher = false, flingAfterAll = false, espCandy = false,
    infAvoidZombies = false, infAvoidSurvivors = false, avoidSherAsMurd = false, avoidMurdAsSheriff = false, autoBattlePass = false, avoidMurdAsInno = false,
    lobbyFlingMurd = false, lobbyFlingSher = false, lobbyFlingAll = false, questsBagFull = false, questsAlways = false, antiTrap = false, tradeHelper = true, antiAfk = true, invisBtn = false, predMulAS = 1, silentChance = 100,
    timeOn = false, clockTime = 14, fogChOn = false, fogChEnd = 600, fogChColor = "#C8D2E6", brightOn = false, brightV = 3,
    ambOn = false, ambColor = "#8C8C9C", skybox = "Off", antiOn = true, antiFlingSel = false, antiAfkSel = true, antiTrapSel = false, autoJumpBomb = false, jumpBtn = false,
    shootBtnX = 8, shootBtnY = 50, invisBtnX = 8, invisBtnY = 64, jumpBtnX = 16, jumpBtnY = 64,
    hitNotify = true, missNotify = false, jumpBombBtn = false, jbbX = 16, jbbY = 50, rain = false, rainRate = 500, rainColor = "#BFD9FF", bagLobby = true, bagMax = 50, binds = "", bindHud = true, voteWant = "", touchFling = false, airStrafe = false, airAccel = 60, airMax = 45, autoStrafe = false, strafeGain = 12, strafeMax = 40, tStrafe = false, tStrafeRadius = 10, tStrafeSpeed = 180, tStrafeMove = 40, coinHighlight = true, coinTracer = true, coinTracerDist = 200, farmUnder = true,
    autoGun = true, autoKill = false, auraRange = 30, auraTp = false, stabReach = 6,
    farmSpeed = 22, vSpeed = 45, depth = 7, gunSpeed = 150, pickDist = 400,
    killSpeed = 70, killRange = 250, hitDelay = 0.15, maxTries = 2,
    maxCoins = 40, coinRange = 1500, dangerDist = 30,
    bhop = false, bhopSpeed = 30, spinOn = false, spinSpeed = 200,
    killSnd = true, replaceSnd = true, gunSnd = "SFX Hit", gunVol = 2.5, knifeSnd = "Among Us Kill", knifeVol = 1.5,
    autoShoot = false, shootBtn = false, shootDelay = 0.1, ghostTransp = 0.5, pickTime = 0.25, shootMax = 1e9,
    shaders = false, blackSky = true, fogOn = true, fog = 350, density = 0.45,
    bloom = 1.6, contrast = 0.3, sat = 0.4, dof = 0.12, bright = 1.6,
    trail = false, trailLife = 0.8, trailTransp = 0.72, trailSmoke = true,
    shotTrail = false, shotLife = 1.2,
    aura = false, wings3d = false, auraSpeed = 1.2, wingX = 0, wingY = 0, wingZ = 0, wingIdle = 0.3, wingYaw = 0.25, wingPreset = "Angel", wingParticles = true, wingOrbs = true,
    helper = false, helperStyle = "Fairy", helperSize = 1,
    noclip = false, fly = false, flySpeed = 60, wsOn = false, walkSpeed = 24, jpOn = false, jumpPower = 70,
    xray = false, xrayTransp = 0.5,
    hackerRetry = false,
    flingAuto = false, antiFling = false, spin = 80000, flingTime = 2.2, killVel = 180, flingCooldown = 6,
    bodyGlow = false, glowColor = "Rainbow", crown = false, groundRing = false, ringColor = "Cyan",
    elemAura = false, elemType = "Fire", nameTag = false, nameTagText = "Zenith", trailColor = "Purple",
    gunCustom = "", knifeCustom = "", killCustom = "", killSndName = "Among Us Kill", killVol = 2,
    orbitStars = false, auraSphere = false, footSparkle = false,
    trailMode = "Chams", powerAura = false, auraStyle = "Super Saiyan",
    hitboxOn = false, hitboxSize = 8, reachOn = false, reachSize = 8,
    roleNotify = true, murderAlert = false, alertDist = 35, fullbright = false, fovOn = false, fov = 90,
    antiAfk = true, infJump = false,
    chamsStyle = "Chams", chamsColor = "Role", weaponEsp = true, weaponStyle = "Chams", knifeColor = "Red", gunColor = "Blue",
    trailDelay = 0.35,
    droneType = "FPV", droneTarget = "Murder (Kill)", droneModelYaw = 0, droneMeshScale = 1, droneMeshFlip = false,
    tung = false, tungScale = 1, tungYaw = 0, tungY = 0, studs = false, droneTpKill = true, droneCam = "First person", droneInfBat = false, droneCamDist = 9,
    knifeSkinName = "None", gunSkinName = "None", droneNoclip = false, knifeLib = "None", gunLib = "None", skinCapture = false, knifeDB = "None", gunDB = "None",
    flingMethod = "Skid", aaOn = false, aaType = "Body", aaMode = "Up", aaAngle = 75, aaRandRate = 0.12,
    auraOn = false, auraName = "Angel", auraColSet = false, auraCol = Color3.fromRGB(255, 255, 255),
    killNotify = true, wmUser = true, wmFps = true, wmPing = true, wmTime = true, wmSub = true, wmCfg = false,
    wmGame = false, wmExec = false, wmRamGb = false, wmRamMb = false,
    speedGlitch = false, sgSpeed = 45, sgAutoJump = false,
    ribbon = false, ribbonColor = "Rainbow", ribbonLife = 0.6, potato = false,
    emote = "Salute", emoteLoop = false, emoteSpeed = 1,
    animPack = "Default", animIdle = "Default", animWalk = "Default", animRun = "Default", animJump = "Default", animFall = "Default", animClimb = "Default",
    gunSkin = false, gunSkinId = "11006944635", gunSkinScale = 1, gunSkinRot = 0,
    knifeSkin = false, knifeSkinId = "", knifeSkinScale = 1, knifeSkinRot = 0,
    customChar = false, charModelId = "84115454229681", charScale = 1, charYaw = 0, charY = 0,
    chinaHat = false, hatColor = "Rainbow",
    watermark = true, wmTimer = true,
    specMurd = false, specSher = false, gunNotify = true,
    lang = "EN", theme = "Black", uiScale = 1, wbMode = "Spoof", droneMesh = false,
}
local COLORS = {
    Murderer = Color3.fromRGB(255, 60, 60),
    Sheriff = Color3.fromRGB(60, 130, 255),
    Hero = Color3.fromRGB(255, 220, 60),
    Innocent = Color3.fromRGB(80, 255, 120),
    Zombie = Color3.fromRGB(150, 255, 40),
    Infected = Color3.fromRGB(150, 255, 40),
    Survivor = Color3.fromRGB(80, 255, 120),
}
-- the murderer, or any zombie / infected in the infection mode
local function hostileRole(r)
    if r == "Murderer" then return true end
    if type(r) ~= "string" then return false end
    local l = string.lower(r)
    return string.find(l, "zomb", 1, true) ~= nil or string.find(l, "infect", 1, true) ~= nil
end
local BLACK = Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(255, 215, 60)
local COLOR_MAP = {
    Dark = Color3.fromRGB(40, 40, 46), Red = Color3.fromRGB(255, 50, 60), Blue = Color3.fromRGB(60, 130, 255),
    Green = Color3.fromRGB(70, 255, 120), Purple = Color3.fromRGB(170, 90, 255), Cyan = Color3.fromRGB(60, 240, 255),
    White = Color3.fromRGB(255, 255, 255), Gold = Color3.fromRGB(255, 205, 60), Pink = Color3.fromRGB(255, 110, 190),
}
local COLOR_NAMES = {"Rainbow", "Red", "Blue", "Green", "Purple", "Cyan", "White", "Gold", "Pink"}
local TRAIL_NAMES = {"Dark", "Rainbow", "Red", "Blue", "Green", "Purple", "Cyan", "White", "Gold", "Pink"}
local function colorOf(name)
    if type(name) == "string" and name:sub(1, 1) == "#" then
        local ok, hc = pcall(Color3.fromHex, name)
        if ok then return hc end
    end
    local c = COLOR_MAP[name]
    if c then return c end
    return Color3.fromHSV((tick() * 0.25) % 1, 0.85, 1)
end

local HAS_DRAW = typeof(Compat.Drawing) == "table" or typeof(Compat.Drawing) == "userdata"

local R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local UP, DOWN = Vector3.new(0, 3, 0), Vector3.new(0, 3.5, 0)
for _, gk in ipairs({"gBox", "gCham", "gSkel", "gTrac", "gName", "gArrow", "gSelf", "gWep"}) do
    if CFG[gk] == nil then
        CFG[gk], CFG[gk .. "A"], CFG[gk .. "B"], CFG[gk .. "Anim"] = false, "#FF4D6D", "#7B5CFF", true
    end
end

do
    local d = {}
    for k, v in pairs(CFG) do d[k] = v end
    genv.ZenithCfgDefault = d
end
local PARTS = {"box", "hpBack", "hp", "tracer", "name", "dist", "arrow"}

local conns, draws = {}, {}
local running = true
local function connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end
local function draw(class)
    local d = Compat.Drawing.new(class)
    draws[#draws + 1] = d
    return d
end
local function newText()
    local a, b = draw("Text"), draw("Text")
    for _, t in ipairs({a, b}) do
        t.Size, t.Center, t.Visible = 16, true, false
        pcall(function() t.Font = 2 end)
    end
    a.Outline, b.Outline = true, false
    pcall(function()
        a.ZIndex = 1
        b.ZIndex = 2
    end)
    local off = Vector2.new(1, 0)
    return setmetatable({}, {
        __index = function(_, k)
            if k == "Remove" then
                return function()
                    pcall(function() a:Remove() end)
                    pcall(function() b:Remove() end)
                end
            end
            return a[k]
        end,
        __newindex = function(_, k, v)
            a[k] = v
            if k == "Position" then b[k] = v + off elseif k ~= "Outline" then b[k] = v end
        end,
    })
end

local ST = genv.ZenithWindST or {}
genv.ZenithWindST = ST
ST.rec = ST.rec or {}
ST.on, ST.aimPos, ST.target = CFG.silent, nil, nil

local WB_METHODS = {"Hacker", "Pro", "Quiet"}

local stRP = RaycastParams.new()
local wbOP = OverlapParams.new()
wbOP.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() wbOP.RespectCanCollide = true end)
stRP.FilterType = Enum.RaycastFilterType.Exclude
ST.hist = ST.hist or setmetatable({}, {__mode = "k"})
ST.knifeSpeed = 100

function ST.passDown(old, ...)
    local prev = ST.on
    ST.on = false
    local ok, err = pcall(old, ...)
    ST.on = prev
    if not ok then error(err, 0) end
end

-- horizontal velocity: replicated one, or measured from displayed positions
function ST.velOf(t)
    local r = ST.hist[t]
    local v = t.AssemblyLinearVelocity
    local av = Vector3.new(v.X, 0, v.Z)
    local hv = r and Vector3.new(r.v.X, 0, r.v.Z) or Vector3.zero
    if av.Magnitude < 1 and hv.Magnitude > 4 then av = hv end
    return av, v.Y
end

-- a farmer: moved through the map by CFrame (no own velocity), far off the floor or under it
ST.farmerLike = function(t)
    ST.flRP = ST.flRP or RaycastParams.new()
    ST.flRP.FilterType = Enum.RaycastFilterType.Exclude
    ST.flRP.FilterDescendantsInstances = {t.Parent, lp.Character}
    local down = workspace:Raycast(t.Position, Vector3.new(0, -12, 0), ST.flRP)
    local up = workspace:Raycast(t.Position, Vector3.new(0, 30, 0), ST.flRP)
    return (not down) or (up and not down)
end
local function predict(t, k, extra)
    local fv, vy = ST.velOf(t)
    local lead = (math.clamp(ST.ping or 0.08, 0, 0.6) + 0.1) * k + (extra or 0)
    -- auto-farmers: moved by CFrame (no velocity of their own) along coins, up and down through the map
    local r = ST.hist[t]
    local real = t.AssemblyLinearVelocity
    if r and r.v and r.v.Magnitude > 32 and real.Magnitude < 1 and ST.farmerLike and ST.farmerLike(t) then
        return t.Position + r.v * lead, Vector3.new(r.v.X, 0, r.v.Z)
    end
    local p = t.Position + fv * lead
    if math.abs(vy) > 3 then
        local dy = vy * lead - 0.5 * 196.2 * lead * lead
        p += Vector3.new(0, math.clamp(dy, -6, 6), 0)
        -- a falling target can't go through the floor
        ST.floorRP = ST.floorRP or RaycastParams.new()
        ST.floorRP.FilterType = Enum.RaycastFilterType.Exclude
        ST.floorRP.FilterDescendantsInstances = {t.Parent, lp.Character}
        local hit = workspace:Raycast(t.Position, Vector3.new(0, -60, 0), ST.floorRP)
        if hit and p.Y < hit.Position.Y + 2.5 then p = Vector3.new(p.X, hit.Position.Y + 2.5, p.Z) end
    end
    return p, fv
end

-- returns a list of {originPos or nil, aimPos}; [1] is the main shot
function ST.wbOrigin(p, me, tChar)
    local ignore = {tChar}
    if lp.Character then ignore[2] = lp.Character end
    stRP.FilterDescendantsInstances = ignore
    wbOP.FilterDescendantsInstances = ignore
    local dir = p - me
    dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0, -1)
    local side = Vector3.new(-dir.Z, 0, dir.X)
    side = side.Magnitude > 0.01 and side.Unit or Vector3.new(1, 0, 0)
    local up = Vector3.new(0, 1, 0)
    local offs = {-dir, (-dir + up * 0.6).Unit, up, side, -side, (-dir + side).Unit, (-dir - side).Unit, (up + side).Unit, (up - side).Unit}
    for _, dist in ipairs({2, 3, 4.5, 6, 8}) do
        for _, off in ipairs(offs) do
            local o = p + off * dist
            if not workspace:Raycast(o, p - o, stRP) then
                local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(o, 0.35, wbOP) end)
                if not ok or #parts == 0 then return o end
            end
        end
    end
    return p - dir * 2
end

function ST.tpShot(remote, a, o, aim)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp or ST.tpBusy then return end
    ST.tpBusy = true
    local old = hrp.CFrame
    local stand = o - Vector3.new(0, 1.5, 0)
    pcall(function()
        hrp.CFrame = CFrame.lookAt(stand, Vector3.new(aim.X, stand.Y, aim.Z))
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        ST.fireShoot(remote, table.unpack(a, 1, a.n))
        RunService.Heartbeat:Wait()
    end)
    hrp.CFrame = old
    hrp.AssemblyLinearVelocity = Vector3.zero
    ST.tpBusy = false
end

function ST.myGun()
    local c = lp.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Shoot") then return t end
    end
    return c:FindFirstChild("Gun")
end

function ST.gunAttachment(gun)
    if not gun then return nil end
    local att = gun:FindFirstChild("GunRaycastAttachment1", true)
    if att and att:IsA("Attachment") then return att end
    return nil
end

function ST.fireShoot(remote, ...)
    if remote:IsA("RemoteFunction") then
        local args = table.pack(...)
        task.spawn(function() pcall(function() remote:InvokeServer(table.unpack(args, 1, args.n)) end) end)
    else
        remote:FireServer(...)
    end
end

function ST.gunOrigin()
    local gun = ST.myGun()
    if not gun then return nil end
    local h = gun:FindFirstChild("Handle")
    local att = ST.gunAttachment(gun)
    if att and att:IsA("Attachment") then
        if att.Parent and att.Parent:IsA("BasePart") then return att.WorldPosition end
        if h then return (h.CFrame * att.CFrame).Position end
    end
    return h and h.Position or nil
end

function ST.peekOrigin(me, aim, tChar, R)
    local ignore = {tChar}
    if lp.Character then ignore[2] = lp.Character end
    stRP.FilterDescendantsInstances = ignore
    wbOP.FilterDescendantsInstances = ignore
    local dir = aim - me
    dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0, -1)
    local side = Vector3.new(-dir.Z, 0, dir.X)
    side = side.Magnitude > 0.01 and side.Unit or Vector3.new(1, 0, 0)
    local up = Vector3.new(0, 1, 0)
    local offs = {dir, side, -side, up, (dir + side).Unit, (dir - side).Unit, (dir + up).Unit,
                  (side + up).Unit, (-side + up).Unit, (dir - up * 0.5).Unit, -up}
    for _, frac in ipairs({0.2, 0.4, 0.6, 0.8, 1}) do
        local r = R * frac
        for _, off in ipairs(offs) do
            local o = me + off * r
            if not workspace:Raycast(o, aim - o, stRP) then
                local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(o, 0.3, wbOP) end)
                if not ok or #parts == 0 then return o end
            end
        end
    end
    return nil
end

function ST.findPeek(me, aim, tChar, R)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local ignore = {tChar, c}
    stRP.FilterDescendantsInstances = ignore
    wbOP.FilterDescendantsInstances = ignore
    local base = hrp.Position
    local gunOff = me - base
    local flat = aim - base
    flat = Vector3.new(flat.X, 0, flat.Z)
    local fwd = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
    local right = Vector3.new(-fwd.Z, 0, fwd.X)
    local ANGLES = {90, -90, 65, -65, 115, -115, 40, -40, 140, -140, 15, -15, 165, -165, 0, 180}
    local box = Vector3.new(1.8, 4.4, 1.4)
    for _, h in ipairs({0, 2.5}) do
        for _, dist in ipairs({1.5, 2.5, 3.5, 5, 7, 9.5, 12, 15, 19, 24, 30, 35, 40}) do
            if dist <= R then
                for _, deg in ipairs(ANGLES) do
                    local a = math.rad(deg)
                    local dir = fwd * math.cos(a) + right * math.sin(a)
                    local p = base + dir * dist + Vector3.new(0, h, 0)
                    local g = p + gunOff
                    if not workspace:Raycast(g, aim - g, stRP) then
                        local ok, parts = pcall(function()
                            return workspace:GetPartBoundsInBox(CFrame.new(p), box, wbOP)
                        end)
                        if not ok or #parts == 0 then
                            return {hrp = p, gun = g, dist = dist}
                        end
                    end
                end
            end
        end
    end
    return nil
end

function ST.peekShot(remote, tp)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp or ST.tpBusy then return end
    ST.tpBusy = true
    local look = tp.a[2]
    ST.ghost = {pos = tp.hrp, face = typeof(look) == "CFrame" and look.Position or nil}
    pcall(function()
        local okp, ping = pcall(function() return lp:GetNetworkPing() end)
        local hold = math.clamp((okp and ping or 0.1) * 0.6 + 0.08, 0.1, 0.3)
        local t0 = tick()
        repeat RunService.Heartbeat:Wait() until tick() - t0 >= hold
        ST.fireShoot(remote, table.unpack(tp.a, 1, tp.a.n))
        local t1 = tick()
        repeat RunService.Heartbeat:Wait() until tick() - t1 >= 0.06
    end)
    ST.ghost = nil
    ST.tpBusy = false
end

function ST.moveGunAttachment(point)
    local gun = ST.myGun()
    local att = ST.gunAttachment(gun)
    local h = gun and gun:FindFirstChild("Handle")
    if not (att and att:IsA("Attachment") and h) then return end
    local old = att.CFrame
    pcall(function()
        if att.Parent and att.Parent:IsA("BasePart") then
            att.WorldPosition = point
        else
            att.CFrame = h.CFrame:ToObjectSpace(CFrame.new(point))
        end
    end)
    task.delay(0.25, function()
        pcall(function() att.CFrame = old end)
    end)
end

function ST.calcAll(me, t, wb)
    ST.shotAt = tick()
    ST.shotTarget = t
    local mul = (ST.asCall and CFG.predMulAS) or CFG.predMul or 1
    local aim = predict(t, mul) + Vector3.new(0, CFG.aimHeight or 0.2, 0)
    ST.aimPos, ST.aimAt = aim, tick()
    local toT = aim - me
    local d = toT.Magnitude > 0.01 and toT.Unit or Vector3.new(0, 0, -1)
    if wb then
        local ignore = {t.Parent}
        if lp.Character then ignore[2] = lp.Character end
        stRP.FilterDescendantsInstances = ignore
        if workspace:Raycast(me, toT, stRP) then
            local pk = ST.findPeek(me, aim, t.Parent, 60)
            if pk then
                local d2 = aim - pk.gun
                d2 = d2.Magnitude > 0.01 and d2.Unit or d
                return {{pk.gun, aim + d2 * 3, peek = pk.hrp}}
            end
            local o = ST.wbOrigin(aim, me, t.Parent)
            ST.moveGunAttachment(o)
            local d2 = aim - o
            d2 = d2.Magnitude > 0.01 and d2.Unit or d
            return {{o, aim + d2 * 3}}
        end
    end
    return {{nil, aim + d * 2}}
end

function ST.knifeTarget(origin, dir, losFrom)
    local best, bestScore = nil, math.huge
    local du = dir.Unit
    local maxAng = math.rad(CFG.knifeFov or 70)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and (not ST.inRound or ST.inRound(p)) then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local blocked = false
            if h and h.Health > 0 and r and losFrom and not CFG.knifeWB then
                local ig = {c}
                if lp.Character then ig[2] = lp.Character end
                stRP.FilterDescendantsInstances = ig
                blocked = workspace:Raycast(losFrom, r.Position - losFrom, stRP) ~= nil
            end
            if h and h.Health > 0 and r and not blocked then
                local d = r.Position - origin
                local dist = d.Magnitude
                if dist > 0.5 and dist < 800 then
                    local score
                    if CFG.knifeMode == "Nearest" then
                        score = dist
                    else
                        local ang = math.acos(math.clamp(du:Dot(d.Unit), -1, 1))
                        if ang <= maxAng then score = ang + dist / 600 end
                    end
                    if score and score < bestScore then best, bestScore = r, score end
                end
            end
        end
    end
    return best
end

function ST.knifeRewrite(args)
    local first, second
    for i = 1, args.n do
        local ty = typeof(args[i])
        if ty == "CFrame" or ty == "Vector3" then
            if not first then
                first = i
            else
                second = i
                break
            end
        end
    end
    if not first then error("no position") end
    local a1 = args[first]
    local origin = typeof(a1) == "CFrame" and a1.Position or a1
    local dir
    if second then
        local a2 = args[second]
        dir = (typeof(a2) == "CFrame" and a2.Position or a2) - origin
    elseif typeof(a1) == "CFrame" then
        dir = a1.LookVector
    end
    if not dir or dir.Magnitude < 0.01 then
        local c0 = workspace.CurrentCamera
        dir = c0 and c0.CFrame.LookVector or Vector3.new(0, 0, -1)
    end
    local cam0 = workspace.CurrentCamera
    local t
    if cam0 and CFG.knifeMode ~= "Nearest" then
        t = ST.knifeTarget(cam0.CFrame.Position, cam0.CFrame.LookVector, origin)
    end
    t = t or ST.knifeTarget(origin, dir, origin)
    if not t then return end

    local spd = math.max(CFG.knifeSpeed, 10)
    local pred, fv = t.Position, Vector3.zero
    local travel = (pred - origin).Magnitude / spd
    for _ = 1, 4 do
        pred, fv = predict(t, CFG.predMul or 1, travel + CFG.knifeLead)
        travel = (pred - origin).Magnitude / spd
    end
    pred = pred + Vector3.new(0, CFG.aimHeight or 0.5, 0)
    local d = pred - origin
    d = d.Magnitude > 0.01 and d.Unit or dir.Unit

    local newO, aim = origin, pred + d * 2
    if CFG.knifeWB then
        stRP.FilterDescendantsInstances = {t.Parent, lp.Character}
        if workspace:Raycast(origin, pred - origin, stRP) then
            newO = ST.wbOrigin(pred, origin, t.Parent)
            local d2 = pred - newO
            d2 = d2.Magnitude > 0.01 and d2.Unit or d
            aim = pred + d2 * 3
        end
    end
    if CFG.knifeAssist and ST.onThrow then task.spawn(ST.onThrow, t, travel, origin) end
    if newO ~= origin then
        if typeof(a1) == "CFrame" then args[first] = CFrame.new(newO) * a1.Rotation else args[first] = newO end
    end
    if second then
        if typeof(args[second]) == "CFrame" then args[second] = CFrame.new(pred) else args[second] = pred end
    elseif typeof(a1) == "CFrame" then
        args[first] = CFrame.lookAt(newO, aim)
    end
end

function ST.isKnifeThrow(r, pn, ...)
    if pn == "Knife" then
        -- direct child of the tool
    elseif pn == "Events" then
        local tool = r.Parent and r.Parent.Parent
        if not (tool and tool.Name == "Knife") then return false end
    else
        return false
    end
    local cnt = 0
    for i = 1, select("#", ...) do
        local ty = typeof((select(i, ...)))
        if ty == "CFrame" or ty == "Vector3" then cnt += 1 end
    end
    local named = r.Name:lower():find("throw", 1, true) ~= nil
    if named then
        ST.throwLog = {t = tick(), a = table.pack(...), name = r:GetFullName()}
        local a1 = (select(1, ...))
        local o = (typeof(a1) == "CFrame" and a1.Position) or (typeof(a1) == "Vector3" and a1) or nil
        if o and ST.calibKnife then task.spawn(ST.calibKnife, o) end
        if cnt == 0 and CFG.knifeAssist and ST.onThrow then
            local cam0 = workspace.CurrentCamera
            local myH = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local from = myH and (myH.Position + Vector3.new(0, 1.5, 0)) or nil
            local tg = cam0 and ST.knifeTarget(cam0.CFrame.Position, cam0.CFrame.LookVector, from)
            if tg then task.spawn(ST.onThrow, tg, 0.25, from) end
        end
    end
    if cnt == 0 then return false end
    return named or cnt >= 2
end

ST.CFG = CFG
if ST.hookVer ~= 5 and Compat.hookmetamethod and Compat.getnamecallmethod and Compat.checkcaller then
    local hookOK, hookError = pcall(function()
    local wrap = Compat.newcclosure or function(f) return f end
    local old
    old = Compat.hookmetamethod(game, "__namecall", wrap(function(self, ...)
        local m = Compat.getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") and not Compat.checkcaller()
           and typeof(self) == "Instance" then
            local par = self.Parent
            if self.Name == "Shoot" and ST.onShotFire then pcall(ST.onShotFire) end
            if ST.antiTrap and par and par.Name == "TrapSystem" and string.find(self.Name, "Hit", 1, true) then
                return nil
            end
            if ST.infOn and ST.infRemote and ST.infRemote(self) then
                local args = table.pack(...)
                local okr, changed = pcall(ST.infRewrite, args)
                if okr and changed then
                    if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
                    return ST.passDown(old, self, table.unpack(args, 1, args.n))
                end
            end
            if ST.onVote and string.find(string.lower(self.Name), "vote", 1, true) then
                task.spawn(ST.onVote, self, m, table.pack(...))
            end
            if m == "FireServer" and self.Name == "GunBeam" and ST.onBeam then
                local pk = table.pack(...)
                task.spawn(ST.onBeam, "client -> server", self, pk)
            end
            if par then
                local pn = par.Name
                if m == "FireServer" and ST.CFG.knifeSilent and ST.isKnifeThrow(self, pn, ...) then
                    local args = table.pack(...)
                    local ok = pcall(ST.knifeRewrite, args)
                    if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
                    if ok then return ST.passDown(old, self, table.unpack(args, 1, args.n)) end
                elseif ST.on and ST.target and ST.target.Parent and (m == "FireServer" or m == "InvokeServer")
                   and ((CFG.silentChance or 100) >= 100 or math.random(1, 100) <= CFG.silentChance)
                   and self.Name == "Shoot" and (pn == "Gun" or par:IsA("Tool")) then
                    local args = table.pack(...)
                    ST.gunLogOrig = table.pack(...)
                    local pend, tp
                    local ok = pcall(function()
                        local first, second
                        for i = 1, args.n do
                            if typeof(args[i]) == "CFrame" then
                                if not first then
                                    first = i
                                else
                                    second = i
                                    break
                                end
                            end
                        end
                        if not first then error("no cframe") end
                        local me = (ST.gunOrigin and ST.gunOrigin()) or args[first].Position
                        local list = ST.calcAll(me, ST.target, ST.CFG.wallbang)
                        ST.aimPos = list[1][2]
                        local function make(v)
                            local a = table.pack(table.unpack(args, 1, args.n))
                            a[first] = CFrame.lookAt(v[1] or me, v[2])
                            if second then a[second] = CFrame.new(v[2]) end
                            return a
                        end
                        pend = {}
                        for i = 2, #list do pend[#pend + 1] = make(list[i]) end
                        args = make(list[1])
                        ST.gunLogSent = args
                        if list[1].peek and ST.peekShot then
                            tp = {a = args, hrp = list[1].peek}
                        end
                    end)
                    if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
                    if ok and tp then
                        task.spawn(ST.peekShot, self, tp)
                        return nil
                    end
                    if ok then
                        local r = ST.passDown(old, self, table.unpack(args, 1, args.n))
                        ST.lastShot = {r = self, t = tick(), n = 0}
                        for _, x in ipairs(pend or {}) do
                            if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
                            ST.passDown(old, self, table.unpack(x, 1, x.n))
                        end
                        return r
                    end
                elseif pn == "Events" then
                    local nm = self.Name
                    local l = ST.rec[nm]
                    if not l then
                        l = {}
                        ST.rec[nm] = l
                    end
                    l[#l + 1] = {a = table.pack(...), p = ST.myPos}
                    if #l > 6 then table.remove(l, 1) end
                end
            end
        end
        if m == "Raycast" and ST.infOn and ST.infRay and self == workspace and not Compat.checkcaller() then
            local o, d = ...
            local okr, nd = pcall(ST.infRay, o, d)
            if okr and nd then
                local args = table.pack(...)
                args[2] = nd
                if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
                return old(self, table.unpack(args, 1, args.n))
            end
        end
        if Compat.setnamecallmethod then Compat.setnamecallmethod(m) end
        return old(self, ...)
    end))
    end)
    if hookOK then
        ST.hookVer = 5
        genv.ZenithWindHook = true
    else
        warn("[Zenith] Namecall hook unavailable: " .. tostring(hookError))
    end
end

local roles, E = {}, {}
local deadF = {}
ST.zCache = ST.zCache or {}
ST.zMark = function(v)
    if type(v) ~= "string" then return false end
    v = string.lower(v)
    return string.find(v, "zomb", 1, true) ~= nil or string.find(v, "infect", 1, true) ~= nil
end
ST.isZombie = function(p)
    if p == lp then return false end
    if hostileRole(roles[p]) and roles[p] ~= "Murderer" then return true end
    local now = tick()
    local cached = ST.zCache[p]
    if cached and now - cached.t < 1 then return cached.v end
    local v = false
    pcall(function()
        if p.Team and ST.zMark(p.Team.Name) then v = true end
        if not v and (ST.zMark(p:GetAttribute("Role")) or ST.zMark(p:GetAttribute("Team"))) then v = true end
        local c = p.Character
        if not v and c then
            if ST.zMark(c:GetAttribute("Role")) or ST.zMark(c:GetAttribute("Team")) then v = true end
            if not v then
                for _, ch in ipairs(c:GetChildren()) do
                    if ST.zMark(ch.Name) then
                        v = true
                        break
                    end
                end
            end
        end
    end)
    ST.zCache[p] = {t = now, v = v}
    return v
end

local function inRound(p)
    if deadF[p] then return false end
    if next(roles) ~= nil and roles[p] == nil then return false end
    return true
end
ST.inRound = inRound
local coins, visited, danger, circles, lines, hls = {}, {}, {}, {}, {}, {}
local seenVis, born = {}, {}
local cooldown, orig = {}, {}
local sheriffGone, got = false, 0
local drop, dropPos
local busy, holding, flinging, under, home = false, false, false, false, nil
local lastPick, lastShot, lastGunFire = 0, 0, 0
local picking = false
local ping = 0.08
local FX = {}
-- a moment where you attack: the anti-aim lets your real position through so stabs / shots count
FX.attackAt = 0
FX.attacking = function() FX.attackAt = tick() end
-- on-screen buttons as a rounded pill: icon on the left, the function's name next to it
-- reset (Esc -> Reset) happens at once, no wait
task.spawn(function()
    local be = Instance.new("BindableEvent")
    be.Event:Connect(function()
        local c = game:GetService("Players").LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        pcall(function() c:BreakJoints() end)
        if h then pcall(function() h.Health = 0 end) end
    end)
    for _ = 1, 20 do
        if pcall(function() game:GetService("StarterGui"):SetCore("ResetButtonCallback", be) end) then break end
        task.wait(0.5)
    end
end)
FX.pillList = {}
FX.pillPaint = function(button)
    local P = FX.themePalette and FX.themePalette()
    if not (P and button and button.Parent) then return end
    pcall(function()
        button.BackgroundColor3 = P.bg
        button.BackgroundTransparency = 0.05
        local st = button:FindFirstChildOfClass("UIStroke")
        if st then st.Color, st.Transparency = P.line or P.accentDim, 0 end
        local tl = button:FindFirstChild("PillText")
        if tl then tl.TextColor3 = P.text end
    end)
end
FX.restylePills = function()
    for i = #FX.pillList, 1, -1 do
        local b = FX.pillList[i]
        if b.Parent then FX.pillPaint(b) else table.remove(FX.pillList, i) end
    end
end
FX.pill = function(button, label, image)
    if not button or button:GetAttribute("ZenithPill") then return end
    button:SetAttribute("ZenithPill", true)
    FX.pillList[#FX.pillList + 1] = button
    task.defer(function() FX.pillPaint(button) end)
    pcall(function()
        button.Size = UDim2.fromOffset(132, 44)
        button.BackgroundColor3 = Color3.fromRGB(22, 23, 26)
        button.BackgroundTransparency = 0.05
        if button:IsA("ImageButton") then button.Image = "" end
        if button:IsA("TextButton") then button.Text = "" end
        local cr = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", button)
        cr.CornerRadius = UDim.new(0, 16)
        local st = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", button)
        st.Color = Color3.fromRGB(46, 47, 53)
        st.Transparency = 0
        st.Thickness = 1
        local old = button:FindFirstChild("Icon")
        if old then old.Visible = false end
        local ic = Instance.new("ImageLabel")
        ic.Name = "PillIcon"
        ic.BackgroundTransparency = 1
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 8, 0.5, 0)
        ic.Size = UDim2.fromOffset(32, 32)
        if type(image) == "table" then
            ic.Image = "rbxassetid://" .. image[1]
            ic.ImageRectOffset = Vector2.new(image[2], image[3])
            ic.ImageRectSize = Vector2.new(48, 48)
        else
            ic.Image = image or ""
        end
        ic.ScaleType = Enum.ScaleType.Fit
        ic.Parent = button
        local tl = Instance.new("TextLabel")
        tl.Name = "PillText"
        tl.BackgroundTransparency = 1
        tl.Position = UDim2.new(0, 46, 0, 0)
        tl.Size = UDim2.new(1, -52, 1, 0)
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextColor3 = Color3.fromRGB(240, 240, 245)
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Text = label
        tl.Parent = button
    end)
end
FX.CHAM_FILL = {Chams = 0.2, Outline = 1, ForceField = 0.65, Neon = 0.65, Glass = 0.6, Flat = 0.7, Glow = 0.6, Ghost = 0.9, Wireframe = 1}
FX.CHAM_MAT = {ForceField = Enum.Material.ForceField, Neon = Enum.Material.Neon, Glass = Enum.Material.Glass,
    Flat = Enum.Material.SmoothPlastic, Glow = Enum.Material.Neon, Ghost = Enum.Material.ForceField}
FX.CHAM_MODES = {"Highlight", "Chams", "Outline", "Pulse", "ForceField", "Neon", "Glass", "Flat", "Glow", "Ghost", "Wireframe"}

local function myHrp()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function touch(a, b)
    if Compat.firetouchinterest then
        Compat.firetouchinterest(a, b, 0)
        Compat.firetouchinterest(a, b, 1)
    end
end

local function hasKnife()
    local c = lp.Character
    return (c and c:FindFirstChild("Knife")) or (lp.Backpack and lp.Backpack:FindFirstChild("Knife"))
end

local function aliveChar(p)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if c and h and h.Health > 0 and r then return c, r, h end
end

local function readData(tbl)
    if typeof(tbl) ~= "table" then return end
    for k, d in pairs(tbl) do
        local p = typeof(k) == "Instance" and k or Players:FindFirstChild(tostring(k))
        local role = typeof(d) == "table" and (d.Role or d.role)
        if p and role then roles[p] = role end
        if p and typeof(d) == "table" then
            deadF[p] = (d.Dead == true or d.Killed == true) or nil
        end
    end
end

local function resetRound()
    table.clear(roles)
    table.clear(deadF)
    table.clear(visited)
    table.clear(danger)
    table.clear(cooldown)
    sheriffGone, got, drop, dropPos = false, 0, nil, nil
    for _, e in pairs(E) do e.lastRole = nil end
end

for _, r in ipairs(RS:GetDescendants()) do
    pcall(function()
        if r:IsA("RemoteEvent") and r.Name == "PlayerDataChanged" then
            connect(r.OnClientEvent, function(...) readData((...)) end)
        elseif r:IsA("RemoteEvent") and r.Name == "LoadingMap" then
            connect(r.OnClientEvent, resetRound)
        elseif r:IsA("RemoteFunction") and r.Name == "GetPlayerData" then
            task.spawn(function()
                local ok, res = pcall(function() return r:InvokeServer() end)
                if ok then readData(res) end
            end)
        end
    end)
end

local function toolCheck(p, ch)
    if ch.Name == "Knife" then
        roles[p] = "Murderer"
    elseif ch.Name == "Gun" and roles[p] ~= "Sheriff" and roles[p] ~= "Murderer" then
        roles[p] = sheriffGone and "Hero" or "Sheriff"
    end
end

local function partOf(i)
    if i:IsA("BasePart") then return i end
    return i:FindFirstChildWhichIsA("BasePart", true)
end

local function vecOf(i)
    if i:IsA("BasePart") then return i.Position end
    if i:IsA("Model") then return i:GetPivot().Position end
end

local function onDropGone()
    local pos = dropPos
    drop, dropPos = nil, nil
    if not pos then return end
    local best, bd = nil, 25
    for p, e in pairs(E) do
        if p ~= lp and e.hrp and e.hrp.Parent and e.hum and e.hum.Health > 0 then
            local d = (e.hrp.Position - pos).Magnitude
            if d < bd then best, bd = p, d end
        end
    end
    local mine = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if mine and (mine.Position - pos).Magnitude < bd then return end
    if best and roles[best] ~= "Murderer" then roles[best] = "Hero" end
end

local function quickTouch(d)
    if not (CFG.autoGun and Compat.firetouchinterest) then return end
    if roles[lp] == "Murderer" then return end
    local c = lp.Character
    if not c then return end
    local targets = {}
    if d:IsA("BasePart") then targets[1] = d end
    for _, x in ipairs(d:GetDescendants()) do
        if x:IsA("BasePart") then targets[#targets + 1] = x end
    end
    for _, nm in ipairs({"HumanoidRootPart", "Head", "LeftFoot", "RightFoot", "Left Leg", "Right Leg", "UpperTorso", "Torso"}) do
        local bp = c:FindFirstChild(nm)
        if bp then
            for _, tp in ipairs(targets) do
                pcall(Compat.firetouchinterest, bp, tp, 0)
                pcall(Compat.firetouchinterest, bp, tp, 1)
            end
        end
    end
end

local function trackDrop(i)
    if i.Name ~= "GunDrop" or drop == i then return end
    drop, dropPos, sheriffGone = i, vecOf(i), true
    quickTouch(i)
    connect(i.DescendantAdded, function(x)
        if x:IsA("TouchTransmitter") and drop == i then quickTouch(i) end
    end)
    if FX.fastPick then task.spawn(FX.fastPick) end
    if CFG.gunNotify and FX.notify then task.spawn(FX.notify, "Zenith", "Gun dropped!") end
    if CFG.gun and not i:FindFirstChild("GunESP") then
        local hl = Instance.new("Highlight")
        hl.Name = "GunESP"
        hl.FillColor, hl.OutlineColor = COLORS.Hero, COLORS.Hero
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = i
    end
    connect(i.AncestryChanged, function(_, parent)
        if not parent and drop == i then onDropGone() end
    end)
end

local function coinish(n)
    n = string.lower(n)
    return string.find(n, "coin", 1, true) ~= nil or string.find(n, "cand", 1, true) ~= nil
end
FX.coinish = coinish
local function isCoin(i)
    if not i:IsA("BasePart") then return false end
    if i.Name == "Coin_Server" then return true end
    local p = i.Parent
    if p and coinish(p.Name) and string.find(string.lower(p.Name), "container", 1, true) then return true end
    return coinish(i.Name) and i:FindFirstChildOfClass("TouchTransmitter") ~= nil
end

local function addCoin(i)
    if coins[i] or not isCoin(i) then return end
    coins[i] = true
    born[i] = tick()
    connect(i.ChildRemoved, function(ch)
        if ch:IsA("TouchTransmitter") then visited[i] = true end
    end)
    if HAS_DRAW then
        local c = Compat.Drawing.new("Circle")
        c.Radius, c.Filled, c.NumSides, c.Transparency, c.Visible = 5, true, 12, 0.9, false
        c.Color = GOLD
        circles[i] = c
        local l = Compat.Drawing.new("Line")
        l.Thickness, l.Transparency, l.Visible = 1, 0.8, false
        l.Color = GOLD
        lines[i] = l
    end
    local hl = Instance.new("Highlight")
    hl.Name = "CoinESP"
    hl.FillColor = GOLD
    hl.OutlineColor = Color3.fromRGB(255, 240, 150)
    hl.FillTransparency = 0.4
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = CFG.coinHighlight
    hl.Parent = i
    hls[i] = hl
end

local function removeCoin(i)
    if not coins[i] then return end
    coins[i], visited[i], danger[i], seenVis[i], born[i] = nil, nil, nil, nil, nil
    if circles[i] then
        pcall(function() circles[i]:Remove() end)
        circles[i] = nil
    end
    if lines[i] then
        pcall(function() lines[i]:Remove() end)
        lines[i] = nil
    end
    if hls[i] then
        pcall(function() hls[i]:Destroy() end)
        hls[i] = nil
    end
end

local function onAdded(i)
    addCoin(i)
    trackDrop(i)
    if i:IsA("TouchTransmitter") and i.Parent then addCoin(i.Parent) end
end
for _, root in ipairs({workspace, RunService}) do
    connect(root.DescendantAdded, onAdded)
    connect(root.DescendantRemoving, removeCoin)
    task.spawn(function()
        local n = 0
        for _, d in ipairs(root:GetDescendants()) do
            onAdded(d)
            n += 1
            if n % 2000 == 0 then task.wait() end
        end
    end)
end

task.spawn(function()
    while running do
        pcall(function()
            ST.ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        end)
        task.wait(0.5)
    end
end)

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude

do
local function create(p)
    if E[p] then return end
    local e = {tries = 0, built = 0, lv = {}, bones = {}}
    if HAS_DRAW then
        e.box = draw("Square"); e.box.Thickness, e.box.Filled, e.box.Visible = 1.5, false, false
        e.hpBack = draw("Square"); e.hpBack.Filled, e.hpBack.Color, e.hpBack.Visible = true, BLACK, false
        e.hp = draw("Square"); e.hp.Filled, e.hp.Visible = true, false
        e.tracer = draw("Line"); e.tracer.Thickness, e.tracer.Visible = 1, false
        local tris = {}
        for _ = 1, 6 do
            local okT, tri = pcall(draw, "Triangle")
            if okT and tri then
                pcall(function()
                    tri.Filled = true
                    tri.Thickness = 1
                    tri.Visible = false
                end)
                tris[#tris + 1] = tri
            end
        end
        e.arrowTris = tris
        e.arrow = setmetatable({}, {
            __index = function(_, k)
                if k == "Remove" then
                    return function()
                        for _, t in ipairs(tris) do pcall(function() t:Remove() end) end
                    end
                end
                if k == "Visible" then return tris[1] ~= nil and tris[1].Visible end
                return nil
            end,
            __newindex = function(_, k, v)
                if k == "Visible" then
                    for _, t in ipairs(tris) do t.Visible = v end
                end
            end,
        })
        e.name, e.dist = newText(), newText()
        e.lines = {}
        for i = 1, 14 do
            local l = draw("Line")
            l.Thickness, l.Visible = 2, false
            e.lines[i] = l
        end
        e.box3 = {}
        for i = 1, 12 do
            local l = draw("Line")
            l.Thickness, l.Visible = 2, false
            e.box3[i] = l
        end
    end
    E[p] = e
end

local function destroy(p)
    local e = E[p]
    if e then
        if e.cc then pcall(function() e.cc:Disconnect() end) end
        if e.hl then pcall(function() e.hl:Destroy() end) end
        if HAS_DRAW then
            for _, k in ipairs(PARTS) do pcall(function() e[k]:Remove() end) end
            for _, l in ipairs(e.lines) do pcall(function() l:Remove() end) end
            for _, l in ipairs(e.box3 or {}) do pcall(function() l:Remove() end) end
            for _, l in ipairs(e.gl or {}) do pcall(function() l:Remove() end) end
            for _, l in ipairs(e.tg or {}) do pcall(function() l:Remove() end) end
        end
        if e.av then pcall(function() e.av:Destroy() end) end
    end
    E[p], roles[p] = nil, nil
end

for _, p in ipairs(Players:GetPlayers()) do create(p) end
connect(Players.PlayerAdded, create)
connect(Players.PlayerRemoving, destroy)

local function build(p, e, c, now)
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return false end
    if e.cc then e.cc:Disconnect() end
    if e.hl then e.hl:Destroy(); e.hl = nil end
    e.char, e.hrp, e.hum, e.lastRole, e.built = c, hrp, hum, nil, now
    local set = c:FindFirstChild("UpperTorso") and R15 or R6
    e.bones = {}
    for _, b in ipairs(set) do
        local a, d = c:FindFirstChild(b[1]), c:FindFirstChild(b[2])
        if a and d then e.bones[#e.bones + 1] = {a, d} end
    end
    e.retry = #e.bones < #set
    e.tries = e.retry and e.tries + 1 or 0
    for _, ch in ipairs(c:GetChildren()) do toolCheck(p, ch) end
    e.cc = c.ChildAdded:Connect(function(ch) toolCheck(p, ch) end)
    return true
end

local BOX_EDGES = {{1, 2}, {2, 3}, {3, 4}, {4, 1}, {5, 6}, {6, 7}, {7, 8}, {8, 5}, {1, 5}, {2, 6}, {3, 7}, {4, 8}}
local BOX_XZ = {{-2, -1}, {2, -1}, {2, 1}, {-2, 1}}

local function hideAll(e)
    if e.av then e.av.Enabled = false end
    if not HAS_DRAW or not e.shown then return end
    e.shown = false
    for _, k in ipairs(PARTS) do e[k].Visible = false end
    for i, l in ipairs(e.lines) do l.Visible = false; e.lv[i] = false end
    for _, l in ipairs(e.box3 or {}) do l.Visible = false end
    for _, l in ipairs(e.gl or {}) do l.Visible = false end
    for _, l in ipairs(e.tg or {}) do l.Visible = false end
end

local GRAD_N = 8
local function gradOf(prefix, now)
    if not CFG[prefix] then return nil, nil end
    local a, b = colorOf(CFG[prefix .. "A"]), colorOf(CFG[prefix .. "B"])
    if CFG[prefix .. "Anim"] then
        local k = (math.sin((now or tick()) * 2) + 1) / 2
        a, b = a:Lerp(b, k), b:Lerp(a, k)
    end
    return a, b
end
FX.gradOf = gradOf

local function boxLines(e, x, y, w, h, cA, cB, style, on)
    if not e.gl then
        if not on then return end
        e.gl = {}
        for i = 1, GRAD_N * 2 + 2 do
            local l = draw("Line")
            l.Thickness = 2
            l.Visible = false
            e.gl[i] = l
        end
    end
    local used = 0
    if on then
        if style == "Corners" then
            local lw, lh = w * 0.28, h * 0.22
            local segs = {
                {x, y, x + lw, y, cA},
                {x, y, x, y + lh, cA:Lerp(cB, 0.11)},
                {x + w, y, x + w - lw, y, cA},
                {x + w, y, x + w, y + lh, cA:Lerp(cB, 0.11)},
                {x, y + h, x + lw, y + h, cB},
                {x, y + h, x, y + h - lh, cA:Lerp(cB, 0.89)},
                {x + w, y + h, x + w - lw, y + h, cB},
                {x + w, y + h, x + w, y + h - lh, cA:Lerp(cB, 0.89)},
            }
            for i, sg in ipairs(segs) do
                local l = e.gl[i]
                l.From, l.To, l.Color = Vector2.new(sg[1], sg[2]), Vector2.new(sg[3], sg[4]), sg[5]
                if not l.Visible then l.Visible = true end
            end
            used = #segs
        else
            local k = 1
            for side = 0, 1 do
                local xx = x + side * w
                for i = 0, GRAD_N - 1 do
                    local l = e.gl[k]
                    k += 1
                    local f0, f1 = i / GRAD_N, (i + 1) / GRAD_N
                    l.From, l.To = Vector2.new(xx, y + h * f0), Vector2.new(xx, y + h * f1)
                    l.Color = cA:Lerp(cB, (f0 + f1) / 2)
                    if not l.Visible then l.Visible = true end
                end
            end
            local tl, bl = e.gl[k], e.gl[k + 1]
            tl.From, tl.To, tl.Color = Vector2.new(x, y), Vector2.new(x + w, y), cA
            bl.From, bl.To, bl.Color = Vector2.new(x, y + h), Vector2.new(x + w, y + h), cB
            tl.Visible, bl.Visible = true, true
            used = k + 1
        end
    end
    for i = used + 1, #e.gl do
        if e.gl[i].Visible then e.gl[i].Visible = false end
    end
end

local function gradTracer(e, a, b, cA, cB, on)
    if not e.tg then
        if not on then return end
        e.tg = {}
        for i = 1, 6 do
            local l = draw("Line")
            l.Thickness = 1
            l.Visible = false
            e.tg[i] = l
        end
    end
    for i, l in ipairs(e.tg) do
        if on then
            local f0, f1 = (i - 1) / 6, i / 6
            l.From, l.To = a:Lerp(b, f0), a:Lerp(b, f1)
            l.Color = cA:Lerp(cB, (f0 + f1) / 2)
            if not l.Visible then l.Visible = true end
        elseif l.Visible then
            l.Visible = false
        end
    end
end

local function drawBox3(e, hrp, color)
    local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
    local cf = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
    local pts = {}
    local n = 0
    for _, y in ipairs({-3, 2.6}) do
        for _, xz in ipairs(BOX_XZ) do
            n += 1
            local w = cam:WorldToViewportPoint((cf * CFrame.new(xz[1], y, xz[2])).Position)
            if w.Z <= 0 then
                for _, l in ipairs(e.box3) do l.Visible = false end
                return
            end
            pts[n] = Vector2.new(w.X, w.Y)
        end
    end
    for k, ed in ipairs(BOX_EDGES) do
        local l = e.box3[k]
        l.From, l.To, l.Color = pts[ed[1]], pts[ed[2]], color
        l.Visible = true
    end
end

local function avatarTag(p, e, c, color)
    if not CFG.avatar then
        if e.av then e.av.Enabled = false end
        return
    end
    local head = c:FindFirstChild("Head")
    if not head then return end
    if not e.av or not e.av.Parent or e.av.Adornee ~= head then
        if e.av then pcall(function() e.av:Destroy() end) end
        local bb = Instance.new("BillboardGui")
        bb.Name = "ZenithAvatar"
        bb.Size = UDim2.fromOffset(36, 36)
        bb.StudsOffset = Vector3.new(0, 1.6, 0)
        bb.SizeOffset = Vector2.new(0, 1.3)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Adornee = head
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=48&h=48"
        img.Parent = bb
        Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
        local st = Instance.new("UIStroke")
        st.Thickness = 2
        st.Parent = img
        local okp = pcall(function() bb.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not okp or not bb.Parent then bb.Parent = head end
        e.av, e.avStroke = bb, st
    end
    e.av.Enabled = true
    e.avStroke.Color = color
end

local PC = {}
local function proj(part)
    local v = PC[part]
    if v == nil then
        local pt, on = cam:WorldToViewportPoint(part.Position)
        v = on and Vector2.new(pt.X, pt.Y) or false
        PC[part] = v
    end
    return v
end

local foundTarget

local ARROW_GLOW = {{7, 0.06}, {4.5, 0.1}, {2, 0.16}}
local ARROW_BODY = {{1, 0.3}, {0.7, 0.3}, {0.42, 0.38}}

local function drawArrow(e, pos, color, vp, color2)
    local tris = e.arrowTris
    if not tris or #tris < 6 then return end
    local cf = cam.CFrame
    local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    if look.Magnitude < 0.01 then
        e.arrow.Visible = false
        return
    end
    local rel = CFrame.lookAt(cf.Position, cf.Position + look):PointToObjectSpace(pos)
    local dir = Vector2.new(rel.X, rel.Z)
    if dir.Magnitude < 0.01 then
        e.arrow.Visible = false
        return
    end
    dir = dir.Unit
    local perp = Vector2.new(-dir.Y, dir.X)
    local base = Vector2.new(vp.X / 2, vp.Y / 2) + dir * CFG.arrowRadius
    local tip = base + dir * 24
    local left, right = base + perp * 13, base - perp * 13
    local k = 0
    for _, g in ipairs(ARROW_GLOW) do
        k += 1
        local t = tris[k]
        local grow = g[1]
        t.PointA = tip + dir * grow
        t.PointB = left + perp * grow - dir * grow * 0.5
        t.PointC = right - perp * grow - dir * grow * 0.5
        t.Color = color2 or color
        t.Transparency = g[2]
        t.Visible = true
    end
    for _, b in ipairs(ARROW_BODY) do
        k += 1
        local t = tris[k]
        local f = b[1]
        t.PointA = tip
        t.PointB = tip + (left - tip) * f
        t.PointC = tip + (right - tip) * f
        t.Color = color
        t.Transparency = b[2]
        t.Visible = true
    end
end

local function step(p, e, camPos, vp, now)
    local c = p.Character
    if c and e.char ~= c then
        if not build(p, e, c, now) then hideAll(e); return end
    elseif c and e.retry and e.tries < 5 and now - e.built > 1 then
        build(p, e, c, now)
    end

    local hum, hrp = e.hum, e.hrp
    local alive = c and e.char == c and hrp and hrp.Parent and hum and hum.Health > 0
    if not alive then
        hideAll(e)
        if e.hl then e.hl:Destroy(); e.hl = nil end
        return
    end

    local pos = hrp.Position
    local role = roles[p] or "Innocent"
    if role ~= "Murderer" and ST.isZombie(p) then role = "Zombie" end
    if hostileRole(role) and p ~= lp then
        local myp = ST.myPos
        local d0 = myp and (myp - hrp.Position).Magnitude or 0
        local vis = true
        if myp then
            ST.visRP = ST.visRP or RaycastParams.new()
            ST.visRP.FilterType = Enum.RaycastFilterType.Exclude
            ST.visRP.FilterDescendantsInstances = {lp.Character, c}
            vis = workspace:Raycast(myp + Vector3.new(0, 1.5, 0), hrp.Position - myp - Vector3.new(0, 1.5, 0), ST.visRP) == nil
        end
        -- a visible enemy always beats a hidden one; among equals the closer one wins
        local score = d0 + (vis and 0 or 10000)
        if not foundTarget or score < (ST.foundDist or math.huge) then
            foundTarget, ST.foundDist = hrp, score
        end
    end

    local dist = (camPos - pos).Magnitude
    if not CFG.esp or (role == "Innocent" and not CFG.showInnocent and p ~= lp) or dist > CFG.maxDist then
        hideAll(e)
        if e.hl then e.hl.Enabled = false end
        return
    end
    local color = COLORS[role] or (hostileRole(role) and COLORS.Zombie) or COLORS.Innocent

    local hstyle = CFG.chamsStyle
    local ccol = (CFG.chamsColor == "Role") and color or colorOf(CFG.chamsColor)
    local chA, chB = gradOf("gCham", now)
    if chA then ccol = chA end
    e.matColor = ccol
    if CFG.highlight then
        if not e.hl or e.hl.Parent ~= c then
            local hl = Instance.new("Highlight")
            hl.Name = "ESP"
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = c
            e.hl = hl
        end
        e.hl.FillColor, e.hl.OutlineColor = ccol, chB or ccol
        local fillT = FX.CHAM_FILL[hstyle] or 0.55
        if hstyle == "Pulse" then fillT = 0.1 + 0.65 * (math.sin(now * 4) + 1) / 2 end
        e.hl.FillTransparency = fillT
        e.hl.OutlineTransparency = 0
        e.hl.Enabled = true
    elseif e.hl then
        e.hl.Enabled = false
    end

    pcall(avatarTag, p, e, c, color)
    if not HAS_DRAW then return end
    local top, v1 = cam:WorldToViewportPoint(pos + UP)
    local bot, v2 = cam:WorldToViewportPoint(pos - DOWN)
    if not (v1 and v2) then
        hideAll(e)
        if CFG.arrows then
            e.shown = true
            local arA, arB = gradOf("gArrow", now)
            drawArrow(e, pos, arA or color, vp, arB)
        end
        return
    end

    e.shown = true
    if e.arrow then e.arrow.Visible = false end
    local h = math.abs(bot.Y - top.Y)
    local w = h / 2
    local cx = (top.X + bot.X) / 2

    local bA, bB = gradOf("gBox", now)
    local box3d = CFG.box and CFG.boxStyle == "3D"
    if box3d then
        e.box.Visible = false
        boxLines(e, 0, 0, 0, 0, color, color, nil, false)
        pcall(drawBox3, e, hrp, bA or color)
    elseif CFG.box and (bA or CFG.boxStyle == "Corners") then
        e.box.Visible = false
        boxLines(e, cx - w / 2, top.Y, w, h, bA or color, bB or color, CFG.boxStyle, true)
    else
        boxLines(e, 0, 0, 0, 0, color, color, nil, false)
        e.box.Visible = CFG.box
        e.box.Color = color
        e.box.Thickness = 2
        e.box.Size = Vector2.new(w, h)
        e.box.Position = Vector2.new(cx - w / 2, top.Y)
    end
    if not box3d then for _, l in ipairs(e.box3) do if l.Visible then l.Visible = false end end end

    local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    e.hpBack.Visible, e.hp.Visible = CFG.health, CFG.health
    if CFG.health then
        e.hpBack.Size = Vector2.new(4, h)
        e.hpBack.Position = Vector2.new(cx - w / 2 - 7, top.Y)
        e.hp.Size = Vector2.new(2, math.max(h * frac - 2, 0))
        e.hp.Position = Vector2.new(cx - w / 2 - 6, top.Y + h - h * frac + 1)
        e.hp.Color = BLACK:Lerp(color, 0.35 + 0.65 * frac)
    end

    local tA, tB = gradOf("gTrac", now)
    gradTracer(e, Vector2.new(vp.X / 2, vp.Y), Vector2.new(cx, bot.Y), tA or color, tB or color, CFG.tracer and tA ~= nil)
    e.tracer.Visible = CFG.tracer and tA == nil
    if CFG.tracer then
        e.tracer.Color = color
        e.tracer.From = Vector2.new(vp.X / 2, vp.Y)
        e.tracer.To = Vector2.new(cx, bot.Y)
    end

    e.name.Visible = CFG.name
    if CFG.name then
        local nA = gradOf("gName", now)
        e.name.Color = nA or color
        e.name.Position = Vector2.new(cx, top.Y - 20)
        local s = p.DisplayName
        local TAGS = {Murderer = "murder", Sheriff = "sheriff", Hero = "sheriff", Zombie = "zombie"}
        if TAGS[role] then s = s .. "  [" .. TAGS[role] .. "]" end
        if CFG.espCandy then
            local cv = ST.candyOf(p)
            if cv then s = s .. "  [" .. tostring(cv) .. "]" end
        end
        if e.nt ~= s then e.nt = s; e.name.Text = s end
    end

    e.dist.Visible = CFG.dist
    if CFG.dist then
        e.dist.Position = Vector2.new(cx, bot.Y + 2)

        local m = math.floor(dist)
        if e.dm ~= m then e.dm = m; e.dist.Text = m .. " studs" end
    end

    table.clear(PC)
    local showSkel = CFG.skeleton and dist < CFG.skelDist
    local sA, sB = gradOf("gSkel", now)
    local nLines = #e.lines
    for i, l in ipairs(e.lines) do
        local b = showSkel and e.bones[i]
        local on = false
        if b then
            local a, d = proj(b[1]), proj(b[2])
            if a and d then
                l.Color, l.From, l.To = sA and sA:Lerp(sB, (i - 1) / math.max(nLines - 1, 1)) or color, a, d
                on = true
            end
        end
        if on ~= e.lv[i] then l.Visible = on; e.lv[i] = on end
    end
end

local gunTxt = HAS_DRAW and newText() or nil

local PERF = {fps = 60, frame = 0}
connect(RunService.RenderStepped, function(dt)
    PERF.fps = PERF.fps * 0.92 + (1 / math.max(dt, 1 / 240)) * 0.08
end)
FX.perf = PERF

connect(PRE_RENDER, function()
    cam = workspace.CurrentCamera
    if not cam then return end
    PERF.frame += 1
    if CFG.optimize and PERF.fps < 45 and PERF.frame % 2 == 1 then return end
    local camPos, vp, now = cam.CFrame.Position, cam.ViewportSize, tick()
    local mh = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    ST.myPos = mh and mh.Position

    foundTarget, ST.foundDist = nil, nil
    local selfScope = FX.espScope == "local"
    for p, e in pairs(E) do
        if (p == lp) == selfScope then
            pcall(step, p, e, camPos, vp, now)
        else
            pcall(hideAll, e)
            if e.hl then e.hl.Enabled = false end
        end
    end

    for _, e in pairs(E) do
        local h = e.hrp
        if h and h.Parent then
            local pos = h.Position
            local rec = ST.hist[h]
            if rec then
                local dt = now - rec.t
                if dt > 0.0005 then
                    local nv = (pos - rec.p) / dt
                    if nv.Magnitude > 150 then nv = Vector3.zero end
                    rec.v = rec.v:Lerp(nv, math.min(1, dt * 14))
                    rec.p, rec.t = pos, now
                end
            else
                ST.hist[h] = {p = pos, t = now, v = Vector3.zero}
            end
        end
    end

    ST.on = CFG.silent
    ST.target = foundTarget
    ST.aimPos = foundTarget and foundTarget.Position or nil

    if drop and drop.Parent then dropPos = vecOf(drop) or dropPos end
    if gunTxt then
        if CFG.esp and CFG.gun and drop and drop.Parent and dropPos then
            gunTxt.Visible = false
        else
            gunTxt.Visible = false
        end
    end

    local hlOn = CFG.coinEsp and CFG.coinHighlight
    for c, hl in pairs(hls) do
        hl.Enabled = hlOn and not visited[c]
    end
    if HAS_DRAW then
        local origin = Vector2.new(vp.X / 2, vp.Y)
        for c, circle in pairs(circles) do
            local line = lines[c]
            if CFG.coinEsp and c.Parent and not visited[c] then
                local pt, vis = cam:WorldToViewportPoint(c.Position)
                circle.Visible = vis
                if vis then circle.Position = Vector2.new(pt.X, pt.Y) end
                if line then
                    local near = (c.Position - camPos).Magnitude <= CFG.coinTracerDist
                    line.Visible = vis and CFG.coinTracer and near
                    if line.Visible then
                        line.From = origin
                        line.To = Vector2.new(pt.X, pt.Y)
                    end
                end
            else
                circle.Visible = false
                if line then line.Visible = false end
            end
        end
    end
end)
end

local Lighting = game:GetService("Lighting")

connect(PRE_SIM, function()
    if not holding then return end
    local c = lp.Character
    if not c then return end
    for _, p in ipairs(c:GetChildren()) do
        if p:IsA("BasePart") then
            if orig[p] == nil then orig[p] = p.CanCollide end
            p.CanCollide = false
        end
    end
end)

local function hold(on)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if on then
        holding = true
        if hrp and not hrp:FindFirstChild("ZenithHold") then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "ZenithHold"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
        end
        if hum then hum.PlatformStand = true end
    else
        holding = false
        if hrp then
            local bv = hrp:FindFirstChild("ZenithHold")
            if bv then bv:Destroy() end
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        if hum then hum.PlatformStand = false end
        for part, v in pairs(orig) do
            if part.Parent then part.CanCollide = v end
        end
        table.clear(orig)
    end
end

local function goTo(cf, speed, keep)
    if CFG.farm then ST.farmActiveAt = tick() end
    local hrp, hum = myHrp()
    if not hrp or not hum or hum.Health <= 0 then return false end
    if not holding then hold(true) end
    hrp.CFrame = CFrame.new(hrp.Position) * cf.Rotation
    local t = math.max((hrp.Position - cf.Position).Magnitude / speed, 0.03)
    local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cf})
    local done = false
    local cc = tw.Completed:Connect(function() done = true end)
    tw:Play()
    local s = tick()
    while not done and tick() - s < t + 1 and running do
        if hum.Health <= 0 or (keep and not keep()) then break end
        task.wait()
    end
    tw:Cancel()
    cc:Disconnect()
    return done
end

local function surface()
    local hrp, hum = myHrp()
    if hrp and hum and hum.Health > 0 then
        local safe = ST.farmSafe
        if safe and (hrp.Position - safe).Magnitude > 1.5 and (hrp.Position - safe).Magnitude < 400 then
            goTo(CFrame.new(safe), math.max(CFG.farmSpeed, 8), nil)
        end
    end
    hold(false)
    under = false
end

local function murdererHrp()
    local me = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local best, bd
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r and (hostileRole(roles[p]) or ST.isZombie(p) or c:FindFirstChild("Knife")) then
                if not me then return r end
                local d = (r.Position - me.Position).Magnitude
                if not bd or d < bd then best, bd = r, d end
            end
        end
    end
    return best
end

local function seen()
    return lp.Character
end

connect(lp.CharacterAdded, function(c)
    holding, under, home = false, false, nil
    table.clear(orig)
end)

local function pickReady()
    if not CFG.autoGun then return false end
    if not (drop and drop.Parent) then return false end
    if roles[lp] == "Murderer" or hasKnife() then return false end
    return tick() - lastPick >= 0.05
end

local PICK_PARTS = {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "Torso", "LeftFoot", "RightFoot", "Left Leg", "Right Leg"}
local function hasGun()
    local c = lp.Character
    local bp = lp:FindFirstChildOfClass("Backpack")
    for _, place in ipairs({c, bp}) do
        if place then
            for _, t in ipairs(place:GetChildren()) do
                if t:IsA("Tool") and (t.Name == "Gun" or t:FindFirstChild("Shoot")) then return t end
            end
        end
    end
    return nil
end

local function gunTouchParts(d)
    local out = {}
    if d:IsA("BasePart") and d:FindFirstChildOfClass("TouchTransmitter") then out[1] = d end
    for _, x in ipairs(d:GetDescendants()) do
        if x:IsA("TouchTransmitter") and x.Parent and x.Parent:IsA("BasePart") then out[#out + 1] = x.Parent end
    end
    if #out == 0 then
        local p = partOf(d)
        if p then out[1] = p end
    end
    return out
end

local function pickGun()
    if picking or not pickReady() or hasGun() then return end
    local d = drop
    if not d then return end
    local c = lp.Character
    local hrp, hum = myHrp()
    if not c or not hrp or not hum or hum.Health <= 0 then return end
    picking = true
    lastPick = tick()
    pcall(function()
        local s0 = tick()
        repeat
            local targets = gunTouchParts(d)
            for _, nm in ipairs(PICK_PARTS) do
                local bp = c:FindFirstChild(nm)
                if bp then
                    for _, tp in ipairs(targets) do
                        if tp.Parent then touch(bp, tp) end
                    end
                end
            end
            if hasGun() or not d.Parent then break end
            RunService.Heartbeat:Wait()
        until tick() - s0 > 1 or hum.Health <= 0
    end)
    picking = false
end

FX.fastPick = function()
    pcall(pickGun)
end

local function rawAlive(c)
    if not c.Parent then return false end
    if seenVis[c] then
        local vis = c:FindFirstChild("CoinVisual")
        if not vis then return false end
        if vis:IsA("BasePart") and vis.Transparency < 0.99 then return true end
        for _, d in ipairs(vis:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency < 0.99 then return true end
        end
        return false
    end
    return c:FindFirstChildOfClass("TouchTransmitter") ~= nil
end

task.spawn(function()
    while running do
        local now = tick()
        for c in pairs(coins) do
            if not visited[c] then
                if seenVis[c] == nil and c:FindFirstChild("CoinVisual") then seenVis[c] = true end
                if now - (born[c] or now) > 1.5 and not rawAlive(c) then visited[c] = true end
            end
        end
        task.wait(0.25)
    end
end)

local function nearestCoin(hrp)
    local best, bd = nil, CFG.coinRange
    local now = tick()
    for c in pairs(coins) do
        if c.Parent and not visited[c] and not (danger[c] and danger[c] > now) then
            local d = (c.Position - hrp.Position).Magnitude
            if d < bd then best, bd = c, d end
        end
    end
    return best
end

local farmCont
ST.sheriffRoot = function()
    local me = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local gun = c and (c:FindFirstChild("Gun") or (function()
                for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Shoot") then return t end end
            end)())
            if h and r and h.Health > 0 and (roles[p] == "Sheriff" or roles[p] == "Hero" or gun) then return r end
        end
    end
end
ST.candyCache = {}
ST.candyOf = function(p)
    if p == lp and FX.candyBalance then
        local own = FX.candyBalance()
        if own then return own end
    end
    local cc = ST.candyCache[p]
    if cc and tick() - cc.t < 2 then return cc.v end
    local v
    pcall(function()
        local function word(n)
            n = string.lower(n)
            return string.find(n, "cand", 1, true) or string.find(n, "coin", 1, true)
        end
        local ls = p:FindFirstChild("leaderstats")
        if ls then
            for _, x in ipairs(ls:GetChildren()) do
                if x:IsA("ValueBase") and word(x.Name) then v = x.Value break end
            end
        end
        if v == nil then
            for k, x in pairs(p:GetAttributes()) do
                if word(k) and type(x) == "number" then v = x break end
            end
        end
        if v == nil and p.Character then
            for k, x in pairs(p.Character:GetAttributes()) do
                if word(k) and type(x) == "number" then v = x break end
            end
        end
    end)
    ST.candyCache[p] = {t = tick(), v = v}
    return v
end

local function farmStep()
    local hrp, hum = myHrp()
    if busy or picking or not hrp or not hum or hum.Health <= 0 then return false end
    if ST.bagFull then return true end
    if not holding then ST.farmSafe = hrp.Position end
    local threats = ST.threats and ST.threats() or {}
    local function nearT(pos)
        local d0 = math.huge
        for _, t in ipairs(threats) do
            local d = (t.Position - pos).Magnitude
            if d < d0 then d0 = d end
        end
        return d0
    end
    local close = nearT(hrp.Position) < CFG.dangerDist
    local best, bd = nil, close and -math.huge or CFG.coinRange
    local now = tick()
    for c in pairs(coins) do
        if c.Parent and not visited[c] and not (danger[c] and danger[c] > now) then
            local dm = nearT(c.Position)
            if dm >= CFG.dangerDist then
                if close then
                    -- escaping: the candy furthest from the murderer
                    if dm > bd and (c.Position - hrp.Position).Magnitude < CFG.coinRange then best, bd = c, dm end
                else
                    local d = (c.Position - hrp.Position).Magnitude
                    if d < bd then best, bd = c, d end
                end
            end
        end
    end
    local coin = best
    if not coin then
        if not holding then return true end
        -- nothing safe to fly to right now: wait in the air in open space instead of dropping inside a wall
        local safe = ST.farmSafe
        if safe and (hrp.Position - safe).Magnitude > 1.5 then
            busy = true
            pcall(goTo, CFrame.new(safe), math.max(CFG.farmSpeed, 8), function() return CFG.farm end)
            busy = false
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        return next(coins) == nil
    end
    if coin.Parent ~= farmCont then
        farmCont = coin.Parent
        got = 0
    end
    busy = true
    pcall(function()
        local function keep()
            if not CFG.farm or not coin.Parent or visited[coin] then return false end
            for _, t in ipairs(ST.threats and ST.threats() or {}) do
                if (t.Position - coin.Position).Magnitude < CFG.dangerDist * 0.8 then
                    danger[coin] = tick() + 8
                    return false
                end
            end
            return true
        end
        local ok
        local speed = math.max(CFG.farmSpeed, 8)
        if CFG.farmMethod == "Fast" then speed = math.min(speed * 1.6, 45) end
        local method = CFG.farmMethod
        local FLIP = CFrame.Angles(-math.pi / 2, 0, 0)
        local spot = CFrame.new(coin.Position - Vector3.new(0, 2.8, 0)) * FLIP
        if method == "Fake lag" then
            if holding then hold(false) end
        end
        if method == "Teleport" then
            local to = coin.Position - hrp.Position
            local dist = to.Magnitude
            local blink = math.clamp(dist * 0.25, 2, 4.5)
            ok = true
            if dist > blink + 1 then
                ok = goTo(CFrame.new(hrp.Position + to.Unit * (dist - blink) - Vector3.new(0, 2.8, 0)) * FLIP, speed, keep)
            end
            if ok and keep() then
                if not holding then hold(true) end
                hrp.CFrame = spot
                hrp.AssemblyLinearVelocity = Vector3.zero
                ok = true
            else
                ok = false
            end
        elseif method == "Up" or method == "Down" then
            local y = (method == "Up") and (math.max(hrp.Position.Y, coin.Position.Y) + 25) or (math.min(hrp.Position.Y, coin.Position.Y) - 18)
            ok = goTo(CFrame.new(hrp.Position.X, y, hrp.Position.Z) * FLIP, speed, keep)
                and goTo(CFrame.new(coin.Position.X, y, coin.Position.Z) * FLIP, speed, keep)
                and goTo(spot, speed, keep)
        elseif method == "Fake lag" then
            ok = false
            while keep() do
                local to = coin.Position - hrp.Position
                if to.Magnitude < 1.5 then
                    ok = true
                    break
                end
                local step = math.min(to.Magnitude, speed * (0.2 + math.random() * 0.15) * 1.6)
                hrp.CFrame = CFrame.new(hrp.Position + to.Unit * step) * hrp.CFrame.Rotation
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.2 + math.random() * 0.15)
            end
        else
            ok = goTo(spot, speed, keep)
        end
        if not ok and coin.Parent and not visited[coin] then
            ST.coinFails = ST.coinFails or {}
            ST.coinFails[coin] = (ST.coinFails[coin] or 0) + 1
            if ST.coinFails[coin] >= 3 then
                danger[coin] = tick() + 10
                ST.coinFails[coin] = 0
            end
        end
        if ok then
            if FX.bagBefore then pcall(FX.bagBefore) end
            local t0 = tick()
            repeat
                hrp.AssemblyLinearVelocity = Vector3.zero
                touch(hrp, coin)
                RunService.Heartbeat:Wait()
            until visited[coin] or not coin.Parent or hum.Health <= 0 or tick() - t0 > ((CFG.farmMethod == "Fast") and 0.12 or 0.25)
            if visited[coin] then
                got += 1
                ST.farmCollected = (ST.farmCollected or 0) + 1
                ST.farmActiveAt = tick()
                if FX.bagAfter then pcall(FX.bagAfter) end
            end
            visited[coin] = true
            ST.farmSafe = hrp.Position
        end
    end)
    busy = false
    return false
end

local function charOf(i)
    if i:IsA("Model") and i:FindFirstChildOfClass("Humanoid") then return i end
    local m = i:FindFirstAncestorOfClass("Model")
    if m and m:FindFirstChildOfClass("Humanoid") then return m end
end

local function pickRec(list)
    if not list or #list == 0 then return end
    for i = #list, 1, -1 do
        local e = list[i]
        for k = 1, e.a.n do
            local v = e.a[k]
            if typeof(v) == "Instance" then
                local ch = charOf(v)
                if (ch and ch ~= lp.Character) or (v:IsA("Player") and v ~= lp) then return e end
            end
        end
    end
    return list[#list]
end

local function sub(a, tp, tc, th, tr, rpos, cp)
    local t = typeof(a)
    if t == "Instance" then
        if a:IsA("Player") then
            return a == lp and a or tp
        end
        local ch = charOf(a)
        if ch and ch ~= lp.Character then
            if a == ch then return tc end
            if a:IsA("Humanoid") then return th end
            return tc:FindFirstChild(a.Name) or tr
        end
        if not ch and a:IsA("BasePart") then return tr end
        return a
    elseif t == "Vector3" then
        if rpos and (a - rpos).Magnitude < 8 then return cp end
        return tr.Position
    elseif t == "CFrame" then
        if rpos and (a.Position - rpos).Magnitude < 8 then return CFrame.lookAt(cp, tr.Position) end
        return CFrame.new(tr.Position)
    end
    return a
end

local function replay(r, rec, p, tc, th, tr, cp)
    local a, args = rec.a, {}
    for i = 1, a.n do args[i] = sub(a[i], p, tc, th, tr, rec.p, cp) end
    if r:IsA("RemoteEvent") then
        r:FireServer(table.unpack(args, 1, a.n))
    else
        r:InvokeServer(table.unpack(args, 1, a.n))
    end
end

ST.calibKnife = function(origin)
    local found
    local conn = workspace.DescendantAdded:Connect(function(d)
        if found or not d:IsA("BasePart") then return end
        if lp.Character and d:IsDescendantOf(lp.Character) then return end
        local nm = (d.Name .. " " .. (d.Parent and d.Parent.Name or "")):lower()
        if (nm:find("knife", 1, true) or nm:find("throw", 1, true) or nm:find("handle", 1, true))
           and (d.Position - origin).Magnitude < 12 then
            found = d
        end
    end)
    local t0 = tick()
    while not found and tick() - t0 < 1.2 do task.wait() end
    conn:Disconnect()
    if not found then return end
    task.wait()
    local p1, t1 = found.Position, tick()
    task.wait(0.2)
    if not found.Parent then return end
    local sp = (found.Position - p1).Magnitude / math.max(tick() - t1, 1e-3)
    if sp > 15 and sp < 800 then
        local old = CFG.knifeSpeed
        CFG.knifeSpeed = math.floor(old * 0.4 + sp * 0.6 + 0.5)
    end
end

ST.onThrow = function(tHrp, travel, from)
    local c = tHrp and tHrp.Parent
    local p = c and Players:GetPlayerFromCharacter(c)
    if not p then return end
    task.wait(math.clamp((travel or 0.2) + 0.05, 0.05, 1.5))
    local c2, r2 = aliveChar(p)
    if not c2 then return end
    if from and not CFG.knifeWB then
        local ig = {c2}
        if lp.Character then ig[2] = lp.Character end
        stRP.FilterDescendantsInstances = ig
        if workspace:Raycast(from, r2.Position - from, stRP) then return end
    end
    local knife = (lp.Character and lp.Character:FindFirstChild("Knife")) or lp.Backpack:FindFirstChild("Knife")
    local ev = knife and knife:FindFirstChild("Events")
    local ht = ev and ev:FindFirstChild("HandleTouched")
    if not ht then return end
    pcall(function() ht:FireServer(r2) end)
    task.wait(0.03)
    local c3 = aliveChar(p)
    local head = c3 and c3:FindFirstChild("Head")
    if head then pcall(function() ht:FireServer(head) end) end
end

FX.throwKill = function(p)
    FX.attacking()
    local c, r = aliveChar(p)
    if not c then return end
    local knife = hasKnife()
    if not knife then return end
    local ch = lp.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if knife.Parent ~= ch and hum then
        pcall(function() hum:EquipTool(knife) end)
        task.wait(0.1)
    end
    local ev = knife:FindFirstChild("Events")
    local thrown = ev and ev:FindFirstChild("KnifeThrown")
    local ht = ev and ev:FindFirstChild("HandleTouched")
    local handle = knife:FindFirstChild("Handle")
    if thrown and handle then
        pcall(function() thrown:FireServer(handle.CFrame, CFrame.new(r.Position)) end)
    end
    if ht then
        task.wait(0.05)
        local c2, r2 = aliveChar(p)
        if c2 then
            pcall(function() ht:FireServer(r2) end)
            local head = c2:FindFirstChild("Head")
            if head then pcall(function() ht:FireServer(head) end) end
        end
    end
end

local auraCd = {}
local function killAuraStep(onlyP)
    local hrp, hum = myHrp()
    if busy or picking or not hrp or not hum or hum.Health <= 0 then return end
    if not hasKnife() then return end
    FX.attacking()
    local targets = {}
    if onlyP then
        targets[1] = onlyP
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and aliveChar(p) and inRound(p) then targets[#targets + 1] = p end
        end
    end
    for _, p in ipairs(targets) do
        if tick() - (auraCd[p] or 0) > 0.35 then
            auraCd[p] = tick()
            task.spawn(FX.throwKill, p)
        end
    end
end

local function stabAuraStep(onlyP)
    local hrp, hum = myHrp()
    if busy or picking or not hrp or not hum or hum.Health <= 0 then return end
    local knife = hasKnife()
    if not knife then return end
    local reach = CFG.auraRange
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c, r, h = aliveChar(p)
            if c then
                local d = (r.Position - hrp.Position).Magnitude
                if d <= reach and inRound(p) then list[#list + 1] = {p = p, d = d} end
            end
        end
    end
    if onlyP then
        list = {}
        local oc, orr = aliveChar(onlyP)
        if oc then list[1] = {p = onlyP, d = (orr.Position - hrp.Position).Magnitude} end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b) return a.d < b.d end)
    busy = true
    local okRun = pcall(function()
        if knife.Parent ~= lp.Character then
            hum:EquipTool(knife)
            task.wait(0.12)
        end
        knife = lp.Character and lp.Character:FindFirstChild("Knife")
        if not knife then return end
        local handle = knife:FindFirstChild("Handle")
        local ev = knife:FindFirstChild("Events")
        local recorded = {}
        if ev then
            for _, r in ipairs(ev:GetChildren()) do
                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and not r.Name:lower():find("throw", 1, true) then
                    local rec = pickRec(ST.rec[r.Name])
                    if rec then recorded[#recorded + 1] = {r, rec} end
                end
            end
        end
        local back = hrp.CFrame
        local moved = false
        for _, t in ipairs(list) do
            if hum.Health <= 0 or not CFG.autoKill then break end
            local tries = 0
            while tries < CFG.maxTries and CFG.autoKill do
                local c, r, h = aliveChar(t.p)
                if not c then break end
                if CFG.auraTp and (r.Position - hrp.Position).Magnitude > CFG.stabReach then
                    hrp.CFrame = r.CFrame * CFrame.new(0, 0, 2.4)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    moved = true
                end
                knife:Activate()
                if handle then
                    touch(handle, r)
                    local head = c:FindFirstChild("Head")
                    if head then touch(handle, head) end
                end
                local cp = hrp.Position
                if #recorded > 0 then
                    for _, it in ipairs(recorded) do
                        task.spawn(pcall, replay, it[1], it[2], t.p, c, h, r, cp)
                    end
                elseif ev then
                    for _, rem in ipairs(ev:GetChildren()) do
                        if rem:IsA("RemoteEvent") and not rem.Name:lower():find("throw", 1, true) then
                            for _, a in ipairs({{r}, {c:FindFirstChild("Head") or r}, {c}, {h}, {t.p}, {r, r.Position}}) do
                                task.spawn(pcall, function() rem:FireServer(table.unpack(a)) end)
                            end
                        end
                    end
                end
                task.wait(CFG.hitDelay)
                tries += 1
            end
        end
        if moved and hrp.Parent and hum.Health > 0 then
            hrp.CFrame = back
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    busy = false
    if not okRun then task.wait(0.2) end
end

do
    local SHERIFF_SET = {Sheriff = true, Hero = true}

    local function targets(kind)
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local r = roles[p]
                local ok
                if kind == "Murderer" then
                    ok = r == "Murderer"
                elseif kind == "Sheriff" then
                    ok = SHERIFF_SET[r] == true
                elseif kind == "Both" then
                    ok = r == "Murderer" or SHERIFF_SET[r] == true
                else
                    ok = true
                end
                if ok and aliveChar(p) and inRound(p) then list[#list + 1] = p end
            end
        end
        return list
    end

    local OFFS = {
        Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
        Vector3.new(2.25, 1.5, -2.25), Vector3.new(-2.25, -1.5, 2.25),
        Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
    }

    local function camHome()
        local cam0 = workspace.CurrentCamera
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if cam0 and h then
            cam0.CameraType = Enum.CameraType.Custom
            cam0.CameraSubject = h
        end
    end
    FX.camHome = camHome

    local function flingOne(p)
        if busy or picking then return false end
        if holding then surface() end
        local char = lp.Character
        local hrp, hum = myHrp()
        if not char or not hrp or not hum or hum.Health <= 0 then return false end
        if char.Parent ~= workspace then return false end
        local tc, tr0, th = aliveChar(p)
        if not tc then return false end
        busy, flinging = true, true
        local old = hrp.CFrame
        local fpdh = workspace.FallenPartsDestroyHeight
        pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
        local cam0 = workspace.CurrentCamera
        local head = tc:FindFirstChild("Head")
        pcall(function() cam0.CameraSubject = head or th end)
        local bv = Instance.new("BodyVelocity")
        bv.Name = "ZenithFlingBV"
        bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = hrp
        local base = tr0
        if head and (tr0.Position - head.Position).Magnitude > 5 then base = head end
        local t0 = tick()
        local angle = 0

        local function done()
            if not running or hum.Health <= 0 then return true end
            if not base.Parent or p.Character ~= tc or p.Parent ~= Players then return true end
            if th.Health <= 0 or th.Sit then return true end
            if base.AssemblyLinearVelocity.Magnitude > 500 then return true end
            return tick() - t0 > CFG.flingTime
        end

        local function fpos(pos, ang)
            local okp, ping = pcall(function() return lp:GetNetworkPing() end)
            local lead = base.AssemblyLinearVelocity * math.clamp(okp and ping or 0.1, 0.03, 0.25)
            local cf = CFrame.new(base.Position + lead) * pos * ang
            hrp.CFrame = cf
            pcall(function() char:PivotTo(cf) end)
            hrp.AssemblyLinearVelocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            hrp.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
            task.wait()
            return done()
        end

        pcall(function()
            if CFG.flingMethod == "Bypass" then
                -- anti-flings reset any huge speed on their side; a steady push under their limit is left alone,
                -- so stand inside them and carry them up and away, with a short spike now and then
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.MaxForce = Vector3.new(0, 0, 0)
                local startY = base.Position.Y
                local away = (base.Position - old.Position) * Vector3.new(1, 0, 1)
                away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
                local i = 0
                while not done() do
                    i += 1
                    PRE_SIM:Wait()
                    if not base.Parent then break end
                    local cf = CFrame.new(base.Position - Vector3.new(0, 1.4, 0) + base.AssemblyLinearVelocity * 0.06)
                    hrp.CFrame = cf
                    pcall(function() char:PivotTo(cf) end)
                    if i % 12 == 0 then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 4000, 0) + away * 4000
                    else
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 75, 0) + away * 55
                    end
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 40, 0)
                    RunService.Heartbeat:Wait()
                    if base.Position.Y - startY > 60 then break end
                end
                return
            end
            if CFG.flingMethod == "Walk" then
                local i = 0
                while not done() do
                    i += 1
                    local off = OFFS[(i % #OFFS) + 1]
                    PRE_SIM:Wait()
                    hrp.CFrame = CFrame.new(base.Position + off * 0.6 + base.AssemblyLinearVelocity * 0.08)
                    RunService.Heartbeat:Wait()
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    PRE_RENDER:Wait()
                    hrp.AssemblyLinearVelocity = vel
                end
                return
            end
            repeat
                local v = base.AssemblyLinearVelocity.Magnitude
                local md = th.MoveDirection
                if v < 50 then
                    angle += 100
                    local a = CFrame.Angles(math.rad(angle), 0, 0)
                    local m = md * v / 1.25
                    if fpos(CFrame.new(0, 1.5, 0) + m, a) then break end
                    if fpos(CFrame.new(0, -1.5, 0) + m, a) then break end
                    if fpos(CFrame.new(2.25, 1.5, -2.25) + m, a) then break end
                    if fpos(CFrame.new(-2.25, -1.5, 2.25) + m, a) then break end
                    if fpos(CFrame.new(0, 1.5, 0) + md, a) then break end
                    if fpos(CFrame.new(0, -1.5, 0) + md, a) then break end
                else
                    local ws = th.WalkSpeed
                    local up90 = CFrame.Angles(math.rad(90), 0, 0)
                    local zero = CFrame.Angles(0, 0, 0)
                    if fpos(CFrame.new(0, 1.5, ws), up90) then break end
                    if fpos(CFrame.new(0, -1.5, -ws), zero) then break end
                    if fpos(CFrame.new(0, 1.5, ws), up90) then break end
                    if fpos(CFrame.new(0, 1.5, v / 1.25), up90) then break end
                    if fpos(CFrame.new(0, -1.5, -v / 1.25), zero) then break end
                    if fpos(CFrame.new(0, 1.5, v / 1.25), up90) then break end
                    if fpos(CFrame.new(0, -1.5, 0), up90) then break end
                    if fpos(CFrame.new(0, -1.5, 0), zero) then break end
                    if fpos(CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) then break end
                    if fpos(CFrame.new(0, -1.5, 0), zero) then break end
                end
            until done()
        end)

        local flung = (not base.Parent) or base.AssemblyLinearVelocity.Magnitude > 500 or th.Health <= 0
        pcall(function() bv:Destroy() end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        camHome()
        local t1 = tick()
        repeat
            if not hrp.Parent or lp.Character ~= char then break end
            hrp.CFrame = old * CFrame.new(0, 0.5, 0)
            pcall(function() char:PivotTo(old * CFrame.new(0, 0.5, 0)) end)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            for _, x in ipairs(char:GetChildren()) do
                if x:IsA("BasePart") then
                    x.AssemblyLinearVelocity = Vector3.zero
                    x.AssemblyAngularVelocity = Vector3.zero
                end
            end
            task.wait()
        until (hrp.Position - old.Position).Magnitude < 25 or tick() - t1 > 2.5
        pcall(function() workspace.FallenPartsDestroyHeight = fpdh end)
        camHome()
        flinging = false
        cooldown[p] = tick()
        busy = false
        return flung
    end

    FX.flingKind = function(kind)
        for _, p in ipairs(targets(kind)) do
            if not running then break end
            flingOne(p)
            task.wait(0.35)
        end
    end

    FX.flingPlayer = function(name)
        local p = name and Players:FindFirstChild(name)
        if p and p ~= lp and aliveChar(p) then flingOne(p) end
    end

    FX.autoFlingRole = function()
        if busy then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and aliveChar(p) then
                local r = roles[p]
                local c = p.Character
                local sher = r == "Sheriff" or r == "Hero" or (c and c:FindFirstChild("Gun") ~= nil)
                local murd = r == "Murderer" or (c and c:FindFirstChild("Knife") ~= nil)
                if ((CFG.flingSheriffAuto and sher) or (CFG.flingMurderAuto and murd)) and (cooldown[p] or 0) + 4 < tick() then
                    flingOne(p)
                    return
                end
            end
        end
    end

    FX.autoFling = function()
        if busy then return end
        for _, p in ipairs(targets("Both")) do
            if (cooldown[p] or 0) + CFG.flingCooldown < tick() then
                flingOne(p)
                break
            end
        end
    end

    FX.playerNames = function()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then t[#t + 1] = p.Name end
        end
        table.sort(t)
        if #t == 0 then t[1] = "-" end
        return t
    end

    connect(PRE_SIM, function()
        if not CFG.antiFling or flinging then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                for _, d in ipairs(p.Character:GetChildren()) do
                    if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
                end
            end
        end
        if busy or holding or CFG.fly then return end
        local hrp = myHrp()
        if not hrp then return end
        local v = hrp.AssemblyLinearVelocity
        local flat = Vector3.new(v.X, math.max(v.Y, 0), v.Z)
        if flat.Magnitude > 120 or hrp.AssemblyAngularVelocity.Magnitude > 50 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

do
    local hbSaved, reachSaved = {}, {}

    FX.killAll = function()
        if busy then return end
        local hrp, hum = myHrp()
        if not hrp or not hum or hum.Health <= 0 then return end
        local knife = hasKnife()
        if not knife then
            if FX.killAllWaiting then return end
            FX.killAllWaiting = true
            task.spawn(function()
                local t0 = tick()
                while running and tick() - t0 < 60 do
                    if hasKnife() then
                        FX.killAllWaiting = false
                        pcall(FX.killAll)
                        return
                    end
                    task.wait(0.15)
                end
                FX.killAllWaiting = false
            end)
            return
        end
        busy = true
        FX.attacking()
        local back = hrp.CFrame
        pcall(function()
            if knife.Parent ~= lp.Character then
                hum:EquipTool(knife)
                task.wait(0.06)
            end
            local ev = knife:FindFirstChild("Events")
            local stab = ev and ev:FindFirstChild("KnifeStabbed")
            local ht = ev and ev:FindFirstChild("HandleTouched")
            local handle = knife:FindFirstChild("Handle")
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and aliveChar(p) and inRound(p) then targets[#targets + 1] = p end
            end
            -- only the knife's own remotes (Knife > Events): no teleporting.
            -- KnifeThrown sends a thrown knife at each player, KnifeStabbed + HandleTouched report the hit on them
            local thrown = ev and ev:FindFirstChild("KnifeThrown")
            local deadline = tick() + 4
            local pass = 0
            while tick() < deadline and hum.Health > 0 do
                local left = 0
                pass = pass + 1
                for _, p in ipairs(targets) do
                    local c, r = aliveChar(p)
                    if c and r then
                        left = left + 1
                        FX.attacking()
                        if thrown and handle and pass % 6 == 1 then
                            pcall(function() thrown:FireServer(handle.CFrame, CFrame.new(r.Position)) end)
                        end
                        if stab then pcall(function() stab:FireServer() end) end
                        if ht then
                            pcall(function() ht:FireServer(r) end)
                            local head = c:FindFirstChild("Head")
                            if head then pcall(function() ht:FireServer(head) end) end
                        end
                    end
                end
                if left == 0 then break end
                game:GetService("RunService").Heartbeat:Wait()
            end
        end)
        if hrp.Parent then
            hrp.CFrame = back
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        busy = false
    end

    FX.killTarget = function(p)
        local r0, t0, k0 = CFG.auraRange, CFG.auraTp, CFG.autoKill
        CFG.auraRange, CFG.autoKill = 5000, true
        if CFG.droneTpKill then CFG.auraTp = true end
        for _ = 1, 2 do
            pcall(killAuraStep, p)
            task.wait(0.1)
        end
        CFG.auraRange, CFG.auraTp, CFG.autoKill = r0, t0, k0
    end

    local function restoreHB()
        for part, o in pairs(hbSaved) do
            if part.Parent then
                pcall(function()
                    part.Size = o.size
                    part.Transparency = o.tr
                    part.CanCollide = o.cc
                end)
            end
        end
        table.clear(hbSaved)
    end
    FX.restoreHB = restoreHB

    local function restoreReach()
        for part, o in pairs(reachSaved) do
            if part.Parent then
                pcall(function()
                    part.Size = o.size
                    part.Massless = o.ml
                    part.LocalTransparencyModifier = 0
                end)
            end
        end
        table.clear(reachSaved)
    end
    FX.restoreReach = restoreReach

    connect(RunService.Heartbeat, function()
        if CFG.hitboxOn then
            local sz = CFG.hitboxSize
            local want = Vector3.new(sz, sz, sz)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then
                    local c, r = aliveChar(p)
                    if c then
                        if not hbSaved[r] then hbSaved[r] = {size = r.Size, tr = r.Transparency, cc = r.CanCollide} end
                        if r.Size ~= want then r.Size = want end
                        r.Transparency = 0.8
                        r.CanCollide = false
                    end
                end
            end
        elseif next(hbSaved) then
            restoreHB()
        end
        local c = lp.Character
        local knife = c and c:FindFirstChild("Knife")
        local h = knife and knife:FindFirstChild("Handle")
        if CFG.reachOn and h and h:IsA("BasePart") then
            if not reachSaved[h] then reachSaved[h] = {size = h.Size, ml = h.Massless} end
            local rs = CFG.reachSize
            local want = Vector3.new(rs, rs, rs)
            if h.Size ~= want then h.Size = want end
            h.Massless = true
            h.LocalTransparencyModifier = 0.85
        elseif next(reachSaved) and not CFG.reachOn then
            restoreReach()
        end
    end)
end

local function findGun()
    local places = {}
    if lp.Character then places[#places + 1] = lp.Character end
    local bp = lp:FindFirstChild("Backpack")
    if bp then places[#places + 1] = bp end
    for _, pl in ipairs(places) do
        for _, t in ipairs(pl:GetChildren()) do
            if t:IsA("Tool") then
                local r = t:FindFirstChild("Shoot")
                if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return t, r end
            end
        end
    end
end

local function autoShootStep()
    if roles[lp] == "Murderer" or picking then return end
    local gun, remote = findGun()
    if not gun then return end
    local t = murdererHrp()
    if not t then return end
    local mine = seen()
    local mhrp = mine and mine:FindFirstChild("HumanoidRootPart")
    local me = ST.gunOrigin() or ((mhrp and mhrp.Position or (ST.myPos or t.Position)) + Vector3.new(0, 1.5, 0))
    if not CFG.wallbang and (t.Position - me).Magnitude > CFG.shootMax then return end
    ST.asCall = true
    local list = ST.calcAll(me, t, CFG.wallbang)
    ST.asCall = false
    if CFG.autoShoot and (CFG.shootChance or 100) < 100 and math.random(1, 100) > CFG.shootChance then
        -- a miss: the shot goes a little to the side of the target
        local side = Vector3.new(math.random(-100, 100), math.random(-30, 60), math.random(-100, 100)).Unit * (4 + math.random() * 3)
        for _, v in ipairs(list) do v[2] = v[2] + side end
    end
    local aim = list[1][2]
    if not CFG.wallbang then
        rp.FilterDescendantsInstances = {mine, t.Parent}
        if workspace:Raycast(me, aim - me, rp) ~= nil then return end
    end
    lastShot = tick()
    lastGunFire = tick()
    FX.attacking()
    ST.aimPos = aim
    for i, v in ipairs(list) do
        local origin = v[1] or me
        if v.peek then
            ST.peekShot(remote, {a = table.pack(CFrame.lookAt(origin, v[2]), CFrame.new(v[2])), hrp = v.peek})
        else
            ST.fireShoot(remote, CFrame.lookAt(origin, v[2]), CFrame.new(v[2]))
        end
        if i < #list then task.wait() end
    end
end

FX.shootNow = function(force)
    if roles[lp] == "Murderer" or hasKnife() then return end
    local gun = findGun()
    if not gun then
        if FX.notify then FX.notify("Zenith", "No gun") end
        return
    end
    local c = lp.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum and gun.Parent ~= c then
        hum:EquipTool(gun)
        for _ = 1, 12 do
            if gun.Parent == c then break end
            task.wait(0.05)
        end
        task.wait(0.1)
    end
    if not murdererHrp() then
        if FX.notify then FX.notify("Zenith", "Murderer not found") end
        return
    end
    lastShot = tick()
    local wb = CFG.wallbang
    if force then CFG.wallbang = true end
    pcall(autoShootStep)
    CFG.wallbang = wb
end

local AS = {equipAt = 0, fireAt = 0, busy = false, rp = RaycastParams.new()}
AS.rp.FilterType = Enum.RaycastFilterType.Exclude
ST.threats = function()
    local list = {}
    local myRole = roles[lp]
    local iMurd = myRole == "Murderer" or hasKnife()
    local iZombie = myRole ~= "Murderer" and hostileRole(myRole)
    local iGun = findGun() ~= nil
    local wantMurd = CFG.avoidMurder or (CFG.avoidMurdAsSheriff and iGun) or (CFG.avoidMurdAsInno and not iGun and not iMurd and not iZombie)
    local wantSher = CFG.avoidSheriff or (CFG.avoidSherAsMurd and iMurd)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local role = roles[p]
                local zombie = (role ~= "Murderer" and hostileRole(role)) or ST.isZombie(p)
                local murd = role == "Murderer" or c:FindFirstChild("Knife") ~= nil
                local sher = role == "Sheriff" or role == "Hero" or c:FindFirstChild("Gun") ~= nil
                if not sher then
                    for _, t in ipairs(c:GetChildren()) do
                        if t:IsA("Tool") and t:FindFirstChild("Shoot") then sher = true break end
                    end
                end
                if (wantMurd and murd and not iMurd) or (wantSher and sher)
                    or (CFG.infAvoidZombies and zombie and not iZombie)
                    or (CFG.infAvoidSurvivors and iZombie and not zombie) then
                    list[#list + 1] = r
                end
            end
        end
    end
    return list
end

task.spawn(function()
    while running do
        if CFG.autoShoot and CFG.wallbang and roles[lp] ~= "Murderer" and not AS.busy then
            local gun = findGun()
            if gun and murdererHrp() and tick() - AS.fireAt > 0.8 then
                AS.busy = true
                pcall(FX.shootNow, true)
                AS.fireAt = tick()
                AS.busy = false
            end
        end
        task.wait(1)
    end
end)
local function autoShootTick()
    if AS.busy or roles[lp] == "Murderer" or picking or ST.tpBusy then return end
    local t = murdererHrp()
    if not t then return end
    local gun = findGun()
    local ch = lp.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not gun or not hrp then return end
    if not CFG.wallbang then
        AS.rp.FilterDescendantsInstances = {ch, t.Parent}
        if workspace:Raycast(hrp.Position + Vector3.new(0, 1.5, 0), t.Position - hrp.Position, AS.rp) then return end
    end
    if gun.Parent ~= ch then
        if tick() - AS.equipAt > 0.5 then
            AS.equipAt = tick()
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(gun) end) end
        end
        return
    end
    if tick() - AS.equipAt < 0.18 then return end
    if tick() - AS.fireAt < (AS.retry and 0.35 or 0.8) then return end
    AS.retry = false
    AS.fireAt = tick()
    AS.busy = true
    pcall(autoShootStep)
    AS.busy = false
end

connect(RunService.Heartbeat, function()
    if CFG.autoShoot and not AS.busy and tick() - AS.fireAt >= 0.05 and tick() - lastShot >= 0.05 then
        task.spawn(autoShootTick)
    end
    local ls = ST.lastShot
    if ls and false then
        local el = tick() - ls.t
        if el >= 0.6 and el <= 2.5 and ls.n < 2 then
            local t = ST.target
            local th = t and t.Parent and t.Parent:FindFirstChildOfClass("Humanoid")
            if not t or not th or th.Health <= 0 or not ls.r or not ls.r.Parent then
                ST.lastShot = nil
            else
                ls.n += 1
                ls.t = tick()
                local mh = myHrp()
                local me = (mh and mh.Position or t.Position) + Vector3.new(0, 1.5, 0)
                local list = ST.calcAll(me, t, true)
                local v = list[1]
                if v then
                    pcall(function()
                        ls.r:FireServer(CFrame.lookAt(v[1] or me, v[2]), CFrame.new(v[2]))
                    end)
                end
            end
        end
    end
end)


task.spawn(function()
    while running do
        pcall(function()
            if CFG.autoGun then pickGun() end
            if CFG.flingAuto and FX.autoFling then FX.autoFling() end
            if CFG.autoKill and (roles[lp] == "Murderer" or hasKnife()) then killAuraStep() end
            if (CFG.flingSheriffAuto or CFG.flingMurderAuto) and FX.autoFlingRole then FX.autoFlingRole() end
            local idle = ST.farmIdle == true
            if holding and not busy and (not CFG.farm or idle) then surface() end
        end)
        task.wait(0.1)
    end
end)

-- the farm itself: next candy right away (Fast every frame, Basic every 30 ms)
task.spawn(function()
    while running do
        if CFG.farm and not busy then
            local ok, idle = pcall(farmStep)
            ST.farmIdle = ok and idle == true
        end
        if CFG.farmMethod == "Fast" then RunService.Heartbeat:Wait() else task.wait(0.03) end
    end
end)

local Debris = game:GetService("Debris")

do
local look = {
    tint = Color3.fromRGB(190, 215, 255),
    amb = Color3.fromRGB(40, 80, 170),
    fogColor = Color3.fromRGB(25, 70, 200),
}
local PRESETS = {
    BlueFog = {tint = Color3.fromRGB(190, 215, 255), amb = Color3.fromRGB(40, 80, 170),
               fogColor = Color3.fromRGB(25, 70, 200), bloom = 1.6, sat = 0.4, fog = 350, density = 0.45},
    Neon = {tint = Color3.fromRGB(215, 190, 255), amb = Color3.fromRGB(70, 60, 110),
            fogColor = Color3.fromRGB(90, 40, 200), bloom = 1.8, sat = 0.5, fog = 500, density = 0.3},
    Ice = {tint = Color3.fromRGB(200, 235, 255), amb = Color3.fromRGB(90, 130, 190),
           fogColor = Color3.fromRGB(120, 180, 255), bloom = 1.0, sat = 0.2, fog = 250, density = 0.6},
    Abyss = {tint = Color3.fromRGB(150, 190, 255), amb = Color3.fromRGB(15, 35, 90),
             fogColor = Color3.fromRGB(5, 20, 80), bloom = 1.2, sat = 0.3, fog = 150, density = 0.7},
}
local PRESET_NAMES = {"BlueFog", "Neon", "Ice", "Abyss"}

local sh = {fx = nil, saved = nil, removed = {}}

local function shadersOn()
    if sh.fx then return end
    sh.saved = {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness, ExposureCompensation = Lighting.ExposureCompensation,
        FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
        ClockTime = Lighting.ClockTime,
    }
    sh.removed = {}
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") then
            sh.removed[#sh.removed + 1] = v
            v.Parent = nil
        end
    end
    local fx = {}
    fx.bloom = Instance.new("BloomEffect", Lighting)
    fx.cc = Instance.new("ColorCorrectionEffect", Lighting)
    fx.rays = Instance.new("SunRaysEffect", Lighting)
    fx.dof = Instance.new("DepthOfFieldEffect", Lighting)
    fx.atm = Instance.new("Atmosphere", Lighting)
    fx.sky = Instance.new("Sky")
    fx.sky.StarCount = 0
    fx.sky.CelestialBodiesShown = false
    sh.fx = fx
end

local function shadersApply()
    local fx = sh.fx
    if not fx then return end
    fx.bloom.Intensity, fx.bloom.Size, fx.bloom.Threshold = CFG.bloom, 45, 0.75
    fx.cc.Contrast, fx.cc.Saturation, fx.cc.TintColor = CFG.contrast, CFG.sat, look.tint
    fx.rays.Intensity, fx.rays.Spread = 0.15, 0.8
    fx.dof.FarIntensity, fx.dof.NearIntensity = CFG.dof, 0
    fx.dof.FocusDistance, fx.dof.InFocusRadius = 60, 80
    local skyOn = CFG.skybox and CFG.skybox ~= "Off"
    fx.atm.Density = (CFG.fogOn and not skyOn) and CFG.density or 0
    fx.atm.Haze = (CFG.fogOn and not skyOn) and 2 or 0
    fx.atm.Offset = 0.2
    fx.atm.Color, fx.atm.Decay = look.fogColor, look.fogColor
    Lighting.Ambient, Lighting.OutdoorAmbient = look.amb, look.amb
    Lighting.Brightness = CFG.bright
    Lighting.ExposureCompensation = 0.3
    Lighting.FogColor, Lighting.FogStart = look.fogColor, 0
    Lighting.FogEnd = CFG.fogOn and CFG.fog or 100000
    fx.sky.Parent = nil
end

local function shadersOff()
    local fx = sh.fx
    if not fx then return end
    sh.fx = nil
    for _, v in pairs(fx) do pcall(function() v:Destroy() end) end
    for _, v in ipairs(sh.removed) do pcall(function() v.Parent = Lighting end) end
    sh.removed = {}
    if sh.saved then
        for k, v in pairs(sh.saved) do pcall(function() Lighting[k] = v end) end
    end
end

local function setShaders(v)
    CFG.shaders = v
    if v then
        shadersOn()
        shadersApply()
    else
        shadersOff()
    end
end

local function applyPreset(name)
    local p = PRESETS[name]
    if not p then return end
    look.tint, look.amb, look.fogColor = p.tint, p.amb, p.fogColor
    CFG.bloom, CFG.sat, CFG.fog, CFG.density = p.bloom, p.sat, p.fog, p.density
    if CFG.shaders then shadersApply() end
end

task.spawn(function()
    while running do
        if CFG.shaders then
            pcall(function()
                shadersOn()
                shadersApply()
            end)
        end
        task.wait(1)
    end
end)
FX.setShaders = setShaders
FX.applyPreset = applyPreset
FX.shadersApply = shadersApply
FX.shadersOff = shadersOff
FX.PRESET_NAMES = PRESET_NAMES
end
local setShaders, applyPreset, shadersApply, PRESET_NAMES = FX.setShaders, FX.applyPreset, FX.shadersApply, FX.PRESET_NAMES

do
local trailFolder = Instance.new("Folder")
trailFolder.Name = "ZenithTrail"
trailFolder.Parent = workspace
local trailCount, trailAcc = 0, 0
local TRAIL_COLOR = Color3.fromRGB(40, 40, 46)

local trailModel = Instance.new("Model")
trailModel.Name = "ZenithGhost"
trailModel.Parent = workspace
local trailHL = Instance.new("Highlight")
trailHL.Adornee = trailModel
trailHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
trailHL.FillTransparency = 0.45
trailHL.OutlineTransparency = 0
trailHL.Enabled = false
trailHL.Parent = trailModel

local gh = {char = nil, parts = {}, hist = {}, mode = nil}

local function clearGhost()
    for _, g in pairs(gh.parts) do pcall(function() g:Destroy() end) end
    gh.parts, gh.hist, gh.char, gh.mode = {}, {}, nil, nil
end

local function buildGhost(c)
    clearGhost()
    gh.char, gh.mode = c, CFG.trailMode
    for _, p in ipairs(c:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 and p.Name:sub(1, 6) ~= "Zenith" then
            local ok, g = pcall(function() return p:Clone() end)
            if ok and g then
                for _, ch in ipairs(g:GetChildren()) do ch:Destroy() end
                if g:IsA("MeshPart") then pcall(function() g.TextureID = "" end) end
            else
                g = Instance.new("Part")
                g.Size = p.Size
            end
            g.Anchored = true
            g.CanCollide = false
            g.CanQuery = false
            g.CanTouch = false
            g.CastShadow = false
            g.Massless = true
            g.CFrame = p.CFrame
            local mode = CFG.trailMode
            if mode == "Chams" or mode == "Neon" then
                g.Material = Enum.Material.Neon
            elseif mode == "ForceField" then
                g.Material = Enum.Material.ForceField
            else
                g.Material = Enum.Material.SmoothPlastic
            end
            g.Transparency = 1
            g.Parent = trailModel
            gh.parts[p] = g
        end
    end
end

local function smokeEmitter(hrp)
    local e = hrp:FindFirstChild("ZenithSmoke")
    if e then return e end
    e = Instance.new("ParticleEmitter")
    e.Name = "ZenithSmoke"
    e.Texture = "rbxasset://textures/particles/smoke_main.dds"
    e.Color = ColorSequence.new(colorOf(CFG.trailColor))
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.15, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2.7),
        NumberSequenceKeypoint.new(1, 6.3),
    })
    e.Lifetime = NumberRange.new(0.55, 0.9)
    e.Rate = 55
    e.Speed = NumberRange.new(0, 0.5)
    e.Rotation = NumberRange.new(0, 360)
    e.RotSpeed = NumberRange.new(-20, 20)
    e.LightEmission = 0
    e.LightInfluence = 0
    e.Drag = 4
    e.SpreadAngle = Vector2.new(180, 180)
    e.Enabled = false
    e.Parent = hrp
    return e
end

connect(RunService.Heartbeat, function()
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    local sm = hrp and hrp:FindFirstChild("ZenithSmoke")
    if not CFG.trail or not hrp or not hum or hum.Health <= 0 then
        if gh.char then clearGhost() end
        trailHL.Enabled = false
        if sm then sm.Enabled = false end
        return
    end
    if gh.char ~= c or gh.mode ~= CFG.trailMode then buildGhost(c) end
    local v = hrp.AssemblyLinearVelocity
    local moving = Vector3.new(v.X, 0, v.Z).Magnitude >= 3
    if CFG.trailSmoke then
        smokeEmitter(hrp).Enabled = moving
    elseif sm then
        sm.Enabled = false
    end
    local now = tick()
    local snap = {}
    for p in pairs(gh.parts) do
        if p.Parent then snap[p] = p.CFrame end
    end
    local hist = gh.hist
    hist[#hist + 1] = {t = now, cf = snap}
    local target = now - CFG.trailDelay
    local idx
    for k = #hist, 1, -1 do
        if hist[k].t <= target then
            idx = k
            break
        end
    end
    if idx and idx > 1 then
        for _ = 1, idx - 1 do table.remove(hist, 1) end
        idx = 1
    end
    while #hist > 600 do table.remove(hist, 1) end
    local use = idx and hist[idx]
    local col = colorOf(CFG.trailColor)
    local mode = CFG.trailMode
    local base = (mode == "Chams" and 0.35) or (mode == "ForceField" and 0.1) or (mode == "Neon" and 0.4) or CFG.trailTransp
    for p, g in pairs(gh.parts) do
        if p.Parent then
            local cf = (use and use.cf[p]) or p.CFrame
            g.CFrame = cf
            g.Color = col
            local vis = math.clamp((cf.Position - p.Position).Magnitude / 2, 0, 1)
            g.Transparency = 1 - (1 - base) * vis
        else
            g.Transparency = 1
        end
    end
    trailHL.Enabled = mode == "Chams"
    if mode == "Chams" then
        trailHL.FillColor = col
        trailHL.OutlineColor = col:Lerp(Color3.new(1, 1, 1), 0.55)
    end
end)

local shotFolder = Instance.new("Folder")
shotFolder.Name = "ZenithShotTrail"
shotFolder.Parent = workspace
local srp = RaycastParams.new()
srp.FilterType = Enum.RaycastFilterType.Exclude

local function mkShotPart(size, cf, tr, shape)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = colorOf(CFG.trailColor)
    p.Shape = shape or Enum.PartType.Block
    p.Size = size
    p.CFrame = cf
    p.Transparency = tr
    p.Parent = shotFolder
    return p
end

local function shotSeg(a, b)
    local d = b - a
    if d.Magnitude < 0.5 then return end
    local ig = {shotFolder}
    if lp.Character then ig[2] = lp.Character end
    srp.FilterDescendantsInstances = ig
    local hit = workspace:Raycast(a, d.Unit * math.min(d.Magnitude + 2, 1000), srp)
    local e = hit and hit.Position or b
    local len = (e - a).Magnitude
    if len < 0.5 then return end
    local white = Color3.new(1, 1, 1)
    local beam = mkShotPart(Vector3.new(0.14, 0.14, len), CFrame.lookAt(a:Lerp(e, 0.5), e), 0)
    beam.Color = white
    local dot = mkShotPart(Vector3.new(0.45, 0.45, 0.45), CFrame.new(e), 0, Enum.PartType.Ball)
    dot.Color = white
    task.delay(1, function()
        local fade = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if beam.Parent then TweenService:Create(beam, fade, {Transparency = 1}):Play() end
        if dot.Parent then TweenService:Create(dot, fade, {Transparency = 1}):Play() end
    end)
    Debris:AddItem(beam, 1.4)
    Debris:AddItem(dot, 1.4)
end
FX.shot = shotSeg

local function restyleTrail(part)
    local beam = part:FindFirstChildOfClass("Beam")
    if not beam then return end
    pcall(function() beam.Enabled = false end)
    local best, b0, b1 = 0, nil, nil
    local t0 = tick()
    while tick() - t0 < 0.25 do
        local a0, a1 = beam.Attachment0, beam.Attachment1
        if a0 and a1 then
            local p0, p1 = a0.WorldPosition, a1.WorldPosition
            local len = (p1 - p0).Magnitude
            if len > best then best, b0, b1 = len, p0, p1 end
        end
        if best > 0.5 and tick() - t0 > 0.1 then break end
        if not beam.Parent then break end
        RunService.Heartbeat:Wait()
        pcall(function() beam.Enabled = false end)
    end
    if best < 0.5 then return end
    local kind = CFG.shotFx or "Neon"
    if kind == "Lighting" then
        local dir = b1 - b0
        local right = dir:Cross(Vector3.new(0, 1, 0))
        if right.Magnitude < 0.01 then right = Vector3.new(1, 0, 0) end
        right = right.Unit
        local up = right:Cross(dir).Unit
        local pts = {b0}
        local n = math.clamp(math.floor(best / 4), 3, 14)
        for k = 1, n - 1 do
            pts[#pts + 1] = b0 + dir * (k / n) + right * (math.random() - 0.5) * 1.8 + up * (math.random() - 0.5) * 1.8
        end
        pts[#pts + 1] = b1
        local segs = {}
        for k = 1, #pts - 1 do
            local a, b = pts[k], pts[k + 1]
            local seg = mkShotPart(Vector3.new(0.12, 0.12, (b - a).Magnitude), CFrame.lookAt(a:Lerp(b, 0.5), b), 0)
            seg.Color = colorOf(CFG.shotColor)
            segs[#segs + 1] = seg
            Debris:AddItem(seg, 1.2)
        end
        task.spawn(function()
            for k = 1, 8 do
                for _, sg in ipairs(segs) do
                    if sg.Parent then sg.Transparency = (k % 2 == 0) and 0 or 0.6 end
                end
                task.wait(0.07)
            end
            for _, sg in ipairs(segs) do
                if sg.Parent then TweenService:Create(sg, TweenInfo.new(0.3), {Transparency = 1}):Play() end
            end
        end)
        return
    end
    if kind == "Explosion" then
        pcall(function()
            local ex = Instance.new("Explosion")
            ex.Position = b1
            ex.BlastRadius = 4
            ex.BlastPressure = 0
            ex.DestroyJointRadiusPercent = 0
            ex.ExplosionType = Enum.ExplosionType.NoCraters
            ex.Parent = workspace
        end)
    elseif kind == "Blood" then
        pcall(function()
            local holder = Instance.new("Part")
            holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
            holder.Transparency = 1
            holder.Size = Vector3.new(0.2, 0.2, 0.2)
            holder.CFrame = CFrame.new(b1)
            holder.Parent = workspace
            local e = Instance.new("ParticleEmitter")
            e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            e.Color = ColorSequence.new(Color3.fromRGB(170, 0, 0), Color3.fromRGB(90, 0, 0))
            e.Size = NumberSequence.new(0.35, 0)
            e.Lifetime = NumberRange.new(0.4, 0.8)
            e.Speed = NumberRange.new(8, 16)
            e.SpreadAngle = Vector2.new(180, 180)
            e.Acceleration = Vector3.new(0, -40, 0)
            e.Rate = 0
            e.Parent = holder
            e:Emit(35)
            Debris:AddItem(holder, 1.5)
        end)
    end
    local line = mkShotPart(Vector3.new(0.14, 0.14, best), CFrame.lookAt(b0:Lerp(b1, 0.5), b1), 0)
    local dot = mkShotPart(Vector3.new(0.45, 0.45, 0.45), CFrame.new(b1), 0, Enum.PartType.Ball)
    if kind == "Blood" then
        line.Color, dot.Color = Color3.fromRGB(140, 0, 0), Color3.fromRGB(140, 0, 0)
    end
    task.spawn(function()
        local s0 = tick()
        while line.Parent and tick() - s0 < 1 do
            local c = (kind == "Blood") and Color3.fromRGB(140, 0, 0) or colorOf(CFG.shotColor)
            line.Color, dot.Color = c, c
            task.wait(0.05)
        end
        local fade = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if line.Parent then TweenService:Create(line, fade, {Transparency = 1}):Play() end
        if dot.Parent then TweenService:Create(dot, fade, {Transparency = 1}):Play() end
    end)
    Debris:AddItem(line, 1.4)
    Debris:AddItem(dot, 1.4)
end

connect(workspace.ChildAdded, function(d)
    if not CFG.shotTrail or not d:IsA("BasePart") then return end
    task.defer(function()
        local t0 = tick()
        while d.Parent and not d:FindFirstChildOfClass("Beam") and tick() - t0 < 0.4 do
            RunService.Heartbeat:Wait()
        end
        if d.Parent and d:FindFirstChildOfClass("Attachment") and d:FindFirstChildOfClass("Beam") then
            RunService.Heartbeat:Wait()
            pcall(restyleTrail, d)
        end
    end)
end)

local function shotCast(origin, dir, ignore)
    srp.FilterDescendantsInstances = {ignore, shotFolder}
    local u = dir.Unit * 500
    local r = workspace:Raycast(origin, u, srp)
    return r and r.Position or origin + u
end

local function muzzle(char)
    local gun = char:FindFirstChild("Gun")
    local h = gun and gun:FindFirstChild("Handle")
    if h then return h.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

local function onShootAnim(p, char)
    if p == lp then
        lastGunFire = tick()
    end
    if true then return end
    local origin = muzzle(char)
    if not origin then return end
    if p == lp then
        origin = (ST.gunOrigin and ST.gunOrigin()) or origin
        local target
        if CFG.silent and ST.aimPos and tick() - (ST.aimAt or 0) < 0.5 then
            target = ST.aimPos
        else
            local c0 = workspace.CurrentCamera
            local vp = c0.ViewportSize
            local ray = c0:ViewportPointToRay(vp.X / 2, vp.Y / 2)
            target = shotCast(ray.Origin, ray.Direction, char)
        end
        shotSeg(origin, target)
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then shotSeg(origin, shotCast(origin, hrp.CFrame.LookVector, char)) end
    end
end

local function hookShotChar(p, char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    local an = hum:FindFirstChildOfClass("Animator") or hum
    connect(an.AnimationPlayed, function(track)
        local a = track.Animation
        if track.Name == "Shoot" or (a and a.Name == "Shoot") then
            onShootAnim(p, char)
        end
    end)
end

local function hookShotPlayer(p)
    if p.Character then task.spawn(hookShotChar, p, p.Character) end
    connect(p.CharacterAdded, function(c) hookShotChar(p, c) end)
end

for _, p in ipairs(Players:GetPlayers()) do hookShotPlayer(p) end
connect(Players.PlayerAdded, hookShotPlayer)
FX.trailFolder = trailFolder
FX.trailModel = trailModel
FX.shotFolder = shotFolder
end

local SND = {
    gun = {
        ["SFX Hit"] = 96359585058783,
        ["Bubble Pop Hit"] = 119697580657161,
        ["Neverlose Hit"] = 82938206376993,
        ["AWP"] = 138705939667182,
        ["Minecraft Hit"] = 100704995846015,
        ["CS:GO Headshot"] = 133002449941130,
        ["Headshot CS:GO 2"] = 132110078840319,
    },
    gunNames = {"SFX Hit", "Bubble Pop Hit", "Neverlose Hit", "AWP", "Minecraft Hit", "CS:GO Headshot", "Headshot CS:GO 2", "Off"},
    knife = {
        ["Among Us Kill"] = 130456049552264,
        ["Knife Kill"] = 137951817204948,
    },
    knifeNames = {"Among Us Kill", "Knife Kill", "Off"},
    kill = {
        ["Among Us Kill"] = 130456049552264,
        ["Knife Kill"] = 137951817204948,
        ["SFX Hit"] = 96359585058783,
        ["Bubble Pop Hit"] = 119697580657161,
        ["Neverlose Hit"] = 82938206376993,
        ["AWP"] = 138705939667182,
        ["Minecraft Hit"] = 100704995846015,
        ["CS:GO Headshot"] = 133002449941130,
        ["Headshot CS:GO 2"] = 132110078840319,
    },
    killNames = {"Among Us Kill", "Knife Kill", "SFX Hit", "Bubble Pop Hit", "Neverlose Hit", "AWP", "Minecraft Hit", "CS:GO Headshot", "Headshot CS:GO 2", "Off"},
    orig = {},
}

do
    local SoundService = game:GetService("SoundService")
    local lastPlay = 0

    CFG.gunCustom, CFG.knifeCustom, CFG.killCustom = "", "", ""
    local function customId(txt)
        local n = tonumber((tostring(txt or ""):gsub("%D", "")))
        if n and n > 0 then return n end
    end

    function SND.id(kind)
        if kind == "gun" then
            return SND.gun[CFG.gunSnd]
        elseif kind == "knife" then
            return SND.knife[CFG.knifeSnd]
        end
        return SND.kill[CFG.killSndName]
    end

    function SND.play(id, vol)
        if not id then return end
        local s = Instance.new("Sound")
        s.Name = "ZenithSnd"
        s.SoundId = "rbxassetid://" .. tostring(id)
        s.Volume = vol or 1
        s.Parent = SoundService
        s.Ended:Connect(function() s:Destroy() end)
        s:Play()
        Debris:AddItem(s, 10)
    end

    local lastGun = 0
    function ST.gunSound()
        local now = tick()
        if now - lastGun < 0.15 then return end
        lastGun = now
        local id = CFG.replaceSnd and SND.id("gun")
        if id then
            SND.play(id, CFG.gunVol)
            return
        end
        local c = lp.Character
        local gun = c and c:FindFirstChild("Gun")
        local h = gun and gun:FindFirstChild("Handle")
        local orig = h and h:FindFirstChild("Gunshot")
        if orig and orig:IsA("Sound") then
            local cl = orig:Clone()
            cl.Parent = SoundService
            cl:Play()
            Debris:AddItem(cl, 6)
        end
    end

    local origKind = {}
    local hooked = setmetatable({}, {__mode = "k"})
    local lastGunPlayed = 0
    local function hookDedupe(snd)
        if hooked[snd] then return end
        hooked[snd] = true
        snd.Played:Connect(function()
            if not CFG.replaceSnd then return end
            local now = tick()
            if now - lastGunPlayed < 0.35 then
                pcall(function() snd:Stop() end)
            else
                lastGunPlayed = now
            end
        end)
    end

    local swaps = {}
    local function swapSound(snd, id, vol)
        local want = "rbxassetid://" .. tostring(id)
        if snd:GetAttribute("ZenithSnd") then
            if snd.SoundId ~= want then snd.SoundId = want end
            if snd.Volume ~= vol then snd.Volume = vol end
            return
        end
        local parent = snd.Parent
        if not parent then return end
        local new = snd:Clone()
        new.SoundId = want
        new.Volume = vol
        new:SetAttribute("ZenithSnd", true)
        swaps[new] = {orig = snd, parent = parent}
        snd.Parent = nil
        new.Parent = parent
        new.Played:Connect(function() ST.lastGamePlay = tick() end)
    end

    local function unswap(new)
        local rec = swaps[new]
        swaps[new] = nil
        pcall(function()
            if rec and rec.parent and rec.parent.Parent then rec.orig.Parent = rec.parent end
            new:Destroy()
        end)
    end

    local function setSound(s, id, vol)
        if SND.orig[s] == nil then SND.orig[s] = {s.SoundId, s.Volume} end
        local want = "rbxassetid://" .. tostring(id)
        if s.SoundId ~= want then s.SoundId = want end
        if s.Volume ~= vol then s.Volume = vol end
    end

    local function muteSound(s)
        if SND.orig[s] == nil then SND.orig[s] = {s.SoundId, s.Volume} end
        if s.Volume ~= 0 then s.Volume = 0 end
    end

    local function restoreSound(s)
        local o = SND.orig[s]
        if not o then return end
        SND.orig[s] = nil
        pcall(function()
            s.SoundId = o[1]
            s.Volume = o[2]
        end)
    end

    function SND.restore()
        for s in pairs(SND.orig) do restoreSound(s) end
        for new in pairs(swaps) do unswap(new) end
    end

    local function release(snd)
        if snd:GetAttribute("ZenithSnd") then unswap(snd) else restoreSound(snd) end
    end

    local function hitName(n)
        n = n:lower()
        return n:find("stab", 1, true) or n:find("slash", 1, true) or n:find("swing", 1, true)
            or n:find("hit", 1, true) or n:find("kill", 1, true) or n:find("knife", 1, true)
    end

    local function toolSounds(t, isGun)
        local out = {}
        local sf = t:FindFirstChild("Sounds")
        local h = t:FindFirstChild("Handle")
        if isGun then
            local shoot = sf and sf:FindFirstChild("Shoot")
            if shoot and shoot:IsA("Sound") then out[#out + 1] = shoot end
            local gs = h and h:FindFirstChild("Gunshot")
            if gs and gs:IsA("Sound") then out[#out + 1] = gs end
        else
            if sf then
                for _, s in ipairs(sf:GetChildren()) do
                    if s:IsA("Sound") then out[#out + 1] = s end
                end
            end
            if h then
                for _, s in ipairs(h:GetChildren()) do
                    if s:IsA("Sound") and hitName(s.Name) then out[#out + 1] = s end
                end
            end
        end
        return out
    end

    local function holders()
        return {lp.Character or false, lp:FindFirstChild("Backpack") or false}
    end

    local function scan()
        local rep = CFG.replaceSnd
        local gid = rep and SND.id("gun")
        local kid = rep and SND.id("knife")
        local killid = CFG.killSnd and SND.id("kill")
        for _, holder in ipairs(holders()) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    if t:IsA("Tool") and (t.Name == "Gun" or t.Name == "Knife") then
                        local isGun = t.Name == "Gun"
                        for _, s in ipairs(toolSounds(t, isGun)) do
                            if isGun then
                                if gid then
                                    if s:GetAttribute("ZenithSnd") then
                                        swapSound(s, gid, CFG.gunVol)
                                    else
                                        if SND.orig[s] == nil then origKind[s.SoundId] = "gun" end
                                        setSound(s, gid, CFG.gunVol)
                                    end
                                    hookDedupe(s)
                                else
                                    release(s)
                                end
                            else
                                local isKill = s.Name:lower():find("kill", 1, true) ~= nil
                                local id = (isKill and killid) or kid
                                if id then
                                    if s:GetAttribute("ZenithSnd") then
                                        swapSound(s, id, isKill and CFG.killVol or CFG.knifeVol)
                                    else
                                        if SND.orig[s] == nil then origKind[s.SoundId] = isKill and "kill" or "knife" end
                                        setSound(s, id, isKill and CFG.killVol or CFG.knifeVol)
                                    end
                                else
                                    release(s)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function SND.dump()
        local out = {}
        for _, holder in ipairs(holders()) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    if t:IsA("Tool") and (t.Name == "Gun" or t.Name == "Knife") then
                        local names = {}
                        for _, d in ipairs(t:GetDescendants()) do
                            if d:IsA("Sound") then names[#names + 1] = d.Parent.Name .. "." .. d.Name end
                        end
                        out[#out + 1] = t.Name .. ": " .. (#names > 0 and table.concat(names, ", ") or "no sounds")
                    end
                end
            end
        end
        if #out == 0 then return "no Gun / Knife in backpack" end
        return table.concat(out, "\n")
    end

    task.spawn(function()
        while running do
            pcall(scan)
            task.wait(0.4)
        end
    end)

    local function watchClone(d)
        if not CFG.replaceSnd or not d:IsA("Sound") then return end
        local kind = origKind[d.SoundId]
        if not kind then return end
        local id, vol
        if kind == "gun" then
            id, vol = SND.id("gun"), CFG.gunVol
        elseif kind == "kill" then
            id, vol = CFG.killSnd and SND.id("kill"), CFG.killVol
        else
            id, vol = SND.id("knife"), CFG.knifeVol
        end
        if id then
            d.SoundId = "rbxassetid://" .. tostring(id)
            d.Volume = vol
            if kind == "gun" then hookDedupe(d) end
        end
    end
    connect(workspace.DescendantAdded, watchClone)
    connect(SoundService.DescendantAdded, watchClone)

    local function onDeath()
        if not CFG.killSnd then return end
        local now = tick()
        if now - lastPlay < 1 then return end
        if not (roles[lp] == "Murderer" or hasKnife()) and now - lastGunFire < 2 then
            local id = SND.id("kill")
            if id then
                lastPlay = now
                SND.play(id, CFG.killVol)
            end
        end
    end

    local function hookChar(p, char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then connect(hum.Died, onDeath) end
    end

    local function hookPlayer(p)
        if p == lp then return end
        if p.Character then task.spawn(hookChar, p, p.Character) end
        connect(p.CharacterAdded, function(c) hookChar(p, c) end)
    end

    for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
    connect(Players.PlayerAdded, hookPlayer)

    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") and (r.Name == "KillEvent" or r.Name == "GunKill" or r.Name == "KnifeKill") then
            connect(r.OnClientEvent, function() onDeath() end)
        end
    end

    task.spawn(function()
        local list = {}
        local function add(id)
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://" .. tostring(id)
            list[#list + 1] = snd
        end
        for _, tbl in ipairs({SND.gun, SND.knife, SND.kill}) do
            for _, id in pairs(tbl) do add(id) end
        end
        for _, id in ipairs({138533090376585, 114037851906101, 1548304764}) do add(id) end
        pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
    end)
end

local WING_PRESETS = {}
do
    local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
    local FIRE = "rbxasset://textures/particles/fire_main.dds"
    local function C(r, g, b) return Color3.fromRGB(r, g, b) end
    WING_PRESETS.Angel = {style = "feather", a = C(255, 255, 255), b = C(255, 218, 120), glow = C(255, 242, 200), halo = true, tex = SPARK}
    WING_PRESETS.Frost = {style = "feather", a = C(240, 250, 255), b = C(100, 185, 255), glow = C(160, 215, 255), halo = true, tex = SPARK}
    WING_PRESETS.Inferno = {style = "feather", a = C(255, 238, 175), b = C(255, 80, 25), glow = C(255, 150, 60), halo = true, tex = FIRE,
                            acc = Vector3.new(0, 2.2, 0), psize = 1.6}
    WING_PRESETS.Phoenix = {style = "feather", tail = true, a = C(255, 246, 170), b = C(235, 40, 20), glow = C(255, 170, 50), halo = true,
                            tex = FIRE, acc = Vector3.new(0, 2, 0), psize = 1.7, idle = 0.1}
    WING_PRESETS.Galaxy = {style = "feather", a = C(140, 170, 255), b = C(190, 60, 255), glow = C(150, 120, 255), halo = true,
                           tex = SPARK, pulse = true, prate = 1.8}
    WING_PRESETS.Sakura = {style = "feather", a = C(255, 235, 242), b = C(255, 120, 170), glow = C(255, 170, 200), halo = false,
                           tex = SPARK, acc = Vector3.new(0, -1.6, 0), psize = 1.3}
    WING_PRESETS.Void = {style = "feather", a = C(200, 150, 255), b = C(45, 10, 100), glow = C(175, 95, 255), halo = true, tex = SPARK}
    WING_PRESETS.Demon = {style = "demon", a = C(38, 10, 14), b = C(120, 6, 24), glow = C(255, 45, 30), halo = false,
                          tex = FIRE, acc = Vector3.new(0, 2.4, 0), psize = 1.4, idle = 0.18, flap = 0.8}
    WING_PRESETS.Butterfly = {style = "butterfly", a = C(255, 190, 70), b = C(80, 130, 255), glow = C(255, 210, 130), halo = false,
                              tex = SPARK, idle = 0.75, flap = 1.8}
    WING_PRESETS.Crystal = {style = "crystal", a = C(200, 248, 255), b = C(130, 90, 255), glow = C(170, 225, 255), halo = false,
                            tex = SPARK, idle = 0.2, flap = 0.5}
    WING_PRESETS.Cyber = {style = "cyber", a = C(0, 255, 225), b = C(255, 0, 200), glow = C(0, 255, 225), halo = false,
                          tex = SPARK, pulse = true, idle = 0.1, flap = 0.25}
    WING_PRESETS.Seraph = {style = "seraph", a = C(255, 255, 255), b = C(255, 225, 150), glow = C(255, 245, 210), halo = true, tex = SPARK}
    WING_PRESETS.Dragon = {style = "demon", a = C(25, 45, 25), b = C(30, 150, 60), glow = C(130, 255, 90), halo = false,
                           tex = FIRE, acc = Vector3.new(0, 2.4, 0), psize = 1.4, idle = 0.2, flap = 0.8}
    WING_PRESETS["Ice Dragon"] = {style = "demon", a = C(200, 230, 255), b = C(70, 140, 255), glow = C(150, 210, 255), halo = false,
                                  tex = SPARK, psize = 1.2, idle = 0.2, flap = 0.8}
    WING_PRESETS.Rainbow = {style = "feather", rainbow = true, a = C(255, 255, 255), b = C(255, 255, 255), glow = C(255, 255, 255),
                            halo = true, tex = SPARK, prate = 1.5}
    WING_PRESETS.Shadow = {style = "feather", a = C(45, 45, 55), b = C(12, 12, 18), glow = C(140, 70, 255), halo = false,
                           tex = "rbxasset://textures/particles/smoke_main.dds", acc = Vector3.new(0, 1.5, 0), psize = 1.6}
    WING_PRESETS.Mecha = {style = "cyber", a = C(255, 150, 20), b = C(70, 70, 80), glow = C(255, 180, 60), halo = false,
                          tex = SPARK, pulse = true, idle = 0.1, flap = 0.25}
end
local WING_NAMES = {"Angel", "Seraph", "Rainbow", "Frost", "Inferno", "Phoenix", "Galaxy", "Sakura", "Void", "Shadow", "Demon", "Dragon", "Ice Dragon", "Butterfly", "Crystal", "Cyber", "Mecha"}

local function newAuraState()
    return {char = nil, folder = nil, core = nil, haloWeld = nil, feathers = {}, emitters = {}, orbs = {},
            flaps = {}, tws = {}, cat = -1, gen = 0}
end
local aura = newAuraState()

local function removeAura()
    aura.gen += 1
    for _, tw in pairs(aura.tws or {}) do pcall(function() tw:Cancel() end) end
    if aura.folder then pcall(function() aura.folder:Destroy() end) end
    aura = newAuraState()
end

do
    local PI = math.pi
    local DEF = {y0 = 0.3, y1 = 0.3, ox = 0.28, oy = 0.6, oz = 0.56, tr = 0.1, t = 0, r = 1, th = 0.04}

    local function el(e)
        for k, v in pairs(DEF) do
            if e[k] == nil then e[k] = v end
        end
        if not e.mat then e.mat = Enum.Material.Neon end
        return e
    end

    local function mix(a, b, t) return a:Lerp(b, math.clamp(t, 0, 1)) end

    local GEN = {}

    function GEN.feather(P)
        local E = {}
        local rows = {
            {n = 7, len = 3.8, w = 0.7},
            {n = 6, len = 2.8, w = 0.62},
            {n = 5, len = 1.8, w = 0.55},
        }
        if P.tail then rows[#rows + 1] = {n = 4, len = 1.1, w = 0.5} end
        for r, row in ipairs(rows) do
            for i = 1, row.n do
                local t = (i - 1) / (row.n - 1)
                E[#E + 1] = el({
                    len = row.len * (1 - 0.35 * t), wid = row.w,
                    r0 = 1.28 - t * 0.55 - (r - 1) * 0.06, r1 = 1.15 - t * 1.95 - (r - 1) * 0.1,
                    y0 = 1.25, y1 = 0.6 + (r - 1) * 0.05,
                    oy = 0.62 - (r - 1) * 0.07,
                    color = mix(P.a, P.b, t * 0.65 + (r - 1) * 0.18), tr = 0.06 + (r - 1) * 0.06,
                    t = t, r = r, tip = (r == 1),
                })
            end
        end
        if P.tail then
            local lens = {5.2, 4.4, 3.6}
            for k = 1, 3 do
                E[#E + 1] = el({
                    len = lens[k], wid = 0.55, r0 = -1.1 - k * 0.12, r1 = -0.75 - k * 0.14,
                    y0 = 1.0, y1 = 0.7, oy = 0.1, color = mix(P.a, P.b, 0.4 + k * 0.2), tr = 0.1,
                    t = k / 3, r = 5,
                })
            end
        end
        return E
    end

    function GEN.seraph(P)
        local E = GEN.feather(P)
        local n = #E
        for i = 1, n do
            local e = E[i]
            local c = {}
            for k, v in pairs(e) do c[k] = v end
            c.len = e.len * 0.72
            c.oy = (e.oy or 0.6) - 0.8
            c.oz = (e.oz or 0.56) + 0.06
            c.r0 = -0.25 - math.abs(e.r0) * 0.45
            c.r1 = -0.35 - math.abs(e.r1) * 0.55
            c.tip = false
            E[#E + 1] = c
        end
        return E
    end

    function GEN.feather3d(P)
        local E = {}
        local rows = {
            {n = 7, len = 3.8, w = 0.74},
            {n = 6, len = 2.8, w = 0.66},
            {n = 5, len = 1.8, w = 0.58},
        }
        if P.tail then rows[#rows + 1] = {n = 4, len = 1.1, w = 0.52} end
        for r, row in ipairs(rows) do
            for i = 1, row.n do
                local t = (i - 1) / (row.n - 1)
                local len = row.len * (1 - 0.35 * t)
                local common = {
                    r0 = 1.28 - t * 0.55 - (r - 1) * 0.06, r1 = 1.15 - t * 1.95 - (r - 1) * 0.1,
                    y0 = 1.25, y1 = 0.6 + (r - 1) * 0.05,
                    oy = 0.62 - (r - 1) * 0.07, oz = 0.56 + (r - 1) * 0.1,
                    t = t, r = r,
                }
                local function add(over)
                    local e = {}
                    for k, v in pairs(common) do e[k] = v end
                    for k, v in pairs(over) do e[k] = v end
                    E[#E + 1] = el(e)
                end
                add({len = len, wid = row.w, th = 0.2, color = mix(P.a, P.b, t * 0.65 + (r - 1) * 0.18), tr = 0.03,
                     mat = Enum.Material.SmoothPlastic, tip = (r == 1)})
                add({len = len * 0.97, wid = 0.1, th = 0.3, color = P.glow, tr = 0.05, pulse = P.pulse})
                add({len = 0.5, wid = row.w * 0.9, th = 0.26, start = len - 0.5, color = mix(P.b, P.a, 0.3), tr = 0.03})
            end
        end
        return E
    end

    function GEN.demon(P)
        local E = {}
        local bone = P.a
        local ARM = 2.9
        E[1] = el({len = ARM, wid = 0.2, th = 0.2, r0 = 1.45, r1 = 1.0, y0 = 0.9, y1 = 0.5, oy = 0.7, oz = 0.58,
                   color = bone, tr = 0, mat = Enum.Material.Slate})
        local lens = {3.6, 4.0, 3.5, 2.7}
        local rel0 = {-0.18, -0.45, -0.72, -1.0}
        local rel1 = {-0.3, -0.85, -1.4, -1.95}
        local n = #lens
        for k = 1, n do
            E[#E + 1] = el({
                len = lens[k], wid = 0.11, th = 0.11, par = 1, plen = ARM, r0 = rel0[k], r1 = rel1[k], y0 = 0, y1 = 0,
                color = bone, tr = 0, mat = Enum.Material.Slate, t = k / n, r = 2, tip = true,
            })
            E[#E + 1] = el({
                len = lens[k] * 0.92, wid = 0.04, th = 0.14, par = 1, plen = ARM, r0 = rel0[k], r1 = rel1[k], y0 = 0, y1 = 0,
                color = P.glow, tr = 0.05, t = k / n, r = 2, pulse = P.pulse,
            })
        end
        for k = 1, n - 1 do
            local m0 = (rel0[k] + rel0[k + 1]) / 2
            local m1 = (rel1[k] + rel1[k + 1]) / 2
            local L = math.min(lens[k], lens[k + 1]) * 0.94
            local gap = math.abs(rel1[k + 1] - rel1[k])
            for s = 1, 4 do
                local rOut = L * s / 4
                E[#E + 1] = el({
                    len = L / 4 + 0.03, wid = 2 * rOut * math.sin(gap / 2), th = 0.025, start = L * (s - 1) / 4,
                    par = 1, plen = ARM, r0 = m0, r1 = m1, y0 = 0, y1 = 0, wvar = true,
                    color = mix(P.b, bone, (s - 1) / 6), tr = 0.16, t = k / n, r = 3,
                })
            end
        end
        E[#E + 1] = el({len = 0.9, wid = 0.1, th = 0.1, par = 1, plen = ARM, r0 = 0.55, r1 = 0.7, y0 = 0, y1 = 0,
                        color = bone, tr = 0, mat = Enum.Material.Slate, t = 0, r = 2})
        return E
    end

    function GEN.butterfly(P)
        local E = {}
        local up, lo = 9, 6
        for i = 1, up do
            local t = (i - 1) / (up - 1)
            E[#E + 1] = el({
                len = 1.8 + 2.0 * math.sin(t * PI * 0.9 + 0.15), wid = 0.95, th = 0.03,
                r0 = 1.55 - t * 0.25, r1 = 1.35 - t * 1.5, y0 = 0.55, y1 = 0.2, oy = 0.7,
                color = mix(P.a, P.b, t), tr = 0.1, t = t, r = 1, tip = true,
            })
        end
        for i = 1, lo do
            local t = (i - 1) / (lo - 1)
            E[#E + 1] = el({
                len = 1.3 + 1.3 * math.sin(t * PI * 0.9 + 0.2), wid = 0.85, th = 0.03,
                r0 = 1.3 - t * 0.2, r1 = -0.1 - t * 0.95, y0 = 0.65, y1 = 0.3, oy = 0.45,
                color = mix(P.b, P.a, t), tr = 0.14, t = t, r = 2,
            })
        end
        return E
    end

    function GEN.crystal(P)
        local E = {}
        local lens = {4.0, 3.2, 3.7, 2.7, 3.0, 2.0, 2.2}
        for i, len in ipairs(lens) do
            local t = (i - 1) / (#lens - 1)
            local r0, r1 = 1.3 - t * 0.45, 1.2 - t * 1.7
            E[#E + 1] = el({
                len = len, wid = 0.34, th = 0.16, r0 = r0, r1 = r1, y0 = 0.85, y1 = 0.3,
                color = mix(P.a, P.b, t), tr = 0.4, t = t, r = 1, tip = true,
            })
            E[#E + 1] = el({
                len = len * 0.92, wid = 0.08, th = 0.2, r0 = r0, r1 = r1, y0 = 0.85, y1 = 0.3,
                color = P.glow, tr = 0.05, t = t, r = 1,
            })
        end
        return E
    end

    function GEN.cyber(P)
        local E = {}
        local lens = {4.4, 3.8, 3.2, 2.6, 2.0}
        for i, len in ipairs(lens) do
            local t = (i - 1) / (#lens - 1)
            local r0, r1 = 1.3 - t * 0.4, 1.0 - t * 1.5
            local col = (i % 2 == 1) and P.a or P.b
            local idx = #E + 1
            E[idx] = el({
                len = len, wid = 0.3, th = 0.12, r0 = r0, r1 = r1, y0 = 0.85, y1 = 0.3,
                color = col, tr = 0.05, t = t, r = 1, tip = true, pulse = true,
            })
            E[#E + 1] = el({
                len = 1.3, wid = 0.22, th = 0.1, par = idx, plen = len, r0 = -0.75, r1 = -0.55, y0 = 0, y1 = 0,
                color = (i % 2 == 1) and P.b or P.a, tr = 0.05, t = t, r = 2, pulse = true,
            })
        end
        return E
    end

    local function auraPart(size, color, transp, parent)
        local p = Instance.new("Part")
        p.Size = size
        p.Color = color
        p.Material = Enum.Material.Neon
        p.Transparency = transp
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Massless = true
        p.Parent = parent
        return p
    end

    local function weld(p0, p1, c0, c1)
        local w = Instance.new("Weld")
        w.Part0, w.Part1 = p0, p1
        w.C0 = c0
        w.C1 = c1 or CFrame.new()
        w.Parent = p0
        return w
    end

    local function startFlap(a, dur)
        a.gen += 1
        local gen = a.gen
        for _, tw in pairs(a.tws) do pcall(function() tw:Cancel() end) end
        a.tws = {}
        for r, v in ipairs(a.flaps) do
            v.Value = 0
            local tw = TweenService:Create(v, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Value = 1})
            a.tws[r] = tw
            task.delay((r - 1) * dur * 0.14, function()
                if a.gen == gen and a.folder and a.folder.Parent then tw:Play() end
            end)
        end
    end

    local function buildAura(char)
        removeAura()
        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if not head or not torso then return end
        local old = char:FindFirstChild("ZenithAura")
        if old then old:Destroy() end
        local P = WING_PRESETS[CFG.wingPreset] or WING_PRESETS.Angel
        local gen = (P.style == "feather" and CFG.wings3d) and GEN.feather3d or (GEN[P.style] or GEN.feather)
        local list = gen(P)
        local folder = Instance.new("Folder")
        folder.Name = "ZenithAura"
        folder.Parent = char
        local emitters = {}
        local psize, prate = P.psize or 1, P.prate or 1

        local function emitter(parent, rate, size, life, speed, accel, spread, useP)
            local em = Instance.new("ParticleEmitter")
            em.Texture = P.tex or "rbxasset://textures/particles/sparkles_main.dds"
            em.Color = ColorSequence.new(P.glow, P.b)
            size = size * psize
            em.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, size),
                NumberSequenceKeypoint.new(0.5, size * 0.7),
                NumberSequenceKeypoint.new(1, 0),
            })
            em.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            })
            em.Lifetime = NumberRange.new(life * 0.7, life)
            rate = rate * prate
            em.Rate = rate
            em.Speed = NumberRange.new(speed * 0.4, speed)
            em.Acceleration = (useP and P.acc) or accel
            em.SpreadAngle = Vector2.new(spread, spread)
            em.Rotation = NumberRange.new(0, 360)
            em.RotSpeed = NumberRange.new(-80, 80)
            em.LightEmission = 1
            em.LightInfluence = 0
            em.Enabled = CFG.wingParticles
            em.Parent = parent
            emitters[#emitters + 1] = {em = em, rate = rate}
            return em
        end

        -- head anchor (halo + light)
        local core = auraPart(Vector3.new(0.2, 0.2, 0.2), P.a, 1, folder)
        local haloWeld = weld(head, core, CFrame.new(0, 1.15, 0))
        if P.halo then
            local n = 22
            for i = 1, n do
                local a = (i / n) * PI * 2
                local pos = Vector3.new(math.cos(a) * 0.8, 0, math.sin(a) * 0.8)
                local seg = auraPart(Vector3.new(0.14, 0.08, 0.34), P.glow, 0, folder)
                weld(core, seg, CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a))))
            end
        end
        local light = Instance.new("PointLight")
        light.Color = P.glow
        light.Brightness = 1.8
        light.Range = 12
        light.Parent = core
        emitter(core, 10, 0.28, 1.4, 1.0, Vector3.new(0, 1.2, 0), 180, false)

        -- glitter falling from the back
        local back = auraPart(Vector3.new(0.2, 0.2, 0.2), P.a, 1, folder)
        weld(torso, back, CFrame.new(0, 0.4, 0.7))
        emitter(back, 14, 0.26, 1.8, 1.4, Vector3.new(0, -1.2, 0), 120, true)

        -- wings
        local feathers = {}
        for _, side in ipairs({1, -1}) do
            local made, tips = {}, {}
            for idx, e in ipairs(list) do
                local part = auraPart(Vector3.new(e.len, e.wid, e.th), e.color, e.tr, folder)
                part.Material = e.mat
                local c1 = CFrame.new(-side * ((e.start or 0) + e.len / 2), 0, 0)
                local rt = {
                    w = weld(torso, part, CFrame.new(), c1),
                    e = e, side = side, part = part,
                    par = e.par and made[e.par] or nil,
                    C0 = CFrame.new(), zj = idx * 0.0025,
                }
                made[idx] = rt
                feathers[#feathers + 1] = rt
                if e.tip then
                    local att = Instance.new("Attachment")
                    att.Position = Vector3.new(side * e.len / 2, 0, 0)
                    att.Parent = part
                    tips[#tips + 1] = att
                end
            end
            local nt = #tips
            if nt >= 2 then
                for _, k in ipairs({1, math.ceil(nt / 2), nt}) do
                    emitter(tips[k], 7, 0.34, 1.1, 0.8, Vector3.new(0, -1.4, 0), 180, true)
                end
                local tr = Instance.new("Trail")
                tr.Attachment0, tr.Attachment1 = tips[1], tips[nt]
                tr.Lifetime = 0.45
                tr.MinLength = 0.05
                tr.LightEmission = 1
                tr.LightInfluence = 0
                tr.FaceCamera = true
                tr.Color = ColorSequence.new(P.glow, P.b)
                tr.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.5),
                    NumberSequenceKeypoint.new(1, 1),
                })
                tr.Enabled = CFG.wingParticles
                tr.Parent = tips[1].Parent
                emitters[#emitters + 1] = {trail = tr}
            end
        end

        -- orbiting orbs with trails
        local orbs = {}
        for i = 1, 5 do
            local o = auraPart(Vector3.new(0.3, 0.3, 0.3), P.glow, 0.1, folder)
            o.Shape = Enum.PartType.Ball
            local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
            a0.Position, a1.Position = Vector3.new(0, 0.15, 0), Vector3.new(0, -0.15, 0)
            a0.Parent, a1.Parent = o, o
            local tr = Instance.new("Trail")
            tr.Attachment0, tr.Attachment1 = a0, a1
            tr.Lifetime = 0.6
            tr.LightEmission = 1
            tr.LightInfluence = 0
            tr.FaceCamera = true
            tr.Color = ColorSequence.new(P.glow, P.b)
            tr.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(1, 1),
            })
            tr.Parent = o
            orbs[i] = {w = weld(torso, o, CFrame.new()), o = o, tr = tr, ph = i * PI * 2 / 5}
        end

        local openV = Instance.new("NumberValue")
        openV.Name = "Open"
        openV.Value = math.max(P.idle or 0, CFG.wingIdle)
        openV.Parent = folder
        local flaps = {}
        for r = 1, 5 do
            local v = Instance.new("NumberValue")
            v.Name = "Flap" .. r
            v.Parent = folder
            flaps[r] = v
        end
        aura = {char = char, folder = folder, core = core, haloWeld = haloWeld,
                feathers = feathers, emitters = emitters, orbs = orbs, P = P,
                openV = openV, flaps = flaps, tws = {}, cat = -1, gen = 0}
        for _, e in ipairs(emitters) do
            if e.em then pcall(function() e.em:Emit(10) end) end
        end
    end

    connect(RunService.Heartbeat, function()
        if not CFG.aura then
            if aura.folder then removeAura() end
            return
        end
        local c = lp.Character
        if not c then return end
        if aura.char ~= c or not aura.folder or not aura.folder.Parent then
            if c:FindFirstChild("Head") and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")) then
                pcall(buildAura, c)
            end
            return
        end
        local P = aura.P
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local speed = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
        local cat = aura.cat
        if CFG.fly then
            cat = 2
        elseif speed > 7 or (cat == 1 and speed > 3) then
            cat = 1
        else
            cat = 0
        end
        if cat ~= aura.cat then
            aura.cat = cat
            local tgt = math.max(cat == 2 and 1 or (cat == 1 and 0.5 or 0), P.idle or 0, CFG.wingIdle)
            TweenService:Create(aura.openV, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = tgt}):Play()
            startFlap(aura, ({0.9, 0.5, 0.3})[cat + 1] / CFG.auraSpeed)
        end
        local open = math.clamp(aura.openV.Value, 0, 1.1)
        local now = tick()
        local t = now * CFG.auraSpeed
        local amp = (0.05 + open * 0.26) * (P.flap or 1)

        aura.haloWeld.C0 = CFrame.new(0, 1.15 + math.sin(t * 2) * 0.06, 0) * CFrame.Angles(0, t * 2, 0)

        for _, rt in ipairs(aura.feathers) do
            local e, side = rt.e, rt.side
            local f = aura.flaps[math.min(e.r, 5)].Value * 2 - 1
            local wave = f * amp * (0.5 + e.t * 0.9)
            if e.par then wave *= 0.5 end
            local roll = e.r0 + (e.r1 - e.r0) * open + wave
            local yaw = e.y0 + (e.y1 - e.y0) * open + f * amp * 0.25
            local c0
            if rt.par then
                c0 = rt.par.C0 * CFrame.new(side * e.plen, 0, rt.zj) * CFrame.Angles(0, -side * yaw, side * roll)
            else
                c0 = CFrame.new(side * (e.ox + CFG.wingX), e.oy + CFG.wingY, e.oz + CFG.wingZ + rt.zj) * CFrame.Angles(0, -side * (yaw + CFG.wingYaw), side * roll)
            end
            rt.C0 = c0
            rt.w.C0 = c0
            if e.wvar then
                local k = 0.4 + 0.6 * open
                if not rt.k or math.abs(k - rt.k) > 0.02 then
                    rt.k = k
                    rt.part.Size = Vector3.new(e.len, e.wid * k, e.th)
                end
            end
            if e.pulse then
                rt.part.Transparency = e.tr + (1 - e.tr) * 0.5 * (0.5 + 0.5 * math.sin(now * 3 - e.t * 5))
            end
            if P.rainbow then
                rt.part.Color = Color3.fromHSV((now * 0.2 + e.t * 0.35 + (e.r or 1) * 0.1) % 1, 0.75, 1)
            end
        end

        local ot = now * 1.4
        for _, ob in ipairs(aura.orbs) do
            local a = ot + ob.ph
            ob.w.C0 = CFrame.new(math.cos(a) * 2.4, math.sin(ot * 1.3 + ob.ph * 2) * 1.3, math.sin(a) * 2.4)
            ob.o.Transparency = CFG.wingOrbs and 0.1 or 1
            ob.tr.Enabled = CFG.wingOrbs
        end

        for _, e in ipairs(aura.emitters) do
            if e.em then
                e.em.Enabled = CFG.wingParticles
                e.em.Rate = e.rate * (0.5 + open * 2.2)
            elseif e.trail then
                e.trail.Enabled = CFG.wingParticles and open > 0.15
            end
        end
    end)
end

local HELPER_NAMES = {"Fairy", "Bat", "Orb"}
local helper = {}

local function removeHelper()
    if helper.folder then pcall(function() helper.folder:Destroy() end) end
    helper = {}
end

do
    local function hpart(size, color, tr, ball, mat)
        local p = Instance.new("Part")
        p.Size = size
        p.Color = color
        p.Transparency = tr
        p.Material = mat or Enum.Material.Neon
        if ball then p.Shape = Enum.PartType.Ball end
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        return p
    end

    local function buildHelper()
        removeHelper()
        local P = WING_PRESETS[CFG.wingPreset] or WING_PRESETS.Angel
        local S = CFG.helperSize
        local style = CFG.helperStyle
        local folder = Instance.new("Folder")
        folder.Name = "ZenithHelper"
        folder.Parent = workspace
        local rel = {}
        local function add(part, cf, kind, side, len, ph)
            part.Parent = folder
            rel[#rel + 1] = {p = part, cf = cf, kind = kind or "fix", side = side or 1, len = len or 1, ph = ph or 0}
            return part
        end
        local black = Color3.fromRGB(8, 8, 12)
        local body

        if style == "Bat" then
            body = add(hpart(Vector3.new(0.9, 0.8, 0.9) * S, Color3.fromRGB(30, 8, 18), 0, true, Enum.Material.SmoothPlastic), CFrame.new())
            for _, sd in ipairs({1, -1}) do
                add(hpart(Vector3.new(0.16, 0.2, 0.16) * S, Color3.fromRGB(255, 40, 40), 0, true),
                    CFrame.new(sd * 0.2 * S, 0.1 * S, -0.4 * S))
                add(hpart(Vector3.new(0.16, 0.5, 0.16) * S, Color3.fromRGB(20, 5, 10), 0, false, Enum.Material.SmoothPlastic),
                    CFrame.new(sd * 0.28 * S, 0.5 * S, -0.05 * S) * CFrame.Angles(0, 0, -sd * 0.35))
                for k = 1, 2 do
                    local len = (k == 1 and 1.7 or 1.2) * S
                    add(hpart(Vector3.new(len, 0.8 * S, 0.03), P.b, 0.15, false),
                        CFrame.new(sd * 0.4 * S, (k == 1 and 0.2 or -0.1) * S, 0.2 * S) * CFrame.Angles(0, -sd * 0.5, 0),
                        "wing", sd, len, k)
                end
            end
        elseif style == "Orb" then
            body = add(hpart(Vector3.new(1.1, 1.1, 1.1) * S, P.glow, 0.05, true), CFrame.new())
            add(hpart(Vector3.new(0.5, 0.5, 0.5) * S, Color3.new(1, 1, 1), 0, true, Enum.Material.SmoothPlastic),
                CFrame.new(0, 0, -0.45 * S))
            add(hpart(Vector3.new(0.24, 0.24, 0.24) * S, black, 0, true, Enum.Material.SmoothPlastic),
                CFrame.new(0, 0, -0.66 * S))
            for k = 1, 3 do
                add(hpart(Vector3.new(0.22, 0.22, 0.22) * S, P.a, 0.1, true), CFrame.new(), "orbit", 1, 1.0 * S, k * 2.1)
            end
        else
            body = add(hpart(Vector3.new(0.8, 0.8, 0.8) * S, P.glow, 0, true), CFrame.new())
            for _, sd in ipairs({1, -1}) do
                add(hpart(Vector3.new(0.14, 0.18, 0.14) * S, black, 0, true, Enum.Material.SmoothPlastic),
                    CFrame.new(sd * 0.17 * S, 0.08 * S, -0.34 * S))
                for k = 1, 2 do
                    local len = (k == 1 and 1.5 or 1.0) * S
                    add(hpart(Vector3.new(len, 0.7 * S, 0.03), k == 1 and P.a or P.b, 0.3, false),
                        CFrame.new(sd * 0.3 * S, (k == 1 and 0.2 or -0.05) * S, 0.15 * S) * CFrame.Angles(0, -sd * 0.5, 0),
                        "wing", sd, len, k)
                end
            end
            add(hpart(Vector3.new(0.18, 0.18, 0.18) * S, P.a, 0, true), CFrame.new(0, 0.55 * S, 0))
        end

        local em = Instance.new("ParticleEmitter")
        em.Texture = P.tex or "rbxasset://textures/particles/sparkles_main.dds"
        em.Color = ColorSequence.new(P.glow, P.b)
        em.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35 * S),
            NumberSequenceKeypoint.new(1, 0),
        })
        em.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        em.Lifetime = NumberRange.new(0.6, 1.1)
        em.Rate = 22
        em.Speed = NumberRange.new(0.2, 1)
        em.SpreadAngle = Vector2.new(180, 180)
        em.LightEmission = 1
        em.LightInfluence = 0
        em.Parent = body

        local light = Instance.new("PointLight")
        light.Color = P.glow
        light.Brightness = 1.5
        light.Range = 9
        light.Parent = body

        local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
        a0.Position, a1.Position = Vector3.new(0, 0.3 * S, 0.2 * S), Vector3.new(0, -0.3 * S, 0.2 * S)
        a0.Parent, a1.Parent = body, body
        local tr = Instance.new("Trail")
        tr.Attachment0, tr.Attachment1 = a0, a1
        tr.Lifetime = 0.7
        tr.LightEmission = 1
        tr.LightInfluence = 0
        tr.FaceCamera = true
        tr.Color = ColorSequence.new(P.glow, P.b)
        tr.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        tr.Parent = body

        local flapV = Instance.new("NumberValue")
        flapV.Name = "Flap"
        flapV.Parent = folder
        TweenService:Create(flapV, TweenInfo.new(0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Value = 1}):Play()

        helper = {folder = folder, rel = rel, pos = nil, cf = nil, flapV = flapV}
    end

    connect(RunService.Heartbeat, function(dt)
        if not CFG.helper then
            if helper.folder then removeHelper() end
            return
        end
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not helper.folder or not helper.folder.Parent then
            pcall(buildHelper)
            return
        end
        local t = os.clock()
        local hp = hrp.Position
        local a = t * 0.7
        local target = hp + Vector3.new(math.cos(a) * 3.6, 2.9 + math.sin(t * 2.1) * 0.45, math.sin(a) * 3.6)
        local old = helper.pos or target
        if (old - hp).Magnitude > 60 then old = target end
        local pos = old:Lerp(target, 1 - math.exp(-dt * 4.5))
        local vel = (pos - old) / math.max(dt, 1e-3)
        helper.pos = pos
        local lookAt = (vel.Magnitude > 4) and (pos + vel) or (hp + Vector3.new(0, 1.5, 0))
        local cf = CFrame.lookAt(pos, lookAt)
        helper.cf = helper.cf and helper.cf:Lerp(cf, 1 - math.exp(-dt * 8)) or cf
        local base = helper.cf
        for _, r in ipairs(helper.rel) do
            if r.kind == "wing" then
                local fv = helper.flapV.Value
                if r.ph == 2 then fv = 1 - fv end
                local fl = (fv * 2 - 1) * 0.55
                r.p.CFrame = base * r.cf * CFrame.Angles(0, 0, r.side * fl) * CFrame.new(r.side * r.len / 2, 0, 0)
            elseif r.kind == "orbit" then
                local o = t * 3 + r.ph
                r.p.CFrame = base * CFrame.new(math.cos(o) * r.len, math.sin(t * 2 + r.ph) * 0.3, math.sin(o) * r.len)
            else
                r.p.CFrame = base * r.cf
            end
        end
    end)
end

do
    local folder
    local cosChar, lastSig
    local fx = {}

    local function clear()
        if folder then pcall(function() folder:Destroy() end) end
        folder = nil
        fx = {}
        cosChar = nil
    end
    FX.clearCos = clear

    local function C(r, g, b) return Color3.fromRGB(r, g, b) end
    local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
    local FIRE = "rbxasset://textures/particles/fire_main.dds"
    local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

    local ELEM = {
        Fire = {tex = FIRE, c1 = C(255, 200, 60), c2 = C(255, 60, 20), size = 1.8, rate = 45, life = 1, speed = 2, acc = Vector3.new(0, 4, 0), emis = 1, flicker = true},
        Ice = {tex = SPARK, c1 = C(210, 245, 255), c2 = C(80, 160, 255), size = 0.7, rate = 35, life = 1.4, speed = 1, acc = Vector3.new(0, -1, 0), emis = 1},
        Electric = {tex = SPARK, c1 = C(255, 255, 150), c2 = C(110, 190, 255), size = 0.5, rate = 70, life = 0.5, speed = 4, acc = Vector3.zero, emis = 1, flicker = true},
        Toxic = {tex = SMOKE, c1 = C(120, 255, 90), c2 = C(30, 140, 40), size = 2.2, rate = 30, life = 1.2, speed = 1, acc = Vector3.new(0, 2, 0), emis = 0.3},
        Shadow = {tex = SMOKE, c1 = C(90, 40, 140), c2 = C(15, 5, 30), size = 2.4, rate = 35, life = 1.3, speed = 1, acc = Vector3.new(0, 2.5, 0), emis = 0},
        Stars = {tex = SPARK, c1 = C(255, 240, 150), c2 = C(255, 180, 60), size = 0.8, rate = 30, life = 1.5, speed = 1, acc = Vector3.new(0, 1, 0), emis = 1},
        Holy = {tex = SPARK, c1 = C(255, 255, 255), c2 = C(255, 225, 140), size = 0.9, rate = 40, life = 1.6, speed = 1.2, acc = Vector3.new(0, 2.5, 0), emis = 1},
    }
    FX.ELEM_NAMES = {"Fire", "Ice", "Electric", "Toxic", "Shadow", "Stars", "Holy"}
    local AURA = {
        ["Super Saiyan"] = {c1 = C(255, 235, 90), c2 = C(255, 165, 25), bolts = true},
        ["Ultra Instinct"] = {c1 = C(230, 240, 255), c2 = C(120, 160, 255), bolts = true},
        ["Dark"] = {c1 = C(160, 70, 255), c2 = C(35, 0, 70)},
        ["Blood"] = {c1 = C(255, 70, 70), c2 = C(120, 0, 0)},
        ["Toxic"] = {c1 = C(140, 255, 90), c2 = C(20, 120, 30)},
        ["Rainbow"] = {c1 = C(255, 255, 255), c2 = C(255, 255, 255), rainbow = true, bolts = true},
    }
    FX.AURA_NAMES = {"Super Saiyan", "Ultra Instinct", "Dark", "Blood", "Toxic", "Rainbow"}

    local function weldTo(p0, p1, c0)
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.C0 = p0, p1, c0
        w.Parent = p0
        return w
    end

    local function mkPart(size, color, transp, shape, mat)
        local p = Instance.new("Part")
        p.Size, p.Color, p.Transparency = size, color, transp
        p.Material = mat or Enum.Material.Neon
        p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
        if shape then p.Shape = shape end
        p.Parent = folder
        return p
    end

    local function emitter(parent, o)
        local em = Instance.new("ParticleEmitter")
        em.Texture = o.tex or SPARK
        em.Color = ColorSequence.new(o.c1 or C(255, 255, 255), o.c2 or o.c1 or C(255, 255, 255))
        local sz = o.size or 0.5
        em.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, sz),
            NumberSequenceKeypoint.new(0.6, sz * 0.7),
            NumberSequenceKeypoint.new(1, 0),
        })
        em.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, o.t0 or 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        em.Lifetime = NumberRange.new((o.life or 1) * 0.6, o.life or 1)
        em.Rate = o.rate or 10
        em.Speed = NumberRange.new((o.speed or 1) * 0.4, o.speed or 1)
        em.Acceleration = o.acc or Vector3.zero
        em.SpreadAngle = o.spread or Vector2.new(180, 180)
        em.Rotation = NumberRange.new(0, 360)
        em.RotSpeed = NumberRange.new(-90, 90)
        em.LightEmission = o.emis or 1
        em.LightInfluence = 0
        if o.dir then em.EmissionDirection = o.dir end
        em.Parent = parent
        return em
    end

    local function light(parent, color, bright, range)
        local l = Instance.new("PointLight")
        l.Color, l.Brightness, l.Range, l.Shadows = color, bright, range, false
        l.Parent = parent
        return l
    end

    local function ring(core, radius, count, size, color, mat, transp)
        local segs = {}
        for i = 1, count do
            local a = (i / count) * math.pi * 2
            local pos = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
            local seg = mkPart(size, color, transp or 0.05, nil, mat)
            weldTo(core, seg, CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a))))
            segs[#segs + 1] = seg
        end
        return segs
    end

    local function build(char)
        clear()
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        folder = Instance.new("Folder")
        folder.Name = "ZenithCos"
        folder.Parent = char
        cosChar = char
        local col = colorOf(CFG.glowColor)

        if CFG.bodyGlow then
            local hl = Instance.new("Highlight")
            hl.Adornee = char
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0
            hl.Parent = folder
            fx.hl = hl
            local core = mkPart(Vector3.new(0.2, 0.2, 0.2), col, 1)
            weldTo(hrp, core, CFrame.new())
            fx.glowLight = light(core, col, 1.4, 12)
        end

        if CFG.crown then
            local core = mkPart(Vector3.new(0.2, 0.2, 0.2), GOLD, 1)
            fx.crownW = weldTo(head, core, CFrame.new(0, 0.62, 0))
            local gold = C(255, 205, 60)
            ring(core, 0.62, 18, Vector3.new(0.22, 0.3, 0.32), gold, Enum.Material.Metal, 0)
            local trim = mkPart(Vector3.new(0.2, 0.2, 0.2), gold, 1)
            weldTo(core, trim, CFrame.new(0, 0.17, 0))
            ring(trim, 0.64, 18, Vector3.new(0.08, 0.06, 0.3), C(255, 240, 170), nil, 0)
            for i = 1, 6 do
                local a = (i / 6) * math.pi * 2
                local pos = Vector3.new(math.cos(a) * 0.62, 0.42, math.sin(a) * 0.62)
                local spike = mkPart(Vector3.new(0.16, 0.55, 0.16), gold, 0, nil, Enum.Material.Metal)
                weldTo(core, spike, CFrame.new(pos))
                local tip = mkPart(Vector3.new(0.16, 0.16, 0.16), C(255, 240, 170), 0, Enum.PartType.Ball)
                weldTo(core, tip, CFrame.new(pos + Vector3.new(0, 0.33, 0)))
                local gem = mkPart(Vector3.new(0.17, 0.17, 0.17), ({C(255, 60, 120), C(70, 160, 255), C(80, 255, 140)})[i % 3 + 1], 0.05, Enum.PartType.Ball)
                weldTo(core, gem, CFrame.new(pos * Vector3.new(1.06, 0, 1.06) + Vector3.new(0, -0.3, 0)))
            end
            light(core, C(255, 215, 130), 1.2, 8)
            emitter(core, {tex = SPARK, c1 = C(255, 245, 190), c2 = C(255, 190, 80), size = 0.22, rate = 7, life = 1.2, speed = 0.6, acc = Vector3.new(0, 0.6, 0)})
        end

        if CFG.groundRing then
            local rc = colorOf(CFG.ringColor)
            local coreA = mkPart(Vector3.new(0.2, 0.2, 0.2), rc, 1)
            fx.ringAW = weldTo(hrp, coreA, CFrame.new(0, -2.95, 0))
            fx.ringA = ring(coreA, 3.2, 32, Vector3.new(0.12, 0.06, 0.65), rc)
            local coreB = mkPart(Vector3.new(0.2, 0.2, 0.2), rc, 1)
            fx.ringBW = weldTo(hrp, coreB, CFrame.new(0, -2.92, 0))
            fx.ringB = ring(coreB, 2.3, 24, Vector3.new(0.1, 0.05, 0.6), rc)
            local disc = mkPart(Vector3.new(0.05, 6.6, 6.6), rc, 0.85, Enum.PartType.Cylinder)
            weldTo(hrp, disc, CFrame.new(0, -3.0, 0) * CFrame.Angles(0, 0, math.rad(90)))
            fx.disc = disc
            local src = mkPart(Vector3.new(6, 0.1, 6), rc, 1)
            weldTo(hrp, src, CFrame.new(0, -2.9, 0))
            fx.ringEm = emitter(src, {tex = SPARK, c1 = rc, size = 0.3, rate = 18, life = 1.4, speed = 1.5,
                acc = Vector3.new(0, 2, 0), spread = Vector2.new(10, 10), dir = Enum.NormalId.Top})
            fx.ringLight = light(coreA, rc, 1.6, 10)
        end

        if CFG.elemAura then
            local p = ELEM[CFG.elemType] or ELEM.Fire
            local body = mkPart(Vector3.new(2.2, 4.6, 1.4), C(255, 255, 255), 1)
            weldTo(hrp, body, CFrame.new(0, -0.3, 0))
            emitter(body, {tex = p.tex, c1 = p.c1, c2 = p.c2, size = p.size, rate = p.rate, life = p.life,
                speed = p.speed, acc = p.acc, emis = p.emis})
            emitter(body, {tex = SPARK, c1 = p.c1, c2 = p.c2, size = 0.25, rate = p.rate * 0.4, life = 0.8, speed = 2.5})
            fx.elemLight = light(body, p.c1, 1.3, 11)
            fx.elemFlicker = p.flicker
        end

        if CFG.powerAura then
            local st = AURA[CFG.auraStyle] or AURA["Super Saiyan"]
            local body = mkPart(Vector3.new(2.6, 5.2, 1.8), C(255, 255, 255), 1)
            weldTo(hrp, body, CFrame.new(0, -0.2, 0))
            fx.pa = {}
            fx.pa[1] = emitter(body, {tex = FIRE, c1 = st.c1, c2 = st.c2, size = 2.4, rate = 60, life = 0.9, speed = 6,
                acc = Vector3.new(0, 10, 0), spread = Vector2.new(8, 8), dir = Enum.NormalId.Top, t0 = 0.35})
            fx.pa[2] = emitter(body, {tex = SPARK, c1 = st.c2, c2 = st.c1, size = 0.4, rate = 40, life = 0.6, speed = 10,
                acc = Vector3.new(0, 14, 0), spread = Vector2.new(5, 5), dir = Enum.NormalId.Top})
            local base = mkPart(Vector3.new(5, 0.1, 5), st.c1, 1)
            weldTo(hrp, base, CFrame.new(0, -2.9, 0))
            fx.pa[3] = emitter(base, {tex = SMOKE, c1 = st.c1, c2 = st.c2, size = 2, rate = 12, life = 1.2, speed = 3,
                acc = Vector3.new(0, 2, 0), spread = Vector2.new(80, 80), dir = Enum.NormalId.Top, emis = 0.5, t0 = 0.5})
            if st.bolts then
                fx.pa[4] = emitter(body, {tex = SPARK, c1 = C(255, 255, 255), c2 = st.c1, size = 0.6, rate = 25, life = 0.25, speed = 8})
            end
            fx.paLight = light(body, st.c1, 2, 14)
            fx.paStyle = st
        end

        if CFG.nameTag then
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 240, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3.4, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = head
            bb.Parent = folder
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Font = Enum.Font.GothamBlack
            tl.TextSize = 26
            tl.Text = (CFG.nameTagText ~= "" and CFG.nameTagText) or "Zenith"
            tl.TextColor3 = C(255, 255, 255)
            tl.Parent = bb
            local st = Instance.new("UIStroke")
            st.Thickness = 1.6
            st.Color = C(0, 0, 0)
            st.Transparency = 0.15
            st.Parent = tl
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C(255, 80, 120)),
                ColorSequenceKeypoint.new(0.25, C(255, 200, 80)),
                ColorSequenceKeypoint.new(0.5, C(90, 255, 160)),
                ColorSequenceKeypoint.new(0.75, C(80, 160, 255)),
                ColorSequenceKeypoint.new(1, C(200, 90, 255)),
            })
            g.Parent = tl
            fx.tagGrad = g
        end

        if CFG.orbitStars then
            fx.stars = {}
            for i = 1, 6 do
                local o = mkPart(Vector3.new(0.35, 0.35, 0.35), col, 0.05, Enum.PartType.Ball)
                local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
                a0.Position, a1.Position = Vector3.new(0, 0.17, 0), Vector3.new(0, -0.17, 0)
                a0.Parent, a1.Parent = o, o
                local tr = Instance.new("Trail")
                tr.Attachment0, tr.Attachment1 = a0, a1
                tr.Lifetime = 0.5
                tr.LightEmission = 1
                tr.LightInfluence = 0
                tr.FaceCamera = true
                tr.Transparency = NumberSequence.new(0.2, 1)
                tr.Parent = o
                fx.stars[i] = {o = o, tr = tr, w = weldTo(hrp, o, CFrame.new()), ph = i * math.pi * 2 / 6,
                    r = 2.2 + (i % 2) * 0.8, h = (i % 3 - 1) * 1.1}
            end
        end

        if CFG.auraSphere then
            local sp = mkPart(Vector3.new(7.5, 7.5, 7.5), col, 0.35, Enum.PartType.Ball, Enum.Material.ForceField)
            fx.sphereW = weldTo(hrp, sp, CFrame.new(0, -0.2, 0))
            fx.sphere = sp
        end

        if CFG.footSparkle then
            local f = mkPart(Vector3.new(1.6, 0.2, 1.2), col, 1)
            weldTo(hrp, f, CFrame.new(0, -2.85, 0))
            fx.foot = emitter(f, {tex = SPARK, c1 = col, c2 = C(255, 255, 255), size = 0.35, rate = 35, life = 0.8,
                speed = 1.2, acc = Vector3.new(0, 1.5, 0)})
            fx.footHrp = hrp
        end
    end

    connect(RunService.Heartbeat, function()
        local c = lp.Character
        local want = CFG.bodyGlow or CFG.crown or CFG.groundRing or CFG.elemAura or CFG.nameTag
            or CFG.orbitStars or CFG.auraSphere or CFG.footSparkle or CFG.powerAura
        if not want then
            if folder then clear() end
            lastSig = nil
            return
        end
        if not c or not c:FindFirstChild("Head") or not c:FindFirstChild("HumanoidRootPart") then return end
        local sg = table.concat({tostring(CFG.bodyGlow), tostring(CFG.crown), tostring(CFG.groundRing),
            tostring(CFG.elemAura), CFG.elemType, tostring(CFG.nameTag), CFG.nameTagText,
            tostring(CFG.orbitStars), tostring(CFG.auraSphere), tostring(CFG.footSparkle),
            tostring(CFG.powerAura), CFG.auraStyle}, "|")
        if cosChar ~= c or not folder or not folder.Parent or sg ~= lastSig then
            lastSig = sg
            pcall(build, c)
            return
        end
        local now = tick()
        local col = colorOf(CFG.glowColor)
        if fx.hl then
            fx.hl.FillColor, fx.hl.OutlineColor = col, col
            fx.hl.FillTransparency = 0.62 + 0.18 * math.sin(now * 3)
        end
        if fx.glowLight then fx.glowLight.Color = col end
        if fx.crownW then
            fx.crownW.C0 = CFrame.new(0, 0.62 + math.sin(now * 2) * 0.03, 0) * CFrame.Angles(0, now * 0.6, 0)
        end
        if fx.ringAW then
            local rc = colorOf(CFG.ringColor)
            fx.ringAW.C0 = CFrame.new(0, -2.95, 0) * CFrame.Angles(0, now * 1.4, 0)
            fx.ringBW.C0 = CFrame.new(0, -2.92, 0) * CFrame.Angles(0, -now * 2.1, 0)
            local pulse = 0.5 + 0.5 * math.sin(now * 3)
            for _, sg2 in ipairs(fx.ringA) do
                sg2.Color = rc
                sg2.Transparency = 0.05 + 0.3 * pulse
            end
            for _, sg2 in ipairs(fx.ringB) do
                sg2.Color = rc
                sg2.Transparency = 0.35 - 0.3 * pulse
            end
            fx.disc.Color = rc
            fx.disc.Transparency = 0.82 + 0.08 * math.sin(now * 2)
            fx.ringEm.Color = ColorSequence.new(rc)
            fx.ringLight.Color = rc
        end
        if fx.elemLight and fx.elemFlicker then
            fx.elemLight.Brightness = 1 + math.random() * 0.8
        end
        if fx.tagGrad then
            fx.tagGrad.Offset = Vector2.new(math.sin(now * 1.2) * 0.5, 0)
        end
        if fx.stars then
            for i, st in ipairs(fx.stars) do
                local a = now * 1.6 + st.ph
                st.w.C0 = CFrame.new(math.cos(a) * st.r, st.h + math.sin(now * 2 + st.ph) * 0.4, math.sin(a) * st.r)
                local sc = col
                if CFG.glowColor == "Rainbow" then sc = Color3.fromHSV((now * 0.25 + i / 6) % 1, 0.8, 1) end
                st.o.Color = sc
                st.tr.Color = ColorSequence.new(sc)
            end
        end
        if fx.sphere then
            fx.sphere.Color = col
            local k = 7.5 + math.sin(now * 2) * 0.3
            fx.sphere.Size = Vector3.new(k, k, k)
            fx.sphereW.C0 = CFrame.new(0, -0.2, 0) * CFrame.Angles(now * 0.3, now * 0.5, 0)
        end
        if fx.paLight then
            fx.paLight.Brightness = 1.6 + math.random() * 0.9
            if fx.paStyle and fx.paStyle.rainbow then
                local a = Color3.fromHSV((now * 0.3) % 1, 0.8, 1)
                local b = Color3.fromHSV((now * 0.3 + 0.15) % 1, 0.9, 1)
                for _, em in pairs(fx.pa) do em.Color = ColorSequence.new(a, b) end
                fx.paLight.Color = a
            end
        end
        if fx.foot and fx.footHrp then
            local v = fx.footHrp.AssemblyLinearVelocity
            fx.foot.Enabled = Vector3.new(v.X, 0, v.Z).Magnitude > 2
            fx.foot.Color = ColorSequence.new(col, Color3.new(1, 1, 1))
        end
    end)
end

local UIS = game:GetService("UserInputService")

do
local function hasCoinBox(m, deep)
    for _, d in ipairs(deep and m:GetDescendants() or m:GetChildren()) do
        if (d:IsA("Model") or d:IsA("Folder")) and FX.coinish(d.Name) and string.find(string.lower(d.Name), "container", 1, true) then
            return true
        end
    end
    return false
end
FX.hasCoinBox = hasCoinBox
local function findMap()
    for _, root in ipairs({workspace, RunService}) do
        for _, ch in ipairs(root:GetChildren()) do
            if (ch:IsA("Model") or ch:IsA("Folder")) and hasCoinBox(ch, false) then return ch end
        end
    end
    for _, root in ipairs({workspace, RunService}) do
        for _, ch in ipairs(root:GetChildren()) do
            if (ch:IsA("Model") or ch:IsA("Folder")) and not Players:GetPlayerFromCharacter(ch) and hasCoinBox(ch, true) then
                return ch
            end
        end
    end
end

local function findLobby()
    local l = workspace:FindFirstChild("Lobby")
    if l then return l end
    for _, ch in ipairs(workspace:GetChildren()) do
        if (ch:IsA("Model") or ch:IsA("Folder")) and ch.Name:lower():find("lobby", 1, true) then return ch end
    end
end

local function spawnPoints(container)
    local list = {}
    if not container then return list end
    local sf = container:FindFirstChild("Spawns", true)
    local scan = sf or container
    for _, d in ipairs(scan:GetDescendants()) do
        if d:IsA("SpawnLocation") or (sf and d:IsA("BasePart")) then list[#list + 1] = d end
    end
    return list
end

local function destCF(container)
    if not container then return nil end
    local pts = spawnPoints(container)
    if #pts > 0 then
        return pts[math.random(#pts)].CFrame + Vector3.new(0, 4, 0)
    end
    local base = container:FindFirstChild("Base", true)
    if base and base:IsA("BasePart") then return base.CFrame + Vector3.new(0, 6, 0) end
    local ok, pv = pcall(function() return container:GetPivot() end)
    if ok then return pv + Vector3.new(0, 8, 0) end
end

local function tpTo(cf)
    if not cf then return false end
    local hrp = myHrp()
    if not hrp then return false end
    if holding then surface() end
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function tpLobby()
    local cf = destCF(findLobby())
    if not cf then
        local m = findMap()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("SpawnLocation") and not (m and d:IsDescendantOf(m)) then
                cf = d.CFrame + Vector3.new(0, 4, 0)
                break
            end
        end
    end
    return tpTo(cf)
end

local function tpMap()
    return tpTo(destCF(findMap()))
end


task.spawn(function()
    local lastMap
    local busySince = 0
    while running do
        pcall(function()
            local m = findMap()
            if m ~= lastMap then
                lastMap = m
                if m then
                    table.clear(visited)
                    table.clear(danger)
                    table.clear(cooldown)
                    got = 0
                end
            end
        end)
        if busy then
            if busySince == 0 then
                busySince = tick()
            elseif tick() - busySince > 40 then
                busy, picking, busySince = false, false, 0
                pcall(hold, false)
            end
        else
            busySince = 0
        end
        task.wait(0.5)
    end
end)

local ncSaved = {}
connect(PRE_SIM, function()
    if not CFG.noclip then
        if next(ncSaved) then
            for part in pairs(ncSaved) do
                if part.Parent then part.CanCollide = true end
            end
            table.clear(ncSaved)
        end
        return
    end
    local c = lp.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            ncSaved[p] = true
            p.CanCollide = false
        end
    end
end)

local fly = {bv = nil, bg = nil, ctrl = nil}
local function flyStop()
    if fly.bv then pcall(function() fly.bv:Destroy() end) end
    if fly.bg then pcall(function() fly.bg:Destroy() end) end
    fly.bv, fly.bg = nil, nil
    local _, hum = myHrp()
    if hum then hum.PlatformStand = false end
end

task.spawn(function()
    local ok, c = pcall(function()
        local pm = lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
        return require(pm):GetControls()
    end)
    fly.ctrl = ok and c or false
end)

local function moveVec()
    if fly.ctrl then
        local ok, v = pcall(function() return fly.ctrl:GetMoveVector() end)
        if ok and typeof(v) == "Vector3" and v.Magnitude > 0 then return v end
    end
    local x = (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
    local z = (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
    return Vector3.new(x, 0, z)
end

connect(PRE_RENDER, function()
    if not CFG.fly or holding or picking then
        if fly.bv then flyStop() end
        return
    end
    local hrp, hum = myHrp()
    if not hrp or not hum or hum.Health <= 0 then return end
    if not fly.bv or fly.bv.Parent ~= hrp then
        flyStop()
        local bv = Instance.new("BodyVelocity")
        bv.Name = "ZenithFly"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.P = 1e4
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "ZenithFlyGyro"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P = 1e5
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        fly.bv, fly.bg = bv, bg
    end
    hum.PlatformStand = true
    local c0 = workspace.CurrentCamera
    local mv = moveVec()
    local dir = c0.CFrame.LookVector * -mv.Z + c0.CFrame.RightVector * mv.X
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
    local target = dir.Magnitude > 0.05 and dir.Unit * CFG.flySpeed or Vector3.zero
    fly.bv.Velocity = fly.bv.Velocity:Lerp(target, 0.35)
    local look = c0.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if CFG.spinOn then
        fly.bg.MaxTorque = Vector3.zero
    else
        fly.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        if flat.Magnitude > 0.01 then
            fly.bg.CFrame = CFrame.new(hrp.Position, hrp.Position + flat)
        end
    end
end)

-- bunny hop
connect(PRE_SIM, function()
    if not CFG.bhop or CFG.fly or holding or busy then return end
    local hrp, hum = myHrp()
    if not hrp or not hum or hum.Health <= 0 then return end
    local md = hum.MoveDirection
    if md.Magnitude < 0.1 then return end
    if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    local v = hrp.AssemblyLinearVelocity
    local flat = Vector3.new(v.X, 0, v.Z):Lerp(md.Unit * CFG.bhopSpeed, 0.3)
    hrp.AssemblyLinearVelocity = Vector3.new(flat.X, v.Y, flat.Z)
end)

-- spin (CFrame based, works with any speed)
local spinAR
local spinLast = os.clock()

local function spinStop()
    local _, hum = myHrp()
    if hum and spinAR ~= nil then hum.AutoRotate = spinAR end
    spinAR = nil
end

connect(PRE_SIM, function()
    local now = os.clock()
    local dt = math.min(now - spinLast, 0.1)
    spinLast = now
    local hrp, hum = myHrp()
    if not hrp or not hum then return end
    if not CFG.spinOn or hum.Health <= 0 or holding then
        if spinAR ~= nil then spinStop() end
        return
    end
    if spinAR == nil then spinAR = hum.AutoRotate end
    hum.AutoRotate = false
    local ang = (CFG.spinSpeed * dt) % (math.pi * 2)
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ang, 0)
end)

local movDef = {}
local wsLast = tick()
connect(PRE_SIM, function()
    local now = tick()
    local dt = math.min(now - wsLast, 0.1)
    wsLast = now
    if FX.droneFlying then return end
    local c = lp.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if movDef.hum ~= hum then
        movDef = {hum = hum}
    end
    -- WalkSpeed itself is never touched (the anti-cheat watches it); the extra speed is added by moving the root
    if movDef.ws ~= nil then
        hum.WalkSpeed = movDef.ws
        movDef.ws = nil
    end
    if CFG.wsOn and not holding and hum.Health > 0 and not hum.Sit then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local md = hum.MoveDirection
        local extra = CFG.walkSpeed - hum.WalkSpeed
        if hrp and md.Magnitude > 0.05 and extra > 0 then
            hrp.CFrame = hrp.CFrame + Vector3.new(md.X, 0, md.Z) * extra * dt
        end
    end
    if CFG.jpOn then
        if movDef.jp == nil then movDef.jp = hum.JumpPower end
        hum.UseJumpPower = true
        hum.JumpPower = CFG.jumpPower
    elseif movDef.jp ~= nil then
        hum.JumpPower = movDef.jp
        movDef.jp = nil
    end
end)

local xr = {map = nil, saved = {}}

local function xrSkip(part)
    local n = part.Name
    if n:find("Coin", 1, true) or n:find("Spawn", 1, true) or n == "GunDrop" or n == "HumanoidRootPart" then return true end
    local m = part:FindFirstAncestorOfClass("Model")
    if m and m:FindFirstChildOfClass("Humanoid") then return true end
    return false
end

local function xrApply(part)
    if not part:IsA("BasePart") or xr.saved[part] ~= nil then return end
    if part.Transparency >= CFG.xrayTransp or xrSkip(part) then return end
    xr.saved[part] = part.Transparency
    part.Transparency = CFG.xrayTransp
end

local function xrRestore()
    for part, t in pairs(xr.saved) do
        pcall(function() part.Transparency = t end)
    end
    table.clear(xr.saved)
    xr.map = nil
end

local function xrRefresh()
    for part in pairs(xr.saved) do
        pcall(function() part.Transparency = CFG.xrayTransp end)
    end
end

connect(workspace.DescendantAdded, function(d)
    if CFG.xray and xr.map and d:IsA("BasePart") and d:IsDescendantOf(xr.map) then
        xrApply(d)
    end
end)

task.spawn(function()
    while running do
        if CFG.xray then
            local m = findMap()
            if m ~= xr.map then
                xrRestore()
                xr.map = m
                if m then
                    local n = 0
                    for _, d in ipairs(m:GetDescendants()) do
                        xrApply(d)
                        n += 1
                        if n % 400 == 0 then task.wait() end
                    end
                end
            end
        elseif next(xr.saved) then
            xrRestore()
        end
        task.wait(1)
    end
end)
FX.mov = function() return movDef end
FX.tpLobby = tpLobby
FX.lobbyCF = function() return destCF(findLobby()) end
FX.tpMap = tpMap
FX.flyStop = flyStop
FX.spinStop = spinStop
FX.ncSaved = ncSaved
FX.xrRefresh = xrRefresh
FX.xrRestore = xrRestore
end
local tpLobby, tpMap, flyStop, xrRefresh = FX.tpLobby, FX.tpMap, FX.flyStop, FX.xrRefresh

do
    local saved
    local fovSet = false
    local alertGui, alertLbl
    local lastRoles = ""

    local function restoreLight()
        if saved then
            for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
            saved = nil
        end
    end

    FX.restoreUtil = function()
        restoreLight()
        if fovSet then
            pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
            fovSet = false
        end
        if alertGui then pcall(function() alertGui:Destroy() end) end
        alertGui = nil
    end

    local function alert(text)
        if not alertGui then
            alertGui = Instance.new("ScreenGui")
            alertGui.Name = "ZenithAlert"
            alertGui.ResetOnSpawn = false
            local ok = pcall(function() alertGui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
            if not ok or not alertGui.Parent then alertGui.Parent = lp:WaitForChild("PlayerGui") end
            alertLbl = Instance.new("TextLabel")
            alertLbl.Size = UDim2.new(0, 320, 0, 40)
            alertLbl.Position = UDim2.new(0.5, -160, 0, 70)
            alertLbl.BackgroundColor3 = Color3.fromRGB(170, 25, 35)
            alertLbl.BackgroundTransparency = 0.15
            alertLbl.TextColor3 = Color3.new(1, 1, 1)
            alertLbl.Font = Enum.Font.GothamBlack
            alertLbl.TextSize = 20
            alertLbl.Parent = alertGui
            Instance.new("UICorner", alertLbl).CornerRadius = UDim.new(0, 10)
        end
        alertLbl.Text = text
        alertGui.Enabled = true
    end

    task.spawn(function()
        while running do
            pcall(function()
                if CFG.roleNotify then
                    local m, sh = {}, {}
                    for p, r in pairs(roles) do
                        if p.Parent then
                            if r == "Murderer" then
                                m[#m + 1] = p.Name
                            elseif r == "Sheriff" or r == "Hero" then
                                sh[#sh + 1] = p.Name
                            end
                        end
                    end
                    local key = table.concat(m, ",") .. "|" .. table.concat(sh, ",")
                    if key ~= lastRoles and (#m > 0 or #sh > 0) then
                        lastRoles = key
                        if FX.notify then
                            FX.notify("Zenith", "Murderer: " .. (#m > 0 and table.concat(m, ", ") or "?")
                                .. "\nSheriff: " .. (#sh > 0 and table.concat(sh, ", ") or "?"))
                        end
                    end
                end
                if CFG.fullbright and not CFG.shaders then
                    if not saved then
                        saved = {
                            Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
                            GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                        }
                    end
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.FogEnd = 100000
                    Lighting.GlobalShadows = false
                    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
                    Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
                elseif saved and not CFG.fullbright then
                    restoreLight()
                end
            end)
            task.wait(0.5)
        end
    end)

    connect(RunService.Heartbeat, function()
        local cam0 = workspace.CurrentCamera
        if cam0 then
            if CFG.fovOn then
                cam0.FieldOfView = CFG.fov
                fovSet = true
            elseif fovSet then
                cam0.FieldOfView = 70
                fovSet = false
            end
        end
        if CFG.murderAlert and roles[lp] ~= "Murderer" then
            local m = murdererHrp()
            local me = myHrp()
            if m and me then
                local d = (m.Position - me.Position).Magnitude
                if d <= CFG.alertDist then
                    alert("!! MURDERER " .. math.floor(d) .. "m !!")
                    return
                end
            end
        end
        if alertGui and alertGui.Enabled then alertGui.Enabled = false end
    end)

    pcall(function()
        local VU = game:GetService("VirtualUser")
        connect(lp.Idled, function()
            if CFG.antiAfk then
                pcall(function()
                    VU:CaptureController()
                    VU:ClickButton2(Vector2.new())
                end)
            end
        end)
    end)

    connect(UIS.JumpRequest, function()
        if not CFG.infJump then return end
        local _, hum = myHrp()
        if hum and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)

    FX.rejoin = function()
        local TS = game:GetService("TeleportService")
        local place, job = game.PlaceId, game.JobId
        if FX.notify then FX.notify("Zenith", "Rejoining...") end
        local conn
        conn = TS.TeleportInitFailed:Connect(function(plr, result, msg)
            if plr ~= lp then return end
            if FX.notify then FX.notify("Zenith", "Teleport failed: " .. tostring(result) .. " " .. tostring(msg or "")) end
        end)
        task.spawn(function()
            if #Players:GetPlayers() > 1 and job ~= "" then
                pcall(function() TS:TeleportToPlaceInstance(place, job, lp) end)
                task.wait(5)
            end
            pcall(function() TS:Teleport(place, lp) end)
            task.wait(5)
            pcall(function() TS:Teleport(place) end)
            task.wait(5)
            pcall(function() lp:Kick("\nRejoining...") end)
            task.wait()
            pcall(function() TS:Teleport(place, lp) end)
        end)
        task.delay(30, function()
            if conn then conn:Disconnect() end
        end)
    end
end

do
    local SoundService2 = game:GetService("SoundService")

    local matSaved = {}
    local function restoreMat(part)
        local o = matSaved[part]
        if not o then return end
        matSaved[part] = nil
        if part.Parent then
            pcall(function()
                part.Material = o[1]
                part.Color = o[2]
            end)
        end
    end
    FX.restoreMatChams = function()
        for part in pairs(matSaved) do restoreMat(part) end
    end

    local function partsOf(inst)
        local list = inst:GetDescendants()
        if inst:IsA("BasePart") then list[#list + 1] = inst end
        return list
    end

    local wpn = {}
    local function restoreWeapon(tool)
        local w = wpn[tool]
        if not w then return end
        wpn[tool] = nil
        for _, h in pairs(w.hls or {}) do pcall(function() h:Destroy() end) end
        if w.light then pcall(function() w.light:Destroy() end) end
        for _, d in ipairs(partsOf(tool)) do
            if d:IsA("BasePart") then restoreMat(d) end
        end
    end
    FX.restoreWeapons = function()
        for tool in pairs(wpn) do restoreWeapon(tool) end
    end

    local function styleWeapon(tool, col, seen)
        local st = CFG.weaponStyle
        local w = wpn[tool]
        if not w then
            w = {hls = {}}
            wpn[tool] = w
        end
        local parts = {}
        for _, d in ipairs(partsOf(tool)) do
            if d:IsA("BasePart") and d.Transparency < 1 and #parts < 6 then parts[#parts + 1] = d end
        end
        local matStyle = st == "ForceField" or st == "Neon"
        for _, p in ipairs(parts) do
            local h = w.hls[p]
            if not h or not h.Parent then
                h = Instance.new("Highlight")
                h.Name = "ZenithWpn"
                h.Adornee = p
                h.Parent = p
                w.hls[p] = h
            end
            h.DepthMode = (st == "Glow") and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            h.FillTransparency = (st == "Outline" and 1) or (st == "Glow" and 0.5) or (matStyle and 0.6) or 0.2
            h.OutlineTransparency = 0
            h.FillColor, h.OutlineColor = col, col
            if matStyle then
                local mat = (st == "ForceField") and Enum.Material.ForceField or Enum.Material.Neon
                if not matSaved[p] then matSaved[p] = {p.Material, p.Color} end
                if p.Material ~= mat then p.Material = mat end
                p.Color = col
                seen[p] = true
            else
                restoreMat(p)
            end
        end
        if st == "Glow" and parts[1] then
            if not w.light or not w.light.Parent then
                w.light = Instance.new("PointLight")
                w.light.Range = 10
                w.light.Brightness = 2
                w.light.Parent = parts[1]
            end
            w.light.Color = col
        elseif w.light then
            w.light:Destroy()
            w.light = nil
        end
    end

    task.spawn(function()
        while running do
            pcall(function()
                local seen = {}
                local st = CFG.chamsStyle
                local on = CFG.esp and CFG.highlight
                local mat = on and FX.CHAM_MAT[st] or nil
                local matMode = mat ~= nil
                if FX.chamExtras then FX.chamExtras(on and st or nil) end
                if matMode then
                    for p, e in pairs(E) do
                        local c = p ~= lp and aliveChar(p)
                        if c and e.matColor then
                            for _, d in ipairs(c:GetChildren()) do
                                if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                                    if not matSaved[d] then matSaved[d] = {d.Material, d.Color} end
                                    if d.Material ~= mat then d.Material = mat end
                                    d.Color = e.matColor
                                    seen[d] = true
                                end
                            end
                        end
                    end
                end
                local wseen = {}
                if CFG.weaponEsp then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= lp and p.Character then
                            for _, t in ipairs(p.Character:GetChildren()) do
                                if t:IsA("Tool") and (t.Name == "Knife" or t.Name == "Gun") then
                                    styleWeapon(t, colorOf(t.Name == "Knife" and CFG.knifeColor or CFG.gunColor), seen)
                                    wseen[t] = true
                                end
                            end
                        end
                    end
                end
                if (CFG.weaponEsp or (CFG.esp and CFG.gun)) and drop and drop.Parent then
                    styleWeapon(drop, colorOf(CFG.gunColor), seen)
                    wseen[drop] = true
                end
                for tool in pairs(wpn) do
                    if not wseen[tool] then restoreWeapon(tool) end
                end
                for part in pairs(matSaved) do
                    if not seen[part] then restoreMat(part) end
                end
            end)
            task.wait(0.25)
        end
    end)

    local hud = {}
    connect(RunService.Heartbeat, function()
        if not (CFG.silent and CFG.silentHud) then
            if hud.gui then
                pcall(function() hud.gui:Destroy() end)
                hud = {}
            end
            return
        end
        if not hud.gui or not hud.gui.Parent then
            local g = Instance.new("ScreenGui")
            g.Name = "ZenithSilentHud"
            g.ResetOnSpawn = false
            local ok = pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
            if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
            local l = Instance.new("TextLabel")
            l.AnchorPoint = Vector2.new(0.5, 0)
            l.Position = UDim2.new(0.5, 0, 0, 6)
            l.Size = UDim2.new(0, 260, 0, 22)
            l.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
            l.BackgroundTransparency = 0.3
            l.Font = Enum.Font.GothamBold
            l.TextSize = 13
            l.Parent = g
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
            hud = {gui = g, label = l}
        end
        local t = ST.target
        local me = myHrp()
        if t and t.Parent and me then
            local pl = Players:GetPlayerFromCharacter(t.Parent)
            hud.label.Text = string.format("SILENT [%s]  %s  %dm", CFG.silentMethod, pl and pl.Name or "?", math.floor((t.Position - me.Position).Magnitude))
            hud.label.TextColor3 = Color3.fromRGB(255, 90, 90)
        else
            hud.label.Text = "SILENT  no target (murderer unknown)"
            hud.label.TextColor3 = Color3.fromRGB(170, 170, 180)
        end
    end)

    local modelCache = {}
    local function loadModel(idText)
        local id = tonumber((tostring(idText or ""):gsub("%D", "")))
        if not id then return nil end
        if modelCache[id] then return modelCache[id] end
        local m
        pcall(function()
            local objs = game:GetObjects("rbxassetid://" .. id)
            m = objs and objs[1]
        end)
        if not m then
            local p = Instance.new("Part")
            p.Size = Vector3.new(1, 1, 1)
            local sm = Instance.new("SpecialMesh")
            sm.MeshType = Enum.MeshType.FileMesh
            sm.MeshId = "rbxassetid://" .. id
            sm.Parent = p
            m = p
        end
        modelCache[id] = m
        return m
    end

    local function prepModel(src, scale)
        local ok, m = pcall(function() return src:Clone() end)
        if not ok or not m then return nil end
        if m:IsA("Model") and scale and scale ~= 1 then pcall(function() m:ScaleTo(scale) end) end
        local parts = {}
        if m:IsA("BasePart") then parts[1] = m end
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("TouchTransmitter") or d:IsA("Humanoid")
                or d:IsA("AnimationController") or d:IsA("Animator") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                parts[#parts + 1] = d
            end
        end
        if #parts == 0 then
            m:Destroy()
            return nil
        end
        local main = (m:IsA("Model") and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)) or nil
        local center = nil
        if not main then
            local best = -1
            for _, p in ipairs(parts) do
                local v = p.Size.X * p.Size.Y * p.Size.Z
                if v > best then best, main = v, p end
            end
            -- no rig root: line up the middle of the whole model with your root, not the biggest part
            if m:IsA("Model") then
                local okB, bcf = pcall(function() return (m:GetBoundingBox()) end)
                if okB and bcf then center = main.CFrame:ToObjectSpace(CFrame.new(bcf.Position) * (main.CFrame - main.CFrame.Position)) end
            end
        end
        if m:IsA("BasePart") and scale and scale ~= 1 then
            m.Size = m.Size * scale
            local sm = m:FindFirstChildOfClass("SpecialMesh")
            if sm then sm.Scale = sm.Scale * scale end
        end
        for _, p in ipairs(parts) do
            p.Anchored = false
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.Massless = true
            p.CastShadow = false
            if p ~= main then
                local wc = Instance.new("WeldConstraint")
                wc.Part0, wc.Part1 = main, p
                wc.Parent = main
            end
        end
        m.Name = "ZenithSkin"
        return m, main, center
    end

    local visCache = {}
    local function loadVisual(id)
        id = tonumber(id)
        if not id then return nil end
        if visCache[id] ~= nil then return visCache[id] or nil end
        local src
        pcall(function()
            local objs = game:GetObjects("rbxassetid://" .. id)
            local o = objs and objs[1]
            if o and (o:IsA("BasePart") or o:FindFirstChildWhichIsA("BasePart", true)) then src = o end
        end)
        if not src then
            pcall(function() src = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromAssetId(id)) end)
        end
        if not src then
            pcall(function()
                src = game:GetService("InsertService"):CreateMeshPartAsync("rbxassetid://" .. id, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
            end)
        end
        if not src then
            local p = Instance.new("Part")
            p.Size = Vector3.new(1, 1, 1)
            local sm = Instance.new("SpecialMesh")
            sm.MeshType = Enum.MeshType.FileMesh
            sm.MeshId = "rbxassetid://" .. id
            sm.Parent = p
            p:SetAttribute("ZenithSpecial", true)
            src = p
        end
        visCache[id] = src
        return src
    end
    FX.loadVisual = loadVisual

    local function sizeOf(o)
        local ok, v = pcall(function()
            if o:IsA("Model") then return o:GetExtentsSize() end
            if o:IsA("BasePart") then return o.Size end
        end)
        return ok and v or nil
    end

    local tung = {}
    local function tungClear()
        if tung.model then pcall(function() tung.model:Destroy() end) end
        for d in pairs(tung.hidden or {}) do
            if d.Parent then pcall(function() d.LocalTransparencyModifier = 0 end) end
        end
        tung = {}
    end
    FX.tungClear = tungClear
    connect(RunService.Heartbeat, function()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not CFG.tung or not hrp or not hum then
            if tung.model then tungClear() end
            return
        end
        if tung.char ~= c or tung.sig ~= CFG.tungScale or not (tung.model and tung.model.Parent) then
            tungClear()
            local src = loadVisual(138151705692565)
            if not src then return end
            local scale = CFG.tungScale
            if not src:GetAttribute("ZenithSpecial") then
                local sz = sizeOf(src)
                if sz and sz.Y > 0 then scale = 5.5 * CFG.tungScale / sz.Y end
            end
            local inner, main = prepModel(src, scale)
            if not inner or not main then return end
            local sz2 = sizeOf(inner) or main.Size
            local m = Instance.new("Model")
            m.Name = "ZenithTung"
            inner.Parent = m
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 0
                    d.Transparency = 0
                end
            end
            local w = Instance.new("Weld")
            w.Part0, w.Part1 = hrp, main
            w.Parent = main
            m.Parent = c
            tung = {char = c, model = m, weld = w, sig = CFG.tungScale, hidden = {},
                    yOff = sz2.Y / 2 - (hum.HipHeight + hrp.Size.Y / 2)}
            if src:GetAttribute("ZenithSpecial") and FX.notify then
                task.spawn(FX.notify, "Tung Tung Sahur", "Mesh loaded without size info - adjust Tung size")
            end
        end
        tung.weld.C0 = CFrame.new(0, tung.yOff + CFG.tungY, 0) * CFrame.Angles(0, math.rad(CFG.tungYaw), 0)
        for _, d in ipairs(c:GetDescendants()) do
            local par = d.Parent
            local body = (d:IsA("BasePart") and (par == c or (par and par:IsA("Accessory"))))
                or (d:IsA("Decal") and par and par.Name == "Head" and par.Parent == c)
            if body and d.Name ~= "HumanoidRootPart" and not d:IsDescendantOf(tung.model) then
                d.LocalTransparencyModifier = 1
                tung.hidden[d] = true
            end
        end
    end)

    local skinLib, libKeys = {}, {}
    local knifeNames, gunNames = {"None"}, {"None"}
    FX.knifeNames = function() return knifeNames end
    FX.gunNames = function() return gunNames end

    local function snapshotTool(tool)
        local h = tool:FindFirstChild("Handle")
        if not h or not h:IsA("BasePart") then return nil end
        local m = Instance.new("Model")
        local n = 0
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency < 1 and not d:FindFirstAncestor("ZenithSkin") then
                local ok, c = pcall(function() return d:Clone() end)
                if ok and c then
                    for _, ch in ipairs(c:GetChildren()) do
                        if not (ch:IsA("DataModelMesh") or ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance")) then
                            ch:Destroy()
                        end
                    end
                    c.CFrame = h.CFrame:ToObjectSpace(d.CFrame)
                    c.Parent = m
                    n += 1
                end
            end
        end
        if n == 0 then
            m:Destroy()
            return nil
        end
        return m
    end

    local function skinKey(tool)
        local h = tool:FindFirstChild("Handle")
        local mid, tid = "", ""
        if h and h:IsA("MeshPart") then mid, tid = h.MeshId, h.TextureID end
        local sm = h and h:FindFirstChildWhichIsA("SpecialMesh")
        if sm then mid, tid = sm.MeshId, sm.TextureId end
        return tool.Name .. "|" .. mid .. "|" .. tid
    end

    local function capture(p, tool)
        local key = skinKey(tool)
        if libKeys[key] then return false end
        local snap = snapshotTool(tool)
        if not snap then return false end
        local label = tool.Name .. " - " .. p.Name
        local i = 2
        while skinLib[label] do
            label = tool.Name .. " - " .. p.Name .. " " .. i
            i += 1
        end
        libKeys[key] = true
        skinLib[label] = snap
        local list = tool.Name == "Knife" and knifeNames or gunNames
        list[#list + 1] = label
        return true
    end

    FX.copySkins = function()
        local added = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                for _, t in ipairs(p.Character:GetChildren()) do
                    if t:IsA("Tool") and (t.Name == "Knife" or t.Name == "Gun") then
                        if capture(p, t) then added += 1 end
                    end
                end
            end
        end
        if added > 0 and FX.skinDD then
            if FX.skinDD.knife then pcall(function() FX.skinDD.knife:Refresh(knifeNames) end) end
            if FX.skinDD.gun then pcall(function() FX.skinDD.gun:Refresh(gunNames) end) end
        end
        return added
    end

    task.spawn(function()
        while running do
            if CFG.skinCapture then pcall(FX.copySkins) end
            task.wait(1.5)
        end
    end)

    local skinHidden = {}
    local function unhideTool(tool)
        local hid = skinHidden[tool]
        if not hid then return end
        for d in pairs(hid) do
            if d.Parent then pcall(function() d.LocalTransparencyModifier = 0 end) end
        end
        skinHidden[tool] = nil
    end

    local function applySkin(tool, enabled, idText, scale, rotY)
        local h = tool:FindFirstChild("Handle")
        local cur = tool:FindFirstChild("ZenithSkin")
        if not enabled or not h then
            if cur then cur:Destroy() end
            unhideTool(tool)
            return
        end
        local sig = tostring(idText) .. "|" .. tostring(scale) .. "|" .. tostring(rotY)
        if cur and cur:GetAttribute("sig") ~= sig then
            cur:Destroy()
            cur = nil
        end
        if not cur then
            local src = (typeof(idText) == "Instance") and idText or loadModel(idText)
            local m, main = nil, nil
            if src then m, main = prepModel(src, scale) end
            if not m then return end
            m:SetAttribute("sig", sig)
            main.CFrame = h.CFrame
            local w = Instance.new("Weld")
            w.Part0, w.Part1 = h, main
            w.C0 = CFrame.Angles(0, math.rad(rotY), 0)
            w.Parent = main
            m.Parent = tool
            cur = m
        end
        local hid = skinHidden[tool] or {}
        skinHidden[tool] = hid
        for _, d in ipairs(tool:GetDescendants()) do
            if (d:IsA("BasePart") or d:IsA("Decal")) and not d:IsDescendantOf(cur) then
                d.LocalTransparencyModifier = 1
                hid[d] = true
            end
        end
    end

    local dbItems, dbKnife, dbGun = {}, {"None"}, {"None"}
    FX.dbKnifeNames = function() return dbKnife end
    FX.dbGunNames = function() return dbGun end

    local function dbVisual(it)
        local mesh, tex, model
        for kk, v in pairs(it) do
            if type(v) == "string" or type(v) == "number" then
                local kl = tostring(kk):lower()
                local num = tostring(v):match("%d%d%d%d+")
                if num then
                    if kl:find("mesh") then
                        mesh = num
                    elseif kl:find("texture") or kl == "tex" then
                        tex = num
                    elseif kl == "itemid" or kl:find("model") or kl:find("asset") then
                        model = model or num
                    end
                end
            end
        end
        if mesh then
            local p = Instance.new("Part")
            p.Size = Vector3.new(1, 1, 1)
            local sm = Instance.new("SpecialMesh")
            sm.MeshType = Enum.MeshType.FileMesh
            sm.MeshId = "rbxassetid://" .. mesh
            if tex then sm.TextureId = "rbxassetid://" .. tex end
            sm.Parent = p
            return p
        end
        if model then return loadModel(model) end
    end

    FX.scanDB = function()
        local cands = {}
        local db = RS:FindFirstChild("Database")
        if db then
            for _, d in ipairs(db:GetDescendants()) do
                if d:IsA("ModuleScript") then cands[#cands + 1] = d end
            end
        end
        for _, d in ipairs(RS:GetDescendants()) do
            if d:IsA("ModuleScript") then
                local nl = d.Name:lower()
                if nl == "item" or nl == "items" or nl == "weapons" or nl == "itemdatabase" or nl == "sync" then
                    cands[#cands + 1] = d
                end
            end
        end
        local found = 0
        for _, ms in ipairs(cands) do
            local ok, data = pcall(require, ms)
            if ok and type(data) == "table" then
                for _, pool in ipairs({data, data.Item, data.Items, data.Weapons}) do
                    if type(pool) == "table" then
                        for name, it in pairs(pool) do
                            if type(it) == "table" then
                                local typ = tostring(it.ItemType or it.Type or it.Category or it.WeaponType or ""):lower()
                                local isK = typ:find("knife") ~= nil
                                local isG = typ:find("gun") ~= nil or typ:find("revolver") ~= nil
                                if isK or isG then
                                    local label = tostring(it.ItemName or it.DisplayName or it.Name or name)
                                    if not dbItems[label] then
                                        dbItems[label] = it
                                        local list = isK and dbKnife or dbGun
                                        list[#list + 1] = label
                                        found += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(dbKnife, function(a, b) return a == "None" or (b ~= "None" and a < b) end)
        table.sort(dbGun, function(a, b) return a == "None" or (b ~= "None" and a < b) end)
        if FX.dbDD then
            if FX.dbDD.knife then pcall(function() FX.dbDD.knife:Refresh(dbKnife) end) end
            if FX.dbDD.gun then pcall(function() FX.dbDD.gun:Refresh(dbGun) end) end
        end
        return found
    end

    local dbCache = {}
    local function dbSource(label)
        if dbCache[label] ~= nil then return dbCache[label] or nil end
        local it = dbItems[label]
        local src = it and dbVisual(it)
        dbCache[label] = src or false
        return src
    end

    local function applySnap(tool, snap, key)
        local h = tool:FindFirstChild("Handle")
        if not h then return end
        local cur = tool:FindFirstChild("ZenithSkin")
        if cur and cur:GetAttribute("sig") ~= key then
            cur:Destroy()
            cur = nil
        end
        if not cur then
            local m = snap:Clone()
            m.Name = "ZenithSkin"
            m:SetAttribute("sig", key)
            for _, p in ipairs(m:GetChildren()) do
                if p:IsA("BasePart") then
                    local rel = p.CFrame
                    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, false, true, false
                    local w = Instance.new("Weld")
                    w.Part0, w.Part1, w.C0 = h, p, rel
                    w.Parent = p
                end
            end
            m.Parent = tool
            cur = m
        end
        local hid = skinHidden[tool] or {}
        skinHidden[tool] = hid
        for _, d in ipairs(tool:GetDescendants()) do
            if (d:IsA("BasePart") or d:IsA("Decal")) and not d:IsDescendantOf(cur) then
                d.LocalTransparencyModifier = 1
                hid[d] = true
            end
        end
    end

    local cs = {char = nil, model = nil, weld = nil, sig = nil, hidden = {}}
    local function clearChar()
        if cs.model then pcall(function() cs.model:Destroy() end) end
        for d in pairs(cs.hidden) do
            if d.Parent then pcall(function() d.LocalTransparencyModifier = 0 end) end
        end
        cs = {char = nil, model = nil, weld = nil, sig = nil, hidden = {}}
    end

    local hat = {}
    local function clearHat()
        if hat.part then pcall(function() hat.part:Destroy() end) end
        hat = {}
    end

    FX.restoreModels = function()
        clearChar()
        clearHat()
        for tool in pairs(skinHidden) do unhideTool(tool) end
        for _, holder in ipairs({lp.Character, lp:FindFirstChild("Backpack")}) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    local sk = t:IsA("Tool") and t:FindFirstChild("ZenithSkin")
                    if sk then sk:Destroy() end
                end
            end
        end
    end

    local specOn = false
    connect(RunService.Heartbeat, function()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local head = c and c:FindFirstChild("Head")
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") then
                    if t.Name == "Gun" then
                        local dsrc = CFG.gunDB ~= "None" and dbSource(CFG.gunDB)
                        local snap = CFG.gunLib ~= "None" and skinLib[CFG.gunLib]
                        if dsrc then
                            pcall(applySkin, t, true, dsrc, CFG.gunSkinScale, CFG.gunSkinRot)
                        elseif snap then
                            pcall(applySnap, t, snap, CFG.gunLib)
                        else
                            pcall(applySkin, t, CFG.gunSkin, CFG.gunSkinId, CFG.gunSkinScale, CFG.gunSkinRot)
                        end
                    elseif t.Name == "Knife" then
                        local dsrc = CFG.knifeDB ~= "None" and dbSource(CFG.knifeDB)
                        local snap = CFG.knifeLib ~= "None" and skinLib[CFG.knifeLib]
                        if dsrc then
                            pcall(applySkin, t, true, dsrc, CFG.knifeSkinScale, CFG.knifeSkinRot)
                        elseif snap then
                            pcall(applySnap, t, snap, CFG.knifeLib)
                        else
                            pcall(applySkin, t, CFG.knifeSkin and CFG.knifeSkinId ~= "", CFG.knifeSkinId, CFG.knifeSkinScale, CFG.knifeSkinRot)
                        end
                    end
                end
            end
        end

        if CFG.customChar and hrp then
            local sig = tostring(CFG.charModelId) .. "|" .. tostring(CFG.charScale)
            if cs.char ~= c or cs.sig ~= sig or not (cs.model and cs.model.Parent) then
                clearChar()
                local src = loadModel(CFG.charModelId)
                local m, main, center = nil, nil, nil
                if src then m, main, center = prepModel(src, CFG.charScale) end
                if m then
                    main.CFrame = hrp.CFrame
                    local w = Instance.new("Weld")
                    w.Part0, w.Part1 = hrp, main
                    if center then w.C1 = center end
                    w.Parent = main
                    m.Parent = c
                    cs.model, cs.weld = m, w
                end
                cs.char, cs.sig = c, sig
            end
            if cs.weld then
                cs.weld.C0 = CFrame.new(0, CFG.charY, 0) * CFrame.Angles(0, math.rad(CFG.charYaw), 0)
            end
            for _, d in ipairs(c:GetDescendants()) do
                local par = d.Parent
                local body = (d:IsA("BasePart") and (par == c or (par and par:IsA("Accessory"))))
                    or (d:IsA("Decal") and par and par.Name == "Head" and par.Parent == c)
                if body and d.Name ~= "HumanoidRootPart" and not (cs.model and d:IsDescendantOf(cs.model)) then
                    d.LocalTransparencyModifier = 1
                    cs.hidden[d] = true
                end
            end
        elseif cs.char then
            clearChar()
        end

        if CFG.chinaHat and head then
            if hat.char ~= c or not (hat.part and hat.part.Parent) then
                clearHat()
                local p = Instance.new("Part")
                p.Name = "ZenithChinaHat"
                p.Size = Vector3.new(1, 1, 1)
                p.Material = Enum.Material.Neon
                p.Transparency = 0.3
                p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
                local sm = Instance.new("SpecialMesh")
                sm.MeshType = Enum.MeshType.FileMesh
                sm.MeshId = "rbxassetid://1033714"
                sm.Scale = Vector3.new(1.7, 1.1, 1.7)
                sm.Parent = p
                local w = Instance.new("Weld")
                w.Part0, w.Part1 = head, p
                w.C0 = CFrame.new(0, 1.05, 0)
                w.Parent = p
                p.Parent = c
                local hl = Instance.new("Highlight")
                hl.Adornee = p
                hl.FillTransparency = 1
                hl.OutlineTransparency = 0
                hl.Parent = p
                hat = {char = c, part = p, hl = hl}
            end
            local col = colorOf(CFG.hatColor)
            hat.part.Color = col
            hat.hl.OutlineColor = col
        elseif hat.part then
            clearHat()
        end

        if not FX.droneFlying then
            local cam0 = workspace.CurrentCamera
            local subj
            if CFG.specMurd then
                local m = murdererHrp()
                subj = m and m.Parent and m.Parent:FindFirstChildOfClass("Humanoid")
            elseif CFG.specSher then
                for p, r in pairs(roles) do
                    if p ~= lp and (r == "Sheriff" or r == "Hero") then
                        local c2, _, h2 = aliveChar(p)
                        if c2 then
                            subj = h2
                            break
                        end
                    end
                end
            end
            if subj and cam0 then
                cam0.CameraSubject = subj
                specOn = true
            elseif specOn and cam0 then
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hum then cam0.CameraSubject = hum end
                specOn = false
            end
        end
    end)

    local function guiRoot(name)
        local g = Instance.new("ScreenGui")
        g.Name = name
        g.IgnoreGuiInset = true
        g.ResetOnSpawn = false
        g.DisplayOrder = 1000
        local ok = pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        return g
    end

    local function osdText(parent, text, ax, ay, px, py, size, color, xa)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.AnchorPoint = Vector2.new(ax, ay)
        t.Position = UDim2.new(px, 0, py, 0)
        t.Size = UDim2.new(0, 420, 0, (size or 18) + 8)
        t.Font = Enum.Font.Code
        t.TextSize = size or 18
        t.TextColor3 = color or Color3.new(1, 1, 1)
        t.TextStrokeTransparency = 0.3
        t.TextXAlignment = xa or Enum.TextXAlignment.Left
        t.Text = text
        t.Parent = parent
        return t
    end

    local droneSrc = {}
    local function loadDroneModel(cf, spec)
        local id = spec.meshId
        if not id then return nil end
        local src = loadVisual(id)
        if not src then return nil end
        local scale = CFG.droneMeshScale
        if not src:GetAttribute("ZenithSpecial") then
            local sz = sizeOf(src)
            if sz then
                local mx = math.max(sz.X, sz.Y, sz.Z)
                if mx > 0 then scale = (spec.modelSize or 3) / mx * CFG.droneMeshScale end
            end
        end
        local inner, main = prepModel(src, scale)
        if not inner or not main then return nil end
        for _, d in ipairs(inner:IsA("BasePart") and {inner} or inner:GetDescendants()) do
            if d:IsA("MeshPart") and (d.TextureID == nil or d.TextureID == "") then
                d.Material = Enum.Material.Metal
                d.Color = spec.frame or Color3.fromRGB(60, 62, 68)
            end
        end
        local m = Instance.new("Model")
        m.Name = "ZenithDrone"
        local body = Instance.new("Part")
        body.Name = "ZenithDroneCore"
        body.Size = Vector3.new(0.3, 0.3, 0.3)
        body.Transparency = 1
        body.Anchored = true
        body.CanCollide, body.CanQuery, body.CanTouch = false, false, false
        body.CFrame = cf
        body.Parent = m
        m.PrimaryPart = body
        inner.Parent = m
        local rot = CFrame.Angles(CFG.droneMeshFlip and math.pi or 0, math.rad(CFG.droneModelYaw or 0), 0)
        main.CFrame = cf * rot
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.C0 = body, main, rot
        w.Parent = body
        local lens = Instance.new("Part")
        lens.Name = "ZenithDroneLens"
        lens.Size = Vector3.new(0.1, 0.1, 0.1)
        lens.Transparency = 1
        lens.CanCollide, lens.CanQuery, lens.CanTouch, lens.Massless = false, false, false, true
        lens.Parent = m
        local lw = Instance.new("Weld")
        lw.Part0, lw.Part1 = body, lens
        lw.C0 = CFrame.new(0, 0.2, -(spec.modelSize or 3) / 2 - 0.3)
        lw.Parent = lens
        m.Parent = workspace
        return m, body, {}, lens
    end

    local DRONES = {
        FPV = {meshId = 79445961621887, modelSize = 3, speed = 80, accel = 2.8, arms = 4, frame = Color3.fromRGB(52, 56, 62), accent = Color3.fromRGB(150, 60, 255),
               led = Color3.fromRGB(150, 60, 255), boom = 6, vol = 1.3, scale = 1, blades = 3},
        ["Kamikaze FPV"] = {meshId = 124994246147928, modelSize = 3.4, speed = 75, accel = 2.5, arms = 4, frame = Color3.fromRGB(70, 76, 58), accent = Color3.fromRGB(200, 60, 40),
                            led = Color3.fromRGB(255, 50, 40), boom = 11, vol = 1.35, scale = 1.05, payload = true, blades = 3},
        ["Shahed-136"] = {speed = 95, accel = 2, wing = true, modelSize = 8, frame = Color3.fromRGB(150, 150, 150), accent = Color3.fromRGB(60, 60, 60),
                  led = Color3.fromRGB(255, 40, 40), boom = 14, vol = 1.6, scale = 1.25, minThrottle = 0.6},
        Racer = {speed = 115, accel = 3.2, arms = 4, frame = Color3.fromRGB(28, 28, 32), accent = Color3.fromRGB(255, 140, 0),
                 led = Color3.fromRGB(255, 140, 0), boom = 6, vol = 1.4, scale = 0.85, blades = 3},
        Heavy = {speed = 50, accel = 1.6, arms = 6, frame = Color3.fromRGB(45, 52, 42), accent = Color3.fromRGB(200, 200, 60),
                 led = Color3.fromRGB(255, 60, 60), boom = 15, vol = 1.7, scale = 1.45, payload = true, blades = 2},
        Kamikaze = {speed = 95, accel = 2, wing = true, frame = Color3.fromRGB(150, 150, 150), accent = Color3.fromRGB(60, 60, 60),
                    led = Color3.fromRGB(255, 40, 40), boom = 12, vol = 1.6, scale = 1.2, minThrottle = 0.6},
        Mini = {speed = 60, accel = 4.5, arms = 4, frame = Color3.fromRGB(28, 28, 32), accent = Color3.fromRGB(60, 140, 255),
                led = Color3.fromRGB(60, 140, 255), boom = 5, vol = 0.8, scale = 0.6, blades = 3},
        Stealth = {speed = 85, accel = 2.8, arms = 4, frame = Color3.fromRGB(10, 10, 12), accent = Color3.fromRGB(25, 25, 28),
                   led = Color3.fromRGB(60, 0, 0), boom = 8, vol = 0.25, scale = 1, blades = 2, propColor = Color3.fromRGB(20, 20, 22)},
        Cinewhoop = {speed = 55, accel = 4, arms = 4, frame = Color3.fromRGB(28, 28, 32), accent = Color3.fromRGB(255, 60, 120),
                     led = Color3.fromRGB(255, 60, 120), boom = 6, vol = 1, scale = 0.9, ducts = true, gopro = true, blades = 5},
        ["Long Range"] = {speed = 90, accel = 2.2, arms = 4, frame = Color3.fromRGB(28, 28, 32), accent = Color3.fromRGB(40, 200, 120),
                          led = Color3.fromRGB(40, 255, 140), boom = 9, vol = 1.2, scale = 1.25, battery = 150, payload = true, blades = 2},
        Thermal = {speed = 70, accel = 2.6, arms = 4, frame = Color3.fromRGB(60, 62, 66), accent = Color3.fromRGB(230, 230, 230),
                   led = Color3.fromRGB(255, 255, 255), boom = 8, vol = 1.1, scale = 1.05, thermal = true, payload = true, blades = 3},
        ["Night Vision"] = {speed = 72, accel = 2.6, arms = 4, frame = Color3.fromRGB(35, 45, 35), accent = Color3.fromRGB(90, 200, 90),
                            led = Color3.fromRGB(80, 255, 80), boom = 8, vol = 1.1, scale = 1, nv = true, payload = true, blades = 3},
        Interceptor = {speed = 150, accel = 4.2, arms = 4, frame = Color3.fromRGB(20, 22, 26), accent = Color3.fromRGB(0, 220, 255),
                       led = Color3.fromRGB(0, 220, 255), boom = 6, vol = 1.5, scale = 0.8, blades = 3},
        Mavic = {speed = 45, accel = 5, arms = 4, frame = Color3.fromRGB(95, 97, 102), accent = Color3.fromRGB(70, 72, 76),
                 led = Color3.fromRGB(255, 80, 80), boom = 6, vol = 0.7, scale = 0.85, gimbal = true, blades = 2,
                 propColor = Color3.fromRGB(60, 60, 64)},
        Lancet = {speed = 105, accel = 2.2, lancet = true, frame = Color3.fromRGB(110, 115, 100), accent = Color3.fromRGB(60, 62, 55),
                  led = Color3.fromRGB(255, 40, 40), boom = 13, vol = 1.6, scale = 1.15, minThrottle = 0.55},
    }

    local function buildDrone(cf, spec)
        if CFG.droneMesh then
            local ok, m0, b0, p0, l0 = pcall(loadDroneModel, cf, spec)
            if ok and m0 then return m0, b0, p0, l0 end
        end
        local k = spec.scale or 1
        local m = Instance.new("Model")
        m.Name = "ZenithDrone"
        local function part(size, color, mat, shape, tr)
            local p = Instance.new("Part")
            p.Size, p.Color = size * k, color
            p.Material = mat or Enum.Material.SmoothPlastic
            p.Transparency = tr or 0
            p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
            p.Massless = true
            if shape then p.Shape = shape end
            p.Parent = m
            return p
        end
        local body = part(Vector3.new(0.3, 0.3, 0.3), spec.frame, nil, nil, 1)
        body.Anchored = true
        body.CFrame = cf
        m.PrimaryPart = body
        local function attach(p, c0)
            local w = Instance.new("Weld")
            w.Part0, w.Part1, w.C0 = body, p, c0
            w.Parent = p
            return w
        end
        local function at(v) return v * k end
        local SIDE = CFrame.Angles(0, 0, math.pi / 2)
        local FWD = CFrame.Angles(0, math.pi / 2, 0)
        local props = {}
        local lens

        if spec.lancet then
            local fus = part(Vector3.new(2.6, 0.42, 0.42), spec.frame, Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(fus, FWD)
            local nose = part(Vector3.new(0.42, 0.42, 0.42), spec.frame, Enum.Material.Metal, Enum.PartType.Ball)
            attach(nose, CFrame.new(at(Vector3.new(0, 0, -1.3))))
            local seeker = part(Vector3.new(0.24, 0.24, 0.24), Color3.fromRGB(20, 20, 24), Enum.Material.Glass, Enum.PartType.Ball)
            attach(seeker, CFrame.new(at(Vector3.new(0, 0, -1.5))))
            for _, zc in ipairs({-0.55, 0.85}) do
                for f = 0, 3 do
                    local ang = math.rad(45 + f * 90)
                    local fin = part(Vector3.new(0.05, 1.1, 0.5), spec.frame, Enum.Material.Metal)
                    attach(fin, CFrame.new(at(Vector3.new(0, 0, zc))) * CFrame.Angles(0, 0, ang) * CFrame.new(0, at(0.6), 0))
                    local tipL = part(Vector3.new(0.06, 0.1, 0.12), spec.led, Enum.Material.Neon)
                    attach(tipL, CFrame.new(at(Vector3.new(0, 0, zc))) * CFrame.Angles(0, 0, ang) * CFrame.new(0, at(1.15), 0))
                end
            end
            local band = part(Vector3.new(0.1, 0.44, 0.44), spec.accent, Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(band, CFrame.new(at(Vector3.new(0, 0, -0.2))) * FWD)
            local motor = part(Vector3.new(0.3, 0.36, 0.36), spec.accent, Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(motor, CFrame.new(at(Vector3.new(0, 0, 1.35))) * FWD)
            local base = at(Vector3.new(0, 0, 1.58))
            for j = 0, 1 do
                local b = part(Vector3.new(0.45, 0.1, 0.03), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
                props[#props + 1] = {w = attach(b, CFrame.new(base)), base = base, off = j * math.pi, axis = "Z", shift = at(0.22)}
            end
            lens = part(Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(60, 140, 255), Enum.Material.Neon, Enum.PartType.Ball)
            attach(lens, CFrame.new(at(Vector3.new(0, -0.12, -1.62))))
        elseif spec.wing then
            local gray = Color3.fromRGB(176, 180, 184)
            local dark = Color3.fromRGB(70, 74, 80)
            local fus = part(Vector3.new(3.2, 0.6, 0.6), gray, Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(fus, FWD)
            for _, z in ipairs({-0.9, -0.2, 0.5, 1.15}) do
                local ring = part(Vector3.new(0.04, 0.63, 0.63), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(ring, CFrame.new(at(Vector3.new(0, 0, z))) * FWD)
            end
            local nose = part(Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(120, 124, 110), Enum.Material.CorrodedMetal, Enum.PartType.Ball)
            attach(nose, CFrame.new(at(Vector3.new(0, 0, -1.6))))
            local blister = part(Vector3.new(0.26, 0.26, 0.26), Color3.fromRGB(20, 40, 70), Enum.Material.Glass, Enum.PartType.Ball)
            attach(blister, CFrame.new(at(Vector3.new(0, -0.24, -1.5))))
            for _, sd in ipairs({1, -1}) do
                local wcf = CFrame.new(at(Vector3.new(sd * 1.35, 0, 0.6))) * CFrame.Angles(0, sd * math.rad(32), 0)
                local wing = part(Vector3.new(2.8, 0.08, 1.35), gray, Enum.Material.Metal)
                attach(wing, wcf)
                local edge = part(Vector3.new(2.8, 0.1, 0.14), dark, Enum.Material.Metal)
                attach(edge, wcf * CFrame.new(0, 0, at(-0.68)))
                local panelL = part(Vector3.new(2.6, 0.09, 0.04), dark, Enum.Material.Metal)
                attach(panelL, wcf * CFrame.new(0, 0, at(0.1)))
                local winglet = part(Vector3.new(0.08, 0.75, 0.62), gray, Enum.Material.Metal)
                attach(winglet, CFrame.new(at(Vector3.new(sd * 2.6, 0.3, 1.35))))
                local navLed = part(Vector3.new(0.12, 0.12, 0.12), sd == 1 and Color3.fromRGB(40, 255, 90) or Color3.fromRGB(255, 40, 40), Enum.Material.Neon, Enum.PartType.Ball)
                attach(navLed, CFrame.new(at(Vector3.new(sd * 2.62, 0, 1.15))))
            end
            local ant = part(Vector3.new(0.05, 0.55, 0.05), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
            attach(ant, CFrame.new(at(Vector3.new(0, 0.55, 0.2))))
            local engine = part(Vector3.new(0.6, 0.5, 0.5), dark, Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(engine, CFrame.new(at(Vector3.new(0, 0, 1.75))) * FWD)
            local fin1 = part(Vector3.new(0.05, 0.3, 0.3), dark, Enum.Material.Metal)
            attach(fin1, CFrame.new(at(Vector3.new(0, 0.3, 1.75))))
            local hub = part(Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, Enum.PartType.Ball)
            attach(hub, CFrame.new(at(Vector3.new(0, 0, 2.1))))
            local base = at(Vector3.new(0, 0, 2.1))
            for j = 0, 1 do
                local b = part(Vector3.new(0.7, 0.14, 0.04), Color3.fromRGB(120, 86, 52), Enum.Material.Wood)
                props[#props + 1] = {w = attach(b, CFrame.new(base)), base = base, off = j * math.pi, axis = "Z", shift = at(0.35)}
            end
            lens = part(Vector3.new(0.12, 0.12, 0.12), Color3.fromRGB(60, 140, 255), Enum.Material.Neon, Enum.PartType.Ball)
            attach(lens, CFrame.new(at(Vector3.new(0, -0.1, -1.95))))
        else
            local bottom = part(Vector3.new(1.0, 0.06, 1.6), spec.frame, Enum.Material.DiamondPlate)
            attach(bottom, CFrame.new())
            local top = part(Vector3.new(0.85, 0.05, 1.3), spec.frame, Enum.Material.Metal)
            attach(top, CFrame.new(at(Vector3.new(0, 0.34, 0))))
            for _, o in ipairs({Vector3.new(0.34, 0.17, 0.55), Vector3.new(-0.34, 0.17, 0.55), Vector3.new(0.34, 0.17, -0.55), Vector3.new(-0.34, 0.17, -0.55)}) do
                local so = part(Vector3.new(0.3, 0.07, 0.07), Color3.fromRGB(196, 200, 206), Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(so, CFrame.new(at(o)) * SIDE)
            end
            local fc = part(Vector3.new(0.62, 0.05, 0.62), Color3.fromRGB(20, 90, 45), Enum.Material.SmoothPlastic)
            attach(fc, CFrame.new(at(Vector3.new(0, 0.16, 0))))
            local bat = part(Vector3.new(0.56, 0.3, 1.0), Color3.fromRGB(235, 195, 40), Enum.Material.SmoothPlastic)
            attach(bat, CFrame.new(at(Vector3.new(0, 0.53, 0.05))))
            local wrap = part(Vector3.new(0.57, 0.31, 0.55), Color3.fromRGB(25, 25, 28), Enum.Material.SmoothPlastic)
            attach(wrap, CFrame.new(at(Vector3.new(0, 0.53, 0.1))))
            local strap = part(Vector3.new(0.62, 0.34, 0.12), Color3.fromRGB(200, 30, 40), Enum.Material.Fabric)
            attach(strap, CFrame.new(at(Vector3.new(0, 0.53, -0.2))))
            local lead = part(Vector3.new(0.5, 0.07, 0.07), Color3.fromRGB(190, 30, 30), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
            attach(lead, CFrame.new(at(Vector3.new(0.12, 0.42, 0.75))) * FWD)
            local xt = part(Vector3.new(0.14, 0.1, 0.18), Color3.fromRGB(240, 220, 40), Enum.Material.SmoothPlastic)
            attach(xt, CFrame.new(at(Vector3.new(0.12, 0.42, 1.02))))
            local ant = part(Vector3.new(0.6, 0.05, 0.05), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
            attach(ant, CFrame.new(at(Vector3.new(0, 0.6, 0.82))) * CFrame.Angles(math.rad(-35), 0, 0) * SIDE)
            local antTip = part(Vector3.new(0.14, 0.14, 0.14), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
            attach(antTip, CFrame.new(at(Vector3.new(0, 0.85, 1.0))))
            for _, sx in ipairs({0.2, -0.2}) do
                local plate = part(Vector3.new(0.05, 0.32, 0.32), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
                attach(plate, CFrame.new(at(Vector3.new(sx, 0.17, -0.68))))
            end
            local camBody = part(Vector3.new(0.34, 0.3, 0.3), Color3.fromRGB(15, 15, 15), Enum.Material.Metal)
            attach(camBody, CFrame.new(at(Vector3.new(0, 0.17, -0.7))) * CFrame.Angles(math.rad(15), 0, 0))
            local lensRing = part(Vector3.new(0.12, 0.22, 0.22), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, Enum.PartType.Cylinder)
            attach(lensRing, CFrame.new(at(Vector3.new(0, 0.19, -0.88))) * FWD)
            lens = part(Vector3.new(0.12, 0.14, 0.14), Color3.fromRGB(60, 140, 255), Enum.Material.Neon, Enum.PartType.Ball)
            attach(lens, CFrame.new(at(Vector3.new(0, 0.19, -0.96))))
            if spec.gimbal then
                local arm1 = part(Vector3.new(0.08, 0.25, 0.08), spec.accent, Enum.Material.Metal)
                attach(arm1, CFrame.new(at(Vector3.new(0, -0.15, -0.72))))
                local gb = part(Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, Enum.PartType.Ball)
                attach(gb, CFrame.new(at(Vector3.new(0, -0.32, -0.72))))
                lens = part(Vector3.new(0.12, 0.12, 0.12), Color3.fromRGB(60, 140, 255), Enum.Material.Neon, Enum.PartType.Ball)
                attach(lens, CFrame.new(at(Vector3.new(0, -0.32, -0.88))))
            end
            if spec.gopro then
                local gp = part(Vector3.new(0.45, 0.32, 0.25), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic)
                attach(gp, CFrame.new(at(Vector3.new(0, 0.86, -0.25))))
                local gpl = part(Vector3.new(0.08, 0.16, 0.16), Color3.fromRGB(60, 60, 70), Enum.Material.Glass, Enum.PartType.Cylinder)
                attach(gpl, CFrame.new(at(Vector3.new(0.1, 0.86, -0.4))) * FWD)
            end
            if spec.payload then
                local war = part(Vector3.new(1.1, 0.32, 0.32), Color3.fromRGB(85, 95, 60), Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(war, CFrame.new(at(Vector3.new(0, -0.28, -0.1))) * FWD)
                local cone = part(Vector3.new(0.32, 0.32, 0.32), Color3.fromRGB(70, 78, 50), Enum.Material.Metal, Enum.PartType.Ball)
                attach(cone, CFrame.new(at(Vector3.new(0, -0.28, -0.68))))
                local band = part(Vector3.new(0.08, 0.34, 0.34), Color3.fromRGB(230, 200, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
                attach(band, CFrame.new(at(Vector3.new(0, -0.28, 0.25))) * FWD)
                for f = 0, 3 do
                    local fin = part(Vector3.new(0.03, 0.22, 0.22), Color3.fromRGB(60, 66, 44), Enum.Material.Metal)
                    attach(fin, CFrame.new(at(Vector3.new(0, -0.28, 0.42))) * CFrame.Angles(0, 0, f * math.pi / 2) * CFrame.new(0, at(0.2), 0))
                end
            end
            local n = spec.arms or 4
            local armLen = 1.25
            for i = 0, n - 1 do
                local r = math.rad((n == 4 and 45 or 0) + i * 360 / n)
                local dir = Vector3.new(math.cos(r), 0, math.sin(r))
                local arm = part(Vector3.new(0.2, 0.07, armLen), spec.frame, Enum.Material.Metal)
                attach(arm, CFrame.lookAt(at(dir * armLen / 2), at(dir * armLen * 2)))
                local stripe = part(Vector3.new(0.08, 0.03, armLen * 0.7), spec.led, Enum.Material.Neon)
                local sp = dir * armLen / 2 - Vector3.new(0, 0.05, 0)
                attach(stripe, CFrame.lookAt(at(sp), at(sp + dir)))
                local mpos = dir * armLen
                local stator = part(Vector3.new(0.18, 0.3, 0.3), Color3.fromRGB(176, 108, 56), Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(stator, CFrame.new(at(mpos + Vector3.new(0, 0.1, 0))) * SIDE)
                local bell = part(Vector3.new(0.1, 0.32, 0.32), Color3.fromRGB(186, 190, 198), Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(bell, CFrame.new(at(mpos + Vector3.new(0, 0.22, 0))) * SIDE)
                local cap = part(Vector3.new(0.05, 0.2, 0.2), spec.accent, Enum.Material.Metal, Enum.PartType.Cylinder)
                attach(cap, CFrame.new(at(mpos + Vector3.new(0, 0.28, 0))) * SIDE)
                local tip = part(Vector3.new(0.24, 0.24, 0.24), spec.frame, Enum.Material.Metal, Enum.PartType.Ball)
                attach(tip, CFrame.new(at(mpos - Vector3.new(0, 0.02, 0))))
                local base = at(mpos + Vector3.new(0, 0.3, 0))
                local bl = spec.blades or 2
                for j = 0, bl - 1 do
                    local b = part(Vector3.new(0.48, 0.025, 0.15), spec.propColor or Color3.fromRGB(235, 235, 240), Enum.Material.SmoothPlastic, nil, 0.05)
                    props[#props + 1] = {w = attach(b, CFrame.new(base)), base = base, off = j * math.pi * 2 / bl, axis = "Y", shift = at(0.24)}
                end
                local disc = part(Vector3.new(0.02, 1.0, 1.0), Color3.fromRGB(200, 200, 210), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, 0.88)
                attach(disc, CFrame.new(base) * SIDE)
                if spec.ducts then
                    for q = 0, 15 do
                        local a = q / 16 * math.pi * 2
                        local off = at(Vector3.new(math.cos(a), 0, math.sin(a)) * 0.56)
                        local seg = part(Vector3.new(0.06, 0.28, 0.24), spec.accent, Enum.Material.SmoothPlastic)
                        attach(seg, CFrame.lookAt(base + off, base + off + Vector3.new(-math.sin(a), 0, math.cos(a))))
                    end
                end
            end
            local ledR = part(Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 40, 40), Enum.Material.Neon, Enum.PartType.Ball)
            attach(ledR, CFrame.new(at(Vector3.new(-0.3, -0.06, 0.78))))
            local ledG = part(Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(40, 255, 90), Enum.Material.Neon, Enum.PartType.Ball)
            attach(ledG, CFrame.new(at(Vector3.new(0.3, -0.06, 0.78))))
        end
        m.Parent = workspace
        return m, body, props, lens
    end

    local function bigBoom(pos, radius)
        local ex = Instance.new("Explosion")
        ex.Position = pos
        ex.BlastPressure = 0
        ex.BlastRadius = radius
        ex.DestroyJointRadiusPercent = 0
        ex.ExplosionType = Enum.ExplosionType.NoCraters
        ex.Parent = workspace
        local folder = Instance.new("Folder")
        folder.Name = "ZenithBoom"
        folder.Parent = workspace
        local function fxp(size, color, shape, tr)
            local p = Instance.new("Part")
            p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
            p.Size, p.Color = size, color
            p.Material = Enum.Material.Neon
            p.Shape = shape or Enum.PartType.Ball
            p.Transparency = tr or 0
            p.CFrame = CFrame.new(pos)
            p.Parent = folder
            return p
        end
        local fire = fxp(Vector3.new(1, 1, 1), Color3.fromRGB(255, 170, 50))
        TweenService:Create(fire, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(1, 1, 1) * radius * 1.6, Transparency = 1, Color = Color3.fromRGB(255, 70, 20)}):Play()
        local core = fxp(Vector3.new(1, 1, 1), Color3.fromRGB(255, 255, 220))
        TweenService:Create(core, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(1, 1, 1) * radius * 0.8, Transparency = 1}):Play()
        local ringP = fxp(Vector3.new(0.2, 1, 1), Color3.fromRGB(255, 210, 140), Enum.PartType.Cylinder, 0.2)
        ringP.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
        TweenService:Create(ringP, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(0.2, radius * 3.2, radius * 3.2), Transparency = 1}):Play()
        local src = fxp(Vector3.new(1, 1, 1), Color3.new(1, 1, 1), nil, 1)
        local function burst(tex, c1, c2, s0, s1, life, sp, count, acc, emis)
            local em = Instance.new("ParticleEmitter")
            em.Texture = tex
            em.Color = ColorSequence.new(c1, c2)
            em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, s0), NumberSequenceKeypoint.new(1, s1)})
            em.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
            em.Lifetime = NumberRange.new(life * 0.6, life)
            em.Speed = NumberRange.new(sp * 0.4, sp)
            em.SpreadAngle = Vector2.new(180, 180)
            em.Acceleration = acc or Vector3.zero
            em.Rotation = NumberRange.new(0, 360)
            em.RotSpeed = NumberRange.new(-120, 120)
            em.LightEmission = emis or 1
            em.LightInfluence = 0
            em.Rate = 0
            em.Drag = 2
            em.Parent = src
            em:Emit(count)
        end
        burst("rbxasset://textures/particles/fire_main.dds", Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 70, 20), radius * 0.5, 0, 0.8, radius * 2.2, 45)
        burst("rbxasset://textures/particles/smoke_main.dds", Color3.fromRGB(70, 70, 70), Color3.fromRGB(25, 25, 25), radius * 0.4, radius * 1.1, 2.6, radius * 1.4, 35, Vector3.new(0, 3, 0), 0)
        burst("rbxasset://textures/particles/sparkles_main.dds", Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 140, 40), 0.5, 0, 0.9, radius * 5, 70, Vector3.new(0, -30, 0))
        local l = Instance.new("PointLight")
        l.Color = Color3.fromRGB(255, 150, 60)
        l.Range = math.min(radius * 4, 60)
        l.Brightness = 10
        l.Parent = src
        TweenService:Create(l, TweenInfo.new(0.7), {Brightness = 0}):Play()
        local bs = Instance.new("Sound")
        bs.SoundId = "rbxassetid://138533090376585"
        bs.Volume = 3
        bs.Parent = SoundService2
        bs:Play()
        Debris:AddItem(bs, 10)
        Debris:AddItem(folder, 4)
    end

    local function signalLost(duration)
        local g = guiRoot("ZenithSignalLost")
        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundColor3 = Color3.new(1, 1, 1)
        bg.BorderSizePixel = 0
        bg.Parent = g
        local flashEnd = tick() + 0.12
        while tick() < flashEnd do PRE_RENDER:Wait() end
        bg.BackgroundColor3 = Color3.fromRGB(6, 6, 9)

        local noise = {}
        for k = 1, 140 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.Parent = bg
            noise[k] = f
        end
        local tears = {}
        for k = 1, 8 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.Parent = bg
            tears[k] = f
        end
        for k = 0, 60 do
            local sl = Instance.new("Frame")
            sl.BorderSizePixel = 0
            sl.BackgroundColor3 = Color3.new(0, 0, 0)
            sl.BackgroundTransparency = 0.6
            sl.Size = UDim2.new(1, 0, 0, 1)
            sl.Position = UDim2.new(0, 0, k / 60, 0)
            sl.ZIndex = 3
            sl.Parent = bg
        end
        local function bigText(color, z)
            local t = osdText(bg, "SIGNAL LOST", 0.5, 0.5, 0.5, 0.44, 52, color, Enum.TextXAlignment.Center)
            t.Size = UDim2.new(0, 700, 0, 66)
            t.TextStrokeTransparency = 1
            t.ZIndex = z
            return t
        end
        local red = bigText(Color3.fromRGB(255, 40, 60), 4)
        local cyan = bigText(Color3.fromRGB(40, 220, 255), 4)
        local white = bigText(Color3.fromRGB(255, 255, 255), 5)
        white.TextStrokeTransparency = 0.4
        local sub = osdText(bg, "NO VIDEO  |  RSSI -- dBm  |  LQ 0%  |  LINK TERMINATED", 0.5, 0.5, 0.5, 0.55, 18, Color3.fromRGB(220, 220, 220), Enum.TextXAlignment.Center)
        sub.Size = UDim2.new(0, 700, 0, 26)
        sub.ZIndex = 5
        local rec = osdText(bg, "REC", 0, 0, 0.03, 0.05, 18, Color3.fromRGB(255, 60, 60))
        rec.ZIndex = 5
        local coords = osdText(bg, "", 1, 1, 0.97, 0.94, 16, Color3.fromRGB(200, 200, 200), Enum.TextXAlignment.Right)
        coords.ZIndex = 5
        local hrp = myHrp()
        local base = hrp and hrp.Position or Vector3.zero
        coords.Text = string.format("GPS %.1f %.1f %.1f  |  BAT 0%%", base.X, base.Y, base.Z)

        local t0 = tick()
        while tick() - t0 < duration do
            local el = tick() - t0
            for _, f in ipairs(noise) do
                local w = math.random(8, 180)
                f.Size = UDim2.new(0, w, 0, math.random(1, 5))
                f.Position = UDim2.new(math.random(), -w / 2, math.random(), 0)
                local v = math.random(30, 230)
                f.BackgroundColor3 = Color3.fromRGB(v, v, v)
                f.BackgroundTransparency = math.random() * 0.65
            end
            for _, f in ipairs(tears) do
                f.Size = UDim2.new(1, 0, 0, math.random(2, 14))
                f.Position = UDim2.new(0, math.random(-30, 30), math.random(), 0)
                local hue = math.random()
                f.BackgroundColor3 = Color3.fromHSV(hue, 0.4, 0.9)
                f.BackgroundTransparency = 0.55 + math.random() * 0.4
            end
            local j = math.random(-3, 3)
            red.Position = UDim2.new(0.5, -4 + j, 0.44, math.random(-2, 2))
            cyan.Position = UDim2.new(0.5, 4 - j, 0.44, math.random(-2, 2))
            white.Position = UDim2.new(0.5, 0, 0.44, 0)
            local vis = math.floor(el * 5) % 3 ~= 0
            red.Visible, cyan.Visible, white.Visible = vis, vis, vis
            rec.Text = string.format("REC 00:%02d   NO SIGNAL", math.floor(el))
            bg.BackgroundTransparency = el > duration - 0.35 and (el - (duration - 0.35)) / 0.35 or 0
            PRE_RENDER:Wait()
        end
        g:Destroy()
    end

    local function nearestOf(filter)
        local hrp = myHrp()
        if not hrp then return nil end
        local best, bd = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local c, r = aliveChar(p)
                if c and filter(p) then
                    local d = (r.Position - hrp.Position).Magnitude
                    if d < bd then best, bd = p, d end
                end
            end
        end
        return best
    end

    FX.DRONE_TARGETS = {"Murder (Kill)"}
    FX.DRONE_TYPES = {"FPV", "Kamikaze FPV", "Shahed-136"}

    local mapC = {t = 0}
    local function onMap(pos)
        local now = tick()
        if now - mapC.t > 1 then
            mapC.t = now
            mapC.box = nil
            for _, ch in ipairs(workspace:GetChildren()) do
                if ch:IsA("Model") and FX.hasCoinBox and FX.hasCoinBox(ch, false) then
                    local ok, cf, size = pcall(function() return ch:GetBoundingBox() end)
                    if ok then mapC.box = {cf, size / 2 + Vector3.new(40, 60, 40)} end
                    break
                end
            end
        end
        local b = mapC.box
        if not b then return true end
        local l = b[1]:PointToObjectSpace(pos)
        return math.abs(l.X) <= b[2].X and math.abs(l.Y) <= b[2].Y and math.abs(l.Z) <= b[2].Z
    end

    local function eligible(p)
        if p == lp then return false end
        local c, r = aliveChar(p)
        if not c or not inRound(p) or not onMap(r.Position) then return false end
        if roles[lp] == "Murderer" or hasKnife() then return true end
        return roles[p] == "Murderer"
    end

    local function act(p)
        local how
        if roles[lp] == "Murderer" or hasKnife() then
            how = "KILL"
            FX.killTarget(p)
        elseif FX.shootNow then
            how = "KILL (SHOT)"
            FX.shootNow()
        end
        task.wait(1.2)
        local c = aliveChar(p)
        if c and inRound(p) then
            how = (how or "") .. " + FLING"
            FX.flingPlayer(p.Name)
        end
        if FX.notify then FX.notify("Zenith FPV", "HIT " .. p.Name .. "  ->  " .. tostring(how)) end
    end

    FX.droneCmd = nil
    local launchInner
    FX.launchDrone = function()
        if FX.droneFlying then
            FX.droneCmd = "boom"
            return
        end
        FX.droneRestore = nil
        local okL, err = pcall(launchInner)
        if not okL then
            if FX.droneRestore then
                pcall(FX.droneRestore)
            else
                FX.droneFlying = false
                FX.droneCmd = nil
                local c0 = workspace.CurrentCamera
                c0.CameraType = Enum.CameraType.Custom
                local _, hm = myHrp()
                if hm then c0.CameraSubject = hm end
            end
            if FX.notify then FX.notify("Zenith FPV", "Error: " .. tostring(err)) end
        end
    end

    launchInner = function()
        if FX.droneFlying then
            FX.droneCmd = "boom"
            return
        end
        local hrp, hum = myHrp()
        if not hrp or not hum or hum.Health <= 0 then return end
        FX.droneFlying = true
        FX.droneCmd = nil
        local spec = DRONES[CFG.droneType] or DRONES.FPV
        local maxSpeed = spec.speed
        local cam0 = workspace.CurrentCamera
        local oldFov, oldMode = cam0.FieldOfView, lp.CameraMode
        local oldWS, oldJP = hum.WalkSpeed, hum.JumpPower
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        local start = hrp.CFrame * CFrame.new(0, 4, -3)
        do
            local up = RaycastParams.new()
            up.FilterType = Enum.RaycastFilterType.Exclude
            up.FilterDescendantsInstances = {lp.Character}
            up.RespectCanCollide = true
            local hitUp = workspace:Raycast(hrp.Position, start.Position - hrp.Position, up)
            if hitUp then start = CFrame.new(hrp.Position + Vector3.new(0, 1.5, 0)) * hrp.CFrame.Rotation end
        end
        local m, body, props, lens = buildDrone(start, spec)
        local oldMin, oldMax = lp.CameraMinZoomDistance, lp.CameraMaxZoomDistance
        cam0.CameraType = Enum.CameraType.Custom
        if CFG.droneCam == "Third person" then
            cam0.CameraSubject = body
            pcall(function()
                lp.CameraMode = Enum.CameraMode.Classic
                lp.CameraMaxZoomDistance = CFG.droneCamDist
                lp.CameraMinZoomDistance = CFG.droneCamDist
            end)
            cam0.FieldOfView = 80
        else
            cam0.CameraSubject = lens
            pcall(function() lp.CameraMode = Enum.CameraMode.LockFirstPerson end)
            cam0.FieldOfView = 100
        end
        local fly = Instance.new("Sound")
        fly.SoundId = "rbxassetid://114037851906101"
        fly.Looped = true
        fly.Volume = spec.vol
        fly.Parent = body
        fly:Play()

        local osd = guiRoot("ZenithFPVOSD")
        local red = Color3.fromRGB(255, 70, 70)
        osdText(osd, string.upper(CFG.droneType) .. (spec.thermal and "  THERMAL" or "") .. (spec.nv and "  NV" or "") .. "  CH 5.8G  1W", 0, 0, 0.03, 0.05, 18)
        local recT = osdText(osd, "REC", 1, 0, 0.97, 0.05, 18, red, Enum.TextXAlignment.Right)
        local cross = osdText(osd, "[  +  ]", 0.5, 0.5, 0.5, 0.5, 26, Color3.new(1, 1, 1), Enum.TextXAlignment.Center)
        cross.Size = UDim2.new(0, 200, 0, 34)
        local tgtT = osdText(osd, "", 0.5, 0, 0.5, 0.12, 18, red, Enum.TextXAlignment.Center)
        local armT = osdText(osd, "ARMED", 0.5, 0, 0.5, 0.17, 20, red, Enum.TextXAlignment.Center)
        local spdT = osdText(osd, "", 0, 1, 0.03, 0.93, 18)
        local batT = osdText(osd, "", 0, 1, 0.03, 0.87, 18)
        local upHeld, downHeld = false, false
        local function mkBtn(text, px, py, color, w)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(1, 1)
            b.Position = UDim2.new(px, 0, py, 0)
            b.Size = UDim2.new(0, w or 90, 0, 46)
            b.BackgroundColor3 = color
            b.BackgroundTransparency = 0.2
            b.Font = Enum.Font.Code
            b.TextSize = 20
            b.TextColor3 = Color3.new(1, 1, 1)
            b.Text = text
            b.AutoButtonColor = true
            b.Parent = osd
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            return b
        end
        local boomB = mkBtn("BOOM", 0.97, 0.62, Color3.fromRGB(200, 30, 40), 110)
        local exitB = mkBtn("EXIT", 0.97, 0.74, Color3.fromRGB(60, 60, 70))
        local upB = mkBtn("UP", 0.85, 0.62, Color3.fromRGB(40, 90, 160))
        local downB = mkBtn("DOWN", 0.85, 0.74, Color3.fromRGB(40, 90, 160))
        boomB.Activated:Connect(function() FX.droneCmd = "boom" end)
        exitB.Activated:Connect(function() FX.droneCmd = "exit" end)
        upB.MouseButton1Down:Connect(function() upHeld = true end)
        upB.MouseButton1Up:Connect(function() upHeld = false end)
        upB.MouseLeave:Connect(function() upHeld = false end)
        downB.MouseButton1Down:Connect(function() downHeld = true end)
        downB.MouseButton1Up:Connect(function() downHeld = false end)
        downB.MouseLeave:Connect(function() downHeld = false end)
        local climb = 0
        local jconn = UIS.JumpRequest:Connect(function() climb = 0.3 end)

        local rpP = RaycastParams.new()
        rpP.FilterType = Enum.RaycastFilterType.Include
        local thermal = {}
        if spec.thermal or spec.nv then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "ZenithThermal"
            if spec.nv then
                cc.Saturation = -0.7
                cc.Contrast = 0.25
                cc.Brightness = 0.18
                cc.TintColor = Color3.fromRGB(120, 255, 120)
            else
                cc.Saturation = -1
                cc.Contrast = 0.35
                cc.Brightness = 0.05
                cc.TintColor = Color3.fromRGB(225, 235, 255)
                thermal.hls = {}
            end
            cc.Parent = Lighting
            thermal.cc = cc
        end
        local rp2 = RaycastParams.new()
        rp2.FilterType = Enum.RaycastFilterType.Exclude
        rp2.FilterDescendantsInstances = {lp.Character, m}
        pcall(function() rp2.RespectCanCollide = true end)

        local restored = false
        FX.droneRestore = function()
            if restored then return end
            restored = true
            pcall(function() jconn:Disconnect() end)
            pcall(function() fly:Stop() end)
            if thermal.cc then pcall(function() thermal.cc:Destroy() end) end
            for _, h in pairs(thermal.hls or {}) do pcall(function() h:Destroy() end) end
            pcall(function() osd:Destroy() end)
            pcall(function() m:Destroy() end)
            pcall(function() lp.CameraMode = oldMode end)
            pcall(function()
                lp.CameraMaxZoomDistance = oldMax
                lp.CameraMinZoomDistance = oldMin
            end)
            pcall(function()
                cam0.FieldOfView = oldFov
                cam0.CameraType = Enum.CameraType.Custom
                local _, hum2 = myHrp()
                if hum2 then cam0.CameraSubject = hum2 end
                if hum.Parent then
                    hum.WalkSpeed = oldWS
                    hum.JumpPower = oldJP
                end
            end)
            FX.droneCmd = nil
            FX.droneFlying = false
        end

        local pos, vel = start.Position, Vector3.zero
        local t0 = tick()
        local hitP, reason = nil, nil
        local spin = 0
        local ok = pcall(function()
            while running do
                local dt = PRE_RENDER:Wait()
                if hum.Health <= 0 or not hum.Parent or lp.Character ~= hum.Parent then
                    reason = "dead"
                    break
                end
                if FX.droneCmd == "exit" or FX.droneCmd == "boom" then
                    reason = FX.droneCmd
                    break
                end
                local el = tick() - t0
                if not CFG.droneInfBat and el > (spec.battery or 60) then
                    reason = "battery"
                    break
                end
                local cf0 = cam0.CFrame
                local look, right = cf0.LookVector, cf0.RightVector
                local fl = Vector3.new(look.X, 0, look.Z)
                fl = fl.Magnitude > 0.01 and fl.Unit or Vector3.new(0, 0, -1)
                local fr = Vector3.new(right.X, 0, right.Z)
                fr = fr.Magnitude > 0.01 and fr.Unit or Vector3.new(1, 0, 0)
                local md = hum.MoveDirection
                local fwd, side = md:Dot(fl), md:Dot(fr)
                if spec.minThrottle and fwd < spec.minThrottle then fwd = spec.minThrottle end
                climb = math.max(0, climb - dt)
                local up = ((climb > 0 or upHeld) and 1) or (downHeld and -1) or 0
                local wish = look * fwd + right * side + Vector3.new(0, up, 0)
                if wish.Magnitude > 1 then wish = wish.Unit end
                vel = vel:Lerp(wish * maxSpeed, math.clamp(dt * spec.accel, 0, 1))
                local stepV = vel * dt
                if stepV.Magnitude > 0.001 then
                    local params = rp2
                    if CFG.droneNoclip then
                        local chars = {}
                        for _, pl in ipairs(Players:GetPlayers()) do
                            if pl ~= lp and pl.Character then chars[#chars + 1] = pl.Character end
                        end
                        rpP.FilterDescendantsInstances = chars
                        params = rpP
                    end
                    local hit = workspace:Raycast(pos, stepV + stepV.Unit * 0.8, params)
                    if hit then
                        local mdl = hit.Instance:FindFirstAncestorOfClass("Model")
                        local hp = mdl and Players:GetPlayerFromCharacter(mdl)
                        if hp and eligible(hp) then
                            hitP, reason = hp, "hit"
                            pos = hit.Position
                            break
                        elseif not CFG.droneNoclip then
                            reason = "crash"
                            pos = hit.Position
                            break
                        end
                    end
                end
                pos = pos + stepV
                local nearP, nearD = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if eligible(p) then
                        local _, r = aliveChar(p)
                        local d = (r.Position - pos).Magnitude
                        if d < nearD then nearP, nearD = p, d end
                    end
                end
                if thermal.hls then
                    for _, pl in ipairs(Players:GetPlayers()) do
                        local ch = pl ~= lp and pl.Character
                        if ch and not thermal.hls[ch] then
                            local h = Instance.new("Highlight")
                            h.FillColor, h.OutlineColor = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
                            h.FillTransparency, h.OutlineTransparency = 0.05, 0
                            h.DepthMode = Enum.HighlightDepthMode.Occluded
                            h.Adornee = ch
                            h.Parent = ch
                            thermal.hls[ch] = h
                        end
                    end
                end
                if nearP and nearD < 3.5 * (spec.scale or 1) then
                    hitP, reason = nearP, "hit"
                    break
                end
                body.CFrame = CFrame.lookAt(pos, pos + fl) * CFrame.Angles(-fwd * 0.35, 0, -side * 0.35)
                spin += dt * 70
                for _, pr in ipairs(props) do
                    if pr.axis == "Z" then
                        pr.w.C0 = CFrame.new(pr.base) * CFrame.Angles(0, 0, spin + pr.off) * CFrame.new(pr.shift or 0, 0, 0)
                    else
                        pr.w.C0 = CFrame.new(pr.base) * CFrame.Angles(0, spin + pr.off, 0) * CFrame.new(pr.shift or 0, 0, 0)
                    end
                end
                fly.PlaybackSpeed = 0.85 + math.clamp(vel.Magnitude / maxSpeed, 0, 1) * 0.6
                spdT.Text = string.format("SPD %d km/h  ALT %dm", math.floor(vel.Magnitude * 1.8), math.floor(pos.Y - start.Position.Y + 4))
                batT.Text = CFG.droneInfBat and "BAT INF" or string.format("BAT %d%%", math.max(0, math.floor(100 - el * 100 / (spec.battery or 60))))
                recT.Text = (math.floor(el * 2) % 2 == 0 and "REC  " or "     ") .. string.format("00:%02d", math.floor(el) % 60)
                armT.Visible = math.floor(el * 3) % 2 == 0
                tgtT.Text = nearP and string.format("TGT %s  %dm", nearP.Name, math.floor(nearD)) or "NO TARGET"
            end
        end)
        jconn:Disconnect()
        if thermal.cc then pcall(function() thermal.cc:Destroy() end) end
        for _, h in pairs(thermal.hls or {}) do pcall(function() h:Destroy() end) end
        pcall(function() fly:Stop() end)

        if reason == "boom" and not hitP then
            local best, bd = nil, spec.boom
            for _, p in ipairs(Players:GetPlayers()) do
                if eligible(p) then
                    local _, r = aliveChar(p)
                    local d = (r.Position - pos).Magnitude
                    if d < bd then best, bd = p, d end
                end
            end
            hitP = best
        end

        pcall(function() osd:Destroy() end)
        if reason ~= "exit" and reason ~= "dead" then
            pcall(function() m:Destroy() end)
            pcall(bigBoom, pos, spec.boom)
            if hitP and ok then
                local target = hitP
                task.spawn(function() pcall(act, target) end)
            elseif FX.notify then
                task.spawn(FX.notify, "Zenith FPV", reason == "crash" and "CRASH - no target" or "NO TARGET")
            end
            pcall(signalLost, 1.8)
        else
            pcall(function() m:Destroy() end)
        end
        FX.droneRestore()
    end

    local wm = {}
    local function roundTimer()
        local part = workspace:FindFirstChild("RoundTimerPart") or RunService:FindFirstChild("RoundTimerPart", true)
        local sg = part and part:FindFirstChildWhichIsA("SurfaceGui")
        local t = sg and sg:FindFirstChild("Timer")
        if t and t:IsA("TextLabel") then return t.Text end
    end

    -- small line icons drawn from frames (no old images)
    local function glyph(parent, kind, col)
        local h = Instance.new("Frame")
        h.BackgroundTransparency = 1
        h.Size = UDim2.fromOffset(12, 12)
        h.Parent = parent
        local function bar(x, y, w, hh, r)
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.BackgroundColor3 = col
            f.Position = UDim2.fromScale(x, y)
            f.Size = UDim2.fromScale(w, hh)
            f.Parent = h
            if r then Instance.new("UICorner", f).CornerRadius = UDim.new(r, 0) end
        end
        local function ring(x, y, w, hh)
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.Position = UDim2.fromScale(x, y)
            f.Size = UDim2.fromScale(w, hh)
            f.Parent = h
            Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke")
            st.Color, st.Thickness = col, 1.4
            st.Parent = f
        end
        if kind == "user" then ring(0.3, 0.02, 0.4, 0.4) bar(0.12, 0.55, 0.76, 0.42, 0.4)
        elseif kind == "fps" then bar(0.05, 0.6, 0.18, 0.38) bar(0.4, 0.35, 0.18, 0.63) bar(0.75, 0.08, 0.18, 0.9)
        elseif kind == "ping" then ring(0.05, 0.05, 0.9, 0.9) bar(0.42, 0.42, 0.16, 0.16, 1)
        elseif kind == "time" then ring(0.04, 0.04, 0.92, 0.92) bar(0.46, 0.2, 0.1, 0.33) bar(0.46, 0.46, 0.3, 0.1)
        elseif kind == "sub" then ring(0.05, 0.25, 0.5, 0.5) bar(0.5, 0.45, 0.48, 0.12) bar(0.82, 0.45, 0.1, 0.32)
        elseif kind == "cfg" then bar(0.15, 0.05, 0.7, 0.9, 0.15) bar(0.3, 0.3, 0.4, 0.08) bar(0.3, 0.5, 0.4, 0.08) bar(0.3, 0.7, 0.25, 0.08)
        elseif kind == "game" then bar(0.02, 0.28, 0.96, 0.5, 0.4) bar(0.2, 0.45, 0.2, 0.08) bar(0.26, 0.38, 0.08, 0.22) bar(0.66, 0.4, 0.12, 0.12, 1)
        elseif kind == "exec" then bar(0.02, 0.12, 0.96, 0.76, 0.15) bar(0.2, 0.36, 0.16, 0.08) bar(0.26, 0.44, 0.16, 0.08) bar(0.48, 0.58, 0.3, 0.08)
        elseif kind == "ram" then bar(0.15, 0.2, 0.7, 0.6, 0.1) bar(0.05, 0.3, 0.1, 0.08) bar(0.05, 0.55, 0.1, 0.08) bar(0.85, 0.3, 0.1, 0.08) bar(0.85, 0.55, 0.1, 0.08)
        end
        return h
    end
    local ITEMS = {
        {"user", "wmUser"}, {"fps", "wmFps"}, {"ping", "wmPing"}, {"time", "wmTime"}, {"sub", "wmSub"},
        {"cfg", "wmCfg"}, {"game", "wmGame"}, {"exec", "wmExec"}, {"ramgb", "wmRamGb"}, {"rammb", "wmRamMb"},
    }
    local function buildWatermark()
        local P = FX.themePalette()
        local g = guiRoot("ZenithWatermark")
        g.DisplayOrder = 50
        local main = Instance.new("Frame")
        main.AutomaticSize = Enum.AutomaticSize.X
        main.Size = UDim2.new(0, 0, 0, 28)
        main.Position = wm.pos or UDim2.new(0, 15, 0, 15)
        main.BackgroundColor3 = P.bg
        main.BackgroundTransparency = 0
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = g
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
        local st = Instance.new("UIStroke")
        st.Color, st.Transparency, st.Thickness = P.accentDim, 0.3, 1
        st.Parent = main
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 10)
        pad.Parent = main
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Padding = UDim.new(0, 8)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = main
        local logo = Instance.new("ImageLabel")
        logo.BackgroundTransparency = 1
        logo.Size = UDim2.fromOffset(16, 16)
        logo.Image = (FX.themeLogo and FX.themeLogo()) or "rbxassetid://13936134740"
        logo.ScaleType = Enum.ScaleType.Fit
        logo.LayoutOrder = 0
        logo.Parent = main
        Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 4)
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.AutomaticSize = Enum.AutomaticSize.X
        title.Size = UDim2.new(0, 0, 1, 0)
        title.Font = Enum.Font.GothamBold
        title.Text = "zenith"
        title.TextColor3 = P.accent
        title.TextSize = 12
        title.LayoutOrder = 1
        title.Parent = main
        wm.cells = {}
        for i, it in ipairs(ITEMS) do
            local cell = Instance.new("Frame")
            cell.BackgroundTransparency = 1
            cell.AutomaticSize = Enum.AutomaticSize.X
            cell.Size = UDim2.new(0, 0, 1, 0)
            cell.LayoutOrder = i + 1
            cell.Visible = false
            cell.Parent = main
            local cl = Instance.new("UIListLayout")
            cl.FillDirection = Enum.FillDirection.Horizontal
            cl.VerticalAlignment = Enum.VerticalAlignment.Center
            cl.Padding = UDim.new(0, 5)
            cl.SortOrder = Enum.SortOrder.LayoutOrder
            cl.Parent = cell
            local sep = Instance.new("Frame")
            sep.BorderSizePixel = 0
            sep.BackgroundColor3 = P.sub
            sep.BackgroundTransparency = 0.6
            sep.Size = UDim2.fromOffset(1, 12)
            sep.LayoutOrder = 0
            sep.Parent = cell
            local kind = it[1]
            if kind == "ramgb" or kind == "rammb" then kind = "ram" end
            local ic = glyph(cell, kind, P.accent)
            ic.LayoutOrder = 1
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.AutomaticSize = Enum.AutomaticSize.X
            l.Size = UDim2.new(0, 0, 1, 0)
            l.Font = Enum.Font.GothamMedium
            l.Text = ""
            l.TextColor3 = P.text
            l.TextSize = 11
            l.LayoutOrder = 2
            l.Parent = cell
            wm.cells[it[1]] = {cell = cell, label = l, key = it[2]}
        end
        wm.gui, wm.main = g, main
        local dragging, dragStart, startPos = false, nil, nil
        main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        wm.pos = main.Position
                    end
                end)
            end
        end)
        wm.drag = UIS.InputChanged:Connect(function(input)
            if not dragging or not dragStart then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    FX.wmDestroy = function()
        if wm.drag then pcall(function() wm.drag:Disconnect() end) end
        if wm.gui then pcall(function() wm.gui:Destroy() end) end
        local keep = wm.pos
        wm = {pos = keep}
    end

    local rt = {}
    local rtPos = UDim2.new(0.5, -60, 0, 64)
    FX.timerDestroy = function()
        if rt.drag then pcall(function() rt.drag:Disconnect() end) end
        if rt.gui then pcall(function() rt.gui:Destroy() end) end
        rt = {}
    end
    local function buildTimer()
        local P = FX.themePalette()
        local g = guiRoot("ZenithRoundTimer")
        g.DisplayOrder = 49
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 84, 0, 30)
        box.Position = rtPos
        box.BackgroundColor3 = P.bg
        box.BackgroundTransparency = 0.15
        box.BorderSizePixel = 0
        box.Active = true
        box.Parent = g
        Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)
        local st = Instance.new("UIStroke")
        st.Color = P.accentDim
        st.Transparency = 0.3
        st.Parent = box
        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 12, 0.5, 0)
        dot.Size = UDim2.fromOffset(7, 7)
        dot.BackgroundColor3 = P.accent
        dot.BorderSizePixel = 0
        dot.Parent = box
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 24, 0, 0)
        lbl.Size = UDim2.new(1, -32, 1, 0)
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = "--:--"
        lbl.TextColor3 = P.text
        lbl.TextSize = 15
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = box
        rtPos = rtPos
        rt.dot, rt.P = dot, P
        local dragging, ds, sp = false, nil, nil
        box.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, ds, sp = true, input.Position, box.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        rtPos = box.Position
                    end
                end)
            end
        end)
        rt = {gui = g, box = box, label = lbl}
        rt.drag = UIS.InputChanged:Connect(function(input)
            if not dragging or not ds then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - ds
                box.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end
    task.spawn(function()
        while running do
            pcall(function()
                if CFG.roundTimer and FX.themePalette then
                    if not rt.gui or not rt.gui.Parent then buildTimer() end
                    local tt = roundTimer()
                    rt.label.Text = tt or "--:--"
                    local secs = 999
                    if tt then
                        local m, sec = string.match(tt, "(%d+):(%d+)")
                        if m then secs = tonumber(m) * 60 + tonumber(sec) else secs = tonumber(string.match(tt, "%d+")) or 999 end
                    end
                    rt.label.TextColor3 = rt.P.text
                elseif rt.gui then
                    FX.timerDestroy()
                end
            end)
            task.wait(0.25)
        end
    end)

    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxassetid://1548304764"
        snd.Volume = 1
        snd.Parent = SoundService2
        task.delay(0.1, function()
            snd:Play()
            Debris:AddItem(snd, 8)
        end)
    end)

    local frames, lastT = 0, tick()
    connect(PRE_RENDER, function()
        frames += 1
        local now = tick()
        if now - lastT >= 1 then
            wm.fpsNow = frames
            frames, lastT = 0, now
        end
    end)
    local Stats = game:GetService("Stats")
    local execName = "unknown"
    pcall(function()
        if identifyexecutor then execName = tostring((identifyexecutor())) elseif getexecutorname then execName = tostring(getexecutorname()) end
    end)
    local function subText()
        local gk = (Compat.getgenv and Compat.getgenv()) or _G
        local e = gk.ZenithKeyEnd
        if not e then return "--" end
        if e < 0 then return "forever" end
        local left = math.max(e - os.time(), 0)
        local d = math.floor(left / 86400)
        local h = math.floor((left % 86400) / 3600)
        if d > 0 then return d .. "d " .. h .. "h" end
        return h .. "h " .. math.floor((left % 3600) / 60) .. "m"
    end

    task.spawn(function()
        while running do
            pcall(function()
                if CFG.watermark and FX.themePalette then
                    if not wm.gui or not wm.gui.Parent then buildWatermark() end
                    local okp, ping = pcall(function() return math.floor(lp:GetNetworkPing() * 1000) end)
                    local mb = 0
                    pcall(function() mb = Stats:GetTotalMemoryUsageMb() end)
                    local vals = {
                        user = lp.Name,
                        fps = tostring(wm.fpsNow or 0) .. " fps",
                        ping = (okp and tostring(ping) or "0") .. " ms",
                        time = os.date("%H:%M"),
                        sub = subText(),
                        cfg = (FX.curCfg and FX.curCfg ~= "" and FX.curCfg) or (FX.cfgGetAuto and FX.cfgGetAuto()) or "default",
                        game = "Murder Mystery 2",
                        exec = execName,
                        ramgb = string.format("%.2f gb", mb / 1024),
                        rammb = tostring(math.floor(mb)) .. " mb",
                    }
                    for name, c in pairs(wm.cells or {}) do
                        c.cell.Visible = CFG[c.key] == true
                        c.label.Text = vals[name] or ""
                    end
                elseif wm.gui then
                    FX.wmDestroy()
                end
            end)
            task.wait(1)
        end
    end)
end

do
    local PACKS = {
        Zombie = {idle1 = 616158929, idle2 = 616160636, walk = 616168032, run = 616163682, jump = 616161997, climb = 616156119, fall = 616157476, swim = 616165109, swimidle = 616166655},
        Ninja = {idle1 = 656117400, idle2 = 656118341, walk = 656121766, run = 656118852, jump = 656117878, climb = 656114359, fall = 656115606, swim = 656119721, swimidle = 656121397},
        Robot = {idle1 = 616088211, idle2 = 616089559, walk = 616095330, run = 616091570, jump = 616090535, climb = 616086039, fall = 616087089, swim = 616092998, swimidle = 616094091},
        Stylish = {idle1 = 616136790, idle2 = 616138447, walk = 616146177, run = 616140816, jump = 616139451, climb = 616133594, fall = 616134815, swim = 616143378, swimidle = 616144772},
        Cartoony = {idle1 = 742637544, idle2 = 742638445, walk = 742640026, run = 742638842, jump = 742637942, climb = 742636889, fall = 742637151, swim = 742639220, swimidle = 742639812},
        Superhero = {idle1 = 616111295, idle2 = 616113536, walk = 616122287, run = 616117076, jump = 616115533, climb = 616104706, fall = 616108001, swim = 616119360, swimidle = 616120861},
        Knight = {idle1 = 657595757, idle2 = 657568135, walk = 657552124, run = 657564596, jump = 658409194, climb = 658360781, fall = 657600338, swim = 657560551, swimidle = 657557095},
        Levitation = {idle1 = 616006778, idle2 = 616008087, walk = 616013216, run = 616010382, jump = 616008936, climb = 616003713, fall = 616005863, swim = 616011509, swimidle = 616012453},
        Astronaut = {idle1 = 891621366, idle2 = 891633237, walk = 891667138, run = 891636393, jump = 891627522, climb = 891609353, fall = 891617961, swim = 891639666, swimidle = 891663592},
        Vampire = {idle1 = 1083445855, idle2 = 1083450166, walk = 1083473930, run = 1083462077, jump = 1083455352, climb = 1083439238, fall = 1083443587, swim = 1083222527, swimidle = 1083225406},
        Werewolf = {idle1 = 1083195517, idle2 = 1083214717, walk = 1083178339, run = 1083216690, jump = 1083218792, climb = 1083182000, fall = 1083189019, swim = 1083222527, swimidle = 1083225406},
        Toy = {idle1 = 782841498, idle2 = 782845736, walk = 782843345, run = 782842708, jump = 782847020, climb = 782843869, fall = 782846423, swim = 782844582, swimidle = 782845186},
        Pirate = {idle1 = 750781874, idle2 = 750782770, walk = 750785693, run = 750783738, jump = 750782230, climb = 750779899, fall = 750780242, swim = 750784579, swimidle = 750785176},
        Elder = {idle1 = 845397899, idle2 = 845400520, walk = 845403856, run = 845386501, jump = 845398858, climb = 845392038, fall = 845396048, swim = 845401742, swimidle = 845403127},
        Mage = {idle1 = 707742142, idle2 = 707855907, walk = 707897309, run = 707861613, jump = 707853694, climb = 707826056, fall = 707829716, swim = 707876443, swimidle = 707894699},
        Bubbly = {idle1 = 910004836, idle2 = 910009958, walk = 910034870, run = 910025107, jump = 910016857, fall = 910001910, swim = 910028158, swimidle = 910030921},
        Rthro = {idle1 = 2510196951, idle2 = 2510197257, walk = 2510202577, run = 2510198475, jump = 2510197830, climb = 2510192778, fall = 2510195892, swim = 2510199791, swimidle = 2510201162},
        Oldschool = {idle1 = 5319828216, idle2 = 5319831086, walk = 5319847204, run = 5319844329, jump = 5319841935, climb = 5319816685, fall = 5319839762, swim = 5319850266, swimidle = 5319852613},
    }
    local names = {"Default"}
    for n in pairs(PACKS) do names[#names + 1] = n end
    table.sort(names, function(a, b) return a == "Default" or (b ~= "Default" and a < b) end)
    FX.ANIM_NAMES = names
    FX.animDDs = {}

    local resolved = {}
    FX.resolveAnim = function(id)
        id = tonumber(id)
        if not id then return nil end
        if resolved[id] ~= nil then return resolved[id] or nil end
        local out = false
        pcall(function()
            for _, o in ipairs(game:GetObjects("rbxassetid://" .. id)) do
                local list = o:IsA("Animation") and {o} or o:GetDescendants()
                for _, a in ipairs(list) do
                    if a:IsA("Animation") then
                        local n = tonumber(tostring(a.AnimationId):match("%d+"))
                        if n then
                            out = n
                            return
                        end
                    end
                end
            end
        end)
        resolved[id] = out
        return out or nil
    end

    FX.addPack = function(name, pack)
        if not PACKS[name] then names[#names + 1] = name end
        PACKS[name] = pack
        for _, ddo in ipairs(FX.animDDs) do pcall(function() ddo:Refresh(names) end) end
    end


    local SLOTS = {
        {key = "animIdle", folder = "idle", anims = {{"Animation1", "idle1"}, {"Animation2", "idle2"}}},
        {key = "animWalk", folder = "walk", anims = {{"WalkAnim", "walk"}}},
        {key = "animRun", folder = "run", anims = {{"RunAnim", "run"}}},
        {key = "animJump", folder = "jump", anims = {{"JumpAnim", "jump"}}},
        {key = "animFall", folder = "fall", anims = {{"FallAnim", "fall"}}},
        {key = "animClimb", folder = "climb", anims = {{"ClimbAnim", "climb"}}},
    }

    local saved = setmetatable({}, {__mode = "k"})
    local function idOf(n) return "http://www.roblox.com/asset/?id=" .. tostring(n) end

    FX.applyAnims = function()
        local c = lp.Character
        local an = c and c:FindFirstChild("Animate")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not an or not hum then return false end
        local orig = saved[an]
        if not orig then
            orig = {}
            for _, sl in ipairs(SLOTS) do
                local f = an:FindFirstChild(sl.folder)
                for _, a in ipairs(sl.anims) do
                    local obj = f and f:FindFirstChild(a[1])
                    if obj then orig[obj] = obj.AnimationId end
                end
            end
            for _, extra in ipairs({{"swim", "Swim"}, {"swimidle", "SwimIdle"}}) do
                local f = an:FindFirstChild(extra[1])
                local obj = f and f:FindFirstChild(extra[2])
                if obj then orig[obj] = obj.AnimationId end
            end
            saved[an] = orig
        end
        for _, sl in ipairs(SLOTS) do
            local choice = CFG[sl.key]
            if choice == "Default" then choice = CFG.animPack end
            local pack = PACKS[choice]
            local f = an:FindFirstChild(sl.folder)
            for _, a in ipairs(sl.anims) do
                local obj = f and f:FindFirstChild(a[1])
                if obj then
                    if pack and pack[a[2]] then
                        obj.AnimationId = idOf(pack[a[2]])
                    elseif orig[obj] then
                        obj.AnimationId = orig[obj]
                    end
                end
            end
        end
        local pk = PACKS[CFG.animPack]
        for _, extra in ipairs({{"swim", "Swim", "swim"}, {"swimidle", "SwimIdle", "swimidle"}}) do
            local f = an:FindFirstChild(extra[1])
            local obj = f and f:FindFirstChild(extra[2])
            if obj then
                if pk and pk[extra[3]] then
                    obj.AnimationId = idOf(pk[extra[3]])
                elseif orig[obj] then
                    obj.AnimationId = orig[obj]
                end
            end
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop(0) end
        end
        an.Disabled = true
        task.wait()
        an.Disabled = false
        return true
    end

    local function wanted()
        if CFG.animPack ~= "Default" then return true end
        for _, sl in ipairs(SLOTS) do
            if CFG[sl.key] ~= "Default" then return true end
        end
        return false
    end

    connect(lp.CharacterAdded, function(c)
        if not wanted() then return end
        c:WaitForChild("Animate", 10)
        task.wait(0.3)
        pcall(FX.applyAnims)
    end)
end

do
    local aa = {char = nil, joints = {}}
    local function aaCollect(c)
        local list = {}
        local function add(partName, jointName, k)
            local p = c:FindFirstChild(partName)
            local j = p and p:FindFirstChild(jointName)
            if j and j:IsA("Motor6D") then list[#list + 1] = {j = j, c0 = j.C0, k = k} end
        end
        add("Head", "Neck", 1)
        add("UpperTorso", "Waist", 0.7)
        add("LowerTorso", "Root", 0.45)
        add("Torso", "Neck", 1)
        add("HumanoidRootPart", "RootJoint", 0.55)
        return list
    end
    local function aaRestore()
        for _, e in ipairs(aa.joints) do
            if e.j.Parent then pcall(function() e.j.C0 = e.c0 end) end
        end
        aa = {char = nil, joints = {}}
    end
    FX.aaRestore = aaRestore

    local aaSign, aaFlip = 1, 0
    local function aaSgn()
        if CFG.aaMode == "Up" then return 1 end
        if CFG.aaMode == "Down" then return -1 end
        local now = tick()
        if now - aaFlip > CFG.aaRandRate then
            aaFlip = now
            aaSign = math.random(2) == 1 and 1 or -1
        end
        return aaSign
    end

    local body = {}
    connect(PRE_SIM, function()
        local hrp = body.hrp
        if body.rot and hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(hrp.Position) * body.rot
        end
        body.rot = nil
    end)

    connect(RunService.Heartbeat, function()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local active = CFG.aaOn and hrp and hum and hum.Health > 0 and not FX.droneFlying and not busy and not flinging
        if not active then
            if aa.char then aaRestore() end
            return
        end
        local sgn = aaSgn()
        local ang = math.rad(CFG.aaAngle) * sgn
        if CFG.aaType == "Joints" then
            if aa.char ~= c then
                aaRestore()
                aa.joints = aaCollect(c)
                aa.char = c
            end
            for _, e in ipairs(aa.joints) do
                if e.j.Parent then
                    e.j.C0 = CFrame.new(e.c0.Position) * CFrame.Angles(ang * e.k, 0, 0) * e.c0.Rotation
                end
            end
        else
            if aa.char then aaRestore() end
            local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
            local rot = CFrame.Angles(0, yaw, 0)
            body.hrp, body.rot = hrp, rot
            hrp.CFrame = CFrame.new(hrp.Position) * rot * CFrame.Angles(ang, 0, 0)
        end
    end)

    connect(RunService.Heartbeat, function()
        if not CFG.speedGlitch or FX.droneFlying then return end
        local hrp, hum = myHrp()
        if not hrp or not hum or hum.Health <= 0 then return end
        local md = hum.MoveDirection
        local st = hum:GetState()
        local air = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
        if md.Magnitude > 0.1 then
            if air then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(md.X * CFG.sgSpeed, v.Y, md.Z * CFG.sgSpeed)
            elseif CFG.sgAutoJump then
                hum.Jump = true
            end
        end
    end)

    local rb = {}
    local function ribbonClear()
        for _, o in pairs(rb) do
            if typeof(o) == "Instance" then pcall(function() o:Destroy() end) end
        end
        rb = {}
    end
    FX.ribbonClear = ribbonClear
    connect(RunService.Heartbeat, function()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not CFG.ribbon or not hrp then
            if rb.trail then ribbonClear() end
            return
        end
        if rb.hrp ~= hrp or not (rb.trail and rb.trail.Parent) then
            ribbonClear()
            local a0 = Instance.new("Attachment")
            a0.Name = "ZenithRibbonA"
            a0.Position = Vector3.new(0, 1.2, 0)
            a0.Parent = hrp
            local a1 = Instance.new("Attachment")
            a1.Name = "ZenithRibbonB"
            a1.Position = Vector3.new(0, -1.6, 0)
            a1.Parent = hrp
            local t = Instance.new("Trail")
            t.Name = "ZenithRibbon"
            t.Attachment0, t.Attachment1 = a0, a1
            t.LightEmission = 0.8
            t.LightInfluence = 0
            t.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)})
            t.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2)})
            t.Parent = hrp
            rb = {hrp = hrp, trail = t, a0 = a0, a1 = a1}
        end
        rb.trail.Lifetime = CFG.ribbonLife
        if CFG.ribbonColor == "Rainbow" then
            local h = (tick() * 0.25) % 1
            rb.trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0.8, 1)),
                ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.33) % 1, 0.8, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.66) % 1, 0.8, 1)),
            })
        else
            rb.trail.Color = ColorSequence.new(colorOf(CFG.ribbonColor))
        end
    end)

    local potSaved, potLight, potActive = {}, nil, false
    local function potatoRestore()
        for d, v in pairs(potSaved) do
            if d.Parent then
                pcall(function()
                    if d:IsA("BasePart") then
                        d.Material, d.Reflectance = v[1], v[2]
                    elseif d:IsA("Decal") or d:IsA("Texture") then
                        d.Transparency = v[1]
                    else
                        d.Enabled = v[1]
                    end
                end)
            end
        end
        table.clear(potSaved)
        if potLight then
            for k, v in pairs(potLight) do pcall(function() Lighting[k] = v end) end
            potLight = nil
        end
        pcall(function() workspace.Terrain.Decoration = true end)
        potActive = false
    end
    FX.potatoRestore = potatoRestore
    local function isOurs(d)
        local a = d
        while a and a ~= workspace do
            if a.Name:sub(1, 6) == "Zenith" then return true end
            if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
            a = a.Parent
        end
        return false
    end
    local function potatoApply()
        potActive = true
        if not potLight then
            potLight = {GlobalShadows = Lighting.GlobalShadows, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
                        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale}
        end
        Lighting.GlobalShadows = false
        pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
        pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
        pcall(function() workspace.Terrain.Decoration = false end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            n += 1
            if n % 1500 == 0 then task.wait() end
            if potSaved[d] == nil then
                if d:IsA("BasePart") then
                    if not isOurs(d) then
                        potSaved[d] = {d.Material, d.Reflectance}
                        d.Material = Enum.Material.SmoothPlastic
                        d.Reflectance = 0
                    end
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    if not isOurs(d) then
                        potSaved[d] = {d.Transparency}
                        d.Transparency = 1
                    end
                elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                    if not isOurs(d) then
                        potSaved[d] = {d.Enabled}
                        d.Enabled = false
                    end
                end
            end
        end
    end
    local studSaved, studActive = {}, false
    local SURF = {"TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface"}
    local function studsRestore()
        for d, o in pairs(studSaved) do
            if d.Parent then
                pcall(function()
                    d.Material = o[1]
                    for k, nm in ipairs(SURF) do d[nm] = o[k + 1] end
                end)
            end
        end
        table.clear(studSaved)
        studActive = false
    end
    FX.studsRestore = studsRestore
    local function studsApply()
        studActive = true
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            n += 1
            if n % 1500 == 0 then task.wait() end
            if d:IsA("Part") and studSaved[d] == nil and not isOurs(d) then
                local o = {d.Material}
                for k, nm in ipairs(SURF) do o[k + 1] = d[nm] end
                studSaved[d] = o
                d.Material = Enum.Material.Plastic
                for _, nm in ipairs(SURF) do d[nm] = Enum.SurfaceType.Studs end
            end
        end
    end
    task.spawn(function()
        while running do
            if CFG.studs then
                pcall(studsApply)
            elseif studActive then
                pcall(studsRestore)
            end
            task.wait(4)
        end
    end)

    task.spawn(function()
        while running do
            if CFG.potato then
                pcall(potatoApply)
            elseif potActive then
                pcall(potatoRestore)
            end
            task.wait(4)
        end
    end)

    local EMOTES = {
        Salute = {3333387824, 3360689775}, Tilt = {3334538554, 3360692915}, Stadium = {3338055167, 3360686498},
        Shrug = {3334392772, 3576968026}, Point = {3344585679, 3576823880}, Hello = {3344650532, 3576686446},
        ["Around Town"] = {3303391864, 3576747102}, Fashionable = {3333331310, 3576745472}, ["Top Rock"] = {3361276673, 3570535774},
        Robot = {3338025566, 3576721660}, Jacks = {3338066331, 3570649048}, T = {3338010159, 3576719440},
        Shy = {3337978742, 3576717965}, Sneaky = {3334424322, 3576754235}, Louder = {3338083565, 3576751796},
        Swish = {3361426436, 3361481910}, Monkey = {3333499508, 3716636630}, Godlike = {3337994105, 3823158750},
        Tree = {4049551434, 4049634387}, ["Line Dance"] = {4049037604, 4049646104}, ["Dorky Dance"] = {4212455378, 4212499637},
        ["Floss Dance"] = {5917459365, 5917570207}, ["Hero Landing"] = {5104344710, 5104377791}, Applaud = {5915693819, 5915779043},
        ["Old Town Road"] = {5937560570, 5938365243},
        ["Floating Aura"] = {79795305221612}, ["Aura Floating"] = {106708015414624},
        ["Ha Ha"] = {132496870420627}, ["Griddy"] = {106715239721951},
        ["Monkey"] = {3716636630}, ["Hype Dance"] = {3696757129}, ["Baby Dance"] = {4272484885},
        ["Fashionable"] = {3333331310}, ["Godlike"] = {3337994105}, ["Sneaky"] = {3334424322},
        ["Tilt"] = {3334538554}, ["Jumping Wave"] = {4940602656}, ["Shrug"] = {3576968026},
        ["Salute"] = {3360689775}, ["Bodybuilder"] = {3333387824}, ["Twirl"] = {3716633898},
        ["Celebrate"] = {3994127840}, ["Hello"] = {3576686446},
        ["Curtsy"] = {4646306583}, ["Sleep"] = {4689362868}, ["Fishing"] = {3994129128},
        ["Rodeo Dance"] = {5938397555}, ["Panini Dance"] = {5915781665}, ["Holiday Dance"] = {5938396308},
        ["Louder"] = {3576751796}, ["Happy"] = {4849499887}, ["Cower"] = {4940563117},
        ["Confused"] = {4940561610}, ["Agree"] = {4849487550}, ["Disagree"] = {4849495710},
        ["Power Blast"] = {4849497510}, ["Beckon"] = {5230598276}, ["Get Out"] = {3333272779},
        ["Idol"] = {4101966434}, ["Fancy Feet"] = {3333432454}, ["Air Guitar"] = {3695300085},
        ["Stadium"] = {3360686498},
        ["Dance 1"] = {507771019}, ["Dance 2"] = {507776043}, ["Dance 3"] = {507777268},
        Wave = {507770239}, Cheer = {507770677}, Laugh = {507770818}, ["Point 2"] = {507770453},
    }
    local emoteNames = {}
    for n in pairs(EMOTES) do emoteNames[#emoteNames + 1] = n end
    table.sort(emoteNames)
    FX.EMOTE_NAMES = emoteNames
    FX.EMOTES = EMOTES
    FX.scanMM2Emotes = function()
        local added = 0
        local roots = {RS, lp:FindFirstChild("PlayerGui"), lp:FindFirstChild("PlayerScripts")}
        for _, root in ipairs(roots) do
            if root then
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("Animation") then
                        local path = d:GetFullName():lower()
                        if path:find("emote", 1, true) or path:find("dance", 1, true) then
                            local name = "MM2: " .. d.Name
                            local id = tonumber(tostring(d.AnimationId):match("%d+"))
                            if id and not EMOTES[name] then
                                EMOTES[name] = {id}
                                emoteNames[#emoteNames + 1] = name
                                added += 1
                            end
                        end
                    end
                end
            end
        end
        if added > 0 then
            table.sort(emoteNames)
            if FX.emoteDD then pcall(function() FX.emoteDD:Refresh(emoteNames) end) end
        end
        return added
    end
    local curTrack
    FX.stopEmote = function(keep)
        if curTrack then pcall(function() curTrack:Stop(0.2) end) end
        curTrack = nil
        if not keep then FX.lastEmote = nil end
    end
    FX.playEmote = function(name)
        local ids = EMOTES[name]
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not ids or not hum then return false end
        FX.stopEmote(true)
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end
        local tr
        local cand = {}
        for _, id in ipairs(ids) do
            cand[#cand + 1] = id
            local rid = FX.resolveAnim and FX.resolveAnim(id)
            if rid and rid ~= id then cand[#cand + 1] = rid end
        end
        for _, id in ipairs(cand) do
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://" .. tostring(id)
            local ok, t = pcall(function() return animator:LoadAnimation(a) end)
            if ok and t then
                t.Priority = Enum.AnimationPriority.Action4
                t.Looped = CFG.emoteLoop
                t:Play(0.15)
                local loaded = false
                for _ = 1, 12 do
                    if t.Length > 0 then
                        loaded = true
                        break
                    end
                    task.wait(0.1)
                end
                if loaded then
                    tr = t
                    break
                end
                pcall(function() t:Stop(0) end)
            end
        end
        if not tr then
            pcall(function()
                local ok, t = hum:PlayEmoteAndGetAnimTrackById(ids[2])
                if ok then tr = t end
            end)
        end
        if tr then
            pcall(function()
                tr.Looped = CFG.emoteLoop
                tr:AdjustSpeed(CFG.emoteSpeed)
            end)
            curTrack = tr
            FX.lastEmote = name
            pcall(function()
                tr.Stopped:Connect(function()
                    if not tr.Looped and FX.lastEmote == name then FX.lastEmote = nil end
                end)
            end)
            return true
        end
        return false
    end
    connect(lp.CharacterAdded, function(c)
        local name = FX.lastEmote
        if not name then return end
        local hum = c:WaitForChild("Humanoid", 10)
        if not hum then return end
        hum:WaitForChild("Animator", 5)
        task.wait(0.6)
        if FX.lastEmote == name and running then pcall(FX.playEmote, name) end
    end)

    local HttpService = game:GetService("HttpService")
    local DIR = "zenithmm2"
    local function fsOk() return Compat.writefile ~= nil and Compat.readfile ~= nil and Compat.isfile ~= nil end
    local function ensureDir()
        if Compat.makefolder and Compat.isfolder and not Compat.isfolder(DIR) then pcall(Compat.makefolder, DIR) end
    end
    FX.cfgList = function()
        local out = {}
        pcall(function()
            if Compat.listfiles and Compat.isfolder and Compat.isfolder(DIR) then
                for _, f in ipairs(Compat.listfiles(DIR)) do
                    local name = tostring(f):match("([^/\\]+)%.json$")
                    if name then out[#out + 1] = name end
                end
            end
        end)
        table.sort(out)
        if #out == 0 then out[1] = "default" end
        return out
    end
    FX.cfgSave = function(name)
        if not fsOk() then return false, "file API not supported" end
        ensureDir()
        local data = {}
        for k, v in pairs(CFG) do
            local t = type(v)
            if (t == "boolean" or t == "number" or t == "string") and not FX.DEAD_KEYS[k] then data[k] = v end
        end
        return pcall(function() Compat.writefile(DIR .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
    end
    FX.DEAD_KEYS = {killTool = true, autoSheriff = true, autoMurder = true, voteDupe = true, voteCopies = true,
        wings = true, espGrad = true, gradA = true, gradB = true, gradAnim = true, coinEsp = true, trailSmoke = true,
        wmTimer = true, lang = true, farmUnder = true, farmMode = true, infPart = true, infFov = true, autoPlay = true,
        botOn = true, botRole = true, botCode = true, botAutoFarm = true, apDanger = true, apHeight = true, apShowPath = true,
        apColor = true, wbStyle = true, wbMode = true, shootDelay = true, shootMax = true}
    FX.applyCfg = function(data)
        local n = 0
        for k, v in pairs(data) do
            if not FX.DEAD_KEYS[k] and CFG[k] ~= nil and type(CFG[k]) == type(v) then
                CFG[k] = v
                n += 1
            end
        end
        return n
    end
    local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function b64enc(data)
        local out = {}
        for i = 1, #data, 3 do
            local a, b, c = string.byte(data, i, i + 2)
            local n = a * 65536 + (b or 0) * 256 + (c or 0)
            local c1, c2 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64
            local c3, c4 = math.floor(n / 64) % 64, n % 64
            out[#out + 1] = string.sub(B64, c1 + 1, c1 + 1) .. string.sub(B64, c2 + 1, c2 + 1)
                .. (b and string.sub(B64, c3 + 1, c3 + 1) or "=") .. (c and string.sub(B64, c4 + 1, c4 + 1) or "=")
        end
        return table.concat(out)
    end
    local function b64dec(str)
        str = string.gsub(str, "[^%w%+/=]", "")
        local map = {}
        for i = 1, 64 do map[string.byte(B64, i)] = i - 1 end
        local out = {}
        for i = 1, #str, 4 do
            local a, b, c, d = string.byte(str, i, i + 3)
            local n1, n2 = map[a], map[b]
            if not n1 or not n2 then break end
            local n3, n4 = c and map[c], d and map[d]
            local n = n1 * 262144 + n2 * 4096 + (n3 or 0) * 64 + (n4 or 0)
            out[#out + 1] = string.char(math.floor(n / 65536) % 256)
            if n3 then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
            if n4 then out[#out + 1] = string.char(n % 256) end
        end
        return table.concat(out)
    end
    FX.cfgShareCode = function()
        local def = genv.ZenithCfgDefault or {}
        local data = {}
        for k, v in pairs(CFG) do
            local t = type(v)
            if (t == "boolean" or t == "number" or t == "string") and not FX.DEAD_KEYS[k] and def[k] ~= v then data[k] = v end
        end
        return "ZEN-" .. b64enc(HttpService:JSONEncode(data))
    end
    FX.cfgFromShare = function(code)
        code = tostring(code or ""):gsub("%s", "")
        if string.sub(code, 1, 4) == "ZEN-" then code = string.sub(code, 5) end
        if code == "" then return false, "empty code" end
        local ok, data = pcall(function() return HttpService:JSONDecode(b64dec(code)) end)
        if not ok or type(data) ~= "table" then return false, "bad code" end
        return true, FX.applyCfg(data)
    end
    FX.cfgLoad = function(name)
        if not fsOk() then return false, "file API not supported" end
        local path = DIR .. "/" .. name .. ".json"
        if not Compat.isfile(path) then return false, "not found" end
        local ok, data = pcall(function() return HttpService:JSONDecode(Compat.readfile(path)) end)
        if not ok or type(data) ~= "table" then return false, "bad file" end
        FX.applyCfg(data)
        return true
    end
    FX.cfgDelete = function(name)
        if Compat.delfile then pcall(Compat.delfile, DIR .. "/" .. name .. ".json") end
    end
    FX.cfgGetAuto = function()
        local ok, v = pcall(function()
            if Compat.isfile and Compat.isfile(DIR .. "/autoload.txt") then return Compat.readfile(DIR .. "/autoload.txt") end
        end)
        return ok and v or nil
    end
    FX.cfgSetAuto = function(name)
        if not fsOk() then return end
        ensureDir()
        pcall(Compat.writefile, DIR .. "/autoload.txt", name or "")
    end
end

connect(lp.CharacterAdded, function(c)
    local h = c:WaitForChild("Humanoid", 10)
    if FX.droneFlying then FX.droneCmd = "exit" end
    task.wait(0.2)
    local cam0 = workspace.CurrentCamera
    if cam0 and h and h.Parent then
        cam0.CameraType = Enum.CameraType.Custom
        cam0.CameraSubject = h
        pcall(function() lp.CameraMode = Enum.CameraMode.Classic end)
        if cam0.FieldOfView > 90 then cam0.FieldOfView = 70 end
    end
end)

do
    FX.applyFps = function()
        if Compat.setfpscap then pcall(Compat.setfpscap, CFG.fpsUnlock and 240 or 60) end
    end
    task.defer(function()
        if CFG.fpsUnlock then FX.applyFps() end
    end)
end

do
    local saved = {}
    local KORB = {RightUpperLeg = "rbxassetid://902942096", RightLowerLeg = "rbxassetid://902942093", RightFoot = "rbxassetid://902942089"}
    local KTEX = "rbxassetid://902843398"

    local function remember(p, fields)
        if saved[p] then return end
        local o = {}
        for _, f in ipairs(fields) do
            local ok, v = pcall(function() return p[f] end)
            if ok then o[f] = v end
        end
        saved[p] = o
    end
    local function restore(p)
        local o = saved[p]
        if not o then return end
        saved[p] = nil
        for f, v in pairs(o) do pcall(function() p[f] = v end) end
    end

    local function korblox(c, on)
        if c:FindFirstChild("RightUpperLeg") then
            for name, mesh in pairs(KORB) do
                local p = c:FindFirstChild(name)
                if p and p:IsA("MeshPart") then
                    if on then
                        remember(p, {"MeshId", "TextureID", "Transparency"})
                        local ok = pcall(function()
                            p.MeshId = mesh
                            p.TextureID = KTEX
                        end)
                        if name ~= "RightUpperLeg" or not ok then p.Transparency = 1 end
                    else
                        restore(p)
                    end
                end
            end
            local up = c:FindFirstChild("RightUpperLeg")
            local fb = up and up:FindFirstChild("ZenithKorblox")
            local meshOk = up and up.MeshId == KORB.RightUpperLeg
            if on and up and not meshOk and not fb then
                fb = Instance.new("Part")
                fb.Name = "ZenithKorblox"
                fb.Size = Vector3.new(1, 2, 1)
                fb.CanCollide, fb.CanQuery, fb.CanTouch, fb.Massless = false, false, false, true
                local sm = Instance.new("SpecialMesh")
                sm.MeshId = KORB.RightLowerLeg
                sm.TextureId = KTEX
                sm.Parent = fb
                local w = Instance.new("Weld")
                w.Part0, w.Part1, w.C0 = up, fb, CFrame.new(0, -0.9, 0)
                w.Parent = fb
                fb.Parent = up
            elseif not on and fb then
                fb:Destroy()
            end
        else
            local leg = c:FindFirstChild("Right Leg")
            if not leg then return end
            local sm = leg:FindFirstChild("ZenithKorblox")
            if on and not sm then
                sm = Instance.new("SpecialMesh")
                sm.Name = "ZenithKorblox"
                sm.MeshId = KORB.RightLowerLeg
                sm.TextureId = KTEX
                sm.Parent = leg
            elseif not on and sm then
                sm:Destroy()
            end
        end
    end

    local function headless(c, on)
        local head = c:FindFirstChild("Head")
        if not head then return end
        local list = {head}
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") then list[#list + 1] = d end
        end
        for _, p in ipairs(list) do
            if on then
                remember(p, {"Transparency"})
                if p.Transparency ~= 1 then p.Transparency = 1 end
            else
                restore(p)
            end
        end
    end

    local state = {k = false, h = false, char = nil}
    task.spawn(function()
        while running do
            local c = lp.Character
            if c then
                if state.char ~= c then
                    state.char, state.k, state.h = c, false, false
                end
                if CFG.fakeKorblox or state.k then
                    pcall(korblox, c, CFG.fakeKorblox)
                    state.k = CFG.fakeKorblox
                end
                if CFG.fakeHeadless or state.h then
                    pcall(headless, c, CFG.fakeHeadless)
                    state.h = CFG.fakeHeadless
                end
            end
            task.wait(0.5)
        end
    end)
    FX.cosmeticsOff = function()
        local c = lp.Character
        if c then
            pcall(korblox, c, false)
            pcall(headless, c, false)
        end
    end
end

do
    local cg, cimg
    local function buildCross()
        cg = Instance.new("ScreenGui")
        cg.Name = "ZenithCrosshair"
        cg.ResetOnSpawn = false
        cg.IgnoreGuiInset = true
        cg.DisplayOrder = 40
        pcall(function() cg.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not cg.Parent then cg.Parent = lp:WaitForChild("PlayerGui") end
        cimg = Instance.new("ImageLabel")
        cimg.BackgroundTransparency = 1
        cimg.AnchorPoint = Vector2.new(0.5, 0.5)
        cimg.Position = UDim2.fromScale(0.5, 0.5)
        cimg.Image = "rbxthumb://type=Asset&id=316279305&w=150&h=150"
        cimg.ScaleType = Enum.ScaleType.Fit
        cimg.Parent = cg
    end
    local crossAt, crossInput = nil, nil
    connect(UIS.InputBegan, function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            crossAt, crossInput = Vector2.new(input.Position.X, input.Position.Y), input
        end
    end)
    connect(UIS.InputChanged, function(input)
        if input == crossInput or input.UserInputType == Enum.UserInputType.MouseMovement then
            crossAt = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    local GuiService = game:GetService("GuiService")
    connect(RunService.RenderStepped, function()
        local c = lp.Character
        local show = running and CFG.crosshair and c ~= nil and ST.myGun() ~= nil
        if show then
            if not cg or not cg.Parent then buildCross() end
            cimg.Visible = true
            cimg.Size = UDim2.fromOffset(44, 44)
            if crossAt then
                local inset = GuiService:GetGuiInset()
                cimg.Position = UDim2.fromOffset(crossAt.X, crossAt.Y + inset.Y)
            else
                cimg.Position = UDim2.fromScale(0.5, 0.5)
            end
        elseif cimg then
            cimg.Visible = false
        end
    end)
    FX.crossOff = function()
        if cg then pcall(function() cg:Destroy() end) end
        cg, cimg = nil, nil
    end

end

do
    local hl, mats = nil, {}
    local function restoreMats()
        for p, o in pairs(mats) do
            if p.Parent then pcall(function() p.Material, p.Color = o[1], o[2] end) end
        end
        mats = {}
    end
    task.spawn(function()
        while running do
            pcall(function()
                local c = lp.Character
                if CFG.selfChams and c then
                    local mode = CFG.selfMode
                    local col = colorOf(CFG.selfColor)
                    local sgA, sgB = FX.gradOf("gSelf", tick())
                    if sgA then col = sgA end
                    if not hl or hl.Parent ~= c then
                        if hl then pcall(function() hl:Destroy() end) end
                        hl = Instance.new("Highlight")
                        hl.Name = "ZenithSelf"
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = c
                        restoreMats()
                    end
                    local matMode = FX.CHAM_MAT[mode] ~= nil
                    hl.FillColor, hl.OutlineColor = col, sgB or col
                    local fillT = FX.CHAM_FILL[mode] or 0.45
                    if mode == "Pulse" then fillT = 0.1 + 0.65 * (math.sin(tick() * 4) + 1) / 2 end
                    hl.FillTransparency = fillT
                    hl.OutlineTransparency = 0
                    hl.Enabled = true
                    if matMode then
                        local mat = FX.CHAM_MAT[mode]
                        for _, d in ipairs(c:GetDescendants()) do
                            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
                                if not mats[d] then mats[d] = {d.Material, d.Color} end
                                if d.Material ~= mat then d.Material = mat end
                                if d.Color ~= col then d.Color = col end
                            end
                        end
                    elseif next(mats) then
                        restoreMats()
                    end
                else
                    if hl then pcall(function() hl:Destroy() end) end
                    hl = nil
                    if next(mats) then restoreMats() end
                end
            end)
            task.wait(0.1)
        end
    end)
    FX.selfChamsOff = function()
        if hl then pcall(function() hl:Destroy() end) end
        hl = nil
        restoreMats()
    end

end

do
    local watched = setmetatable({}, {__mode = "k"})
    local lastGunSound = 0
    local function watch(snd)
        if watched[snd] then return end
        watched[snd] = true
        snd.Played:Connect(function()
            local now = tick()
            if now - lastGunSound < 0.3 then
                pcall(function() snd:Stop() end)
            else
                lastGunSound = now
            end
        end)
    end
    task.spawn(function()
        while running do
            pcall(function()
                local c = lp.Character
                local gun = c and c:FindFirstChild("Gun")
                if gun then
                    for _, d in ipairs(gun:GetDescendants()) do
                        if d:IsA("Sound") then watch(d) end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)

    local real, realVel
    local function myRoot()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then return hrp end
    end
    local function aaRestore()
        local hrp = myRoot()
        if real and hrp then hrp.CFrame = real end
        if realVel and hrp then
            hrp.AssemblyLinearVelocity = realVel
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        real, realVel = nil, nil
    end
    connect(RunService.Heartbeat, function()
        task.defer(function()
            if not running or not (CFG.aaDesync or CFG.invis) then return end
            local hrp = myRoot()
            if not hrp then return end
            -- your own stab / shot / kill all: stay where you really are so it counts
            if not CFG.invis and (busy or tick() - (FX.attackAt or 0) < 0.35) then return end
            if not CFG.invis then
                local ch0 = hrp.Parent
                if ch0 and (ch0:FindFirstChild("Gun") or ch0:FindFirstChild("Knife") or ch0:FindFirstChildOfClass("Tool")) then return end
            end
            real = real or hrp.CFrame
            local h = CFG.aaHeight
            local function rnd() return math.random(-1000, 1000) / 1000 end
            local off, rot
            if CFG.invis then
                -- invisible: for everyone else you are deep under the map
                off, rot = Vector3.new(0, -400, 0), real.Rotation
            else
                -- high up in the sky, thrown around every frame: nothing down here can hit it
                off = Vector3.new(rnd() * 120, 900 + math.random() * 1600, rnd() * 120)
                rot = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2)
                realVel = realVel or hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(rnd() * 5000, rnd() * 5000, rnd() * 5000)
                hrp.AssemblyAngularVelocity = Vector3.new(rnd() * 500, rnd() * 500, rnd() * 500)
            end
            hrp.CFrame = CFrame.new(real.Position + off) * rot
        end)
    end)
    task.spawn(function()
        local was = false
        while running do
            pcall(function()
                local c = lp.Character
                if c and (CFG.invis or was) then
                    for _, d in ipairs(c:GetDescendants()) do
                        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                            d.LocalTransparencyModifier = CFG.invis and 0.5 or 0
                        elseif d:IsA("Decal") then
                            d.LocalTransparencyModifier = CFG.invis and 0.5 or 0
                        end
                    end
                end
                was = CFG.invis
            end)
            task.wait(0.2)
        end
    end)
    RunService:BindToRenderStep("ZenithAA", Enum.RenderPriority.First.Value, aaRestore)
    connect(RunService.PreSimulation, aaRestore)
    FX.aaOff = function()
        pcall(function() RunService:UnbindFromRenderStep("ZenithAA") end)
        aaRestore()
    end
end

do
    local glows, wires = {}, {}
    FX.chamExtras = function(st)
        local liveG, liveW = {}, {}
        if st == "Glow" or st == "Wireframe" then
            for p, e in pairs(E) do
                local c = p ~= lp and p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local col = e.matColor
                if hrp and col and e.hl and e.hl.Enabled then
                    if st == "Glow" then
                        local l = glows[p]
                        if not l or l.Parent ~= hrp then
                            if l then pcall(function() l:Destroy() end) end
                            l = Instance.new("PointLight")
                            l.Name = "ZenithGlow"
                            l.Range, l.Brightness, l.Shadows = 9, 2.5, false
                            l.Parent = hrp
                            glows[p] = l
                        end
                        l.Color = col
                        liveG[p] = true
                    else
                        for _, d in ipairs(c:GetChildren()) do
                            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                                local sb = wires[d]
                                if not sb or sb.Parent == nil then
                                    sb = Instance.new("SelectionBox")
                                    sb.Name = "ZenithWire"
                                    sb.LineThickness = 0.025
                                    sb.SurfaceTransparency = 1
                                    sb.Adornee = d
                                    sb.Parent = d
                                    wires[d] = sb
                                end
                                sb.Color3 = col
                                liveW[d] = true
                            end
                        end
                    end
                end
            end
        end
        for p, l in pairs(glows) do
            if not liveG[p] then pcall(function() l:Destroy() end); glows[p] = nil end
        end
        for d, sb in pairs(wires) do
            if not liveW[d] then pcall(function() sb:Destroy() end); wires[d] = nil end
        end
    end

    -- chams on your own knife / gun
    local whl, wsaved = nil, {}
    local function wRestore()
        for p, o in pairs(wsaved) do
            if p.Parent then pcall(function() p.Material, p.Color = o[1], o[2] end) end
        end
        wsaved = {}
    end
    task.spawn(function()
        while running do
            pcall(function()
                local c = lp.Character
                local tool = c and (c:FindFirstChild("Knife") or c:FindFirstChild("Gun"))
                if CFG.wepChams and tool and tool:IsA("Tool") then
                    local mode = CFG.wepMode
                    local col = colorOf(CFG.wepColor)
                    local gA, gB = FX.gradOf("gWep", tick())
                    if gA then col = gA end
                    if not whl or whl.Parent ~= tool then
                        if whl then pcall(function() whl:Destroy() end) end
                        wRestore()
                        whl = Instance.new("Highlight")
                        whl.Name = "ZenithWeaponChams"
                        whl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        whl.Parent = tool
                    end
                    local fillT = FX.CHAM_FILL[mode] or 0.55
                    if mode == "Pulse" then fillT = 0.1 + 0.65 * (math.sin(tick() * 4) + 1) / 2 end
                    whl.FillColor, whl.OutlineColor = col, gB or col
                    whl.FillTransparency = fillT
                    whl.OutlineTransparency = 0
                    whl.Enabled = true
                    local mat = FX.CHAM_MAT[mode]
                    if mat then
                        for _, d in ipairs(tool:GetDescendants()) do
                            if d:IsA("BasePart") and d.Transparency < 1 then
                                if not wsaved[d] then wsaved[d] = {d.Material, d.Color} end
                                if d.Material ~= mat then d.Material = mat end
                                if d.Color ~= col then d.Color = col end
                            end
                        end
                    elseif next(wsaved) then
                        wRestore()
                    end
                else
                    if whl then pcall(function() whl:Destroy() end) end
                    whl = nil
                    if next(wsaved) then wRestore() end
                end
            end)
            task.wait(0.1)
        end
    end)
    FX.wepChamsOff = function()
        if whl then pcall(function() whl:Destroy() end) end
        whl = nil
        wRestore()
        FX.chamExtras(nil)
    end
end


-- Infection mode silent (survivor): aims every shot of the tool in your hands at the nearest zombie
do
    local function zombieTarget()
        local c = lp.Character
        local me = c and c:FindFirstChild("HumanoidRootPart")
        if not me then return nil end
        local best, bd
        local vp = cam.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local pc = p.Character
                local h = pc and pc:FindFirstChildOfClass("Humanoid")
                local r = pc and pc:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 and (ST.isZombie(p) or hostileRole(roles[p])) then
                    local part = pc:FindFirstChild("UpperTorso") or pc:FindFirstChild("Torso") or r
                    local d = (r.Position - me.Position).Magnitude
                    if not bd or d < bd then best, bd = part, d end
                end
            end
        end
        return best
    end

    ST.infRemote = function(remote)
        local c = lp.Character
        local tool = c and c:FindFirstChildOfClass("Tool")
        if not tool or not remote:IsDescendantOf(tool) then return false end
        if remote.Name == "Shoot" and ST.target then return false end
        return true
    end

    local function rewriteValue(v, origin, aim, part)
        local t = typeof(v)
        if t == "Vector3" then
            if math.abs(v.Magnitude - 1) < 0.05 then return (aim - origin).Unit, true end
            if (v - origin).Magnitude > 6 then return aim, true end
        elseif t == "CFrame" then
            if (v.Position - origin).Magnitude <= 12 then return CFrame.lookAt(v.Position, aim), true end
            return CFrame.new(aim), true
        elseif t == "Instance" and v:IsA("BasePart") then
            local m = v:FindFirstAncestorOfClass("Model")
            if m and m:FindFirstChildOfClass("Humanoid") and m ~= lp.Character then return part, true end
        end
        return v, false
    end

    ST.infRewrite = function(args)
        local part = zombieTarget()
        if not part then return false end
        local c = lp.Character
        local me = c and c:FindFirstChild("HumanoidRootPart")
        if not me then return false end
        local tool = c:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        local origin = (handle and handle.Position) or (me.Position + Vector3.new(0, 1.5, 0))
        local okp, ping = pcall(function() return lp:GetNetworkPing() end)
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart") or part
        local vel = root.AssemblyLinearVelocity
        local aim = part.Position + Vector3.new(vel.X, vel.Y * 0.4, vel.Z) * ((okp and ping or 0.1) + 0.05)
        local changed = false
        for i = 1, args.n do
            local v = args[i]
            if type(v) == "table" then
                for k, x in pairs(v) do
                    local nv, ch = rewriteValue(x, origin, aim, part)
                    if ch then
                        v[k] = nv
                        changed = true
                    end
                end
            else
                local nv, ch = rewriteValue(v, origin, aim, part)
                if ch then
                    args[i] = nv
                    changed = true
                end
            end
        end
        return changed
    end

    ST.infRay = function(o, d)
        if typeof(o) ~= "Vector3" or typeof(d) ~= "Vector3" or d.Magnitude < 15 then return nil end
        local c = lp.Character
        local tool = c and c:FindFirstChildOfClass("Tool")
        local me = c and c:FindFirstChild("HumanoidRootPart")
        if not tool or not me then return nil end
        if (o - me.Position).Magnitude > 12 and (o - cam.CFrame.Position).Magnitude > 12 then return nil end
        local part = zombieTarget()
        if not part then return nil end
        local okp, ping = pcall(function() return lp:GetNetworkPing() end)
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart") or part
        local vel = root.AssemblyLinearVelocity
        local aim = part.Position + Vector3.new(vel.X, vel.Y * 0.4, vel.Z) * ((okp and ping or 0.1) + 0.05)
        return (aim - o).Unit * d.Magnitude
    end

    task.spawn(function()
        while running do
            ST.infOn = CFG.infSilent == true
            task.wait(0.2)
        end
        ST.infOn = false
    end)
    FX.infOff = function() ST.infOn = false end
end


do
    local B = {label = nil, snap = nil}
    local function bagWord(n)
        n = string.lower(n)
        return string.find(n, "cand", 1, true) ~= nil or string.find(n, "coin", 1, true) ~= nil or string.find(n, "bag", 1, true) ~= nil
    end
    local function nearBagWord(l)
        local x = l
        for _ = 1, 4 do
            if not x then return false end
            if bagWord(x.Name) then return true end
            local par = x.Parent
            if par then
                for _, sib in ipairs(par:GetChildren()) do
                    if sib:IsA("GuiObject") and bagWord(sib.Name) then return true end
                end
            end
            x = par
        end
        return false
    end
    local function numbers()
        local out = {}
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return out end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") then
                local n = tonumber(string.match(d.Text, "^%s*(%d+)"))
                if n then out[d] = n end
            end
        end
        return out
    end
    FX.bagBefore = function()
        if B.label and B.label.Parent then return end
        B.label = nil
        B.snap = numbers()
    end
    FX.bagAfter = function()
        local snap = B.snap
        if not snap or (B.label and B.label.Parent) then return end
        B.snap = nil
        task.delay(0.4, function()
            local hits = {}
            for l, v in pairs(numbers()) do
                local old = snap[l]
                if old and v == old + 1 then hits[#hits + 1] = l end
            end
            local pick
            for _, l in ipairs(hits) do
                if nearBagWord(l) then
                    pick = l
                    break
                end
            end
            if not pick and #hits == 1 then pick = hits[1] end
            if pick then B.label = pick end
        end)
    end
    FX.bagCount = function()
        if B.label and B.label.Parent then
            return tonumber(string.match(B.label.Text, "^%s*(%d+)"))
        end
        return nil
    end
    task.spawn(function()
        while running do
            pcall(function()
                local inR = next(roles) ~= nil and inRound(lp)
                if not inR then
                    ST.bagFull = false
                    return
                end
                if ST.bagFull or not CFG.farm then return end
                local n = FX.bagCount()
                local full = (n ~= nil and n >= CFG.bagMax and n < 1000) or (n == nil and got >= CFG.bagMax)
                if full then
                    ST.bagFull = true
                    local t0 = tick()
                    while busy and tick() - t0 < 1.5 do task.wait(0.05) end
                    if holding then pcall(surface) end
                    task.wait(0.2)
                    local role = roles[lp]
                    local zombie = role ~= "Murderer" and hostileRole(role)
                    if CFG.bfKillMurder and findGun() and murdererHrp() then
                        local t1 = tick()
                        while running and murdererHrp() and findGun() and next(roles) ~= nil and tick() - t1 < 30 do
                            pcall(FX.shootNow, true)
                            task.wait(1.1)
                        end
                        task.wait(0.3)
                    end
                    if CFG.bfKillAll and (role == "Murderer" or hasKnife()) and FX.killAll then
                        pcall(FX.killAll)
                        task.wait(0.5)
                    end
                    if CFG.bfInfKillZombies and not zombie and findGun() then
                        local t1 = tick()
                        while running and murdererHrp() and tick() - t1 < 10 do
                            pcall(FX.shootNow)
                            task.wait(0.9)
                        end
                    end
                    if CFG.bfInfKillAll and zombie then
                        local c = lp.Character
                        local hrp = c and c:FindFirstChild("HumanoidRootPart")
                        local tool = c and c:FindFirstChildOfClass("Tool")
                        local handle = tool and tool:FindFirstChild("Handle")
                        for _, p in ipairs(Players:GetPlayers()) do
                            local pc = p ~= lp and p.Character
                            local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                            local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                            if ph and pr and ph.Health > 0 and not hostileRole(roles[p]) and not ST.isZombie(p) and hrp then
                                hrp.CFrame = pr.CFrame * CFrame.new(0, 0, 2)
                                if tool then pcall(function() tool:Activate() end) end
                                if handle and Compat.firetouchinterest then
                                    pcall(Compat.firetouchinterest, handle, pr, 0)
                                    pcall(Compat.firetouchinterest, handle, pr, 1)
                                end
                                pcall(Compat.firetouchinterest, hrp, pr, 0)
                                pcall(Compat.firetouchinterest, hrp, pr, 1)
                                task.wait(0.2)
                            end
                        end
                    end
                    if CFG.bfReset then
                        local c = lp.Character
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        if h then pcall(function() h.Health = 0 end) end
                        if FX.notify then FX.notify("Zenith", "reset") end
                    elseif CFG.bagLobby then
                        if FX.tpLobby then pcall(FX.tpLobby) end
                        if FX.notify then FX.notify("Zenith", "tp: lobby") end
                        if FX.flingKind and (CFG.lobbyFlingMurd or CFG.lobbyFlingSher or CFG.lobbyFlingAll) then
                            task.wait(1.5)
                            if CFG.lobbyFlingAll then
                                pcall(FX.flingKind, "All")
                            else
                                if CFG.lobbyFlingMurd then pcall(FX.flingKind, "Murderer") end
                                if CFG.lobbyFlingSher then pcall(FX.flingKind, "Sheriff") end
                            end
                        end
                    end
                end
            end)
            task.wait(0.25)
        end
    end)
end

do
    connect(UIS.InputBegan, function(i, gpe)
        if gpe or FX.bindListening or not running or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local name = i.KeyCode.Name
        for key, code in pairs(FX.parseBinds()) do
            if code == name then
                local t = FX.toggles[key]
                if t and t.obj and t.obj.Set then
                    pcall(function() t.obj:Set(not CFG[key]) end)
                else
                    CFG[key] = not CFG[key]
                end
            end
        end
    end)

    local H = {}
    local hudPos = UDim2.new(0, 15, 0.32, 0)
    local function destroy()
        if H.drag then pcall(function() H.drag:Disconnect() end) end
        if H.gui then pcall(function() H.gui:Destroy() end) end
        H = {}
    end
    FX.bindHudDestroy = destroy

    local function build()
        local P = FX.themePalette()
        local g = Instance.new("ScreenGui")
        g.Name = "ZenithKeybinds"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.DisplayOrder = 48
        pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 178, 0, 0)
        main.AutomaticSize = Enum.AutomaticSize.Y
        main.Position = hudPos
        main.BackgroundColor3 = P.bg
        main.BackgroundTransparency = 0.12
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = g
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
        local st = Instance.new("UIStroke")
        st.Color = P.accentDim
        st.Transparency = 0.2
        st.Parent = main
        local pad = Instance.new("UIPadding")
        pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
        pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
        pad.Parent = main
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 5)
        lay.Parent = main
        local head = Instance.new("Frame")
        head.BackgroundTransparency = 1
        head.Size = UDim2.new(1, 0, 0, 18)
        head.LayoutOrder = 0
        head.Parent = main
        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = P.accent
        dot.BorderSizePixel = 0
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 0, 0.5, 0)
        dot.Size = UDim2.fromOffset(6, 6)
        dot.Parent = head
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(12, 0)
        title.Size = UDim2.new(1, -12, 1, 0)
        title.Font = Enum.Font.GothamBold
        title.Text = "Keybinds"
        title.TextColor3 = P.text
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = head
        local line = Instance.new("Frame")
        line.BackgroundColor3 = P.accentDim
        line.BackgroundTransparency = 0.4
        line.BorderSizePixel = 0
        line.Size = UDim2.new(1, 0, 0, 1)
        line.LayoutOrder = 1
        line.Parent = main
        local rows = Instance.new("Frame")
        rows.BackgroundTransparency = 1
        rows.Size = UDim2.new(1, 0, 0, 0)
        rows.AutomaticSize = Enum.AutomaticSize.Y
        rows.LayoutOrder = 2
        rows.Parent = main
        local rl = Instance.new("UIListLayout")
        rl.SortOrder = Enum.SortOrder.LayoutOrder
        rl.Padding = UDim.new(0, 3)
        rl.Parent = rows
        H = {gui = g, main = main, rows = rows, P = P}
        local dragging, ds, sp = false, nil, nil
        main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, ds, sp = true, input.Position, main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        hudPos = main.Position
                    end
                end)
            end
        end)
        H.drag = UIS.InputChanged:Connect(function(input)
            if not dragging or not ds then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - ds
                main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    local function refresh()
        local list = {}
        for key, code in pairs(FX.parseBinds()) do
            local t = FX.toggles[key]
            list[#list + 1] = {title = t and tostring(t.title) or key, code = code, on = CFG[key] == true}
        end
        table.sort(list, function(a, b) return a.title < b.title end)
        local sig = {}
        for _, it in ipairs(list) do sig[#sig + 1] = it.title .. it.code .. tostring(it.on) end
        sig = table.concat(sig, "|")
        if sig == H.sig then return end
        H.sig = sig
        local P = H.P
        for _, ch in ipairs(H.rows:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() end
        end
        if #list == 0 then
            local e = Instance.new("TextLabel")
            e.BackgroundTransparency = 1
            e.Size = UDim2.new(1, 0, 0, 16)
            e.Font = Enum.Font.Gotham
            e.Text = "No binds yet"
            e.TextColor3 = P.sub
            e.TextSize = 11
            e.TextXAlignment = Enum.TextXAlignment.Left
            e.Parent = H.rows
            return
        end
        for i, it in ipairs(list) do
            local r = Instance.new("Frame")
            r.BackgroundTransparency = 1
            r.Size = UDim2.new(1, 0, 0, 18)
            r.LayoutOrder = i
            r.Parent = H.rows
            local nm = Instance.new("TextLabel")
            nm.BackgroundTransparency = 1
            nm.Size = UDim2.new(1, -56, 1, 0)
            nm.Font = Enum.Font.GothamMedium
            nm.Text = it.title
            nm.TextColor3 = it.on and P.text or P.sub
            nm.TextSize = 11
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = r
            local pill = Instance.new("TextLabel")
            pill.AnchorPoint = Vector2.new(1, 0.5)
            pill.Position = UDim2.new(1, 0, 0.5, 0)
            pill.Size = UDim2.fromOffset(50, 16)
            pill.BackgroundColor3 = it.on and P.accent or (P.row or P.bg)
            pill.BackgroundTransparency = it.on and 0 or 0.2
            pill.Font = Enum.Font.GothamBold
            pill.Text = it.code
            pill.TextColor3 = it.on and ((P.accent.R + P.accent.G + P.accent.B) > 1.8 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)) or P.sub
            pill.TextSize = 10
            pill.TextTruncate = Enum.TextTruncate.AtEnd
            pill.Parent = r
            Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 8)
        end
    end

    task.spawn(function()
        while running do
            pcall(function()
                if CFG.bindHud and FX.themePalette and not FX.nlHotkeys then
                    if not H.gui or not H.gui.Parent then build() end
                    refresh()
                elseif H.gui then
                    destroy()
                end
            end)
            task.wait(0.25)
        end
    end)
end

-- Vote duper: stand on a map's vote pad, die, respawn, stand on it again, until voting is over
do
    local V = {running = false, target = nil, loops = 0}
    FX.padLive = function(m)
        local icon = m:FindFirstChild("MapIcon", true)
        if not (icon and icon:IsA("ImageLabel") and icon.Image ~= "" and icon.Visible) then return false end
        for _, gname in ipairs({"MapInfoGui", "VoteInfoGui"}) do
            local g = m:FindFirstChild(gname, true)
            if g and g:IsA("LayerCollector") and g.Enabled == false then return false end
        end
        return true
    end
    FX.votePads = function()
        local lobby = workspace:FindFirstChild("Lobby")
        local vp = lobby and lobby:FindFirstChild("VotePads")
        local out = {}
        if not vp then return out end
        for _, m in ipairs(vp:GetChildren()) do
            local pad = m:FindFirstChild("Pad")
            if pad and pad:IsA("BasePart") and FX.padLive(m) then
                local icon = m:FindFirstChild("MapIcon", true)
                local name = m:FindFirstChild("MapName", true)
                local votes = m:FindFirstChild("Votes", true)
                local title = (name and name:IsA("TextLabel") and name.Text ~= "") and name.Text or m.Name
                local label = title
                if votes and votes:IsA("TextLabel") and votes.Text ~= "" then label = title .. " | " .. votes.Text end
                out[#out + 1] = {model = m, image = (icon and icon:IsA("ImageLabel")) and icon.Image or "", label = label, name = title}
            end
        end
        table.sort(out, function(a, b) return a.model.Name < b.model.Name end)
        return out
    end
    FX.voteStop = function()
        V.running = false
    end

    -- seconds left before the round starts, read from the lobby countdown ("... через" / "starting in" + a number)
    local cdLabel
    local function lobbyCountdown()
        if cdLabel and cdLabel.Parent and cdLabel.Visible then
            local n = tonumber(string.match(cdLabel.Text, "(%d+)"))
            if n then return n end
        end
        cdLabel = nil
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and d.Visible then
                local t = string.lower(d.Text)
                if string.find(t, "через", 1, true) or string.find(t, "starting", 1, true) or string.find(t, "start in", 1, true)
                    or string.find(t, "начн", 1, true) then
                    local n = tonumber(string.match(d.Text, "(%d+)"))
                    if n then
                        cdLabel = d
                        return n
                    end
                    local par = d.Parent
                    if par then
                        for _, sib in ipairs(par:GetDescendants()) do
                            if sib:IsA("TextLabel") and sib ~= d then
                                local v = tonumber(string.match(sib.Text, "^%s*(%d+)%s*$"))
                                if v then
                                    cdLabel = sib
                                    return v
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end
    local function votingOver()
        local left = lobbyCountdown()
        return left ~= nil and left <= 6
    end

    local function votesOf(m)
        local v = m and m:FindFirstChild("Votes", true)
        if v and v:IsA("TextLabel") then return tonumber(string.match(v.Text, "(%d+)")) end
        return nil
    end

    local function waitRespawn(old)
        local t0 = tick()
        while running and tick() - t0 < 25 do
            local c = lp.Character
            if c and c ~= old then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then return c end
            end
            task.wait()
        end
        return nil
    end

    local Http = game:GetService("HttpService")
    local book = {
        {name = "Police Station", image = "rbxassetid://3214479176"},
        {name = "Barn", image = "rbxassetid://11275868758"},
        {name = "Office 3", image = "rbxassetid://3214478924"},
        {name = "Bio Lab", image = "rbxassetid://3214475802"},
        {name = "Workplace", image = "rbxassetid://3214479481"},
        {name = "Factory", image = "rbxassetid://3214476069"},
        {name = "Vampire's Castle", image = "rbxassetid://119631273448225"},
        {name = "Hospital 3", image = "rbxassetid://3214476562"},
        {name = "Farmhouse", image = "rbxassetid://7808084105"},
        {name = "Mineshaft", image = "rbxassetid://11286327533"},
        {name = "Haunted House 2", image = "rbxassetid://144256000"},
        {name = "Spaceship", image = "rbxassetid://120032355857563"},
        {name = "Mansion 2", image = "rbxassetid://3214477676"},
        {name = "Bank 2", image = "rbxassetid://3214475169"},
        {name = "Hotel 2", image = "rbxassetid://3214477063"},
        {name = "Manor", image = "rbxassetid://7808084572"},
        {name = "Research Facility", image = "rbxassetid://4751350477"},
        {name = "Mil Base", image = "rbxassetid://3214477899"}
    }
    local function saveBook() end
    FX.voteWants = function()
        local set = {}
        for img in string.gmatch(CFG.voteWant or "", "[^|]+") do set[img] = true end
        return set
    end
    FX.mapBook = function()
        local out, seen, seenName = {}, {}, {}
        local function nm(x) return string.lower(tostring(x or "")):gsub("%s+", "") end
        for _, it in ipairs(FX.votePads()) do
            if it.image ~= "" and not seen[it.image] and not seenName[nm(it.label)] then
                seen[it.image] = true
                seenName[nm(it.label)] = true
                out[#out + 1] = {label = it.label, image = it.image, selected = FX.voteWants()[it.image] == true, live = true}
            end
        end
        local rest = {}
        for _, b in ipairs(book) do
            if not seen[b.image] and not seenName[nm(b.name)] then
                seen[b.image] = true
                seenName[nm(b.name)] = true
                rest[#rest + 1] = {label = b.name, image = b.image, selected = FX.voteWants()[b.image] == true}
            end
        end
        table.sort(rest, function(a, b) return a.label < b.label end)
        for _, r in ipairs(rest) do out[#out + 1] = r end
        return out
    end
    local function learn()
        local changed = false
        for _, it in ipairs(FX.votePads()) do
            if it.image ~= "" then
                local found
                for _, b in ipairs(book) do
                    if b.image == it.image then
                        found = b
                        break
                    end
                end
                if not found then
                    book[#book + 1] = {name = it.name, image = it.image}
                    changed = true
                elseif found.name ~= it.name then
                    found.name = it.name
                    changed = true
                end
            end
        end
        if changed then saveBook() end
        return changed
    end

    FX.voteDupe = function(item)
        if not item or not item.model then return end
        V.running = false
        task.wait(0.1)
        V.running, V.target = true, item.model
        task.spawn(function()
            local over, checkAt = false, 0
            local function stillOn()
                if tick() - checkAt > 0.5 then
                    checkAt = tick()
                    over = not (V.target and V.target.Parent and FX.padLive(V.target)) or votingOver()
                end
                return running and V.running and not over
            end
            local function standCF(pad, hum, hrp, c)
                local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
                local cf, sz = pad.CFrame, pad.Size
                local half = 0.5 * (math.abs(cf.RightVector.Y) * sz.X + math.abs(cf.UpVector.Y) * sz.Y + math.abs(cf.LookVector.Y) * sz.Z)
                local floorY = pad.Position.Y - half
                local rpFloor = RaycastParams.new()
                rpFloor.FilterType = Enum.RaycastFilterType.Exclude
                rpFloor.FilterDescendantsInstances = {pad, c}
                local hit = workspace:Raycast(Vector3.new(pad.Position.X, pad.Position.Y + half + 2, pad.Position.Z), Vector3.new(0, -(half * 2 + 60), 0), rpFloor)
                if hit then floorY = hit.Position.Y end
                local legs = (hum.RigType == Enum.HumanoidRigType.R6) and 3 or (hum.HipHeight + hrp.Size.Y / 2)
                return CFrame.new(Vector3.new(pad.Position.X, floorY + legs, pad.Position.Z)) * CFrame.Angles(0, yaw, 0)
            end
            local function touchAll(c, pad)
                for _, part in ipairs(c:GetChildren()) do
                    if part:IsA("BasePart") then
                        pcall(Compat.firetouchinterest, part, pad, 0)
                        pcall(Compat.firetouchinterest, part, pad, 1)
                    end
                end
            end
            while stillOn() do
                local pad = V.target:FindFirstChild("Pad")
                local c = lp.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if not pad then break end
                if hum and hrp and hum.Health > 0 then
                    local stand = standCF(pad, hum, hrp, c)
                    local before = votesOf(V.target)
                    local t1 = tick()
                    local done = false
                    repeat
                        hrp.CFrame = stand
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        touchAll(c, pad)
                        RunService.Heartbeat:Wait()
                        local now = votesOf(V.target)
                        -- counted -> reset straight away; no readable count -> a short stand is enough
                        if before ~= nil and now ~= nil then done = now > before else done = tick() - t1 > 0.25 end
                    until done or tick() - t1 > 2 or not V.running
                    if not stillOn() then break end
                    pcall(function() c:BreakJoints() end)
                    pcall(function() hum.Health = 0 end)
                end
                if not waitRespawn(c) then break end
            end
            V.running = false
        end)
    end

    FX.voteWantClick = function(it)
        local set = FX.voteWants()
        if set[it.image] then
            set[it.image] = nil
            if V.running and V.target then
                for _, p in ipairs(FX.votePads()) do
                    if p.model == V.target and p.image == it.image then V.running = false end
                end
            end
        else
            set[it.image] = true
        end
        local list = {}
        for img in pairs(set) do list[#list + 1] = img end
        CFG.voteWant = table.concat(list, "|")
        if set[it.image] and not V.running then
            for _, p in ipairs(FX.votePads()) do
                if p.image == it.image then
                    FX.voteDupe(p)
                    return
                end
            end
        end
    end

    -- learn maps from the pads and start the duper as soon as the chosen map shows up
    task.spawn(function()
        local session
        while running do
            pcall(function()
                learn()
                local pads = FX.votePads()
                if #pads == 0 then
                    session = nil
                    return
                end
                if CFG.voteWant == "" or V.running then return end
                local want = FX.voteWants()
                for _, it in ipairs(pads) do
                    if want[it.image] and session ~= it.model then
                        session = it.model
                        FX.voteDupe(it)
                        break
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

-- Touch Fling: anyone who bumps into you flies off; your own speed is put back before you see it
do
    task.spawn(function()
        local movel = 0.1
        while running do
            if CFG.touchFling then
                RunService.Heartbeat:Wait()
                local c = lp.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    if hrp.Parent then hrp.AssemblyLinearVelocity = vel end
                    RunService.Stepped:Wait()
                    if hrp.Parent then hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0) end
                    movel = -movel
                end
            else
                task.wait(0.2)
            end
        end
    end)
end

-- Air Strafe / Auto Strafe
do
    local ang = 0
    connect(RunService.Heartbeat, function(dt)
        if not running or not (CFG.airStrafe or CFG.autoStrafe) then return end
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 or hum.Sit then return end
        local st = hum:GetState()
        local inAir = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping or hum.FloorMaterial == Enum.Material.Air
        local v = hrp.AssemblyLinearVelocity
        local flat = Vector3.new(v.X, 0, v.Z)

        -- in the air, push toward where you are moving
        if CFG.airStrafe and inAir then
            local md = hum.MoveDirection
            if md.Magnitude > 0.1 then
                local nv = flat + md.Unit * CFG.airAccel * dt
                if nv.Magnitude > CFG.airMax then nv = nv.Unit * CFG.airMax end
                flat = nv
                hrp.AssemblyLinearVelocity = Vector3.new(nv.X, v.Y, nv.Z)
            end
        end

        -- in the air, curve toward where the camera looks and keep gaining speed
        if CFG.autoStrafe and inAir then
            local look = workspace.CurrentCamera.CFrame.LookVector
            local want = Vector3.new(look.X, 0, look.Z)
            if want.Magnitude > 0.01 then
                want = want.Unit
                local spd = math.min(math.max(flat.Magnitude, hum.WalkSpeed) + CFG.strafeGain * dt, CFG.strafeMax)
                local dir = flat.Magnitude > 0.1 and flat.Unit:Lerp(want, math.clamp(dt * 6, 0, 1)) or want
                if dir.Magnitude > 0.01 then dir = dir.Unit end
                hrp.AssemblyLinearVelocity = Vector3.new(dir.X * spd, v.Y, dir.Z * spd)
            end
        end

    end)
end

-- Rain: falling streaks around your camera (only you see it)
do
    local R = {}
    local function clear()
        if R.part then pcall(function() R.part:Destroy() end) end
        R = {}
    end
    FX.rainOff = clear
    local function build()
        local p = Instance.new("Part")
        p.Name = "ZenithRain"
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.Transparency = 1
        p.Size = Vector3.new(140, 1, 140)
        p.Parent = workspace
        local e = Instance.new("ParticleEmitter")
        e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        e.EmissionDirection = Enum.NormalId.Bottom
        e.Orientation = Enum.ParticleOrientation.VelocityParallel
        e.Lifetime = NumberRange.new(1.1, 1.5)
        e.Speed = NumberRange.new(70, 85)
        e.SpreadAngle = Vector2.new(4, 4)
        e.Size = NumberSequence.new(0.12)
        e.Squash = NumberSequence.new(-2.6)
        e.Transparency = NumberSequence.new(0.35, 0.6)
        e.LightEmission = 0.25
        e.Shape = Enum.ParticleEmitterShape.Box
        pcall(function() e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume end)
        e.Parent = p
        R = {part = p, emit = e}
    end
    connect(RunService.RenderStepped, function()
        if not running or not CFG.rain then
            if R.part then clear() end
            return
        end
        if not (R.part and R.part.Parent) then build() end
        local cpos = workspace.CurrentCamera.CFrame.Position
        R.part.CFrame = CFrame.new(cpos + Vector3.new(0, 45, 0))
        R.emit.Rate = CFG.rainRate
        R.emit.Color = ColorSequence.new(colorOf(CFG.rainColor))
    end)
end

-- ready shaders: one tap, no settings
do
    local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
    local P = {
        {"Cinematic", {rgb(40, 50, 70), rgb(200, 170, 140)}, {cc = {-0.02, 0.15, -0.1, rgb(255, 245, 235)}, bloom = {0.6, 24, 1.8}, rays = {0.06, 0.4}, exp = -0.1}},
        {"Golden Hour", {rgb(255, 170, 90), rgb(120, 60, 40)}, {clock = 17.6, cc = {0.03, 0.1, 0.15, rgb(255, 220, 180)}, bloom = {0.8, 30, 1.5}, rays = {0.15, 0.6}, atmo = {0.3, rgb(255, 190, 140), rgb(200, 120, 90), 0.5, 1.5}}},
        {"Night", {rgb(10, 15, 40), rgb(50, 60, 110)}, {clock = 0.5, amb = rgb(40, 45, 70), out = rgb(60, 70, 110), cc = {-0.05, 0.1, -0.2, rgb(190, 205, 255)}, bloom = {1, 20, 1.2}}},
        {"Neon City", {rgb(120, 0, 180), rgb(0, 200, 255)}, {clock = 0, amb = rgb(80, 30, 120), cc = {0, 0.25, 0.5, rgb(255, 200, 255)}, bloom = {1.5, 40, 0.9}}},
        {"Cold", {rgb(210, 230, 255), rgb(90, 120, 160)}, {cc = {0, 0.1, -0.15, rgb(200, 225, 255)}, atmo = {0.25, rgb(200, 230, 255), rgb(150, 190, 230), 0, 1}}},
        {"Warm", {rgb(255, 210, 170), rgb(160, 90, 60)}, {cc = {0.02, 0.05, 0.1, rgb(255, 225, 200)}}},
        {"Vintage", {rgb(210, 190, 150), rgb(110, 90, 70)}, {cc = {0.02, -0.05, -0.35, rgb(255, 235, 200)}, bloom = {0.3, 20, 2}}},
        {"Noir", {rgb(230, 230, 230), rgb(20, 20, 20)}, {cc = {0, 0.3, -1, rgb(255, 255, 255)}}},
        {"Vivid", {rgb(0, 200, 120), rgb(255, 80, 40)}, {cc = {0.02, 0.2, 0.6, rgb(255, 255, 255)}}},
        {"Dreamy", {rgb(255, 210, 240), rgb(180, 160, 230)}, {cc = {0.05, -0.05, 0.1, rgb(255, 235, 250)}, bloom = {1.2, 56, 0.8}, atmo = {0.35, rgb(255, 220, 240), rgb(200, 170, 220), 0.3, 1.8}}},
        {"Toxic", {rgb(150, 255, 100), rgb(30, 70, 20)}, {cc = {0, 0.15, 0.2, rgb(180, 255, 150)}, atmo = {0.4, rgb(150, 255, 120), rgb(60, 120, 40), 0, 2}}},
        {"Blood", {rgb(255, 70, 70), rgb(60, 0, 0)}, {clock = 18.5, cc = {-0.03, 0.2, 0.1, rgb(255, 150, 150)}, atmo = {0.35, rgb(255, 80, 80), rgb(120, 10, 10), 0, 1.5}}},
        {"Ocean", {rgb(90, 190, 255), rgb(10, 50, 110)}, {cc = {0, 0.1, 0.1, rgb(170, 220, 255)}, atmo = {0.3, rgb(120, 200, 255), rgb(40, 90, 160), 0, 1.2}}},
        {"Foggy", {rgb(205, 210, 220), rgb(140, 145, 155)}, {fog = {140, rgb(190, 195, 205)}, cc = {0.02, -0.1, -0.25, rgb(255, 255, 255)}, atmo = {0.55, rgb(200, 205, 215), rgb(160, 165, 175), 0, 2.5}}},
        {"Pastel", {rgb(255, 220, 235), rgb(200, 230, 255)}, {cc = {0.06, -0.15, -0.1, rgb(255, 240, 250)}, bloom = {0.5, 30, 1.6}}},
        {"Midnight", {rgb(90, 40, 160), rgb(20, 10, 50)}, {clock = 0, amb = rgb(70, 40, 110), out = rgb(90, 60, 140), cc = {-0.02, 0.15, 0.2, rgb(220, 190, 255)}, atmo = {0.3, rgb(140, 90, 220), rgb(60, 30, 120), 0.2, 1.5}}},
        {"Desert", {rgb(255, 220, 150), rgb(190, 140, 80)}, {clock = 13, cc = {0.03, 0.1, 0.05, rgb(255, 230, 190)}, rays = {0.2, 0.7}, atmo = {0.35, rgb(240, 210, 160), rgb(200, 160, 110), 0.2, 2}}},
        {"Matrix", {rgb(0, 255, 100), rgb(0, 30, 10)}, {cc = {0, 0.25, -0.6, rgb(150, 255, 170)}, bloom = {0.8, 24, 1.2}}},
        {"Sunrise", {rgb(255, 200, 150), rgb(120, 150, 220)}, {clock = 6.5, cc = {0.02, 0.08, 0.1, rgb(255, 225, 205)}, rays = {0.2, 0.8}, bloom = {0.7, 30, 1.4}}},
        {"Overcast", {rgb(170, 175, 185), rgb(110, 115, 125)}, {cc = {-0.03, -0.05, -0.3, rgb(225, 230, 240)}, atmo = {0.45, rgb(180, 185, 195), rgb(140, 145, 155), 0, 1.6}}},
        {"Rainy", {rgb(120, 135, 150), rgb(50, 60, 75)}, {clock = 16, cc = {-0.06, 0.05, -0.3, rgb(200, 215, 230)}, atmo = {0.5, rgb(140, 155, 170), rgb(70, 85, 100), 0, 2}}},
        {"Snowy", {rgb(235, 245, 255), rgb(170, 195, 220)}, {cc = {0.08, -0.05, -0.2, rgb(235, 245, 255)}, bloom = {0.6, 30, 1.4}, atmo = {0.4, rgb(230, 240, 255), rgb(190, 210, 235), 0, 1.8}}},
        {"Sepia", {rgb(220, 190, 140), rgb(110, 80, 50)}, {cc = {0.02, 0.05, -0.8, rgb(255, 220, 170)}}},
        {"Retro", {rgb(255, 150, 120), rgb(70, 40, 110)}, {cc = {0, 0.15, 0.25, rgb(255, 210, 220)}, bloom = {0.9, 30, 1.1}}},
        {"Synthwave", {rgb(255, 60, 180), rgb(40, 10, 80)}, {clock = 19, amb = rgb(110, 40, 140), cc = {0, 0.2, 0.4, rgb(255, 170, 230)}, bloom = {1.3, 40, 0.9}}},
        {"Cyberpunk", {rgb(255, 230, 0), rgb(0, 160, 255)}, {clock = 22, amb = rgb(60, 50, 110), cc = {0, 0.3, 0.45, rgb(220, 230, 255)}, bloom = {1.4, 36, 0.9}}},
        {"Horror", {rgb(70, 60, 60), rgb(5, 0, 0)}, {clock = 0, amb = rgb(30, 20, 20), cc = {-0.1, 0.3, -0.5, rgb(255, 200, 200)}, atmo = {0.6, rgb(60, 40, 40), rgb(20, 0, 0), 0, 2.5}}},
        {"Halloween", {rgb(255, 130, 20), rgb(60, 20, 90)}, {clock = 19.5, amb = rgb(90, 50, 110), cc = {0, 0.2, 0.25, rgb(255, 190, 140)}, bloom = {1, 30, 1.1}, atmo = {0.35, rgb(255, 140, 60), rgb(90, 30, 110), 0.2, 1.6}}},
        {"Christmas", {rgb(220, 30, 40), rgb(20, 120, 50)}, {cc = {0.03, 0.12, 0.2, rgb(255, 240, 235)}, bloom = {0.8, 28, 1.3}, atmo = {0.3, rgb(240, 245, 255), rgb(200, 210, 230), 0.1, 1.4}}},
        {"Lush", {rgb(120, 230, 120), rgb(20, 90, 40)}, {cc = {0.02, 0.1, 0.35, rgb(225, 255, 215)}, rays = {0.12, 0.6}}},
        {"Autumn", {rgb(240, 150, 60), rgb(120, 50, 20)}, {clock = 16.5, cc = {0.02, 0.08, 0.15, rgb(255, 215, 170)}, atmo = {0.25, rgb(240, 180, 120), rgb(170, 100, 60), 0.1, 1.2}}},
        {"Underwater", {rgb(40, 170, 200), rgb(0, 40, 80)}, {cc = {-0.04, 0.05, 0, rgb(130, 210, 230)}, fog = {120, rgb(30, 110, 150)}, atmo = {0.6, rgb(40, 140, 180), rgb(0, 60, 100), 0, 2}}},
        {"Mars", {rgb(230, 110, 60), rgb(110, 40, 20)}, {cc = {0, 0.15, 0.1, rgb(255, 170, 130)}, atmo = {0.45, rgb(230, 130, 80), rgb(140, 60, 30), 0.1, 2}}},
        {"Moonlight", {rgb(120, 140, 200), rgb(15, 20, 45)}, {clock = 1, amb = rgb(60, 70, 110), out = rgb(80, 95, 140), cc = {0.02, 0.1, -0.3, rgb(190, 205, 255)}, bloom = {0.8, 24, 1.2}}},
        {"Infrared", {rgb(255, 80, 200), rgb(255, 230, 255)}, {cc = {0.05, 0.25, 0.3, rgb(255, 160, 220)}}},
        {"Thermal", {rgb(255, 230, 0), rgb(100, 0, 160)}, {cc = {0, 0.4, 0.6, rgb(255, 180, 120)}, bloom = {0.6, 20, 1.3}}},
        {"Bleach", {rgb(245, 245, 240), rgb(170, 170, 165)}, {cc = {0.1, -0.1, -0.5, rgb(255, 255, 250)}, bloom = {0.5, 30, 1.6}}},
        {"High Contrast", {rgb(255, 255, 255), rgb(0, 0, 0)}, {cc = {0, 0.6, 0.15, rgb(255, 255, 255)}}},
        {"Soft", {rgb(240, 235, 245), rgb(200, 205, 225)}, {cc = {0.04, -0.2, -0.05, rgb(255, 250, 255)}, bloom = {0.6, 40, 1.4}}},
        {"Gold", {rgb(255, 210, 90), rgb(140, 90, 20)}, {cc = {0.03, 0.12, 0.2, rgb(255, 225, 150)}, bloom = {1, 30, 1.2}, rays = {0.15, 0.6}}},
        {"Ice", {rgb(200, 240, 255), rgb(60, 130, 200)}, {cc = {0.03, 0.12, 0, rgb(200, 235, 255)}, bloom = {0.7, 28, 1.3}}},
        {"Lava", {rgb(255, 120, 0), rgb(60, 0, 0)}, {clock = 20, amb = rgb(120, 40, 10), cc = {0, 0.25, 0.3, rgb(255, 160, 110)}, bloom = {1.2, 30, 0.9}, atmo = {0.4, rgb(255, 100, 40), rgb(80, 10, 0), 0.3, 1.8}}},
        {"Candy", {rgb(255, 170, 220), rgb(170, 220, 255)}, {cc = {0.05, 0.05, 0.4, rgb(255, 230, 245)}, bloom = {0.8, 36, 1.2}}},
    }
    local byName = {}
    for _, p in ipairs(P) do byName[p[1]] = p end
    local fx, saved = {}, nil
    local function restore()
        for _, e in pairs(fx) do pcall(function() e:Destroy() end) end
        fx = {}
        if saved then
            for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
            saved = nil
        end
    end
    FX.presetOff = restore
    local function apply(def)
        if not saved then
            saved = {ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor, ExposureCompensation = Lighting.ExposureCompensation}
        end
        local function get(class, name)
            local e = fx[name]
            if not e or not e.Parent then
                e = Instance.new(class)
                e.Name = name
                e.Parent = Lighting
                fx[name] = e
            end
            return e
        end
        if def.cc then
            local cc = get("ColorCorrectionEffect", "ZenithPresetCC")
            cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = def.cc[1], def.cc[2], def.cc[3], def.cc[4]
        elseif fx.ZenithPresetCC then fx.ZenithPresetCC:Destroy() end
        if def.bloom then
            local b = get("BloomEffect", "ZenithPresetBloom")
            b.Intensity, b.Size, b.Threshold = def.bloom[1], def.bloom[2], def.bloom[3]
        elseif fx.ZenithPresetBloom then fx.ZenithPresetBloom:Destroy() end
        if def.rays then
            local r = get("SunRaysEffect", "ZenithPresetRays")
            r.Intensity, r.Spread = def.rays[1], def.rays[2]
        elseif fx.ZenithPresetRays then fx.ZenithPresetRays:Destroy() end
        if def.atmo and (CFG.skybox == nil or CFG.skybox == "Off") then
            local a = get("Atmosphere", "ZenithPresetAtmo")
            a.Density, a.Color, a.Decay, a.Glare, a.Haze = def.atmo[1], def.atmo[2], def.atmo[3], def.atmo[4], def.atmo[5]
        elseif fx.ZenithPresetAtmo then fx.ZenithPresetAtmo:Destroy() end
        Lighting.ClockTime = def.clock or saved.ClockTime
        Lighting.Ambient = def.amb or saved.Ambient
        Lighting.OutdoorAmbient = def.out or saved.OutdoorAmbient
        Lighting.ExposureCompensation = def.exp or saved.ExposureCompensation
        if def.fog then
            Lighting.FogEnd, Lighting.FogColor = def.fog[1], def.fog[2]
        else
            Lighting.FogEnd, Lighting.FogColor = saved.FogEnd, saved.FogColor
        end
    end
    -- the little scene on each card is coloured the way the shader would colour the world
    local function clamp01(x) return math.clamp(x, 0, 1) end
    local function painter(def)
        local cc = def.cc or {0, 0, 0, Color3.new(1, 1, 1)}
        local br, co, sat, tint = cc[1], cc[2], cc[3], cc[4]
        local dim = 1
        if def.clock then
            if def.clock < 5.5 or def.clock > 19.5 then dim = 0.45
            elseif def.clock > 17 or def.clock < 7 then dim = 0.8 end
        end
        return function(c)
            local r, g, b = c.R, c.G, c.B
            local grey = 0.299 * r + 0.587 * g + 0.114 * b
            local k = 1 + sat
            r, g, b = grey + (r - grey) * k, grey + (g - grey) * k, grey + (b - grey) * k
            local q = 1 + co
            r, g, b = (r - 0.5) * q + 0.5 + br, (g - 0.5) * q + 0.5 + br, (b - 0.5) * q + 0.5 + br
            r, g, b = r * tint.R * dim, g * tint.G * dim, b * tint.B * dim
            if def.atmo then
                local a, ac = def.atmo[1] * 0.5, def.atmo[2]
                r, g, b = r + (ac.R - r) * a, g + (ac.G - g) * a, b + (ac.B - b) * a
            end
            return Color3.new(clamp01(r), clamp01(g), clamp01(b))
        end
    end
    local SCENE = {
        {Vector3.new(16, 0.6, 16), CFrame.new(0, -0.3, 0), rgb(85, 165, 75)},
        {Vector3.new(4, 3, 4), CFrame.new(-2.5, 1.5, 1.5), rgb(235, 225, 210)},
        {Vector3.new(4.6, 1, 4.6), CFrame.new(-2.5, 3.5, 1.5), rgb(175, 60, 50)},
        {Vector3.new(1, 1.6, 0.2), CFrame.new(-1.5, 0.8, -0.55), rgb(120, 80, 50)},
        {Vector3.new(0.6, 2.4, 0.6), CFrame.new(3.2, 1.2, -0.5), rgb(110, 75, 45)},
        {Vector3.new(2.8, 2.8, 2.8), CFrame.new(3.2, 3.4, -0.5), rgb(60, 145, 60), Enum.PartType.Ball},
        {Vector3.new(1.4, 1.4, 1.4), CFrame.new(1, 0.7, -3), rgb(60, 120, 235)},
        {Vector3.new(1.2, 1.2, 1.2), CFrame.new(-0.6, 0.6, -2.4), rgb(245, 205, 60), Enum.PartType.Ball},
        {Vector3.new(0.8, 2, 0.8), CFrame.new(0.4, 1, 0.2), rgb(230, 230, 230)},
    }
    local function preview(def, vpf)
        local paint = painter(def)
        local model = Instance.new("Model")
        for _, d in ipairs(SCENE) do
            local p = Instance.new("Part")
            p.Anchored = true
            p.Size, p.CFrame = d[1], d[2]
            p.Color = paint(d[3])
            p.Material = Enum.Material.SmoothPlastic
            if d[4] then p.Shape = d[4] end
            p.Parent = model
        end
        model.Parent = vpf
        local cam = Instance.new("Camera")
        cam.FieldOfView = 45
        cam.CFrame = CFrame.lookAt(Vector3.new(8, 6.5, -10), Vector3.new(0, 1.4, 0))
        cam.Parent = vpf
        vpf.CurrentCamera = cam
        vpf.Ambient = Color3.fromRGB(175, 175, 175)
        vpf.LightColor = Color3.new(1, 1, 1)
        vpf.LightDirection = Vector3.new(-1, -1.6, 0.6)
    end
    FX.presetItems = function()
        local out = {}
        for _, p in ipairs(P) do
            local def = p[3]
            out[#out + 1] = {label = p[1], colors = p[2], selected = CFG.shaderPreset == p[1], preset = p[1],
                viewport = function(vpf) preview(def, vpf) end}
        end
        return out
    end
    task.spawn(function()
        while running do
            pcall(function()
                local p = byName[CFG.shaderPreset]
                if p then apply(p[3]) elseif saved or next(fx) then restore() end
            end)
            task.wait(2)
        end
    end)
    FX.presetSet = function(name)
        CFG.shaderPreset = (CFG.shaderPreset == name) and "Off" or name
        local p = byName[CFG.shaderPreset]
        if p then pcall(apply, p[3]) else restore() end
    end
end

do
    connect(lp.CharacterAdded, function()
        if not (CFG.flingAfterMurd or CFG.flingAfterSher or CFG.flingAfterAll) then return end
        task.wait(2)
        if not running or not FX.flingKind then return end
        if CFG.flingAfterAll then
            pcall(FX.flingKind, "All")
        else
            if CFG.flingAfterMurd then pcall(FX.flingKind, "Murderer") end
            if CFG.flingAfterSher then pcall(FX.flingKind, "Sheriff") end
        end
    end)

    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    local lastTry = 0
    local function queueSelf()
        if type(ZENITH_SELF) ~= "string" or #ZENITH_SELF < 100 then return end
        local q = Compat.queue_on_teleport or Compat.queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not q then return end
        local eq = "="
        while string.find(ZENITH_SELF, "]" .. eq .. "]", 1, true) do eq = eq .. "=" end
        -- the queued code hands itself to the script again, so every next kick queues it too
        local code = "local __z = [" .. eq .. "[\n" .. ZENITH_SELF .. "]" .. eq .. "] local __f = (loadstring or load)(__z) if __f then __f(__z) end"
        pcall(q, code)
    end
    connect(GuiService.ErrorMessageChanged, function(msg)
        if not running or not CFG.autoRejoin or msg == nil or msg == "" then return end
        if tick() - lastTry < 10 then return end
        lastTry = tick()
        queueSelf()
        task.wait(1)
        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
    end)

    -- after joining: pick the device the game asks for (Phone on a phone, Tablet on a tablet or a PC)
    task.spawn(function()
        local UIS0 = game:GetService("UserInputService")
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local phone = UIS0.TouchEnabled and not UIS0.KeyboardEnabled and math.min(vp.X, vp.Y) < 700
        local want = phone and "phone" or "tablet"
        local words = phone and {"phone", "телефон"} or {"tablet", "планшет"}
        local function shown(g)
            local x = g
            while x and x:IsA("GuiObject") do
                if not x.Visible then return false end
                x = x.Parent
            end
            return not (x and x:IsA("ScreenGui") and x.Enabled == false)
        end
        local function click(b)
            local fired = false
            if Compat.getconnections then
                for _, sig in ipairs({b.MouseButton1Click, b.Activated, b.MouseButton1Down}) do
                    local ok, cons = pcall(Compat.getconnections, sig)
                    if ok and cons then
                        for _, cn in ipairs(cons) do
                            if pcall(function() cn:Fire() end) then fired = true end
                        end
                    end
                end
            end
            if not fired and Compat.firesignal then
                pcall(Compat.firesignal, b.MouseButton1Click)
                pcall(Compat.firesignal, b.Activated)
            end
        end
        local t0 = tick()
        while running and tick() - t0 < 40 do
            local pg = lp:FindFirstChild("PlayerGui")
            local done = false
            if pg then
                for _, d in ipairs(pg:GetDescendants()) do
                    if d:IsA("GuiButton") and shown(d) then
                        local n = string.lower(d.Name)
                        local t = d:IsA("TextButton") and string.lower(d.Text) or ""
                        for _, w in ipairs(words) do
                            if n == w or t == w or string.find(t, w, 1, true) then
                                click(d)
                                done = true
                                break
                            end
                        end
                    end
                    if done then break end
                end
            end
            if done then break end
            task.wait(0.5)
        end
    end)
end

do
    local function click(b)
        local fired = false
        if Compat.getconnections then
            for _, sig in ipairs({b.MouseButton1Click, b.Activated, b.MouseButton1Down}) do
                local ok, cons = pcall(Compat.getconnections, sig)
                if ok and cons then
                    for _, cn in ipairs(cons) do
                        if pcall(function() cn:Fire() end) then fired = true end
                    end
                end
            end
        end
        if not fired and Compat.firesignal then
            pcall(Compat.firesignal, b.MouseButton1Click)
            pcall(Compat.firesignal, b.Activated)
        end
    end
    -- battle pass straight through the event remotes (Remotes.Events.<Event>Remotes)
    local RS0 = game:GetService("ReplicatedStorage")
    local function profile()
        local ok, m = pcall(function() return require(RS0:WaitForChild("Modules", 5):WaitForChild("ProfileData", 5)) end)
        return ok and type(m) == "table" and m or nil
    end
    local function eventRemotes()
        local r = RS0:FindFirstChild("Remotes")
        local ev = r and r:FindFirstChild("Events")
        if not ev then return nil end
        for _, f in ipairs(ev:GetChildren()) do
            if f:FindFirstChild("BuyBattlePassTiers") then return f end
        end
        return nil
    end
    FX.candyBalance = function()
        local P = profile()
        local owned = P and P.Materials and P.Materials.Owned
        if type(owned) ~= "table" then return nil end
        local any
        for k, v in pairs(owned) do
            local l = string.lower(tostring(k))
            if type(v) == "number" then
                if string.find(l, "2026", 1, true) or string.find(l, "halloween", 1, true) then return v end
                if string.find(l, "cand", 1, true) then any = any or v end
            end
        end
        return any
    end
    FX.buyBattlePass = function()
        local rem = eventRemotes()
        if not rem then return false end
        local bought = false
        local candy = FX.candyBalance()
        if candy and candy >= 600 then
            pcall(function() rem.BuyBattlePassTiers:FireServer(1) end)
            bought = true
        end
        -- pick up every reward that is already unlocked
        local P = profile()
        local data = P and P[(string.gsub(rem.Name, "Remotes$", ""))]
        if type(data) == "table" and type(data.ClaimedRewards) == "table" and tonumber(data.CurrentTier) then
            for i = 1, tonumber(data.CurrentTier) do
                if data.ClaimedRewards[tostring(i)] ~= true and data.ClaimedRewards[i] ~= true then
                    pcall(function() rem.ClaimBattlePassReward:FireServer(tostring(i)) end)
                    task.wait(0.2)
                end
            end
        end
        return bought
    end
    task.spawn(function()
        while running do
            if CFG.autoBattlePass then
                local ok, res = pcall(FX.buyBattlePass)
                if ok and res and FX.notify then FX.notify("Zenith", "battle pass +1") end
            end
            task.wait(15)
        end
    end)
end

-- auto quests: reads the event quests and switches on what each one needs
do
    local RS0 = game:GetService("ReplicatedStorage")
    local Q = {ev = nil, note = ""}
    local function need(mod)
        local ok, m = pcall(function() return require(mod) end)
        return ok and m or nil
    end
    local function mainEvent()
        if Q.ev then return Q.ev end
        local ss = RS0:FindFirstChild("SharedServices")
        local svc = ss and ss:FindFirstChild("EventInfoService") and need(ss.EventInfoService)
        if not svc then return nil end
        local ok, inst = pcall(function() return svc:WaitForInitializedAsync() end)
        if not ok or not inst then return nil end
        local ok2, ev = pcall(function() return inst:GetMainEvent() end)
        if ok2 and type(ev) == "table" then Q.ev = ev end
        return Q.ev
    end
    FX.questList = function()
        local ev = mainEvent()
        local info = ev and ev.EventStartInfo
        if not info or type(info.Quests) ~= "table" then return {} end
        local mods = RS0:FindFirstChild("Modules")
        local P = mods and mods:FindFirstChild("ProfileData") and need(mods.ProfileData)
        local data = P and P[ev.Title] and P[ev.Title].Quests or {}
        local out = {}
        for id, q in pairs(info.Quests) do
            local goal = 0
            for _, step in ipairs(q.Quests or {}) do goal = math.max(goal, tonumber(step.ChallengeAmount) or 0) end
            local prog = (type(data[id]) == "table" and tonumber(data[id].Progress)) or 0
            if goal > 0 and prog < goal then
                out[#out + 1] = {id = id, title = tostring(q.Title or id), desc = tostring(q.Description or ""), prog = prog, goal = goal}
            end
        end
        return out
    end
    local function has(t, words)
        for _, w in ipairs(words) do
            if string.find(t, w, 1, true) then return true end
        end
        return false
    end
    local function wants(text)
        local t = string.lower(text)
        local w = {}
        if has(t, {"candy", "candies", "coin", "collect", "конфет", "собер", "собрать"}) then w.farm = true end
        if has(t, {"murderer", "убийц"}) and has(t, {"kill", "elimin", "убе", "убить", "убей"}) then w.murd = true end
        if has(t, {"sheriff", "hero", "shoot", "шериф", "герой", "застрел", "выстрел"}) then w.sher = true end
        if has(t, {"survive", "win", "выжи", "побед"}) then w.survive = true end
        if has(t, {"zombie", "infect", "зомби", "зараз"}) then w.zombie = true end
        if not next(w) and has(t, {"kill", "убе", "убить"}) then w.murd = true end
        return w
    end
    local function zombieHit()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local tool = c and c:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if not hrp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            local pc = p ~= lp and p.Character
            local ph = pc and pc:FindFirstChildOfClass("Humanoid")
            local pr = pc and pc:FindFirstChild("HumanoidRootPart")
            if ph and pr and ph.Health > 0 and not hostileRole(roles[p]) and not ST.isZombie(p) then
                hrp.CFrame = pr.CFrame * CFrame.new(0, 0, 2)
                if tool then pcall(function() tool:Activate() end) end
                if handle and Compat.firetouchinterest then
                    pcall(Compat.firetouchinterest, handle, pr, 0)
                    pcall(Compat.firetouchinterest, handle, pr, 1)
                end
                task.wait(0.2)
            end
        end
    end
    task.spawn(function()
        local lastKill = 0
        while running do
            pcall(function()
                local on = CFG.questsAlways or (CFG.questsBagFull and ST.bagFull)
                if not on then return end
                local list = FX.questList()
                if #list == 0 then return end
                local w = {}
                for _, q in ipairs(list) do
                    for k in pairs(wants(q.title .. " " .. q.desc)) do w[k] = true end
                end
                local first = list[1]
                local note = first.title .. " " .. first.prog .. "/" .. first.goal
                if note ~= Q.note then
                    Q.note = note
                    if FX.notify then FX.notify("quest", note) end
                end
                local role = roles[lp]
                local iMurd = role == "Murderer" or hasKnife()
                local iZombie = role ~= "Murderer" and hostileRole(role)
                if w.farm and not ST.bagFull then CFG.farm = true end
                if w.survive then CFG.avoidMurder = true end
                if w.sher and findGun() then CFG.autoShoot = true end
                if w.murd and iMurd then
                    CFG.autoKill = true
                    if tick() - lastKill > 12 and FX.killAll then
                        lastKill = tick()
                        task.spawn(function() pcall(FX.killAll) end)
                    end
                end
                if w.zombie and iZombie and tick() - lastKill > 8 then
                    lastKill = tick()
                    task.spawn(function() pcall(zombieHit) end)
                end
            end)
            task.wait(3)
        end
    end)
end

-- Anti trap: trap hits are never reported, trap effects are muted, trap parts can't be touched
do
    local RS0 = game:GetService("ReplicatedStorage")
    local muted, parts = {}, {}
    local function isTrap(d)
        return d:IsA("BasePart") and string.find(string.lower(d.Name), "trap", 1, true) ~= nil
    end
    local function guard(d)
        if isTrap(d) and parts[d] == nil then
            parts[d] = d.CanTouch
            if ST.antiTrap then pcall(function() d.CanTouch = false end) end
        end
    end
    connect(workspace.DescendantAdded, guard)
    task.spawn(function()
        for i, d in ipairs(workspace:GetDescendants()) do
            guard(d)
            if i % 3000 == 0 then task.wait() end
        end
    end)
    local was = false
    task.spawn(function()
        while running do
            ST.antiTrap = CFG.antiTrap == true
            if ST.antiTrap ~= was then
                was = ST.antiTrap
                for p, orig in pairs(parts) do
                    if p.Parent then pcall(function() p.CanTouch = (not was) and orig or false end) else parts[p] = nil end
                end
                local ts = RS0:FindFirstChild("TrapSystem")
                if ts and Compat.getconnections then
                    for _, r in ipairs(ts:GetChildren()) do
                        if r:IsA("RemoteEvent") and r.Name ~= "PlaceTrap-E" then
                            local ok, cons = pcall(Compat.getconnections, r.OnClientEvent)
                            if ok and cons then
                                for _, cn in ipairs(cons) do
                                    pcall(function()
                                        if was then cn:Disable() else cn:Enable() end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Trade helper: rarity and a rough worth on every item in a trade, and both totals
do
    local RS0 = game:GetService("ReplicatedStorage")
    local WORTH = {Common = 1, Uncommon = 2, Rare = 5, Legendary = 15, Vintage = 80, Godly = 100, Christmas = 150,
        Halloween = 150, Ancient = 300, Chroma = 400, Unique = 500}
    local COL = {Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(80, 220, 120), Rare = Color3.fromRGB(60, 140, 255),
        Legendary = Color3.fromRGB(255, 140, 0), Vintage = Color3.fromRGB(230, 200, 120), Godly = Color3.fromRGB(255, 60, 60),
        Christmas = Color3.fromRGB(90, 220, 90), Halloween = Color3.fromRGB(255, 130, 30), Ancient = Color3.fromRGB(180, 90, 255),
        Chroma = Color3.fromRGB(0, 255, 200), Unique = Color3.fromRGB(255, 200, 60)}
    local sync, tm
    local function db()
        if not sync then
            local ok, m = pcall(function() return require(RS0:WaitForChild("Database", 5):WaitForChild("Sync", 5)) end)
            if ok and type(m) == "table" then sync = m end
        end
        return sync
    end
    local function tmod()
        if not tm then
            local ok, m = pcall(function() return require(RS0:WaitForChild("Modules", 5):WaitForChild("TradeModule", 5)) end)
            if ok and type(m) == "table" then tm = m end
        end
        return tm
    end
    local function info(id, typ)
        local d = db()
        local t = d and d[typ] and d[typ][id]
        if type(t) ~= "table" then return nil end
        local rar = tostring(t.Rarity or "Common")
        if t.Chroma == true then rar = "Chroma" end
        return rar
    end
    local function label(parent, name, size, pos)
        local l = parent:FindFirstChild(name)
        if not l then
            l = Instance.new("TextLabel")
            l.Name = name
            l.BackgroundColor3 = Color3.new(0, 0, 0)
            l.BackgroundTransparency = 0.3
            l.BorderSizePixel = 0
            l.Font = Enum.Font.GothamBold
            l.TextSize = 11
            l.ZIndex = 50
            l.Size, l.Position = size, pos
            l.Parent = parent
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)
        end
        return l
    end
    local function side(gui, offer)
        local total = 0
        if not gui or type(offer) ~= "table" then return 0 end
        for i, it in pairs(offer) do
            local id = it[1] or it.ItemID
            local amt = tonumber(it[2] or it.Amount) or 1
            local typ = it[3] or it.ItemType
            local rar = info(id, typ)
            local d = db()
            local entry = d and d[typ] and d[typ][id]
            local nm = type(entry) == "table" and entry.ItemName and tostring(entry.ItemName) or nil
            if nm and type(entry) == "table" and entry.Chroma == true then nm = "Chroma " .. nm end
            local real = nm and FX.valueOf and FX.valueOf(nm)
            local w = (real or (rar and WORTH[rar]) or 1) * amt
            total += w
            local fr = gui.Container and gui.Container:FindFirstChild("NewItem" .. tostring(i))
            if fr and rar then
                local l = label(fr, "ZenithWorth", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -14))
                l.Text = real and tostring(math.floor(w)) or (rar .. " ~" .. w)
                l.TextColor3 = COL[rar] or Color3.new(1, 1, 1)
                l.Visible = CFG.tradeHelper
            end
        end
        return total
    end
    local function render(data)
        local T = tmod()
        if not T or not T.GUI or not T.GUI.YourOffer or type(data) ~= "table" then return end
        local mine = (data.Player1 and data.Player1.Player == lp) and "Player1" or "Player2"
        local other = (mine == "Player1") and "Player2" or "Player1"
        local a = side(T.GUI.YourOffer, data[mine] and data[mine].Offer)
        local b = side(T.GUI.TheirOffer, data[other] and data[other].Offer)
        local l = label(T.GUI.TheirOffer, "ZenithTotal", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, -20))
        l.Text = "you " .. math.floor(a) .. "  |  them " .. math.floor(b)
        l.TextColor3 = (b >= a) and Color3.fromRGB(90, 230, 120) or Color3.fromRGB(255, 90, 90)
        l.Visible = CFG.tradeHelper
    end
    task.spawn(function()
        local trade = RS0:WaitForChild("Trade", 30)
        local ev = trade and trade:WaitForChild("UpdateTrade", 10)
        if ev then
            connect(ev.OnClientEvent, function(d)
                task.defer(function() pcall(render, d) end)
            end)
        end
    end)
end

do
    connect(lp.Idled, function()
        if not running or not CFG.antiAfk then return end
        local vu = game:GetService("VirtualUser")
        pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)

    local IB = {}
    local function destroy()
        if IB.drag then pcall(function() IB.drag:Disconnect() end) end
        if IB.gui then pcall(function() IB.gui:Destroy() end) end
        IB = {}
    end
    FX.invisBtnOff = destroy
    local function build()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ZenithInvisButton"
        gui.ResetOnSpawn = false
        pcall(function() gui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
        local button = Instance.new("ImageButton")
        button.Size = UDim2.new(0, 60, 0, 60)
        button.Position = UDim2.new(0, 20, 0.5, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        button.BackgroundTransparency = 0.35
        button.Image = "rbxassetid://95780604256188"
        button.BorderSizePixel = 0
        button.ScaleType = Enum.ScaleType.Fit
        button.AutoButtonColor = false
        button.Parent = gui
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.Activated:Connect(function()
            CFG.invis = not CFG.invis
            local t = FX.toggles and FX.toggles.invis
            if t and t.obj and t.obj.Set then pcall(function() t.obj:Set(CFG.invis) end) end
        end)
        IB.gui, IB.button = gui, button
        FX.pill(button, "invisible", "rbxassetid://95780604256188")
    end
    local JB = {}
    local function jbOff()
        if JB.gui then pcall(function() JB.gui:Destroy() end) end
        JB = {}
    end
    FX.jumpBtnOff = jbOff
    local function jbBuild()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ZenithJumpButton"
        gui.ResetOnSpawn = false
        pcall(function() gui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
        local button = Instance.new("ImageButton")
        button.Size = UDim2.new(0, 60, 0, 60)
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        button.BackgroundTransparency = 0.35
        button.Image = "rbxassetid://12510788215"
        button.ImageColor3 = Color3.fromRGB(255, 255, 255)
        button.BorderSizePixel = 0
        button.ScaleType = Enum.ScaleType.Fit
        button.AutoButtonColor = false
        button.Parent = gui
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
        button.Activated:Connect(function()
            local c = lp.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then
                h.Jump = true
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end)
        JB.gui, JB.button = gui, button
        FX.pill(button, "jump", "rbxassetid://12510788215")
    end
    task.spawn(function()
        while running do
            pcall(function()
                if CFG.jumpBtn then
                    if not (JB.gui and JB.gui.Parent) then jbBuild() end
                    JB.button.Position = UDim2.new(CFG.jumpBtnX / 100, 0, CFG.jumpBtnY / 100, 0)
                elseif JB.gui then
                    jbOff()
                end
                if IB.button then IB.button.Position = UDim2.new(CFG.invisBtnX / 100, 0, CFG.invisBtnY / 100, 0) end
                if FX.shootButton then FX.shootButton.Position = UDim2.new(CFG.shootBtnX / 100, 0, CFG.shootBtnY / 100, 0) end
            end)
            task.wait(0.25)
        end
        jbOff()
    end)
    task.spawn(function()
        while running do
            if CFG.invisBtn then
                if not (IB.gui and IB.gui.Parent) then build() end
                if IB.button then
                    local pic = IB.button:FindFirstChild("PillIcon")
                    local col = CFG.invis and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 255, 255)
                    if pic then pic.ImageColor3 = col else IB.button.ImageColor3 = col end
                end
            elseif IB.gui then
                destroy()
            end
            task.wait(0.2)
        end
    end)
end

do
    local saved = {}
    local function hold(prop, on, value)
        if on then
            if saved[prop] == nil then saved[prop] = Lighting[prop] end
            if Lighting[prop] ~= value then pcall(function() Lighting[prop] = value end) end
        elseif saved[prop] ~= nil then
            pcall(function() Lighting[prop] = saved[prop] end)
            saved[prop] = nil
        end
    end
    local SKIES = {
        {"Classic", "rbxasset://textures/sky/sky512_", true},
        {"Pink Daylight", {271042516, 271077243, 271042556, 271042310, 271042467, 271077958}},
        {"Night", {12064107, 12064152, 12064121, 12063984, 12064115, 12064131}},
        {"Space", {159248188, 159248183, 159248187, 159248173, 159248192, 159248176}},
        {"Sunset", {150335574, 150335628, 150335585, 150335604, 150335642, 150335613}},
        {"Minecraft", {1876545003, 1876544331, 1876542941, 1876543392, 1876543764, 1876544642}},
    }
    local FACES = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
    local SUFFIX = {"bk", "dn", "ft", "lf", "rt", "up"}
    local function faces(def)
        local out = {}
        for k, f in ipairs(FACES) do
            if def[3] then out[f] = def[2] .. SUFFIX[k] .. ".tex" else out[f] = "rbxassetid://" .. def[2][k] end
        end
        return out
    end
    FX.skyItems = function()
        local out = {}
        for _, d in ipairs(SKIES) do
            local img = d[3] and "" or ("rbxassetid://" .. d[2][3])
            out[#out + 1] = {label = d[1], image = img, selected = CFG.skybox == d[1], sky = d[1]}
        end
        return out
    end
    local mine, hidden = nil, {}
    local function skyOff()
        if mine then pcall(function() mine:Destroy() end) mine = nil end
        for _, sk in ipairs(hidden) do pcall(function() sk.Parent = Lighting end) end
        hidden = {}
    end
    FX.skyOff = skyOff
    local function skyOn(name)
        local def
        for _, d in ipairs(SKIES) do if d[1] == name then def = d end end
        if not def then return skyOff() end
        if not (mine and mine.Parent) then
            mine = Instance.new("Sky")
            mine.Name = "ZenithSky"
        end
        for f, id in pairs(faces(def)) do mine[f] = id end
        mine.Parent = Lighting
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Sky") and v ~= mine then
                hidden[#hidden + 1] = v
                v.Parent = nil
            end
        end
    end
    FX.skySet = function(name)
        CFG.skybox = (CFG.skybox == name) and "Off" or name
        if CFG.skybox == "Off" then skyOff() else skyOn(CFG.skybox) end
    end
    task.spawn(function()
        while running do
            pcall(function()
                hold("ClockTime", CFG.timeOn, CFG.clockTime)
                hold("FogEnd", CFG.fogChOn, CFG.fogChEnd)
                hold("FogStart", CFG.fogChOn, 0)
                hold("FogColor", CFG.fogChOn, colorOf(CFG.fogChColor))
                hold("Brightness", CFG.brightOn, CFG.brightV)
                hold("Ambient", CFG.ambOn, colorOf(CFG.ambColor))
                hold("OutdoorAmbient", CFG.ambOn, colorOf(CFG.ambColor))
                if CFG.skybox ~= "Off" then
                    local stray = false
                    for _, v in ipairs(Lighting:GetChildren()) do
                        if v:IsA("Sky") and v ~= mine then stray = true end
                    end
                    if stray or not (mine and mine.Parent) then skyOn(CFG.skybox) end
                elseif mine then
                    skyOff()
                end
            end)
            task.wait(0.3)
        end
        for p in pairs(saved) do hold(p, false) end
        skyOff()
    end)
end


-- real trade values from supremevalues.com (cached for 6 hours)
do
    local Http = game:GetService("HttpService")
    local RS0 = game:GetService("ReplicatedStorage")
    local req = (syn and syn.request) or Compat.http_request or Compat.request or (fluxus and fluxus.request) or (http and http.request)
    local PAGES = {"godlies", "uniques", "ancients", "vintages", "chromas", "legendaries", "rares", "uncommons", "commons", "pets", "misc-items"}
    local FILE = "ZenithMM2/values.json"
    local V = {map = nil, loading = false}
    local function norm(n) return string.lower(string.gsub(tostring(n), "[^%w]", "")) end
    FX.valueOf = function(name)
        return V.map and V.map[norm(name)] or nil
    end
    local function knownNames()
        local set = {}
        local ok, sync = pcall(function() return require(RS0:WaitForChild("Database", 5):WaitForChild("Sync", 5)) end)
        if ok and type(sync) == "table" then
            for _, cat in pairs(sync) do
                if type(cat) == "table" then
                    for _, it in pairs(cat) do
                        if type(it) == "table" and it.ItemName then
                            set[norm(it.ItemName)] = true
                            set[norm("Chroma " .. tostring(it.ItemName))] = true
                        end
                    end
                end
            end
        end
        return set
    end
    local function number(str)
        local num, suf = string.match(str, "^%s*([%d,%.]+)%s*([kKmM]?)%s*$")
        if not num then return nil end
        local v = tonumber((string.gsub(num, ",", "")))
        if not v then return nil end
        if suf == "k" or suf == "K" then v = v * 1000 elseif suf == "m" or suf == "M" then v = v * 1000000 end
        return v
    end
    local function parse(html, names, map)
        html = string.gsub(html, "<script.-</script>", " ")
        html = string.gsub(html, "<style.-</style>", " ")
        html = string.gsub(html, "<[^>]+>", "\n")
        html = string.gsub(html, "&amp;", "&")
        local lines = {}
        for ln in string.gmatch(html, "[^\n]+") do
            ln = string.gsub(ln, "^%s+", "")
            ln = string.gsub(ln, "%s+$", "")
            if ln ~= "" then lines[#lines + 1] = ln end
        end
        local count = 0
        for i, ln in ipairs(lines) do
            local key = norm(ln)
            if names[key] and map[key] == nil then
                local val
                for j = i + 1, math.min(i + 14, #lines) do
                    local nk = norm(lines[j])
                    if names[nk] then break end
                    local l = string.lower(lines[j])
                    if string.find(l, "value", 1, true) then
                        val = number(string.match(lines[j], "([%d,%.]+%s*[kKmM]?)%s*$") or "") or number(lines[j + 1] or "")
                        if val then break end
                    end
                end
                if not val then
                    for j = i + 1, math.min(i + 8, #lines) do
                        if names[norm(lines[j])] then break end
                        val = number(lines[j])
                        if val then break end
                    end
                end
                if val then
                    map[key] = val
                    count += 1
                end
            end
        end
        return count
    end
    FX.loadValues = function(force)
        if V.loading then return end
        V.loading = true
        task.spawn(function()
            pcall(function()
                if not force and V.map then return end
                if not req then return end
                local names = knownNames()
                local map, total = {}, 0
                for _, page in ipairs(PAGES) do
                    local ok, res = pcall(function()
                        return req({Url = "https://supremevalues.com/mm2/" .. page, Method = "GET",
                            Headers = {["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}})
                    end)
                    if ok and type(res) == "table" and res.Body and (res.StatusCode or 200) < 400 then
                        total += parse(tostring(res.Body), names, map)
                    end
                    task.wait(0.3)
                end
                if total > 0 then
                    V.map = map
                end
            end)
            V.loading = false
        end)
    end
    task.delay(5, function()
        if running and CFG.tradeHelper then FX.loadValues(false) end
    end)
end

task.spawn(function()
    while running do
        CFG.antiFling = CFG.antiOn and CFG.antiFlingSel or false
        CFG.antiAfk = CFG.antiOn and CFG.antiAfkSel or false
        CFG.antiTrap = CFG.antiOn and CFG.antiTrapSel or false
        task.wait(0.3)
    end
end)

-- auto jump bomb: every jump throws the bomb right under your feet
do
    local last, wasJump = 0, false
    local function bombTool()
        local any
        for _, place in ipairs({lp.Character, lp:FindFirstChildOfClass("Backpack")}) do
            if place then
                for _, t in ipairs(place:GetChildren()) do
                    local r = t:IsA("Tool") and t:FindFirstChild("Remote")
                    if r and r:IsA("RemoteEvent") and not t:FindFirstChild("Shoot") and t.Name ~= "Knife" then
                        if string.find(string.lower(t.Name), "bomb", 1, true) then return t end
                        any = any or t
                    end
                end
            end
        end
        return any
    end
    local function jumpBomb(alsoJump)
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local tool = bombTool()
        if not (hum and hrp and tool) or tick() - last < 1 then return end
        last = tick()
        if alsoJump then
            hum.Jump = true
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            task.wait(0.05)
        end
        local prev = c:FindFirstChildOfClass("Tool")
        if tool.Parent ~= c then
            hum:EquipTool(tool)
            task.wait(0.08)
        end
        pcall(function() tool.Remote:FireServer(CFrame.new(hrp.Position - Vector3.new(0, 3, 0)), 50) end)
        task.wait(0.1)
        if prev and prev ~= tool and prev.Parent then
            pcall(function() hum:EquipTool(prev) end)
        elseif not prev then
            pcall(function() hum:UnequipTools() end)
        end
    end
    FX.jumpBomb = function() task.spawn(jumpBomb, true) end
    -- auto: jumps and bombs by itself every time the bomb is ready (22 s), plus on your own jumps
    task.spawn(function()
        local lastAuto = 0
        while running do
            if CFG.autoJumpBomb and bombTool() and tick() - lastAuto >= 22 then
                lastAuto = tick()
                pcall(jumpBomb, true)
            end
            task.wait(0.5)
        end
    end)
    connect(RunService.Heartbeat, function()
        if not running or not CFG.autoJumpBomb then return end
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local jumping = hum:GetState() == Enum.HumanoidStateType.Jumping
        if jumping and not wasJump then task.spawn(jumpBomb, false) end
        wasJump = jumping
    end)
    local BB = {}
    task.spawn(function()
        while running do
            pcall(function()
                if CFG.jumpBombBtn then
                    if not (BB.gui and BB.gui.Parent) then
                        local gui = Instance.new("ScreenGui")
                        gui.Name = "ZenithJumpBomb"
                        gui.ResetOnSpawn = false
                        pcall(function() gui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
                        if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
                        local b = Instance.new("ImageButton")
                        b.Size = UDim2.new(0, 60, 0, 60)
                        b.AnchorPoint = Vector2.new(0.5, 0.5)
                        b.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        b.BackgroundTransparency = 0.35
                        b.Image = "rbxassetid://12510788215"
                        b.ImageColor3 = Color3.fromRGB(255, 160, 60)
                        b.BorderSizePixel = 0
                        b.ScaleType = Enum.ScaleType.Fit
                        b.AutoButtonColor = false
                        b.Parent = gui
                        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
                        b.Activated:Connect(function() task.spawn(jumpBomb, true) end)
                        BB.gui, BB.button = gui, b
                        FX.pill(b, "jump bomb", "rbxassetid://12510788215")
                        local pic = b:FindFirstChild("PillIcon")
                        if pic then pic.ImageColor3 = Color3.fromRGB(255, 160, 60) end
                    end
                    BB.button.Position = UDim2.new(CFG.jbbX / 100, 0, CFG.jbbY / 100, 0)
                elseif BB.gui then
                    BB.gui:Destroy()
                    BB = {}
                end
            end)
            task.wait(0.25)
        end
        if BB.gui then pcall(function() BB.gui:Destroy() end) end
    end)
end

-- extra on-screen buttons for the main functions
do
    local DEFS = {
        {key = "kaBtn", label = "kill all", icon = {16898613777, 49, 869}, fn = function() if FX.killAll then FX.killAll() end end, x = 92, y = 40},
        {key = "fmBtn", label = "fling murd", icon = {16898613869, 918, 906}, fn = function() if FX.flingKind then FX.flingKind("Murderer") end end, x = 92, y = 50},
        {key = "fsBtn", label = "fling sheriff", icon = {16898613869, 918, 906}, fn = function() if FX.flingKind then FX.flingKind("Sheriff") end end, x = 92, y = 60},
        {key = "faBtn", label = "fling all", icon = {16898613869, 967, 98}, fn = function() if FX.flingKind then FX.flingKind("All") end end, x = 92, y = 70},
        {key = "tlBtn", label = "tp lobby", icon = {16898613869, 514, 771}, fn = function() if FX.tpLobby then FX.tpLobby() end end, x = 92, y = 80},
    }
    FX.extraBtnDefs = DEFS
    for _, d in ipairs(DEFS) do
        if CFG[d.key] == nil then CFG[d.key] = false end
        if CFG[d.key .. "X"] == nil then CFG[d.key .. "X"] = d.x end
        if CFG[d.key .. "Y"] == nil then CFG[d.key .. "Y"] = d.y end
    end
    local live = {}
    task.spawn(function()
        while running do
            for _, d in ipairs(DEFS) do
                pcall(function()
                    local b = live[d.key]
                    if CFG[d.key] then
                        if not (b and b.Parent) then
                            local gui = Instance.new("ScreenGui")
                            gui.Name = "ZenithBtn_" .. d.key
                            gui.ResetOnSpawn = false
                            pcall(function() gui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
                            if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
                            b = Instance.new("TextButton")
                            b.AnchorPoint = Vector2.new(0.5, 0.5)
                            b.AutoButtonColor = false
                            b.BorderSizePixel = 0
                            b.Parent = gui
                            FX.pill(b, d.label, d.icon)
                            b.Activated:Connect(function()
                                local pic = b:FindFirstChild("PillIcon")
                                if pic then pic.ImageColor3 = Color3.fromRGB(150, 200, 255) end
                                task.spawn(function() pcall(d.fn) end)
                                task.delay(0.3, function() if pic and pic.Parent then pic.ImageColor3 = Color3.new(1, 1, 1) end end)
                            end)
                            live[d.key] = b
                        end
                        b.Position = UDim2.new(CFG[d.key .. "X"] / 100, 0, CFG[d.key .. "Y"] / 100, 0)
                    elseif b then
                        pcall(function() b.Parent:Destroy() end)
                        live[d.key] = nil
                    end
                end)
            end
            task.wait(0.25)
        end
        for _, b in pairs(live) do pcall(function() b.Parent:Destroy() end) end
    end)
end

-- hit notify: a small card for every shot of yours, hit or miss
do
    local H = {}
    local function root()
        if H.list and H.list.Parent then return H.list end
        local g = Instance.new("ScreenGui")
        g.Name = "ZenithHitLog"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.DisplayOrder = 60
        pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        local list = Instance.new("Frame")
        list.BackgroundTransparency = 1
        list.AnchorPoint = Vector2.new(1, 0.5)
        list.Position = UDim2.new(1, -14, 0.5, 0)
        list.Size = UDim2.new(0, 250, 0, 320)
        list.Parent = g
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 6)
        lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Parent = list
        H.gui, H.list, H.n = g, list, 0
        return list
    end
    FX.hitLogOff = function()
        if H.gui then pcall(function() H.gui:Destroy() end) end
        H = {}
    end
    local function card(hit, plr, studs, lead)
        local P = FX.themePalette and FX.themePalette() or {bg = Color3.fromRGB(15, 15, 18), text = Color3.new(1, 1, 1), sub = Color3.fromRGB(170, 170, 180)}
        local list = root()
        H.n += 1
        local col = hit and Color3.fromRGB(90, 225, 130) or Color3.fromRGB(245, 95, 95)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromOffset(236, 50)
        holder.LayoutOrder = -H.n
        holder.Parent = list
        local f = Instance.new("Frame")
        f.Size = UDim2.fromScale(1, 1)
        f.Position = UDim2.fromOffset(40, 0)
        f.BackgroundColor3 = P.bg
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Parent = holder
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local st = Instance.new("UIStroke")
        st.Color = col
        st.Transparency = 1
        st.Thickness = 1
        st.Parent = f
        local bar = Instance.new("Frame")
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = col
        bar.BackgroundTransparency = 1
        bar.Position = UDim2.new(0, 6, 0.5, -14)
        bar.Size = UDim2.fromOffset(3, 28)
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        local av = Instance.new("ImageLabel")
        av.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
        av.BackgroundTransparency = 1
        av.ImageTransparency = 1
        av.Position = UDim2.new(0, 16, 0.5, -17)
        av.Size = UDim2.fromOffset(34, 34)
        av.Image = plr and ("rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150") or ""
        av.Parent = f
        Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
        local t1 = Instance.new("TextLabel")
        t1.BackgroundTransparency = 1
        t1.Position = UDim2.fromOffset(58, 7)
        t1.Size = UDim2.new(1, -66, 0, 18)
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 13
        t1.TextXAlignment = Enum.TextXAlignment.Left
        t1.RichText = true
        t1.TextTransparency = 1
        t1.TextColor3 = P.text
        t1.Text = string.format('<font color="#%s">%s</font>  %s', col:ToHex(), hit and "hit" or "miss", plr and plr.DisplayName or "")
        t1.Parent = f
        local bits = {}
        if studs then bits[#bits + 1] = math.floor(studs + 0.5) .. " studs" end
        if lead then bits[#bits + 1] = "lead " .. string.format("%.1f", lead) end
        local t2 = Instance.new("TextLabel")
        t2.BackgroundTransparency = 1
        t2.Position = UDim2.fromOffset(58, 26)
        t2.Size = UDim2.new(1, -66, 0, 16)
        t2.Font = Enum.Font.Gotham
        t2.TextSize = 11
        t2.TextXAlignment = Enum.TextXAlignment.Left
        t2.TextTransparency = 1
        t2.TextColor3 = P.sub
        t2.Text = table.concat(bits, "   ")
        t2.Parent = f
        local inInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(f, inInfo, {Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.5}):Play()
        TweenService:Create(st, inInfo, {Transparency = 0.6}):Play()
        TweenService:Create(bar, inInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(av, inInfo, {ImageTransparency = 0, BackgroundTransparency = 0.3}):Play()
        TweenService:Create(t1, inInfo, {TextTransparency = 0}):Play()
        TweenService:Create(t2, inInfo, {TextTransparency = 0}):Play()
        local kids = {}
        for _, k in ipairs(list:GetChildren()) do
            if k:IsA("Frame") then kids[#kids + 1] = k end
        end
        if #kids > 5 then
            table.sort(kids, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
            kids[1]:Destroy()
        end
        task.delay(3, function()
            if not holder.Parent then return end
            local out = TweenInfo.new(0.3)
            TweenService:Create(f, out, {Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1}):Play()
            for _, o in ipairs({t1, t2}) do TweenService:Create(o, out, {TextTransparency = 1}):Play() end
            TweenService:Create(av, out, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
            TweenService:Create(bar, out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(st, out, {Transparency = 1}):Play()
            task.wait(0.35)
            holder:Destroy()
        end)
    end
    ST.onShotFire = function()
        if not running then return end
        if tick() - (H.lastShot or 0) < 0.3 then return end
        H.lastShot = tick()
        task.spawn(function()
            local c = lp.Character
            local me = c and c:FindFirstChild("HumanoidRootPart")
            if not me then return end
            local alive = {}
            for _, p in ipairs(Players:GetPlayers()) do
                local h = p ~= lp and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then alive[p] = h.Health end
            end
            local target = (ST.target and ST.target.Parent and tick() - (ST.aimAt or 0) < 1.5) and ST.target or nil
            local tplr = target and Players:GetPlayerFromCharacter(target.Parent)
            local studs = target and (target.Position - me.Position).Magnitude or nil
            local lead = (target and ST.aimPos) and (ST.aimPos - target.Position).Magnitude or nil
            task.wait(0.7)
            local victim
            for p, hp in pairs(alive) do
                local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if not h or h.Health <= 0 or h.Health < hp then
                    if not victim or p == tplr then victim = p end
                end
            end
            if victim then
                local vh = victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
                local killed = not vh or vh.Health <= 0
                if CFG.hitNotify and not killed then
                    local vr = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
                    local d = vr and me.Parent and (vr.Position - me.Position).Magnitude or studs
                    local msg = victim.DisplayName .. "  ·  " .. math.floor(d or 0) .. " studs"
                    if FX.hitLog then FX.hitLog(msg, "hit") elseif FX.notify then FX.notify("Hit", msg) end
                end
                if killed and CFG.killNotify and FX.notify then
                    local msg = victim.DisplayName .. (studs and ("  ·  " .. math.floor(studs) .. " studs") or "")
                    if FX.hitLog then FX.hitLog("<b>" .. msg .. "</b>", "kill") else FX.notify("Kill", msg) end
                end
            else
                -- missed: auto shoot may fire again right away
                AS.retry = true
                AS.fireAt = 0
                if CFG.missNotify and FX.notify then
                    local msg = (tplr and tplr.DisplayName or "target") .. (studs and ("  ·  " .. math.floor(studs) .. " studs") or "")
                    if FX.hitLog then FX.hitLog(msg, "miss") else FX.notify("Miss", msg) end
                end
            end
        end)
    end
    connect(workspace.ChildAdded, function(d)
        if not running or not (CFG.hitNotify or CFG.missNotify) or not d:IsA("BasePart") then return end
        task.defer(function()
            local t0 = tick()
            while d.Parent and not d:FindFirstChildOfClass("Beam") and tick() - t0 < 0.4 do
                RunService.Heartbeat:Wait()
            end
            local beam = d.Parent and d:FindFirstChildOfClass("Beam")
            if not beam then return end
            local c = lp.Character
            local me = c and c:FindFirstChild("HumanoidRootPart")
            if not me or not (ST.myGun and ST.myGun()) then return end
            local t1 = tick()
            while tick() - t1 < 0.3 do
                local a0, a1 = beam.Attachment0, beam.Attachment1
                if a0 and a1 and (a1.WorldPosition - a0.WorldPosition).Magnitude > 1 then
                    if (a0.WorldPosition - me.Position).Magnitude <= 12 then pcall(ST.onShotFire) end
                    return
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end)
end

-- Avatar: copy another player's look onto your character (only on your screen)
do
    local A = {orig = nil, from = nil, char = nil}
    local function snapshot(c)
        local o = {acc = {}, cloth = {}, colors = {}, face = nil}
        for _, x in ipairs(c:GetChildren()) do
            if x:IsA("Accessory") then o.acc[#o.acc + 1] = x end
            if x:IsA("Shirt") or x:IsA("Pants") or x:IsA("ShirtGraphic") or x:IsA("BodyColors") then o.cloth[#o.cloth + 1] = x end
            if x:IsA("BasePart") then o.colors[x] = x.Color end
        end
        local head = c:FindFirstChild("Head")
        local face = head and head:FindFirstChildOfClass("Decal")
        o.face = face and face.Texture
        return o
    end
    local function clearCopy(c)
        for _, x in ipairs(c:GetDescendants()) do
            if x:GetAttribute("ZenithCopy") then pcall(function() x:Destroy() end) end
        end
    end
    local function restore()
        local c = lp.Character
        if not c or not A.orig or A.char ~= c then return end
        clearCopy(c)
        for _, x in ipairs(A.orig.acc) do pcall(function() x.Parent = c end) end
        for _, x in ipairs(A.orig.cloth) do pcall(function() x.Parent = c end) end
        for p, col in pairs(A.orig.colors) do if p.Parent then p.Color = col end end
        local head = c:FindFirstChild("Head")
        local face = head and head:FindFirstChildOfClass("Decal")
        if face and A.orig.face then face.Texture = A.orig.face end
    end
    local function source(p)
        local live = p.Character
        if live and live:FindFirstChildOfClass("Humanoid") then
            local n = 0
            for _, x in ipairs(live:GetChildren()) do
                if x:IsA("Accessory") or x:IsA("Shirt") or x:IsA("Pants") then n += 1 end
            end
            if n > 0 then return live, false end
        end
        local ok, model = pcall(function() return Players:GetCharacterAppearanceAsync(p.UserId) end)
        if ok and model then return model, true end
        return live, false
    end
    local function wear(c, acc)
        local handle = acc:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then return end
        for _, w in ipairs(acc:GetDescendants()) do
            if w:IsA("JointInstance") or w:IsA("WeldConstraint") or w:IsA("Constraint") then w:Destroy() end
        end
        handle.Anchored, handle.CanCollide, handle.Massless = false, false, true
        pcall(function() handle.CanQuery, handle.CanTouch = false, false end)
        local att = handle:FindFirstChildOfClass("Attachment")
        local target
        if att then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("Attachment") and d.Name == att.Name and d.Parent and d.Parent:IsA("BasePart")
                    and not d:FindFirstAncestorOfClass("Accessory") then
                    target = d
                    break
                end
            end
        end
        acc.Parent = c
        local w = Instance.new("Weld")
        w.Name = "AccessoryWeld"
        w.Part0 = handle
        if att and target then
            w.Part1 = target.Parent
            w.C0, w.C1 = att.CFrame, target.CFrame
        else
            w.Part1 = c:FindFirstChild("Head")
            w.C0, w.C1 = CFrame.new(), CFrame.new(0, 0.6, 0)
        end
        w.Parent = handle
    end
    local function apply(p)
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local src, fromWeb = source(p)
        if not src then return false end
        if A.char ~= c or not A.orig then
            A.orig, A.char = snapshot(c), c
        else
            restore()
        end
        for _, x in ipairs(A.orig.acc) do x.Parent = nil end
        for _, x in ipairs(A.orig.cloth) do x.Parent = nil end
        for _, x in ipairs(src:GetChildren()) do
            pcall(function()
                if x:IsA("Accessory") then
                    x.Archivable = true
                    local cl = x:Clone()
                    for _, sc in ipairs(cl:GetDescendants()) do
                        if sc:IsA("LuaSourceContainer") then sc:Destroy() end
                    end
                    cl:SetAttribute("ZenithCopy", true)
                    wear(c, cl)
                elseif x:IsA("Shirt") or x:IsA("Pants") or x:IsA("ShirtGraphic") or x:IsA("BodyColors") then
                    x.Archivable = true
                    local cl = x:Clone()
                    cl:SetAttribute("ZenithCopy", true)
                    cl.Parent = c
                end
            end)
        end
        local bc = src:FindFirstChildOfClass("BodyColors")
        if bc then
            local map = {Head = bc.HeadColor3, Torso = bc.TorsoColor3, UpperTorso = bc.TorsoColor3, LowerTorso = bc.TorsoColor3,
                ["Left Arm"] = bc.LeftArmColor3, LeftUpperArm = bc.LeftArmColor3, LeftLowerArm = bc.LeftArmColor3, LeftHand = bc.LeftArmColor3,
                ["Right Arm"] = bc.RightArmColor3, RightUpperArm = bc.RightArmColor3, RightLowerArm = bc.RightArmColor3, RightHand = bc.RightArmColor3,
                ["Left Leg"] = bc.LeftLegColor3, LeftUpperLeg = bc.LeftLegColor3, LeftLowerLeg = bc.LeftLegColor3, LeftFoot = bc.LeftLegColor3,
                ["Right Leg"] = bc.RightLegColor3, RightUpperLeg = bc.RightLegColor3, RightLowerLeg = bc.RightLegColor3, RightFoot = bc.RightLegColor3}
            for name, col in pairs(map) do
                local part = c:FindFirstChild(name)
                if part and part:IsA("BasePart") then part.Color = col end
            end
        else
            for _, x in ipairs(src:GetChildren()) do
                if x:IsA("BasePart") then
                    local mine = c:FindFirstChild(x.Name)
                    if mine and mine:IsA("BasePart") then mine.Color = x.Color end
                end
            end
        end
        local face
        for _, d in ipairs(src:GetDescendants()) do
            if d:IsA("Decal") and (d.Name == "face" or d.Name == "Face") then face = d break end
        end
        local head = c:FindFirstChild("Head")
        local myFace = head and head:FindFirstChildOfClass("Decal")
        if face and myFace then myFace.Texture = face.Texture end
        if fromWeb then pcall(function() src:Destroy() end) end
        return true
    end
    FX.copyAvatar = function(p)
        if A.from == p.UserId then
            A.from = nil
            restore()
            return
        end
        task.spawn(function()
            if apply(p) then A.from = p.UserId end
        end)
    end
    FX.resetAvatar = function()
        A.from = nil
        restore()
    end
    connect(lp.CharacterAdded, function()
        A.orig, A.char = nil, nil
        local uid = A.from
        if not uid then return end
        task.wait(1.5)
        local p = Players:GetPlayerByUserId(uid)
        if p and A.from == uid then pcall(apply, p) end
    end)
end

do
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local DIRS = {}
    for k = 0, 7 do
        local a = k * math.pi / 4
        DIRS[#DIRS + 1] = Vector3.new(math.cos(a), 0, math.sin(a))
    end
    connect(RunService.Heartbeat, function()
        if not running or not CFG.pixelSurf then return end
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end
        if hum:GetState() ~= Enum.HumanoidStateType.Freefall then return end
        rp.FilterDescendantsInstances = {c}
        local feet = hrp.Position - Vector3.new(0, 2.2, 0)
        local touching = false
        for _, d in ipairs(DIRS) do
            if workspace:Raycast(feet, d * 1.6, rp) or workspace:Raycast(hrp.Position, d * 1.6, rp) then
                touching = true
                break
            end
        end
        if touching then
            local v = hrp.AssemblyLinearVelocity
            if v.Y < -CFG.surfFall then
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, -CFG.surfFall, v.Z)
            end
        end
    end)
end

do
    local Http = game:GetService("HttpService")
    local req = (syn and syn.request) or Compat.http_request or Compat.request or (fluxus and fluxus.request) or (http and http.request)
    local CH = {chat = "zenith-mm2-chat-v1", pres = "zenith-mm2-online-v1", since = "600s", seen = {}, online = 0}
    FX.chatLog = FX.chatLog or {}
    local function post(topic, tbl)
        if not req then return end
        pcall(function()
            req({Url = "https://ntfy.sh/" .. topic, Method = "POST", Headers = {["Content-Type"] = "text/plain"}, Body = Http:JSONEncode(tbl)})
        end)
    end
    local function poll(topic, since)
        if not req then return {} end
        local ok, res = pcall(function()
            return req({Url = "https://ntfy.sh/" .. topic .. "/json?poll=1&since=" .. tostring(since), Method = "GET"})
        end)
        if not ok or type(res) ~= "table" or not res.Body then return {} end
        local out = {}
        for line in tostring(res.Body):gmatch("[^\n]+") do
            local okj, m = pcall(Http.JSONDecode, Http, line)
            if okj and type(m) == "table" and m.event == "message" and m.message then
                local okb, body = pcall(Http.JSONDecode, Http, m.message)
                if okb and type(body) == "table" then out[#out + 1] = {id = m.id, body = body} end
            end
        end
        return out
    end
    FX.chatSend = function(text)
        text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return end
        if not req then
            if FX.notify then FX.notify("chat", "your executor can't send web requests") end
            return
        end
        if tick() - (CH.last or 0) < 2 then return end
        CH.last = tick()
        if #text > 200 then text = string.sub(text, 1, 200) end
        local msg = {n = lp.DisplayName, u = lp.Name, id = lp.UserId, t = text, f = CFG.chatFrame}
        if FX.chatReply then
            msg.r = {n = FX.chatReply.n, t = string.sub(FX.chatReply.t, 1, 60)}
            FX.chatReply = nil
            if FX.chatReplyShow then pcall(FX.chatReplyShow, nil) end
        end
        task.spawn(post, CH.chat, msg)
    end
    FX.online = function() return CH.online end
    task.spawn(function()
        local lastPres, lastCount = 0, 0
        while running do
            if req then
                pcall(function()
                    if tick() - lastPres > 40 then
                        lastPres = tick()
                        post(CH.pres, {u = lp.UserId})
                    end
                    if tick() - lastCount > 30 then
                        lastCount = tick()
                        local users, n = {}, 0
                        for _, m in ipairs(poll(CH.pres, "95s")) do
                            local u = m.body.u
                            if u and not users[u] then
                                users[u] = true
                                n += 1
                            end
                        end
                        CH.online = math.max(n, 1)
                        if FX.onlineSet then pcall(FX.onlineSet, CH.online) end
                    end
                    for _, m in ipairs(poll(CH.chat, CH.since)) do
                        if m.id and not CH.seen[m.id] then
                            CH.seen[m.id] = true
                            CH.since = m.id
                            local b = m.body
                            local entry = {n = tostring(b.n or "?"), u = tostring(b.u or ""), id = tonumber(b.id), t = tostring(b.t or ""),
                                f = tostring(b.f or "None")}
                            if type(b.r) == "table" then entry.r = {n = tostring(b.r.n or ""), t = tostring(b.r.t or "")} end
                            table.insert(FX.chatLog, entry)
                            if #FX.chatLog > 80 then table.remove(FX.chatLog, 1) end
                            if FX.chatAdd then pcall(FX.chatAdd, entry) end
                        end
                    end
                end)
            end
            task.wait(3)
        end
    end)
end

-- wall hop: jump again off a wall you are touching in the air
do
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local last = 0
    connect(UIS.JumpRequest, function()
        if not running or not CFG.wallHop then return end
        local c = lp.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end
        local st = hum:GetState()
        if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then return end
        if tick() - last < 0.22 then return end
        rp.FilterDescendantsInstances = {c}
        local normal
        for k = 0, 7 do
            local a = k * math.pi / 4
            local hit = workspace:Raycast(hrp.Position, Vector3.new(math.cos(a), 0, math.sin(a)) * 2.4, rp)
            if hit then
                normal = hit.Normal
                break
            end
        end
        if not normal then return end
        last = tick()
        local v = hrp.AssemblyLinearVelocity
        local push = Vector3.new(normal.X, 0, normal.Z) * 12
        local up = (hum.UseJumpPower and hum.JumpPower > 0) and hum.JumpPower or 50
        hrp.AssemblyLinearVelocity = Vector3.new(v.X + push.X, math.max(up, 45), v.Z + push.Z)
    end)
end

-- auto farm dashboard: status, time, candies this session, mode
do
    local D = {}
    local startAt, wasOn = nil, false
    ST.farmCollected = ST.farmCollected or 0
    local function build()
        local g = Instance.new("ScreenGui")
        g.Name = "ZenithFarmDash"
        g.ResetOnSpawn = false
        g.DisplayOrder = 55
        pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        local P = FX.themePalette and FX.themePalette() or {bg = Color3.fromRGB(15, 15, 18), text = Color3.new(1, 1, 1), sub = Color3.fromRGB(170, 170, 180)}
        local f = Instance.new("Frame")
        f.Position = UDim2.new(0, 14, 0, 120)
        f.Size = UDim2.fromOffset(210, 112)
        f.BackgroundColor3 = P.bg
        f.BackgroundTransparency = 0.5
        f.BorderSizePixel = 0
        f.Active = true
        f.Parent = g
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local st = Instance.new("UIStroke")
        st.Color = Color3.new(1, 1, 1)
        st.Transparency = 0.85
        st.Parent = f
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(12, 6)
        title.Size = UDim2.new(1, -24, 0, 20)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = P.text
        title.Text = "auto farm"
        title.Parent = f
        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(1, 0.5)
        dot.Position = UDim2.new(1, -12, 0, 16)
        dot.Size = UDim2.fromOffset(8, 8)
        dot.BorderSizePixel = 0
        dot.Parent = f
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local rows = {}
        for k, nm in ipairs({"status", "time", "candies", "mode"}) do
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Position = UDim2.fromOffset(12, 10 + k * 19)
            l.Size = UDim2.new(0.45, 0, 0, 18)
            l.Font = Enum.Font.Gotham
            l.TextSize = 12
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextColor3 = P.sub
            l.Text = nm
            l.Parent = f
            local v = l:Clone()
            v.Position = UDim2.new(0.45, 0, 0, 10 + k * 19)
            v.Size = UDim2.new(0.55, -12, 0, 18)
            v.TextXAlignment = Enum.TextXAlignment.Right
            v.Font = Enum.Font.GothamMedium
            v.TextColor3 = P.text
            v.Text = "-"
            v.Parent = f
            rows[nm] = v
        end
        local dragging, ds, sp
        f.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, ds, sp = true, i.Position, f.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        D.gui, D.rows, D.dot = g, rows, dot
    end
    FX.farmDashOff = function()
        if D.gui then pcall(function() D.gui:Destroy() end) end
        D = {}
    end
    task.spawn(function()
        while running do
            pcall(function()
                if CFG.farm and not wasOn then startAt, wasOn = tick(), true end
                if not CFG.farm and wasOn then wasOn = false end
                if not CFG.farmDash then
                    if D.gui then FX.farmDashOff() end
                    return
                end
                if not (D.gui and D.gui.Parent) then build() end
                local status
                if not CFG.farm then status = "off"
                elseif ST.bagFull then status = "bag full"
                elseif tick() - (ST.farmActiveAt or 0) < 2.5 then status = "farming"
                else status = "waiting" end
                local secs = (CFG.farm and startAt) and math.floor(tick() - startAt) or 0
                D.rows.status.Text = status
                D.rows.time.Text = string.format("%02d:%02d:%02d", secs // 3600, (secs % 3600) // 60, secs % 60)
                D.rows.candies.Text = tostring(ST.farmCollected or 0)
                D.rows.mode.Text = string.lower(CFG.farmMethod or "")
                D.dot.BackgroundColor3 = (status == "farming") and Color3.fromRGB(90, 225, 130)
                    or (status == "off" and Color3.fromRGB(150, 150, 160) or Color3.fromRGB(255, 190, 70))
            end)
            task.wait(0.5)
        end
        FX.farmDashOff()
    end)
end

task.spawn(function()
    local NAMES = {ZenithWatermark = true, ZenithRoundTimer = true, ZenithKeybinds = true, ZenithFarmDash = true, ZenithHitLog = true}
    while running do
        pcall(function()
            local sc = math.clamp(tonumber(CFG.uiScale) or 1, 0.1, 3)
            local roots = {}
            pcall(function() roots[#roots + 1] = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
            roots[#roots + 1] = lp:FindFirstChild("PlayerGui")
            for _, r in ipairs(roots) do
                for _, g in ipairs(r and r:GetChildren() or {}) do
                    if NAMES[g.Name] then
                        for _, top in ipairs(g:GetChildren()) do
                            if top:IsA("GuiObject") then
                                local u = top:FindFirstChild("ZenithScale")
                                if not u then
                                    u = Instance.new("UIScale")
                                    u.Name = "ZenithScale"
                                    u.Parent = top
                                end
                                if math.abs(u.Scale - sc) > 0.001 then u.Scale = sc end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.4)
    end
end)

local function showError(text)
    warn("[Zenith] " .. tostring(text))
end

local ZUI = {}
do
    local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
    local C = {
        bg = rgb(8, 12, 24), side = rgb(10, 15, 30), group = rgb(12, 18, 36), row = rgb(16, 24, 46),
        line = rgb(30, 42, 74), accent = rgb(66, 133, 255), accentDim = rgb(28, 58, 120),
        text = rgb(226, 231, 240), sub = rgb(128, 140, 166), dim = rgb(80, 92, 120), white = rgb(255, 255, 255),
    }
    local PALETTES = {
        Black = {bg = rgb(11, 11, 14), side = rgb(15, 15, 19), group = rgb(19, 19, 24), row = rgb(30, 30, 37),
                 line = rgb(44, 44, 54), accent = rgb(132, 104, 255), accentDim = rgb(58, 46, 112),
                 text = rgb(236, 236, 242), sub = rgb(146, 146, 160), dim = rgb(96, 96, 110), white = rgb(255, 255, 255)},
    }
    local LOGOS = {}
    ZUI.current = "Black"
    ZUI.LOGO = "rbxassetid://13936134740"
    local function onAccent()
        local a = C.accent
        return (0.299 * a.R + 0.587 * a.G + 0.114 * a.B) > 0.7 and C.bg or C.white
    end
    function ZUI.applyPalette(name)
        local pal = PALETTES[name] and name or "Black"
        for k, v in pairs(PALETTES[pal]) do C[k] = v end
        ZUI.current = pal
        ZUI.LOGO = LOGOS[pal] or "rbxassetid://13936134740"
    end
    FX.themePalette = function() return C end
    FX.themeLogo = function() return ZUI.LOGO end
    local SOFT = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function tw(o, info, props)
        local t = TweenService:Create(o, info, props)
        t:Play()
        return t
    end
    local function rootGui(name, order)
        local g = Instance.new("ScreenGui")
        g.Name = name
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        g.DisplayOrder = order or 100
        local ok = pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        return g
    end
    local function corner(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 4)
        c.Parent = o
    end
    local function stroke(o, col, th, tr)
        local st = Instance.new("UIStroke")
        st.Color = col
        st.Thickness = th or 1
        st.Transparency = tr or 0
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Parent = o
        return st
    end
    local function text(parent, str, size, col, font, xa)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = str
        l.TextSize = size
        l.TextColor3 = col
        l.Font = font or Enum.Font.GothamMedium
        l.TextXAlignment = xa or Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = parent
        return l
    end
    local function frame(parent, col, tr)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = col or C.row
        f.BackgroundTransparency = tr or 0
        f.BorderSizePixel = 0
        f.Parent = parent
        return f
    end

    -- vector icons drawn from frames (16x16 canvas)
    local function icon(parent, name, col)
        local h = Instance.new("Frame")
        h.BackgroundTransparency = 1
        h.Size = UDim2.fromOffset(16, 16)
        h.Parent = parent
        local fills, strokes = {}, {}
        local function bar(x, y, w, ht, rot, r)
            local f = frame(h, col)
            f.Position = UDim2.fromOffset(x, y)
            f.Size = UDim2.fromOffset(w, ht)
            f.Rotation = rot or 0
            if r then corner(f, r) end
            fills[#fills + 1] = f
            return f
        end
        local function ring(x, y, w, ht, th, r)
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.Position = UDim2.fromOffset(x, y)
            f.Size = UDim2.fromOffset(w, ht or w)
            f.Parent = h
            corner(f, r or 99)
            strokes[#strokes + 1] = stroke(f, col, th or 1.5)
            return f
        end
        if name == "swords" then
            ring(3, 3, 10, 10, 1.5)
            bar(7.25, 0, 1.5, 4)
            bar(7.25, 12, 1.5, 4)
            bar(0, 7.25, 4, 1.5)
            bar(12, 7.25, 4, 1.5)
            bar(6.5, 6.5, 3, 3, 0, 2)
        elseif name == "flame" then
            bar(7, 0, 2.5, 8, 22)
            bar(4, 6.5, 8, 2.5, 0)
            bar(6.5, 8, 2.5, 8, 22)
        elseif name == "wind" then
            bar(1, 3, 11, 2, 0, 1)
            bar(4, 7, 11, 2, 0, 1)
            bar(1, 11, 8, 2, 0, 1)
        elseif name == "user" then
            bar(5, 0.5, 6, 6, 0, 3)
            bar(2, 8, 12, 7.5, 0, 4)
        elseif name == "map-pin" then
            ring(3, 0.5, 10, 10, 1.5)
            bar(5.5, 7.5, 5, 5, 45)
            bar(6.5, 4, 3, 3, 0, 2)
        elseif name == "coins" then
            ring(1, 1, 14, 14, 1.5)
            bar(7.25, 4, 1.5, 8)
            bar(5, 5, 6, 1.5)
            bar(5, 9.5, 6, 1.5)
        elseif name == "scan-eye" then
            ring(0.5, 4, 15, 8, 1.5, 6)
            bar(6, 6, 4, 4, 0, 2)
        elseif name == "globe" then
            ring(1, 1, 14, 14, 1.5)
            ring(5, 1, 6, 14, 1.2)
            bar(1, 7.25, 14, 1.5)
        elseif name == "person-standing" then
            bar(10, 1, 2, 10)
            bar(10, 1, 5, 2)
            bar(4, 9, 8, 6, 0, 3)
        elseif name == "volume-2" then
            bar(1, 5.5, 4, 5)
            bar(4, 3, 4, 10, 0, 1)
            bar(10, 5, 1.5, 6, 0, 1)
            bar(13, 3, 1.5, 10, 0, 1)
        elseif name == "wrench" then
            bar(1, 3, 14, 1.5)
            bar(1, 7.25, 14, 1.5)
            bar(1, 11.5, 14, 1.5)
            bar(3, 1.5, 4, 4.5, 0, 2)
            bar(9, 5.75, 4, 4.5, 0, 2)
            bar(5, 10, 4, 4.5, 0, 2)
        elseif name == "save" then
            ring(1, 1, 14, 14, 1.5, 3)
            bar(4.5, 3, 7, 3.5)
            bar(4, 9, 8, 5, 0, 1)
        elseif name == "settings" then
            ring(3.5, 3.5, 9, 9, 2.2)
            for k = 0, 7 do
                local a = math.rad(k * 45)
                local cx, cy = 8 + math.cos(a) * 6.6, 8 + math.sin(a) * 6.6
                bar(cx - 1.4, cy - 1.4, 2.8, 2.8, k * 45)
            end
        elseif name == "search" then
            ring(1, 1, 10, 10, 1.6)
            bar(10.5, 9, 2, 6.5, -45, 1)
        elseif name == "close" then
            bar(7.25, 1, 1.6, 14, 45, 1)
            bar(7.25, 1, 1.6, 14, -45, 1)
        elseif name == "chev" then
            bar(3, 6.5, 6, 1.6, 40, 1)
            bar(7, 6.5, 6, 1.6, -40, 1)
        elseif name == "check" then
            bar(3, 8.5, 5, 2, 45, 1)
            bar(6, 7, 8, 2, -50, 1)
        else
            bar(6, 6, 4, 4, 0, 2)
        end
        local ic = {holder = h}
        function ic:Color(c2)
            for _, f in ipairs(fills) do f.BackgroundColor3 = c2 end
            for _, st in ipairs(strokes) do st.Color = c2 end
        end
        function ic:Tween(c2)
            for _, f in ipairs(fills) do tw(f, QUICK, {BackgroundColor3 = c2}) end
            for _, st in ipairs(strokes) do tw(st, QUICK, {Color = c2}) end
        end
        return ic
    end
    ZUI.icon = icon

    local notifGui, notifHolder
    function ZUI:Notify(o)
        if not notifGui or not notifGui.Parent then
            notifGui = rootGui("ZenithNotify", 300)
            notifHolder = Instance.new("Frame")
            notifHolder.BackgroundTransparency = 1
            notifHolder.AnchorPoint = Vector2.new(1, 0)
            notifHolder.Position = UDim2.new(1, -14, 0, 56)
            notifHolder.Size = UDim2.new(0, 300, 1, -66)
            notifHolder.Parent = notifGui
            local lay = Instance.new("UIListLayout")
            lay.Padding = UDim.new(0, 6)
            lay.SortOrder = Enum.SortOrder.LayoutOrder
            lay.Parent = notifHolder
        end
        local dur = o.Duration or 5
        local slot = Instance.new("Frame")
        slot.BackgroundTransparency = 1
        slot.Size = UDim2.new(1, 0, 0, 62)
        slot.Parent = notifHolder
        local f = Instance.new("CanvasGroup")
        f.Size = UDim2.fromScale(1, 1)
        f.Position = UDim2.new(0, 60, 0, 0)
        f.BackgroundColor3 = C.bg
        f.BackgroundTransparency = 0.08
        f.GroupTransparency = 1
        f.Parent = slot
        corner(f, 5)
        stroke(f, C.line, 1)
        local edge = frame(f, C.accent)
        edge.Size = UDim2.new(0, 3, 1, 0)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(30, 30)
        ic.Position = UDim2.fromOffset(12, 10)
        ic.BackgroundTransparency = 1
        ic.Image = ZUI.LOGO
        ic.ScaleType = Enum.ScaleType.Fit
        ic.Parent = f
        corner(ic, 4)
        local t = text(f, string.upper(tostring(o.Title or "")), 12, C.text, Enum.Font.GothamBold)
        t.Position = UDim2.fromOffset(50, 9)
        t.Size = UDim2.new(1, -60, 0, 16)
        local c = text(f, tostring(o.Content or ""), 12, C.sub)
        c.Position = UDim2.fromOffset(50, 26)
        c.Size = UDim2.new(1, -60, 0, 30)
        c.TextWrapped = true
        c.TextTruncate = Enum.TextTruncate.None
        c.TextYAlignment = Enum.TextYAlignment.Top
        local prog = frame(f, C.accent, 0.3)
        prog.AnchorPoint = Vector2.new(0, 1)
        prog.Position = UDim2.new(0, 3, 1, 0)
        prog.Size = UDim2.new(1, -3, 0, 2)
        tw(f, SOFT, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0})
        tw(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
        local done = false
        local function close()
            if done then return end
            done = true
            tw(f, SOFT, {Position = UDim2.new(0, 60, 0, 0), GroupTransparency = 1})
            task.wait(0.2)
            tw(slot, QUICK, {Size = UDim2.new(1, 0, 0, 0)})
            task.wait(0.13)
            slot:Destroy()
        end
        local hit = Instance.new("TextButton")
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Size = UDim2.fromScale(1, 1)
        hit.Parent = f
        hit.Activated:Connect(function() task.spawn(close) end)
        task.delay(dur, close)
    end

    function ZUI:GetThemes() return PALETTES end
    function ZUI:SetTheme(name)
        ZUI.applyPalette(name)
        pcall(function() if FX.wmDestroy then FX.wmDestroy() end end)
        pcall(function() if FX.timerDestroy then FX.timerDestroy() end end)
        pcall(function() if FX.bindHudDestroy then FX.bindHudDestroy() end end)
        pcall(function() if FX.applyOpenTheme then FX.applyOpenTheme() end end)
        if ZUI.rebuild then task.delay(0.1, ZUI.rebuild) end
    end

    function ZUI:CreateWindow(opts)
        if opts.Theme then ZUI.applyPalette(opts.Theme) end
        local W = {tabs = {}, conns = {}, open = true, guis = {}}
        local gui = rootGui("ZenithMenu", 100)
        local main = Instance.new("Frame")
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.fromScale(0.5, 0.5)
        main.Size = UDim2.fromOffset(640, 420)
        main.BackgroundColor3 = C.bg
        main.BackgroundTransparency = 0.04
        main.Visible = false
        main.ClipsDescendants = true
        main.Parent = gui
        corner(main, 14)
        stroke(main, C.line, 1)
        local art = Instance.new("Frame")
        art.Name = "ZenithBgArt"
        art.BackgroundTransparency = 1
        art.Size = UDim2.fromScale(1, 1)
        art.ZIndex = 0
        art.Parent = main
        FX.menuArt = art
        if FX.drawMenuBg then pcall(FX.drawMenuBg) end
        local sc = Instance.new("UIScale")
        sc.Parent = main
        local function baseScale()
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            return math.clamp(math.min((vp.X - 24) / 640, (vp.Y - 24) / 420), 0.55, 1.25)
        end
        W.mult = opts.Scale or 1
        local function target() return baseScale() * W.mult end
        sc.Scale = target()

        local top = frame(main, C.side, 1)
        top.Size = UDim2.new(1, 0, 0, 50)
        top.Active = true
        local strip = frame(main, C.white)
        strip.Size = UDim2.new(1, 0, 0, 2)
        strip.ZIndex = 5
        strip.Visible = false
        local sg = Instance.new("UIGradient")
        sg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.accentDim),
            ColorSequenceKeypoint.new(0.5, C.accent),
            ColorSequenceKeypoint.new(1, C.accentDim),
        })
        sg.Parent = strip
        task.spawn(function()
            local t0 = tick()
            while strip.Parent do
                sg.Offset = Vector2.new(math.sin((tick() - t0) * 0.8) * 0.5, 0)
                RunService.Heartbeat:Wait()
            end
        end)
        local topLine = frame(top, C.line)
        topLine.AnchorPoint = Vector2.new(0, 1)
        topLine.Position = UDim2.new(0, 0, 1, 0)
        topLine.Size = UDim2.new(1, 0, 0, 1)
        local glow = frame(top, C.accent)
        glow.AnchorPoint = Vector2.new(0, 1)
        glow.Position = UDim2.new(0, 0, 1, 0)
        glow.Size = UDim2.new(0, 0, 0, 1)
        glow.Visible = false
        local logo = Instance.new("ImageLabel")
        logo.Size = UDim2.fromOffset(28, 28)
        logo.Position = UDim2.new(0, 14, 0.5, -14)
        logo.BackgroundTransparency = 1
        logo.Image = ZUI.LOGO
        logo.ScaleType = Enum.ScaleType.Fit
        logo.Parent = top
        corner(logo, 4)
        if ZUI.current == "Halloween" then
            pcall(function()
                -- the event's own pictures from the game GUI, plus the Halloween cat
                local pics, seen = {"rbxassetid://137886818975521"}, {["rbxassetid://137886818975521"] = true}
                local pg = lp:FindFirstChild("PlayerGui")
                if pg then
                    for _, d in ipairs(pg:GetDescendants()) do
                        if #pics >= 6 then break end
                        if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image ~= "" and not seen[d.Image] then
                            local x, hw = d, false
                            for _ = 1, 10 do
                                if not x or x == pg then break end
                                local n = string.lower(x.Name)
                                if string.find(n, "hallow", 1, true) or string.find(n, "event", 1, true) or string.find(n, "candy", 1, true) then
                                    hw = true
                                    break
                                end
                                x = x.Parent
                            end
                            if hw then
                                seen[d.Image] = true
                                pics[#pics + 1] = d.Image
                            end
                        end
                    end
                end
                local function pic(parent, img, size, pos, tr, rot, z)
                    local l = Instance.new("ImageLabel")
                    l.BackgroundTransparency = 1
                    l.Image = img
                    l.ImageTransparency = tr
                    l.ScaleType = Enum.ScaleType.Fit
                    l.Size = UDim2.fromOffset(size, size)
                    l.Position = pos
                    l.Rotation = rot or 0
                    l.ZIndex = z or 0
                    l.Parent = parent
                    return l
                end
                local badge = pic(top, pics[1], 22, UDim2.new(0, 132, 0.5, -11), 0, 0, 6)
                Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
                pic(main, pics[2] or pics[1], 120, UDim2.new(1, -130, 1, -130), 0.82, -8, 0)
                pic(main, pics[3] or pics[1], 64, UDim2.new(1, -72, 0, 52), 0.75, 12, 0)
                if pics[4] then pic(main, pics[4], 56, UDim2.new(0, 8, 1, -64), 0.78, -10, 0) end
            end)
        end
        local name = text(top, "zenith", 17, C.white, Enum.Font.GothamBold)
        name.Position = UDim2.fromOffset(52, 8)
        name.Size = UDim2.fromOffset(70, 20)
        local author = text(top, opts.Author or "", 11, C.sub, Enum.Font.Gotham)
        author.Position = UDim2.fromOffset(52, 28)
        author.Size = UDim2.fromOffset(200, 14)

        local sBox = frame(top, C.row, 0.2)
        sBox.AnchorPoint = Vector2.new(1, 0.5)
        sBox.Position = UDim2.new(1, -46, 0.5, 0)
        sBox.Size = UDim2.fromOffset(190, 30)
        corner(sBox, 10)
        local sStroke = stroke(sBox, C.line, 1)
        local sIc = icon(sBox, "search", C.dim)
        sIc.holder.Position = UDim2.new(0, 8, 0.5, -8)
        local search = Instance.new("TextBox")
        search.BackgroundTransparency = 1
        search.Position = UDim2.fromOffset(30, 0)
        search.Size = UDim2.new(1, -36, 1, 0)
        search.TextColor3 = C.text
        search.PlaceholderColor3 = C.dim
        search.PlaceholderText = "search"
        search.Text = ""
        search.Font = Enum.Font.GothamMedium
        search.TextSize = 12
        search.ClearTextOnFocus = false
        search.TextXAlignment = Enum.TextXAlignment.Left
        search.Parent = sBox
        search.Focused:Connect(function()
            tw(sStroke, QUICK, {Color = C.accent})
            sIc:Tween(C.accent)
        end)
        search.FocusLost:Connect(function()
            tw(sStroke, QUICK, {Color = C.line})
            sIc:Tween(C.dim)
        end)

        local close = Instance.new("TextButton")
        close.AnchorPoint = Vector2.new(1, 0.5)
        close.Position = UDim2.new(1, -10, 0.5, 0)
        close.Size = UDim2.fromOffset(30, 30)
        close.BackgroundColor3 = C.row
        close.BackgroundTransparency = 0.2
        close.Text = ""
        close.AutoButtonColor = false
        close.Parent = top
        corner(close, 10)
        stroke(close, C.line, 1)
        local cIc = icon(close, "close", C.sub)
        cIc.holder.Position = UDim2.new(0.5, -8, 0.5, -8)
        close.MouseEnter:Connect(function()
            tw(close, QUICK, {BackgroundColor3 = rgb(120, 30, 44)})
            cIc:Tween(C.white)
        end)
        close.MouseLeave:Connect(function()
            tw(close, QUICK, {BackgroundColor3 = C.row})
            cIc:Tween(C.sub)
        end)

        local side = Instance.new("ScrollingFrame")
        side.Position = UDim2.fromOffset(0, 50)
        side.Size = UDim2.new(0, 168, 1, -110)
        side.BackgroundColor3 = C.side
        side.BackgroundTransparency = 1
        side.BorderSizePixel = 0
        side.ScrollBarThickness = 0
        side.CanvasSize = UDim2.new()
        side.AutomaticCanvasSize = Enum.AutomaticSize.Y
        side.ScrollingDirection = Enum.ScrollingDirection.Y
        side.Parent = main
        local sidePad = Instance.new("UIPadding")
        sidePad.PaddingTop = UDim.new(0, 6)
        sidePad.PaddingBottom = UDim.new(0, 8)
        sidePad.PaddingLeft = UDim.new(0, 10)
        sidePad.PaddingRight = UDim.new(0, 8)
        sidePad.Parent = side
        local sl = Instance.new("UIListLayout")
        sl.Padding = UDim.new(0, 4)
        sl.SortOrder = Enum.SortOrder.LayoutOrder
        sl.Parent = side
        local sideLine = frame(main, C.line)
        sideLine.Position = UDim2.fromOffset(168, 50)
        sideLine.Size = UDim2.new(0, 1, 1, -50)
        sideLine.BackgroundTransparency = 0.4

        local prof = frame(main, C.side, 1)
        prof.AnchorPoint = Vector2.new(0, 1)
        prof.Position = UDim2.new(0, 0, 1, 0)
        prof.Size = UDim2.fromOffset(168, 58)
        local profLine = frame(prof, C.line)
        profLine.Size = UDim2.new(1, 0, 0, 1)
        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(34, 34)
        av.Position = UDim2.new(0, 10, 0.5, -17)
        av.BackgroundColor3 = C.row
        av.Image = ""
        av.Parent = prof
        corner(av, 17)
        stroke(av, C.accent, 1.5)
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and img then av.Image = img end
        end)
        local dot = frame(prof, rgb(60, 220, 120))
        dot.Size = UDim2.fromOffset(9, 9)
        dot.Position = UDim2.new(0, 36, 0.5, 8)
        corner(dot, 5)
        stroke(dot, C.side, 1.5)
        local dn = text(prof, lp.DisplayName, 12, C.white, Enum.Font.GothamBold)
        dn.Position = UDim2.fromOffset(52, 11)
        dn.Size = UDim2.new(1, -58, 0, 16)
        local un = text(prof, "@" .. lp.Name, 11, C.sub, Enum.Font.Gotham)
        un.Position = UDim2.fromOffset(52, 29)
        un.Size = UDim2.new(1, -58, 0, 14)

        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(180, 58)
        holder.Size = UDim2.new(1, -192, 1, -66)
        holder.BackgroundTransparency = 1
        holder.ClipsDescendants = true
        holder.Parent = main

        local dragging, dStart, pStart = false, nil, nil
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, dStart, pStart = true, i.Position, main.Position
            end
        end)
        W.conns[#W.conns + 1] = UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dStart
                main.Position = UDim2.new(pStart.X.Scale, pStart.X.Offset + d.X, pStart.Y.Scale, pStart.Y.Offset + d.Y)
            end
        end)
        W.conns[#W.conns + 1] = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local closing = false
        function W:Open()
            W.open = true
            main.Visible = true
            sc.Scale = target() * 0.9
            tw(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target()})
        end
        function W:Close()
            if closing then return end
            closing = true
            W.open = false
            tw(sc, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = target() * 0.9}).Completed:Wait()
            if not W.open then main.Visible = false end
            closing = false
        end
        function W:Toggle()
            if W.open then task.spawn(function() W:Close() end) else W:Open() end
        end
        function W:SetScale(m)
            W.mult = m
            sc.Scale = target()
        end
        close.Activated:Connect(function() task.spawn(function() W:Close() end) end)

        local function selectTab(t)
            for _, x in ipairs(W.tabs) do
                local on = x == t
                tw(x.btn, QUICK, {BackgroundTransparency = on and 0.82 or 1})
                tw(x.btnText, QUICK, {TextColor3 = on and C.white or C.sub})
                x.ic:Tween(on and C.accent or C.dim)
                x.mark.Visible = false
                if on then
                    x.wrap.Visible = true
                    x.wrap.Position = UDim2.fromOffset(0, 10)
                    tw(x.wrap, SOFT, {Position = UDim2.fromOffset(0, 0)})
                else
                    x.wrap.Visible = false
                end
            end
            W.cur = t
        end

        local function applySearch()
            local q = string.lower(search.Text or "")
            local firstHit
            for _, t in ipairs(W.tabs) do
                local any = false
                local groupVis = {}
                for _, r in ipairs(t.rows) do
                    local show = q == "" or r.title:find(q, 1, true) ~= nil
                    r.frame.Visible = show
                    if show then
                        any = true
                        groupVis[r.group] = true
                    end
                end
                for _, g in ipairs(t.groups) do
                    g.box.Visible = q == "" or groupVis[g] == true
                    g.head.Visible = q == ""
                end
                for _, ch in ipairs(t.page:GetDescendants()) do
                    if ch.Name == "ZList" then ch.Visible = q == "" end
                end
                if q ~= "" and any and not firstHit then firstHit = t end
            end
            if q ~= "" and firstHit and W.cur then
                local has = false
                for _, r in ipairs(W.cur.rows) do
                    if r.frame.Visible then
                        has = true
                        break
                    end
                end
                if not has then selectTab(firstHit) end
            end
        end
        search:GetPropertyChangedSignal("Text"):Connect(applySearch)

        function W:Tab(o)
            local T = {rows = {}, groups = {}, order = 0}
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 38)
            b.BackgroundColor3 = C.accent
            b.BackgroundTransparency = 1
            b.Text = ""
            b.AutoButtonColor = false
            b.LayoutOrder = #W.tabs + 1
            b.Parent = side
            corner(b, 11)
            local mark = frame(b, C.accent)
            mark.AnchorPoint = Vector2.new(0, 0.5)
            mark.Position = UDim2.new(0, 3, 0.5, 0)
            mark.Size = UDim2.fromOffset(3, 16)
            mark.Visible = false
            corner(mark, 2)
            local ic = icon(b, o.Icon, C.dim)
            ic.holder.Position = UDim2.new(0, 14, 0.5, -8)
            local bt = text(b, tostring(o.Title or ""), 13, C.sub, Enum.Font.GothamMedium)
            bt.Position = UDim2.fromOffset(40, 0)
            bt.Size = UDim2.new(1, -46, 1, 0)
            local wrap = Instance.new("Frame")
            wrap.Size = UDim2.fromScale(1, 1)
            wrap.BackgroundTransparency = 1
            wrap.Visible = false
            wrap.Parent = holder
            local page = Instance.new("ScrollingFrame")
            page.Size = UDim2.fromScale(1, 1)
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.ScrollBarThickness = 2
            page.ScrollBarImageColor3 = C.accent
            page.CanvasSize = UDim2.new()
            page.AutomaticCanvasSize = Enum.AutomaticSize.Y
            page.ScrollingDirection = Enum.ScrollingDirection.Y
            page.Parent = wrap
            local pp = Instance.new("UIPadding")
            pp.PaddingRight = UDim.new(0, 6)
            pp.PaddingBottom = UDim.new(0, 10)
            pp.Parent = page
            local cols = Instance.new("Frame")
            cols.BackgroundTransparency = 1
            cols.Size = UDim2.new(1, 0, 0, 0)
            cols.AutomaticSize = Enum.AutomaticSize.Y
            cols.Parent = page
            T.cols = {}
            do
                local col = Instance.new("Frame")
                col.BackgroundTransparency = 1
                col.Size = UDim2.new(1, 0, 0, 0)
                col.AutomaticSize = Enum.AutomaticSize.Y
                col.Parent = cols
                local cl = Instance.new("UIListLayout")
                cl.Padding = UDim.new(0, 10)
                cl.SortOrder = Enum.SortOrder.LayoutOrder
                cl.Parent = col
                T.cols[1] = {f = col, h = 0}
                T.cols[2] = T.cols[1]
            end
            T.page, T.btn, T.btnText, T.ic, T.mark, T.wrap = page, b, bt, ic, mark, wrap
            b.MouseEnter:Connect(function() if W.cur ~= T then tw(bt, QUICK, {TextColor3 = C.text}) end end)
            b.MouseLeave:Connect(function() if W.cur ~= T then tw(bt, QUICK, {TextColor3 = C.sub}) end end)

            local curGroup
            local function newGroup(title)
                T.order += 10
                local col = (T.cols[1].h <= T.cols[2].h) and T.cols[1] or T.cols[2]
                col.h += 34
                local box = frame(col.f, C.group, 0.1)
                box.Size = UDim2.new(1, 0, 0, 0)
                box.AutomaticSize = Enum.AutomaticSize.Y
                box.LayoutOrder = T.order
                corner(box, 12)
                local bst = stroke(box, C.line, 1)
                bst.Transparency = 0.55
                local gl = Instance.new("UIListLayout")
                gl.SortOrder = Enum.SortOrder.LayoutOrder
                gl.Parent = box
                local gp = Instance.new("UIPadding")
                gp.PaddingBottom = UDim.new(0, 4)
                gp.Parent = box
                local head = frame(box, C.group, 1)
                head.Size = UDim2.new(1, 0, 0, title and 30 or 0)
                head.LayoutOrder = 0
                head.Visible = title ~= nil
                if title then
                    local ht = text(head, string.upper(tostring(title)), 11, C.sub, Enum.Font.GothamBold)
                    ht.Position = UDim2.fromOffset(14, 4)
                    ht.Size = UDim2.new(1, -28, 1, -4)
                    local hl = frame(head, C.line)
                    hl.AnchorPoint = Vector2.new(0, 1)
                    hl.Position = UDim2.new(0, 14, 1, 0)
                    hl.Size = UDim2.new(1, -28, 0, 1)
                    hl.BackgroundTransparency = 0.5
                end
                local g = {box = box, head = head, order = 0, col = col}
                T.groups[#T.groups + 1] = g
                curGroup = g
                return g
            end

            local function row(h, titleText)
                local g = curGroup or newGroup(nil)
                g.order += 10
                if not T._into then g.col.h += h end
                local f = frame(T._into or g.box, C.row, 1)
                f.Size = UDim2.new(1, 0, 0, h)
                f.LayoutOrder = g.order
                T.rows[#T.rows + 1] = {frame = f, title = string.lower(tostring(titleText or "")), group = g}
                return f, g
            end

            function T:Section(so)
                newGroup(tostring(so.Title or ""))
            end

            function T:Toggle(to)
                local f = row(40, to.Title)
                local l = text(f, tostring(to.Title or ""), 13, C.text)
                l.Position = UDim2.fromOffset(14, 0)
                l.Size = UDim2.new(1, to.Settings and -104 or -66, 1, 0)
                local box = frame(f, C.row)
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -14, 0.5, 0)
                box.Size = UDim2.fromOffset(40, 22)
                corner(box, 11)
                local bs = stroke(box, C.line, 1)
                local knob = frame(box, C.sub)
                knob.AnchorPoint = Vector2.new(0, 0.5)
                knob.Size = UDim2.fromOffset(16, 16)
                corner(knob, 8)
                local state = to.Value and true or false
                local function render(anim)
                    local info = anim and QUICK or TweenInfo.new(0)
                    tw(box, info, {BackgroundColor3 = state and C.accent or C.row})
                    tw(bs, info, {Color = state and C.accent or C.line})
                    tw(knob, info, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                        BackgroundColor3 = state and onAccent() or C.sub})
                end
                render(false)
                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Text = ""
                hit.Size = UDim2.fromScale(1, 1)
                hit.Parent = f
                hit.MouseEnter:Connect(function() tw(f, QUICK, {BackgroundTransparency = 0.6}) end)
                hit.MouseLeave:Connect(function() tw(f, QUICK, {BackgroundTransparency = 1}) end)
                local obj = {}
                function obj:Set(v)
                    state = v and true or false
                    render(true)
                    if to.Callback then task.spawn(to.Callback, state) end
                end
                hit.Activated:Connect(function()
                    obj:Set(not state)
                    if FX.uiClick then FX.uiClick() end
                end)
                if to.Settings then
                    local dots = Instance.new("TextButton")
                    dots.AnchorPoint = Vector2.new(1, 0.5)
                    dots.Position = UDim2.new(1, -60, 0.5, 0)
                    dots.Size = UDim2.fromOffset(26, 22)
                    dots.BackgroundColor3 = C.row
                    dots.BackgroundTransparency = 1
                    dots.Text = ""
                    dots.AutoButtonColor = false
                    dots.ZIndex = 3
                    dots.Parent = f
                    corner(dots, 4)
                    local dl = {}
                    for k = -1, 1 do
                        local d = frame(dots, C.sub)
                        d.AnchorPoint = Vector2.new(0.5, 0.5)
                        d.Position = UDim2.new(0.5, k * 6, 0.5, 0)
                        d.Size = UDim2.fromOffset(3, 3)
                        d.ZIndex = 4
                        corner(d, 2)
                        dl[#dl + 1] = d
                    end
                    local cont = Instance.new("Frame")
                    cont.BackgroundTransparency = 1
                    cont.Size = UDim2.new(1, 0, 0, 0)
                    cont.AutomaticSize = Enum.AutomaticSize.Y
                    cont.LayoutOrder = f.LayoutOrder + 1
                    cont.Visible = false
                    cont.Parent = f.Parent
                    local cl = Instance.new("UIListLayout")
                    cl.SortOrder = Enum.SortOrder.LayoutOrder
                    cl.Parent = cont
                    local cp = Instance.new("UIPadding")
                    cp.PaddingLeft = UDim.new(0, 10)
                    cp.Parent = cont
                    local bar = frame(cont, C.accent, 0.4)
                    bar.Size = UDim2.new(0, 2, 0, 0)
                    bar.LayoutOrder = -1
                    local prev = T._into
                    T._into = cont
                    pcall(to.Settings, T)
                    T._into = prev
                    local function paintDots(open)
                        for _, d in ipairs(dl) do tw(d, QUICK, {BackgroundColor3 = open and C.accent or C.sub}) end
                        tw(dots, QUICK, {BackgroundTransparency = open and 0.3 or 1})
                    end
                    dots.Activated:Connect(function()
                        cont.Visible = not cont.Visible
                        paintDots(cont.Visible)
                    end)
                end
                return obj
            end

            function T:Slider(so)
                local v = so.Value or {}
                local mn, mx, step = v.Min or 0, v.Max or 100, so.Step or 1
                local val = v.Default or mn
                local f = row(44, so.Title)
                local l = text(f, tostring(so.Title or ""), 13, C.text)
                l.Position = UDim2.fromOffset(12, 4)
                l.Size = UDim2.new(1, -90, 0, 18)
                local pill = frame(f, C.row)
                pill.AnchorPoint = Vector2.new(1, 0)
                pill.Position = UDim2.new(1, -12, 0, 4)
                pill.Size = UDim2.fromOffset(52, 18)
                corner(pill, 9)
                local vl = text(pill, "", 11, C.text, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
                vl.Size = UDim2.fromScale(1, 1)
                local bar = frame(f, C.line)
                bar.Position = UDim2.fromOffset(12, 31)
                bar.Size = UDim2.new(1, -24, 0, 5)
                corner(bar, 3)
                local fill = frame(bar, C.accent)
                corner(fill, 3)
                local knob = frame(bar, C.white)
                knob.Size = UDim2.fromOffset(14, 14)
                knob.AnchorPoint = Vector2.new(0.5, 0.5)
                corner(knob, 7)
                stroke(knob, C.accent, 2)
                local function fmt(x)
                    if step < 1 then return string.format("%.2f", x) end
                    return tostring(math.floor(x + 0.5))
                end
                local function render(anim)
                    local a = (mx > mn) and math.clamp((val - mn) / (mx - mn), 0, 1) or 0
                    local info = anim and QUICK or TweenInfo.new(0)
                    tw(fill, info, {Size = UDim2.new(a, 0, 1, 0)})
                    tw(knob, info, {Position = UDim2.new(a, 0, 0.5, 0)})
                    vl.Text = fmt(val)
                end
                render(false)
                local drag = false
                local function setX(x)
                    local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    local q = math.floor((a * (mx - mn)) / step + 0.5) * step + mn
                    q = math.clamp(q, mn, mx)
                    if math.abs(q - val) > 1e-9 then
                        val = q
                        render(true)
                        if so.Callback then task.spawn(so.Callback, val) end
                    end
                end
                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Text = ""
                hit.Position = UDim2.fromOffset(4, 20)
                hit.Size = UDim2.new(1, -8, 0, 24)
                hit.Parent = f
                hit.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        drag = true
                        tw(knob, QUICK, {Size = UDim2.fromOffset(17, 17)})
                        setX(i.Position.X)
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        setX(i.Position.X)
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputEnded:Connect(function(i)
                    if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                        drag = false
                        tw(knob, QUICK, {Size = UDim2.fromOffset(10, 10)})
                    end
                end)
                local obj = {}
                function obj:Set(x)
                    val = math.clamp(x, mn, mx)
                    render(true)
                end
                return obj
            end

            function T:Button(bo)
                local f = row(38, bo.Title)
                local b2 = Instance.new("TextButton")
                b2.AnchorPoint = Vector2.new(0.5, 0.5)
                b2.Position = UDim2.fromScale(0.5, 0.5)
                b2.Size = UDim2.new(1, -20, 0, 30)
                b2.BackgroundColor3 = C.row
                b2.Text = tostring(bo.Title or "")
                b2.TextColor3 = C.text
                b2.Font = Enum.Font.GothamMedium
                b2.TextSize = 12
                b2.AutoButtonColor = false
                b2.Parent = f
                corner(b2, 7)
                local st = stroke(b2, C.line, 1)
                b2.MouseEnter:Connect(function()
                    tw(st, QUICK, {Color = C.accent})
                    tw(b2, QUICK, {BackgroundColor3 = C.accentDim})
                end)
                b2.MouseLeave:Connect(function()
                    tw(st, QUICK, {Color = C.line})
                    tw(b2, QUICK, {BackgroundColor3 = C.row})
                end)
                b2.Activated:Connect(function()
                    b2.BackgroundColor3 = C.accent
                    tw(b2, TweenInfo.new(0.3), {BackgroundColor3 = C.row})
                    if bo.Callback then task.spawn(bo.Callback) end
                end)
                return {}
            end

            function T:Dropdown(dop)
                local values = dop.Values or {}
                local cur = dop.Value
                local f, g = row(34, dop.Title)
                local l = text(f, tostring(dop.Title or ""), 13, C.text)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(0.5, -12, 1, 0)
                local vb = Instance.new("TextButton")
                vb.AnchorPoint = Vector2.new(1, 0.5)
                vb.Position = UDim2.new(1, -12, 0.5, 0)
                vb.Size = UDim2.new(0.5, -12, 0, 24)
                vb.BackgroundColor3 = C.row
                vb.Text = ""
                vb.AutoButtonColor = false
                vb.Parent = f
                corner(vb, 4)
                local vst = stroke(vb, C.line, 1)
                local vt = text(vb, "", 12, C.text, Enum.Font.GothamMedium)
                vt.Position = UDim2.fromOffset(8, 0)
                vt.Size = UDim2.new(1, -30, 1, 0)
                local chev = icon(vb, "chev", C.sub)
                chev.holder.AnchorPoint = Vector2.new(1, 0.5)
                chev.holder.Position = UDim2.new(1, -4, 0.5, 0)
                local function show() vt.Text = tostring(cur or "-") end
                show()
                local list
                local function closeList()
                    if list then
                        local l2 = list
                        list = nil
                        tw(chev.holder, QUICK, {Rotation = 0})
                        tw(vst, QUICK, {Color = C.line})
                        tw(l2, QUICK, {Size = UDim2.new(1, -24, 0, 0)}).Completed:Connect(function() l2:Destroy() end)
                    end
                end
                local function openList()
                    if list then
                        list:Destroy()
                        list = nil
                    end
                    local h = math.min(#values, 6) * 26 + 6
                    list = Instance.new("ScrollingFrame")
                    list.Name = "ZList"
                    list.LayoutOrder = f.LayoutOrder + 1
                    list.Size = UDim2.new(1, -24, 0, 0)
                    list.BackgroundColor3 = C.bg
                    list.BackgroundTransparency = 0.05
                    list.BorderSizePixel = 0
                    list.ScrollBarThickness = 2
                    list.ScrollBarImageColor3 = C.accent
                    list.CanvasSize = UDim2.new(0, 0, 0, #values * 26 + 6)
                    list.Parent = f.Parent
                    corner(list, 4)
                    stroke(list, C.line, 1)
                    local lp2 = Instance.new("UIPadding")
                    lp2.PaddingTop, lp2.PaddingLeft, lp2.PaddingRight = UDim.new(0, 3), UDim.new(0, 3), UDim.new(0, 3)
                    lp2.Parent = list
                    local ll = Instance.new("UIListLayout")
                    ll.Padding = UDim.new(0, 1)
                    ll.Parent = list
                    for _, v in ipairs(values) do
                        local sel = v == cur
                        local ob = Instance.new("TextButton")
                        ob.Size = UDim2.new(1, -2, 0, 25)
                        ob.BackgroundColor3 = sel and C.accentDim or C.row
                        ob.BackgroundTransparency = sel and 0 or 1
                        ob.Text = "  " .. tostring(v)
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.TextColor3 = sel and C.white or C.sub
                        ob.Font = Enum.Font.GothamMedium
                        ob.TextSize = 12
                        ob.AutoButtonColor = false
                        ob.Parent = list
                        corner(ob, 3)
                        if not sel then
                            ob.MouseEnter:Connect(function() tw(ob, QUICK, {BackgroundTransparency = 0.3, TextColor3 = C.text}) end)
                            ob.MouseLeave:Connect(function() tw(ob, QUICK, {BackgroundTransparency = 1, TextColor3 = C.sub}) end)
                        end
                        ob.Activated:Connect(function()
                            cur = v
                            show()
                            closeList()
                            if dop.Callback then task.spawn(dop.Callback, v) end
                        end)
                    end
                    tw(chev.holder, QUICK, {Rotation = 180})
                    tw(vst, QUICK, {Color = C.accent})
                    tw(list, SOFT, {Size = UDim2.new(1, -24, 0, h)})
                end
                vb.Activated:Connect(function()
                    if list then closeList() else openList() end
                end)
                local obj = {}
                function obj:Refresh(vals)
                    values = vals or {}
                    if list then openList() end
                end
                function obj:Select(v)
                    cur = v
                    show()
                end
                obj.Set = obj.Select
                return obj
            end

            function T:ColorPicker(co)
                local extras = co.Extras or {}
                local value = co.Value
                local f, g = row(34, co.Title)
                local l = text(f, tostring(co.Title or ""), 13, C.text)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -90, 1, 0)
                local sw = Instance.new("TextButton")
                sw.AnchorPoint = Vector2.new(1, 0.5)
                sw.Position = UDim2.new(1, -12, 0.5, 0)
                sw.Size = UDim2.fromOffset(46, 20)
                sw.Text = ""
                sw.AutoButtonColor = false
                sw.Parent = f
                corner(sw, 4)
                stroke(sw, C.line, 1)
                local swT = text(sw, "", 10, C.white, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
                swT.Size = UDim2.fromScale(1, 1)
                swT.TextStrokeTransparency = 0.3
                local h, s, v = 0, 0, 1
                local function parse(val)
                    if type(val) == "string" and val:sub(1, 1) == "#" then
                        local ok, c = pcall(Color3.fromHex, val)
                        if ok then h, s, v = c:ToHSV() end
                    end
                end
                parse(value)
                local function showSwatch()
                    if value == "Rainbow" then
                        sw.BackgroundColor3 = Color3.fromHSV((tick() * 0.25) % 1, 0.85, 1)
                        swT.Text = "RGB"
                    elseif value == "Role" then
                        sw.BackgroundColor3 = C.row
                        swT.Text = "ROLE"
                    elseif type(value) == "string" and value:sub(1, 1) ~= "#" then
                        sw.BackgroundColor3 = Color3.fromHSV(h, s, v)
                        swT.Text = ""
                    else
                        sw.BackgroundColor3 = Color3.fromHSV(h, s, v)
                        swT.Text = ""
                    end
                end
                showSwatch()
                local function commit(nv)
                    value = nv
                    showSwatch()
                    if co.Callback then task.spawn(co.Callback, nv) end
                end
                local panel, pconns
                local function closePanel()
                    if pconns then for _, c in ipairs(pconns) do pcall(function() c:Disconnect() end) end end
                    pconns = nil
                    if panel then panel:Destroy() end
                    panel = nil
                    page.ScrollingEnabled = true
                end
                local inset = game:GetService("GuiService"):GetGuiInset()
                local function openPanel()
                    closePanel()
                    pconns = {}
                    panel = frame(f.Parent, C.bg, 0.05)
                    panel.Name = "ZList"
                    panel.LayoutOrder = f.LayoutOrder + 1
                    panel.Size = UDim2.new(1, -24, 0, 168)
                    corner(panel, 4)
                    stroke(panel, C.line, 1)
                    local svBox = frame(panel, Color3.fromHSV(h, 1, 1))
                    svBox.Position = UDim2.fromOffset(8, 8)
                    svBox.Size = UDim2.new(1, -42, 0, 120)
                    corner(svBox, 3)
                    local wl = frame(svBox, Color3.new(1, 1, 1))
                    wl.Size = UDim2.fromScale(1, 1)
                    corner(wl, 3)
                    local wg = Instance.new("UIGradient")
                    wg.Transparency = NumberSequence.new(0, 1)
                    wg.Parent = wl
                    local bl = frame(svBox, Color3.new(0, 0, 0))
                    bl.Size = UDim2.fromScale(1, 1)
                    corner(bl, 3)
                    local bg2 = Instance.new("UIGradient")
                    bg2.Transparency = NumberSequence.new(1, 0)
                    bg2.Rotation = 90
                    bg2.Parent = bl
                    local dot = frame(svBox, Color3.new(1, 1, 1))
                    dot.Size = UDim2.fromOffset(9, 9)
                    dot.AnchorPoint = Vector2.new(0.5, 0.5)
                    dot.ZIndex = 4
                    corner(dot, 5)
                    stroke(dot, Color3.new(0, 0, 0), 1)
                    local hb = frame(panel, Color3.new(1, 1, 1))
                    hb.AnchorPoint = Vector2.new(1, 0)
                    hb.Position = UDim2.new(1, -8, 0, 8)
                    hb.Size = UDim2.fromOffset(18, 120)
                    corner(hb, 3)
                    local hg = Instance.new("UIGradient")
                    hg.Rotation = 90
                    local kp = {}
                    for i = 0, 6 do kp[#kp + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)) end
                    hg.Color = ColorSequence.new(kp)
                    hg.Parent = hb
                    local hl = frame(hb, Color3.new(1, 1, 1))
                    hl.AnchorPoint = Vector2.new(0.5, 0.5)
                    hl.Size = UDim2.new(1, 4, 0, 3)
                    hl.ZIndex = 4
                    stroke(hl, Color3.new(0, 0, 0), 1)
                    local hex = Instance.new("TextBox")
                    hex.Position = UDim2.fromOffset(8, 136)
                    hex.Size = UDim2.fromOffset(92, 24)
                    hex.BackgroundColor3 = C.row
                    hex.TextColor3 = C.text
                    hex.Font = Enum.Font.GothamMedium
                    hex.TextSize = 12
                    hex.ClearTextOnFocus = false
                    hex.Parent = panel
                    corner(hex, 4)
                    stroke(hex, C.line, 1)
                    local bx = 108
                    for _, ex in ipairs(extras) do
                        local eb = Instance.new("TextButton")
                        eb.Position = UDim2.fromOffset(bx, 136)
                        eb.Size = UDim2.fromOffset(62, 24)
                        eb.BackgroundColor3 = (value == ex) and C.accentDim or C.row
                        eb.TextColor3 = C.text
                        eb.Font = Enum.Font.GothamBold
                        eb.TextSize = 10
                        eb.Text = string.upper(ex)
                        eb.AutoButtonColor = false
                        eb.Parent = panel
                        corner(eb, 4)
                        stroke(eb, C.line, 1)
                        eb.Activated:Connect(function()
                            commit(ex)
                            closePanel()
                        end)
                        bx += 68
                    end
                    local function render()
                        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        dot.Position = UDim2.fromScale(s, 1 - v)
                        hl.Position = UDim2.new(0.5, 0, h, 0)
                        hex.Text = "#" .. string.upper(Color3.fromHSV(h, s, v):ToHex())
                    end
                    render()
                    local dragSV, dragH = false, false
                    local function upd(i)
                        local y = i.Position.Y + inset.Y
                        if dragSV then
                            local ap, as = svBox.AbsolutePosition, svBox.AbsoluteSize
                            s = math.clamp((i.Position.X - ap.X) / math.max(as.X, 1), 0, 1)
                            v = 1 - math.clamp((y - ap.Y) / math.max(as.Y, 1), 0, 1)
                        elseif dragH then
                            local ap, as = hb.AbsolutePosition, hb.AbsoluteSize
                            h = math.clamp((y - ap.Y) / math.max(as.Y, 1), 0, 0.999)
                        else
                            return
                        end
                        render()
                        commit("#" .. Color3.fromHSV(h, s, v):ToHex())
                    end
                    local function grab(target, which)
                        local b = Instance.new("TextButton")
                        b.BackgroundTransparency = 1
                        b.Text = ""
                        b.Size = UDim2.fromScale(1, 1)
                        b.ZIndex = 5
                        b.Parent = target
                        b.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                                dragSV, dragH = which == "sv", which == "h"
                                page.ScrollingEnabled = false
                                upd(i)
                            end
                        end)
                    end
                    grab(svBox, "sv")
                    grab(hb, "h")
                    pconns[#pconns + 1] = UIS.InputChanged:Connect(function(i)
                        if (dragSV or dragH) and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                            upd(i)
                        end
                    end)
                    pconns[#pconns + 1] = UIS.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                            dragSV, dragH = false, false
                            page.ScrollingEnabled = true
                        end
                    end)
                    hex.FocusLost:Connect(function()
                        local t = tostring(hex.Text):gsub("#", ""):gsub("%s", "")
                        local ok, c = pcall(Color3.fromHex, t)
                        if ok and c then
                            h, s, v = c:ToHSV()
                            render()
                            commit("#" .. c:ToHex())
                        else
                            render()
                        end
                    end)
                end
                sw.Activated:Connect(function()
                    if panel then closePanel() else openPanel() end
                end)
                if value == "Rainbow" then
                    task.spawn(function()
                        while sw.Parent do
                            if value == "Rainbow" then showSwatch() end
                            task.wait(0.1)
                        end
                    end)
                end
                local obj = {}
                function obj:Set(nv)
                    value = nv
                    parse(nv)
                    showSwatch()
                end
                return obj
            end

            function T:PlayerGrid(po)
                local f = row(10, po.Title or "players")
                f.Size = UDim2.new(1, 0, 0, 0)
                f.AutomaticSize = Enum.AutomaticSize.Y
                local holder = Instance.new("Frame")
                holder.BackgroundTransparency = 1
                holder.Position = UDim2.fromOffset(8, 4)
                holder.Size = UDim2.new(1, -16, 0, 0)
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Parent = f
                local gl = Instance.new("UIGridLayout")
                gl.CellSize = UDim2.fromOffset(58, 74)
                gl.CellPadding = UDim2.fromOffset(6, 6)
                gl.SortOrder = Enum.SortOrder.Name
                gl.Parent = holder
                local fp = Instance.new("UIPadding")
                fp.PaddingBottom = UDim.new(0, 10)
                fp.Parent = f
                local sel = po.Selected or {}
                local obj = {}
                function obj:Refresh()
                    for _, ch in ipairs(holder:GetChildren()) do
                        if ch:IsA("GuiObject") then ch:Destroy() end
                    end
                    for _, p in ipairs(po.GetPlayers()) do
                        local cell = Instance.new("TextButton")
                        cell.Name = p.Name
                        cell.Text = ""
                        cell.AutoButtonColor = false
                        cell.BackgroundColor3 = C.row
                        cell.BackgroundTransparency = 0.2
                        cell.Parent = holder
                        corner(cell, 6)
                        local on = sel[p.Name] == true
                        local st = stroke(cell, on and C.accent or C.line, on and 2 or 1)
                        local img = Instance.new("ImageLabel")
                        img.BackgroundTransparency = 1
                        img.Size = UDim2.fromOffset(44, 44)
                        img.Position = UDim2.new(0.5, -22, 0, 5)
                        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=48&h=48"
                        img.Parent = cell
                        corner(img, 22)
                        local nm = text(cell, p.DisplayName, 10, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
                        nm.Position = UDim2.new(0, 2, 0, 52)
                        nm.Size = UDim2.new(1, -4, 0, 16)
                        cell.Activated:Connect(function()
                            if po.OnClick then
                                st.Color, st.Thickness = C.accent, 2
                                task.delay(0.35, function()
                                    if st.Parent then st.Color, st.Thickness = C.line, 1 end
                                end)
                                task.spawn(po.OnClick, p)
                                return
                            end
                            sel[p.Name] = (not sel[p.Name]) or nil
                            local now = sel[p.Name] == true
                            st.Color = now and C.accent or C.line
                            st.Thickness = now and 2 or 1
                        end)
                    end
                end
                obj:Refresh()
                return obj
            end

            function T:ImageGrid(io2)
                local f = row(10, io2.Title or "maps")
                f.Size = UDim2.new(1, 0, 0, 0)
                f.AutomaticSize = Enum.AutomaticSize.Y
                local holder = Instance.new("Frame")
                holder.BackgroundTransparency = 1
                holder.Position = UDim2.fromOffset(8, 4)
                holder.Size = UDim2.new(1, -16, 0, 0)
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Parent = f
                local gl = Instance.new("UIGridLayout")
                gl.CellSize = UDim2.fromOffset(96, 78)
                gl.CellPadding = UDim2.fromOffset(6, 6)
                gl.SortOrder = Enum.SortOrder.LayoutOrder
                gl.Parent = holder
                local fp = Instance.new("UIPadding")
                fp.PaddingBottom = UDim.new(0, 10)
                fp.Parent = f
                local empty = text(f, io2.Empty or "", 11, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                empty.Position = UDim2.fromOffset(0, 4)
                empty.Size = UDim2.new(1, 0, 0, 22)
                local obj = {}
                function obj:Refresh()
                    for _, ch in ipairs(holder:GetChildren()) do
                        if ch:IsA("GuiObject") then ch:Destroy() end
                    end
                    local items = io2.GetItems() or {}
                    empty.Visible = #items == 0
                    for i, it in ipairs(items) do
                        local cell = Instance.new("TextButton")
                        cell.Text = ""
                        cell.LayoutOrder = i
                        cell.AutoButtonColor = false
                        cell.BackgroundColor3 = C.row
                        cell.BackgroundTransparency = 0.2
                        cell.ClipsDescendants = true
                        cell.Parent = holder
                        corner(cell, 6)
                        local st = stroke(cell, it.selected and C.accent or C.line, it.selected and 2 or 1)
                        if it.colors then
                            local pv = Instance.new("Frame")
                            pv.BorderSizePixel = 0
                            pv.BackgroundColor3 = Color3.new(1, 1, 1)
                            pv.Size = UDim2.new(1, 0, 0, 58)
                            pv.ClipsDescendants = true
                            pv.Parent = cell
                            local g = Instance.new("UIGradient")
                            g.Rotation = 90
                            g.Color = ColorSequence.new(it.colors[1], it.colors[2])
                            g.Parent = pv
                            if it.viewport then
                                local vpf = Instance.new("ViewportFrame")
                                vpf.BackgroundTransparency = 1
                                vpf.Size = UDim2.fromScale(1, 1)
                                vpf.Parent = pv
                                pcall(it.viewport, vpf)
                            end
                        else
                            local img = Instance.new("ImageLabel")
                            img.BackgroundTransparency = 1
                            img.Size = UDim2.new(1, 0, 0, 58)
                            img.ScaleType = Enum.ScaleType.Crop
                            img.Image = it.image or ""
                            img.Parent = cell
                        end
                        local nm = text(cell, tostring(it.label or ""), 10, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
                        nm.Position = UDim2.new(0, 2, 0, 60)
                        nm.Size = UDim2.new(1, -4, 0, 16)
                        cell.Activated:Connect(function()
                            st.Color, st.Thickness = C.accent, 2
                            task.delay(0.4, function()
                                if st.Parent then st.Color, st.Thickness = it.selected and C.accent or C.line, it.selected and 2 or 1 end
                            end)
                            if io2.OnClick then task.spawn(io2.OnClick, it) end
                        end)
                    end
                end
                obj:Refresh()
                return obj
            end

            function T:Keybind(ko)
                local f = row(32, ko.Title)
                local l = text(f, tostring(ko.Title or "Keybind"), 12, C.sub)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -112, 1, 0)
                local b = Instance.new("TextButton")
                b.AnchorPoint = Vector2.new(1, 0.5)
                b.Position = UDim2.new(1, -12, 0.5, 0)
                b.Size = UDim2.fromOffset(88, 22)
                b.BackgroundColor3 = C.row
                b.TextColor3 = C.text
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 11
                b.AutoButtonColor = false
                b.Parent = f
                corner(b, 7)
                local st = stroke(b, C.line, 1)
                local key = ko.Value
                local function show()
                    b.Text = key and key or "None"
                    b.TextColor3 = key and C.text or C.sub
                end
                show()
                local listening, conn = false, nil
                b.Activated:Connect(function()
                    if listening then return end
                    listening = true
                    FX.bindListening = true
                    b.Text = "press a key..."
                    st.Color = C.accent
                    conn = UIS.InputBegan:Connect(function(i)
                        if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        local name = i.KeyCode.Name
                        if name == "Backspace" or name == "Escape" or name == "Delete" then
                            key = nil
                        else
                            key = name
                        end
                        conn:Disconnect()
                        st.Color = C.line
                        show()
                        if ko.Callback then task.spawn(ko.Callback, key) end
                        task.delay(0.15, function()
                            listening = false
                            FX.bindListening = false
                        end)
                    end)
                end)
                return {}
            end

            function T:Label(lo)
                local f = row(28, lo.Title)
                local l = text(f, tostring(lo.Title or ""), 12, C.sub, Enum.Font.GothamMedium)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -24, 1, 0)
                local obj = {}
                function obj:Set(t)
                    if l.Parent then l.Text = tostring(t) end
                end
                return obj
            end

            function T:Chat(co)
                local f = row(300, "chat")
                local note = text(f, co.Note or "", 10, C.sub, Enum.Font.Gotham)
                note.Position = UDim2.fromOffset(12, 2)
                note.Size = UDim2.new(1, -24, 0, 16)
                local box = Instance.new("ScrollingFrame")
                box.Position = UDim2.fromOffset(10, 20)
                box.Size = UDim2.new(1, -20, 0, 208)
                box.BackgroundColor3 = C.bg
                box.BackgroundTransparency = 0.2
                box.BorderSizePixel = 0
                box.ScrollBarThickness = 3
                box.CanvasSize = UDim2.new()
                box.AutomaticCanvasSize = Enum.AutomaticSize.Y
                box.Parent = f
                corner(box, 6)
                stroke(box, C.line, 1)
                local lay = Instance.new("UIListLayout")
                lay.SortOrder = Enum.SortOrder.LayoutOrder
                lay.Padding = UDim.new(0, 3)
                lay.Parent = box
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
                pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
                pad.Parent = box
                local tb = Instance.new("TextBox")
                tb.Position = UDim2.new(0, 10, 0, 256)
                tb.Size = UDim2.new(1, -96, 0, 32)
                tb.BackgroundColor3 = C.row
                tb.TextColor3 = C.text
                tb.PlaceholderText = co.Placeholder or "Message..."
                tb.PlaceholderColor3 = C.sub
                tb.Font = Enum.Font.Gotham
                tb.TextSize = 12
                tb.Text = ""
                tb.ClearTextOnFocus = false
                tb.TextXAlignment = Enum.TextXAlignment.Left
                tb.Parent = f
                corner(tb, 6)
                stroke(tb, C.line, 1)
                local tp = Instance.new("UIPadding")
                tp.PaddingLeft = UDim.new(0, 8)
                tp.Parent = tb
                local send = Instance.new("TextButton")
                send.AnchorPoint = Vector2.new(1, 0)
                send.Position = UDim2.new(1, -10, 0, 256)
                send.Size = UDim2.fromOffset(78, 32)
                send.BackgroundColor3 = C.accentDim
                send.TextColor3 = C.text
                send.Font = Enum.Font.GothamBold
                send.TextSize = 11
                send.Text = co.SendText or "SEND"
                send.AutoButtonColor = false
                send.Parent = f
                corner(send, 6)
                local count = 0
                local function esc(t)
                    return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
                end
                local obj = {}
                local FRAMES = {Gold = Color3.fromRGB(255, 200, 60), Neon = Color3.fromRGB(80, 255, 200), Ruby = Color3.fromRGB(255, 70, 110),
                    Ice = Color3.fromRGB(140, 200, 255), Violet = Color3.fromRGB(170, 110, 255)}
                local replyBar = text(f, "", 10, C.sub, Enum.Font.Gotham)
                replyBar.Position = UDim2.fromOffset(12, 232)
                replyBar.Size = UDim2.new(1, -24, 0, 18)
                replyBar.Visible = false
                FX.chatReplyShow = function(e)
                    if not replyBar.Parent then return end
                    if e then
                        replyBar.Text = "replying to " .. e.n .. ": " .. string.sub(e.t, 1, 40) .. "   (tap to cancel)"
                        replyBar.Visible = true
                    else
                        replyBar.Visible = false
                    end
                end
                local cancel = Instance.new("TextButton")
                cancel.BackgroundTransparency = 1
                cancel.Text = ""
                cancel.Size = UDim2.fromScale(1, 1)
                cancel.Parent = replyBar
                cancel.Activated:Connect(function()
                    FX.chatReply = nil
                    FX.chatReplyShow(nil)
                end)
                local obj = {}
                function obj:Add(e)
                    if not box.Parent then return end
                    count += 1
                    local fc = FRAMES[e.f]
                    local row0 = Instance.new("TextButton")
                    row0.AutoButtonColor = false
                    row0.Text = ""
                    row0.BackgroundColor3 = C.row
                    row0.BackgroundTransparency = 0.6
                    row0.Size = UDim2.new(1, 0, 0, 0)
                    row0.AutomaticSize = Enum.AutomaticSize.Y
                    row0.LayoutOrder = count
                    row0.Parent = box
                    corner(row0, 8)
                    local rp = Instance.new("UIPadding")
                    rp.PaddingLeft, rp.PaddingRight = UDim.new(0, 40), UDim.new(0, 6)
                    rp.PaddingTop, rp.PaddingBottom = UDim.new(0, 4), UDim.new(0, 5)
                    rp.Parent = row0
                    local av = Instance.new("ImageLabel")
                    av.BackgroundColor3 = C.bg
                    av.Position = UDim2.new(0, -34, 0, 0)
                    av.Size = UDim2.fromOffset(28, 28)
                    av.Image = e.id and ("rbxthumb://type=AvatarHeadShot&id=" .. e.id .. "&w=150&h=150") or ""
                    av.Parent = row0
                    corner(av, 14)
                    if fc then stroke(av, fc, 2) end
                    local col = Instance.new("Frame")
                    col.BackgroundTransparency = 1
                    col.Size = UDim2.new(1, 0, 0, 0)
                    col.AutomaticSize = Enum.AutomaticSize.Y
                    col.Parent = row0
                    local cl = Instance.new("UIListLayout")
                    cl.SortOrder = Enum.SortOrder.LayoutOrder
                    cl.Padding = UDim.new(0, 1)
                    cl.Parent = col
                    local function line(txt, size, color, font, order)
                        local l = Instance.new("TextLabel")
                        l.BackgroundTransparency = 1
                        l.Size = UDim2.new(1, 0, 0, 0)
                        l.AutomaticSize = Enum.AutomaticSize.Y
                        l.RichText = true
                        l.TextWrapped = true
                        l.TextXAlignment = Enum.TextXAlignment.Left
                        l.Font = font
                        l.TextSize = size
                        l.TextColor3 = color
                        l.Text = txt
                        l.LayoutOrder = order
                        l.Parent = col
                        return l
                    end
                    local nameHex = (fc or C.accent):ToHex()
                    line(string.format('<b><font color="#%s">%s</font></b> <font color="#%s">@%s</font>', nameHex, esc(e.n), C.sub:ToHex(), esc(e.u)), 12, C.text, Enum.Font.Gotham, 1)
                    if e.r and e.r.n ~= "" then
                        line(string.format('<i>%s: %s</i>', esc(e.r.n), esc(e.r.t)), 10, C.sub, Enum.Font.Gotham, 2)
                    end
                    line(esc(e.t), 12, C.text, Enum.Font.Gotham, 3)
                    row0.Activated:Connect(function()
                        FX.chatReply = {n = e.n, t = e.t}
                        FX.chatReplyShow(e)
                        tb:CaptureFocus()
                    end)
                    local kids = {}
                    for _, k in ipairs(box:GetChildren()) do
                        if k:IsA("TextButton") then kids[#kids + 1] = k end
                    end
                    if #kids > 80 then kids[1]:Destroy() end
                    task.defer(function()
                        if box.Parent then box.CanvasPosition = Vector2.new(0, math.max(0, box.AbsoluteCanvasSize.Y - box.AbsoluteSize.Y)) end
                    end)
                end
                local function fire()
                    local t = tb.Text
                    tb.Text = ""
                    if co.OnSend then task.spawn(co.OnSend, t) end
                end
                send.Activated:Connect(fire)
                tb.FocusLost:Connect(function(enter)
                    if enter then fire() end
                end)
                return obj
            end

            function T:Input(io)
                local f = row(34, io.Title)
                local l = text(f, tostring(io.Title or ""), 13, C.text)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(0.45, -12, 1, 0)
                local box = Instance.new("TextBox")
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -12, 0.5, 0)
                box.Size = UDim2.new(0.55, -12, 0, 24)
                box.BackgroundColor3 = C.row
                box.TextColor3 = C.text
                box.PlaceholderColor3 = C.dim
                box.PlaceholderText = tostring(io.Placeholder or "")
                box.Text = tostring(io.Value or "")
                box.Font = Enum.Font.GothamMedium
                box.TextSize = 12
                box.ClearTextOnFocus = false
                box.Parent = f
                corner(box, 4)
                local bs = stroke(box, C.line, 1)
                box.Focused:Connect(function() tw(bs, QUICK, {Color = C.accent}) end)
                box.FocusLost:Connect(function()
                    tw(bs, QUICK, {Color = C.line})
                    if io.Callback then task.spawn(io.Callback, box.Text) end
                end)
                return {}
            end

            function T:Preview(po)
                local f = row(280, po.Title or "preview")
                local box = frame(f, C.bg, 0.15)
                box.Position = UDim2.fromOffset(10, 8)
                box.Size = UDim2.new(1, -20, 1, -14)
                box.ClipsDescendants = true
                corner(box, 5)
                stroke(box, C.line, 1)
                local vp = Instance.new("ViewportFrame")
                vp.BackgroundTransparency = 1
                vp.Size = UDim2.fromScale(1, 1)
                vp.Ambient = Color3.fromRGB(170, 170, 180)
                vp.LightColor = Color3.fromRGB(255, 255, 255)
                vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
                vp.Parent = box
                local vcam = Instance.new("Camera")
                vcam.FieldOfView = 40
                vcam.Parent = vp
                vp.CurrentCamera = vcam
                local wmod = Instance.new("WorldModel")
                wmod.Parent = vp
                local anim = {idle = nil, walk = nil, now = nil}
                local ov = Instance.new("Frame")
                ov.BackgroundTransparency = 1
                ov.Size = UDim2.fromScale(1, 1)
                ov.ZIndex = 3
                ov.Parent = box
                local function ln()
                    local l = frame(ov, C.white)
                    l.AnchorPoint = Vector2.new(0.5, 0.5)
                    l.ZIndex = 4
                    l.Visible = false
                    return l
                end
                local function seg(l, a, b2, col, th)
                    local d = b2 - a
                    l.Size = UDim2.fromOffset(d.Magnitude + 1, th or 1.5)
                    l.Position = UDim2.fromOffset((a.X + b2.X) / 2, (a.Y + b2.Y) / 2)
                    l.Rotation = math.deg(math.atan2(d.Y, d.X))
                    l.BackgroundColor3 = col
                    l.Visible = true
                end
                local boxL, skelL = {}, {}
                for i = 1, 4 do boxL[i] = ln() end
                for i = 1, 13 do skelL[i] = ln() end
                local nameT = text(ov, "", 14, C.white, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
                nameT.Size = UDim2.fromOffset(200, 16)
                nameT.AnchorPoint = Vector2.new(0.5, 1)
                nameT.TextStrokeTransparency = 0.1
                nameT.ZIndex = 5
                local distT = text(ov, "24m", 13, C.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
                distT.Size = UDim2.fromOffset(120, 14)
                distT.AnchorPoint = Vector2.new(0.5, 0)
                distT.TextStrokeTransparency = 0.2
                distT.ZIndex = 5
                local hpBack = frame(ov, rgb(0, 0, 0))
                hpBack.ZIndex = 4
                local hpFill = frame(hpBack, rgb(80, 220, 110))
                hpFill.AnchorPoint = Vector2.new(0, 1)
                hpFill.Position = UDim2.fromScale(0, 1)
                hpFill.Size = UDim2.fromScale(1, 0.8)
                hpFill.ZIndex = 5
                local av = Instance.new("ImageLabel")
                av.Size = UDim2.fromOffset(28, 28)
                av.AnchorPoint = Vector2.new(0.5, 1)
                av.BackgroundColor3 = C.row
                av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=48&h=48"
                av.ZIndex = 5
                av.Parent = ov
                corner(av, 14)
                local avS = stroke(av, C.accent, 1.5)

                local model, charRef, weapon, weaponKind = nil, false, nil, nil
                local orig, worig = {}, {}
                local yaw = 0
                local rot, lastX = false, 0
                box.Active = true
                box.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        rot, lastX = true, i.Position.X
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputChanged:Connect(function(i)
                    if rot and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        local dx = i.Position.X - lastX
                        lastX = i.Position.X
                        yaw += dx * 0.015
                        if model then pcall(function() model:PivotTo(CFrame.Angles(0, yaw, 0)) end) end
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        rot = false
                    end
                end)

                local function findWeaponSource(kind)
                    local c = lp.Character
                    local src = (c and c:FindFirstChild(kind)) or lp.Backpack:FindFirstChild(kind)
                    if src and src:IsA("Tool") then return src end
                    for _, p in ipairs(Players:GetPlayers()) do
                        local t = p.Character and p.Character:FindFirstChild(kind)
                        if t and t:IsA("Tool") then return t end
                    end
                    return nil
                end

                local function buildWeapon(kind)
                    if weapon then pcall(function() weapon:Destroy() end) end
                    weapon = nil
                    table.clear(worig)
                    weaponKind = kind
                    if not kind or not model then return end
                    local hand = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
                    if not hand then return end
                    local w = Instance.new("Model")
                    w.Name = "PreviewWeapon"
                    local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
                    local src = findWeaponSource(kind)
                    local handle = src and src:FindFirstChild("Handle")
                    local placed = false
                    if handle and handle:IsA("BasePart") then
                        for _, d in ipairs(src:GetDescendants()) do
                            if d:IsA("BasePart") and d.Transparency < 1 then
                                local okc, cl = pcall(function() return d:Clone() end)
                                if okc and cl then
                                    for _, ch in ipairs(cl:GetChildren()) do
                                        if not (ch:IsA("DataModelMesh") or ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance")) then
                                            ch:Destroy()
                                        end
                                    end
                                    cl.Anchored = true
                                    cl.CFrame = grip * handle.CFrame:ToObjectSpace(d.CFrame)
                                    cl.Parent = w
                                    placed = true
                                end
                            end
                        end
                    end
                    if not placed then
                        local function pp(size, color, cf, mat)
                            local p = Instance.new("Part")
                            p.Anchored = true
                            p.Size, p.Color = size, color
                            p.Material = mat or Enum.Material.Metal
                            p.CFrame = grip * cf
                            p.Parent = w
                        end
                        if kind == "Knife" then
                            pp(Vector3.new(0.25, 0.25, 0.9), Color3.fromRGB(45, 32, 26), CFrame.new(), Enum.Material.Wood)
                            pp(Vector3.new(0.5, 0.12, 0.12), Color3.fromRGB(120, 120, 128), CFrame.new(0, 0, -0.5))
                            pp(Vector3.new(0.08, 0.36, 1.9), Color3.fromRGB(205, 210, 218), CFrame.new(0, 0.04, -1.5))
                        else
                            pp(Vector3.new(0.3, 0.8, 0.35), Color3.fromRGB(45, 45, 50), CFrame.new(0, -0.1, 0.1) * CFrame.Angles(math.rad(-15), 0, 0))
                            pp(Vector3.new(0.3, 0.38, 1.5), Color3.fromRGB(70, 72, 78), CFrame.new(0, 0.36, -0.55))
                            pp(Vector3.new(0.18, 0.18, 0.7), Color3.fromRGB(30, 30, 34), CFrame.new(0, 0.42, -1.55))
                        end
                    end
                    for _, d in ipairs(w:GetDescendants()) do
                        if d:IsA("BasePart") then worig[d] = {d.Color, d.Material} end
                    end
                    w.Parent = vp
                    weapon = w
                end

                local function buildModel()
                    if model then pcall(function() model:Destroy() end) end
                    model = nil
                    table.clear(orig)
                    local ch = lp.Character
                    charRef = ch
                    if not ch then return end
                    local okc, cl = pcall(function()
                        local old = ch.Archivable
                        ch.Archivable = true
                        local x = ch:Clone()
                        ch.Archivable = old
                        return x
                    end)
                    if not okc or not cl then return end
                    for _, d in ipairs(cl:GetChildren()) do
                        if d.Name:sub(1, 6) == "Zenith" or d:IsA("Tool") then d:Destroy() end
                    end
                    for _, d in ipairs(cl:GetDescendants()) do
                        if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui")
                           or d:IsA("Highlight") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("ForceField") then
                            d:Destroy()
                        elseif d:IsA("Humanoid") then
                            d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        elseif d:IsA("BasePart") then
                            -- only the root is pinned; the limbs hang on their joints so animations move them
                            d.Anchored = d.Name == "HumanoidRootPart"
                            d.CanCollide = false
                            d.LocalTransparencyModifier = 0
                            if d.Name == "HumanoidRootPart" then d.Transparency = 1 end
                            orig[d] = {d.Color, d.Material, d.Transparency}
                        end
                    end
                    pcall(function() cl:PivotTo(CFrame.new()) end)
                    cl.Parent = wmod
                    model = cl
                    -- idle / walk like your character (R15 or R6 default animations)
                    anim.idle, anim.walk, anim.now = nil, nil, nil
                    pcall(function()
                        local hum = cl:FindFirstChildOfClass("Humanoid")
                        if not hum then return end
                        local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
                        local r15 = hum.RigType == Enum.HumanoidRigType.R15
                        local function track(id)
                            local a = Instance.new("Animation")
                            a.AnimationId = "rbxassetid://" .. id
                            local tr = an:LoadAnimation(a)
                            tr.Looped = true
                            return tr
                        end
                        anim.idle = track(r15 and 507766388 or 180435571)
                        anim.walk = track(r15 and 507777826 or 180426354)
                    end)
                    local okb, cf, size = pcall(function() return cl:GetBoundingBox() end)
                    if okb then
                        local dist = (size.Y / 2) / math.tan(math.rad(vcam.FieldOfView / 2)) * 1.6
                        local lift = Vector3.new(0, size.Y * 0.15, 0)
                        vcam.CFrame = CFrame.lookAt(cf.Position + lift + Vector3.new(0, 0, -dist), cf.Position + lift)
                    end
                    if yaw ~= 0 then pcall(function() cl:PivotTo(CFrame.Angles(0, yaw, 0)) end) end
                end

                local function paint(p, o, on, ty, cc)
                    if on and ty == "ForceField" then
                        p.Material, p.Color = Enum.Material.ForceField, cc
                    elseif on and ty == "Neon" then
                        p.Material, p.Color = Enum.Material.Neon, cc
                    elseif on and ty ~= "Outline" then
                        p.Material, p.Color = Enum.Material.SmoothPlastic, o[1]:Lerp(cc, ty == "Chams" and 0.85 or 0.55)
                    else
                        p.Material, p.Color = o[2], o[1]
                    end
                end

                local function apply()
                    local st = po.Get and po.Get() or {}
                    if lp.Character ~= charRef or not (model and model.Parent) then pcall(buildModel) end
                    if st.weapon ~= weaponKind then pcall(buildWeapon, st.weapon) end
                    local col = st.color or C.accent
                    pcall(function()
                        for p, o in pairs(orig) do
                            if p.Parent and o[3] < 1 then paint(p, o, st.chams, st.chamsType, st.chamsColor or col) end
                        end
                        for p, o in pairs(worig) do
                            if p.Parent then paint(p, o, st.weaponEsp, st.weaponStyle, st.weaponColor or col) end
                        end
                    end)
                    -- walk while you walk, idle while you stand
                    pcall(function()
                        local mh = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                        local want = (mh and mh.MoveDirection.Magnitude > 0.1) and anim.walk or anim.idle
                        if want and anim.now ~= want then
                            if anim.now then anim.now:Stop(0.2) end
                            want:Play(0.2)
                            anim.now = want
                        end
                    end)
                    local W2, H = box.AbsoluteSize.X, box.AbsoluteSize.Y
                    local figH = H / 1.6
                    local cx, top = W2 / 2, (H - figH) / 2 + H * (0.15 / 1.6)
                    local bot = top + figH
                    local fw = figH * 0.5
                    if st.box then
                        local x1, x2 = cx - fw / 2, cx + fw / 2
                        local A = {Vector2.new(x1, top), Vector2.new(x2, top), Vector2.new(x2, bot), Vector2.new(x1, bot)}
                        for i = 1, 4 do seg(boxL[i], A[i], A[i % 4 + 1], col, 2) end
                    else
                        for _, l in ipairs(boxL) do l.Visible = false end
                    end
                    if st.skeleton then
                        local function P(x, y) return Vector2.new(cx + (x - 0.5) * fw * 1.25, top + y * figH) end
                        local J = {head = P(0.5, 0.11), neck = P(0.5, 0.21), chest = P(0.5, 0.32), pelvis = P(0.5, 0.52),
                                   ls = P(0.3, 0.25), le = P(0.22, 0.38), lh = P(0.2, 0.5), rs = P(0.7, 0.25), re = P(0.78, 0.38),
                                   rh = P(0.8, 0.5), lk = P(0.4, 0.74), lf = P(0.39, 0.97), rk = P(0.6, 0.74), rf = P(0.61, 0.97)}
                        local S = {{"head", "neck"}, {"neck", "chest"}, {"chest", "pelvis"}, {"neck", "ls"}, {"ls", "le"},
                                   {"le", "lh"}, {"neck", "rs"}, {"rs", "re"}, {"re", "rh"}, {"pelvis", "lk"}, {"lk", "lf"},
                                   {"pelvis", "rk"}, {"rk", "rf"}}
                        for i, sg2 in ipairs(S) do seg(skelL[i], J[sg2[1]], J[sg2[2]], C.white, 2) end
                    else
                        for _, l in ipairs(skelL) do l.Visible = false end
                    end
                    local y = top - 3
                    nameT.Visible = st.name == true
                    if st.name then
                        nameT.Text = lp.DisplayName
                        nameT.TextColor3 = col
                        nameT.Position = UDim2.fromOffset(cx, y)
                        y -= 18
                    end
                    av.Visible = st.avatar == true
                    if st.avatar then
                        av.Position = UDim2.fromOffset(cx, y)
                        avS.Color = col
                    end
                    distT.Visible = st.dist == true
                    if st.dist then distT.Position = UDim2.fromOffset(cx, bot + 3) end
                    hpBack.Visible = st.health == true
                    if st.health then
                        hpBack.Size = UDim2.fromOffset(4, figH)
                        hpBack.Position = UDim2.fromOffset(cx - fw / 2 - 9, top)
                    end
                end

                task.spawn(function()
                    while gui.Parent do
                        if main.Visible and wrap.Visible and box.AbsoluteSize.X > 10 then pcall(apply) end
                        task.wait(0.05)
                    end
                end)
                return {}
            end

            b.Activated:Connect(function()
                selectTab(T)
                if FX.uiClick then FX.uiClick() end
            end)
            W.tabs[#W.tabs + 1] = T
            if #W.tabs == 1 then selectTab(T) end
            return T
        end

        function W:Destroy()
            for _, c in ipairs(W.conns) do pcall(function() c:Disconnect() end) end
            for _, g in ipairs(W.guis) do pcall(function() g:Destroy() end) end
            pcall(function() gui:Destroy() end)
        end
        W.gui, W.main = gui, main
        task.defer(function() W:Open() end)
        return W
    end
end


-- Neverlose menu (your NeverloseUI) under the same calls the menu code already makes
local NLA = {}
do
    local okL, NL = pcall(function()
        return (function()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local UI = {
	Flags = {},
	Configs = {},
	Settings = {
		Language = "English",
		MenuScale = "Auto",
		ESPScale = "100%",
		WindowsScale = "Auto",
		Units = "Auto",
		SafeMode = "Automatic",
		Sync = true,
	},
}

local T = {
	Window    = Color3.fromRGB(19, 20, 23),
	Panel     = Color3.fromRGB(23, 24, 27),
	Group     = Color3.fromRGB(28, 29, 33),
	Popup     = Color3.fromRGB(26, 27, 31),
	Field     = Color3.fromRGB(34, 35, 40),
	FieldHi   = Color3.fromRGB(41, 42, 48),
	Nav       = Color3.fromRGB(37, 38, 43),
	Stroke    = Color3.fromRGB(39, 40, 46),
	Divider   = Color3.fromRGB(36, 37, 42),
	Text      = Color3.fromRGB(232, 232, 236),
	SubText   = Color3.fromRGB(141, 143, 152),
	Caps      = Color3.fromRGB(100, 102, 110),
	Accent    = Color3.fromRGB(84, 112, 240),
	Danger    = Color3.fromRGB(240, 82, 82),
	Success   = Color3.fromRGB(72, 205, 120),
	Warning   = Color3.fromRGB(245, 180, 70),
	SwitchOff = Color3.fromRGB(45, 46, 52),
	KnobOff   = Color3.fromRGB(148, 149, 156),
	Pill      = Color3.fromRGB(22, 23, 26),
	PillLine  = Color3.fromRGB(46, 47, 53),
}
UI.Theme = T

local ACCENT_PRESETS = {
	{ "Blue", Color3.fromRGB(84, 112, 240) },
	{ "Purple", Color3.fromRGB(150, 95, 255) },
	{ "Pink", Color3.fromRGB(240, 90, 170) },
	{ "Red", Color3.fromRGB(240, 82, 82) },
	{ "Orange", Color3.fromRGB(245, 145, 60) },
	{ "Green", Color3.fromRGB(72, 205, 120) },
	{ "Cyan", Color3.fromRGB(50, 200, 230) },
	{ "White", Color3.fromRGB(230, 230, 235) },
}

local FONT = "rbxasset://fonts/families/BuilderSans.json"
local MONO = "rbxasset://fonts/families/RobotoMono.json"
local F = {
	Regular = Font.new(FONT, Enum.FontWeight.Regular),
	Medium  = Font.new(FONT, Enum.FontWeight.Medium),
	Bold    = Font.new(FONT, Enum.FontWeight.Bold),
	Heavy   = Font.new(FONT, Enum.FontWeight.ExtraBold),
	Mono    = Font.new(MONO, Enum.FontWeight.Regular),
	MonoB   = Font.new(MONO, Enum.FontWeight.Bold),
	Logo    = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy),
}

local ICONS = {
	crosshair = { 16898613044, 453, 869 },
	mouse = { 16898613613, 563, 918 },
	image = { 16898613509, 306, 918 },
	layers = { 16898613509, 98, 967 },
	["layout-list"] = { 16898613509, 869, 453 },
	list = { 16898613509, 869, 808 },
	eye = { 16898613353, 771, 563 },
	["eye-off"] = { 16898613353, 820, 514 },
	clock = { 16898613044, 771, 661 },
	user = { 16898613869, 661, 869 },
	users = { 16898613869, 967, 98 },
	folder = { 16898613353, 404, 967 },
	["folder-open"] = { 16898613353, 820, 759 },
	save = { 16898613699, 918, 453 },
	search = { 16898613699, 918, 857 },
	ellipsis = { 16898613353, 771, 49 },
	["chevron-down"] = { 16898612819, 196, 918 },
	["chevron-right"] = { 16898612819, 869, 759 },
	["chevron-left"] = { 16898612819, 404, 967 },
	settings = { 16898613777, 771, 257 },
	["settings-2"] = { 16898613777, 0, 771 },
	keyboard = { 16898613509, 453, 820 },
	sliders = { 16898613777, 820, 355 },
	target = { 16898613869, 514, 771 },
	palette = { 16898613613, 453, 918 },
	sun = { 16898613777, 967, 453 },
	moon = { 16898613613, 306, 918 },
	globe = { 16898613509, 771, 563 },
	monitor = { 16898613613, 404, 820 },
	sparkles = { 16898613777, 918, 49 },
	star = { 16898613777, 967, 147 },
	plus = { 16898613699, 257, 918 },
	minus = { 16898613613, 771, 196 },
	trash = { 16898613869, 257, 918 },
	check = { 16898612819, 710, 869 },
	x = { 16898613869, 869, 906 },
	["rotate-ccw"] = { 16898613699, 967, 355 },
	["refresh-cw"] = { 16898613699, 404, 869 },
	link = { 16898613509, 918, 453 },
	["toggle-left"] = { 16898613869, 869, 49 },
	["toggle-right"] = { 16898613869, 820, 98 },
	info = { 16898613509, 612, 869 },
	bell = { 16898612819, 820, 257 },
	lock = { 16898613509, 918, 857 },
	copy = { 16898613044, 918, 612 },
	download = { 16898613044, 820, 906 },
	upload = { 16898613869, 612, 869 },
	shield = { 16898613777, 869, 0 },
	crown = { 16898613044, 404, 918 },
	hash = { 16898613509, 147, 771 },
	type = { 16898613869, 967, 257 },
	pipette = { 16898613699, 869, 49 },
	move = { 16898613613, 453, 820 },
	zap = { 16898613869, 918, 906 },
	gauge = { 16898613353, 771, 955 },
	ruler = { 16898613777, 869, 710 },
	terminal = { 16898613869, 820, 257 },
	skull = { 16898613777, 49, 869 },
	sword = { 16898613777, 710, 967 },
	focus = { 16898613353, 771, 759 },
	radar = { 16898613699, 820, 404 },
	message = { 16898613044, 355, 869 },
	languages = { 16898613509, 771, 563 },
	scale = { 16898613353, 771, 955 },
	ghost = { 16898613353, 869, 906 },
	flame = { 16898613353, 967, 306 },
}
UI.Icons = ICONS

local function Create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(obj, props, t, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function Corner(r)
	return Create("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end

local function Round()
	return Create("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function Stroke(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or T.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Pad(t, r, b, l)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
	})
end

local function List(padding, direction, hAlign, vAlign)
	return Create("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
	})
end

local function Label(props)
	local base = {
		BackgroundTransparency = 1,
		FontFace = F.Medium,
		TextSize = 14,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return Create("TextLabel", base)
end

local function Icon(name, parent, size, color, props)
	local img = Create("ImageLabel", {
		Size = UDim2.fromOffset(size or 16, size or 16),
		BackgroundTransparency = 1,
		ImageColor3 = color or T.SubText,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
	local d = ICONS[name] or ICONS.star
	img.Image = "rbxassetid://" .. d[1]
	img.ImageRectOffset = Vector2.new(d[2], d[3])
	img.ImageRectSize = Vector2.new(48, 48)
	for k, v in pairs(props or {}) do
		img[k] = v
	end
	return img
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Neverlose] " .. tostring(err))
	end
end

local orderCounter = 0
local function NextOrder()
	orderCounter += 1
	return orderCounter
end

local function KeyName(k)
	if not k then
		return "None"
	end
	local n = k.Name
	local map = {
		MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3",
		LeftShift = "LShift", RightShift = "RShift",
		LeftControl = "LCtrl", RightControl = "RCtrl",
		LeftAlt = "LAlt", RightAlt = "RAlt",
		Insert = "Ins", Delete = "Del", Backspace = "Back",
		CapsLock = "Caps", Return = "Enter", Space = "Space",
		Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
		BackSlash = "\\", LeftBracket = "[", RightBracket = "]", Minus = "-",
		Equals = "=", Backquote = "`", Tilde = "~", PageUp = "PgUp", PageDown = "PgDn",
		KeypadZero = "Num0", KeypadOne = "Num1", KeypadTwo = "Num2", KeypadThree = "Num3",
		KeypadFour = "Num4", KeypadFive = "Num5", KeypadSix = "Num6", KeypadSeven = "Num7",
		KeypadEight = "Num8", KeypadNine = "Num9",
		One = "1", Two = "2", Three = "3", Four = "4", Five = "5",
		Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	}
	return map[n] or n
end

local function Mouse()
	return UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
end

local function Inside(gui, m, pad)
	if not gui or not gui.Visible then
		return false
	end
	pad = pad or 0
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return m.X >= p.X - pad and m.X <= p.X + s.X + pad and m.Y >= p.Y - pad and m.Y <= p.Y + s.Y + pad
end

local function ValueEquals(a, b)
	if type(a) == "table" and type(b) == "table" then
		if #a ~= #b then
			return false
		end
		for i = 1, #a do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	end
	return a == b
end

local function CopyValue(v)
	if type(v) == "table" then
		return table.clone(v)
	end
	return v
end

local function FollowShadow(target, root, radius, layers, strength, z, step)
	step = step or 3
	radius = radius or 12
	layers = layers or 6
	strength = strength or 0.12
	local margin = layers * 3 + 4
	local isGroup = target:IsA("CanvasGroup")
	local holder = Create("Frame", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = z or math.max(target.ZIndex - 1, 0),
		Parent = root,
	})
	local corners = {}
	local frames = {}
	for i = 1, layers do
		local grow = i * step
		local c = Create("UICorner", { CornerRadius = UDim.new(0, radius + grow) })
		table.insert(corners, { Corner = c, Grow = grow })
		local base = 1 - strength * (1 - (i - 1) / layers)
		local f = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, grow * 2 - margin * 2, 1, grow * 2 - margin * 2),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = base,
			Active = false,
			ZIndex = holder.ZIndex,
			Parent = holder,
		}, { c })
		table.insert(frames, { Frame = f, Base = base })
	end
	local function Visible()
		local g = target
		while g and g:IsA("GuiObject") do
			if not g.Visible then
				return false
			end
			g = g.Parent
		end
		return target.Parent ~= nil
	end
	local function Sync()
		if not target.Parent then
			holder:Destroy()
			return
		end
		local p, s = target.AbsolutePosition, target.AbsoluteSize
		local rp = root.AbsolutePosition
		holder.Position = UDim2.fromOffset(p.X - rp.X - margin, p.Y - rp.Y - margin)
		holder.Size = UDim2.fromOffset(s.X + margin * 2, s.Y + margin * 2)
		holder.Visible = Visible()
	end
	target:GetPropertyChangedSignal("AbsolutePosition"):Connect(Sync)
	target:GetPropertyChangedSignal("AbsoluteSize"):Connect(Sync)
	target:GetPropertyChangedSignal("Visible"):Connect(Sync)
	target.AncestryChanged:Connect(Sync)
	if isGroup then
		local function Fade()
			local gt = target.GroupTransparency
			for _, l in ipairs(frames) do
				l.Frame.BackgroundTransparency = l.Base + (1 - l.Base) * gt
			end
		end
		target:GetPropertyChangedSignal("GroupTransparency"):Connect(Fade)
		Fade()
	end
	task.defer(Sync)
	return holder, Sync, corners
end

local AccentHooks = {}
local function OnAccent(fn)
	table.insert(AccentHooks, fn)
	fn(T.Accent)
end

function UI:SetAccent(color)
	T.Accent = color
	for _, fn in ipairs(AccentHooks) do
		SafeCall(fn, color)
	end
end

local MAX_LEVEL = 5

local FadeTokens = setmetatable({}, { __mode = "k" })

local function HideFrame(frame)
	local tok = (FadeTokens[frame] or 0) + 1
	FadeTokens[frame] = tok
	if frame:IsA("CanvasGroup") then
		Tween(frame, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quint).Completed:Connect(function()
			if FadeTokens[frame] == tok then
				frame.Visible = false
			end
		end)
	else
		frame.Visible = false
	end
end

local function CloseFrom(win, level, keep)
	for l = MAX_LEVEL, level, -1 do
		local e = win._layers[l]
		if e then
			win._layers[l] = nil
			win._closedAt[e.Frame] = os.clock()
			if e.Frame ~= keep then
				HideFrame(e.Frame)
			end
			SafeCall(e.OnClose)
		end
	end
end

local function OpenLayer(win, level, frame, onClose)
	CloseFrom(win, level, frame)
	win._layers[level] = { Frame = frame, OnClose = onClose }
	FadeTokens[frame] = (FadeTokens[frame] or 0) + 1
	frame.Visible = true
end

local function IsOpen(win, frame)
	if not frame then
		return false
	end
	for l = 1, MAX_LEVEL do
		local e = win._layers[l]
		if e and e.Frame == frame then
			return true
		end
	end
	return false
end

local function JustClosed(win, frame)
	return os.clock() - (win._closedAt[frame] or 0) < 0.3
end

local function InsideLayers(win, m)
	for l = 1, MAX_LEVEL do
		local e = win._layers[l]
		if e and Inside(e.Frame, m, 2) then
			return true
		end
	end
	return false
end

local function AnimateIn(frame, x, y)
	frame.Position = UDim2.fromOffset(x, y - 8)
	Tween(frame, { Position = UDim2.fromOffset(x, y) }, 0.38, Enum.EasingStyle.Quint)
	if frame:IsA("CanvasGroup") then
		Tween(frame, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quint)
	end
end

local function PlaceNear(win, frame, anchor, width, mode)
	local p, s = anchor.AbsolutePosition, anchor.AbsoluteSize
	local scr = win.Gui.AbsoluteSize
	local x, y
	if mode == "right" then
		x, y = p.X + s.X + 8, p.Y - 6
	elseif mode == "below-left" then
		x, y = p.X, p.Y + s.Y + 6
	else
		x, y = p.X + s.X - width, p.Y + s.Y + 6
	end
	x = math.clamp(x, 6, math.max(scr.X - width - 6, 6))
	frame.Position = UDim2.fromOffset(x, y)
	task.defer(function()
		local h = frame.AbsoluteSize.Y
		if y + h > scr.Y - 8 then
			y = math.max(scr.Y - h - 8, 6)
		end
		AnimateIn(frame, x, y)
	end)
end

local function PopupFrame(win, width, title, zbase)
	zbase = zbase or 100
	local frame = Create("CanvasGroup", {
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = zbase,
		Parent = win.Overlay,
	}, { Pad(1, 1, 1, 1) })
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Popup,
		ZIndex = zbase,
		Parent = frame,
	}, { Corner(12), Stroke(T.Stroke) })
	FollowShadow(frame, win.Overlay, 12, 6, 0.16, zbase - 1)
	local items = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = zbase + 1,
		Parent = card,
	}, { List(0, nil, Enum.HorizontalAlignment.Center), Pad(6, 0, 6, 0) })
	if title then
		local cap = Label({
			Text = title:upper(),
			FontFace = F.Medium,
			TextSize = 11,
			TextColor3 = T.Caps,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = -100,
			ZIndex = zbase + 2,
			Parent = items,
		})
		Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = cap })
	end
	return frame, items
end

local function MenuRow(parent, o)
	local z = o.Z or 102
	local row = Create("TextButton", {
		Size = UDim2.new(1, -12, 0, o.Height or 34),
		BackgroundColor3 = T.Nav,
		BackgroundTransparency = o.Selected and 0 or 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = o.Order or NextOrder(),
		ZIndex = z,
		Parent = parent,
	}, { Corner(8) })
	local color = o.Color or T.Text
	local x = 12
	local ic
	if o.Icon then
		ic = Icon(o.Icon, row, 16, o.IconColor or (o.Color or T.SubText), {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			ZIndex = z + 1,
		})
		x = 38
	end
	local lbl = Label({
		Text = o.Text or "",
		TextSize = 13,
		TextColor3 = color,
		Position = UDim2.fromOffset(x, 0),
		Size = UDim2.new(1, -x - 90, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = z + 1,
		Parent = row,
	})
	local rightLbl
	if o.Right then
		rightLbl = Label({
			Text = o.Right,
			TextSize = 13,
			TextColor3 = T.SubText,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, o.Chevron and -30 or -12, 0.5, 0),
			Size = UDim2.fromOffset(100, 20),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = z + 1,
			Parent = row,
		})
	end
	local chev
	if o.Chevron then
		chev = Icon("chevron-right", row, 14, T.SubText, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			ZIndex = z + 1,
		})
	end
	row.MouseEnter:Connect(function()
		if not o.Selected then
			Tween(row, { BackgroundTransparency = 0.4 }, 0.22)
		end
	end)
	row.MouseLeave:Connect(function()
		if not o.Selected then
			Tween(row, { BackgroundTransparency = 1 }, 0.22)
		end
	end)
	if o.Callback then
		row.Activated:Connect(function()
			o.Callback(row)
		end)
	end
	return row, lbl, rightLbl, ic, chev
end

local function MenuDivider(parent, z)
	local d = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(),
		ZIndex = z or 102,
		Parent = parent,
	})
	Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = T.Divider,
		BorderSizePixel = 0,
		ZIndex = (z or 102) + 1,
		Parent = d,
	})
	return d
end

local function Switch(parent, z, small)
	local w, h, k = small and 34 or 42, small and 20 or 24, small and 14 or 18
	local sw = Create("Frame", {
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = T.SwitchOff,
		ZIndex = z,
		Parent = parent,
	}, { Round() })
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(k, k),
		BackgroundColor3 = T.KnobOff,
		ZIndex = z + 1,
		Parent = sw,
	}, { Round() })
	local state = false
	local function Paint(on, animate)
		state = on
		local t = animate and 0.34 or 0
		Tween(sw, { BackgroundColor3 = on and T.Accent or T.SwitchOff }, t)
		Tween(knob, {
			Position = on and UDim2.new(1, -(k + 3), 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = on and Color3.new(1, 1, 1) or T.KnobOff,
		}, t)
	end
	OnAccent(function()
		if state then
			sw.BackgroundColor3 = T.Accent
		end
	end)
	return sw, Paint
end

local Hotkey = {}
Hotkey.__index = Hotkey

function Hotkey.new(win, elem)
	local hk = setmetatable({
		Window = win,
		Elem = elem,
		Key = nil,
		Mode = "Toggle",
		Value = elem:_DefaultHotkeyValue(),
		Visible = true,
		Active = false,
		ActivatedAt = 0,
	}, Hotkey)
	table.insert(elem.Hotkeys, hk)
	table.insert(win._hotkeys, hk)
	win:_RefreshHotkeys()
	return hk
end

function Hotkey:SetActive(active)
	active = active and true or false
	if active == self.Active then
		return
	end
	self.Active = active
	if active then
		self.ActivatedAt = os.clock()
	end
	self.Elem:_Recompute()
	self.Window:_RefreshHotkeys()
end

function Hotkey:SetMode(mode)
	self.Mode = mode
	if mode == "Always" then
		self:SetActive(true)
	else
		self:SetActive(false)
	end
	self.Window:_RefreshHotkeys()
end

function Hotkey:SetKey(key)
	self.Key = key
	self.Window:_RefreshHotkeys()
end

function Hotkey:SetValue(v)
	self.Value = CopyValue(v)
	if self.Active then
		self.Elem:_Recompute()
	end
end

function Hotkey:Destroy()
	self:SetActive(false)
	local list = self.Elem.Hotkeys
	local i = table.find(list, self)
	if i then
		table.remove(list, i)
	end
	local all = self.Window._hotkeys
	local j = table.find(all, self)
	if j then
		table.remove(all, j)
	end
	self.Window:_RefreshHotkeys()
end

function Hotkey:Describe()
	local v = self.Value
	if type(v) == "boolean" then
		return v and "On" or "Off"
	elseif type(v) == "table" then
		return #v == 0 and "None" or table.concat(v, ", ")
	elseif type(v) == "number" and self.Elem._Fmt then
		return self.Elem._Fmt(v)
	end
	return tostring(v)
end

local function MakeBindable(elem)
	elem.Hotkeys = {}
	elem.Base = CopyValue(elem.Value)

	function elem:_Recompute(silent)
		local v, best = self.Base, -math.huge
		for _, hk in ipairs(self.Hotkeys) do
			if hk.Active and hk.ActivatedAt > best then
				best = hk.ActivatedAt
				v = hk.Value
			end
		end
		self:_Apply(CopyValue(v), silent)
	end

	function elem:Set(v, silent)
		self.Base = CopyValue(v)
		local changedHotkeys = false
		for _, hk in ipairs(self.Hotkeys) do
			if hk.Mode == "Toggle" and hk.Active then
				hk.Active = false
				changedHotkeys = true
			end
		end
		self:_Recompute(silent)
		if changedHotkeys and self.Window then
			self.Window:_RefreshHotkeys()
		end
	end

	function elem:Get()
		return self.Value
	end

	function elem:Reset()
		self:Set(CopyValue(self.Default))
	end

	function elem:_PaintHint() end

	return elem
end

local function PrevValue(o)
	local f = o.Flag and UI.Flags[o.Flag]
	if f and f.Base ~= nil then
		return CopyValue(f.Base)
	end
	return nil
end

local Container = {}
Container.__index = Container

local function NewContainer(win, items, z, opts)
	opts = opts or {}
	return setmetatable({
		Window = win,
		Items = items,
		_count = 0,
		_z = z or 1,
		_noRegister = opts.NoRegister,
		_noMenu = opts.NoMenu,
		_level = opts.Level or 1,
		Tab = opts.Tab,
		Frame = opts.Frame,
	}, Container)
end

local function NewRow(self, height)
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 40),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(),
		ZIndex = self._z,
		Parent = self.Items,
	})
	if self._count > 0 then
		Create("Frame", {
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 0, 1),
			BackgroundColor3 = T.Divider,
			BorderSizePixel = 0,
			ZIndex = self._z,
			Parent = row,
		})
	end
	self._count += 1
	return row
end

local function RowLabel(self, row, text, rightSpace)
	return Label({
		Text = text,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -(rightSpace or 120), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = self._z,
		Parent = row,
	})
end

local function RightHolder(self, row)
	return Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = self._z,
		Parent = row,
	}, { List(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
end

local function Register(self, o, elem, row)
	elem.Name = o.Name
	elem.Window = self.Window
	elem._row = row
	if not self._noRegister then
		if o.Flag then
			UI.Flags[o.Flag] = elem
		end
		if self.Tab then
			table.insert(self.Window._elements, {
				Name = (o.Name or ""):lower(),
				Row = row,
				Container = self,
				Elem = elem,
			})
		end
	end
	return elem
end

local function AddDots(self, holder, elem, o, order)
	local dots = Create("ImageButton", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Image = "",
		LayoutOrder = order or 6,
		ZIndex = self._z + 2,
		Parent = holder,
	})
	local icon = Icon("ellipsis", dots, 18, T.SubText, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = self._z + 3,
	})
	dots.MouseEnter:Connect(function()
		Tween(icon, { ImageColor3 = T.Text }, 0.22)
	end)
	dots.MouseLeave:Connect(function()
		if not elem._menuOpen then
			Tween(icon, { ImageColor3 = T.SubText }, 0.22)
		end
	end)
	dots.Activated:Connect(function()
		self.Window:_OpenElementMenu(elem, dots, o, icon)
	end)
	elem._dots = dots
	elem._dotsIcon = icon
	return dots
end

function Container:AddToggle(o)
	o = o or {}
	local win, z = self.Window, self._z
	local start = PrevValue(o)
	if start == nil then
		start = o.Default and true or false
	end
	local elem = {
		Type = "Toggle",
		Value = start,
		Default = o.Default and true or false,
		Settings = o.Settings,
		Window = win,
	}
	MakeBindable(elem)

	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Toggle", 160)
	local holder = RightHolder(self, row)

	local sw, Paint = Switch(holder, z)
	sw.LayoutOrder = 10


	if o.Color then
		elem.ColorPicker = self:_Swatch(holder, o.Color, o.ColorFlag, o.ColorCallback, 4, o.Name)
	end

	if not self._noMenu and o.Bindable ~= false then
		AddDots(self, holder, elem, o, 6)
	end

	function elem:_Apply(v, silent)
		local changed = v ~= self.Value
		self.Value = v
		Paint(v, true)
		if changed and not silent then
			SafeCall(o.Callback, v)
		end
	end

	function elem:_DefaultHotkeyValue()
		return true
	end

	local hit = Create("TextButton", {
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = z,
		Parent = row,
	})
	local swHit = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = z + 2,
		Parent = sw,
	})
	hit.Activated:Connect(function()
		elem:Set(not elem.Value)
	end)
	swHit.Activated:Connect(function()
		elem:Set(not elem.Value)
	end)
	if elem._dots then
		hit.MouseButton2Click:Connect(function()
			win:_OpenElementMenu(elem, elem._dots, o, elem._dotsIcon)
		end)
	end

	Paint(elem.Value, false)
	return Register(self, o, elem, row)
end

function Container:AddSlider(o)
	o = o or {}
	local win, z = self.Window, self._z
	local min, max = o.Min or 0, o.Max or 100
	local inc = o.Increment or 1
	local start = PrevValue(o)
	if start == nil then
		start = o.Default or min
	end
	local elem = {
		Type = "Slider",
		Value = start,
		Default = o.Default or min,
		Settings = o.Settings,
		Min = min,
		Max = max,
		Increment = inc,
		Suffix = o.Suffix,
		Window = win,
	}
	MakeBindable(elem)

	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Slider", self._noMenu and 190 or 230)

	local rightOffset = 14
	if not self._noMenu and o.Bindable ~= false then
		local h = RightHolder(self, row)
		AddDots(self, h, elem, o, 1)
		rightOffset = 44
	end

	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -rightOffset, 0.5, 0),
		Size = UDim2.fromOffset(48, 26),
		BackgroundColor3 = T.Field,
		Text = "",
		FontFace = F.Medium,
		TextSize = 12,
		TextColor3 = T.SubText,
		ClearTextOnFocus = false,
		ZIndex = z,
		Parent = row,
	}, { Corner(7), Stroke(T.Stroke) })

	local trackW = o.TrackWidth or (self._noMenu and 96 or 120)
	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -rightOffset - 60, 0.5, 0),
		Size = UDim2.fromOffset(trackW, 4),
		BackgroundColor3 = T.SwitchOff,
		ZIndex = z,
		Parent = row,
	}, { Round() })
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = T.Accent,
		ZIndex = z + 1,
		Parent = track,
	}, { Round() })
	OnAccent(function(c)
		fill.BackgroundColor3 = c
	end)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = z + 2,
		Parent = track,
	}, { Round() })

	local decimals = 0
	do
		local s = tostring(inc)
		local dot = s:find("%.")
		if dot then
			decimals = #s - dot
		end
	end
	local function Fmt(v)
		return string.format("%." .. decimals .. "f", v) .. (o.Suffix or "")
	end
	local function Snap(v)
		return math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
	end
	elem._Fmt = Fmt

	function elem:_Apply(v, silent)
		v = Snap(v)
		local changed = v ~= self.Value
		self.Value = v
		local pct = (v - min) / math.max(max - min, 1e-9)
		Tween(fill, { Size = UDim2.fromScale(pct, 1) }, 0.14)
		Tween(knob, { Position = UDim2.fromScale(pct, 0.5) }, 0.14)
		box.Text = Fmt(v)
		if changed and not silent then
			SafeCall(o.Callback, v)
		end
	end

	function elem:_DefaultHotkeyValue()
		return self.Base
	end

	box.FocusLost:Connect(function()
		local n = tonumber((box.Text:gsub("[^%d%.%-]", "")))
		if n then
			elem:Set(n)
		else
			box.Text = Fmt(elem.Value)
		end
	end)

	local dragging = false
	local hit = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -rightOffset - 54, 0.5, 0),
		Size = UDim2.fromOffset(trackW + 12, 26),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = z + 3,
		Parent = row,
	})
	local function FromMouse()
		local m = Mouse()
		local pct = math.clamp((m.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		elem:Set(min + (max - min) * pct)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.1)
			FromMouse()
		end
	end)
	table.insert(win._conns, UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			if not row.Parent then
				dragging = false
				return
			end
			FromMouse()
		end
	end))
	table.insert(win._conns, UserInputService.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.1)
		end
	end))

	elem.Value = nil
	elem:_Apply(elem.Base, true)
	return Register(self, o, elem, row)
end

local function DropBox(z, parent, width, rightOffset)
	local box = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(rightOffset or 14), 0.5, 0),
		Size = width or UDim2.new(0.5, -4, 0, 30),
		BackgroundColor3 = T.Field,
		AutoButtonColor = false,
		Text = "",
		ZIndex = z,
		Parent = parent,
	}, { Corner(8), Stroke(T.Stroke) })
	local txt = Label({
		Text = "",
		TextSize = 13,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -40, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = z,
		Parent = box,
	})
	local chev = Icon("chevron-down", box, 14, T.SubText, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		ZIndex = z,
	})
	box.MouseEnter:Connect(function()
		Tween(box, { BackgroundColor3 = T.FieldHi }, 0.22)
	end)
	box.MouseLeave:Connect(function()
		Tween(box, { BackgroundColor3 = T.Field }, 0.22)
	end)
	return box, txt, chev
end

function Container:AddDropdown(o)
	o = o or {}
	local win, z = self.Window, self._z
	local multi = o.Multi
	local options = o.Options or {}
	local default = multi and table.clone(o.Default or {}) or (o.Default or options[1])
	local start = PrevValue(o)
	if start == nil then
		start = CopyValue(default)
	end
	local elem = {
		Type = "Dropdown",
		Options = options,
		Multi = multi,
		Value = start,
		Default = CopyValue(default),
		Settings = o.Settings,
		Window = win,
	}
	MakeBindable(elem)

	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Dropdown", 230)

	local rightOffset = 14
	if not self._noMenu and o.Bindable ~= false then
		local h = RightHolder(self, row)
		AddDots(self, h, elem, o, 1)
		rightOffset = 44
	end
	local box, txt, chev = DropBox(z, row, UDim2.new(0.5, -(rightOffset - 10), 0, 30), rightOffset)

	local level = self._level + (self._noMenu and 1 or 0)
	local pop = Create("ScrollingFrame", {
		Size = UDim2.fromOffset(200, 0),
		BackgroundColor3 = T.Popup,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.Caps,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 140 + level * 10,
		Parent = win.Overlay,
	}, { Corner(10), Stroke(T.Stroke), List(2), Pad(5, 5, 5, 5) })
	FollowShadow(pop, win.Overlay, 10, 5, 0.16, pop.ZIndex - 1)

	local function IsOn(opt)
		if multi then
			return table.find(elem.Value, opt) ~= nil
		end
		return elem.Value == opt
	end

	local function Display()
		if multi then
			txt.Text = #elem.Value == 0 and "None" or table.concat(elem.Value, ", ")
		else
			txt.Text = tostring(elem.Value or "None")
		end
	end

	local Build
	function Build()
		for _, c in ipairs(pop:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		local zz = pop.ZIndex + 1
		for i, opt in ipairs(elem.Options) do
			local on = IsOn(opt)
			local b = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = T.Nav,
				BackgroundTransparency = on and 0 or 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = i,
				ZIndex = zz,
				Parent = pop,
			}, { Corner(7) })
			local t = Label({
				Text = tostring(opt),
				TextSize = 13,
				TextColor3 = on and T.Text or T.SubText,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -36, 1, 0),
				ZIndex = zz + 1,
				Parent = b,
			})
			if on then
				Icon("check", b, 14, T.Accent, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					ZIndex = zz + 1,
				})
			end
			b.MouseEnter:Connect(function()
				if not IsOn(opt) then
					Tween(b, { BackgroundTransparency = 0.5 }, 0.1)
					Tween(t, { TextColor3 = T.Text }, 0.1)
				end
			end)
			b.MouseLeave:Connect(function()
				if not IsOn(opt) then
					Tween(b, { BackgroundTransparency = 1 }, 0.1)
					Tween(t, { TextColor3 = T.SubText }, 0.1)
				end
			end)
			b.Activated:Connect(function()
				if multi then
					local v = table.clone(elem.Value)
					local idx = table.find(v, opt)
					if idx then
						table.remove(v, idx)
					else
						table.insert(v, opt)
					end
					elem:Set(v)
				else
					elem:Set(opt)
					CloseFrom(win, level)
				end
			end)
		end
		pop.Size = UDim2.fromOffset(box.AbsoluteSize.X, math.min(#elem.Options * 32 + 10, 260))
	end

	function elem:_Apply(v, silent)
		local changed = not ValueEquals(v, self.Value)
		self.Value = v
		Display()
		if pop.Visible then
			Build()
		end
		if changed and not silent then
			SafeCall(o.Callback, CopyValue(v))
		end
	end

	function elem:_DefaultHotkeyValue()
		return CopyValue(self.Base)
	end

	function elem:Refresh(newOptions, keep)
		self.Options = newOptions or {}
		if not keep then
			self:Set(multi and {} or self.Options[1])
		else
			Display()
		end
		if pop.Visible then
			Build()
		end
	end

	box.Activated:Connect(function()
		if IsOpen(win, pop) then
			CloseFrom(win, level)
		elseif not JustClosed(win, pop) then
			Build()
			PlaceNear(win, pop, box, box.AbsoluteSize.X, "below-right")
			Tween(chev, { Rotation = 180 }, 0.15)
			OpenLayer(win, level, pop, function()
				Tween(chev, { Rotation = 0 }, 0.15)
			end)
		end
	end)

	Display()
	return Register(self, o, elem, row)
end

function Container:_Swatch(parent, default, flag, callback, layoutOrder, name)
	local win = self.Window
	local level = self._level + (self._noMenu and 1 or 0)
	local cp = { Type = "ColorPicker", Value = default or Color3.new(1, 1, 1), Name = name }
	local h, s, v = cp.Value:ToHSV()

	local sw = Create("TextButton", {
		Size = UDim2.fromOffset(22, 14),
		BackgroundColor3 = cp.Value,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = layoutOrder or 1,
		ZIndex = self._z,
		Parent = parent,
	}, { Corner(4), Stroke(Color3.new(0, 0, 0), 1, 0.4) })

	local zb = 160 + level * 10
	local pop = Create("Frame", {
		Size = UDim2.fromOffset(222, 248),
		BackgroundColor3 = T.Popup,
		Visible = false,
		ZIndex = zb,
		Parent = win.Overlay,
	}, { Corner(12), Stroke(T.Stroke) })
	FollowShadow(pop, win.Overlay, 12, 6, 0.16, zb - 1)

	local svBox = Create("ImageButton", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(164, 164),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		AutoButtonColor = false,
		Image = "",
		ZIndex = zb + 1,
		Parent = pop,
	}, { Corner(8) })
	Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Active = false,
		ZIndex = zb + 2,
		Parent = svBox,
	}, { Corner(8), Create("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
	Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Active = false,
		ZIndex = zb + 3,
		Parent = svBox,
	}, { Corner(8), Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
	local svKnob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ZIndex = zb + 4,
		Parent = svBox,
	}, { Round(), Stroke(Color3.new(1, 1, 1), 2) })

	local hue = Create("ImageButton", {
		Position = UDim2.fromOffset(186, 12),
		Size = UDim2.fromOffset(24, 164),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Image = "",
		ZIndex = zb + 1,
		Parent = pop,
	}, {
		Corner(8),
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
				ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
				ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
				ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
				ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
				ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
			}),
		}),
	})
	local hueKnob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = zb + 2,
		Parent = hue,
	}, { Corner(2) })

	local presets = Create("Frame", {
		Position = UDim2.fromOffset(12, 184),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundTransparency = 1,
		ZIndex = zb + 1,
		Parent = pop,
	}, { List(6, Enum.FillDirection.Horizontal) })

	local hex = Create("TextBox", {
		Position = UDim2.fromOffset(12, 212),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundColor3 = T.Field,
		Text = "",
		FontFace = F.Medium,
		TextSize = 12,
		TextColor3 = T.Text,
		ClearTextOnFocus = false,
		ZIndex = zb + 1,
		Parent = pop,
	}, { Corner(7), Stroke(T.Stroke) })

	local function Apply(silent)
		cp.Value = Color3.fromHSV(h, s, v)
		sw.BackgroundColor3 = cp.Value
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svKnob.Position = UDim2.fromScale(s, 1 - v)
		hueKnob.Position = UDim2.fromScale(0.5, h)
		hex.Text = "#" .. cp.Value:ToHex():upper()
		if not silent then
			SafeCall(callback, cp.Value)
		end
	end

	function cp:Set(c, silent)
		h, s, v = c:ToHSV()
		Apply(silent)
	end

	for _, pr in ipairs(ACCENT_PRESETS) do
		local b = Create("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = pr[2],
			AutoButtonColor = false,
			Text = "",
			ZIndex = zb + 2,
			Parent = presets,
		}, { Round() })
		b.Activated:Connect(function()
			cp:Set(pr[2])
		end)
	end

	local mode
	local function Update()
		local m = Mouse()
		if mode == "sv" then
			s = math.clamp((m.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((m.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
		elseif mode == "hue" then
			h = math.clamp((m.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
		end
		Apply()
	end
	svBox.MouseButton1Down:Connect(function()
		mode = "sv"
		Update()
	end)
	hue.MouseButton1Down:Connect(function()
		mode = "hue"
		Update()
	end)
	table.insert(win._conns, UserInputService.InputChanged:Connect(function(i)
		if mode and i.UserInputType == Enum.UserInputType.MouseMovement then
			Update()
		end
	end))
	table.insert(win._conns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			mode = nil
		end
	end))
	hex.FocusLost:Connect(function()
		local str = (hex.Text:gsub("#", ""))
		local ok, c = pcall(Color3.fromHex, str)
		if ok and c then
			cp:Set(c)
		else
			Apply(true)
		end
	end)

	sw.Activated:Connect(function()
		if IsOpen(win, pop) then
			CloseFrom(win, level)
		elseif not JustClosed(win, pop) then
			PlaceNear(win, pop, sw, 222, "below-right")
			OpenLayer(win, level, pop)
		end
	end)

	Apply(true)
	if flag and not self._noRegister then
		UI.Flags[flag] = cp
	end
	return cp
end

function Container:AddColorPicker(o)
	o = o or {}
	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Color", 80)
	local holder = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(22, 14),
		BackgroundTransparency = 1,
		ZIndex = self._z,
		Parent = row,
	})
	local cp = self:_Swatch(holder, o.Default, nil, o.Callback, 1, o.Name)
	return Register(self, o, cp, row)
end

function Container:AddButton(o)
	o = o or {}
	local z = self._z
	local row = NewRow(self, 48)
	local b = Create("TextButton", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 1, -15),
		BackgroundColor3 = o.Danger and Color3.fromRGB(52, 30, 32) or T.Field,
		AutoButtonColor = false,
		Text = o.Name or "Button",
		FontFace = F.Medium,
		TextSize = 13,
		TextColor3 = o.Danger and T.Danger or T.Text,
		ZIndex = z,
		Parent = row,
	}, { Corner(8), Stroke(T.Stroke) })
	local base = b.BackgroundColor3
	b.MouseEnter:Connect(function()
		Tween(b, { BackgroundColor3 = o.Danger and Color3.fromRGB(64, 34, 36) or T.FieldHi }, 0.22)
	end)
	b.MouseLeave:Connect(function()
		Tween(b, { BackgroundColor3 = base }, 0.22)
	end)
	b.Activated:Connect(function()
		b.BackgroundColor3 = o.Danger and T.Danger or T.Accent
		Tween(b, { BackgroundColor3 = base }, 0.35)
		SafeCall(o.Callback)
	end)
	return Register(self, o, { Type = "Button" }, row)
end

function Container:AddKeybind(o)
	o = o or {}
	local win, z = self.Window, self._z
	local kb = { Type = "Keybind", Value = o.Default, Listening = false }
	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Keybind", 120)
	local chip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Field,
		AutoButtonColor = false,
		Text = "",
		FontFace = F.Medium,
		TextSize = 12,
		TextColor3 = T.SubText,
		ZIndex = z,
		Parent = row,
	}, { Corner(7), Stroke(T.Stroke), Pad(0, 12, 0, 12) })
	local function Paint()
		chip.Text = kb.Listening and "Press a key..." or KeyName(kb.Value)
		chip.TextColor3 = kb.Listening and T.Accent or T.SubText
	end
	function kb:Set(k)
		self.Value = k
		Paint()
		SafeCall(o.Changed, k)
	end
	chip.Activated:Connect(function()
		kb.Listening = true
		win._listeningKeybind = kb
		Paint()
	end)
	table.insert(win._conns, UserInputService.InputBegan:Connect(function(i, gp)
		if kb.Listening then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				kb.Listening = false
				task.defer(function()
					win._listeningKeybind = nil
				end)
				if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then
					kb:Set(nil)
				else
					kb:Set(i.KeyCode)
				end
			end
			return
		end
		if not gp and kb.Value and i.KeyCode == kb.Value then
			SafeCall(o.Callback)
		end
	end))
	Paint()
	return Register(self, o, kb, row)
end

function Container:AddTextbox(o)
	o = o or {}
	local z = self._z
	local tb = { Type = "Textbox", Value = o.Default or "" }
	local row = NewRow(self, 40)
	RowLabel(self, row, o.Name or "Text", 230)
	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.5, -4, 0, 30),
		BackgroundColor3 = T.Field,
		Text = tb.Value,
		PlaceholderText = o.Placeholder or "",
		PlaceholderColor3 = T.Caps,
		FontFace = F.Medium,
		TextSize = 13,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = z,
		Parent = row,
	}, { Corner(8), Stroke(T.Stroke), Pad(0, 12, 0, 12) })
	function tb:Set(t)
		self.Value = t
		box.Text = t
	end
	box.FocusLost:Connect(function(enter)
		tb.Value = box.Text
		SafeCall(o.Callback, box.Text, enter)
	end)
	return Register(self, o, tb, row)
end

function Container:AddLabel(text)
	local row = NewRow(self, 36)
	local l = Label({
		Text = text or "",
		TextSize = 12,
		TextColor3 = T.SubText,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		TextWrapped = true,
		ZIndex = self._z,
		Parent = row,
	})
	return {
		Type = "Label",
		Set = function(_, t)
			l.Text = t
		end,
	}
end

function Container:AddParagraph(o)
	o = o or {}
	local row = NewRow(self, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local inner = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = self._z,
		Parent = row,
	}, { List(4), Pad(10, 16, 10, 16) })
	Label({
		Text = o.Title or "",
		FontFace = F.Bold,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16),
		ZIndex = self._z,
		Parent = inner,
	})
	Label({
		Text = o.Text or "",
		TextSize = 12,
		TextColor3 = T.SubText,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		ZIndex = self._z,
		Parent = inner,
	})
	return { Type = "Paragraph" }
end

local Window = {}
Window.__index = Window

local SIDEBAR = 186
local BASE_W, BASE_H = 840, 600

function UI:CreateWindow(opts)
	opts = opts or {}
	if opts.Accent then
		T.Accent = opts.Accent
	end

	local win = setmetatable({
		_conns = {},
		_elements = {},
		_hotkeys = {},
		_tabs = {},
		_layers = {},
		_closedAt = {},
		_hudScales = {},
		Brand = opts.Brand or "Neverlose",
		Logo = opts.Logo or "CH",
		Game = opts.Game or "",
		SubText = opts.SubText or "Lifetime",
		Config = "default",
		Visible = true,
		ToggleKey = opts.ToggleKey or Enum.KeyCode.Insert,
	}, Window)

	local old = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NeverloseMenu")
	if old then
		old:Destroy()
	end
	local gui = Create("ScreenGui", {
		Name = "NeverloseMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
		AutoLocalize = false,
		Parent = LocalPlayer:WaitForChild("PlayerGui"),
	})
	win.Gui = gui

	local main = Create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 30),
		Size = UDim2.fromOffset(BASE_W, BASE_H),
		BackgroundColor3 = T.Window,
		GroupTransparency = 0,
		ZIndex = 2,
		Parent = gui,
	}, { Corner(16) })
	Create("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = main,
	}, { Corner(15), Stroke(Color3.fromRGB(36, 37, 42)) })
	win.Main = main
	win.Scale = Create("UIScale", { Parent = main })
	FollowShadow(main, gui, 16, 3, 0.5, 1, 2)
	win.Overlay = Create("Frame", {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 90,
		Parent = gui,
	})
	win._modal = Create("TextButton", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Modal = true,
		Parent = main,
	})

	local side = Create("Frame", {
		Size = UDim2.new(0, SIDEBAR, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = main,
	})
	win._side = side

	local head = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = side,
	})
	win._head = head
	local logo = Create("Frame", {
		Position = UDim2.fromOffset(16, 18),
		Size = UDim2.fromOffset(42, 42),
		BackgroundColor3 = Color3.fromRGB(12, 13, 15),
		ZIndex = 3,
		Parent = head,
	}, { Corner(10), Stroke(Color3.fromRGB(36, 37, 42)) })
	win._logoLbl = Label({
		Text = win.Logo,
		FontFace = F.Logo,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = logo,
	})
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.2, Transparency = 0.35, Parent = win._logoLbl })
	win._brandLbl = Label({
		Text = win.Brand,
		FontFace = F.Bold,
		TextSize = 15,
		Position = UDim2.fromOffset(68, 20),
		Size = UDim2.new(1, -76, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = head,
	})
	win._gameLbl = Label({
		Text = win.Game,
		TextSize = 12,
		TextColor3 = T.Caps,
		Position = UDim2.fromOffset(68, 40),
		Size = UDim2.new(1, -76, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = head,
	})
	if win.Game == "" then
		win._gameLbl.Visible = false
		win._brandLbl.Position = UDim2.fromOffset(68, 30)
	end

	win._nav = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 78),
		Size = UDim2.new(1, 0, 1, -78 - 76),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = side,
	})
	win._navContent = Create("Frame", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = win._nav,
	}, { List(4) })
	win._navHighlight = Create("Frame", {
		Size = UDim2.new(1, -24, 0, 40),
		BackgroundColor3 = T.Nav,
		Visible = false,
		ZIndex = 2,
		Parent = win._nav,
	}, { Corner(10) })

	local foot = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = side,
	})
	Create("Frame", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = T.Divider,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = foot,
	})
	local card = Create("TextButton", {
		Position = UDim2.fromOffset(8, 10),
		Size = UDim2.new(1, -16, 0, 56),
		BackgroundColor3 = T.Nav,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = foot,
	}, { Corner(10) })
	win._profileCard = card
	local av = Create("ImageLabel", {
		Position = UDim2.fromOffset(8, 9),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = T.Field,
		ZIndex = 4,
		Parent = card,
	}, { Round() })
	win._avatar = av
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then
			av.Image = img
			win._avatarImage = img
			if win._profileAvatar then
				win._profileAvatar.Image = img
			end
		end
	end)
	Label({
		Text = LocalPlayer.Name,
		FontFace = F.Medium,
		TextSize = 13,
		Position = UDim2.fromOffset(54, 11),
		Size = UDim2.new(1, -86, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = card,
	})
	win._subLbl = Label({
		Text = win.SubText,
		TextSize = 12,
		TextColor3 = T.Caps,
		Position = UDim2.fromOffset(54, 29),
		Size = UDim2.new(1, -86, 0, 15),
		ZIndex = 4,
		Parent = card,
	})
	local cardChev = Icon("chevron-right", card, 14, T.Caps, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		ZIndex = 4,
	})
	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.4 }, 0.22)
		Tween(cardChev, { ImageColor3 = T.Text }, 0.22)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 1 }, 0.22)
		Tween(cardChev, { ImageColor3 = T.Caps }, 0.22)
	end)
	card.Activated:Connect(function()
		win:_ToggleProfileMenu()
	end)

	local panel = Create("Frame", {
		Position = UDim2.fromOffset(SIDEBAR, 8),
		Size = UDim2.new(1, -SIDEBAR - 8, 1, -16),
		BackgroundColor3 = T.Panel,
		ZIndex = 2,
		Parent = main,
	}, { Corner(12), Stroke(Color3.fromRGB(33, 34, 39)) })
	win._panel = panel

	local top = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = panel,
	})
	win._top = top
	Create("Frame", {
		Position = UDim2.new(0, 14, 1, -1),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = T.Divider,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = top,
	})

	local cfgBox = Create("Frame", {
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(200, 34),
		BackgroundColor3 = T.Group,
		ZIndex = 3,
		Parent = top,
	}, { Corner(9), Stroke(T.Stroke) })
	win._cfgBox = cfgBox
	local saveBtn = Create("ImageButton", {
		Size = UDim2.fromOffset(38, 34),
		BackgroundTransparency = 1,
		Image = "",
		ZIndex = 4,
		Parent = cfgBox,
	})
	local saveIcon = Icon("save", saveBtn, 15, T.SubText, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 5,
	})
	Create("Frame", {
		Position = UDim2.fromOffset(38, 8),
		Size = UDim2.fromOffset(1, 18),
		BackgroundColor3 = T.Stroke,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = cfgBox,
	})
	local cfgBtn = Create("TextButton", {
		Position = UDim2.fromOffset(39, 0),
		Size = UDim2.new(1, -39, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = cfgBox,
	})
	win._cfgLbl = Label({
		Text = win.Config,
		TextSize = 13,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -40, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = cfgBtn,
	})
	local cfgChev = Icon("chevron-down", cfgBtn, 14, T.SubText, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		ZIndex = 5,
	})
	saveBtn.MouseEnter:Connect(function()
		Tween(saveIcon, { ImageColor3 = T.Text }, 0.22)
	end)
	saveBtn.MouseLeave:Connect(function()
		Tween(saveIcon, { ImageColor3 = T.SubText }, 0.22)
	end)
	saveBtn.Activated:Connect(function()
		win:SaveConfig(win.Config)
		win:Notify({ Title = "Config", Text = "Saved \"" .. win.Config .. "\"", Icon = "save" })
	end)

	local cfgPop, cfgItems = PopupFrame(win, 220, "Configs")
	local function FillConfigs()
		for _, c in ipairs(cfgItems:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("Frame") then
				c:Destroy()
			end
		end
		local names = win:ConfigNames()
		if not table.find(names, win.Config) then
			table.insert(names, 1, win.Config)
		end
		for _, n in ipairs(names) do
			local on = n == win.Config
			MenuRow(cfgItems, {
				Text = n,
				Icon = on and "folder-open" or "folder",
				IconColor = on and T.Accent or T.SubText,
				Color = on and T.Text or T.SubText,
				Selected = on,
				Callback = function()
					win:_SetConfig(n)
					win:LoadConfig(n)
					CloseFrom(win, 1)
					win:Notify({ Title = "Config", Text = "Loaded \"" .. n .. "\"", Icon = "folder-open" })
				end,
			})
		end
		MenuDivider(cfgItems)
		MenuRow(cfgItems, {
			Text = "New config",
			Icon = "plus",
			IconColor = T.Accent,
			Callback = function()
				local n = "config " .. (#win:ConfigNames() + 1)
				win:_SetConfig(n)
				win:SaveConfig(n)
				CloseFrom(win, 1)
				win:Notify({ Title = "Config", Text = "Created \"" .. n .. "\"", Icon = "plus" })
			end,
		})
		MenuRow(cfgItems, {
			Text = "Export / Import",
			Icon = "upload",
			Callback = function()
				CloseFrom(win, 1)
				win:_ShowExport(win:SaveConfig(win.Config))
			end,
		})
		MenuRow(cfgItems, {
			Text = "Delete",
			Icon = "trash",
			IconColor = T.Danger,
			Color = T.Danger,
			Callback = function()
				UI.Configs[win.Config] = nil
				CloseFrom(win, 1)
				win:Notify({ Title = "Config", Text = "Deleted \"" .. win.Config .. "\"", Icon = "trash" })
			end,
		})
	end
	cfgBtn.Activated:Connect(function()
		if IsOpen(win, cfgPop) then
			CloseFrom(win, 1)
		elseif not JustClosed(win, cfgPop) then
			FillConfigs()
			PlaceNear(win, cfgPop, cfgBox, 220, "below-left")
			Tween(cfgChev, { Rotation = 180 }, 0.15)
			OpenLayer(win, 1, cfgPop, function()
				Tween(cfgChev, { Rotation = 0 }, 0.15)
			end)
		end
	end)

	local contexts = opts.Contexts or { "Local" }
	win.Context = contexts[1]
	local ctxBox = Create("TextButton", {
		Position = UDim2.fromOffset(226, 14),
		Size = UDim2.fromOffset(124, 34),
		BackgroundColor3 = T.Group,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = top,
	}, { Corner(9), Stroke(T.Stroke) })
	win._ctxBox = ctxBox
	local ctxLbl = Label({
		Text = win.Context,
		TextSize = 13,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -40, 1, 0),
		ZIndex = 4,
		Parent = ctxBox,
	})
	local ctxChev = Icon("chevron-down", ctxBox, 14, T.SubText, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		ZIndex = 4,
	})
	local ctxPop, ctxItems = PopupFrame(win, 170)
	for _, c in ipairs(contexts) do
		MenuRow(ctxItems, {
			Text = c,
			Callback = function()
				win.Context = c
				ctxLbl.Text = c
				CloseFrom(win, 1)
				SafeCall(opts.ContextChanged, c)
			end,
		})
	end
	ctxBox.Activated:Connect(function()
		if IsOpen(win, ctxPop) then
			CloseFrom(win, 1)
		elseif not JustClosed(win, ctxPop) then
			PlaceNear(win, ctxPop, ctxBox, 170, "below-left")
			Tween(ctxChev, { Rotation = 180 }, 0.15)
			OpenLayer(win, 1, ctxPop, function()
				Tween(ctxChev, { Rotation = 0 }, 0.15)
			end)
		end
	end)

	local searchWrap = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = T.Group,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = top,
	}, { Corner(9) })
	win._searchWrap = searchWrap
	local searchStroke = Stroke(T.Stroke, 1, 1)
	searchStroke.Parent = searchWrap
	local searchBox = Create("TextBox", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = T.Caps,
		FontFace = F.Medium,
		TextSize = 13,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Visible = false,
		ZIndex = 4,
		Parent = searchWrap,
	})
	local searchBtn = Create("ImageButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 1,
		Image = "",
		ZIndex = 4,
		Parent = searchWrap,
	})
	local searchIcon = Icon("search", searchBtn, 17, T.SubText, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 5,
	})
	local searchOpen = false
	searchBtn.Activated:Connect(function()
		searchOpen = not searchOpen
		Tween(searchWrap, {
			Size = UDim2.fromOffset(searchOpen and 220 or 34, 34),
			BackgroundTransparency = searchOpen and 0 or 1,
		}, 0.25)
		Tween(searchStroke, { Transparency = searchOpen and 0 or 1 }, 0.25)
		Tween(searchIcon, { ImageColor3 = searchOpen and T.Text or T.SubText }, 0.2)
		searchBox.Visible = searchOpen
		if searchOpen then
			searchBox:CaptureFocus()
		else
			searchBox.Text = ""
		end
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		win:_Filter(searchBox.Text)
	end)

	win._pages = Create("Frame", {
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = panel,
	})

	win:_SetupDrag()

	table.insert(win._conns, UserInputService.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then
			local m = Mouse()
			task.defer(function()
				local anyOpen = false
				for l = 1, MAX_LEVEL do
					if win._layers[l] then
						anyOpen = true
						break
					end
				end
				if anyOpen and not InsideLayers(win, m) then
					CloseFrom(win, 1)
				end
			end)
		end
	end))

	table.insert(win._conns, UserInputService.InputBegan:Connect(function(i)
		if win._listeningMenuKey then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				local done = win._listeningMenuKey
				if i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode ~= Enum.KeyCode.Unknown then
					win.ToggleKey = i.KeyCode
				end
				task.defer(function()
					win._listeningMenuKey = nil
				end)
				SafeCall(done)
			end
			return
		end
		if i.KeyCode == win.ToggleKey and not UserInputService:GetFocusedTextBox() and not win._listeningKeybind and not win._listeningHotkey then
			win:SetVisible(not win.Visible)
		end
	end))

	win:_SetupHotkeyInput()

	local hudOk, hudErr = pcall(win._BuildHud, win)
	if not hudOk then
		warn("[Neverlose] " .. tostring(hudErr))
	end

	local cam = workspace.CurrentCamera
	if cam then
		table.insert(win._conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			win:_ApplyScale()
		end))
	end
	win:_ApplyScale()
	return win
end

function Window:_SetupDrag()
	local main = self.Main
	local dragging, startMouse, startPos = false, nil, nil

	local function OverControl(m)
		local blockers = { self._cfgBox, self._ctxBox, self._searchWrap, self._profileCard }
		for _, b in ipairs(blockers) do
			if b and Inside(b, m) then
				return true
			end
		end
		for _, t in ipairs(self._tabs) do
			if Inside(t._btn, m) then
				return true
			end
		end
		local tab = self.ActiveTab
		if tab then
			for _, g in ipairs(tab._groups) do
				if g.Frame.Visible and Inside(g.Box, m) then
					return true
				end
			end
		end
		return false
	end

	table.insert(self._conns, UserInputService.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if not self.Visible or not main.Visible then
			return
		end
		local m = Mouse()
		if not Inside(main, m) or InsideLayers(self, m) then
			return
		end
		if OverControl(m) then
			return
		end
		dragging = true
		startMouse = m
		startPos = main.Position
	end))
	table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
		if not dragging then
			return
		end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local d = Mouse() - startMouse
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end))
	table.insert(self._conns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function ParseScale(s)
	if s == "Auto" or not s then
		return nil
	end
	local n = tonumber((tostring(s):gsub("%%", "")))
	return n and n / 100 or nil
end

function Window:_ApplyScale()
	local cam = workspace.CurrentCamera
	local vs = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
	local auto = math.min(1, (vs.Y - 140) / BASE_H, (vs.X - 40) / BASE_W)
	self._fit = ParseScale(UI.Settings.MenuScale) or auto
	if self.Visible then
		self.Scale.Scale = self._fit
	end
	local hudScale = ParseScale(UI.Settings.WindowsScale) or math.min(1, vs.Y / 720)
	for _, s in ipairs(self._hudScales) do
		s.Scale = hudScale
	end
end

function Window:SetVisible(v)
	self.Visible = v
	CloseFrom(self, 1)
	self._modal.Modal = v
	local ease = Enum.EasingStyle.Quint
	if v then
		if not self.Main.Visible then
			self.Scale.Scale = self._fit * 0.95
			self.Main.GroupTransparency = 1
		end
		self.Main.Visible = true
		Tween(self.Scale, { Scale = self._fit }, 0.45, ease)
		Tween(self.Main, { GroupTransparency = 0 }, 0.35, ease)
	else
		Tween(self.Main, { GroupTransparency = 1 }, 0.28, ease)
		Tween(self.Scale, { Scale = self._fit * 0.95 }, 0.32, ease).Completed:Connect(function()
			if not self.Visible then
				self.Main.Visible = false
			end
		end)
	end
	self:_RefreshHotkeys()
	self:_RefreshSpectators()
	self:_RefreshWidgets()
end

function Window:_MoveNavHighlight(btn)
	task.defer(function()
		local hl, content = self._navHighlight, self._navContent
		local scale = self.Main.AbsoluteSize.X / BASE_W
		if scale <= 0 then
			return
		end
		local y = (btn.AbsolutePosition.Y - content.AbsolutePosition.Y) / scale
		local target = UDim2.fromOffset(12, y)
		if not hl.Visible then
			hl.Position = target
			hl.Visible = true
		else
			Tween(hl, { Position = target }, 0.32)
		end
	end)
end

function Window:SetBrand(name, logo, gameName)
	if name then
		self.Brand = name
		self._brandLbl.Text = name
	end
	if logo then
		self.Logo = logo
		self._logoLbl.Text = logo
		self._wmLogo.Text = logo
	end
	if gameName then
		self.Game = gameName
		self._gameLbl.Text = gameName
	end
end

local Section = {}
Section.__index = Section

function Window:AddCategory(name)
	local cap = Label({
		Text = name:upper(),
		FontFace = F.Medium,
		TextSize = 11,
		TextColor3 = T.Caps,
		Size = UDim2.new(1, 0, 0, #self._tabs == 0 and 24 or 38),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = NextOrder(),
		ZIndex = 3,
		Parent = self._navContent,
	})
	Create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6), Parent = cap })
	return setmetatable({ Window = self, Name = name }, Section)
end

local Tab = {}
Tab.__index = Tab

function Section:AddTab(name, icon)
	local win = self.Window
	local tab = setmetatable({ Window = win, Name = name, Section = self.Name, _groups = {} }, Tab)

	local btn = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = T.Nav,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = NextOrder(),
		ZIndex = 3,
		Parent = win._navContent,
	}, { Corner(10) })
	local ic = Icon(icon or "star", btn, 18, T.SubText, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		ZIndex = 4,
	})
	local lbl = Label({
		Text = name,
		TextSize = 14,
		TextColor3 = T.SubText,
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -48, 1, 0),
		ZIndex = 4,
		Parent = btn,
	})
	tab._btn, tab._icon, tab._lbl = btn, ic, lbl

	local page = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Caps,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 2,
		Parent = win._pages,
	}, { Pad(6, 14, 16, 14) })
	local left = Create("Frame", {
		Size = UDim2.new(0.5, -7, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = page,
	}, { List(0) })
	local right = Create("Frame", {
		Position = UDim2.new(0.5, 7, 0, 0),
		Size = UDim2.new(0.5, -7, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = page,
	}, { List(0) })
	tab._page, tab._left, tab._right = page, left, right

	local empty = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(260, 90),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = win._pages,
	})
	tab._empty = empty

	local function PaintNav(t, on)
		Tween(t._lbl, { TextColor3 = on and T.Text or T.SubText }, 0.18)
		Tween(t._icon, { ImageColor3 = on and T.Accent or T.SubText }, 0.18)
	end
	OnAccent(function()
		if win.ActiveTab == tab then
			tab._icon.ImageColor3 = T.Accent
		end
	end)

	function tab:Select()
		for _, t in ipairs(win._tabs) do
			local on = t == tab
			t._page.Visible = on
			t._empty.Visible = on and #t._groups == 0
			PaintNav(t, on)
		end
		win.ActiveTab = tab
		win:_MoveNavHighlight(btn)
		page.Position = UDim2.fromOffset(0, 14)
		Tween(page, { Position = UDim2.new() }, 0.38)
		CloseFrom(win, 1)
	end

	btn.MouseEnter:Connect(function()
		if win.ActiveTab ~= tab then
			Tween(lbl, { TextColor3 = T.Text }, 0.22)
		end
	end)
	btn.MouseLeave:Connect(function()
		if win.ActiveTab ~= tab then
			Tween(lbl, { TextColor3 = T.SubText }, 0.22)
		end
	end)
	btn.Activated:Connect(function()
		tab:Select()
	end)

	table.insert(win._tabs, tab)
	if #win._tabs == 1 then
		tab:Select()
	end
	return tab
end

function Tab:AddGroup(name, side)
	local col = (side == "Right" or side == 2) and self._right or self._left
	local wrap = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(),
		ZIndex = 2,
		Parent = col,
	})
	Label({
		Text = (name or ""):upper(),
		TextSize = 11,
		TextColor3 = T.Caps,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -8, 0, 34),
		ZIndex = 2,
		Parent = wrap,
	})
	local box = Create("Frame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Group,
		ZIndex = 2,
		Parent = wrap,
	}, { Corner(12), Stroke(T.Stroke) })
	local items = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = box,
	}, { List(0), Pad(2, 0, 2, 0) })
	Create("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = wrap })

	local c = NewContainer(self.Window, items, 3, { Tab = self, Frame = wrap })
	c.Box = box
	table.insert(self._groups, c)
	if self.Window.ActiveTab == self then
		self._empty.Visible = false
	end
	return c
end

function Window:_Filter(q)
	q = (q or ""):lower()
	local tab = self.ActiveTab
	if not tab then
		return
	end
	local any = {}
	for _, e in ipairs(self._elements) do
		if e.Container.Tab == tab and e.Row then
			local show = q == "" or e.Name:find(q, 1, true) ~= nil
			e.Row.Visible = show
			if show then
				any[e.Container] = true
			end
		end
	end
	for _, g in ipairs(tab._groups) do
		g.Frame.Visible = q == "" or any[g] == true
	end
end

local function ClearChildren(holder)
	for _, c in ipairs(holder:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function EditorRow(items, order, icon, text, z)
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = z,
		Parent = items,
	})
	Icon(icon, row, 16, T.SubText, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		ZIndex = z + 1,
	})
	Label({
		Text = text,
		TextSize = 13,
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(0, 100, 1, 0),
		ZIndex = z + 1,
		Parent = row,
	})
	return row
end

local function DecorateSubRow(elemRow, icon, z)
	local lbl = elemRow:FindFirstChildWhichIsA("TextLabel")
	if lbl then
		lbl.Position = UDim2.fromOffset(42, 0)
		lbl.TextSize = 13
	end
	Icon(icon, elemRow, 16, T.SubText, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		ZIndex = z + 1,
	})
end

function Window:_OpenElementMenu(elem, anchor, o, dotsIcon)
	local win = self
	local M = win._elemMenu
	if M and M.Elem == elem then
		if IsOpen(win, M.Frame) then
			CloseFrom(win, 1)
			return
		end
		if JustClosed(win, M.Frame) then
			return
		end
	end

	if not M then
		local left, leftItems = PopupFrame(win, 210, nil, 100)
		local right, rightItems = PopupFrame(win, 280, nil, 120)
		M = { Frame = left, Items = leftItems, Right = right, RightItems = rightItems }
		win._elemMenu = M
	end
	M.Elem = elem
	M.Options = o

	local OpenEditor, OpenAll, OpenSettings, BuildLeft

	function OpenEditor(hk, rowAnchor)
		ClearChildren(M.RightItems)
		local items = M.RightItems
		local z = 122

		local cap = Label({
			Text = ((elem.Name or "Hotkey") .. " · HOTKEY"):upper(),
			TextSize = 11,
			TextColor3 = T.Caps,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = 0,
			ZIndex = z,
			Parent = items,
		})
		Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = cap })

		do
			local row = EditorRow(items, 1, "keyboard", "Key", z)
			local chip = Create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(0, 26),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = T.Field,
				AutoButtonColor = false,
				Text = hk.Key and KeyName(hk.Key) or "-",
				FontFace = F.Medium,
				TextSize = 12,
				TextColor3 = T.SubText,
				ZIndex = z + 1,
				Parent = row,
			}, { Corner(7), Stroke(T.Stroke), Pad(0, 12, 0, 12) })
			chip.Activated:Connect(function()
				chip.Text = "Press a key..."
				chip.TextColor3 = T.Accent
				win._listeningHotkey = {
					Hotkey = hk,
					Done = function()
						if chip.Parent then
							chip.Text = hk.Key and KeyName(hk.Key) or "-"
							chip.TextColor3 = T.SubText
						end
						BuildLeft()
						elem:_PaintHint()
					end,
				}
			end)
		end

		do
			local row = EditorRow(items, 2, "toggle-left", "Mode", z)
			local seg = Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(168, 26),
				BackgroundColor3 = T.Field,
				ZIndex = z + 1,
				Parent = row,
			}, { Corner(8), Stroke(T.Stroke) })
			local pill = Create("Frame", {
				Size = UDim2.new(1 / 3, -4, 1, -4),
				Position = UDim2.fromOffset(2, 2),
				BackgroundColor3 = T.Accent,
				ZIndex = z + 2,
				Parent = seg,
			}, { Corner(6) })
			local modes = { "Toggle", "Hold", "Always" }
			local btns = {}
			local function PaintSeg(animate)
				local i = table.find(modes, hk.Mode) or 1
				local target = UDim2.new((i - 1) / 3, 2, 0, 2)
				if animate then
					Tween(pill, { Position = target }, 0.22)
				else
					pill.Position = target
				end
				for j, b in ipairs(btns) do
					b.TextColor3 = j == i and Color3.new(1, 1, 1) or T.SubText
				end
			end
			for i, m in ipairs(modes) do
				local b = Create("TextButton", {
					Position = UDim2.fromScale((i - 1) / 3, 0),
					Size = UDim2.fromScale(1 / 3, 1),
					BackgroundTransparency = 1,
					Text = m,
					FontFace = F.Medium,
					TextSize = 12,
					TextColor3 = T.SubText,
					ZIndex = z + 3,
					Parent = seg,
				})
				b.Activated:Connect(function()
					hk:SetMode(m)
					PaintSeg(true)
					BuildLeft()
				end)
				btns[i] = b
			end
			PaintSeg(false)
		end

		do
			local valueHolder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				ZIndex = z,
				Parent = items,
			}, { List(0) })
			local sub = NewContainer(win, valueHolder, z, { NoRegister = true, NoMenu = true, Level = 2 })
			local made
			if elem.Type == "Toggle" then
				made = sub:AddToggle({
					Name = "Value",
					Default = hk.Value,
					Bindable = false,
					Callback = function(v)
						hk:SetValue(v)
						BuildLeft()
					end,
				})
			elseif elem.Type == "Slider" then
				made = sub:AddSlider({
					Name = "Value",
					Min = elem.Min,
					Max = elem.Max,
					Increment = elem.Increment,
					Suffix = elem.Suffix,
					Default = hk.Value,
					TrackWidth = 80,
					Bindable = false,
					Callback = function(v)
						hk:SetValue(v)
						BuildLeft()
					end,
				})
			elseif elem.Type == "Dropdown" then
				made = sub:AddDropdown({
					Name = "Value",
					Options = elem.Options,
					Multi = elem.Multi,
					Default = CopyValue(hk.Value),
					Bindable = false,
					Callback = function(v)
						hk:SetValue(v)
						BuildLeft()
					end,
				})
			end
			if made and made._row then
				DecorateSubRow(made._row, "link", z)
			end
		end

		do
			local row = EditorRow(items, 4, "eye", "Visible", z)
			local holder = Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(34, 20),
				BackgroundTransparency = 1,
				ZIndex = z + 1,
				Parent = row,
			})
			local sw, Paint = Switch(holder, z + 1, true)
			Paint(hk.Visible, false)
			local b = Create("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = z + 4,
				Parent = sw,
			})
			b.Activated:Connect(function()
				hk.Visible = not hk.Visible
				Paint(hk.Visible, true)
				win:_RefreshHotkeys()
			end)
		end

		MenuDivider(items, z).LayoutOrder = 5

		MenuRow(items, {
			Text = "Delete",
			Icon = "trash",
			IconColor = T.Danger,
			Color = T.Danger,
			Z = z,
			Order = 6,
			Callback = function()
				hk:Destroy()
				elem:_PaintHint()
				CloseFrom(win, 2)
				BuildLeft()
			end,
		})

		PlaceNear(win, M.Right, rowAnchor, 280, "right")
		OpenLayer(win, 2, M.Right)
	end

	function OpenAll(rowAnchor)
		ClearChildren(M.RightItems)
		local items = M.RightItems
		local cap = Label({
			Text = "ALL HOTKEYS",
			TextSize = 11,
			TextColor3 = T.Caps,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = 0,
			ZIndex = 122,
			Parent = items,
		})
		Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = cap })
		if #win._hotkeys == 0 then
			local l = Label({
				Text = "No hotkeys yet",
				TextSize = 13,
				TextColor3 = T.SubText,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = 1,
				ZIndex = 122,
				Parent = items,
			})
			Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = l })
		end
		for i, hk in ipairs(win._hotkeys) do
			MenuRow(items, {
				Text = (hk.Elem.Name or "?"),
				Right = (hk.Key and KeyName(hk.Key) or "-") .. " · " .. hk.Mode:lower(),
				Icon = hk.Active and "toggle-right" or "toggle-left",
				IconColor = hk.Active and T.Accent or T.SubText,
				Z = 122,
				Order = i,
			})
		end
		PlaceNear(win, M.Right, rowAnchor, 280, "right")
		OpenLayer(win, 2, M.Right)
	end

	function OpenSettings(rowAnchor)
		ClearChildren(M.RightItems)
		local items = M.RightItems
		local cap = Label({
			Text = ((o.Name or "") .. " · SETTINGS"):upper(),
			TextSize = 11,
			TextColor3 = T.Caps,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = -1,
			ZIndex = 122,
			Parent = items,
		})
		Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = cap })
		local holder = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = 122,
			Parent = items,
		}, { List(0) })
		local sub = NewContainer(win, holder, 122, { NoMenu = true, Level = 2 })
		SafeCall(elem.Settings, sub)
		PlaceNear(win, M.Right, rowAnchor, 280, "right")
		OpenLayer(win, 2, M.Right)
	end

	function BuildLeft()
		ClearChildren(M.Items)
		local items = M.Items
		local n = 0
		local function Next()
			n += 1
			return n
		end
		if type(elem.Settings) == "function" then
			MenuRow(items, {
				Text = "Settings",
				Icon = "sliders",
				Chevron = true,
				Order = Next(),
				Callback = function(row)
					OpenSettings(row)
				end,
			})
			MenuDivider(items).LayoutOrder = Next()
		end
		if #elem.Hotkeys == 0 then
			MenuRow(items, {
				Text = "Unbound",
				Icon = "keyboard",
				Chevron = true,
				Order = Next(),
				Callback = function(row)
					local hk = Hotkey.new(win, elem)
					BuildLeft()
					OpenEditor(hk, row)
				end,
			})
		end
		for _, hk in ipairs(elem.Hotkeys) do
			MenuRow(items, {
				Text = hk.Key and KeyName(hk.Key) or "Unbound",
				Right = hk:Describe(),
				Icon = "keyboard",
				IconColor = hk.Active and T.Accent or T.SubText,
				Chevron = true,
				Order = Next(),
				Callback = function(row)
					OpenEditor(hk, row)
				end,
			})
		end
		MenuRow(items, {
			Text = "All Hotkeys",
			Icon = "list",
			Chevron = true,
			Order = Next(),
			Callback = function(row)
				OpenAll(row)
			end,
		})
		MenuRow(items, {
			Text = "New Hotkey",
			Icon = "plus",
			Color = T.SubText,
			Order = Next(),
			Callback = function(row)
				local hk = Hotkey.new(win, elem)
				BuildLeft()
				OpenEditor(hk, row)
			end,
		})
		MenuDivider(items).LayoutOrder = Next()
		MenuRow(items, {
			Text = "Reset",
			Icon = "rotate-ccw",
			IconColor = T.Danger,
			Color = T.Danger,
			Order = Next(),
			Callback = function()
				for i = #elem.Hotkeys, 1, -1 do
					elem.Hotkeys[i]:Destroy()
				end
				elem:Reset()
				elem:_PaintHint()
				CloseFrom(win, 1)
				win:Notify({ Title = elem.Name or "Reset", Text = "Value and hotkeys reset", Icon = "rotate-ccw" })
			end,
		})
	end

	BuildLeft()
	PlaceNear(win, M.Frame, anchor, 210, "below-right")
	elem._menuOpen = true
	if dotsIcon then
		dotsIcon.ImageColor3 = T.Text
	end
	OpenLayer(win, 1, M.Frame, function()
		elem._menuOpen = false
		if dotsIcon then
			Tween(dotsIcon, { ImageColor3 = T.SubText }, 0.22)
		end
	end)
end

function Window:_SetupHotkeyInput()
	table.insert(self._conns, UserInputService.InputBegan:Connect(function(i)
		local listen = self._listeningHotkey
		if listen then
			local key
			if i.UserInputType == Enum.UserInputType.Keyboard then
				if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then
					key = false
				else
					key = i.KeyCode
				end
			elseif i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then
				key = i.UserInputType
			end
			if key ~= nil then
				listen.Hotkey:SetKey(key or nil)
				task.defer(function()
					self._listeningHotkey = nil
				end)
				SafeCall(listen.Done)
			end
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		for _, hk in ipairs(self._hotkeys) do
			if hk.Key and (i.KeyCode == hk.Key or i.UserInputType == hk.Key) then
				if hk.Mode == "Toggle" then
					hk:SetActive(not hk.Active)
				elseif hk.Mode == "Hold" then
					hk:SetActive(true)
				end
			end
		end
	end))
	table.insert(self._conns, UserInputService.InputEnded:Connect(function(i)
		for _, hk in ipairs(self._hotkeys) do
			if hk.Key and hk.Mode == "Hold" and (i.KeyCode == hk.Key or i.UserInputType == hk.Key) then
				hk:SetActive(false)
			end
		end
	end))
end

local SCALE_OPTIONS = { "Auto", "75%", "100%", "125%", "150%", "175%", "200%" }

function Window:_ToggleProfileMenu()
	local win = self
	if win._profile and IsOpen(win, win._profile.Frame) then
		CloseFrom(win, 1)
		return
	end
	if win._profile and JustClosed(win, win._profile.Frame) then
		return
	end

	if not win._profile then
		local frame = Create("CanvasGroup", {
			Size = UDim2.fromOffset(270, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 100,
			Parent = win.Overlay,
		}, { Pad(1, 1, 1, 1) })
		local card = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = T.Popup,
			ZIndex = 100,
			Parent = frame,
		}, { Corner(14), Stroke(T.Stroke) })
		FollowShadow(frame, win.Overlay, 14, 7, 0.16, 99)
		local items = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 101,
			Parent = card,
		}, { List(0, nil, Enum.HorizontalAlignment.Center), Pad(8, 0, 8, 0) })
		local sub, subItems = PopupFrame(win, 170, nil, 120)
		win._profile = { Frame = frame, Items = items, Sub = sub, SubItems = subItems }
	end
	local P = win._profile

	local Build

	local function OpenChoices(row, options, current, onPick, swatches)
		ClearChildren(P.SubItems)
		for i, opt in ipairs(options) do
			local name = swatches and opt[1] or opt
			local on = name == current
			local r = MenuRow(P.SubItems, {
				Text = name,
				Color = on and T.Text or T.SubText,
				Selected = on,
				Z = 122,
				Order = i,
				Callback = function()
					onPick(opt)
					CloseFrom(win, 2)
					Build()
				end,
			})
			if swatches then
				Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = opt[2],
					ZIndex = 124,
					Parent = r,
				}, { Corner(4) })
			elseif on then
				Icon("check", r, 14, T.Accent, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					ZIndex = 124,
				})
			end
		end
		PlaceNear(win, P.Sub, row, 170, "right")
		OpenLayer(win, 2, P.Sub)
	end

	function Build()
		ClearChildren(P.Items)
		local items = P.Items

		local head = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 62),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = 102,
			Parent = items,
		})
		local av = Create("ImageLabel", {
			Position = UDim2.fromOffset(14, 8),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = T.Field,
			Image = win._avatarImage or "",
			ZIndex = 103,
			Parent = head,
		}, { Round() })
		win._profileAvatar = av
		Label({
			Text = LocalPlayer.Name,
			FontFace = F.Bold,
			TextSize = 14,
			Position = UDim2.fromOffset(68, 8),
			Size = UDim2.new(1, -80, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 103,
			Parent = head,
		})
		Label({
			Text = "Till: " .. win.SubText,
			TextSize = 12,
			TextColor3 = T.SubText,
			Position = UDim2.fromOffset(68, 26),
			Size = UDim2.new(1, -80, 0, 14),
			ZIndex = 103,
			Parent = head,
		})
		local renew = Create("TextButton", {
			Position = UDim2.fromOffset(68, 42),
			Size = UDim2.fromOffset(0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = "Renew",
			FontFace = F.Medium,
			TextSize = 12,
			TextColor3 = T.Accent,
			ZIndex = 103,
			Parent = head,
		})
		renew.Activated:Connect(function()
			win:Notify({ Title = "Subscription", Text = "Your license: " .. win.SubText, Icon = "crown" })
		end)

		MenuDivider(items).LayoutOrder = 2

		local s = UI.Settings
		local order = 2
		local function Choice(icon, text, value, options, onPick)
			order += 1
			MenuRow(items, {
				Text = text,
				Right = value,
				Icon = icon,
				Chevron = true,
				Order = order,
				Callback = function(row)
					OpenChoices(row, options, value, onPick)
				end,
			})
		end

		Choice("languages", "Language", s.Language, { "English" }, function(v)
			s.Language = v
		end)
		Choice("scale", "Menu Scale", s.MenuScale, SCALE_OPTIONS, function(v)
			s.MenuScale = v
			win:_ApplyScale()
		end)
		Choice("focus", "ESP Scale", s.ESPScale, { "75%", "100%", "125%", "150%", "175%", "200%" }, function(v)
			s.ESPScale = v
			SafeCall(win.OnSetting, "ESPScale", v)
		end)
		Choice("monitor", "Windows Scale", s.WindowsScale, SCALE_OPTIONS, function(v)
			s.WindowsScale = v
			win:_ApplyScale()
		end)
		Choice("ruler", "Units", s.Units, { "Auto", "Studs", "Meters", "Feet" }, function(v)
			s.Units = v
			SafeCall(win.OnSetting, "Units", v)
		end)

		order += 1
		local keyRow, _, keyLbl = MenuRow(items, {
			Text = "Menu Key",
			Right = KeyName(win.ToggleKey),
			Icon = "keyboard",
			Order = order,
		})
		keyRow.Activated:Connect(function()
			keyLbl.Text = "Press a key..."
			Tween(keyLbl, { TextColor3 = T.Accent }, 0.2)
			win._listeningMenuKey = function()
				if keyLbl.Parent then
					keyLbl.Text = KeyName(win.ToggleKey)
					Tween(keyLbl, { TextColor3 = T.SubText }, 0.2)
				end
			end
		end)


		order += 1
		MenuDivider(items).LayoutOrder = order

		Choice("shield", "Safe Mode", s.SafeMode, { "Automatic", "Enabled", "Disabled" }, function(v)
			s.SafeMode = v
		end)

		order += 1
		local syncRow = MenuRow(items, {
			Text = "Synchronization",
			Icon = "refresh-cw",
			Order = order,
		})
		local holder = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(34, 20),
			BackgroundTransparency = 1,
			ZIndex = 104,
			Parent = syncRow,
		})
		local _, PaintSync = Switch(holder, 104, true)
		PaintSync(s.Sync, false)
		syncRow.Activated:Connect(function()
			s.Sync = not s.Sync
			PaintSync(s.Sync, true)
		end)

		order += 1
		MenuDivider(items).LayoutOrder = order

		order += 1
		MenuRow(items, {
			Text = "About",
			Icon = "info",
			Order = order,
			Callback = function()
				win:Notify({ Title = win.Brand, Icon = "info" })
			end,
		})
		order += 1
		MenuRow(items, {
			Text = "Chat",
			Icon = "message",
			Order = order,
			Callback = function()
				win:Notify({ Title = "Chat", Text = "Coming soon", Icon = "message" })
			end,
		})
	end

	Build()
	local cardPos = win._profileCard.AbsolutePosition
	P.Frame.Position = UDim2.fromOffset(cardPos.X, cardPos.Y)
	OpenLayer(win, 1, P.Frame)
	task.defer(function()
		local h = P.Frame.AbsoluteSize.Y
		AnimateIn(P.Frame, cardPos.X, math.max(cardPos.Y - h - 8, 6))
	end)
end

function Window:SaveConfig(name)
	local data = { Flags = {}, Hotkeys = {} }
	for flag, obj in pairs(UI.Flags) do
		local v = obj.Base
		if v == nil then
			v = obj.Value
		end
		if typeof(v) == "Color3" then
			data.Flags[flag] = { C = v:ToHex() }
		elseif typeof(v) == "EnumItem" then
			data.Flags[flag] = { K = v.Name }
		elseif type(v) == "table" then
			data.Flags[flag] = { L = v }
		elseif v ~= nil then
			data.Flags[flag] = v
		end
	end
	for flag, obj in pairs(UI.Flags) do
		if obj.Hotkeys then
			for _, hk in ipairs(obj.Hotkeys) do
				table.insert(data.Hotkeys, {
					Flag = flag,
					Key = hk.Key and hk.Key.Name or nil,
					KeyType = hk.Key and tostring(hk.Key.EnumType) or nil,
					Mode = hk.Mode,
					Value = hk.Value,
					Visible = hk.Visible,
				})
			end
		end
	end
	local raw = HttpService:JSONEncode(data)
	if name then
		UI.Configs[name] = raw
	end
	return raw
end

function Window:LoadConfig(name, raw)
	raw = raw or UI.Configs[name]
	if not raw then
		return false
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then
		return false
	end
	for i = #self._hotkeys, 1, -1 do
		self._hotkeys[i]:Destroy()
	end
	for flag, v in pairs(data.Flags or {}) do
		local obj = UI.Flags[flag]
		if obj and obj.Set then
			if type(v) == "table" and v.C then
				pcall(function()
					obj:Set(Color3.fromHex(v.C))
				end)
			elseif type(v) == "table" and v.K then
				pcall(function()
					obj:Set(Enum.KeyCode[v.K])
				end)
			elseif type(v) == "table" and v.L then
				obj:Set(v.L)
			else
				obj:Set(v)
			end
		end
	end
	for _, h in ipairs(data.Hotkeys or {}) do
		local obj = UI.Flags[h.Flag]
		if obj and obj.Hotkeys then
			local hk = Hotkey.new(self, obj)
			if h.Key then
				pcall(function()
					if h.KeyType == "UserInputType" then
						hk.Key = Enum.UserInputType[h.Key]
					else
						hk.Key = Enum.KeyCode[h.Key]
					end
				end)
			end
			hk.Value = h.Value
			hk.Visible = h.Visible ~= false
			hk:SetMode(h.Mode or "Toggle")
			obj:_PaintHint()
		end
	end
	self:_RefreshHotkeys()
	return true
end

function Window:ConfigNames()
	local t = {}
	for n in pairs(UI.Configs) do
		table.insert(t, n)
	end
	table.sort(t)
	return t
end

function Window:_ShowExport(raw)
	if not self._export then
		local f = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(420, 260),
			BackgroundColor3 = T.Popup,
			Visible = false,
			ZIndex = 200,
			Parent = self.Overlay,
		}, { Corner(14), Stroke(T.Stroke) })
		FollowShadow(f, self.Overlay, 14, 7, 0.2, 199)
		Label({
			Text = "EXPORT / IMPORT CONFIG",
			TextSize = 11,
			TextColor3 = T.Caps,
			Position = UDim2.fromOffset(16, 10),
			Size = UDim2.new(1, -60, 0, 20),
			ZIndex = 201,
			Parent = f,
		})
		local close = Create("ImageButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			Image = "",
			ZIndex = 201,
			Parent = f,
		})
		Icon("x", close, 16, T.SubText, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 202,
		})
		local box = Create("TextBox", {
			Position = UDim2.fromOffset(14, 38),
			Size = UDim2.new(1, -28, 1, -96),
			BackgroundColor3 = T.Field,
			Text = "",
			FontFace = F.Mono,
			TextSize = 11,
			TextColor3 = T.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			ClearTextOnFocus = false,
			MultiLine = true,
			ZIndex = 201,
			Parent = f,
		}, { Corner(8), Stroke(T.Stroke), Pad(8, 8, 8, 8) })
		local import = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -14, 1, -14),
			Size = UDim2.fromOffset(110, 32),
			BackgroundColor3 = T.Accent,
			AutoButtonColor = false,
			Text = "Import",
			FontFace = F.Bold,
			TextSize = 13,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 201,
			Parent = f,
		}, { Corner(8) })
		OnAccent(function(c)
			import.BackgroundColor3 = c
		end)
		close.Activated:Connect(function()
			f.Visible = false
		end)
		import.Activated:Connect(function()
			if self:LoadConfig(nil, box.Text) then
				self:Notify({ Title = "Config", Text = "Imported", Icon = "download" })
				f.Visible = false
			else
				self:Notify({ Title = "Config", Text = "Invalid config text", Icon = "x" })
			end
		end)
		self._export = { Frame = f, Box = box }
	end
	self._export.Box.Text = raw or ""
	self._export.Frame.Visible = true
end

local EASE = Enum.EasingStyle.Quint
local ROW_W = 236
local LOG_W = 360

local function EscText(v)
	local r = tostring(v):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return r
end

function Window:_HudDrag(handle, target, onClick, onDragged)
	local pressing, moved, startMouse, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			pressing = true
			moved = false
			startMouse = Mouse()
			startPos = target.AbsolutePosition
		end
	end)
	table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
		if not pressing then
			return
		end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local d = Mouse() - startMouse
		if not moved and d.Magnitude < 4 then
			return
		end
		if not moved then
			moved = true
			SafeCall(onDragged)
		end
		local scr, s = self.Gui.AbsoluteSize, target.AbsoluteSize
		local x = math.clamp(startPos.X + d.X, 0, math.max(scr.X - s.X, 0))
		local y = math.clamp(startPos.Y + d.Y, 0, math.max(scr.Y - s.Y, 0))
		target.Position = UDim2.fromOffset(x, y)
	end))
	table.insert(self._conns, UserInputService.InputEnded:Connect(function(i)
		if pressing and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			pressing = false
			if not moved then
				SafeCall(onClick)
			end
		end
	end))
end

function Window:_Pill(withBody)
	local wrap = Create("CanvasGroup", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		GroupTransparency = 0,
		ZIndex = 3,
		Parent = self.Gui,
	}, { Pad(1, 1, 1, 1) })
	table.insert(self._hudScales, Create("UIScale", { Parent = wrap }))
	local _, _, shadowCorners = FollowShadow(wrap, self.Gui, 23, 3, 0.5, 1, 2)

	local pill = Create("Frame", {
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = withBody and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Pill,
		ClipsDescendants = withBody and true or false,
		ZIndex = 3,
		Parent = wrap,
	}, { Stroke(T.PillLine), List(0) })
	local corner = Create("UICorner", { CornerRadius = UDim.new(0, 22), Parent = pill })
	local wrapScale = wrap:FindFirstChildOfClass("UIScale")
	local function FitWrap()
		local sc = math.max(wrapScale and wrapScale.Scale or 1, 0.01)
		local a = pill.AbsoluteSize
		wrap.Size = UDim2.fromOffset(math.ceil(a.X / sc) + 2, math.ceil(a.Y / sc) + 2)
	end
	pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitWrap)
	if wrapScale then
		wrapScale:GetPropertyChangedSignal("Scale"):Connect(FitWrap)
	end
	task.defer(FitWrap)

	local head = Create("TextButton", {
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = 1,
		ZIndex = 4,
		Parent = pill,
	}, { Pad(0, 18, 0, 18) })
	local inner = Create("Frame", {
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = head,
	}, { List(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })

	local body, bodyPad
	if withBody then
		bodyPad = Pad(0, 14, 0, 14)
		body = Create("Frame", {
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = 4,
			Parent = pill,
		}, { List(0), bodyPad })
	end

	head.MouseEnter:Connect(function()
		Tween(pill, { BackgroundColor3 = Color3.fromRGB(27, 28, 32) }, 0.25, EASE)
	end)
	head.MouseLeave:Connect(function()
		Tween(pill, { BackgroundColor3 = T.Pill }, 0.25, EASE)
	end)
	return {
		Wrap = wrap,
		Pill = pill,
		Inner = inner,
		Head = head,
		Body = body,
		Corner = corner,
		BodyPad = bodyPad,
		ShadowCorners = shadowCorners,
	}
end

local function PillSep(parent, order)
	return Create("Frame", {
		Size = UDim2.fromOffset(1, 18),
		BackgroundColor3 = Color3.fromRGB(54, 55, 62),
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 5,
		Parent = parent,
	})
end

local function PillSepNotify(parent, order)
	return Create("Frame", {
		Size = UDim2.fromOffset(1, 16),
		BackgroundColor3 = Color3.fromRGB(54, 55, 62),
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 9,
		Parent = parent,
	})
end

local function PillText(parent, text, order, bold)
	return Label({
		Text = text,
		FontFace = bold and F.Bold or F.Medium,
		TextSize = 14,
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = order,
		ZIndex = 5,
		Parent = parent,
	})
end

local function NewHudRow(body, item, order, rowW)
	local row = Create("CanvasGroup", {
		Size = UDim2.fromOffset(rowW, 0),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		LayoutOrder = order,
		ZIndex = 6,
		Parent = body,
	})
	local hasRight = item.Right ~= nil
	local left = Label({
		Text = item.Left,
		RichText = true,
		TextSize = 13,
		Position = UDim2.fromOffset(-10, 0),
		Size = UDim2.fromOffset(hasRight and rowW - 110 or rowW, 28),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		Parent = row,
	})
	local right = Label({
		Text = item.Right or "",
		TextSize = 12,
		TextColor3 = item.RightColor or T.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(rowW - 100, 0),
		Size = UDim2.fromOffset(110, 28),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = hasRight,
		ZIndex = 7,
		Parent = row,
	})
	Tween(row, { Size = UDim2.fromOffset(rowW, 28), GroupTransparency = 0 }, 0.45, EASE)
	Tween(left, { Position = UDim2.fromOffset(0, 0) }, 0.55, EASE)
	Tween(right, { Position = UDim2.fromOffset(rowW - 110, 0) }, 0.55, EASE)
	return { Frame = row, Left = left, Right = right }
end

function Window:_PillList(w, rowW)
	local win = self
	rowW = rowW or ROW_W
	local pill, body, corner, bodyPad, head, wrap = w.Pill, w.Body, w.Corner, w.BodyPad, w.Head, w.Wrap
	local P = { Rows = {}, Items = {}, Enabled = true, Expanded = false, Shown = true, _token = 0, Wrap = wrap }
	local uiScale = wrap:FindFirstChildOfClass("UIScale")

	local function TargetWidth()
		local sc = uiScale and uiScale.Scale or 1
		local headW = head.AbsoluteSize.X / math.max(sc, 0.01)
		if P.Expanded then
			return math.max(headW, rowW + 28)
		end
		return headW
	end
	local function FitWidth(animate)
		local wd = TargetWidth()
		if animate then
			Tween(pill, { Size = UDim2.fromOffset(wd, 0) }, 0.45, EASE)
		else
			pill.Size = UDim2.fromOffset(wd, 0)
		end
	end
	head:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		FitWidth(false)
	end)
	task.defer(FitWidth, false)

	local divider = Create("Frame", {
		Size = UDim2.fromOffset(rowW, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		ZIndex = 5,
		Parent = body,
	})
	local line = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.PillLine,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = divider,
	})

	local function SetExpanded(on)
		if on == P.Expanded then
			return
		end
		P.Expanded = on
		Tween(corner, { CornerRadius = UDim.new(0, on and 16 or 22) }, 0.4, EASE)
		for _, sc in ipairs(w.ShadowCorners or {}) do
			Tween(sc.Corner, { CornerRadius = UDim.new(0, (on and 17 or 23) + sc.Grow) }, 0.4, EASE)
		end
		Tween(divider, { Size = UDim2.fromOffset(rowW, on and 8 or 0) }, 0.4, EASE)
		Tween(line, { BackgroundTransparency = on and 0 or 1 }, 0.4, EASE)
		Tween(bodyPad, { PaddingBottom = UDim.new(0, on and 10 or 0) }, 0.4, EASE)
		FitWidth(true)
	end

	function P:SetShown(on)
		if on == self.Shown then
			return
		end
		self.Shown = on
		self._token += 1
		local token = self._token
		if on then
			wrap.Visible = true
			Tween(wrap, { GroupTransparency = 0 }, 0.35, EASE)
		else
			Tween(wrap, { GroupTransparency = 1 }, 0.3, EASE).Completed:Connect(function()
				if self._token == token then
					wrap.Visible = false
				end
			end)
		end
	end

	function P:UpdateShown()
		self:SetShown(self.Visible ~= false and (win.Visible or #self.Items > 0 or self.AlwaysOn))
	end

	local function Render()
		local show = P.Enabled and P.Items or {}
		local seen = {}
		for i, it in ipairs(show) do
			seen[it.Id] = true
			local r = P.Rows[it.Id]
			if not r then
				r = NewHudRow(body, it, i, rowW)
				P.Rows[it.Id] = r
			else
				r.Frame.LayoutOrder = i
				r.Left.Text = it.Left
				r.Right.Text = it.Right or ""
			end
			r.Right.TextColor3 = it.RightColor or T.Accent
		end
		for id, r in pairs(P.Rows) do
			if not seen[id] then
				P.Rows[id] = nil
				Tween(r.Frame, { Size = UDim2.fromOffset(rowW, 0), GroupTransparency = 1 }, 0.35, EASE).Completed:Connect(function()
					r.Frame:Destroy()
				end)
			end
		end
		SetExpanded(#show > 0)
		P:UpdateShown()
	end

	function P:Sync(items)
		self.Items = items
		Render()
	end

	function P:Toggle()
		self.Enabled = not self.Enabled
		Render()
	end

	return P
end

function Window:_BuildHud()
	local gui = self.Gui

	local hkW = self:_Pill(true)
	Icon("keyboard", hkW.Inner, 16, T.SubText, { LayoutOrder = 1, ZIndex = 5 })
	PillSep(hkW.Inner, 2)
	PillText(hkW.Inner, "Hotkeys", 3, true)

	local wmW = self:_Pill(false)
	self._wmLogo = PillText(wmW.Inner, self.Logo, 1, true)
	self._wmLogo.FontFace = F.Logo
	self._wmLogo.TextSize = 18
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.4, Parent = self._wmLogo })
	local clockI = Icon("clock", wmW.Inner, 16, T.Accent, { LayoutOrder = 2, ZIndex = 5 })
	local timeL = PillText(wmW.Inner, os.date("%H:%M"), 3)
	local userI = Icon("user", wmW.Inner, 16, T.Accent, { LayoutOrder = 4, ZIndex = 5 })
	PillText(wmW.Inner, LocalPlayer.Name, 5)
	local folderI = Icon("folder", wmW.Inner, 16, T.Accent, { LayoutOrder = 6, ZIndex = 5 })
	self._wmCfg = PillText(wmW.Inner, self.Config, 7)

	local spW = self:_Pill(true)
	local eyeI = Icon("eye", spW.Inner, 16, T.Accent, { LayoutOrder = 1, ZIndex = 5 })
	PillText(spW.Inner, "Spectators", 2, true)

	local kW = self:_Pill(false)
	local skullI = Icon("skull", kW.Inner, 16, T.Accent, { LayoutOrder = 1, ZIndex = 5 })
	PillSep(kW.Inner, 2)
	PillText(kW.Inner, "Kill List", 3, true)

	local mW = self:_Pill(false)
	Icon("x", mW.Inner, 16, T.Warning, { LayoutOrder = 1, ZIndex = 5 })
	PillSep(mW.Inner, 2)
	PillText(mW.Inner, "Miss List", 3, true)

	OnAccent(function(c)
		clockI.ImageColor3 = c
		userI.ImageColor3 = c
		folderI.ImageColor3 = c
		eyeI.ImageColor3 = c
		skullI.ImageColor3 = c
	end)

	task.spawn(function()
		while gui.Parent do
			timeL.Text = os.date("%H:%M")
			task.wait(1)
		end
	end)

	self._hkList = self:_PillList(hkW, ROW_W)
	self._spList = self:_PillList(spW, ROW_W)
	self._killList = self:_LogAnchor(kW)
	self._missList = self:_LogAnchor(mW)
	self._wmWidget = wmW
	self._widgets = {
		Hotkeys = { W = hkW, List = self._hkList },
		Watermark = { W = wmW },
		Spectators = { W = spW, List = self._spList },
		Kills = { W = kW, List = self._killList },
		Misses = { W = mW, List = self._missList },
	}

	local dragged = {}
	local function Layout()
		local x = 24
		for _, w in ipairs({ hkW, wmW, spW }) do
			if not dragged[w] then
				w.Wrap.Position = UDim2.fromOffset(x, 20)
			end
			x += math.max(w.Head.AbsoluteSize.X, 1) + 14
		end
		local y = math.floor(gui.AbsoluteSize.Y * 0.3)
		if not dragged[kW] then
			kW.Wrap.Position = UDim2.fromOffset(24, y)
		end
		if not dragged[mW] then
			local sc = kW.Wrap:FindFirstChildOfClass("UIScale")
			local s = sc and sc.Scale or 1
			mW.Wrap.Position = UDim2.fromOffset(24 + (LOG_W + 160) * s, y)
		end
	end
	for _, w in ipairs({ hkW, wmW, spW, kW, mW }) do
		w.Head:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout)
	end
	task.defer(Layout)

	local function Bind(w, list)
		self:_HudDrag(w.Head, w.Wrap, list and function()
			list:Toggle()
		end or nil, function()
			dragged[w] = true
		end)
	end
	Bind(hkW, self._hkList)
	Bind(wmW, nil)
	Bind(spW, self._spList)
	Bind(kW, self._killList)
	Bind(mW, self._missList)

	self._notes = Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(600, 400),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = gui,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	table.insert(self._hudScales, Create("UIScale", { Parent = self._notes }))

	self._specItems = {}
	self.LogsEnabled = true
	self.LogDuration = 6
	self.LogMax = 6
	self:_RefreshHotkeys()
	self:_RefreshSpectators()
	self._killList:UpdateShown()
	self._missList:UpdateShown()
end

function Window:_LogAnchor(w)
	local win = self
	local A = { Shown = true, _token = 0 }
	local logs = Create("Frame", {
		Size = UDim2.fromOffset(LOG_W + 120, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = self.Gui,
	}, { List(5) })
	table.insert(self._hudScales, Create("UIScale", { Parent = logs }))
	local function Follow()
		local p, sz = w.Wrap.AbsolutePosition, w.Wrap.AbsoluteSize
		logs.Position = UDim2.fromOffset(p.X, p.Y + sz.Y + 6)
	end
	w.Wrap:GetPropertyChangedSignal("AbsolutePosition"):Connect(Follow)
	w.Wrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(Follow)
	task.defer(Follow)
	A.Logs = logs

	function A:SetShown(on)
		if on == self.Shown then
			return
		end
		self.Shown = on
		self._token += 1
		local token = self._token
		if on then
			w.Wrap.Visible = true
			Tween(w.Wrap, { GroupTransparency = 0 }, 0.35, EASE)
		else
			Tween(w.Wrap, { GroupTransparency = 1 }, 0.3, EASE).Completed:Connect(function()
				if self._token == token then
					w.Wrap.Visible = false
				end
			end)
		end
	end
	function A:UpdateShown()
		self:SetShown(self.Visible ~= false and win.Visible)
	end
	function A:Toggle() end
	return A
end

function Window:_RefreshWidgets()
	for _, d in pairs(self._widgets or {}) do
		if d.List then
			d.List:UpdateShown()
		end
	end
end

function Window:SetHud(name, visible)
	local d = self._widgets and self._widgets[name]
	if not d then
		return
	end
	if d.List then
		d.List.Visible = visible
		d.List:UpdateShown()
	else
		d.W.Wrap.Visible = visible
	end
end

function Window:_SetConfig(name)
	self.Config = name
	self._cfgLbl.Text = name
	if self._wmCfg then
		self._wmCfg.Text = name
	end
end

local MODE_TEXT = { Toggle = "toggled", Hold = "holding", Always = "always" }

function Window:_RefreshHotkeys()
	if not self._hkList then
		return
	end
	local items = {}
	for _, hk in ipairs(self._hotkeys) do
		if hk.Key or hk.Active then
			table.insert(items, {
				Id = hk,
				Left = EscText(hk.Elem.Name or "?"),
				Right = (hk.Key and ("[" .. KeyName(hk.Key) .. "] ") or "") .. (hk.Active and "on" or "off"),
				RightColor = hk.Active and T.Accent or T.SubText,
			})
		end
	end
	self._hkList:Sync(items)
end

function Window:SetSpectators(items)
	self._specItems = items or {}
	self:_RefreshSpectators()
end

function Window:_RefreshSpectators()
	if self._spList then
		self._spList:Sync(self._specItems)
	end
end

function Window:HitLog(richText, kind)
	if not self.LogsEnabled or not self._killList then
		return
	end
	local holder = (kind == "miss" and self._missList or self._killList).Logs
	local colors = { hit = T.Accent, kill = T.Danger, miss = T.Warning }
	local icons = { hit = "crosshair", kill = "skull", miss = "x" }
	local c = colors[kind] or T.SubText
	local row = Create("CanvasGroup", {
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(14, 15, 17),
		BackgroundTransparency = 0.15,
		GroupTransparency = 1,
		LayoutOrder = NextOrder(),
		ZIndex = 5,
		Parent = holder,
	}, { Corner(6), Pad(0, 12, 0, 8) })
	local inner = Create("Frame", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = row,
	}, { List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })
	Create("Frame", {
		Size = UDim2.fromOffset(3, 14),
		BackgroundColor3 = c,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 7,
		Parent = inner,
	}, { Round() })
	Icon(icons[kind] or "info", inner, 13, c, { LayoutOrder = 1, ZIndex = 7 })
	Create("TextLabel", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		RichText = true,
		Text = richText,
		FontFace = F.Mono,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(225, 226, 230),
		LayoutOrder = 2,
		ZIndex = 7,
		Parent = inner,
	})
	local rows = {}
	for _, ch in ipairs(holder:GetChildren()) do
		if ch:IsA("CanvasGroup") then
			table.insert(rows, ch)
		end
	end
	table.sort(rows, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	while #rows > self.LogMax do
		table.remove(rows, 1):Destroy()
	end
	Tween(row, { GroupTransparency = 0, Size = UDim2.fromOffset(0, 26) }, 0.4, EASE)
	task.delay(self.LogDuration, function()
		if row.Parent then
			Tween(row, { GroupTransparency = 1, Size = UDim2.fromOffset(0, 0) }, 0.45, EASE).Completed:Connect(function()
				row:Destroy()
			end)
		end
	end)
end

function Window:Notify(o)
	o = o or {}
	local dur = o.Duration or 3

	local holder = Create("Frame", {
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		LayoutOrder = NextOrder(),
		ZIndex = 6,
		Parent = self._notes,
	})
	local group = Create("CanvasGroup", {
		Position = UDim2.fromOffset(60, 0),
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 6,
		Parent = holder,
	}, { Pad(2, 2, 4, 2) })
	local card = Create("Frame", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Pill,
		ZIndex = 7,
		Parent = group,
	}, { Round(), Stroke(T.PillLine), Pad(0, 18, 0, 6) })
	local row = Create("Frame", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 8,
		Parent = card,
	}, { List(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })

	local badge = Create("Frame", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.fromRGB(12, 13, 15),
		LayoutOrder = 1,
		ZIndex = 9,
		Parent = row,
	}, { Round(), Stroke(T.PillLine) })
	if self.LogoImage then
		Create("ImageLabel", { Image = self.LogoImage, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = badge }, { Round() })
	end
	Label({
		Text = self.LogoImage and "" or self.Logo,
		FontFace = F.Logo,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = badge,
	})
	PillSepNotify(row, 2)
	if o.Icon then
		Icon(o.Icon, row, 15, T.Accent, { LayoutOrder = 3, ZIndex = 9 })
	end
	Label({
		Text = o.Title or self.Brand,
		FontFace = F.Bold,
		TextSize = 13,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 4,
		ZIndex = 9,
		Parent = row,
	})
	if o.Text and o.Text ~= "" then
		Label({
			Text = o.Text,
			TextSize = 13,
			TextColor3 = T.SubText,
			Size = UDim2.fromOffset(0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 5,
			ZIndex = 9,
			Parent = row,
		})
	end

	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -1),
		Size = UDim2.new(1, -48, 0, 2),
		BackgroundColor3 = T.Accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = group,
	}, { Round() })

	local ease = Enum.EasingStyle.Quint
	Tween(holder, { Size = UDim2.fromOffset(0, 46) }, 0.35, ease)
	Tween(group, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, 0.5, ease)
	Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
	task.delay(dur, function()
		Tween(group, { Position = UDim2.fromOffset(60, 0), GroupTransparency = 1 }, 0.4, ease)
		Tween(holder, { Size = UDim2.fromOffset(0, 0) }, 0.45, ease).Completed:Connect(function()
			holder:Destroy()
		end)
	end)
end

function Window:Destroy()
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	self.Gui:Destroy()
end

local HitLogger = {}

local GUN_NAMES = { "gun", "revolver", "pistol", "sheriff" }
local KNIFE_NAMES = { "knife", "blade", "murder" }

local function ToolKind(tool)
	local n = tool.Name:lower()
	for _, g in ipairs(GUN_NAMES) do
		if n:find(g, 1, true) then
			return "Gun"
		end
	end
	for _, k in ipairs(KNIFE_NAMES) do
		if n:find(k, 1, true) then
			return "Knife"
		end
	end
	return nil
end

local function BodyRegion(part)
	if not part then
		return nil
	end
	local n = part.Name:lower()
	if n:find("head") then
		return "head"
	elseif n:find("torso") or n:find("chest") or n == "humanoidrootpart" then
		return "body"
	elseif n:find("arm") or n:find("hand") then
		return "arm"
	elseif n:find("leg") or n:find("foot") then
		return "leg"
	end
	return nil
end

local function Esc(s)
	local r = tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return r
end

local GRAY = "8d8f98"

function HitLogger.Start(win)
	local lastAction = nil
	local conns = {}

	local function WindowFor(kind)
		return kind == "Knife" and 2.5 or 1.2
	end

	local function Recent()
		local a = lastAction
		if a and os.clock() - a.Time <= WindowFor(a.Kind) then
			return a
		end
		return nil
	end

	local function OnAction(tool)
		local kind = ToolKind(tool)
		if not kind then
			return
		end
		local mouse = LocalPlayer:GetMouse()
		local target = mouse and mouse.Target
		local action = {
			Time = os.clock(),
			Kind = kind,
			Tool = tool.Name,
			TargetPart = target,
			Aimed = nil,
			Hit = false,
		}
		lastAction = action
		return action
	end

	local function WatchMiss(action)
		if action.Aimed then
			task.delay(WindowFor(action.Kind), function()
				if not action.Hit and action.Aimed.Parent then
					win:HitLog(string.format(
						'Missed shot at <font color="#%s"><b>%s</b></font> <font color="#%s">(%s)</font>',
						T.Accent:ToHex(),
						Esc(action.Aimed.DisplayName),
						GRAY,
						Esc(action.Tool)
					), "miss")
				end
			end)
		end
	end

	function HitLogger.AimbotShot(plr, toolName)
		local action = {
			Time = os.clock(),
			Kind = "Gun",
			Tool = toolName or "Gun",
			TargetPart = plr and plr.Character and plr.Character:FindFirstChild("Head"),
			Aimed = plr,
			Hit = false,
		}
		lastAction = action
		WatchMiss(action)
	end

	local function HookTool(tool)
		if tool:IsA("Tool") then
			table.insert(conns, tool.Activated:Connect(function()
				OnAction(tool)
			end))
		end
	end

	local function HookCharacter(char)
		for _, t in ipairs(char:GetChildren()) do
			HookTool(t)
		end
		table.insert(conns, char.ChildAdded:Connect(HookTool))
	end

	local function LogKill(plr, a, region, dmg)
		local hex = T.Accent:ToHex()
		win:HitLog(string.format(
			'Killed <font color="#%s"><b>%s</b></font>%s with %s <font color="#%s">(%d damage)</font>',
			hex,
			Esc(plr.DisplayName),
			region and (" in the " .. region) or "",
			Esc(a.Tool),
			GRAY,
			math.floor(dmg + 0.5)
		), "kill")
	end

	local function LogHit(plr, region, dmg, left)
		local hex = T.Accent:ToHex()
		win:HitLog(string.format(
			'Hit <font color="#%s"><b>%s</b></font>%s for <font color="#%s">%d</font> damage <font color="#%s">(%d health left)</font>',
			hex,
			Esc(plr.DisplayName),
			region and (" in the " .. region) or "",
			hex,
			math.floor(dmg + 0.5),
			GRAY,
			math.floor(left + 0.5)
		), "hit")
	end

	local function WatchPlayer(plr)
		if plr == LocalPlayer then
			return
		end
		local function OnChar(char)
			local hum = char:WaitForChild("Humanoid", 10)
			if not hum then
				return
			end
			local health = hum.Health
			local logged = false

			local function RegionFor(a)
				if a.TargetPart and a.TargetPart:IsDescendantOf(char) then
					return BodyRegion(a.TargetPart)
				end
				return nil
			end

			table.insert(conns, hum.HealthChanged:Connect(function(newHealth)
				local old = health
				health = newHealth
				local dmg = old - newHealth
				if dmg <= 0 or logged then
					return
				end
				local a = Recent()
				if not a then
					return
				end
				a.Hit = true
				if newHealth <= 0 then
					logged = true
					LogKill(plr, a, RegionFor(a), dmg)
				else
					LogHit(plr, RegionFor(a), dmg, newHealth)
				end
			end))

			table.insert(conns, hum.Died:Connect(function()
				if logged then
					return
				end
				local a = Recent()
				if a then
					a.Hit = true
					logged = true
					LogKill(plr, a, RegionFor(a), math.max(health, 0) > 0 and health or hum.MaxHealth)
				end
			end))

			table.insert(conns, char.AncestryChanged:Connect(function(_, parent)
				if parent or logged then
					return
				end
				local a = Recent()
				if a and health > 0 then
					a.Hit = true
					logged = true
					LogKill(plr, a, RegionFor(a), health)
				end
			end))
		end
		if plr.Character then
			task.spawn(OnChar, plr.Character)
		end
		table.insert(conns, plr.CharacterAdded:Connect(OnChar))
	end

	if LocalPlayer.Character then
		HookCharacter(LocalPlayer.Character)
	end
	table.insert(conns, LocalPlayer.CharacterAdded:Connect(HookCharacter))
	for _, p in ipairs(Players:GetPlayers()) do
		WatchPlayer(p)
	end
	table.insert(conns, Players.PlayerAdded:Connect(WatchPlayer))

	return function()
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
	end
end

local SpectatorTracker = {}

function SpectatorTracker.Start(win)
	local dead = {}
	local counter = 0
	local conns = {}
	local running = true

	local function Push()
		local items = {}
		for plr, order in pairs(dead) do
			if plr.Parent then
				table.insert(items, {
					Id = plr,
					Left = plr.DisplayName,
					Right = "@" .. plr.Name,
					RightColor = T.SubText,
					Order = order,
				})
			end
		end
		table.sort(items, function(a, b)
			return a.Order < b.Order
		end)
		win:SetSpectators(items)
	end

	local function Clear()
		if next(dead) then
			table.clear(dead)
			Push()
		end
	end

	local function LocalAlive()
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		return h ~= nil and h.Health > 0
	end

	local function Watch(plr)
		if plr == LocalPlayer then
			return
		end
		local function OnChar(char)
			local hum = char:WaitForChild("Humanoid", 10)
			if not hum then
				return
			end
			table.insert(conns, hum.Died:Connect(function()
				if LocalAlive() and not dead[plr] then
					counter += 1
					dead[plr] = counter
					Push()
				end
			end))
		end
		if plr.Character then
			task.spawn(OnChar, plr.Character)
		end
		table.insert(conns, plr.CharacterAdded:Connect(OnChar))
	end

	local function OnLocalChar(char)
		Clear()
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			table.insert(conns, hum.Died:Connect(Clear))
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		Watch(p)
	end
	table.insert(conns, Players.PlayerAdded:Connect(Watch))
	table.insert(conns, Players.PlayerRemoving:Connect(function(p)
		if dead[p] then
			dead[p] = nil
			Push()
		end
	end))
	if LocalPlayer.Character then
		task.spawn(OnLocalChar, LocalPlayer.Character)
	end
	table.insert(conns, LocalPlayer.CharacterAdded:Connect(OnLocalChar))

	task.spawn(function()
		local last
		while running do
			local c = LocalPlayer.Character
			local root = c and c:FindFirstChild("HumanoidRootPart")
			if root then
				local pos = root.Position
				if last and (pos - last).Magnitude > 250 then
					Clear()
				end
				last = pos
			else
				last = nil
			end
			task.wait(0.25)
		end
	end)

	return function()
		running = false
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
	end
end

UI.HitLogger = HitLogger
UI.SpectatorTracker = SpectatorTracker

return UI

        end)()
    end)
    if not okL or type(NL) ~= "table" then
        NLA = nil
    else
        local ICON_MAP = {swords = "sword", ["scan-eye"] = "eye", globe = "globe", user = "user", wrench = "settings-2",
            wind = "zap", ["person-standing"] = "ghost", ["map-pin"] = "target", settings = "settings"}
        local function PAL()
            local T0 = NL.Theme
            return {bg = T0.Group, side = T0.Panel, group = T0.Group, row = T0.Field, line = T0.Stroke, accent = T0.Accent,
                accentDim = T0.Nav, text = T0.Text, sub = T0.SubText, dim = T0.Caps, white = Color3.new(1, 1, 1)}
        end
        local function toColor(v)
            if typeof(v) == "Color3" then return v end
            local ok, c = pcall(colorOf, v)
            return (ok and typeof(c) == "Color3") and c or Color3.new(1, 1, 1)
        end
        -- the special widgets (player / map grids, chat, preview, label), drawn inside a Neverlose group
        local function customs(obj, getCont, win, tab, W)
            local C = PAL()
            local gui, main, wrap = win.Gui, win.Main, (tab and tab._page) or {Visible = true}
            local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
    local function tw(o, info, props)
        local t = TweenService:Create(o, info, props)
        t:Play()
        return t
    end
    local function rootGui(name, order)
        local g = Instance.new("ScreenGui")
        g.Name = name
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        g.DisplayOrder = order or 100
        local ok = pcall(function() g.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        return g
    end
    local function corner(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 4)
        c.Parent = o
    end
    local function stroke(o, col, th, tr)
        local st = Instance.new("UIStroke")
        st.Color = col
        st.Thickness = th or 1
        st.Transparency = tr or 0
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Parent = o
        return st
    end
    local function text(parent, str, size, col, font, xa)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = str
        l.TextSize = size
        l.TextColor3 = col
        l.Font = font or Enum.Font.GothamMedium
        l.TextXAlignment = xa or Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = parent
        return l
    end
    local function frame(parent, col, tr)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = col or C.row
        f.BackgroundTransparency = tr or 0
        f.BorderSizePixel = 0
        f.Parent = parent
        return f
    end

            local function row(h, title)
                local e = getCont():AddButton({Name = ""})
                local r = e._row
                for _, ch in ipairs(r:GetChildren()) do ch:Destroy() end
                r.Size = UDim2.new(1, 0, 0, h)
                return r
            end
            local T = obj
            function T:PlayerGrid(po)
                local f = row(10, po.Title or "players")
                f.Size = UDim2.new(1, 0, 0, 0)
                f.AutomaticSize = Enum.AutomaticSize.Y
                local holder = Instance.new("Frame")
                holder.BackgroundTransparency = 1
                holder.Position = UDim2.fromOffset(8, 4)
                holder.Size = UDim2.new(1, -16, 0, 0)
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Parent = f
                local gl = Instance.new("UIGridLayout")
                gl.CellSize = UDim2.fromOffset(58, 74)
                gl.CellPadding = UDim2.fromOffset(6, 6)
                gl.SortOrder = Enum.SortOrder.Name
                gl.Parent = holder
                local fp = Instance.new("UIPadding")
                fp.PaddingBottom = UDim.new(0, 10)
                fp.Parent = f
                local sel = po.Selected or {}
                local obj = {}
                function obj:Refresh()
                    for _, ch in ipairs(holder:GetChildren()) do
                        if ch:IsA("GuiObject") then ch:Destroy() end
                    end
                    for _, p in ipairs(po.GetPlayers()) do
                        local cell = Instance.new("TextButton")
                        cell.Name = p.Name
                        cell.Text = ""
                        cell.AutoButtonColor = false
                        cell.BackgroundColor3 = C.row
                        cell.BackgroundTransparency = 0.2
                        cell.Parent = holder
                        corner(cell, 6)
                        local on = sel[p.Name] == true
                        local st = stroke(cell, on and C.accent or C.line, on and 2 or 1)
                        local img = Instance.new("ImageLabel")
                        img.BackgroundTransparency = 1
                        img.Size = UDim2.fromOffset(44, 44)
                        img.Position = UDim2.new(0.5, -22, 0, 5)
                        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=48&h=48"
                        img.Parent = cell
                        corner(img, 22)
                        local nm = text(cell, p.DisplayName, 10, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
                        nm.Position = UDim2.new(0, 2, 0, 52)
                        nm.Size = UDim2.new(1, -4, 0, 16)
                        cell.Activated:Connect(function()
                            if po.OnClick then
                                st.Color, st.Thickness = C.accent, 2
                                task.delay(0.35, function()
                                    if st.Parent then st.Color, st.Thickness = C.line, 1 end
                                end)
                                task.spawn(po.OnClick, p)
                                return
                            end
                            sel[p.Name] = (not sel[p.Name]) or nil
                            local now = sel[p.Name] == true
                            st.Color = now and C.accent or C.line
                            st.Thickness = now and 2 or 1
                        end)
                    end
                end
                obj:Refresh()
                return obj
            end

            function T:ImageGrid(io2)
                local f = row(10, io2.Title or "maps")
                f.Size = UDim2.new(1, 0, 0, 0)
                f.AutomaticSize = Enum.AutomaticSize.Y
                local holder = Instance.new("Frame")
                holder.BackgroundTransparency = 1
                holder.Position = UDim2.fromOffset(8, 4)
                holder.Size = UDim2.new(1, -16, 0, 0)
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Parent = f
                local gl = Instance.new("UIGridLayout")
                gl.CellSize = UDim2.fromOffset(96, 78)
                gl.CellPadding = UDim2.fromOffset(6, 6)
                gl.SortOrder = Enum.SortOrder.LayoutOrder
                gl.Parent = holder
                local fp = Instance.new("UIPadding")
                fp.PaddingBottom = UDim.new(0, 10)
                fp.Parent = f
                local empty = text(f, io2.Empty or "", 11, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                empty.Position = UDim2.fromOffset(0, 4)
                empty.Size = UDim2.new(1, 0, 0, 22)
                local obj = {}
                function obj:Refresh()
                    for _, ch in ipairs(holder:GetChildren()) do
                        if ch:IsA("GuiObject") then ch:Destroy() end
                    end
                    local items = io2.GetItems() or {}
                    empty.Visible = #items == 0
                    for i, it in ipairs(items) do
                        local cell = Instance.new("TextButton")
                        cell.Text = ""
                        cell.LayoutOrder = i
                        cell.AutoButtonColor = false
                        cell.BackgroundColor3 = C.row
                        cell.BackgroundTransparency = 0.2
                        cell.ClipsDescendants = true
                        cell.Parent = holder
                        corner(cell, 6)
                        local st = stroke(cell, it.selected and C.accent or C.line, it.selected and 2 or 1)
                        if it.colors then
                            local pv = Instance.new("Frame")
                            pv.BorderSizePixel = 0
                            pv.BackgroundColor3 = Color3.new(1, 1, 1)
                            pv.Size = UDim2.new(1, 0, 0, 58)
                            pv.ClipsDescendants = true
                            pv.Parent = cell
                            local g = Instance.new("UIGradient")
                            g.Rotation = 90
                            g.Color = ColorSequence.new(it.colors[1], it.colors[2])
                            g.Parent = pv
                            if it.viewport then
                                local vpf = Instance.new("ViewportFrame")
                                vpf.BackgroundTransparency = 1
                                vpf.Size = UDim2.fromScale(1, 1)
                                vpf.Parent = pv
                                pcall(it.viewport, vpf)
                            end
                        else
                            local img = Instance.new("ImageLabel")
                            img.BackgroundTransparency = 1
                            img.Size = UDim2.new(1, 0, 0, 58)
                            img.ScaleType = Enum.ScaleType.Crop
                            img.Image = it.image or ""
                            img.Parent = cell
                        end
                        local nm = text(cell, tostring(it.label or ""), 10, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
                        nm.Position = UDim2.new(0, 2, 0, 60)
                        nm.Size = UDim2.new(1, -4, 0, 16)
                        cell.Activated:Connect(function()
                            st.Color, st.Thickness = C.accent, 2
                            task.delay(0.4, function()
                                if st.Parent then st.Color, st.Thickness = it.selected and C.accent or C.line, it.selected and 2 or 1 end
                            end)
                            if io2.OnClick then task.spawn(io2.OnClick, it) end
                        end)
                    end
                end
                obj:Refresh()
                return obj
            end

            function T:Label(lo)
                local f = row(28, lo.Title)
                local l = text(f, tostring(lo.Title or ""), 12, C.sub, Enum.Font.GothamMedium)
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -24, 1, 0)
                local obj = {}
                function obj:Set(t)
                    if l.Parent then l.Text = tostring(t) end
                end
                return obj
            end

            function T:Chat(co)
                local f = row(300, "chat")
                local note = text(f, co.Note or "", 10, C.sub, Enum.Font.Gotham)
                note.Position = UDim2.fromOffset(12, 2)
                note.Size = UDim2.new(1, -24, 0, 16)
                local box = Instance.new("ScrollingFrame")
                box.Position = UDim2.fromOffset(10, 20)
                box.Size = UDim2.new(1, -20, 0, 208)
                box.BackgroundColor3 = C.bg
                box.BackgroundTransparency = 0.2
                box.BorderSizePixel = 0
                box.ScrollBarThickness = 3
                box.CanvasSize = UDim2.new()
                box.AutomaticCanvasSize = Enum.AutomaticSize.Y
                box.Parent = f
                corner(box, 6)
                stroke(box, C.line, 1)
                local lay = Instance.new("UIListLayout")
                lay.SortOrder = Enum.SortOrder.LayoutOrder
                lay.Padding = UDim.new(0, 3)
                lay.Parent = box
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
                pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
                pad.Parent = box
                local tb = Instance.new("TextBox")
                tb.Position = UDim2.new(0, 10, 0, 256)
                tb.Size = UDim2.new(1, -96, 0, 32)
                tb.BackgroundColor3 = C.row
                tb.TextColor3 = C.text
                tb.PlaceholderText = co.Placeholder or "Message..."
                tb.PlaceholderColor3 = C.sub
                tb.Font = Enum.Font.Gotham
                tb.TextSize = 12
                tb.Text = ""
                tb.ClearTextOnFocus = false
                tb.TextXAlignment = Enum.TextXAlignment.Left
                tb.Parent = f
                corner(tb, 6)
                stroke(tb, C.line, 1)
                local tp = Instance.new("UIPadding")
                tp.PaddingLeft = UDim.new(0, 8)
                tp.Parent = tb
                local send = Instance.new("TextButton")
                send.AnchorPoint = Vector2.new(1, 0)
                send.Position = UDim2.new(1, -10, 0, 256)
                send.Size = UDim2.fromOffset(78, 32)
                send.BackgroundColor3 = C.accentDim
                send.TextColor3 = C.text
                send.Font = Enum.Font.GothamBold
                send.TextSize = 11
                send.Text = co.SendText or "SEND"
                send.AutoButtonColor = false
                send.Parent = f
                corner(send, 6)
                local count = 0
                local function esc(t)
                    return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
                end
                local obj = {}
                local FRAMES = {Gold = Color3.fromRGB(255, 200, 60), Neon = Color3.fromRGB(80, 255, 200), Ruby = Color3.fromRGB(255, 70, 110),
                    Ice = Color3.fromRGB(140, 200, 255), Violet = Color3.fromRGB(170, 110, 255)}
                local replyBar = text(f, "", 10, C.sub, Enum.Font.Gotham)
                replyBar.Position = UDim2.fromOffset(12, 232)
                replyBar.Size = UDim2.new(1, -24, 0, 18)
                replyBar.Visible = false
                FX.chatReplyShow = function(e)
                    if not replyBar.Parent then return end
                    if e then
                        replyBar.Text = "replying to " .. e.n .. ": " .. string.sub(e.t, 1, 40) .. "   (tap to cancel)"
                        replyBar.Visible = true
                    else
                        replyBar.Visible = false
                    end
                end
                local cancel = Instance.new("TextButton")
                cancel.BackgroundTransparency = 1
                cancel.Text = ""
                cancel.Size = UDim2.fromScale(1, 1)
                cancel.Parent = replyBar
                cancel.Activated:Connect(function()
                    FX.chatReply = nil
                    FX.chatReplyShow(nil)
                end)
                local obj = {}
                function obj:Add(e)
                    if not box.Parent then return end
                    count += 1
                    local fc = FRAMES[e.f]
                    local row0 = Instance.new("TextButton")
                    row0.AutoButtonColor = false
                    row0.Text = ""
                    row0.BackgroundColor3 = C.row
                    row0.BackgroundTransparency = 0.6
                    row0.Size = UDim2.new(1, 0, 0, 0)
                    row0.AutomaticSize = Enum.AutomaticSize.Y
                    row0.LayoutOrder = count
                    row0.Parent = box
                    corner(row0, 8)
                    local rp = Instance.new("UIPadding")
                    rp.PaddingLeft, rp.PaddingRight = UDim.new(0, 40), UDim.new(0, 6)
                    rp.PaddingTop, rp.PaddingBottom = UDim.new(0, 4), UDim.new(0, 5)
                    rp.Parent = row0
                    local av = Instance.new("ImageLabel")
                    av.BackgroundColor3 = C.bg
                    av.Position = UDim2.new(0, -34, 0, 0)
                    av.Size = UDim2.fromOffset(28, 28)
                    av.Image = e.id and ("rbxthumb://type=AvatarHeadShot&id=" .. e.id .. "&w=150&h=150") or ""
                    av.Parent = row0
                    corner(av, 14)
                    if fc then stroke(av, fc, 2) end
                    local col = Instance.new("Frame")
                    col.BackgroundTransparency = 1
                    col.Size = UDim2.new(1, 0, 0, 0)
                    col.AutomaticSize = Enum.AutomaticSize.Y
                    col.Parent = row0
                    local cl = Instance.new("UIListLayout")
                    cl.SortOrder = Enum.SortOrder.LayoutOrder
                    cl.Padding = UDim.new(0, 1)
                    cl.Parent = col
                    local function line(txt, size, color, font, order)
                        local l = Instance.new("TextLabel")
                        l.BackgroundTransparency = 1
                        l.Size = UDim2.new(1, 0, 0, 0)
                        l.AutomaticSize = Enum.AutomaticSize.Y
                        l.RichText = true
                        l.TextWrapped = true
                        l.TextXAlignment = Enum.TextXAlignment.Left
                        l.Font = font
                        l.TextSize = size
                        l.TextColor3 = color
                        l.Text = txt
                        l.LayoutOrder = order
                        l.Parent = col
                        return l
                    end
                    local nameHex = (fc or C.accent):ToHex()
                    line(string.format('<b><font color="#%s">%s</font></b> <font color="#%s">@%s</font>', nameHex, esc(e.n), C.sub:ToHex(), esc(e.u)), 12, C.text, Enum.Font.Gotham, 1)
                    if e.r and e.r.n ~= "" then
                        line(string.format('<i>%s: %s</i>', esc(e.r.n), esc(e.r.t)), 10, C.sub, Enum.Font.Gotham, 2)
                    end
                    line(esc(e.t), 12, C.text, Enum.Font.Gotham, 3)
                    row0.Activated:Connect(function()
                        FX.chatReply = {n = e.n, t = e.t}
                        FX.chatReplyShow(e)
                        tb:CaptureFocus()
                    end)
                    local kids = {}
                    for _, k in ipairs(box:GetChildren()) do
                        if k:IsA("TextButton") then kids[#kids + 1] = k end
                    end
                    if #kids > 80 then kids[1]:Destroy() end
                    task.defer(function()
                        if box.Parent then box.CanvasPosition = Vector2.new(0, math.max(0, box.AbsoluteCanvasSize.Y - box.AbsoluteSize.Y)) end
                    end)
                end
                local function fire()
                    local t = tb.Text
                    tb.Text = ""
                    if co.OnSend then task.spawn(co.OnSend, t) end
                end
                send.Activated:Connect(fire)
                tb.FocusLost:Connect(function(enter)
                    if enter then fire() end
                end)
                return obj
            end

            function T:Preview(po)
                local f = row(280, po.Title or "preview")
                local box = frame(f, C.bg, 0.15)
                box.Position = UDim2.fromOffset(10, 8)
                box.Size = UDim2.new(1, -20, 1, -14)
                box.ClipsDescendants = true
                corner(box, 5)
                stroke(box, C.line, 1)
                local vp = Instance.new("ViewportFrame")
                vp.BackgroundTransparency = 1
                vp.Size = UDim2.fromScale(1, 1)
                vp.Ambient = Color3.fromRGB(170, 170, 180)
                vp.LightColor = Color3.fromRGB(255, 255, 255)
                vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
                vp.Parent = box
                local vcam = Instance.new("Camera")
                vcam.FieldOfView = 40
                vcam.Parent = vp
                vp.CurrentCamera = vcam
                local wmod = Instance.new("WorldModel")
                wmod.Parent = vp
                local anim = {idle = nil, walk = nil, now = nil}
                local ov = Instance.new("Frame")
                ov.BackgroundTransparency = 1
                ov.Size = UDim2.fromScale(1, 1)
                ov.ZIndex = 3
                ov.Parent = box
                local function ln()
                    local l = frame(ov, C.white)
                    l.AnchorPoint = Vector2.new(0.5, 0.5)
                    l.ZIndex = 4
                    l.Visible = false
                    return l
                end
                local function seg(l, a, b2, col, th)
                    local d = b2 - a
                    l.Size = UDim2.fromOffset(d.Magnitude + 1, th or 1.5)
                    l.Position = UDim2.fromOffset((a.X + b2.X) / 2, (a.Y + b2.Y) / 2)
                    l.Rotation = math.deg(math.atan2(d.Y, d.X))
                    l.BackgroundColor3 = col
                    l.Visible = true
                end
                local boxL, skelL = {}, {}
                for i = 1, 4 do boxL[i] = ln() end
                for i = 1, 13 do skelL[i] = ln() end
                local nameT = text(ov, "", 14, C.white, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
                nameT.Size = UDim2.fromOffset(200, 16)
                nameT.AnchorPoint = Vector2.new(0.5, 1)
                nameT.TextStrokeTransparency = 0.1
                nameT.ZIndex = 5
                local distT = text(ov, "24m", 13, C.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
                distT.Size = UDim2.fromOffset(120, 14)
                distT.AnchorPoint = Vector2.new(0.5, 0)
                distT.TextStrokeTransparency = 0.2
                distT.ZIndex = 5
                local hpBack = frame(ov, rgb(0, 0, 0))
                hpBack.ZIndex = 4
                local hpFill = frame(hpBack, rgb(80, 220, 110))
                hpFill.AnchorPoint = Vector2.new(0, 1)
                hpFill.Position = UDim2.fromScale(0, 1)
                hpFill.Size = UDim2.fromScale(1, 0.8)
                hpFill.ZIndex = 5
                local av = Instance.new("ImageLabel")
                av.Size = UDim2.fromOffset(28, 28)
                av.AnchorPoint = Vector2.new(0.5, 1)
                av.BackgroundColor3 = C.row
                av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=48&h=48"
                av.ZIndex = 5
                av.Parent = ov
                corner(av, 14)
                local avS = stroke(av, C.accent, 1.5)

                local model, charRef, weapon, weaponKind = nil, false, nil, nil
                local orig, worig = {}, {}
                local yaw = 0
                local rot, lastX = false, 0
                box.Active = true
                box.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        rot, lastX = true, i.Position.X
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputChanged:Connect(function(i)
                    if rot and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        local dx = i.Position.X - lastX
                        lastX = i.Position.X
                        yaw += dx * 0.015
                        if model then pcall(function() model:PivotTo(CFrame.Angles(0, yaw, 0)) end) end
                    end
                end)
                W.conns[#W.conns + 1] = UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        rot = false
                    end
                end)

                local function findWeaponSource(kind)
                    local c = lp.Character
                    local src = (c and c:FindFirstChild(kind)) or lp.Backpack:FindFirstChild(kind)
                    if src and src:IsA("Tool") then return src end
                    for _, p in ipairs(Players:GetPlayers()) do
                        local t = p.Character and p.Character:FindFirstChild(kind)
                        if t and t:IsA("Tool") then return t end
                    end
                    return nil
                end

                local function buildWeapon(kind)
                    if weapon then pcall(function() weapon:Destroy() end) end
                    weapon = nil
                    table.clear(worig)
                    weaponKind = kind
                    if not kind or not model then return end
                    local hand = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
                    if not hand then return end
                    local w = Instance.new("Model")
                    w.Name = "PreviewWeapon"
                    local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
                    local src = findWeaponSource(kind)
                    local handle = src and src:FindFirstChild("Handle")
                    local placed = false
                    if handle and handle:IsA("BasePart") then
                        for _, d in ipairs(src:GetDescendants()) do
                            if d:IsA("BasePart") and d.Transparency < 1 then
                                local okc, cl = pcall(function() return d:Clone() end)
                                if okc and cl then
                                    for _, ch in ipairs(cl:GetChildren()) do
                                        if not (ch:IsA("DataModelMesh") or ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance")) then
                                            ch:Destroy()
                                        end
                                    end
                                    cl.Anchored = true
                                    cl.CFrame = grip * handle.CFrame:ToObjectSpace(d.CFrame)
                                    cl.Parent = w
                                    placed = true
                                end
                            end
                        end
                    end
                    if not placed then
                        local function pp(size, color, cf, mat)
                            local p = Instance.new("Part")
                            p.Anchored = true
                            p.Size, p.Color = size, color
                            p.Material = mat or Enum.Material.Metal
                            p.CFrame = grip * cf
                            p.Parent = w
                        end
                        if kind == "Knife" then
                            pp(Vector3.new(0.25, 0.25, 0.9), Color3.fromRGB(45, 32, 26), CFrame.new(), Enum.Material.Wood)
                            pp(Vector3.new(0.5, 0.12, 0.12), Color3.fromRGB(120, 120, 128), CFrame.new(0, 0, -0.5))
                            pp(Vector3.new(0.08, 0.36, 1.9), Color3.fromRGB(205, 210, 218), CFrame.new(0, 0.04, -1.5))
                        else
                            pp(Vector3.new(0.3, 0.8, 0.35), Color3.fromRGB(45, 45, 50), CFrame.new(0, -0.1, 0.1) * CFrame.Angles(math.rad(-15), 0, 0))
                            pp(Vector3.new(0.3, 0.38, 1.5), Color3.fromRGB(70, 72, 78), CFrame.new(0, 0.36, -0.55))
                            pp(Vector3.new(0.18, 0.18, 0.7), Color3.fromRGB(30, 30, 34), CFrame.new(0, 0.42, -1.55))
                        end
                    end
                    for _, d in ipairs(w:GetDescendants()) do
                        if d:IsA("BasePart") then worig[d] = {d.Color, d.Material} end
                    end
                    w.Parent = vp
                    weapon = w
                end

                local function buildModel()
                    if model then pcall(function() model:Destroy() end) end
                    model = nil
                    table.clear(orig)
                    local ch = lp.Character
                    charRef = ch
                    if not ch then return end
                    local okc, cl = pcall(function()
                        local old = ch.Archivable
                        ch.Archivable = true
                        local x = ch:Clone()
                        ch.Archivable = old
                        return x
                    end)
                    if not okc or not cl then return end
                    for _, d in ipairs(cl:GetChildren()) do
                        if d.Name:sub(1, 6) == "Zenith" or d:IsA("Tool") then d:Destroy() end
                    end
                    for _, d in ipairs(cl:GetDescendants()) do
                        if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui")
                           or d:IsA("Highlight") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("ForceField") then
                            d:Destroy()
                        elseif d:IsA("Humanoid") then
                            d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        elseif d:IsA("BasePart") then
                            -- only the root is pinned; the limbs hang on their joints so animations move them
                            d.Anchored = d.Name == "HumanoidRootPart"
                            d.CanCollide = false
                            d.LocalTransparencyModifier = 0
                            if d.Name == "HumanoidRootPart" then d.Transparency = 1 end
                            orig[d] = {d.Color, d.Material, d.Transparency}
                        end
                    end
                    pcall(function() cl:PivotTo(CFrame.new()) end)
                    cl.Parent = wmod
                    model = cl
                    -- idle / walk like your character (R15 or R6 default animations)
                    anim.idle, anim.walk, anim.now = nil, nil, nil
                    pcall(function()
                        local hum = cl:FindFirstChildOfClass("Humanoid")
                        if not hum then return end
                        local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
                        local r15 = hum.RigType == Enum.HumanoidRigType.R15
                        local function track(id)
                            local a = Instance.new("Animation")
                            a.AnimationId = "rbxassetid://" .. id
                            local tr = an:LoadAnimation(a)
                            tr.Looped = true
                            return tr
                        end
                        anim.idle = track(r15 and 507766388 or 180435571)
                        anim.walk = track(r15 and 507777826 or 180426354)
                    end)
                    local okb, cf, size = pcall(function() return cl:GetBoundingBox() end)
                    if okb then
                        local dist = (size.Y / 2) / math.tan(math.rad(vcam.FieldOfView / 2)) * 1.6
                        local lift = Vector3.new(0, size.Y * 0.15, 0)
                        vcam.CFrame = CFrame.lookAt(cf.Position + lift + Vector3.new(0, 0, -dist), cf.Position + lift)
                    end
                    if yaw ~= 0 then pcall(function() cl:PivotTo(CFrame.Angles(0, yaw, 0)) end) end
                end

                local function paint(p, o, on, ty, cc)
                    if on and ty == "ForceField" then
                        p.Material, p.Color = Enum.Material.ForceField, cc
                    elseif on and ty == "Neon" then
                        p.Material, p.Color = Enum.Material.Neon, cc
                    elseif on and ty ~= "Outline" then
                        p.Material, p.Color = Enum.Material.SmoothPlastic, o[1]:Lerp(cc, ty == "Chams" and 0.85 or 0.55)
                    else
                        p.Material, p.Color = o[2], o[1]
                    end
                end

                local function apply()
                    local st = po.Get and po.Get() or {}
                    if lp.Character ~= charRef or not (model and model.Parent) then pcall(buildModel) end
                    if st.weapon ~= weaponKind then pcall(buildWeapon, st.weapon) end
                    local col = st.color or C.accent
                    pcall(function()
                        for p, o in pairs(orig) do
                            if p.Parent and o[3] < 1 then paint(p, o, st.chams, st.chamsType, st.chamsColor or col) end
                        end
                        for p, o in pairs(worig) do
                            if p.Parent then paint(p, o, st.weaponEsp, st.weaponStyle, st.weaponColor or col) end
                        end
                    end)
                    -- walk while you walk, idle while you stand
                    pcall(function()
                        local mh = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                        local want = (mh and mh.MoveDirection.Magnitude > 0.1) and anim.walk or anim.idle
                        if want and anim.now ~= want then
                            if anim.now then anim.now:Stop(0.2) end
                            want:Play(0.2)
                            anim.now = want
                        end
                    end)
                    local W2, H = box.AbsoluteSize.X, box.AbsoluteSize.Y
                    local figH = H / 1.6
                    local cx, top = W2 / 2, (H - figH) / 2 + H * (0.15 / 1.6)
                    local bot = top + figH
                    local fw = figH * 0.5
                    if st.box then
                        local x1, x2 = cx - fw / 2, cx + fw / 2
                        local A = {Vector2.new(x1, top), Vector2.new(x2, top), Vector2.new(x2, bot), Vector2.new(x1, bot)}
                        for i = 1, 4 do seg(boxL[i], A[i], A[i % 4 + 1], col, 2) end
                    else
                        for _, l in ipairs(boxL) do l.Visible = false end
                    end
                    if st.skeleton then
                        local function P(x, y) return Vector2.new(cx + (x - 0.5) * fw * 1.25, top + y * figH) end
                        local J = {head = P(0.5, 0.11), neck = P(0.5, 0.21), chest = P(0.5, 0.32), pelvis = P(0.5, 0.52),
                                   ls = P(0.3, 0.25), le = P(0.22, 0.38), lh = P(0.2, 0.5), rs = P(0.7, 0.25), re = P(0.78, 0.38),
                                   rh = P(0.8, 0.5), lk = P(0.4, 0.74), lf = P(0.39, 0.97), rk = P(0.6, 0.74), rf = P(0.61, 0.97)}
                        local S = {{"head", "neck"}, {"neck", "chest"}, {"chest", "pelvis"}, {"neck", "ls"}, {"ls", "le"},
                                   {"le", "lh"}, {"neck", "rs"}, {"rs", "re"}, {"re", "rh"}, {"pelvis", "lk"}, {"lk", "lf"},
                                   {"pelvis", "rk"}, {"rk", "rf"}}
                        for i, sg2 in ipairs(S) do seg(skelL[i], J[sg2[1]], J[sg2[2]], C.white, 2) end
                    else
                        for _, l in ipairs(skelL) do l.Visible = false end
                    end
                    local y = top - 3
                    nameT.Visible = st.name == true
                    if st.name then
                        nameT.Text = lp.DisplayName
                        nameT.TextColor3 = col
                        nameT.Position = UDim2.fromOffset(cx, y)
                        y -= 18
                    end
                    av.Visible = st.avatar == true
                    if st.avatar then
                        av.Position = UDim2.fromOffset(cx, y)
                        avS.Color = col
                    end
                    distT.Visible = st.dist == true
                    if st.dist then distT.Position = UDim2.fromOffset(cx, bot + 3) end
                    hpBack.Visible = st.health == true
                    if st.health then
                        hpBack.Size = UDim2.fromOffset(4, figH)
                        hpBack.Position = UDim2.fromOffset(cx - fw / 2 - 9, top)
                    end
                end

                task.spawn(function()
                    while gui.Parent do
                        if main.Visible and wrap.Visible and box.AbsoluteSize.X > 10 then pcall(apply) end
                        task.wait(0.05)
                    end
                end)
                return {}
            end

        end
        local function attach(obj, getCont, win, tab, W)
            function obj:Toggle(o)
                local st = o.Settings
                return getCont():AddToggle({Name = o.Title, Default = o.Value and true or false, Callback = o.Callback,
                    Settings = st and function(sub)
                        local so = {_into = true}
                        attach(so, function() return sub end, win, tab, W)
                        st(so)
                    end or nil})
            end
            function obj:Slider(o)
                local v = o.Value or {}
                return getCont():AddSlider({Name = o.Title, Min = v.Min or 0, Max = v.Max or 100, Default = v.Default or v.Min or 0,
                    Increment = o.Step or 1, Callback = o.Callback})
            end
            function obj:Dropdown(o)
                return getCont():AddDropdown({Name = o.Title, Options = o.Values or {}, Default = o.Value, Callback = o.Callback})
            end
            function obj:Input(o)
                return getCont():AddTextbox({Name = o.Title, Default = tostring(o.Value or ""), Placeholder = o.Placeholder,
                    Callback = function(t) if o.Callback then o.Callback(t) end end})
            end
            function obj:Button(o)
                return getCont():AddButton({Name = o.Title, Callback = o.Callback})
            end
            function obj:ColorPicker(o)
                return getCont():AddColorPicker({Name = o.Title, Default = toColor(o.Value), Callback = function(c)
                    if o.Callback then o.Callback("#" .. c:ToHex()) end
                end})
            end
            customs(obj, getCont, win, tab, W)
        end

        function NLA:Notify(o)
            if NLA.win then pcall(function() NLA.win:Notify({Title = o.Title, Text = o.Content or o.Text, Duration = o.Duration}) end) end
        end
        function NLA:GetThemes() return {Black = true} end
        function NLA:SetTheme() end
        function NLA:CreateWindow(opts)
            FX.espScope = "global"
            local win = NL:CreateWindow({Brand = "zenith.cc", Logo = "", Game = "Murder Mystery 2", SubText = "@" .. lp.Name,
                Contexts = {"global", "local"}, ContextChanged = function(c) FX.espScope = c end})
            win.LogoImage = "rbxassetid://13936134740"
            pcall(function()
                local holder = win._logoLbl.Parent
                win._logoLbl.Text = ""
                local im = Instance.new("ImageLabel")
                im.BackgroundTransparency = 1
                im.Size = UDim2.fromScale(1, 1)
                im.Image = win.LogoImage
                im.ScaleType = Enum.ScaleType.Crop
                im.ZIndex = 5
                im.Parent = holder
                Instance.new("UICorner", im).CornerRadius = UDim.new(0, 10)
            end)
            NLA.win = win
            -- our watermark stays; keybinds use the library's own Hotkeys panel (black, with its icon)
            pcall(function()
                win:SetHud("Watermark", false)
                local hk = win._widgets and win._widgets.Hotkeys
                if hk and hk.List then hk.List.AlwaysOn = true end
                win:SetHud("Hotkeys", CFG.bindHud ~= false)
                win:SetHud("Spectators", false)
            end)
            FX.nlSetHud = function(name, v) pcall(function() win:SetHud(name, v) end) end
            FX.nlHotkeys = true
            -- the menu's own colours for our watermark, timer, buttons, open button
            local T0 = NL.Theme
            FX.themePalette = function()
                return {bg = T0.Pill, side = T0.Panel, group = T0.Group, row = T0.Field, line = T0.PillLine, accent = T0.Accent,
                    accentDim = T0.PillLine, text = T0.Text, sub = T0.SubText, dim = T0.Caps, white = Color3.new(1, 1, 1)}
            end
            local function repaintAll()
                pcall(function() if FX.wmDestroy then FX.wmDestroy() end end)
                pcall(function() if FX.timerDestroy then FX.timerDestroy() end end)
                pcall(function() if FX.bindHudDestroy then FX.bindHudDestroy() end end)
                pcall(function() if FX.applyOpenTheme then FX.applyOpenTheme() end end)
                pcall(function() if FX.restylePills then FX.restylePills() end end)
            end
            task.defer(repaintAll)
            local origAccent = NL.SetAccent
            if type(origAccent) == "function" then
                NL.SetAccent = function(self, c, ...)
                    local r = origAccent(self, c, ...)
                    task.defer(repaintAll)
                    return r
                end
            end
            FX.hitLog = function(rich, kind) pcall(function() win:HitLog(rich, kind) end) end
            local cat = win:AddCategory("zenith")
            local W = {conns = {}, nl = win}
            local function fit(m)
                local cam0 = workspace.CurrentCamera
                local vs = (cam0 and cam0.ViewportSize) or Vector2.new(1280, 720)
                local auto = math.min(1, (vs.Y - 24) / 600, (vs.X - 24) / 840)
                NL.Settings.MenuScale = tostring(math.floor(auto * (m or 1) * 100)) .. "%"
                pcall(function() win:_ApplyScale() end)
            end
            fit(opts and opts.Scale or 1)
            function W:Tab(o)
                local tab = cat:AddTab(o.Title or "tab", ICON_MAP[o.Icon or ""] or "star")
                local AT = {side = 0, cont = nil}
                local function group(title)
                    AT.side = AT.side + 1
                    AT.cont = tab:AddGroup(tostring(title or ""), (AT.side % 2 == 1) and "Left" or "Right")
                end
                local function getCont()
                    if not AT.cont then group(o.Title) end
                    return AT.cont
                end
                function AT:Section(so) group(so.Title) end
                attach(AT, getCont, win, tab, W)
                return AT
            end
            function W:Toggle() win:SetVisible(not win.Visible) end
            function W:Open() win:SetVisible(true) end
            function W:Close() win:SetVisible(false) end
            function W:SetScale(m) fit(m) end
            function W:Destroy()
                for _, c in ipairs(W.conns) do pcall(function() c:Disconnect() end) end
                pcall(function() win:Destroy() end)
            end
            W.gui, W.main = win.Gui, win.Main
            return W
        end
    end
end

local WindUI = NLA or ZUI

local function notifSound()
    if not CFG.uiSound then return end
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxasset://sounds/button.wav"
        snd.Volume = 0.5
        snd.Parent = game:GetService("SoundService")
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 3)
    end)
end
FX.notifSound = notifSound
FX.uiClick = notifSound
local function notify(title, text)
    notifSound()
    if WindUI then
        pcall(function() WindUI:Notify({Title = title, Content = text, Duration = 8}) end)
    end
end
FX.notify = notify

do
local btnGui = Instance.new("ScreenGui")
btnGui.Name = "ZenithButton"
btnGui.ResetOnSpawn = false
btnGui.IgnoreGuiInset = true
local okp = pcall(function() btnGui.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
if not okp or not btnGui.Parent then btnGui.Parent = lp:WaitForChild("PlayerGui") end

local Button = Instance.new("TextButton")
Button.Name = "SwagaButton"
Button.Size = UDim2.new(0, 60, 0, 60)
Button.AnchorPoint = Vector2.new(0.5, 0.5)
Button.Position = UDim2.new(0.08, 0, 0.5, 0)
Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Button.BackgroundTransparency = 0.35
Button.BorderSizePixel = 0
Button.Text = ""
Button.AutoButtonColor = false
Button.Active = true
Button.Parent = btnGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Button

local STROKE_IDLE = Color3.fromRGB(25, 70, 135)
local Stroke = Instance.new("UIStroke")
Stroke.Color = STROKE_IDLE
Stroke.Thickness = 2
Stroke.Transparency = 1
Stroke.Parent = Button

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.BackgroundTransparency = 1
Icon.Size = UDim2.new(0, 44, 0, 44)
Icon.Position = UDim2.new(0.5, -22, 0.5, -22)
Icon.Image = "rbxassetid://9826609769"
Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
Icon.ImageTransparency = 0
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = Button

local function setShootBtn(v)
    CFG.shootBtn = v
    Button.Visible = v
    Stroke.Color = STROKE_IDLE
end



local dragging, dragStart, startPos, moved = false, nil, nil, 0
connect(Button.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos, moved = true, input.Position, Button.Position, 0
        TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.fromOffset(124, 41)}):Play()
    end
end)
connect(UIS.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - dragStart
        moved = math.max(moved, d.Magnitude)

    end
end)
connect(UIS.InputEnded, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
        TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.fromOffset(132, 44)}):Play()
        local pic = Button:FindFirstChild("PillIcon") or Icon
        pic.ImageColor3 = Color3.fromRGB(120, 200, 255)
        task.spawn(function()
            if FX.shootNow then pcall(FX.shootNow) end
            task.wait(0.3)
            pic.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end
end)
FX.btnGui = btnGui
FX.shootButton = Button
FX.pill(Button, "shoot", "rbxassetid://9826609769")

do
    local og = Instance.new("ScreenGui")
    og.Name = "ZenithOpen"
    og.ResetOnSpawn = false
    og.IgnoreGuiInset = true
    og.DisplayOrder = 150
    local okq = pcall(function() og.Parent = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
    if not okq or not og.Parent then og.Parent = lp:WaitForChild("PlayerGui") end
    local ob = Instance.new("ImageButton")
    ob.Name = "Open"
    ob.Size = UDim2.fromOffset(58, 58)
    ob.Position = UDim2.new(0, 18, 0, 96)
    ob.BackgroundColor3 = Color3.fromRGB(5, 20, 45)
    ob.BackgroundTransparency = 1
    ob.AutoButtonColor = false
    ob.Image = ""
    ob.Parent = og
    Instance.new("UICorner", ob).CornerRadius = UDim.new(1, 0)
    local ost = Instance.new("UIStroke")
    ost.Color = Color3.fromRGB(25, 70, 135)
    ost.Thickness = 2
    ost.Transparency = 1
    ost.Parent = ob
    local oimg = Instance.new("ImageLabel")
    oimg.BackgroundTransparency = 1
    oimg.AnchorPoint = Vector2.new(0.5, 0.5)
    oimg.Position = UDim2.fromScale(0.5, 0.5)
    oimg.Size = UDim2.fromScale(1, 1)
    oimg.Image = "rbxassetid://13936134740"
    oimg.ScaleType = Enum.ScaleType.Crop
    oimg.Parent = ob
    Instance.new("UICorner", oimg).CornerRadius = UDim.new(1, 0)
    connect(ob.MouseEnter, function()
        TweenService:Create(ost, TweenInfo.new(0.15), {Color = Color3.fromRGB(66, 133, 255)}):Play()
    end)
    connect(ob.MouseLeave, function()
        local P = FX.themePalette and FX.themePalette()
        TweenService:Create(ost, TweenInfo.new(0.15), {Color = P and P.accentDim or Color3.fromRGB(25, 70, 135)}):Play()
    end)
    local od, oStart, oPos, oMoved = false, nil, nil, 0
    connect(ob.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            od, oStart, oPos, oMoved = true, input.Position, ob.Position, 0
            TweenService:Create(ob, TweenInfo.new(0.1), {Size = UDim2.fromOffset(52, 52)}):Play()
        end
    end)
    connect(UIS.InputChanged, function(input)
        if not od then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - oStart
            oMoved = math.max(oMoved, d.Magnitude)
            if oMoved > 10 then
                ob.Position = UDim2.new(oPos.X.Scale, oPos.X.Offset + d.X, oPos.Y.Scale, oPos.Y.Offset + d.Y)
            end
        end
    end)
    connect(UIS.InputEnded, function(input)
        if od and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            od = false
            TweenService:Create(ob, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(58, 58)}):Play()
            if oMoved <= 10 and FX.toggleMenu then FX.toggleMenu() end
        end
    end)
    FX.applyOpenTheme = function()
        local P = FX.themePalette and FX.themePalette()
        if P then
            ob.BackgroundColor3 = P.bg
            ost.Color = P.accentDim
        end
        oimg.Image = (FX.themeLogo and FX.themeLogo()) or "rbxassetid://13936134740"
    end
    pcall(FX.applyOpenTheme)
    FX.openGui = og
end
FX.setShootBtn = setShootBtn
end
local setShootBtn = FX.setShootBtn

local Window
local flDrop, buildUI
local selectedPlayer

local LANG_LABELS = {"English (EN)", "Русский (RU)", "Қазақша (KZ)", "Українська (UA)"}
local LANG_CODES = {["English (EN)"] = "EN", ["Русский (RU)"] = "RU", ["Қазақша (KZ)"] = "KZ", ["Українська (UA)"] = "UA"}
local LANG_NAME = {EN = "English (EN)", RU = "Русский (RU)", KZ = "Қазақша (KZ)", UA = "Українська (UA)"}

CFG.lang = genv.ZenithLang or CFG.lang
CFG.theme = "Black"

local function lowerFirst(str)
    if type(str) ~= "string" or str == "" then return str end
    local first, rest
    for p, cp in utf8.codes(str) do
        first = cp
        rest = string.sub(str, p + #utf8.char(cp))
        break
    end
    if not first then return str end
    local second = string.byte(rest, 1)
    if first >= 65 and first <= 90 then
        if second and second >= 65 and second <= 90 then return str end
        return utf8.char(first + 32) .. rest
    elseif first >= 0x0410 and first <= 0x042F then
        return utf8.char(first + 32) .. rest
    elseif first == 0x0401 then
        return utf8.char(0x0451) .. rest
    end
    return str
end
FX.lowerFirst = lowerFirst

local function L(en, ru, kk, uk)
    local l = CFG.lang
    if l == "RU" then return ru or en end
    if l == "KZ" then return kk or en end
    if l == "UA" then return uk or en end
    return en
end

local function val(v) return (type(v) == "table" and v[1]) or v end

FX.drawMenuBg = function()
    local art = FX.menuArt
    if not (art and art.Parent) then return end
    art:ClearAllChildren()
    local kind = CFG.menuBg
    local PAL = FX.themePalette and FX.themePalette() or {}
    local ACCENT = PAL.accent or Color3.fromRGB(140, 110, 255)
    local rnd = Random.new(7)
    local function fr(props)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        for k, v in pairs(props) do f[k] = v end
        f.ZIndex = 0
        f.Parent = art
        return f
    end
    if kind == "Space" then
        local g = Instance.new("UIGradient")
        local glow = fr({Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82})
        g.Rotation = 35
        g.Color = ColorSequence.new(Color3.fromRGB(40, 20, 90), Color3.fromRGB(5, 5, 15))
        g.Parent = glow
        for _ = 1, 3 do
            local s0 = rnd:NextInteger(140, 260)
            local n = fr({Size = UDim2.fromOffset(s0, s0), Position = UDim2.new(rnd:NextNumber(0, 0.9), -s0 / 2, rnd:NextNumber(0, 0.9), -s0 / 2),
                BackgroundColor3 = Color3.fromRGB(rnd:NextInteger(90, 160), 60, rnd:NextInteger(180, 255)), BackgroundTransparency = 0.9})
            Instance.new("UICorner", n).CornerRadius = UDim.new(1, 0)
        end
        for _ = 1, 70 do
            local z = rnd:NextInteger(1, 3)
            local st = fr({Size = UDim2.fromOffset(z, z), Position = UDim2.fromScale(rnd:NextNumber(), rnd:NextNumber()),
                BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = rnd:NextNumber(0.2, 0.75)})
            Instance.new("UICorner", st).CornerRadius = UDim.new(1, 0)
        end
    elseif kind == "Geometry" then
        for x = 0, 720, 28 do fr({Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94}) end
        for y = 0, 420, 28 do fr({Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94}) end
        for _ = 1, 9 do
            local s0 = rnd:NextInteger(30, 90)
            local q = fr({Size = UDim2.fromOffset(s0, s0), Position = UDim2.fromScale(rnd:NextNumber(), rnd:NextNumber()), Rotation = rnd:NextInteger(0, 45),
                BackgroundTransparency = 1})
            local st = Instance.new("UIStroke")
            st.Color = ACCENT
            st.Transparency = 0.75
            st.Parent = q
        end
    elseif kind == "Triangles" then
        for _ = 1, 16 do
            local sz = rnd:NextInteger(26, 80)
            local cx, cy = rnd:NextNumber(), rnd:NextNumber()
            local rot = rnd:NextInteger(0, 120)
            local col = (rnd:NextNumber() < 0.5) and ACCENT or Color3.new(1, 1, 1)
            for k = 0, 2 do
                local a = math.rad(rot + k * 120)
                local h = sz * 0.577
                fr({AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(sz, 1),
                    Position = UDim2.new(cx, math.cos(a) * h * 0.5, cy, math.sin(a) * h * 0.5), Rotation = math.deg(a) + 90,
                    BackgroundColor3 = col, BackgroundTransparency = 0.8})
            end
        end
    end
end

local function newTab(title, icon)
    if not Window then return nil end
    local ok, t = pcall(function() return Window:Tab({Title = lowerFirst(title), Icon = icon}) end)
    if ok then return t end
end

local function sec(tab, title)
    if tab then pcall(function() tab:Section({Title = title}) end) end
end

FX.toggles = FX.toggles or {}
FX.parseBinds = function()
    local m = {}
    for k, v in string.gmatch(CFG.binds or "", "([%w_]+)=([%w]+)") do m[k] = v end
    return m
end
FX.bindOf = function(key) return FX.parseBinds()[key] end
FX.setBind = function(key, code)
    local m = FX.parseBinds()
    m[key] = code
    local parts = {}
    for k, v in pairs(m) do parts[#parts + 1] = k .. "=" .. v end
    table.sort(parts)
    CFG.binds = table.concat(parts, ";")
end

local function tog(tab, title, key, cb, settings)
    if not tab then return nil end
    title = lowerFirst(title)
    local bare = settings == false
    if bare then settings = nil end
    local nested = tab._into ~= nil or bare
    local full = settings
    if not nested and (settings or WindUI == ZUI) then
        full = function(t)
            if settings then settings(t) end
            if t.Keybind then
                t:Keybind({Title = L("Keybind", "Клавиша", "Перне", "Клавіша"), Value = FX.bindOf(key), Callback = function(code)
                    FX.setBind(key, code)
                end})
            end
        end
    end
    local ok, el = pcall(function()
        return tab:Toggle({Title = title, Value = CFG[key], Settings = full, Callback = function(v)
            CFG[key] = v
            if cb then cb(v) end
        end})
    end)
    if ok then
        if not nested and el then FX.toggles[key] = {obj = el, title = title} end
        return el
    end
end

local function sld(tab, title, key, mn, mx, step, cb)
    if not tab then return end
    title = lowerFirst(title)
    pcall(function()
        tab:Slider({Title = title, Step = step, Value = {Min = mn, Max = mx, Default = CFG[key]}, Callback = function(v)
            CFG[key] = v
            if cb then cb(v) end
        end})
    end)
end

local function btn(tab, title, fn)
    title = lowerFirst(title)
    if not tab then return end
    pcall(function()
        tab:Button({Title = title, Callback = function()
            task.spawn(function() pcall(fn) end)
        end})
    end)
end

local function dd(tab, title, values, default, cb)
    title = lowerFirst(title)
    if not tab then return nil end
    local ok, el = pcall(function()
        return tab:Dropdown({Title = title, Values = values, Value = default, Callback = cb})
    end)
    if ok then return el end
end

local function inp(tab, title, value, placeholder, cb)
    if not tab then return end
    pcall(function()
        tab:Input({Title = title, Value = tostring(value or ""), Placeholder = placeholder or "", Callback = cb})
    end)
end

local function reshade()
    if CFG.shaders then pcall(shadersApply) end
end

local function themeNames()
    local out = {}
    if WindUI then
        pcall(function()
            for name in pairs(WindUI:GetThemes()) do out[#out + 1] = name end
        end)
    end
    if #out == 0 then
        out = {"Dark", "Light", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet", "Amber", "Emerald"}
    end
    table.sort(out)
    return out
end

local AURA_IDS = {
    Angel = "97658130917593", Starlight = "134645216613107", Heavenly = "139300897520961", Ribbon = "132069507632161",
    Sakura = "81755778619404", Wind = "80694081850877", Flow = "119913533725648", Star = "73754563740680",
}
local AURA_NAMES = {"Angel", "Starlight", "Heavenly", "Ribbon", "Sakura", "Wind", "Flow", "Star"}
local auraCache = {}
local function tintOne(e, c)
    local function cs(v) return ColorSequence.new(v) end
    pcall(function() if e:IsA("ParticleEmitter") or e:IsA("Beam") or e:IsA("Trail") then e.Color = cs(c) end end)
    pcall(function() if e:IsA("PointLight") or e:IsA("SpotLight") or e:IsA("SurfaceLight") then e.Color = c end end)
    pcall(function() if e:IsA("Decal") or e:IsA("Texture") then e.Color3 = c end end)
    pcall(function() if e:IsA("BasePart") then e.Color = c end end)
    pcall(function()
        if e:IsA("MeshPart") and e.TextureID ~= "" then
            if e:GetAttribute("ZenithTex") == nil then e:SetAttribute("ZenithTex", e.TextureID) end
            e.TextureID = ""
        end
    end)
    pcall(function() if e:IsA("SpecialMesh") and e.TextureId ~= "" then e.VertexColor = Vector3.new(c.R * 1.6, c.G * 1.6, c.B * 1.6) end end)
    pcall(function() if e:IsA("Sparkles") then e.SparkleColor = c end end)
    pcall(function() if e:IsA("Fire") then e.Color = c e.SecondaryColor = c end end)
    pcall(function() if e:IsA("Smoke") then e.Color = c end end)
    pcall(function() if e:IsA("Highlight") then e.FillColor = c e.OutlineColor = c end end)
    pcall(function() if e:IsA("ImageLabel") or e:IsA("ImageButton") then e.ImageColor3 = c end end)
    pcall(function() if e:IsA("SpecialMesh") then e.VertexColor = Vector3.new(c.R, c.G, c.B) end end)
    pcall(function() if e:IsA("SurfaceAppearance") then e:Destroy() end end)
    -- anything else that carries a colour
    pcall(function() if typeof(e.Color) == "Color3" then e.Color = c elseif typeof(e.Color) == "ColorSequence" then e.Color = cs(c) end end)
    pcall(function() if typeof(e.Color3) == "Color3" then e.Color3 = c end end)
end
local function tintEffect(e, c)
    tintOne(e, c)
    for _, d in ipairs(e:GetDescendants()) do tintOne(d, c) end
end
local function clearAura(char)
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:GetAttribute("ZenithAura") then pcall(function() obj:Destroy() end) end
    end
end
local relinkAuraLater
FX.applyAura = function()
    local lpL = game:GetService("Players").LocalPlayer
    local char = lpL.Character
    if not char then return end
    clearAura(char)
    if not CFG.auraOn then return end
    local id = AURA_IDS[CFG.auraName]
    if not id then return end
    local src = auraCache[id]
    if not (src and src.Parent) then
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
        src = ok and objs and objs[1] or nil
        if not src then return end
        src.Parent = FX.auraStore
        auraCache[id] = src
    end
    -- the model's own body part to measure the extra pieces from (torso / root)
    local srcRef = src:FindFirstChild("HumanoidRootPart") or src:FindFirstChild("UpperTorso") or src:FindFirstChild("Torso")
    local myRef = srcRef and char:FindFirstChild(srcRef.Name)
    for _, sourcePart in ipairs(src:GetChildren()) do
        local targetPart = char:FindFirstChild(sourcePart.Name)
        if targetPart and targetPart:IsA("BasePart") then
            for _, effect in ipairs(sourcePart:GetChildren()) do
                if not effect:IsA("JointInstance") and not effect:IsA("WeldConstraint") and not effect:IsA("LuaSourceContainer") then
                    local cl = effect:Clone()
                    for _, d in ipairs(cl:GetDescendants()) do
                        if d:IsA("LuaSourceContainer") then pcall(function() d:Destroy() end) end
                    end
                    cl:SetAttribute("ZenithAura", true)
                    if CFG.auraColSet then tintEffect(cl, CFG.auraCol) end
                    cl.Parent = targetPart
                end
            end
        elseif sourcePart:IsA("Accessory") then
            -- wings / halos made as accessories: worn on you through your humanoid
            local cl = sourcePart:Clone()
            cl:SetAttribute("ZenithAura", true)
            for _, d in ipairs(cl:GetDescendants()) do
                if d:IsA("LuaSourceContainer") then pcall(function() d:Destroy() end) end
                if d:IsA("BasePart") then d.CanCollide, d.Massless = false, true end
            end
            if CFG.auraColSet then tintEffect(cl, CFG.auraCol) end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:AddAccessory(cl) end) end
            if not cl.Parent then cl.Parent = char end
        elseif (sourcePart:IsA("BasePart") or sourcePart:IsA("Model")) and srcRef and myRef then
            -- a decoration that is not a body part (wings, a sakura tree behind the back...): welded where it sits on the model
            local cl = sourcePart:Clone()
            cl:SetAttribute("ZenithAura", true)
            for _, d in ipairs(cl:GetDescendants()) do
                if d:IsA("LuaSourceContainer") then pcall(function() d:Destroy() end) end
            end
            local parts = {}
            if cl:IsA("BasePart") then parts[1] = cl end
            for _, d in ipairs(cl:GetDescendants()) do
                if d:IsA("BasePart") then parts[#parts + 1] = d end
                if d:IsA("JointInstance") or d:IsA("WeldConstraint") then pcall(function() d:Destroy() end) end
            end
            local okp, pivot = pcall(function() return sourcePart:IsA("Model") and sourcePart:GetPivot() or sourcePart.CFrame end)
            if okp then
                local rel = srcRef.CFrame:ToObjectSpace(pivot)
                pcall(function()
                    if cl:IsA("Model") then cl:PivotTo(myRef.CFrame * rel) else cl.CFrame = myRef.CFrame * rel end
                end)
                for _, p in ipairs(parts) do
                    p.Anchored, p.CanCollide, p.Massless = false, false, true
                    pcall(function() p.CanQuery, p.CanTouch = false, false end)
                    local w = Instance.new("WeldConstraint")
                    w.Part0, w.Part1 = myRef, p
                    w.Parent = p
                end
                if CFG.auraColSet then tintEffect(cl, CFG.auraCol) end
                cl.Parent = char
            end
        end
    end
    if relinkAuraLater then pcall(relinkAuraLater, char) end
    if CFG.auraColSet and FX.recolorAura then pcall(FX.recolorAura) end
end
local AURA_FX = {ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true}
local function relinkAura(char)
    local function mine(att)
        if not att or att:IsDescendantOf(char) then return att end
        local part = att.Parent and char:FindFirstChild(att.Parent.Name)
        local found = part and part:FindFirstChild(att.Name)
        if not found then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("Attachment") and d.Name == att.Name then found = d break end
            end
        end
        return found or att
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Beam") then
            pcall(function() d.Attachment0, d.Attachment1 = mine(d.Attachment0), mine(d.Attachment1) end)
        elseif d:IsA("Trail") then
            pcall(function() d.Attachment0, d.Attachment1 = mine(d.Attachment0), mine(d.Attachment1) end)
        end
    end
end
relinkAuraLater = relinkAura
FX.recolorAura = function()
    local lpL = game:GetService("Players").LocalPlayer
    local char = lpL.Character
    if not char then return end
    local c = CFG.auraCol
    for _, obj in ipairs(char:GetDescendants()) do
        if AURA_FX[obj.ClassName] then
            tintOne(obj, c)
        elseif obj:GetAttribute("ZenithAura") then
            tintEffect(obj, c)
        end
    end
end
do
    local store = Instance.new("Folder")
    store.Name = "ZenithAuraStore"
    pcall(function() store.Parent = game:GetService("ReplicatedStorage") end)
    FX.auraStore = store
    local lpL = game:GetService("Players").LocalPlayer
    lpL.CharacterAdded:Connect(function()
        task.wait(1)
        if CFG.auraOn then pcall(FX.applyAura) end
    end)
end

FX.toggleMenu = function()
    local w = FX.window
    if w then pcall(function() w:Toggle() end) end
end

local function rebuildUI()
    if Window then pcall(function() Window:Destroy() end) end
    Window, flDrop = nil, nil
    buildUI()
end

buildUI = function()
    if WindUI then
        local ok, w = pcall(function()
            return WindUI:CreateWindow({
                Title = "Zenith | MM2",
                Icon = "rbxassetid://13936134740",
                Scale = CFG.uiScale,
                Author = "by @zenithee",
                Folder = "ZenithHub",
                Size = UDim2.fromOffset(520, 340),
                Theme = CFG.theme,
            })
        end)
        if ok and w then
            Window = w
            FX.window = w
        else
            showError("WindUI окно не создалось: " .. tostring(w))
        end
    end

    local function cpick(tab, title, key, extras)
        if tab.ColorPicker then
            return tab:ColorPicker({Title = title, Value = CFG[key], Extras = extras, Callback = function(v) CFG[key] = v end})
        end
    end

    local function gradSet(tab, prefix)
        tog(tab, L("Gradient", "Градиент", "Градиент", "Градієнт"), prefix)
        cpick(tab, L("Gradient color 1", "Цвет градиента 1", "Градиент түсі 1", "Колір градієнта 1"), prefix .. "A", {"Rainbow"})
        cpick(tab, L("Gradient color 2", "Цвет градиента 2", "Градиент түсі 2", "Колір градієнта 2"), prefix .. "B", {"Rainbow"})
        tog(tab, L("Animated gradient", "Живой градиент", "Қозғалмалы градиент", "Живий градієнт"), prefix .. "Anim")
    end

    local tabAim = newTab(L("Combat", "Бой", "Ұрыс", "Бій"), "swords")
    sec(tabAim, "infection")
    tog(tabAim, "survivor silent", "infSilent")
    sec(tabAim, "silent")
    tog(tabAim, "silent", "silent", nil, function(tabAim)
        sld(tabAim, "hit chance", "silentChance", 0, 100, 1)
    end)
    tog(tabAim, "Force shoot", "wallbang")
    tog(tabAim, "hit notify", "hitNotify")
    tog(tabAim, "kill notify", "killNotify")
    tog(tabAim, "miss notify", "missNotify")
    tog(tabAim, L("Auto shoot", "Авто-выстрел", "Авто ату", "Авто-постріл"), "autoShoot", nil, function(tabAim)
        sld(tabAim, "hit chance", "shootChance", 0, 100, 1)
    end)
    sec(tabAim, L("Silent knife", "Скрытый нож", "Жасырын пышақ", "Прихований ніж"))
    tog(tabAim, "throw silent", "knifeSilent", nil, function(tabAim)
        tog(tabAim, L("Throw hit assist", "Помощь попадания ножом", "Пышақ тигізуге көмек", "Допомога влучання ножем"), "knifeAssist")
        tog(tabAim, L("Knife through walls", "Нож сквозь стены", "Пышақ қабырға арқылы", "Ніж крізь стіни"), "knifeWB")
        dd(tabAim, L("Knife target", "Цель ножа", "Пышақ нысанасы", "Ціль ножа"), {"Crosshair", "Nearest"}, CFG.knifeMode, function(v)
            CFG.knifeMode = val(v)
        end)
        sld(tabAim, L("Knife FOV", "Угол захвата ножа", "Пышақ көру бұрышы", "Кут захоплення ножа"), "knifeFov", 10, 180, 5)
    end)
    sec(tabAim, L("Murderer", "Убийца", "Өлтіруші", "Вбивця"))
    tog(tabAim, L("Kill Aura", "Килл Аура", "Өлтіру аурасы", "Кіл Аура"), "autoKill")
    btn(tabAim, L("Kill All", "Убить всех", "Барлығын өлтіру", "Вбити всіх"), function() FX.killAll() end)
    tog(tabAim, L("Knife reach", "Дальность ножа", "Пышақ қашықтығы", "Дальність ножа"), "reachOn", nil, function(tabAim)
        sld(tabAim, L("Reach size", "Размер досягаемости", "Жету өлшемі", "Розмір досяжності"), "reachSize", 2, 25, 1)
    end)
    sec(tabAim, L("Sheriff", "Шериф", "Шериф", "Шериф"))
    btn(tabAim, L("Shoot murderer now", "Выстрелить в убийцу сейчас", "Өлтірушіге қазір ату", "Вистрілити у вбивцю зараз"), function() FX.shootNow() end)
    tog(tabAim, L("Auto pick gun", "Авто-подбор пистолета", "Мылтықты авто алу", "Авто-підбір пістолета"), "autoGun")
    tog(tabAim, L("Crosshair", "Прицел", "Көздеу", "Приціл"), "crosshair")

    local tabVis = newTab(L("Visuals", "Визуалы", "Визуалдар", "Візуали"), "scan-eye")
    sec(tabVis, L("Preview", "Превью", "Алдын ала қарау", "Превʼю"))
    local prevRole = "Murderer"
    if tabVis.Preview then
        tabVis:Preview({Title = "preview", Get = function()
            local roleCol = COLORS[prevRole] or COLORS.Innocent
            return {
                color = roleCol,
                chamsColor = (CFG.chamsColor == "Role") and roleCol or colorOf(CFG.chamsColor),
                chams = CFG.esp and CFG.highlight, chamsType = CFG.chamsStyle,
                box = CFG.esp and CFG.box, skeleton = CFG.esp and CFG.skeleton, name = CFG.esp and CFG.name,
                dist = CFG.esp and CFG.dist, health = CFG.esp and CFG.health, avatar = CFG.esp and CFG.avatar,
            }
        end})
    end
    dd(tabVis, L("Preview role", "Роль в превью", "Превью рөлі", "Роль у превʼю"), {"Murderer", "Sheriff", "Hero", "Innocent"}, prevRole, function(v)
        prevRole = val(v)
    end)
    sec(tabVis, "ESP")
    tog(tabVis, L("ESP", "ESP", "ESP", "ESP"), "esp", nil, function(tabVis)
        tog(tabVis, L("Innocents", "Мирные", "Бейбіттер", "Мирні"), "showInnocent")
        sld(tabVis, L("Skeleton range", "Дальность скелета", "Қаңқа қашықтығы", "Дальність скелета"), "skelDist", 50, 1000, 10)
        sld(tabVis, L("ESP range", "Дальность ESP", "ESP қашықтығы", "Дальність ESP"), "maxDist", 100, 2000, 50)
    end)
    tog(tabVis, L("Box", "Бокс", "Бокс", "Бокс"), "box", nil, function(tabVis)
        dd(tabVis, L("Box style", "Стиль бокса", "Бокс стилі", "Стиль боксу"), {"Corners", "Full", "3D"}, CFG.boxStyle, function(v)
            CFG.boxStyle = val(v)
        end)
        gradSet(tabVis, "gBox")
    end)
    tog(tabVis, L("Skeleton", "Скелет", "Қаңқа", "Скелет"), "skeleton", nil, function(tabVis)
        gradSet(tabVis, "gSkel")
    end)
    tog(tabVis, L("Candy", "Конфеты", "Кәмпиттер", "Цукерки"), "espCandy")
    tog(tabVis, L("Name", "Ник", "Ник", "Нік"), "name", nil, function(tabVis)
        gradSet(tabVis, "gName")
    end)
    tog(tabVis, L("Distance", "Дистанция", "Қашықтық", "Дистанція"), "dist")
    tog(tabVis, L("Avatar", "Аватар", "Аватар", "Аватар"), "avatar")
    tog(tabVis, L("Arrows", "Стрелки", "Көрсеткілер", "Стрілки"), "arrows", nil, function(tabVis)
        sld(tabVis, L("Arrow distance", "Отступ стрелок", "Көрсеткі қашықтығы", "Відступ стрілок"), "arrowRadius", 60, 400, 5)
        gradSet(tabVis, "gArrow")
    end)
    tog(tabVis, L("Chams", "Чамсы", "Чамс", "Чамси"), "highlight", nil, function(tabVis)
        dd(tabVis, L("Chams type", "Тип чамсов", "Чамс түрі", "Тип чамсів"), FX.CHAM_MODES, CFG.chamsStyle, function(v)
            CFG.chamsStyle = val(v)
        end)
        cpick(tabVis, L("Chams color", "Цвет чамсов", "Чамс түсі", "Колір чамсів"), "chamsColor", {"Role", "Rainbow"})
        gradSet(tabVis, "gCham")
    end)
    tog(tabVis, L("Self chams", "Чамсы на себя", "Өзіңе чамс", "Чамси на себе"), "selfChams", nil, function(tabVis)
        dd(tabVis, L("Self chams type", "Тип чамсов на себя", "Өз чамс түрі", "Тип чамсів на себе"), FX.CHAM_MODES, CFG.selfMode, function(v)
            CFG.selfMode = val(v)
        end)
        cpick(tabVis, L("Self chams color", "Цвет чамсов на себя", "Өз чамс түсі", "Колір чамсів на себе"), "selfColor", {"Rainbow"})
        gradSet(tabVis, "gSelf")
    end)
    tog(tabVis, L("Weapon chams", "Чамсы оружия", "Қару чамсы", "Чамси зброї"), "wepChams", nil, function(tabVis)
        dd(tabVis, L("Weapon chams type", "Тип чамсов оружия", "Қару чамс түрі", "Тип чамсів зброї"), FX.CHAM_MODES, CFG.wepMode, function(v)
            CFG.wepMode = val(v)
        end)
        cpick(tabVis, L("Weapon chams color", "Цвет чамсов оружия", "Қару чамс түсі", "Колір чамсів зброї"), "wepColor", {"Rainbow"})
        gradSet(tabVis, "gWep")
    end)
    tog(tabVis, L("Gun drop", "Пистолет на земле", "Жердегі мылтық", "Пістолет на землі"), "gun")
    sec(tabVis, L("Weapons", "Оружие", "Қару", "Зброя"))
    tog(tabVis, L("China hat", "Китайская шляпа", "Қытай қалпағы", "Китайський капелюх"), "chinaHat", nil, function(t)
        cpick(t, L("Hat color", "Цвет шляпы", "Қалпақ түсі", "Колір капелюха"), "hatColor", {"Rainbow"})
    end)
    tog(tabVis, "Backtrack", "trail", nil, function(tabVis)
        dd(tabVis, L("Ghost style", "Стиль тени", "Көлеңке стилі", "Стиль тіні"), {"Chams", "ForceField", "Neon", "Classic"}, CFG.trailMode, function(v)
            CFG.trailMode = val(v)
        end)
        cpick(tabVis, L("Ghost color", "Цвет тени", "Көлеңке түсі", "Колір тіні"), "trailColor", {"Rainbow"})
        sld(tabVis, L("Ghost delay", "Задержка тени", "Көлеңке кідірісі", "Затримка тіні"), "trailDelay", 0.1, 1.5, 0.05)
    end)
    tog(tabVis, L("Weapon ESP", "ESP оружия", "Қару ESP", "ESP зброї"), "weaponEsp", nil, function(tabVis)
        dd(tabVis, L("Weapon style", "Стиль оружия", "Қару стилі", "Стиль зброї"), {"Chams", "Outline", "Glow", "ForceField", "Neon"}, CFG.weaponStyle, function(v)
            CFG.weaponStyle = val(v)
        end)
        cpick(tabVis, L("Knife color", "Цвет ножа", "Пышақ түсі", "Колір ножа"), "knifeColor", {"Rainbow"})
        cpick(tabVis, L("Gun color", "Цвет пистолета", "Мылтық түсі", "Колір пістолета"), "gunColor", {"Rainbow"})
    end)
    local tabWorld = newTab(L("World", "Мир", "Әлем", "Світ"), "globe")
    sec(tabWorld, L("World", "Мир", "Әлем", "Світ"))
    tog(tabWorld, L("Fullbright", "Полная яркость", "Толық жарық", "Повна яскравість"), "fullbright")
    sec(tabWorld, L("Aura", "Аура", "Аура", "Аура"))
    tog(tabWorld, L("Aura", "Аура", "Аура", "Аура"), "auraOn", function() task.spawn(function() pcall(FX.applyAura) end) end, function(t)
        dd(t, L("Effect", "Эффект", "Эффект", "Ефект"), AURA_NAMES, CFG.auraName, function(v)
            CFG.auraName = val(v)
            if CFG.auraOn then task.spawn(function() pcall(FX.applyAura) end) end
        end)
        if t.ColorPicker then
            t:ColorPicker({Title = lowerFirst(L("Color", "Цвет", "Түс", "Колір")), Value = CFG.auraCol, Callback = function(v)
                CFG.auraCol, CFG.auraColSet = (typeof(v) == "Color3") and v or colorOf(v), true
                task.spawn(function() pcall(FX.recolorAura) end)
            end})
        end
    end)
    tog(tabWorld, L("Custom FOV", "Свой FOV", "Жеке FOV", "Свій FOV"), "fovOn", nil, function(tabWorld)
        sld(tabWorld, "FOV", "fov", 40, 120, 1)
    end)
    tog(tabWorld, L("X-ray", "X-ray", "X-ray", "X-ray"), "xray", nil, function(tabWorld)
        sld(tabWorld, L("X-ray transparency", "Прозрачность X-ray", "X-ray мөлдірлігі", "Прозорість X-ray"), "xrayTransp", 0.1, 0.9, 0.05, function()
            xrRefresh()
        end)
    end)
    tog(tabWorld, L("Potato graphics", "Картошечная графика", "Картоп графика", "Картопляна графіка"), "potato")
    tog(tabWorld, L("Studs graphics", "Графика из студов", "Студ графикасы", "Графіка зі студів"), "studs")
    sec(tabWorld, L("Shaders", "Шейдеры", "Шейдерлер", "Шейдери"))
    if tabWorld.ImageGrid then
        local sg
        sg = tabWorld:ImageGrid({
            Title = "shaders",
            GetItems = function() return FX.presetItems and FX.presetItems() or {} end,
            OnClick = function(it)
                FX.presetSet(it.preset)
                task.defer(function() pcall(function() sg:Refresh() end) end)
            end,
        })
    end
    tog(tabWorld, L("Shaders", "Шейдеры", "Шейдерлер", "Шейдери"), "shaders", setShaders, function(tabWorld)
        dd(tabWorld, L("Preset", "Пресет", "Пресет", "Пресет"), PRESET_NAMES, "BlueFog", applyPreset)
        tog(tabWorld, L("Blue fog", "Синий туман", "Көк тұман", "Синій туман"), "fogOn", reshade)
        sld(tabWorld, "distance", "fog", 50, 2000, 10, reshade)
        sld(tabWorld, L("Fog density", "Плотность тумана", "Тұман тығыздығы", "Щільність туману"), "density", 0, 1, 0.05, reshade)
        sld(tabWorld, "Bloom", "bloom", 0, 4, 0.1, reshade)
        sld(tabWorld, L("Contrast", "Контраст", "Контраст", "Контраст"), "contrast", -0.5, 1, 0.05, reshade)
        sld(tabWorld, L("Saturation", "Насыщенность", "Қанықтық", "Насиченість"), "sat", -1, 1, 0.05, reshade)
        sld(tabWorld, L("Blur", "Размытие", "Бұлыңғырлық", "Розмиття"), "dof", 0, 1, 0.05, reshade)
        sld(tabWorld, L("Brightness", "Яркость", "Жарықтық", "Яскравість"), "bright", 0, 5, 0.1, reshade)
    end)
    sec(tabWorld, L("Sky", "Небо", "Аспан", "Небо"))
    tog(tabWorld, "time", "timeOn", nil, function(tabWorld)
        sld(tabWorld, L("Time", "Время", "Уақыт", "Час"), "clockTime", 0, 24, 0.5)
    end)
    tog(tabWorld, "fog", "fogChOn", nil, function(tabWorld)
        sld(tabWorld, "distance", "fogChEnd", 20, 5000, 10)
        cpick(tabWorld, "color", "fogChColor", {"Rainbow"})
    end)
    tog(tabWorld, "brightness", "brightOn", nil, function(tabWorld)
        sld(tabWorld, L("Brightness", "Яркость", "Жарықтық", "Яскравість"), "brightV", 0, 10, 0.1)
    end)
    tog(tabWorld, "ambient", "ambOn", nil, function(tabWorld)
        cpick(tabWorld, "color", "ambColor", {"Rainbow"})
    end)
    sec(tabWorld, "Skybox")
    if tabWorld.ImageGrid then
        local skyGrid
        skyGrid = tabWorld:ImageGrid({
            Title = "skybox",
            GetItems = function() return FX.skyItems and FX.skyItems() or {} end,
            OnClick = function(it)
                FX.skySet(it.sky)
                task.defer(function() pcall(function() skyGrid:Refresh() end) end)
            end,
        })
    end
    tog(tabWorld, L("Rain", "Дождь", "Жаңбыр", "Дощ"), "rain", nil, function(tabWorld)
        sld(tabWorld, "amount", "rainRate", 100, 1500, 50)
        cpick(tabWorld, "color", "rainColor", {"Rainbow"})
    end)
    sec(tabWorld, L("Trails", "Следы", "Іздер", "Сліди"))
    tog(tabWorld, L("Trail", "Шлейф", "Шлейф", "Шлейф"), "ribbon", nil, function(tabWorld)
        cpick(tabWorld, L("Trail color", "Цвет шлейфа", "Шлейф түсі", "Колір шлейфу"), "ribbonColor", {"Rainbow"})
        sld(tabWorld, L("Trail length", "Длина шлейфа", "Шлейф ұзындығы", "Довжина шлейфу"), "ribbonLife", 0.1, 2, 0.05)
    end)
    tog(tabWorld, L("Shoot Trail", "След выстрела", "Ату ізі", "Слід пострілу"), "shotTrail", nil, function(tabWorld)
        dd(tabWorld, L("Effect", "Эффект", "Эффект", "Ефект"), {"Neon", "Lighting", "Explosion", "Blood"}, CFG.shotFx, function(v)
            CFG.shotFx = val(v)
        end)
        cpick(tabWorld, L("Shoot Trail color", "Цвет следа выстрела", "Ату ізінің түсі", "Колір сліду пострілу"), "shotColor", {"Rainbow"})
    end)
    local tabChar = newTab(L("Character", "Персонаж", "Кейіпкер", "Персонаж"), "user")
    sec(tabChar, L("Movement", "Движение", "Қозғалыс", "Рух"))
    tog(tabChar, L("WalkSpeed", "Скорость ходьбы", "Жүру жылдамдығы", "Швидкість ходьби"), "wsOn", nil, function(tabChar)
        sld(tabChar, L("WalkSpeed value", "Значение скорости ходьбы", "Жүру жылдамдығының мәні", "Значення швидкості ходьби"), "walkSpeed", 16, 200, 1)
    end)
    tog(tabChar, L("JumpPower", "Сила прыжка", "Секіру күші", "Сила стрибка"), "jpOn", nil, function(tabChar)
        sld(tabChar, L("JumpPower value", "Значение силы прыжка", "Секіру күшінің мәні", "Значення сили стрибка"), "jumpPower", 50, 300, 5)
    end)
    tog(tabChar, L("Infinite jump", "Бесконечный прыжок", "Шексіз секіру", "Нескінченний стрибок"), "infJump")
    tog(tabChar, L("Bunny Hop", "Банни-хоп", "Банни-хоп", "Банні-хоп"), "bhop", nil, function(tabChar)
        sld(tabChar, L("Bunny Hop speed", "Скорость банни-хопа", "Банни-хоп жылдамдығы", "Швидкість банні-хопа"), "bhopSpeed", 10, 50, 1)
    end)
    tog(tabChar, "wall hop", "wallHop")
    tog(tabChar, "pixel surf", "pixelSurf", nil, function(tabChar)
        sld(tabChar, "fall speed", "surfFall", 0, 10, 0.5)
    end)
    tog(tabChar, "Air Strafe", "airStrafe", nil, function(tabChar)
        sld(tabChar, L("Air acceleration", "Ускорение в воздухе", "Ауадағы үдеу", "Прискорення в повітрі"), "airAccel", 10, 200, 5)
        sld(tabChar, L("Max air speed", "Макс. скорость в воздухе", "Ауадағы макс. жылдамдық", "Макс. швидкість у повітрі"), "airMax", 16, 120, 1)
    end)

    local tabMisc = newTab(L("Misc", "Разное", "Әртүрлі", "Різне"), "wrench")
    sec(tabMisc, L("Movement", "Движение", "Қозғалыс", "Рух"))
    tog(tabMisc, L("Noclip", "Прохождение сквозь стены", "Қабырғадан өту", "Проходження крізь стіни"), "noclip")
    tog(tabMisc, L("Fly", "Полёт", "Ұшу", "Політ"), "fly", function(v)
        if not v then flyStop() end
    end, function(tabMisc)
        sld(tabMisc, L("Fly speed", "Скорость полёта", "Ұшу жылдамдығы", "Швидкість польоту"), "flySpeed", 10, 250, 5)
    end)
    tog(tabMisc, "Auto Strafe", "autoStrafe", nil, function(tabMisc)
        sld(tabMisc, L("Speed gain", "Набор скорости", "Жылдамдық жинау", "Набір швидкості"), "strafeGain", 1, 60, 1)
        sld(tabMisc, L("Max speed", "Макс. скорость", "Макс. жылдамдық", "Макс. швидкість"), "strafeMax", 16, 120, 1)
    end)
    tog(tabMisc, "Speed-Glitch", "speedGlitch", nil, function(tabMisc)
        sld(tabMisc, L("Speed-Glitch speed", "Скорость Speed-Glitch", "Speed-Glitch жылдамдығы", "Швидкість Speed-Glitch"), "sgSpeed", 20, 120, 1)
        tog(tabMisc, L("Auto jump", "Автопрыжок", "Авто секіру", "Автострибок"), "sgAutoJump")
    end)
    tog(tabMisc, L("Spin", "Вращение", "Айналу", "Обертання"), "spinOn", nil, function(tabMisc)
        inp(tabMisc, L("Spin speed", "Скорость вращения", "Айналу жылдамдығы", "Швидкість обертання"),
            CFG.spinSpeed, "20, 200, 5000...", function(text)
                local n = tonumber(text)
                if n and n == n then CFG.spinSpeed = math.clamp(n, 20, 1e12) end
            end)
    end)
    tog(tabMisc, L("Invisible", "Невидимость", "Көрінбейтін", "Невидимість"), "invis")
    sec(tabMisc, "Anti-Aim")
    tog(tabMisc, "Anti-aim", "aaDesync", nil, false)
    tog(tabMisc, "auto jump bomb", "autoJumpBomb")
    sec(tabMisc, L("Models", "Модели", "Модельдер", "Моделі"))
    tog(tabMisc, L("Custom model", "Своя модель", "Өз моделі", "Своя модель"), "customChar", function(v)
        if not v then CFG.tung = false end
    end, function(tabMisc)
        sld(tabMisc, L("Model size", "Размер модели", "Модель өлшемі", "Розмір моделі"), "charScale", 0.3, 3, 0.05)
        sld(tabMisc, L("Model rotation", "Поворот модели", "Модельді бұру", "Поворот моделі"), "charYaw", -180, 180, 5)
        sld(tabMisc, L("Model height", "Высота модели", "Модель биіктігі", "Висота моделі"), "charY", -5, 5, 0.1)
        inp(tabMisc, L("Model ID", "ID модели", "Модель ID", "ID моделі"), tostring(CFG.charModelId), "model id", function(text)
            local id = tostring(text or ""):match("%d+")
            if id then CFG.charModelId = id end
        end)
    end)
    FX.MODELS = FX.MODELS or {
        {label = "Kotost", id = "117318033999248"},
        {label = "Tung Tung Sahur", id = "138151705692565", tung = true},
        {label = "Fortnite", id = "13086442541"},
        {label = "Villager", id = "90405905565781"},
    }
    if tabMisc.ImageGrid then
        tabMisc:ImageGrid({
            Title = "models",
            GetItems = function()
                local out = {}
                for _, m in ipairs(FX.MODELS) do
                    out[#out + 1] = {label = m.label, id = m.id, tung = m.tung, image = "rbxthumb://type=Asset&id=" .. m.id .. "&w=150&h=150"}
                end
                return out
            end,
            OnClick = function(it)
                if it.tung then
                    CFG.customChar = false
                    CFG.tung = true
                else
                    CFG.tung = false
                    CFG.charModelId = it.id
                    CFG.customChar = true
                end
                if FX.notify then FX.notify("Model", it.label) end
            end,
        })
    end
    sec(tabMisc, L("Cosmetics", "Косметика", "Косметика", "Косметика"))
    tog(tabMisc, "Fake Korblox", "fakeKorblox")
    tog(tabMisc, "Fake Headless", "fakeHeadless")
    sec(tabMisc, L("Farm", "Фарм", "Ферма", "Фарм"))
    tog(tabMisc, "farm dashboard", "farmDash")
    tog(tabMisc, L("Auto farm", "Авто-фарм", "Авто ферма", "Авто-фарм"), "farm", nil, function(tabMisc)
        dd(tabMisc, "Method", {"Basic", "Fast", "Teleport", "Up", "Down", "Fake lag"}, CFG.farmMethod, function(v)
            CFG.farmMethod = val(v)
        end)
        sld(tabMisc, "speed", "farmSpeed", 10, 40, 1)
        tog(tabMisc, "avoid murd", "avoidMurder")
        tog(tabMisc, "avoid sheriff", "avoidSheriff")
        tog(tabMisc, "avoid sheriff (murd)", "avoidSherAsMurd")
        tog(tabMisc, "avoid murd (sheriff)", "avoidMurdAsSheriff")
        tog(tabMisc, "avoid murd (inno)", "avoidMurdAsInno")
        tog(tabMisc, "avoid zombies (surv)", "infAvoidZombies")
        tog(tabMisc, "avoid survs (zombie)", "infAvoidSurvivors")
        tog(tabMisc, "Auto buy battlepass", "autoBattlePass")
        tog(tabMisc, "quests on full bag", "questsBagFull")
        tog(tabMisc, "quests", "questsAlways")
        tog(tabMisc, "lobby on full bag", "bagLobby")
        tog(tabMisc, "fling murd after lobby", "lobbyFlingMurd")
        tog(tabMisc, "fling sheriff after lobby", "lobbyFlingSher")
        tog(tabMisc, "fling all after lobby", "lobbyFlingAll")
        tog(tabMisc, "reset on full bag", "bfReset")
        tog(tabMisc, "kill murd on full bag", "bfKillMurder")
        tog(tabMisc, "kill all on full bag", "bfKillAll")
        tog(tabMisc, "zombie: kill all on full bag", "bfInfKillAll")
        tog(tabMisc, "surv: kill zombies on full bag", "bfInfKillZombies")
        tog(tabMisc, "fling murd after reset", "flingAfterMurd")
        tog(tabMisc, "fling sheriff after reset", "flingAfterSher")
        tog(tabMisc, "fling all after reset", "flingAfterAll")
        tog(tabMisc, "rejoin on kick", "autoRejoin")
    end)
    sec(tabMisc, "Anti")
    tog(tabMisc, "anti", "antiOn", nil, function(tabMisc)
        tog(tabMisc, "fling", "antiFlingSel")
        tog(tabMisc, "afk", "antiAfkSel")
        tog(tabMisc, "trap", "antiTrapSel")
    end)
    sec(tabMisc, L("Trade", "Трейд", "Сауда", "Трейд"))
    tog(tabMisc, L("Trade helper", "Трейд хелпер", "Сауда көмекшісі", "Трейд хелпер"), "tradeHelper", function(v)
        if v and FX.loadValues then FX.loadValues(false) end
    end, function(tabMisc)
        btn(tabMisc, "update values", function()
            if FX.loadValues then FX.loadValues(true) end
        end)
    end)


    local tabAvatar = newTab("Avatar", "user")
    sec(tabAvatar, "avatar")
    if tabAvatar.PlayerGrid then
        FX.avatarGrid = tabAvatar:PlayerGrid({Title = "avatars", Selected = {}, GetPlayers = function()
            local out = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then out[#out + 1] = p end
            end
            return out
        end, OnClick = function(p)
            if FX.copyAvatar then FX.copyAvatar(p) end
        end})
    end
    btn(tabAvatar, "reset", function()
        if FX.resetAvatar then FX.resetAvatar() end
    end)

    local tabFling = newTab(L("Fling", "Флинг", "Флинг", "Флінг"), "wind")
    sec(tabFling, L("Fling", "Флинг", "Флинг", "Флінг"))
    btn(tabFling, L("Fling Sheriff", "Флинг шерифа", "Шерифті ұшыру", "Флінг шерифа"), function() FX.flingKind("Sheriff") end)
    btn(tabFling, L("Fling Murderer", "Флинг убийцы", "Өлтірушіні ұшыру", "Флінг вбивці"), function() FX.flingKind("Murderer") end)
    btn(tabFling, L("Fling All", "Флинг всех", "Барлығын ұшыру", "Флінг усіх"), function() FX.flingKind("All") end)
    local names = FX.playerNames()
    selectedPlayer = selectedPlayer or names[1]
    flDrop = dd(tabFling, L("Fling Player", "Флинг игрока", "Ойыншыны ұшыру", "Флінг гравця"), names, selectedPlayer, function(v)
        selectedPlayer = val(v)
    end)
    btn(tabFling, L("Fling selected player", "Флинг выбранного игрока", "Таңдалған ойыншыны ұшыру", "Флінг обраного гравця"), function()
        FX.flingPlayer(selectedPlayer)
    end)
    tog(tabFling, "Touch Fling", "touchFling")
    tog(tabFling, L("Auto fling sheriff", "Авто-флинг шерифа", "Шерифті авто ұшыру", "Авто-флінг шерифа"), "flingSheriffAuto")
    tog(tabFling, L("Auto fling murderer", "Авто-флинг убийцы", "Өлтірушіні авто ұшыру", "Авто-флінг вбивці"), "flingMurderAuto")
    tog(tabFling, L("Auto Fling", "Авто-флинг", "Авто ұшыру", "Авто-флінг"), "flingAuto", nil, function(tabFling)
        sld(tabFling, L("Fling time", "Время флинга", "Ұшыру уақыты", "Час флінга"), "flingTime", 1, 5, 0.1)
        sld(tabFling, L("Spin power", "Сила вращения", "Айналу күші", "Сила обертання"), "spin", 20000, 150000, 5000)
    end)
    sec(tabFling, L("Players", "Игроки", "Ойыншылар", "Гравці"))
    FX.flingSel = FX.flingSel or {}
    if tabFling.PlayerGrid then
        FX.flingGrid = tabFling:PlayerGrid({Title = "players", Selected = FX.flingSel, GetPlayers = function()
            local out = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then out[#out + 1] = p end
            end
            return out
        end})
    end
    btn(tabFling, L("Fling selected", "Флинг выбранных", "Таңдалғандарды ұшыру", "Флінг обраних"), function()
        local any = false
        for name in pairs(FX.flingSel) do
            if Players:FindFirstChild(name) then
                any = true
                FX.flingPlayer(name)
            else
                FX.flingSel[name] = nil
            end
        end
        if not any and FX.notify then FX.notify("Zenith", "Tap players first") end
    end)
    btn(tabFling, L("Select all", "Выбрать всех", "Барлығын таңдау", "Обрати всіх"), function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then FX.flingSel[p.Name] = true end
        end
        if FX.flingGrid then FX.flingGrid:Refresh() end
    end)
    btn(tabFling, L("Clear selection", "Снять выбор", "Таңдауды алу", "Зняти вибір"), function()
        table.clear(FX.flingSel)
        if FX.flingGrid then FX.flingGrid:Refresh() end
    end)
    local tabAnim = newTab(L("Anims", "Анимации", "Анимациялар", "Анімації"), "person-standing")
    sec(tabAnim, L("Animations", "Анимации", "Анимациялар", "Анімації"))
    local PACK_BUNDLE = {
        Zombie = 80, Ninja = 75, Robot = 82, Stylish = 83, Cartoony = 56, Superhero = 81, Knight = 68,
        Levitation = 79, Astronaut = 34, Vampire = 33, Werewolf = 32, Toy = 43, Pirate = 55, Elder = 48,
        Mage = 63, Bubbly = 39, Rthro = 356, Oldschool = 667,
    }
    if tabAnim.ImageGrid then
        local packGrid
        packGrid = tabAnim:ImageGrid({
            Title = "packs",
            GetItems = function()
                local out = {}
                for _, name in ipairs(FX.ANIM_NAMES or {}) do
                    if name ~= "Default" then
                        local b = PACK_BUNDLE[name]
                        out[#out + 1] = {
                            label = name,
                            image = b and ("rbxthumb://type=BundleThumbnail&id=" .. b .. "&w=150&h=150") or "",
                            pack = name,
                            selected = CFG.animPack == name,
                        }
                    end
                end
                return out
            end,
            OnClick = function(it)
                CFG.animPack = (CFG.animPack == it.pack) and "Default" or it.pack
                for _, k in ipairs({"animIdle", "animWalk", "animRun", "animJump", "animFall", "animClimb"}) do CFG[k] = "Default" end
                task.spawn(function()
                    local ok = pcall(FX.applyAnims)
                    if not ok and FX.notify then FX.notify("Zenith", "Animate script not found") end
                end)
                task.defer(function() pcall(function() packGrid:Refresh() end) end)
            end,
        })
    end
    sec(tabAnim, L("Emotes", "Эмоции", "Эмоциялар", "Емоції"))
    if tabAnim.ImageGrid then
        local eg
        eg = tabAnim:ImageGrid({
            Title = "emotes",
            GetItems = function()
                local out = {}
                for _, name in ipairs(FX.EMOTE_NAMES or {}) do
                    local ids = FX.EMOTES and FX.EMOTES[name]
                    local id = ids and ids[#ids]
                    out[#out + 1] = {
                        label = name,
                        image = id and ("rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150") or "",
                        selected = FX.lastEmote == name,
                        emote = name,
                    }
                end
                return out
            end,
            OnClick = function(it)
                if FX.lastEmote == it.emote then
                    FX.stopEmote()
                else
                    CFG.emote = it.emote
                    if not FX.playEmote(it.emote) and FX.notify then FX.notify("Zenith", "R15 only") end
                end
                task.defer(function() pcall(function() eg:Refresh() end) end)
            end,
        })
    end
    tog(tabAnim, L("Loop emote", "Повторять эмоцию", "Эмоцияны қайталау", "Повторювати емоцію"), "emoteLoop", nil, function(tabAnim)
        sld(tabAnim, L("Emote speed", "Скорость эмоции", "Эмоция жылдамдығы", "Швидкість емоції"), "emoteSpeed", 0.25, 3, 0.05)
    end)
    local tabTp = newTab(L("Teleport", "Телепорт", "Телепорт", "Телепорт"), "map-pin")
    sec(tabTp, L("Teleport", "Телепорт", "Телепорт", "Телепорт"))
    btn(tabTp, L("TP Lobby", "ТП в лобби", "Лоббиге ТП", "ТП в лобі"), tpLobby)
    btn(tabTp, L("TP Map", "ТП на карту", "Картаға ТП", "ТП на мапу"), tpMap)
    sec(tabTp, L("Players", "Игроки", "Ойыншылар", "Гравці"))
    if tabTp.PlayerGrid then
        FX.tpGrid = tabTp:PlayerGrid({Title = "players", Selected = {}, GetPlayers = function()
            local out = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then out[#out + 1] = p end
            end
            return out
        end, OnClick = function(p)
            local c, r = nil, nil
            if p and p.Parent then c, r = aliveChar(p) end
            local hrp = myHrp()
            if r and hrp then
                hrp.CFrame = r.CFrame * CFrame.new(0, 0, 3)
            elseif FX.notify then
                FX.notify("Zenith", p.DisplayName .. " is dead")
            end
        end})
    end
    sec(tabTp, L("Gun", "Пистолет", "Мылтық", "Пістолет"))
    btn(tabTp, L("Teleport Gun", "Телепорт к пистолету", "Мылтыққа телепорт", "Телепорт до пістолета"), function()
        local hrp = myHrp()
        local part = drop and drop.Parent and partOf(drop)
        if part and hrp then
            hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        elseif FX.notify then
            FX.notify("Zenith", "No dropped gun")
        end
    end)

    local tabMaps = newTab(L("Maps", "Карты", "Карталар", "Карти"), "map-pin")
    sec(tabMaps, "maps")
    if tabMaps.ImageGrid then
        local grid = tabMaps:ImageGrid({
            Title = "maps",
            Empty = L("Maps show up here after the first vote", "Карты появятся после первого голосования", "Карталар алғашқы дауыстан кейін шығады", "Карти з'являться після першого голосування"),
            GetItems = function() return FX.mapBook and FX.mapBook() or {} end,
            OnClick = function(it)
                FX.voteWantClick(it)
                task.defer(function() pcall(function() FX.voteGrid:Refresh() end) end)
            end,
        })
        FX.voteGrid = grid
        task.spawn(function()
            local last = ""
            while running and FX.voteGrid == grid do
                local sig = {}
                for _, it in ipairs(FX.mapBook and FX.mapBook() or {}) do sig[#sig + 1] = it.label .. it.image .. tostring(it.selected) end
                sig = table.concat(sig, "|")
                if sig ~= last then
                    last = sig
                    pcall(function() grid:Refresh() end)
                end
                task.wait(1)
            end
        end)
    end


    local tabBtn = newTab(L("Buttons", "Кнопки", "Батырмалар", "Кнопки"), "wrench")
    sec(tabBtn, L("Buttons", "Кнопки", "Батырмалар", "Кнопки"))
    tog(tabBtn, "shoot button", "shootBtn", function(v)
        setShootBtn(v)
    end, function(tabBtn)
        sld(tabBtn, "x", "shootBtnX", 0, 100, 1)
        sld(tabBtn, "y", "shootBtnY", 0, 100, 1)
    end)
    tog(tabBtn, "invis button", "invisBtn", nil, function(tabBtn)
        sld(tabBtn, "x", "invisBtnX", 0, 100, 1)
        sld(tabBtn, "y", "invisBtnY", 0, 100, 1)
    end)
    tog(tabBtn, "jump button", "jumpBtn", nil, function(tabBtn)
        sld(tabBtn, "x", "jumpBtnX", 0, 100, 1)
        sld(tabBtn, "y", "jumpBtnY", 0, 100, 1)
    end)
    for _, d in ipairs(FX.extraBtnDefs or {}) do
        tog(tabBtn, d.label .. " button", d.key, nil, function(t)
            sld(t, "x", d.key .. "X", 0, 100, 1)
            sld(t, "y", d.key .. "Y", 0, 100, 1)
        end)
    end
    tog(tabBtn, "jump bomb button", "jumpBombBtn", nil, function(tabBtn)
        sld(tabBtn, "x", "jbbX", 0, 100, 1)
        sld(tabBtn, "y", "jbbY", 0, 100, 1)
    end)

    local tabChat = newTab(L("Chat", "Чат", "Чат", "Чат"), "globe")
    sec(tabChat, L("Zenith users", "Пользователи Zenith", "Zenith қолданушылары", "Користувачі Zenith"))
    if tabChat.Chat then
        local chat = tabChat:Chat({
            Note = "chat",
            Placeholder = L("Message...", "Сообщение...", "Хабарлама...", "Повідомлення..."),
            SendText = L("SEND", "ОТПР.", "ЖІБЕРУ", "НАДІСЛ."),
            OnSend = function(t) FX.chatSend(t) end,
        })
        for _, e in ipairs(FX.chatLog or {}) do chat:Add(e) end
        FX.chatAdd = function(e) chat:Add(e) end
    end

    local tabSet = newTab(L("Settings", "Настройки", "Баптаулар", "Налаштування"), "settings")
    sec(tabSet, L("Interface", "Интерфейс", "Интерфейс", "Інтерфейс"))
    sld(tabSet, "ui size", "uiScale", 0.1, 3, 0.1, function(v)
        if FX.window and FX.window.SetScale then pcall(function() FX.window:SetScale(v) end) end
    end)
    tog(tabSet, L("Watermark", "Ватермарк", "Су белгісі", "Водяний знак"), "watermark", nil, function(t)
        tog(t, "user", "wmUser")
        tog(t, "fps", "wmFps")
        tog(t, "ping", "wmPing")
        tog(t, "time", "wmTime")
        tog(t, "subscription time", "wmSub")
        tog(t, "config name", "wmCfg")
        tog(t, "game name", "wmGame")
        tog(t, "executor", "wmExec")
        tog(t, "ram gb", "wmRamGb")
        tog(t, "ram mb", "wmRamMb")
    end)
    tog(tabSet, L("Round timer", "Таймер раунда", "Раунд таймері", "Таймер раунду"), "roundTimer")
    tog(tabSet, "hotkeys", "bindHud", function(v)
        if FX.nlSetHud then FX.nlSetHud("Hotkeys", v == true) end
    end)
    sec(tabSet, L("Sound", "Звук", "Дыбыс", "Звук"))
    tog(tabSet, "sounds", "replaceSnd", function(v)
        if not v then pcall(SND.restore) end
    end, function(tabSet)
        dd(tabSet, "gun sound", SND.gunNames, CFG.gunSnd, function(v)
            CFG.gunSnd = val(v)
        end)
        sld(tabSet, L("Gun volume", "Громкость пистолета", "Мылтық дыбыс деңгейі", "Гучність пістолета"), "gunVol", 0, 10, 0.1)
        dd(tabSet, "murder sound", SND.knifeNames, CFG.knifeSnd, function(v)
            CFG.knifeSnd = val(v)
        end)
        sld(tabSet, L("Knife volume", "Громкость ножа", "Пышақ дыбыс деңгейі", "Гучність ножа"), "knifeVol", 0, 10, 0.1)
    end)
    tog(tabSet, "kill sound", "killSnd", function(v)
        if not v then pcall(SND.restore) end
    end, function(tabSet)
        dd(tabSet, "sound", SND.killNames, CFG.killSndName, function(v)
            CFG.killSndName = val(v)
        end)
        sld(tabSet, L("Kill volume", "Громкость убийства", "Өлтіру дыбыс деңгейі", "Гучність вбивства"), "killVol", 0, 10, 0.1)
    end)
    sec(tabSet, L("Online", "Онлайн", "Онлайн", "Онлайн"))
    dd(tabSet, "menu background", {"None", "Space", "Geometry", "Triangles"}, CFG.menuBg, function(v)
        CFG.menuBg = val(v)
        if FX.drawMenuBg then pcall(FX.drawMenuBg) end
    end)
    tog(tabSet, "click sound", "uiSound")
    dd(tabSet, "profile frame", {"None", "Gold", "Neon", "Ruby", "Ice", "Violet"}, CFG.chatFrame, function(v)
        CFG.chatFrame = val(v)
    end)
    if tabSet.Label then
        local onl = tabSet:Label({Title = "online: " .. tostring(FX.online and FX.online() or "...")})
        FX.onlineSet = function(n)
            onl:Set("online: " .. tostring(n))
        end
    end
    sec(tabSet, L("Performance", "Производительность", "Өнімділік", "Продуктивність"))
    tog(tabSet, L("Optimization", "Оптимизация", "Оңтайландыру", "Оптимізація"), "optimize")
    tog(tabSet, L("Unlock FPS", "Разблокировать FPS", "FPS шектеуін алу", "Розблокувати FPS"), "fpsUnlock", function()
        FX.applyFps()
    end)

    sec(tabSet, L("Utility", "Утилиты", "Утилиталар", "Утиліти"))
    tog(tabSet, L("Role notifications", "Уведомления о ролях", "Рөлдер туралы хабарлама", "Сповіщення про ролі"), "roleNotify")
    tog(tabSet, L("Gun drop alert", "Оповещение о выпавшем пистолете", "Мылтық түскені туралы хабарлама", "Сповіщення про випадений пістолет"), "gunNotify")
    tog(tabSet, L("Spectate murderer", "Следить за убийцей", "Өлтірушіні бақылау", "Стежити за вбивцею"), "specMurd")
    tog(tabSet, L("Spectate sheriff", "Следить за шерифом", "Шерифті бақылау", "Стежити за шерифом"), "specSher")
    btn(tabSet, L("Rejoin server", "Перезайти на сервер", "Серверге қайта кіру", "Перезайти на сервер"), function() FX.rejoin() end)

    sec(tabSet, L("Config", "Конфиг", "Конфиг", "Конфіг"))
    CFG.coinEsp, CFG.trailSmoke = false, false
    local cfgName = FX.cfgGetAuto() or "default"
    if cfgName == "" then cfgName = "default" end
    inp(tabSet, L("Config name", "Имя конфига", "Конфиг атауы", "Назва конфігу"), cfgName, "default", function(t)
        local n = tostring(t or ""):gsub("[^%w_%-]", "")
        if n ~= "" then cfgName = n FX.curCfg = n end
    end)
    local cfgDD = dd(tabSet, L("Saved configs", "Сохранённые конфиги", "Сақталған конфигтер", "Збережені конфіги"), FX.cfgList(), cfgName, function(v)
        cfgName = val(v) or cfgName
        FX.curCfg = cfgName
    end)
    local function refreshCfg()
        if cfgDD then pcall(function() cfgDD:Refresh(FX.cfgList()) end) end
    end
    btn(tabSet, L("Save config", "Сохранить конфиг", "Конфигті сақтау", "Зберегти конфіг"), function()
        local ok, err = FX.cfgSave(cfgName)
        refreshCfg()
        if FX.notify then FX.notify("Zenith", ok and ("Saved: " .. cfgName) or ("Save failed: " .. tostring(err))) end
    end)
    btn(tabSet, L("Load config", "Загрузить конфиг", "Конфигті жүктеу", "Завантажити конфіг"), function()
        local ok, err = FX.cfgLoad(cfgName)
        if FX.notify then FX.notify("Zenith", ok and ("Loaded: " .. cfgName) or ("Load failed: " .. tostring(err))) end
        if ok then
            genv.ZenithLang = CFG.lang
            setShaders(CFG.shaders)
            pcall(setShootBtn, CFG.shootBtn == true)
            CFG.auraRange, CFG.hitDelay = 1e6, 0.1
CFG.killTool = false
CFG.health = false
CFG.predMul, CFG.predMulAS = 1, 1
CFG.flingMethod = "Bypass"
CFG.blackSky = false
if CFG.farmMethod == "Ground" then CFG.farmMethod = "Basic" end
CFG.aaHeight, CFG.aaSpin = 60, true
CFG.theme = "Black"
            CFG.shootDelay, CFG.shootMax, CFG.wbStyle = 0.1, 1e9, "Attachment"
            task.spawn(function() pcall(FX.applyAnims) end)
            task.delay(0.3, rebuildUI)
        end
    end)
    btn(tabSet, L("Get share code", "Получить код", "Бөлісу кодын алу", "Отримати код"), function()
        local code = FX.cfgShareCode()
        local copied = Compat.setclipboard and pcall(Compat.setclipboard, code)
        if FX.notify then FX.notify("Zenith", copied and "Share code copied" or code) end
    end)
    local shareText = ""
    inp(tabSet, L("Share code", "Код конфига", "Бөлісу коды", "Код конфігу"), "", "ZEN-...", function(t)
        shareText = tostring(t or "")
    end)
    btn(tabSet, L("Load share code", "Загрузить по коду", "Код бойынша жүктеу", "Завантажити за кодом"), function()
        local ok, res = FX.cfgFromShare(shareText)
        if FX.notify then FX.notify("Zenith", ok and "Config loaded from code" or ("Code error: " .. tostring(res))) end
        if ok then
            pcall(setShaders, CFG.shaders)
            pcall(setShootBtn, CFG.shootBtn == true)
            task.spawn(function() pcall(FX.applyAnims) end)
            task.delay(0.3, rebuildUI)
        end
    end)
    btn(tabSet, L("Delete config", "Удалить конфиг", "Конфигті жою", "Видалити конфіг"), function()
        FX.cfgDelete(cfgName)
        refreshCfg()
    end)
    btn(tabSet, L("Set as autoload", "Загружать при запуске", "Іске қосқанда жүктеу", "Завантажувати при запуску"), function()
        FX.cfgSetAuto(cfgName)
        if FX.notify then FX.notify("Zenith", "Autoload: " .. cfgName) end
    end)
    btn(tabSet, L("Disable autoload", "Выключить автозагрузку", "Авто жүктеуді өшіру", "Вимкнути автозавантаження"), function()
        FX.cfgSetAuto("")
    end)

    sec(tabSet, L("Script", "Скрипт", "Скрипт", "Скрипт"))
    btn(tabSet, L("Unload", "Выгрузить скрипт", "Скриптті өшіру", "Вивантажити скрипт"), function()
        if genv.ZenithWind then genv.ZenithWind() end
    end)
end

do
    local auto = FX.cfgGetAuto and FX.cfgGetAuto()
    if auto and auto ~= "" then
        local ok = FX.cfgLoad(auto)
        if ok then
            genv.ZenithLang = CFG.lang
            pcall(setShaders, CFG.shaders)
            task.spawn(function() pcall(FX.applyAnims) end)
        end
    end
end

ZUI.rebuild = rebuildUI
do
    local hidden = {}
    local function hideOurs(on)
        local roots = {}
        pcall(function() roots[#roots + 1] = (Compat.gethui and Compat.gethui()) or game:GetService("CoreGui") end)
        pcall(function() roots[#roots + 1] = lp:FindFirstChild("PlayerGui") end)
        for _, r in ipairs(roots) do
            for _, gui in ipairs(r:GetChildren()) do
                if gui:IsA("ScreenGui") and string.sub(gui.Name, 1, 6) == "Zenith" and gui.Name ~= "ZenithLoading" then
                    if on then
                        if gui.Enabled then
                            hidden[gui] = true
                            gui.Enabled = false
                        end
                    elseif hidden[gui] then
                        gui.Enabled = true
                    end
                end
            end
        end
        if not on then hidden = {} end
    end
    local okUI, errUI = pcall(buildUI)
    if not ZLoad.gone then
        pcall(hideOurs, true)
        task.spawn(function()
            local t0 = tick()
            while not ZLoad.gone and tick() - t0 < 30 do
                pcall(hideOurs, true)
                task.wait(0.1)
            end
            pcall(hideOurs, false)
        end)
    end
    if not okUI then
        warn("[Zenith] menu error: " .. tostring(errUI))
        pcall(showError, "Zenith menu error: " .. tostring(errUI))
    end
    task.delay(1.2, function() if ZLoad.done then ZLoad.done() end end)
end

local function refreshPlayers()
    if FX.flingGrid then pcall(function() FX.flingGrid:Refresh() end) end
    if FX.tpGrid then pcall(function() FX.tpGrid:Refresh() end) end
    if FX.avatarGrid then pcall(function() FX.avatarGrid:Refresh() end) end
    if flDrop then pcall(function() flDrop:Refresh(FX.playerNames()) end) end
    if FX.tpDD then pcall(function() FX.tpDD:Refresh(FX.playerNames()) end) end
end
connect(Players.PlayerAdded, function() task.defer(refreshPlayers) end)
connect(Players.PlayerRemoving, function() task.defer(refreshPlayers) end)

setShootBtn(CFG.shootBtn == true)
CFG.auraRange, CFG.hitDelay = 1e6, 0.1
CFG.shootDelay, CFG.shootMax, CFG.wbStyle = 0.1, 1e9, "Attachment"

genv.ZenithWind = function()
    running = false
    for _, k in ipairs({"autoShoot", "autoGun", "autoKill", "farm", "fly", "noclip", "flingAuto", "antiFling",
                        "wsOn", "jpOn", "bhop", "spinOn", "xray", "aura", "helper", "trail", "shotTrail", "silent",
                        "bodyGlow", "crown", "groundRing", "elemAura", "nameTag", "aaOn", "speedGlitch", "ribbon", "potato", "tung", "studs", "orbitStars", "auraSphere", "footSparkle", "powerAura", "hitboxOn", "reachOn", "murderAlert",
                        "fullbright", "fovOn", "infJump", "roleNotify", "customChar", "gunSkin", "knifeSkin", "chinaHat",
                        "specMurd", "specSher", "weaponEsp", "watermark"}) do
        CFG[k] = false
    end
    ST.on, ST.aimPos, ST.target, ST.lastShot = false, nil, nil, nil
    pcall(flyStop)
    pcall(FX.spinStop)
    pcall(FX.xrRestore)
    pcall(FX.shadersOff)
    pcall(removeAura)
    pcall(removeHelper)
    pcall(FX.clearCos)
    pcall(FX.restoreHB)
    pcall(FX.restoreReach)
    pcall(FX.restoreUtil)
    pcall(FX.restoreModels)
    pcall(FX.restoreMatChams)
    pcall(FX.restoreWeapons)
    pcall(FX.wmDestroy)
    pcall(FX.farmDashOff)
    pcall(FX.resetAvatar)
    pcall(FX.jumpBtnOff)
    pcall(FX.hitLogOff)
    pcall(FX.skyOff)
    pcall(FX.invisBtnOff)
    pcall(FX.presetOff)
    pcall(FX.rainOff)
    pcall(FX.bindHudDestroy)
    pcall(FX.ghostOff)
    pcall(FX.infOff)
    pcall(FX.wepChamsOff)
    pcall(FX.aaOff)
    pcall(FX.selfChamsOff)
    pcall(FX.crossOff)
    pcall(FX.cosmeticsOff)
    pcall(FX.timerDestroy)
    if CFG.fpsUnlock and Compat.setfpscap then pcall(Compat.setfpscap, 60) end
    for _, e in pairs(E) do
        if e.av then pcall(function() e.av:Destroy() end) end
    end
    pcall(FX.tungClear)
    pcall(FX.studsRestore)
    pcall(FX.aaRestore)
    pcall(FX.ribbonClear)
    pcall(FX.potatoRestore)
    pcall(FX.stopEmote)
    pcall(function() FX.trailModel:Destroy() end)
    pcall(SND.restore)
    pcall(function()
        if holding then surface() end
    end)
    pcall(function()
        local md = FX.mov()
        if md.hum then
            if md.ws then md.hum.WalkSpeed = md.ws end
            if md.jp then md.hum.JumpPower = md.jp end
        end
    end)
    for part in pairs(FX.ncSaved) do
        if part.Parent then part.CanCollide = true end
    end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, e in pairs(E) do
        if e.cc then pcall(function() e.cc:Disconnect() end) end
        if e.hl then pcall(function() e.hl:Destroy() end) end
    end
    for _, d in ipairs(draws) do pcall(function() d:Remove() end) end
    for _, c in pairs(circles) do pcall(function() c:Remove() end) end
    for _, l in pairs(lines) do pcall(function() l:Remove() end) end
    for _, h in pairs(hls) do pcall(function() h:Destroy() end) end
    pcall(function() FX.trailFolder:Destroy() end)
    pcall(function() FX.shotFolder:Destroy() end)
    local g = drop and drop:FindFirstChild("GunESP")
    if g then pcall(function() g:Destroy() end) end
    local hrp = myHrp()
    if hrp then
        for _, n in ipairs({"ZenithSmoke", "ZenithHold", "ZenithSpin", "ZenithFly", "ZenithFlyGyro", "ZenithFlingBV"}) do
            local o = hrp:FindFirstChild(n)
            if o then pcall(function() o:Destroy() end) end
        end
    end
    pcall(function() FX.btnGui:Destroy() end)
    pcall(function() FX.openGui:Destroy() end)
    if Window then pcall(function() Window:Destroy() end) end
    genv.ZenithWind = nil
end

end
return xpcall(runZenith, showStartupError, ...)
