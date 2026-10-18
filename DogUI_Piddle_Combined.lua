-- COMBINED SOURCE: DogUI_Full.lua + addon.lua (3).txt
-- All original source lines are preserved. Note: these are two UI frameworks, so both original entrypoints run.

--[[
    DogUI  |  dark sidebar UI library for Roblox (PC + Mobile)
    Layout: logo / sidebar tabs (+sub tabs) / search / two-column collapsible sections / profile card
    Elements: Toggle(+options popup), Slider, Dropdown(multi), Keybind, Textbox, Button, Label, Divider, ColorPicker
    Extras: draggable window, floating toggle button, notifications, config save/load, animated network background

    Images (Logo / Banner / ToggleIcon) accept:
      - number or "rbxassetid://ID"
      - file in executor workspace ("dog_logo.png")  -> getcustomasset
      - direct URL ("https://...png")                -> downloaded to workspace, then getcustomasset
]]

local Library = {
    Version = "1.0.0",
    Flags = {},
    Options = {},
    Windows = {},
    LowerCase = true,
    Connections = {},
    Unloaded = false,
}

--// services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local IsTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled

--// theme
local Theme = {
    Window      = Color3.fromRGB(10, 10, 12),
    Sidebar     = Color3.fromRGB(13, 13, 15),
    Section     = Color3.fromRGB(17, 17, 20),
    SectionHead = Color3.fromRGB(21, 21, 25),
    Row         = Color3.fromRGB(24, 24, 28),
    Box         = Color3.fromRGB(26, 26, 30),
    Stroke      = Color3.fromRGB(34, 34, 40),
    StrokeSoft  = Color3.fromRGB(26, 26, 31),
    Accent      = Color3.fromRGB(240, 240, 245),
    Text        = Color3.fromRGB(222, 222, 228),
    Dim         = Color3.fromRGB(128, 128, 138),
    Dimmer      = Color3.fromRGB(78, 78, 88),
    Check       = Color3.fromRGB(12, 12, 14),
    Line        = Color3.fromRGB(255, 255, 255),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontLight   = Enum.Font.Gotham,
}
Library.Theme = Theme

local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--// utils
local function tl(text)
    text = tostring(text)
    return Library.LowerCase and string.lower(text) or text
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info or TWEEN_FAST, props)
    t:Play()
    return t
end

local function New(class, props, children)
    local inst = Instance.new(class)
    if class == "TextButton" or class == "ImageButton" then
        inst.AutoButtonColor = false
    end
    if class == "Frame" or class == "TextButton" or class == "ScrollingFrame" or class == "ImageLabel" or class == "ImageButton" then
        inst.BorderSizePixel = 0
    end
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 4), Parent = parent })
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Padding(parent, l, t, r, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent = parent,
    })
end

local function List(parent, pad, dir, halign, valign)
    return New("UIListLayout", {
        Padding = UDim.new(0, pad or 0),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = valign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function Label(props)
    local base = {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        TextSize = 11,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = false,
    }
    for k, v in pairs(props) do base[k] = v end
    return New("TextLabel", base)
end

local function IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function Clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function Round(v, step)
    if not step or step <= 0 then return v end
    return math.floor(v / step + 0.5) * step
end

local function FormatNumber(v, step)
    if step and step < 1 then
        local decimals = math.max(0, math.ceil(-math.log10(step)))
        return string.format("%." .. decimals .. "f", v)
    end
    return tostring(math.floor(v + 0.5))
end

--// image resolver (asset id / workspace file / url)
local getAsset = (getcustomasset or get_custom_asset or getsynasset)
local function ResolveImage(src)
    if src == nil or src == "" then return "" end
    if typeof(src) == "number" then return "rbxassetid://" .. src end
    if typeof(src) ~= "string" then return "" end
    if src:find("^rbxasset") or src:find("^rbxthumb") then return src end
    if src:match("^%d+$") then return "rbxassetid://" .. src end
    if not getAsset then return "" end

    local isUrl = src:find("^https?://") ~= nil
    local fileName = src
    if isUrl then
        local clean = src:gsub("[^%w]", ""):sub(-40)
        fileName = "dogui_" .. clean .. ".png"
        if isfile and writefile and not isfile(fileName) then
            local ok, data = pcall(function() return game:HttpGet(src) end)
            if ok and data then pcall(writefile, fileName, data) end
        end
    end
    if isfile and isfile(fileName) then
        local ok, res = pcall(getAsset, fileName)
        if ok then return res end
    end
    return ""
end

local function GetGuiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    ok, h = pcall(function() return game:GetService("CoreGui") end)
    if ok and h then
        local test = pcall(function() return h.Name end)
        if test then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function Protect(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
end

--// drag helper
local function MakeDraggable(handle, target, getScale, onClick)
    local dragging, startInput, startPos, startMouse, moved
    Connect(handle.InputBegan, function(input)
        if IsPress(input) then
            dragging = true
            moved = 0
            startMouse = input.Position
            startPos = target.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                    if onClick and moved < 5 then onClick() end
                end
            end)
        end
    end)
    Connect(UIS.InputChanged, function(input)
        if dragging and IsMove(input) then
            local d = input.Position - startMouse
            moved = math.max(moved, d.Magnitude)
            local s = getScale and getScale() or 1
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s, startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
        end
    end)
end

------------------------------------------------------------------------------------------------
-- Element container (shared by Sections and Option popups)
------------------------------------------------------------------------------------------------
local Container = {}
Container.__index = Container

function Container:_register(element, row, name)
    element.Row = row
    element.SearchName = string.lower(name or "")
    table.insert(self.Elements, element)
    if element.Flag then
        Library.Flags[element.Flag] = element.Value
        Library.Options[element.Flag] = element
    end
    return element
end

function Container:_row(height)
    self._order = (self._order or 0) + 1
    return New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 22),
        BackgroundTransparency = 1,
        LayoutOrder = self._order,
        Parent = self.Holder,
    })
end

local function Fire(element, ...)
    if element.Flag then Library.Flags[element.Flag] = element.Value end
    local ok, err = pcall(element.Callback, ...)
    if not ok then warn("[DogUI] callback error (" .. tostring(element.Name) .. "): " .. tostring(err)) end
    for _, fn in ipairs(element._changed) do pcall(fn, ...) end
end

-- ---------- Label ----------
function Container:AddLabel(cfg)
    if type(cfg) == "string" then cfg = { Name = cfg } end
    local el = { Type = "Label", Name = cfg.Name or "label", _changed = {}, Callback = function() end }
    local row = self:_row(cfg.Height or 18)
    local lbl = Label({
        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0),
        Text = cfg.Raw and cfg.Name or tl(cfg.Name or "label"),
        TextColor3 = cfg.Color or Theme.Dim, TextSize = cfg.TextSize or 10,
        TextWrapped = true, Parent = row,
    })
    function el:SetText(t) lbl.Text = cfg.Raw and t or tl(t) end
    return self:_register(el, row, el.Name)
end

-- ---------- Divider ----------
function Container:AddDivider()
    local el = { Type = "Divider", Name = "", _changed = {}, Callback = function() end }
    local row = self:_row(8)
    New("Frame", {
        Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0.5, 0),
        BackgroundColor3 = Theme.Stroke, Parent = row,
    })
    return self:_register(el, row, "")
end

-- ---------- Button ----------
function Container:AddButton(cfg)
    cfg = cfg or {}
    local el = { Type = "Button", Name = cfg.Name or "button", Callback = cfg.Callback or function() end, _changed = {} }
    local row = self:_row(26)
    local btn = New("TextButton", {
        Size = UDim2.new(1, -12, 0, 20), Position = UDim2.new(0, 6, 0.5, -10),
        BackgroundColor3 = Theme.Box, Text = "", Parent = row,
    })
    Corner(btn, 4)
    local st = Stroke(btn, Theme.Stroke)
    local txt = Label({
        Size = UDim2.fromScale(1, 1), Text = tl(el.Name), TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Theme.Dim, Parent = btn,
    })
    Connect(btn.MouseEnter, function()
        Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Row })
        Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Text })
    end)
    Connect(btn.MouseLeave, function()
        Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Box })
        Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Dim })
    end)
    Connect(btn.MouseButton1Down, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Accent }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Check }) end)
    Connect(btn.MouseButton1Up, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Row }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Text }) end)
    Connect(btn.MouseButton1Click, function() Fire(el) end)
    function el:SetText(t) txt.Text = tl(t) end
    return self:_register(el, row, el.Name)
end

-- ---------- Toggle (+ options popup) ----------
local function DrawCheck(box)
    local short = New("Frame", {
        Size = UDim2.fromOffset(2, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4, 7.5),
        Rotation = -45, BackgroundColor3 = Theme.Check, BackgroundTransparency = 1, Parent = box,
    })
    local long = New("Frame", {
        Size = UDim2.fromOffset(2, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7.5, 5.5),
        Rotation = 45, BackgroundColor3 = Theme.Check, BackgroundTransparency = 1, Parent = box,
    })
    return short, long
end

local function DrawDots(parent)
    local holder = New("Frame", { Size = UDim2.fromOffset(12, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = parent })
    local dots = {}
    for i = 0, 2 do
        local d = New("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(i * 5, 0.5), BackgroundColor3 = Theme.Dimmer, Parent = holder })
        Corner(d, 1)
        table.insert(dots, d)
    end
    return dots
end

function Container:AddToggle(cfg)
    cfg = cfg or {}
    local el = {
        Type = "Toggle", Name = cfg.Name or "toggle", Flag = cfg.Flag, Value = cfg.Default and true or false,
        Callback = cfg.Callback or function() end, _changed = {},
    }
    local row = self:_row(22)
    local hit = New("TextButton", { Size = UDim2.new(1, cfg.Options and -26 or 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row })

    local box = New("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 8, 0.5, -6),
        BackgroundColor3 = Theme.Box, Parent = row,
    })
    Corner(box, 3)
    local boxStroke = Stroke(box, Theme.Stroke)
    local c1, c2 = DrawCheck(box)

    local lbl = Label({
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(28, 0),
        Text = tl(el.Name), TextColor3 = Theme.Dim, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })

    local function Render(animate)
        local on = el.Value
        local info = animate and TWEEN_FAST or TweenInfo.new(0)
        Tween(box, info, { BackgroundColor3 = on and Theme.Accent or Theme.Box })
        Tween(boxStroke, info, { Color = on and Theme.Accent or Theme.Stroke })
        Tween(c1, info, { BackgroundTransparency = on and 0 or 1 })
        Tween(c2, info, { BackgroundTransparency = on and 0 or 1 })
        Tween(lbl, info, { TextColor3 = on and Theme.Text or Theme.Dim })
    end

    function el:Set(v, silent)
        v = v and true or false
        if self.Value == v then return end
        self.Value = v
        Render(true)
        if not silent then Fire(self, v) else if self.Flag then Library.Flags[self.Flag] = v end end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end

    Connect(hit.MouseButton1Click, function() el:Set(not el.Value) end)
    Connect(hit.MouseEnter, function() if not el.Value then Tween(lbl, TWEEN_FAST, { TextColor3 = Theme.Text }) end end)
    Connect(hit.MouseLeave, function() if not el.Value then Tween(lbl, TWEEN_FAST, { TextColor3 = Theme.Dim }) end end)
    Render(false)

    -- options ("...") popup
    if cfg.Options then
        local dotsBtn = New("TextButton", {
            Size = UDim2.fromOffset(22, 18), Position = UDim2.new(1, -26, 0.5, -9),
            BackgroundTransparency = 1, Text = "", Parent = row,
        })
        local dots = DrawDots(dotsBtn)
        Connect(dotsBtn.MouseEnter, function() for _, d in ipairs(dots) do Tween(d, TWEEN_FAST, { BackgroundColor3 = Theme.Text }) end end)
        Connect(dotsBtn.MouseLeave, function() for _, d in ipairs(dots) do Tween(d, TWEEN_FAST, { BackgroundColor3 = Theme.Dimmer }) end end)
        local popup
        Connect(dotsBtn.MouseButton1Click, function()
            if not popup then
                popup = self.Window:_createPopup(el.Name)
                if typeof(cfg.Options) == "function" then cfg.Options(popup) end
                el.Popup = popup
            end
            self.Window:_openPopup(popup, dotsBtn)
        end)
        el.Options = cfg.Options
    end

    return self:_register(el, row, el.Name)
end

-- ---------- Slider ----------
function Container:AddSlider(cfg)
    cfg = cfg or {}
    local min, max = cfg.Min or 0, cfg.Max or 100
    local step = cfg.Increment or 1
    local el = {
        Type = "Slider", Name = cfg.Name or "slider", Flag = cfg.Flag,
        Value = Clamp(cfg.Default or min, min, max), Callback = cfg.Callback or function() end, _changed = {},
    }
    local suffix = cfg.Suffix or ""
    local row = self:_row(32)
    Label({ Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(8, 2), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local valueLbl = Label({
        Size = UDim2.new(0, 50, 0, 16), Position = UDim2.new(1, -58, 0, 2), TextXAlignment = Enum.TextXAlignment.Right,
        Text = "", TextColor3 = Theme.Text, TextSize = 10, Parent = row,
    })
    local hit = New("TextButton", { Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(6, 18), BackgroundTransparency = 1, Text = "", Parent = row })
    local track = New("Frame", { Size = UDim2.new(1, -4, 0, 4), Position = UDim2.new(0, 2, 0.5, -2), BackgroundColor3 = Theme.Box, Parent = hit })
    Corner(track, 2)
    Stroke(track, Theme.Stroke)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, Parent = track })
    Corner(fill, 2)
    local knob = New("Frame", {
        Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Theme.Accent, Parent = track,
    })
    Corner(knob, 4)

    local function Render(animate)
        local a = (el.Value - min) / math.max(max - min, 1e-9)
        local info = animate and TWEEN_FAST or TweenInfo.new(0)
        Tween(fill, info, { Size = UDim2.fromScale(a, 1) })
        Tween(knob, info, { Position = UDim2.fromScale(a, 0.5) })
        valueLbl.Text = FormatNumber(el.Value, step) .. suffix
    end

    function el:Set(v, silent)
        v = Clamp(Round(v, step), min, max)
        if v == self.Value then return end
        self.Value = v
        Render(true)
        if not silent then Fire(self, v) elseif self.Flag then Library.Flags[self.Flag] = v end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end

    local dragging = false
    local function FromInput(input)
        local a = Clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        el:Set(min + (max - min) * a)
    end
    Connect(hit.InputBegan, function(input)
        if IsPress(input) then
            dragging = true
            self.Window:_lockDrag(true)
            Tween(knob, TWEEN_FAST, { Size = UDim2.fromOffset(10, 10) })
            FromInput(input)
        end
    end)
    Connect(UIS.InputEnded, function(input)
        if dragging and IsPress(input) then
            dragging = false
            self.Window:_lockDrag(false)
            Tween(knob, TWEEN_FAST, { Size = UDim2.fromOffset(8, 8) })
        end
    end)
    Connect(UIS.InputChanged, function(input)
        if dragging and IsMove(input) then FromInput(input) end
    end)
    Render(false)
    return self:_register(el, row, el.Name)
end

-- ---------- Dropdown ----------
function Container:AddDropdown(cfg)
    cfg = cfg or {}
    local values = cfg.Values or {}
    local multi = cfg.Multi
    local el = {
        Type = "Dropdown", Name = cfg.Name or "dropdown", Flag = cfg.Flag, Values = values,
        Callback = cfg.Callback or function() end, _changed = {}, Multi = multi,
    }
    if multi then
        el.Value = {}
        for _, v in ipairs(cfg.Default or {}) do el.Value[v] = true end
    else
        el.Value = cfg.Default
    end

    self._order = (self._order or 0) + 1
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = self._order, Parent = self.Holder,
    })
    List(row, 2, nil, Enum.HorizontalAlignment.Center)
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", LayoutOrder = 1, Parent = row })
    Label({ Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = head })
    local box = New("Frame", { Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0.5, 2, 0.5, -9), BackgroundColor3 = Theme.Box, Parent = head })
    Corner(box, 4)
    Stroke(box, Theme.Stroke)
    local sel = Label({
        Size = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(6, 0), TextColor3 = Theme.Text, TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = box,
    })
    local arrow = Label({
        Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -14, 0.5, -6), Text = ">", Rotation = 90,
        TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dim, TextSize = 10, Font = Theme.FontBold, Parent = box,
    })

    local list = New("Frame", {
        Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Box,
        Visible = false, LayoutOrder = 2, Parent = row,
    })
    list.Position = UDim2.fromOffset(6, 0)
    Corner(list, 4)
    Stroke(list, Theme.Stroke)
    List(list, 0)
    Padding(list, 0, 2, 0, 2)
    local buttons = {}
    local open = false

    local function SelectedText()
        if multi then
            local t = {}
            for _, v in ipairs(el.Values) do if el.Value[v] then table.insert(t, tostring(v)) end end
            return #t == 0 and "none" or table.concat(t, ", ")
        end
        return el.Value ~= nil and tostring(el.Value) or "none"
    end

    local function Render()
        sel.Text = tl(SelectedText())
        for v, b in pairs(buttons) do
            local on = multi and el.Value[v] or (not multi and el.Value == v)
            Tween(b.Label, TWEEN_FAST, { TextColor3 = on and Theme.Accent or Theme.Dim })
            b.Dot.Visible = on and true or false
        end
    end

    local function Build()
        for _, b in pairs(buttons) do b.Button:Destroy() end
        table.clear(buttons)
        for i, v in ipairs(el.Values) do
            local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", LayoutOrder = i, Parent = list })
            local l = Label({ Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(v), TextColor3 = Theme.Dim, TextSize = 10, Parent = b })
            local dot = New("Frame", { Size = UDim2.fromOffset(4, 4), Position = UDim2.new(1, -12, 0.5, -2), BackgroundColor3 = Theme.Accent, Visible = false, Parent = b })
            Corner(dot, 2)
            buttons[v] = { Button = b, Label = l, Dot = dot }
            Connect(b.MouseEnter, function() l.TextColor3 = Theme.Text end)
            Connect(b.MouseLeave, function()
                local on = multi and el.Value[v] or (not multi and el.Value == v)
                l.TextColor3 = on and Theme.Accent or Theme.Dim
            end)
            Connect(b.MouseButton1Click, function()
                if multi then
                    el.Value[v] = not el.Value[v] or nil
                else
                    el.Value = v
                    open = false
                    list.Visible = false
                    Tween(arrow, TWEEN_FAST, { Rotation = 90 })
                end
                Render()
                Fire(el, el.Value)
            end)
        end
        Render()
    end

    function el:Set(v, silent)
        if multi then
            self.Value = {}
            for k, on in pairs(v) do
                if type(k) == "number" then self.Value[on] = true elseif on then self.Value[k] = true end
            end
        else
            self.Value = v
        end
        Render()
        if not silent then Fire(self, self.Value) elseif self.Flag then Library.Flags[self.Flag] = self.Value end
    end
    function el:Get() return self.Value end
    function el:SetValues(newValues)
        self.Values = newValues
        Build()
    end
    function el:OnChanged(fn) table.insert(self._changed, fn) end

    Connect(head.MouseButton1Click, function()
        open = not open
        list.Visible = open
        Tween(arrow, TWEEN_FAST, { Rotation = open and -90 or 90 })
    end)
    Build()
    return self:_register(el, row, el.Name)
end

-- ---------- Keybind ----------
local KeyNames = {
    [Enum.KeyCode.LeftShift] = "LShift", [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftControl] = "LCtrl", [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftAlt] = "LAlt", [Enum.KeyCode.RightAlt] = "RAlt",
}
local function KeyToString(k)
    if not k then return "none" end
    if typeof(k) == "EnumItem" then
        if k.EnumType == Enum.UserInputType then
            if k == Enum.UserInputType.MouseButton1 then return "M1" end
            if k == Enum.UserInputType.MouseButton2 then return "M2" end
            if k == Enum.UserInputType.MouseButton3 then return "M3" end
            return k.Name
        end
        return KeyNames[k] or k.Name
    end
    return tostring(k)
end

function Container:AddKeybind(cfg)
    cfg = cfg or {}
    local el = {
        Type = "Keybind", Name = cfg.Name or "keybind", Flag = cfg.Flag, Value = cfg.Default,
        Mode = cfg.Mode or "Toggle", State = false,
        Callback = cfg.Callback or function() end, Changed = cfg.OnBindChanged or function() end, _changed = {},
    }
    local row = self:_row(22)
    Label({ Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local btn = New("TextButton", {
        Size = UDim2.fromOffset(52, 16), Position = UDim2.new(1, -58, 0.5, -8), BackgroundColor3 = Theme.Box,
        Text = "", Parent = row,
    })
    Corner(btn, 4)
    Stroke(btn, Theme.Stroke)
    local txt = Label({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 9, Text = "", TextColor3 = Theme.Text, Parent = btn })
    local listening = false

    local function Render() txt.Text = listening and "..." or tl(KeyToString(el.Value)) end
    function el:Set(k, silent)
        self.Value = k
        listening = false
        Render()
        if self.Flag then Library.Flags[self.Flag] = k end
        if not silent then pcall(self.Changed, k) end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end

    Connect(btn.MouseButton1Click, function()
        listening = true
        Render()
    end)
    Connect(UIS.InputBegan, function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then el:Set(nil) else el:Set(input.KeyCode) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                el:Set(input.UserInputType)
            end
            return
        end
        if processed or not el.Value then return end
        if input.KeyCode == el.Value or input.UserInputType == el.Value then
            if el.Mode == "Toggle" then
                el.State = not el.State
                Fire(el, el.State)
            elseif el.Mode == "Hold" then
                el.State = true
                Fire(el, true)
            else
                Fire(el, true)
            end
        end
    end)
    Connect(UIS.InputEnded, function(input)
        if el.Mode == "Hold" and el.Value and (input.KeyCode == el.Value or input.UserInputType == el.Value) then
            el.State = false
            Fire(el, false)
        end
    end)
    Render()
    return self:_register(el, row, el.Name)
end

-- ---------- Textbox ----------
function Container:AddTextbox(cfg)
    cfg = cfg or {}
    local el = {
        Type = "Textbox", Name = cfg.Name or "textbox", Flag = cfg.Flag, Value = cfg.Default or "",
        Callback = cfg.Callback or function() end, _changed = {},
    }
    local row = self:_row(28)
    Label({ Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local holder = New("Frame", { Size = UDim2.new(0.6, -10, 0, 20), Position = UDim2.new(0.4, 2, 0.5, -10), BackgroundColor3 = Theme.Box, Parent = row })
    Corner(holder, 4)
    local st = Stroke(holder, Theme.Stroke)
    local box = New("TextBox", {
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(5, 0), BackgroundTransparency = 1,
        Text = el.Value, PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = Theme.Dimmer,
        TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = holder,
    })
    function el:Set(v, silent)
        self.Value = tostring(v)
        box.Text = self.Value
        if not silent then Fire(self, self.Value) elseif self.Flag then Library.Flags[self.Flag] = self.Value end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    Connect(box.Focused, function() Tween(st, TWEEN_FAST, { Color = Theme.Accent }) end)
    Connect(box.FocusLost, function()
        Tween(st, TWEEN_FAST, { Color = Theme.Stroke })
        if cfg.Numeric and not tonumber(box.Text) then box.Text = el.Value return end
        el.Value = box.Text
        Fire(el, el.Value)
    end)
    return self:_register(el, row, el.Name)
end

-- ---------- Color picker ----------
function Container:AddColorPicker(cfg)
    cfg = cfg or {}
    local el = {
        Type = "ColorPicker", Name = cfg.Name or "color", Flag = cfg.Flag, Value = cfg.Default or Color3.fromRGB(255, 255, 255),
        Callback = cfg.Callback or function() end, _changed = {},
    }
    local h, s, v = el.Value:ToHSV()

    self._order = (self._order or 0) + 1
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = self._order, Parent = self.Holder,
    })
    List(row, 2, nil, Enum.HorizontalAlignment.Center)
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", LayoutOrder = 1, Parent = row })
    Label({ Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = head })
    local swatch = New("Frame", { Size = UDim2.fromOffset(22, 12), Position = UDim2.new(1, -30, 0.5, -6), BackgroundColor3 = el.Value, Parent = head })
    Corner(swatch, 3)
    Stroke(swatch, Theme.Stroke)

    local panel = New("Frame", { Size = UDim2.new(1, -12, 0, 78), Position = UDim2.fromOffset(6, 0), BackgroundColor3 = Theme.Box, Visible = false, LayoutOrder = 2, Parent = row })
    Corner(panel, 4)
    Stroke(panel, Theme.Stroke)

    local sv = New("TextButton", { Size = UDim2.new(1, -40, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Text = "", ClipsDescendants = true, Parent = panel })
    Corner(sv, 3)
    local white = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
    New("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
    local svCursor = New("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = sv })
    Corner(svCursor, 3)
    Stroke(svCursor, Color3.new(0, 0, 0), 1)

    local hue = New("TextButton", { Size = UDim2.new(0, 14, 1, -12), Position = UDim2.new(1, -22, 0, 6), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", Parent = panel })
    Corner(hue, 3)
    New("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        }),
        Parent = hue,
    })
    local hueCursor = New("Frame", { Size = UDim2.new(1, 4, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = hue })
    Corner(hueCursor, 2)
    Stroke(hueCursor, Color3.new(0, 0, 0), 1)

    local function Render(fire)
        el.Value = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = el.Value
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        if fire then Fire(el, el.Value) elseif el.Flag then Library.Flags[el.Flag] = el.Value end
    end
    function el:Set(c, silent)
        h, s, v = c:ToHSV()
        Render(not silent)
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end

    local mode
    local function Update(input)
        if mode == "sv" then
            s = Clamp((input.Position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
            v = 1 - Clamp((input.Position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        elseif mode == "hue" then
            h = Clamp((input.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 0.999)
        end
        Render(true)
    end
    Connect(sv.InputBegan, function(i) if IsPress(i) then mode = "sv"; self.Window:_lockDrag(true); Update(i) end end)
    Connect(hue.InputBegan, function(i) if IsPress(i) then mode = "hue"; self.Window:_lockDrag(true); Update(i) end end)
    Connect(UIS.InputChanged, function(i) if mode and IsMove(i) then Update(i) end end)
    Connect(UIS.InputEnded, function(i) if mode and IsPress(i) then mode = nil; self.Window:_lockDrag(false) end end)
    Connect(head.MouseButton1Click, function() panel.Visible = not panel.Visible end)
    Render(false)
    return self:_register(el, row, el.Name)
end

------------------------------------------------------------------------------------------------
-- Section
------------------------------------------------------------------------------------------------
local function NewSection(tab, cfg)
    local sec = setmetatable({
        Name = cfg.Name or "section", Elements = {}, Window = tab.Window, Tab = tab, _order = 0, Collapsed = false,
    }, Container)

    local column = (cfg.Side == "Right" or cfg.Side == 2) and tab.RightColumn or tab.LeftColumn
    sec.Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Section,
        LayoutOrder = (#tab.Sections + 1), Parent = column,
    })
    Corner(sec.Frame, 5)
    Stroke(sec.Frame, Theme.StrokeSoft)
    List(sec.Frame, 0)

    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.SectionHead, Text = "", LayoutOrder = 0, Parent = sec.Frame })
    Corner(head, 5)
    -- square off the bottom corners of the header
    New("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Theme.SectionHead, Parent = head })
    Label({ Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(sec.Name), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 10, Parent = head })
    local arrow = Label({
        Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -20, 0.5, -7), Text = ">", Rotation = -90,
        TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dim, Font = Theme.FontBold, TextSize = 10, Parent = head,
    })

    sec.Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = 1, ClipsDescendants = false, Parent = sec.Frame,
    })
    List(sec.Holder, 0)
    Padding(sec.Holder, 0, 3, 0, 4)

    Connect(head.MouseButton1Click, function()
        sec.Collapsed = not sec.Collapsed
        sec.Holder.Visible = not sec.Collapsed
        Tween(arrow, TWEEN_FAST, { Rotation = sec.Collapsed and 90 or -90 })
    end)

    function sec:SetCollapsed(state)
        self.Collapsed = state
        self.Holder.Visible = not state
        arrow.Rotation = state and 90 or -90
    end

    table.insert(tab.Sections, sec)
    return sec
end

------------------------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------------------------
local Window = {}
Window.__index = Window

function Window:_lockDrag(state)
    self._dragLocked = state
end

function Window:_createPopup(title)
    local popup = setmetatable({
        Name = title, Elements = {}, Window = self, _order = 0,
    }, Container)
    popup.Frame = New("Frame", {
        Size = UDim2.fromOffset(150, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Section,
        Visible = false, ZIndex = 50, Parent = self.PopupLayer,
    })
    Corner(popup.Frame, 5)
    Stroke(popup.Frame, Theme.Stroke)
    List(popup.Frame, 0)
    local head = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Theme.SectionHead, LayoutOrder = 0, Parent = popup.Frame })
    Corner(head, 5)
    New("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Theme.SectionHead, Parent = head })
    Label({ Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(title), Font = Theme.FontBold, TextSize = 10, Parent = head })
    popup.Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = popup.Frame })
    List(popup.Holder, 0)
    Padding(popup.Holder, 0, 3, 0, 4)
    -- raise z-index of everything created inside popup
    popup.Frame.DescendantAdded:Connect(function(d)
        if d:IsA("GuiObject") then d.ZIndex = 50 + (d.ZIndex > 1 and d.ZIndex - 1 or 0) end
    end)
    return popup
end

function Window:_closePopup()
    if self._activePopup then
        self._activePopup.Frame.Visible = false
        self._activePopup = nil
    end
end

function Window:_openPopup(popup, anchorButton)
    if self._activePopup == popup then
        self:_closePopup()
        return
    end
    self:_closePopup()
    local scale = self.UIScale.Scale
    local rel = (anchorButton.AbsolutePosition - self.Main.AbsolutePosition) / scale
    local x = Clamp(rel.X - 150 + anchorButton.AbsoluteSize.X / scale, 4, self.Size.X - 154)
    local y = rel.Y + anchorButton.AbsoluteSize.Y / scale + 2
    popup.Frame.Position = UDim2.fromOffset(x, y)
    popup.Frame.Visible = true
    self._activePopup = popup
end

function Window:SetSearch(text)
    text = string.lower(text or "")
    self.SearchBox.Text = text
    self:_applySearch()
end

function Window:_applySearch()
    local q = string.lower(self.SearchBox.Text or "")
    local tab = self.CurrentTab
    if not tab then return end
    for _, sec in ipairs(tab.Sections) do
        local any = false
        for _, el in ipairs(sec.Elements) do
            local match = q == "" or (el.SearchName ~= "" and el.SearchName:find(q, 1, true) ~= nil)
            if el.Type == "Divider" then match = q == "" end
            el.Row.Visible = match
            any = any or match
        end
        sec.Frame.Visible = q == "" or any or string.lower(sec.Name):find(q, 1, true) ~= nil
    end
end

function Window:SelectTab(tab)
    if self.CurrentTab == tab then return end
    self:_closePopup()
    local prev = self.CurrentTab
    if prev then
        prev.Page.Visible = false
        Tween(prev.Bg, TWEEN_FAST, { BackgroundTransparency = 1 })
        Tween(prev.Bar, TWEEN_FAST, { BackgroundTransparency = 1 })
        Tween(prev.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Dim })
        Tween(prev.IconRing, TWEEN_FAST, { Color = Theme.Dimmer })
    end
    self.CurrentTab = tab
    tab.Page.Visible = true
    Tween(tab.Bg, TWEEN_FAST, { BackgroundTransparency = 0.35 })
    Tween(tab.Bar, TWEEN_FAST, { BackgroundTransparency = 0 })
    Tween(tab.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Text })
    Tween(tab.IconRing, TWEEN_FAST, { Color = Theme.Accent })
    self:_applySearch()
end

function Window:SetVisible(state)
    self.Visible = state
    if state then
        self.Root.Visible = true
        Tween(self.UIScale, TWEEN_MED, { Scale = self._baseScale })
        Tween(self.Main, TWEEN_MED, { GroupTransparency = 0 })
        if self.BannerGui then Tween(self.BannerGui, TWEEN_MED, { ImageTransparency = 0 }) end
    else
        self:_closePopup()
        Tween(self.UIScale, TWEEN_FAST, { Scale = self._baseScale * 0.94 })
        Tween(self.Main, TWEEN_FAST, { GroupTransparency = 1 })
        if self.BannerGui then Tween(self.BannerGui, TWEEN_FAST, { ImageTransparency = 1 }) end
        task.delay(0.16, function()
            if not self.Visible and self.Root then self.Root.Visible = false end
        end)
    end
end

function Window:Toggle() self:SetVisible(not self.Visible) end

local function BuildTab(window, cfg, parentTab)
    local tab = {
        Name = cfg.Name or "tab", Subtitle = cfg.Subtitle or "", Window = window, Sections = {},
        Parent = parentTab, Children = {}, Collapsed = false,
    }

    local container = parentTab and parentTab.ChildHolder or window.TabList
    tab.Group = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = (#container:GetChildren()), Parent = container,
    })
    List(tab.Group, 1)

    local indent = parentTab and 14 or 0
    local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", LayoutOrder = 0, Parent = tab.Group })
    tab.Button = btn
    tab.Bg = New("Frame", { Size = UDim2.new(1, -10, 1, -2), Position = UDim2.fromOffset(5, 1), BackgroundColor3 = Theme.Row, BackgroundTransparency = 1, Parent = btn })
    Corner(tab.Bg, 5)
    tab.Bar = New("Frame", { Size = UDim2.fromOffset(2, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = btn })
    Corner(tab.Bar, 1)

    -- icon: custom image or procedural ring
    local iconHolder = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 14 + indent, 0.5, -7), BackgroundTransparency = 1, Parent = btn })
    if cfg.Icon and cfg.Icon ~= "" then
        New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ResolveImage(cfg.Icon), ImageColor3 = Theme.Dim, Parent = iconHolder })
        tab.IconRing = New("UIStroke", { Thickness = 0, Parent = iconHolder })
    else
        local ring = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, Parent = iconHolder })
        Corner(ring, parentTab and 5 or 3)
        tab.IconRing = Stroke(ring, Theme.Dimmer, 1.2)
    end

    tab.NameLabel = Label({
        Size = UDim2.new(1, -60 - indent, 0, 14), Position = UDim2.new(0, 36 + indent, 0, 5),
        Text = tl(tab.Name), TextColor3 = Theme.Dim, TextSize = 11, Font = Theme.Font, Parent = btn,
    })
    Label({
        Size = UDim2.new(1, -60 - indent, 0, 11), Position = UDim2.new(0, 36 + indent, 0, 18),
        Text = tl(tab.Subtitle), TextColor3 = Theme.Dimmer, TextSize = 8, Font = Theme.FontLight, Parent = btn,
    })

    tab.ChildHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Visible = true, Parent = tab.Group })
    List(tab.ChildHolder, 1)

    tab.Arrow = nil
    function tab:_enableChevron()
        if self.Arrow then return end
        self.Arrow = Label({
            Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -22, 0.5, -7), Text = ">", Rotation = -90,
            TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dimmer, Font = Theme.FontBold, TextSize = 10, Parent = self.Button,
        })
        local chev = New("TextButton", { Size = UDim2.fromOffset(26, 36), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1, Text = "", Parent = self.Button })
        Connect(chev.MouseButton1Click, function()
            self.Collapsed = not self.Collapsed
            self.ChildHolder.Visible = not self.Collapsed
            Tween(self.Arrow, TWEEN_FAST, { Rotation = self.Collapsed and 90 or -90 })
        end)
    end

    -- page
    tab.Page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Dimmer,
        ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = window.PageHolder,
    })
    Padding(tab.Page, 0, 0, 4, 6)
    tab.LeftColumn = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tab.Page })
    List(tab.LeftColumn, 6)
    tab.RightColumn = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), Position = UDim2.new(0.5, 3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tab.Page })
    List(tab.RightColumn, 6)

    function tab:AddSection(c)
        if type(c) == "string" then c = { Name = c } end
        return NewSection(self, c)
    end
    function tab:AddSubTab(c)
        local sub = BuildTab(window, c, self)
        table.insert(self.Children, sub)
        self:_enableChevron()
        return sub
    end

    Connect(btn.MouseEnter, function()
        if window.CurrentTab ~= tab then Tween(tab.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Text }) end
    end)
    Connect(btn.MouseLeave, function()
        if window.CurrentTab ~= tab then Tween(tab.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Dim }) end
    end)
    Connect(btn.MouseButton1Click, function() window:SelectTab(tab) end)

    table.insert(window.Tabs, tab)
    if not window.CurrentTab then window:SelectTab(tab) end
    return tab
end

function Window:AddTab(cfg)
    if type(cfg) == "string" then cfg = { Name = cfg } end
    return BuildTab(self, cfg, nil)
end

------------------------------------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------------------------------------
function Library:Notify(cfg)
    cfg = type(cfg) == "string" and { Text = cfg } or (cfg or {})
    local gui = self.Gui
    if not gui then return end
    if not self.NotifyHolder then
        self.NotifyHolder = New("Frame", {
            Size = UDim2.fromOffset(230, 400), Position = UDim2.new(1, -240, 0, 14), BackgroundTransparency = 1, Parent = gui,
        })
        List(self.NotifyHolder, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right)
    end
    local duration = cfg.Duration or 4
    local slot = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = self.NotifyHolder })
    local card = New("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(240, 0), BackgroundColor3 = Theme.Window, Parent = slot })
    Corner(card, 6)
    Stroke(card, Theme.Stroke)
    local bar = New("Frame", { Size = UDim2.new(0, 2, 1, -14), Position = UDim2.fromOffset(6, 7), BackgroundColor3 = cfg.Color or Theme.Accent, Parent = card })
    Corner(bar, 1)
    Label({ Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(16, 6), Text = tl(cfg.Title or "notification"), Font = Theme.FontBold, Parent = card })
    Label({ Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(16, 23), Text = tl(cfg.Text or ""), TextColor3 = Theme.Dim, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
    local life = New("Frame", { Size = UDim2.new(1, -12, 0, 1), Position = UDim2.new(0, 6, 1, -3), BackgroundColor3 = Theme.Dimmer, Parent = card })
    Tween(card, TWEEN_MED, { Position = UDim2.fromOffset(0, 0) })
    Tween(life, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 1) })
    task.delay(duration, function()
        if card.Parent then
            Tween(card, TWEEN_MED, { Position = UDim2.fromOffset(240, 0) })
            task.wait(0.25)
            slot:Destroy()
        end
    end)
end

------------------------------------------------------------------------------------------------
-- Config system
------------------------------------------------------------------------------------------------
Library.ConfigFolder = "DogUI"

local function Serialize()
    local data = {}
    for flag, el in pairs(Library.Options) do
        local v = el.Value
        if el.Type == "ColorPicker" then
            data[flag] = { _t = "c", v.R, v.G, v.B }
        elseif el.Type == "Keybind" then
            data[flag] = { _t = "k", v and v.Name or false, v and tostring(v.EnumType) or false }
        elseif el.Type ~= "Button" and el.Type ~= "Label" then
            data[flag] = v
        end
    end
    return HttpService:JSONEncode(data)
end

function Library:SaveConfig(name)
    if not (writefile and makefolder) then return false, "no filesystem" end
    pcall(makefolder, self.ConfigFolder)
    local ok, err = pcall(writefile, self.ConfigFolder .. "/" .. name .. ".json", Serialize())
    return ok, err
end

function Library:LoadConfig(name)
    if not (readfile and isfile) then return false, "no filesystem" end
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return false, "not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return false, "bad json" end
    for flag, v in pairs(data) do
        local el = Library.Options[flag]
        if el then
            pcall(function()
                if type(v) == "table" and v._t == "c" then
                    el:Set(Color3.new(v[1], v[2], v[3]))
                elseif type(v) == "table" and v._t == "k" then
                    if v[1] then
                        local enum = v[2] == "Enum.UserInputType" and Enum.UserInputType or Enum.KeyCode
                        el:Set(enum[v[1]])
                    else
                        el:Set(nil)
                    end
                else
                    el:Set(v)
                end
            end)
        end
    end
    return true
end

function Library:ListConfigs()
    local out = {}
    if listfiles and isfolder and isfolder(self.ConfigFolder) then
        for _, f in ipairs(listfiles(self.ConfigFolder)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    return out
end

------------------------------------------------------------------------------------------------
-- Animated network background
------------------------------------------------------------------------------------------------
local function BuildNetwork(parent, count, maxDist)
    local layer = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0, Parent = parent })
    local points, lines = {}, {}
    local maxLines = count * 3
    for i = 1, count do
        points[i] = { x = math.random(), y = math.random(), vx = (math.random() - 0.5) * 0.05, vy = (math.random() - 0.5) * 0.05 }
    end
    for i = 1, maxLines do
        lines[i] = New("Frame", {
            Size = UDim2.fromOffset(0, 1), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Line,
            BackgroundTransparency = 1, Visible = false, ZIndex = 0, Parent = layer,
        })
    end
    local acc = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < 1 / 30 then return end
        local step = acc
        acc = 0
        if not layer.Parent or not layer.Visible or layer.AbsoluteSize.X == 0 then return end
        local w, h = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
        local scale = 1
        for _, p in ipairs(points) do
            p.x += p.vx * step
            p.y += p.vy * step
            if p.x < 0 or p.x > 1 then p.vx = -p.vx; p.x = Clamp(p.x, 0, 1) end
            if p.y < 0 or p.y > 1 then p.vy = -p.vy; p.y = Clamp(p.y, 0, 1) end
        end
        local li = 0
        for i = 1, #points do
            for j = i + 1, #points do
                local a, b = points[i], points[j]
                local dx, dy = (a.x - b.x) * w, (a.y - b.y) * h
                local d = math.sqrt(dx * dx + dy * dy)
                if d < maxDist and li < maxLines then
                    li += 1
                    local ln = lines[li]
                    ln.Visible = true
                    ln.Size = UDim2.fromOffset(d, 1)
                    ln.Position = UDim2.fromOffset((a.x + b.x) / 2 * w, (a.y + b.y) / 2 * h)
                    ln.Rotation = math.deg(math.atan2(-dy, -dx))
                    ln.BackgroundTransparency = 0.78 + 0.2 * (d / maxDist)
                end
            end
        end
        for k = li + 1, maxLines do
            if lines[k].Visible then lines[k].Visible = false end
        end
    end)
    table.insert(Library.Connections, conn)
    return layer
end

------------------------------------------------------------------------------------------------
-- CreateWindow
------------------------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    if not self.Gui then
        local gui = New("ScreenGui", {
            Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        })
        Protect(gui)
        gui.Parent = GetGuiParent()
        self.Gui = gui
    end

    local win = setmetatable({
        Tabs = {}, Visible = true, Library = self, _dragLocked = false,
    }, Window)

    local size = cfg.Size or Vector2.new(400, 404)
    local sidebarW = cfg.SidebarWidth or 116

    -- main (CanvasGroup lets the whole window fade)
    win.Size = size
    win.Root = New("Frame", {
        Name = "Root", Size = UDim2.fromOffset(size.X, size.Y), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = cfg.Position or UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = self.Gui,
    })
    win.UIScale = New("UIScale", { Scale = 1, Parent = win.Root })
    win.Main = New("CanvasGroup", {
        Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Window, GroupTransparency = 0, Parent = win.Root,
    })
    Corner(win.Main, 8)
    Stroke(win.Main, Theme.Stroke, 1)

    local function ComputeScale()
        local cam = Workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        local s = math.min(vp.X / (size.X + 80), vp.Y / (size.Y + 40), 1)
        if IsTouch then s = math.min(s, 0.95) end
        return Clamp(s, 0.5, 1.15)
    end
    win._baseScale = ComputeScale()
    win.UIScale.Scale = win._baseScale
    if Workspace.CurrentCamera then
        Connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
            win._baseScale = ComputeScale()
            if win.Visible then win.UIScale.Scale = win._baseScale end
        end)
    end

    -- sidebar
    win.Sidebar = New("Frame", { Size = UDim2.new(0, sidebarW, 1, 0), BackgroundColor3 = Theme.Sidebar, Parent = win.Main })
    New("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.StrokeSoft, Parent = win.Sidebar })

    local logoHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1, Parent = win.Sidebar })
    win.Logo = New("ImageLabel", {
        Size = UDim2.fromOffset(cfg.LogoSize or 56, cfg.LogoSize or 56), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52), BackgroundTransparency = 1, Image = ResolveImage(cfg.Logo),
        ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1), ScaleType = Enum.ScaleType.Fit, Parent = logoHolder,
    })
    if not cfg.Logo or win.Logo.Image == "" then
        Label({ Size = UDim2.fromScale(1, 1), Text = "D", Font = Theme.FontBold, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center, Parent = logoHolder })
    end

    win.TabScroll = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -78 - 46), Position = UDim2.fromOffset(0, 78), BackgroundTransparency = 1,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = win.Sidebar,
    })
    win.TabList = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = win.TabScroll })
    List(win.TabList, 1)

    -- profile card
    local profile = New("Frame", { Size = UDim2.new(1, -12, 0, 36), Position = UDim2.new(0, 6, 1, -42), BackgroundColor3 = Theme.Section, Parent = win.Sidebar })
    Corner(profile, 6)
    Stroke(profile, Theme.StrokeSoft)
    local avatar = New("ImageLabel", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Box, Parent = profile })
    Corner(avatar, 12)
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and avatar.Parent then avatar.Image = img end
    end)
    Label({ Size = UDim2.new(1, -38, 0, 14), Position = UDim2.fromOffset(34, 5), Text = cfg.DisplayName or LocalPlayer.DisplayName, TextSize = 9, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })
    Label({ Size = UDim2.new(1, -38, 0, 12), Position = UDim2.fromOffset(34, 18), Text = "@" .. (cfg.UserName or LocalPlayer.Name), TextSize = 8, TextColor3 = Theme.Dimmer, Font = Theme.FontLight, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })

    -- content area
    win.Content = New("Frame", { Size = UDim2.new(1, -sidebarW, 1, 0), Position = UDim2.fromOffset(sidebarW, 0), BackgroundTransparency = 1, Parent = win.Main })
    win.Network = BuildNetwork(win.Content, cfg.NetworkPoints or 9, cfg.NetworkDistance or 150)

    -- search bar
    local search = New("Frame", { Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Section, Parent = win.Content })
    Corner(search, 6)
    local searchStroke = Stroke(search, Theme.StrokeSoft)
    win.SearchBox = New("TextBox", {
        Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "", TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 11, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = search,
    })
    -- procedural magnifier icon
    local mag = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -24, 0.5, -7), BackgroundTransparency = 1, Parent = search })
    local lens = New("Frame", { Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Parent = mag })
    Corner(lens, 5)
    local lensStroke = Stroke(lens, Theme.Dim, 1.3)
    New("Frame", { Size = UDim2.fromOffset(1.5, 5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(11, 11), Rotation = -45, BackgroundColor3 = Theme.Dim, Parent = mag })
    Connect(win.SearchBox.Focused, function()
        Tween(searchStroke, TWEEN_FAST, { Color = Theme.Dimmer })
        Tween(lensStroke, TWEEN_FAST, { Color = Theme.Accent })
    end)
    Connect(win.SearchBox.FocusLost, function()
        Tween(searchStroke, TWEEN_FAST, { Color = Theme.StrokeSoft })
        Tween(lensStroke, TWEEN_FAST, { Color = Theme.Dim })
    end)
    Connect(win.SearchBox:GetPropertyChangedSignal("Text"), function() win:_applySearch() end)

    win.PageHolder = New("Frame", { Size = UDim2.new(1, -12, 1, -46), Position = UDim2.fromOffset(6, 40), BackgroundTransparency = 1, Parent = win.Content })

    -- popup layer sits above everything inside the window
    win.PopupLayer = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = win.Main })
    local outside = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 49, Visible = true, Parent = win.PopupLayer })
    outside.Visible = false
    local oldOpen = win._openPopup
    function win:_openPopup(popup, anchor)
        oldOpen(self, popup, anchor)
        outside.Visible = self._activePopup ~= nil
    end
    local oldClose = win._closePopup
    function win:_closePopup()
        oldClose(self)
        outside.Visible = false
    end
    Connect(outside.MouseButton1Click, function() win:_closePopup() end)

    -- drag handles: search area strip + logo + sidebar background
    MakeDraggable(logoHolder, win.Root, function() return win.UIScale.Scale end)
    MakeDraggable(win.Sidebar, win.Root, function() return win.UIScale.Scale end)
    local dragStrip = New("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1, Parent = win.Content })
    MakeDraggable(dragStrip, win.Root, function() return win.UIScale.Scale end)

    -- banner (image 3) peeking above the top-left of the window
    if cfg.Banner then
        local bw, bh = cfg.BannerSize and cfg.BannerSize.X or 104, cfg.BannerSize and cfg.BannerSize.Y or 104
        local bannerImg = ResolveImage(cfg.Banner)
        win.BannerGui = New("ImageLabel", {
            Size = UDim2.fromOffset(bw, bh), Position = UDim2.new(0, cfg.BannerOffset and cfg.BannerOffset.X or 6, 0, cfg.BannerOffset and cfg.BannerOffset.Y or -(bh - 26)),
            BackgroundTransparency = 1, Image = bannerImg, ScaleType = Enum.ScaleType.Fit, ZIndex = 20, Parent = win.Root,
        })
    end

    -- floating toggle button (mobile + pc)
    if cfg.ToggleButton ~= false then
        local fb = New("ImageButton", {
            Name = "FloatingToggle", Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = cfg.TogglePosition or UDim2.new(1, -28, 0.5, 0), BackgroundColor3 = Theme.Window, BackgroundTransparency = 0.1,
            Image = "", Parent = self.Gui,
        })
        Corner(fb, 18)
        Stroke(fb, Theme.Stroke)
        local fImg = New("ImageLabel", {
            Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1, Image = ResolveImage(cfg.ToggleIcon or cfg.Logo), ImageColor3 = Color3.new(1, 1, 1), Parent = fb,
        })
        MakeDraggable(fb, fb, nil, function() win:Toggle() end)
        win.FloatingButton = fb
    end

    -- keybind to toggle on PC
    local key = cfg.Keybind or Enum.KeyCode.RightShift
    Connect(UIS.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == key then win:Toggle() end
    end)

    table.insert(self.Windows, win)
    win.Root.Visible = true
    return win
end

function Library:Unload()
    self.Unloaded = true
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(self.Connections)
    if self.Gui then self.Gui:Destroy() end
    self.Gui = nil
end

------------------------------------------------------------------------------------------------
-- CONFIG: вставь свои asset id (число или "rbxassetid://123")
------------------------------------------------------------------------------------------------
local CONFIG = {
    LogoId   = 0, -- фото 1 (собачка-контур) вместо буквы S
    BannerId = 0, -- фото 3 (собачка в шляпе) вместо аниме-картинки
}

local Win = Library:CreateWindow({
    Logo = CONFIG.LogoId ~= 0 and CONFIG.LogoId or nil,
    Banner = CONFIG.BannerId ~= 0 and CONFIG.BannerId or nil,
    ToggleIcon = CONFIG.LogoId ~= 0 and CONFIG.LogoId or nil,
    Keybind = Enum.KeyCode.RightShift,
    Size = Vector2.new(400, 404),
})

local noop = function() end

-- game
local Game = Win:AddTab({ Name = "game", Subtitle = "game func" })

local Sheriff = Game:AddSection({ Name = "sheriff", Side = "Left" })
Sheriff:AddToggle({ Name = "silent", Flag = "sheriff_silent", Callback = noop })
Sheriff:AddToggle({ Name = "prediction", Flag = "sheriff_prediction", Default = true, Callback = noop })
Sheriff:AddToggle({
    Name = "force shoot", Flag = "sheriff_force", Callback = noop,
    Options = function(menu)
        menu:AddSlider({ Name = "range", Flag = "sheriff_force_range", Min = 5, Max = 200, Default = 50, Callback = noop })
        menu:AddKeybind({ Name = "bind", Flag = "sheriff_force_bind", Default = Enum.KeyCode.E, Callback = noop })
    end,
})
Sheriff:AddToggle({
    Name = "auto shoot", Flag = "sheriff_auto", Callback = noop,
    Options = function(menu)
        menu:AddSlider({ Name = "delay", Flag = "sheriff_auto_delay", Min = 0, Max = 1, Increment = 0.05, Default = 0.1, Suffix = "s", Callback = noop })
    end,
})

local Murder = Game:AddSection({ Name = "murder", Side = "Left" })
Murder:AddToggle({ Name = "kill aura", Flag = "murder_aura", Callback = noop, Options = function(menu)
    menu:AddSlider({ Name = "radius", Flag = "murder_aura_radius", Min = 1, Max = 30, Default = 10, Callback = noop })
    menu:AddDropdown({ Name = "mode", Flag = "murder_aura_mode", Values = { "nearest", "random" }, Default = "nearest", Callback = noop })
end })
Murder:AddToggle({ Name = "kill all", Flag = "murder_all", Callback = noop })
Murder:AddToggle({ Name = "throw silent", Flag = "murder_throw", Callback = noop, Options = function(menu)
    menu:AddToggle({ Name = "visible check", Flag = "murder_throw_vis", Callback = noop })
end })
Murder:AddToggle({ Name = "prediction", Flag = "murder_prediction", Default = true, Callback = noop })

local Autos = Game:AddSection({ Name = "autos", Side = "Right" })
Autos:AddToggle({ Name = "grab gun", Flag = "autos_grab", Callback = noop })
Autos:AddToggle({ Name = "farm", Flag = "autos_farm", Callback = noop, Options = function(menu)
    menu:AddDropdown({ Name = "target", Flag = "autos_farm_target", Values = { "coins", "items", "all" }, Default = "coins", Callback = noop })
    menu:AddSlider({ Name = "speed", Flag = "autos_farm_speed", Min = 1, Max = 100, Default = 40, Callback = noop })
end })

-- visuals (+ sub tab world)
local Visuals = Win:AddTab({ Name = "visuals", Subtitle = "players visuals" })
local V1 = Visuals:AddSection({ Name = "players", Side = "Left" })
V1:AddToggle({ Name = "box", Flag = "vis_box", Callback = noop, Options = function(menu)
    menu:AddColorPicker({ Name = "color", Flag = "vis_box_color", Default = Color3.fromRGB(255, 255, 255), Callback = noop })
end })
V1:AddToggle({ Name = "name", Flag = "vis_name", Callback = noop })
V1:AddToggle({ Name = "health", Flag = "vis_health", Callback = noop })
V1:AddToggle({ Name = "tracers", Flag = "vis_tracers", Callback = noop })

local World = Visuals:AddSubTab({ Name = "world", Subtitle = "world visuals" })
local W1 = World:AddSection({ Name = "environment", Side = "Left" })
W1:AddToggle({ Name = "fullbright", Flag = "world_fb", Callback = noop })
W1:AddSlider({ Name = "time of day", Flag = "world_time", Min = 0, Max = 24, Default = 14, Callback = noop })
W1:AddColorPicker({ Name = "ambient", Flag = "world_ambient", Default = Color3.fromRGB(120, 120, 140), Callback = noop })

-- player (+ models / animations / emotes)
local Player = Win:AddTab({ Name = "player", Subtitle = "local perk" })
local P1 = Player:AddSection({ Name = "movement", Side = "Left" })
P1:AddSlider({ Name = "walk speed", Flag = "plr_ws", Min = 16, Max = 120, Default = 16, Callback = noop })
P1:AddSlider({ Name = "jump power", Flag = "plr_jp", Min = 50, Max = 200, Default = 50, Callback = noop })
P1:AddToggle({ Name = "infinite jump", Flag = "plr_ij", Callback = noop })

local Models = Player:AddSubTab({ Name = "models", Subtitle = "model library" })
Models:AddSection({ Name = "library", Side = "Left" }):AddLabel("empty")

local Animations = Win:AddTab({ Name = "animations", Subtitle = "custom animations" })
Animations:AddSection({ Name = "custom", Side = "Left" }):AddLabel("empty")
local Emotes = Animations:AddSubTab({ Name = "emotes", Subtitle = "emote library" })
Emotes:AddSection({ Name = "library", Side = "Left" }):AddLabel("empty")

-- target
local Target = Win:AddTab({ Name = "target", Subtitle = "for riggers" })
local T1 = Target:AddSection({ Name = "selection", Side = "Left" })
T1:AddDropdown({ Name = "player", Flag = "tgt_player", Values = { "none" }, Default = "none", Callback = noop })
T1:AddButton({ Name = "refresh", Callback = function() Library:Notify({ Title = "target", Text = "list refreshed" }) end })

-- settings (config)
local Settings = Win:AddTab({ Name = "settings", Subtitle = "ui config" })
local S1 = Settings:AddSection({ Name = "config", Side = "Left" })
local cfgName = S1:AddTextbox({ Name = "name", Flag = "cfg_name", Default = "default", Callback = noop })
S1:AddButton({ Name = "save", Callback = function()
    Library:SaveConfig(Library.Flags.cfg_name or "default")
    Library:Notify({ Title = "config", Text = "saved" })
end })
S1:AddButton({ Name = "load", Callback = function()
    local ok, err = Library:LoadConfig(Library.Flags.cfg_name or "default")
    Library:Notify({ Title = "config", Text = ok and "loaded" or tostring(err) })
end })
local S2 = Settings:AddSection({ Name = "ui", Side = "Right" })
S2:AddKeybind({ Name = "menu key", Default = Enum.KeyCode.RightShift, Callback = noop })
S2:AddButton({ Name = "unload", Callback = function() Library:Unload() end })

Library:Notify({ Title = "DogUI", Text = "loaded - RightShift or tap the dog" })


-- ===== ORIGINAL PIDDLE ADDON (preserved in full) =====

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Velvet = {
    Flags = {},
    Windows = {},
    Notifications = {},
    Theme = nil,
    _connections = {},
    _listeners = {},
    _elements = {},
    _errorLog = {},
    _onError = nil,
    _activeDrag = nil, -- mutex so picker drag doesn't bleed into slider
    _version = "3.2.0"
}

-- defaults
local DEFAULT_THEME = {
    Name = "Midnight",
    Base = Color3.fromRGB(10, 10, 14),
    Surface = Color3.fromRGB(18, 18, 26),
    Panel = Color3.fromRGB(24, 24, 36),
    Border = Color3.fromRGB(45, 45, 65),
    Accent = Color3.fromRGB(124, 92, 252),
    AccentDark = Color3.fromRGB(90, 65, 200),
    Text = Color3.fromRGB(232, 232, 240),
    TextDim = Color3.fromRGB(136, 136, 170),
    TextMuted = Color3.fromRGB(80, 80, 110),
    Success = Color3.fromRGB(80, 220, 120),
    Warning = Color3.fromRGB(255, 180, 50),
    Error = Color3.fromRGB(255, 80, 80),
    Info = Color3.fromRGB(80, 160, 255),
}

Velvet.Theme = DEFAULT_THEME

-- preset themes (devs love these)
Velvet.Themes = {
    Midnight = DEFAULT_THEME,

    Catppuccin = {
        Name = "Catppuccin",
        Base = Color3.fromRGB(24, 24, 37),
        Surface = Color3.fromRGB(30, 30, 46),
        Panel = Color3.fromRGB(49, 50, 68),
        Border = Color3.fromRGB(69, 71, 90),
        Accent = Color3.fromRGB(203, 166, 247),
        AccentDark = Color3.fromRGB(166, 132, 213),
        Text = Color3.fromRGB(205, 214, 244),
        TextDim = Color3.fromRGB(166, 173, 200),
        TextMuted = Color3.fromRGB(108, 112, 134),
        Success = Color3.fromRGB(166, 227, 161),
        Warning = Color3.fromRGB(249, 226, 175),
        Error = Color3.fromRGB(243, 139, 168),
        Info = Color3.fromRGB(137, 180, 250),
    },

    TokyoNight = {
        Name = "Tokyo Night",
        Base = Color3.fromRGB(26, 27, 38),
        Surface = Color3.fromRGB(36, 40, 59),
        Panel = Color3.fromRGB(41, 46, 66),
        Border = Color3.fromRGB(65, 72, 104),
        Accent = Color3.fromRGB(125, 207, 255),
        AccentDark = Color3.fromRGB(86, 154, 200),
        Text = Color3.fromRGB(192, 202, 245),
        TextDim = Color3.fromRGB(154, 165, 206),
        TextMuted = Color3.fromRGB(86, 95, 137),
        Success = Color3.fromRGB(158, 206, 106),
        Warning = Color3.fromRGB(224, 175, 104),
        Error = Color3.fromRGB(247, 118, 142),
        Info = Color3.fromRGB(122, 162, 247),
    },

    Dracula = {
        Name = "Dracula",
        Base = Color3.fromRGB(40, 42, 54),
        Surface = Color3.fromRGB(52, 54, 70),
        Panel = Color3.fromRGB(68, 71, 90),
        Border = Color3.fromRGB(98, 114, 164),
        Accent = Color3.fromRGB(189, 147, 249),
        AccentDark = Color3.fromRGB(150, 110, 210),
        Text = Color3.fromRGB(248, 248, 242),
        TextDim = Color3.fromRGB(180, 180, 190),
        TextMuted = Color3.fromRGB(98, 114, 164),
        Success = Color3.fromRGB(80, 250, 123),
        Warning = Color3.fromRGB(241, 250, 140),
        Error = Color3.fromRGB(255, 85, 85),
        Info = Color3.fromRGB(139, 233, 253),
    },

    Nord = {
        Name = "Nord",
        Base = Color3.fromRGB(46, 52, 64),
        Surface = Color3.fromRGB(59, 66, 82),
        Panel = Color3.fromRGB(67, 76, 94),
        Border = Color3.fromRGB(76, 86, 106),
        Accent = Color3.fromRGB(136, 192, 208),
        AccentDark = Color3.fromRGB(94, 129, 172),
        Text = Color3.fromRGB(236, 239, 244),
        TextDim = Color3.fromRGB(216, 222, 233),
        TextMuted = Color3.fromRGB(129, 161, 193),
        Success = Color3.fromRGB(163, 190, 140),
        Warning = Color3.fromRGB(235, 203, 139),
        Error = Color3.fromRGB(191, 97, 106),
        Info = Color3.fromRGB(129, 161, 193),
    },

    Rose = {
        Name = "Rose Pine",
        Base = Color3.fromRGB(25, 23, 36),
        Surface = Color3.fromRGB(38, 35, 58),
        Panel = Color3.fromRGB(49, 46, 77),
        Border = Color3.fromRGB(64, 61, 82),
        Accent = Color3.fromRGB(235, 188, 186),
        AccentDark = Color3.fromRGB(196, 167, 231),
        Text = Color3.fromRGB(224, 222, 244),
        TextDim = Color3.fromRGB(144, 140, 170),
        TextMuted = Color3.fromRGB(110, 106, 134),
        Success = Color3.fromRGB(156, 207, 216),
        Warning = Color3.fromRGB(246, 193, 119),
        Error = Color3.fromRGB(235, 111, 146),
        Info = Color3.fromRGB(196, 167, 231),
    },

    Cyberpunk = {
        Name = "Cyberpunk",
        Base = Color3.fromRGB(13, 13, 20),
        Surface = Color3.fromRGB(20, 20, 35),
        Panel = Color3.fromRGB(28, 28, 48),
        Border = Color3.fromRGB(255, 0, 128),
        Accent = Color3.fromRGB(0, 255, 200),
        AccentDark = Color3.fromRGB(0, 180, 150),
        Text = Color3.fromRGB(240, 240, 255),
        TextDim = Color3.fromRGB(180, 180, 220),
        TextMuted = Color3.fromRGB(120, 100, 180),
        Success = Color3.fromRGB(0, 255, 150),
        Warning = Color3.fromRGB(255, 200, 0),
        Error = Color3.fromRGB(255, 50, 100),
        Info = Color3.fromRGB(100, 200, 255),
    },

    Monochrome = {
        Name = "Monochrome",
        Base = Color3.fromRGB(15, 15, 15),
        Surface = Color3.fromRGB(22, 22, 22),
        Panel = Color3.fromRGB(32, 32, 32),
        Border = Color3.fromRGB(60, 60, 60),
        Accent = Color3.fromRGB(230, 230, 230),
        AccentDark = Color3.fromRGB(180, 180, 180),
        Text = Color3.fromRGB(245, 245, 245),
        TextDim = Color3.fromRGB(170, 170, 170),
        TextMuted = Color3.fromRGB(110, 110, 110),
        Success = Color3.fromRGB(200, 200, 200),
        Warning = Color3.fromRGB(220, 220, 220),
        Error = Color3.fromRGB(255, 100, 100),
        Info = Color3.fromRGB(180, 180, 180),
    },
}

-- utils
local function tween(obj, props, dur, style)
    local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.22, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function create(cls, props)
    local inst = Instance.new(cls)
    for k, v in props do
        if k ~= "Parent" and k ~= "Children" then
            inst[k] = v
        end
    end
    if props.Children then
        for _, child in props.Children do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Velvet.Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent
    })
end

local function addPadding(parent, t, b, l, r)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 10),
        PaddingRight = UDim.new(0, r or 10),
        Parent = parent
    })
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getScreenSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function round(v, inc)
    inc = inc or 1
    return math.floor(v / inc + 0.5) * inc
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function color3ToHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) or 0
    local g = tonumber(hex:sub(3,4), 16) or 0
    local b = tonumber(hex:sub(5,6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- error handling
local function velvetError(source, err)
    local trace = debug.traceback(tostring(err), 3)
    local entry = {
        source = source,
        message = tostring(err),
        traceback = trace,
        time = os.clock(),
    }
    table.insert(Velvet._errorLog, entry)
    if #Velvet._errorLog > 50 then table.remove(Velvet._errorLog, 1) end

    warn(`[Velvet] {source}: {err}`)

    if Velvet._onError then
        pcall(Velvet._onError, entry)
    end

    -- show notification if Notify is available
    pcall(function()
        Velvet:Notify({
            Title = "Velvet Error",
            Content = source .. ": " .. tostring(err):sub(1, 120),
            Duration = 5,
            Type = "error",
        })
    end)
end

local function safecall(source, fn, ...)
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(fn, table.unpack(args, 1, args.n))
        if not ok then velvetError(source, err) end
    end)
end

function Velvet:OnError(fn)
    self._onError = fn
end

function Velvet:GetErrors()
    return self._errorLog
end

-- flag listener system
function Velvet:OnFlagChanged(id, fn)
    if not self._listeners[id] then self._listeners[id] = {} end
    table.insert(self._listeners[id], fn)
end

local function fireListeners(id, val)
    local cbs = Velvet._listeners[id]
    if cbs then
        for _, fn in cbs do safecall(`Listener:{id}`, fn, val) end
    end
end

local function tagSearch(frame, text)
    if not frame or not text then return end
    frame:SetAttribute("VelvetSearch", string.lower(text))
end

local function setupVisibility(elem, frame, opts)
    if not opts.VisibleWhen then return end
    local depId = opts.VisibleWhen
    local function check(v)
        local vis = not not v -- truthy check
        frame.Visible = vis
    end
    -- initial state
    local cur = Velvet.Flags[depId]
    if cur ~= nil then check(cur) else frame.Visible = false end
    Velvet:OnFlagChanged(depId, check)
end

-- attach OnChanged to element objects
local function attachOnChanged(elem, id)
    function elem:OnChanged(fn)
        Velvet:OnFlagChanged(id, fn)
        return self
    end
end

-- wire tooltip if opts.Tooltip is set
local function setupTooltip(frame, opts)
    if not opts or not opts.Tooltip then return end
    if Velvet.AttachTooltip then
        pcall(function() Velvet:AttachTooltip(frame, opts.Tooltip) end)
    end
end

-- cleanup old gui
pcall(function()
    local old = gethui():FindFirstChild("VelvetUI")
    if old then old:Destroy() end
end)

-- root gui
local gui = create("ScreenGui", {
    Name = "VelvetUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 500
})
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- notifications live in a separate screengui so they always float above the window
local notifGui = create("ScreenGui", {
    Name = "VelvetNotifs",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 10000,
})
pcall(function() notifGui.Parent = gethui() end)
if not notifGui.Parent then
    notifGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- notification container (top right)
local notifHolder = create("Frame", {
    Name = "Notifications",
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(1, -310, 0, 10),
    BackgroundTransparency = 1,
    Parent = notifGui,
    Children = {
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })
    }
})

-- ~~
-- ICON RESOLVER
-- accepts: rbxassetid://..., plain number id, "rbxassetid://12345",
-- or a lucide icon name ("sword", "heart", "arrow-left") if icons are bound
-- ~~
function Velvet:SetIcons(iconPack)
    self._icons = iconPack
end

function Velvet:ResolveIcon(ref)
    if not ref then return nil end
    if type(ref) == "number" then return "rbxassetid://" .. ref end
    if type(ref) ~= "string" then return nil end
    -- already an asset url
    if ref:find("rbxassetid://") or ref:find("rbxthumb://") or ref:find("rbxgameasset://") or ref:find("http") then
        return ref
    end
    -- numeric string
    if tonumber(ref) then return "rbxassetid://" .. ref end
    -- lucide name via bound icon pack
    if self._icons then
        local id = self._icons:Get(ref) or self._icons:Fuzzy(ref)
        if id then return id end
    end
    return nil
end

function Velvet:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Velvet"
    local content = opts.Content or ""
    local dur = opts.Duration or 4
    local ntype = opts.Type or "info"
    if self._notifHook then pcall(self._notifHook, opts) end
    local theme = self.Theme

    local accentColor = ({
        info = theme.Info,
        success = theme.Success,
        warning = theme.Warning,
        error = theme.Error,
    })[ntype] or theme.Accent

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.1,
        ClipsDescendants = true,
        Parent = notifHolder
    })
    addCorner(card, 10)
    addStroke(card, accentColor, 1, 0.4)

    -- accent bar left
    create("Frame", {
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = card,
        Children = { create("UICorner", { CornerRadius = UDim.new(0, 2) }) }
    })

    local titleLbl = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 16, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local contentLbl = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 16, 0, 26),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = theme.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card
    })

    -- calc height
    local textH = contentLbl.TextBounds.Y
    if textH < 12 then textH = 14 end
    local totalH = 26 + textH + 12

    -- animate in
    tween(card, {Size = UDim2.new(1, 0, 0, totalH)}, 0.3)

    -- auto dismiss
    task.delay(dur, function()
        tween(card, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.25)
        task.wait(0.3)
        pcall(function() card:Destroy() end)
    end)
end

-- ~~---------
-- WINDOW
-- ~~---------
-- ~~---------
-- KEY SYSTEM
-- ~~---------
function Velvet:KeySystem(opts)
    opts = opts or {}
    local title = opts.Title or "Key System"
    local subtitle = opts.SubTitle or "Enter your key to continue"
    local keys = opts.Keys or {}
    local hashedKeys = opts.HashedKeys -- optional: pre-hashed sha256 keys (recommended)
    local saveName = opts.SaveKey or "VelvetKey.txt"
    local cb = opts.Callback or function() end
    local maxAttempts = opts.MaxAttempts or 5
    local theme = self.Theme
    local mobile = isMobile()

    -- hash helper (SHA-256 with HWID salt for binding)
    local function hwidSalt()
        local h
        pcall(function() h = (gethwid and gethwid()) or "" end)
        return tostring(h or "")
    end

    local function hashKey(k)
        if not crypt or not crypt.hash then return k end
        local ok, out = pcall(crypt.hash, k .. "::velvet::" .. hwidSalt(), "sha256")
        return ok and out or k
    end

    -- valid hash list
    local validHashes = {}
    if hashedKeys then
        for _, h in hashedKeys do validHashes[h] = true end
    else
        for _, k in keys do validHashes[hashKey(k)] = true end
    end

    local function checkKey(input)
        return validHashes[hashKey(input)] == true
    end

    -- check saved key first (file stores HWID-bound hash, not raw key)
    local savedHash = nil
    pcall(function()
        if isfile and isfile(saveName) then savedHash = readfile(saveName) end
    end)
    if savedHash and validHashes[savedHash] then
        safecall("KeySystem", cb, true)
        return true
    end

    -- attempt counter (in-memory, persists for session)
    local attempts = 0

    local passed = false
    local keyGui = create("Frame", {
        Name = "VelvetKeySystem",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        ZIndex = 200,
        Parent = gui
    })

    local card = create("Frame", {
        Size = UDim2.new(0, mobile and 320 or 340, 0, 0),
        Position = UDim2.new(0.5, mobile and -160 or -170, 0.5, 0),
        BackgroundColor3 = theme.Base,
        ClipsDescendants = true,
        ZIndex = 201,
        Parent = keyGui
    })
    addCorner(card, 14)
    addStroke(card, theme.Border, 1, 0.3)

    -- accent line
    create("Frame", {
        Size = UDim2.new(0, 40, 0, 2),
        Position = UDim2.new(0.5, -20, 0, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 210,
        Parent = card
    })

    -- title
    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 210,
        Parent = card
    })

    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 14),
        Position = UDim2.new(0, 20, 0, 42),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 210,
        Parent = card
    })

    -- input
    local inputBg = create("Frame", {
        Size = UDim2.new(1, -40, 0, 38),
        Position = UDim2.new(0, 20, 0, 68),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 210,
        Parent = card
    })
    addCorner(inputBg, 8)
    local keyStroke = addStroke(inputBg, theme.Border, 1, 0.5)

    local keyInput = create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Enter key...",
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.TextMuted,
        TextSize = 13,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 211,
        Parent = inputBg
    })

    keyInput.Focused:Connect(function()
        tween(keyStroke, {Color = theme.Accent, Transparency = 0}, 0.15)
    end)
    keyInput.FocusLost:Connect(function()
        tween(keyStroke, {Color = theme.Border, Transparency = 0.5}, 0.15)
    end)

    -- status label
    local statusLabel = create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 14),
        Position = UDim2.new(0, 20, 0, 112),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme.Error,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 210,
        Parent = card
    })

    -- submit button
    local submitBtn = create("TextButton", {
        Size = UDim2.new(1, -40, 0, 36),
        Position = UDim2.new(0, 20, 0, 130),
        BackgroundColor3 = theme.Accent,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 210,
        Parent = card
    })
    addCorner(submitBtn, 8)

    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Verify",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        ZIndex = 211,
        Parent = submitBtn
    })

    submitBtn.MouseEnter:Connect(function()
        tween(submitBtn, {BackgroundColor3 = theme.AccentDark}, 0.15)
    end)
    submitBtn.MouseLeave:Connect(function()
        tween(submitBtn, {BackgroundColor3 = theme.Accent}, 0.15)
    end)

    -- get key link (styled, secondary button below verify)
    if opts.GetKeyLink then
        local linkBtn = create("TextButton", {
            Size = UDim2.new(1, -40, 0, mobile and 36 or 32),
            Position = UDim2.new(0, 20, 0, 176),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.2,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 210,
            Parent = card
        })
        addCorner(linkBtn, 8)
        local linkStroke = addStroke(linkBtn, theme.Border, 1, 0.5)

        -- icon + text together
        local row = create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 211,
            Parent = linkBtn
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = row
        })

        local iconImg = (Velvet._icons and Velvet._icons["external-link"]) or "rbxassetid://104262388679305"
        create("ImageLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Image = iconImg,
            ImageColor3 = theme.Accent,
            ZIndex = 212,
            LayoutOrder = 1,
            Parent = row
        })
        local linkLbl = create("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.GetKeyText or "Get Key",
            TextColor3 = theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            ZIndex = 212,
            LayoutOrder = 2,
            Parent = row
        })

        linkBtn.MouseEnter:Connect(function()
            tween(linkBtn, {BackgroundTransparency = 0.05}, 0.15)
            tween(linkStroke, {Color = theme.Accent, Transparency = 0.2}, 0.15)
        end)
        linkBtn.MouseLeave:Connect(function()
            tween(linkBtn, {BackgroundTransparency = 0.2}, 0.15)
            tween(linkStroke, {Color = theme.Border, Transparency = 0.5}, 0.15)
        end)
        linkBtn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(opts.GetKeyLink) end)
            linkLbl.Text = "Link copied!"
            linkLbl.TextColor3 = theme.Success
            task.delay(1.5, function()
                if linkLbl.Parent then
                    linkLbl.Text = opts.GetKeyText or "Get Key"
                    linkLbl.TextColor3 = theme.Text
                end
            end)
        end)
    end

    local cardH = opts.GetKeyLink and (mobile and 226 or 222) or 180

    -- animate in
    tween(card, {
        Size = UDim2.new(0, mobile and 320 or 340, 0, cardH),
        Position = UDim2.new(0.5, mobile and -160 or -170, 0.5, -cardH/2),
    }, 0.3)

    -- verify
    local locked = false
    local function tryKey()
        if locked then return end
        local input = keyInput.Text
        if input == "" then
            statusLabel.Text = "Enter a key first"
            statusLabel.TextColor3 = theme.Warning
            return
        end

        if checkKey(input) then
            statusLabel.Text = "Key accepted!"
            statusLabel.TextColor3 = theme.Success
            -- store hash, not the raw key (file leak doesn't expose key)
            pcall(function() writefile(saveName, hashKey(input)) end)
            passed = true
            tween(card, {
                Size = UDim2.new(0, mobile and 320 or 340, 0, 0),
                Position = UDim2.new(0.5, mobile and -160 or -170, 0.5, 0),
            }, 0.25)
            tween(keyGui, {BackgroundTransparency = 1}, 0.3)
            task.delay(0.3, function()
                pcall(function() keyGui:Destroy() end)
                safecall("KeySystem", cb, true)
            end)
        else
            attempts = attempts + 1
            if attempts >= maxAttempts then
                locked = true
                statusLabel.Text = `Too many attempts. Locked.`
                statusLabel.TextColor3 = theme.Error
                keyInput.TextEditable = false
                submitBtn.Active = false
                tween(submitBtn, {BackgroundTransparency = 0.6}, 0.2)
                if opts.OnLockout then pcall(opts.OnLockout) end
                return
            end
            statusLabel.Text = `Invalid key ({attempts}/{maxAttempts})`
            statusLabel.TextColor3 = theme.Error
            -- shake
            local orig = card.Position
            for i = 1, 3 do
                tween(card, {Position = orig + UDim2.new(0, 8, 0, 0)}, 0.04)
                task.wait(0.04)
                tween(card, {Position = orig + UDim2.new(0, -8, 0, 0)}, 0.04)
                task.wait(0.04)
            end
            tween(card, {Position = orig}, 0.04)
        end
    end

    submitBtn.MouseButton1Click:Connect(tryKey)
    keyInput.FocusLost:Connect(function(enter)
        if enter then tryKey() end
    end)

    -- yield current thread until user passes or hits lockout
    -- (so caller can do `if not Velvet:KeySystem(...) then return end` synchronously)
    while not passed and not locked do task.wait() end
    return passed
end

function Velvet:CreateWindow(opts)
    opts = opts or {}
    local theme = self.Theme
    local mobile = isMobile()
    local screen = getScreenSize()

    local winW = opts.Width or (mobile and math.min(screen.X - 20, 380) or 560)
    local winH = opts.Height or (mobile and math.min(screen.Y - 80, 420) or 400)
    local tabW = opts.TabWidth or (mobile and 52 or 150)

    local window = {
        Tabs = {},
        ActiveTab = nil,
        Visible = true,
        _flags = self.Flags,
        _theme = theme,
    }

    -- main frame
    local main = create("Frame", {
        Name = "VelvetWindow",
        Size = UDim2.new(0, winW, 0, winH),
        Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2),
        BackgroundColor3 = theme.Base,
        BackgroundTransparency = 0.02,
        ClipsDescendants = true,
        Parent = gui
    })
    addCorner(main, 14)
    addStroke(main, theme.Border, 1, 0.25)
    -- subtle accent ambient (premium glow)
    local glowStroke = create("UIStroke", {
        Color = theme.Accent,
        Thickness = 2,
        Transparency = 0.85,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = main
    })
    window._glowStroke = glowStroke
    window._main = main

    -- ui scale (global multiplier for everything inside the window)
    local uiScale = create("UIScale", {
        Scale = opts.Scale or 1,
        Parent = main,
    })
    function window:SetScale(s)
        uiScale.Scale = math.clamp(s, 0.5, 2)
    end
    function window:GetScale() return uiScale.Scale end

    -- glass overlay
    local glass = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = main
    })
    addCorner(glass, 12)

    -- top accent line (gradient-faded edges so it feels like a glow strip)
    local accentLine = create("Frame", {
        Size = UDim2.new(0, 80, 0, 2),
        Position = UDim2.new(0.5, -40, 0, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = main
    })
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = accentLine
    })

    -- header
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = theme.Base,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = main
    })
    addCorner(header, 12)
    -- fix bottom corners
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = theme.Base,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = header
    })

    -- logo dot (gently pulses so window feels "alive")
    local logoDot = create("Frame", {
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(0, 16, 0.5, -3),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = header
    })
    addCorner(logoDot, 4)
    -- pulse halo
    local logoHalo = create("Frame", {
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(0, 16, 0.5, -3),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = header,
    })
    addCorner(logoHalo, 4)
    task.spawn(function()
        while logoHalo.Parent do
            tween(logoHalo, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 12, 0.5, -8), BackgroundTransparency = 1}, 1.4, Enum.EasingStyle.Sine)
            task.wait(1.4)
            logoHalo.Size = UDim2.new(0, 7, 0, 7)
            logoHalo.Position = UDim2.new(0, 16, 0.5, -3)
            logoHalo.BackgroundTransparency = 0.6
            task.wait(0.4)
        end
    end)

    -- title
    create("TextLabel", {
        Size = UDim2.new(0, 200, 0, 16),
        Position = UDim2.new(0, 30, 0, 8),
        BackgroundTransparency = 1,
        Text = opts.Title or "Velvet",
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = header
    })

    -- subtitle
    if opts.SubTitle then
        create("TextLabel", {
            Size = UDim2.new(0, 200, 0, 12),
            Position = UDim2.new(0, 30, 0, 24),
            BackgroundTransparency = 1,
            Text = opts.SubTitle,
            TextColor3 = theme.TextMuted,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            Parent = header
        })
    end

    -- search bar (header right, before the 3 buttons; collapses to icon on mobile)
    local searchBarW = mobile and 28 or 160
    local searchBar = create("Frame", {
        Name = "VelvetSearchBar",
        Size = UDim2.new(0, searchBarW, 0, 26),
        Position = UDim2.new(1, -(110 + searchBarW + 6), 0.5, -13),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = mobile and 0.4 or 0.1,
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = header,
    })
    addCorner(searchBar, 6)
    local searchStroke = addStroke(searchBar, theme.Border, 1, 0.5)

    -- search icon
    create("ImageLabel", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 6, 0.5, -7),
        BackgroundTransparency = 1,
        Image = "rbxassetid://121018724060431",
        ImageColor3 = theme.TextMuted,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 8,
        Parent = searchBar,
    })

    local searchBox = create("TextBox", {
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.TextMuted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 8,
        Parent = searchBar,
        Visible = not mobile,
    })

    searchBox.Focused:Connect(function()
        tween(searchStroke, {Color = theme.Accent, Transparency = 0.2}, 0.15)
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchStroke, {Color = theme.Border, Transparency = 0.5}, 0.15)
    end)

    -- mobile: tap icon to expand. expanded bar sits ABOVE the buttons row
    -- (full width minus padding) so it doesnt clip the close/min/toggle.
    -- a small × at the right of the expanded bar lets users collapse it.
    local mobileExpanded = false
    local closeBtn
    if mobile then
        local tapBtn = create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 9,
            Parent = searchBar,
        })

        -- close icon that appears only when expanded, used to collapse
        closeBtn = create("TextButton", {
            Size = UDim2.new(0, 22, 1, 0),
            Position = UDim2.new(1, -22, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 10,
            Visible = false,
            Parent = searchBar,
        })
        create("ImageLabel", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, -6, 0.5, -6),
            BackgroundTransparency = 1,
            Image = "rbxassetid://110786993356448",
            ImageColor3 = theme.TextMuted,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 11,
            Parent = closeBtn,
        })

        local function collapse()
            mobileExpanded = false
            searchBox.Text = ""
            searchBox.Visible = false
            closeBtn.Visible = false
            tween(searchBar, {Size = UDim2.new(0, 28, 0, 26), Position = UDim2.new(1, -(110 + 28 + 6), 0.5, -13), BackgroundTransparency = 0.4}, 0.2)
            if window._applySearch then window:_applySearch("") end
        end

        tapBtn.MouseButton1Click:Connect(function()
            if mobileExpanded then return end
            mobileExpanded = true
            searchBox.Visible = true
            -- shrink box width to leave room for × button
            searchBox.Size = UDim2.new(1, -52, 1, 0)
            -- place expanded bar near the right edge but stop short of the action buttons
            -- header buttons take ~110px; pad 6px gap. Use full width so search has room.
            tween(searchBar, {Size = UDim2.new(1, -130, 0, 26), Position = UDim2.new(0, 12, 0.5, -13), BackgroundTransparency = 0}, 0.2)
            closeBtn.Visible = true
            task.delay(0.22, function()
                if mobileExpanded then searchBox:CaptureFocus() end
            end)
        end)

        closeBtn.MouseButton1Click:Connect(collapse)
        -- also collapse if user taps elsewhere & box loses focus with no text
        searchBox.FocusLost:Connect(function()
            if mobileExpanded and searchBox.Text == "" then
                task.wait(0.1)
                if mobileExpanded and searchBox.Text == "" then collapse() end
            end
        end)
    end

    -- core filter, walks every elem frame's VelvetSearch attr
    function window:_applySearch(q)
        q = string.lower(q or "")
        for _, t in self.Tabs do
            local content = t._content
            if content then
                for _, secFrame in content:GetChildren() do
                    if secFrame:IsA("Frame") then
                        local anyVisible = false
                        for _, child in secFrame:GetDescendants() do
                            if child:IsA("Frame") or child:IsA("TextButton") then
                                local s = child:GetAttribute("VelvetSearch")
                                if s then
                                    local match = q == "" or string.find(s, q, 1, true) ~= nil
                                    child.Visible = match
                                    if match then anyVisible = true end
                                end
                            end
                        end
                        -- hide whole section if nothing matches and there's a query
                        if q ~= "" then
                            secFrame.Visible = anyVisible
                        else
                            secFrame.Visible = true
                        end
                    end
                end
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        window:_applySearch(searchBox.Text)
    end)

    -- close button
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -36, 0.5, -12),
        BackgroundColor3 = theme.Error,
        BackgroundTransparency = 0.6,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 7,
        AutoButtonColor = false,
        Parent = header
    })
    create("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0.5, -6, 0.5, -6),
        BackgroundTransparency = 1,
        Image = "rbxassetid://110786993356448",
        ImageColor3 = theme.Text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 8,
        Parent = closeBtn,
    })
    addCorner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, {BackgroundTransparency = 0.6}, 0.15)
    end)

    -- minimize button
    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -66, 0.5, -12),
        BackgroundColor3 = theme.Warning,
        BackgroundTransparency = 0.6,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 7,
        AutoButtonColor = false,
        Parent = header
    })
    create("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0.5, -6, 0.5, -6),
        BackgroundTransparency = 1,
        Image = "rbxassetid://118026365011536",
        ImageColor3 = theme.Text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 8,
        Parent = minBtn,
    })
    addCorner(minBtn, 6)

    minBtn.MouseEnter:Connect(function()
        tween(minBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    minBtn.MouseLeave:Connect(function()
        tween(minBtn, {BackgroundTransparency = 0.6}, 0.15)
    end)

    -- tab sidebar
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, tabW, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = theme.Base,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 4,
        ClipsDescendants = true,
        Parent = main
    })

    -- sidebar separator
    create("Frame", {
        Size = UDim2.new(0, 1, 1, -12),
        Position = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = sidebar
    })

    local tabList = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -6),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 5,
        Parent = sidebar,
        Children = {
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            }),
            create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            })
        }
    })

    -- active tab indicator (height adapts to tab content)
    local indicatorH = mobile and 28 or 18
    local tabIndicator = create("Frame", {
        Size = UDim2.new(0, 3, 0, indicatorH),
        Position = UDim2.new(0, 2, 0, 8),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = sidebar
    })
    addCorner(tabIndicator, 2)

    -- content area
    local contentArea = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -(tabW + 2), 1, -48),
        Position = UDim2.new(0, tabW + 2, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 3,
        ClipsDescendants = true,
        Parent = main
    })

    -- dragging
    local dragging, dragStart, startPos = false, nil, nil

    local function beginDrag(pos)
        dragging = true
        dragStart = pos
        startPos = main.Position
    end
    local function updateDrag(pos)
        if not dragging then return end
        local delta = pos - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    local function endDrag() dragging = false end

    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            beginDrag(Vector2.new(inp.Position.X, inp.Position.Y))
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            updateDrag(Vector2.new(inp.Position.X, inp.Position.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            endDrag()
        end
    end)

    -- floating toggle pill
    -- toggle pill - supports text OR icon, auto-sizes
    local resolvedToggleIcon = Velvet:ResolveIcon(opts.ToggleIcon)
    local pillText = opts.ToggleText or resolvedToggleIcon or "V"
    local pillIsIcon = resolvedToggleIcon ~= nil
    local pillH = mobile and 48 or 36

    -- calc width: auto-size for text length
    local pillW = pillH -- default square
    if not pillIsIcon and #pillText > 1 then
        -- estimate text width + padding
        pillW = math.max(pillH, #pillText * (mobile and 11 or 9) + (mobile and 24 or 18))
    end

    local togglePill = create("TextButton", {
        Name = "VelvetToggle",
        Size = UDim2.new(0, pillW, 0, pillH),
        Position = UDim2.new(0, 12, 0.5, -pillH/2),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.15,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 100,
        Visible = false,
        Parent = gui
    })
    addCorner(togglePill, pillH / 2)
    addStroke(togglePill, theme.Accent, 1, 0.3)

    if pillIsIcon then
        -- icon mode: use ImageLabel
        local iconImg = create("ImageLabel", {
            Size = UDim2.new(0, mobile and 22 or 18, 0, mobile and 22 or 18),
            Position = UDim2.new(0.5, mobile and -11 or -9, 0.5, mobile and -11 or -9),
            BackgroundTransparency = 1,
            Image = resolvedToggleIcon,
            ImageColor3 = theme.Text,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 101,
            Parent = togglePill
        })
    else
        -- text mode
        create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = pillText,
            TextColor3 = theme.Text,
            TextSize = mobile and 16 or 13,
            Font = Enum.Font.GothamBold,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 101,
            Parent = togglePill
        })
    end

    -- pill drag
    local pillDrag, pillDragStart, pillStartPos = false, nil, nil
    local pillMoved = false

    togglePill.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            pillDrag = true
            pillMoved = false
            pillDragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            pillStartPos = togglePill.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not pillDrag then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local pos = Vector2.new(inp.Position.X, inp.Position.Y)
            local delta = pos - pillDragStart
            if delta.Magnitude > 5 then pillMoved = true end
            togglePill.Position = UDim2.new(pillStartPos.X.Scale, pillStartPos.X.Offset + delta.X, pillStartPos.Y.Scale, pillStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if pillDrag and not pillMoved then
                -- tap, toggle window
                window:Show()
            end
            pillDrag = false
        end
    end)

    -- hover glow on pill
    togglePill.MouseEnter:Connect(function()
        tween(togglePill, {BackgroundTransparency = 0}, 0.15)
    end)
    togglePill.MouseLeave:Connect(function()
        tween(togglePill, {BackgroundTransparency = 0.15}, 0.15)
    end)

    window._togglePill = togglePill

    -- show/hide
    function window:Show()
        if self.Visible then return end
        self.Visible = true
        main.Visible = true
        togglePill.Visible = false
        main.Size = UDim2.new(0, winW * 0.9, 0, winH * 0.9)
        main.BackgroundTransparency = 0.5
        tween(main, {
            Size = UDim2.new(0, winW, 0, winH),
            BackgroundTransparency = 0.02
        }, 0.3)
    end

    function window:Hide()
        if not self.Visible then return end
        self.Visible = false
        tween(main, {
            Size = UDim2.new(0, winW * 0.9, 0, winH * 0.9),
            BackgroundTransparency = 0.6
        }, 0.2)
        task.delay(0.22, function()
            main.Visible = false
            -- skip the pill if an addon (e.g. QuickBar) suppresses it
            if not self._pillSuppressed then
                togglePill.Visible = true
                tween(togglePill, {BackgroundTransparency = 0.15}, 0.2)
            else
                togglePill.Visible = false
            end
        end)
    end

    function window:Toggle()
        if self.Visible then self:Hide() else self:Show() end
    end

    function window:Destroy()
        pcall(function() main:Destroy() end)
        pcall(function() togglePill:Destroy() end)
    end
    window.ScreenGui = gui

    -- close / minimize
    closeBtn.MouseButton1Click:Connect(function()
        -- full nuke: window + watermark + toggle pill + listeners + all velvet stuff
        Velvet:Destroy()
    end)
    minBtn.MouseButton1Click:Connect(function()
        window:Hide()
    end)

    -- toggle key
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == toggleKey then
            window:Toggle()
        end
    end)

    -- open animation
    main.Size = UDim2.new(0, winW * 0.8, 0, winH * 0.8)
    main.BackgroundTransparency = 0.5
    tween(main, {
        Size = UDim2.new(0, winW, 0, winH),
        BackgroundTransparency = 0.02
    }, 0.35)

    -- ~~--------
    -- SIDEBAR COLLAPSE (mobile or opt-in)
    -- ~~--------
    local sidebarCollapsed = false
    local collapsedW = 0
    local expandedW = tabW

    local function applySidebar()
        local w = sidebarCollapsed and collapsedW or expandedW
        tween(sidebar, {Size = UDim2.new(0, w, 1, -48)}, 0.22)
        tween(contentArea, {
            Size = UDim2.new(1, -(w + 2), 1, -48),
            Position = UDim2.new(0, w + 2, 0, 48),
        }, 0.22)
    end

    function window:ToggleSidebar()
        sidebarCollapsed = not sidebarCollapsed
        applySidebar()
    end

    -- collapse toggle button in header (right side, before minimize)
    local collapseBtn = create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -96, 0.5, -12),
        BackgroundColor3 = theme.Info,
        BackgroundTransparency = 0.6,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 7,
        AutoButtonColor = false,
        Parent = header
    })
    create("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0.5, -6, 0.5, -6),
        BackgroundTransparency = 1,
        Image = "rbxassetid://97419752870313",
        ImageColor3 = theme.Text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 8,
        Parent = collapseBtn,
    })
    addCorner(collapseBtn, 6)
    collapseBtn.Visible = opts.SidebarToggle ~= false
    collapseBtn.MouseButton1Click:Connect(function()
        window:ToggleSidebar()
    end)
    collapseBtn.MouseEnter:Connect(function()
        tween(collapseBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    collapseBtn.MouseLeave:Connect(function()
        tween(collapseBtn, {BackgroundTransparency = 0.6}, 0.15)
    end)

    -- ~~--------
    -- GESTURE: swipe to switch tabs on mobile
    -- ~~--------
    if mobile and opts.Gestures ~= false then
        local swipeStart
        contentArea.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch then
                swipeStart = Vector2.new(inp.Position.X, inp.Position.Y)
            end
        end)
        contentArea.InputEnded:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.Touch or not swipeStart then return end
            local endP = Vector2.new(inp.Position.X, inp.Position.Y)
            local delta = endP - swipeStart
            swipeStart = nil
            if math.abs(delta.X) < 80 or math.abs(delta.Y) > 60 then return end
            -- find active idx
            local curIdx
            for i, t in window.Tabs do
                if t == window.ActiveTab then curIdx = i break end
            end
            if not curIdx then return end
            local newIdx
            if delta.X < 0 then
                newIdx = curIdx + 1
            else
                newIdx = curIdx - 1
            end
            if newIdx < 1 or newIdx > #window.Tabs then return end
            local nt = window.Tabs[newIdx]
            if nt and nt._btn then
                -- haptic
                if Velvet.Haptic then Velvet:Haptic("light") end
                pcall(function() firesignal(nt._btn.MouseButton1Click) end)
            end
        end)
    end

    -- ~~--------
    -- TAB
    -- ~~--------
    function window:AddTab(name, icon)
        local tabIdx = #self.Tabs + 1
        local tab = {
            Name = name,
            Sections = {},
            _elements = {},
        }

        -- resolve icon (can be lucide name, asset id, or url)
        local iconUrl = Velvet:ResolveIcon(icon)

        -- tab button
        local tabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, mobile and 44 or 32),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 6,
            Parent = tabList
        })
        addCorner(tabBtn, 6)

        -- icon (if provided)
        local iconImg
        local iconSize = mobile and 20 or 14
        local textOffset = 10
        if iconUrl and mobile then
            -- mobile: icon centered top, text below
            iconImg = create("ImageLabel", {
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0, 4),
                BackgroundTransparency = 1,
                Image = iconUrl,
                ImageColor3 = theme.TextDim,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 7,
                Parent = tabBtn,
            })
        elseif iconUrl then
            -- pc: icon left, text right
            iconImg = create("ImageLabel", {
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, 8, 0.5, -iconSize/2),
                BackgroundTransparency = 1,
                Image = iconUrl,
                ImageColor3 = theme.TextDim,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 7,
                Parent = tabBtn,
            })
            textOffset = 8 + iconSize + 6
        end

        local tabLabel = create("TextLabel", {
            Size = mobile and UDim2.new(1, 0, 0, 12) or UDim2.new(1, -(textOffset + 4), 1, 0),
            Position = mobile and UDim2.new(0, 0, 1, -15) or UDim2.new(0, textOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = mobile and name:sub(1, 3) or name,
            TextColor3 = theme.TextDim,
            TextSize = mobile and 9 or 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = mobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = tabBtn
        })

        -- active toggle badge, top-right corner of tab btn
        local badge = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(1, -(mobile and 4 or 6), 0, mobile and 3 or 4),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 8,
            Parent = tabBtn,
        })
        addCorner(badge, 7)
        local badgeLbl = create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "0",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            ZIndex = 9,
            Parent = badge,
        })
        tab._badge = badge
        tab._badgeLbl = badgeLbl
        function tab:_refreshBadge()
            local n = 0
            for _, tg in self._toggles or {} do
                -- only count toggles whose row is currently visible (skip VisibleWhen=false)
                local visible = (not tg._frame) or tg._frame.Visible
                if visible and tg.Get and tg:Get() then n = n + 1 end
            end
            if n > 0 then
                badge.Visible = true
                -- compact: 1234 -> 1.2k, 12345 -> 12k, 1234567 -> 1.2m
                local txt
                if n < 1000 then
                    txt = tostring(n)
                elseif n < 10000 then
                    txt = string.format("%.1fk", n/1000):gsub("%.0k$", "k")
                elseif n < 1000000 then
                    txt = string.format("%dk", math.floor(n/1000))
                elseif n < 10000000 then
                    txt = string.format("%.1fm", n/1000000):gsub("%.0m$", "m")
                else
                    txt = string.format("%dm", math.floor(n/1000000))
                end
                badgeLbl.Text = txt
                -- grow width with text length so it morphs from circle to pill
                local len = #txt
                local w = (len <= 1) and 14 or (10 + len * 5)
                tween(badge, {Size = UDim2.new(0, w, 0, 14)}, 0.18, Enum.EasingStyle.Back)
            else
                badge.Visible = false
            end
        end

        -- content scroll for this tab
        local tabContent = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 4,
            Parent = contentArea,
            Children = {
                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                }),
                create("UIPadding", {
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                })
            }
        })
        tab._content = tabContent
        tab._btn = tabBtn
        tab._label = tabLabel
        tab._icon = iconImg

        local function activate()
            -- deactivate all
            for _, t in self.Tabs do
                t._content.Visible = false
                tween(t._label, {TextColor3 = theme.TextDim}, 0.15)
                tween(t._btn, {BackgroundTransparency = 1}, 0.15)
                if t._icon then tween(t._icon, {ImageColor3 = theme.TextDim}, 0.15) end
            end
            -- activate this
            tabContent.Visible = true
            tween(tabLabel, {TextColor3 = theme.Text}, 0.15)
            tween(tabBtn, {BackgroundTransparency = 0.85}, 0.15)
            if iconImg then tween(iconImg, {ImageColor3 = theme.Text}, 0.15) end

            -- move indicator, center aligned to whatever the tab btn actually has (icon-only, text-only, or both)
            local btnH = mobile and 44 or 32
            local step = btnH + 2 -- list padding
            local listTop = 8 -- tabList offset (6) + padTop (2)
            local centerY = listTop + (tabIdx - 1) * step + btnH / 2
            local yPos = centerY - indicatorH / 2
            tween(tabIndicator, {Position = UDim2.new(0, 2, 0, yPos)}, 0.32, Enum.EasingStyle.Back)

            self.ActiveTab = tab
        end

        tabBtn.MouseButton1Click:Connect(activate)

        -- hover
        tabBtn.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab then
                tween(tabBtn, {BackgroundTransparency = 0.9}, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab then
                tween(tabBtn, {BackgroundTransparency = 1}, 0.1)
            end
        end)

        table.insert(self.Tabs, tab)

        -- first tab auto-activate
        if tabIdx == 1 then
            task.defer(activate)
        end

        -- ~~----
        -- SUB-TABS (horizontal pill row inside a tab)
        -- ~~----
        tab.SubTabs = {}
        tab._activeSub = nil

        function tab:AddSubTab(subName)
            -- lazy init the sub-tab row
            if not tab._subRow then
                tab._subRow = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 34 or 28),
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    ZIndex = 5,
                    Parent = tabContent,
                })
                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = tab._subRow,
                })
            end

            local subIdx = #tab.SubTabs + 1
            local sub = { Name = subName, _sections = {} }

            local subBtn = create("TextButton", {
                Size = UDim2.new(0, 0, 1, -4),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = theme.Surface,
                BackgroundTransparency = 0.6,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                ZIndex = 6,
                LayoutOrder = subIdx,
                Parent = tab._subRow,
            })
            addCorner(subBtn, 6)
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = subBtn,
            })
            local subLbl = create("TextLabel", {
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = subName,
                TextColor3 = theme.TextDim,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                ZIndex = 7,
                Parent = subBtn,
            })

            -- container for this sub-tab's sections
            local subContainer = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
                LayoutOrder = subIdx + 100,
                ZIndex = 4,
                Parent = tabContent,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = subContainer,
            })
            sub._container = subContainer

            local function activateSub()
                for _, s in tab.SubTabs do
                    if s._container then s._container.Visible = false end
                    if s._btn then
                        tween(s._btn, {BackgroundTransparency = 0.6}, 0.15)
                        tween(s._lbl, {TextColor3 = theme.TextDim}, 0.15)
                    end
                end
                subContainer.Visible = true
                tween(subBtn, {BackgroundTransparency = 0.1}, 0.15)
                tween(subLbl, {TextColor3 = theme.Text}, 0.15)
                tab._activeSub = sub
            end

            sub._btn = subBtn
            sub._lbl = subLbl
            subBtn.MouseButton1Click:Connect(activateSub)

            -- sections inside a subtab: proxy to container
            function sub:AddSection(name)
                -- temporarily redirect parent via an upvalue swap
                local oldContent = tabContent
                local swapped = subContainer
                -- hijack: build section then reparent
                local s = tab:AddSection(name)
                if s and s.Frame then
                    s.Frame.Parent = swapped
                end
                return s
            end

            table.insert(tab.SubTabs, sub)
            if subIdx == 1 then task.defer(activateSub) end
            return sub
        end

        -- ~~----
        -- SECTION
        -- ~~----
        function tab:AddSection(sectionName)
            local section = { Elements = {} }

            local sectionFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Panel,
                BackgroundTransparency = 0.4,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                ZIndex = 5,
                Parent = tabContent
            })
            section.Frame = sectionFrame
            addCorner(sectionFrame, 10)
            addStroke(sectionFrame, theme.Border, 1, 0.55)
            -- accent rail on the left edge for a more premium feel
            create("Frame", {
                Size = UDim2.new(0, 2, 0, 16),
                Position = UDim2.new(0, 0, 0, 7),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 6,
                Parent = sectionFrame,
            })

            -- section header
            local sectionHeader = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 6,
                Parent = sectionFrame
            })

            create("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = sectionName or "Section",
                TextColor3 = theme.TextDim,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
                Parent = sectionHeader
            })

            -- arrow
            local arrow = create("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text = "v",
                TextColor3 = theme.TextMuted,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                ZIndex = 7,
                Parent = sectionHeader
            })

            -- elements container
            local elemContainer = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 5,
                Parent = sectionFrame,
                Children = {
                    create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 4),
                    }),
                    create("UIPadding", {
                        PaddingTop = UDim.new(0, 2),
                        PaddingBottom = UDim.new(0, 8),
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10),
                    })
                }
            })

            local collapsed = false
            sectionHeader.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                tween(arrow, {Rotation = collapsed and -90 or 0}, 0.2)
                elemContainer.Visible = not collapsed
            end)

            section._container = elemContainer

            -- ===
            -- TOGGLE
            -- ===
            function section:AddToggle(id, opts)
                opts = opts or {}
                local value = opts.Default or false
                local cb = opts.Callback or function() end

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 38 or 32),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -56, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or id,
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elem
                })

                -- toggle track
                local track = create("Frame", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -44, 0.5, -10),
                    BackgroundColor3 = theme.Surface,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                    Parent = elem
                })
                addCorner(track, 10)
                addStroke(track, theme.Border, 1, 0.5)

                -- thumb
                local thumb = create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = theme.TextDim,
                    BorderSizePixel = 0,
                    ZIndex = 8,
                    Parent = track
                })
                addCorner(thumb, 8)

                local function update(v, silent)
                    value = v
                    if v then
                        tween(thumb, {Position = UDim2.new(0, 22, 0.5, -8), BackgroundColor3 = Color3.new(1,1,1)}, 0.28, Enum.EasingStyle.Back)
                        tween(track, {BackgroundColor3 = theme.Accent}, 0.2)
                    else
                        tween(thumb, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = theme.TextDim}, 0.22)
                        tween(track, {BackgroundColor3 = theme.Surface}, 0.2)
                    end
                    Velvet.Flags[id] = v
                    fireListeners(id, v)
                    if not silent then safecall(`Toggle:{id}`, cb, v) end
                end

                -- click zone
                local clickBtn = create("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 9,
                    Parent = elem
                })
                clickBtn.MouseButton1Click:Connect(function()
                    update(not value)
                end)

                update(value, true)

                local toggle = { Value = value, _frame = elem }
                function toggle:Set(v) update(v) end
                function toggle:Get() return value end
                attachOnChanged(toggle, id)
                setupVisibility(toggle, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)

                Velvet._elements[id] = toggle
                table.insert(section.Elements, toggle)
                -- track for tab badge count
                tab._toggles = tab._toggles or {}
                table.insert(tab._toggles, toggle)
                -- if this toggle has VisibleWhen, refresh badge when its visibility flips
                if opts.VisibleWhen then
                    Velvet:OnFlagChanged(opts.VisibleWhen, function()
                        if tab._refreshBadge then tab:_refreshBadge() end
                    end)
                end
                Velvet:OnFlagChanged(id, function() if tab._refreshBadge then tab:_refreshBadge() end end)
                if tab._refreshBadge then tab:_refreshBadge() end
                return toggle
            end

            -- ===
            -- SLIDER
            -- ===
            function section:AddSlider(id, opts)
                opts = opts or {}
                local min = opts.Min or 0
                local max = opts.Max or 100
                local inc = opts.Increment or 1
                local suffix = opts.Suffix or ""
                local value = clamp(opts.Default or min, min, max)
                local cb = opts.Callback or function() end

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 48 or 42),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                local label = create("TextLabel", {
                    Size = UDim2.new(0.6, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = opts.Text or id,
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elem
                })

                local valLabel = create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 0, 16),
                    Position = UDim2.new(0.6, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(value) .. suffix,
                    TextColor3 = theme.Accent,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 7,
                    Parent = elem
                })

                -- track
                local sliderTrack = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, mobile and 28 or 24),
                    BackgroundColor3 = theme.Surface,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                    Parent = elem
                })
                addCorner(sliderTrack, 3)

                -- fill
                local fill = create("Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    ZIndex = 8,
                    Parent = sliderTrack
                })
                addCorner(fill, 3)

                -- thumb circle
                local sliderThumb = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 9,
                    Parent = sliderTrack
                })
                addCorner(sliderThumb, 7)

                local function update(v, silent)
                    v = round(clamp(v, min, max), inc)
                    value = v
                    local pct = (v - min) / (max - min)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    sliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
                    valLabel.Text = tostring(v) .. suffix
                    Velvet.Flags[id] = v
                    fireListeners(id, v)
                    if not silent then safecall(`Slider:{id}`, cb, v) end
                end

                -- interaction
                local sliding = false
                local clickArea = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, mobile and 20 or 16),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 10,
                    Parent = elem
                })

                clickArea.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if Velvet._activeDrag and Velvet._activeDrag ~= "slider" then return end
                        sliding = true
                        Velvet._activeDrag = "slider"
                    end
                end)

                UserInputService.InputChanged:Connect(function(inp)
                    if not sliding then return end
                    if Velvet._activeDrag ~= "slider" then return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        local absPos = sliderTrack.AbsolutePosition.X
                        local absSize = sliderTrack.AbsoluteSize.X
                        local rel = clamp((inp.Position.X - absPos) / absSize, 0, 1)
                        update(min + (max - min) * rel)
                    end
                end)

                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if sliding then
                            sliding = false
                            if Velvet._activeDrag == "slider" then Velvet._activeDrag = nil end
                        end
                    end
                end)

                update(value, true)

                local slider = { Value = value }
                function slider:Set(v) update(v) end
                function slider:Get() return value end
                attachOnChanged(slider, id)
                setupVisibility(slider, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)

                Velvet._elements[id] = slider
                table.insert(section.Elements, slider)
                return slider
            end

            -- ===
            -- BUTTON
            -- ===
            function section:AddButton(opts)
                opts = opts or {}
                local cb = opts.Callback or function() end

                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, mobile and 38 or 32),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.3,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 6,
                    Parent = elemContainer
                })
                addCorner(btn, 7)
                local btnStroke = addStroke(btn, theme.Border, 1, 0.55)

                create("TextLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = opts.Text or "Button",
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    ZIndex = 7,
                    Parent = btn
                })

                btn.MouseEnter:Connect(function()
                    tween(btn, {BackgroundTransparency = 0.08}, 0.15)
                    tween(btnStroke, {Color = theme.Accent, Transparency = 0.4}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    tween(btn, {BackgroundTransparency = 0.3}, 0.15)
                    tween(btnStroke, {Color = theme.Border, Transparency = 0.55}, 0.15)
                end)
                btn.MouseButton1Click:Connect(function()
                    -- press flash + tiny scale pulse for haptic feel
                    tween(btn, {BackgroundColor3 = theme.Accent}, 0.08)
                    task.delay(0.12, function()
                        tween(btn, {BackgroundColor3 = theme.Surface}, 0.18)
                    end)
                    safecall(`Button:{opts.Text or "?"}`, cb)
                end)

                return btn
            end

            -- ===
            -- DROPDOWN
            -- ===
            function section:AddDropdown(id, opts)
                opts = opts or {}
                local values = opts.Values or {}
                local multi = opts.Multi or false
                local cb = opts.Callback or function() end
                local selected = multi and {} or (opts.Default or (values[1] or ""))

                if multi and opts.Default then
                    for _, v in opts.Default do selected[v] = true end
                end

                local hasTitle = opts.Text ~= nil
                local headerY = hasTitle and 16 or 0
                local elemH = (mobile and 38 or 32) + headerY

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, elemH),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 6,
                    ClipsDescendants = false,
                    Parent = elemContainer
                })

                local header = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, mobile and 38 or 32),
                    Position = UDim2.new(0, 0, 0, headerY),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.3,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 7,
                    Parent = elem
                })
                addCorner(header, 6)
                addStroke(header, theme.Border, 1, 0.6)

                local function getDisplayText()
                    if multi then
                        local items = {}
                        for k, v in selected do
                            if v then table.insert(items, k) end
                        end
                        return #items > 0 and table.concat(items, ", ") or (opts.Text or "Select...")
                    else
                        return tostring(selected)
                    end
                end

                local headerLabel = create("TextLabel", {
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = getDisplayText(),
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 8,
                    Parent = header
                })

                if hasTitle then
                    create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = opts.Text,
                        TextColor3 = theme.TextDim,
                        TextSize = 10,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7,
                        Parent = elem
                    })
                end

                local dropArrow = create("TextLabel", {
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "v",
                    TextColor3 = theme.TextMuted,
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 8,
                    Parent = header
                })

                -- dropdown list
                local dropFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, headerY + (mobile and 42 or 36)),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.05,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 20,
                    Parent = elem
                })
                addCorner(dropFrame, 6)
                addStroke(dropFrame, theme.Border, 1, 0.4)

                local dropList = create("ScrollingFrame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 21,
                    Parent = dropFrame,
                    Children = {
                        create("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 1),
                        }),
                        create("UIPadding", {
                            PaddingTop = UDim.new(0, 3),
                            PaddingBottom = UDim.new(0, 3),
                            PaddingLeft = UDim.new(0, 4),
                            PaddingRight = UDim.new(0, 4),
                        })
                    }
                })

                local open = false

                local function refreshItems()
                    for _, c in dropList:GetChildren() do
                        if c:IsA("TextButton") then c:Destroy() end
                    end

                    for _, val in values do
                        local isSelected = multi and selected[val] or (selected == val)
                        local item = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, mobile and 32 or 26),
                            BackgroundColor3 = isSelected and theme.Accent or theme.Panel,
                            BackgroundTransparency = isSelected and 0.6 or 0.8,
                            Text = "",
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            ZIndex = 22,
                            Parent = dropList
                        })
                        addCorner(item, 4)

                        create("TextLabel", {
                            Size = UDim2.new(1, -10, 1, 0),
                            Position = UDim2.new(0, 8, 0, 0),
                            BackgroundTransparency = 1,
                            Text = tostring(val),
                            TextColor3 = isSelected and theme.Text or theme.TextDim,
                            TextSize = 12,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 23,
                            Parent = item
                        })

                        item.MouseEnter:Connect(function()
                            tween(item, {BackgroundTransparency = 0.5}, 0.1)
                        end)
                        item.MouseLeave:Connect(function()
                            local sel = multi and selected[val] or (selected == val)
                            tween(item, {BackgroundTransparency = sel and 0.6 or 0.8}, 0.1)
                        end)

                        item.MouseButton1Click:Connect(function()
                            if multi then
                                selected[val] = not selected[val]
                            else
                                selected = val
                                -- close
                                open = false
                                tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                                task.delay(0.2, function() dropFrame.Visible = false end)
                                tween(dropArrow, {Rotation = 0}, 0.15)
                            end
                            headerLabel.Text = getDisplayText()
                            Velvet.Flags[id] = multi and selected or selected
                            fireListeners(id, multi and selected or selected)
                            refreshItems()
                            safecall(`Dropdown:{id}`, cb, multi and selected or selected)
                        end)
                    end
                end

                header.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        refreshItems()
                        dropFrame.Visible = true
                        local itemH = mobile and 32 or 26
                        local h = math.min(#values * (itemH + 1) + 8, 180)
                        tween(dropFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.2)
                        tween(dropArrow, {Rotation = 180}, 0.15)
                    else
                        tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        task.delay(0.2, function() dropFrame.Visible = false end)
                        tween(dropArrow, {Rotation = 0}, 0.15)
                    end
                end)

                Velvet.Flags[id] = selected
                refreshItems()

                local dropdown = { Value = selected }
                function dropdown:Set(v)
                    selected = v
                    headerLabel.Text = getDisplayText()
                    Velvet.Flags[id] = selected
                    fireListeners(id, selected)
                    refreshItems()
                end
                function dropdown:Refresh(newValues)
                    values = newValues
                    refreshItems()
                end
                function dropdown:Get() return selected end

                attachOnChanged(dropdown, id)
                setupVisibility(dropdown, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)
                Velvet._elements[id] = dropdown
                table.insert(section.Elements, dropdown)
                return dropdown
            end

            -- ===
            -- INPUT
            -- ===
            function section:AddInput(id, opts)
                opts = opts or {}
                local value = opts.Default or ""
                local cb = opts.Callback or function() end

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 56 or 48),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                if opts.Text then
                    create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        BackgroundTransparency = 1,
                        Text = opts.Text,
                        TextColor3 = theme.TextDim,
                        TextSize = 10,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7,
                        Parent = elem
                    })
                end

                local inputBg = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 36 or 30),
                    Position = UDim2.new(0, 0, 1, mobile and -36 or -30),
                    BackgroundColor3 = theme.Surface,
                    BorderSizePixel = 0,
                    ZIndex = 7,
                    Parent = elem
                })
                addCorner(inputBg, 6)
                local inputStroke = addStroke(inputBg, theme.Border, 1, 0.5)

                local textBox = create("TextBox", {
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = value,
                    PlaceholderText = opts.Placeholder or "Type here...",
                    TextColor3 = theme.Text,
                    PlaceholderColor3 = theme.TextMuted,
                    TextSize = 12,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    ZIndex = 8,
                    Parent = inputBg
                })

                textBox.Focused:Connect(function()
                    tween(inputStroke, {Color = theme.Accent, Transparency = 0}, 0.15)
                end)
                textBox.FocusLost:Connect(function(enterPressed)
                    tween(inputStroke, {Color = theme.Border, Transparency = 0.5}, 0.15)
                    value = textBox.Text
                    Velvet.Flags[id] = value
                    fireListeners(id, value)
                    safecall(`Input:{id}`, cb, value, enterPressed)
                end)

                Velvet.Flags[id] = value

                local input = { Value = value }
                function input:Set(v)
                    textBox.Text = v
                    value = v
                    Velvet.Flags[id] = v
                    fireListeners(id, v)
                end
                function input:Get() return value end

                attachOnChanged(input, id)
                setupVisibility(input, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)
                Velvet._elements[id] = input
                table.insert(section.Elements, input)
                return input
            end

            -- ===
            -- KEYBIND
            -- ===
            function section:AddKeybind(id, opts)
                opts = opts or {}
                local key = opts.Default or Enum.KeyCode.Unknown
                local mode = opts.Mode or "Toggle"
                local cb = opts.Callback or function() end
                local active = false
                local listening = false

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 38 or 32),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -80, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or id,
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elem
                })

                local bindBtn = create("TextButton", {
                    Size = UDim2.new(0, 70, 0, 24),
                    Position = UDim2.new(1, -74, 0.5, -12),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.3,
                    Text = key ~= Enum.KeyCode.Unknown and key.Name or "None",
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 8,
                    Parent = elem
                })
                addCorner(bindBtn, 4)
                addStroke(bindBtn, theme.Border, 1, 0.6)

                bindBtn.MouseButton1Click:Connect(function()
                    listening = true
                    bindBtn.Text = "..."
                    tween(bindBtn, {BackgroundColor3 = theme.Accent}, 0.15)
                end)

                UserInputService.InputBegan:Connect(function(inp, gpe)
                    if listening then
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            key = inp.KeyCode
                            bindBtn.Text = key.Name
                            listening = false
                            tween(bindBtn, {BackgroundColor3 = theme.Surface}, 0.15)
                            Velvet.Flags[id] = key
                            fireListeners(id, key)
                        end
                        return
                    end

                    if gpe then return end
                    if inp.KeyCode ~= key or key == Enum.KeyCode.Unknown then return end

                    if mode == "Toggle" then
                        active = not active
                        safecall(`Keybind:{id}`, cb, active)
                    elseif mode == "Hold" then
                        active = true
                        safecall(`Keybind:{id}`, cb, true)
                    end
                end)

                UserInputService.InputEnded:Connect(function(inp)
                    if mode == "Hold" and inp.KeyCode == key and active then
                        active = false
                        safecall(`Keybind:{id}`, cb, false)
                    end
                end)

                Velvet.Flags[id] = key

                local keybind = { Value = key, Active = active }
                function keybind:Set(k)
                    key = k
                    bindBtn.Text = k.Name
                    Velvet.Flags[id] = k
                    fireListeners(id, k)
                end
                function keybind:Get() return key end
                function keybind:IsActive() return active end

                attachOnChanged(keybind, id)
                setupVisibility(keybind, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)
                Velvet._elements[id] = keybind
                table.insert(section.Elements, keybind)
                return keybind
            end

            -- ===
            -- COLORPICKER
            -- ===
            function section:AddColorPicker(id, opts)
                opts = opts or {}
                local color = opts.Default or Color3.fromRGB(255, 255, 255)
                local cb = opts.Callback or function() end

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, mobile and 38 or 32),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -44, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or id,
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elem
                })

                -- swatch preview
                local swatch = create("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -32, 0.5, -10),
                    BackgroundColor3 = color,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 8,
                    Parent = elem
                })
                addCorner(swatch, 4)
                addStroke(swatch, theme.Border, 1, 0.4)

                -- picker popup (parented to gui so section ClipsDescendants doesn't clip it)
                local pickerOpen = false
                local pickerFrame = create("Frame", {
                    Size = UDim2.new(0, 180, 0, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.05,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 100,
                    Parent = gui
                })
                addCorner(pickerFrame, 8)
                addStroke(pickerFrame, theme.Border, 1, 0.3)

                -- hue/sat canvas
                local canvas = create("Frame", {
                    Size = UDim2.new(1, -16, 0, 120),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.new(1, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 31,
                    Parent = pickerFrame
                })
                addCorner(canvas, 4)

                -- sat overlay (white gradient left to right)
                local satOverlay = create("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 32,
                    Parent = canvas,
                    Children = {
                        create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                        create("UIGradient", {
                            Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
                            Transparency = NumberSequence.new(0, 1),
                            Rotation = 0,
                        })
                    }
                })

                -- val overlay (black gradient top to bottom)
                local valOverlay = create("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 33,
                    Parent = canvas,
                    Children = {
                        create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                        create("UIGradient", {
                            Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)),
                            Transparency = NumberSequence.new(1, 0),
                            Rotation = 90,
                        })
                    }
                })

                -- canvas cursor
                local cursor = create("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 35,
                    Parent = canvas
                })
                addCorner(cursor, 5)
                addStroke(cursor, Color3.new(0,0,0), 1, 0)

                -- hue slider
                local hueBar = create("Frame", {
                    Size = UDim2.new(1, -16, 0, 12),
                    Position = UDim2.new(0, 8, 0, 134),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 31,
                    Parent = pickerFrame,
                    Children = {
                        create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                        create("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,1,1)),
                                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,1,1)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,1,1)),
                                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,1,1)),
                                ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
                            })
                        })
                    }
                })

                local hueThumb = create("Frame", {
                    Size = UDim2.new(0, 4, 1, 2),
                    Position = UDim2.new(0, 0, 0, -1),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0,
                    ZIndex = 33,
                    Parent = hueBar
                })
                addCorner(hueThumb, 2)

                -- hex input
                local hexBox = create("TextBox", {
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 8, 0, 152),
                    BackgroundColor3 = theme.Panel,
                    Text = color3ToHex(color),
                    TextColor3 = theme.Text,
                    PlaceholderColor3 = theme.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    BorderSizePixel = 0,
                    ZIndex = 32,
                    Parent = pickerFrame
                })
                addCorner(hexBox, 4)

                -- state
                local h, s, v = Color3.toHSV(color)

                local function updateColor(silent)
                    color = Color3.fromHSV(h, s, v)
                    swatch.BackgroundColor3 = color
                    canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    cursor.Position = UDim2.new(s, -5, 1 - v, -5)
                    hueThumb.Position = UDim2.new(h, -2, 0, -1)
                    hexBox.Text = color3ToHex(color)
                    Velvet.Flags[id] = color
                    fireListeners(id, color)
                    if not silent then safecall(`ColorPicker:{id}`, cb, color) end
                end

                -- canvas drag (claims mutex so slider underneath stays still)
                local canvasDrag = false
                canvas.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        canvasDrag = true
                        Velvet._activeDrag = "picker"
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not canvasDrag then return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        local pos = Vector2.new(inp.Position.X, inp.Position.Y)
                        s = clamp((pos.X - canvas.AbsolutePosition.X) / canvas.AbsoluteSize.X, 0, 1)
                        v = 1 - clamp((pos.Y - canvas.AbsolutePosition.Y) / canvas.AbsoluteSize.Y, 0, 1)
                        updateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if canvasDrag then
                            canvasDrag = false
                            if Velvet._activeDrag == "picker" then Velvet._activeDrag = nil end
                        end
                    end
                end)

                -- hue drag
                local hueDrag = false
                hueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = true
                        Velvet._activeDrag = "picker"
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not hueDrag then return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        h = clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                        updateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if hueDrag then
                            hueDrag = false
                            if Velvet._activeDrag == "picker" then Velvet._activeDrag = nil end
                        end
                    end
                end)

                -- hex input
                hexBox.FocusLost:Connect(function()
                    local ok, c = pcall(hexToColor3, hexBox.Text)
                    if ok and c then
                        h, s, v = Color3.toHSV(c)
                        updateColor()
                    end
                end)

                swatch.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    if pickerOpen then
                        -- position next to swatch
                        local absPos = swatch.AbsolutePosition
                        local absSize = swatch.AbsoluteSize
                        local guiOff = gui.AbsolutePosition
                        local px = absPos.X - guiOff.X + absSize.X - 180
                        local py = absPos.Y - guiOff.Y + absSize.Y + 4
                        pickerFrame.Position = UDim2.new(0, px, 0, py)
                        pickerFrame.Visible = true
                        tween(pickerFrame, {Size = UDim2.new(0, 180, 0, 182)}, 0.2)
                    else
                        tween(pickerFrame, {Size = UDim2.new(0, 180, 0, 0)}, 0.15)
                        task.delay(0.15, function() pickerFrame.Visible = false end)
                    end
                end)

                updateColor(true)

                local picker = { Value = color }
                function picker:Set(c)
                    h, s, v = Color3.toHSV(c)
                    updateColor()
                end
                function picker:Get() return color end

                attachOnChanged(picker, id)
                setupVisibility(picker, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)
                Velvet._elements[id] = picker
                table.insert(section.Elements, picker)
                return picker
            end

            -- ===
            -- LABEL
            -- ===
            function section:AddLabel(text)
                -- accept table form too: AddLabel({ Text = "..." })
                if type(text) == "table" then text = text.Text or text.Title or "" end
                local lbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = tostring(text or ""),
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elemContainer
                })
                local label = {}
                function label:Set(t) lbl.Text = t end
                return label
            end

            -- ===
            -- DIVIDER
            -- ===
            function section:AddDivider()
                create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = theme.Border,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    ZIndex = 6,
                    Parent = elemContainer
                })
            end

            -- ===
            -- PARAGRAPH
            -- ===
            function section:AddParagraph(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                if opts.Title then
                    create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Text = opts.Title,
                        TextColor3 = theme.Text,
                        TextSize = 12,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7,
                        Parent = frame
                    })
                end

                local bodyLbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, opts.Title and 18 or 0),
                    BackgroundTransparency = 1,
                    Text = opts.Content or "",
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 7,
                    Parent = frame
                })

                local para = {}
                function para:Set(txt) bodyLbl.Text = txt end
                return para
            end

            -- ===
            -- PROGRESS BAR
            -- ===
            function section:AddProgressBar(id, opts)
                opts = opts or {}
                local progress = opts.Default or 0
                local maxVal = opts.Max or 100
                local showText = opts.ShowText ~= false

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                    Parent = elemContainer
                })

                local topLbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = opts.Text or id,
                    TextColor3 = theme.TextDim,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = elem
                })

                local barBg = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 12),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 7,
                    Parent = elem
                })
                addCorner(barBg, 4)
                addStroke(barBg, theme.Border, 1, 0.6)

                local fill = create("Frame", {
                    Size = UDim2.new(math.clamp(progress / maxVal, 0, 1), 0, 1, 0),
                    BackgroundColor3 = opts.Color or theme.Accent,
                    BorderSizePixel = 0,
                    ZIndex = 8,
                    Parent = barBg
                })

                local pctLbl
                if showText then
                    pctLbl = create("TextLabel", {
                        Size = UDim2.new(0, 50, 0, 14),
                        Position = UDim2.new(1, -50, 0, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(math.floor(progress)) .. "/" .. tostring(maxVal),
                        TextColor3 = theme.TextDim,
                        TextSize = 10,
                        Font = Enum.Font.Code,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 7,
                        Parent = elem
                    })
                end

                Velvet.Flags[id] = progress

                local bar = { Value = progress }
                function bar:Set(v)
                    progress = math.clamp(v, 0, maxVal)
                    tween(fill, {Size = UDim2.new(progress / maxVal, 0, 1, 0)}, 0.12)
                    if pctLbl then pctLbl.Text = tostring(math.floor(progress)) .. "/" .. tostring(maxVal) end
                    Velvet.Flags[id] = progress
                    fireListeners(id, progress)
                end
                function bar:SetMax(m)
                    maxVal = m
                    bar:Set(progress)
                end
                function bar:SetColor(c) fill.BackgroundColor3 = c end
                function bar:Get() return progress end

                attachOnChanged(bar, id)
                setupVisibility(bar, elem, opts)
                setupTooltip(elem, opts)
                tagSearch(elem, opts.Text or id)
                Velvet._elements[id] = bar
                table.insert(section.Elements, bar)
                return bar
            end

            -- ===
            -- LOG / CONSOLE
            -- ===
            function section:AddLog(opts)
                opts = opts or {}
                local maxLines = opts.MaxLines or 50
                local lines = {}

                local elem = create("Frame", {
                    Size = UDim2.new(1, 0, 0, opts.Height or 120),
                    BackgroundColor3 = theme.Surface,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ZIndex = 6,
                    Parent = elemContainer
                })
                addCorner(elem, 4)
                addStroke(elem, theme.Border, 1, 0.6)

                local scroll = create("ScrollingFrame", {
                    Size = UDim2.new(1, -8, 1, -8),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = theme.Border,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ZIndex = 7,
                    Parent = elem
                })

                local layout = create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1),
                    Parent = scroll
                })

                local log = {}
                local function append(txt, color)
                    if #lines >= maxLines then
                        local first = lines[1]
                        if first then first:Destroy() end
                        table.remove(lines, 1)
                    end
                    local line = create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14),
                        BackgroundTransparency = 1,
                        Text = txt,
                        TextColor3 = color or theme.TextDim,
                        TextSize = 11,
                        Font = Enum.Font.Code,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        LayoutOrder = #lines + 1,
                        ZIndex = 8,
                        Parent = scroll
                    })
                    table.insert(lines, line)
                    task.defer(function()
                        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
                    end)
                end

                function log:Info(txt)  append("[i] " .. tostring(txt), theme.Text) end
                function log:Warn(txt)  append("[!] " .. tostring(txt), Color3.fromRGB(255, 200, 90)) end
                function log:Error(txt) append("[x] " .. tostring(txt), Color3.fromRGB(255, 90, 90)) end
                function log:Success(txt) append("[+] " .. tostring(txt), Color3.fromRGB(120, 230, 140)) end
                function log:Print(txt, color) append(tostring(txt), color) end
                function log:Clear()
                    for _, l in lines do l:Destroy() end
                    table.clear(lines)
                end

                table.insert(section.Elements, log)
                return log
            end

            -- ===
            -- PLAYER SELECTOR (dropdown preloaded with players + auto-refresh)
            -- ===
            function section:AddPlayerSelector(id, opts)
                opts = opts or {}
                local excludeSelf = opts.ExcludeSelf ~= false
                local multi = opts.Multi or false

                local function buildList()
                    local list = {}
                    if not excludeSelf then table.insert(list, "@me") end
                    table.insert(list, "@random")
                    table.insert(list, "@nearest")
                    for _, p in pairs(Players:GetPlayers()) do
                        if not excludeSelf or p ~= Players.LocalPlayer then
                            table.insert(list, p.Name)
                        end
                    end
                    return list
                end

                local dropOpts = {
                    Text = opts.Text or "Select Player",
                    Values = buildList(),
                    Default = opts.Default or (multi and {} or ""),
                    Multi = multi,
                    Callback = opts.Callback,
                    VisibleWhen = opts.VisibleWhen,
                }

                local dd = section:AddDropdown(id, dropOpts)

                -- auto-refresh on join/leave
                local conn1 = Players.PlayerAdded:Connect(function() dd:Refresh(buildList()) end)
                local conn2 = Players.PlayerRemoving:Connect(function() dd:Refresh(buildList()) end)

                function dd:GetPlayers()
                    local sel = dd:Get()
                    if type(sel) == "string" then
                        if sel == "@me" then return {Players.LocalPlayer}
                        elseif sel == "@random" then
                            local list = {}
                            for _, p in pairs(Players:GetPlayers()) do
                                if p ~= Players.LocalPlayer then table.insert(list, p) end
                            end
                            return #list > 0 and {list[math.random(1, #list)]} or {}
                        elseif sel == "@nearest" then
                            local lp = Players.LocalPlayer
                            local myChar = lp.Character
                            if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return {} end
                            local myPos = myChar.HumanoidRootPart.Position
                            local best, bd = nil, math.huge
                            for _, p in pairs(Players:GetPlayers()) do
                                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                    local d = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                                    if d < bd then best, bd = p, d end
                                end
                            end
                            return best and {best} or {}
                        else
                            local p = Players:FindFirstChild(sel)
                            return p and {p} or {}
                        end
                    elseif type(sel) == "table" then
                        local out = {}
                        for name, on in pairs(sel) do
                            if on then
                                local p = Players:FindFirstChild(name)
                                if p then table.insert(out, p) end
                            end
                        end
                        return out
                    end
                    return {}
                end

                return dd
            end

            table.insert(tab.Sections, section)
            return section
        end

        return tab
    end

    table.insert(self.Windows, window)
    return window
end

-- theme setter with live recolor
function Velvet:SetTheme(themeTable)
    -- build old->new color map
    local colorMap = {}
    for k, v in themeTable do
        if typeof(v) == "Color3" and typeof(self.Theme[k]) == "Color3" then
            local old = self.Theme[k]
            colorMap[string.format("%d_%d_%d", math.floor(old.R*255+.5), math.floor(old.G*255+.5), math.floor(old.B*255+.5))] = v
        end
        self.Theme[k] = v
    end

    -- recolor all descendants of VelvetUI + VelvetNotifs
    local colorProps = {"BackgroundColor3", "TextColor3", "PlaceholderColor3", "ImageColor3", "ScrollBarImageColor3"}
    local containers = {}
    pcall(function()
        for _, g in gethui():GetChildren() do
            if g.Name == "VelvetUI" or g.Name == "VelvetNotifs" then
                table.insert(containers, g)
            end
        end
    end)

    for _, container in containers do
        for _, desc in container:GetDescendants() do
            for _, prop in colorProps do
                pcall(function()
                    local cur = desc[prop]
                    if typeof(cur) == "Color3" then
                        local key = string.format("%d_%d_%d", math.floor(cur.R*255+.5), math.floor(cur.G*255+.5), math.floor(cur.B*255+.5))
                        if colorMap[key] then
                            desc[prop] = colorMap[key]
                        end
                    end
                end)
            end
            -- UIStroke
            if desc:IsA("UIStroke") then
                pcall(function()
                    local cur = desc.Color
                    local key = string.format("%d_%d_%d", math.floor(cur.R*255+.5), math.floor(cur.G*255+.5), math.floor(cur.B*255+.5))
                    if colorMap[key] then desc.Color = colorMap[key] end
                end)
            end
        end
    end

    -- also update watermark if exists
    if self._watermark then
        pcall(function()
            for _, desc in self._watermark:GetDescendants() do
                for _, prop in colorProps do
                    pcall(function()
                        local cur = desc[prop]
                        if typeof(cur) == "Color3" then
                            local key = string.format("%d_%d_%d", math.floor(cur.R*255+.5), math.floor(cur.G*255+.5), math.floor(cur.B*255+.5))
                            if colorMap[key] then desc[prop] = colorMap[key] end
                        end
                    end)
                end
            end
        end)
    end
end

function Velvet:GetTheme()
    return self.Theme
end

-- ~~
-- WATERMARK / HUD
-- ~~
function Velvet:CreateWatermark(opts)
    opts = opts or {}
    local theme = self.Theme

    -- kill old
    if self._watermark then
        pcall(function() self._watermark:Destroy() end)
    end

    local frame = create("Frame", {
        Name = "VelvetWatermark",
        Size = UDim2.new(0, 200, 0, 26),
        Position = opts.Position or UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = theme.Base,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 200,
        Parent = gui
    })
    addCorner(frame, 6)
    addStroke(frame, theme.Accent, 1, 0.4)

    local pad = create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = frame,
    })

    local lbl = create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = opts.Text or "Velvet | {fps} fps | {ping} ms",
        TextColor3 = theme.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201,
        Parent = frame,
    })

    self._watermark = frame

    -- live update
    local template = opts.Text or "Velvet | {fps} fps | {ping} ms"
    local lastTick = tick()
    local frames = 0
    local fps = 60

    local RS = game:GetService("RunService")
    local stats = game:GetService("Stats")
    local lp = Players.LocalPlayer

    local conn
    conn = RS.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastTick >= 0.5 then
            fps = math.floor(frames / (now - lastTick))
            frames = 0
            lastTick = now
        end

        local ping = 0
        pcall(function()
            ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        local txt = template
        txt = txt:gsub("{fps}", tostring(fps))
        txt = txt:gsub("{ping}", tostring(ping))
        txt = txt:gsub("{time}", os.date("%H:%M:%S"))
        txt = txt:gsub("{user}", lp and lp.Name or "?")
        txt = txt:gsub("{place}", tostring(game.PlaceId))

        -- substitute flags
        txt = txt:gsub("{flag:([%w_]+)}", function(flag)
            local v = Velvet.Flags[flag]
            if v == nil then return "?" end
            return tostring(v)
        end)

        lbl.Text = txt
    end)

    local watermark = {}
    function watermark:SetText(t) template = t end
    function watermark:SetPosition(p) frame.Position = p end
    function watermark:Destroy()
        if conn then conn:Disconnect() end
        pcall(function() frame:Destroy() end)
        Velvet._watermark = nil
    end
    function watermark:Show() frame.Visible = true end
    function watermark:Hide() frame.Visible = false end

    return watermark
end

-- ~~
-- HAPTIC FEEDBACK (mobile-ish, uses HapticService + visual flash)
-- ~~
function Velvet:Haptic(strength)
    -- strength: "light" | "medium" | "heavy"
    strength = strength or "light"
    local HapticService = game:GetService("HapticService")
    pcall(function()
        local motor = Enum.VibrationMotor.Large
        local amp = strength == "heavy" and 1 or strength == "medium" and 0.6 or 0.3
        -- try all gamepads
        for _, gp in pairs(Enum.UserInputType:GetEnumItems()) do
            if tostring(gp):find("Gamepad") then
                pcall(function()
                    HapticService:SetMotor(gp, motor, amp)
                    task.delay(0.05, function()
                        pcall(function() HapticService:SetMotor(gp, motor, 0) end)
                    end)
                end)
            end
        end
    end)
end

-- ~~
-- AUTO-UPDATE CHECK (fetches latest tag from github)
-- ~~
function Velvet:CheckForUpdate(repo)
    repo = repo or "DexCodeSX/Velvet"
    local url = "https://api.github.com/repos/" .. repo .. "/releases/latest"
    local ok, resp = pcall(function()
        if request then
            return request({Url = url, Method = "GET"})
        elseif http_request then
            return http_request({Url = url, Method = "GET"})
        end
    end)
    if not ok or not resp or not resp.Body then return nil end
    local HttpService = game:GetService("HttpService")
    local okDec, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
    if not okDec or not data.tag_name then return nil end
    return {
        latest = data.tag_name,
        current = self._version,
        outdated = data.tag_name ~= self._version,
        url = data.html_url,
        body = data.body,
    }
end

-- ~~
-- TOOLTIP helper (attach to any GuiObject)
-- ~~
function Velvet:AttachTooltip(guiObj, text)
    if not guiObj or not text then return end
    local theme = self.Theme
    local tip
    local function show()
        if tip then pcall(function() tip:Destroy() end) end
        tip = create("Frame", {
            Name = "VelvetTooltip",
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = theme.Base,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 250,
            Parent = gui,
        })
        addCorner(tip, 4)
        addStroke(tip, theme.Border, 1, 0.5)
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = tip,
        })
        create("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = theme.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            ZIndex = 251,
            Parent = tip,
        })
        local pos = guiObj.AbsolutePosition
        local sz = guiObj.AbsoluteSize
        tip.Position = UDim2.new(0, pos.X, 0, pos.Y + sz.Y + 4)
    end
    local function hide()
        if tip then pcall(function() tip:Destroy() end) tip = nil end
    end
    guiObj.MouseEnter:Connect(show)
    guiObj.MouseLeave:Connect(hide)
    if guiObj:IsA("GuiButton") then
        guiObj.MouseButton1Click:Connect(hide)
    end
end

-- cleanup: destroy all velvet windows, clear listeners, disconnect everything
function Velvet:Destroy()
    -- fire cleanup listener if registered
    if self._onDestroy then
        for _, fn in self._onDestroy do pcall(fn) end
    end

    -- destroy all tracked connections
    if self._connections then
        for _, c in self._connections do
            pcall(function() c:Disconnect() end)
        end
        table.clear(self._connections)
    end

    -- nuke watermark if exists
    if self._watermark then
        pcall(function() self._watermark:Destroy() end)
        self._watermark = nil
    end

    -- destroy all window screengui's
    for _, w in self.Windows do
        if w and w.ScreenGui then
            pcall(function() w.ScreenGui:Destroy() end)
        end
    end

    -- also blow away any leftover gui under gethui named Velvet/VelvetUI/VelvetNotifs
    local hui = (gethui and gethui()) or game:GetService("CoreGui")
    for _, g in pairs(hui:GetChildren()) do
        if g.Name == "Velvet" or g.Name == "VelvetUI" or g.Name == "VelvetNotifs" then
            pcall(function() g:Destroy() end)
        end
    end

    table.clear(self.Windows)
    table.clear(self.Flags)
    table.clear(self._listeners)
    table.clear(self._elements)
end

function Velvet:OnDestroy(fn)
    if not self._onDestroy then self._onDestroy = {} end
    table.insert(self._onDestroy, fn)
end

-- Округление всех элементов Velvet
local _origAddCorner = addCorner
addCorner = function(parent, radius)
    local newRadius = radius or 12
    if newRadius < 20 then newRadius = newRadius + 6 end
    return _origAddCorner(parent, newRadius)
end

_G.Velvet = Velvet

-- ============================================================
-- PIDDLE MM2 v33 + Velvet — FIXED VERSION
-- ============================================================

local ASSETS = {
    logo         = "rbxassetid://116621850916845",     -- rbxassetid://XXX — пусто = дефолт
    header_icon  = "rbxassetid://139363965217986",     -- rbxassetid://XXX — пусто = дефолт
    background   = "rbxassetid://85303808547863",     -- rbxassetid://XXX — пусто = дефолт
}

local BG_LIST = {
    ["None"]          = "",
    ["Default"]       = "rbxassetid://7734068321",
    ["Purple"]        = "rbxassetid://83690600042971",
    ["Halloween"]     = "rbxassetid://85303808547863",
    ["Rain"]          = "rbxassetid://107306683089605",
    ["Anime"]         = "rbxassetid://111095989342249",
    ["Dark"]          = "rbxassetid://79020220019422",
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")

local WS = workspace
local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local ICONS = {
    MENU = "rbxassetid://10734898355",
    HOME = "rbxassetid://10723407389",
    EYE = "rbxassetid://10723346959",
    SPEED = "rbxassetid://10709752035",
    NOCLIP = "rbxassetid://10723346871",
    FLY = "rbxassetid://10723354359",
    TARGET = "rbxassetid://10734898355",
    HAT = "rbxassetid://10723407389",
    TP = "rbxassetid://10723354359",
    GUN = "rbxassetid://10723346959",
    COIN = "rbxassetid://10709752035",
    SHIELD = "rbxassetid://10723346871",
    UTIL = "rbxassetid://10723407389",
    FLING = "rbxassetid://10723354359",
}

local hasFile = false
safe(function() hasFile = (type(writefile) == "function" and type(isfile) == "function") end)

local CFG = {
    speed = 16, jump = 50, volume = 50,
    shootThroughWalls = true, predictMovement = true,
    selectedPack = nil, korbloxOn = false, headlessOn = false,
    chinaHatOn = false, bgName = "Default",
    autoAimMurderer = false,
}

safe(function()
    if hasFile and isfile("PiddleConfig.json") then
        local d = HttpService:JSONDecode(readfile("PiddleConfig.json"))
        for k, v in pairs(d) do CFG[k] = v end
    end
end)

local function saveCFG()
    if not hasFile then return end
    safe(function() writefile("PiddleConfig.json", HttpService:JSONEncode(CFG)) end)
end

-- ROLES
local rolesCache = {}
local function fetchRoles()
    safe(function()
        local r = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if r and r:IsA("RemoteFunction") then
            local res = r:InvokeServer()
            if res then rolesCache = res end
        end
    end)
end

local function getRole(plr)
    local ok, r = pcall(function()
        if plr == LP then
            if rolesCache[LP.Name] then
                local d = rolesCache[LP.Name]
                if not d.Killed and not d.Dead then return d.Role or "Innocent" end
            end
            if LP.Character then
                if LP.Character:FindFirstChild("Knife") then return "Murderer" end
                if LP.Character:FindFirstChild("Gun") then return "Sheriff" end
            end
            return "Innocent"
        end
        if not plr.Character then return "NPC" end
        if plr.Character.Parent ~= WS then return "NPC" end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return "NPC" end
        local fullPath = plr.Character:GetFullName():lower()
        if fullPath:find("lobby") or fullPath:find("menu") or fullPath:find("waiting")
            or fullPath:find("spectate") or fullPath:find("intermission")
            or fullPath:find("npc") or fullPath:find("dummy") then
            return "NPC"
        end
        if plr.UserId <= 0 then return "NPC" end
        if not plr:FindFirstChild("PlayerGui") and not plr:FindFirstChild("Backpack") then
            return "NPC"
        end
        if rolesCache[plr.Name] then
            local d = rolesCache[plr.Name]
            if d.Killed or d.Dead then return "NPC" end
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
    return ok and r or "NPC"
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

local function getKnife()
    local ch = LP.Character
    if not ch then return nil end
    local k = ch:FindFirstChild("Knife")
    if not k then
        local bp = LP:FindFirstChild("Backpack")
        if bp then k = bp:FindFirstChild("Knife") end
    end
    return k
end

local function getGun()
    local ch = LP.Character
    if not ch then return nil end
    local g = ch:FindFirstChild("Gun")
    if not g then
        local bp = LP:FindFirstChild("Backpack")
        if bp then g = bp:FindFirstChild("Gun") end
    end
    return g
end

local function isDead()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    return not h or h.Health <= 0
end

local function isSheriffOrHero()
    local r = getRole(LP)
    return r == "Sheriff" or r == "Hero"
end

task.spawn(function()
    while true do
        task.wait(1.5)
        safe(fetchRoles)
    end
end)

local roleColors = {
    Murderer = Color3.fromRGB(255, 60, 80),
    Sheriff = Color3.fromRGB(80, 140, 255),
    Innocent = Color3.fromRGB(80, 220, 120),
    Hero = Color3.fromRGB(255, 220, 80),
    Gun = Color3.fromRGB(255, 180, 60),
    NPC = Color3.fromRGB(180, 180, 180),
}

-- STATE
local espF = {Murderer=false, Sheriff=false, Innocent=false, Hero=false, Gun=false, NPC=false, NameTag=false, Distance=false, All=false}
local espP = {}
local tracersOn = false
local tracers = {}
local killAuraOn, killAuraCd = false, 0
local killAllActive = false
local autoShoot, autoKnife, autoThrow = false, false, false
local keepSpeed, keepJump, flying, noclip = false, false, false, false
local flyBV, flyBG = nil, nil
local dSpeed, dJump = CFG.speed, CFG.jump
local spinOn, spinSpd, spinA = false, 30, 0
local autoGun = false
local autoRespawn, fastRespawn, antiVoid = false, false, false
local antiAimOn, antiAimSpeed = false, 0.1
local aimMurd = false
local shootThroughWalls = CFG.shootThroughWalls
local predictMovement = CFG.predictMovement
local playerAuraOn, playerAuraColor = false, Color3.fromRGB(255,100,130)
local playerAuraPart, playerAuraLight = nil, nil
local selectedPack = CFG.selectedPack

local UD = {
    enabled = false, ScanRadius = 22, ProjectileSpeedMin = 25, DodgeDist = 20,
    WallBuffer = 2.5, BaseCooldown = 0.6, OverdriveCooldown = 0.1,
    StressThreshold = 2, StressDecay = 0.6, stressLevel = 0,
    lastDodgeTime = 0, isDodging = false, meleeDist = 15,
}

local KillFx = {
    RunKill = false, RunKillRange = 3.5,
    EyeLaser = false, EyeLaserRange = 200, EyeLaserCd = 0,
    EyeLaserTarget = nil,
}

-- ===== KILL AURA (без range, весь сервер, только за Murderer) =====
task.spawn(function()
    while true do
        task.wait(0.08)
        if killAuraOn and LP.Character then
            safe(function()
                local k = getKnife()
                if not k then return end
                local ch = LP.Character
                local hum = ch:FindFirstChildOfClass("Humanoid")
                local root = ch:FindFirstChild("HumanoidRootPart")
                if not (hum and root and hum.Health > 0) then return end
                local best, bd = nil, 10000 -- большой радиус = весь сервер
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                        local tr = p.Character:FindFirstChild("HumanoidRootPart")
                        local th = p.Character:FindFirstChildOfClass("Humanoid")
                        if tr and th and th.Health > 0 then
                            local d = (tr.Position - root.Position).Magnitude
                            if d < bd then bd = d; best = p end
                        end
                    end
                end
                if best and tick() - killAuraCd > 0.2 then
                    local tr = best.Character:FindFirstChild("HumanoidRootPart")
                    if tr then
                        local oldCF = root.CFrame
                        root.CFrame = tr.CFrame * CFrame.new(0, 0, 2.5)
                        if k.Parent ~= ch then hum:EquipTool(k) end
                        safe(function() k:Activate() end)
                        local ev = k:FindFirstChild("Events")
                        local stab = ev and ev:FindFirstChild("Stab")
                        if stab then safe(function() stab:FireServer() end) end
                        task.wait(0.03)
                        root.CFrame = oldCF
                        killAuraCd = tick()
                    end
                end
            end)
        end
    end
end)

-- ===== KILL ALL — без тп игроков, ты стоишь на месте =====
local function killAllRun()
    if not hasItem(LP, "Knife") then return end
    killAllActive = true
    task.spawn(function()
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if not (root and hum) then killAllActive = false; return end
        local home = root.CFrame
        local startT = tick()
        while killAllActive and tick() - startT < 5 do
            root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if not (root and hum) then break end
            local anyAlive = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                    local th = p.Character:FindFirstChildOfClass("Humanoid")
                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                    if th and tr and th.Health > 0 then
                        anyAlive = true
                        local k = getKnife()
                        if k then
                            if k.Parent ~= LP.Character then hum:EquipTool(k) end
                            -- подходим очень быстро, бьём, возвращаемся
                            local oldCF = root.CFrame
                            root.CFrame = CFrame.new(tr.Position - tr.CFrame.LookVector * 2, tr.Position)
                            safe(function() k:Activate() end)
                            local ev = k:FindFirstChild("Events")
                            local stab = ev and ev:FindFirstChild("Stab")
                            if stab then safe(function() stab:FireServer() end) end
                            task.wait(0.02)
                            root.CFrame = home
                        end
                    end
                end
            end
            if not anyAlive then break end
            RunService.Heartbeat:Wait()
        end
        local r2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r2 then r2.CFrame = home end
        killAllActive = false
    end)
end

-- AUTO KNIFE / THROW
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoKnife and LP.Character then
            local k = getKnife()
            if k and k.Parent == LP.Character then safe(function() k:Activate() end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.15)
        if autoThrow and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local k = getKnife()
                if k and k.Parent ~= LP.Character then
                    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:EquipTool(k) end
                end
                if k then
                    local ev = k:FindFirstChild("Events")
                    local th = ev and ev:FindFirstChild("KnifeThrown")
                    if th then
                        local closest, cd = nil, 2000
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                                local h = p.Character:FindFirstChildOfClass("Humanoid")
                                if tr and h and h.Health > 0 then
                                    local d = (tr.Position - root.Position).Magnitude
                                    if d < cd then cd = d; closest = p end
                                end
                            end
                        end
                        if closest then
                            local tr = closest.Character:FindFirstChild("HumanoidRootPart")
                            if tr then
                                local pd = tr.Position + tr.AssemblyLinearVelocity*0.15
                                safe(function() th:FireServer(tr.CFrame + tr.CFrame.LookVector*2, CFrame.new(pd)) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ===== AUTO SHOOT — УЛУЧШЕННЫЙ ПРЕДИКТ =====
local PING = 0.1
task.spawn(function()
    while true do
        local ms = safe(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ms then PING = math.clamp(ms / 1000, 0.02, 1) end
        task.wait(0.5)
    end
end)

RunService.RenderStepped:Connect(function()
    if not autoShoot or not LP.Character then return end
    if not isSheriffOrHero() then return end
    if not hasItem(LP, "Gun") then return end
    safe(function()
        local ch = LP.Character
        local root = ch:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local g = getGun()
        if not g then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if g.Parent ~= ch then
            if hum then hum:EquipTool(g) end
            return
        end
        local sh = g:FindFirstChild("Shoot")
        if not sh then return end
        local m = findMurderer()
        if not m or not m.Character then return end
        local mh = m.Character:FindFirstChildOfClass("Humanoid")
        local mr = m.Character:FindFirstChild("HumanoidRootPart")
        local mHead = m.Character:FindFirstChild("Head")
        if not mh or mh.Health <= 0 or not mr then return end
        local targetPart = mHead or mr
        -- УЛУЧШЕННЫЙ ПРЕДИКТ
        local aimPos = targetPart.Position
        if predictMovement then
            local vel = targetPart.AssemblyLinearVelocity
            local dist = (aimPos - root.Position).Magnitude
            local bulletSpeed = 900 -- примерная скорость пули в MM2 (studs/sec)
            local flyTime = dist / bulletSpeed
            local lead = flyTime + PING
            -- учитываем движение цели
            aimPos = aimPos + vel * lead
            -- учитываем гравитацию если цель в воздухе
            if mh.FloorMaterial == Enum.Material.Air then
                aimPos = aimPos + Vector3.new(0, -0.5 * WS.Gravity * lead * lead, 0)
            end
            -- headshot bias — целимся чуть выше
            aimPos = aimPos + Vector3.new(0, 0.5, 0)
        end
        local at = root:FindFirstChild("GunRaycastAttachment")
        local origin = at and at.WorldCFrame or root.CFrame
        if shootThroughWalls then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {ch, m.Character}
            local candidates = {
                aimPos + Vector3.new(0, 3, 0),
                aimPos + Vector3.new(3, 2, 0),
                aimPos + Vector3.new(-3, 2, 0),
                aimPos + Vector3.new(0, 5, 0),
                aimPos,
            }
            for _, c in ipairs(candidates) do
                local r2 = WS:Raycast(c, aimPos - c, params)
                if not r2 then origin = CFrame.new(c, aimPos); break end
            end
        end
        sh:FireServer(origin, CFrame.new(aimPos))
    end)
end)

-- ===== AIMLOCK =====
RunService.RenderStepped:Connect(function()
    if not aimMurd then return end
    if not isSheriffOrHero() then return end
    if not hasItem(LP, "Gun") then return end
    local m = findMurderer()
    if m and m.Character then
        local hd = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
        if hd then
            Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, hd.Position), 0.25)
        end
    end
end)

-- ===== ANTI-AIM =====
task.spawn(function()
    while true do
        task.wait(antiAimSpeed)
        if antiAimOn and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                -- быстрые угловые прыжки в позиции + velocity
                local randomVel = Vector3.new(
                    math.random(-15, 15),
                    math.random(-5, 5),
                    math.random(-15, 15)
                )
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + randomVel
                -- вращение тела
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-30, 30)), 0)
            end
        end
    end
end)

-- ===== MOVEMENT =====
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
        task.wait(0.01)
        if spinOn and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                spinA = spinA + spinSpd
                hrp.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, math.rad(spinA), 0)
            end
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
        local mv = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if IS_MOBILE and h and h.MoveDirection.Magnitude > 0 then
            mv = Cam.CFrame.LookVector * (h.MoveDirection:Dot(Cam.CFrame.LookVector) > -0.2 and 1 or -1)
        end
        flyBV.Velocity = mv * 60
        flyBG.CFrame = Cam.CFrame
    end)
end)

task.spawn(function()
    while true do
        task.wait(1)
        if autoRespawn and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 then
                task.wait(0.5)
                safe(function() LP.Character:BreakJoints() end)
            end
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

task.spawn(function()
    while true do
        task.wait(0.3)
        if autoGun and LP.Character then
            safe(function()
                if isDead() then return end
                if hasItem(LP, "Gun") then return end
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                for _, o in ipairs(WS:GetDescendants()) do
                    if o:IsA("BasePart") and o.Name == "GunDrop" then
                        if (o.Position - hrp.Position).Magnitude < 5000 then
                            hrp.CFrame = o.CFrame + Vector3.new(0,2,0)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- ===== PLAYER AURA =====
task.spawn(function()
    while true do
        task.wait(0.3)
        if playerAuraOn and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if not playerAuraPart or not playerAuraPart.Parent then
                    playerAuraPart = Instance.new("Part")
                    playerAuraPart.Name = "PiddleAura"
                    playerAuraPart.Shape = Enum.PartType.Ball
                    playerAuraPart.Size = Vector3.new(6, 6, 6)
                    playerAuraPart.Material = Enum.Material.Neon
                    playerAuraPart.Color = playerAuraColor
                    playerAuraPart.Transparency = 0.6
                    playerAuraPart.CanCollide = false
                    playerAuraPart.Anchored = false
                    playerAuraPart.Massless = true
                    playerAuraPart.CanQuery = false
                    playerAuraPart.Parent = LP.Character
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = root
                    w.Part1 = playerAuraPart
                    w.Parent = playerAuraPart
                    playerAuraLight = Instance.new("PointLight")
                    playerAuraLight.Color = playerAuraColor
                    playerAuraLight.Range = 12
                    playerAuraLight.Brightness = 3
                    playerAuraLight.Parent = playerAuraPart
                end
                playerAuraPart.Color = playerAuraColor
                if playerAuraLight then playerAuraLight.Color = playerAuraColor end
            end
        else
            if playerAuraPart and playerAuraPart.Parent then playerAuraPart:Destroy() end
            playerAuraPart, playerAuraLight = nil, nil
        end
    end
end)

-- ===== PACKS =====
local PACKS = {
    Ninja = {Run="656118852",Walk="656121766",Jump="656117878",Idle="656117400",Fall="656115606",Swim="656119721",SwimIdle="656121397",Climb="656114359"},
    Zombie = {Run="616163682",Walk="616168032",Jump="616161997",Idle="616158929",Fall="616157476",Swim="616165109",SwimIdle="616166655",Climb="616156119"},
    Mage = {Run="707861613",Walk="707897309",Jump="707853694",Idle="707742142",Fall="707829716",Swim="707876443",SwimIdle="707894699",Climb="707826056"},
    Pirate = {Run="750783738",Walk="750785693",Jump="750782230",Idle="750781874",Fall="750780242",Swim="750784579",SwimIdle="750785176",Climb="750779899"},
    Robot = {Run="616091570",Walk="616095330",Jump="616090535",Idle="616088211",Fall="616087089",Swim="616092998",SwimIdle="616094091",Climb="616086039"},
}

local function applyPack(name)
    local ch = LP.Character
    if not ch then return end
    local animate = ch:FindFirstChild("Animate")
    if not animate then return end
    local pack = PACKS[name]
    if not pack then return end
    local function setId(cname, id)
        local c = animate:FindFirstChild(cname)
        if c then
            for _, a in ipairs(c:GetChildren()) do
                if a:IsA("Animation") then a.AnimationId = "rbxassetid://"..id end
            end
        end
    end
    setId("idle", pack.Idle); setId("walk", pack.Walk); setId("run", pack.Run)
    setId("jump", pack.Jump); setId("fall", pack.Fall); setId("climb", pack.Climb)
    setId("swim", pack.Swim); setId("swimidle", pack.SwimIdle)
end

-- ===== KORBLOX — FIXED =====
local function applyKorbloxNow()
    local char = LP.Character
    if not char then return end
    local function tryApply()
        local rf = char:FindFirstChild("RightFoot")
        local rl = char:FindFirstChild("RightLowerLeg")
        local ru = char:FindFirstChild("RightUpperLeg")
        local found = 0
        if rf then rf.MeshId = "http://www.roblox.com/asset/?id=902942089"; rf.Transparency = 1; found = found + 1 end
        if rl then rl.MeshId = "http://www.roblox.com/asset/?id=902942093"; rl.Transparency = 1; found = found + 1 end
        if ru then ru.MeshId = "http://www.roblox.com/asset/?id=902942096"; ru.TextureID = "http://roblox.com/asset/?id=902843398"; found = found + 1 end
        return found == 3
    end
    if tryApply() then return end
    task.spawn(function()
        for _ = 1, 15 do
            task.wait(0.5)
            if tryApply() then return end
        end
    end)
end

local function removeKorbloxNow()
    local char = LP.Character
    if not char then return end
    for _, name in ipairs({"RightFoot","RightLowerLeg","RightUpperLeg"}) do
        local p = char:FindFirstChild(name)
        if p then p.MeshId = ""; p.TextureID = ""; p.Transparency = 0 end
    end
end

local function applyHeadlessNow()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 1
    for _, c in ipairs(head:GetChildren()) do
        if c:IsA("Decal") then c.Transparency = 1 end
    end
end

local function removeHeadlessNow()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 0
    for _, c in ipairs(head:GetChildren()) do
        if c:IsA("Decal") then c.Transparency = 0 end
    end
end

local function applyChinaHat()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    for _, n in ipairs({"PiddleChinaHat", "PiddleChinaHatCone", "PiddleChinaHatTassel"}) do
        local old = char:FindFirstChild(n)
        if old then old:Destroy() end
    end
    local hat = Instance.new("Part")
    hat.Name = "PiddleChinaHat"
    hat.Size = Vector3.new(2.2, 0.15, 2.2)
    hat.Shape = Enum.PartType.Cylinder
    hat.Material = Enum.Material.SmoothPlastic
    hat.Color = Color3.fromRGB(255, 220, 60)
    hat.CanCollide = false
    hat.Massless = true
    hat.CFrame = head.CFrame * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
    hat.Parent = char
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head; weld.Part1 = hat; weld.Parent = hat
    local cone = Instance.new("Part")
    cone.Name = "PiddleChinaHatCone"
    cone.Size = Vector3.new(0.8, 0.6, 0.8)
    cone.Shape = Enum.PartType.Ball
    cone.Material = Enum.Material.Neon
    cone.Color = Color3.fromRGB(255, 50, 50)
    cone.CanCollide = false
    cone.Massless = true
    cone.CFrame = head.CFrame * CFrame.new(0, 1.2, 0)
    cone.Parent = char
    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = head; weld2.Part1 = cone; weld2.Parent = cone
    local tassel = Instance.new("Part")
    tassel.Name = "PiddleChinaHatTassel"
    tassel.Size = Vector3.new(0.1, 0.6, 0.1)
    tassel.Material = Enum.Material.SmoothPlastic
    tassel.Color = Color3.fromRGB(255, 50, 50)
    tassel.CanCollide = false
    tassel.Massless = true
    tassel.CFrame = head.CFrame * CFrame.new(0, 1.6, 0)
    tassel.Parent = char
    local weld3 = Instance.new("WeldConstraint")
    weld3.Part0 = head; weld3.Part1 = tassel; weld3.Parent = tassel
end

local function removeChinaHat()
    local char = LP.Character
    if not char then return end
    for _, name in ipairs({"PiddleChinaHat", "PiddleChinaHatCone", "PiddleChinaHatTassel"}) do
        local p = char:FindFirstChild(name)
        if p then p:Destroy() end
    end
end

-- ===== ESP (без моргания) =====
local function buildESP(plr)
    if not plr.Character or plr.Character:FindFirstChild("PiddleHighlight") then return end
    local ch = plr.Character
    local hd = ch:FindFirstChild("Head")
    if not hd then return end
    safe(function()
        local h = Instance.new("Highlight")
        h.Name = "PiddleHighlight"
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = false
        h.Parent = ch
    end)
    safe(function()
        local tag = Instance.new("BillboardGui")
        tag.Name = "PiddleTag"
        tag.Size = UDim2.new(0, 160, 0, 40)
        tag.StudsOffset = Vector3.new(0, 3, 0)
        tag.AlwaysOnTop = true
        tag.Adornee = hd
        tag.Enabled = false
        tag.Parent = ch
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, 0, 1, 0)
        lb.BackgroundTransparency = 1
        lb.Font = Enum.Font.GothamBold
        lb.TextSize = 16
        lb.TextStrokeTransparency = 0
        lb.Parent = tag
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end)
        if p.Character then safe(buildESP, p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LP then
        p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        local h = p.Character:FindFirstChild("PiddleHighlight"); if h then h:Destroy() end
        local t = p.Character:FindFirstChild("PiddleTag"); if t then t:Destroy() end
    end
    if tracers[p] then safe(function() tracers[p]:Remove() end); tracers[p] = nil end
    espP[p] = nil
end)

task.spawn(function()
    while true do
        task.wait(0.15)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if not p.Character then
                    espP[p] = nil
                else
                    local d = p.Character:FindFirstChild("PiddleHighlight")
                    local t = p.Character:FindFirstChild("PiddleTag")
                    if (not d or not t) and p.Character:FindFirstChild("Head") then
                        buildESP(p)
                        d = p.Character:FindFirstChild("PiddleHighlight")
                        t = p.Character:FindFirstChild("PiddleTag")
                    end
                    if d and t then
                        local r = getRole(p)
                        local c = roleColors[r] or Color3.fromRGB(255, 255, 255)
                        local tx = r or "Player"
                        local show = false
                        if espP[p] then show = true; c = Color3.fromRGB(220, 180, 255); tx = "SELECTED"
                        elseif espF.All then show = true
                        elseif espF.Gun and hasItem(p, "Gun") then show = true; c = roleColors.Gun; tx = "GUN"
                        elseif espF.NPC and r == "NPC" then show = true
                        elseif r and espF[r] then show = true end
                        if show ~= d.Enabled then
                            d.Enabled = show
                            t.Enabled = show
                        end
                        if show then
                            d.FillColor = c
                            d.OutlineColor = c
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
                        end
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not tracersOn then
        for _, line in pairs(tracers) do safe(function() line.Visible = false end) end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hd = p.Character:FindFirstChild("Head")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local point = hd or hrp
            if point then
                local v, onScreen = Cam:WorldToViewportPoint(point.Position)
                if onScreen then
                    if not tracers[p] then
                        local l = Drawing.new("Line")
                        l.Thickness = 1.5
                        l.Transparency = 0.9
                        l.Visible = false
                        tracers[p] = l
                    end
                    local line = tracers[p]
                    local r = getRole(p)
                    line.Color = roleColors[r] or Color3.fromRGB(255, 255, 255)
                    line.To = Vector2.new(v.X, v.Y)
                    line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                    line.Visible = true
                else
                    if tracers[p] then tracers[p].Visible = false end
                end
            end
        end
    end
end)

-- ===== FLING — с возвратом на место =====
local Fling = {
    Active = false, Target = nil,
    SavedCFrame = nil,
    BodyVel = nil, BodyGyro = nil,
    AntiFlingWas = nil,
}

local AF = { on = true }

local function stopFling()
    Fling.Active = false
    Fling.Target = nil
    if Fling.BodyVel then safe(function() Fling.BodyVel:Destroy() end); Fling.BodyVel = nil end
    if Fling.BodyGyro then safe(function() Fling.BodyGyro:Destroy() end); Fling.BodyGyro = nil end
    -- ВОЗВРАЩАЕМ НА МЕСТО
    local ch = LP.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if root and Fling.SavedCFrame then
        root.CFrame = Fling.SavedCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then safe(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    if Fling.AntiFlingWas ~= nil and AF then
        AF.on = Fling.AntiFlingWas
        Fling.AntiFlingWas = nil
    end
    Fling.SavedCFrame = nil
end

local function FlingTarget(target)
    if not target or not target.Character then return end
    local myChar = LP.Character
    if not myChar then return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myHum and myHum.RootPart
    if not myRoot then return end

    Fling.SavedCFrame = myRoot.CFrame
    Fling.Target = target
    Fling.Active = true
    if AF then
        Fling.AntiFlingWas = AF.on
        AF.on = false
    end
    safe(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)

    Fling.BodyVel = Instance.new("BodyVelocity")
    Fling.BodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Fling.BodyVel.Velocity = Vector3.zero
    Fling.BodyVel.P = 1250
    Fling.BodyVel.Parent = myRoot

    Fling.BodyGyro = Instance.new("BodyGyro")
    Fling.BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    Fling.BodyGyro.P = 10000
    Fling.BodyGyro.D = 500
    Fling.BodyGyro.CFrame = myRoot.CFrame
    Fling.BodyGyro.Parent = myRoot

    task.spawn(function()
        local startT = tick()
        while Fling.Active and tick() - startT < 1.5 do
            if not target.Character or not target.Character.Parent then break end
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if not tRoot then break end
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not r then break end
            local dir = (tRoot.Position - r.Position)
            local dist = dir.Magnitude
            if Fling.BodyVel and dist > 0.1 then
                Fling.BodyVel.Velocity = dir.Unit * math.min(dist * 50, 500)
            end
            if Fling.BodyGyro then
                Fling.BodyGyro.CFrame = CFrame.new(r.Position, tRoot.Position)
            end
            r.AssemblyAngularVelocity = Vector3.new(4e4, 4e4, 4e4)
            RunService.Heartbeat:Wait()
        end
        stopFling()
    end)
end

local function flingPlayer(p)
    if not p or not p.Character then return end
    if Fling.Active then stopFling(); task.wait(0.05) end
    task.spawn(function() safe(FlingTarget, p) end)
end

local function flingRole(r)
    local p = findByRole(r)
    if p then flingPlayer(p) end
end

local function flingAll()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                flingPlayer(p)
                task.wait(1.7)
            end
        end
    end)
end

local function stopFlingAll() stopFling() end

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

-- ===== EYE LASER — РАБОТАЕТ ЗА ЛЮБОГО, ПОСТОЯННЫЙ ЛУЧ =====
task.spawn(function()
    while true do
        task.wait(0.05)
        if KillFx.EyeLaser and LP.Character then
            safe(function()
                local ch = LP.Character
                local myRoot = ch:FindFirstChild("HumanoidRootPart")
                local myHead = ch:FindFirstChild("Head")
                if not (myRoot and myHead) then return end

                local camLook = Cam.CFrame.LookVector
                local best, bestDot, bestPos = nil, 0.85, nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                        local tr = p.Character:FindFirstChild("HumanoidRootPart")
                        local th = p.Character:FindFirstChildOfClass("Humanoid")
                        if tr and th and th.Health > 0 then
                            local to = (tr.Position - myHead.Position)
                            local dist = to.Magnitude
                            if dist < KillFx.EyeLaserRange then
                                local dir = to.Unit
                                local dot = dir:Dot(camLook)
                                if dot > bestDot then
                                    local rp = RaycastParams.new()
                                    rp.FilterType = Enum.RaycastFilterType.Exclude
                                    rp.FilterDescendantsInstances = {ch, p.Character}
                                    local ray = WS:Raycast(myHead.Position, to, rp)
                                    if not ray then
                                        best = p
                                        bestDot = dot
                                        bestPos = tr.Position
                                    end
                                end
                            end
                        end
                    end
                end

                -- ПОСТОЯННЫЙ ЛУЧ — обновляем существующий, не пересоздаём
                if best and bestPos then
                    KillFx.EyeLaserTarget = best
                    if not KillFx._currentBeam or not KillFx._currentBeam.Parent then
                        KillFx._currentBeam = Instance.new("Part")
                        KillFx._currentBeam.Size = Vector3.new(0.2, 0.2, 1)
                        KillFx._currentBeam.Material = Enum.Material.Neon
                        KillFx._currentBeam.Color = Color3.fromRGB(255, 30, 30)
                        KillFx._currentBeam.Anchored = true
                        KillFx._currentBeam.CanCollide = false
                        KillFx._currentBeam.CanQuery = false
                        KillFx._currentBeam.Parent = WS
                    end
                    local beam = KillFx._currentBeam
                    local midPos = (myHead.Position + bestPos) / 2
                    beam.Size = Vector3.new(0.2, 0.2, (bestPos - myHead.Position).Magnitude)
                    beam.CFrame = CFrame.new(midPos, bestPos)
                    beam.Transparency = 0

                    -- если ты Murderer — убиваем
                    if getRole(LP) == "Murderer" then
                        local k = getKnife()
                        if k and tick() - KillFx.EyeLaserCd > 0.3 then
                            local targetRoot = best.Character:FindFirstChild("HumanoidRootPart")
                            local myHum = ch:FindFirstChildOfClass("Humanoid")
                            if targetRoot and myHum then
                                local oldCF = myRoot.CFrame
                                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2)
                                if k.Parent ~= ch then myHum:EquipTool(k) end
                                safe(function() k:Activate() end)
                                local ev = k:FindFirstChild("Events")
                                local stab = ev and ev:FindFirstChild("Stab")
                                if stab then safe(function() stab:FireServer() end) end
                                task.wait(0.03)
                                myRoot.CFrame = oldCF
                                KillFx.EyeLaserCd = tick()
                            end
                        end
                    end
                else
                    if KillFx._currentBeam and KillFx._currentBeam.Parent then
                        KillFx._currentBeam.Transparency = 1
                    end
                end
            end)
        end
    end
end)

-- ===== ULTRA DODGE =====
local envParams = RaycastParams.new()
envParams.FilterType = Enum.RaycastFilterType.Exclude
local threatParams = RaycastParams.new()
threatParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateDodgeFilters()
    local ch = LP.Character
    local ignoreList = {Cam}
    if ch then table.insert(ignoreList, ch) end
    envParams.FilterDescendantsInstances = ignoreList
    threatParams.FilterDescendantsInstances = {Cam}
end

if LP.Character then updateDodgeFilters() end
LP.CharacterAdded:Connect(function() task.wait(0.5); updateDodgeFilters() end)

local function getSafePosition(origin, direction, distance)
    local ray = WS:Raycast(origin, direction * distance, envParams)
    local targetPos
    if ray then
        local hitNormal = ray.Normal
        local slideDir = direction - (direction:Dot(hitNormal) * hitNormal)
        if slideDir.Magnitude < 0.1 then
            targetPos = origin + (direction * (ray.Distance - UD.WallBuffer))
        else
            targetPos = origin + (slideDir.Unit * (distance * 0.8))
        end
    else
        targetPos = origin + (direction * distance)
    end
    local floorRay = WS:Raycast(targetPos + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), envParams)
    if not floorRay then return origin end
    return targetPos
end

local function scanForThreats()
    local ch = LP.Character
    local rootPart = ch and ch:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, "None", Vector3.new(0,0,0) end
    local myVel = rootPart.AssemblyLinearVelocity
    local scanParams = OverlapParams.new()
    scanParams.FilterDescendantsInstances = {ch, Cam}
    scanParams.FilterType = Enum.RaycastFilterType.Exclude
    local parts = WS:GetPartBoundsInRadius(rootPart.Position, UD.ScanRadius, scanParams)
    local chosenThreat, threatType = nil, "None"
    local threatVector = Vector3.new(0,0,0)
    for _, part in ipairs(parts) do
        local pvel = part.AssemblyLinearVelocity
        local speedDiff = (pvel - myVel).Magnitude
        if speedDiff > 20 then
            if not part.Anchored and pvel.Magnitude > UD.ProjectileSpeedMin then
                local vel = pvel
                local toMe = (rootPart.Position - part.Position)
                if vel.Unit:Dot(toMe.Unit) > 0.5 then
                    local predictRay = WS:Raycast(part.Position, vel * 0.2, threatParams)
                    if predictRay and predictRay.Instance and predictRay.Instance:IsDescendantOf(ch) then
                        chosenThreat = part
                        threatType = "Projectile"
                        threatVector = vel.Unit
                        break
                    end
                end
            end
        end
        local model = part.Parent
        if model and model ~= ch and model:FindFirstChild("Humanoid") then
            local otherPlr = Players:GetPlayerFromCharacter(model)
            if otherPlr and otherPlr ~= LP then
                local myRole = getRole(LP)
                local otherRole = getRole(otherPlr)
                local isEnemy = false
                if myRole == "Innocent" and otherRole == "Murderer" then isEnemy = true
                elseif myRole == "Murderer" and (otherRole == "Sheriff" or otherRole == "Hero") then isEnemy = true
                elseif myRole == "Sheriff" and otherRole == "Murderer" then isEnemy = true
                elseif myRole == "Hero" and otherRole == "Murderer" then isEnemy = true end
                if isEnemy then
                    local enemyRoot = model:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        local eHum = model.Humanoid
                        if eHum.Health > 0 then
                            local toPlayer = (rootPart.Position - enemyRoot.Position)
                            local dist = toPlayer.Magnitude
                            local facing = enemyRoot.CFrame.LookVector:Dot(-toPlayer.Unit)
                            local speed = enemyRoot.AssemblyLinearVelocity.Magnitude
                            if dist < UD.meleeDist and (facing > 0.6 or speed > 10) then
                                chosenThreat = enemyRoot
                                threatType = "Melee"
                                threatVector = (rootPart.Position - enemyRoot.Position).Unit
                            end
                        end
                    end
                end
            end
        end
    end
    return chosenThreat, threatType, threatVector
end

RunService.Heartbeat:Connect(function(dt)
    if not UD.enabled then return end
    local ch = LP.Character
    local rootPart = ch and ch:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local now = tick()
    if UD.stressLevel > 0 then
        UD.stressLevel = math.max(0, UD.stressLevel - (UD.StressDecay * dt))
    end
    local currentCooldown = (UD.stressLevel > UD.StressThreshold) and UD.OverdriveCooldown or UD.BaseCooldown
    if UD.isDodging or (now - UD.lastDodgeTime < currentCooldown) then return end
    local threat, type, dirVec = scanForThreats()
    if threat then
        UD.isDodging = true
        local mode = (UD.stressLevel > UD.StressThreshold) and "Panic" or "Normal"
        local dodgeDir = Vector3.new(0,0,0)
        if type == "Projectile" then
            local left = dirVec:Cross(Vector3.new(0, 1, 0))
            dodgeDir = (math.random() > 0.5) and left or -left
            UD.stressLevel = UD.stressLevel + 2
        elseif type == "Melee" then
            if mode == "Panic" then
                dodgeDir = -dirVec + (Vector3.new(math.random()-0.5, 0, math.random()-0.5))
            else
                local left = dirVec:Cross(Vector3.new(0, 1, 0))
                dodgeDir = dirVec + (left * 0.5)
            end
            UD.stressLevel = UD.stressLevel + 1
        end
        dodgeDir = Vector3.new(dodgeDir.X, 0, dodgeDir.Z).Unit
        local finalPos = getSafePosition(rootPart.Position, dodgeDir, UD.DodgeDist)
        if (finalPos - rootPart.Position).Magnitude > 2 then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            local lookTarget = (type == "Projectile") and (rootPart.Position + dodgeDir) or threat.Position
            rootPart.CFrame = CFrame.new(finalPos, Vector3.new(lookTarget.X, finalPos.Y, lookTarget.Z))
            UD.lastDodgeTime = now
        end
        task.wait(0.05)
        UD.isDodging = false
    end
end)

-- ===== FARM =====
local FarmState = {
    isLoaded=false, enabled=false, afkActive=false,
    bagIsFull=false, isWaitingForCoins=false,
    activeCoins={}, blacklistedCoins={}, currentTarget=nil,
    character=nil, rootPart=nil, humanoid=nil,
    linearVelocity=nil, velocityAttachment=nil,
    connections={},
}

do
    local function farmCleanup()
        for k, c in pairs(FarmState.connections) do
            safe(function() c:Disconnect() end)
            FarmState.connections[k] = nil
        end
    end
    local function farmDestroyVelocity()
        if FarmState.linearVelocity then safe(function() FarmState.linearVelocity:Destroy() end); FarmState.linearVelocity = nil end
        if FarmState.velocityAttachment then safe(function() FarmState.velocityAttachment:Destroy() end); FarmState.velocityAttachment = nil end
    end
    local function farmStopMovement()
        if FarmState.linearVelocity then
            FarmState.linearVelocity.VectorVelocity = Vector3.zero
            FarmState.linearVelocity.Enabled = false
        end
    end
    local function farmSetupVelocity()
        if not FarmState.rootPart or not FarmState.rootPart.Parent then return end
        FarmState.velocityAttachment = FarmState.rootPart:FindFirstChild("FarmAttachment")
        if not FarmState.velocityAttachment then
            FarmState.velocityAttachment = Instance.new("Attachment")
            FarmState.velocityAttachment.Name = "FarmAttachment"
            FarmState.velocityAttachment.Parent = FarmState.rootPart
        end
        FarmState.linearVelocity = FarmState.rootPart:FindFirstChild("FarmLinearVelocity")
        if not FarmState.linearVelocity then
            FarmState.linearVelocity = Instance.new("LinearVelocity")
            FarmState.linearVelocity.Name = "FarmLinearVelocity"
            FarmState.linearVelocity.Attachment0 = FarmState.velocityAttachment
            FarmState.linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            FarmState.linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            FarmState.linearVelocity.VectorVelocity = Vector3.zero
            FarmState.linearVelocity.Enabled = false
            FarmState.linearVelocity.MaxAxesForce = Vector3.new(100000, 100000, 100000)
            FarmState.linearVelocity.Parent = FarmState.rootPart
        end
    end
    local function farmIsCoin(part)
        if not part:IsA("BasePart") or FarmState.blacklistedCoins[part] then return false end
        local name = part.Name:lower()
        return name:find("coin") or name:find("cash") or name:find("money") or name:find("collect")
    end
    local function farmTrackCoins()
        FarmState.activeCoins = {}
        for _, v in ipairs(WS:GetDescendants()) do
            if farmIsCoin(v) then FarmState.activeCoins[v] = true end
        end
        FarmState.connections.coinAdd = WS.DescendantAdded:Connect(function(part)
            if farmIsCoin(part) then FarmState.activeCoins[part] = true end
        end)
        FarmState.connections.coinRemove = WS.DescendantRemoving:Connect(function(part)
            FarmState.activeCoins[part] = nil
            if FarmState.currentTarget == part then FarmState.currentTarget = nil end
        end)
    end
    local farmStartRef
    farmStartRef = function()
        farmCleanup()
        farmDestroyVelocity()
        farmSetupVelocity()
        local parts = {}
        if FarmState.character then
            for _, part in ipairs(FarmState.character:GetChildren()) do
                if part:IsA("BasePart") then table.insert(parts, part) end
            end
        end
        FarmState.connections.noclip = RunService.Stepped:Connect(function()
            if FarmState.enabled and FarmState.character and FarmState.character.Parent then
                for _, part in ipairs(parts) do
                    if part and part.Parent and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
        FarmState.connections.heartbeat = RunService.Heartbeat:Connect(function()
            if not FarmState.enabled then farmStopMovement(); return end
            local rp = FarmState.rootPart
            local hum = FarmState.humanoid
            if not rp or not rp.Parent or not hum or hum.Health <= 0 then farmStopMovement(); return end
            if FarmState.currentTarget and FarmState.currentTarget.Parent then
                local targetPos = FarmState.currentTarget.Position
                local dist = (targetPos - rp.Position).Magnitude
                if dist <= 1.2 then
                    rp.CFrame = CFrame.new(targetPos)
                    farmStopMovement()
                    FarmState.blacklistedCoins[FarmState.currentTarget] = true
                    FarmState.activeCoins[FarmState.currentTarget] = nil
                    FarmState.currentTarget = nil
                else
                    if FarmState.linearVelocity then
                        FarmState.linearVelocity.Enabled = true
                        FarmState.linearVelocity.VectorVelocity = (targetPos - rp.Position).Unit * 23
                    end
                end
            else
                farmStopMovement()
            end
        end)
        farmTrackCoins()
        FarmState.connections.targetFinder = RunService.Heartbeat:Connect(function()
            if not FarmState.enabled then return end
            local rp = FarmState.rootPart
            if not rp or not rp.Parent then return end
            local nearest, nd = nil, 1001
            for coin in pairs(FarmState.activeCoins) do
                if coin and coin.Parent and not FarmState.blacklistedCoins[coin] then
                    local d = (coin.Position - rp.Position).Magnitude
                    if d < nd then nd = d; nearest = coin end
                else
                    FarmState.activeCoins[coin] = nil
                end
            end
            FarmState.currentTarget = nearest
        end)
    end
    _G.PIDDLE_farmStart = farmStartRef
    _G.PIDDLE_farmCleanup = farmCleanup
    _G.PIDDLE_farmStop = farmStopMovement
    _G.PIDDLE_farmDestroy = farmDestroyVelocity

    local function farmLoad()
        if FarmState.isLoaded then
            FarmState.isLoaded = false
            farmCleanup()
            farmStopMovement()
            farmDestroyVelocity()
        end
        FarmState.isLoaded = true
        FarmState.character = LP.Character or LP.CharacterAdded:Wait()
        FarmState.rootPart = FarmState.character:WaitForChild("HumanoidRootPart")
        FarmState.humanoid = FarmState.character:WaitForChild("Humanoid")
        FarmState.blacklistedCoins = {}
        farmStartRef()
    end
    _G.PIDDLE_farmLoad = farmLoad

    local function farmAntiAfkLoop()
        while FarmState.afkActive and FarmState.enabled do
            task.wait(30)
            if not FarmState.afkActive or not FarmState.enabled then break end
            safe(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
    _G.PIDDLE_farmAfk = farmAntiAfkLoop

    LP.CharacterAdded:Connect(function(newChar)
        if not FarmState.isLoaded then return end
        farmCleanup()
        farmDestroyVelocity()
        FarmState.character = newChar
        FarmState.rootPart = newChar:WaitForChild("HumanoidRootPart", 10)
        FarmState.humanoid = newChar:WaitForChild("Humanoid", 10)
        FarmState.blacklistedCoins = {}
        FarmState.currentTarget = nil
        task.wait(1.5)
        if FarmState.isLoaded and FarmState.enabled then farmStartRef() end
    end)
end

-- ===== LIGHTING / WEATHER =====
local VisState = { weather = nil, weatherThread = nil, particles = {} }
local atmosphere = nil

local function ensureAtmosphere(on)
    if on and not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Density = 0.3
        atmosphere.Haze = 1.5
        atmosphere.Glare = 0.2
        atmosphere.Color = Color3.fromRGB(199,199,199)
        atmosphere.Decay = Color3.fromRGB(106,112,125)
        atmosphere.Parent = Lighting
    elseif not on and atmosphere then
        safe(function() atmosphere:Destroy() end)
        atmosphere = nil
    end
end

local function clearWeather()
    VisState.weather = nil
    for _, p in ipairs(VisState.particles) do safe(function() p:Destroy() end) end
    VisState.particles = {}
end

local function spawnWeather(kind)
    clearWeather()
    VisState.weather = kind
    local root = Instance.new("Folder")
    root.Name = "PiddleWeather"
    root.Parent = WS
    table.insert(VisState.particles, root)
    local cam = Cam
    if kind == "Rain" or kind == "Storm" then
        for i = 1, 150 do
            local p = Instance.new("Part")
            p.Size = Vector3.new(0.08, 1.2, 0.08)
            p.Anchored = true; p.CanCollide = false
            p.Color = Color3.fromRGB(180,200,255); p.Transparency = 0.3
            p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80)))
            p.Parent = root; p.CanQuery = false; p.CanTouch = false
        end
    elseif kind == "Snow" then
        for i = 1, 120 do
            local p = Instance.new("Part")
            p.Shape = Enum.PartType.Ball
            p.Size = Vector3.new(0.4,0.4,0.4)
            p.Anchored = true; p.CanCollide = false
            p.Color = Color3.fromRGB(255,255,255); p.Transparency = 0.2
            p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80)))
            p.Parent = root; p.CanQuery = false; p.CanTouch = false
        end
    elseif kind == "Leaves" then
        for i = 1, 80 do
            local p = Instance.new("Part")
            p.Size = Vector3.new(0.6,0.1,0.6)
            p.Anchored = true; p.CanCollide = false
            p.Color = Color3.fromRGB(180,90,30); p.Transparency = 0.2
            p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80))) * CFrame.Angles(math.random()*3, math.random()*3, math.random()*3)
            p.Parent = root; p.CanQuery = false; p.CanTouch = false
        end
    elseif kind == "Embers" then
        for i = 1, 120 do
            local p = Instance.new("Part")
            p.Shape = Enum.PartType.Ball
            p.Size = Vector3.new(0.2,0.2,0.2)
            p.Anchored = true; p.CanCollide = false
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(255,100,20); p.Transparency = 0.1
            p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(-20,40), math.random(-80,80)))
            p.Parent = root; p.CanQuery = false; p.CanTouch = false
        end
    end
    if VisState.weatherThread then safe(function() task.cancel(VisState.weatherThread) end) end
    VisState.weatherThread = task.spawn(function()
        while VisState.weather and VisState.weather ~= "None" do
            RunService.Heartbeat:Wait()
            local camPos = Cam.CFrame.Position
            for _, p in ipairs(root:GetChildren()) do
                if p:IsA("BasePart") and p.Parent then
                    local pos = p.Position
                    if kind == "Rain" or kind == "Storm" then
                        pos = pos + Vector3.new(0, -3, 0)
                    elseif kind == "Snow" then
                        pos = pos + Vector3.new(math.sin(tick()*2 + p.Position.X)*0.05, -0.6, 0)
                    elseif kind == "Leaves" then
                        pos = pos + Vector3.new(math.sin(tick()*1.5 + p.Position.Z)*0.1, -0.5, 0)
                    elseif kind == "Embers" then
                        pos = pos + Vector3.new(math.sin(tick()*3 + p.Position.X)*0.2, 1.5, 0)
                    end
                    if pos.Y < camPos.Y - 10 then
                        pos = camPos + Vector3.new(math.random(-80,80), math.random(30,60), math.random(-80,80))
                    end
                    p.CFrame = CFrame.new(pos)
                end
            end
        end
    end)
end

local function applyLightingPreset(name)
    if name == "Default" then
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.FogEnd = 1000; Lighting.FogColor = Color3.fromRGB(192,192,192)
        ensureAtmosphere(false)
    elseif name == "Night" then
        Lighting.Brightness = 0.5; Lighting.ClockTime = 0
        Lighting.Ambient = Color3.fromRGB(30,30,50)
        Lighting.OutdoorAmbient = Color3.fromRGB(50,50,80)
        Lighting.FogEnd = 400; Lighting.FogColor = Color3.fromRGB(20,20,40)
        ensureAtmosphere(true)
        if atmosphere then atmosphere.Density = 0.4; atmosphere.Color = Color3.fromRGB(15,15,40) end
    elseif name == "Deep Night" then
        Lighting.Brightness = 0.1; Lighting.ClockTime = 0
        Lighting.Ambient = Color3.fromRGB(5,5,15)
        Lighting.OutdoorAmbient = Color3.fromRGB(15,15,35)
        Lighting.FogEnd = 150; Lighting.FogColor = Color3.fromRGB(5,5,15)
        ensureAtmosphere(true)
        if atmosphere then atmosphere.Density = 0.6; atmosphere.Color = Color3.fromRGB(0,0,10) end
    elseif name == "Sunset" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 18
        Lighting.Ambient = Color3.fromRGB(120,60,40)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,100,70)
        Lighting.FogEnd = 600; Lighting.FogColor = Color3.fromRGB(255,150,80)
        ensureAtmosphere(true)
        if atmosphere then atmosphere.Density = 0.35; atmosphere.Color = Color3.fromRGB(255,140,80) end
    elseif name == "Dawn" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 6
        Lighting.Ambient = Color3.fromRGB(120,80,120)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,160,180)
        Lighting.FogEnd = 800; Lighting.FogColor = Color3.fromRGB(255,180,200)
        ensureAtmosphere(true)
    elseif name == "Rainy" then
        Lighting.Brightness = 1; Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(60,65,75)
        Lighting.OutdoorAmbient = Color3.fromRGB(90,95,110)
        Lighting.FogEnd = 300; Lighting.FogColor = Color3.fromRGB(80,85,95)
        ensureAtmosphere(true)
        if atmosphere then atmosphere.Density = 0.5 end
    elseif name == "Foggy" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 14
        Lighting.FogEnd = 100; Lighting.FogColor = Color3.fromRGB(200,200,200)
        ensureAtmosphere(true)
        if atmosphere then atmosphere.Density = 0.7; atmosphere.Haze = 3 end
    elseif name == "Storm" then
        Lighting.Brightness = 0.8; Lighting.ClockTime = 12
        Lighting.Ambient = Color3.fromRGB(40,45,55)
        Lighting.OutdoorAmbient = Color3.fromRGB(70,75,90)
        Lighting.FogEnd = 200; Lighting.FogColor = Color3.fromRGB(60,65,80)
        ensureAtmosphere(true)
    elseif name == "Realistic" then
        Lighting.Brightness = 2; Lighting.ClockTime = 15
        Lighting.Ambient = Color3.fromRGB(80,80,80)
        Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140)
        Lighting.FogEnd = 1e6
        ensureAtmosphere(false)
    end
end

-- ===== VOTE / TRADE =====
_G.PIDDLE_VOTE_ON = false
_G.PIDDLE_VOTE_TARGET = nil

task.spawn(function()
    local PLATFORMS = {
        Vector3.new(25.69, 507.37, 49.26),
        Vector3.new(14.10, 507.37, 51.04),
        Vector3.new(1.83, 507.37, 50.76),
    }
    while true do
        task.wait(0.1)
        if _G.PIDDLE_VOTE_ON and _G.PIDDLE_VOTE_TARGET then
            local pos = PLATFORMS[_G.PIDDLE_VOTE_TARGET]
            local ch = LP.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if hrp and pos and _G.PIDDLE_VOTE_ON then
                hrp.CFrame = CFrame.new(pos)
                for _ = 1, 3 do
                    task.wait(0.1)
                    if not _G.PIDDLE_VOTE_ON then break end
                end
                if _G.PIDDLE_VOTE_ON then safe(function() ch:BreakJoints() end) end
                for _ = 1, 3 do
                    task.wait(0.1)
                    if not _G.PIDDLE_VOTE_ON then break end
                end
            end
        end
    end
end)

local TRADE_DATA = { loaded=false, items={} }
local SUPREME_URL = "https://supremevalues.com/api/values.json"
local FALLBACK_JSON = [==[PASTE_YOUR_JSON_HERE]==]

local function parseItems(json)
    if not json or #json < 100 then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or not data or not data.d then return false end
    TRADE_DATA.items = {}
    for cat, list in pairs(data.d) do
        if type(list) == "table" then
            for _, row in ipairs(list) do
                local id = row[1] or "unknown"
                local alias = row[2] or ""
                local kind = row[3] or ""
                local year = row[4] or 0
                local val = row[5] or 0
                local displayName = id:gsub("^%l", string.upper)
                if alias ~= "" then displayName = displayName.." ("..alias..")" end
                table.insert(TRADE_DATA.items, {
                    id=id, name=displayName, raw=id, alias=alias,
                    kind=kind, year=year, value=val, category=cat,
                })
            end
        end
    end
    TRADE_DATA.loaded = true
    return true
end

local function fetchSupremeValues()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function()
            return req({ Url = SUPREME_URL, Method = "GET" })
        end)
        if ok and res and res.Body and #res.Body > 100 then
            if parseItems(res.Body) then return true end
        end
    end
    local ok, body = pcall(function() return HttpService:GetAsync(SUPREME_URL) end)
    if ok and body and #body > 100 then
        if parseItems(body) then return true end
    end
    return false
end

safe(function() parseItems(FALLBACK_JSON) end)
task.spawn(function()
    fetchSupremeValues()
    while true do
        task.wait(300)
        fetchSupremeValues()
    end
end)

local function findTradeItem(query)
    if not query or query == "" then return nil end
    local q = query:lower()
    local exact, partial
    for _, item in ipairs(TRADE_DATA.items) do
        local id = item.id:lower()
        local nm = item.name:lower()
        if id == q or nm == q then exact = item; break end
        if not partial and (id:find(q, 1, true) or nm:find(q, 1, true)) then
            partial = item
        end
    end
    return exact or partial
end
-- ============================================================
-- UI через Velvet
-- ============================================================

local Velvet = _G.Velvet
if not Velvet then
    warn("[PIDDLE] Velvet не найден")
    return
end

Velvet:SetTheme(Velvet.Themes.Midnight)

-- ============================================================
-- WATERMARK — только он и есть кнопка открытия/закрытия UI
-- ============================================================
local watermark = Velvet:CreateWatermark({
    Text = "",
    Position = UDim2.new(0, 12, 0, 12),
})

local wmBtnRef = nil

if Velvet._watermark then
    local wmFrame = Velvet._watermark
    wmFrame.Size = UDim2.new(0, 220, 0, 40)

    -- Фон watermark
    local wmBg = Instance.new("ImageLabel")
    wmBg.Name = "PiddleWmBg"
    wmBg.Size = UDim2.new(1, 0, 1, 0)
    wmBg.BackgroundTransparency = 1
    wmBg.ImageTransparency = 0.35
    wmBg.ScaleType = Enum.ScaleType.Crop
    local initialBg = ASSETS.background ~= "" and ASSETS.background or BG_LIST[CFG.bgName] or ""
    wmBg.Image = initialBg
    wmBg.ZIndex = 1
    wmBg.Parent = wmFrame

    local wmBgCorner = Instance.new("UICorner")
    wmBgCorner.CornerRadius = UDim.new(0, 20)
    wmBgCorner.Parent = wmBg

    -- Лого
    local wmLogo = Instance.new("ImageLabel")
    wmLogo.Name = "PiddleWmLogo"
    wmLogo.Size = UDim2.new(0, 26, 0, 26)
    wmLogo.Position = UDim2.new(0, 8, 0.5, -13)
    wmLogo.BackgroundTransparency = 1
    wmLogo.Image = ASSETS.logo ~= "" and ASSETS.logo or ICONS.MENU
    wmLogo.ImageColor3 = Color3.fromRGB(255,255,255)
    wmLogo.ScaleType = Enum.ScaleType.Fit
    wmLogo.ZIndex = 3
    wmLogo.Parent = wmFrame

    -- Текст PIDDLE
    local wmText = Instance.new("TextLabel")
    wmText.Name = "PiddleWmText"
    wmText.Size = UDim2.new(0, 60, 1, 0)
    wmText.Position = UDim2.new(0, 40, 0, 0)
    wmText.BackgroundTransparency = 1
    wmText.Text = "PIDDLE"
    wmText.TextColor3 = Color3.fromRGB(240,240,240)
    wmText.Font = Enum.Font.GothamBold
    wmText.TextSize = 14
    wmText.TextXAlignment = Enum.TextXAlignment.Left
    wmText.ZIndex = 3
    wmText.Parent = wmFrame

    -- FPS/PING
    local wmStats = Instance.new("TextLabel")
    wmStats.Name = "PiddleWmStats"
    wmStats.Size = UDim2.new(1, -110, 1, 0)
    wmStats.Position = UDim2.new(0, 100, 0, 0)
    wmStats.BackgroundTransparency = 1
    wmStats.Text = "--fps --ms"
    wmStats.TextColor3 = Color3.fromRGB(150,150,150)
    wmStats.Font = Enum.Font.Gotham
    wmStats.TextSize = 10
    wmStats.TextXAlignment = Enum.TextXAlignment.Right
    wmStats.ZIndex = 3
    wmStats.Parent = wmFrame

    -- Обновление FPS/PING
    local fpsBuffer = {}
    RunService.RenderStepped:Connect(function(dt)
        table.insert(fpsBuffer, dt)
        if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end
    end)
    task.spawn(function()
        while true do
            task.wait(1)
            local fps = 0
            if #fpsBuffer > 0 then
                local sum = 0
                for _, v in ipairs(fpsBuffer) do sum = sum + v end
                fps = math.round(#fpsBuffer / sum)
            end
            local ping = 0
            pcall(function() ping = math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            wmStats.Text = string.format("%d fps | %d ms", fps, ping)
        end
    end)

    -- Кликабельная кнопка ПОВЕРХ всего
    local wmBtn = Instance.new("TextButton")
    wmBtn.Name = "PiddleWmBtn"
    wmBtn.Size = UDim2.new(1, 0, 1, 0)
    wmBtn.BackgroundTransparency = 1
    wmBtn.Text = ""
    wmBtn.ZIndex = 10
    wmBtn.Parent = wmFrame
    wmBtnRef = wmBtn
end

Velvet:Notify({
    Title = "PIDDLE",
    Content = "Loaded. Click watermark to toggle UI",
    Duration = 4,
    Type = "success",
})

-- ============================================================
-- ОКНО
-- ============================================================
local window = Velvet:CreateWindow({
    Title = "PIDDLE",
    SubTitle = "MM2 | v33",
    Width = IS_MOBILE and 380 or 600,
    Height = IS_MOBILE and 420 or 460,
    TabWidth = IS_MOBILE and 52 or 150,
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleText = "PIDDLE",
    Scale = 1,
})

-- Привязываем watermark-кнопку к toggle
if wmBtnRef then
    wmBtnRef.MouseButton1Click:Connect(function()
        window:Toggle()
    end)
end

-- ============================================================
-- BACKGROUND IMAGE ЗА ОКНОМ
-- ============================================================
task.spawn(function()
    local velvetGui = nil
    for _ = 1, 20 do
        velvetGui = (gethui and gethui():FindFirstChild("VelvetUI"))
            or game:GetService("CoreGui"):FindFirstChild("VelvetUI")
            or LP.PlayerGui:FindFirstChild("VelvetUI")
        if velvetGui then break end
        task.wait(0.2)
    end
    if not velvetGui then return end

    local win = velvetGui:FindFirstChild("VelvetWindow")
    if not win then return end

    local bgHolder = Instance.new("Frame")
    bgHolder.Name = "PiddleBgHolder"
    bgHolder.Size = UDim2.new(1, 0, 1, 0)
    bgHolder.BackgroundTransparency = 1
    bgHolder.ZIndex = 0
    bgHolder.ClipsDescendants = true
    bgHolder.Parent = win

    local bg = Instance.new("ImageLabel")
    bg.Name = "PiddleBg"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundTransparency = 1
    bg.ImageTransparency = 0.35
    bg.ScaleType = Enum.ScaleType.Crop
    bg.Image = ASSETS.background ~= "" and ASSETS.background or BG_LIST[CFG.bgName] or ""
    bg.ZIndex = 0
    bg.Parent = bgHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 22)
    corner.Parent = bg

    -- сохраняем ссылку глобально для смены из Settings
    _G.PIDDLE_BG = bg
    _G.PIDDLE_WM_BG = wmFrame and wmFrame:FindFirstChild("PiddleWmBg")
end)

-- ============================================================
-- ЛОГО И КАРТИНКА В HEADER ОКНА
-- ============================================================
task.spawn(function()
    task.wait(0.5)
    local velvetGui = (gethui and gethui():FindFirstChild("VelvetUI"))
        or game:GetService("CoreGui"):FindFirstChild("VelvetUI")
        or LP.PlayerGui:FindFirstChild("VelvetUI")
    if not velvetGui then return end
    local win = velvetGui:FindFirstChild("VelvetWindow")
    if not win then return end
    local header = win:FindFirstChild("Header")
    if not header then return end

    -- Убираем дефолтный logoDot если есть
    local logoDot = header:FindFirstChild("logoDot")
    if logoDot then logoDot.Visible = false end
    local logoHalo = header:FindFirstChild("logoHalo")
    if logoHalo then logoHalo.Visible = false end

    -- Лого в header (большая картинка слева)
    local headerImg = Instance.new("ImageLabel")
    headerImg.Name = "PiddleHeaderIcon"
    headerImg.Size = UDim2.new(0, 30, 0, 30)
    headerImg.Position = UDim2.new(0, 12, 0.5, -15)
    headerImg.BackgroundTransparency = 1
    headerImg.Image = ASSETS.header_icon ~= "" and ASSETS.header_icon
        or (ASSETS.logo ~= "" and ASSETS.logo or ICONS.MENU)
    headerImg.ImageColor3 = Color3.fromRGB(255,255,255)
    headerImg.ScaleType = Enum.ScaleType.Fit
    headerImg.ZIndex = 250
    headerImg.Parent = header

    -- Сдвигаем заголовок Velvet вправо чтобы не наложился
    for _, child in ipairs(header:GetChildren()) do
        if child:IsA("TextLabel") then
            if child.Position.X.Offset < 30 then
                child.Position = UDim2.new(0, 50, child.Position.Y.Scale, child.Position.Y.Offset)
            end
        end
    end

    _G.PIDDLE_HEADER_ICON = headerImg
end)

-- ============================================================
-- ВКЛАДКИ
-- ============================================================

-- HOME
local tabHome = window:AddTab("Home", ICONS.HOME)
local secHomeMain = tabHome:AddSection("General")
secHomeMain:AddButton({ Text = "Save Config", Callback = function()
    saveCFG()
    Velvet:Notify({ Title = "PIDDLE", Content = "Config saved", Duration = 2, Type = "success" })
end })
secHomeMain:AddButton({ Text = "Reset Character", Callback = function()
    if LP.Character then safe(function() LP.Character:BreakJoints() end) end
end })
secHomeMain:AddButton({ Text = "Rejoin Server", Callback = function()
    safe(function() TeleportService:Teleport(game.PlaceId, LP) end)
end })
secHomeMain:AddButton({ Text = "Close UI", Callback = function() window:Hide() end })

-- COMBAT
local tabCombat = window:AddTab("Combat", ICONS.TARGET)

local secMurder = tabCombat:AddSection("Murderer")
secMurder:AddToggle("kill_aura", {
    Text = "Kill Aura (весь сервер)",
    Default = false,
    Callback = function(v) killAuraOn = v end,
})
secMurder:AddButton({ Text = "Kill All (без ТП)", Callback = function() killAllRun() end })
secMurder:AddToggle("auto_knife", { Text = "Auto-Knife", Default = false, Callback = function(v) autoKnife = v end })
secMurder:AddToggle("auto_throw", { Text = "Auto-Throw", Default = false, Callback = function(v) autoThrow = v end })

local secSheriff = tabCombat:AddSection("Sheriff / Hero")
secSheriff:AddToggle("aimlock", { Text = "Aimlock", Default = false, Callback = function(v) aimMurd = v end })
secSheriff:AddToggle("auto_shoot", {
    Text = "Auto-Shoot (Predict точный)",
    Default = false,
    Callback = function(v) autoShoot = v end,
})
secSheriff:AddToggle("shoot_walls", {
    Text = "Shoot Through Walls",
    Default = CFG.shootThroughWalls,
    Callback = function(v) shootThroughWalls = v; CFG.shootThroughWalls = v; saveCFG() end,
})
secSheriff:AddToggle("predict", {
    Text = "Predict Movement",
    Default = CFG.predictMovement,
    Callback = function(v) predictMovement = v; CFG.predictMovement = v; saveCFG() end,
})

local secKillFx = tabCombat:AddSection("Kill Features")
secKillFx:AddToggle("eye_laser", {
    Text = "Eye Laser (работает за любого)",
    Default = false,
    Callback = function(v) KillFx.EyeLaser = v end,
})
secKillFx:AddSlider("eye_laser_range", {
    Text = "Eye Laser Range",
    Min = 50, Max = 500, Default = 200,
    Callback = function(v) KillFx.EyeLaserRange = v end,
})
secKillFx:AddToggle("run_kill", {
    Text = "Run Kill (Murderer)",
    Default = false,
    Callback = function(v) KillFx.RunKill = v end,
})
secKillFx:AddSlider("run_kill_range", {
    Text = "Run Kill Range",
    Min = 1, Max = 20, Default = 4,
    Callback = function(v) KillFx.RunKillRange = v end,
})

local secAntiAim = tabCombat:AddSection("Anti-Aim")
secAntiAim:AddToggle("anti_aim", {
    Text = "Anti-Aim (Spoof Position)",
    Default = false,
    Callback = function(v) antiAimOn = v end,
})
secAntiAim:AddSlider("anti_aim_speed", {
    Text = "Anti-Aim Speed",
    Min = 1, Max = 50, Default = 10,
    Callback = function(v) antiAimSpeed = 1 / v end,
})

-- VISUALS
local tabVisual = window:AddTab("Visuals", ICONS.EYE)

local secESP = tabVisual:AddSection("ESP")
secESP:AddToggle("esp_all", { Text = "ESP All", Default = false, Callback = function(v) espF.All = v end })
secESP:AddToggle("esp_murd", { Text = "ESP Murderer", Default = false, Callback = function(v) espF.Murderer = v end })
secESP:AddToggle("esp_sher", { Text = "ESP Sheriff", Default = false, Callback = function(v) espF.Sheriff = v end })
secESP:AddToggle("esp_inno", { Text = "ESP Innocent", Default = false, Callback = function(v) espF.Innocent = v end })
secESP:AddToggle("esp_npc", { Text = "ESP NPC", Default = false, Callback = function(v) espF.NPC = v end })
secESP:AddToggle("esp_gun", { Text = "ESP Gun", Default = false, Callback = function(v) espF.Gun = v end })
secESP:AddToggle("esp_name", { Text = "ESP NameTag", Default = false, Callback = function(v) espF.NameTag = v end })
secESP:AddToggle("esp_dist", { Text = "ESP Distance", Default = false, Callback = function(v) espF.Distance = v end })
secESP:AddToggle("tracers", { Text = "Tracers", Default = false, Callback = function(v) tracersOn = v end })

local secAura = tabVisual:AddSection("Player Aura")
secAura:AddToggle("player_aura", {
    Text = "Enable Player Aura",
    Default = false,
    Callback = function(v) playerAuraOn = v end,
})
secAura:AddColorPicker("aura_color", {
    Text = "Aura Color",
    Default = Color3.fromRGB(255, 100, 130),
    Callback = function(c)
        playerAuraColor = c
        if playerAuraPart then playerAuraPart.Color = c end
        if playerAuraLight then playerAuraLight.Color = c end
    end,
})

local secPreset = tabVisual:AddSection("Lighting Presets")
for _, n in ipairs({"Night","Deep Night","Sunset","Dawn","Rainy","Foggy","Storm","Realistic","Default"}) do
    secPreset:AddButton({ Text = n, Callback = function() applyLightingPreset(n) end })
end

local secWeather = tabVisual:AddSection("Weather")
secWeather:AddButton({ Text = "None", Callback = function() clearWeather() end })
secWeather:AddButton({ Text = "Rain", Callback = function() spawnWeather("Rain") end })
secWeather:AddButton({ Text = "Snow", Callback = function() spawnWeather("Snow") end })
secWeather:AddButton({ Text = "Leaves", Callback = function() spawnWeather("Leaves") end })
secWeather:AddButton({ Text = "Embers", Callback = function() spawnWeather("Embers") end })
secWeather:AddButton({ Text = "Storm", Callback = function() spawnWeather("Storm") end })

local secLight = tabVisual:AddSection("Lighting")
secLight:AddToggle("fullbright", { Text = "Fullbright", Default = false, Callback = function(o)
    Lighting.Brightness = o and 3 or 2
    Lighting.OutdoorAmbient = o and Color3.new(1,1,1) or Color3.fromRGB(128,128,128)
end })
secLight:AddToggle("nofog", { Text = "No Fog", Default = false, Callback = function(o)
    Lighting.FogEnd = o and 1e6 or 1000
end })
secLight:AddSlider("time_day", { Text = "Time of Day", Min = 0, Max = 24, Default = 14, Callback = function(v) Lighting.ClockTime = v end })
secLight:AddSlider("brightness", { Text = "Brightness", Min = 0, Max = 5, Default = 2, Callback = function(v) Lighting.Brightness = v end })
secLight:AddSlider("fov", { Text = "FOV", Min = 50, Max = 130, Default = 70, Callback = function(v) Cam.FieldOfView = v end })

-- PLAYERS
local tabPlayers = window:AddTab("Players", ICONS.UTIL)
local secPlayers = tabPlayers:AddSection("Player List")
local playerSel = secPlayers:AddPlayerSelector("target_player", { Text = "Select Target" })

secPlayers:AddButton({ Text = "Fling Selected (с возвратом)", Callback = function()
    local list = playerSel:GetPlayers()
    if #list > 0 then flingPlayer(list[1]) end
end })
secPlayers:AddButton({ Text = "TP to Selected", Callback = function()
    local list = playerSel:GetPlayers()
    if #list > 0 and list[1].Character and LP.Character then
        local tr = list[1].Character:FindFirstChild("HumanoidRootPart")
        local lr = LP.Character:FindFirstChild("HumanoidRootPart")
        if tr and lr then lr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
    end
end })

-- FARM
local tabFarm = window:AddTab("Farm", ICONS.COIN)
local secFarm = tabFarm:AddSection("Auto Farm")
secFarm:AddToggle("auto_farm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(state)
        FarmState.enabled = state
        if state then
            if not FarmState.isLoaded then _G.PIDDLE_farmLoad() end
            _G.PIDDLE_farmStart()
        else
            _G.PIDDLE_farmStop()
            _G.PIDDLE_farmCleanup()
        end
    end,
})
secFarm:AddToggle("anti_afk", {
    Text = "Anti-AFK",
    Default = false,
    Callback = function(state)
        FarmState.afkActive = state
        if state and FarmState.enabled then task.spawn(_G.PIDDLE_farmAfk) end
    end,
})
secFarm:AddToggle("auto_gun", { Text = "Auto Get Gun", Default = false, Callback = function(v) autoGun = v end })

-- TELEPORT
local tabTp = window:AddTab("Teleport", ICONS.TP)
local secTp = tabTp:AddSection("Teleport")
secTp:AddButton({ Text = "TP Murderer", Callback = function()
    local p = findMurderer()
    if p and p.Character and LP.Character then
        local pr = p.Character:FindFirstChild("HumanoidRootPart")
        local lr = LP.Character:FindFirstChild("HumanoidRootPart")
        if pr and lr then lr.CFrame = pr.CFrame + Vector3.new(0, 3, 0) end
    end
end })
secTp:AddButton({ Text = "TP Sheriff", Callback = function()
    local p = findSheriff()
    if p and p.Character and LP.Character then
        local pr = p.Character:FindFirstChild("HumanoidRootPart")
        local lr = LP.Character:FindFirstChild("HumanoidRootPart")
        if pr and lr then lr.CFrame = pr.CFrame + Vector3.new(0, 3, 0) end
    end
end })

-- FLING
local tabFling = window:AddTab("Fling", ICONS.FLING)
local secFling = tabFling:AddSection("Fling")
secFling:AddButton({ Text = "FLING Murderer", Callback = function() flingRole("Murderer") end })
secFling:AddButton({ Text = "FLING Sheriff", Callback = function() flingRole("Sheriff") end })
secFling:AddButton({ Text = "FLING All", Callback = function() flingAll() end })
secFling:AddButton({ Text = "Stop", Callback = function() stopFlingAll() end })
secFling:AddToggle("touch_fling", { Text = "Touch Fling", Default = false, Callback = function(v) setTouchFling(v) end })

-- MOVEMENT
local tabMove = window:AddTab("Movement", ICONS.FLY)
local secMove = tabMove:AddSection("Move")
secMove:AddToggle("keep_speed", { Text = "Keep Speed", Default = false, Callback = function(v) keepSpeed = v end })
secMove:AddSlider("speed", { Text = "Speed", Min = 16, Max = 200, Default = dSpeed, Callback = function(v) dSpeed = v; CFG.speed = v end })
secMove:AddToggle("keep_jump", { Text = "Keep Jump", Default = false, Callback = function(v) keepJump = v end })
secMove:AddSlider("jump", { Text = "Jump", Min = 50, Max = 300, Default = dJump, Callback = function(v) dJump = v; CFG.jump = v end })
secMove:AddToggle("fly", {
    Text = "Fly",
    Default = false,
    Callback = function(o)
        flying = o
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if flyBV then safe(function() flyBV:Destroy() end); flyBV = nil end
        if flyBG then safe(function() flyBG:Destroy() end); flyBG = nil end
        if o and hrp then
            flyBV = Instance.new("BodyVelocity")
            flyBV.Parent = hrp
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Velocity = Vector3.new(0, 0, 0)
            flyBG = Instance.new("BodyGyro")
            flyBG.Parent = hrp
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1000
        end
    end,
})
secMove:AddToggle("noclip", { Text = "Noclip", Default = false, Callback = function(o) noclip = o end })
secMove:AddToggle("spin", { Text = "Spin", Default = false, Callback = function(o) spinOn = o end })
secMove:AddSlider("spin_speed", { Text = "Spin Speed", Min = 1, Max = 500, Default = 30, Callback = function(v) spinSpd = v end })

-- DODGE
local tabDodge = window:AddTab("Dodge", ICONS.SHIELD)
local secDodge = tabDodge:AddSection("Ultra Dodge")
secDodge:AddToggle("ud_enabled", { Text = "Enable", Default = false, Callback = function(o) UD.enabled = o end })
secDodge:AddSlider("ud_scan", { Text = "Scan Radius", Min = 5, Max = 40, Default = UD.ScanRadius, Callback = function(v) UD.ScanRadius = v end })
secDodge:AddSlider("ud_dist", { Text = "Dodge Distance", Min = 5, Max = 30, Default = UD.DodgeDist, Callback = function(v) UD.DodgeDist = v end })
secDodge:AddSlider("ud_panic", { Text = "Panic Threshold", Min = 1, Max = 10, Default = UD.StressThreshold, Callback = function(v) UD.StressThreshold = v end })

-- MISC
local tabMisc = window:AddTab("Misc", ICONS.UTIL)
local secMisc = tabMisc:AddSection("Auto")
secMisc:AddToggle("auto_respawn", { Text = "Auto-Respawn", Default = false, Callback = function(o) autoRespawn = o end })
secMisc:AddToggle("fast_respawn", { Text = "Fast-Respawn", Default = false, Callback = function(o) fastRespawn = o end })
secMisc:AddToggle("anti_void", { Text = "Anti-Void", Default = false, Callback = function(o) antiVoid = o end })
secMisc:AddToggle("anti_fling", { Text = "Anti-Fling", Default = true, Callback = function(o) AF.on = o end })

-- PLAYER
local tabPlayer = window:AddTab("Player", ICONS.HAT)
local secPacks = tabPlayer:AddSection("Animation Packs")
for _, n in ipairs({"Ninja","Zombie","Mage","Pirate","Robot"}) do
    secPacks:AddButton({ Text = n, Callback = function()
        selectedPack = n
        CFG.selectedPack = n
        saveCFG()
        applyPack(n)
    end })
end

local secEmotes = tabPlayer:AddSection("Emotes")
local EMOTES = {
    Wave="507770239", Point="507770453", Dance="507771019", Laugh="507770818",
    Cheer="507770677", Salute="507770965", Shrug="507770647", Facepalm="507770585",
    Bow="507770603", Flex="507770720", Frog="507770674", Zombie="507770762",
    Pray="507770612", Sit="507770750", Lay="507770758", Sword="507770858",
    Kick="507770863", Dab="248263260", Floss="5002593297", DefaultDance="180435571",
}
local curEmote
for emoteName, id in pairs(EMOTES) do
    secEmotes:AddButton({ Text = emoteName, Callback = function()
        safe(function() if curEmote then curEmote:Stop() end end)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not h then return end
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://" .. id
        local ok, tr = pcall(function() return h:LoadAnimation(a) end)
        if ok and tr then
            tr.Priority = Enum.AnimationPriority.Action4
            tr.Looped = true
            tr:Play()
            curEmote = tr
        end
    end })
end

local secOutfit = tabPlayer:AddSection("Outfits")
secOutfit:AddButton({ Text = "Korblox ON", Callback = function() CFG.korbloxOn = true; saveCFG(); applyKorbloxNow() end })
secOutfit:AddButton({ Text = "Korblox OFF", Callback = function() CFG.korbloxOn = false; saveCFG(); removeKorbloxNow() end })
secOutfit:AddButton({ Text = "Headless ON", Callback = function() CFG.headlessOn = true; saveCFG(); applyHeadlessNow() end })
secOutfit:AddButton({ Text = "Headless OFF", Callback = function() CFG.headlessOn = false; saveCFG(); removeHeadlessNow() end })
secOutfit:AddButton({ Text = "China Hat ON", Callback = function() CFG.chinaHatOn = true; saveCFG(); applyChinaHat() end })
secOutfit:AddButton({ Text = "China Hat OFF", Callback = function() CFG.chinaHatOn = false; saveCFG(); removeChinaHat() end })

-- VOTE
local tabVote = window:AddTab("Vote", ICONS.GUN)
local secVote = tabVote:AddSection("Vote Duper")
local mapDropdown = secVote:AddDropdown("map_select", {
    Text = "Select Map",
    Values = {"Map 1", "Map 2", "Map 3"},
    Default = "Map 1",
})
secVote:AddButton({ Text = "Start Duper", Callback = function()
    local sel = mapDropdown:Get()
    local idx = (sel == "Map 1" and 1) or (sel == "Map 2" and 2) or 3
    _G.PIDDLE_VOTE_TARGET = idx
    _G.PIDDLE_VOTE_ON = true
    Velvet:Notify({ Title = "Vote Duper", Content = "Started: " .. sel, Duration = 2, Type = "success" })
end })
secVote:AddButton({ Text = "Stop Duper", Callback = function()
    _G.PIDDLE_VOTE_ON = false
    Velvet:Notify({ Title = "Vote Duper", Content = "Stopped", Duration = 2, Type = "info" })
end })

-- TRADE
local tabTrade = window:AddTab("Trade", ICONS.UTIL)
local secTrade = tabTrade:AddSection("Trade Calculator")
local myTotal, hisTotal = 0, 0
local myItems, hisItems = {}, {}
local myLbl = secTrade:AddLabel("Your Total: 0")
local hisLbl = secTrade:AddLabel("Their Total: 0")
local searchInput = secTrade:AddInput("trade_search", { Text = "Item Name", Placeholder = "Search..." })
secTrade:AddButton({ Text = "Add My", Callback = function()
    local item = findTradeItem(searchInput:Get())
    if item then
        table.insert(myItems, item)
        myTotal = 0
        for _, v in ipairs(myItems) do myTotal = myTotal + (v.value or 0) end
        myLbl:Set("Your Total: " .. myTotal)
        searchInput:Set("")
    end
end })
secTrade:AddButton({ Text = "Add His", Callback = function()
    local item = findTradeItem(searchInput:Get())
    if item then
        table.insert(hisItems, item)
        hisTotal = 0
        for _, v in ipairs(hisItems) do hisTotal = hisTotal + (v.value or 0) end
        hisLbl:Set("Their Total: " .. hisTotal)
        searchInput:Set("")
    end
end })
secTrade:AddButton({ Text = "Clear", Callback = function()
    myItems = {}; hisItems = {}; myTotal = 0; hisTotal = 0
    myLbl:Set("Your Total: 0")
    hisLbl:Set("Their Total: 0")
end })

-- MUSIC
local tabMusic = window:AddTab("Music", ICONS.SPEED)
local secMusic = tabMusic:AddSection("Music")
local bgSound = Instance.new("Sound")
bgSound.Name = "PiddleMusic"
bgSound.Volume = CFG.volume / 100
bgSound.Looped = true
bgSound.Parent = SoundService

local TRACKS = {
    ["Chill"] = "rbxassetid://1837879082",
    ["Synth"] = "rbxassetid://1836318003",
    ["Trap"]  = "rbxassetid://1837842597",
    ["Phonk"] = "rbxassetid://9046731150",
}
local orderTracks = {}
for k in pairs(TRACKS) do table.insert(orderTracks, k) end
table.sort(orderTracks)
local curTrack = 1
local function playIdx(i)
    i = ((i - 1) % #orderTracks) + 1
    curTrack = i
    bgSound.SoundId = TRACKS[orderTracks[i]]
    bgSound:Play()
end

secMusic:AddButton({ Text = "Play", Callback = function()
    if bgSound.SoundId == "" then playIdx(curTrack) else bgSound:Play() end
end })
secMusic:AddButton({ Text = "Pause", Callback = function() bgSound:Pause() end })
secMusic:AddButton({ Text = "Stop", Callback = function() bgSound:Stop() end })
secMusic:AddButton({ Text = "Next", Callback = function() playIdx(curTrack + 1) end })
secMusic:AddButton({ Text = "Prev", Callback = function() playIdx(curTrack - 1) end })
secMusic:AddSlider("volume", {
    Text = "Volume",
    Min = 0, Max = 100, Default = CFG.volume,
    Callback = function(v) bgSound.Volume = v / 100; CFG.volume = v end,
})

-- SETTINGS
local tabSettings = window:AddTab("Settings", ICONS.NOCLIP)
local secSettings = tabSettings:AddSection("Settings")

secSettings:AddDropdown("theme_select", {
    Text = "Theme",
    Values = {"Midnight", "Catppuccin", "TokyoNight", "Dracula", "Nord", "Rose", "Cyberpunk", "Monochrome"},
    Default = "Midnight",
    Callback = function(v)
        if Velvet.Themes[v] then
            Velvet:SetTheme(Velvet.Themes[v])
            Velvet:Notify({ Title = "Theme", Content = "Changed to " .. v, Duration = 2, Type = "info" })
        end
    end,
})

local bgNames = {}
for k, _ in pairs(BG_LIST) do table.insert(bgNames, k) end
table.sort(bgNames)

secSettings:AddDropdown("bg_select", {
    Text = "Background",
    Values = bgNames,
    Default = CFG.bgName or "Default",
    Callback = function(v)
        CFG.bgName = v
        saveCFG()
        local img = BG_LIST[v] or ""
        if _G.PIDDLE_BG then _G.PIDDLE_BG.Image = img end
        if _G.PIDDLE_WM_BG then _G.PIDDLE_WM_BG.Image = img end
    end,
})

secSettings:AddSlider("bg_transparency", {
    Text = "BG Transparency",
    Min = 0, Max = 100, Default = 35,
    Callback = function(v)
        if _G.PIDDLE_BG then _G.PIDDLE_BG.ImageTransparency = v / 100 end
        if _G.PIDDLE_WM_BG then _G.PIDDLE_WM_BG.ImageTransparency = math.min(0.6, v / 100 + 0.1) end
    end,
})

secSettings:AddSlider("ui_scale", {
    Text = "UI Scale",
    Min = 50, Max = 150, Default = 100,
    Callback = function(v) window:SetScale(v / 100) end,
})

secSettings:AddToggle("header_icon_toggle", {
    Text = "Show Header Icon",
    Default = true,
    Callback = function(v)
        if _G.PIDDLE_HEADER_ICON then _G.PIDDLE_HEADER_ICON.Visible = v end
    end,
})

secSettings:AddButton({ Text = "Save Config", Callback = function() saveCFG() end })

task.delay(1, function()
    Velvet:Notify({
        Title = "PIDDLE",
        Content = "Click watermark to toggle UI",
        Duration = 5,
        Type = "info",
    })
end)


--[[
    DOGUI + PIDDLE ADDON MERGE NOTES
    AnimationImageAssetId / EmotionImageAssetId are placeholders you can fill in.
    Map preview: watches the game's existing map-vote UI and keeps its map thumbnails
    visible; it does not invent thumbnail IDs when the game provides none.
]]
local DOG_ANIMATION_IMAGE_ASSET_ID = 0 -- <-- вставь asset id картинки анимаций
local DOG_EMOTION_IMAGE_ASSET_ID = 0   -- <-- вставь asset id картинки эмоций

-- Find and refresh thumbnails from the game's own voting cards when the vote UI appears.
-- Existing ImageLabels are preserved; the script never guesses arbitrary map asset IDs.
task.spawn(function()
    local seen = setmetatable({}, { __mode = "k" })
    local function isVoteRelated(obj)
        local s = string.lower(obj.Name .. " " .. (obj:IsA("TextLabel") or obj:IsA("TextButton") and obj.Text or ""))
        return s:find("vote", 1, true) or s:find("map", 1, true)
    end
    local function inspect(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and not seen[obj] then
                local p = obj.Parent
                local related = false
                for _ = 1, 5 do
                    if not p then break end
                    if isVoteRelated(p) then related = true break end
                    p = p.Parent
                end
                if related and obj.Image ~= "" then
                    seen[obj] = true
                    -- Reassigning the game's own image prompts Roblox to load it if needed.
                    local image = obj.Image
                    task.defer(function()
                        if obj.Parent then obj.Image = image end
                    end)
                end
            end
        end
    end
    while not Library.Unloaded do
        pcall(function()
            local pg = LP:FindFirstChildOfClass("PlayerGui")
            if pg then inspect(pg) end
            local core = game:GetService("CoreGui")
            inspect(core)
        end)
        task.wait(0.5)
    end
end)

warn("[PIDDLE] Loaded")
