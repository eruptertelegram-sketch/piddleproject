-- PIDDLE MM2 v8 - PC + Mobile
warn("[PIDDLE] loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WS = workspace
local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera

local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local HttpService = safe(function() return game:GetService("HttpService") end)

local pg = LP:WaitForChild("PlayerGui")
for _, n in ipairs({"PiddleGui","PiddleWatermark","PiddleDropdowns","TouchFlingWindow","AntiFlingIndicator"}) do
    local o = pg:FindFirstChild(n)
    if o then safe(function() o:Destroy() end) end
end

local LOGO = "rbxassetid://116621850916845"
local BG_LIST = {
    { name = "Anime Style", id = "rbxassetid://83690600042971" },
    { name = "Halloween",   id = "rbxassetid://85303808547863" },
    { name = "Old",         id = "rbxassetid://123694970390583" },
    { name = "Dark Night",  id = "rbxassetid://79020220019422" },
    { name = "Night Rain",  id = "rbxassetid://107306683089605" },
}
local BG = BG_LIST[2].id

local ICO = {
    Home = "rbxassetid://7539983780",
    Combat = "rbxassetid://103289157776464",
    Visual = "rbxassetid://103289157776464",
    Players = "rbxassetid://2795572803",
    Farm = "rbxassetid://9405931596",
    Teleport = "rbxassetid://137182874573549",
    Fling = "rbxassetid://137182874573549",
    Move = "rbxassetid://7539983780",
    Dodge = "rbxassetid://2795572803",
    Bg = "rbxassetid://9405931596",
    Music = "rbxassetid://103289157776464",
    Config = "rbxassetid://9405931596",
    Misc = "rbxassetid://2795572803",
    Vote = "rbxassetid://137182874573549",
    Player = "rbxassetid://2795572803",
    Settings = "rbxassetid://9405931596",
    Chevron = "rbxassetid://10709790948",
    Close = "rbxassetid://10747384394",
}

local S = {
    home="Home", combat="Combat", visual="Visual", players="Players", farm="Farm",
    teleport="Teleport", fling="Fling", movement="Movement", dodge="Dodge",
    background="Background", music="Music", config="Config", misc="Misc",
    player="Player", settings="Settings", vote="Vote",
    general="General", save_cfg="Save Config", load_cfg="Load Config", ui_size="UI Size",
    respawn="Respawn", rejoin="Rejoin", esp="ESP",
    esp_murderer="ESP Murderer", esp_sheriff="ESP Sheriff", esp_innocent="ESP Innocent",
    esp_hero="ESP Hero", esp_gun="ESP Gun", esp_all="ESP All", esp_npc="ESP NPC",
    esp_nametag="ESP NameTag", esp_distance="ESP Distance",
    aimlock="Aimlock", aimlock_murder="Aimlock Murderer", aimlock_predict="Predict",
    aimlock_smooth="Smoothness", kill_aura="Kill Aura",
    auto_knife="Auto-Knife", auto_throw="Auto-Throw",
    auto_shoot="Auto-Shoot", auto_reload="Auto-Reload",
    lighting="Lighting", bright="Fullbright", no_fog="No Fog", fov="Field of View",
    list_players="Player List", refresh_list="Refresh List",
    money="Money", farm_coins="Farm Coins", auto_get_gun="Auto Get Gun",
    select_player="Select Player", player_sel="Player", tp_selected="TP",
    fast_tp="Fast TP", tp_murderer="TP Murderer", tp_sheriff="TP Sheriff", tp_hero="TP Hero",
    fling_return="Return", fling_murderer="FLING Murderer", fling_sheriff="FLING Sheriff",
    fling_innocent="FLING Innocent", fling_hero="FLING Hero", fling_all="FLING All",
    stop_fling="Stop",
    speed="Speed", keep_speed="Keep Speed", jump_power="Jump Power",
    keep_jump="Keep Jump", auto_jump="Auto-Jump", fly="Fly", noclip="Noclip",
    spin="Spin", spin_speed="Spin Speed", spin_madness="SPIN MADNESS", stop_spin="Stop Spin",
    auto_dodge="Auto-Dodge", dodge_murderer="Dodge Murderer",
    auto_respawn="Auto-Respawn", fast_respawn="Fast-Respawn", anti_void="Anti-Void",
    bg_transparency="Image Transparency", ui_transparency="UI Transparency",
    wm_transparency="Watermark Transparency",
    tracks="Tracks", play="Play", pause="Pause", stop="Stop",
    next_track="Next", prev_track="Previous",
    custom_music="Custom ID", play_custom="Play Custom", volume="Volume", language="Language",
    animations="Animations", emotes="Emotes", outfits="Outfits",
    reset_char="Reset Character", custom_anim="Custom Animation ID",
    apply="Apply", stop_anim="Stop",
    vote_duper="Map Vote Duper", vote_refresh="Refresh Maps",
    vote_start="Start Duper", vote_stop="Stop Duper", vote_select="Vote",
    bg_chooser="Choose Background", multi_fling="Multi-Target Fling",
    refresh_targets="Refresh Targets", start_fling="START FLING",
    stop_all_fling="STOP ALL", select_all="SELECT ALL", deselect_all="DESELECT ALL",
    anti_fling="Anti-Fling",
}
local function T(k) return S[k] or k end

local hasFile = false
safe(function()
    hasFile = (type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function")
end)

local CFG = {
    tintTransparency = 0.72, bgTransparency = 0, wmTransparency = 0.2,
    speed = 16, jump = 50, volume = 50, musicId = "", uiScale = 1,
    flingReturnMode = "Original", language = "EN", bgName = "Halloween",
}
local function loadCFG()
    safe(function()
        if hasFile and HttpService and isfile("PiddleConfig.json") then
            local d = HttpService:JSONDecode(readfile("PiddleConfig.json"))
            for k,v in pairs(d) do CFG[k] = v end
        end
    end)
end
loadCFG()
local function saveCFG()
    if not hasFile or not HttpService then return end
    safe(function() writefile("PiddleConfig.json", HttpService:JSONEncode(CFG)) end)
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props) do safe(function() o[k] = v end) end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r)
    safe(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 10)
        c.Parent = o
    end)
end

-- ===== ROLES / HELPERS =====
local rolesCache, sheriffName = {}, nil
local function fetchRoles()
    safe(function()
        local r = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if r and r:IsA("RemoteFunction") then
            local res = r:InvokeServer()
            if res then rolesCache = res end
        end
    end)
end
local function isAlive(rd) return rd and not rd.Killed and not rd.Dead end
local function isNPC(plr)
    if plr == LP then return false end
    local ch = plr.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") or ch.Parent ~= WS then return true end
    local full = ch:GetFullName():lower()
    if full:find("lobby") or full:find("menu") or full:find("waiting") then return true end
    local h = ch:FindFirstChildOfClass("Humanoid")
    return h and h.Health <= 0
end
local function getRole(plr)
    local ok, r = pcall(function()
        if isNPC(plr) then return "NPC" end
        if rolesCache[plr.Name] and isAlive(rolesCache[plr.Name]) then
            local d = rolesCache[plr.Name]
            if d.Role == "Hero" then return "Hero" end
            if d.Role == "Sheriff" and sheriffName and not isAlive(rolesCache[sheriffName]) then return "Hero" end
            return d.Role or "Innocent"
        end
        local bp = plr:FindFirstChild("Backpack")
        local ch = plr.Character
        local hk = (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
        local hg = (ch and ch:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun"))
        if hk then return "Murderer" end
        if hg then return "Sheriff" end
        return "Innocent"
    end)
    return ok and r or "Innocent"
end
local function hasItem(plr, item)
    local bp = plr:FindFirstChild("Backpack")
    local ch = plr.Character
    return (bp and bp:FindFirstChild(item)) or (ch and ch:FindFirstChild(item))
end
local function findByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and getRole(p) == role then return p end
    end
end
local function findMurderer() return findByRole("Murderer") end
local function findSheriff() return findByRole("Sheriff") end
local function findHero() return findByRole("Hero") end
local function getTool(name)
    local ch = LP.Character; if not ch then return nil end
    local k = ch:FindFirstChild(name)
    if not k then local bp = LP:FindFirstChild("Backpack"); if bp then k = bp:FindFirstChild(name) end end
    return k
end
local function getKnife() return getTool("Knife") end
local function getGun() return getTool("Gun") end
local function isDead()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    return not h or h.Health <= 0
end
local function inVoting()
    local pgui = LP:FindFirstChild("PlayerGui")
    if pgui then
        for _, n in ipairs({"VoteGui","VotingGui","MapVoting","Vote","VoteMenu","Voting"}) do
            if pgui:FindFirstChild(n) then return true end
        end
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(1)
        safe(fetchRoles)
        sheriffName = nil
        for n, d in pairs(rolesCache) do
            if d and d.Role == "Sheriff" then sheriffName = n end
        end
    end
end)

-- ===== THEME (dark glass: background image stays visible) =====
local THEME = {
    text = Color3.fromRGB(245,245,250),
    textDim = Color3.fromRGB(195,195,210),
    stroke = Color3.fromRGB(255,255,255),
    panel = Color3.fromRGB(16,16,24),
    panelTrans = 0.5,
    buttonBg = Color3.fromRGB(255,255,255),
    buttonStroke = Color3.fromRGB(255,255,255),
    toggleOn = Color3.fromRGB(255,100,130),
    toggleOff = Color3.fromRGB(110,110,128),
    accentDark = Color3.fromRGB(255,100,130),
    closeBg = Color3.fromRGB(255,90,110),
    iconBg = Color3.fromRGB(255,255,255),
}
local RC = {
    Murderer = Color3.fromRGB(255,60,80),
    Sheriff = Color3.fromRGB(80,140,255),
    Innocent = Color3.fromRGB(80,220,120),
    Hero = Color3.fromRGB(255,220,80),
    Gun = Color3.fromRGB(255,180,60),
    NPC = Color3.fromRGB(170,170,180),
}
local UI_SCALE = CFG.uiScale or 1
do
    local vp = Cam.ViewportSize
    local fit = math.min(1, (vp.X - 20) / 640, (vp.Y - 20) / 420)
    if IS_MOBILE then fit = math.min(1, (vp.X - 20) / 540, (vp.Y - 20) / 400) end
    if fit < UI_SCALE then UI_SCALE = math.max(fit, 0.5) end
end

-- ===== WATERMARK =====
local wmGui = new("ScreenGui", {Name="PiddleWatermark", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=1000, Parent=pg})
local wm = new("TextButton", {
    Size=UDim2.new(0,220,0,38), Position=UDim2.new(0.5,-110,0,16),
    BackgroundColor3=THEME.panel,
    BackgroundTransparency=CFG.wmTransparency,
    BorderSizePixel=0, Text="", AutoButtonColor=false, Active=true, Parent=wmGui
})
round(wm, 19)
new("UIStroke", {Color=THEME.stroke, Transparency=0.75, Thickness=1}, wm)
new("ImageLabel", {
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(0,8,0,6),
    BackgroundTransparency=1, Image=LOGO, ScaleType=Enum.ScaleType.Fit, Parent=wm
})
new("TextLabel", {
    Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,40,0,0),
    BackgroundTransparency=1, Text="PIDDLE", TextColor3=THEME.text,
    Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, Parent=wm
})
local wmStats = new("TextLabel", {
    Size=UDim2.new(1,-140,1,0), Position=UDim2.new(0,132,0,0),
    BackgroundTransparency=1, Text="FPS -- | PING --", TextColor3=THEME.textDim,
    Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, Parent=wm
})
do
    local fc, lft, fps = 0, tick(), 60
    RunService.RenderStepped:Connect(function()
        fc = fc + 1
        if tick() - lft >= 1 then fps = fc; fc = 0; lft = tick() end
    end)
    task.spawn(function()
        while true do
            task.wait(1)
            local ping = 0
            safe(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            wmStats.Text = string.format("FPS %d | PING %d", fps, ping)
        end
    end)
end

-- ===== MAIN GUI =====
local ddGui = new("ScreenGui", {Name="PiddleDropdowns", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=2000, Parent=pg})
local gui = new("ScreenGui", {Name="PiddleGui", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999, Parent=pg})

local W, H = 640, 420
if IS_MOBILE then W, H = 540, 400 end
local main = new("Frame", {
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
    Size=UDim2.new(0,W,0,H), BackgroundColor3=Color3.fromRGB(10,10,16),
    BorderSizePixel=0, Active=true, Parent=gui
})
round(main, 24)
local uiScaleObj = new("UIScale", {Scale=UI_SCALE}, main)
new("UIStroke", {Color=THEME.stroke, Transparency=0.7, Thickness=1.5}, main)

local bgImg = new("ImageLabel", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Image=BG, ImageTransparency=CFG.bgTransparency,
    ScaleType=Enum.ScaleType.Crop, ZIndex=0, Parent=main
})
round(bgImg, 24)
local tint = new("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=CFG.tintTransparency, BorderSizePixel=0, ZIndex=1, Parent=main
})
round(tint, 24)

local function panelStyle(f, r)
    f.BackgroundColor3 = THEME.panel
    f.BackgroundTransparency = THEME.panelTrans
    f.BorderSizePixel = 0
    round(f, r)
    new("UIStroke", {Color=THEME.stroke, Transparency=0.82, Thickness=1}, f)
end

local header = new("Frame", {
    Position=UDim2.new(0,10,0,10), Size=UDim2.new(1,-20,0,50), ZIndex=2, Parent=main
})
panelStyle(header, 18)
new("ImageLabel", {
    Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,10,0,8),
    BackgroundTransparency=1, Image=LOGO, ScaleType=Enum.ScaleType.Fit, ZIndex=3, Parent=header
})
new("TextLabel", {
    Size=UDim2.new(0,300,0,24), Position=UDim2.new(0,52,0,7),
    BackgroundTransparency=1, Text="PIDDLE", TextColor3=THEME.text,
    Font=Enum.Font.GothamBlack, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3, Parent=header
})
new("TextLabel", {
    Size=UDim2.new(0,300,0,14), Position=UDim2.new(0,52,0,29),
    BackgroundTransparency=1, Text="MM2 | v8 | "..(IS_MOBILE and "Mobile" or "PC"), TextColor3=THEME.textDim,
    Font=Enum.Font.GothamMedium, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3, Parent=header
})
local closeBtn = new("TextButton", {
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-40,0,10),
    BackgroundColor3=THEME.closeBg, BackgroundTransparency=0.15, BorderSizePixel=0, Text="X",
    TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, ZIndex=3, Parent=header
})
round(closeBtn, 15)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local sidebar = new("Frame", {
    Position=UDim2.new(0,10,0,70), Size=UDim2.new(0,64,1,-80), ZIndex=2, Parent=main
})
panelStyle(sidebar, 18)
local tabList = new("ScrollingFrame", {
    Size=UDim2.new(1,-8,1,-12), Position=UDim2.new(0,4,0,6),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=3, Parent=sidebar
})
do
    local l = Instance.new("UIListLayout", tabList)
    l.Padding = UDim.new(0,5)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

local content = new("Frame", {
    Position=UDim2.new(0,84,0,70), Size=UDim2.new(1,-94,1,-80),
    ClipsDescendants=true, ZIndex=50, Parent=main
})
panelStyle(content, 18)
content.BackgroundTransparency = 0.75
local pageScroll = new("ScrollingFrame", {
    Size=UDim2.new(1,-14,1,-14), Position=UDim2.new(0,7,0,7), BackgroundTransparency=1,
    BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=THEME.textDim,
    ScrollBarImageTransparency=0.4, CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y, ClipsDescendants=true, ZIndex=50, Parent=content
})
do
    local l = Instance.new("UIListLayout", pageScroll)
    l.Padding = UDim.new(0,10)
end

local ContentProvider = game:GetService("ContentProvider")
-- image icon; if the asset fails to load a plain ASCII glyph is drawn instead
local function makeIcon(parent, assetId, size, pos, z, fallback)
    local img = new("ImageLabel", {
        Size=size, Position=pos, BackgroundTransparency=1, Image=assetId,
        ImageColor3=Color3.fromRGB(255,255,255), ScaleType=Enum.ScaleType.Fit, ZIndex=z, Parent=parent
    })
    task.spawn(function()
        safe(function()
            ContentProvider:PreloadAsync({img}, function(_, status)
                if status ~= Enum.AssetFetchStatus.Success and img.Parent then
                    img.Image = ""
                    new("TextLabel", {
                        Size=size, Position=pos, BackgroundTransparency=1, Text=fallback or ">",
                        TextColor3=THEME.text, Font=Enum.Font.GothamBold, TextSize=15, ZIndex=z, Parent=parent
                    })
                end
            end)
        end)
    end)
    return img
end

local tabIcons = {
    home = ICO.Home, combat = ICO.Combat, visual = ICO.Visual,
    players = ICO.Players, farm = ICO.Farm, teleport = ICO.Teleport,
    fling = ICO.Fling, movement = ICO.Move, dodge = ICO.Dodge,
    background = ICO.Bg, music = ICO.Music, config = ICO.Config,
    misc = ICO.Misc, vote = ICO.Vote, player = ICO.Player, settings = ICO.Settings,
}

local tabs = {}
local function hideDropdowns()
    for _, c in ipairs(ddGui:GetChildren()) do
        if c:IsA("GuiObject") then c.Visible = false end
    end
end
local function setTabActive(t, on)
    t.container.Visible = on
    t.button.BackgroundTransparency = on and 0.55 or 1
    t.iconBg.BackgroundTransparency = on and 0.35 or 0.85
    t.stroke.Transparency = on and 0.5 or 1
end
local function createTab(name)
    local btn = new("TextButton", {
        Size=UDim2.new(1,-4,0,46), BackgroundColor3=THEME.buttonBg,
        BackgroundTransparency=1, Text="", AutoButtonColor=false,
        ZIndex=4, Parent=tabList
    })
    round(btn, 14)
    local stroke = new("UIStroke", {Color=THEME.stroke, Thickness=1, Transparency=1, Parent=btn})
    local iconBg = new("Frame", {
        Size=UDim2.new(0,34,0,34), Position=UDim2.new(0.5,-17,0.5,-17),
        BackgroundColor3=THEME.iconBg, BackgroundTransparency=0.85, BorderSizePixel=0, ZIndex=5, Parent=btn
    })
    round(iconBg, 12)
    makeIcon(iconBg, tabIcons[name] or ICO.Home, UDim2.new(0,22,0,22), UDim2.new(0.5,-11,0.5,-11), 6, name:sub(1,1):upper())
    local cont = new("Frame", {
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Visible=false, ZIndex=51, Parent=pageScroll
    })
    local l = Instance.new("UIListLayout", cont)
    l.Padding = UDim.new(0,10)
    tabs[name] = {button=btn, container=cont, iconBg=iconBg, stroke=stroke}
    btn.MouseButton1Click:Connect(function()
        hideDropdowns()
        for n, t in pairs(tabs) do setTabActive(t, n == name) end
        pageScroll.CanvasPosition = Vector2.new(0,0)
    end)
    return cont
end

local function createSection(parent, name)
    local sec = new("Frame", {
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=52, Parent=parent
    })
    panelStyle(sec, 16)
    local L = Instance.new("UIListLayout", sec)
    L.Padding = UDim.new(0,6)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local titleRow = new("Frame", {Size=UDim2.new(1,-20,0,28), BackgroundTransparency=1, LayoutOrder=0, ZIndex=53, Parent=sec})
    new("Frame", {Size=UDim2.new(0,3,0,12), Position=UDim2.new(0,4,0.5,-6),
        BackgroundColor3=THEME.accentDark, BorderSizePixel=0, ZIndex=54, Parent=titleRow})
    new("TextLabel", {
        Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text=name, TextColor3=THEME.text,
        Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=54, Parent=titleRow
    })
    local inner = new("Frame", {
        Size=UDim2.new(1,-16,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, LayoutOrder=1, ZIndex=53, Parent=sec
    })
    local il = Instance.new("UIListLayout", inner)
    il.Padding = UDim.new(0,6)
    local pad = Instance.new("UIPadding", sec)
    pad.PaddingBottom = UDim.new(0,8)
    return inner
end

local function glassRow(parent, h, z)
    local f = new("Frame", {
        Size=UDim2.new(1,0,0,h), BackgroundColor3=THEME.buttonBg,
        BackgroundTransparency=0.86, BorderSizePixel=0, ZIndex=z or 54, Parent=parent
    })
    round(f, 12)
    new("UIStroke", {Color=THEME.stroke, Transparency=0.82, Thickness=1}, f)
    return f
end

local function createButton(parent, label, cb, icon)
    local row = glassRow(parent, 38)
    makeIcon(row, ICO.Chevron, UDim2.new(0,16,0,16), UDim2.new(0,12,0.5,-8), 55, ">")
    new("TextLabel", {
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,36,0,0),
        BackgroundTransparency=1, Text=label, TextColor3=THEME.text,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=55, Parent=row
    })
    local b = new("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=58, Parent=row})
    b.MouseButton1Click:Connect(function()
        safe(function() TweenService:Create(row, TweenInfo.new(0.08), {BackgroundTransparency=0.7}):Play() end)
        task.delay(0.1, function() safe(function() TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency=0.86}):Play() end) end)
        safe(cb)
    end)
    return b
end

local function createToggle(parent, label, def, cb, icon)
    local st = def or false
    local f = glassRow(parent, 38)
    makeIcon(f, ICO.Chevron, UDim2.new(0,16,0,16), UDim2.new(0,12,0.5,-8), 55, ">")
    new("TextLabel", {
        Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,36,0,0),
        BackgroundTransparency=1, Text=label, TextColor3=THEME.text,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=55, Parent=f
    })
    local track = new("Frame", {
        Size=UDim2.new(0,38,0,22), Position=UDim2.new(1,-48,0.5,-11),
        BackgroundColor3=st and THEME.toggleOn or THEME.toggleOff,
        BorderSizePixel=0, ZIndex=55, Parent=f
    })
    round(track, 11)
    local knob = new("Frame", {
        Size=UDim2.new(0,18,0,18),
        Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
        BackgroundColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0, ZIndex=56, Parent=track
    })
    round(knob, 9)
    local cl = new("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=58, Parent=f})
    if st then safe(function() cb(true) end) end
    cl.MouseButton1Click:Connect(function()
        st = not st
        safe(function() TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = st and THEME.toggleOn or THEME.toggleOff}):Play() end)
        safe(function() TweenService:Create(knob, TweenInfo.new(0.2), {Position = st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play() end)
        safe(function() cb(st) end)
    end)
end

local function createSlider(parent, label, mn, mx, def, cb)
    local f = glassRow(parent, 52)
    local t = new("TextLabel", {
        Size=UDim2.new(1,-24,0,20), Position=UDim2.new(0,12,0,6),
        BackgroundTransparency=1, Text=label..": "..def, TextColor3=THEME.text,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=55, Parent=f
    })
    local bar = new("Frame", {
        Size=UDim2.new(1,-24,0,6), Position=UDim2.new(0,12,0,36),
        BackgroundColor3=THEME.toggleOff, BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=55, Parent=f
    })
    round(bar, 3)
    local fill = new("Frame", {
        Size=UDim2.new(math.clamp((def-mn)/(mx-mn),0,1),0,1,0),
        BackgroundColor3=THEME.accentDark, BorderSizePixel=0, ZIndex=56, Parent=bar
    })
    round(fill, 3)
    local drag = false
    local function upd(i)
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx-mn)*rel)
        fill.Size = UDim2.new(rel,0,1,0)
        t.Text = label..": "..v
        safe(function() cb(v) end)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; upd(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local function createTextBox(parent, ph, def, cb)
    local b = new("TextBox", {
        Size=UDim2.new(1,0,0,38), BackgroundColor3=THEME.buttonBg, BackgroundTransparency=0.86,
        TextColor3=THEME.text, PlaceholderText=ph, PlaceholderColor3=THEME.textDim,
        Font=Enum.Font.GothamMedium, TextSize=13, Text=def or "", BorderSizePixel=0,
        ClearTextOnFocus=false, ZIndex=54, Parent=parent
    })
    round(b, 12)
    new("UIStroke", {Color=THEME.stroke, Transparency=0.82, Thickness=1}, b)
    b.FocusLost:Connect(function() safe(function() cb(b.Text) end) end)
    return b
end

local function createDropdown(parent, label, opts, def, cb)
    local sel = def or opts[1]
    local cont = glassRow(parent, 38, 100)
    local b = new("TextButton", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        TextColor3=THEME.text, Font=Enum.Font.GothamMedium, TextSize=13,
        Text="  "..label..":  "..tostring(sel).."  v",
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=101, Parent=cont
    })
    local list = new("ScrollingFrame", {
        BackgroundColor3=Color3.fromRGB(22,22,32), BackgroundTransparency=0.05, Visible=false, ZIndex=500,
        ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, BorderSizePixel=0, Parent=ddGui
    })
    round(list, 12)
    new("UIStroke", {Color=THEME.stroke, Transparency=0.75, Thickness=1}, list)
    local ll = Instance.new("UIListLayout", list)
    ll.Padding = UDim.new(0,2)
    local function rf()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, o in ipairs(opts) do
            local ob = new("TextButton", {
                Size=UDim2.new(1,-6,0,28), BackgroundColor3=THEME.buttonBg, BackgroundTransparency=0.9,
                TextColor3=THEME.text, Font=Enum.Font.GothamMedium, TextSize=12, BorderSizePixel=0,
                Text="  "..tostring(o), TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=501, Parent=list
            })
            round(ob, 9)
            ob.MouseButton1Click:Connect(function()
                sel = o
                b.Text = "  "..label..":  "..tostring(sel).."  v"
                list.Visible = false
                safe(function() cb(sel) end)
            end)
        end
    end
    rf()
    b.MouseButton1Click:Connect(function()
        if list.Visible then list.Visible = false; return end
        hideDropdowns()
        local bp, bs = b.AbsolutePosition, b.AbsoluteSize
        list.Position = UDim2.new(0, bp.X, 0, bp.Y + bs.Y + 4)
        list.Size = UDim2.new(0, bs.X, 0, math.min(#opts,6)*30+6)
        rf()
        list.Visible = true
    end)
    return {
        SetOptions = function(no)
            opts = no
            if not sel or not table.find(opts, sel) then
                sel = opts[1]
                b.Text = "  "..label..":  "..tostring(sel).."  v"
            end
            rf()
        end,
        Get = function() return sel end
    }
end

local function draggable(frame, handle, onTap, getScale)
    handle = handle or frame
    local dg, ds, sp, mv = false, nil, nil, false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true; mv = false; ds = i.Position; sp = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local sc = getScale and getScale() or 1
            local d = i.Position - ds
            if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then mv = true end
            if mv then
                frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X/sc, sp.Y.Scale, sp.Y.Offset+d.Y/sc)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dg and not mv and onTap then onTap() end
            dg = false
        end
    end)
end
draggable(main, header, nil, function() return UI_SCALE end)
draggable(wm, wm, function() main.Visible = not main.Visible; hideDropdowns() end)

-- ===== ESP =====
local espF = {Murderer=false,Sheriff=false,Innocent=false,Hero=false,Gun=false,NPC=false,NameTag=false,Distance=false,All=false}
local espP = {}
local function removeESP(plr)
    if plr.Character then
        local h = plr.Character:FindFirstChild("PiddleHighlight"); if h then h:Destroy() end
        local t = plr.Character:FindFirstChild("PiddleTag"); if t then t:Destroy() end
    end
end
local function buildESP(plr)
    if not plr.Character or plr.Character:FindFirstChild("PiddleHighlight") then return end
    local ch = plr.Character
    local hd = ch:FindFirstChild("Head"); if not hd then return end
    safe(function()
        new("Highlight", {
            Name="PiddleHighlight", FillTransparency=0.5, OutlineTransparency=0,
            DepthMode=Enum.HighlightDepthMode.AlwaysOnTop, Enabled=false, Parent=ch
        })
    end)
    safe(function()
        local tag = new("BillboardGui", {
            Name="PiddleTag", Size=UDim2.new(0,160,0,40),
            StudsOffset=Vector3.new(0,3,0), AlwaysOnTop=true, Adornee=hd, Enabled=false, Parent=ch
        })
        new("TextLabel", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Font=Enum.Font.GothamBold, TextSize=16, TextStrokeTransparency=0, Parent=tag
        })
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end)
        if p.Character then safe(buildESP, p) end
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LP then p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end) end
end)
Players.PlayerRemoving:Connect(function(p) safe(removeESP, p); espP[p] = nil end)

task.spawn(function()
    while true do
        task.wait(0.15)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                safe(function()
                    if not p.Character then return end
                    local d = p.Character:FindFirstChild("PiddleHighlight")
                    local t = p.Character:FindFirstChild("PiddleTag")
                    if (not d or not t) and p.Character:FindFirstChild("Head") then
                        buildESP(p)
                        d = p.Character:FindFirstChild("PiddleHighlight")
                        t = p.Character:FindFirstChild("PiddleTag")
                    end
                    if not (d and t) then return end
                    local r = getRole(p)
                    local c = RC[r] or Color3.fromRGB(255,255,255)
                    local tx = r or "Player"
                    local show = false
                    if espP[p] then show = true; c = Color3.fromRGB(220,180,255); tx = "SELECTED"
                    elseif espF.All then show = true
                    elseif espF.Gun and hasItem(p, "Gun") then show = true; c = RC.Gun; tx = "GUN"
                    elseif espF.NPC and r == "NPC" then show = true
                    elseif r and espF[r] then show = true end
                    if show then
                        d.Enabled = true; t.Enabled = true
                        d.FillColor = c; d.OutlineColor = c
                        local lb = t:FindFirstChildOfClass("TextLabel")
                        if lb then
                            lb.TextColor3 = c
                            local s = tx
                            if espF.NameTag then s = p.Name.." | "..tx end
                            local pr = p.Character:FindFirstChild("HumanoidRootPart")
                            local lr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if espF.Distance and pr and lr then
                                s = s..string.format(" [%dm]", math.floor((pr.Position - lr.Position).Magnitude))
                            end
                            lb.Text = s
                        end
                    else
                        d.Enabled = false; t.Enabled = false
                    end
                end)
            end
        end
    end
end)

-- ===== COMBAT CORE: ping, velocity, prediction, stab, throw, kill all =====
local CORE = { ping = 0.1, walls = false, killBusy = false, lastThrow = 0, lastShot = 0 }
task.spawn(function()
    while true do
        local ms = safe(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if not ms then ms = (safe(function() return LP:GetNetworkPing() end) or 0.05) * 2000 end
        CORE.ping = math.clamp(ms / 1000, 0.02, 1)
        task.wait(0.4)
    end
end)

local velHist = {}
RunService.Heartbeat:Connect(function()
    local now = tick()
    for _, p in ipairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local h = velHist[p]
            if not h then h = {}; velHist[p] = h end
            h[#h + 1] = { t = now, p = hrp.Position }
            while #h > 0 and now - h[1].t > 0.2 do table.remove(h, 1) end
        else
            velHist[p] = nil
        end
    end
end)
Players.PlayerRemoving:Connect(function(p) velHist[p] = nil end)

-- measured velocity (what we actually see), not the unreliable replicated one
function CORE.vel(p)
    local h = velHist[p]
    if h and #h >= 2 then
        local a, b = h[1], h[#h]
        local dt = b.t - a.t
        if dt > 0.05 then
            local v = (b.p - a.p) / dt
            if v.Magnitude < 1.5 then return Vector3.zero end
            return v
        end
    end
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.AssemblyLinearVelocity or Vector3.zero
end

-- lead = round-trip ping + small processing margin
function CORE.predict(p, part, extra)
    local ch = p.Character
    part = part or (ch and ch:FindFirstChild("HumanoidRootPart"))
    if not part then return nil end
    local v = CORE.vel(p)
    local lead = CORE.ping + (extra or 0.04)
    local pos = part.Position + Vector3.new(v.X, 0, v.Z) * lead
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum and hum.FloorMaterial == Enum.Material.Air then
        pos = pos + Vector3.new(0, v.Y * lead - 0.5 * WS.Gravity * lead * lead, 0)
    end
    return pos
end

-- are we an alive participant of the current round
function CORE.inRound()
    if next(rolesCache) ~= nil then
        local d = rolesCache[LP.Name]
        return d ~= nil and isAlive(d) and not isDead()
    end
    return not isDead() and (hasItem(LP, "Knife") ~= nil or hasItem(LP, "Gun") ~= nil or WS:FindFirstChild("GunDrop", true) ~= nil)
end

function CORE.findRemote(tool, names)
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("RemoteEvent") then
            local n = d.Name:lower()
            for _, w in ipairs(names) do
                if n:find(w, 1, true) then return d end
            end
        end
    end
end

function CORE.stab(p)
    local ch = LP.Character
    local k = getKnife()
    if not (ch and k) then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if k.Parent ~= ch and hum then hum:EquipTool(k) end
    local handle = k:FindFirstChild("Handle")
    local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not (handle and tr) then return end
    safe(function() k:Activate() end)
    local st = CORE.findRemote(k, {"stab", "slash"})
    if st then safe(function() st:FireServer("Slash") end) end
    if type(firetouchinterest) == "function" then
        safe(function() firetouchinterest(handle, tr, 0); firetouchinterest(handle, tr, 1) end)
    end
    local ht = CORE.findRemote(k, {"handletouched", "touched"})
    if ht then safe(function() ht:FireServer(tr) end) end
end

function CORE.throw(p)
    local ch = LP.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local k = root and getKnife()
    if not k then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if k.Parent ~= ch then
        if hum then hum:EquipTool(k) end
        return false
    end
    local th = CORE.findRemote(k, {"knifethrown", "throw"})
    local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not (th and tr) then return false end
    local aim = CORE.predict(p, tr, 0.06) or tr.Position
    th:FireServer(CFrame.new(root.Position + root.CFrame.LookVector * 1.5, aim), CFrame.new(aim))
    return true
end

function CORE.killAll()
    if CORE.killBusy then return end
    if not hasItem(LP, "Knife") or not CORE.inRound() then return end
    CORE.killBusy = true
    task.spawn(function()
        local ch = LP.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if not root then CORE.killBusy = false; return end
        local home = root.CFrame
        for _, p in ipairs(Players:GetPlayers()) do
            if not CORE.killBusy then break end
            if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                local th = p.Character:FindFirstChildOfClass("Humanoid")
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                if th and tr and th.Health > 0 then
                    local t0 = tick()
                    while CORE.killBusy and th.Health > 0 and p.Parent and tr.Parent and tick() - t0 < 1.6 do
                        root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if not root then break end
                        local pos = CORE.predict(p, tr, 0.02) or tr.Position
                        root.CFrame = CFrame.new(pos - tr.CFrame.LookVector * 2, pos)
                        root.AssemblyLinearVelocity = Vector3.zero
                        CORE.stab(p)
                        if tick() - t0 > 0.7 then safe(CORE.throw, p) end
                        RunService.Heartbeat:Wait()
                    end
                end
            end
        end
        local r2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r2 then r2.CFrame = home; r2.AssemblyLinearVelocity = Vector3.zero end
        CORE.killBusy = false
    end)
end

-- ===== AIMLOCK =====
local aimOn, aimTgt = false, nil
local aimSm, aimPredM = 0.10, 0.15
local aimMurd, aimPred = false, true
RunService.RenderStepped:Connect(function()
    local function lookAt(plr)
        if not plr or not plr.Character then return end
        local part = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then return end
        local pos = aimPred and (CORE.predict(plr, part) or part.Position) or part.Position
        Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, pos), aimSm)
    end
    if aimOn and aimTgt and aimTgt.Parent then lookAt(aimTgt) end
    if aimMurd and hasItem(LP, "Gun") then lookAt(findMurderer()) end
end)

-- ===== FLING =====
local FlingOn, flingMap = false, false
local function getMapCenter()
    local ps = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(ps, p.Character.HumanoidRootPart.Position)
        end
    end
    if #ps == 0 then
        local sp = WS:FindFirstChildOfClass("SpawnLocation")
        if sp then return sp.CFrame end
        return nil
    end
    local s = Vector3.new(0,0,0)
    for _, x in ipairs(ps) do s = s + x end
    return CFrame.new(s/#ps + Vector3.new(0,5,0))
end
local function SkidFling(tp)
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local rp = hum and hum.RootPart
    local tc = tp and tp.Character
    if not (ch and hum and rp and tc) then return end
    local th = tc:FindFirstChildOfClass("Humanoid")
    local tr = th and th.RootPart
    local thd = tc:FindFirstChild("Head")
    local acc = tc:FindFirstChildOfClass("Accessory")
    local ha = acc and acc:FindFirstChild("Handle")
    if th and th.Sit then return end
    local rc = rp.CFrame
    if thd then Cam.CameraSubject = thd
    elseif ha then Cam.CameraSubject = ha
    elseif th and tr then Cam.CameraSubject = th end
    if not tc:FindFirstChildWhichIsA("BasePart") then return end
    local oldF = WS.FallenPartsDestroyHeight
    safe(function() WS.FallenPartsDestroyHeight = -math.huge end)
    local bv = Instance.new("BodyVelocity")
    bv.Parent = rp; bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    local tp2 = tr or thd or ha
    local start = tick()
    while tick()-start < 1.5 and FlingOn do
        if tp2 and tp2.Parent then
            rp.CFrame = CFrame.new(tp2.Position)*CFrame.new(0,1.5,0)
            rp.Velocity = Vector3.new(9e7,9e8,9e7)
            rp.RotVelocity = Vector3.new(9e8,9e8,9e8)
            task.wait()
            rp.CFrame = CFrame.new(tp2.Position)*CFrame.new(0,-1.5,0)
            rp.Velocity = Vector3.new(9e7,9e8,9e7)
            rp.RotVelocity = Vector3.new(9e8,9e8,9e8)
            task.wait()
        else break end
    end
    safe(function() bv:Destroy() end)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    local rt = flingMap and (getMapCenter() or rc) or rc
    local function zero()
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("BasePart") then
                d.AssemblyLinearVelocity = Vector3.zero
                d.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
    zero()
    for _ = 1, 90 do
        if not rp or not rp.Parent then break end
        rp.CFrame = rt
        zero()
        RunService.Heartbeat:Wait()
    end
    safe(function() rp.Anchored = true end)
    zero()
    task.wait(0.15)
    safe(function() rp.Anchored = false end)
    zero()
    safe(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    Cam.CameraSubject = hum
    safe(function() WS.FallenPartsDestroyHeight = oldF end)
end
local function flingPlayer(p)
    if not p or not p.Character then return end
    FlingOn = true
    task.spawn(function() safe(SkidFling, p); FlingOn = false end)
end
local function flingRole(r)
    local p = findByRole(r)
    if p then flingPlayer(p) end
end
local function flingAll()
    FlingOn = true
    task.spawn(function()
        while FlingOn do
            for _, p in ipairs(Players:GetPlayers()) do
                if not FlingOn then break end
                if p ~= LP and p.Character then safe(SkidFling, p); task.wait(0.1) end
            end
            task.wait(0.5)
        end
    end)
end

-- Touch fling (logic only, toggle lives in the Fling tab)
local touchFlingOn = false
local function setTouchFling(on)
    touchFlingOn = on
    if on then
        task.spawn(function()
            local movel = 0.1
            while touchFlingOn do
                RunService.Heartbeat:Wait()
                local c = LP.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    hrp.AssemblyLinearVelocity = vel
                    RunService.Stepped:Wait()
                    hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0)
                    movel = -movel
                end
            end
        end)
    end
end

-- ===== SPIN =====
local spinOn, spinSpd = false, 30
task.spawn(function()
    local spinA = 0
    while true do
        task.wait(0.01)
        if spinOn and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                spinA = spinA + spinSpd
                hrp.CFrame = CFrame.new(hrp.CFrame.Position)*CFrame.Angles(0,math.rad(spinA),0)
            end
        end
    end
end)

-- ===== AUTO FEATURES =====
local autoKnife, autoThrow, autoShoot, autoReload = false, false, false, false
local autoJump, autoRespawn, fastRespawn, antiVoid = false, false, false, false
local noclip, flying = false, false
local flyBV, flyBG = nil, nil
local keepSpeed, keepJump = false, false
local dSpeed, dJump = CFG.speed, CFG.jump
local autoGun, farmCoins = false, false

do
    -- Kill aura: stab nearest alive player in range (murderer only)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if autoKnife and LP.Character and hasItem(LP, "Knife") and CORE.inRound() then
                safe(function()
                    local root = LP.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local best, bd = nil, 14
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            local tr = p.Character:FindFirstChild("HumanoidRootPart")
                            local h = p.Character:FindFirstChildOfClass("Humanoid")
                            if tr and h and h.Health > 0 and getRole(p) ~= "NPC" then
                                local d = (tr.Position - root.Position).Magnitude
                                if d < bd then bd = d; best = p end
                            end
                        end
                    end
                    if best then CORE.stab(best) end
                end)
            end
        end
    end)

    -- Auto-throw: nearest target, ping-compensated lead
    task.spawn(function()
        while true do
            task.wait(0.12)
            if autoThrow and LP.Character and hasItem(LP, "Knife") and tick() - CORE.lastThrow > 0.5 then
                safe(function()
                    local root = LP.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local closest, cd = nil, 2000
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            local tr = p.Character:FindFirstChild("HumanoidRootPart")
                            local h = p.Character:FindFirstChildOfClass("Humanoid")
                            if tr and h and h.Health > 0 and getRole(p) ~= "NPC" then
                                local d = (tr.Position - root.Position).Magnitude
                                if d < cd then cd = d; closest = p end
                            end
                        end
                    end
                    if closest and CORE.throw(closest) then CORE.lastThrow = tick() end
                end)
            end
        end
    end)

    -- Auto-shoot murderer: ping lead, velocity from samples, optional through-walls origin
    RunService.Heartbeat:Connect(function()
        if not autoShoot or not LP.Character then return end
        if tick() - CORE.lastShot < 0.3 then return end
        safe(function()
            local ch = LP.Character
            local root = ch:FindFirstChild("HumanoidRootPart"); if not root then return end
            local g = getGun(); if not g then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if g.Parent ~= ch then
                if hum then hum:EquipTool(g) end
                return
            end
            local sh = g:FindFirstChild("Shoot"); if not sh then return end
            local m = findMurderer()
            if not m or not m.Character then return end
            local mh = m.Character:FindFirstChildOfClass("Humanoid")
            local mr = m.Character:FindFirstChild("HumanoidRootPart")
            if not mh or mh.Health <= 0 or not mr then return end
            if (mr.Position - root.Position).Magnitude > 2000 then return end

            local aim = (CORE.predict(m, mr, 0.05) or mr.Position) + Vector3.new(0, 0.4, 0)
            local at = root:FindFirstChild("GunRaycastAttachment")
            local origin = at and at.WorldCFrame or root.CFrame

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {ch, m.Character}
            local function clear(from) return WS:Raycast(from, aim - from, params) == nil end

            if not clear(origin.Position) then
                if not CORE.walls then return end
                -- through walls: move the ray origin to a clear spot right next to the target
                local toMe = origin.Position - aim
                local dirMe = toMe.Magnitude > 0.1 and toMe.Unit or Vector3.new(0, 0, 1)
                local cands = {
                    aim + dirMe * 2, aim + dirMe * 4, aim + Vector3.new(0, 5, 0),
                    aim + dirMe * 7, aim + Vector3.new(3, 3, 0), aim + Vector3.new(-3, 3, 0),
                }
                local pick = cands[1]
                for _, c in ipairs(cands) do
                    if clear(c) then pick = c; break end
                end
                origin = CFrame.new(pick, aim)
            end
            sh:FireServer(origin, CFrame.new(aim))
            CORE.lastShot = tick()
        end)
    end)

    RunService.RenderStepped:Connect(function()
        if not autoReload or not LP.Character then return end
        safe(function()
            local g = getGun(); if not g then return end
            local r = g:FindFirstChild("Reload")
            if r then r:FireServer() end
        end)
    end)

    RunService.Heartbeat:Connect(function()
        if not autoJump or not LP.Character then return end
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then safe(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if autoRespawn and LP.Character then
                local h = LP.Character:FindFirstChildOfClass("Humanoid")
                if not h or h.Health <= 0 then task.wait(0.5); safe(function() LP.Character:BreakJoints() end) end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)
            if fastRespawn and LP.Character then
                local h = LP.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health <= 0 then safe(function() LP.Character:BreakJoints() end) end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if antiVoid and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -50 then
                local sp = WS:FindFirstChildOfClass("SpawnLocation")
                if sp then hrp.CFrame = sp.CFrame + Vector3.new(0,5,0) end
            end
        end
    end)

    RunService.Stepped:Connect(function()
        if noclip and LP.Character then
            for _, p in ipairs(LP.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not flying or not flyBV or not LP.Character then return end
        safe(function()
            local mv = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + Cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - Cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            -- mobile: follow humanoid MoveDirection
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if IS_MOBILE and h and h.MoveDirection.Magnitude > 0 then
                mv = Cam.CFrame.LookVector * (h.MoveDirection:Dot(Cam.CFrame.LookVector) > -0.2 and 1 or -1)
            end
            flyBV.Velocity = mv*60
            flyBG.CFrame = Cam.CFrame
        end)
    end)

    task.spawn(function()
        while true do
            task.wait(0.05)
            if LP.Character then
                local h = LP.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    if keepSpeed and h.WalkSpeed ~= dSpeed then h.WalkSpeed = dSpeed end
                    if keepJump then
                        if h.UseJumpPower == false then h.UseJumpPower = true end
                        if h.JumpPower ~= dJump then h.JumpPower = dJump end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)
            if farmCoins and LP.Character then
                safe(function()
                    for _, ch in ipairs(WS:GetChildren()) do
                        if not farmCoins then break end
                        if ch:IsA("BasePart") and ch.Name == "Coin_Server" then
                            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then hrp.CFrame = ch.CFrame; task.wait(2.9) end
                        end
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.3)
            if autoGun then
                safe(function()
                    if isDead() or inVoting() then return end
                    if not CORE.inRound() then return end
                    if hasItem(LP, "Knife") or getRole(LP) == "Murderer" then return end
                    if hasItem(LP, "Gun") then return end
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local o = WS:FindFirstChild("GunDrop", true)
                    if o and o:IsA("BasePart") and (o.Position - hrp.Position).Magnitude < 5000 then
                        local old = hrp.CFrame
                        hrp.CFrame = o.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.35)
                        if hrp and hrp.Parent and not isDead() then hrp.CFrame = old end
                    end
                end)
            end
        end
    end)
end

-- ===== ANTI-FLING =====
local AF = { on = true, update = function() end }
do
    local afConnections = {}
    local AF_RADIUS, AF_MAX_VEL = 25, 80
    local afGui = new("ScreenGui", {Name="AntiFlingIndicator", ResetOnSpawn=false, Parent=pg})
    local afBtn = new("TextButton", {
        Size=UDim2.new(0,220,0,30), Position=UDim2.new(0,15,1,-45),
        BackgroundTransparency=1, Text="Anti-Fling & Ring: Enabled",
        TextColor3=Color3.fromRGB(0,255,140), TextSize=16,
        Font=Enum.Font.SourceSansBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=afGui
    })
    new("UIStroke", {Thickness=1.5, Color=Color3.fromRGB(0,0,0), Transparency=0.3, Parent=afBtn})
    AF.update = function()
        if AF.on then
            afBtn.Text = "Anti-Fling & Ring: Enabled"
            afBtn.TextColor3 = Color3.fromRGB(0,255,140)
        else
            afBtn.Text = "Anti-Fling & Ring: Disabled"
            afBtn.TextColor3 = Color3.fromRGB(255,80,80)
        end
    end
    local function setupCharCollision(character)
        local function dis(part)
            if AF.on and part:IsA("BasePart") then part.CanCollide = false end
        end
        for _, p in ipairs(character:GetChildren()) do dis(p) end
        local c1 = character.ChildAdded:Connect(dis)
        local c2 = RunService.Stepped:Connect(function()
            if AF.on and character:IsDescendantOf(WS) then
                for _, p in ipairs(character:GetChildren()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end)
        character.Destroying:Connect(function() c1:Disconnect(); c2:Disconnect() end)
    end
    local function trackPlayer(player)
        if player == LP then return end
        afConnections[player] = player.CharacterAdded:Connect(setupCharCollision)
        if player.Character then setupCharCollision(player.Character) end
    end
    for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
    Players.PlayerAdded:Connect(trackPlayer)
    Players.PlayerRemoving:Connect(function(p)
        if afConnections[p] then afConnections[p]:Disconnect(); afConnections[p] = nil end
    end)
    RunService.Heartbeat:Connect(function()
        if not AF.on then return end
        local myChar = LP.Character; if not myChar then return end
        local hrp = myChar:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hrpPos = hrp.Position
        for _, item in ipairs(WS:GetChildren()) do
            if item:IsA("BasePart") and not item.Anchored and not item:IsDescendantOf(myChar) then
                if (item.Position - hrpPos).Magnitude <= AF_RADIUS and item.AssemblyLinearVelocity.Magnitude > AF_MAX_VEL then
                    item.CanCollide = false
                    item.AssemblyLinearVelocity = Vector3.new()
                    item.AssemblyAngularVelocity = Vector3.new()
                    safe(function() item.CFrame = item.CFrame + Vector3.new(0,500,0) end)
                end
            end
        end
    end)
    afBtn.MouseButton1Click:Connect(function() AF.on = not AF.on; AF.update() end)
    LP.Chatted:Connect(function(msg)
        msg = msg:lower()
        if msg == ";af on" then AF.on = true; AF.update()
        elseif msg == ";af off" then AF.on = false; AF.update() end
    end)
end

-- =========================================================
-- TABS (each in its own do...end to stay under the 200 local limit)
-- =========================================================

-- HOME
do
    local tab = createTab("home")
    local sec = createSection(tab, T("general"))
    createButton(sec, T("save_cfg"), function() saveCFG() end)
    createButton(sec, T("load_cfg"), function() loadCFG() end)
    createSlider(sec, T("ui_size"), 50, 150, math.floor(UI_SCALE*100), function(v)
        UI_SCALE = v/100
        CFG.uiScale = UI_SCALE
        uiScaleObj.Scale = UI_SCALE
    end)
    createButton(sec, T("respawn"), function()
        if LP.Character then safe(function() LP.Character:BreakJoints() end) end
    end)
    createButton(sec, T("rejoin"), function()
        safe(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)
    end)
end

-- PLAYER
do
    local tab = createTab("player")
    local animSec = createSection(tab, T("animations"))
    local curAnimTrack = nil
    local function clearAnim()
        safe(function() if curAnimTrack then curAnimTrack:Stop(); curAnimTrack = nil end end)
    end
    local function playAnim(id)
        clearAnim()
        local ch = LP.Character; if not ch then return end
        local h = ch:FindFirstChildOfClass("Humanoid"); if not h then return end
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..(tostring(id):gsub("%D",""))
        local ok, tr = pcall(function() return h:LoadAnimation(a) end)
        if ok and tr then
            tr.Priority = Enum.AnimationPriority.Action4
            tr.Looped = true
            tr:Play()
            curAnimTrack = tr
        end
    end
    local animIdBox = createTextBox(animSec, T("custom_anim"), "", function() end)
    createButton(animSec, T("apply"), function()
        local id = animIdBox.Text:gsub("%D","")
        if id ~= "" then playAnim(id) end
    end)
    createButton(animSec, T("stop_anim"), clearAnim)

    local emoteSec = createSection(tab, T("emotes"))
    local EMOTES = {
        Wave="507770239", Point="507770453", Dance="507771019", Laugh="507770818",
        Cheer="507770677", Salute="507770965", Shrug="507770647", Facepalm="507770585",
        Bow="507770603", Flex="507770720", Frog="507770674", Zombie="507770762",
        Pray="507770612", Sit="507770750", Lay="507770758", Ninja="507770855",
        Sword="507770858", Kick="507770863", FreeFall="507770811", Astronaut="507770843",
        HipHop="507771019", Robot="507771016", TapDance="507771017", Cheerleader="507771020",
        Cartwheel="507770825", Gangnam="507771032", YMCA="507771031",
        Clap="507770647", Confused="507770629", Panic="507770899", Applause="507770667",
        Sleep="507770761", Cry="507770611",
    }
    local names = {}
    for n in pairs(EMOTES) do table.insert(names, n) end
    table.sort(names)
    for _, n in ipairs(names) do
        createButton(emoteSec, n, function() playAnim(EMOTES[n]) end)
    end

    local outfitSec = createSection(tab, T("outfits"))
    local function applyKorblox()
        local char = LP.Character; if not char then return end
        local lf = char:FindFirstChild("LeftFoot"); local ll = char:FindFirstChild("LeftLowerLeg")
        local lu = char:FindFirstChild("LeftUpperLeg"); local rf = char:FindFirstChild("RightFoot")
        local rl = char:FindFirstChild("RightLowerLeg"); local ru = char:FindFirstChild("RightUpperLeg")
        if lf then lf.MeshId = "http://www.roblox.com/asset/?id=902942077"; lf.Transparency = 1 end
        if ll then ll.MeshId = "http://www.roblox.com/asset/?id=902942101"; ll.TextureID = "http://roblox.com/asset/?id=902842271" end
        if lu then lu.MeshId = "http://www.roblox.com/asset/?id=902942082"; lu.TextureID = "http://roblox.com/asset/?id=902842271" end
        if rf then rf.MeshId = "http://www.roblox.com/asset/?id=902942089"; rf.Transparency = 1 end
        if rl then rl.MeshId = "http://www.roblox.com/asset/?id=902942093"; rl.Transparency = 1 end
        if ru then ru.MeshId = "http://www.roblox.com/asset/?id=902942096"; ru.TextureID = "http://roblox.com/asset/?id=902843398" end
    end
    local function removeKorblox()
        local char = LP.Character; if not char then return end
        for _, name in ipairs({"LeftFoot","LeftLowerLeg","LeftUpperLeg","RightFoot","RightLowerLeg","RightUpperLeg"}) do
            local p = char:FindFirstChild(name)
            if p then p.MeshId = ""; p.TextureID = ""; p.Transparency = 0 end
        end
    end
    local function setHeadless(on)
        local char = LP.Character; if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        head.Transparency = on and 1 or 0
        for _, c in ipairs(head:GetChildren()) do
            if c:IsA("Decal") then c.Transparency = on and 1 or 0 end
        end
    end
    createButton(outfitSec, "Korblox ON", applyKorblox)
    createButton(outfitSec, "Korblox OFF", removeKorblox)
    createButton(outfitSec, "Headless ON", function() setHeadless(true) end)
    createButton(outfitSec, "Headless OFF", function() setHeadless(false) end)
end

-- COMBAT
do
    local tab = createTab("combat")
    local espSec = createSection(tab, T("esp"))
    createToggle(espSec, T("esp_murderer"), false, function(o) espF.Murderer = o end)
    createToggle(espSec, T("esp_sheriff"), false, function(o) espF.Sheriff = o end)
    createToggle(espSec, T("esp_innocent"), false, function(o) espF.Innocent = o end)
    createToggle(espSec, T("esp_hero"), false, function(o) espF.Hero = o end)
    createToggle(espSec, T("esp_gun"), false, function(o) espF.Gun = o end)
    createToggle(espSec, T("esp_npc"), false, function(o) espF.NPC = o end)
    createToggle(espSec, T("esp_all"), false, function(o) espF.All = o end)
    createToggle(espSec, T("esp_nametag"), false, function(o) espF.NameTag = o end)
    createToggle(espSec, T("esp_distance"), false, function(o) espF.Distance = o end)

    local aimSec = createSection(tab, T("aimlock"))
    createToggle(aimSec, T("aimlock_murder"), false, function(o) aimMurd = o end)
    createToggle(aimSec, T("aimlock_predict"), true, function(o) aimPred = o end)
    createSlider(aimSec, T("aimlock_smooth"), 1, 100, 10, function(v) aimSm = v/100 end)

    local kaSec = createSection(tab, T("kill_aura"))
    createToggle(kaSec, T("auto_knife"), false, function(o) autoKnife = o end)
    createToggle(kaSec, T("auto_throw"), false, function(o) autoThrow = o end)

    local shootSec = createSection(tab, T("auto_shoot"))
    createToggle(shootSec, "Auto-Shoot Murderer", false, function(o) autoShoot = o end)
    createToggle(shootSec, "Shoot Through Walls", false, function(o) CORE.walls = o end)
    createToggle(shootSec, T("auto_reload"), false, function(o) autoReload = o end)

    local murSec = createSection(tab, "Murderer")
    createButton(murSec, "Kill All", function() CORE.killAll() end)
    createButton(murSec, "Stop Kill All", function() CORE.killBusy = false end)
end

-- VISUAL
do
    local tab = createTab("visual")
    local sec = createSection(tab, T("lighting"))
    createToggle(sec, T("bright"), false, function(o)
        Lighting.Brightness = o and 3 or 2
        Lighting.OutdoorAmbient = o and Color3.new(1,1,1) or Color3.fromRGB(128,128,128)
    end)
    createToggle(sec, T("no_fog"), false, function(o) Lighting.FogEnd = o and 1e6 or 1000 end)
    createSlider(sec, T("fov"), 50, 130, 70, function(v) Cam.FieldOfView = v end)
end

-- PLAYERS
do
    local tab = createTab("players")
    local sec = createSection(tab, T("list_players"))
    local listFrame = new("Frame", {
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=54, Parent=sec
    })
    local lfL = Instance.new("UIListLayout", listFrame)
    lfL.Padding = UDim.new(0,6)
    local pRows = {}
    local function refreshPlayers()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        pRows = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local row = new("Frame", {
                    Size=UDim2.new(1,0,0,54), BackgroundColor3=THEME.buttonBg, BackgroundTransparency=0.86, ZIndex=55, Parent=listFrame
                })
                round(row, 10)
                new("UIStroke", {Color=THEME.buttonStroke, Thickness=1}, row)
                new("ImageLabel", {
                    Size=UDim2.new(0,42,0,42), Position=UDim2.new(0,6,0,6),
                    BackgroundColor3=THEME.toggleOff,
                    Image="rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150",
                    ZIndex=56, Parent=row
                })
                new("TextLabel", {
                    Size=UDim2.new(1,-230,0,18), Position=UDim2.new(0,54,0,6),
                    BackgroundTransparency=1, Text=p.Name, TextColor3=THEME.text,
                    Font=Enum.Font.GothamMedium, TextSize=13, TextTruncate=Enum.TextTruncate.AtEnd,
                    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=56, Parent=row
                })
                local rl = new("TextLabel", {
                    Size=UDim2.new(1,-230,0,14), Position=UDim2.new(0,54,0,26),
                    BackgroundTransparency=1, Text=getRole(p), TextColor3=THEME.textDim,
                    Font=Enum.Font.GothamBold, TextSize=11,
                    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=56, Parent=row
                })
                local function mk(txt, x, bg, fg)
                    local b = new("TextButton", {
                        Size=UDim2.new(0,50,0,24), Position=UDim2.new(1,x,0,8),
                        BackgroundColor3=bg, TextColor3=fg,
                        Font=Enum.Font.GothamBold, TextSize=10, Text=txt, ZIndex=56, Parent=row
                    })
                    round(b, 8)
                    return b
                end
                local fB = mk("FLING", -166, Color3.fromRGB(252,225,228), Color3.fromRGB(200,70,90))
                local aB = mk("AIM", -112, Color3.fromRGB(255,245,225), Color3.fromRGB(190,150,60))
                local eB = mk("ESP", -58, Color3.fromRGB(225,235,255), Color3.fromRGB(80,130,210))
                fB.MouseButton1Click:Connect(function() flingPlayer(p) end)
                aB.MouseButton1Click:Connect(function()
                    if aimOn and aimTgt == p then aimOn = false; aimTgt = nil
                    else aimOn = true; aimTgt = p end
                end)
                eB.MouseButton1Click:Connect(function()
                    if espP[p] then espP[p] = nil else espP[p] = true end
                end)
                pRows[p] = { roleLabel = rl }
            end
        end
    end
    createButton(sec, T("refresh_list"), refreshPlayers)
    Players.PlayerAdded:Connect(function() task.wait(1); refreshPlayers() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); refreshPlayers() end)
    refreshPlayers()

    task.spawn(function()
        while true do
            task.wait(0.5)
            for p, d in pairs(pRows) do
                if p.Parent then
                    local r = getRole(p)
                    d.roleLabel.Text = r
                    d.roleLabel.TextColor3 = RC[r] or RC.Innocent
                end
            end
        end
    end)
end

-- FARM
do
    local tab = createTab("farm")
    local sec = createSection(tab, T("money"))
    createToggle(sec, T("farm_coins"), false, function(o) farmCoins = o end)
    createToggle(sec, T("auto_get_gun"), false, function(o) autoGun = o end)
end

-- TELEPORT
do
    local tab = createTab("teleport")
    local tpOpts = {}
    local function refreshTP()
        tpOpts = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(tpOpts, p.Name) end
        end
        if #tpOpts == 0 then tpOpts = {"(none)"} end
    end
    refreshTP()
    local function tpTo(p)
        if p and p.Character and LP.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            local lr = LP.Character:FindFirstChild("HumanoidRootPart")
            if pr and lr then lr.CFrame = pr.CFrame + Vector3.new(0,3,0) end
        end
    end
    local sec = createSection(tab, T("select_player"))
    local dd = createDropdown(sec, T("player_sel"), tpOpts, tpOpts[1], function() end)
    createButton(sec, T("refresh_list"), function() refreshTP(); dd.SetOptions(tpOpts) end)
    createButton(sec, T("tp_selected"), function()
        local n = dd.Get()
        if n == "(none)" then return end
        tpTo(Players:FindFirstChild(n))
    end)
    local sec2 = createSection(tab, T("fast_tp"))
    createButton(sec2, T("tp_murderer"), function() tpTo(findMurderer()) end)
    createButton(sec2, T("tp_sheriff"), function() tpTo(findSheriff()) end)
    createButton(sec2, T("tp_hero"), function() tpTo(findHero()) end)
end

-- FLING
do
    local tab = createTab("fling")
    local sec = createSection(tab, T("fling_return"))
    createDropdown(sec, T("fling_return"), {"Original","Map"}, CFG.flingReturnMode, function(v)
        CFG.flingReturnMode = v
        flingMap = (v == "Map")
        saveCFG()
    end)
    flingMap = (CFG.flingReturnMode == "Map")

    local tfSec = createSection(tab, "Touch Fling")
    createToggle(tfSec, "Touch Fling", false, setTouchFling)

    local mtSec = createSection(tab, T("multi_fling"))
    local mtStatus = new("TextLabel", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1,
        Text="0 target(s) selected", TextColor3=THEME.text,
        Font=Enum.Font.GothamMedium, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=54, Parent=mtSec
    })
    local mtList = new("ScrollingFrame", {
        Size=UDim2.new(1,0,0,150), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=54, Parent=mtSec
    })
    local mtLL = Instance.new("UIListLayout", mtList)
    mtLL.Padding = UDim.new(0,4)
    local mtSelected, mtCheckboxes = {}, {}
    local function countSel()
        local c = 0; for _ in pairs(mtSelected) do c = c + 1 end
        mtStatus.Text = c.." target(s) selected"
        return c
    end
    local function mtRefresh()
        for _, c in ipairs(mtList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        mtCheckboxes = {}
        local list = Players:GetPlayers()
        table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)
        for _, player in ipairs(list) do
            if player ~= LP then
                local entry = new("Frame", {
                    Size=UDim2.new(1,-6,0,30), BackgroundColor3=THEME.buttonBg, BackgroundTransparency=0.86, ZIndex=55, Parent=mtList
                })
                round(entry, 8)
                new("UIStroke", {Color=THEME.buttonStroke, Thickness=1}, entry)
                local cb = new("Frame", {
                    Size=UDim2.new(0,24,0,24), Position=UDim2.new(0,3,0.5,-12),
                    BackgroundColor3=THEME.toggleOff, BorderSizePixel=0, ZIndex=56, Parent=entry
                })
                round(cb, 6)
                local chk = new("Frame", {
                    Size=UDim2.new(1,-8,1,-8), Position=UDim2.new(0,4,0,4),
                    BackgroundColor3=Color3.fromRGB(80,255,140), BorderSizePixel=0,
                    Visible=mtSelected[player.Name] ~= nil, ZIndex=57, Parent=cb
                })
                round(chk, 4)
                new("TextLabel", {
                    Size=UDim2.new(1,-35,1,0), Position=UDim2.new(0,30,0,0),
                    BackgroundTransparency=1, Text=player.Name, TextColor3=THEME.text,
                    TextSize=14, Font=Enum.Font.GothamMedium,
                    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=56, Parent=entry
                })
                local click = new("TextButton", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=58, Parent=entry
                })
                click.MouseButton1Click:Connect(function()
                    if mtSelected[player.Name] then
                        mtSelected[player.Name] = nil; chk.Visible = false
                    else
                        mtSelected[player.Name] = player; chk.Visible = true
                    end
                    countSel()
                end)
                mtCheckboxes[player.Name] = chk
            end
        end
    end
    mtRefresh()
    Players.PlayerAdded:Connect(function() task.wait(1); mtRefresh() end)
    Players.PlayerRemoving:Connect(function(p) mtSelected[p.Name] = nil; task.wait(0.5); mtRefresh(); countSel() end)
    createButton(mtSec, T("refresh_targets"), mtRefresh)
    createButton(mtSec, T("select_all"), function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                mtSelected[p.Name] = p
                local chk = mtCheckboxes[p.Name]
                if chk then chk.Visible = true end
            end
        end
        countSel()
    end)
    createButton(mtSec, T("deselect_all"), function()
        mtSelected = {}
        for _, chk in pairs(mtCheckboxes) do chk.Visible = false end
        countSel()
    end)
    local mtActive = false
    createButton(mtSec, T("start_fling"), function()
        if mtActive then return end
        if countSel() == 0 then return end
        mtActive = true; FlingOn = true
        task.spawn(function()
            while mtActive do
                for _, player in pairs(mtSelected) do
                    if mtActive and player and player.Parent and player.Character then
                        safe(SkidFling, player)
                        task.wait(0.1)
                    end
                end
                task.wait(0.5)
            end
        end)
    end)
    createButton(mtSec, T("stop_all_fling"), function() mtActive = false; FlingOn = false end)

    local sec2 = createSection(tab, T("fling"))
    createButton(sec2, T("fling_murderer"), function() flingRole("Murderer") end)
    createButton(sec2, T("fling_sheriff"), function() flingRole("Sheriff") end)
    createButton(sec2, T("fling_innocent"), function() flingRole("Innocent") end)
    createButton(sec2, T("fling_hero"), function() flingRole("Hero") end)
    createButton(sec2, T("fling_all"), function() flingAll() end)
    createButton(sec2, T("stop_fling"), function() FlingOn = false; mtActive = false end)
end

-- MOVEMENT
do
    local tab = createTab("movement")
    local sec = createSection(tab, T("speed"))
    createToggle(sec, T("keep_speed"), false, function(o) keepSpeed = o end)
    createSlider(sec, T("speed"), 16, 200, dSpeed, function(v) dSpeed = v; CFG.speed = v end)
    createToggle(sec, T("keep_jump"), false, function(o) keepJump = o end)
    createSlider(sec, T("jump_power"), 50, 300, dJump, function(v) dJump = v; CFG.jump = v end)
    createToggle(sec, T("auto_jump"), false, function(o) autoJump = o end)
    createToggle(sec, T("fly"), false, function(o)
        flying = o
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if flyBV then safe(function() flyBV:Destroy() end); flyBV = nil end
        if flyBG then safe(function() flyBG:Destroy() end); flyBG = nil end
        if o and hrp then
            flyBV = new("BodyVelocity", {Parent=hrp, MaxForce=Vector3.new(1e5,1e5,1e5), Velocity=Vector3.new(0,0,0)})
            flyBG = new("BodyGyro", {Parent=hrp, MaxTorque=Vector3.new(1e5,1e5,1e5), P=1000})
        end
    end)
    createToggle(sec, T("noclip"), false, function(o) noclip = o end)

    local spinSec = createSection(tab, T("spin"))
    createToggle(spinSec, T("spin"), false, function(o) spinOn = o end)
    createSlider(spinSec, T("spin_speed"), 1, 500, 30, function(v) spinSpd = v end)
    createButton(spinSec, T("spin_madness"), function() spinOn = true; spinSpd = 500 end)
    createButton(spinSec, T("stop_spin"), function() spinOn = false end)
end

-- DODGE
do
    local tab = createTab("dodge")
    local dodgeOn, dodgeMurd, dodgeAim = false, false, false
    local DETECT = {"knife", "blade", "throwing", "bullet", "projectile", "shot", "dagger"}
    local tracked = {}
    local lastDodge = 0

    local function inAnyCharacter(inst)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and inst:IsDescendantOf(p.Character) then return true end
        end
        return false
    end

    -- sidestep: try both sides (clear of walls), else hop
    local function sideStep(dir, dist)
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or tick() - lastDodge < 0.2 then return end
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude < 0.01 then dir = Vector3.new(1, 0, 0) end
        dir = dir.Unit
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ch}
        for _, d in ipairs({dir, -dir}) do
            if not WS:Raycast(hrp.Position, d * (dist + 1.5), params) then
                hrp.CFrame = hrp.CFrame + d * dist
                lastDodge = tick()
                return
            end
        end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then safe(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        lastDodge = tick()
    end

    -- track anything knife/bullet-like that appears anywhere in workspace
    WS.DescendantAdded:Connect(function(d)
        if not dodgeOn then return end
        if not (d:IsA("BasePart") or d:IsA("Model")) then return end
        local n = d.Name:lower()
        local hit = false
        for _, w in ipairs(DETECT) do
            if n:find(w, 1, true) then hit = true; break end
        end
        if not hit then return end
        task.defer(function()
            local part = d
            if d:IsA("Model") then part = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true) end
            if part and part:IsA("BasePart") and part.Parent and not inAnyCharacter(part) then
                tracked[part] = { pos = part.Position, t = tick(), born = tick(), v = Vector3.zero }
            end
        end)
    end)

    -- closest-approach prediction using the part's measured motion (works for CFrame-driven projectiles too)
    RunService.Heartbeat:Connect(function()
        if not dodgeOn then return end
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local now = tick()
        local me = hrp.Position
        for part, info in pairs(tracked) do
            if not part.Parent or now - info.born > 8 then
                tracked[part] = nil
            else
                local pos = part.Position
                local dt = now - info.t
                if dt > 0 then
                    local raw = (pos - info.pos) / dt
                    info.v = info.v:Lerp(raw, 0.6)
                    info.pos = pos
                    info.t = now
                    local v = info.v
                    local spd = v.Magnitude
                    if spd > 15 then
                        local t = (me - pos):Dot(v) / (spd * spd)
                        if t > 0 and t < 0.6 + CORE.ping then
                            local closest = (pos + v * t) - me
                            if closest.Magnitude < 6 then
                                local perp = Vector3.new(-v.Z, 0, v.X)
                                if perp.Magnitude > 0.01 then
                                    perp = perp.Unit
                                    -- step away from the projectile line
                                    local sign = perp:Dot(me - (pos + v * t)) >= 0 and 1 or -1
                                    sideStep(perp * sign, 9)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- proximity (murderer) + gun-aim dodge
    task.spawn(function()
        while true do
            task.wait(0.06)
            if dodgeOn then
                safe(function()
                    local ch = LP.Character
                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    if dodgeMurd then
                        local m = findMurderer()
                        local mr = m and m.Character and m.Character:FindFirstChild("HumanoidRootPart")
                        if mr and (mr.Position - hrp.Position).Magnitude <= 12 and hasItem(m, "Knife") then
                            sideStep(hrp.Position - mr.Position, 10)
                        end
                    end
                    if dodgeAim then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LP and p.Character and p.Character:FindFirstChild("Gun") then
                                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                                if pr then
                                    local to = hrp.Position - pr.Position
                                    if to.Magnitude < 250 and to.Magnitude > 3 then
                                        local aimDot = pr.CFrame.LookVector:Dot(to.Unit)
                                        if aimDot > 0.985 then
                                            local perp = Vector3.new(-to.Z, 0, to.X)
                                            if perp.Magnitude > 0.01 then sideStep(perp.Unit, 7) end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    local sec = createSection(tab, T("auto_dodge"))
    createToggle(sec, "Dodge Knife / Bullets", false, function(o) dodgeOn = o end)
    createToggle(sec, T("dodge_murderer"), false, function(o) dodgeMurd = o end)
    createToggle(sec, "Dodge Gun Aim", false, function(o) dodgeAim = o end)
end

-- MISC
do
    local tab = createTab("misc")
    local sec = createSection(tab, "Auto")
    createToggle(sec, T("auto_respawn"), false, function(o) autoRespawn = o end)
    createToggle(sec, T("fast_respawn"), false, function(o) fastRespawn = o end)
    createToggle(sec, T("anti_void"), false, function(o) antiVoid = o end)
    local afSec = createSection(tab, T("anti_fling"))
    new("TextLabel", {
        Size=UDim2.new(1,0,0,26), BackgroundTransparency=1,
        Text="Anti-Fling protects from fling/Ring attacks",
        TextColor3=THEME.textDim, Font=Enum.Font.GothamMedium, TextSize=11,
        TextWrapped=true, Parent=afSec
    })
    createButton(afSec, "Toggle Anti-Fling", function() AF.on = not AF.on; AF.update() end)
end

-- BACKGROUND
do
    local tab = createTab("background")
    local s1 = createSection(tab, T("bg_chooser"))
    local bgOpts = {}
    for _, b in ipairs(BG_LIST) do table.insert(bgOpts, b.name) end
    createDropdown(s1, T("bg_chooser"), bgOpts, CFG.bgName, function(v)
        CFG.bgName = v
        for _, b in ipairs(BG_LIST) do
            if b.name == v then bgImg.Image = b.id break end
        end
        saveCFG()
    end)
    for _, b in ipairs(BG_LIST) do
        if b.name == CFG.bgName then bgImg.Image = b.id end
    end
    local s2 = createSection(tab, T("bg_transparency"))
    createSlider(s2, T("bg_transparency"), 0, 100, math.floor(CFG.bgTransparency*100), function(v)
        CFG.bgTransparency = v/100
        bgImg.ImageTransparency = v/100
    end)
    local s3 = createSection(tab, T("ui_transparency"))
    createSlider(s3, "Overlay Darkness", 0, 100, 100 - math.floor(CFG.tintTransparency*100), function(v)
        CFG.tintTransparency = 1 - v/100
        tint.BackgroundTransparency = CFG.tintTransparency
    end)
    local s4 = createSection(tab, T("wm_transparency"))
    createSlider(s4, T("wm_transparency"), 0, 100, math.floor(CFG.wmTransparency*100), function(v)
        CFG.wmTransparency = v/100
        wm.BackgroundTransparency = v/100
    end)
end

-- MUSIC
do
    local tab = createTab("music")
    local bgSound = new("Sound", {Name="PiddleMusic", Volume=CFG.volume/100, Looped=true, Parent=SoundService})
    local TRACKS = {
        ["Chill Lo-Fi"]="rbxassetid://1837879082", ["Synthwave"]="rbxassetid://1836318003",
        ["Trap Beat"]="rbxassetid://1837842597", ["Phonk"]="rbxassetid://9046731150",
        ["Epic Battle"]="rbxassetid://1840684520", ["Sad Piano"]="rbxassetid://1838441755",
    }
    local tOrder = {}
    for k in pairs(TRACKS) do table.insert(tOrder, k) end
    table.sort(tOrder)
    local curTrack = 1
    local function playIdx(i)
        i = ((i-1) % #tOrder) + 1
        curTrack = i
        bgSound.SoundId = TRACKS[tOrder[i]]
        bgSound:Play()
    end
    local sec = createSection(tab, T("tracks"))
    createButton(sec, T("play"), function()
        if bgSound.SoundId == "" then playIdx(curTrack) else bgSound:Play() end
    end)
    createButton(sec, T("pause"), function() bgSound:Pause() end)
    createButton(sec, T("stop"), function() bgSound:Stop(); bgSound.TimePosition = 0 end)
    createButton(sec, T("next_track"), function() playIdx(curTrack + 1) end)
    createButton(sec, T("prev_track"), function() playIdx(curTrack - 1) end)
    local musicBox = createTextBox(sec, T("custom_music"), CFG.musicId, function(t) CFG.musicId = t end)
    createButton(sec, T("play_custom"), function()
        local id = musicBox.Text:gsub("%D","")
        if id ~= "" then
            bgSound.SoundId = "rbxassetid://"..id
            bgSound:Play()
            CFG.musicId = id
        end
    end)
    createSlider(sec, T("volume"), 0, 100, CFG.volume, function(v)
        bgSound.Volume = v/100
        CFG.volume = v
    end)
end

-- CONFIG
do
    local tab = createTab("config")
    local sec = createSection(tab, T("config"))
    createButton(sec, T("save_cfg"), function() saveCFG() end)
    createButton(sec, T("load_cfg"), function() loadCFG() end)
end

-- SETTINGS
do
    local tab = createTab("settings")
    local sec = createSection(tab, T("settings"))
    createDropdown(sec, T("language"), {"EN","RU"}, "EN", function() end)
end

-- VOTE
do
    local tab = createTab("vote")
    local candidates = {"VoteGui","VotingGui","MapVoting","Vote","VoteMenu","VotingScreen","Voting","MapVote","VoteUI","VoteFrame"}
    local function getVoteGuiAny()
        local pgui = LP:FindFirstChild("PlayerGui")
        if pgui then
            for _, n in ipairs(candidates) do
                local v = pgui:FindFirstChild(n)
                if v then return v end
            end
            for _, d in ipairs(pgui:GetDescendants()) do
                if d:IsA("ScreenGui") and d.Name:lower():find("vote") then return d end
            end
        end
        return nil
    end
    local function collectMapButtons(v)
        local btns = {}
        if not v then return btns end
        for _, d in ipairs(v:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible
                and d.AbsoluteSize.X > 30 and d.AbsoluteSize.Y > 30 then
                table.insert(btns, d)
            end
        end
        return btns
    end

    -- Button:Activate() does NOT fire MouseButton1Click, so use real signal firing
    local function clickBtn(b)
        local fired = false
        if type(firesignal) == "function" then
            for _, sn in ipairs({"MouseButton1Down","MouseButton1Click","MouseButton1Up","Activated"}) do
                if safe(function() firesignal(b[sn]); return true end) then fired = true end
            end
        end
        if not fired and type(getconnections) == "function" then
            for _, sn in ipairs({"MouseButton1Click","Activated","MouseButton1Down"}) do
                safe(function()
                    for _, c in ipairs(getconnections(b[sn])) do
                        safe(function() c:Fire() end)
                        fired = true
                    end
                end)
            end
        end
        if not fired then safe(function() b:Activate() end) end
    end

    -- capture the game's real vote remote + args when you vote once manually
    local lastVote = nil
    local hooked = false
    safe(function()
        if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
            local old
            local wrap = newcclosure or function(f) return f end
            old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                local m = getnamecallmethod()
                if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance"
                    and string.find(string.lower(self.Name), "vote", 1, true) then
                    lastVote = { remote = self, method = m, args = table.pack(...) }
                end
                return old(self, ...)
            end))
            hooked = true
        end
    end)

    local function scanRemotes()
        local r = {}
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name:lower():find("vote") then
                table.insert(r, d)
            end
        end
        return r
    end

    local voteDuperOn = false
    local voteDuperTargetIndex = nil
    local function replayVote()
        local lv = lastVote
        if not lv or not lv.remote or not lv.remote.Parent then return end
        for _ = 1, 3 do
            task.spawn(function()
                safe(function()
                    if lv.method == "FireServer" then lv.remote:FireServer(table.unpack(lv.args, 1, lv.args.n))
                    else lv.remote:InvokeServer(table.unpack(lv.args, 1, lv.args.n)) end
                end)
            end)
        end
    end
    local function voteDuperLoop()
        while voteDuperOn do
            task.wait(0.25)
            safe(replayVote)
            safe(function()
                local v = getVoteGuiAny()
                if not v then return end
                local btns = collectMapButtons(v)
                if #btns == 0 then return end
                local target = voteDuperTargetIndex and btns[voteDuperTargetIndex] or btns[1]
                if target then clickBtn(target) end
                for _, d in ipairs(v:GetDescendants()) do
                    if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                        local t = (d:IsA("TextButton") and d.Text or ""):lower()
                        if t:find("vote") or t:find("confirm") or t:find("select") or t:find("ready") then
                            clickBtn(d)
                        end
                    end
                end
            end)
        end
    end

    local sec = createSection(tab, T("vote_duper"))
    local voteStatus = new("TextLabel", {
        Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, TextWrapped=true,
        Text="Status: idle. Vote for a map once manually so the remote gets captured.",
        TextColor3=THEME.textDim, Font=Enum.Font.GothamMedium, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=54, Parent=sec
    })
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not voteDuperOn then
                if lastVote then
                    voteStatus.Text = "Captured: "..lastVote.remote.Name.." ("..lastVote.args.n.." args). Ready."
                elseif not hooked then
                    voteStatus.Text = "Executor has no hookmetamethod: GUI-click mode only."
                end
            end
        end
    end)
    local voteMapsList = new("ScrollingFrame", {
        Size=UDim2.new(1,0,0,110), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=54, Parent=sec
    })
    local vmL = Instance.new("UIListLayout", voteMapsList)
    vmL.Padding = UDim.new(0,4)
    local function refreshVoteMaps()
        for _, c in ipairs(voteMapsList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local btns = collectMapButtons(getVoteGuiAny())
        if #btns == 0 then
            voteStatus.Text = "Status: no voting GUI right now"
            return
        end
        voteStatus.Text = "Voting GUI found ("..#btns.." buttons). Pick a target."
        for i = 1, #btns do
            local nm = btns[i].Name
            if btns[i]:IsA("TextButton") and btns[i].Text ~= "" then nm = btns[i].Text end
            local btn = new("TextButton", {
                Size=UDim2.new(1,-4,0,30), BackgroundColor3=THEME.buttonBg, BackgroundTransparency=0.86,
                TextColor3=THEME.text, Font=Enum.Font.GothamMedium, TextSize=12, BorderSizePixel=0,
                Text="  #"..i.."  "..nm, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=55, Parent=voteMapsList
            })
            round(btn, 10)
            btn.MouseButton1Click:Connect(function()
                voteDuperTargetIndex = i
                voteStatus.Text = "Target set: #"..i.." "..nm
            end)
        end
    end
    createButton(sec, T("vote_refresh"), refreshVoteMaps)
    createButton(sec, "Scan Remotes", function()
        local r = scanRemotes()
        local names = {}
        for i = 1, math.min(#r, 4) do table.insert(names, r[i].Name) end
        voteStatus.Text = #r.." vote remote(s): "..(#names > 0 and table.concat(names, ", ") or "none")
    end)
    createButton(sec, T("vote_start"), function()
        if voteDuperOn then return end
        voteDuperOn = true
        voteStatus.Text = "Status: RUNNING"
        task.spawn(voteDuperLoop)
    end)
    createButton(sec, T("vote_stop"), function()
        voteDuperOn = false
        voteStatus.Text = "Status: stopped"
    end)
end

-- WATCHDOG: removes any UI text containing the Cyrillic word "sek" (written via code points, no encoding issues)
do
    local lo = {0x441, 0x435, 0x43A}
    local up = {0x421, 0x415, 0x41A}
    local WORDS = {}
    for mask = 0, 7 do
        local cps = {}
        for i = 1, 3 do
            cps[i] = (bit32.band(bit32.rshift(mask, i - 1), 1) == 1) and up[i] or lo[i]
        end
        table.insert(WORDS, utf8.char(cps[1], cps[2], cps[3]))
    end
    local function isText(i) return i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") end
    local function kill(i, t)
        warn("[PIDDLE][WD] removed: "..tostring(t))
        safe(function() i:Destroy() end)
        if i.Parent then
            safe(function() i.Text = "" end)
            safe(function() i.Visible = false end)
        end
    end
    local function check(i)
        if not isText(i) then return end
        local t = i.Text
        if t and t ~= "" then
            for _, w in ipairs(WORDS) do
                if string.find(t, w, 1, true) then kill(i, t); return end
            end
        end
    end
    local function watch(i)
        if not isText(i) then return end
        check(i)
        safe(function() i:GetPropertyChangedSignal("Text"):Connect(function() check(i) end) end)
    end
    local roots = { pg }
    safe(function() table.insert(roots, game:GetService("CoreGui")) end)
    safe(function() if type(gethui) == "function" then table.insert(roots, gethui()) end end)
    safe(function() if type(get_hidden_gui) == "function" then table.insert(roots, get_hidden_gui()) end end)
    for _, r in ipairs(roots) do
        safe(function() r.DescendantAdded:Connect(function(d) task.defer(watch, d) end) end)
        safe(function() for _, d in ipairs(r:GetDescendants()) do watch(d) end end)
    end
    task.spawn(function()
        while true do
            task.wait(0.35)
            for _, r in ipairs(roots) do
                safe(function() for _, d in ipairs(r:GetDescendants()) do check(d) end end)
            end
        end
    end)
end

-- ===== INIT =====
for n, t in pairs(tabs) do setTabActive(t, n == "home") end
pageScroll.CanvasPosition = Vector2.new(0,0)

warn("[PIDDLE] LOADED v8 OK")
