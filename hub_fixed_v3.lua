if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end
task.wait(1)

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
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local InsertService = game:GetService("InsertService")
local PathService = game:GetService("PathfindingService")
if type(getgenv) ~= "function" then getgenv = function() return _G end end

repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local WS = workspace
repeat task.wait() until WS.CurrentCamera
local Cam = WS.CurrentCamera

local EX = {}
function EX.env()
    local ok,g=pcall(function() return getgenv() end)
    if ok and type(g)=="table" then return g end
    return _G
end
function EX.modal(v) pcall(function() UIS.ModalEnabled=v end) end
function EX.clip(s)
    for _,f in ipairs({"setclipboard","toclipboard"}) do
        local fn=EX.env()[f] or _G[f]
        if type(fn)=="function" and pcall(fn,s) then return true end
    end
    return false
end
function EX.touch(a,b,fast)
    local f = nil
    pcall(function() f = firetouchinterest end)
    if type(f) ~= "function" then pcall(function() f = syn and syn.firetouchinterest end) end
    if type(f) ~= "function" then return false end
    return pcall(function() f(a,b,0); if not fast then task.wait() end; f(a,b,1) end)
end
function EX.prompt(p,fast)
    local f = nil
    pcall(function() f = fireproximityprompt end)
    if type(f) == "function" and pcall(f,p) then return true end
    if fast then return pcall(function() p:InputHoldBegin(); p:InputHoldEnd() end) end
    return pcall(function() p:InputHoldBegin(); task.wait((p.HoldDuration or 0)+0.05); p:InputHoldEnd() end)
end

local Library = { Version="1.0.0", Flags={}, Options={}, Windows={}, LowerCase=true, Connections={}, Unloaded=false }
local Theme = {
    Window=Color3.fromRGB(10,10,12), Sidebar=Color3.fromRGB(13,13,15), Section=Color3.fromRGB(17,17,20),
    SectionHead=Color3.fromRGB(21,21,25), Row=Color3.fromRGB(24,24,28), Box=Color3.fromRGB(26,26,30),
    Stroke=Color3.fromRGB(34,34,40), StrokeSoft=Color3.fromRGB(26,26,31), Accent=Color3.fromRGB(240,240,245),
    Text=Color3.fromRGB(222,222,228), Dim=Color3.fromRGB(128,128,138), Dimmer=Color3.fromRGB(78,78,88),
    Check=Color3.fromRGB(12,12,14), Line=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamMedium, FontBold=Enum.Font.GothamBold, FontLight=Enum.Font.Gotham,
}
Library.Theme = Theme
do
    local g = EX.env()
    if type(g.PIDDLE_UNLOAD)=="function" then pcall(g.PIDDLE_UNLOAD) end
    g.PIDDLE_UNLOAD=function() pcall(function() Library:Unload() end) end
end
local TWEEN_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tl(t) t = tostring(t); return Library.LowerCase and string.lower(t) or t end
local function Tween(o,i,p) local t=TweenService:Create(o,i or TWEEN_FAST,p); t:Play(); return t end
local function New(c, p, ch)
    local i = Instance.new(c)
    if c=="TextButton" or c=="ImageButton" then i.AutoButtonColor=false end
    if c=="Frame" or c=="TextButton" or c=="ScrollingFrame" or c=="ImageLabel" or c=="ImageButton" then i.BorderSizePixel=0 end
    for k,v in pairs(p or {}) do if k~="Parent" then i[k]=v end end
    for _,x in ipairs(ch or {}) do x.Parent=i end
    if p and p.Parent then i.Parent=p.Parent end
    return i
end
local function Corner(p,r) return New("UICorner",{CornerRadius=UDim.new(0,r or 4),Parent=p}) end
local function Stroke(p,c,t,tr) return New("UIStroke",{Color=c or Theme.Stroke,Thickness=t or 1,Transparency=tr or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=p}) end
local function Padding(p,l,t,r,b) return New("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingTop=UDim.new(0,t or 0),PaddingRight=UDim.new(0,r or 0),PaddingBottom=UDim.new(0,b or 0),Parent=p}) end
local function List(p,pad,dir,ha,va) return New("UIListLayout",{Padding=UDim.new(0,pad or 0),FillDirection=dir or Enum.FillDirection.Vertical,HorizontalAlignment=ha or Enum.HorizontalAlignment.Left,VerticalAlignment=va or Enum.VerticalAlignment.Top,SortOrder=Enum.SortOrder.LayoutOrder,Parent=p}) end
local function Connect(s,fn) local c=s:Connect(fn); table.insert(Library.Connections,c); return c end
local function Label(p) local b={BackgroundTransparency=1,Font=Theme.Font,TextSize=11,TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false}; for k,v in pairs(p) do b[k]=v end; return New("TextLabel",b) end
local function IsPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function IsMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end
local function Clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function Round(v,s) if not s or s<=0 then return v end return math.floor(v/s+0.5)*s end
local function FormatNumber(v,s)
    if s and s<1 then local d=math.max(0,math.ceil(-math.log10(s))); return string.format("%."..d.."f",v) end
    return tostring(math.floor(v+0.5))
end
local function ResolveImage(src)
    if src==nil or src=="" then return "" end
    if typeof(src)=="number" then return "rbxassetid://"..src end
    if typeof(src)~="string" then return "" end
    if src:find("^rbxasset") or src:find("^rbxthumb") then return src end
    if src:match("^%d+$") then return "rbxassetid://"..src end
    return src
end
local function GetGuiParent()
    if EX.guiParent and EX.guiParent.Parent then return EX.guiParent end
    local cands={
        function() return (type(gethui)=="function") and gethui() or nil end,
        function() return game:GetService("CoreGui") end,
        function() return LocalPlayer:WaitForChild("PlayerGui",10) end,
    }
    for _,get in ipairs(cands) do
        local ok,p=pcall(get)
        if ok and p then
            local probe=Instance.new("Folder")
            local ok2=pcall(function() probe.Parent=p end)
            local good=ok2 and probe.Parent==p
            pcall(function() probe:Destroy() end)
            if good then EX.guiParent=p; return p end
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local Sounds = { Click = "rbxassetid://535716488", Load = "rbxassetid://535716488" }
local function playSound(id, vol)
    if not id or id == "" then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 1
    s.Parent = SoundService
    s:Play()
    Debris:AddItem(s, 5)
end

UIS.MouseIconEnabled = true

local function MakeDraggable(handle, target, getScale, onClick)
    local dragging, startPos, startMouse, moved
    Connect(handle.InputBegan, function(i) if IsPress(i) then dragging=true; moved=0; startMouse=i.Position; startPos=target.Position; EX.modal(true) end end)
    Connect(UIS.InputChanged, function(i) if dragging and IsMove(i) then
        local d=i.Position-startMouse; moved=math.max(moved,d.Magnitude)
        local s=getScale and getScale() or 1
        target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X/s,startPos.Y.Scale,startPos.Y.Offset+d.Y/s)
    end end)
    Connect(UIS.InputEnded, function(i) if dragging and IsPress(i) then if onClick and moved<5 then onClick() end; dragging=false; EX.modal(false) end end)
end

local Container = {}; Container.__index = Container
function Container:_register(el,row,name) el.Row=row; el.SearchName=string.lower(name or ""); table.insert(self.Elements,el); if el.Flag then Library.Flags[el.Flag]=el.Value; Library.Options[el.Flag]=el end; return el end
function Container:_row(h) self._order=(self._order or 0)+1; return New("Frame",{Size=UDim2.new(1,0,0,h or 22),BackgroundTransparency=1,LayoutOrder=self._order,Parent=self.Holder}) end
local function Fire(el,...)
    if el.Flag then Library.Flags[el.Flag]=el.Value end
    local ok,err=pcall(el.Callback,...)
    if not ok then warn("[DogUI] "..tostring(el.Name)..": "..tostring(err)) end
    for _,fn in ipairs(el._changed) do pcall(fn,...) end
end
function Container:AddLabel(cfg)
    if type(cfg)=="string" then cfg={Name=cfg} end
    local el={Type="Label",Name=cfg.Name or "label",_changed={},Callback=function() end}
    local row=self:_row(cfg.Height or 18)
    local lbl=Label({Size=UDim2.new(1,-12,1,0),Position=UDim2.fromOffset(8,0),Text=cfg.Raw and cfg.Name or tl(cfg.Name or "label"),TextColor3=cfg.Color or Theme.Dim,TextSize=cfg.TextSize or 10,TextWrapped=true,Parent=row})
    function el:SetText(t) lbl.Text=cfg.Raw and t or tl(t) end
    return self:_register(el,row,el.Name)
end
function Container:AddParagraph(name, body)
    local el={Type="Paragraph",Name=name,_changed={},Callback=function() end}
    local row=self:_row(48)
    Label({Size=UDim2.new(1,-12,0,14),Position=UDim2.fromOffset(8,4),Text=tl(name),TextColor3=Theme.Text,TextSize=11,Parent=row})
    Label({Size=UDim2.new(1,-12,0,28),Position=UDim2.fromOffset(8,18),Text=tl(body),TextColor3=Theme.Dimmer,TextSize=9,TextWrapped=true,Parent=row})
    return self:_register(el,row,el.Name)
end
function Container:AddDivider()
    local el={Type="Divider",Name="",_changed={},Callback=function() end}
    local row=self:_row(8)
    New("Frame",{Size=UDim2.new(1,-16,0,1),Position=UDim2.new(0,8,0.5,0),BackgroundColor3=Theme.Stroke,Parent=row})
    return self:_register(el,row,"")
end
function Container:AddButton(cfg)
    cfg=cfg or {}
    local el={Type="Button",Name=cfg.Name or "button",Callback=cfg.Callback or function() end,_changed={}}
    local row=self:_row(26)
    local btn=New("TextButton",{Size=UDim2.new(1,-12,0,20),Position=UDim2.new(0,6,0.5,-10),BackgroundColor3=Theme.Box,Text="",Parent=row})
    Corner(btn,4); Stroke(btn,Theme.Stroke)
    local txt=Label({Size=UDim2.fromScale(1,1),Text=tl(el.Name),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Theme.Dim,Parent=btn})
    Connect(btn.MouseEnter,function() Tween(btn,TWEEN_FAST,{BackgroundColor3=Theme.Row}); Tween(txt,TWEEN_FAST,{TextColor3=Theme.Text}) end)
    Connect(btn.MouseLeave,function() Tween(btn,TWEEN_FAST,{BackgroundColor3=Theme.Box}); Tween(txt,TWEEN_FAST,{TextColor3=Theme.Dim}) end)
    Connect(btn.MouseButton1Down,function() Tween(btn,TWEEN_FAST,{BackgroundColor3=Theme.Accent}); Tween(txt,TWEEN_FAST,{TextColor3=Theme.Check}) end)
    Connect(btn.MouseButton1Up,function() Tween(btn,TWEEN_FAST,{BackgroundColor3=Theme.Row}); Tween(txt,TWEEN_FAST,{TextColor3=Theme.Text}) end)
    Connect(btn.MouseButton1Click,function() playSound(Sounds.Click, 0.5); Fire(el) end)
    function el:SetText(t) txt.Text=tl(t) end
    return self:_register(el,row,el.Name)
end
local function DrawCheck(box)
    local s=New("Frame",{Size=UDim2.fromOffset(2,4),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(4,7.5),Rotation=-45,BackgroundColor3=Theme.Check,BackgroundTransparency=1,Parent=box})
    local l=New("Frame",{Size=UDim2.fromOffset(2,8),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(7.5,5.5),Rotation=45,BackgroundColor3=Theme.Check,BackgroundTransparency=1,Parent=box})
    return s,l
end
function Container:AddToggle(cfg)
    cfg=cfg or {}
    local el={Type="Toggle",Name=cfg.Name or "toggle",Flag=cfg.Flag,Value=cfg.Default and true or false,Callback=cfg.Callback or function() end,_changed={}}
    local row=self:_row(22)
    local hit=New("TextButton",{Size=UDim2.new(1,cfg.Options and -26 or 0,1,0),BackgroundTransparency=1,Text="",Parent=row})
    local box=New("Frame",{Size=UDim2.fromOffset(12,12),Position=UDim2.new(0,8,0.5,-6),BackgroundColor3=Theme.Box,Parent=row})
    Corner(box,3); local bs=Stroke(box,Theme.Stroke)
    local c1,c2=DrawCheck(box)
    local lbl=Label({Size=UDim2.new(1,-34,1,0),Position=UDim2.fromOffset(28,0),Text=tl(el.Name),TextColor3=Theme.Dim,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row})
    local function Render(animate)
        local on=el.Value
        local info=animate and TWEEN_FAST or TweenInfo.new(0)
        Tween(box,info,{BackgroundColor3=on and Theme.Accent or Theme.Box})
        Tween(bs,info,{Color=on and Theme.Accent or Theme.Stroke})
        Tween(c1,info,{BackgroundTransparency=on and 0 or 1})
        Tween(c2,info,{BackgroundTransparency=on and 0 or 1})
        Tween(lbl,info,{TextColor3=on and Theme.Text or Theme.Dim})
    end
    function el:Set(v,silent) v=v and true or false; if self.Value==v then return end; self.Value=v; Render(true); if not silent then Fire(self,v) elseif self.Flag then Library.Flags[self.Flag]=v end end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed,fn) end
    Connect(hit.MouseButton1Click,function() playSound(Sounds.Click, 0.5); el:Set(not el.Value) end)
    Connect(hit.MouseEnter,function() if not el.Value then Tween(lbl,TWEEN_FAST,{TextColor3=Theme.Text}) end end)
    Connect(hit.MouseLeave,function() if not el.Value then Tween(lbl,TWEEN_FAST,{TextColor3=Theme.Dim}) end end)
    Render(false)
    return self:_register(el,row,el.Name)
end
function Container:AddSlider(cfg)
    cfg=cfg or {}
    local min,max=cfg.Min or 0,cfg.Max or 100
    local step=cfg.Increment or 1
    local el={Type="Slider",Name=cfg.Name or "slider",Flag=cfg.Flag,Value=Clamp(cfg.Default or min,min,max),Callback=cfg.Callback or function() end,_changed={}}
    local suffix=cfg.Suffix or ""
    local row=self:_row(32)
    Label({Size=UDim2.new(1,-60,0,16),Position=UDim2.fromOffset(8,2),Text=tl(el.Name),TextColor3=Theme.Dim,Parent=row})
    local vl=Label({Size=UDim2.new(0,50,0,16),Position=UDim2.new(1,-58,0,2),TextXAlignment=Enum.TextXAlignment.Right,Text="",TextColor3=Theme.Text,TextSize=10,Parent=row})
    local hit=New("TextButton",{Size=UDim2.new(1,-12,0,14),Position=UDim2.fromOffset(6,18),BackgroundTransparency=1,Text="",Parent=row})
    local track=New("Frame",{Size=UDim2.new(1,-4,0,4),Position=UDim2.new(0,2,0.5,-2),BackgroundColor3=Theme.Box,Parent=hit})
    Corner(track,2); Stroke(track,Theme.Stroke)
    local fill=New("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=Theme.Accent,Parent=track}); Corner(fill,2)
    local knob=New("Frame",{Size=UDim2.fromOffset(8,8),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),BackgroundColor3=Theme.Accent,Parent=track}); Corner(knob,4)
    local function Render(animate)
        local a=(el.Value-min)/math.max(max-min,1e-9)
        local info=animate and TWEEN_FAST or TweenInfo.new(0)
        Tween(fill,info,{Size=UDim2.fromScale(a,1)}); Tween(knob,info,{Position=UDim2.fromScale(a,0.5)})
        vl.Text=FormatNumber(el.Value,step)..suffix
    end
    function el:Set(v,silent) v=Clamp(Round(v,step),min,max); if v==self.Value then return end; self.Value=v; Render(true); if not silent then Fire(self,v) elseif self.Flag then Library.Flags[self.Flag]=v end end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed,fn) end
    local dragging=false
    local function FromInput(i) local a=Clamp((i.Position.X-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1); el:Set(min+(max-min)*a) end
    Connect(hit.InputBegan,function(i) if IsPress(i) then dragging=true; self.Window:_lockDrag(true); EX.modal(true); Tween(knob,TWEEN_FAST,{Size=UDim2.fromOffset(10,10)}); FromInput(i) end end)
    Connect(UIS.InputEnded,function(i) if dragging and IsPress(i) then dragging=false; self.Window:_lockDrag(false); EX.modal(false); Tween(knob,TWEEN_FAST,{Size=UDim2.fromOffset(8,8)}) end end)
    Connect(UIS.InputChanged,function(i) if dragging and IsMove(i) then FromInput(i) end end)
    Render(false)
    return self:_register(el,row,el.Name)
end

function Container:AddDropdown(cfg)
    cfg=cfg or {}
    local values=cfg.Values or {}
    local multi=cfg.Multi
    local el={Type="Dropdown",Name=cfg.Name or "dropdown",Flag=cfg.Flag,Values=values,Callback=cfg.Callback or function() end,_changed={},Multi=multi}
    if multi then el.Value={}; for _,v in ipairs(cfg.Default or {}) do el.Value[v]=true end else el.Value=cfg.Default end
    self._order=(self._order or 0)+1
    local row=New("Frame",{Size=UDim2.new(1,0,0,22),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=self._order,Parent=self.Holder})
    List(row,2,nil,Enum.HorizontalAlignment.Center)
    local head=New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text="",LayoutOrder=1,Parent=row})
    Label({Size=UDim2.new(0.5,-8,1,0),Position=UDim2.fromOffset(8,0),Text=tl(el.Name),TextColor3=Theme.Dim,Parent=head})
    local box=New("Frame",{Size=UDim2.new(0.5,-10,0,18),Position=UDim2.new(0.5,2,0.5,-9),BackgroundColor3=Theme.Box,Parent=head})
    Corner(box,4); Stroke(box,Theme.Stroke)
    local sel=Label({Size=UDim2.new(1,-18,1,0),Position=UDim2.fromOffset(6,0),TextColor3=Theme.Text,TextSize=10,TextTruncate=Enum.TextTruncate.AtEnd,Text="",Parent=box})
    local arrow=Label({Size=UDim2.fromOffset(12,12),Position=UDim2.new(1,-14,0.5,-6),Text=">",Rotation=90,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Theme.Dim,TextSize=10,Font=Theme.FontBold,Parent=box})
    local list=New("Frame",{Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Theme.Box,Visible=false,LayoutOrder=2,Parent=row})
    list.Position=UDim2.fromOffset(6,0); Corner(list,4); Stroke(list,Theme.Stroke); List(list,0); Padding(list,0,2,0,2)
    local buttons={}; local open=false
    local function SelectedText()
        if multi then local t={}; for _,v in ipairs(el.Values) do if el.Value[v] then table.insert(t,tostring(v)) end end; return #t==0 and "none" or table.concat(t,", ") end
        return el.Value~=nil and tostring(el.Value) or "none"
    end
    local function Render()
        sel.Text=tl(SelectedText())
        for v,b in pairs(buttons) do
            local on=multi and el.Value[v] or (not multi and el.Value==v)
            Tween(b.Label,TWEEN_FAST,{TextColor3=on and Theme.Accent or Theme.Dim}); b.Dot.Visible=on and true or false
        end
    end
    local function Build()
        for _,b in pairs(buttons) do b.Button:Destroy() end; table.clear(buttons)
        for i,v in ipairs(el.Values) do
            local b=New("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="",LayoutOrder=i,Parent=list})
            local l=Label({Size=UDim2.new(1,-24,1,0),Position=UDim2.fromOffset(8,0),Text=tl(v),TextColor3=Theme.Dim,TextSize=10,Parent=b})
            local dot=New("Frame",{Size=UDim2.fromOffset(4,4),Position=UDim2.new(1,-12,0.5,-2),BackgroundColor3=Theme.Accent,Visible=false,Parent=b}); Corner(dot,2)
            buttons[v]={Button=b,Label=l,Dot=dot}
            Connect(b.MouseEnter,function() l.TextColor3=Theme.Text end)
            Connect(b.MouseLeave,function() local on=multi and el.Value[v] or (not multi and el.Value==v); l.TextColor3=on and Theme.Accent or Theme.Dim end)
            Connect(b.MouseButton1Click,function()
                playSound(Sounds.Click, 0.5)
                if multi then el.Value[v]=not el.Value[v] or nil
                else el.Value=v open=false list.Visible=false Tween(arrow,TWEEN_FAST,{Rotation=90}) end
                Render(); Fire(el,el.Value)
            end)
        end
        Render()
    end
    function el:Set(v,silent)
        if multi then self.Value={}; for k,on in pairs(v) do if type(k)=="number" then self.Value[on]=true elseif on then self.Value[k]=true end end
        else self.Value=v end
        Render()
        if not silent then Fire(self,self.Value) elseif self.Flag then Library.Flags[self.Flag]=self.Value end
    end
    function el:Get() return self.Value end
    function el:SetValues(nv) self.Values=nv Build() end
    function el:OnChanged(fn) table.insert(self._changed,fn) end
    Connect(head.MouseButton1Click,function() playSound(Sounds.Click, 0.5); open=not open; list.Visible=open; Tween(arrow,TWEEN_FAST,{Rotation=open and -90 or 90}) end)
    Build()
    return self:_register(el,row,el.Name)
end

function Container:AddTextbox(cfg)
    cfg=cfg or {}
    local el={Type="Textbox",Name=cfg.Name or "textbox",Flag=cfg.Flag,Value=tostring(cfg.Default or ""),Callback=cfg.Callback or function() end,_changed={}}
    local row=self:_row(28)
    Label({Size=UDim2.new(0.4,-8,1,0),Position=UDim2.fromOffset(8,0),Text=tl(el.Name),TextColor3=Theme.Dim,Parent=row})
    local holder=New("Frame",{Size=UDim2.new(0.6,-10,0,20),Position=UDim2.new(0.4,2,0.5,-10),BackgroundColor3=Theme.Box,Parent=row})
    Corner(holder,4); local st=Stroke(holder,Theme.Stroke)
    local box=New("TextBox",{Size=UDim2.new(1,-10,1,0),Position=UDim2.fromOffset(5,0),BackgroundTransparency=1,Text=el.Value,PlaceholderText=cfg.Placeholder or "",PlaceholderColor3=Theme.Dimmer,TextColor3=Theme.Text,Font=Theme.Font,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=holder})
    function el:Set(v,silent) self.Value=tostring(v); box.Text=self.Value; if not silent then Fire(self,self.Value) elseif self.Flag then Library.Flags[self.Flag]=self.Value end end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed,fn) end
    Connect(box.Focused,function() Tween(st,TWEEN_FAST,{Color=Theme.Accent}) end)
    Connect(box.FocusLost,function() Tween(st,TWEEN_FAST,{Color=Theme.Stroke}); el.Value=box.Text; Fire(el,el.Value) end)
    return self:_register(el,row,el.Name)
end

function Container:AddColorPicker(cfg)
    cfg=cfg or {}
    local el={Type="ColorPicker",Name=cfg.Name or "color",Flag=cfg.Flag,Value=cfg.Default or Color3.fromRGB(255,255,255),Callback=cfg.Callback or function() end,_changed={}}
    local h,s,v=el.Value:ToHSV()
    self._order=(self._order or 0)+1
    local row=New("Frame",{Size=UDim2.new(1,0,0,22),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=self._order,Parent=self.Holder})
    List(row,2,nil,Enum.HorizontalAlignment.Center)
    local head=New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text="",LayoutOrder=1,Parent=row})
    Label({Size=UDim2.new(1,-40,1,0),Position=UDim2.fromOffset(8,0),Text=tl(el.Name),TextColor3=Theme.Dim,Parent=head})
    local swatch=New("Frame",{Size=UDim2.fromOffset(22,12),Position=UDim2.new(1,-30,0.5,-6),BackgroundColor3=el.Value,Parent=head}); Corner(swatch,3); Stroke(swatch,Theme.Stroke)
    local panel=New("Frame",{Size=UDim2.new(1,-12,0,78),Position=UDim2.fromOffset(6,0),BackgroundColor3=Theme.Box,Visible=false,LayoutOrder=2,Parent=row}); Corner(panel,4); Stroke(panel,Theme.Stroke)
    local sv=New("TextButton",{Size=UDim2.new(1,-40,1,-12),Position=UDim2.fromOffset(6,6),BackgroundColor3=Color3.fromHSV(h,1,1),Text="",ClipsDescendants=true,Parent=panel}); Corner(sv,3)
    local white=New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),Parent=sv}); New("UIGradient",{Transparency=NumberSequence.new(0,1),Parent=white})
    local black=New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),Parent=sv}); New("UIGradient",{Transparency=NumberSequence.new(1,0),Rotation=90,Parent=black})
    local svC=New("Frame",{Size=UDim2.fromOffset(6,6),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),ZIndex=3,Parent=sv}); Corner(svC,3); Stroke(svC,Color3.new(0,0,0),1)
    local hue=New("TextButton",{Size=UDim2.new(0,14,1,-12),Position=UDim2.new(1,-22,0,6),BackgroundColor3=Color3.new(1,1,1),Text="",Parent=panel}); Corner(hue,3)
    New("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),ColorSequenceKeypoint.new(0.5,Color3.fromHSV(0.5,1,1)),ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1))}),Parent=hue})
    local hueC=New("Frame",{Size=UDim2.new(1,4,0,3),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),ZIndex=3,Parent=hue}); Corner(hueC,2); Stroke(hueC,Color3.new(0,0,0),1)
    local function Render(fire)
        el.Value=Color3.fromHSV(h,s,v)
        swatch.BackgroundColor3=el.Value; sv.BackgroundColor3=Color3.fromHSV(h,1,1)
        svC.Position=UDim2.fromScale(s,1-v); hueC.Position=UDim2.new(0.5,0,h,0)
        if fire then Fire(el,el.Value) elseif el.Flag then Library.Flags[el.Flag]=el.Value end
    end
    function el:Set(c,silent) h,s,v=c:ToHSV(); Render(not silent) end
    function el:Get() return self.Value end
    function el:OnChanged(fn) table.insert(self._changed,fn) end
    local mode
    local function Update(i)
        if mode=="sv" then s=Clamp((i.Position.X-sv.AbsolutePosition.X)/math.max(sv.AbsoluteSize.X,1),0,1); v=1-Clamp((i.Position.Y-sv.AbsolutePosition.Y)/math.max(sv.AbsoluteSize.Y,1),0,1)
        elseif mode=="hue" then h=Clamp((i.Position.Y-hue.AbsolutePosition.Y)/math.max(hue.AbsoluteSize.Y,1),0,0.999) end
        Render(true)
    end
    Connect(sv.InputBegan,function(i) if IsPress(i) then mode="sv"; self.Window:_lockDrag(true); EX.modal(true); Update(i) end end)
    Connect(hue.InputBegan,function(i) if IsPress(i) then mode="hue"; self.Window:_lockDrag(true); EX.modal(true); Update(i) end end)
    Connect(UIS.InputChanged,function(i) if mode and IsMove(i) then Update(i) end end)
    Connect(UIS.InputEnded,function(i) if mode and IsPress(i) then mode=nil; self.Window:_lockDrag(false); EX.modal(false) end end)
    Connect(head.MouseButton1Click,function() playSound(Sounds.Click, 0.5); panel.Visible=not panel.Visible end)
    Render(false)
    return self:_register(el,row,el.Name)
end

local function NewSection(tab,cfg)
    local sec=setmetatable({Name=cfg.Name or "section",Elements={},Window=tab.Window,Tab=tab,_order=0,Collapsed=false},Container)
    local column=(cfg.Side=="Right" or cfg.Side==2) and tab.RightColumn or tab.LeftColumn
    sec.Frame=New("Frame",{Size=UDim2.new(1,0,0,22),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Theme.Section,LayoutOrder=(#tab.Sections+1),Parent=column})
    Corner(sec.Frame,5); Stroke(sec.Frame,Theme.StrokeSoft); List(sec.Frame,0)
    local head=New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundColor3=Theme.SectionHead,Text="",LayoutOrder=0,Parent=sec.Frame}); Corner(head,5)
    New("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,1,-5),BackgroundColor3=Theme.SectionHead,Parent=head})
    Label({Size=UDim2.new(1,-30,1,0),Position=UDim2.fromOffset(8,0),Text=tl(sec.Name),TextColor3=Theme.Text,Font=Theme.FontBold,TextSize=10,Parent=head})
    local arrow=Label({Size=UDim2.fromOffset(14,14),Position=UDim2.new(1,-20,0.5,-7),Text=">",Rotation=-90,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Theme.Dim,Font=Theme.FontBold,TextSize=10,Parent=head})
    sec.Holder=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1,ClipsDescendants=false,Parent=sec.Frame})
    List(sec.Holder,0); Padding(sec.Holder,0,3,0,4)
    Connect(head.MouseButton1Click,function() playSound(Sounds.Click, 0.5); sec.Collapsed=not sec.Collapsed; sec.Holder.Visible=not sec.Collapsed; Tween(arrow,TWEEN_FAST,{Rotation=sec.Collapsed and 90 or -90}) end)
    table.insert(tab.Sections,sec)
    return sec
end

local Window={}; Window.__index=Window
function Window:_lockDrag(state) self._dragLocked=state end
function Window:_closePopup() if self._activePopup then self._activePopup.Frame.Visible=false; self._activePopup=nil end end
function Window:_applySearch()
    local q=string.lower(self.SearchBox.Text or "")
    local tab=self.CurrentTab; if not tab then return end
    for _,sec in ipairs(tab.Sections) do
        local any=false
        for _,el in ipairs(sec.Elements) do
            local match=q=="" or (el.SearchName~="" and el.SearchName:find(q,1,true)~=nil)
            if el.Type=="Divider" then match=q=="" end
            el.Row.Visible=match; any=any or match
        end
        sec.Frame.Visible=q=="" or any or string.lower(sec.Name):find(q,1,true)~=nil
    end
end
function Window:SelectTab(tab)
    if self.CurrentTab==tab then return end
    self:_closePopup()
    local prev=self.CurrentTab
    if prev then
        prev.Page.Visible=false
        Tween(prev.Bg,TWEEN_FAST,{BackgroundTransparency=1}); Tween(prev.Bar,TWEEN_FAST,{BackgroundTransparency=1})
        Tween(prev.NameLabel,TWEEN_FAST,{TextColor3=Theme.Dim}); Tween(prev.IconRing,TWEEN_FAST,{Color=Theme.Dimmer})
    end
    self.CurrentTab=tab; tab.Page.Visible=true
    Tween(tab.Bg,TWEEN_FAST,{BackgroundTransparency=0.35}); Tween(tab.Bar,TWEEN_FAST,{BackgroundTransparency=0})
    Tween(tab.NameLabel,TWEEN_FAST,{TextColor3=Theme.Text}); Tween(tab.IconRing,TWEEN_FAST,{Color=Theme.Accent})
    self:_applySearch()
end
function Window:SetVisible(state)
    self.Visible=state
    if state then
        self.Root.Visible=true
        Tween(self.UIScale,TWEEN_MED,{Scale=self._baseScale})
        Tween(self.Main,TWEEN_MED,{BackgroundTransparency=0})
        if self.TopImg then self.TopImg.Visible = self._topImageOn ~= false end
    else
        self:_closePopup()
        Tween(self.UIScale,TWEEN_FAST,{Scale=self._baseScale*0.94})
        Tween(self.Main,TWEEN_FAST,{BackgroundTransparency=1})
        if self.TopImg then self.TopImg.Visible = false end
        task.delay(0.16,function() if not self.Visible and self.Root then self.Root.Visible=false end end)
    end
end
function Window:Toggle() self:SetVisible(not self.Visible) end

local function BuildTab(window,cfg,parentTab)
    local tab={Name=cfg.Name or "tab",Subtitle=cfg.Subtitle or "",Window=window,Sections={},Parent=parentTab,Children={},Collapsed=false}
    local container=parentTab and parentTab.ChildHolder or window.TabList
    tab.Group=New("Frame",{Size=UDim2.new(1,0,0,36),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=(#container:GetChildren()),Parent=container})
    List(tab.Group,1)
    local indent=parentTab and 14 or 0
    local btn=New("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Text="",LayoutOrder=0,Parent=tab.Group})
    tab.Button=btn
    tab.Bg=New("Frame",{Size=UDim2.new(1,-10,1,-2),Position=UDim2.fromOffset(5,1),BackgroundColor3=Theme.Row,BackgroundTransparency=1,Parent=btn}); Corner(tab.Bg,5)
    tab.Bar=New("Frame",{Size=UDim2.fromOffset(2,16),Position=UDim2.new(0,0,0.5,-8),BackgroundColor3=Theme.Accent,BackgroundTransparency=1,Parent=btn}); Corner(tab.Bar,1)
    local iconHolder=New("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(0,14+indent,0.5,-7),BackgroundTransparency=1,Parent=btn})
    if cfg.Icon and cfg.Icon~="" then
        New("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=ResolveImage(cfg.Icon),ImageColor3=Theme.Dim,Parent=iconHolder})
        tab.IconRing=New("UIStroke",{Thickness=0,Parent=iconHolder})
    else
        local ring=New("Frame",{Size=UDim2.fromOffset(10,10),Position=UDim2.fromOffset(2,2),BackgroundTransparency=1,Parent=iconHolder})
        Corner(ring,parentTab and 5 or 3); tab.IconRing=Stroke(ring,Theme.Dimmer,1.2)
    end
    tab.NameLabel=Label({Size=UDim2.new(1,-60-indent,0,14),Position=UDim2.new(0,36+indent,0,5),Text=tl(tab.Name),TextColor3=Theme.Dim,TextSize=11,Font=Theme.Font,Parent=btn})
    Label({Size=UDim2.new(1,-60-indent,0,11),Position=UDim2.new(0,36+indent,0,18),Text=tl(tab.Subtitle),TextColor3=Theme.Dimmer,TextSize=8,Font=Theme.FontLight,Parent=btn})
    tab.ChildHolder=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1,Visible=true,Parent=tab.Group})
    List(tab.ChildHolder,1)
    function tab:AddSection(c) if type(c)=="string" then c={Name=c} end; return NewSection(self,c) end
    tab.Page=New("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=Theme.Dimmer,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Never,Parent=window.PageHolder})
    Padding(tab.Page,0,0,4,6)
    tab.LeftColumn=New("Frame",{Size=UDim2.new(0.5,-3,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=tab.Page}); List(tab.LeftColumn,6)
    tab.RightColumn=New("Frame",{Size=UDim2.new(0.5,-3,0,0),Position=UDim2.new(0.5,3,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=tab.Page}); List(tab.RightColumn,6)
    Connect(btn.MouseEnter,function() if window.CurrentTab~=tab then Tween(tab.NameLabel,TWEEN_FAST,{TextColor3=Theme.Text}) end end)
    Connect(btn.MouseLeave,function() if window.CurrentTab~=tab then Tween(tab.NameLabel,TWEEN_FAST,{TextColor3=Theme.Dim}) end end)
    Connect(btn.MouseButton1Click,function() playSound(Sounds.Click, 0.5); window:SelectTab(tab) end)
    table.insert(window.Tabs,tab)
    if not window.CurrentTab then window:SelectTab(tab) end
    return tab
end
function Window:AddTab(cfg) if type(cfg)=="string" then cfg={Name=cfg} end; return BuildTab(self,cfg,nil) end

function Library:Notify(cfg)
    cfg=type(cfg)=="string" and {Text=cfg} or (cfg or {})
    local gui=self.Gui; if not gui then return end
    if not self.NotifyHolder then
        self.NotifyHolder=New("Frame",{Size=UDim2.fromOffset(230,400),Position=UDim2.new(1,-240,0,14),BackgroundTransparency=1,Parent=gui})
        List(self.NotifyHolder,6,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Right)
    end
    local duration=cfg.Duration or 4
    local slot=New("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1,Parent=self.NotifyHolder})
    local card=New("Frame",{Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(240,0),BackgroundColor3=Theme.Window,Parent=slot})
    Corner(card,6); Stroke(card,Theme.Stroke)
    local bar=New("Frame",{Size=UDim2.new(0,2,1,-14),Position=UDim2.fromOffset(6,7),BackgroundColor3=cfg.Color or Theme.Accent,Parent=card}); Corner(bar,1)
    Label({Size=UDim2.new(1,-24,0,16),Position=UDim2.fromOffset(16,6),Text=tl(cfg.Title or "notification"),Font=Theme.FontBold,Parent=card})
    Label({Size=UDim2.new(1,-24,0,16),Position=UDim2.fromOffset(16,23),Text=tl(cfg.Text or ""),TextColor3=Theme.Dim,TextSize=10,TextTruncate=Enum.TextTruncate.AtEnd,Parent=card})
    local life=New("Frame",{Size=UDim2.new(1,-12,0,1),Position=UDim2.new(0,6,1,-3),BackgroundColor3=Theme.Dimmer,Parent=card})
    Tween(card,TWEEN_MED,{Position=UDim2.fromOffset(0,0)})
    Tween(life,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,1)})
    task.delay(duration,function() if card.Parent then Tween(card,TWEEN_MED,{Position=UDim2.fromOffset(240,0)}); task.wait(0.25); slot:Destroy() end end)
end

function Library:CreateWindow(cfg)
    cfg=cfg or {}
    if not self.Gui then
        local gui=New("ScreenGui",{Name=HttpService:GenerateGUID(false),ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999})
        gui.Parent=GetGuiParent(); self.Gui=gui
    end
    local win=setmetatable({Tabs={},Visible=true,Library=self,_dragLocked=false},Window)
    local size=cfg.Size or Vector2.new(420,440)
    local sidebarW=cfg.SidebarWidth or 130
    win.Root = New("Frame",{Name="Root", Size=UDim2.fromOffset(size.X, size.Y + 200), AnchorPoint=Vector2.new(0.5,0.5), Position=cfg.Position or UDim2.fromScale(0.5,0.5), BackgroundTransparency=1, Parent=self.Gui, Active=true})
    win.UIScale=New("UIScale",{Scale=1,Parent=win.Root}); win._baseScale=1
    win.TopImg = New("ImageLabel", {Name="TopImage", Size=UDim2.fromOffset(150,120), AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,4,0,196), BackgroundTransparency=1, Visible=false, ScaleType=Enum.ScaleType.Fit, Parent=win.Root})
    win._topImageOn = true
    win.Main=New("Frame",{Name="Main",Size=UDim2.fromOffset(size.X, size.Y), Position=UDim2.new(0,0,0,200), BackgroundColor3=Theme.Window,Parent=win.Root,Active=true})
    Corner(win.Main,8); Stroke(win.Main,Theme.Stroke,1)
    win.BgImage=New("ImageLabel",{Name="BgImage",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=ResolveImage(cfg.Background),ImageTransparency=0.4,ScaleType=Enum.ScaleType.Crop,ZIndex=0,Parent=win.Main}); Corner(win.BgImage,8)
    win.Sidebar=New("Frame",{Size=UDim2.new(0,sidebarW,1,0),BackgroundColor3=Theme.Sidebar,BackgroundTransparency=0.2,ZIndex=1,Parent=win.Main})
    New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=Theme.StrokeSoft,Parent=win.Sidebar})
    local logoHolder=New("Frame",{Size=UDim2.new(1,0,0,78),BackgroundTransparency=1,Parent=win.Sidebar})
    win.Logo=New("ImageLabel",{Size=UDim2.fromOffset(cfg.LogoSize or 56,cfg.LogoSize or 56),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),BackgroundTransparency=1,Image=ResolveImage(cfg.Logo),ImageColor3=Color3.new(1,1,1),ScaleType=Enum.ScaleType.Fit,Parent=logoHolder})
    win.TabScroll=New("ScrollingFrame",{Size=UDim2.new(1,0,1,-78-80),Position=UDim2.fromOffset(0,78),BackgroundTransparency=1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=win.Sidebar})
    win.TabList=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=win.TabScroll}); List(win.TabList,1)
    local profile=New("Frame",{Size=UDim2.new(1,-12,0,68),Position=UDim2.new(0,6,1,-74),BackgroundColor3=Theme.Section,Parent=win.Sidebar})
    Corner(profile,6); Stroke(profile,Theme.StrokeSoft)
    local avatar=New("ImageLabel",{Size=UDim2.fromOffset(36,36),Position=UDim2.fromOffset(6,6),BackgroundColor3=Theme.Box,Image="",Parent=profile})
    Corner(avatar,18)
    task.spawn(function()
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
        if ok and img then avatar.Image = img end
    end)
    local nameLbl=Label({Size=UDim2.new(1,-50,0,14),Position=UDim2.fromOffset(48,6),Text=LocalPlayer.Name,Font=Theme.FontBold,TextColor3=Theme.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=profile})
    local roleLbl=Label({Size=UDim2.new(1,-50,0,12),Position=UDim2.fromOffset(48,20),Text="Role: --",Font=Theme.Font,TextColor3=Theme.Dim,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,Parent=profile})
    local idLbl=Label({Size=UDim2.new(1,-50,0,12),Position=UDim2.fromOffset(48,32),Text="ID: "..LocalPlayer.UserId,Font=Theme.Font,TextColor3=Theme.Dimmer,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,Parent=profile})
    local pingLbl=Label({Size=UDim2.new(1,-50,0,12),Position=UDim2.fromOffset(48,44),Text="Ping: --",Font=Theme.Font,TextColor3=Theme.Dimmer,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,Parent=profile})
    local profileBtn = New("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=profile})
    Connect(profileBtn.MouseButton1Click, function()
        playSound(Sounds.Click, 0.5)
        EX.clip(tostring(LocalPlayer.UserId))
        Library:Notify({Title="Profile", Text="User ID copied to clipboard", Duration=3})
    end)
    win.Content=New("Frame",{Size=UDim2.new(1,-sidebarW,1,0),Position=UDim2.fromOffset(sidebarW,0),BackgroundTransparency=1,Parent=win.Main})
    local search=New("Frame",{Size=UDim2.new(1,-12,0,28),Position=UDim2.fromOffset(6,6),BackgroundColor3=Theme.Section,Parent=win.Content}); Corner(search,6); Stroke(search,Theme.StrokeSoft)
    win.SearchBox=New("TextBox",{Size=UDim2.new(1,-40,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,Text="",PlaceholderText="Search...",TextColor3=Theme.Text,Font=Theme.Font,TextSize=11,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Parent=search})
    win.PageHolder=New("Frame",{Size=UDim2.new(1,-12,1,-46),Position=UDim2.fromOffset(6,40),BackgroundTransparency=1,Parent=win.Content})
    win.PopupLayer=New("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=50,Parent=win.Main})
    Connect(win.SearchBox:GetPropertyChangedSignal("Text"),function() win:_applySearch() end)
    MakeDraggable(logoHolder,win.Root,function() return win.UIScale.Scale end)
    table.insert(self.Windows,win)
    win.Root.Visible=true
    local key=cfg.Keybind or Enum.KeyCode.RightShift
    Connect(UIS.InputBegan,function(input,processed) if processed then return end; if input.KeyCode==key then win:Toggle() end end)
    return win
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded=true
    for _,c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(self.Connections)
    if self.Gui then pcall(function() self.Gui:Destroy() end); self.Gui=nil end
    for _,w in ipairs(self.Windows) do pcall(function() w.Root:Destroy() end) end
    table.clear(self.Windows)
    UIS.MouseIconEnabled = true
end
local ASSETS = {
    logo = "rbxassetid://116621850916845",
    header_icon = "rbxassetid://139363965217986",
    background = "rbxassetid://83690600042971",
}

local TOP_IMAGES = {
    Furry  = "rbxassetid://128362841824609",
    Pibble = "rbxassetid://129955732475523",
    Anime  = "rbxassetid://127453159406468",
}

local PACKS = {
    Ninja = { Run="656118852", Walk="656121766", Jump="656117878", Idle="656117400", Fall="656115606", Swim="656119721", SwimIdle="656121397", Climb="656114359" },
    Zombie = { Run="616163682", Walk="616168032", Jump="616161997", Idle="616158929", Fall="616157476", Swim="616165109", SwimIdle="616166655", Climb="616156119" },
    Mage = { Run="707861613", Walk="707897309", Jump="707853694", Idle="707742142", Fall="707829716", Swim="707876443", SwimIdle="707894699", Climb="707826056" },
    Pirate = { Run="750783738", Walk="750785693", Jump="750782230", Idle="750781874", Fall="750780242", Swim="750784579", SwimIdle="750785176", Climb="750779899" },
    Robot = { Run="616091570", Walk="616095330", Jump="616090535", Idle="616088211", Fall="616087089", Swim="616092998", SwimIdle="616094091", Climb="616086039" },
}

local EMOTES = {
    Wave="507770239", Point="507770453", Dance="507771019", Laugh="507770818", Cheer="507770677", Salute="3338399990", Shrug="3338403912", Facepalm="3338404383",
    Bow="3338399532", Flex="3338400435", Frog="3338401213", Zombie="3338403061", Pray="3338401416", Sit="507768133", Lay="3338402561", Sword="3338402124", Kick="3338401923",
    Dab="2482643533", Floss="3338400927", DefaultDance="507771955",
}

local BG_LIST = {
    ["Halloween"] = "rbxassetid://85303808547863",
    ["Forest"]    = "rbxassetid://79020220019422",
    ["White Anime"] = "rbxassetid://83690600042971",
    ["Rain"]      = "rbxassetid://107306683089605",
    ["None"]      = "",
}

local hasFile = false
pcall(function() hasFile=(type(writefile)=="function" and type(isfile)=="function") end)

local CFG = {
    speed=16, jump=50, volume=50, shootThroughWalls=true, predictMovement=true,
    selectedPack=nil, korbloxOn=false, headlessOn=false, chinaHatOn=false, chinaHatColor=Color3.fromRGB(255,255,255),
    bgName="Halloween", knifeSkin="Default", gunSkin="Default",
    topImage="Anime", topImageVisible=true, uiScale=100,
    killEffectOn=true, killEffectStyle="confetti", killEffectSelf=false, bulletTracerOn=true, bulletTracerColor=Color3.fromRGB(255,220,80), bulletTracerTime=0.4, bulletTracerWidth=0.12,
    musicOn=false, musicVolume=50,
    warnRoundStart = true, warnRole = true,
    laserColor = Color3.fromRGB(255,50,50),
    laser2Color = Color3.fromRGB(50,150,255),
    autoVote = false, dupe = false, reverse = false, pick = 1, dupeCount = 3, delay = 40,
    espBox = false, espSkeleton = false, antiLag = false,
    autoGunMode = "remote",
    autoFarmMode = "under",
    gunSkinAssetId = "76990190751911",
    knifeSkinAssetId = "5970465447",
    autoFarmReset = true,
}
pcall(function()
    if hasFile and isfile("PiddleConfig.json") then
        local d = HttpService:JSONDecode(readfile("PiddleConfig.json"))
        for k,v in pairs(d) do
            if (k=="bulletTracerColor" or k=="chinaHatColor" or k=="laserColor" or k=="laser2Color" or k=="uiAccent" or k=="uiLine" or k=="tracerCol" or k=="tracerCol2" or k=="sidebarColor") and type(v)=="table" then v=Color3.new(v[1],v[2],v[3]) end
            CFG[k]=v
        end
    end
end)
if type(CFG.gunSkinAssetId)=="number" then CFG.gunSkinAssetId=tostring(CFG.gunSkinAssetId) end
if type(CFG.knifeSkinAssetId)=="number" then CFG.knifeSkinAssetId=tostring(CFG.knifeSkinAssetId) end
if CFG.gunSkinAssetId==nil or CFG.gunSkinAssetId=="" then CFG.gunSkinAssetId="76990190751911" end
if CFG.knifeSkinAssetId==nil or CFG.knifeSkinAssetId=="" then CFG.knifeSkinAssetId="5970465447" end
local function saveCFG()
    local t={}
    for k,v in pairs(CFG) do
        if typeof(v)=="Color3" then t[k]={v.R,v.G,v.B} else t[k]=v end
    end
    pcall(function() EX.env().PIDDLE_CFG_CACHE=t end)
    if not hasFile then return end
    pcall(function() writefile("PiddleConfig.json", HttpService:JSONEncode(t)) end)
end
pcall(function()
    local cache = EX.env().PIDDLE_CFG_CACHE
    if type(cache)=="table" and not (hasFile and isfile("PiddleConfig.json")) then
        for k,v in pairs(cache) do
            if (k=="bulletTracerColor" or k=="chinaHatColor" or k=="laserColor" or k=="laser2Color" or k=="uiAccent" or k=="uiLine" or k=="tracerCol" or k=="tracerCol2" or k=="sidebarColor") and type(v)=="table" then v=Color3.new(v[1],v[2],v[3]) end
            CFG[k]=v
        end
    end
end)

local rolesCache = {}
local function fetchRoles()
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if r and r:IsA("RemoteFunction") then
            local res = r:InvokeServer()
            if res then rolesCache = res end
        end
    end)
end

local function getRole(plr)
    if plr == LocalPlayer then
        if rolesCache[LocalPlayer.Name] then
            local d = rolesCache[LocalPlayer.Name]
            if not d.Killed and not d.Dead then return d.Role or "Innocent" end
        end
        if LocalPlayer.Character then
            if LocalPlayer.Character:FindFirstChild("Knife") then return "Murderer" end
            if LocalPlayer.Character:FindFirstChild("Gun") then return "Sheriff" end
        end
        return "Innocent"
    end
    if not plr.Character or plr.Character.Parent~=WS then return "NPC" end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health<=0 then return "NPC" end
    if plr.UserId<=0 then return "NPC" end
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
end

local function isRealNpc(plr)
    if not plr then return true end
    if plr.UserId<=0 then return true end
    local ch = plr.Character
    if not ch then return true end
    if not ch:FindFirstChildOfClass("Humanoid") then return true end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    if rolesCache[plr.Name] then
        local d = rolesCache[plr.Name]
        if d.Killed or d.Dead then return true end
    end
    local fullPath = ch:GetFullName():lower()
    if fullPath:find("lobby") or fullPath:find("menu") or fullPath:find("spectate") or fullPath:find("intermission") or fullPath:find("npc") or fullPath:find("dummy") then 
        return true 
    end
    return false
end

local function isZombie(plr)
    if not plr or not plr.Character then return false end
    local ch = plr.Character
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false end
    if hum.WalkSpeed <= 10 and hum.WalkSpeed > 0 then return true end
    local name = ch.Name:lower()
    if name:find("zombie") or name:find("infect") then return true end
    if ch:FindFirstChild("ZombieTag") or ch:FindFirstChild("Zombie") then return true end
    return false
end

local function hasItem(plr, item)
    local bp = plr:FindFirstChild("Backpack")
    local ch = plr.Character
    return (bp and bp:FindFirstChild(item)) or (ch and ch:FindFirstChild(item))
end
local function findByRole(role)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and getRole(p)==role then return p end
    end
end
local function findMurderer() return findByRole("Murderer") end
local function findSheriff() return findByRole("Sheriff") end

local Fling = {Active=false, busy=false, allRun=0}
local function stopFling() Fling.Active=false end

function Fling.run(target)
    if not target then return end
    if Fling.busy then
        Fling.Active=false
        for _=1,40 do if not Fling.busy then break end task.wait(0.05) end
    end
    local myChar=LocalPlayer.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum=myChar and myChar:FindFirstChildOfClass("Humanoid")
    local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not (myRoot and myHum and tRoot) or myHum.Health<=0 then return end

    Fling.busy=true; Fling.Active=true
    local home=myRoot.CFrame
    local startPos=tRoot.Position
    local oldFall=WS.FallenPartsDestroyHeight
    pcall(function() WS.FallenPartsDestroyHeight=0/0 end)

    local pp={}
    for _,pt in ipairs(myChar:GetDescendants()) do
        if pt:IsA("BasePart") then
            pp[pt]=pt.CustomPhysicalProperties
            pcall(function() pt.CustomPhysicalProperties=PhysicalProperties.new(100,0.3,0.5) end)
        end
    end
    local spin=Instance.new("BodyAngularVelocity")
    spin.Name="PiddleFling"
    spin.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    spin.P=math.huge
    spin.AngularVelocity=Vector3.new(0,9e5,0)
    spin.Parent=myRoot

    local offsets={Vector3.new(0,1.5,0),Vector3.new(0,-1.5,0),Vector3.new(2.25,1.5,-2.25),Vector3.new(-2.25,-1.5,2.25),Vector3.new(0,1.5,2.25),Vector3.new(0,-1.5,-2.25)}
    local i,t0=0,tick()
    while Fling.Active and tick()-t0<3 do
        local tr=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local th=target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        local mr=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if LocalPlayer.Character~=myChar or not tr or not mr or (th and th.Health<=0) then break end
        if tr.AssemblyLinearVelocity.Magnitude>600 or (tr.Position-startPos).Magnitude>120 then break end
        i=i%#offsets+1
        mr.CFrame=CFrame.new(tr.Position+offsets[i]+tr.AssemblyLinearVelocity*0.1)*CFrame.Angles(math.rad(90*i),0,0)
        mr.AssemblyLinearVelocity=Vector3.new(9e7,9e7*10,9e7)
        mr.AssemblyAngularVelocity=Vector3.new(9e8,9e8,9e8)
        RunService.Heartbeat:Wait()
    end

    pcall(function() spin:Destroy() end)
    if LocalPlayer.Character==myChar then
        local t1=tick()
        while tick()-t1<0.7 do
            local mr=myChar:FindFirstChild("HumanoidRootPart")
            if not mr then break end
            mr.CFrame=home
            mr.AssemblyLinearVelocity=Vector3.zero
            mr.AssemblyAngularVelocity=Vector3.zero
            RunService.Heartbeat:Wait()
        end
    end
    for pt,v in pairs(pp) do if pt.Parent then pcall(function() pt.CustomPhysicalProperties=v end) end end
    if LocalPlayer.Character==myChar and myHum.Parent then pcall(function() myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    pcall(function() WS.FallenPartsDestroyHeight=oldFall end)
    Fling.Active=false; Fling.busy=false
end

local function flingPlayer(target) task.spawn(Fling.run,target) end

function Fling.gunHolder()
    local best
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not isRealNpc(p) and hasItem(p,"Gun") then
            local d=rolesCache[p.Name]
            if d and d.Role=="Hero" then return p end
            best=best or p
        end
    end
    return best
end
function Fling.all()
    Fling.allRun=Fling.allRun+1
    local id=Fling.allRun
    task.spawn(function()
        for _,p in ipairs(Players:GetPlayers()) do
            if Fling.allRun~=id then return end
            if p~=LocalPlayer and p.Character and not isRealNpc(p) and getRole(p)~="NPC" then Fling.run(p) end
        end
    end)
end

local function getKnife()
    local ch = LocalPlayer.Character; if not ch then return nil end
    local k = ch:FindFirstChild("Knife")
    if not k then local bp=LocalPlayer:FindFirstChild("Backpack"); if bp then k=bp:FindFirstChild("Knife") end end
    return k
end
local function getGun()
    local ch = LocalPlayer.Character; if not ch then return end
    local g = ch:FindFirstChild("Gun")
    if not g then local bp=LocalPlayer:FindFirstChild("Backpack"); if bp then g=bp:FindFirstChild("Gun") end end
    return g
end
task.spawn(function() while true do task.wait(1.5); pcall(fetchRoles) end end)
do
    local sig, myRole = "", nil
    task.spawn(function()
        while not Library.Unloaded do
            task.wait(1)
            pcall(function()
                local m, s
                for name, d in pairs(rolesCache) do
                    if type(d) == "table" then
                        if d.Role == "Murderer" then m = name
                        elseif d.Role == "Sheriff" or d.Role == "Hero" then s = s or name end
                    end
                end
                local mine = rolesCache[LocalPlayer.Name]
                local role = type(mine) == "table" and mine.Role or nil
                if m then
                    if sig == "" then
                        if CFG.warnRoundStart then Library:Notify({Title="round", Text="round started", Duration=4}) end
                        if CFG.warnRole and role then
                            local t = "you are " .. tostring(role)
                            if role ~= "Murderer" then t = t .. " | murderer: " .. m end
                            Library:Notify({Title="role", Text=t, Duration=6})
                        end
                        myRole = role
                    elseif CFG.warnRole and role and role ~= myRole then
                        Library:Notify({Title="role", Text="you are now " .. tostring(role), Duration=5})
                        myRole = role
                    end
                    sig = m .. "|" .. (s or "")
                else
                    sig = ""; myRole = nil
                end
            end)
        end
    end)
end

local roleColors = {
    Murderer=Color3.fromRGB(255,60,80), Sheriff=Color3.fromRGB(80,140,255),
    Innocent=Color3.fromRGB(80,220,120), Hero=Color3.fromRGB(255,220,80),
    Gun=Color3.fromRGB(255,180,60), NPC=Color3.fromRGB(180,180,180),
    Zombie=Color3.fromRGB(120,220,80),
}

local State = {
    killAuraOn=false, killAuraCd=0, killAllActive=false, stopKillAll=false,
    autoShoot=false, autoKnife=false, autoThrow=false,
    keepSpeed=false, keepJump=false, flying=false, noclip=false,
    flyBV=nil, flyBG=nil, dSpeed=CFG.speed, dJump=CFG.jump,
    spinOn=false, spinSpd=30, spinA=0,
    autoGun=false, autoRespawn=false, fastRespawn=false, antiVoid=false,
    autoKillAll=false,
    antiAimOn=false,
    aimlockSheriff=false, aimlockZombie=false,
    shootThroughWalls=CFG.shootThroughWalls, predictMovement=CFG.predictMovement,
    playerAuraOn=false, playerAuraColor=Color3.fromRGB(255,100,130), playerAuraPart=nil, playerAuraLight=nil,
    tracersOn=false, touchFlingOn=false, tradeHelperOn=(CFG.tradeHelperOn~=false),
    coinFarmOn=false, stopFarm=false,
    farmSpeed=23,
    zombieAutoKill=false, zombieAutoShoot=false,
    skeletonESP=CFG.espSkeleton,
    boxESP=CFG.espBox,
    antiLagOn=CFG.antiLag,
    speedGlitch=false, glitchSpeed=200, boostActive=false,
}
local ESP_FLAGS = {Murderer=false, Sheriff=false, Innocent=false, Hero=false, Gun=false, NPC=false, NameTag=false, Distance=false, All=false, Zombie=false}
local espP, tracers = {}, {}
local KillFx = {RunKill=false, RunKillRange=4, EyeLaser=false, EyeLaserRange=200, EyeLaserCd=0, _beam=nil, _beam2=nil, Target=nil}
local AF = {on=(CFG.antiFling~=false)}
local X = {}
X.NC = {parts={}}
function X.NC.set(part) if part.CanCollide then X.NC.parts[part]=true; part.CanCollide=false end end
function X.NC.restore()
    for part in pairs(X.NC.parts) do
        if part.Parent then pcall(function() part.CanCollide=true end) end
    end
    X.NC.parts={}
end
local UD = {enabled=false, ScanRadius=22, ProjectileSpeedMin=25, DodgeDist=20, WallBuffer=2.5, BaseCooldown=0.6, OverdriveCooldown=0.1, StressThreshold=2, StressDecay=0.6, stressLevel=0, lastDodgeTime=0, isDodging=false, meleeDist=15}

local Win = Library:CreateWindow({Logo=ASSETS.logo, Background=BG_LIST[CFG.bgName] or ASSETS.background, Keybind=Enum.KeyCode.RightShift, Size=Vector2.new(460,460), SidebarWidth=140, ToggleButton=false})
Win.UIScale.Scale = CFG.uiScale / 100
Win._baseScale = CFG.uiScale / 100

local WmGui=New("ScreenGui",{Name="PiddleWatermark",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1000})
WmGui.Parent=GetGuiParent()

local wmFrame=New("Frame",{Parent=WmGui,Size=UDim2.fromOffset(220,38),Position=UDim2.fromOffset(12,12),BackgroundColor3=Theme.Window,ClipsDescendants=true,Active=true})
Corner(wmFrame,8); Stroke(wmFrame,Theme.Stroke)
local wmBg=New("ImageLabel",{Parent=wmFrame,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=BG_LIST[CFG.bgName],ImageTransparency=0.5,ScaleType=Enum.ScaleType.Crop}); Corner(wmBg,8)
New("ImageLabel",{Parent=wmFrame,Size=UDim2.fromOffset(26,26),Position=UDim2.fromOffset(8,6),BackgroundTransparency=1,Image=ResolveImage(ASSETS.logo),ImageColor3=Color3.new(1,1,1),ScaleType=Enum.ScaleType.Fit})
New("TextLabel",{Parent=wmFrame,Size=UDim2.new(0,60,1,0),Position=UDim2.fromOffset(40,0),BackgroundTransparency=1,Text="PIDDLE",Font=Theme.FontBold,TextSize=14,TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left})
local wmStats=New("TextLabel",{Parent=wmFrame,Size=UDim2.new(1,-110,1,0),Position=UDim2.fromOffset(100,0),BackgroundTransparency=1,Text="--fps --ms",TextColor3=Theme.Dim,Font=Theme.Font,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right})
local wmBtn=New("TextButton",{Parent=wmFrame,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=10})

local fpsBuffer={}
Connect(RunService.RenderStepped,function(dt) table.insert(fpsBuffer,dt); if #fpsBuffer>30 then table.remove(fpsBuffer,1) end end)
task.spawn(function()
    while true do
        task.wait(1)
        local fps=0
        if #fpsBuffer>0 then local s=0; for _,v in ipairs(fpsBuffer) do s=s+v end; fps=math.floor(#fpsBuffer/s+0.5) end
        local ping=0; pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        wmStats.Text=string.format("%d fps | %d ms",fps,ping)
    end
end)

local wmDrag,wmStart,wmPos,wmMoved
Connect(wmBtn.InputBegan,function(i)
    if IsPress(i) then wmDrag=true; wmMoved=false; wmStart=i.Position; wmPos=wmFrame.Position; EX.modal(true) end
end)
Connect(UIS.InputChanged,function(i)
    if wmDrag and IsMove(i) then
        local d=i.Position-wmStart
        if d.Magnitude>5 then wmMoved=true end
        wmFrame.Position=UDim2.new(wmPos.X.Scale,wmPos.X.Offset+d.X,wmPos.Y.Scale,wmPos.Y.Offset+d.Y)
    end
end)
Connect(UIS.InputEnded,function(i)
    if wmDrag and IsPress(i) then
        wmDrag=false; EX.modal(false)
        if not wmMoved then playSound(Sounds.Click, 0.5); Win:Toggle() end
    end
end)

local BT={hooked=false}
function BT.wallOrigin(head,targetPos,targetChar)
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={LocalPlayer.Character,Cam,targetChar}
    local function clear(a,b) return WS:Raycast(a,b-a,rp)==nil end
    if clear(head,targetPos) then return head end
    local toMe=head-targetPos
    local base=toMe.Magnitude>0.1 and toMe.Unit or Vector3.new(0,1,0)
    local dirs={base,Vector3.new(0,1,0),Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(0,-1,0),
        Vector3.new(0.7,0.7,0),Vector3.new(-0.7,0.7,0),Vector3.new(0,0.7,0.7),Vector3.new(0,0.7,-0.7),Vector3.new(0.7,0,0.7),Vector3.new(-0.7,0,0.7),Vector3.new(0.7,0,-0.7),Vector3.new(-0.7,0,-0.7)}
    for _,r in ipairs({1.5,3,5,8,12}) do
        for _,d in ipairs(dirs) do
            local p=targetPos+d*r
            if clear(p,targetPos) then return p end
        end
    end
    return targetPos+base*1.2
end

pcall(function()
    if not (hookmetamethod and getnamecallmethod and newcclosure) then return end
    local old
    old=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
        local method=getnamecallmethod()
        if method=="FireServer" then
            local ok,isShot=pcall(function() return self.Name=="Shoot" and self.Parent and self.Parent.Name=="Gun" end)
            if ok and isShot then
                local a,b=...
                task.spawn(function()
                    local ok2,o,t=pcall(function() return a.Position,b.Position end)
                    if ok2 and getgenv().__NoirTracers then
                        local G = getgenv().__NoirTracers
                        if G.on then
                            if G.build then
                                G.build(o, t, G.impact, G.muzzle)
                            end
                        end
                    end
                end)
            end
        end
        return old(self,...)
    end))
    BT.hooked=true
end)

function BT.bind(tool)
    if not tool:IsA("Tool") or tool.Name~="Gun" then return end
    Connect(tool.Activated,function()
        if BT.hooked then return end
        local ch=LocalPlayer.Character
        local head=ch and ch:FindFirstChild("Head")
        if not head then return end
        local loc=UIS:GetMouseLocation()
        if loc.Magnitude<1 then loc=Cam.ViewportSize/2 end
        local ray=Cam:ViewportPointToRay(loc.X,loc.Y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={ch}
        local hit=WS:Raycast(ray.Origin,ray.Direction*1000,params)
        local o = head.Position
        local t = hit and hit.Position or (ray.Origin+ray.Direction*500)
        if getgenv().__NoirTracers then
            local G = getgenv().__NoirTracers
            if G.on and G.build then G.build(o, t, G.impact, G.muzzle) end
        end
    end)
end
function BT.all()
    for _,c in ipairs({LocalPlayer.Character,LocalPlayer:FindFirstChild("Backpack")}) do
        if c then
            for _,tool in ipairs(c:GetChildren()) do BT.bind(tool) end
            Connect(c.ChildAdded,BT.bind)
        end
    end
end
BT.all()
Connect(LocalPlayer.CharacterAdded,function() task.wait(0.5); BT.all() end)

local DeathFx={}
function DeathFx.part(root,size,color,pos,shape)
    local p=Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
    p.Material=Enum.Material.Neon; p.Size=size; p.Color=color; p.CFrame=CFrame.new(pos)
    if shape then p.Shape=shape end
    p.Parent=root
    return p
end
function DeathFx.confetti(pos, root)
    for i = 1, 40 do
        local hue = math.random()
        local p = DeathFx.part(root, Vector3.new(0.25, 0.4, 0.25), Color3.fromHSV(hue, 0.85, 1), pos + Vector3.new(math.random(-1,1), 2, math.random(-1,1)))
        local r = Random.new()
        local dir = Vector3.new(r:NextNumber(-1,1), r:NextNumber(0.5,1.5), r:NextNumber(-1,1)).Unit
        local dist = r:NextNumber(4, 10)
        local flightTime = r:NextNumber(1.2, 2.2)
        local targetPos = p.Position + dir * dist + Vector3.new(0, -3, 0)
        TweenService:Create(p, TweenInfo.new(flightTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPos,
            Rotation = Vector3.new(r:NextNumber(-360,360), r:NextNumber(-360,360), r:NextNumber(-360,360)),
            Transparency = 1,
            Size = Vector3.new(0.05, 0.05, 0.05),
        }):Play()
        Debris:AddItem(p, flightTime + 0.1)
    end
end
function DeathFx.fireworks(pos,root)
    local col=Color3.fromHSV(math.random(),0.9,1)
    for i=1,32 do
        local dir=Vector3.new(math.random()-0.5,math.random()*0.8+0.2,math.random()-0.5).Unit
        local p=DeathFx.part(root,Vector3.new(0.35,0.35,0.35),col,pos+Vector3.new(0,2,0),Enum.PartType.Ball)
        Tween(p,TweenInfo.new(0.9,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=p.Position+dir*(8+math.random()*6),Transparency=1,Size=Vector3.new(0.05,0.05,0.05)})
    end
end
function DeathFx.shockwave(pos,root)
    local base=pos-Vector3.new(0,2.8,0)
    for i=1,2 do
        local p=DeathFx.part(root,Vector3.new(0.25,1,1),i==1 and Color3.fromRGB(120,200,255) or Color3.fromRGB(255,255,255),base,Enum.PartType.Cylinder)
        p.CFrame=CFrame.new(base)*CFrame.Angles(0,0,math.rad(90)); p.Transparency=0.2
        Tween(p,TweenInfo.new(0.6+i*0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(0.25,14+i*8,14+i*8),Transparency=1})
    end
end
function DeathFx.lightning(pos,root)
    local last=pos+Vector3.new(0,60,0)
    for i=1,10 do
        local nxt=(i==10) and pos or (pos+Vector3.new((math.random()-0.5)*6,60-i*6,(math.random()-0.5)*6))
        local len=(nxt-last).Magnitude
        local p=DeathFx.part(root,Vector3.new(0.4,0.4,len),Color3.fromRGB(190,170,255),(last+nxt)/2)
        p.CFrame=CFrame.lookAt(last,nxt)*CFrame.new(0,0,-len/2)
        Tween(p,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1})
        last=nxt
    end
    local lp=DeathFx.part(root,Vector3.new(1,1,1),Color3.new(1,1,1),pos); lp.Transparency=1
    local l=Instance.new("PointLight"); l.Color=Color3.fromRGB(190,170,255); l.Range=24; l.Brightness=6; l.Parent=lp
    Tween(l,TweenInfo.new(0.4),{Brightness=0})
end
function DeathFx.ghost(pos,root)
    local p=DeathFx.part(root,Vector3.new(2.2,2.2,2.2),Color3.fromRGB(235,240,255),pos,Enum.PartType.Ball)
    p.Transparency=0.35; p.Material=Enum.Material.ForceField
    Tween(p,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Position=pos+Vector3.new(0,14,0),Size=Vector3.new(4,4,4),Transparency=1})
end
function DeathFx.explosion(pos,root)
    local e=Instance.new("Explosion")
    e.Position=pos; e.BlastRadius=6; e.BlastPressure=0; e.DestroyJointRadiusPercent=0
    e.ExplosionType=Enum.ExplosionType.NoCraters; e.Parent=root
end
DeathFx.styles={"confetti","fireworks","shockwave","lightning","ghost","explosion"}
function DeathFx.play(pos,force)
    if not force and not CFG.killEffectOn then return end
    local style=CFG.killEffectStyle or "confetti"
    if style=="random" then style=DeathFx.styles[math.random(1,#DeathFx.styles)] end
    local root=Instance.new("Folder"); root.Name="PiddleFx"; root.Parent=WS
    local ok,err=pcall(DeathFx[style] or DeathFx.confetti,pos,root)
    if not ok then warn("[PIDDLE] fx: "..tostring(err)) end
    Debris:AddItem(root,5)
end
task.spawn(function()
    local deadTracked={}
    while true do
        task.wait(0.3)
        for _,p in ipairs(Players:GetPlayers()) do
            if (p~=LocalPlayer or CFG.killEffectSelf) and p.Character then
                local hum=p.Character:FindFirstChildOfClass("Humanoid")
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health<=0 and not deadTracked[p] then
                    deadTracked[p]=true; DeathFx.play(hrp.Position)
                elseif hum and hum.Health>0 then deadTracked[p]=nil end
            end
        end
    end
end)

local GD={drop=nil,scan=0,conns={}}
function GD.find()
    for _,o in ipairs(WS:GetDescendants()) do
        if o.Name=="GunDrop" then GD.drop=o; return o end
    end
end
function GD.watch(on)
    for _,c in ipairs(GD.conns) do pcall(function() c:Disconnect() end) end
    GD.conns={}
    if not on then GD.drop=nil; return end
    GD.conns[1]=Connect(WS.DescendantAdded,function(o) if o.Name=="GunDrop" then GD.drop=o; if GD.grab then task.defer(GD.grab) end end end)
    GD.conns[2]=Connect(WS.DescendantRemoving,function(o) if o==GD.drop then GD.drop=nil end end)
    GD.find()
end
function GD.parts()
    local d=GD.drop
    if not d or not d.Parent then
        GD.drop=nil
        if os.clock()-GD.scan>1.5 then GD.scan=os.clock(); d=GD.find() else d=nil end
    end
    if not d then return nil end
    local part=d:IsA("BasePart") and d or d:FindFirstChild("Handle") or d:FindFirstChildWhichIsA("BasePart",true)
    local prompt=d:FindFirstChildWhichIsA("ProximityPrompt",true)
    return part,prompt,d
end
function GD.remotes()
    if GD.rl and os.clock()-GD.rlT<5 then return GD.rl end
    local l={}
    for _,r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            local n=r.Name:lower()
            if n:find("pick") or n:find("gun") or n:find("interact") or n:find("drop") then l[#l+1]=r end
        end
    end
    GD.rl=l; GD.rlT=os.clock()
    return l
end
local function grabDroppedGun()
    local myChar=LocalPlayer.Character
    local myHum=myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum or myHum.Health<=0 then return false end
    if getRole(LocalPlayer)=="Murderer" or isRealNpc(LocalPlayer) then return false end
    local hrp=myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local part,prompt,drop=GD.parts()
    if not part then return false end
    local mode = CFG.autoGunMode or "remote"
    if mode == "fastTP" then
        if myHum.Health<=0 or getRole(LocalPlayer)=="Murderer" then return false end
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
        EX.touch(hrp, part, true)
        if prompt then EX.prompt(prompt, true) end
    else
        if prompt then EX.prompt(prompt, true) end
        EX.touch(hrp, part, true)
        if not hasItem(LocalPlayer, "Gun") and os.clock() - (GD.lastR or 0) > 0.1 then
            GD.lastR = os.clock()
            for _, r in ipairs(GD.remotes()) do pcall(function() r:FireServer(drop) end) end
        end
    end
    return true
end
GD.grab=grabDroppedGun
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if (State.autoGun or State.autoShoot or State.zombieAutoShoot) and LocalPlayer.Character and not hasItem(LocalPlayer, "Gun") then
            local myHum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if myHum and myHum.Health>0 and getRole(LocalPlayer)~="Murderer" and not isRealNpc(LocalPlayer) then
                pcall(grabDroppedGun)
            end
        end
    end
end)

local PING = 0.1
task.spawn(function()
    while true do
        local ok, ms = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ok and ms then PING = math.clamp(ms/1000, 0.02, 1) end
        task.wait(0.5)
    end
end)

local function preciseAim(targetPart, targetChar)
    local ch = LocalPlayer.Character
    if not ch then return end
    local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local origin = head.Position
    local aimPos = targetPart.Position
    if State.predictMovement then
        local vel = targetPart.AssemblyLinearVelocity
        local dist = (aimPos - origin).Magnitude
        local flyTime = dist / 900
        aimPos = aimPos + vel * (flyTime + PING)
    end
    return origin, aimPos
end

function fireGunWallbang(targetPos, targetPart)
    local ch = LocalPlayer.Character; if not ch then return end
    local role = getRole(LocalPlayer)
    if role ~= "Sheriff" and role ~= "Hero" then return end
    local g = getGun(); if not g then return end
    local shoot = g:FindFirstChild("Shoot"); if not shoot then return end
    local head = ch:FindFirstChild("Head"); if not head then return end
    local origin = head.Position
    if State.shootThroughWalls and targetPart then
        origin = BT.wallOrigin(head.Position, targetPos, targetPart.Parent)
    end
    pcall(function() shoot:FireServer(CFrame.new(origin, targetPos), CFrame.new(targetPos)) end)
    if getgenv().__NoirTracers and getgenv().__NoirTracers.on and getgenv().__NoirTracers.build then
        getgenv().__NoirTracers.build(origin, targetPos, getgenv().__NoirTracers.impact, getgenv().__NoirTracers.muzzle)
    end
end

X.autoShootCd = 0
RunService.Heartbeat:Connect(function()
    if not State.autoShoot then return end
    pcall(function()
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not ch or not hum or hum.Health <= 0 then return end
        local g = getGun(); if not g then return end
        if getRole(LocalPlayer) == "Murderer" then return end
        local now = os.clock()
        if now - X.autoShootCd < 0.3 then return end
        local m = findMurderer(); if not m or not m.Character then return end
        local mh = m.Character:FindFirstChildOfClass("Humanoid")
        local mr = m.Character:FindFirstChild("HumanoidRootPart")
        local mHead = m.Character:FindFirstChild("Head")
        if not mh or mh.Health <= 0 or not mr then return end
        if g.Parent ~= ch then hum:EquipTool(g); return end
        local shoot = g:FindFirstChild("Shoot"); if not shoot then return end
        local origin, aimPos = preciseAim(mHead or mr, m.Character)
        if not (origin and aimPos) then return end
        X.autoShootCd = now
        if State.shootThroughWalls then
            origin = BT.wallOrigin(origin, aimPos, m.Character)
        end
        shoot:FireServer(CFrame.new(origin, aimPos), CFrame.new(aimPos))
        if getgenv().__NoirTracers and getgenv().__NoirTracers.on and getgenv().__NoirTracers.build then
            getgenv().__NoirTracers.build(origin, aimPos, getgenv().__NoirTracers.impact, getgenv().__NoirTracers.muzzle)
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    if not State.aimlockSheriff then return end
    local role=getRole(LocalPlayer)
    if role~="Sheriff" and role~="Hero" then return end
    local m=findMurderer()
    if m and m.Character then
        local hd=m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
        if hd then Cam.CFrame=CFrame.lookAt(Cam.CFrame.Position,hd.Position) end
    end
end)

RunService.RenderStepped:Connect(function()
    if not State.aimlockZombie then return end
    local ch=LocalPlayer.Character; if not ch then return end
    local myHead=ch:FindFirstChild("Head"); if not myHead then return end
    local closest,cd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not isRealNpc(p) and isZombie(p) and getRole(p)~="Murderer" then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChildOfClass("Humanoid")
            if tr and h and h.Health>0 then
                local d=(tr.Position-myHead.Position).Magnitude
                if d<cd then cd=d; closest=p end
            end
        end
    end
    if closest and closest.Character then
        local hd=closest.Character:FindFirstChild("Head") or closest.Character:FindFirstChild("HumanoidRootPart")
        if hd then Cam.CFrame=CFrame.lookAt(Cam.CFrame.Position,hd.Position) end
    end
end)

RunService.RenderStepped:Connect(function()
    if not State.zombieAutoShoot then return end
    local ch=LocalPlayer.Character; if not ch then return end
    local myHead=ch:FindFirstChild("Head"); if not myHead then return end
    local closest,cd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not isRealNpc(p) and isZombie(p) then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChildOfClass("Humanoid")
            if tr and h and h.Health>0 then
                local d=(tr.Position-myHead.Position).Magnitude
                if d<cd then cd=d; closest=p end
            end
        end
    end
    if closest then
        local tr=closest.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local targetPos=tr.Position + tr.AssemblyLinearVelocity*0.15
            fireGunWallbang(targetPos, tr)
        end
    end
end)

local function killAllRun()
    local plr = LocalPlayer
    if not plr then return end
    local char = plr.Character
    if not char then return end
    local knife = char:FindFirstChild("Knife")
    if not knife then
        local bpk = plr:FindFirstChild("Backpack") and plr.Backpack:FindFirstChild("Knife")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if bpk and hum then
            hum:EquipTool(bpk)
            local t0 = os.clock()
            repeat task.wait(0.05) knife = char:FindFirstChild("Knife") until knife or os.clock()-t0 > 1.5
        end
    end
    if not knife then return end
    local events = knife:FindFirstChild("Events")
    if not events then return end
    local HandleTouched = events:FindFirstChild("HandleTouched")
    if not HandleTouched then return end
    for i,v in pairs(Players:GetPlayers()) do
        if v and v.Character and v ~= LocalPlayer then
            local primary = v.Character:FindFirstChild("HumanoidRootPart")
            if primary then
                HandleTouched:FireServer(primary)
                task.wait(0.05)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if State.autoThrow and LocalPlayer.Character then
            local root=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local k=getKnife()
                if k and k.Parent~=LocalPlayer.Character then
                    local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(k) end
                end
                if k then
                    local ev=k:FindFirstChild("Events")
                    local th=ev and ev:FindFirstChild("KnifeThrown")
                    if th then
                        local closest,cd=nil,2000
                        for _,p in ipairs(Players:GetPlayers()) do
                            if p~=LocalPlayer and p.Character and getRole(p)~="NPC" and not isRealNpc(p) then
                                local tr=p.Character:FindFirstChild("HumanoidRootPart")
                                local h=p.Character:FindFirstChildOfClass("Humanoid")
                                if tr and h and h.Health>0 then
                                    local d=(tr.Position-root.Position).Magnitude
                                    if d<cd then cd=d; closest=p end
                                end
                            end
                        end
                        if closest then
                            local tr=closest.Character:FindFirstChild("HumanoidRootPart")
                            if tr then
                                local pd=tr.Position+tr.AssemblyLinearVelocity*0.15
                                pcall(function() th:FireServer(tr.CFrame+tr.CFrame.LookVector*2, CFrame.new(pd)) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

local antiAimConn = nil
local aaPreset = CFG.aaPreset or "low"
local function aaSetFF(value)
    pcall(function()
        if type(setfflag) == "function" then
            setfflag("S2PhysicsSenderRate", tostring(value))
        end
    end)
end
local function aaSigned(value)
    return math.random(1, 2) == 1 and -value or value
end
local function aaVelocity()
    if aaPreset == "y high" then
        return Vector3.new(0, 16384, 0)
    elseif aaPreset == "limit" then
        local function limitComponent()
            local magnitude = math.random() * 2147483647
            return math.random(1, 2) == 1 and -magnitude or magnitude
        end
        return Vector3.new(limitComponent(), limitComponent(), limitComponent())
    elseif aaPreset == "high" then
        return Vector3.new(
            aaSigned(16384),
            math.random(1, 2) == 1 and -14384 or 16384,
            aaSigned(16384)
        )
    elseif aaPreset == "zero" then
        return Vector3.new(0, 0, 0)
    end
    return Vector3.new(aaSigned(300), aaSigned(300), aaSigned(300))
end
local aaFflagOld = nil
local aaBusy = false
local function startAntiAim()
    if antiAimConn then antiAimConn:Disconnect(); antiAimConn=nil end
    aaFflagOld = nil
    pcall(function()
        if type(getfflag) == "function" then
            local value = getfflag("S2PhysicsSenderRate")
            if value ~= nil then aaFflagOld = tostring(value) end
        end
    end)
    antiAimConn = RunService.Heartbeat:Connect(function(dt)
        if aaBusy then return end
        local ch=LocalPlayer.Character
        if not ch then return end
        local root=ch:FindFirstChild("HumanoidRootPart", true)
        local humanoid=ch:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or not root.Parent or humanoid.Health <= 0 then return end

        local env = EX.env()
        local flingActive = type(env) == "table" and env.FLING_ACTIVE or nil
        if flingActive == true or (tonumber(flingActive) or 0) ~= 0 then return end

        local fps = 60
        if type(dt) == "number" and dt > 0 then
            fps = math.floor(math.min(1000, math.max(1, 1 / dt)) * 10 + 0.5) / 10
        end
        aaSetFF(fps)
        pcall(function()
            if type(sethiddenproperty) == "function" then
                sethiddenproperty(root, "NetworkIsSleeping", false)
            end
        end)

        aaBusy = true
        local oldLin, oldAng
        local ok = pcall(function()
            oldLin = root.AssemblyLinearVelocity
            oldAng = root.AssemblyAngularVelocity
            if type(env) == "table" then env.VELOCITY_DESYNC_UNTIL = os.clock() + 0.35 end
            root.AssemblyLinearVelocity = aaVelocity()
        end)
        if not ok then
            aaBusy = false
            return
        end

        RunService.RenderStepped:Wait()
        if root and root.Parent then
            pcall(function()
                root.AssemblyLinearVelocity = oldLin
                root.AssemblyAngularVelocity = oldAng
            end)
        end
        if type(env) == "table" then env.VELOCITY_DESYNC_UNTIL = os.clock() + 0.05 end
        aaBusy = false
    end)
end
local function stopAntiAim()
    if antiAimConn then antiAimConn:Disconnect(); antiAimConn=nil end
    aaSetFF(aaFflagOld or "15")
    aaFflagOld = nil
    pcall(function()
        local env = EX.env()
        if type(env) == "table" then env.VELOCITY_DESYNC_UNTIL = os.clock() end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if LocalPlayer.Character then
            local h=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then
                if State.keepSpeed and h.WalkSpeed~=State.dSpeed then h.WalkSpeed=State.dSpeed end
                if State.keepJump then
                    if h.UseJumpPower==false then h.UseJumpPower=true end
                    if h.JumpPower~=State.dJump then h.JumpPower=State.dJump end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.01)
        if State.spinOn and LocalPlayer.Character then
            local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then State.spinA=State.spinA+State.spinSpd; hrp.CFrame=CFrame.new(hrp.CFrame.Position)*CFrame.Angles(0,math.rad(State.spinA),0) end
        end
    end
end)
RunService.Stepped:Connect(function()
    local ch = LocalPlayer.Character
    if ch and (State.noclip or State.farmClip) then
        for _,p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then X.NC.set(p) end
        end
    end
end)

local function updateFly()
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if State.flying and hrp then
        if not State.flyBV or State.flyBV.Parent~=hrp then
            if State.flyBV then pcall(function() State.flyBV:Destroy() end) end
            if State.flyBG then pcall(function() State.flyBG:Destroy() end) end
            State.flyBV=Instance.new("BodyVelocity"); State.flyBV.Parent=hrp; State.flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); State.flyBV.Velocity=Vector3.new()
            State.flyBG=Instance.new("BodyGyro"); State.flyBG.Parent=hrp; State.flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); State.flyBG.P=1000
        end
        local mv=Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
        local moveDirection = LocalPlayer.Character.Humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            local forward = Cam.CFrame.LookVector
            local right = Cam.CFrame.RightVector
            local flatForward = Vector3.new(forward.X, 0, forward.Z)
            local flatRight = Vector3.new(right.X, 0, right.Z)
            local forwardInput = moveDirection:Dot(flatForward.Unit)
            local sideInput = moveDirection:Dot(flatRight.Unit)
            local flightDir = forward * forwardInput + right * sideInput
            if flightDir.Magnitude > 0.1 then mv = flightDir.Unit * 60 end
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
        State.flyBV.Velocity=mv*60; State.flyBG.CFrame=Cam.CFrame
    elseif not State.flying then
        if State.flyBV then pcall(function() State.flyBV:Destroy() end); State.flyBV=nil end
        if State.flyBG then pcall(function() State.flyBG:Destroy() end); State.flyBG=nil end
    end
end
Connect(RunService.RenderStepped, updateFly)

Connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.ButtonA and State.flying and State.flyBV then
        State.flyBV.Velocity = Vector3.new(0, 60, 0)
    end
end)

X.RESP = {busy=false}
function X.RESP.go(mode)
    if X.RESP.busy then return end
    X.RESP.busy = true
    task.spawn(function()
        local ch = LocalPlayer.Character
        local done = false
        if mode == "fast" then
            pcall(function()
                if ch then
                    local nc = Instance.new("Model"); nc.Parent = WS
                    LocalPlayer.Character = nc
                    task.wait()
                    LocalPlayer.Character = ch
                    nc:Destroy()
                    ch:BreakJoints()
                    done = true
                end
            end)
        end
        if not done then
            pcall(function()
                if type(replicatesignal) == "function" then
                    replicatesignal(LocalPlayer.ConnectDiedSignalBackend)
                    task.wait(math.max(0, (Players.RespawnTime or 0) - 0.1))
                    replicatesignal(LocalPlayer.Kill)
                elseif ch then
                    ch:BreakJoints()
                end
            end)
        end
        task.wait(0.6)
        X.RESP.busy = false
    end)
end
function X.RESP.hook(ch)
    local hum = ch:WaitForChild("Humanoid", 10)
    if not hum then return end
    Connect(hum.Died, function()
        if State.fastRespawn then
            X.RESP.go("fast")
        elseif State.autoRespawn then
            task.wait(0.5)
            if LocalPlayer.Character == ch then X.RESP.go("auto") end
        end
    end)
end
if LocalPlayer.Character then task.spawn(X.RESP.hook, LocalPlayer.Character) end
Connect(LocalPlayer.CharacterAdded, function(ch) task.spawn(X.RESP.hook, ch) end)

X.VOID = {safe=nil}
RunService.Heartbeat:Connect(function()
    if not State.antiVoid then X.VOID.safe=nil; return end
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        X.VOID.safe = hrp.CFrame
    end
    local fh = WS.FallenPartsDestroyHeight
    if fh ~= fh then fh = -500 end
    local limit = fh + 120
    local fell = X.VOID.safe and hrp.Position.Y < (X.VOID.safe.Position.Y - 45) and hrp.AssemblyLinearVelocity.Y < -20
    if hrp.Position.Y < limit or fell then
        local target = X.VOID.safe
        if not target then
            local sp = WS:FindFirstChildWhichIsA("SpawnLocation", true)
            if sp then target = sp.CFrame + Vector3.new(0, 5, 0) end
        end
        if target then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = target + Vector3.new(0, 3, 0)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if State.playerAuraOn and LocalPlayer.Character then
            local root=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if not State.playerAuraPart or not State.playerAuraPart.Parent then
                    State.playerAuraPart=Instance.new("Part")
                    State.playerAuraPart.Name="PiddleAura"
                    State.playerAuraPart.Shape=Enum.PartType.Ball
                    State.playerAuraPart.Size=Vector3.new(6,6,6)
                    State.playerAuraPart.Material=Enum.Material.Neon
                    State.playerAuraPart.Color=State.playerAuraColor
                    State.playerAuraPart.Transparency=0.6
                    State.playerAuraPart.CanCollide=false
                    State.playerAuraPart.Massless=true
                    State.playerAuraPart.CanQuery=false
                    State.playerAuraPart.CanTouch=false
                    State.playerAuraPart.CFrame=root.CFrame
                    State.playerAuraPart.Parent=LocalPlayer.Character
                    local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=State.playerAuraPart; w.Parent=State.playerAuraPart
                    State.playerAuraLight=Instance.new("PointLight")
                    State.playerAuraLight.Color=State.playerAuraColor
                    State.playerAuraLight.Range=12
                    State.playerAuraLight.Brightness=3
                    State.playerAuraLight.Parent=State.playerAuraPart
                end
                State.playerAuraPart.Color=State.playerAuraColor
                if State.playerAuraLight then State.playerAuraLight.Color=State.playerAuraColor end
            end
        else
            if State.playerAuraPart and State.playerAuraPart.Parent then State.playerAuraPart:Destroy() end
            State.playerAuraPart, State.playerAuraLight = nil, nil
        end
    end
end)

local function applyPack(name)
    local ch=LocalPlayer.Character; if not ch then return end
    local animate=ch:FindFirstChild("Animate"); if not animate then return end
    local pack=PACKS[name]; if not pack then return end
    local function setId(cname,id)
        local c=animate:FindFirstChild(cname)
        if c and id and id~="" then
            for _,a in ipairs(c:GetChildren()) do
                if a:IsA("Animation") then a.AnimationId="rbxassetid://"..id end
            end
        end
    end
    setId("idle",pack.Idle); setId("walk",pack.Walk); setId("run",pack.Run)
    setId("jump",pack.Jump); setId("fall",pack.Fall); setId("climb",pack.Climb)
    setId("swim",pack.Swim); setId("swimidle",pack.SwimIdle)
end
local function applyKorbloxNow()
    local char=LocalPlayer.Character; if not char then return end
    local rf=char:FindFirstChild("RightFoot"); local rl=char:FindFirstChild("RightLowerLeg"); local ru=char:FindFirstChild("RightUpperLeg")
    if rf then rf.MeshId="rbxassetid://902942089"; rf.Transparency=1 end
    if rl then rl.MeshId="rbxassetid://902942093"; rl.Transparency=1 end
    if ru then ru.MeshId="rbxassetid://902942096"; ru.TextureID="rbxassetid://902843398" end
end
local function removeKorbloxNow()
    local char=LocalPlayer.Character; if not char then return end
    for _,n in ipairs({"RightFoot","RightLowerLeg","RightUpperLeg"}) do
        local p=char:FindFirstChild(n); if p then p.MeshId=""; p.TextureID=""; p.Transparency=0 end
    end
end
local function applyHeadlessNow()
    local char=LocalPlayer.Character; if not char then return end
    local head=char:FindFirstChild("Head"); if not head then return end
    head.Transparency=1
    for _,c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency=1 end end
end
local function removeHeadlessNow()
    local char=LocalPlayer.Character; if not char then return end
    local head=char:FindFirstChild("Head"); if not head then return end
    head.Transparency=0
    for _,c in ipairs(head:GetChildren()) do if c:IsA("Decal") then c.Transparency=0 end end
end
local Hat = {id=78884791711594}
function Hat.remove()
    local char=LocalPlayer.Character; if not char then return end
    if Hat.prevDesc and Hat.descChar==char then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:ApplyDescription(Hat.prevDesc) end) end
    end
    Hat.prevDesc=nil; Hat.descChar=nil
    for _,n in ipairs({"PiddleChinaHat","PiddleChinaHatCone","PiddleChinaHatTassel"}) do
        for _,o in ipairs(char:GetChildren()) do if o.Name==n then o:Destroy() end end
    end
end
function Hat.load()
    local ok,res=pcall(function() return game:GetObjects("rbxassetid://"..Hat.id) end)
    if ok and type(res)=="table" and res[1] then return res[1] end
    local ok2,m=pcall(function() return InsertService:LoadAsset(Hat.id) end)
    if ok2 and m then return m end
    return nil
end
function X.accKey(a)
    local h = a:FindFirstChild("Handle")
    local id = ""
    if h then
        if h:IsA("MeshPart") then id = h.MeshId
        else
            local m = h:FindFirstChildWhichIsA("SpecialMesh")
            if m then id = m.MeshId end
        end
    end
    return a.Name .. "|" .. tostring(id)
end
function Hat.viaDesc(char,hum)
    local ok,desc=pcall(function() return hum:GetAppliedDescription() end)
    if not ok or not desc then return false end
    local before=#hum:GetAccessories()
    local seen={}
    for _,a in ipairs(hum:GetAccessories()) do seen[X.accKey(a)]=true end
    local prev=desc:Clone()
    local cur=tostring(desc.HatAccessory or "")
    desc.HatAccessory=(cur~="" and (cur..",") or "")..tostring(Hat.id)
    if not pcall(function() hum:ApplyDescription(desc) end) then return false end
    local t0=os.clock()
    while os.clock()-t0<3 and #hum:GetAccessories()<=before do task.wait(0.1) end
    if #hum:GetAccessories()>before then
        Hat.prevDesc=prev; Hat.descChar=char
        for _,a in ipairs(hum:GetAccessories()) do
            if not seen[X.accKey(a)] then a.Name="PiddleChinaHat" end
        end
        return true
    end
    return false
end
function Hat.weld(head,part)
    part.Anchored=false; part.CanCollide=false; part.Massless=true
    part.CFrame=head.CFrame*CFrame.new(0,head.Size.Y/2+part.Size.Y/2,0)
    local w=Instance.new("WeldConstraint"); w.Part0=head; w.Part1=part; w.Parent=part
end
function Hat.apply()
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local head=char and char:FindFirstChild("Head")
    if not (hum and head) then return end
    Hat.remove()
    local obj=Hat.load()
    local item
    if obj then
        if obj:IsA("Accessory") or obj:IsA("Hat") then item=obj
        else item=obj:FindFirstChildWhichIsA("Accessory",true) or obj:FindFirstChildWhichIsA("Hat",true) or (obj:IsA("BasePart") and obj) or obj:FindFirstChildWhichIsA("BasePart",true) end
    end
    if item and (item:IsA("Accessory") or item:IsA("Hat")) then
        item.Name="PiddleChinaHat"
        pcall(function() hum:AddAccessory(item) end)
        if item.Parent~=char then item.Parent=char end
        local handle=item:FindFirstChild("Handle")
        task.delay(0.2,function()
            if handle and handle.Parent and head.Parent and not handle:FindFirstChildWhichIsA("Weld") and not handle:FindFirstChildWhichIsA("WeldConstraint") then
                Hat.weld(head,handle)
            end
        end)
        return
    end
    if not item and Hat.viaDesc(char,hum) then return end
    local part
    if item and item:IsA("BasePart") then
        part=item:Clone()
    else
        part=Instance.new("Part"); part.Size=Vector3.new(2,1,2)
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.FileMesh
        mesh.MeshId="rbxassetid://"..Hat.id; mesh.Parent=part
    end
    part.Name="PiddleChinaHat"
    Hat.weld(head,part)
    part.Parent=char
end
function X.paintHat(d, c)
    if d:IsA("BasePart") then
        d.Color = c
        if d:IsA("MeshPart") then pcall(function() d.TextureID = "" end) end
    elseif d:IsA("SpecialMesh") then
        pcall(function() d.TextureId = ""; d.VertexColor = Vector3.new(c.R, c.G, c.B) end)
    elseif d:IsA("SurfaceAppearance") then
        d:Destroy()
    elseif d:IsA("Decal") or d:IsA("Texture") then
        d.Color3 = c
    end
end
local function updateHatColor(c)
    local char=LocalPlayer.Character
    if not char then return end
    c = c or CFG.chinaHatColor
    local custom = c ~= Color3.new(1,1,1)
    for _,o in ipairs(char:GetChildren()) do
        if o.Name:find("PiddleChinaHat") then
            X.paintHat(o, c)
            for _,d in ipairs(o:GetDescendants()) do X.paintHat(d, c) end
            local hl = o:FindFirstChild("PiddleHatColor")
            if custom then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "PiddleHatColor"
                    hl.FillTransparency = 0
                    hl.OutlineTransparency = 1
                    hl.DepthMode = Enum.HighlightDepthMode.Occluded
                    hl.Adornee = o
                    hl.Parent = o
                end
                hl.FillColor = c
            elseif hl then
                hl:Destroy()
            end
        end
    end
end

local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}
local SKELETON_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local Skeletons = {}
local function destroySkeleton(plr)
    local sk = Skeletons[plr]
    if sk then
        for _,l in pairs(sk.lines) do pcall(function() l:Remove() end) end
        Skeletons[plr] = nil
    end
end
local function hideSkeleton(sk)
    for _,l in pairs(sk.lines) do l.Visible = false end
end

local function buildESP(plr)
    if not plr.Character or plr.Character:FindFirstChild("PiddleHighlight") then return end
    local ch=plr.Character; local hd=ch:FindFirstChild("Head"); if not hd then return end
    pcall(function()
        local h=Instance.new("Highlight")
        h.Name="PiddleHighlight"; h.FillTransparency=0.5; h.OutlineTransparency=0
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Enabled=false; h.Parent=ch
    end)
    pcall(function()
        local tag=Instance.new("BillboardGui")
        tag.Name="PiddleTag"; tag.Size=UDim2.new(0,160,0,40); tag.StudsOffset=Vector3.new(0,3,0)
        tag.AlwaysOnTop=true; tag.Adornee=hd; tag.Enabled=false; tag.Parent=ch
        local lb=Instance.new("TextLabel")
        lb.Size=UDim2.new(1,0,1,0); lb.BackgroundTransparency=1
        lb.Font=Enum.Font.GothamBold; lb.TextSize=16; lb.TextStrokeTransparency=0; lb.Parent=tag
    end)
    pcall(function()
        local box=Instance.new("BoxHandleAdornment")
        box.Name="PiddleBox"; box.Adornee=ch:FindFirstChild("HumanoidRootPart") or hd; box.AlwaysOnTop=true; box.ZIndex=5; box.Visible=false
        box.Size=Vector3.new(4,6,2); box.CFrame=CFrame.new(0,-0.25,0); box.Color3=Color3.fromRGB(255,255,255); box.Transparency=0.7; box.Parent=ch
    end)
end

for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then
        p.CharacterAdded:Connect(function() task.wait(0.5); pcall(buildESP,p) end)
        if p.Character then pcall(buildESP,p) end
    end
end
Players.PlayerAdded:Connect(function(p) if p~=LocalPlayer then p.CharacterAdded:Connect(function() task.wait(0.5); pcall(buildESP,p) end) end end)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        local h=p.Character:FindFirstChild("PiddleHighlight"); if h then h:Destroy() end
        local t=p.Character:FindFirstChild("PiddleTag"); if t then t:Destroy() end
        local b=p.Character:FindFirstChild("PiddleBox"); if b then b:Destroy() end
    end
    if tracers[p] then pcall(function() tracers[p].Visible=false end); tracers[p]=nil end
    destroySkeleton(p)
    espP[p]=nil
end)
task.spawn(function()
    while true do
        task.wait(0.15)
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                pcall(function()
                    local d=p.Character:FindFirstChild("PiddleHighlight")
                    local t=p.Character:FindFirstChild("PiddleTag")
                    local b=p.Character:FindFirstChild("PiddleBox")
                    if (not d or not t or not b) and p.Character:FindFirstChild("Head") then
                        buildESP(p); d=p.Character:FindFirstChild("PiddleHighlight"); t=p.Character:FindFirstChild("PiddleTag"); b=p.Character:FindFirstChild("PiddleBox")
                    end
                    if d and t and b then
                        local r=getRole(p)
                        local realNpc=isRealNpc(p)
                        local isZ=isZombie(p)
                        local c=roleColors[r] or Color3.fromRGB(255,255,255)
                        local tx=r or "Player"
                        local show=false
                        if espP[p] then show=true; c=Color3.fromRGB(220,180,255); tx="SELECTED"
                        elseif ESP_FLAGS.All then show=true
                        elseif ESP_FLAGS.Zombie and isZ then show=true; c=roleColors.Zombie; tx="ZOMBIE"
                        elseif ESP_FLAGS.Gun and hasItem(p,"Gun") then show=true; c=roleColors.Gun; tx="GUN"
                        elseif ESP_FLAGS.NPC and realNpc and r=="NPC" then show=true; c=roleColors.NPC; tx="NPC"
                        elseif r and r~="NPC" and ESP_FLAGS[r] then show=true end
                        local alive = (r~="NPC")
                        local tagOn = show or ((ESP_FLAGS.NameTag or ESP_FLAGS.Distance) and alive)
                        d.Enabled=show
                        t.Enabled=tagOn
                        local hrpB=p.Character:FindFirstChild("HumanoidRootPart")
                        if hrpB and b.Adornee~=hrpB then b.Adornee=hrpB end
                        b.Visible = State.boxESP and alive
                        if show or tagOn or b.Visible then
                            d.FillColor=c; d.OutlineColor=c
                            b.Color3=c
                            local lb=t:FindFirstChildOfClass("TextLabel")
                            if lb then
                                lb.TextColor3=c
                                local s=""
                                if ESP_FLAGS.NameTag then s=p.Name; if show then s=s.." | "..tx end
                                elseif show then s=tx end
                                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                                local lr=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if ESP_FLAGS.Distance and pr and lr then s=s..string.format(" [%dm]",math.floor((pr.Position-lr.Position).Magnitude)) end
                                lb.Text=s
                            end
                        end
                    end
                end)
            end
        end
    end
end)

X.Coins = {list={}, t=0}
function X.Coins.get()
    if os.clock()-X.Coins.t > 0.4 then
        X.Coins.t = os.clock()
        local l = {}
        for _,o in ipairs(WS:GetDescendants()) do
            if o.Name=="Coin_Server" and o:IsA("BasePart") and o:GetAttribute("CoinID")=="Candy" then l[#l+1]=o end
        end
        X.Coins.list = l
    end
    return X.Coins.list
end
X.CandyTags = {}
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if State.candyESP then
                local alive = {}
                for _,o in ipairs(X.Coins.get()) do
                    alive[o] = true
                    if not X.CandyTags[o] or not X.CandyTags[o].Parent then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "PiddleCandy"; bb.AlwaysOnTop = true; bb.Size = UDim2.fromOffset(16,16); bb.Adornee = o; bb.Parent = o
                        local f = Instance.new("Frame")
                        f.Size = UDim2.fromScale(1,1); f.BackgroundColor3 = Color3.fromRGB(255,140,40); f.BorderSizePixel = 0; f.Parent = bb
                        local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(1,0); cr.Parent = f
                        local st = Instance.new("UIStroke"); st.Color = Color3.new(1,1,1); st.Thickness = 1.5; st.Parent = f
                        X.CandyTags[o] = bb
                    end
                end
                for o,bb in pairs(X.CandyTags) do
                    if not alive[o] then pcall(function() bb:Destroy() end); X.CandyTags[o] = nil end
                end
            else
                for o,bb in pairs(X.CandyTags) do pcall(function() bb:Destroy() end); X.CandyTags[o] = nil end
            end
        end)
    end
end)

Connect(RunService.RenderStepped, function()
    pcall(function()
        if not State.skeletonESP or not Drawing then
            for _,sk in pairs(Skeletons) do hideSkeleton(sk) end
            return
        end
        local cam = WS.CurrentCamera
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local sk = Skeletons[p]
                if not sk then sk = {lines={}}; Skeletons[p] = sk end
                local ch = p.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local r = getRole(p)
                if not ch or not hum or hum.Health <= 0 or r == "NPC" then
                    hideSkeleton(sk)
                else
                    local map = (hum.RigType == Enum.HumanoidRigType.R15) and SKELETON_R15 or SKELETON_R6
                    local col = roleColors[r] or Color3.fromRGB(255,255,255)
                    for i,pair in ipairs(map) do
                        local a = ch:FindFirstChild(pair[1])
                        local b = ch:FindFirstChild(pair[2])
                        local line = sk.lines[i]
                        if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                            if not line then
                                line = Drawing.new("Line")
                                line.Thickness = 1.5
                                sk.lines[i] = line
                            end
                            local pa, onA = cam:WorldToViewportPoint(a.Position)
                            local pb, onB = cam:WorldToViewportPoint(b.Position)
                            if onA and onB then
                                line.Color = col
                                line.Transparency = 1
                                line.From = Vector2.new(pa.X, pa.Y)
                                line.To = Vector2.new(pb.X, pb.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                    for i = #map + 1, #sk.lines do
                        if sk.lines[i] then sk.lines[i].Visible = false end
                    end
                end
            end
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    if not State.tracersOn or not Drawing then
        for _,line in pairs(tracers) do pcall(function() line.Visible=false end) end
        return
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local ch=p.Character
            local hum=ch and ch:FindFirstChildOfClass("Humanoid")
            local hd=ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
            local line=tracers[p]
            if hd and hum and hum.Health>0 and getRole(p)~="NPC" then
                local v,onScreen=Cam:WorldToViewportPoint(hd.Position)
                if onScreen then
                    if not line then
                        line=Drawing.new("Line"); line.Thickness=1.5; line.Transparency=0.9; line.Visible=false; tracers[p]=line
                    end
                    line.Color=roleColors[getRole(p)] or Color3.fromRGB(255,255,255)
                    line.To=Vector2.new(v.X,v.Y)
                    line.From=Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                    line.Visible=true
                elseif line then
                    line.Visible=false
                end
            elseif line then
                line.Visible=false
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if KillFx.EyeLaser and LocalPlayer.Character then
            pcall(function()
                local ch=LocalPlayer.Character
                local myHead=ch:FindFirstChild("Head"); if not myHead then return end
                local origin=myHead.Position
                local dir=Cam.CFrame.LookVector
                local rp=RaycastParams.new()
                rp.FilterType=Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances={ch}
                local hit=WS:Raycast(origin,dir*KillFx.EyeLaserRange,rp)
                local hitPos=hit and hit.Position or (origin+dir*KillFx.EyeLaserRange)
                if not KillFx._beam or not KillFx._beam.Parent then
                    KillFx._beam=Instance.new("Part")
                    KillFx._beam.Size=Vector3.new(0.2,0.2,1)
                    KillFx._beam.Material=Enum.Material.Neon
                    KillFx._beam.Anchored=true; KillFx._beam.CanCollide=false; KillFx._beam.CanQuery=false
                    KillFx._beam.Parent=WS
                end
                if not KillFx._beam2 or not KillFx._beam2.Parent then
                    KillFx._beam2=Instance.new("Part")
                    KillFx._beam2.Size=Vector3.new(0.2,0.2,1)
                    KillFx._beam2.Material=Enum.Material.Neon
                    KillFx._beam2.Anchored=true; KillFx._beam2.CanCollide=false; KillFx._beam2.CanQuery=false
                    KillFx._beam2.Parent=WS
                end
                local leftEye = myHead.CFrame * CFrame.new(-0.2, 0.1, -0.3)
                local rightEye = myHead.CFrame * CFrame.new(0.2, 0.1, -0.3)
                
                local function updateBeam(b, startPos)
                    b.Size=Vector3.new(0.15,0.15,(hitPos-startPos).Magnitude)
                    b.CFrame=CFrame.new((startPos+hitPos)/2,hitPos)
                    b.Transparency=0
                end
                updateBeam(KillFx._beam, leftEye.Position)
                updateBeam(KillFx._beam2, rightEye.Position)
                KillFx._beam.Color = CFG.laserColor
                KillFx._beam2.Color = CFG.laser2Color
                
                if hit and hit.Instance then
                    local model=hit.Instance:FindFirstAncestorOfClass("Model")
                    local plr=model and Players:GetPlayerFromCharacter(model)
                    if plr and plr~=LocalPlayer and tick()-KillFx.EyeLaserCd>0.3 then
                        local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not Fling.busy then
                                KillFx.EyeLaserCd=tick()
                                flingPlayer(plr)
                            end
                        end
                    end
                end
            end)
        else
            if KillFx._beam and KillFx._beam.Parent then KillFx._beam.Transparency=1 end
            if KillFx._beam2 and KillFx._beam2.Parent then KillFx._beam2.Transparency=1 end
        end
    end
end)

local envParams=RaycastParams.new(); envParams.FilterType=Enum.RaycastFilterType.Exclude
local function updateDodgeFilters()
    local ch=LocalPlayer.Character
    local ign={Cam}; if ch then table.insert(ign,ch) end
    envParams.FilterDescendantsInstances=ign
end
if LocalPlayer.Character then updateDodgeFilters() end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.3); updateDodgeFilters() end)

UD.ScanRadius=14; UD.DodgeDist=8; UD.BaseCooldown=0.45; UD.WallBuffer=2.5

function X.dodgeThreat(root)
    local myRole=getRole(LocalPlayer)
    local best,bd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.UserId>0 then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health>0 then
                local threat
                if myRole=="Murderer" then threat=hasItem(p,"Gun")
                else threat=(getRole(p)=="Murderer") or hasItem(p,"Knife") end
                if threat then
                    local d=(r.Position-root.Position).Magnitude
                    if d<bd then best,bd=r,d end
                end
            end
        end
    end
    return best,bd
end

function X.dodgeSpot(root, away)
    local origin=root.Position
    local fh=WS.FallenPartsDestroyHeight
    if fh~=fh then fh=-500 end
    local voidY=fh+25
    local myFloor=WS:Raycast(origin,Vector3.new(0,-15,0),envParams)
    local height=myFloor and (origin.Y-myFloor.Position.Y) or 3
    local baseY=myFloor and myFloor.Position.Y or (origin.Y-3)
    for _,deg in ipairs({0,35,-35,70,-70,110,-110,150,-150,180}) do
        local dir=CFrame.Angles(0,math.rad(deg),0)*away
        local wall=WS:Raycast(origin,dir*UD.DodgeDist,envParams)
        local d=wall and math.max(wall.Distance-UD.WallBuffer,0) or UD.DodgeDist
        if d>=2 then
            local target=origin+dir*d
            local floor=WS:Raycast(target+Vector3.new(0,4,0),Vector3.new(0,-30,0),envParams)
            if floor and floor.Position.Y>voidY and math.abs(floor.Position.Y-baseY)<=12 then
                return Vector3.new(target.X,floor.Position.Y+height,target.Z)
            end
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not UD.enabled then return end
    local ch=LocalPlayer.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    local now=tick()
    if UD.isDodging or now-UD.lastDodgeTime<UD.BaseCooldown then return end
    local thr,dist=X.dodgeThreat(root)
    if not thr or dist>UD.ScanRadius then return end
    local toMe=Vector3.new(root.Position.X-thr.Position.X,0,root.Position.Z-thr.Position.Z)
    if toMe.Magnitude<0.05 then toMe=Vector3.new(1,0,0) end
    local away=toMe.Unit
    local approaching=thr.AssemblyLinearVelocity:Dot(away)>3
    if not approaching and dist>6 then return end
    UD.isDodging=true
    local okd,spot=pcall(X.dodgeSpot,root,away)
    if not okd then spot=nil end
    if spot then
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        root.CFrame=CFrame.new(spot)*(root.CFrame-root.CFrame.Position)
        UD.lastDodgeTime=now
    end
    task.wait(0.05)
    UD.isDodging=false
end)

local FlyFarm = {on=false, speed=15, collected=0, startTime=0, visited={}, mode=CFG.autoFarmMode or "under", depth=2, tween=nil, held=false, home=nil}
function FlyFarm.release()
    State.farmClip=false
    FlyFarm.held=false
    if not State.noclip then X.NC.restore() end
    local ch=LocalPlayer.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    local hm=ch and ch:FindFirstChildOfClass("Humanoid")
    if hm then hm.PlatformStand=false end
    if hrp then hrp.AssemblyLinearVelocity=Vector3.zero end
end
function FlyFarm.stop()
    if FlyFarm.tween then pcall(function() FlyFarm.tween:Cancel() end); FlyFarm.tween=nil end
    local ch=LocalPlayer.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    local hm=ch and ch:FindFirstChildOfClass("Humanoid")
    local wasHeld=FlyFarm.held
    FlyFarm.release()
    if hrp and hm and hm.Health>0 then
        if wasHeld and FlyFarm.home then
            hrp.CFrame=FlyFarm.home
        else
            hrp.CFrame=CFrame.new(hrp.Position)
        end
    end
    FlyFarm.home=nil
end
function X.resetChar()
    if State.fastRespawn then X.RESP.go("fast") elseif State.autoRespawn then X.RESP.go("auto") end
    local ch=LocalPlayer.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.Health=0 end) end
end
function X.shootMurderer()
    local ch=LocalPlayer.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    local g=getGun()
    if not g or not hum or hum.Health<=0 then return false end
    if getRole(LocalPlayer)=="Murderer" then return false end
    local m=findMurderer()
    local mch=m and m.Character
    local mr=mch and mch:FindFirstChild("HumanoidRootPart")
    if not mr then return false end
    if g.Parent~=ch then hum:EquipTool(g); task.wait(0.25) end
    for _=1,3 do
        local part=mch:FindFirstChild("Head") or mr
        local origin,aim=preciseAim(part,mch)
        if origin and aim then fireGunWallbang(aim,part) end
        task.wait(0.35)
        local mh=mch:FindFirstChildOfClass("Humanoid")
        if not mh or mh.Health<=0 then break end
    end
    return true
end
Connect(RunService.Heartbeat, function()
    if not FlyFarm.held then return end
    local ch=LocalPlayer.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health>0 then
        hrp.AssemblyLinearVelocity=Vector3.zero
    else
        FlyFarm.held=false
        State.farmClip=false
    end
end)
Connect(LocalPlayer.CharacterAdded, function()
    FlyFarm.held=false
    FlyFarm.home=nil
    FlyFarm.visited={}
    FlyFarm.collected=0
    State.farmClip=false
end)
task.spawn(function()
    while true do
        task.wait(0.1)
        if FlyFarm.on and LocalPlayer.Character then
            pcall(function()
                local ch = LocalPlayer.Character
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                local hum = ch:FindFirstChildOfClass("Humanoid")
                local murderer = findMurderer()
                local inRound = murderer or findSheriff()
                if not hrp or not hum or hum.Health <= 0 or not inRound then
                    if FlyFarm.held or State.farmClip then FlyFarm.release() end
                    if next(FlyFarm.visited) then FlyFarm.visited = {} end
                    return
                end
                local mr = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
                local murdererPos = mr and mr.Position
                local closest, dist = nil, math.huge
                for _, obj in ipairs(X.Coins.get()) do
                    if obj.Parent and not FlyFarm.visited[obj] then
                        local d = (obj.Position - hrp.Position).Magnitude
                        if d < dist and d <= 300 then
                            if not (murdererPos and (obj.Position - murdererPos).Magnitude < 25) then
                                closest, dist = obj, d
                            end
                        end
                    end
                end
                if not closest then
                    if next(FlyFarm.visited) then FlyFarm.visited = {} end
                    return
                end
                if not FlyFarm.held then FlyFarm.home = hrp.CFrame; FlyFarm.held = true end
                State.farmClip = true
                if FlyFarm.mode == "under" then hum.PlatformStand = true end
                FlyFarm.visited[closest] = true
                local off = (FlyFarm.mode == "under") and Vector3.new(0, -FlyFarm.depth, 0) or Vector3.new(0, 0.5, 0)
                local dest = closest.Position + off
                local travel = (dest - hrp.Position).Magnitude
                local dur = math.max(travel / FlyFarm.speed, 0.05)
                local lie = (FlyFarm.mode == "under") and CFrame.Angles(math.rad(-90), 0, 0) or CFrame.new()
                FlyFarm.tween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = CFrame.new(dest) * lie })
                FlyFarm.tween:Play()
                local t0 = os.clock()
                while FlyFarm.on and hrp.Parent and closest.Parent and os.clock() - t0 < dur + 0.3 do
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    task.wait()
                end
                if FlyFarm.tween then pcall(function() FlyFarm.tween:Cancel() end); FlyFarm.tween = nil end
                if FlyFarm.on and hrp.Parent and closest.Parent then
                    hrp.CFrame = CFrame.new(dest) * lie
                    EX.touch(hrp, closest, true)
                    FlyFarm.collected = FlyFarm.collected + 1
                    task.wait(0.05)
                end
                if FlyFarm.collected >= 50 then
                    FlyFarm.on = false
                    FlyFarm.stop()
                    if CFG.farmFullShoot then pcall(X.shootMurderer) end
                    if CFG.autoFarmReset then
                        pcall(X.resetChar)
                        Library:Notify({Title="Farm", Text="50 coins collected, resetting...", Duration=3})
                    else
                        Library:Notify({Title="Farm", Text="50 coins collected (auto reset OFF)", Duration=3})
                    end
                end
            end)
        end
    end
end)

local VisState={weather=nil,thread=nil,particles={}}
local atmosphere=nil
local function ensureAtmosphere(on)
    if on and not atmosphere then
        atmosphere=Instance.new("Atmosphere"); atmosphere.Density=0.3; atmosphere.Haze=1.5; atmosphere.Glare=0.2
        atmosphere.Color=Color3.fromRGB(199,199,199); atmosphere.Decay=Color3.fromRGB(106,112,125); atmosphere.Parent=Lighting
    elseif not on and atmosphere then pcall(function() atmosphere:Destroy() end); atmosphere=nil end
end
X.W = {
    snd=nil, thunder=nil, custom="",
    rain={}, thunderIds={}, thunderCustom="",
    baseBrightness=nil, spin={},
}
function X.W.load(snd, ids, kind)
    for _,id in ipairs(ids) do
        if VisState.weather ~= kind then return false end
        snd.SoundId = id
        local t0 = os.clock()
        while not snd.IsLoaded and os.clock() - t0 < 2.5 do task.wait(0.1) end
        if snd.IsLoaded and snd.TimeLength > 0 then return true end
    end
    return false
end
function X.W.stopSound()
    if X.W.snd then pcall(function() X.W.snd:Stop(); X.W.snd:Destroy() end); X.W.snd=nil end
    if X.W.thunder then pcall(function() X.W.thunder:Stop(); X.W.thunder:Destroy() end); X.W.thunder=nil end
end
function X.W.startSound(kind)
    X.W.stopSound()
    if kind ~= "Rain" and kind ~= "Storm" then return end
    local snd = Instance.new("Sound")
    snd.Name = "PiddleWeatherSound"; snd.Looped = true; snd.Volume = (kind=="Storm") and 0.9 or 0.6; snd.Parent = SoundService
    X.W.snd = snd
    if X.W.custom == "" then
        Library:Notify({Title="weather", Text="paste a sound id in 'rain sound id'", Duration=4})
    else
        task.spawn(function()
            if X.W.load(snd, {X.W.custom}, kind) and X.W.snd == snd and VisState.weather == kind then snd:Play() end
        end)
    end
    if kind == "Storm" then
        local th = Instance.new("Sound")
        th.Name = "PiddleThunder"; th.Volume = 1; th.Parent = SoundService
        X.W.thunder = th
        if X.W.thunderCustom ~= "" then task.spawn(function() X.W.load(th, {X.W.thunderCustom}, kind) end) end
    end
end
local function clearWeather()
    VisState.weather=nil
    for _,p in ipairs(VisState.particles) do pcall(function() p:Destroy() end) end
    VisState.particles={}
    X.W.spin={}
    X.W.stopSound()
    if X.W.baseBrightness then pcall(function() Lighting.Brightness=X.W.baseBrightness end); X.W.baseBrightness=nil end
end
local function spawnWeather(kind)
    clearWeather(); VisState.weather=kind
    local root=Instance.new("Folder"); root.Name="PiddleWeather"; root.Parent=WS
    table.insert(VisState.particles,root)
    local function rnd() return Cam.CFrame.Position+Vector3.new(math.random(-80,80),math.random(20,60),math.random(-80,80)) end
    if kind=="Rain" or kind=="Storm" then
        for i=1,150 do
            local p=Instance.new("Part"); p.Size=Vector3.new(0.08,1.2,0.08)
            p.Anchored=true; p.CanCollide=false; p.Color=Color3.fromRGB(180,200,255); p.Transparency=0.3
            p.CFrame=CFrame.new(rnd()); p.Parent=root; p.CanQuery=false; p.CanTouch=false
        end
    elseif kind=="Snow" then
        for i=1,120 do
            local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(0.4,0.4,0.4)
            p.Anchored=true; p.CanCollide=false; p.Color=Color3.fromRGB(255,255,255); p.Transparency=0.2
            p.CFrame=CFrame.new(rnd()); p.Parent=root; p.CanQuery=false; p.CanTouch=false
        end
    elseif kind=="Leaves" then
        for i=1,80 do
            local p=Instance.new("Part"); p.Size=Vector3.new(0.6,0.1,0.6)
            p.Anchored=true; p.CanCollide=false; p.Color=Color3.fromRGB(180,90,30); p.Transparency=0.2
            p.CFrame=CFrame.new(rnd()); p.Parent=root; p.CanQuery=false; p.CanTouch=false
            X.W.spin[p]={ang=Vector3.new(math.random()*6,math.random()*6,math.random()*6),
                vel=Vector3.new((math.random()-0.5)*2.4,(math.random()-0.5)*2.4,(math.random()-0.5)*2.4)}
        end
    elseif kind=="Embers" then
        for i=1,120 do
            local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(0.2,0.2,0.2)
            p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon
            p.Color=Color3.fromRGB(255,100,20); p.Transparency=0.1
            p.CFrame=CFrame.new(Cam.CFrame.Position+Vector3.new(math.random(-80,80),math.random(-20,40),math.random(-80,80))); p.Parent=root; p.CanQuery=false; p.CanTouch=false
        end
    end
    X.W.startSound(kind)
    if kind=="Storm" then X.W.baseBrightness = Lighting.Brightness end
    if VisState.thread then pcall(function() task.cancel(VisState.thread) end) end
    VisState.thread=task.spawn(function()
        local nextThunder = os.clock() + math.random(5,12)
        while VisState.weather and VisState.weather~="None" do
            local dt=RunService.Heartbeat:Wait()
            local camPos=Cam.CFrame.Position
            for _,p in ipairs(root:GetChildren()) do
                if p:IsA("BasePart") and p.Parent then
                    local pos=p.Position
                    if kind=="Rain" or kind=="Storm" then pos=pos+Vector3.new(0,-3,0)
                    elseif kind=="Snow" then pos=pos+Vector3.new(math.sin(tick()*2+p.Position.X)*0.05,-0.6,0)
                    elseif kind=="Leaves" then pos=pos+Vector3.new(math.sin(tick()*1.5+p.Position.Z)*0.1,-0.5,0)
                    elseif kind=="Embers" then pos=pos+Vector3.new(math.sin(tick()*3+p.Position.X)*0.2,1.5,0) end
                    local off=pos-camPos
                    if off.Y<-10 or math.abs(off.X)>90 or math.abs(off.Z)>90 then
                        pos=camPos+Vector3.new(math.random(-80,80),math.random(30,60),math.random(-80,80))
                    elseif kind=="Embers" and off.Y>50 then
                        pos=camPos+Vector3.new(math.random(-80,80),-20,math.random(-80,80))
                    end
                    local s=X.W.spin[p]
                    if s then
                        s.ang=s.ang+s.vel*dt
                        p.CFrame=CFrame.new(pos)*CFrame.Angles(s.ang.X,s.ang.Y,s.ang.Z)
                    else
                        p.CFrame=CFrame.new(pos)
                    end
                end
            end
            if kind=="Storm" and os.clock()>=nextThunder then
                nextThunder=os.clock()+math.random(6,14)
                task.spawn(function()
                    local base=X.W.baseBrightness or Lighting.Brightness
                    Lighting.Brightness=base+3
                    task.wait(0.07)
                    Lighting.Brightness=base
                    task.wait(0.08)
                    Lighting.Brightness=base+2
                    task.wait(0.05)
                    Lighting.Brightness=base
                    if X.W.thunder and X.W.thunder.IsLoaded then X.W.thunder:Play() end
                end)
            end
        end
    end)
end
local function applyLightingPreset(name)
    if name=="Default" then
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.Ambient=Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
        Lighting.FogEnd=1000; Lighting.FogColor=Color3.fromRGB(192,192,192); ensureAtmosphere(false)
    elseif name=="Night" then
        Lighting.Brightness=0.5; Lighting.ClockTime=0; Lighting.Ambient=Color3.fromRGB(30,30,50); Lighting.OutdoorAmbient=Color3.fromRGB(50,50,80)
        Lighting.FogEnd=400; Lighting.FogColor=Color3.fromRGB(20,20,40); ensureAtmosphere(true)
    elseif name=="Deep Night" then
        Lighting.Brightness=0.1; Lighting.ClockTime=0; Lighting.Ambient=Color3.fromRGB(5,5,15); Lighting.OutdoorAmbient=Color3.fromRGB(15,15,35)
        Lighting.FogEnd=150; Lighting.FogColor=Color3.fromRGB(5,5,15); ensureAtmosphere(true)
    elseif name=="Sunset" then
        Lighting.Brightness=1.5; Lighting.ClockTime=18; Lighting.Ambient=Color3.fromRGB(120,60,40); Lighting.OutdoorAmbient=Color3.fromRGB(200,100,70)
        Lighting.FogEnd=600; Lighting.FogColor=Color3.fromRGB(255,150,80); ensureAtmosphere(true)
    elseif name=="Dawn" then
        Lighting.Brightness=1.5; Lighting.ClockTime=6; Lighting.Ambient=Color3.fromRGB(120,80,120); Lighting.OutdoorAmbient=Color3.fromRGB(200,160,180)
        Lighting.FogEnd=800; Lighting.FogColor=Color3.fromRGB(255,180,200); ensureAtmosphere(true)
    elseif name=="Rainy" then
        Lighting.Brightness=1; Lighting.ClockTime=14; Lighting.Ambient=Color3.fromRGB(60,65,75); Lighting.OutdoorAmbient=Color3.fromRGB(90,95,110)
        Lighting.FogEnd=300; Lighting.FogColor=Color3.fromRGB(80,85,95); ensureAtmosphere(true)
    elseif name=="Foggy" then
        Lighting.Brightness=1.5; Lighting.ClockTime=14; Lighting.FogEnd=100; Lighting.FogColor=Color3.fromRGB(200,200,200); ensureAtmosphere(true)
    elseif name=="Storm" then
        Lighting.Brightness=0.8; Lighting.ClockTime=12; Lighting.Ambient=Color3.fromRGB(40,45,55); Lighting.OutdoorAmbient=Color3.fromRGB(70,75,90)
        Lighting.FogEnd=200; Lighting.FogColor=Color3.fromRGB(60,65,80); ensureAtmosphere(true)
    elseif name=="Realistic" then
        Lighting.Brightness=2; Lighting.ClockTime=15; Lighting.Ambient=Color3.fromRGB(80,80,80); Lighting.OutdoorAmbient=Color3.fromRGB(140,140,140)
        Lighting.FogEnd=1e6; ensureAtmosphere(false)
    end
end

local TRADE={loaded=false, items={}}
local SUPREME_URL="https://supremevalues.com/api/values.json"
local function parseItems(json)
    if not json or #json<100 then return false end
    local ok,data=pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or not data or not data.d then return false end
    TRADE.items={}
    for cat,list in pairs(data.d) do
        if type(list)=="table" then
            for _,row in ipairs(list) do
                local id=row[1] or "unknown"; local alias=row[2] or ""
                local kind=row[3] or ""; local year=row[4] or 0; local val=row[5] or 0
                local disp=id:gsub("^%l",string.upper)
                if alias~="" then disp=disp.." ("..alias..")" end
                table.insert(TRADE.items,{id=id,name=disp,alias=alias,kind=kind,year=year,value=val,category=cat})
            end
        end
    end
    TRADE.loaded=true; return true
end
local function fetchSupremeValues()
    local req=(syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok,res=pcall(function() return req({Url=SUPREME_URL,Method="GET"}) end)
        if ok and res and res.Body and #res.Body>100 then if parseItems(res.Body) then return true end end
    end
    local ok,body=pcall(function() return HttpService:GetAsync(SUPREME_URL) end)
    if ok and body and #body>100 then if parseItems(body) then return true end end
    return false
end
task.spawn(function() fetchSupremeValues(); while true do task.wait(300); fetchSupremeValues() end end)
local function findTradeItem(q)
    if not q or q=="" then return nil end
    q=q:lower()
    local ex,par
    for _,it in ipairs(TRADE.items) do
        local id=it.id:lower(); local nm=it.name:lower()
        if id==q or nm==q then ex=it; break end
        if not par and (id:find(q,1,true) or nm:find(q,1,true)) then par=it end
    end
    return ex or par
end
local priceTags={}
local function attachPriceTag(tool)
    if not tool or not tool:IsA("Tool") then return end
    if priceTags[tool] then return end
    local item=findTradeItem(tool.Name)
    if not item then return end
    local part=tool:FindFirstChildWhichIsA("BasePart",true)
    if not part then return end
    local bill=Instance.new("BillboardGui")
    bill.Name="PiddlePriceTag"; bill.Size=UDim2.new(0,160,0,40); bill.StudsOffset=Vector3.new(0,2.5,0)
    bill.AlwaysOnTop=true; bill.Adornee=part; bill.Parent=part
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.fromScale(1,1); lbl.BackgroundTransparency=1
    lbl.Text=item.name.."\n$"..tostring(item.value)
    lbl.TextColor3=Color3.fromRGB(255,220,80); lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.TextStrokeTransparency=0
    lbl.Parent=bill; priceTags[tool]=bill
end
task.spawn(function()
    while true do
        task.wait(2)
        if not State.tradeHelperOn then
            for tool,bill in pairs(priceTags) do pcall(function() bill:Destroy() end); priceTags[tool]=nil end
        else
            local bp=LocalPlayer:FindFirstChild("Backpack")
            local ch=LocalPlayer.Character
            for _,cont in ipairs({bp,ch}) do
                if cont then
                    for _,tool in ipairs(cont:GetChildren()) do
                        if tool:IsA("Tool") then attachPriceTag(tool) end
                    end
                end
            end
        end
    end
end)

local function normalKillAura()
    if not State.killAuraOn then return end
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local root = ch:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local role = getRole(LocalPlayer)
    local now = tick()
    if now - (State.killAuraCd or 0) < 0.15 then return end
    if role == "Murderer" then
        local k = getKnife()
        if k then
            if k.Parent ~= ch then hum:EquipTool(k); task.wait(0.05) end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not isRealNpc(p) then
                    local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local thum = p.Character:FindFirstChildOfClass("Humanoid")
                    if thrp and thum and thum.Health > 0 then
                        if (thrp.Position - root.Position).Magnitude <= 12 then
                            local ev = k:FindFirstChild("Events")
                            local ht = ev and ev:FindFirstChild("HandleTouched")
                            if ht then pcall(function() ht:FireServer(thrp) end) end
                            State.killAuraCd = now
                        end
                    end
                end
            end
        end
    elseif role == "Sheriff" or role == "Hero" then
        local g = getGun()
        if g then
            if g.Parent ~= ch then hum:EquipTool(g); task.wait(0.05) end
            local shoot = g:FindFirstChild("Shoot")
            if shoot then
                local head = ch:FindFirstChild("Head") or root
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and not isRealNpc(p) then
                        local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local thum = p.Character:FindFirstChildOfClass("Humanoid")
                        if thrp and thum and thum.Health > 0 then
                            if (thrp.Position - root.Position).Magnitude <= 200 then
                                pcall(function() shoot:FireServer(CFrame.new(head.Position, thrp.Position), CFrame.new(thrp.Position)) end)
                                State.killAuraCd = now
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end
RunService.Heartbeat:Connect(function() pcall(normalKillAura) end)

X.runKillCd = 0
RunService.Heartbeat:Connect(function()
    if not KillFx.RunKill then return end
    pcall(function()
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return end
        local k = getKnife()
        if not k then return end
        local now = os.clock()
        if now - X.runKillCd < 0.1 then return end
        if k.Parent ~= ch then hum:EquipTool(k); return end
        local ev = k:FindFirstChild("Events")
        local ht = ev and ev:FindFirstChild("HandleTouched")
        local handle = k:FindFirstChild("Handle")
        if not ht then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not isRealNpc(p) then
                local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                local thum = p.Character:FindFirstChildOfClass("Humanoid")
                if thrp and thum and thum.Health > 0 and (thrp.Position - root.Position).Magnitude <= KillFx.RunKillRange then
                    X.runKillCd = now
                    X.stab(k, ht, handle, thrp)
                end
            end
        end
    end)
end)

local HomeTab = Win:AddTab({Name="main", Subtitle="home"})
local HomeMain = HomeTab:AddSection({Name="general", Side="Left"})
HomeMain:AddButton({Name="save config", Callback=function() saveCFG(); Library:Notify({Title="piddle", Text="config saved"}) end})
HomeMain:AddButton({Name="reset character", Callback=function() if LocalPlayer.Character then pcall(function() LocalPlayer.Character:BreakJoints() end) end end})
HomeMain:AddButton({Name="rejoin server", Callback=function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end})
HomeMain:AddButton({Name="close ui", Callback=function() Win:SetVisible(false) end})
local HomeInfo = HomeTab:AddSection({Name="info", Side="Right"})
local roleLbl2 = HomeInfo:AddLabel({Name="role: --"})
local pingLbl2 = HomeInfo:AddLabel({Name="ping: --"})
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            roleLbl2:SetText("role: "..getRole(LocalPlayer))
            pingLbl2:SetText("ping: "..math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()).."ms")
        end)
    end
end)

local CombatTab = Win:AddTab({Name="combat", Subtitle="murderer & sheriff"})
local MurderSec = CombatTab:AddSection({Name="murderer", Side="Left"})
MurderSec:AddToggle({Name="kill aura", Callback=function(v) State.killAuraOn=v end})
MurderSec:AddButton({Name="kill all", Callback=function() task.spawn(X.killAll, true) end})
MurderSec:AddToggle({Name="auto throw", Callback=function(v) State.autoThrow=v end})
local SheriffSec = CombatTab:AddSection({Name="sheriff / hero", Side="Right"})
SheriffSec:AddToggle({Name="aimlock (sheriff only)", Callback=function(v) State.aimlockSheriff=v end})
SheriffSec:AddToggle({Name="auto shoot", Callback=function(v)
    State.autoShoot=v
    if v then
        State.autoGun=true
        pcall(function() GD.watch(true) end)
        pcall(GD.find)
    else
        State.autoGun=State.autoGunUser or false
        if not State.autoGun then pcall(function() GD.watch(false) end) end
    end
end})
SheriffSec:AddToggle({Name="shoot through walls", Default=CFG.shootThroughWalls, Callback=function(v) State.shootThroughWalls=v; CFG.shootThroughWalls=v; saveCFG() end})
SheriffSec:AddToggle({Name="predict movement", Default=CFG.predictMovement, Callback=function(v) State.predictMovement=v; CFG.predictMovement=v; saveCFG() end})
local KillFxSec = CombatTab:AddSection({Name="kill features", Side="Left"})
KillFxSec:AddToggle({Name="eye laser", Callback=function(v) KillFx.EyeLaser=v end})
KillFxSec:AddSlider({Name="laser range", Min=50, Max=500, Default=200, Callback=function(v) KillFx.EyeLaserRange=v end})
KillFxSec:AddColorPicker({Name="laser color 1", Default=CFG.laserColor, Callback=function(c) CFG.laserColor=c; saveCFG() end})
KillFxSec:AddColorPicker({Name="laser color 2", Default=CFG.laser2Color, Callback=function(c) CFG.laser2Color=c; saveCFG() end})
KillFxSec:AddToggle({Name="run kill", Callback=function(v) KillFx.RunKill=v end})
KillFxSec:AddSlider({Name="run kill range", Min=1, Max=20, Default=4, Callback=function(v) KillFx.RunKillRange=v end})

local VisualsTab = Win:AddTab({Name="visuals", Subtitle="esp & lighting"})
local ESPSec = VisualsTab:AddSection({Name="esp", Side="Left"})
ESPSec:AddToggle({Name="esp all", Callback=function(v) ESP_FLAGS.All=v end})
ESPSec:AddToggle({Name="esp murderer", Callback=function(v) ESP_FLAGS.Murderer=v end})
ESPSec:AddToggle({Name="esp sheriff", Callback=function(v) ESP_FLAGS.Sheriff=v end})
ESPSec:AddToggle({Name="esp innocent", Callback=function(v) ESP_FLAGS.Innocent=v end})
ESPSec:AddToggle({Name="esp zombie", Callback=function(v) ESP_FLAGS.Zombie=v end})
ESPSec:AddToggle({Name="esp npc", Callback=function(v) ESP_FLAGS.NPC=v end})
ESPSec:AddToggle({Name="esp gun", Callback=function(v) ESP_FLAGS.Gun=v end})
ESPSec:AddToggle({Name="esp nametag", Callback=function(v) ESP_FLAGS.NameTag=v end})
ESPSec:AddToggle({Name="esp distance", Callback=function(v) ESP_FLAGS.Distance=v end})
ESPSec:AddToggle({Name="skeleton esp", Default=CFG.espSkeleton, Callback=function(v) State.skeletonESP=v; CFG.espSkeleton=v; saveCFG() end})
ESPSec:AddToggle({Name="box esp", Default=CFG.espBox, Callback=function(v) State.boxESP=v; CFG.espBox=v; saveCFG() end})
ESPSec:AddToggle({Name="esp candy", Callback=function(v) State.candyESP=v end})
ESPSec:AddToggle({Name="tracers", Default=false, Callback=function(v)
    State.tracersOn=v
    if not v then
        for _,line in pairs(tracers) do pcall(function() line.Visible=false end) end
    end
end})
Connect(Players.PlayerRemoving, function(p)
    if tracers[p] then pcall(function() tracers[p]:Remove() end); tracers[p]=nil end
end)
local AuraSec = VisualsTab:AddSection({Name="player aura", Side="Right"})
AuraSec:AddToggle({Name="enable aura", Callback=function(v) State.playerAuraOn=v end})
AuraSec:AddColorPicker({Name="aura color", Default=Color3.fromRGB(255,100,130), Callback=function(c) State.playerAuraColor=c; if State.playerAuraPart then State.playerAuraPart.Color=c end; if State.playerAuraLight then State.playerAuraLight.Color=c end end})
local LightSec = VisualsTab:AddSection({Name="lighting presets", Side="Left"})
for _,n in ipairs({"Night","Deep Night","Sunset","Dawn","Rainy","Foggy","Storm","Realistic","Default"}) do
    LightSec:AddButton({Name=n, Callback=function() applyLightingPreset(n) end})
end
local WeatherSec = VisualsTab:AddSection({Name="weather", Side="Right"})
WeatherSec:AddButton({Name="none", Callback=function() clearWeather() end})
WeatherSec:AddButton({Name="rain", Callback=function() spawnWeather("Rain") end})
WeatherSec:AddButton({Name="snow", Callback=function() spawnWeather("Snow") end})
WeatherSec:AddButton({Name="leaves", Callback=function() spawnWeather("Leaves") end})
WeatherSec:AddButton({Name="embers", Callback=function() spawnWeather("Embers") end})
WeatherSec:AddButton({Name="storm", Callback=function() spawnWeather("Storm") end})
X.W.custom = ResolveImage(CFG.rainSoundId or "")
X.W.thunderCustom = ResolveImage(CFG.thunderSoundId or "")
WeatherSec:AddTextbox({Name="rain sound id", Placeholder="sound id", Default=CFG.rainSoundId or "", Callback=function(v)
    CFG.rainSoundId = v; saveCFG()
    X.W.custom = ResolveImage(v)
    if VisState.weather=="Rain" or VisState.weather=="Storm" then X.W.startSound(VisState.weather) end
end})
WeatherSec:AddTextbox({Name="thunder sound id", Placeholder="sound id", Default=CFG.thunderSoundId or "", Callback=function(v)
    CFG.thunderSoundId = v; saveCFG()
    X.W.thunderCustom = ResolveImage(v)
    if VisState.weather=="Storm" then X.W.startSound("Storm") end
end})
local LightCtlSec = VisualsTab:AddSection({Name="lighting", Side="Left"})
LightCtlSec:AddToggle({Name="fullbright", Callback=function(o) Lighting.Brightness=o and 3 or 2; Lighting.OutdoorAmbient=o and Color3.new(1,1,1) or Color3.fromRGB(128,128,128) end})
LightCtlSec:AddToggle({Name="no fog", Callback=function(o) Lighting.FogEnd=o and 1e6 or 1000 end})
LightCtlSec:AddSlider({Name="time of day", Min=0, Max=24, Default=14, Callback=function(v) Lighting.ClockTime=v end})
LightCtlSec:AddSlider({Name="brightness", Min=0, Max=5, Default=2, Callback=function(v) Lighting.Brightness=v end})
LightCtlSec:AddSlider({Name="fov", Min=50, Max=130, Default=70, Callback=function(v) Cam.FieldOfView=v end})

local PlayersTab = Win:AddTab({Name="players", Subtitle="player list"})
local PlayersSec = PlayersTab:AddSection({Name="player list", Side="Left"})
local function buildPlayerList()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(list,p.Name) end end
    return list
end
local playerDropdown = PlayersSec:AddDropdown({Name="select player", Values=buildPlayerList(), Callback=function(v) for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then espP[p]=(p.Name==v) end end end})
Players.PlayerAdded:Connect(function() if playerDropdown then playerDropdown:SetValues(buildPlayerList()) end end)
Players.PlayerRemoving:Connect(function() if playerDropdown then playerDropdown:SetValues(buildPlayerList()) end end)
PlayersSec:AddButton({Name="fling selected", Callback=function() local sel=playerDropdown:Get(); local p=sel and Players:FindFirstChild(sel); if p and p~=LocalPlayer then flingPlayer(p) end end})
PlayersSec:AddButton({Name="tp to selected", Callback=function() local sel=playerDropdown:Get(); local p=sel and Players:FindFirstChild(sel); if p and p.Character and LocalPlayer.Character then local tr=p.Character:FindFirstChild("HumanoidRootPart"); local lr=LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if tr and lr then lr.CFrame=tr.CFrame+Vector3.new(0,3,0) end end end})

local FarmTab = Win:AddTab({Name="auto", Subtitle="auto farm"})
local FarmSec = FarmTab:AddSection({Name="auto farm", Side="Left"})
FarmSec:AddToggle({Name="auto farm", Callback=function(state) FlyFarm.on=state; if state then FlyFarm.collected=0; FlyFarm.startTime=tick(); FlyFarm.visited={} else FlyFarm.stop() end end})
FarmSec:AddSlider({Name="fly speed", Min=1, Max=24, Default=15, Callback=function(v) FlyFarm.speed=v end})
FarmSec:AddSlider({Name="under depth", Min=0, Max=8, Increment=0.5, Default=FlyFarm.depth, Callback=function(v) FlyFarm.depth=v end})
FarmSec:AddDropdown({Name="farm mode", Values={"under", "above"}, Default=CFG.autoFarmMode, Callback=function(v) CFG.autoFarmMode=v; FlyFarm.mode=v; saveCFG() end})
FarmSec:AddToggle({Name="anti-afk", Callback=function(state)
    if state then
        task.spawn(function()
            while FlyFarm.on do task.wait(30); pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
        end)
    end
end})
FarmSec:AddToggle({Name="auto get gun", Callback=function(v) State.autoGunUser=v; State.autoGun=v or State.autoShoot; GD.watch(State.autoGun) end})
FarmSec:AddDropdown({Name="gun pickup mode", Values={"remote", "fastTP"}, Default=CFG.autoGunMode, Callback=function(v) CFG.autoGunMode=v; saveCFG() end})
FarmSec:AddToggle({Name="auto kill all", Callback=function(v) State.autoKillAll=v end})
FarmSec:AddToggle({Name="auto reset (50 coins)", Default=CFG.autoFarmReset, Callback=function(v) CFG.autoFarmReset=v; saveCFG() end})
FarmSec:AddToggle({Name="full bag: shoot murderer", Default=CFG.farmFullShoot==true, Callback=function(v) CFG.farmFullShoot=v; saveCFG() end})

function X.stab(k, ht, handle, thrp)
    pcall(function() k:Activate() end)
    pcall(function() ht:FireServer(thrp) end)
    if handle then EX.touch(handle, thrp, true) end
end
function X.killAll(manual)
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return end
    local k = getKnife()
    if not k then return end
    if k.Parent ~= ch then
        hum:EquipTool(k)
        local t0 = os.clock()
        while k.Parent ~= ch and os.clock() - t0 < 1 do task.wait(0.03) end
        if k.Parent ~= ch then return end
    end
    local ev = k:FindFirstChild("Events")
    local ht = ev and ev:FindFirstChild("HandleTouched")
    if not ht then return end
    local handle = k:FindFirstChild("Handle")
    local home = root.CFrame
    local moved = false
    for _, p in ipairs(Players:GetPlayers()) do
        if not manual and not State.autoKillAll and not State.zombieAutoKill then break end
        if p ~= LocalPlayer and p.Character and not isRealNpc(p) then
            local thrp = p.Character:FindFirstChild("HumanoidRootPart")
            local thum = p.Character:FindFirstChildOfClass("Humanoid")
            if thrp and thum and thum.Health > 0 and root.Parent then
                root.CFrame = thrp.CFrame * CFrame.new(0, 0, 2.2)
                root.AssemblyLinearVelocity = Vector3.zero
                moved = true
                X.stab(k, ht, handle, thrp)
                task.wait(0.05)
            end
        end
    end
    if moved and root.Parent then
        root.CFrame = home
        root.AssemblyLinearVelocity = Vector3.zero
    end
end
task.spawn(function()
    while true do
        task.wait(0.4)
        if State.autoKillAll or State.zombieAutoKill then
            pcall(function()
                local ch = LocalPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end
                if not getKnife() then return end
                local m0 = findMurderer()
                local s0 = findSheriff()
                if not m0 and not s0 then return end
                X.killAll()
            end)
        end
    end
end)

local TpTab = Win:AddTab({Name="teleport", Subtitle="tp"})
local TpSec = TpTab:AddSection({Name="teleport", Side="Left"})
TpSec:AddButton({Name="tp murderer", Callback=function() local p=findMurderer(); if p and p.Character and LocalPlayer.Character then local pr=p.Character:FindFirstChild("HumanoidRootPart"); local lr=LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame=pr.CFrame+Vector3.new(0,3,0) end end end})
TpSec:AddButton({Name="tp sheriff", Callback=function() local p=findSheriff(); if p and p.Character and LocalPlayer.Character then local pr=p.Character:FindFirstChild("HumanoidRootPart"); local lr=LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame=pr.CFrame+Vector3.new(0,3,0) end end end})

local FlingTab = Win:AddTab({Name="fling", Subtitle="fling"})
local FlingSec = FlingTab:AddSection({Name="fling", Side="Left"})
FlingSec:AddButton({Name="fling murderer", Callback=function() local p=findMurderer(); if p then flingPlayer(p) end end})
FlingSec:AddButton({Name="fling sheriff", Callback=function() local p=findSheriff(); if p then flingPlayer(p) end end})
FlingSec:AddButton({Name="fling hero", Callback=function() local p=Fling.gunHolder(); if p then flingPlayer(p) else Library:Notify({Title="fling", Text="nobody has the gun"}) end end})
FlingSec:AddButton({Name="fling all", Callback=function() Fling.all() end})
FlingSec:AddButton({Name="fling selected", Callback=function() local sel=playerDropdown:Get(); local p=sel and Players:FindFirstChild(sel); if p and p~=LocalPlayer then flingPlayer(p) end end})
FlingSec:AddButton({Name="stop fling", Callback=function() Fling.allRun=Fling.allRun+1; stopFling() end})
FlingSec:AddToggle({Name="touch fling", Callback=function(v) State.touchFlingOn=v end})

task.spawn(function()
    local movel = 0.1
    while true do
        RunService.Heartbeat:Wait()
        if State.touchFlingOn and not Fling.busy then
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                if hrp.Parent then hrp.AssemblyLinearVelocity = vel end
                RunService.Stepped:Wait()
                if hrp.Parent then hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0) end
                movel = -movel
            end
        end
    end
end)

Connect(UIS.JumpRequest, function()
    if not State.infJump then return end
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    local jp = hum.UseJumpPower and hum.JumpPower or math.sqrt(2 * WS.Gravity * hum.JumpHeight)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local v = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(v.X, jp, v.Z)
end)
State.glitchSpeed = 200
X.SG = {boost=false, token=0, active=false, jumpMod=false}
function X.SG.startBoost()
    if X.SG.boost then return end
    X.SG.boost = true
    X.SG.token = X.SG.token + 1
    local tk = X.SG.token
    Library:Notify({Title="speed glitch", Text="boost 8s", Duration=2})
    task.delay(8, function() if X.SG.token == tk then X.SG.boost = false end end)
end
Connect(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F and State.speedGlitch then X.SG.startBoost() end
end)
Connect(RunService.RenderStepped, function()
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local base = State.keepSpeed and State.dSpeed or 16
    if not State.speedGlitch then
        if X.SG.active then
            X.SG.active = false
            X.SG.boost = false
            hum.WalkSpeed = base
            if X.SG.jumpMod then X.SG.jumpMod = false; hum.JumpPower = State.keepJump and State.dJump or 50 end
        end
        return
    end
    X.SG.active = true
    local st = hum:GetState()
    local inAir = st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall
    if inAir and hum.MoveDirection.Magnitude > 0 then
        hum.WalkSpeed = X.SG.boost and 500 or State.glitchSpeed
        if X.SG.boost then hum.JumpPower = 100; X.SG.jumpMod = true end
    else
        hum.WalkSpeed = base
        if not X.SG.boost and X.SG.jumpMod then X.SG.jumpMod = false; hum.JumpPower = State.keepJump and State.dJump or 50 end
    end
end)

local MoveTab = Win:AddTab({Name="movement", Subtitle="move"})
local MoveSec = MoveTab:AddSection({Name="move", Side="Left"})
MoveSec:AddToggle({Name="keep speed", Callback=function(v)
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if v then
        if h and not State.keepSpeed then State.origSpeed = h.WalkSpeed end
        State.keepSpeed = true
    else
        State.keepSpeed = false
        task.wait(0.06)
        local h2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h2 then h2.WalkSpeed = State.origSpeed or 16 end
    end
end})
MoveSec:AddSlider({Name="speed", Min=16, Max=200, Default=State.dSpeed, Callback=function(v) State.dSpeed=v; CFG.speed=v; saveCFG() end})
MoveSec:AddToggle({Name="keep jump", Callback=function(v)
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if v then
        if h and not State.keepJump then State.origJump = h.JumpPower; State.origUseJP = h.UseJumpPower end
        State.keepJump = true
    else
        State.keepJump = false
        task.wait(0.06)
        local h2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h2 then
            h2.JumpPower = State.origJump or 50
            if State.origUseJP ~= nil then h2.UseJumpPower = State.origUseJP end
        end
    end
end})
MoveSec:AddSlider({Name="jump", Min=50, Max=300, Default=State.dJump, Callback=function(v) State.dJump=v; CFG.jump=v; saveCFG() end})
MoveSec:AddToggle({Name="fly", Callback=function(o) State.flying=o; updateFly() end})
MoveSec:AddToggle({Name="noclip", Callback=function(o) State.noclip=o; if not o and not State.farmClip then X.NC.restore() end end})
MoveSec:AddToggle({Name="spin", Callback=function(o) State.spinOn=o end})
MoveSec:AddSlider({Name="spin speed", Min=1, Max=500, Default=30, Callback=function(v) State.spinSpd=v end})
MoveSec:AddToggle({Name="infinity jump", Callback=function(v) State.infJump=v end})
MoveSec:AddToggle({Name="speed glitch", Callback=function(v) State.speedGlitch=v end})
MoveSec:AddSlider({Name="glitch speed", Min=16, Max=500, Default=200, Callback=function(v) State.glitchSpeed=v end})
MoveSec:AddButton({Name="boost (8s)", Callback=function() X.SG.startBoost() end})

local DodgeTab = Win:AddTab({Name="dodge", Subtitle="ultra dodge & protect"})
local DodgeSec = DodgeTab:AddSection({Name="ultra dodge", Side="Left"})
DodgeSec:AddToggle({Name="enable", Callback=function(o) UD.enabled=o end})
DodgeSec:AddSlider({Name="scan radius", Min=5, Max=40, Default=UD.ScanRadius, Callback=function(v) UD.ScanRadius=v end})
DodgeSec:AddSlider({Name="dodge distance", Min=5, Max=30, Default=UD.DodgeDist, Callback=function(v) UD.DodgeDist=v end})
DodgeSec:AddSlider({Name="panic threshold", Min=1, Max=10, Default=UD.StressThreshold, Callback=function(v) UD.StressThreshold=v end})
DodgeSec:AddToggle({Name="anti aim", Callback=function(o) State.antiAimOn=o; if o then startAntiAim() else stopAntiAim() end end})
DodgeSec:AddDropdown({Name="anti aim preset", Values={"low","high","y high","limit","zero"}, Default=aaPreset, Callback=function(v) aaPreset=v; CFG.aaPreset=v; saveCFG() end})

local AFSec = DodgeTab:AddSection({Name="anti fling", Side="Right"})
AFSec:AddToggle({Name="anti-fling", Default=AF.on, Callback=function(v) AF.on=v; CFG.antiFling=v; saveCFG() end})
AF.players=(CFG.antiFlingPlayers~=false)
AF.done=setmetatable({},{__mode="k"})
AFSec:AddToggle({Name="anti fling (players)", Default=AF.players, Callback=function(v) AF.players=v; CFG.antiFlingPlayers=v; saveCFG() end})
Connect(RunService.Stepped,function()
    if not AF.players or Fling.busy or State.touchFlingOn then return end
    for _,p in ipairs(Players:GetPlayers()) do
        local ch=p~=LocalPlayer and p.Character
        if ch then
            for _,part in ipairs(ch:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide=false
                    if part.Name=="HumanoidRootPart" then
                        if not AF.done[part] then
                            AF.done[part]=true
                            pcall(function() part.CustomPhysicalProperties=PhysicalProperties.new(0,0,0,0,0) end)
                        end
                        part.AssemblyLinearVelocity=Vector3.zero
                        part.AssemblyAngularVelocity=Vector3.zero
                    end
                end
            end
        end
    end
end)

local MiscTab = Win:AddTab({Name="misc", Subtitle="auto"})
local MiscSec = MiscTab:AddSection({Name="auto", Side="Left"})
MiscSec:AddToggle({Name="auto-respawn", Callback=function(o) State.autoRespawn=o end})
MiscSec:AddToggle({Name="fast-respawn", Callback=function(o) State.fastRespawn=o end})
MiscSec:AddToggle({Name="anti-void", Callback=function(o) State.antiVoid=o end})
X.AL = {on=false, orig=setmetatable({}, {__mode="k"})}
X.ALC = {ParticleEmitter=true, Trail=true, Smoke=true, Fire=true, Sparkles=true, Beam=true, BloomEffect=true, BlurEffect=true, SunRaysEffect=true, DepthOfFieldEffect=true}
function X.AL.apply(v)
    if X.ALC[v.ClassName] and X.AL.orig[v]==nil then
        if v:FindFirstAncestor("PiddleFx") or v:FindFirstAncestor("PiddleWeather") then return end
        X.AL.orig[v]=v.Enabled
        pcall(function() v.Enabled=false end)
    end
end
function X.AL.enable()
    X.AL.on=true; State.antiLagOn=true
    for _,v in ipairs(WS:GetDescendants()) do X.AL.apply(v) end
    for _,v in ipairs(Lighting:GetChildren()) do X.AL.apply(v) end
end
function X.AL.disable()
    X.AL.on=false; State.antiLagOn=false
    for v,e in pairs(X.AL.orig) do
        if v.Parent then pcall(function() v.Enabled=e end) end
        X.AL.orig[v]=nil
    end
end
Connect(WS.DescendantAdded, function(v) if X.AL.on then task.defer(X.AL.apply, v) end end)
task.spawn(function()
    while true do
        task.wait(1)
        if X.AL.on then
            for v in pairs(X.AL.orig) do
                if v.Parent and v.Enabled then pcall(function() v.Enabled=false end) end
            end
        end
    end
end)
MiscSec:AddToggle({Name="anti lag", Default=CFG.antiLag, Callback=function(o)
    CFG.antiLag=o; saveCFG()
    if o then X.AL.enable() else X.AL.disable() end
end})
if CFG.antiLag then task.defer(X.AL.enable) end

local WarnTab = Win:AddTab({Name="warnings", Subtitle="notifications"})
local WarnSec = WarnTab:AddSection({Name="notifications", Side="Left"})
WarnSec:AddToggle({Name="role notice", Default=CFG.warnRole~=false, Callback=function(v) CFG.warnRole=v; saveCFG() end})
WarnSec:AddToggle({Name="round start", Default=CFG.warnRoundStart~=false, Callback=function(v) CFG.warnRoundStart=v; saveCFG() end})

local UpdateTab = Win:AddTab({Name="update", Subtitle="zombie mode"})
local ZombieSec = UpdateTab:AddSection({Name="zombie features", Side="Left"})
ZombieSec:AddToggle({Name="auto shoot zombies", Callback=function(v) State.zombieAutoShoot=v end})
ZombieSec:AddToggle({Name="aimlock zombie", Callback=function(v) State.aimlockZombie=v end})
ZombieSec:AddToggle({Name="auto kill all (zombie)", Callback=function(v) State.zombieAutoKill=v end})
local zStat = UpdateTab:AddSection({Name="status", Side="Right"}):AddLabel({Name="zombie: no"})
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function() zStat:SetText("zombie: " .. (isZombie(LocalPlayer) and "yes" or "no")) end)
    end
end)

local PlayerTab = Win:AddTab({Name="player", Subtitle="cosmetics"})
local PacksSec = PlayerTab:AddSection({Name="animation packs", Side="Left"})
for name,_ in pairs(PACKS) do
    PacksSec:AddButton({Name=name, Callback=function() CFG.selectedPack=name; saveCFG(); applyPack(name) end})
end
local EmotesSec = PlayerTab:AddSection({Name="emotes", Side="Right"})
do
local curEmote
X.EM = {
    Wave={"507770239","128777973"}, Point={"507770453","128853357"}, Dance={"507771019","182435998"},
    Dance2={"507776043","182491037"}, Dance3={"507777268","182491065"}, Laugh={"507770818","129423131"},
    Cheer={"507770677","129423030"}, Sit={"507768133","178130996"},
}
local function playEmote(name)
    pcall(function() if curEmote then curEmote:Stop(0.1) end end)
    curEmote = nil
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local r6 = hum.RigType == Enum.HumanoidRigType.R6
    local pair = X.EM[name]
    local id = pair and (r6 and pair[2] or pair[1]) or ((not r6) and EMOTES[name] or nil)
    if not id then Library:Notify({Title="emote", Text="not available for this rig"}); return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. id
    local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
    if not ok or not tr then Library:Notify({Title="emote", Text="failed to load animation"}); return end
    local t0 = os.clock()
    while tr.Length == 0 and os.clock() - t0 < 3 do task.wait(0.05) end
    if tr.Length == 0 then Library:Notify({Title="emote", Text="animation unavailable"}); return end
    tr.Priority = Enum.AnimationPriority.Action4
    tr.Looped = true
    tr:Play(0.15, 1, 1)
    curEmote = tr
end
local emoteNames, seenE = {}, {}
for n in pairs(EMOTES) do if not seenE[n] then seenE[n] = true; table.insert(emoteNames, n) end end
for n in pairs(X.EM) do if not seenE[n] then seenE[n] = true; table.insert(emoteNames, n) end end
table.sort(emoteNames)
for _,eName in ipairs(emoteNames) do
    EmotesSec:AddButton({Name=eName, Callback=function() task.spawn(playEmote, eName) end})
end
EmotesSec:AddButton({Name="stop emote", Callback=function()
    pcall(function() if curEmote then curEmote:Stop(0.15) end end)
    curEmote=nil
end})
end
local OutfitSec = PlayerTab:AddSection({Name="outfits", Side="Left"})
OutfitSec:AddToggle({Name="korblox", Default=CFG.korbloxOn, Callback=function(v) CFG.korbloxOn=v; saveCFG(); if v then pcall(applyKorbloxNow) else pcall(removeKorbloxNow) end end})
OutfitSec:AddToggle({Name="headless", Default=CFG.headlessOn, Callback=function(v) CFG.headlessOn=v; saveCFG(); if v then pcall(applyHeadlessNow) else pcall(removeHeadlessNow) end end})
OutfitSec:AddToggle({Name="china hat", Default=CFG.chinaHatOn or false, Callback=function(v) CFG.chinaHatOn=v; saveCFG(); if v then pcall(Hat.apply); task.delay(0.7, function() pcall(updateHatColor, CFG.chinaHatColor) end) else pcall(Hat.remove) end end})
OutfitSec:AddColorPicker({Name="china hat color", Default=CFG.chinaHatColor, Callback=function(c) CFG.chinaHatColor=c; saveCFG(); updateHatColor(c) end})
X.SK = {on=false, guns={}, knives={}, picked={}, loaded={}, cur=setmetatable({}, {__mode="k"})}
local SkinSec = VisualsTab:AddSection({Name="skin changer", Side="Right"})
function X.SK.apply(tool)
    local kind = (tool.Name == "Knife" and "knife") or (tool.Name == "Gun" and "gun") or nil
    if not kind then return end
    local src = X.SK.on and X.SK.picked[kind] or nil
    local has = tool:FindFirstChild("PiddleSkin")
    if not src then
        if has then X.SK.restore(tool) end
        return
    end
    if has and X.SK.cur[tool] == src then return end
    X.SK.restore(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return end
    local clone = src:Clone()
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then d:Destroy() end
    end
    local sh = clone:FindFirstChild("Handle")
    if not (sh and sh:IsA("BasePart")) then sh = clone:FindFirstChildWhichIsA("BasePart", true) end
    if not sh and clone:IsA("BasePart") then sh = clone end
    if not sh then clone:Destroy(); return end
    local parts = {}
    if clone:IsA("BasePart") then parts[#parts + 1] = clone end
    for _, p in ipairs(clone:GetDescendants()) do
        if p:IsA("BasePart") then parts[#parts + 1] = p end
    end
    local f = Instance.new("Folder")
    f.Name = "PiddleSkin"
    f.Parent = tool
    local shCF = sh.CFrame
    for _, p in ipairs(parts) do
        local rel = shCF:ToObjectSpace(p.CFrame)
        p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
        p.CFrame = handle.CFrame * rel
        local w = Instance.new("WeldConstraint")
        w.Part0 = handle; w.Part1 = p; w.Parent = p
        p.Parent = f
    end
    clone:Destroy()
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") and not f:IsAncestorOf(d) then
            X.SK.hid = X.SK.hid or setmetatable({}, {__mode="k"})
            X.SK.hid[d] = {tool, d.Transparency}
            pcall(function() d.Transparency = 1 end)
        end
    end
    X.SK.cur[tool] = src
end
function X.SK.restore(tool)
    local f = tool:FindFirstChild("PiddleSkin")
    if f then f:Destroy() end
    if X.SK.hid then
        for part, info in pairs(X.SK.hid) do
            if info[1] == tool then
                if part.Parent then pcall(function() part.Transparency = info[2] end) end
                X.SK.hid[part] = nil
            end
        end
    end
    X.SK.cur[tool] = nil
end
function X.SK.refresh()
    local ch = LocalPlayer.Character
    if not ch then return end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then pcall(X.SK.restore, t); pcall(X.SK.apply, t) end
    end
end
function X.SK.scan()
    X.SK.guns, X.SK.knives = {}, {}
    local kw = {knife={"knife","blade","karambit","butterfly","dagger","fang","sword","scythe","cleaver"},
                gun={"gun","sniper","pistol","revolver","rifle","blaster","laser","shotgun","awp","deagle","luger"}}
    local n = 0
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        n = n + 1
        if n % 500 == 0 then task.wait() end
        if (d:IsA("Tool") or d:IsA("Model")) and (d:FindFirstChild("Handle") or d:FindFirstChildWhichIsA("BasePart", true)) then
            local l = d.Name:lower()
            for kind, words in pairs(kw) do
                local tbl = (kind == "knife") and X.SK.knives or X.SK.guns
                for _, w in ipairs(words) do
                    if l:find(w, 1, true) then
                        if not tbl[d.Name] then tbl[d.Name] = d end
                        break
                    end
                end
            end
        end
    end
    local gl, kl = {}, {}
    for k in pairs(X.SK.guns) do gl[#gl + 1] = k end
    for k in pairs(X.SK.knives) do kl[#kl + 1] = k end
    table.sort(gl); table.sort(kl)
    table.insert(gl, 1, "none"); table.insert(kl, 1, "none")
    X.SK.gunDD:SetValues(gl)
    X.SK.knifeDD:SetValues(kl)
    Library:Notify({Title="skins", Text=(#gl - 1) .. " gun / " .. (#kl - 1) .. " knife skins found"})
end
function X.SK.fromId(kind, v)
    local id = tonumber(tostring(v):match("%d+"))
    if not id then X.SK.picked[kind] = nil; X.SK.refresh(); return end
    task.spawn(function()
        local obj = X.SK.loaded[id]
        if not obj then
            local ok, res = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
            if ok and type(res) == "table" and res[1] then obj = res[1]
            else
                local ok2, m = pcall(function() return InsertService:LoadAsset(id) end)
                if ok2 and m then obj = m end
            end
            if obj then X.SK.loaded[id] = obj end
        end
        if not obj then Library:Notify({Title="skins", Text="failed to load asset"}); return end
        X.SK.picked[kind] = (obj:IsA("Tool") and obj) or obj:FindFirstChildWhichIsA("Tool", true) or obj
        X.SK.refresh()
    end)
end
SkinSec:AddToggle({Name="skin changer", Callback=function(v) X.SK.on = v; X.SK.refresh() end})
X.SK.gunDD = SkinSec:AddDropdown({Name="gun skin", Values={"none"}, Default="none", Callback=function(v)
    X.SK.picked.gun = (v ~= "none") and X.SK.guns[v] or nil
    X.SK.refresh()
end})
X.SK.knifeDD = SkinSec:AddDropdown({Name="knife skin", Values={"none"}, Default="none", Callback=function(v)
    X.SK.picked.knife = (v ~= "none") and X.SK.knives[v] or nil
    X.SK.refresh()
end})
SkinSec:AddButton({Name="scan skins", Callback=function() task.spawn(X.SK.scan) end})
SkinSec:AddTextbox({Name="gun asset id", Placeholder="asset id", Default=CFG.gunSkinAssetId, Callback=function(v) CFG.gunSkinAssetId=v; saveCFG(); X.SK.fromId("gun", v) end})
SkinSec:AddTextbox({Name="knife asset id", Placeholder="asset id", Default=CFG.knifeSkinAssetId, Callback=function(v) CFG.knifeSkinAssetId=v; saveCFG(); X.SK.fromId("knife", v) end})
task.spawn(function()
    task.wait(2)
    if CFG.gunSkinAssetId and tostring(CFG.gunSkinAssetId) ~= "" then pcall(X.SK.fromId, "gun", CFG.gunSkinAssetId) end
    if CFG.knifeSkinAssetId and tostring(CFG.knifeSkinAssetId) ~= "" then pcall(X.SK.fromId, "knife", CFG.knifeSkinAssetId) end
end)
task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.5)
        if X.SK.on then
            local ch = LocalPlayer.Character
            if ch then
                for _, t in ipairs(ch:GetChildren()) do
                    if t:IsA("Tool") then pcall(X.SK.apply, t) end
                end
            end
        end
    end
end)
local TopImgSec = PlayerTab:AddSection({Name="top image", Side="Left"})
local topNames={"Furry","Pibble","Anime","None"}
TopImgSec:AddDropdown({Name="select image", Values=topNames, Default=CFG.topImage, Callback=function(v)
    CFG.topImage=v; saveCFG()
    Win.TopImg.Image=ResolveImage(TOP_IMAGES[v] or "")
    Win.TopImg.Visible=(TOP_IMAGES[v] or "")~="" and CFG.topImageVisible and Win.Visible
end})
TopImgSec:AddToggle({Name="show image", Default=CFG.topImageVisible~=false, Callback=function(v)
    CFG.topImageVisible=v; saveCFG()
    Win.TopImg.Visible=(TOP_IMAGES[CFG.topImage] or "")~="" and v and Win.Visible
end})
TopImgSec:AddTextbox({Name="custom image id", Placeholder="rbxassetid://...", Callback=function(v)
    if v~="" then Win.TopImg.Image = ResolveImage(v); Win.TopImg.Visible = true end
end})
function X.initTracer(sec)
    local G = {
        on = CFG.bulletTracerOn ~= false,
        method = CFG.tracerMethod or "Classic",
        style = CFG.tracerStyle or "Energy",
        col = (typeof(CFG.tracerCol) == "Color3" and CFG.tracerCol) or Color3.fromRGB(110, 190, 255),
        col2 = (typeof(CFG.tracerCol2) == "Color3" and CFG.tracerCol2) or Color3.fromRGB(255, 90, 210),
        rainbow = CFG.tracerRainbow == true,
        width = CFG.tracerWidth or 100,
        speed = CFG.tracerSpeed or 520,
        life = (CFG.tracerLife or 12) / 10,
        impact = CFG.tracerImpact ~= false,
        muzzle = CFG.tracerMuzzle ~= false,
        others = CFG.tracerOthers == true,
        live = {},
        pool = {},
        made = {},
        log = {},
    }
    pcall(function() getgenv().__NoirTracers = G; getgenv().__NoirTracer = G end)

    local PathSvc = game:GetService("PathfindingService")
    local Terrain = workspace.Terrain
    local TweenSvc = game:GetService("TweenService")
    local RepStorage = game:GetService("ReplicatedStorage")
    local RunSvc = game:GetService("RunService")
    local PlayersSvc = game:GetService("Players")
    local LP = PlayersSvc.LocalPlayer

    local Tex = {
        glow = "rbxassetid://12781803086", energy = "rbxassetid://12781800668", core = "rbxassetid://12781750620",
        bolt = "rbxassetid://12781757438", earth = "rbxassetid://12781803991", fire = "rbxassetid://12781855685",
        smoke = "rbxassetid://12781879045", helix = "rbxassetid://7071778278", dust = "rbxassetid://1851669703",
        dot = "rbxassetid://16512006463", star = "rbxassetid://14590086212", ring = "rbxassetid://12403112662",
        soft = "rbxassetid://1075864321",
    }
    local Styles = {
        Energy = {
            { tex = "core", w = 4, spd = 4, br = 1.6, a = 0.35, mix = 0 },
            { tex = "energy", w = 3.2, spd = 4, br = 3, a = 1, mix = 0.2, wrap = 7 },
            { tex = "core", w = 1, spd = 4, br = 3, a = 1, mix = 0.75 },
        },
        Laser = {
            { tex = "core", w = 4.5, spd = 4, br = 1.6, a = 0.4, mix = 0 },
            { tex = "core", w = 1.8, spd = 4, br = 2.4, a = 0.85, mix = 0.2 },
            { tex = "core", w = 0.7, spd = 4, br = 3.5, a = 1, mix = 0.85 },
        },
        Lightning = {
            { tex = "core", w = 4, spd = 4, br = 1.6, a = 0.3, mix = 0 },
            { tex = "bolt", w = 3.4, spd = 5, br = 4, a = 1, mix = 0.3, wrap = 9 },
            { tex = "core", w = 0.8, spd = 4, br = 3, a = 1, mix = 0.8 },
        },
        Plasma = {
            { tex = "core", w = 4, spd = 3, br = 1.6, a = 0.35, mix = 0 },
            { tex = "helix", w = 2.8, spd = 3, br = 3, a = 1, mix = 0.2, wrap = 6 },
            { tex = "core", w = 0.9, spd = 3, br = 3, a = 1, mix = 0.7 },
        },
        Fire = {
            { tex = "core", w = 4, spd = 4, br = 1.8, a = 0.4, mix = 0 },
            { tex = "fire", w = 3.2, spd = 5, br = 3.5, a = 1, mix = 0.1, wrap = 7 },
            { tex = "core", w = 0.9, spd = 4, br = 3, a = 1, mix = 0.6 },
        },
        Smoke = {
            { tex = "smoke", w = 3.4, spd = 3, br = 1.2, a = 0.8, mix = 0.6, wrap = 9 },
            { tex = "core", w = 0.6, spd = 4, br = 2.6, a = 1, mix = 0.85 },
        },
        Stardust = {
            { tex = "core", w = 4, spd = 3, br = 1.6, a = 0.3, mix = 0 },
            { tex = "dust", w = 3.2, spd = 3, br = 3.5, a = 1, mix = 0.3, wrap = 5 },
            { tex = "core", w = 0.8, spd = 3, br = 3, a = 1, mix = 0.75 },
        },
    }
    if not Styles[G.style] then G.style = "Energy" end
    local StyleList = {"Energy", "Laser", "Lightning", "Plasma", "Fire", "Smoke", "Stardust"}

    local function logTracer(msg)
        G.log[#G.log + 1] = string.format("%.2f %s", os.clock(), msg)
        if #G.log > 30 then table.remove(G.log, 1) end
    end

    task.spawn(function()
        local arr = {}
        for _, v in pairs(Tex) do
            local d = Instance.new("Decal")
            d.Texture = v
            arr[#arr + 1] = d
        end
        pcall(function() game:GetService("ContentProvider"):PreloadAsync(arr) end)
        for _, v in ipairs(arr) do pcall(function() v:Destroy() end) end
    end)

    local function acquireBeam()
        local V = table.remove(G.pool)
        if V and V.b.Parent and V.a0.Parent and V.a1.Parent then return V end
        local a0 = Instance.new("Attachment"); a0.Name = "NoirTracerA"; a0.Parent = Terrain
        local a1 = Instance.new("Attachment"); a1.Name = "NoirTracerB"; a1.Parent = Terrain
        local beam = Instance.new("Beam")
        beam.Name = "NoirTracer"
        beam.Attachment0, beam.Attachment1 = a0, a1
        beam.FaceCamera = true
        beam.LightEmission, beam.LightInfluence = 1, 0
        beam.Enabled = false
        beam.Parent = Terrain
        V = {a0 = a0, a1 = a1, b = beam}
        G.made[#G.made + 1] = V
        return V
    end
    local function releaseBeam(V)
        if not V then return end
        pcall(function() V.b.Enabled = false end)
        if #G.pool < 160 then
            G.pool[#G.pool + 1] = V
        else
            pcall(function() V.b:Destroy(); V.a0:Destroy(); V.a1:Destroy() end)
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    pcall(function() rayParams.RespectCanCollide = true end)
    local rayUpdate = 0
    local function getRayParams()
        if os.clock() - rayUpdate > 1 then
            rayUpdate = os.clock()
            local list = {}
            for _, pl in ipairs(PlayersSvc:GetPlayers()) do
                if pl.Character then list[#list + 1] = pl.Character end
            end
            local cam = workspace.CurrentCamera
            if cam then list[#list + 1] = cam end
            rayParams.FilterDescendantsInstances = list
        end
        return rayParams
    end
    local function isObstructed(a, b)
        local dir = b - a
        if dir.Magnitude < 0.05 then return nil end
        local cur = a
        for i = 1, 5 do
            local hit = workspace:Raycast(cur, b - cur, getRayParams())
            if not hit then return nil end
            local transp = 0
            pcall(function() transp = hit.Instance.Transparency end)
            if transp < 0.85 then return hit end
            cur = hit.Position + dir.Unit * 0.05
            if (b - cur):Dot(dir.Unit) <= 0 then return nil end
        end
        return nil
    end

    local function buildPathfinder(s, e)
        local ok, pts = pcall(function()
            local path = PathSvc:CreatePath({AgentRadius = 1.5, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 6})
            path:ComputeAsync(s - Vector3.new(0, 2.5, 0), e - Vector3.new(0, 2.5, 0))
            if path.Status ~= Enum.PathStatus.Success then return nil end
            local arr = {s}
            for _, wp in ipairs(path:GetWaypoints()) do
                arr[#arr + 1] = wp.Position + Vector3.new(0, 3, 0)
            end
            arr[#arr + 1] = e
            return arr
        end)
        if not ok or type(pts) ~= "table" then return nil end
        local len = 0
        for i = 1, #pts - 1 do len = len + (pts[i + 1] - pts[i]).Magnitude end
        if len > (e - s).Magnitude * 4 + 40 then return nil end
        return pts
    end

    local function smoothPoints(pts)
        if #pts <= 2 then return pts end
        local out = {pts[1]}
        local total = 0
        for i = 1, #pts - 1 do total = total + (pts[i + 1] - pts[i]).Magnitude end
        local step = math.max(2.2, total / 44)
        for i = 1, #pts - 1 do
            local p0 = pts[math.max(1, i - 1)]
            local p1 = pts[i]
            local p2 = pts[i + 1]
            local p3 = pts[math.min(#pts, i + 2)]
            local segLen = (p2 - p1).Magnitude
            local cnt = math.clamp(math.floor(segLen / step + 0.5), 2, 16)
            for j = 1, cnt do
                local t = j / cnt
                local t2 = t * t
                local t3 = t2 * t
                out[#out + 1] = 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
            end
        end
        out[#out] = pts[#pts]
        return out
    end

    local function newAttachment(pos)
        local a = Instance.new("Attachment")
        a.Name = "NoirTracerFx"
        a.WorldPosition = pos
        a.Parent = Terrain
        return a
    end
    local function makeEmitter(parent, props)
        local em = Instance.new("ParticleEmitter")
        em.Rate = 0
        em.LightEmission, em.LightInfluence = 1, 0
        em.Speed = NumberRange.new(0)
        em.Rotation = NumberRange.new(0)
        em.RotSpeed = NumberRange.new(0)
        for k, v in pairs(props) do pcall(function() em[k] = v end) end
        em.Parent = parent
        return em
    end
    local function spawnMuzzle(pos, col)
        local a = newAttachment(pos)
        local cs = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.55), col)
        makeEmitter(a, {Texture = Tex.star, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.4), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.1), Brightness = 4, ZOffset = 1}):Emit(1)
        makeEmitter(a, {Texture = Tex.soft, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.4)}), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}), Lifetime = NumberRange.new(0.14), Brightness = 3}):Emit(1)
        local light = Instance.new("PointLight")
        light.Color, light.Range, light.Brightness = col, 9, 3.5
        light.Parent = a
        pcall(function() TweenSvc:Create(light, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play() end)
        task.delay(0.5, function() pcall(function() a:Destroy() end) end)
    end
    local function spawnImpact(pos, col)
        local a = newAttachment(pos)
        local cs = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.6), col)
        makeEmitter(a, {Texture = Tex.star, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.6), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.2), Brightness = 4, ZOffset = 1}):Emit(1)
        makeEmitter(a, {Texture = Tex.ring, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 5.5)}), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Lifetime = NumberRange.new(0.35), Brightness = 3}):Emit(1)
        makeEmitter(a, {Texture = Tex.dot, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0)}), Speed = NumberRange.new(12, 30), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -45, 0), Drag = 3, Lifetime = NumberRange.new(0.3, 0.6), Brightness = 3}):Emit(18)
        makeEmitter(a, {Texture = Tex.soft, Color = cs, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.6), NumberSequenceKeypoint.new(1, 0.6)}), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)}), Lifetime = NumberRange.new(0.25), Brightness = 2}):Emit(1)
        local light = Instance.new("PointLight")
        light.Color, light.Range, light.Brightness = col, 12, 3.5
        light.Parent = a
        pcall(function() TweenSvc:Create(light, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play() end)
        task.delay(1.2, function() pcall(function() a:Destroy() end) end)
    end
    local function getColors(opts)
        local rainbow = opts.rainbow
        if rainbow == nil then rainbow = G.rainbow end
        if rainbow then
            local h = os.clock() * 0.18 % 1
            return Color3.fromHSV(h, 0.7, 1), Color3.fromHSV((h + 0.18) % 1, 0.75, 1)
        end
        return opts.col or G.col, opts.col2 or G.col2
    end

    local function buildTracer(pts, opts)
        opts = opts or {}
        if #pts < 2 then return end
        while #G.live >= 8 do
            local old = table.remove(G.live, 1)
            for _, row in ipairs(old.rows) do for _, b in ipairs(row) do releaseBeam(b) end end
            if old.head then pcall(function() old.head:Destroy() end) end
        end
        local cum = {0}
        for i = 2, #pts do cum[i] = cum[i - 1] + (pts[i] - pts[i - 1]).Magnitude end
        local total = cum[#cum]
        if total < 0.5 then return end
        local style = Styles[opts.style or G.style] or Styles.Energy
        local col, col2 = getColors(opts)
        local wk = (opts.width or G.width or 100) / 100
        local rows = {}
        for li, layer in ipairs(style) do
            local row = {}
            for i = 1, #pts - 1 do
                local b = acquireBeam()
                local beam = b.b
                beam.Texture = Tex[layer.tex]
                if layer.wrap then
                    beam.TextureMode = Enum.TextureMode.Wrap
                    beam.TextureLength = layer.wrap * wk
                else
                    beam.TextureMode = Enum.TextureMode.Stretch
                    beam.TextureLength = 1
                end
                beam.TextureSpeed = layer.spd
                beam.Brightness = layer.br
                beam.Segments = (#pts == 2 and 24 or 4)
                beam.ZOffset = li * 0.05
                b.a0.WorldPosition = pts[i]
                b.a1.WorldPosition = pts[i + 1]
                beam.Enabled = false
                row[i] = b
            end
            rows[li] = row
        end
        local tracer = {
            pts = pts, cum = cum, L = total, t0 = os.clock(), rows = rows, style = style, col = col, col2 = col2, wk = wk,
            speed = math.max(40, opts.speed or G.speed or 520),
            life = math.max(0.2, opts.life or G.life or 1.2),
            impact = opts.impact,
            landed = false,
        }
        tracer.tail = opts.tail or math.clamp(total * 0.45, 8, 60)
        tracer.clearHead = opts.clearHead
        if opts.muzzle then pcall(spawnMuzzle, pts[1], col) end
        local head = newAttachment(pts[1])
        makeEmitter(head, {Texture = Tex.dot, Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.5)), Size = NumberSequence.new(2.8 * wk), Lifetime = NumberRange.new(total / tracer.speed + 0.05), LockedToPart = true, Brightness = 5, ZOffset = 1}):Emit(1)
        makeEmitter(head, {Texture = Tex.star, Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.35)), Size = NumberSequence.new(3.4 * wk), Lifetime = NumberRange.new(total / tracer.speed + 0.05), LockedToPart = true, Brightness = 4, ZOffset = 1.1}):Emit(1)
        tracer.trail = makeEmitter(head, {Texture = Tex.dot, Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.3), col2), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.32 * wk), NumberSequenceKeypoint.new(1, 0)}), Speed = NumberRange.new(1.5, 5), SpreadAngle = Vector2.new(180, 180), Drag = 4, Lifetime = NumberRange.new(0.2, 0.42), Rate = 70, Brightness = 3})
        tracer.head = head
        G.live[#G.live + 1] = tracer
        if opts.cb then task.spawn(opts.cb, tracer) end
        return tracer
    end

    local function pointOnPath(tr, dist)
        local cum, pts = tr.cum, tr.pts
        if dist <= 0 then return pts[1], 1 end
        if dist >= tr.L then return pts[#pts], #pts - 1 end
        local lo, hi = 1, #cum
        while hi - lo > 1 do
            local mid = (lo + hi) // 2
            if cum[mid] <= dist then lo = mid else hi = mid end
        end
        local segLen = cum[lo + 1] - cum[lo]
        local t = segLen > 0 and (dist - cum[lo]) / segLen or 0
        return pts[lo]:Lerp(pts[lo + 1], t), lo
    end

    local function updateTracers()
        if #G.live == 0 then return end
        local now = os.clock()
        local i = 1
        while i <= #G.live do
            local tr = G.live[i]
            local elapsed = now - tr.t0
            local total, speed = tr.L, tr.speed
            local headDist = math.min(total, elapsed * speed)
            local tailDist = elapsed * speed - tr.tail
            local totalTime = total / speed
            if not tr.landed and headDist >= total then
                tr.landed = true
                if tr.trail then tr.trail.Rate = 0 end
                if tr.clearHead and tr.head then
                    for _, ch in ipairs(tr.head:GetChildren()) do
                        if ch:IsA("ParticleEmitter") and ch ~= tr.trail then pcall(function() ch:Clear() end) end
                    end
                end
                if tr.impact then pcall(spawnImpact, tr.pts[#tr.pts], tr.col) end
            end
            local fade = 0.38
            if elapsed > totalTime then
                fade = 0.38 * math.clamp(1 - (elapsed - totalTime) / tr.life, 0, 1) ^ 1.5
            end
            local shouldRemove = elapsed > totalTime + tr.life and tailDist >= total
            if shouldRemove then
                for _, row in ipairs(tr.rows) do for _, b in ipairs(row) do releaseBeam(b) end end
                pcall(function() tr.head:Destroy() end)
                table.remove(G.live, i)
            else
                local headPos = pointOnPath(tr, headDist)
                if tr.head then tr.head.WorldPosition = headPos end
                local function alphaAt(d)
                    if d >= tailDist and d <= headDist + 0.001 then
                        return ((d - tailDist) / math.max(headDist - tailDist, 0.01)) ^ 1.4
                    end
                    return 0
                end
                local isStraight = #tr.pts == 2
                for li, row in ipairs(tr.rows) do
                    local layer = tr.style[li]
                    local baseA = layer.a
                    for segIdx, b in ipairs(row) do
                        local segStart = tr.cum[segIdx]
                        local segEnd = tr.cum[segIdx + 1]
                        if segStart >= headDist or (fade <= 0.004 and segEnd <= tailDist) then
                            if b.b.Enabled then b.b.Enabled = false end
                        else
                            local segTail = math.min(segEnd, headDist)
                            if segEnd > headDist then
                                b.a1.WorldPosition = headPos
                            else
                                b.a1.WorldPosition = tr.pts[segIdx + 1]
                            end
                            local keys = {}
                            local steps = isStraight and 9 or 2
                            for s = 0, steps - 1 do
                                local t = steps == 1 and 0 or s / (steps - 1)
                                local dist = segStart + (segEnd - segStart) * t
                                if dist < tailDist then dist = tailDist end
                                if dist > segTail then dist = segTail end
                                keys[#keys + 1] = NumberSequenceKeypoint.new(t, math.clamp(1 - alphaAt(dist) * baseA, 0, 1))
                            end
                            b.b.Transparency = NumberSequence.new(keys)
                            local a0 = math.max(alphaAt(segStart), 0)
                            local a1 = math.max(alphaAt(segEnd), 0)
                            b.b.Width0 = 0.9 * layer.w * tr.wk * (0.55 + 0.45 * a0)
                            b.b.Width1 = 0.9 * layer.w * tr.wk * (0.55 + 0.45 * a1)
                            local colA = tr.col2:Lerp(tr.col, segStart / total):Lerp(Color3.new(1, 1, 1), layer.mix)
                            local colB = tr.col2:Lerp(tr.col, segEnd / total):Lerp(Color3.new(1, 1, 1), layer.mix)
                            b.b.Color = ColorSequence.new(colA, colB)
                            if not b.b.Enabled then b.b.Enabled = true end
                        end
                    end
                end
                i = i + 1
            end
        end
    end
    RunSvc.Heartbeat:Connect(function() pcall(updateTracers) end)

    local function spawnFromTo(a, b, impact, muzzle, extra)
        extra = extra or {}
        local opts = {impact = impact, muzzle = muzzle, speed = extra.speed, life = extra.life, cb = extra.cb}
        if (b - a).Magnitude > 700 then b = a + (b - a).Unit * 700 end
        if G.method == "Path Finder" then
            if not isObstructed(a, b) then
                return buildTracer(smoothPoints({a, b}), opts)
            end
            task.spawn(function()
                local st = os.clock()
                local pts = buildPathfinder(a, b)
                if pts then
                    pts = smoothPoints(pts)
                    logTracer(string.format("PF nav pts=%d %.1fms", #pts, (os.clock() - st) * 1000))
                    buildTracer(pts, opts)
                else
                    logTracer("PF fallback straight")
                    buildTracer({a, b}, opts)
                end
            end)
            return
        end
        return buildTracer({a, b}, opts)
    end
    G.build = spawnFromTo

    local function findOrigin(char, part, vec)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local att = hrp and hrp:FindFirstChild("GunRaycastAttachment")
        if att then return att.WorldPosition end
        if typeof(part) == "Instance" and part:IsA("BasePart") then return part.Position end
        if typeof(vec) == "Vector3" then return vec end
        return nil
    end

    task.spawn(function()
        local ok, obj = pcall(function() return RepStorage:WaitForChild("ClientServices", 5) end)
        local ws = ok and obj and obj:FindFirstChild("WeaponService")
        local ev = ws and ws:FindFirstChild("GunFired")
        if not (ev and ev:IsA("RemoteEvent")) then return end
        ev.OnClientEvent:Connect(function(...)
            local args = {...}
            task.spawn(function()
                pcall(function()
                    local target = nil
                    for _, v in ipairs(args) do if typeof(v) == "Vector3" then target = v end end
                    if not target or not G.on then return end
                    local shooter = args[1]
                    local originPart = args[2]
                    local char = typeof(shooter) == "Instance" and shooter or nil
                    while char and not (char:IsA("Model") and char:FindFirstChildOfClass("Humanoid")) do char = char.Parent end
                    local isMe = char and char == LP.Character
                    if not isMe and not G.others then return end
                    local origin = findOrigin(char, originPart, nil)
                    if not origin then
                        local myChar = LP.Character
                        origin = myChar and myChar:GetPivot().Position or target
                    end
                    spawnFromTo(origin, target, G.impact, G.muzzle)
                end)
            end)
        end)
        logTracer("GunFired hook armed")
    end)

    G.preview = function(vec, extra)
        if G.previewing then return end
        local myChar = LP.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not (hrp and cam) then return end
        G.previewing = true
        local origin = (myChar:GetPivot() * CFrame.new(1.4, 1.25, -3.45)).Position
        local target
        if typeof(vec) == "Vector3" then
            target = vec
        else
            local best, bestDist = nil, 1e9
            for _, pl in ipairs(PlayersSvc:GetPlayers()) do
                if pl ~= LP and pl.Character then
                    local hr = pl.Character:FindFirstChild("HumanoidRootPart")
                    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                    if hr and hum and hum.Health > 0 then
                        local d = (hr.Position - origin).Magnitude
                        if d > 12 and d < 260 and d < bestDist then best, bestDist = hr.Position, d end
                    end
                end
            end
            if best then
                target = best
            else
                local dir = cam.CFrame.LookVector
                local flat = Vector3.new(dir.X, 0, dir.Z)
                flat = flat.Magnitude > 0.1 and flat.Unit or cam.CFrame.LookVector
                local hit = workspace:Raycast(origin, flat * 140 + Vector3.new(0, 2, 0), getRayParams())
                target = hit and hit.Position or origin + flat * 140
            end
        end
        extra = extra or {}
        extra.cb = function(tr) G._lastPreview = tr end
        spawnFromTo(origin, target, true, true, extra)
        local start = os.clock()
        while not G._lastPreview and os.clock() - start < 2 do task.wait() end
        local tr = G._lastPreview
        G._lastPreview = nil
        if not tr then G.previewing = false; return end
        local startCam = cam.CFrame.Position
        local dir = (target - origin).Unit
        local endPos = target
        cam.CameraType = Enum.CameraType.Scriptable
        pcall(function()
            RunSvc:BindToRenderStep("NoirTracerCam", Enum.RenderPriority.Camera.Value + 2, function(dt)
                if not G.previewing then return end
                local elapsed = os.clock() - tr.t0
                local headDist = math.min(tr.L, elapsed * tr.speed)
                local headPos = pointOnPath(tr, headDist)
                local t = headPos - origin
                if t.Magnitude > 0.05 then dir = t.Unit end
                local camPos = headDist < tr.L and (headPos - dir * 5.5 + Vector3.new(0, 2.4, 0)) or (endPos + Vector3.new(9, 3, 0))
                local look = headDist < tr.L and (headPos + dir * 2.5) or endPos
                startCam = startCam:Lerp(camPos, 1 - math.exp(-(dt or 0.016) * 14))
                cam.CFrame = CFrame.lookAt(startCam, look)
            end)
        end)
        local dur = tr.L / tr.speed
        local endT = os.clock()
        while os.clock() - endT < math.min(dur + 1.5, 9) and G.previewing do task.wait() end
        pcall(function() RunSvc:UnbindFromRenderStep("NoirTracerCam") end)
        pcall(function() cam.CameraType = Enum.CameraType.Custom; cam.CameraSubject = myChar:FindFirstChildOfClass("Humanoid") end)
        G.previewing = false
    end

    sec:AddToggle({Name = "bullet tracers", Default = G.on, Callback = function(v) G.on = v == true; CFG.bulletTracerOn = G.on; saveCFG() end})
    sec:AddDropdown({Name = "tracer method", Values = {"Classic", "Path Finder"}, Default = G.method, Callback = function(v)
        if v == "Classic" or v == "Path Finder" then G.method = v; CFG.tracerMethod = v; saveCFG() end
    end})
    sec:AddDropdown({Name = "tracer style", Values = StyleList, Default = G.style, Callback = function(v)
        if Styles[v] then G.style = v; CFG.tracerStyle = v; saveCFG() end
    end})
    sec:AddColorPicker({Name = "tracer color", Default = G.col, Callback = function(c)
        if typeof(c) == "Color3" then G.col = c; CFG.tracerCol = c; saveCFG() end
    end})
    sec:AddColorPicker({Name = "tail color", Default = G.col2, Callback = function(c)
        if typeof(c) == "Color3" then G.col2 = c; CFG.tracerCol2 = c; saveCFG() end
    end})
    sec:AddToggle({Name = "rainbow tracers", Default = G.rainbow, Callback = function(v) G.rainbow = v == true; CFG.tracerRainbow = G.rainbow; saveCFG() end})
    sec:AddSlider({Name = "tracer width", Min = 40, Max = 250, Default = G.width, Callback = function(v) G.width = tonumber(v) or 100; CFG.tracerWidth = G.width; saveCFG() end})
    sec:AddSlider({Name = "tracer speed", Min = 150, Max = 1500, Default = G.speed, Callback = function(v) G.speed = tonumber(v) or 520; CFG.tracerSpeed = G.speed; saveCFG() end})
    sec:AddSlider({Name = "tracer duration", Min = 3, Max = 40, Default = math.floor(G.life * 10 + 0.5), Callback = function(v)
        local n = tonumber(v) or 12
        G.life = n / 10; CFG.tracerLife = n; saveCFG()
    end})
    sec:AddToggle({Name = "impact effect", Default = G.impact, Callback = function(v) G.impact = v == true; CFG.tracerImpact = G.impact; saveCFG() end})
    sec:AddToggle({Name = "muzzle flash", Default = G.muzzle, Callback = function(v) G.muzzle = v == true; CFG.tracerMuzzle = G.muzzle; saveCFG() end})
    sec:AddToggle({Name = "show other shots", Default = G.others, Callback = function(v) G.others = v == true; CFG.tracerOthers = G.others; saveCFG() end})
    sec:AddButton({Name = "preview tracer", Callback = function() task.spawn(function() pcall(G.preview) end) end})
end

local BtSec = VisualsTab:AddSection({Name="bullet tracer", Side="Right"})
X.initTracer(BtSec)

do
local MV = {
    auto = false,
    dupe = false,
    running = false,
    session = 0,
    used = 0,
    gain = 0,
    cap = 3,
    pick = 1,
    delay = 0.04,
    status = "idle",
    mode = "none",
    entries = {},
    lastEntries = {},
    alt = nil,
    altMode = nil,
    origin = nil,
    spot = nil,
    conns = {},
    yOff = -4,
    offs = {0, -0.6, -1.2, 0.6, -1.8, 1.2, -2.4},
    offIdx = 1,
    PLATFORMS = {
        Vector3.new(25.69, 507.37, 49.26),
        Vector3.new(14.10, 507.37, 51.04),
        Vector3.new(1.83, 507.37, 50.76)
    }
}

function MV.padPos(p)
    if not p then return Vector3.zero end
    if p:IsA("BasePart") then return p.Position end
    local ok, cf = pcall(function() return p:GetPivot() end)
    return ok and cf.Position or Vector3.zero
end

function MV.padSpot(p)
    local pos = MV.padPos(p)
    local top = pos.Y
    if p:IsA("BasePart") then
        top = pos.Y + p.Size.Y / 2
    else
        pcall(function()
            local cf, sz = p:GetBoundingBox()
            pos = cf.Position
            top = cf.Position.Y + sz.Y / 2
        end)
    end
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local drop = 3
    if hum and hum.RigType ~= Enum.HumanoidRigType.R6 then
        drop = hum.HipHeight + (hrp and hrp.Size.Y / 2 or 1)
    end
    return Vector3.new(pos.X, top + drop - 0.25 + MV.yOff + (MV.offs[MV.offIdx] or 0), pos.Z)
end

function MV.tallyOf(e)
    if not e or not e.tally or not e.tally.Text then return 0 end
    return tonumber(string.match(tostring(e.tally.Text), "%d+")) or 0
end

function MV.shape(model)
    if not model then return nil end
    local pad = model:FindFirstChild("Pad", true)
        or model:FindFirstChild("VotePad", true)
        or model:FindFirstChild("Platform", true)
    local info = model:FindFirstChild("MapInfoGui", true)
        or model:FindFirstChild("MapInfo", true)
    local vote = model:FindFirstChild("VoteInfoGui", true)
        or model:FindFirstChild("VoteInfo", true)
    local icon = nil
    if info then
        icon = info:FindFirstChild("MapIcon", true)
            or info:FindFirstChildWhichIsA("ImageLabel", true)
            or info:FindFirstChildWhichIsA("ImageButton", true)
            or info:FindFirstChildWhichIsA("Decal", true)
            or info:FindFirstChildWhichIsA("Texture", true)
            or info:FindFirstChildWhichIsA("BasePart", true)
    end
    local box = nil
    if vote then
        box = vote:FindFirstChild("Container", true) or vote
    end
    if not box and info then
        box = info:FindFirstChild("Container", true)
    end
    local title = nil
    local tally = nil
    if box then
        title = box:FindFirstChild("MapName", true)
            or box:FindFirstChild("Name", true)
            or box:FindFirstChild("Title", true)
            or box:FindFirstChildWhichIsA("TextLabel", true)
        tally = box:FindFirstChild("Votes", true)
            or box:FindFirstChild("VoteCount", true)
            or box:FindFirstChild("Tally", true)
    end
    if not tally and vote then
        for _, d in ipairs(vote:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text and d.Text:match("%d+") then
                tally = d
                break
            end
        end
    end
    if not title and vote then
        for _, d in ipairs(vote:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text and d.Text ~= "" and d ~= tally then
                title = d
                break
            end
        end
    end
    if not (pad and info and icon and title and tally) then return nil end
    return { pad = pad, info = info, icon = icon, title = title, tally = tally, real = true, model = model }
end

function MV.exact()
    local out, seen = {}, {}
    local function inspect(vp)
        if not vp or seen[vp] then return end
        seen[vp] = true
        for _, m in ipairs(vp:GetChildren()) do
            local e = MV.shape(m)
            if e then out[#out + 1] = e end
        end
    end
    for _, n in ipairs({"SummerLobby", "Lobby", "LobbyMap", "Menu"}) do
        local r = workspace:FindFirstChild(n)
        if r then inspect(r:FindFirstChild("VotePads", true)) end
    end
    if #out == 0 then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d.Name == "VotePads" or d.Name == "VotePadsFolder" then
                inspect(d)
                if #out > 0 then break end
            end
        end
    end
    if #out == 0 then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d.Name == "MapInfoGui" or d.Name == "VoteInfoGui" then
                local model = d.Parent
                while model and model ~= workspace do
                    local e = MV.shape(model)
                    if e then out[#out + 1] = e; break end
                    model = model.Parent
                end
            end
        end
    end
    return MV.order(out)
end

function MV.order(out)
    table.sort(out, function(a, b)
        return MV.padPos(a.pad).X > MV.padPos(b.pad).X
    end)
    return out
end

function MV.getEntries()
    local now = os.clock()
    local list = MV._list
    if list then
        local ok = true
        for _, x in ipairs(list) do
            if (x.pad and not x.pad.Parent) or not x.tally.Parent or not x.icon.Parent then ok = false; break end
        end
        if ok and now - (MV._t or 0) < 10 then return list end
    end
    if now - (MV._scanT or -100) < (list and 1.5 or 4) then return MV.entries end
    MV._scanT = now
    local e = MV.exact()
    if #e > 0 then
        MV.mode = "pads"
        MV.entries = e
        MV._list = e
        MV._t = now
        MV.lastEntries = e
        return e
    end
    MV._list = nil
    if MV.alt and #MV.alt > 0 then
        local ok = true
        for _, x in ipairs(MV.alt) do
            if not x.tally.Parent or not x.icon.Parent or (x.pad and not x.pad.Parent) then
                ok = false
                break
            end
        end
        if ok then
            MV.mode = MV.altMode or "scan"
            MV.entries = MV.alt
            MV.lastEntries = MV.alt
            return MV.alt
        end
        MV.alt = nil
    end
    MV.mode = "hardcoded"
    MV.entries = {}
    return MV.entries
end

function MV.spotFor(i)
    local e = MV.entries[i]
    local hard = MV.PLATFORMS[i]
    if e and e.pad then
        return MV.padSpot(e.pad)
    end
    if hard then
        return hard + Vector3.new(0, MV.yOff + (MV.offs[MV.offIdx] or 0), 0)
    end
    return nil
end

function MV.image(e)
    local ic = e.icon
    local v = ""
    local c = ic.ClassName
    if c == "ImageLabel" or c == "ImageButton" then
        v = ic.Image
    elseif c == "Decal" or c == "Texture" then
        v = ic.Texture
    elseif c == "BasePart" then
        v = ""
    end
    v = tostring(v or "")
    if v:match("^%d+$") then v = "rbxassetid://" .. v end
    return v
end

function MV.drop()
    for k, c in pairs(MV.conns) do
        pcall(function() c:Disconnect() end)
        MV.conns[k] = nil
    end
end

function MV.back()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if hrp and MV.origin then
        local hum = ch:FindFirstChildWhichIsA("Humanoid")
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
        hrp.CFrame = MV.origin
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.delay(0.05, function()
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildWhichIsA("Humanoid")
            if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end) end
        end)
    end
end

function MV.finish(back)
    MV.session = MV.session + 1
    MV.drop()
    if back then MV.back() end
    MV.running = false
    MV.spot = nil
end

function MV.kill()
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
    end
    pcall(function() ch:BreakJoints() end)
end

function MV.spawned(old)
    local ch = LocalPlayer.Character
    if not ch or ch == old then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    return ch:FindFirstChild("HumanoidRootPart") ~= nil and hum ~= nil and hum.Health > 0
end

function MV.run(id, slot)
    local function alive()
        return MV.session == id and MV.running and not Library.Unloaded
    end
    local entry = MV.entries[slot]
    local startTally = entry and MV.tallyOf(entry) or 0
    local last = startTally
    local wasEn = entry and entry.info.Enabled
    local t0 = os.clock()
    local reason = "done"
    local miss = 0
    local switching = false
    local function minWin() return math.max(0.03, PING * 0.9 + 0.03) end
    local function maxWin() return math.max(0.08, PING * 2.2 + 0.15) end
    local win = minWin()
    while alive() do
        if MV.pick ~= slot then reason = "switch"; switching = true; break end
        if entry and entry.pad and not entry.pad.Parent then reason = "pad removed"; break end
        if wasEn and not entry.info.Enabled then reason = "voting ended"; break end
        if MV.used >= MV.cap then reason = "count reached"; break end
        if os.clock() - t0 > 120 then reason = "timeout"; break end
        local ch = LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local spot = MV.spotFor(slot) or MV.spot
            MV.spot = spot
            hrp.CFrame = CFrame.new(spot)
            hrp.AssemblyLinearVelocity = Vector3.zero
            if entry and entry.pad then EX.touch(hrp, entry.pad, true) end
            local limit = (not MV.dupe) and 0.1 or win
            local tt = os.clock()
            local got = false
            while alive() and MV.pick == slot and os.clock() - tt < limit do
                if MV.dupe and entry and MV.tallyOf(entry) > last then got = true; break end
                if hrp.Parent and (hrp.Position - spot).Magnitude > 3 then
                    hrp.CFrame = CFrame.new(spot)
                end
                RunService.Heartbeat:Wait()
            end
            if not alive() then break end
            MV.used = MV.used + 1
            if entry then
                local cur = MV.tallyOf(entry)
                if cur > last then last = cur; got = true end
                MV.gain = last - startTally
            end
            if MV.dupe and entry and entry.real then
                if got then
                    miss = 0
                    win = math.max(minWin(), math.min(win, (os.clock() - tt) * 1.2 + 0.02))
                else
                    miss = miss + 1
                    if miss >= 3 then
                        miss = 0
                        if win < maxWin() then
                            win = math.min(maxWin(), win * 1.5 + 0.02)
                        else
                            MV.offIdx = MV.offIdx % #MV.offs + 1
                        end
                    end
                end
            end
            if not MV.dupe then reason = "voted"; break end
            if MV.used >= MV.cap then reason = "count reached"; break end
            MV.kill()
            local rt = os.clock()
            while alive() and not MV.spawned(ch) and os.clock() - rt < 8 do
                RunService.Heartbeat:Wait()
            end
        else
            RunService.Heartbeat:Wait()
        end
    end
    if MV.session == id then
        MV.status = reason .. " (" .. MV.used .. (entry and (" / +" .. MV.gain) or "") .. ")"
        MV.finish(true)
        if switching then task.defer(function() MV.begin() end) end
    end
end

function MV.begin()
    if MV.running then return false, "already running" end
    local entries = MV.getEntries()
    local entry = entries[MV.pick]
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "no character" end
    local spot = MV.spotFor(MV.pick)
    if not spot then return false, "no platform for slot " .. MV.pick end
    if entry and entry.real and entry.info.Enabled == false then
        return false, "no active vote pad"
    end
    MV.session = MV.session + 1
    local id = MV.session
    MV.running = true
    MV.used = 0
    MV.gain = 0
    MV.status = "voting"
    MV.origin = hrp.CFrame
    MV.spot = spot
    MV.mark = entry and MV.tallyOf(entry) or 0
    MV.startTally = MV.mark
    hrp.CFrame = CFrame.new(spot)
    if entry and entry.pad then EX.touch(hrp, entry.pad, true) end
    if not MV.dupe then
        task.delay(math.max(0.15, PING * 2 + 0.12), function()
            if MV.session == id then
                MV.status = "voted"
                MV.finish(true)
            end
        end)
        return true
    end
    MV.conns.hold = Connect(RunService.Heartbeat, function()
        if MV.session ~= id or not MV.spot then return end
        if entry and entry.info.Enabled == false then
            MV.status = "voting ended (" .. MV.used .. ")"
            MV.finish(true)
            return
        end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local flat = Vector3.new(h.Position.X - MV.spot.X, 0, h.Position.Z - MV.spot.Z)
        if flat.Magnitude > 2.5 then h.CFrame = CFrame.new(MV.spot) end
    end)
    if entry and entry.real then
        MV.conns.tally = Connect(entry.tally:GetPropertyChangedSignal("Text"), function()
            if MV.session ~= id or not MV.dupe then return end
            local now = MV.tallyOf(entry)
            if now <= (MV.mark or 0) then
                MV.mark = now
                return
            end
            MV.mark = now
            MV.gain = now - (MV.startTally or 0)
        end)
    end
    MV.conns.spawn = Connect(LocalPlayer.CharacterAdded, function(char)
        if MV.session ~= id or not MV.dupe then return end
        local h = char:WaitForChild("HumanoidRootPart", 6)
        if not h or MV.session ~= id or not MV.spot then return end
        if entry and entry.info.Enabled == false then return end
        if MV.used >= MV.cap then
            MV.status = "count reached (" .. MV.used .. ")"
            MV.finish(true)
            return
        end
        h.CFrame = CFrame.new(MV.spot)
        if entry and entry.pad then EX.touch(h, entry.pad, true) end
    end)
    task.spawn(MV.run, id, MV.pick)
    return true
end

local MapTab = Win:AddTab({Name = "map vote", Subtitle = "vote duper"})
local MapSec = MapTab:AddSection({Name = "maps", Side = "Left"})

local MapContainer = New("Frame", {
    Size = UDim2.new(1, 0, 0, 260),
    BackgroundTransparency = 1,
    Parent = MapSec.Holder
})

local cards = {}
for i = 1, 3 do
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 76),
        Position = UDim2.fromOffset(0, (i - 1) * 82),
        BackgroundColor3 = Theme.Box,
        Text = "",
        Parent = MapContainer
    })
    Corner(btn, 6)
    local st = Stroke(btn, Theme.Stroke)
    local imgFrame = New("Frame", {
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Row,
        ClipsDescendants = true,
        Parent = btn
    })
    Corner(imgFrame, 5)
    local img = New("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Parent = imgFrame
    })
    local nm = Label({
        Size = UDim2.new(1, -76, 0, 18),
        Position = UDim2.fromOffset(76, 12),
        Text = "map " .. i,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 14,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn
    })
    local vt = Label({
        Size = UDim2.new(1, -76, 0, 16),
        Position = UDim2.fromOffset(76, 36),
        Text = "votes: -",
        TextColor3 = Theme.Dim,
        TextSize = 12,
        Parent = btn
    })
    Connect(btn.MouseButton1Click, function()
        playSound(Sounds.Click, 0.5)
        MV.pick = i
    end)
    cards[i] = {btn = btn, imgFrame = imgFrame, st = st, img = img, nm = nm, vt = vt}
end

local CtlSec = MapTab:AddSection({Name = "duper", Side = "Right"})
local stLbl = CtlSec:AddLabel({Name = "status: idle"})

CtlSec:AddToggle({
    Name = "auto vote",
    Default=false,
    Callback = function(v)
        MV.auto = v
        if not v and MV.running then MV.finish(true) end
    end
})
CtlSec:AddToggle({
    Name = "dupe",
    Default=false,
    Callback = function(v)
        MV.dupe = v
        if not v and MV.running then MV.finish(true) end
    end
})
CtlSec:AddSlider({
    Name = "dupe count",
    Min = 1, Max = 100, Default = CFG.dupeCount or 3,
    Callback = function(v) CFG.dupeCount = v; saveCFG(); MV.cap = v end
})
MV.cap = CFG.dupeCount or 3
CtlSec:AddButton({
    Name = "vote now",
    Callback = function()
        local ok, why = MV.begin()
        if not ok then Library:Notify({Title = "vote", Text = tostring(why)}) end
    end
})
CtlSec:AddButton({
    Name = "stop",
    Callback = function()
        if MV.running then
            MV.status = "stopped (" .. MV.used .. ")"
            MV.finish(true)
        end
    end
})

task.spawn(function()
    while not Library.Unloaded do
        local shown = Win.Visible
        pcall(function()
            MV.getEntries()
            if shown then
                for i = 1, 3 do
                    local c, e = cards[i], MV.entries[i]
                    if not e then e = MV.lastEntries[i] end
                    local img, name, votes
                    if e then
                        img = MV.image(e)
                        local tt = e.title and e.title.Text
                        name = (tt and tt ~= "" and tostring(tt)) or ("map " .. i)
                        votes = "votes: " .. tostring(MV.tallyOf(e))
                    else
                        img = ""
                        name = "map " .. i .. " (not found)"
                        votes = "votes: -"
                    end
                    if c.lastImg ~= img then c.lastImg = img; c.img.Image = img end
                    if c.lastName ~= name then c.lastName = name; c.nm.Text = name end
                    if c.lastVotes ~= votes then c.lastVotes = votes; c.vt.Text = votes end
                    local sel = (MV.pick == i)
                    if c.lastSel ~= sel then c.lastSel = sel; c.st.Color = sel and Theme.Accent or Theme.Stroke end
                end
            end
            local sel = MV.entries[MV.pick]
            local en = sel and sel.info.Enabled or false
            if MV.auto and sel and en and not MV.wasEn and not MV.running then
                MV.begin()
            end
            MV.wasEn = en
            if shown then
                local s = "status: " .. (MV.running and ("voting #" .. MV.used .. (sel and (" +" .. MV.gain) or "")) or MV.status)
                    .. " [" .. MV.mode .. " " .. #MV.entries .. "]"
                if s ~= MV.lastStatus then MV.lastStatus = s; stLbl:SetText(s) end
            end
        end)
        task.wait(shown and 0.5 or 1)
    end
end)
end

do
local FxTab=Win:AddTab({Name="effects",Subtitle="death effect"})
local FxSec=FxTab:AddSection({Name="death effect",Side="Left"})
FxSec:AddToggle({Name="enable effect",Default=CFG.killEffectOn,Callback=function(v) CFG.killEffectOn=v; saveCFG() end})
FxSec:AddDropdown({Name="style",Values={"confetti","fireworks","shockwave","lightning","ghost","explosion","random"},Default=CFG.killEffectStyle,Callback=function(v) CFG.killEffectStyle=v; saveCFG() end})
FxSec:AddToggle({Name="on my death",Default=CFG.killEffectSelf,Callback=function(v) CFG.killEffectSelf=v; saveCFG() end})
FxSec:AddButton({Name="preview",Callback=function()
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then DeathFx.play(hrp.Position+hrp.CFrame.LookVector*8,true) end
end})
end

do
local TradeTab = Win:AddTab({Name="trade", Subtitle="calculator"})
local TradeSec = TradeTab:AddSection({Name="trade calculator", Side="Left"})
local myTotal,hisTotal=0,0
local myItems,hisItems={},{}
local myLbl=TradeSec:AddLabel({Name="your total: 0"})
local hisLbl=TradeSec:AddLabel({Name="their total: 0"})
local searchInput=TradeSec:AddTextbox({Name="item", Placeholder="search..."})
TradeSec:AddButton({Name="add my", Callback=function() local item=findTradeItem(searchInput:Get()); if item then table.insert(myItems,item); myTotal=0; for _,v in ipairs(myItems) do myTotal=myTotal+(v.value or 0) end; myLbl:SetText("your total: "..myTotal); searchInput:Set("") end end})
TradeSec:AddButton({Name="add his", Callback=function() local item=findTradeItem(searchInput:Get()); if item then table.insert(hisItems,item); hisTotal=0; for _,v in ipairs(hisItems) do hisTotal=hisTotal+(v.value or 0) end; hisLbl:SetText("their total: "..hisTotal); searchInput:Set("") end end})
TradeSec:AddButton({Name="clear", Callback=function() myItems={}; hisItems={}; myTotal=0; hisTotal=0; myLbl:SetText("your total: 0"); hisLbl:SetText("their total: 0") end})
local TradeHelperSec = TradeTab:AddSection({Name="trade helper", Side="Right"})
TradeHelperSec:AddToggle({Name="show price on items", Default=State.tradeHelperOn, Callback=function(v) State.tradeHelperOn=v; CFG.tradeHelperOn=v; saveCFG() end})
end

local MusicTab = Win:AddTab({Name="music", Subtitle="sounds"})
local MusicSec = MusicTab:AddSection({Name="music", Side="Left"})
local bgSound=Instance.new("Sound"); bgSound.Name="PiddleMusic"; bgSound.Volume=CFG.musicVolume/100; bgSound.Looped=true; bgSound.Parent=SoundService
local TRACKS={["Chill"]="rbxassetid://1837879082", ["Synth"]="rbxassetid://1836318003", ["Trap"]="rbxassetid://1837842597", ["Phonk"]="rbxassetid://9046731150"}
local orderTracks={}; for k in pairs(TRACKS) do table.insert(orderTracks,k) end; table.sort(orderTracks)
local curTrack=1
local function playIdx(i) i=((i-1)%#orderTracks)+1; curTrack=i; bgSound.SoundId=TRACKS[orderTracks[i]]; bgSound:Play() end
MusicSec:AddButton({Name="play", Callback=function()
    if bgSound.IsPaused then bgSound:Resume()
    elseif bgSound.SoundId=="" then playIdx(curTrack)
    elseif not bgSound.IsPlaying then bgSound:Play() end
end})
MusicSec:AddButton({Name="pause", Callback=function() bgSound:Pause() end})
MusicSec:AddButton({Name="stop", Callback=function() bgSound:Stop() end})
MusicSec:AddButton({Name="next", Callback=function() playIdx(curTrack+1) end})
MusicSec:AddButton({Name="prev", Callback=function() playIdx(curTrack-1) end})
MusicSec:AddSlider({Name="volume", Min=0, Max=100, Default=CFG.musicVolume, Callback=function(v) bgSound.Volume=v/100; CFG.musicVolume=v; saveCFG() end})

local SettingsTab = Win:AddTab({Name="settings", Subtitle="ui config"})
local BgSec = SettingsTab:AddSection({Name="background", Side="Left"})
local bgNames={}; for k in pairs(BG_LIST) do table.insert(bgNames,k) end; table.sort(bgNames)
BgSec:AddDropdown({Name="background", Values=bgNames, Default=CFG.bgName, Callback=function(v)
    CFG.bgName=v; saveCFG()
    local img=BG_LIST[v] or ""
    if Win.BgImage then Win.BgImage.Image=img end
    if wmBg then wmBg.Image=img end
end})
BgSec:AddSlider({Name="bg transparency", Min=0, Max=100, Default=40, Callback=function(v)
    if Win.BgImage then Win.BgImage.ImageTransparency=v/100 end
    if wmBg then wmBg.ImageTransparency=math.min(0.8,v/100+0.1) end
end})
BgSec:AddSlider({Name="ui scale", Min=50, Max=150, Default=CFG.uiScale, Callback=function(v)
    CFG.uiScale = v
    Win._baseScale = v/100
    if Win.UIScale then Win.UIScale.Scale = v/100 end
    saveCFG()
end})
X.UI = {pend=nil, busy=false}
function X.UI.remap(list)
    local gui = Library.Gui
    if not gui then return end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiObject") then
            local c = d.BackgroundColor3
            for _, pr in ipairs(list) do
                if c == pr[1] then d.BackgroundColor3 = pr[2]; break end
            end
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                local t = d.TextColor3
                for _, pr in ipairs(list) do
                    if t == pr[1] then d.TextColor3 = pr[2]; break end
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local t = d.ImageColor3
                for _, pr in ipairs(list) do
                    if t == pr[1] then d.ImageColor3 = pr[2]; break end
                end
            elseif d:IsA("ScrollingFrame") then
                local t = d.ScrollBarImageColor3
                for _, pr in ipairs(list) do
                    if t == pr[1] then d.ScrollBarImageColor3 = pr[2]; break end
                end
            end
        elseif d:IsA("UIStroke") then
            local c = d.Color
            for _, pr in ipairs(list) do
                if c == pr[1] then d.Color = pr[2]; break end
            end
        end
    end
end
function X.UI.setAccent(c)
    local old = Theme.Accent
    if old == c then return end
    X.UI.remap({{old, c}})
    Theme.Accent = c
end
function X.UI.setLine(c)
    local oldS, oldSoft = Theme.Stroke, Theme.StrokeSoft
    local newSoft = c:Lerp(Theme.Window, 0.45)
    if oldS == c then return end
    X.UI.remap({{oldS, c}, {oldSoft, newSoft}})
    Theme.Stroke = c
    Theme.StrokeSoft = newSoft
end
function X.UI.queue(kind, c)
    X.UI.pend = X.UI.pend or {}
    X.UI.pend[kind] = c
    if X.UI.busy then return end
    X.UI.busy = true
    task.delay(0.15, function()
        X.UI.busy = false
        local p = X.UI.pend
        X.UI.pend = nil
        if not p then return end
        if p.accent then pcall(X.UI.setAccent, p.accent) end
        if p.line then pcall(X.UI.setLine, p.line) end
    end)
end
BgSec:AddColorPicker({Name="ui color", Default=(typeof(CFG.uiAccent)=="Color3" and CFG.uiAccent) or Theme.Accent, Callback=function(c)
    CFG.uiAccent = c; saveCFG(); X.UI.queue("accent", c)
end})
BgSec:AddColorPicker({Name="ui lines color", Default=(typeof(CFG.uiLine)=="Color3" and CFG.uiLine) or Theme.Stroke, Callback=function(c)
    CFG.uiLine = c; saveCFG(); X.UI.queue("line", c)
end})
BgSec:AddColorPicker({Name="sidebar color", Default=(typeof(CFG.sidebarColor)=="Color3" and CFG.sidebarColor) or Theme.Sidebar, Callback=function(c)
    CFG.sidebarColor = c; saveCFG()
    if Win.Sidebar then Win.Sidebar.BackgroundColor3 = c end
end})
BgSec:AddSlider({Name="sidebar transparency", Min=0, Max=100, Default=CFG.sidebarTrans or 20, Callback=function(v)
    CFG.sidebarTrans = v; saveCFG()
    if Win.Sidebar then Win.Sidebar.BackgroundTransparency = v / 100 end
end})
local SysSec = SettingsTab:AddSection({Name="system", Side="Right"})
SysSec:AddButton({Name="save config", Callback=function() saveCFG(); Library:Notify({Title="piddle", Text="config saved"}) end})
SysSec:AddButton({Name="reload ui", Callback=function() Library:Unload() end})
if CFG.topImage and TOP_IMAGES[CFG.topImage] then
    Win.TopImg.Image = ResolveImage(TOP_IMAGES[CFG.topImage])
    Win.TopImg.Visible = CFG.topImageVisible
end
task.delay(1.5, function()
    pcall(function()
        if CFG.korbloxOn then applyKorbloxNow() end
        if CFG.headlessOn then applyHeadlessNow() end
        if CFG.chinaHatOn then Hat.apply(); task.delay(0.7, function() pcall(updateHatColor, CFG.chinaHatColor) end) end
        if CFG.selectedPack then applyPack(CFG.selectedPack) end
        bgSound.Volume=CFG.musicVolume/100
    end)
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        if CFG.korbloxOn then applyKorbloxNow() end
        if CFG.headlessOn then applyHeadlessNow() end
        if CFG.chinaHatOn then Hat.apply(); task.delay(0.7, function() pcall(updateHatColor, CFG.chinaHatColor) end) end
        if CFG.selectedPack then applyPack(CFG.selectedPack) end
    end)
end)
for n,o in pairs({["main"]=-6,["combat"]=-5,["update"]=-4,["map vote"]=-3,["player"]=-2,["players"]=-1}) do
    for _,tb in ipairs(Win.Tabs) do if tb.Name==n then tb.Group.LayoutOrder=o end end
end
function X.round(d)
    local c = d.ClassName
    if c ~= "Frame" and c ~= "TextButton" and c ~= "ImageLabel" and c ~= "ImageButton" and c ~= "TextBox" and c ~= "ScrollingFrame" then return end
    if d:FindFirstChildOfClass("UICorner") then return end
    local solid = d.BackgroundTransparency < 0.95
    local img = (c == "ImageLabel" or c == "ImageButton") and d.Image ~= ""
    if not solid and not img then return end
    local sx, sy = d.Size.X, d.Size.Y
    local mn = math.huge
    if sx.Scale == 0 then mn = math.min(mn, sx.Offset) end
    if sy.Scale == 0 then mn = math.min(mn, sy.Offset) end
    if mn <= 3 then return end
    local r = 5
    if mn ~= math.huge and mn < 16 then r = math.max(2, math.floor(mn / 2)) end
    if sx.Scale == 1 and sy.Scale == 1 then r = 8 end
    if d.Name == "BgImage" or d.Name == "Main" then r = 8 end
    Corner(d, r)
end
X.rq = {}
if Library.Gui then
    for _, d in ipairs(Library.Gui:GetDescendants()) do pcall(X.round, d) end
    Connect(Library.Gui.DescendantAdded, function(d)
        X.rq[#X.rq + 1] = d
        if X.rbusy then return end
        X.rbusy = true
        task.delay(0.25, function()
            X.rbusy = false
            local q = X.rq
            X.rq = {}
            for _, o in ipairs(q) do
                if o.Parent then pcall(X.round, o) end
            end
        end)
    end)
end
if typeof(CFG.uiAccent) == "Color3" then pcall(X.UI.setAccent, CFG.uiAccent) end
if typeof(CFG.uiLine) == "Color3" then pcall(X.UI.setLine, CFG.uiLine) end
if Win.Sidebar then
    if typeof(CFG.sidebarColor) == "Color3" then Win.Sidebar.BackgroundColor3 = CFG.sidebarColor end
    if CFG.sidebarTrans then Win.Sidebar.BackgroundTransparency = CFG.sidebarTrans / 100 end
end
task.delay(0.8, function() Library:Notify({Title="piddle", Text="loaded successfully", Duration=5}) end)
task.delay(2.5, function() Library:Notify({Title="piddle", Text="click watermark to toggle ui", Duration=5}) end)
warn("[PIDDLE] Loaded, hope u enjoy it")