--[[
    DogUI + PIDDLE MM2 v33  |  Full Integration
    - Все функции PIDDLE перенесены в DogUI
    - Анимации: поле ASSET для картинки (вставь свой rbxassetid)
    - Эмоции: поле ASSET для картинки (вставь свой rbxassetid)
    - Голосование: карты сами подгружают картинки (MapVoteImages)
]]

--============================================================
-- DOGUI CORE (без изменений, полный)
--============================================================
local Library = {
    Version = "1.0.0",
    Flags = {},
    Options = {},
    Windows = {},
    LowerCase = true,
    Connections = {},
    Unloaded = false,
}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local IsTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled

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

local function tl(text) return Library.LowerCase and string.lower(tostring(text)) or tostring(text) end
local function Tween(obj, info, props) local t = TweenService:Create(obj, info or TWEEN_FAST, props); t:Play(); return t end
local function New(class, props, children)
    local inst = Instance.new(class)
    if class == "TextButton" or class == "ImageButton" then inst.AutoButtonColor = false end
    if class == "Frame" or class == "TextButton" or class == "ScrollingFrame" or class == "ImageLabel" or class == "ImageButton" then inst.BorderSizePixel = 0 end
    for k, v in pairs(props or {}) do if k ~= "Parent" then inst[k] = v end end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end
local function Corner(parent, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 4), Parent = parent }) end
local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", { Color = color or Theme.Stroke, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end
local function Padding(parent, l, t, r, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0), Parent = parent })
end
local function List(parent, pad, dir, halign, valign)
    return New("UIListLayout", { Padding = UDim.new(0, pad or 0), FillDirection = dir or Enum.FillDirection.Vertical, HorizontalAlignment = halign or Enum.HorizontalAlignment.Left, VerticalAlignment = valign or Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent })
end
local function Connect(signal, fn) local c = signal:Connect(fn); table.insert(Library.Connections, c); return c end
local function Label(props)
    local base = { BackgroundTransparency = 1, Font = Theme.Font, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, RichText = false }
    for k, v in pairs(props) do base[k] = v end
    return New("TextLabel", base)
end
local function IsPress(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
local function IsMove(input) return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch end
local function Clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function Round(v, step) if not step or step <= 0 then return v end; return math.floor(v / step + 0.5) * step end
local function FormatNumber(v, step)
    if step and step < 1 then local decimals = math.max(0, math.ceil(-math.log10(step))); return string.format("%." .. decimals .. "f", v) end
    return tostring(math.floor(v + 0.5))
end

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
    if isfile and isfile(fileName) then local ok, res = pcall(getAsset, fileName); if ok then return res end end
    return ""
end

local function GetGuiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    ok, h = pcall(function() return game:GetService("CoreGui") end)
    if ok and h then local test = pcall(function() return h.Name end); if test then return h end end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function Protect(gui) pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end) end

local function MakeDraggable(handle, target, getScale, onClick)
    local dragging, startInput, startPos, startMouse, moved
    Connect(handle.InputBegan, function(input)
        if IsPress(input) then
            dragging = true; moved = 0; startMouse = input.Position; startPos = target.Position
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

-- Container
local Container = {}
Container.__index = Container
function Container:_register(element, row, name)
    element.Row = row
    element.SearchName = string.lower(name or "")
    table.insert(self.Elements, element)
    if element.Flag then Library.Flags[element.Flag] = element.Value; Library.Options[element.Flag] = element end
    return element
end
function Container:_row(height)
    self._order = (self._order or 0) + 1
    return New("Frame", { Size = UDim2.new(1, 0, 0, height or 22), BackgroundTransparency = 1, LayoutOrder = self._order, Parent = self.Holder })
end

local function Fire(element, ...)
    if element.Flag then Library.Flags[element.Flag] = element.Value end
    local ok, err = pcall(element.Callback, ...)
    if not ok then warn("[DogUI] callback error (" .. tostring(element.Name) .. "): " .. tostring(err)) end
    for _, fn in ipairs(element._changed) do pcall(fn, ...) end
end

-- Label
function Container:AddLabel(cfg)
    if type(cfg) == "string" then cfg = { Name = cfg } end
    local el = { Type = "Label", Name = cfg.Name or "label", _changed = {}, Callback = function() end }
    local row = self:_row(cfg.Height or 18)
    local lbl = Label({ Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0), Text = cfg.Raw and cfg.Name or tl(cfg.Name or "label"), TextColor3 = cfg.Color or Theme.Dim, TextSize = cfg.TextSize or 10, TextWrapped = true, Parent = row })
    function el:SetText(t) lbl.Text = cfg.Raw and t or tl(t) end
    return self:_register(el, row, el.Name)
end

-- Divider
function Container:AddDivider()
    local el = { Type = "Divider", Name = "", _changed = {}, Callback = function() end }
    local row = self:_row(8)
    New("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0.5, 0), BackgroundColor3 = Theme.Stroke, Parent = row })
    return self:_register(el, row, "")
end

-- Button
function Container:AddButton(cfg)
    cfg = cfg or {}
    local el = { Type = "Button", Name = cfg.Name or "button", Callback = cfg.Callback or function() end, _changed = {} }
    local row = self:_row(26)
    local btn = New("TextButton", { Size = UDim2.new(1, -12, 0, 20), Position = UDim2.new(0, 6, 0.5, -10), BackgroundColor3 = Theme.Box, Text = "", Parent = row })
    Corner(btn, 4)
    local st = Stroke(btn, Theme.Stroke)
    local txt = Label({ Size = UDim2.fromScale(1, 1), Text = tl(el.Name), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dim, Parent = btn })
    Connect(btn.MouseEnter, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Row }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Text }) end)
    Connect(btn.MouseLeave, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Box }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Dim }) end)
    Connect(btn.MouseButton1Down, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Accent }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Check }) end)
    Connect(btn.MouseButton1Up, function() Tween(btn, TWEEN_FAST, { BackgroundColor3 = Theme.Row }); Tween(txt, TWEEN_FAST, { TextColor3 = Theme.Text }) end)
    Connect(btn.MouseButton1Click, function() Fire(el) end)
    function el:SetText(t) txt.Text = tl(t) end
    return self:_register(el, row, el.Name)
end

-- Toggle
local function DrawCheck(box)
    local short = New("Frame", { Size = UDim2.fromOffset(2, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4, 7.5), Rotation = -45, BackgroundColor3 = Theme.Check, BackgroundTransparency = 1, Parent = box })
    local long = New("Frame", { Size = UDim2.fromOffset(2, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7.5, 5.5), Rotation = 45, BackgroundColor3 = Theme.Check, BackgroundTransparency = 1, Parent = box })
    return short, long
end
local function DrawDots(parent)
    local holder = New("Frame", { Size = UDim2.fromOffset(12, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = parent })
    local dots = {}
    for i = 0, 2 do
        local d = New("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(i * 5, 0.5), BackgroundColor3 = Theme.Dimmer, Parent = holder })
        Corner(d, 1); table.insert(dots, d)
    end
    return dots
end
function Container:AddToggle(cfg)
    cfg = cfg or {}
    local el = { Type = "Toggle", Name = cfg.Name or "toggle", Flag = cfg.Flag, Value = cfg.Default and true or false, Callback = cfg.Callback or function() end, _changed = {} }
    local row = self:_row(22)
    local hit = New("TextButton", { Size = UDim2.new(1, cfg.Options and -26 or 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row })
    local box = New("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 8, 0.5, -6), BackgroundColor3 = Theme.Box, Parent = row })
    Corner(box, 3)
    local boxStroke = Stroke(box, Theme.Stroke)
    local c1, c2 = DrawCheck(box)
    local lbl = Label({ Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(28, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
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
        self.Value = v; Render(true)
        if not silent then Fire(self, v) elseif self.Flag then Library.Flags[self.Flag] = v end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    Connect(hit.MouseButton1Click, function() el:Set(not el.Value) end)
    Connect(hit.MouseEnter, function() if not el.Value then Tween(lbl, TWEEN_FAST, { TextColor3 = Theme.Text }) end end)
    Connect(hit.MouseLeave, function() if not el.Value then Tween(lbl, TWEEN_FAST, { TextColor3 = Theme.Dim }) end end)
    Render(false)
    if cfg.Options then
        local dotsBtn = New("TextButton", { Size = UDim2.fromOffset(22, 18), Position = UDim2.new(1, -26, 0.5, -9), BackgroundTransparency = 1, Text = "", Parent = row })
        local dots = DrawDots(dotsBtn)
        Connect(dotsBtn.MouseEnter, function() for _, d in ipairs(dots) do Tween(d, TWEEN_FAST, { BackgroundColor3 = Theme.Text }) end end)
        Connect(dotsBtn.MouseLeave, function() for _, d in ipairs(dots) do Tween(d, TWEEN_FAST, { BackgroundColor3 = Theme.Dimmer }) end end)
        local popup
        Connect(dotsBtn.MouseButton1Click, function()
            if not popup then popup = self.Window:_createPopup(el.Name); if typeof(cfg.Options) == "function" then cfg.Options(popup) end; el.Popup = popup end
            self.Window:_openPopup(popup, dotsBtn)
        end)
        el.Options = cfg.Options
    end
    return self:_register(el, row, el.Name)
end

-- Slider
function Container:AddSlider(cfg)
    cfg = cfg or {}
    local min, max = cfg.Min or 0, cfg.Max or 100
    local step = cfg.Increment or 1
    local el = { Type = "Slider", Name = cfg.Name or "slider", Flag = cfg.Flag, Value = Clamp(cfg.Default or min, min, max), Callback = cfg.Callback or function() end, _changed = {} }
    local suffix = cfg.Suffix or ""
    local row = self:_row(32)
    Label({ Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(8, 2), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local valueLbl = Label({ Size = UDim2.new(0, 50, 0, 16), Position = UDim2.new(1, -58, 0, 2), TextXAlignment = Enum.TextXAlignment.Right, Text = "", TextColor3 = Theme.Text, TextSize = 10, Parent = row })
    local hit = New("TextButton", { Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(6, 18), BackgroundTransparency = 1, Text = "", Parent = row })
    local track = New("Frame", { Size = UDim2.new(1, -4, 0, 4), Position = UDim2.new(0, 2, 0.5, -2), BackgroundColor3 = Theme.Box, Parent = hit })
    Corner(track, 2); Stroke(track, Theme.Stroke)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, Parent = track }); Corner(fill, 2)
    local knob = New("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Theme.Accent, Parent = track }); Corner(knob, 4)
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
        self.Value = v; Render(true)
        if not silent then Fire(self, v) elseif self.Flag then Library.Flags[self.Flag] = v end
    end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    local dragging = false
    local function FromInput(input)
        local a = Clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        el:Set(min + (max - min) * a)
    end
    Connect(hit.InputBegan, function(input) if IsPress(input) then dragging = true; self.Window:_lockDrag(true); Tween(knob, TWEEN_FAST, { Size = UDim2.fromOffset(10, 10) }); FromInput(input) end end)
    Connect(UIS.InputEnded, function(input) if dragging and IsPress(input) then dragging = false; self.Window:_lockDrag(false); Tween(knob, TWEEN_FAST, { Size = UDim2.fromOffset(8, 8) }) end end)
    Connect(UIS.InputChanged, function(input) if dragging and IsMove(input) then FromInput(input) end end)
    Render(false)
    return self:_register(el, row, el.Name)
end

-- Dropdown
function Container:AddDropdown(cfg)
    cfg = cfg or {}
    local values = cfg.Values or {}
    local multi = cfg.Multi
    local el = { Type = "Dropdown", Name = cfg.Name or "dropdown", Flag = cfg.Flag, Values = values, Callback = cfg.Callback or function() end, _changed = {}, Multi = multi }
    if multi then el.Value = {}; for _, v in ipairs(cfg.Default or {}) do el.Value[v] = true end else el.Value = cfg.Default end
    self._order = (self._order or 0) + 1
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self._order, Parent = self.Holder })
    List(row, 2, nil, Enum.HorizontalAlignment.Center)
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", LayoutOrder = 1, Parent = row })
    Label({ Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = head })
    local box = New("Frame", { Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0.5, 2, 0.5, -9), BackgroundColor3 = Theme.Box, Parent = head })
    Corner(box, 4); Stroke(box, Theme.Stroke)
    local sel = Label({ Size = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(6, 0), TextColor3 = Theme.Text, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = box })
    local arrow = Label({ Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -14, 0.5, -6), Text = ">", Rotation = 90, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dim, TextSize = 10, Font = Theme.FontBold, Parent = box })
    local list = New("Frame", { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Box, Visible = false, LayoutOrder = 2, Parent = row })
    list.Position = UDim2.fromOffset(6, 0); Corner(list, 4); Stroke(list, Theme.Stroke); List(list, 0); Padding(list, 0, 2, 0, 2)
    local buttons = {}; local open = false
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
            Connect(b.MouseLeave, function() local on = multi and el.Value[v] or (not multi and el.Value == v); l.TextColor3 = on and Theme.Accent or Theme.Dim end)
            Connect(b.MouseButton1Click, function()
                if multi then el.Value[v] = not el.Value[v] or nil
                else el.Value = v; open = false; list.Visible = false; Tween(arrow, TWEEN_FAST, { Rotation = 90 }) end
                Render(); Fire(el, el.Value)
            end)
        end
        Render()
    end
    function el:Set(v, silent)
        if multi then self.Value = {}; for k, on in pairs(v) do if type(k) == "number" then self.Value[on] = true elseif on then self.Value[k] = true end end
        else self.Value = v end
        Render()
        if not silent then Fire(self, self.Value) elseif self.Flag then Library.Flags[self.Flag] = self.Value end
    end
    function el:Get() return self.Value end
    function el:SetValues(newValues) self.Values = newValues; Build() end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    Connect(head.MouseButton1Click, function() open = not open; list.Visible = open; Tween(arrow, TWEEN_FAST, { Rotation = open and -90 or 90 }) end)
    Build()
    return self:_register(el, row, el.Name)
end

-- Keybind
local KeyNames = { [Enum.KeyCode.LeftShift] = "LShift", [Enum.KeyCode.RightShift] = "RShift", [Enum.KeyCode.LeftControl] = "LCtrl", [Enum.KeyCode.RightControl] = "RCtrl", [Enum.KeyCode.LeftAlt] = "LAlt", [Enum.KeyCode.RightAlt] = "RAlt" }
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
    local el = { Type = "Keybind", Name = cfg.Name or "keybind", Flag = cfg.Flag, Value = cfg.Default, Mode = cfg.Mode or "Toggle", State = false, Callback = cfg.Callback or function() end, Changed = cfg.OnBindChanged or function() end, _changed = {} }
    local row = self:_row(22)
    Label({ Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local btn = New("TextButton", { Size = UDim2.fromOffset(52, 16), Position = UDim2.new(1, -58, 0.5, -8), BackgroundColor3 = Theme.Box, Text = "", Parent = row })
    Corner(btn, 4); Stroke(btn, Theme.Stroke)
    local txt = Label({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 9, Text = "", TextColor3 = Theme.Text, Parent = btn })
    local listening = false
    local function Render() txt.Text = listening and "..." or tl(KeyToString(el.Value)) end
    function el:Set(k, silent) self.Value = k; listening = false; Render(); if self.Flag then Library.Flags[self.Flag] = k end; if not silent then pcall(self.Changed, k) end end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    Connect(btn.MouseButton1Click, function() listening = true; Render() end)
    Connect(UIS.InputBegan, function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then el:Set(nil) else el:Set(input.KeyCode) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then el:Set(input.UserInputType) end
            return
        end
        if processed or not el.Value then return end
        if input.KeyCode == el.Value or input.UserInputType == el.Value then
            if el.Mode == "Toggle" then el.State = not el.State; Fire(el, el.State)
            elseif el.Mode == "Hold" then el.State = true; Fire(el, true)
            else Fire(el, true) end
        end
    end)
    Connect(UIS.InputEnded, function(input) if el.Mode == "Hold" and el.Value and (input.KeyCode == el.Value or input.UserInputType == el.Value) then el.State = false; Fire(el, false) end end)
    Render()
    return self:_register(el, row, el.Name)
end

-- Textbox
function Container:AddTextbox(cfg)
    cfg = cfg or {}
    local el = { Type = "Textbox", Name = cfg.Name or "textbox", Flag = cfg.Flag, Value = cfg.Default or "", Callback = cfg.Callback or function() end, _changed = {} }
    local row = self:_row(28)
    Label({ Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = row })
    local holder = New("Frame", { Size = UDim2.new(0.6, -10, 0, 20), Position = UDim2.new(0.4, 2, 0.5, -10), BackgroundColor3 = Theme.Box, Parent = row })
    Corner(holder, 4); local st = Stroke(holder, Theme.Stroke)
    local box = New("TextBox", { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(5, 0), BackgroundTransparency = 1, Text = el.Value, PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = Theme.Dimmer, TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = holder })
    function el:Set(v, silent) self.Value = tostring(v); box.Text = self.Value; if not silent then Fire(self, self.Value) elseif self.Flag then Library.Flags[self.Flag] = self.Value end end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed, fn) end
    Connect(box.Focused, function() Tween(st, TWEEN_FAST, { Color = Theme.Accent }) end)
    Connect(box.FocusLost, function()
        Tween(st, TWEEN_FAST, { Color = Theme.Stroke })
        if cfg.Numeric and not tonumber(box.Text) then box.Text = el.Value return end
        el.Value = box.Text; Fire(el, el.Value)
    end)
    return self:_register(el, row, el.Name)
end

-- ColorPicker
function Container:AddColorPicker(cfg)
    cfg = cfg or {}
    local el = { Type = "ColorPicker", Name = cfg.Name or "color", Flag = cfg.Flag, Value = cfg.Default or Color3.fromRGB(255, 255, 255), Callback = cfg.Callback or function() end, _changed = {} }
    local h, s, v = el.Value:ToHSV()
    self._order = (self._order or 0) + 1
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self._order, Parent = self.Holder })
    List(row, 2, nil, Enum.HorizontalAlignment.Center)
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", LayoutOrder = 1, Parent = row })
    Label({ Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(el.Name), TextColor3 = Theme.Dim, Parent = head })
    local swatch = New("Frame", { Size = UDim2.fromOffset(22, 12), Position = UDim2.new(1, -30, 0.5, -6), BackgroundColor3 = el.Value, Parent = head })
    Corner(swatch, 3); Stroke(swatch, Theme.Stroke)
    local panel = New("Frame", { Size = UDim2.new(1, -12, 0, 78), Position = UDim2.fromOffset(6, 0), BackgroundColor3 = Theme.Box, Visible = false, LayoutOrder = 2, Parent = row })
    Corner(panel, 4); Stroke(panel, Theme.Stroke)
    local sv = New("TextButton", { Size = UDim2.new(1, -40, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Text = "", ClipsDescendants = true, Parent = panel })
    Corner(sv, 3)
    local white = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
    New("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
    local svCursor = New("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = sv })
    Corner(svCursor, 3); Stroke(svCursor, Color3.new(0, 0, 0), 1)
    local hue = New("TextButton", { Size = UDim2.new(0, 14, 1, -12), Position = UDim2.new(1, -22, 0, 6), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", Parent = panel })
    Corner(hue, 3)
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)), ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)), ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)) }), Parent = hue })
    local hueCursor = New("Frame", { Size = UDim2.new(1, 4, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = hue })
    Corner(hueCursor, 2); Stroke(hueCursor, Color3.new(0, 0, 0), 1)
    local function Render(fire)
        el.Value = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = el.Value
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        if fire then Fire(el, el.Value) elseif el.Flag then Library.Flags[el.Flag] = el.Value end
    end
    function el:Set(c, silent) h, s, v = c:ToHSV(); Render(not silent) end
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

-- Section
local function NewSection(tab, cfg)
    local sec = setmetatable({ Name = cfg.Name or "section", Elements = {}, Window = tab.Window, Tab = tab, _order = 0, Collapsed = false }, Container)
    local column = (cfg.Side == "Right" or cfg.Side == 2) and tab.RightColumn or tab.LeftColumn
    sec.Frame = New("Frame", { Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Section, LayoutOrder = (#tab.Sections + 1), Parent = column })
    Corner(sec.Frame, 5); Stroke(sec.Frame, Theme.StrokeSoft); List(sec.Frame, 0)
    local head = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.SectionHead, Text = "", LayoutOrder = 0, Parent = sec.Frame })
    Corner(head, 5)
    New("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Theme.SectionHead, Parent = head })
    Label({ Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(sec.Name), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 10, Parent = head })
    local arrow = Label({ Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -20, 0.5, -7), Text = ">", Rotation = -90, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dim, Font = Theme.FontBold, TextSize = 10, Parent = head })
    sec.Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, ClipsDescendants = false, Parent = sec.Frame })
    List(sec.Holder, 0); Padding(sec.Holder, 0, 3, 0, 4)
    Connect(head.MouseButton1Click, function() sec.Collapsed = not sec.Collapsed; sec.Holder.Visible = not sec.Collapsed; Tween(arrow, TWEEN_FAST, { Rotation = sec.Collapsed and 90 or -90 }) end)
    function sec:SetCollapsed(state) self.Collapsed = state; self.Holder.Visible = not state; arrow.Rotation = state and 90 or -90 end
    table.insert(tab.Sections, sec)
    return sec
end

-- Window
local Window = {}
Window.__index = Window
function Window:_lockDrag(state) self._dragLocked = state end
function Window:_createPopup(title)
    local popup = setmetatable({ Name = title, Elements = {}, Window = self, _order = 0 }, Container)
    popup.Frame = New("Frame", { Size = UDim2.fromOffset(150, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Section, Visible = false, ZIndex = 50, Parent = self.PopupLayer })
    Corner(popup.Frame, 5); Stroke(popup.Frame, Theme.Stroke); List(popup.Frame, 0)
    local head = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Theme.SectionHead, LayoutOrder = 0, Parent = popup.Frame })
    Corner(head, 5)
    New("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Theme.SectionHead, Parent = head })
    Label({ Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0), Text = tl(title), Font = Theme.FontBold, TextSize = 10, Parent = head })
    popup.Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = popup.Frame })
    List(popup.Holder, 0); Padding(popup.Holder, 0, 3, 0, 4)
    popup.Frame.DescendantAdded:Connect(function(d) if d:IsA("GuiObject") then d.ZIndex = 50 + (d.ZIndex > 1 and d.ZIndex - 1 or 0) end end)
    return popup
end
function Window:_closePopup() if self._activePopup then self._activePopup.Frame.Visible = false; self._activePopup = nil end end
function Window:_openPopup(popup, anchorButton)
    if self._activePopup == popup then self:_closePopup(); return end
    self:_closePopup()
    local scale = self.UIScale.Scale
    local rel = (anchorButton.AbsolutePosition - self.Main.AbsolutePosition) / scale
    local x = Clamp(rel.X - 150 + anchorButton.AbsoluteSize.X / scale, 4, self.Size.X - 154)
    local y = rel.Y + anchorButton.AbsoluteSize.Y / scale + 2
    popup.Frame.Position = UDim2.fromOffset(x, y)
    popup.Frame.Visible = true
    self._activePopup = popup
end
function Window:SetSearch(text) text = string.lower(text or ""); self.SearchBox.Text = text; self:_applySearch() end
function Window:_applySearch()
    local q = string.lower(self.SearchBox.Text or "")
    local tab = self.CurrentTab
    if not tab then return end
    for _, sec in ipairs(tab.Sections) do
        local any = false
        for _, el in ipairs(sec.Elements) do
            local match = q == "" or (el.SearchName ~= "" and el.SearchName:find(q, 1, true) ~= nil)
            if el.Type == "Divider" then match = q == "" end
            el.Row.Visible = match; any = any or match
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
        task.delay(0.16, function() if not self.Visible and self.Root then self.Root.Visible = false end end)
    end
end
function Window:Toggle() self:SetVisible(not self.Visible) end

local function BuildTab(window, cfg, parentTab)
    local tab = { Name = cfg.Name or "tab", Subtitle = cfg.Subtitle or "", Window = window, Sections = {}, Parent = parentTab, Children = {}, Collapsed = false }
    local container = parentTab and parentTab.ChildHolder or window.TabList
    tab.Group = New("Frame", { Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = (#container:GetChildren()), Parent = container })
    List(tab.Group, 1)
    local indent = parentTab and 14 or 0
    local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", LayoutOrder = 0, Parent = tab.Group })
    tab.Button = btn
    tab.Bg = New("Frame", { Size = UDim2.new(1, -10, 1, -2), Position = UDim2.fromOffset(5, 1), BackgroundColor3 = Theme.Row, BackgroundTransparency = 1, Parent = btn }); Corner(tab.Bg, 5)
    tab.Bar = New("Frame", { Size = UDim2.fromOffset(2, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = btn }); Corner(tab.Bar, 1)
    local iconHolder = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 14 + indent, 0.5, -7), BackgroundTransparency = 1, Parent = btn })
    if cfg.Icon and cfg.Icon ~= "" then
        New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ResolveImage(cfg.Icon), ImageColor3 = Theme.Dim, Parent = iconHolder })
        tab.IconRing = New("UIStroke", { Thickness = 0, Parent = iconHolder })
    else
        local ring = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, Parent = iconHolder }); Corner(ring, parentTab and 5 or 3)
        tab.IconRing = Stroke(ring, Theme.Dimmer, 1.2)
    end
    tab.NameLabel = Label({ Size = UDim2.new(1, -60 - indent, 0, 14), Position = UDim2.new(0, 36 + indent, 0, 5), Text = tl(tab.Name), TextColor3 = Theme.Dim, TextSize = 11, Font = Theme.Font, Parent = btn })
    Label({ Size = UDim2.new(1, -60 - indent, 0, 11), Position = UDim2.new(0, 36 + indent, 0, 18), Text = tl(tab.Subtitle), TextColor3 = Theme.Dimmer, TextSize = 8, Font = Theme.FontLight, Parent = btn })
    tab.ChildHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Visible = true, Parent = tab.Group })
    List(tab.ChildHolder, 1)
    tab.Arrow = nil
    function tab:_enableChevron()
        if self.Arrow then return end
        self.Arrow = Label({ Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -22, 0.5, -7), Text = ">", Rotation = -90, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Dimmer, Font = Theme.FontBold, TextSize = 10, Parent = self.Button })
        local chev = New("TextButton", { Size = UDim2.fromOffset(26, 36), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1, Text = "", Parent = self.Button })
        Connect(chev.MouseButton1Click, function() self.Collapsed = not self.Collapsed; self.ChildHolder.Visible = not self.Collapsed; Tween(self.Arrow, TWEEN_FAST, { Rotation = self.Collapsed and 90 or -90 }) end)
    end
    tab.Page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Dimmer, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = window.PageHolder })
    Padding(tab.Page, 0, 0, 4, 6)
    tab.LeftColumn = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tab.Page })
    List(tab.LeftColumn, 6)
    tab.RightColumn = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), Position = UDim2.new(0.5, 3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tab.Page })
    List(tab.RightColumn, 6)
    function tab:AddSection(c) if type(c) == "string" then c = { Name = c } end; return NewSection(self, c) end
    function tab:AddSubTab(c) local sub = BuildTab(window, c, self); table.insert(self.Children, sub); self:_enableChevron(); return sub end
    Connect(btn.MouseEnter, function() if window.CurrentTab ~= tab then Tween(tab.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Text }) end end)
    Connect(btn.MouseLeave, function() if window.CurrentTab ~= tab then Tween(tab.NameLabel, TWEEN_FAST, { TextColor3 = Theme.Dim }) end end)
    Connect(btn.MouseButton1Click, function() window:SelectTab(tab) end)
    table.insert(window.Tabs, tab)
    if not window.CurrentTab then window:SelectTab(tab) end
    return tab
end
function Window:AddTab(cfg) if type(cfg) == "string" then cfg = { Name = cfg } end; return BuildTab(self, cfg, nil) end

function Library:Notify(cfg)
    cfg = type(cfg) == "string" and { Text = cfg } or (cfg or {})
    local gui = self.Gui
    if not gui then return end
    if not self.NotifyHolder then
        self.NotifyHolder = New("Frame", { Size = UDim2.fromOffset(230, 400), Position = UDim2.new(1, -240, 0, 14), BackgroundTransparency = 1, Parent = gui })
        List(self.NotifyHolder, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right)
    end
    local duration = cfg.Duration or 4
    local slot = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = self.NotifyHolder })
    local card = New("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(240, 0), BackgroundColor3 = Theme.Window, Parent = slot })
    Corner(card, 6); Stroke(card, Theme.Stroke)
    local bar = New("Frame", { Size = UDim2.new(0, 2, 1, -14), Position = UDim2.fromOffset(6, 7), BackgroundColor3 = cfg.Color or Theme.Accent, Parent = card }); Corner(bar, 1)
    Label({ Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(16, 6), Text = tl(cfg.Title or "notification"), Font = Theme.FontBold, Parent = card })
    Label({ Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(16, 23), Text = tl(cfg.Text or ""), TextColor3 = Theme.Dim, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
    local life = New("Frame", { Size = UDim2.new(1, -12, 0, 1), Position = UDim2.new(0, 6, 1, -3), BackgroundColor3 = Theme.Dimmer, Parent = card })
    Tween(card, TWEEN_MED, { Position = UDim2.fromOffset(0, 0) })
    Tween(life, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 1) })
    task.delay(duration, function() if card.Parent then Tween(card, TWEEN_MED, { Position = UDim2.fromOffset(240, 0) }); task.wait(0.25); slot:Destroy() end end)
end

Library.ConfigFolder = "DogUI"
local function Serialize()
    local data = {}
    for flag, el in pairs(Library.Options) do
        local v = el.Value
        if el.Type == "ColorPicker" then data[flag] = { _t = "c", v.R, v.G, v.B }
        elseif el.Type == "Keybind" then data[flag] = { _t = "k", v and v.Name or false, v and tostring(v.EnumType) or false }
        elseif el.Type ~= "Button" and el.Type ~= "Label" then data[flag] = v end
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
                if type(v) == "table" and v._t == "c" then el:Set(Color3.new(v[1], v[2], v[3]))
                elseif type(v) == "table" and v._t == "k" then
                    if v[1] then local enum = v[2] == "Enum.UserInputType" and Enum.UserInputType or Enum.KeyCode; el:Set(enum[v[1]]) else el:Set(nil) end
                else el:Set(v) end
            end)
        end
    end
    return true
end
function Library:ListConfigs()
    local out = {}
    if listfiles and isfolder and isfolder(self.ConfigFolder) then
        for _, f in ipairs(listfiles(self.ConfigFolder)) do local n = f:match("([^/\\]+)%.json$"); if n then table.insert(out, n) end end
    end
    return out
end

local function BuildNetwork(parent, count, maxDist)
    local layer = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0, Parent = parent })
    local points, lines = {}, {}
    local maxLines = count * 3
    for i = 1, count do points[i] = { x = math.random(), y = math.random(), vx = (math.random() - 0.5) * 0.05, vy = (math.random() - 0.5) * 0.05 } end
    for i = 1, maxLines do lines[i] = New("Frame", { Size = UDim2.fromOffset(0, 1), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Line, BackgroundTransparency = 1, Visible = false, ZIndex = 0, Parent = layer }) end
    local acc = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < 1 / 30 then return end
        local step = acc; acc = 0
        if not layer.Parent or not layer.Visible or layer.AbsoluteSize.X == 0 then return end
        local w, h = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
        for _, p in ipairs(points) do
            p.x += p.vx * step; p.y += p.vy * step
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
        for k = li + 1, maxLines do if lines[k].Visible then lines[k].Visible = false end end
    end)
    table.insert(Library.Connections, conn)
    return layer
end

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    if not self.Gui then
        local gui = New("ScreenGui", { Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
        Protect(gui); gui.Parent = GetGuiParent(); self.Gui = gui
    end
    local win = setmetatable({ Tabs = {}, Visible = true, Library = self, _dragLocked = false }, Window)
    local size = cfg.Size or Vector2.new(400, 404)
    local sidebarW = cfg.SidebarWidth or 116
    win.Size = size
    win.Root = New("Frame", { Name = "Root", Size = UDim2.fromOffset(size.X, size.Y), AnchorPoint = Vector2.new(0.5, 0.5), Position = cfg.Position or UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = self.Gui })
    win.UIScale = New("UIScale", { Scale = 1, Parent = win.Root })
    win.Main = New("CanvasGroup", { Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Window, GroupTransparency = 0, Parent = win.Root })
    Corner(win.Main, 8); Stroke(win.Main, Theme.Stroke, 1)
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
    win.Sidebar = New("Frame", { Size = UDim2.new(0, sidebarW, 1, 0), BackgroundColor3 = Theme.Sidebar, Parent = win.Main })
    New("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.StrokeSoft, Parent = win.Sidebar })
    local logoHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1, Parent = win.Sidebar })
    win.Logo = New("ImageLabel", { Size = UDim2.fromOffset(cfg.LogoSize or 56, cfg.LogoSize or 56), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), BackgroundTransparency = 1, Image = ResolveImage(cfg.Logo), ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1), ScaleType = Enum.ScaleType.Fit, Parent = logoHolder })
    if not cfg.Logo or win.Logo.Image == "" then Label({ Size = UDim2.fromScale(1, 1), Text = "D", Font = Theme.FontBold, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center, Parent = logoHolder }) end
    win.TabScroll = New("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -78 - 46), Position = UDim2.fromOffset(0, 78), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = win.Sidebar })
    win.TabList = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = win.TabScroll })
    List(win.TabList, 1)
    local profile = New("Frame", { Size = UDim2.new(1, -12, 0, 36), Position = UDim2.new(0, 6, 1, -42), BackgroundColor3 = Theme.Section, Parent = win.Sidebar })
    Corner(profile, 6); Stroke(profile, Theme.StrokeSoft)
    local avatar = New("ImageLabel", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Box, Parent = profile }); Corner(avatar, 12)
    task.spawn(function()
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if ok and avatar.Parent then avatar.Image = img end
    end)
    Label({ Size = UDim2.new(1, -38, 0, 14), Position = UDim2.fromOffset(34, 5), Text = cfg.DisplayName or LocalPlayer.DisplayName, TextSize = 9, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })
    Label({ Size = UDim2.new(1, -38, 0, 12), Position = UDim2.fromOffset(34, 18), Text = "@" .. (cfg.UserName or LocalPlayer.Name), TextSize = 8, TextColor3 = Theme.Dimmer, Font = Theme.FontLight, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })
    win.Content = New("Frame", { Size = UDim2.new(1, -sidebarW, 1, 0), Position = UDim2.fromOffset(sidebarW, 0), BackgroundTransparency = 1, Parent = win.Main })
    win.Network = BuildNetwork(win.Content, cfg.NetworkPoints or 9, cfg.NetworkDistance or 150)
    local search = New("Frame", { Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Section, Parent = win.Content })
    Corner(search, 6); local searchStroke = Stroke(search, Theme.StrokeSoft)
    win.SearchBox = New("TextBox", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "", TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = search })
    local mag = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -24, 0.5, -7), BackgroundTransparency = 1, Parent = search })
    local lens = New("Frame", { Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Parent = mag }); Corner(lens, 5)
    local lensStroke = Stroke(lens, Theme.Dim, 1.3)
    New("Frame", { Size = UDim2.fromOffset(1.5, 5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(11, 11), Rotation = -45, BackgroundColor3 = Theme.Dim, Parent = mag })
    Connect(win.SearchBox.Focused, function() Tween(searchStroke, TWEEN_FAST, { Color = Theme.Dimmer }); Tween(lensStroke, TWEEN_FAST, { Color = Theme.Accent }) end)
    Connect(win.SearchBox.FocusLost, function() Tween(searchStroke, TWEEN_FAST, { Color = Theme.StrokeSoft }); Tween(lensStroke, TWEEN_FAST, { Color = Theme.Dim }) end)
    Connect(win.SearchBox:GetPropertyChangedSignal("Text"), function() win:_applySearch() end)
    win.PageHolder = New("Frame", { Size = UDim2.new(1, -12, 1, -46), Position = UDim2.fromOffset(6, 40), BackgroundTransparency = 1, Parent = win.Content })
    win.PopupLayer = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = win.Main })
    local outside = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 49, Visible = true, Parent = win.PopupLayer })
    outside.Visible = false
    local oldOpen = win._openPopup
    function win:_openPopup(popup, anchor) oldOpen(self, popup, anchor); outside.Visible = self._activePopup ~= nil end
    local oldClose = win._closePopup
    function win:_closePopup() oldClose(self); outside.Visible = false end
    Connect(outside.MouseButton1Click, function() win:_closePopup() end)
    MakeDraggable(logoHolder, win.Root, function() return win.UIScale.Scale end)
    MakeDraggable(win.Sidebar, win.Root, function() return win.UIScale.Scale end)
    local dragStrip = New("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1, Parent = win.Content })
    MakeDraggable(dragStrip, win.Root, function() return win.UIScale.Scale end)
    if cfg.Banner then
        local bw, bh = cfg.BannerSize and cfg.BannerSize.X or 104, cfg.BannerSize and cfg.BannerSize.Y or 104
        local bannerImg = ResolveImage(cfg.Banner)
        win.BannerGui = New("ImageLabel", { Size = UDim2.fromOffset(bw, bh), Position = UDim2.new(0, cfg.BannerOffset and cfg.BannerOffset.X or 6, 0, cfg.BannerOffset and cfg.BannerOffset.Y or -(bh - 26)), BackgroundTransparency = 1, Image = bannerImg, ScaleType = Enum.ScaleType.Fit, ZIndex = 20, Parent = win.Root })
    end
    if cfg.ToggleButton ~= false then
        local fb = New("ImageButton", { Name = "FloatingToggle", Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(0.5, 0.5), Position = cfg.TogglePosition or UDim2.new(1, -28, 0.5, 0), BackgroundColor3 = Theme.Window, BackgroundTransparency = 0.1, Image = "", Parent = self.Gui })
        Corner(fb, 18); Stroke(fb, Theme.Stroke)
        New("ImageLabel", { Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Image = ResolveImage(cfg.ToggleIcon or cfg.Logo), ImageColor3 = Color3.new(1, 1, 1), Parent = fb })
        MakeDraggable(fb, fb, nil, function() win:Toggle() end)
        win.FloatingButton = fb
    end
    local key = cfg.Keybind or Enum.KeyCode.RightShift
    Connect(UIS.InputBegan, function(input, processed) if processed then return end; if input.KeyCode == key then win:Toggle() end end)
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

--============================================================
-- PIDDLE MM2 — ВСЕ ФУНКЦИИ (полный перенос)
--============================================================

local WS = workspace
local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function safe(fn, ...) local ok, res = pcall(fn, ...); if ok then return res end; return nil end

-- ASSETS для кастомных картинок (вставь свои rbxassetid)
local ASSETS = {
    logo         = 0, -- фото 1 (собачка-контур)
    header_icon  = 0, -- фото 3 (собачка в шляпе)
    background   = 0, -- фон окна
}

-- ИКОНКИ ВКЛАДОК
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

-- ЗАГРУЗКА КАРТИНОК ДЛЯ АНИМАЦИЙ (вставь свои asset id)
local ANIMATION_IMAGES = {
    Ninja = "",
    Zombie = "",
    Mage = "",
    Pirate = "",
    Robot = "",
    Default = "",
}

-- ЗАГРУЗКА КАРТИНОК ДЛЯ ЭМОЦИЙ (вставь свои asset id)
local EMOTE_IMAGES = {
    Wave = "",
    Point = "",
    Dance = "",
    Laugh = "",
    Cheer = "",
    Salute = "",
    Shrug = "",
    Facepalm = "",
    Bow = "",
    Flex = "",
    Frog = "",
    Zombie = "",
    Pray = "",
    Sit = "",
    Lay = "",
    Sword = "",
    Kick = "",
    Dab = "",
    Floss = "",
    DefaultDance = "",
}

-- КАРТИНКИ КАРТ ДЛЯ ГОЛОСОВАНИЯ (вставь свои asset id для каждой карты)
-- Формат: [номер_карты] = "rbxassetid://XXX"
local MAP_VOTE_IMAGES = {
    [1] = "", -- Map 1
    [2] = "", -- Map 2
    [3] = "", -- Map 3
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
        if not plr:FindFirstChild("PlayerGui") and not plr:FindFirstChild("Backpack") then return "NPC" end
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
    if not k then local bp = LP:FindFirstChild("Backpack"); if bp then k = bp:FindFirstChild("Knife") end end
    return k
end
local function getGun()
    local ch = LP.Character
    if not ch then return nil end
    local g = ch:FindFirstChild("Gun")
    if not g then local bp = LP:FindFirstChild("Backpack"); if bp then g = bp:FindFirstChild("Gun") end end
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

task.spawn(function() while true do task.wait(1.5); safe(fetchRoles) end end)

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

-- KILL AURA
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
                local best, bd = nil, 10000
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

-- KILL ALL
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
task.spawn(function() while true do task.wait(0.1); if autoKnife and LP.Character then local k = getKnife(); if k and k.Parent == LP.Character then safe(function() k:Activate() end) end end end end)
task.spawn(function()
    while true do
        task.wait(0.15)
        if autoThrow and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local k = getKnife()
                if k and k.Parent ~= LP.Character then local hum = LP.Character:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(k) end end
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

-- AUTO SHOOT
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
        if g.Parent ~= ch then if hum then hum:EquipTool(g) end; return end
        local sh = g:FindFirstChild("Shoot")
        if not sh then return end
        local m = findMurderer()
        if not m or not m.Character then return end
        local mh = m.Character:FindFirstChildOfClass("Humanoid")
        local mr = m.Character:FindFirstChild("HumanoidRootPart")
        local mHead = m.Character:FindFirstChild("Head")
        if not mh or mh.Health <= 0 or not mr then return end
        local targetPart = mHead or mr
        local aimPos = targetPart.Position
        if predictMovement then
            local vel = targetPart.AssemblyLinearVelocity
            local dist = (aimPos - root.Position).Magnitude
            local bulletSpeed = 900
            local flyTime = dist / bulletSpeed
            local lead = flyTime + PING
            aimPos = aimPos + vel * lead
            if mh.FloorMaterial == Enum.Material.Air then aimPos = aimPos + Vector3.new(0, -0.5 * WS.Gravity * lead * lead, 0) end
            aimPos = aimPos + Vector3.new(0, 0.5, 0)
        end
        local at = root:FindFirstChild("GunRaycastAttachment")
        local origin = at and at.WorldCFrame or root.CFrame
        if shootThroughWalls then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {ch, m.Character}
            local candidates = { aimPos + Vector3.new(0, 3, 0), aimPos + Vector3.new(3, 2, 0), aimPos + Vector3.new(-3, 2, 0), aimPos + Vector3.new(0, 5, 0), aimPos }
            for _, c in ipairs(candidates) do
                local r2 = WS:Raycast(c, aimPos - c, params)
                if not r2 then origin = CFrame.new(c, aimPos); break end
            end
        end
        sh:FireServer(origin, CFrame.new(aimPos))
    end)
end)

-- AIMLOCK
RunService.RenderStepped:Connect(function()
    if not aimMurd then return end
    if not isSheriffOrHero() then return end
    if not hasItem(LP, "Gun") then return end
    local m = findMurderer()
    if m and m.Character then
        local hd = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
        if hd then Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, hd.Position), 0.25) end
    end
end)

-- ANTI-AIM
task.spawn(function()
    while true do
        task.wait(antiAimSpeed)
        if antiAimOn and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local randomVel = Vector3.new(math.random(-15, 15), math.random(-5, 5), math.random(-15, 15))
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + randomVel
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-30, 30)), 0)
            end
        end
    end
end)

-- MOVEMENT
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
            if hrp then spinA = spinA + spinSpd; hrp.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, math.rad(spinA), 0) end
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
        if IS_MOBILE and h and h.MoveDirection.Magnitude > 0 then mv = Cam.CFrame.LookVector * (h.MoveDirection:Dot(Cam.CFrame.LookVector) > -0.2 and 1 or -1) end
        flyBV.Velocity = mv * 60
        flyBG.CFrame = Cam.CFrame
    end)
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
                        if (o.Position - hrp.Position).Magnitude < 5000 then hrp.CFrame = o.CFrame + Vector3.new(0,2,0); break end
                    end
                end
            end)
        end
    end
end)

-- PLAYER AURA
task.spawn(function()
    while true do
        task.wait(0.3)
        if playerAuraOn and LP.Character then
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if not playerAuraPart or not playerAuraPart.Parent then
                    playerAuraPart = Instance.new("Part")
                    playerAuraPart.Name = "PiddleAura"; playerAuraPart.Shape = Enum.PartType.Ball
                    playerAuraPart.Size = Vector3.new(6, 6, 6); playerAuraPart.Material = Enum.Material.Neon
                    playerAuraPart.Color = playerAuraColor; playerAuraPart.Transparency = 0.6
                    playerAuraPart.CanCollide = false; playerAuraPart.Anchored = false
                    playerAuraPart.Massless = true; playerAuraPart.CanQuery = false
                    playerAuraPart.Parent = LP.Character
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = root; w.Part1 = playerAuraPart; w.Parent = playerAuraPart
                    playerAuraLight = Instance.new("PointLight")
                    playerAuraLight.Color = playerAuraColor; playerAuraLight.Range = 12; playerAuraLight.Brightness = 3
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

-- PACKS (с картинками)
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
        if c then for _, a in ipairs(c:GetChildren()) do if a:IsA("Animation") then a.AnimationId = "rbxassetid://"..id end end end
    end
    setId("idle", pack.Idle); setId("walk", pack.Walk); setId("run", pack.Run)
    setId("jump", pack.Jump); setId("fall", pack.Fall); setId("climb", pack.Climb)
    setId("swim", pack.Swim); setId("swimidle", pack.SwimIdle)
end

-- KORBLOX
local function applyKorbloxNow()
    local char = LP.Character; if not char then return end
    local function tryApply()
        local rf = char:FindFirstChild("RightFoot"); local rl = char:FindFirstChild("RightLowerLeg"); local ru = char:FindFirstChild("RightUpperLeg"); local found = 0
        if rf then rf.MeshId = "http://www.roblox.com/asset/?id=902942089"; rf.Transparency = 1; found = found + 1 end
        if rl then rl.MeshId = "http://www.roblox.com/asset/?id=902942093"; rl.Transparency = 1; found = found + 1 end
        if ru then ru.MeshId = "http://www.roblox.com/asset/?id=902942096"; ru.TextureID = "http://roblox.com/asset/?id=902843398"; found = found + 1 end
        return found == 3
    end
    if tryApply() then return end
    task.spawn(function() for _ = 1, 15 do task.wait(0.5); if tryApply() then return end end end)
end
local function removeKorbloxNow()
    local char = LP.Character; if not char then return end
    for _, name in ipairs({"RightFoot","RightLowerLeg","RightUpperLeg"}) do local p = char:FindFirstChild(name); if p then p.MeshId = ""; p.TextureID = ""; p.Transparency = 0 end end
end
local function applyHeadlessNow()
    local char = LP.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    head.Transparency = 1
    for _, c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency = 1 end end
end
local function removeHeadlessNow()
    local char = LP.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    head.Transparency = 0
    for _, c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency = 0 end end
end
local function applyChinaHat()
    local char = LP.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    for _, n in ipairs({"PiddleChinaHat", "PiddleChinaHatCone", "PiddleChinaHatTassel"}) do local old = char:FindFirstChild(n); if old then old:Destroy() end end
    local hat = Instance.new("Part"); hat.Name = "PiddleChinaHat"; hat.Size = Vector3.new(2.2, 0.15, 2.2); hat.Shape = Enum.PartType.Cylinder; hat.Material = Enum.Material.SmoothPlastic; hat.Color = Color3.fromRGB(255, 220, 60); hat.CanCollide = false; hat.Massless = true; hat.CFrame = head.CFrame * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)); hat.Parent = char
    local weld = Instance.new("WeldConstraint"); weld.Part0 = head; weld.Part1 = hat; weld.Parent = hat
    local cone = Instance.new("Part"); cone.Name = "PiddleChinaHatCone"; cone.Size = Vector3.new(0.8, 0.6, 0.8); cone.Shape = Enum.PartType.Ball; cone.Material = Enum.Material.Neon; cone.Color = Color3.fromRGB(255, 50, 50); cone.CanCollide = false; cone.Massless = true; cone.CFrame = head.CFrame * CFrame.new(0, 1.2, 0); cone.Parent = char
    local weld2 = Instance.new("WeldConstraint"); weld2.Part0 = head; weld2.Part1 = cone; weld2.Parent = cone
    local tassel = Instance.new("Part"); tassel.Name = "PiddleChinaHatTassel"; tassel.Size = Vector3.new(0.1, 0.6, 0.1); tassel.Material = Enum.Material.SmoothPlastic; tassel.Color = Color3.fromRGB(255, 50, 50); tassel.CanCollide = false; tassel.Massless = true; tassel.CFrame = head.CFrame * CFrame.new(0, 1.6, 0); tassel.Parent = char
    local weld3 = Instance.new("WeldConstraint"); weld3.Part0 = head; weld3.Part1 = tassel; weld3.Parent = tassel
end
local function removeChinaHat()
    local char = LP.Character; if not char then return end
    for _, name in ipairs({"PiddleChinaHat", "PiddleChinaHatCone", "PiddleChinaHatTassel"}) do local p = char:FindFirstChild(name); if p then p:Destroy() end end
end

-- ESP
local function buildESP(plr)
    if not plr.Character or plr.Character:FindFirstChild("PiddleHighlight") then return end
    local ch = plr.Character; local hd = ch:FindFirstChild("Head"); if not hd then return end
    safe(function() local h = Instance.new("Highlight"); h.Name = "PiddleHighlight"; h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Enabled = false; h.Parent = ch end)
    safe(function()
        local tag = Instance.new("BillboardGui"); tag.Name = "PiddleTag"; tag.Size = UDim2.new(0, 160, 0, 40); tag.StudsOffset = Vector3.new(0, 3, 0); tag.AlwaysOnTop = true; tag.Adornee = hd; tag.Enabled = false; tag.Parent = ch
        local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(1, 0, 1, 0); lb.BackgroundTransparency = 1; lb.Font = Enum.Font.GothamBold; lb.TextSize = 16; lb.TextStrokeTransparency = 0; lb.Parent = tag
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end)
        if p.Character then safe(buildESP, p) end
    end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then p.CharacterAdded:Connect(function() task.wait(0.5); safe(buildESP, p) end) end end)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then local h = p.Character:FindFirstChild("PiddleHighlight"); if h then h:Destroy() end; local t = p.Character:FindFirstChild("PiddleTag"); if t then t:Destroy() end end
    if tracers[p] then safe(function() tracers[p]:Remove() end); tracers[p] = nil end
    espP[p] = nil
end)
task.spawn(function()
    while true do
        task.wait(0.15)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if not p.Character then espP[p] = nil
                else
                    local d = p.Character:FindFirstChild("PiddleHighlight"); local t = p.Character:FindFirstChild("PiddleTag")
                    if (not d or not t) and p.Character:FindFirstChild("Head") then buildESP(p); d = p.Character:FindFirstChild("PiddleHighlight"); t = p.Character:FindFirstChild("PiddleTag") end
                    if d and t then
                        local r = getRole(p); local c = roleColors[r] or Color3.fromRGB(255, 255, 255); local tx = r or "Player"; local show = false
                        if espP[p] then show = true; c = Color3.fromRGB(220, 180, 255); tx = "SELECTED"
                        elseif espF.All then show = true
                        elseif espF.Gun and hasItem(p, "Gun") then show = true; c = roleColors.Gun; tx = "GUN"
                        elseif espF.NPC and r == "NPC" then show = true
                        elseif r and espF[r] then show = true end
                        if show ~= d.Enabled then d.Enabled = show; t.Enabled = show end
                        if show then
                            d.FillColor = c; d.OutlineColor = c
                            local lb = t:FindFirstChildOfClass("TextLabel")
                            if lb then
                                lb.TextColor3 = c
                                local s = tx
                                if espF.NameTag then s = p.Name.." | "..tx end
                                local pr = p.Character:FindFirstChild("HumanoidRootPart"); local lr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if espF.Distance and pr and lr then s = s..string.format(" [%dm]", math.floor((pr.Position - lr.Position).Magnitude)) end
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
    if not tracersOn then for _, line in pairs(tracers) do safe(function() line.Visible = false end) end; return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hd = p.Character:FindFirstChild("Head"); local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local point = hd or hrp
            if point then
                local v, onScreen = Cam:WorldToViewportPoint(point.Position)
                if onScreen then
                    if not tracers[p] then local l = Drawing.new("Line"); l.Thickness = 1.5; l.Transparency = 0.9; l.Visible = false; tracers[p] = l end
                    local line = tracers[p]; local r = getRole(p); line.Color = roleColors[r] or Color3.fromRGB(255, 255, 255)
                    line.To = Vector2.new(v.X, v.Y); line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y); line.Visible = true
                else if tracers[p] then tracers[p].Visible = false end end
            end
        end
    end
end)

-- FLING
local Fling = { Active = false, Target = nil, SavedCFrame = nil, BodyVel = nil, BodyGyro = nil, AntiFlingWas = nil }
local AF = { on = true }
local function stopFling()
    Fling.Active = false; Fling.Target = nil
    if Fling.BodyVel then safe(function() Fling.BodyVel:Destroy() end); Fling.BodyVel = nil end
    if Fling.BodyGyro then safe(function() Fling.BodyGyro:Destroy() end); Fling.BodyGyro = nil end
    local ch = LP.Character; local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if root and Fling.SavedCFrame then root.CFrame = Fling.SavedCFrame; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    local hum = ch and ch:FindFirstChildOfClass("Humanoid"); if hum then safe(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    if Fling.AntiFlingWas ~= nil and AF then AF.on = Fling.AntiFlingWas; Fling.AntiFlingWas = nil end
    Fling.SavedCFrame = nil
end
local function FlingTarget(target)
    if not target or not target.Character then return end
    local myChar = LP.Character; if not myChar then return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid"); local myRoot = myHum and myHum.RootPart; if not myRoot then return end
    Fling.SavedCFrame = myRoot.CFrame; Fling.Target = target; Fling.Active = true
    if AF then Fling.AntiFlingWas = AF.on; AF.on = false end
    safe(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)
    Fling.BodyVel = Instance.new("BodyVelocity"); Fling.BodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9); Fling.BodyVel.Velocity = Vector3.zero; Fling.BodyVel.P = 1250; Fling.BodyVel.Parent = myRoot
    Fling.BodyGyro = Instance.new("BodyGyro"); Fling.BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); Fling.BodyGyro.P = 10000; Fling.BodyGyro.D = 500; Fling.BodyGyro.CFrame = myRoot.CFrame; Fling.BodyGyro.Parent = myRoot
    task.spawn(function()
        local startT = tick()
        while Fling.Active and tick() - startT < 1.5 do
            if not target.Character or not target.Character.Parent then break end
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart"); if not tRoot then break end
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not r then break end
            local dir = (tRoot.Position - r.Position); local dist = dir.Magnitude
            if Fling.BodyVel and dist > 0.1 then Fling.BodyVel.Velocity = dir.Unit * math.min(dist * 50, 500) end
            if Fling.BodyGyro then Fling.BodyGyro.CFrame = CFrame.new(r.Position, tRoot.Position) end
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
local function flingRole(r) local p = findByRole(r); if p then flingPlayer(p) end end
local function flingAll()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and getRole(p) ~= "NPC" then flingPlayer(p); task.wait(1.7) end end
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
                local c = LP.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait(); hrp.AssemblyLinearVelocity = vel
                    RunService.Stepped:Wait(); hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0)
                    movel = -movel
                end
            end
        end)
    end
end

-- EYE LASER
task.spawn(function()
    while true do
        task.wait(0.05)
        if KillFx.EyeLaser and LP.Character then
            safe(function()
                local ch = LP.Character; local myRoot = ch:FindFirstChild("HumanoidRootPart"); local myHead = ch:FindFirstChild("Head")
                if not (myRoot and myHead) then return end
                local camLook = Cam.CFrame.LookVector; local best, bestDot, bestPos = nil, 0.85, nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and getRole(p) ~= "NPC" then
                        local tr = p.Character:FindFirstChild("HumanoidRootPart"); local th = p.Character:FindFirstChildOfClass("Humanoid")
                        if tr and th and th.Health > 0 then
                            local to = (tr.Position - myHead.Position); local dist = to.Magnitude
                            if dist < KillFx.EyeLaserRange then
                                local dir = to.Unit; local dot = dir:Dot(camLook)
                                if dot > bestDot then
                                    local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {ch, p.Character}
                                    local ray = WS:Raycast(myHead.Position, to, rp)
                                    if not ray then best = p; bestDot = dot; bestPos = tr.Position end
                                end
                            end
                        end
                    end
                end
                if best and bestPos then
                    KillFx.EyeLaserTarget = best
                    if not KillFx._currentBeam or not KillFx._currentBeam.Parent then
                        KillFx._currentBeam = Instance.new("Part"); KillFx._currentBeam.Size = Vector3.new(0.2, 0.2, 1); KillFx._currentBeam.Material = Enum.Material.Neon; KillFx._currentBeam.Color = Color3.fromRGB(255, 30, 30); KillFx._currentBeam.Anchored = true; KillFx._currentBeam.CanCollide = false; KillFx._currentBeam.CanQuery = false; KillFx._currentBeam.Parent = WS
                    end
                    local beam = KillFx._currentBeam; local midPos = (myHead.Position + bestPos) / 2
                    beam.Size = Vector3.new(0.2, 0.2, (bestPos - myHead.Position).Magnitude); beam.CFrame = CFrame.new(midPos, bestPos); beam.Transparency = 0
                    if getRole(LP) == "Murderer" then
                        local k = getKnife()
                        if k and tick() - KillFx.EyeLaserCd > 0.3 then
                            local targetRoot = best.Character:FindFirstChild("HumanoidRootPart"); local myHum = ch:FindFirstChildOfClass("Humanoid")
                            if targetRoot and myHum then
                                local oldCF = myRoot.CFrame; myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2)
                                if k.Parent ~= ch then myHum:EquipTool(k) end
                                safe(function() k:Activate() end)
                                local ev = k:FindFirstChild("Events"); local stab = ev and ev:FindFirstChild("Stab"); if stab then safe(function() stab:FireServer() end) end
                                task.wait(0.03); myRoot.CFrame = oldCF; KillFx.EyeLaserCd = tick()
                            end
                        end
                    end
                else
                    if KillFx._currentBeam and KillFx._currentBeam.Parent then KillFx._currentBeam.Transparency = 1 end
                end
            end)
        end
    end
end)

-- ULTRA DODGE
local envParams = RaycastParams.new(); envParams.FilterType = Enum.RaycastFilterType.Exclude
local threatParams = RaycastParams.new(); threatParams.FilterType = Enum.RaycastFilterType.Exclude
local function updateDodgeFilters()
    local ch = LP.Character; local ignoreList = {Cam}; if ch then table.insert(ignoreList, ch) end
    envParams.FilterDescendantsInstances = ignoreList; threatParams.FilterDescendantsInstances = {Cam}
end
if LP.Character then updateDodgeFilters() end
LP.CharacterAdded:Connect(function() task.wait(0.5); updateDodgeFilters() end)
local function getSafePosition(origin, direction, distance)
    local ray = WS:Raycast(origin, direction * distance, envParams); local targetPos
    if ray then
        local hitNormal = ray.Normal; local slideDir = direction - (direction:Dot(hitNormal) * hitNormal)
        if slideDir.Magnitude < 0.1 then targetPos = origin + (direction * (ray.Distance - UD.WallBuffer)) else targetPos = origin + (slideDir.Unit * (distance * 0.8)) end
    else targetPos = origin + (direction * distance) end
    local floorRay = WS:Raycast(targetPos + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), envParams)
    if not floorRay then return origin end
    return targetPos
end
local function scanForThreats()
    local ch = LP.Character; local rootPart = ch and ch:FindFirstChild("HumanoidRootPart"); if not rootPart then return nil, "None", Vector3.new(0,0,0) end
    local myVel = rootPart.AssemblyLinearVelocity
    local scanParams = OverlapParams.new(); scanParams.FilterDescendantsInstances = {ch, Cam}; scanParams.FilterType = Enum.RaycastFilterType.Exclude
    local parts = WS:GetPartBoundsInRadius(rootPart.Position, UD.ScanRadius, scanParams)
    local chosenThreat, threatType = nil, "None"; local threatVector = Vector3.new(0,0,0)
    for _, part in ipairs(parts) do
        local pvel = part.AssemblyLinearVelocity; local speedDiff = (pvel - myVel).Magnitude
        if speedDiff > 20 then
            if not part.Anchored and pvel.Magnitude > UD.ProjectileSpeedMin then
                local vel = pvel; local toMe = (rootPart.Position - part.Position)
                if vel.Unit:Dot(toMe.Unit) > 0.5 then
                    local predictRay = WS:Raycast(part.Position, vel * 0.2, threatParams)
                    if predictRay and predictRay.Instance and predictRay.Instance:IsDescendantOf(ch) then chosenThreat = part; threatType = "Projectile"; threatVector = vel.Unit; break end
                end
            end
        end
        local model = part.Parent
        if model and model ~= ch and model:FindFirstChild("Humanoid") then
            local otherPlr = Players:GetPlayerFromCharacter(model)
            if otherPlr and otherPlr ~= LP then
                local myRole = getRole(LP); local otherRole = getRole(otherPlr); local isEnemy = false
                if myRole == "Innocent" and otherRole == "Murderer" then isEnemy = true
                elseif myRole == "Murderer" and (otherRole == "Sheriff" or otherRole == "Hero") then isEnemy = true
                elseif myRole == "Sheriff" and otherRole == "Murderer" then isEnemy = true
                elseif myRole == "Hero" and otherRole == "Murderer" then isEnemy = true end
                if isEnemy then
                    local enemyRoot = model:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        local eHum = model.Humanoid
                        if eHum.Health > 0 then
                            local toPlayer = (rootPart.Position - enemyRoot.Position); local dist = toPlayer.Magnitude
                            local facing = enemyRoot.CFrame.LookVector:Dot(-toPlayer.Unit); local speed = enemyRoot.AssemblyLinearVelocity.Magnitude
                            if dist < UD.meleeDist and (facing > 0.6 or speed > 10) then chosenThreat = enemyRoot; threatType = "Melee"; threatVector = (rootPart.Position - enemyRoot.Position).Unit end
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
    local ch = LP.Character; local rootPart = ch and ch:FindFirstChild("HumanoidRootPart"); if not rootPart then return end
    local now = tick()
    if UD.stressLevel > 0 then UD.stressLevel = math.max(0, UD.stressLevel - (UD.StressDecay * dt)) end
    local currentCooldown = (UD.stressLevel > UD.StressThreshold) and UD.OverdriveCooldown or UD.BaseCooldown
    if UD.isDodging or (now - UD.lastDodgeTime < currentCooldown) then return end
    local threat, type, dirVec = scanForThreats()
    if threat then
        UD.isDodging = true
        local mode = (UD.stressLevel > UD.StressThreshold) and "Panic" or "Normal"; local dodgeDir = Vector3.new(0,0,0)
        if type == "Projectile" then local left = dirVec:Cross(Vector3.new(0, 1, 0)); dodgeDir = (math.random() > 0.5) and left or -left; UD.stressLevel = UD.stressLevel + 2
        elseif type == "Melee" then
            if mode == "Panic" then dodgeDir = -dirVec + (Vector3.new(math.random()-0.5, 0, math.random()-0.5))
            else local left = dirVec:Cross(Vector3.new(0, 1, 0)); dodgeDir = dirVec + (left * 0.5) end
            UD.stressLevel = UD.stressLevel + 1
        end
        dodgeDir = Vector3.new(dodgeDir.X, 0, dodgeDir.Z).Unit
        local finalPos = getSafePosition(rootPart.Position, dodgeDir, UD.DodgeDist)
        if (finalPos - rootPart.Position).Magnitude > 2 then
            rootPart.AssemblyLinearVelocity = Vector3.zero; rootPart.AssemblyAngularVelocity = Vector3.zero
            local lookTarget = (type == "Projectile") and (rootPart.Position + dodgeDir) or threat.Position
            rootPart.CFrame = CFrame.new(finalPos, Vector3.new(lookTarget.X, finalPos.Y, lookTarget.Z)); UD.lastDodgeTime = now
        end
        task.wait(0.05); UD.isDodging = false
    end
end)

-- FARM
local FarmState = { isLoaded=false, enabled=false, afkActive=false, bagIsFull=false, isWaitingForCoins=false, activeCoins={}, blacklistedCoins={}, currentTarget=nil, character=nil, rootPart=nil, humanoid=nil, linearVelocity=nil, velocityAttachment=nil, connections={} }
do
    local function farmCleanup() for k, c in pairs(FarmState.connections) do safe(function() c:Disconnect() end); FarmState.connections[k] = nil end end
    local function farmDestroyVelocity() if FarmState.linearVelocity then safe(function() FarmState.linearVelocity:Destroy() end); FarmState.linearVelocity = nil end; if FarmState.velocityAttachment then safe(function() FarmState.velocityAttachment:Destroy() end); FarmState.velocityAttachment = nil end end
    local function farmStopMovement() if FarmState.linearVelocity then FarmState.linearVelocity.VectorVelocity = Vector3.zero; FarmState.linearVelocity.Enabled = false end end
    local function farmSetupVelocity()
        if not FarmState.rootPart or not FarmState.rootPart.Parent then return end
        FarmState.velocityAttachment = FarmState.rootPart:FindFirstChild("FarmAttachment")
        if not FarmState.velocityAttachment then FarmState.velocityAttachment = Instance.new("Attachment"); FarmState.velocityAttachment.Name = "FarmAttachment"; FarmState.velocityAttachment.Parent = FarmState.rootPart end
        FarmState.linearVelocity = FarmState.rootPart:FindFirstChild("FarmLinearVelocity")
        if not FarmState.linearVelocity then
            FarmState.linearVelocity = Instance.new("LinearVelocity"); FarmState.linearVelocity.Name = "FarmLinearVelocity"; FarmState.linearVelocity.Attachment0 = FarmState.velocityAttachment; FarmState.linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; FarmState.linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World; FarmState.linearVelocity.VectorVelocity = Vector3.zero; FarmState.linearVelocity.Enabled = false; FarmState.linearVelocity.MaxAxesForce = Vector3.new(100000, 100000, 100000); FarmState.linearVelocity.Parent = FarmState.rootPart
        end
    end
    local function farmIsCoin(part) if not part:IsA("BasePart") or FarmState.blacklistedCoins[part] then return false end; local name = part.Name:lower(); return name:find("coin") or name:find("cash") or name:find("money") or name:find("collect") end
    local function farmTrackCoins()
        FarmState.activeCoins = {}
        for _, v in ipairs(WS:GetDescendants()) do if farmIsCoin(v) then FarmState.activeCoins[v] = true end end
        FarmState.connections.coinAdd = WS.DescendantAdded:Connect(function(part) if farmIsCoin(part) then FarmState.activeCoins[part] = true end end)
        FarmState.connections.coinRemove = WS.DescendantRemoving:Connect(function(part) FarmState.activeCoins[part] = nil; if FarmState.currentTarget == part then FarmState.currentTarget = nil end end)
    end
    local farmStartRef
    farmStartRef = function()
        farmCleanup(); farmDestroyVelocity(); farmSetupVelocity()
        local parts = {}
        if FarmState.character then for _, part in ipairs(FarmState.character:GetChildren()) do if part:IsA("BasePart") then table.insert(parts, part) end end end
        FarmState.connections.noclip = RunService.Stepped:Connect(function()
            if FarmState.enabled and FarmState.character and FarmState.character.Parent then
                for _, part in ipairs(parts) do if part and part.Parent and part.CanCollide then part.CanCollide = false end end
            end
        end)
        FarmState.connections.heartbeat = RunService.Heartbeat:Connect(function()
            if not FarmState.enabled then farmStopMovement(); return end
            local rp = FarmState.rootPart; local hum = FarmState.humanoid
            if not rp or not rp.Parent or not hum or hum.Health <= 0 then farmStopMovement(); return end
            if FarmState.currentTarget and FarmState.currentTarget.Parent then
                local targetPos = FarmState.currentTarget.Position; local dist = (targetPos - rp.Position).Magnitude
                if dist <= 1.2 then rp.CFrame = CFrame.new(targetPos); farmStopMovement(); FarmState.blacklistedCoins[FarmState.currentTarget] = true; FarmState.activeCoins[FarmState.currentTarget] = nil; FarmState.currentTarget = nil
                else if FarmState.linearVelocity then FarmState.linearVelocity.Enabled = true; FarmState.linearVelocity.VectorVelocity = (targetPos - rp.Position).Unit * 23 end end
            else farmStopMovement() end
        end)
        farmTrackCoins()
        FarmState.connections.targetFinder = RunService.Heartbeat:Connect(function()
            if not FarmState.enabled then return end
            local rp = FarmState.rootPart; if not rp or not rp.Parent then return end
            local nearest, nd = nil, 1001
            for coin in pairs(FarmState.activeCoins) do
                if coin and coin.Parent and not FarmState.blacklistedCoins[coin] then local d = (coin.Position - rp.Position).Magnitude; if d < nd then nd = d; nearest = coin end
                else FarmState.activeCoins[coin] = nil end
            end
            FarmState.currentTarget = nearest
        end)
    end
    _G.PIDDLE_farmStart = farmStartRef; _G.PIDDLE_farmCleanup = farmCleanup; _G.PIDDLE_farmStop = farmStopMovement; _G.PIDDLE_farmDestroy = farmDestroyVelocity
    local function farmLoad()
        if FarmState.isLoaded then FarmState.isLoaded = false; farmCleanup(); farmStopMovement(); farmDestroyVelocity() end
        FarmState.isLoaded = true
        FarmState.character = LP.Character or LP.CharacterAdded:Wait()
        FarmState.rootPart = FarmState.character:WaitForChild("HumanoidRootPart")
        FarmState.humanoid = FarmState.character:WaitForChild("Humanoid")
        FarmState.blacklistedCoins = {}
        farmStartRef()
    end
    _G.PIDDLE_farmLoad = farmLoad
    local function farmAntiAfkLoop() while FarmState.afkActive and FarmState.enabled do task.wait(30); if not FarmState.afkActive or not FarmState.enabled then break end; safe(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end
    _G.PIDDLE_farmAfk = farmAntiAfkLoop
    LP.CharacterAdded:Connect(function(newChar)
        if not FarmState.isLoaded then return end
        farmCleanup(); farmDestroyVelocity()
        FarmState.character = newChar; FarmState.rootPart = newChar:WaitForChild("HumanoidRootPart", 10); FarmState.humanoid = newChar:WaitForChild("Humanoid", 10)
        FarmState.blacklistedCoins = {}; FarmState.currentTarget = nil
        task.wait(1.5)
        if FarmState.isLoaded and FarmState.enabled then farmStartRef() end
    end)
end

-- LIGHTING / WEATHER
local VisState = { weather = nil, weatherThread = nil, particles = {} }
local atmosphere = nil
local function ensureAtmosphere(on)
    if on and not atmosphere then atmosphere = Instance.new("Atmosphere"); atmosphere.Density = 0.3; atmosphere.Haze = 1.5; atmosphere.Glare = 0.2; atmosphere.Color = Color3.fromRGB(199,199,199); atmosphere.Decay = Color3.fromRGB(106,112,125); atmosphere.Parent = Lighting
    elseif not on and atmosphere then safe(function() atmosphere:Destroy() end); atmosphere = nil end
end
local function clearWeather() VisState.weather = nil; for _, p in ipairs(VisState.particles) do safe(function() p:Destroy() end) end; VisState.particles = {} end
local function spawnWeather(kind)
    clearWeather(); VisState.weather = kind
    local root = Instance.new("Folder"); root.Name = "PiddleWeather"; root.Parent = WS; table.insert(VisState.particles, root)
    local cam = Cam
    if kind == "Rain" or kind == "Storm" then
        for i = 1, 150 do local p = Instance.new("Part"); p.Size = Vector3.new(0.08, 1.2, 0.08); p.Anchored = true; p.CanCollide = false; p.Color = Color3.fromRGB(180,200,255); p.Transparency = 0.3; p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80))); p.Parent = root; p.CanQuery = false; p.CanTouch = false end
    elseif kind == "Snow" then
        for i = 1, 120 do local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = Vector3.new(0.4,0.4,0.4); p.Anchored = true; p.CanCollide = false; p.Color = Color3.fromRGB(255,255,255); p.Transparency = 0.2; p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80))); p.Parent = root; p.CanQuery = false; p.CanTouch = false end
    elseif kind == "Leaves" then
        for i = 1, 80 do local p = Instance.new("Part"); p.Size = Vector3.new(0.6,0.1,0.6); p.Anchored = true; p.CanCollide = false; p.Color = Color3.fromRGB(180,90,30); p.Transparency = 0.2; p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(20,60), math.random(-80,80))) * CFrame.Angles(math.random()*3, math.random()*3, math.random()*3); p.Parent = root; p.CanQuery = false; p.CanTouch = false end
    elseif kind == "Embers" then
        for i = 1, 120 do local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = Vector3.new(0.2,0.2,0.2); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255,100,20); p.Transparency = 0.1; p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(math.random(-80,80), math.random(-20,40), math.random(-80,80))); p.Parent = root; p.CanQuery = false; p.CanTouch = false end
    end
    if VisState.weatherThread then safe(function() task.cancel(VisState.weatherThread) end) end
    VisState.weatherThread = task.spawn(function()
        while VisState.weather and VisState.weather ~= "None" do
            RunService.Heartbeat:Wait()
            local camPos = Cam.CFrame.Position
            for _, p in ipairs(root:GetChildren()) do
                if p:IsA("BasePart") and p.Parent then
                    local pos = p.Position
                    if kind == "Rain" or kind == "Storm" then pos = pos + Vector3.new(0, -3, 0)
                    elseif kind == "Snow" then pos = pos + Vector3.new(math.sin(tick()*2 + p.Position.X)*0.05, -0.6, 0)
                    elseif kind == "Leaves" then pos = pos + Vector3.new(math.sin(tick()*1.5 + p.Position.Z)*0.1, -0.5, 0)
                    elseif kind == "Embers" then pos = pos + Vector3.new(math.sin(tick()*3 + p.Position.X)*0.2, 1.5, 0) end
                    if pos.Y < camPos.Y - 10 then pos = camPos + Vector3.new(math.random(-80,80), math.random(30,60), math.random(-80,80)) end
                    p.CFrame = CFrame.new(pos)
                end
            end
        end
    end)
end
local function applyLightingPreset(name)
    if name == "Default" then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.Ambient = Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128); Lighting.FogEnd = 1000; Lighting.FogColor = Color3.fromRGB(192,192,192); ensureAtmosphere(false)
    elseif name == "Night" then
        Lighting.Brightness = 0.5; Lighting.ClockTime = 0; Lighting.Ambient = Color3.fromRGB(30,30,50); Lighting.OutdoorAmbient = Color3.fromRGB(50,50,80); Lighting.FogEnd = 400; Lighting.FogColor = Color3.fromRGB(20,20,40); ensureAtmosphere(true); if atmosphere then atmosphere.Density = 0.4; atmosphere.Color = Color3.fromRGB(15,15,40) end
    elseif name == "Deep Night" then
        Lighting.Brightness = 0.1; Lighting.ClockTime = 0; Lighting.Ambient = Color3.fromRGB(5,5,15); Lighting.OutdoorAmbient = Color3.fromRGB(15,15,35); Lighting.FogEnd = 150; Lighting.FogColor = Color3.fromRGB(5,5,15); ensureAtmosphere(true); if atmosphere then atmosphere.Density = 0.6; atmosphere.Color = Color3.fromRGB(0,0,10) end
    elseif name == "Sunset" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 18; Lighting.Ambient = Color3.fromRGB(120,60,40); Lighting.OutdoorAmbient = Color3.fromRGB(200,100,70); Lighting.FogEnd = 600; Lighting.FogColor = Color3.fromRGB(255,150,80); ensureAtmosphere(true); if atmosphere then atmosphere.Density = 0.35; atmosphere.Color = Color3.fromRGB(255,140,80) end
    elseif name == "Dawn" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 6; Lighting.Ambient = Color3.fromRGB(120,80,120); Lighting.OutdoorAmbient = Color3.fromRGB(200,160,180); Lighting.FogEnd = 800; Lighting.FogColor = Color3.fromRGB(255,180,200); ensureAtmosphere(true)
    elseif name == "Rainy" then
        Lighting.Brightness = 1; Lighting.ClockTime = 14; Lighting.Ambient = Color3.fromRGB(60,65,75); Lighting.OutdoorAmbient = Color3.fromRGB(90,95,110); Lighting.FogEnd = 300; Lighting.FogColor = Color3.fromRGB(80,85,95); ensureAtmosphere(true); if atmosphere then atmosphere.Density = 0.5 end
    elseif name == "Foggy" then
        Lighting.Brightness = 1.5; Lighting.ClockTime = 14; Lighting.FogEnd = 100; Lighting.FogColor = Color3.fromRGB(200,200,200); ensureAtmosphere(true); if atmosphere then atmosphere.Density = 0.7; atmosphere.Haze = 3 end
    elseif name == "Storm" then
        Lighting.Brightness = 0.8; Lighting.ClockTime = 12; Lighting.Ambient = Color3.fromRGB(40,45,55); Lighting.OutdoorAmbient = Color3.fromRGB(70,75,90); Lighting.FogEnd = 200; Lighting.FogColor = Color3.fromRGB(60,65,80); ensureAtmosphere(true)
    elseif name == "Realistic" then
        Lighting.Brightness = 2; Lighting.ClockTime = 15; Lighting.Ambient = Color3.fromRGB(80,80,80); Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140); Lighting.FogEnd = 1e6; ensureAtmosphere(false)
    end
end

-- VOTE / TRADE (уже с загрузкой картинок карт)
_G.PIDDLE_VOTE_ON = false
_G.PIDDLE_VOTE_TARGET = nil
task.spawn(function()
    local PLATFORMS = { Vector3.new(25.69, 507.37, 49.26), Vector3.new(14.10, 507.37, 51.04), Vector3.new(1.83, 507.37, 50.76) }
    while true do
        task.wait(0.1)
        if _G.PIDDLE_VOTE_ON and _G.PIDDLE_VOTE_TARGET then
            local pos = PLATFORMS[_G.PIDDLE_VOTE_TARGET]
            local ch = LP.Character; local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if hrp and pos and _G.PIDDLE_VOTE_ON then
                hrp.CFrame = CFrame.new(pos)
                for _ = 1, 3 do task.wait(0.1); if not _G.PIDDLE_VOTE_ON then break end end
                if _G.PIDDLE_VOTE_ON then safe(function() ch:BreakJoints() end) end
                for _ = 1, 3 do task.wait(0.1); if not _G.PIDDLE_VOTE_ON then break end end
            end
        end
    end
end)

-- TRADE DATA
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
                local id = row[1] or "unknown"; local alias = row[2] or ""; local kind = row[3] or ""; local year = row[4] or 0; local val = row[5] or 0
                local displayName = id:gsub("^%l", string.upper)
                if alias ~= "" then displayName = displayName.." ("..alias..")" end
                table.insert(TRADE_DATA.items, { id=id, name=displayName, raw=id, alias=alias, kind=kind, year=year, value=val, category=cat })
            end
        end
    end
    TRADE_DATA.loaded = true
    return true
end
local function fetchSupremeValues()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function() return req({ Url = SUPREME_URL, Method = "GET" }) end)
        if ok and res and res.Body and #res.Body > 100 then if parseItems(res.Body) then return true end end
    end
    local ok, body = pcall(function() return HttpService:GetAsync(SUPREME_URL) end)
    if ok and body and #body > 100 then if parseItems(body) then return true end end
    return false
end
safe(function() parseItems(FALLBACK_JSON) end)
task.spawn(function() fetchSupremeValues(); while true do task.wait(300); fetchSupremeValues() end end)
local function findTradeItem(query)
    if not query or query == "" then return nil end
    local q = query:lower(); local exact, partial
    for _, item in ipairs(TRADE_DATA.items) do
        local id = item.id:lower(); local nm = item.name:lower()
        if id == q or nm == q then exact = item; break end
        if not partial and (id:find(q, 1, true) or nm:find(q, 1, true)) then partial = item end
    end
    return exact or partial
end

--============================================================
-- СОЗДАНИЕ ОКНА DOGUI С ВКЛАДКАМИ PIDDLE
--============================================================

local CONFIG = {
    LogoId   = 0,
    BannerId = 0,
}

local Win = Library:CreateWindow({
    Logo = CONFIG.LogoId ~= 0 and CONFIG.LogoId or nil,
    Banner = CONFIG.BannerId ~= 0 and CONFIG.BannerId or nil,
    ToggleIcon = CONFIG.LogoId ~= 0 and CONFIG.LogoId or nil,
    Keybind = Enum.KeyCode.RightShift,
    Size = Vector2.new(440, 480),
})

local noop = function() end

-- ==================== HOME ====================
local tabHome = Win:AddTab({ Name = "Home", Subtitle = "general", Icon = ICONS.HOME })
local secHomeMain = tabHome:AddSection({ Name = "general", Side = "Left" })
secHomeMain:AddButton({ Name = "Save Config", Callback = function() saveCFG(); Library:Notify({ Title = "PIDDLE", Text = "config saved" }) end })
secHomeMain:AddButton({ Name = "Reset Character", Callback = function() if LP.Character then safe(function() LP.Character:BreakJoints() end) end end })
secHomeMain:AddButton({ Name = "Rejoin Server", Callback = function() safe(function() TeleportService:Teleport(game.PlaceId, LP) end) end })
secHomeMain:AddButton({ Name = "Close UI", Callback = function() Win:Toggle() end })

-- ==================== COMBAT ====================
local tabCombat = Win:AddTab({ Name = "Combat", Subtitle = "fight", Icon = ICONS.TARGET })
local secMurder = tabCombat:AddSection({ Name = "murderer", Side = "Left" })
secMurder:AddToggle({ Name = "Kill Aura (all server)", Flag = "kill_aura", Callback = function(v) killAuraOn = v end })
secMurder:AddButton({ Name = "Kill All (no TP)", Callback = function() killAllRun() end })
secMurder:AddToggle({ Name = "Auto-Knife", Flag = "auto_knife", Callback = function(v) autoKnife = v end })
secMurder:AddToggle({ Name = "Auto-Throw", Flag = "auto_throw", Callback = function(v) autoThrow = v end })

local secSheriff = tabCombat:AddSection({ Name = "sheriff / hero", Side = "Right" })
secSheriff:AddToggle({ Name = "Aimlock", Flag = "aimlock", Callback = function(v) aimMurd = v end })
secSheriff:AddToggle({ Name = "Auto-Shoot (predict)", Flag = "auto_shoot", Callback = function(v) autoShoot = v end })
secSheriff:AddToggle({ Name = "Shoot Through Walls", Flag = "shoot_walls", Default = CFG.shootThroughWalls, Callback = function(v) shootThroughWalls = v; CFG.shootThroughWalls = v; saveCFG() end })
secSheriff:AddToggle({ Name = "Predict Movement", Flag = "predict", Default = CFG.predictMovement, Callback = function(v) predictMovement = v; CFG.predictMovement = v; saveCFG() end })

local secKillFx = tabCombat:AddSection({ Name = "kill features", Side = "Left" })
secKillFx:AddToggle({ Name = "Eye Laser (any role)", Flag = "eye_laser", Callback = function(v) KillFx.EyeLaser = v end })
secKillFx:AddSlider({ Name = "Eye Laser Range", Flag = "eye_laser_range", Min = 50, Max = 500, Default = 200, Callback = function(v) KillFx.EyeLaserRange = v end })
secKillFx:AddToggle({ Name = "Run Kill (Murderer)", Flag = "run_kill", Callback = function(v) KillFx.RunKill = v end })
secKillFx:AddSlider({ Name = "Run Kill Range", Flag = "run_kill_range", Min = 1, Max = 20, Default = 4, Callback = function(v) KillFx.RunKillRange = v end })

local secAntiAim = tabCombat:AddSection({ Name = "anti-aim", Side = "Right" })
secAntiAim:AddToggle({ Name = "Anti-Aim (Spoof)", Flag = "anti_aim", Callback = function(v) antiAimOn = v end })
secAntiAim:AddSlider({ Name = "Anti-Aim Speed", Flag = "anti_aim_speed", Min = 1, Max = 50, Default = 10, Callback = function(v) antiAimSpeed = 1 / v end })

-- ==================== VISUALS ====================
local tabVisual = Win:AddTab({ Name = "Visuals", Subtitle = "esp", Icon = ICONS.EYE })
local secESP = tabVisual:AddSection({ Name = "esp", Side = "Left" })
secESP:AddToggle({ Name = "ESP All", Flag = "esp_all", Callback = function(v) espF.All = v end })
secESP:AddToggle({ Name = "ESP Murderer", Flag = "esp_murd", Callback = function(v) espF.Murderer = v end })
secESP:AddToggle({ Name = "ESP Sheriff", Flag = "esp_sher", Callback = function(v) espF.Sheriff = v end })
secESP:AddToggle({ Name = "ESP Innocent", Flag = "esp_inno", Callback = function(v) espF.Innocent = v end })
secESP:AddToggle({ Name = "ESP NPC", Flag = "esp_npc", Callback = function(v) espF.NPC = v end })
secESP:AddToggle({ Name = "ESP Gun", Flag = "esp_gun", Callback = function(v) espF.Gun = v end })
secESP:AddToggle({ Name = "ESP NameTag", Flag = "esp_name", Callback = function(v) espF.NameTag = v end })
secESP:AddToggle({ Name = "ESP Distance", Flag = "esp_dist", Callback = function(v) espF.Distance = v end })
secESP:AddToggle({ Name = "Tracers", Flag = "tracers", Callback = function(v) tracersOn = v end })

local secAura = tabVisual:AddSection({ Name = "player aura", Side = "Right" })
secAura:AddToggle({ Name = "Enable Aura", Flag = "player_aura", Callback = function(v) playerAuraOn = v end })
secAura:AddColorPicker({ Name = "Aura Color", Flag = "aura_color", Default = Color3.fromRGB(255, 100, 130), Callback = function(c) playerAuraColor = c; if playerAuraPart then playerAuraPart.Color = c end; if playerAuraLight then playerAuraLight.Color = c end end })

local secPreset = tabVisual:AddSection({ Name = "lighting presets", Side = "Left" })
for _, n in ipairs({"Night","Deep Night","Sunset","Dawn","Rainy","Foggy","Storm","Realistic","Default"}) do
    secPreset:AddButton({ Name = n, Callback = function() applyLightingPreset(n) end })
end

local secWeather = tabVisual:AddSection({ Name = "weather", Side = "Right" })
secWeather:AddButton({ Name = "None", Callback = function() clearWeather() end })
secWeather:AddButton({ Name = "Rain", Callback = function() spawnWeather("Rain") end })
secWeather:AddButton({ Name = "Snow", Callback = function() spawnWeather("Snow") end })
secWeather:AddButton({ Name = "Leaves", Callback = function() spawnWeather("Leaves") end })
secWeather:AddButton({ Name = "Embers", Callback = function() spawnWeather("Embers") end })
secWeather:AddButton({ Name = "Storm", Callback = function() spawnWeather("Storm") end })

local secLight = tabVisual:AddSection({ Name = "lighting", Side = "Left" })
secLight:AddToggle({ Name = "Fullbright", Flag = "fullbright", Callback = function(o) Lighting.Brightness = o and 3 or 2; Lighting.OutdoorAmbient = o and Color3.new(1,1,1) or Color3.fromRGB(128,128,128) end })
secLight:AddToggle({ Name = "No Fog", Flag = "nofog", Callback = function(o) Lighting.FogEnd = o and 1e6 or 1000 end })
secLight:AddSlider({ Name = "Time of Day", Flag = "time_day", Min = 0, Max = 24, Default = 14, Callback = function(v) Lighting.ClockTime = v end })
secLight:AddSlider({ Name = "Brightness", Flag = "brightness", Min = 0, Max = 5, Default = 2, Callback = function(v) Lighting.Brightness = v end })
secLight:AddSlider({ Name = "FOV", Flag = "fov", Min = 50, Max = 130, Default = 70, Callback = function(v) Cam.FieldOfView = v end })

-- ==================== PLAYERS ====================
local tabPlayers = Win:AddTab({ Name = "Players", Subtitle = "target", Icon = ICONS.UTIL })
local secPlayers = tabPlayers:AddSection({ Name = "player list", Side = "Left" })
local playerDropdown = secPlayers:AddDropdown({ Name = "Select Target", Flag = "target_player", Values = {"none"}, Default = "none", Callback = noop })
local function refreshPlayerList()
    local list = {"none", "@random", "@nearest"}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(list, p.Name) end end
    playerDropdown:SetValues(list)
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
secPlayers:AddButton({ Name = "Refresh List", Callback = refreshPlayerList })
local function getSelectedPlayer()
    local sel = playerDropdown:Get()
    if sel == "none" or not sel then return nil end
    if sel == "@random" then
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(list, p) end end
        return #list > 0 and list[math.random(1, #list)] or nil
    elseif sel == "@nearest" then
        local lp = LP.Character; if not lp then return nil end
        local myRoot = lp:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil end
        local best, bd = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then local tr = p.Character:FindFirstChild("HumanoidRootPart"); if tr then local d = (tr.Position - myRoot.Position).Magnitude; if d < bd then bd = d; best = p end end end
        end
        return best
    else
        return Players:FindFirstChild(sel)
    end
end
secPlayers:AddButton({ Name = "Fling Selected", Callback = function() local p = getSelectedPlayer(); if p then flingPlayer(p) end end })
secPlayers:AddButton({ Name = "TP to Selected", Callback = function() local p = getSelectedPlayer(); if p and p.Character and LP.Character then local tr = p.Character:FindFirstChild("HumanoidRootPart"); local lr = LP.Character:FindFirstChild("HumanoidRootPart"); if tr and lr then lr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end end end })

-- ==================== FARM ====================
local tabFarm = Win:AddTab({ Name = "Farm", Subtitle = "auto", Icon = ICONS.COIN })
local secFarm = tabFarm:AddSection({ Name = "auto farm", Side = "Left" })
secFarm:AddToggle({ Name = "Auto Farm", Flag = "auto_farm", Callback = function(state)
    FarmState.enabled = state
    if state then if not FarmState.isLoaded then _G.PIDDLE_farmLoad() end; _G.PIDDLE_farmStart()
    else _G.PIDDLE_farmStop(); _G.PIDDLE_farmCleanup() end
end })
secFarm:AddToggle({ Name = "Anti-AFK", Flag = "anti_afk", Callback = function(state) FarmState.afkActive = state; if state and FarmState.enabled then task.spawn(_G.PIDDLE_farmAfk) end end })
secFarm:AddToggle({ Name = "Auto Get Gun", Flag = "auto_gun", Callback = function(v) autoGun = v end })

-- ==================== TELEPORT ====================
local tabTp = Win:AddTab({ Name = "Teleport", Subtitle = "tp", Icon = ICONS.TP })
local secTp = tabTp:AddSection({ Name = "teleport", Side = "Left" })
secTp:AddButton({ Name = "TP Murderer", Callback = function() local p = findMurderer(); if p and p.Character and LP.Character then local pr = p.Character:FindFirstChild("HumanoidRootPart"); local lr = LP.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame = pr.CFrame + Vector3.new(0, 3, 0) end end end })
secTp:AddButton({ Name = "TP Sheriff", Callback = function() local p = findSheriff(); if p and p.Character and LP.Character then local pr = p.Character:FindFirstChild("HumanoidRootPart"); local lr = LP.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame = pr.CFrame + Vector3.new(0, 3, 0) end end end })

-- ==================== FLING ====================
local tabFling = Win:AddTab({ Name = "Fling", Subtitle = "fling", Icon = ICONS.FLING })
local secFling = tabFling:AddSection({ Name = "fling", Side = "Left" })
secFling:AddButton({ Name = "FLING Murderer", Callback = function() flingRole("Murderer") end })
secFling:AddButton({ Name = "FLING Sheriff", Callback = function() flingRole("Sheriff") end })
secFling:AddButton({ Name = "FLING All", Callback = function() flingAll() end })
secFling:AddButton({ Name = "Stop", Callback = function() stopFlingAll() end })
secFling:AddToggle({ Name = "Touch Fling", Flag = "touch_fling", Callback = function(v) setTouchFling(v) end })

-- ==================== MOVEMENT ====================
local tabMove = Win:AddTab({ Name = "Movement", Subtitle = "move", Icon = ICONS.FLY })
local secMove = tabMove:AddSection({ Name = "move", Side = "Left" })
secMove:AddToggle({ Name = "Keep Speed", Flag = "keep_speed", Callback = function(v) keepSpeed = v end })
secMove:AddSlider({ Name = "Speed", Flag = "speed", Min = 16, Max = 200, Default = dSpeed, Callback = function(v) dSpeed = v; CFG.speed = v end })
secMove:AddToggle({ Name = "Keep Jump", Flag = "keep_jump", Callback = function(v) keepJump = v end })
secMove:AddSlider({ Name = "Jump", Flag = "jump", Min = 50, Max = 300, Default = dJump, Callback = function(v) dJump = v; CFG.jump = v end })
secMove:AddToggle({ Name = "Fly", Flag = "fly", Callback = function(o)
    flying = o
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if flyBV then safe(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then safe(function() flyBG:Destroy() end); flyBG = nil end
    if o and hrp then flyBV = Instance.new("BodyVelocity"); flyBV.Parent = hrp; flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5); flyBV.Velocity = Vector3.new(0, 0, 0); flyBG = Instance.new("BodyGyro"); flyBG.Parent = hrp; flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5); flyBG.P = 1000 end
end })
secMove:AddToggle({ Name = "Noclip", Flag = "noclip", Callback = function(o) noclip = o end })
secMove:AddToggle({ Name = "Spin", Flag = "spin", Callback = function(o) spinOn = o end })
secMove:AddSlider({ Name = "Spin Speed", Flag = "spin_speed", Min = 1, Max = 500, Default = 30, Callback = function(v) spinSpd = v end })

-- ==================== DODGE ====================
local tabDodge = Win:AddTab({ Name = "Dodge", Subtitle = "ultra", Icon = ICONS.SHIELD })
local secDodge = tabDodge:AddSection({ Name = "ultra dodge", Side = "Left" })
secDodge:AddToggle({ Name = "Enable", Flag = "ud_enabled", Callback = function(o) UD.enabled = o end })
secDodge:AddSlider({ Name = "Scan Radius", Flag = "ud_scan", Min = 5, Max = 40, Default = UD.ScanRadius, Callback = function(v) UD.ScanRadius = v end })
secDodge:AddSlider({ Name = "Dodge Distance", Flag = "ud_dist", Min = 5, Max = 30, Default = UD.DodgeDist, Callback = function(v) UD.DodgeDist = v end })
secDodge:AddSlider({ Name = "Panic Threshold", Flag = "ud_panic", Min = 1, Max = 10, Default = UD.StressThreshold, Callback = function(v) UD.StressThreshold = v end })

-- ==================== MISC ====================
local tabMisc = Win:AddTab({ Name = "Misc", Subtitle = "auto", Icon = ICONS.UTIL })
local secMisc = tabMisc:AddSection({ Name = "auto", Side = "Left" })
secMisc:AddToggle({ Name = "Auto-Respawn", Flag = "auto_respawn", Callback = function(o) autoRespawn = o end })
secMisc:AddToggle({ Name = "Fast-Respawn", Flag = "fast_respawn", Callback = function(o) fastRespawn = o end })
secMisc:AddToggle({ Name = "Anti-Void", Flag = "anti_void", Callback = function(o) antiVoid = o end })
secMisc:AddToggle({ Name = "Anti-Fling", Flag = "anti_fling", Default = true, Callback = function(o) AF.on = o end })

-- ==================== PLAYER (с картинками анимаций и эмоций) ====================
local tabPlayer = Win:AddTab({ Name = "Player", Subtitle = "local", Icon = ICONS.HAT })
local secPacks = tabPlayer:AddSection({ Name = "animation packs", Side = "Left" })
for _, n in ipairs({"Ninja","Zombie","Mage","Pirate","Robot"}) do
    local img = ANIMATION_IMAGES[n] or ""
    local labelText = n
    secPacks:AddButton({ Name = labelText, Callback = function()
        selectedPack = n; CFG.selectedPack = n; saveCFG(); applyPack(n)
    end })
end

local secEmotes = tabPlayer:AddSection({ Name = "emotes", Side = "Right" })
local EMOTES = {
    Wave="507770239", Point="507770453", Dance="507771019", Laugh="507770818",
    Cheer="507770677", Salute="507770965", Shrug="507770647", Facepalm="507770585",
    Bow="507770603", Flex="507770720", Frog="507770674", Zombie="507770762",
    Pray="507770612", Sit="507770750", Lay="507770758", Sword="507770858",
    Kick="507770863", Dab="248263260", Floss="5002593297", DefaultDance="180435571",
}
local curEmote
for emoteName, id in pairs(EMOTES) do
    secEmotes:AddButton({ Name = emoteName, Callback = function()
        safe(function() if curEmote then curEmote:Stop() end end)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not h then return end
        local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. id
        local ok, tr = pcall(function() return h:LoadAnimation(a) end)
        if ok and tr then tr.Priority = Enum.AnimationPriority.Action4; tr.Looped = true; tr:Play(); curEmote = tr end
    end })
end

local secOutfit = tabPlayer:AddSection({ Name = "outfits", Side = "Left" })
secOutfit:AddButton({ Name = "Korblox ON", Callback = function() CFG.korbloxOn = true; saveCFG(); applyKorbloxNow() end })
secOutfit:AddButton({ Name = "Korblox OFF", Callback = function() CFG.korbloxOn = false; saveCFG(); removeKorbloxNow() end })
secOutfit:AddButton({ Name = "Headless ON", Callback = function() CFG.headlessOn = true; saveCFG(); applyHeadlessNow() end })
secOutfit:AddButton({ Name = "Headless OFF", Callback = function() CFG.headlessOn = false; saveCFG(); removeHeadlessNow() end })
secOutfit:AddButton({ Name = "China Hat ON", Callback = function() CFG.chinaHatOn = true; saveCFG(); applyChinaHat() end })
secOutfit:AddButton({ Name = "China Hat OFF", Callback = function() CFG.chinaHatOn = false; saveCFG(); removeChinaHat() end })

-- ==================== VOTE (с автозагрузкой картинок карт) ====================
local tabVote = Win:AddTab({ Name = "Vote", Subtitle = "duper", Icon = ICONS.GUN })
local secVote = tabVote:AddSection({ Name = "vote duper", Side = "Left" })
local mapDropdown = secVote:AddDropdown({ Name = "Select Map", Flag = "map_select", Values = {"Map 1", "Map 2", "Map 3"}, Default = "Map 1", Callback = function(v)
    local idx = (v == "Map 1" and 1) or (v == "Map 2" and 2) or 3
    local imgId = MAP_VOTE_IMAGES[idx]
    if imgId and imgId ~= "" then
        -- Показываем картинку карты в уведомлении
        Library:Notify({ Title = "Map " .. idx, Text = "Selected map " .. idx })
    end
end })

-- Автозагрузка картинок карт при открытии вкладки Vote
local voteImageFrame = Instance.new("Frame")
voteImageFrame.Name = "VoteMapImage"
voteImageFrame.Size = UDim2.new(1, -12, 0, 80)
voteImageFrame.Position = UDim2.new(0, 6, 0, 6)
voteImageFrame.BackgroundColor3 = Theme.Box
voteImageFrame.Visible = false
voteImageFrame.Parent = tabVote.Page

local voteImage = Instance.new("ImageLabel")
voteImage.Size = UDim2.fromScale(1, 1)
voteImage.BackgroundTransparency = 1
voteImage.ScaleType = Enum.ScaleType.Crop
voteImage.Parent = voteImageFrame
local voteImageCorner = Instance.new("UICorner")
voteImageCorner.CornerRadius = UDim.new(0, 4)
voteImageCorner.Parent = voteImage

-- Обновление картинки при смене карты
mapDropdown:OnChanged(function(v)
    local idx = (v == "Map 1" and 1) or (v == "Map 2" and 2) or 3
    local imgId = MAP_VOTE_IMAGES[idx]
    if imgId and imgId ~= "" then
        voteImage.Image = imgId
        voteImageFrame.Visible = true
    else
        voteImageFrame.Visible = false
    end
end)

secVote:AddButton({ Name = "Start Duper", Callback = function()
    local sel = mapDropdown:Get()
    local idx = (sel == "Map 1" and 1) or (sel == "Map 2" and 2) or 3
    _G.PIDDLE_VOTE_TARGET = idx
    _G.PIDDLE_VOTE_ON = true
    Library:Notify({ Title = "Vote Duper", Text = "Started: " .. sel })
end })
secVote:AddButton({ Name = "Stop Duper", Callback = function()
    _G.PIDDLE_VOTE_ON = false
    Library:Notify({ Title = "Vote Duper", Text = "Stopped" })
end })

-- ==================== TRADE ====================
local tabTrade = Win:AddTab({ Name = "Trade", Subtitle = "calculator", Icon = ICONS.UTIL })
local secTrade = tabTrade:AddSection({ Name = "trade calculator", Side = "Left" })
local myTotal, hisTotal = 0, 0
local myItems, hisItems = {}, {}
local myLbl = secTrade:AddLabel("Your Total: 0")
local hisLbl = secTrade:AddLabel("Their Total: 0")
local searchInput = secTrade:AddTextbox({ Name = "Item Name", Flag = "trade_search", Placeholder = "Search...", Callback = noop })
secTrade:AddButton({ Name = "Add My", Callback = function()
    local item = findTradeItem(searchInput:Get())
    if item then table.insert(myItems, item); myTotal = 0; for _, v in ipairs(myItems) do myTotal = myTotal + (v.value or 0) end; myLbl:SetText("Your Total: " .. myTotal); searchInput:Set("") end
end })
secTrade:AddButton({ Name = "Add His", Callback = function()
    local item = findTradeItem(searchInput:Get())
    if item then table.insert(hisItems, item); hisTotal = 0; for _, v in ipairs(hisItems) do hisTotal = hisTotal + (v.value or 0) end; hisLbl:SetText("Their Total: " .. hisTotal); searchInput:Set("") end
end })
secTrade:AddButton({ Name = "Clear", Callback = function() myItems = {}; hisItems = {}; myTotal = 0; hisTotal = 0; myLbl:SetText("Your Total: 0"); hisLbl:SetText("Their Total: 0") end })

-- ==================== MUSIC ====================
local tabMusic = Win:AddTab({ Name = "Music", Subtitle = "sound", Icon = ICONS.SPEED })
local secMusic = tabMusic:AddSection({ Name = "music", Side = "Left" })
local bgSound = Instance.new("Sound"); bgSound.Name = "PiddleMusic"; bgSound.Volume = CFG.volume / 100; bgSound.Looped = true; bgSound.Parent = SoundService
local TRACKS = { ["Chill"] = "rbxassetid://1837879082", ["Synth"] = "rbxassetid://1836318003", ["Trap"] = "rbxassetid://1837842597", ["Phonk"] = "rbxassetid://9046731150" }
local orderTracks = {}
for k in pairs(TRACKS) do table.insert(orderTracks, k) end
table.sort(orderTracks)
local curTrack = 1
local function playIdx(i) i = ((i - 1) % #orderTracks) + 1; curTrack = i; bgSound.SoundId = TRACKS[orderTracks[i]]; bgSound:Play() end
secMusic:AddButton({ Name = "Play", Callback = function() if bgSound.SoundId == "" then playIdx(curTrack) else bgSound:Play() end end })
secMusic:AddButton({ Name = "Pause", Callback = function() bgSound:Pause() end })
secMusic:AddButton({ Name = "Stop", Callback = function() bgSound:Stop() end })
secMusic:AddButton({ Name = "Next", Callback = function() playIdx(curTrack + 1) end })
secMusic:AddButton({ Name = "Prev", Callback = function() playIdx(curTrack - 1) end })
secMusic:AddSlider({ Name = "Volume", Flag = "volume", Min = 0, Max = 100, Default = CFG.volume, Callback = function(v) bgSound.Volume = v / 100; CFG.volume = v end })

-- ==================== SETTINGS ====================
local tabSettings = Win:AddTab({ Name = "Settings", Subtitle = "config", Icon = ICONS.NOCLIP })
local secSettings = tabSettings:AddSection({ Name = "config", Side = "Left" })
local cfgName = secSettings:AddTextbox({ Name = "Config Name", Flag = "cfg_name", Default = "default", Callback = noop })
secSettings:AddButton({ Name = "Save", Callback = function() Library:SaveConfig(Library.Flags.cfg_name or "default"); Library:Notify({ Title = "config", Text = "saved" }) end })
secSettings:AddButton({ Name = "Load", Callback = function() local ok, err = Library:LoadConfig(Library.Flags.cfg_name or "default"); Library:Notify({ Title = "config", Text = ok and "loaded" or tostring(err) }) end })

local secUiSettings = tabSettings:AddSection({ Name = "ui", Side = "Right" })
secUiSettings:AddKeybind({ Name = "Menu Key", Default = Enum.KeyCode.RightShift, Callback = noop })
secUiSettings:AddButton({ Name = "Unload", Callback = function() Library:Unload() end })

-- Уведомление о загрузке
task.delay(0.5, function()
    Library:Notify({ Title = "PIDDLE MM2", Text = "loaded - RightShift or tap toggle" })
end)