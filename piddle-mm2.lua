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
local function Stroke(p,c,t,tr) local s_=New("UIStroke",{Color=c or Theme.Stroke,Thickness=t or 1,Transparency=tr or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=p}); if c==nil or c==Theme.Stroke or c==Theme.StrokeSoft then s_:SetAttribute("L",true) end; return s_ end
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

-- ===== vector tab icons (smooth: rotated rounded bars + circles, no pixel grid) =====
do
local TabIcons = {}
local function mk(parent, class, props) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; o.Parent = parent; return o end
-- primitives return a "painter" (function(color)) so the whole icon can be recoloured
local function seg(parent, paints, x1, y1, x2, y2, t)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local f = mk(parent, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2), Size = UDim2.fromOffset(len + t * 0.4, t),
        Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = Theme.Dimmer, BorderSizePixel = 0})
    mk(f, "UICorner", {CornerRadius = UDim.new(0.5, 0)})
    paints[#paints + 1] = function(c) f.BackgroundColor3 = c end
end
local function path(parent, paints, pts, t) for i = 1, #pts - 1 do seg(parent, paints, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], t) end end
local function circ(parent, paints, cx, cy, r, t, filled)
    local f = mk(parent, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(r * 2, r * 2), BorderSizePixel = 0,
        BackgroundTransparency = filled and 0 or 1, BackgroundColor3 = Theme.Dimmer})
    mk(f, "UICorner", {CornerRadius = UDim.new(0.5, 0)})
    if filled then paints[#paints + 1] = function(c) f.BackgroundColor3 = c end
    else
        local s = mk(f, "UIStroke", {Thickness = t, Color = Theme.Dimmer, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
        paints[#paints + 1] = function(c) s.Color = c end
    end
end
local function box(parent, paints, x, y, w, h, t, rad)
    local f = mk(parent, "Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0})
    mk(f, "UICorner", {CornerRadius = UDim.new(0, rad or 2)})
    local s = mk(f, "UIStroke", {Thickness = t, Color = Theme.Dimmer, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    paints[#paints + 1] = function(c) s.Color = c end
end
local function arc(cx, cy, r, a0, a1, steps)
    local pts = {}
    for i = 0, steps do local a = math.rad(a0 + (a1 - a0) * i / steps); pts[#pts + 1] = {cx + r * math.cos(a), cy + r * math.sin(a)} end
    return pts
end
local T = 1.4
TabIcons.main = function(p, c) path(p, c, {{3, 1.5}, {3, 12}, {5.9, 9.3}, {8.2, 13}, {9.8, 12.2}, {7.6, 8.7}, {11.5, 8.5}, {3, 1.5}}, T) end
TabIcons.combat = function(p, c)
    circ(p, c, 7, 7, 4.8, T); circ(p, c, 7, 7, 0.9, 0, true)
    seg(p, c, 7, 0.8, 7, 3.4, T); seg(p, c, 7, 10.6, 7, 13.2, T); seg(p, c, 0.8, 7, 3.4, 7, T); seg(p, c, 10.6, 7, 13.2, 7, T)
end
TabIcons.visuals = function(p, c)
    -- animated eye: the pupil looks around and the eye blinks
    local eye = mk(p, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(13, 8), BackgroundTransparency = 1, BorderSizePixel = 0})
    mk(eye, "UICorner", {CornerRadius = UDim.new(0.5, 0)})
    local st = mk(eye, "UIStroke", {Thickness = T, Color = Theme.Dimmer, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    c[#c + 1] = function(col) st.Color = col end
    local pupil = mk(p, "Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(4.2, 4.2), BackgroundColor3 = Theme.Dimmer, BorderSizePixel = 0})
    mk(pupil, "UICorner", {CornerRadius = UDim.new(0.5, 0)})
    c[#c + 1] = function(col) pupil.BackgroundColor3 = col end
    local TI = function(t) return TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
    task.spawn(function()
        local rng = Random.new()
        while eye.Parent and not Library.Unloaded do
            task.wait(rng:NextNumber(1.4, 3.2))
            if not eye.Parent then break end
            if Library.Lite then
            elseif rng:NextInteger(1, 3) == 1 then
                -- blink
                TweenService:Create(eye, TI(0.07), {Size = UDim2.fromOffset(13, 1.2)}):Play()
                TweenService:Create(pupil, TI(0.07), {Size = UDim2.fromOffset(4.2, 0.8)}):Play()
                task.wait(0.09)
                TweenService:Create(eye, TI(0.09), {Size = UDim2.fromOffset(13, 8)}):Play()
                TweenService:Create(pupil, TI(0.09), {Size = UDim2.fromOffset(4.2, 4.2)}):Play()
            else
                -- look left / right / centre
                local dirs = {-2.6, 0, 2.6}
                local dx = dirs[rng:NextInteger(1, 3)]
                local dy = rng:NextNumber(-0.7, 0.7)
                TweenService:Create(pupil, TI(0.16), {Position = UDim2.fromOffset(7 + dx, 7 + dy)}):Play()
            end
        end
    end)
end
TabIcons.players = function(p, c)
    circ(p, c, 5, 4.3, 2, T); path(p, c, arc(5, 12.6, 3.7, 180, 360, 6), T)
    circ(p, c, 10.4, 5, 1.5, T); path(p, c, arc(10.4, 12.6, 2.6, 190, 350, 5), T)
end
TabIcons.auto = function(p, c) circ(p, c, 7, 7, 5.6, T); circ(p, c, 7, 7, 2.5, T) end
TabIcons.teleport = function(p, c)
    circ(p, c, 7, 5.2, 3.5, T); path(p, c, {{3.9, 7}, {7, 13.2}, {10.1, 7}}, T); circ(p, c, 7, 5.2, 1, 0, true)
end
TabIcons.fling = function(p, c) path(p, c, {{8.6, 0.8}, {3.4, 7.8}, {7, 7.8}, {5.4, 13.2}, {10.6, 6}, {7, 6}, {8.6, 0.8}}, T) end
TabIcons.movement = function(p, c)
    seg(p, c, 7, 1.4, 7, 12.6, T); seg(p, c, 1.4, 7, 12.6, 7, T)
    path(p, c, {{5.2, 3.2}, {7, 1.4}, {8.8, 3.2}}, T); path(p, c, {{5.2, 10.8}, {7, 12.6}, {8.8, 10.8}}, T)
    path(p, c, {{3.2, 5.2}, {1.4, 7}, {3.2, 8.8}}, T); path(p, c, {{10.8, 5.2}, {12.6, 7}, {10.8, 8.8}}, T)
end
TabIcons.dodge = function(p, c) path(p, c, {{2, 2.6}, {7, 1}, {12, 2.6}, {11.5, 8}, {7, 13}, {2.5, 8}, {2, 2.6}}, T); seg(p, c, 7, 4.2, 7, 9.4, T) end
TabIcons.misc = function(p, c)
    circ(p, c, 7, 7, 3, T)
    for k = 0, 7 do local a = k * math.pi / 4; seg(p, c, 7 + 4.4 * math.cos(a), 7 + 4.4 * math.sin(a), 7 + 6 * math.cos(a), 7 + 6 * math.sin(a), T) end
end
TabIcons.warnings = function(p, c)
    path(p, c, {{7, 1.4}, {9.8, 3.5}, {10.2, 8.2}, {12, 10.2}, {2, 10.2}, {3.8, 8.2}, {4.2, 3.5}, {7, 1.4}}, T); circ(p, c, 7, 12.3, 1, 0, true)
end
TabIcons.update = function(p, c)
    path(p, c, arc(7, 7, 5.2, 40, 330, 14), T); path(p, c, {{9.2, 1.4}, {12, 2.4}, {10.4, 5.2}}, T)
end
TabIcons.player = function(p, c) path(p, c, {{1, 4}, {5, 1.6}, {6.4, 3}, {7.6, 3}, {9, 1.6}, {13, 4}, {11.4, 6.8}, {10, 6}, {10, 12.8}, {4, 12.8}, {4, 6}, {2.6, 6.8}, {1, 4}}, T) end
TabIcons["map vote"] = function(p, c) box(p, c, 2, 1.5, 10, 11, T, 2); path(p, c, {{4.6, 7.4}, {6.4, 9.4}, {9.6, 4.8}}, T) end
TabIcons.effects = function(p, c) path(p, c, {{7, 1}, {8.6, 5.4}, {13, 7}, {8.6, 8.6}, {7, 13}, {5.4, 8.6}, {1, 7}, {5.4, 5.4}, {7, 1}}, T) end
TabIcons.trade = function(p, c)
    seg(p, c, 1.8, 4.4, 12, 4.4, T); path(p, c, {{9.6, 2}, {12, 4.4}, {9.6, 6.8}}, T)
    seg(p, c, 12.2, 9.6, 2, 9.6, T); path(p, c, {{4.4, 7.2}, {2, 9.6}, {4.4, 12}}, T)
end
TabIcons.music = function(p, c)
    circ(p, c, 4.6, 10.8, 2.2, 0, true); circ(p, c, 10.2, 9.4, 2.2, 0, true)
    seg(p, c, 6.7, 10.6, 6.7, 2.4, T); seg(p, c, 12.3, 9.2, 12.3, 1.6, T); seg(p, c, 6.7, 2.6, 12.3, 1.6, T * 1.4)
end
TabIcons.settings = function(p, c)
    seg(p, c, 1.4, 3.4, 12.6, 3.4, T); circ(p, c, 9, 3.4, 1.7, 0, true)
    seg(p, c, 1.4, 7, 12.6, 7, T); circ(p, c, 5, 7, 1.7, 0, true)
    seg(p, c, 1.4, 10.6, 12.6, 10.6, T); circ(p, c, 8.5, 10.6, 1.7, 0, true)
end
TabIcons.minigames = function(p, c)
    box(p, c, 1, 3.8, 12, 7.4, T, 3.5); seg(p, c, 4, 5.8, 4, 9.2, T); seg(p, c, 2.3, 7.5, 5.7, 7.5, T); circ(p, c, 9.6, 6.6, 0.8, 0, true); circ(p, c, 11.2, 8.4, 0.8, 0, true)
end
TabIcons.hotkeys = function(p, c)
    box(p, c, 1, 3, 12, 8, T, 2)
    for _, x in ipairs({3.6, 5.8, 8, 10.2}) do circ(p, c, x, 5.6, 0.7, 0, true) end
    seg(p, c, 4, 8.8, 10, 8.8, T)
end
-- returns setColor(c) or nil when the tab has no icon
function Library.DrawTabIcon(parent, name)
    local fn = TabIcons[string.lower(name or "")]
    if not fn then return nil end
    local paints = {}
    fn(parent, paints)
    return function(col) for _, f in ipairs(paints) do f(col) end end
end
end

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
        local setIcon = (not parentTab) and Library.DrawTabIcon and Library.DrawTabIcon(iconHolder, tab.Name) or nil
        if setIcon then
            tab.IconRing=New("UIStroke",{Thickness=0,Color=Theme.Dimmer,Parent=iconHolder})
            local function paintIcon() setIcon(tab.IconRing.Color) end
            paintIcon(); Connect(tab.IconRing:GetPropertyChangedSignal("Color"),paintIcon)
        else
            local ring=New("Frame",{Size=UDim2.fromOffset(10,10),Position=UDim2.fromOffset(2,2),BackgroundTransparency=1,Parent=iconHolder})
            Corner(ring,parentTab and 5 or 3); tab.IconRing=Stroke(ring,Theme.Dimmer,1.2)
        end
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
    for _,h in ipairs(self.UnloadHooks or {}) do pcall(h) end
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
    ["Glowing particles"] = "video:glow",
    ["Triangles"] = "anim:tri",
    ["Constellation"] = "anim:net",
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
            if (k=="bulletTracerColor" or k=="chinaHatColor" or k=="laserColor" or k=="laser2Color" or k=="uiAccent" or k=="uiLine" or k=="tracerCol" or k=="tracerCol2" or k=="sidebarColor" or k=="espBoxColor" or k=="wingsColor" or k=="triColor" or k=="netDotColor" or k=="netLineColor") and type(v)=="table" then v=Color3.new(v[1],v[2],v[3]) end
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
            if (k=="bulletTracerColor" or k=="chinaHatColor" or k=="laserColor" or k=="laser2Color" or k=="uiAccent" or k=="uiLine" or k=="tracerCol" or k=="tracerCol2" or k=="sidebarColor" or k=="espBoxColor" or k=="wingsColor" or k=="triColor" or k=="netDotColor" or k=="netLineColor") and type(v)=="table" then v=Color3.new(v[1],v[2],v[3]) end
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
    if not hum or hum.Health <= 0 then return false end
    local bp = plr:FindFirstChild("Backpack")
    local hk = (ch and ch:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
    if hk then return true end
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
    playerAuraOn=false, playerAuraColor=Color3.new(1,1,1), playerAuraPart=nil, playerAuraLight=nil,
    tracersOn=false, touchFlingOn=false, tradeHelperOn=(CFG.tradeHelperOn~=false),
    coinFarmOn=false, stopFarm=false,
    farmSpeed=23,
    zombieAutoKill=false, zombieAutoShoot=false,
    skeletonESP=CFG.espSkeleton,
    boxESP=CFG.espBox,
    antiLagOn=CFG.antiLag,
    speedGlitch=false, glitchSpeed=200, boostActive=false,
    candyESP=false, infJump=false, farmClip=false,
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

Library.Lite = CFG.lite == true
local Win = Library:CreateWindow({Logo=ASSETS.logo, Background=(function() local b=BG_LIST[CFG.bgName]; if type(b)=="string" and (b:find("^video:") or b:find("^anim:")) then return ASSETS.background end; return b or ASSETS.background end)(), Keybind=Enum.KeyCode.RightShift, Size=Vector2.new(460,460), SidebarWidth=140, ToggleButton=false})
Win.UIScale.Scale = CFG.uiScale / 100
Win._baseScale = CFG.uiScale / 100

local WmGui=New("ScreenGui",{Name="PiddleWatermark",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1000})
WmGui.Parent=GetGuiParent()

local wmFrame=New("Frame",{Parent=WmGui,Size=UDim2.fromOffset(290,38),Position=UDim2.fromOffset(12,12),BackgroundColor3=Theme.Window,ClipsDescendants=true,Active=true})
Corner(wmFrame,10); Stroke(wmFrame,Theme.Stroke)
local wmBg=New("ImageLabel",{Parent=wmFrame,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=(function() local b=BG_LIST[CFG.bgName]; if type(b)=="string" and (b:find("^video:") or b:find("^anim:")) then return "" end; return b end)(),ImageTransparency=0.5,ScaleType=Enum.ScaleType.Crop}); Corner(wmBg,10)
local wmBtn=New("TextButton",{Parent=wmFrame,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=10})
do
    local function lbl(x,w,text,size,col,bold,align) return New("TextLabel",{Parent=wmFrame,Size=UDim2.new(0,w,1,0),Position=UDim2.fromOffset(x,0),BackgroundTransparency=1,Text=text,Font=bold and Theme.FontBold or Theme.Font,TextSize=size,TextColor3=col,TextXAlignment=align or Enum.TextXAlignment.Left}) end
    New("ImageLabel",{Parent=wmFrame,Size=UDim2.fromOffset(26,26),Position=UDim2.fromOffset(8,6),BackgroundTransparency=1,Image=ResolveImage(ASSETS.logo),ImageColor3=Color3.new(1,1,1),ScaleType=Enum.ScaleType.Fit})
    lbl(40,62,"PIDDLE",14,Theme.Text,true)
    lbl(98,30,"MM2",10,Theme.Dim,false)
    local function divider(x) New("Frame",{Parent=wmFrame,Size=UDim2.fromOffset(1,16),Position=UDim2.fromOffset(x,11),BackgroundColor3=Theme.Stroke,BorderSizePixel=0}) end
    divider(134)
    -- pulse (heartbeat) picture instead of the "fps" text: stays in place, only changes colour
    local pulse=New("Frame",{Parent=wmFrame,Size=UDim2.fromOffset(20,14),Position=UDim2.fromOffset(146,12),BackgroundTransparency=1})
    local pulseBars={}
    local ecg={{0,7},{4.5,7},{7,1.5},{10.5,12.5},{13.5,4},{15.5,7},{20,7}}
    for i=1,#ecg-1 do
        local x1,y1,x2,y2=ecg[i][1],ecg[i][2],ecg[i+1][1],ecg[i+1][2]
        local len=math.sqrt((x2-x1)^2+(y2-y1)^2)
        local b=New("Frame",{Parent=pulse,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Size=UDim2.fromOffset(len+0.7,1.7),Rotation=math.deg(math.atan2(y2-y1,x2-x1)),BackgroundColor3=Theme.Dim,BorderSizePixel=0})
        New("UICorner",{CornerRadius=UDim.new(0.5,0),Parent=b})
        pulseBars[#pulseBars+1]=b
    end
    local wmFps=lbl(172,36,"--",13,Theme.Text,true)
    divider(212)
    -- signal-strength picture instead of the "ms" text
    local sig=New("Frame",{Parent=wmFrame,Size=UDim2.fromOffset(17,13),Position=UDim2.fromOffset(222,12),BackgroundTransparency=1})
    local sigBars={}
    for i=1,4 do
        local h=3*i
        local b=New("Frame",{Parent=sig,Size=UDim2.fromOffset(3.4,h),Position=UDim2.fromOffset((i-1)*4.6,13-h),BackgroundColor3=Theme.Dimmer,BorderSizePixel=0})
        New("UICorner",{CornerRadius=UDim.new(0,1),Parent=b})
        sigBars[i]=b
    end
    local wmPing=lbl(246,40,"--",13,Theme.Text,true)
    local frames,acc=0,0
    Connect(RunService.RenderStepped,function(dt) frames=frames+1; acc=acc+dt end)
    task.spawn(function()
        while not Library.Unloaded do
            task.wait(Library.Lite and 2 or 0.8)
            local fps=0
            if acc>0 then fps=math.floor(frames/acc+0.5) end
            frames,acc=0,0
            local ping=0; pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            wmFps.Text=tostring(fps); wmPing.Text=tostring(ping)
            local fc=fps>=50 and Color3.fromRGB(90,220,120) or (fps>=30 and Color3.fromRGB(255,200,80) or Color3.fromRGB(240,90,100))
            -- the pulse never moves or scales: it flashes bright on every beat and settles back to the fps colour
            for _,b in ipairs(pulseBars) do b.BackgroundColor3=Color3.new(1,1,1); Tween(b,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3=fc}) end
            local n=ping<=70 and 4 or (ping<=120 and 3 or (ping<=200 and 2 or 1))
            local pc=n>=4 and Color3.fromRGB(90,220,120) or (n==3 and Color3.fromRGB(170,220,90) or (n==2 and Color3.fromRGB(255,170,70) or Color3.fromRGB(240,90,100)))
            for i,b in ipairs(sigBars) do b.BackgroundColor3=i<=n and pc or Theme.Dimmer end
        end
    end)
end

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
                                G.shot(o, t, G.impact, G.muzzle)
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
            if G.on and G.build then G.shot(o, t, G.impact, G.muzzle) end
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

-- ===== smarter prediction: velocity tracker + bullet speed calibration + intercept solver =====
X.TRK = setmetatable({}, {__mode="k"})
X.BULLET = {speed=220, auto=true, samples=0}
X.predStrength = 1
X.smartTiming = true
X.trkTick = 0
Connect(RunService.Heartbeat, function()
    X.trkTick = X.trkTick + 1
    if X.trkTick % 2 == 1 then return end            -- ~30 Hz is enough to estimate velocity
    local now = os.clock()
    for _, p in ipairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local t = X.TRK[p]
            if not t then t = {}; X.TRK[p] = t end
            t[#t + 1] = {now, hrp.Position}
            while #t > 0 and now - t[1][1] > 0.6 do table.remove(t, 1) end
        end
    end
end)
function X.TRKspan(t, from, to)
    -- average velocity between samples aged [from..to] seconds
    local now = os.clock()
    local a, b
    for i = #t, 1, -1 do
        local age = now - t[i][1]
        if not b and age >= from then b = t[i] end
        if age >= to then a = t[i]; break end
    end
    if a and b and b[1] - a[1] > 0.03 then return (b[2] - a[2]) / (b[1] - a[1]) end
end
function X.TRK.vel(plr)
    local t = X.TRK[plr]
    if not t or #t < 3 then return nil end
    return X.TRKspan(t, 0, 0.22) or X.TRKspan(t, 0, 0.4)
end
function X.TRK.reversing(plr)
    local t = X.TRK[plr]
    if not t or #t < 8 then return false end
    local v1, v0 = X.TRKspan(t, 0, 0.14), X.TRKspan(t, 0.14, 0.3)
    if not v1 or not v0 then return false end
    local f1, f0 = Vector3.new(v1.X, 0, v1.Z), Vector3.new(v0.X, 0, v0.Z)
    if f1.Magnitude < 5 or f0.Magnitude < 5 then return false end
    return f1.Unit:Dot(f0.Unit) < -0.2
end
Connect(WS.DescendantAdded, function(o)
    if not State.predictMovement or not X.BULLET.auto or not o:IsA("BasePart") then return end
    local nm = o.Name:lower()
    if not (nm:find("bullet", 1, true) or nm:find("projectile", 1, true)) then return end
    task.spawn(function()
        local p0, t0 = o.Position, os.clock()
        task.wait(0.06)
        if not o.Parent then return end
        local dt = os.clock() - t0
        local sp = (o.Position - p0).Magnitude / math.max(dt, 0.01)
        if sp > 60 and sp < 1500 then
            local B = X.BULLET
            B.speed = B.samples == 0 and sp or (B.speed * 0.7 + sp * 0.3)
            B.samples = B.samples + 1
        end
    end)
end)

function X.aimPoint(tch)
    local hrp = tch:FindFirstChild("HumanoidRootPart")
    local hum = tch:FindFirstChildOfClass("Humanoid")
    if not hrp then return nil end
    local plr = Players:GetPlayerFromCharacter(tch)
    local myc = LocalPlayer.Character
    local myHead = myc and (myc:FindFirstChild("Head") or myc:FindFirstChild("HumanoidRootPart"))
    local origin = myHead and myHead.Position or Cam.CFrame.Position
    local pos = hrp.Position
    local ws = hum and math.min(hum.WalkSpeed, 40) or 16
    local v = (plr and X.TRK.vel(plr)) or hrp.AssemblyLinearVelocity
    local md = hum and hum.MoveDirection or Vector3.zero
    local fx, fz
    if md.Magnitude < 0.05 then fx, fz = v.X * 0.2, v.Z * 0.2
    else fx, fz = v.X * 0.55 + md.X * ws * 0.45, v.Z * 0.55 + md.Z * ws * 0.45 end
    local flat = Vector3.new(fx, 0, fz)
    local cap = math.max(ws * 1.35, 20)
    if flat.Magnitude > cap then flat = flat.Unit * cap end
    local air = hum and hum.FloorMaterial == Enum.Material.Air
    local vy = air and math.clamp(v.Y, -70, 70) or 0
    local bs = math.max(X.BULLET.speed, 60)
    local lat = (PING + 0.05) * X.predStrength
    local t = ((pos - origin).Magnitude / bs) + lat
    local P = pos
    for _ = 1, 4 do
        local tt = t * X.predStrength
        local y = air and (vy * tt - 0.5 * 196.2 * tt * tt) or 0
        P = pos + Vector3.new(flat.X * tt, y, flat.Z * tt)
        t = ((P - origin).Magnitude / bs) + lat
    end
    -- don't aim through geometry the target can't walk through
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {myc, tch, Cam}
    local d = P - pos
    if d.Magnitude > 0.5 then
        local hit = WS:Raycast(pos, d, rp)
        if hit then P = hit.Position - d.Unit * 0.8 end
    end
    return P + Vector3.new(0, 0.2, 0)
end

local function preciseAim(targetPart, targetChar)
    local ch = LocalPlayer.Character
    if not ch then return end
    local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local origin = head.Position
    local aimPos = targetPart.Position
    if State.predictMovement and targetChar then
        aimPos = X.aimPoint(targetChar) or aimPos
    end
    return origin, aimPos
end

function fireGunWallbang(targetPos, targetPart)
    local ch = LocalPlayer.Character; if not ch then return end
    if getRole(LocalPlayer) == "Murderer" then return end
    local g = getGun(); if not g then return end
    if g.Parent ~= ch then
        if X.eqBusy then return end
        X.eqBusy = true
        local hum0 = ch:FindFirstChildOfClass("Humanoid")
        if hum0 then pcall(function() hum0:EquipTool(g) end) end
        local t0 = os.clock()
        while g.Parent ~= ch and os.clock() - t0 < 0.4 do task.wait() end
        X.eqBusy = false
        if g.Parent ~= ch then return end
    end
    local shoot = g:FindFirstChild("Shoot") or g:FindFirstChild("Fire") or g:FindFirstChild("ShootGun")
    if not shoot then
        local ev = g:FindFirstChild("Events") or g:FindFirstChild("Remotes")
        if ev then shoot = ev:FindFirstChild("Shoot") or ev:FindFirstChild("Fire") or ev:FindFirstChild("ShootGun") end
    end
    local head = ch:FindFirstChild("Head"); if not head then return end
    local origin = head.Position
    if State.shootThroughWalls and targetPart then
        origin = BT.wallOrigin(head.Position, targetPos, targetPart.Parent)
    end
    if shoot then
        pcall(function() shoot:FireServer(CFrame.new(origin, targetPos), CFrame.new(targetPos)) end)
    else
        pcall(function() g:Activate() end)
    end
    if getgenv().__NoirTracers and getgenv().__NoirTracers.on and getgenv().__NoirTracers.build then
        getgenv().__NoirTracers.shot(origin, targetPos, getgenv().__NoirTracers.impact, getgenv().__NoirTracers.muzzle)
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
        if now - X.autoShootCd < 0.25 then return end

        local target = findMurderer()
        local tch = target and target.Character
        if not (tch and tch:FindFirstChild("HumanoidRootPart")) then
            local myHead = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
            if myHead then
                local best, bd = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and not isRealNpc(p) then
                        local ph = p.Character:FindFirstChildOfClass("Humanoid")
                        local pr = p.Character:FindFirstChild("HumanoidRootPart")
                        if ph and pr and ph.Health > 0 and hasItem(p, "Knife") then
                            local d = (pr.Position - myHead.Position).Magnitude
                            if d < bd then bd = d; best = p end
                        end
                    end
                end
                if best then target = best; tch = best.Character end
            end
        end
        if not (tch and tch:FindFirstChild("HumanoidRootPart")) then return end

        local th    = tch:FindFirstChildOfClass("Humanoid")
        local tr    = tch:FindFirstChild("HumanoidRootPart")
        local tHead = tch:FindFirstChild("Head")
        if not th or th.Health <= 0 or not tr then return end

        if g.Parent ~= ch then pcall(function() hum:EquipTool(g) end); return end

        local shoot = g:FindFirstChild("Shoot")
            or g:FindFirstChild("Fire")
            or g:FindFirstChild("ShootGun")
        if not shoot then
            local ev = g:FindFirstChild("Events") or g:FindFirstChild("Remotes")
            if ev then
                shoot = ev:FindFirstChild("Shoot") or ev:FindFirstChild("Fire") or ev:FindFirstChild("ShootGun")
            end
        end

        local origin, aimPos = preciseAim(tHead or tr, tch)
        if not (origin and aimPos) then return end
        if State.predictMovement and X.smartTiming and target and X.TRK.reversing(target) then
            X.holdSince = X.holdSince or now
            if now - X.holdSince < 0.35 then return end
        end
        X.holdSince = nil
        X.autoShootCd = now

        if State.shootThroughWalls then
            origin = BT.wallOrigin(origin, aimPos, tch)
        end

        if shoot then
            pcall(function() shoot:FireServer(CFrame.new(origin, aimPos), CFrame.new(aimPos)) end)
        else
            pcall(function() g:Activate() end)
        end

        if getgenv().__NoirTracers and getgenv().__NoirTracers.on and getgenv().__NoirTracers.build then
            getgenv().__NoirTracers.shot(origin, aimPos, getgenv().__NoirTracers.impact, getgenv().__NoirTracers.muzzle)
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
        if hd then
            local ap = State.predictMovement and X.aimPoint(m.Character) or hd.Position
            Cam.CFrame=CFrame.lookAt(Cam.CFrame.Position,ap)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not State.aimlockZombie then return end
    local ch=LocalPlayer.Character; if not ch then return end
    local myHead=ch:FindFirstChild("Head"); if not myHead then return end
    local closest,cd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not isRealNpc(p) and hasItem(p,"Knife") and getRole(p)~="Murderer" then
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

X.zShootCd = 0
RunService.RenderStepped:Connect(function()
    if not State.zombieAutoShoot then return end
    if os.clock() - X.zShootCd < 0.25 then return end
    local ch=LocalPlayer.Character; if not ch then return end
    local myHead=ch:FindFirstChild("Head"); if not myHead then return end
    local closest,cd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not isRealNpc(p) and hasItem(p,"Knife") then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChildOfClass("Humanoid")
            if tr and h and h.Health>0 then
                local d=(tr.Position-myHead.Position).Magnitude
                if d<cd then cd=d; closest=p end
            end
        end
    end
    if closest and closest.Character then
        local tr=closest.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            X.zShootCd = os.clock()
            local targetPos = X.aimPoint(closest.Character) or tr.Position
            task.spawn(fireGunWallbang, targetPos, tr)
        end
    end
end)

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

State.flySpeed = tonumber(CFG.flySpeed) or 40
local function updateFly()
    local ch=LocalPlayer.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if State.flying and hrp and hum then
        if not State.flyBV or State.flyBV.Parent~=hrp then
            if State.flyBV then pcall(function() State.flyBV:Destroy() end) end
            if State.flyBG then pcall(function() State.flyBG:Destroy() end) end
            State.flyBV=Instance.new("BodyVelocity"); State.flyBV.Parent=hrp; State.flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); State.flyBV.Velocity=Vector3.new()
            State.flyBG=Instance.new("BodyGyro"); State.flyBG.Parent=hrp; State.flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); State.flyBG.P=1000
        end
        local dir=Vector3.new()
        if not (X.MG and X.MG.frozen) then
            local md=hum.MoveDirection
            if md.Magnitude>0.1 then
                local look, rightV = Cam.CFrame.LookVector, Cam.CFrame.RightVector
                local flatF = Vector3.new(look.X,0,look.Z); flatF = flatF.Magnitude>0.01 and flatF.Unit or Vector3.new(0,0,-1)
                local flatR = Vector3.new(rightV.X,0,rightV.Z); flatR = flatR.Magnitude>0.01 and flatR.Unit or Vector3.new(1,0,0)
                dir = look*md:Dot(flatF) + rightV*md:Dot(flatR)
            end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then dir=dir-Vector3.new(0,1,0) end
        end
        local spd = State.flySpeed or 40
        State.flyBV.Velocity = dir.Magnitude>0.05 and dir.Unit*spd or Vector3.new()
        State.flyBG.CFrame=Cam.CFrame
    elseif not State.flying then
        if State.flyBV then pcall(function() State.flyBV:Destroy() end); State.flyBV=nil end
        if State.flyBG then pcall(function() State.flyBG:Destroy() end); State.flyBG=nil end
    end
end
Connect(RunService.RenderStepped, updateFly)

Connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.ButtonA and State.flying and State.flyBV then
        State.flyBV.Velocity = Vector3.new(0, State.flySpeed or 40, 0)
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

X.AURA = {part=nil, size=7}
function X.AURA.destroy()
    if X.AURA.part then pcall(function() X.AURA.part:Destroy() end) end
    X.AURA.part = nil
    State.playerAuraPart, State.playerAuraLight = nil, nil
end
function X.AURA.ensure()
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    local p = X.AURA.part
    if p and p.Parent == ch then return p end
    X.AURA.destroy()
    p = Instance.new("Part")
    p.Name = "PiddleAura"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(X.AURA.size, X.AURA.size, X.AURA.size)
    p.Material = Enum.Material.Neon
    p.Color = State.playerAuraColor
    p.Transparency = 0.78
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.CastShadow = false
    p.CFrame = root.CFrame
    p.Parent = ch
    local w = Instance.new("WeldConstraint")
    w.Part0 = root
    w.Part1 = p
    w.Parent = p
    local light = Instance.new("PointLight")
    light.Color = State.playerAuraColor
    light.Range = 14
    light.Brightness = 2.5
    light.Parent = p
    local em = Instance.new("ParticleEmitter")
    em.Name = "AuraSparks"
    em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    em.Color = ColorSequence.new(State.playerAuraColor:Lerp(Color3.new(1, 1, 1), 0.5), State.playerAuraColor)
    em.LightEmission = 1
    em.LightInfluence = 0
    em.Rate = 28
    em.Lifetime = NumberRange.new(1, 1.8)
    em.Speed = NumberRange.new(1, 3)
    em.SpreadAngle = Vector2.new(180, 180)
    em.Acceleration = Vector3.new(0, 3, 0)
    em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
    em.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    em.Parent = p
    X.AURA.part = p
    State.playerAuraPart, State.playerAuraLight = p, light
    return p
end
function X.AURA.recolor(c)
    local p = X.AURA.part
    if not p or not p.Parent then return end
    p.Color = c
    local l = p:FindFirstChildOfClass("PointLight")
    if l then l.Color = c end
    local em = p:FindFirstChild("AuraSparks")
    if em then em.Color = ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.5), c) end
end
task.spawn(function()
    local t = 0
    while true do
        local dt = task.wait(0.1)
        if State.playerAuraOn then
            pcall(function()
                local p = X.AURA.ensure()
                if p then
                    t = t + (dt or 0.1)
                    local s = X.AURA.size * (1 + 0.05 * math.sin(t * 2.2))
                    p.Size = Vector3.new(s, s, s)
                end
            end)
        elseif X.AURA.part then
            X.AURA.destroy()
        end
    end
end)
Connect(LocalPlayer.CharacterAdded, function()
    X.AURA.part = nil
    State.playerAuraPart, State.playerAuraLight = nil, nil
end)
-- ===== ASSET LOADER (shared by wings + aura) =====
X.ASSET = {cache = {}, loading = {}}
function X.ASSET.get(id, cb)
    local c = X.ASSET.cache[id]
    if c then return c, "ok" end
    if c == false then return nil, "failed" end
    if not X.ASSET.loading[id] then
        X.ASSET.loading[id] = true
        task.spawn(function()
            local obj
            pcall(function() local r = game:GetObjects("rbxassetid://" .. id); obj = r and r[1] end)
            if not obj then pcall(function() local m = InsertService:LoadAsset(tonumber(id)); obj = m and (m:GetChildren()[1] or m) end) end
            X.ASSET.cache[id] = obj or false
            X.ASSET.loading[id] = nil
            if cb then pcall(cb, obj) end
        end)
    end
    return nil, "loading"
end
function X.ASSET.prep(root)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true; d.Anchored = false
        elseif d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") or d:IsA("ManualWeld") or d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
    end
end
-- weld every part of `clone` to a root part keeping the template's relative layout
function X.ASSET.rig(clone)
    local parts = {}
    if clone:IsA("BasePart") then parts[1] = clone end
    for _, d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then parts[#parts + 1] = d end end
    if #parts == 0 then return nil end
    local root = (clone:IsA("Model") and clone.PrimaryPart) or clone:FindFirstChild("Handle") or parts[1]
    if not root or not root:IsA("BasePart") then root = parts[1] end
    local rel = {}
    for _, p in ipairs(parts) do if p ~= root then rel[p] = root.CFrame:ToObjectSpace(p.CFrame) end end
    X.ASSET.prep(clone)
    for p, cf in pairs(rel) do
        local w = Instance.new("Weld"); w.Part0 = root; w.Part1 = p; w.C0 = cf; w.Parent = p
    end
    return root, parts
end
X.ASSET.BODY = {Head=1, Torso=1, UpperTorso=1, LowerTorso=1, HumanoidRootPart=1, ["Left Arm"]=1, ["Right Arm"]=1, ["Left Leg"]=1, ["Right Leg"]=1,
    LeftUpperArm=1, LeftLowerArm=1, LeftHand=1, RightUpperArm=1, RightLowerArm=1, RightHand=1, LeftUpperLeg=1, LeftLowerLeg=1, LeftFoot=1, RightUpperLeg=1, RightLowerLeg=1, RightFoot=1}
-- pulls ONLY the wing pieces out of an asset (a character-style asset also carries a white body we must not copy)
function X.ASSET.extract(tpl)
    local acc = {}
    if tpl:IsA("Accessory") then acc[1] = tpl end
    for _, d in ipairs(tpl:GetDescendants()) do if d:IsA("Accessory") then acc[#acc + 1] = d end end
    local named = {}
    for _, a in ipairs(acc) do if string.find(string.lower(a.Name), "wing", 1, true) then named[#named + 1] = a end end
    if #named > 0 then acc = named end
    if #acc > 0 then return "acc", acc end
    local parts = {}
    local function consider(d) if d:IsA("BasePart") and not X.ASSET.BODY[d.Name] then parts[#parts + 1] = d end end
    consider(tpl)
    for _, d in ipairs(tpl:GetDescendants()) do consider(d) end
    local wp = {}
    for _, p in ipairs(parts) do
        local nm = string.lower(p.Name .. (p.Parent and p.Parent.Name or ""))
        if string.find(nm, "wing", 1, true) then wp[#wp + 1] = p end
    end
    if #wp > 0 then parts = wp end
    if #parts > 0 then return "parts", parts end
    return nil
end
function X.ASSET.solidify(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("MeshPart") then d.TextureID = ""; d.Material = Enum.Material.Neon
        elseif d:IsA("BasePart") then d.Material = Enum.Material.Neon
        elseif d:IsA("SpecialMesh") then d.TextureId = ""
        elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
    end
    if inst:IsA("MeshPart") then inst.TextureID = ""; inst.Material = Enum.Material.Neon end
end

-- ===== PLAYER AURA: WINGS =====
X.WINGS = {on=false, color=(typeof(CFG.wingsColor)=="Color3" and CFG.wingsColor) or Color3.new(1,1,1), size=1, speed=3, rainbow=false, model=nil, feathers={}, t=0, chk=0,
    assetId="118272429961434", flip=false, solid=true, custom=nil, accs={}}
;(function()
local W = X.WINGS
local LEN  = {2.3, 3.0, 3.6, 4.0, 3.7, 3.1, 2.4}
local ELEV = {1.30, 1.05, 0.80, 0.55, 0.30, 0.05, -0.20}
function W.destroy()
    for _, a in ipairs(W.accs) do pcall(function() a:Destroy() end) end
    W.accs = {}
    if W.model then pcall(function() W.model:Destroy() end) end
    W.model = nil; W.feathers = {}; W.custom = nil; W.rootWeld = nil
end
local function featherColor(i)
    if W.rainbow then return Color3.fromHSV((W.t * 0.25 + i * 0.045) % 1, 0.75, 1) end
    return W.color:Lerp(Color3.new(1, 1, 1), (i - 1) / 14)
end
local function tintCustom(col, rainbow)
    local idx = 0
    local function paint(d)
        if d:IsA("BasePart") then
            idx = idx + 1
            d.Color = rainbow and Color3.fromHSV((W.t * 0.25 + idx * 0.05) % 1, 0.75, 1) or col
        end
    end
    for _, a in ipairs(W.accs) do paint(a); for _, d in ipairs(a:GetDescendants()) do paint(d) end end
    if W.model then paint(W.model); for _, d in ipairs(W.model:GetDescendants()) do paint(d) end end
end
function W.buildCustom(tpl, ch, hum, torso)
    local kind, list = X.ASSET.extract(tpl)
    if not kind then return false end
    if kind == "acc" then
        for _, a in ipairs(list) do
            local clone = a:Clone()
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("BasePart") then d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true end
            end
            local h = clone:FindFirstChild("Handle")
            if h and W.size ~= 1 then pcall(function() h.Size = h.Size * W.size end) end
            if W.solid then X.ASSET.solidify(clone) end
            hum:AddAccessory(clone)
            W.accs[#W.accs + 1] = clone
        end
        W.custom = "acc"
        return true
    end
    -- loose parts: clone only the wing pieces and weld them to our torso
    local holder = Instance.new("Model"); holder.Name = "PiddleWings"
    local first = list[1]
    local clones = {}
    for _, p in ipairs(list) do
        local c = p:Clone()
        c.Parent = holder
        clones[p] = c
    end
    X.ASSET.prep(holder)
    local root = clones[first]
    local s = W.size
    if s ~= 1 then for _, c in pairs(clones) do if c:IsA("BasePart") then c.Size = c.Size * s end end end
    for p, c in pairs(clones) do
        if c ~= root then
            local rel = first.CFrame:ToObjectSpace(p.CFrame)
            local w = Instance.new("Weld"); w.Part0 = root; w.Part1 = c
            w.C0 = CFrame.new(rel.Position * s) * (rel - rel.Position); w.Parent = c
        end
    end
    if W.solid then X.ASSET.solidify(holder) end
    root.CFrame = torso.CFrame
    local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = root; w.Parent = root
    W.base = CFrame.new(0, 0.4, 0.55) * CFrame.Angles(0, W.flip and math.pi or 0, 0)
    w.C0 = W.base
    holder.Parent = ch
    W.model = holder; W.custom = "model"; W.rootWeld = w
    return true
end
function W.build()
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
    if not ch or not hum or hum.Health <= 0 or not torso then return end
    W.destroy()
    local tpl, st = X.ASSET.get(W.assetId, function() W.chk = 0 end)
    if st == "loading" then return end
    if tpl and W.buildCustom(tpl, ch, hum, torso) then
        tintCustom(W.color, W.rainbow)
        return
    end
    local m = Instance.new("Model"); m.Name = "PiddleWings"
    local feathers = {}
    for _, side in ipairs({-1, 1}) do
        for i = 1, #LEN do
            local len = LEN[i] * W.size
            local p = Instance.new("Part")
            p.Name = "Feather"; p.Size = Vector3.new(len, 0.12, 0.55 * W.size)
            p.Material = Enum.Material.Neon; p.Color = featherColor(i); p.Transparency = 0.15
            p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = false
            p.CFrame = torso.CFrame
            p.Parent = m
            local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = p; w.Parent = p
            feathers[#feathers + 1] = {part = p, weld = w, side = side, i = i, len = len}
        end
    end
    m.Parent = ch
    W.model = m; W.feathers = feathers
end
function W.recolor()
    if W.custom then tintCustom(W.color, false); return end
    for _, f in ipairs(W.feathers) do if f.part.Parent then f.part.Color = featherColor(f.i) end end
end
local function alive()
    if W.custom == "acc" then
        local a = W.accs[1]
        return a and a.Parent == LocalPlayer.Character
    end
    return W.model and W.model.Parent and W.model.Parent == LocalPlayer.Character
end
Connect(RunService.RenderStepped, function(dt)
    if not W.on then
        if W.model or #W.accs > 0 then W.destroy() end
        return
    end
    W.t = W.t + (dt or 0.016)
    if not alive() then
        if os.clock() - W.chk < 0.5 then return end
        W.chk = os.clock(); pcall(W.build)
        if not alive() then return end
    end
    if W.custom == "acc" then
        if W.rainbow then tintCustom(W.color, true) end
        return
    end
    if W.custom == "model" then
        if W.rootWeld and W.base then W.rootWeld.C0 = W.base * CFrame.new(0, math.sin(W.t * W.speed) * 0.15, 0) end
        if W.rainbow then tintCustom(W.color, true) end
        return
    end
    local flap = math.sin(W.t * W.speed) * 0.32
    for _, f in ipairs(W.feathers) do
        local s = f.side
        local a = ELEV[f.i] + flap * (1 - (f.i - 1) * 0.07)
        local cf = CFrame.new(0.35 * s, 0.5, 0.55) * CFrame.Angles(0, -s * (0.30 + 0.05 * f.i), 0) * CFrame.Angles(0, 0, s * a) * CFrame.new(s * f.len / 2, 0, 0)
        f.weld.C0 = cf
        if W.rainbow then f.part.Color = featherColor(f.i) end
    end
end)
Connect(LocalPlayer.CharacterAdded, function() W.model = nil; W.feathers = {}; W.custom = nil; W.accs = {}; W.rootWeld = nil end)
end)()

-- ===== PLAYER AURA (made by the script): orbiting orbs with trails, ground halo, sparks, glow =====
X.AURA.rainbow = false
X.AURA.orbs = {}
X.AURA.NORBS = 10
function X.AURA.colorFor(i, t)
    if X.AURA.rainbow then return Color3.fromHSV(((t or 0) * 0.2 + (i or 0) * 0.07) % 1, 0.8, 1) end
    return State.playerAuraColor
end
function X.AURA.ensure()
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    local p = X.AURA.part
    if p and p.Parent == ch then return p end
    X.AURA.destroy()
    local col = X.AURA.colorFor(0, 0)
    p = Instance.new("Part")
    p.Name = "PiddleAura"; p.Shape = Enum.PartType.Ball; p.Size = Vector3.new(1, 1, 1); p.Transparency = 1
    p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = false
    p.CFrame = root.CFrame
    p.Parent = ch
    local w = Instance.new("Weld"); w.Part0 = root; w.Part1 = p; w.Parent = p
    local R = math.max(X.AURA.size * 0.32, 1.6)
    X.AURA.orbs = {}
    for i = 1, X.AURA.NORBS do
        local o = Instance.new("Part")
        o.Name = "PiddleOrb"; o.Shape = Enum.PartType.Ball; o.Size = Vector3.new(0.42, 0.42, 0.42); o.Material = Enum.Material.Neon; o.Color = col
        o.CanCollide = false; o.CanQuery = false; o.CanTouch = false; o.Massless = true; o.CastShadow = false
        o.CFrame = p.CFrame; o.Parent = p
        local ow = Instance.new("Weld"); ow.Part0 = p; ow.Part1 = o; ow.Parent = o
        local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.21, 0); a0.Parent = o
        local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.21, 0); a1.Parent = o
        local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.5; tr.MinLength = 0.05; tr.FaceCamera = true
        tr.LightEmission = 1; tr.Color = ColorSequence.new(col); tr.Transparency = NumberSequence.new(0.15, 1)
        tr.WidthScale = NumberSequence.new(1, 0); tr.Parent = o
        X.AURA.orbs[i] = {part = o, weld = ow, trail = tr}
    end
    local d = Instance.new("Part")
    d.Name = "PiddleHalo"; d.Shape = Enum.PartType.Cylinder; d.Size = Vector3.new(0.1, R * 2, R * 2); d.Material = Enum.Material.Neon; d.Color = col; d.Transparency = 0.55
    d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true; d.CastShadow = false
    d.CFrame = p.CFrame; d.Parent = p
    local dw = Instance.new("Weld"); dw.Part0 = p; dw.Part1 = d; dw.C0 = CFrame.new(0, -2.95, 0) * CFrame.Angles(0, 0, math.pi / 2); dw.Parent = d
    X.AURA.halo = {part = d, weld = dw}
    local light = Instance.new("PointLight"); light.Color = col; light.Range = 12; light.Brightness = 1.8; light.Parent = p
    local em = Instance.new("ParticleEmitter")
    em.Name = "AuraSparks"; em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    em.Color = ColorSequence.new(col); em.LightEmission = 1; em.LightInfluence = 0; em.Rate = 12
    em.Lifetime = NumberRange.new(1, 1.6); em.Speed = NumberRange.new(0.5, 2); em.SpreadAngle = Vector2.new(180, 180); em.Acceleration = Vector3.new(0, 3, 0)
    em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0)})
    em.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}); em.Parent = p
    X.AURA.part = p; X.AURA.R = R
    State.playerAuraPart, State.playerAuraLight = p, light
    return p
end
function X.AURA.recolor(c)
    State.playerAuraColor = c
    local p = X.AURA.part
    if not p or not p.Parent then return end
    for _, o in ipairs(X.AURA.orbs) do o.part.Color = c; o.trail.Color = ColorSequence.new(c) end
    if X.AURA.halo then X.AURA.halo.part.Color = c end
    local l = p:FindFirstChildOfClass("PointLight"); if l then l.Color = c end
    local em = p:FindFirstChild("AuraSparks"); if em then em.Color = ColorSequence.new(c) end
end
do
    local t = 0
    Connect(RunService.RenderStepped, function(dt)
        local p = X.AURA.part
        if not p or not p.Parent or not State.playerAuraOn then return end
        t = t + (dt or 0.016)
        local R = X.AURA.R or 2
        for i, o in ipairs(X.AURA.orbs) do
            if o.part.Parent then
                local a
                local pos
                if i % 2 == 0 then
                    a = t * 1.7 + i * (math.pi * 2 / X.AURA.NORBS)
                    pos = Vector3.new(math.cos(a) * R, -0.4 + math.sin(a * 2) * 0.3, math.sin(a) * R)
                else
                    a = -t * 1.3 + i * (math.pi * 2 / X.AURA.NORBS)
                    local rr, tilt = R * 0.9, math.rad(58)
                    pos = Vector3.new(math.cos(a) * rr, math.sin(a) * rr * math.cos(tilt), math.sin(a) * rr * math.sin(tilt))
                end
                o.weld.C0 = CFrame.new(pos)
            end
        end
        if X.AURA.halo and X.AURA.halo.part.Parent then
            X.AURA.halo.part.Transparency = 0.5 + math.sin(t * 2.2) * 0.15
            X.AURA.halo.weld.C0 = CFrame.new(0, -2.95, 0) * CFrame.Angles(0, t * 0.8, math.pi / 2)
        end
        if X.AURA.rainbow then
            for i, o in ipairs(X.AURA.orbs) do local c = X.AURA.colorFor(i, t); o.part.Color = c; o.trail.Color = ColorSequence.new(c) end
            if X.AURA.halo then X.AURA.halo.part.Color = X.AURA.colorFor(0, t) end
        end
    end)
end
function X.AURA.destroy()
    if X.AURA.part then pcall(function() X.AURA.part:Destroy() end) end
    X.AURA.part = nil; X.AURA.orbs = {}; X.AURA.halo = nil
    State.playerAuraPart, State.playerAuraLight = nil, nil
end

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
    end
    if tracers[p] then pcall(function() tracers[p].Visible=false end); tracers[p]=nil end
    destroySkeleton(p)
    espP[p]=nil
    if X.BoxESPRemove then pcall(X.BoxESPRemove, p) end
end)
task.spawn(function()
    while true do
        task.wait(0.15)
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                pcall(function()
                    local d=p.Character:FindFirstChild("PiddleHighlight")
                    local t=p.Character:FindFirstChild("PiddleTag")
                    if (not d or not t) and p.Character:FindFirstChild("Head") then
                        buildESP(p); d=p.Character:FindFirstChild("PiddleHighlight"); t=p.Character:FindFirstChild("PiddleTag")
                    end
                    if d and t then
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
                        if show or tagOn then
                            d.FillColor=c; d.OutlineColor=c
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

X.BoxESP = {
    Settings = {
        Color = (typeof(CFG.espBoxColor) == "Color3" and CFG.espBoxColor) or Color3.fromRGB(255, 60, 80),
        Thickness = CFG.espBoxThickness or 1,
        HealthBar = true,
        UseRoleColor = CFG.espBoxRoleColor ~= false,
    },
    _data = setmetatable({}, {__mode="k"}),
}
do
local B = X.BoxESP
B.gui = nil
B.Settings.Round = tonumber(CFG.espBoxRound) or 6
local function root()
    if B.gui and B.gui.Parent then return B.gui end
    B.gui = Instance.new("ScreenGui")
    B.gui.Name = "PiddleBox"; B.gui.ResetOnSpawn = false; B.gui.IgnoreGuiInset = true
    B.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; B.gui.DisplayOrder = 5
    B.gui.Parent = GetGuiParent()
    return B.gui
end
local function mkFrame(parent)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.Visible = false; f.Parent = parent
    return f
end
local function ensure(plr)
    if B._data[plr] then return B._data[plr] end
    local d = {}
    d.outer = mkFrame(root())              -- black outline
    d.outerCorner = Instance.new("UICorner"); d.outerCorner.Parent = d.outer
    d.outerStroke = Instance.new("UIStroke"); d.outerStroke.Color = Color3.new(0, 0, 0); d.outerStroke.Transparency = 0.2
    d.outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; d.outerStroke.Parent = d.outer
    d.box = mkFrame(d.outer)               -- coloured box
    d.box.Size = UDim2.fromScale(1, 1)
    d.boxCorner = Instance.new("UICorner"); d.boxCorner.Parent = d.box
    d.stroke = Instance.new("UIStroke"); d.stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; d.stroke.Parent = d.box
    d.hbBg = mkFrame(root()); d.hbBg.BackgroundColor3 = Color3.new(0, 0, 0); d.hbBg.BackgroundTransparency = 0.25
    local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0, 2); c1.Parent = d.hbBg
    d.hbFill = Instance.new("Frame"); d.hbFill.BorderSizePixel = 0; d.hbFill.AnchorPoint = Vector2.new(0, 1)
    d.hbFill.Position = UDim2.fromScale(0, 1); d.hbFill.Parent = d.hbBg
    local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 2); c2.Parent = d.hbFill
    B._data[plr] = d
    return d
end
local function hide(d)
    if not d then return end
    d.outer.Visible = false; d.box.Visible = false; d.hbBg.Visible = false
end
function B.hideAll() for _, d in pairs(B._data) do hide(d) end end
function B.destroyAll()
    for plr, d in pairs(B._data) do pcall(function() d.outer:Destroy(); d.hbBg:Destroy() end); B._data[plr] = nil end
    if B.gui then pcall(function() B.gui:Destroy() end); B.gui = nil end
end
local function remove(plr)
    local d = B._data[plr]
    if d then pcall(function() d.outer:Destroy(); d.hbBg:Destroy() end); B._data[plr] = nil end
end
X.BoxESPRemove = remove
Connect(RunService.RenderStepped, function()
    if not State.boxESP then
        if B.gui then B.destroyAll() end
        return
    end
    local s = B.Settings
    local right = Cam.CFrame.RightVector
    local r = math.clamp(s.Round, 0, 24)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local d = ensure(plr)
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local head = ch and ch:FindFirstChild("Head")
            local role = (ch and hum and hum.Health > 0) and getRole(plr) or "NPC"
            local shown = false
            if ch and hum and hrp and head and role ~= "NPC" then
                -- exact body height: head top .. soles (rig + scale aware, no limb jitter)
                local top = head.Position.Y + head.Size.Y * 0.5
                local bottom
                if hum.RigType == Enum.HumanoidRigType.R15 then bottom = hrp.Position.Y - (hum.HipHeight + hrp.Size.Y * 0.5)
                else bottom = hrp.Position.Y - hrp.Size.Y * 1.5 end
                local halfH = (top - bottom) * 0.5 * 1.03
                local halfW = halfH * 0.54
                local c3 = Vector3.new(hrp.Position.X, (top + bottom) * 0.5, hrp.Position.Z)
                local pT = Cam:WorldToViewportPoint(c3 + Vector3.new(0, halfH, 0))
                local pB = Cam:WorldToViewportPoint(c3 - Vector3.new(0, halfH, 0))
                local pR = Cam:WorldToViewportPoint(c3 + right * halfW)
                local pL = Cam:WorldToViewportPoint(c3 - right * halfW)
                if pT.Z > 0 and pB.Z > 0 and pR.Z > 0 and pL.Z > 0 then
                    local x1, x2 = math.floor(math.min(pL.X, pR.X)), math.floor(math.max(pL.X, pR.X))
                    local y1, y2 = math.floor(pT.Y), math.floor(pB.Y)
                    local w, h = math.max(x2 - x1, 4), math.max(y2 - y1, 6)
                    local col = s.UseRoleColor and (roleColors[role] or s.Color) or s.Color
                    local th = math.clamp(s.Thickness, 1, 5)
                    d.outer.Position = UDim2.fromOffset(x1, y1); d.outer.Size = UDim2.fromOffset(w, h)
                    d.outerStroke.Thickness = th + 2
                    local rad = UDim.new(0, math.min(r, math.floor(math.min(w, h) / 2)))
                    d.outerCorner.CornerRadius = rad; d.boxCorner.CornerRadius = rad
                    d.stroke.Thickness = th; d.stroke.Color = col
                    d.outer.Visible = true; d.box.Visible = true
                    shown = true
                    if s.HealthBar then
                        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        d.hbBg.Position = UDim2.fromOffset(x1 - 7, y1); d.hbBg.Size = UDim2.fromOffset(3, h)
                        d.hbFill.Size = UDim2.fromScale(1, frac)
                        d.hbFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(70, 255, 110), frac)
                        d.hbBg.Visible = true
                    else d.hbBg.Visible = false end
                end
            end
            if not shown then hide(d) end
        end
    end
end)
end

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

function X.dodgeSpot(root, away, dd)
    dd = dd or UD.DodgeDist
    local origin=root.Position
    local fh=WS.FallenPartsDestroyHeight
    if fh~=fh then fh=-500 end
    local voidY=fh+25
    local myFloor=WS:Raycast(origin,Vector3.new(0,-15,0),envParams)
    local height=myFloor and (origin.Y-myFloor.Position.Y) or 3
    local baseY=myFloor and myFloor.Position.Y or (origin.Y-3)
    for _,deg in ipairs({0,35,-35,70,-70,110,-110,150,-150,180}) do
        local dir=CFrame.Angles(0,math.rad(deg),0)*away
        local wall=WS:Raycast(origin,dir*dd,envParams)
        local d=wall and math.max(wall.Distance-UD.WallBuffer,0) or dd
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

-- thrown knives / bullets are tracked as projectiles and dodged sideways
X.UDP = {}
do
local function projName(n) n = string.lower(n); return string.find(n, "knife", 1, true) or string.find(n, "bullet", 1, true) or string.find(n, "projectile", 1, true) or string.find(n, "dagger", 1, true) or string.find(n, "throw", 1, true) end
Connect(WS.DescendantAdded, function(o)
    if not UD.enabled or not o:IsA("BasePart") then return end
    local ch = LocalPlayer.Character
    if ch and o:IsDescendantOf(ch) then return end
    if o:FindFirstAncestorOfClass("Tool") or o:FindFirstAncestorOfClass("Accessory") then return end
    -- ignore anything that is part of a player's rig / knife display
    local m = o:FindFirstAncestorOfClass("Model")
    while m do
        if m:FindFirstChildOfClass("Humanoid") then return end
        local p = m.Parent
        m = p and p:FindFirstAncestorOfClass("Model") or nil
    end
    if not (projName(o.Name) or (o.Parent and projName(o.Parent.Name))) then return end
    X.UDP[o] = true
    task.delay(8, function() X.UDP[o] = nil end)
end)
end

RunService.Heartbeat:Connect(function()
    if not UD.enabled then return end
    local ch=LocalPlayer.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    -- only dodge while a round is actually running and we are alive in it (no random teleports in the lobby / after the round)
    local myData = rolesCache[LocalPlayer.Name]
    if not (myData and myData.Role) or myData.Killed or myData.Dead then return end
    local now=tick()
    if UD.isDodging or now-UD.lastDodgeTime<math.min(UD.BaseCooldown, 0.3) then return end
    local away, hop
    -- 1) incoming projectile?
    for part in pairs(X.UDP) do
        if not part.Parent then X.UDP[part] = nil
        else
            local v = part.AssemblyLinearVelocity
            local sp = v.Magnitude
            if sp >= UD.ProjectileSpeedMin then
                local dirv = v / sp
                local rel = root.Position - part.Position
                local along = rel:Dot(dirv)
                if along > 0 then
                    local t = along / sp
                    local lateral = rel - dirv * along
                    if t < 0.75 and lateral.Magnitude < 5 then
                        local flat = Vector3.new(lateral.X, 0, lateral.Z)
                        if flat.Magnitude < 0.6 then
                            local perp = dirv:Cross(Vector3.new(0, 1, 0))
                            flat = perp.Magnitude > 0.1 and perp or Vector3.new(1, 0, 0)
                        end
                        away = flat.Unit; hop = math.clamp(UD.DodgeDist, 8, 14)
                        break
                    end
                end
            end
        end
    end
    -- 2) murderer / knife holder closing in
    if not away then
        local thr,dist=X.dodgeThreat(root)
        if thr and dist<=math.max(UD.ScanRadius, UD.meleeDist) then
            local plr = Players:GetPlayerFromCharacter(thr.Parent)
            local toMe=Vector3.new(root.Position.X-thr.Position.X,0,root.Position.Z-thr.Position.Z)
            if toMe.Magnitude<0.05 then toMe=Vector3.new(1,0,0) end
            local dirAway=toMe.Unit
            local tv = (plr and X.TRK and X.TRK.vel(plr)) or thr.AssemblyLinearVelocity
            local closing = tv:Dot(dirAway) > 4
            if closing or dist <= 7 then away = dirAway; hop = UD.DodgeDist end
        end
    end
    if not away then return end
    UD.isDodging=true
    local okd,spot=pcall(X.dodgeSpot,root,away,hop)
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
X.W.DEFAULT_SOUND = {
    Rain   = "rbxassetid://1516791621",
    Storm  = "rbxassetid://1516791621",
    Snow   = "rbxassetid://551546110",
    Leaves = "rbxassetid://9116258071",
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
    local default = X.W.DEFAULT_SOUND[kind]
    if not default then return end
    local custom
    if kind == "Rain" or kind == "Storm" then custom = X.W.custom end
    local id = (custom and custom ~= "") and custom or default

    local snd = Instance.new("Sound")
    snd.Name = "PiddleWeatherSound"
    snd.Looped = true
    snd.Volume = (kind == "Storm") and 0.9 or 0.6
    snd.Parent = SoundService
    X.W.snd = snd
    task.spawn(function()
        if X.W.load(snd, {id}, kind) and X.W.snd == snd and VisState.weather == kind then
            snd:Play()
        end
    end)

    if kind == "Storm" then
        local th = Instance.new("Sound")
        th.Name = "PiddleThunder"; th.Volume = 1; th.Parent = SoundService
        X.W.thunder = th
        if X.W.thunderCustom ~= "" then
            task.spawn(function() X.W.load(th, {X.W.thunderCustom}, kind) end)
        end
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
local SUPREME_URL="https://api.rblxvalue.com/v2/items?api_key=rbx_b732593076f51fcf9239b9c6b4331969548bf1616434d0d0"
local function normKey(s)
    return (tostring(s or ""):lower():gsub("[^%w]", ""))
end
local function addRows(list)
    TRADE.items = {}
    for _, row in ipairs(list) do
        if type(row) == "table" then
            local name = (tostring(row.name or row.slug or "unknown"):gsub("^%s+", ""):gsub("%s+$", ""))
            local acr = tostring(row.acronym or "")
            local disp = name
            if acr ~= "" then disp = disp .. " (" .. acr .. ")" end
            table.insert(TRADE.items, {
                id = name, name = disp, alias = acr, kind = tostring(row.type or ""), year = 0,
                value = tonumber(row.value) or 0, category = tostring(row.category or ""),
                key = normKey(name), slugKey = normKey(row.slug), acrKey = normKey(acr),
            })
        end
    end
    TRADE.loaded = #TRADE.items > 0
    return TRADE.loaded
end
local function httpGetBody(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function() return req({Url = url, Method = "GET"}) end)
        if ok and res and res.Body and #res.Body > 50 then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body and #body > 50 then return body end
    local ok2, b2 = pcall(function() return HttpService:GetAsync(url) end)
    if ok2 and b2 and #b2 > 50 then return b2 end
    return nil
end
local function fetchSupremeValues()
    local rows, offset, total = {}, 0, nil
    for _ = 1, 40 do
        local body = httpGetBody(SUPREME_URL .. "&limit=200&offset=" .. offset)
        if not body then break end
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok or type(data) ~= "table" or type(data.items) ~= "table" or #data.items == 0 then break end
        for _, r in ipairs(data.items) do rows[#rows + 1] = r end
        total = tonumber(data.total) or total
        offset = offset + #data.items
        if total and offset >= total then break end
        task.wait(0.1)
    end
    if #rows == 0 then return false end
    return addRows(rows)
end
task.spawn(function() fetchSupremeValues(); while true do task.wait(300); fetchSupremeValues() end end)
local function findTradeItem(q)
    if not q or q == "" then return nil end
    local k = normKey(q)
    if k == "" then return nil end
    local par
    for _, it in ipairs(TRADE.items) do
        if it.key == k or it.slugKey == k or (it.acrKey ~= "" and it.acrKey == k) then return it end
        if not par and (it.key:find(k, 1, true) or it.slugKey:find(k, 1, true)) then par = it end
    end
    return par
end
-- ===== value overlay: small tag on top of the item slot (inventory, trade, shop) =====
X.PV = {tags = setmetatable({}, {__mode = "k"})}
;(function()
local PV = X.PV
local function exact(text)
    if not text or text == "" or #text > 48 then return nil end
    if PV.mapN ~= #TRADE.items then
        PV.map = {}; PV.mapN = #TRADE.items
        for _, it in ipairs(TRADE.items) do
            PV.map[it.key] = it
            if it.slugKey and it.slugKey ~= "" then PV.map[it.slugKey] = it end
        end
    end
    local k = normKey(text)
    if k == "" then return nil end
    return PV.map[k]
end
local function mine(d)
    return (Library.Gui and d:IsDescendantOf(Library.Gui)) or (X.MG and X.MG.gui and d:IsDescendantOf(X.MG.gui)) or (WmGui and d:IsDescendantOf(WmGui))
end
local function attach(slot, item)
    if not slot or not slot:IsA("GuiObject") then return end
    local ax, ay = slot.AbsoluteSize.X, slot.AbsoluteSize.Y
    if ax < 24 or ax > 260 or ay < 24 or ay > 260 then return end
    local lb = PV.tags[slot]
    if lb and lb.Parent then
        local txt = "$" .. tostring(item.value)
        if lb.Text ~= txt then lb.Text = txt end
        return
    end
    lb = Instance.new("TextLabel")
    lb.Name = "PiddleVal"
    lb.AnchorPoint = Vector2.new(1, 0)
    lb.Position = UDim2.new(1, -2, 0, 2)
    lb.Size = UDim2.fromOffset(0, 0)
    lb.AutomaticSize = Enum.AutomaticSize.XY
    lb.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    lb.BackgroundTransparency = 0.25
    lb.BorderSizePixel = 0
    lb.Text = "$" .. tostring(item.value)
    lb.TextColor3 = Color3.fromRGB(255, 220, 80)
    lb.Font = Enum.Font.GothamBold
    lb.TextSize = 11
    lb.ZIndex = 60
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 3); pad.PaddingRight = UDim.new(0, 3); pad.PaddingTop = UDim.new(0, 1); pad.PaddingBottom = UDim.new(0, 1)
    pad.Parent = lb
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 4); cr.Parent = lb
    lb.Parent = slot
    PV.tags[slot] = lb
end
function PV.clear()
    for slot, lb in pairs(PV.tags) do pcall(function() lb:Destroy() end); PV.tags[slot] = nil end
end
function PV.scan()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg or not TRADE.loaded then return end
    local n = 0
    local list = {}
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled then for _, d in ipairs(g:GetDescendants()) do list[#list + 1] = d end end
    end
    for _, d in ipairs(list) do
        n = n + 1
        if n % 400 == 0 then task.wait() end
        if d.Name ~= "PiddleVal" then
            if d:IsA("TextLabel") then
                if d.Visible and d.Text ~= "" then
                    local it = exact(d.Text)
                    if it and not mine(d) then attach(d.Parent, it) end
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") or d:IsA("Frame") then
                local it = exact(d.Name)
                if it and not mine(d) then attach(d, it) end
            end
        end
    end
    for slot, lb in pairs(PV.tags) do
        if not slot.Parent or not lb.Parent then PV.tags[slot] = nil end
    end
end
task.spawn(function()
    while not Library.Unloaded do
        task.wait(2.5)
        if State.tradeHelperOn then pcall(PV.scan) else PV.clear() end
    end
end)
end)()

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

function X.stab(k, ht, handle, thrp)
    pcall(function() k:Activate() end)
    pcall(function() ht:FireServer(thrp) end)
    if handle then EX.touch(handle, thrp, true) end
end
function X.killAll(manual)
    local plr = LocalPlayer
    if not plr then return end
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local k = getKnife()
    if k and k.Parent ~= char and hum then
        hum:EquipTool(k)
        local t0 = os.clock()
        while k.Parent ~= char and os.clock() - t0 < 1 do task.wait(0.03) end
    end
    local knife = char:FindFirstChild("Knife")
    if not knife then return end
    local events = knife:FindFirstChild("Events")
    if not events then return end
    local HandleTouched = events:FindFirstChild("HandleTouched")
    if not HandleTouched then return end
    for _, v in pairs(Players:GetPlayers()) do
        if not manual and not State.autoKillAll and not State.zombieAutoKill then break end
        if v and v ~= plr and v.Character then
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
        task.wait(0.4)
        if State.autoKillAll or State.zombieAutoKill then
            pcall(function()
                local ch = LocalPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end
                if not getKnife() then return end
                X.killAll()
            end)
        end
    end
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
KillFxSec:AddToggle({Name="eye laser", Callback=function(v) KillFx.EyeLaser=v; if not v then for _,k_ in ipairs({"_beam","_beam2"}) do if KillFx[k_] then pcall(function() KillFx[k_]:Destroy() end); KillFx[k_]=nil end end end end})
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
local BoxSec = VisualsTab:AddSection({Name="box esp", Side="Right"})
BoxSec:AddToggle({Name="box esp", Default=CFG.espBox, Callback=function(v) State.boxESP=v; CFG.espBox=v; saveCFG(); if not v and X.BoxESP.destroyAll then X.BoxESP.destroyAll() end end})
BoxSec:AddColorPicker({Name="box color", Default=(typeof(CFG.espBoxColor)=="Color3" and CFG.espBoxColor) or Color3.fromRGB(255,60,80), Callback=function(c) X.BoxESP.Settings.Color=c; CFG.espBoxColor=c; saveCFG() end})
BoxSec:AddSlider({Name="box thickness", Min=1, Max=5, Default=CFG.espBoxThickness or 1, Callback=function(v) X.BoxESP.Settings.Thickness=v; CFG.espBoxThickness=v; saveCFG() end})
BoxSec:AddSlider({Name="box roundness", Min=0, Max=20, Default=tonumber(CFG.espBoxRound) or 6, Callback=function(v) X.BoxESP.Settings.Round=v; CFG.espBoxRound=v; saveCFG() end})
BoxSec:AddToggle({Name="box health bar", Default=true, Callback=function(v) X.BoxESP.Settings.HealthBar=v end})
BoxSec:AddToggle({Name="box role color", Default=CFG.espBoxRoleColor~=false, Callback=function(v) X.BoxESP.Settings.UseRoleColor=v; CFG.espBoxRoleColor=v; saveCFG() end})
local AuraSec = VisualsTab:AddSection({Name="player aura", Side="Right"})
AuraSec:AddToggle({Name="enable aura", Callback=function(v) State.playerAuraOn=v; if not v then X.AURA.destroy() end end})
AuraSec:AddSlider({Name="aura size", Min=3, Max=16, Default=7, Callback=function(v) X.AURA.size=v; if State.playerAuraOn then X.AURA.destroy() end end})
AuraSec:AddColorPicker({Name="aura color", Default=Color3.new(1,1,1), Callback=function(c) State.playerAuraColor=c; X.AURA.recolor(c) end})
AuraSec:AddToggle({Name="rainbow aura", Callback=function(v) X.AURA.rainbow=v; if not v then X.AURA.recolor(State.playerAuraColor) end end})
AuraSec:AddToggle({Name="wings", Callback=function(v) X.WINGS.on=v; if not v then X.WINGS.destroy() end end})
AuraSec:AddColorPicker({Name="wings color", Default=X.WINGS.color, Callback=function(c) X.WINGS.color=c; CFG.wingsColor=c; saveCFG(); X.WINGS.recolor() end})
AuraSec:AddToggle({Name="rainbow wings", Callback=function(v) X.WINGS.rainbow=v; if not v then X.WINGS.recolor() end end})
AuraSec:AddToggle({Name="solid color wings", Default=true, Callback=function(v) X.WINGS.solid=v; if X.WINGS.on then X.WINGS.destroy() end end})
AuraSec:AddSlider({Name="wings size", Min=6, Max=20, Default=10, Callback=function(v) X.WINGS.size=v/10; if X.WINGS.on then X.WINGS.destroy() end end})
AuraSec:AddSlider({Name="flap speed", Min=1, Max=12, Default=3, Callback=function(v) X.WINGS.speed=v end})
AuraSec:AddToggle({Name="flip wings", Callback=function(v) X.WINGS.flip=v; if X.WINGS.on then X.WINGS.destroy() end end})
-- lighting is enforced every frame so the game / map scripts can't undo it
X.LT = {}
Connect(RunService.RenderStepped, function()
    local L = X.LT
    if next(L) == nil then return end
    if L.fb then
        Lighting.Brightness = 3; Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190); Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    elseif L.bright then Lighting.Brightness = L.bright end
    if L.time then Lighting.ClockTime = L.time end
    if L.nofog then
        Lighting.FogEnd = 1e6
        local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a then a.Density = 0; a.Haze = 0 end
    end
    if L.fov then Cam.FieldOfView = L.fov end
    if L.snap and os.clock() - (L.snapT or 0) > 0.4 then
        L.snapT = os.clock()
        for k, v in pairs(L.snap) do pcall(function() Lighting[k] = v end) end
    end
end)
function X.LT.snapNow()
    return {Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor}
end
local LightSec = VisualsTab:AddSection({Name="lighting presets", Side="Left"})
for _,n in ipairs({"Night","Deep Night","Sunset","Dawn","Rainy","Foggy","Storm","Realistic","Default"}) do
    LightSec:AddButton({Name=n, Callback=function() applyLightingPreset(n); X.LT.fb=nil; X.LT.time=nil; X.LT.bright=nil; X.LT.snap=(n~="Default") and X.LT.snapNow() or nil end})
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
WeatherSec:AddTextbox({Name="rain sound id", Placeholder="sound id (opt)", Default=CFG.rainSoundId or "", Callback=function(v)
    CFG.rainSoundId = v; saveCFG()
    X.W.custom = ResolveImage(v)
    if VisState.weather=="Rain" or VisState.weather=="Storm" then X.W.startSound(VisState.weather) end
end})
WeatherSec:AddTextbox({Name="thunder sound id", Placeholder="sound id (opt)", Default=CFG.thunderSoundId or "", Callback=function(v)
    CFG.thunderSoundId = v; saveCFG()
    X.W.thunderCustom = ResolveImage(v)
    if VisState.weather=="Storm" then X.W.startSound("Storm") end
end})
local LightCtlSec = VisualsTab:AddSection({Name="lighting", Side="Left"})
LightCtlSec:AddToggle({Name="fullbright", Callback=function(o) X.LT.fb=o or nil; if not o then X.LT.snap=nil; Lighting.Brightness=2; Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128); Lighting.Ambient=Color3.fromRGB(70,70,70) end end})
LightCtlSec:AddToggle({Name="no fog", Callback=function(o) X.LT.nofog=o or nil; if not o then Lighting.FogEnd=1000 end end})
LightCtlSec:AddSlider({Name="time of day", Min=0, Max=24, Default=14, Callback=function(v) X.LT.time=v; Lighting.ClockTime=v end})
LightCtlSec:AddSlider({Name="brightness", Min=0, Max=5, Default=2, Callback=function(v) X.LT.bright=v; Lighting.Brightness=v end})
LightCtlSec:AddSlider({Name="fov", Min=50, Max=130, Default=70, Callback=function(v) X.LT.fov=v; Cam.FieldOfView=v end})

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
    State.antiAfk = state
    if state then
        task.spawn(function()
            while State.antiAfk and not Library.Unloaded do
                pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
                for _=1,25 do if not State.antiAfk then break end; task.wait(1) end
            end
        end)
    end
end})
FarmSec:AddToggle({Name="auto get gun", Callback=function(v) State.autoGunUser=v; State.autoGun=v or State.autoShoot; GD.watch(State.autoGun) end})
FarmSec:AddDropdown({Name="gun pickup mode", Values={"remote", "fastTP"}, Default=CFG.autoGunMode, Callback=function(v) CFG.autoGunMode=v; saveCFG() end})
FarmSec:AddToggle({Name="auto kill all", Callback=function(v) State.autoKillAll=v end})
FarmSec:AddToggle({Name="auto reset (50 coins)", Default=CFG.autoFarmReset, Callback=function(v) CFG.autoFarmReset=v; saveCFG() end})
FarmSec:AddToggle({Name="full bag: shoot murderer", Default=CFG.farmFullShoot==true, Callback=function(v) CFG.farmFullShoot=v; saveCFG() end})

local TpTab = Win:AddTab({Name="teleport", Subtitle="tp"})
local TpSec = TpTab:AddSection({Name="teleport", Side="Left"})
TpSec:AddButton({Name="tp murderer", Callback=function() local p=findMurderer(); if p and p.Character and LocalPlayer.Character then local pr=p.Character:FindFirstChild("HumanoidRootPart"); local lr=LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame=pr.CFrame+Vector3.new(0,3,0) end end end})
TpSec:AddButton({Name="tp sheriff", Callback=function() local p=findSheriff(); if p and p.Character and LocalPlayer.Character then local pr=p.Character:FindFirstChild("HumanoidRootPart"); local lr=LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if pr and lr then lr.CFrame=pr.CFrame+Vector3.new(0,3,0) end end end})
do
local function tpTo(cf)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = cf
    return true
end
local function pivotOf(o)
    if o:IsA("Model") then return o:GetPivot() end
    if o:IsA("BasePart") then return o.CFrame end
end
local function firstSpawn(container)
    if not container then return nil end
    local sp = container:FindFirstChild("Spawns") or container:FindFirstChild("Spawn") or container:FindFirstChild("SpawnLocations")
    local list = {}
    if sp then for _, c in ipairs(sp:GetChildren()) do if c:IsA("BasePart") then list[#list + 1] = c end end end
    if #list == 0 then for _, d in ipairs(container:GetDescendants()) do if d:IsA("SpawnLocation") then list[#list + 1] = d end end end
    if #list > 0 then return list[math.random(1, #list)].CFrame + Vector3.new(0, 4, 0) end
    local pv = pivotOf(container)
    return pv and (pv + Vector3.new(0, 6, 0)) or nil
end
TpSec:AddButton({Name="tp lobby", Callback=function()
    local lobby = WS:FindFirstChild("Lobby")
    local cf = firstSpawn(lobby)
    if not cf then
        for _, d in ipairs(WS:GetChildren()) do if string.find(string.lower(d.Name), "lobby", 1, true) then cf = firstSpawn(d); if cf then break end end end
    end
    if cf and tpTo(cf) then return end
    Library:Notify({Title="teleport", Text="lobby not found", Duration=3})
end})
TpSec:AddButton({Name="tp map", Callback=function()
    local mapModel
    for _, d in ipairs(WS:GetChildren()) do
        if d:IsA("Model") and d.Name ~= "Lobby" and not Players:GetPlayerFromCharacter(d) then
            if d:FindFirstChild("CoinContainer", true) or d:FindFirstChild("Spawns") then mapModel = d; break end
        end
    end
    if not mapModel then
        local cc = WS:FindFirstChild("CoinContainer", true)
        mapModel = cc and cc.Parent
    end
    local cf = firstSpawn(mapModel)
    if cf and tpTo(cf) then return end
    Library:Notify({Title="teleport", Text="no map is loaded right now", Duration=3})
end})
TpSec:AddButton({Name="tp secret room (halloween)", Callback=function()
    local best
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("Model") or d:IsA("BasePart") then
            local n = string.lower(d.Name)
            if string.find(n, "secret", 1, true) or string.find(n, "hidden room", 1, true) or string.find(n, "easter", 1, true) then best = d; break end
        end
    end
    if not best then
        for _, d in ipairs(WS:GetDescendants()) do
            if d:IsA("Model") or d:IsA("BasePart") then
                local n = string.lower(d.Name)
                if string.find(n, "halloween", 1, true) and (string.find(n, "room", 1, true) or string.find(n, "crypt", 1, true) or string.find(n, "basement", 1, true)) then best = d; break end
            end
        end
    end
    local pv = best and pivotOf(best)
    if pv and tpTo(pv + Vector3.new(0, 5, 0)) then return end
    Library:Notify({Title="teleport", Text="secret room not found on this map / server", Duration=4})
end})
end

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
        pcall(function()
            RunService.Heartbeat:Wait()
            if State.touchFlingOn and not Fling.busy then
                local ch = LocalPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    -- make sure our own parts can actually collide with other players
                    for _, p in ipairs(ch:GetChildren()) do
                        if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end); if p == hrp then p.CanCollide = true end end
                    end
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    if hrp.Parent then hrp.AssemblyLinearVelocity = vel end
                    RunService.Stepped:Wait()
                    if hrp.Parent then hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0) end
                    movel = -movel
                end
            end
        end)
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
MoveSec:AddSlider({Name="fly speed (move)", Min=5, Max=150, Default=State.flySpeed, Callback=function(v) State.flySpeed=v; CFG.flySpeed=v; saveCFG() end})
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
X.AL.charCache = setmetatable({}, {__mode = "k"})
X.AL.lightOld = nil
-- originals live on the instances themselves (attributes) so they survive a script re-run and can always be restored
X.AL.KEYS = {"PL_S", "PL_Mat", "PL_Refl", "PL_Sh", "PL_Tex", "PL_Tr", "PL_ColorMap", "PL_MetalnessMap", "PL_NormalMap", "PL_RoughnessMap"}
function X.AL.isChar(v)
    local m = v:FindFirstAncestorOfClass("Model")
    while m do
        local c = X.AL.charCache[m]
        if c == nil then c = m:FindFirstChildOfClass("Humanoid") ~= nil; X.AL.charCache[m] = c end
        if c then return true end
        local p = m.Parent
        m = p and p:FindFirstAncestorOfClass("Model") or nil
    end
    return false
end
-- removes textures / materials / decals from world objects (characters are left alone)
function X.AL.strip(v)
    local c = v.ClassName
    local isPart = v:IsA("BasePart")
    if not (isPart or c == "Texture" or c == "Decal" or c == "SurfaceAppearance" or c == "SpecialMesh") then return end
    if v:GetAttribute("PL_S") then return end
    if v:FindFirstAncestor("PiddleFx") or v:FindFirstAncestor("PiddleWeather") or string.sub(v.Name, 1, 6) == "Piddle" then return end
    if X.AL.isChar(v) then return end
    if isPart then
        if v.Material == Enum.Material.Neon then return end
        v:SetAttribute("PL_Mat", v.Material.Name); v:SetAttribute("PL_Refl", v.Reflectance); v:SetAttribute("PL_Sh", v.CastShadow)
        v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0; v.CastShadow = false
        if c == "MeshPart" then v:SetAttribute("PL_Tex", v.TextureID); v.TextureID = "" end
    elseif c == "Texture" or c == "Decal" then
        v:SetAttribute("PL_Tr", v.Transparency); v.Transparency = 1
    elseif c == "SurfaceAppearance" then
        for _, k in ipairs({"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"}) do
            v:SetAttribute("PL_" .. k, v[k]); v[k] = ""
        end
    elseif c == "SpecialMesh" then
        v:SetAttribute("PL_Tex", v.TextureId); v.TextureId = ""
    end
    v:SetAttribute("PL_S", true)
end
function X.AL.restoreOne(v)
    if not v:GetAttribute("PL_S") then return end
    local c = v.ClassName
    pcall(function()
        if v:IsA("BasePart") then
            local m = v:GetAttribute("PL_Mat"); if m then v.Material = Enum.Material[m] end
            local r = v:GetAttribute("PL_Refl"); if r ~= nil then v.Reflectance = r end
            local sh = v:GetAttribute("PL_Sh"); if sh ~= nil then v.CastShadow = sh end
            local t = v:GetAttribute("PL_Tex"); if t ~= nil and c == "MeshPart" then v.TextureID = t end
        elseif c == "Texture" or c == "Decal" then
            local t = v:GetAttribute("PL_Tr"); if t ~= nil then v.Transparency = t end
        elseif c == "SpecialMesh" then
            local t = v:GetAttribute("PL_Tex"); if t ~= nil then v.TextureId = t end
        elseif c == "SurfaceAppearance" then
            for _, k in ipairs({"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"}) do
                local a = v:GetAttribute("PL_" .. k); if a ~= nil then v[k] = a end
            end
        end
    end)
    for _, k in ipairs(X.AL.KEYS) do v:SetAttribute(k, nil) end
end
function X.AL.restoreTex()
    local n = 0
    for _, v in ipairs(WS:GetDescendants()) do
        pcall(X.AL.restoreOne, v)
        n = n + 1
        if n % 600 == 0 then task.wait() end
    end
end
function X.AL.enable()
    X.AL.on = true; State.antiLagOn = true
    pcall(function() if X.AL.lightOld == nil then X.AL.lightOld = Lighting.GlobalShadows end; Lighting.GlobalShadows = false end)
    for _, v in ipairs(Lighting:GetChildren()) do X.AL.apply(v) end
    X.AL.gen = (X.AL.gen or 0) + 1
    local gen = X.AL.gen
    task.spawn(function()
        local n = 0
        for _, v in ipairs(WS:GetDescendants()) do
            if not X.AL.on or X.AL.gen ~= gen then break end
            X.AL.apply(v); pcall(X.AL.strip, v)
            n = n + 1
            if n % 600 == 0 then task.wait() end
        end
    end)
end
function X.AL.disable()
    X.AL.on = false; State.antiLagOn = false
    X.AL.gen = (X.AL.gen or 0) + 1
    for v, e in pairs(X.AL.orig) do
        if v.Parent then pcall(function() v.Enabled = e end) end
        X.AL.orig[v] = nil
    end
    pcall(function() if X.AL.lightOld ~= nil then Lighting.GlobalShadows = X.AL.lightOld; X.AL.lightOld = nil end end)
    task.spawn(X.AL.restoreTex)
end
Connect(WS.DescendantAdded, function(v) if X.AL.on then task.defer(function() X.AL.apply(v); pcall(X.AL.strip, v) end) end end)
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

-- ===== LIVE WALLPAPER (video) =====
X.LW = {on = false, video = nil, dim = nil, busy = false, vdim = CFG.liveDim or 35,
    urls = {
        "https://github.com/eruptertelegram-sketch/piddleproject/raw/Glowing%20particles%20overlay%20free%20to%20use.mp4",
        "https://github.com/eruptertelegram-sketch/piddleproject/raw/main/Glowing%20particles%20overlay%20free%20to%20use.mp4",
        "https://github.com/eruptertelegram-sketch/piddleproject/raw/master/Glowing%20particles%20overlay%20free%20to%20use.mp4",
        "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/main/Glowing%20particles%20overlay%20free%20to%20use.mp4",
        "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/master/Glowing%20particles%20overlay%20free%20to%20use.mp4",
    },
    file = "PiddleLive/glow_particles.mp4"}
;(function()
local LW = X.LW
local function isMp4(b) return type(b) == "string" and #b > 20000 and string.sub(b, 5, 8) == "ftyp" end
local function discover()
    -- finds the mp4 inside the repo no matter which branch / folder it was uploaded to
    local out = {}
    local function addFrom(list, base)
        if type(list) ~= "table" then return end
        for _, f in ipairs(list) do
            if type(f) == "table" then
                local nm = f.name or f.path
                if type(nm) == "string" and string.lower(nm):match("%.mp4$") then
                    local url = f.download_url
                    if not url and f.path then url = "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/" .. base .. "/" .. string.gsub(f.path, " ", "%%20") end
                    if url then
                        local score = string.find(string.lower(nm), "glow", 1, true) and 0 or 1
                        out[#out + 1] = {url = url, score = score}
                    end
                end
            end
        end
    end
    local b1 = httpGetBody("https://api.github.com/repos/eruptertelegram-sketch/piddleproject/contents/")
    if b1 then pcall(function() addFrom(HttpService:JSONDecode(b1), "main") end) end
    if #out == 0 then
        for _, br in ipairs({"main", "master"}) do
            local b2 = httpGetBody("https://api.github.com/repos/eruptertelegram-sketch/piddleproject/git/trees/" .. br .. "?recursive=1")
            if b2 then pcall(function() local d = HttpService:JSONDecode(b2); addFrom(d.tree, br) end) end
            if #out > 0 then break end
        end
    end
    table.sort(out, function(a, b) return a.score < b.score end)
    local urls = {}
    for _, o in ipairs(out) do urls[#urls + 1] = o.url end
    return urls
end
function LW.asset()
    if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then return nil, "executor needs writefile + getcustomasset" end
    pcall(function() if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("PiddleLive") then makefolder("PiddleLive") end end)
    local have = false
    pcall(function() have = type(isfile) == "function" and isfile(LW.file) and #readfile(LW.file) > 20000 end)
    if not have then
        local got
        for _, u in ipairs(LW.urls) do
            local b = httpGetBody(u)
            if isMp4(b) then got = b; break end
        end
        if not got then
            for _, u in ipairs(discover()) do
                local b = httpGetBody(u)
                if isMp4(b) then got = b; break end
            end
        end
        if not got then return nil, "can't find / download the mp4 in the repo (is the file uploaded to the main branch?)" end
        if not pcall(writefile, LW.file, got) then return nil, "writefile failed" end
    end
    local ok, a = pcall(getcustomasset, LW.file)
    if ok and a then return a end
    return nil, "getcustomasset failed"
end
function LW.remove()
    if LW.video then pcall(function() LW.video:Destroy() end); LW.video = nil end
    if LW.dim then pcall(function() LW.dim:Destroy() end); LW.dim = nil end
    if Win.BgImage then Win.BgImage.Visible = true end
end
function LW.setDim(v)
    LW.vdim = v; CFG.liveDim = v
    if LW.dim then LW.dim.BackgroundTransparency = 1 - v / 100 end
end
function LW.apply(on)
    if on and Library.Lite then LW.on = false; return end
    LW.on = on and true or false
    CFG.liveWallpaper = LW.on; saveCFG()
    if not on then LW.remove(); return end
    if LW.busy then return end
    LW.busy = true
    task.spawn(function()
        local asset, err = LW.asset()
        LW.busy = false
        if not LW.on then return end
        if not asset then Library:Notify({Title = "wallpaper", Text = tostring(err), Duration = 5}); return end
        LW.remove()
        local okv, v = pcall(Instance.new, "VideoFrame")
        if not okv or not v then Library:Notify({Title = "wallpaper", Text = "this executor can't create VideoFrame", Duration = 5}); return end
        v.Name = "LiveWallpaper"; v.Size = UDim2.fromScale(1, 1); v.BackgroundTransparency = 1; v.ZIndex = 0
        v.Looped = true; v.Volume = 0; v.Video = asset
        v.Parent = Win.Main
        local dim = Instance.new("Frame")
        dim.Name = "LiveDim"; dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0); dim.BorderSizePixel = 0
        dim.BackgroundTransparency = 1 - LW.vdim / 100; dim.ZIndex = 0; dim.Parent = Win.Main
        local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = v
        local cr2 = Instance.new("UICorner"); cr2.CornerRadius = UDim.new(0, 8); cr2.Parent = dim
        LW.video, LW.dim = v, dim
        if Win.BgImage then Win.BgImage.Visible = false end
        v.Playing = true
        pcall(function() v:Play() end)
        Library:Notify({Title = "wallpaper", Text = "wallpaper on", Duration = 3})
        task.delay(6, function()
            if LW.video == v and not v.IsLoaded then
                Library:Notify({Title = "wallpaper", Text = "video did not load - this executor may not play mp4 in VideoFrame", Duration = 6})
            end
        end)
    end)
end
end)()

-- ===== ANIMATED BACKGROUNDS (script-made): triangles / constellation =====
X.ANIM = {on = false, mode = "tri", frame = nil, items = {}, conn = nil, count = tonumber(CFG.triCount) or 14, speed = tonumber(CFG.triSpeed) or 100,
    color = (typeof(CFG.triColor) == "Color3" and CFG.triColor) or nil,
    dotColor = (typeof(CFG.netDotColor) == "Color3" and CFG.netDotColor) or nil, lineColor = (typeof(CFG.netLineColor) == "Color3" and CFG.netLineColor) or nil,
    lineMax = tonumber(CFG.netLineMax) or 135, sizeMin = tonumber(CFG.netSizeMin) or 1.5, sizeMax = tonumber(CFG.netSizeMax) or 8}
;(function()
local A = X.ANIM
local function col() return A.color or Color3.fromRGB(235, 235, 245) end
function A.destroy()
    if A.conn then pcall(function() A.conn:Disconnect() end); A.conn = nil end
    if A.frame then pcall(function() A.frame:Destroy() end); A.frame = nil end
    A.items = {}
end
local function baseFrame()
    local f = Instance.new("Frame")
    f.Name = "AnimBg"; f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0
    f.ClipsDescendants = true; f.ZIndex = 0; f.Parent = Win.Main
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = f
    return f
end
function A.buildTri()
    local W, H = Win.Main.Size.X.Offset, Win.Main.Size.Y.Offset
    local f = baseFrame()
    local rng = Random.new()
    for i = 1, A.count do
        local size = rng:NextInteger(14, 64)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1; l.Text = (i % 3 == 0) and "△" or "▲"
        l.Font = Enum.Font.GothamBold; l.TextSize = size; l.TextColor3 = col()
        l.Size = UDim2.fromOffset(size, size); l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Position = UDim2.fromOffset(rng:NextInteger(0, W), rng:NextInteger(0, H))
        l.Rotation = rng:NextInteger(0, 359); l.ZIndex = 0; l.Parent = f
        A.items[#A.items + 1] = {l = l, x = rng:NextNumber(0, W), y = rng:NextNumber(0, H), vx = rng:NextNumber(-14, 14), vy = rng:NextNumber(-34, -6),
            spin = rng:NextNumber(-45, 45), rot = l.Rotation, ph = rng:NextNumber(0, 6.28), base = rng:NextNumber(0.55, 0.9)}
    end
    A.frame = f
    local t = 0
    local carry = 0
    A.conn = RunService.RenderStepped:Connect(function(dt)
        carry = carry + dt
        if carry < 0.033 then return end
        dt = math.min(carry, 0.08); carry = 0
        t = t + dt
        local sp = A.speed / 100
        for _, it in ipairs(A.items) do
            it.x = it.x + it.vx * dt * sp; it.y = it.y + it.vy * dt * sp; it.rot = it.rot + it.spin * dt * sp
            if it.y < -80 then it.y = H + 80; it.x = rng:NextNumber(0, W) end
            if it.y > H + 90 then it.y = -70 end
            if it.x < -80 then it.x = W + 70 elseif it.x > W + 80 then it.x = -70 end
            it.l.Position = UDim2.fromOffset(it.x, it.y); it.l.Rotation = it.rot
            it.l.TextTransparency = it.base + math.sin(t * 0.9 + it.ph) * 0.12
            it.l.TextColor3 = col()
        end
    end)
end
-- constellation: dots bounce off the edges of the UI, linked by lines that fade out past the max length
function A.buildNet()
    local f = baseFrame()
    local N = math.clamp(A.count, 6, 28)
    local W, H = Win.Main.Size.X.Offset, Win.Main.Size.Y.Offset
    local pts, dots, lines = {}, {}, {}
    local rng = Random.new()
    local function dotSize(t)
        local lo, hi = math.min(A.sizeMin, A.sizeMax), math.max(A.sizeMin, A.sizeMax)
        return lo + (hi - lo) * t
    end
    local function dotCol() return A.dotColor or A.color or Theme.Accent end
    local function lineCol() return A.lineColor or A.color or Theme.Accent end
    for i = 1, N do
        local ang = rng:NextNumber(0, 6.2832)
        local spd = rng:NextNumber(18, 55)
        pts[i] = {x = rng:NextNumber(6, W - 6), y = rng:NextNumber(6, H - 6), vx = math.cos(ang) * spd, vy = math.sin(ang) * spd, t = rng:NextNumber(0, 1)}
        local d = Instance.new("Frame")
        d.AnchorPoint = Vector2.new(0.5, 0.5); d.BackgroundColor3 = dotCol(); d.BorderSizePixel = 0; d.ZIndex = 0; d.Parent = f
        local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.5, 0); cr.Parent = d
        dots[i] = d
    end
    for i = 1, N - 1 do
        for j = i + 1, N do
            local l = Instance.new("Frame")
            l.AnchorPoint = Vector2.new(0.5, 0.5); l.Size = UDim2.fromOffset(0, 1); l.BackgroundColor3 = lineCol(); l.BorderSizePixel = 0; l.Visible = false; l.ZIndex = 0; l.Parent = f
            lines[#lines + 1] = {i = i, j = j, l = l}
        end
    end
    A.frame = f
    local acc = 0
    local carry = 0
    A.conn = RunService.RenderStepped:Connect(function(dt)
        carry = carry + dt
        if carry < 0.033 then return end   -- ~30 fps is plenty for a background
        dt = math.min(carry, 0.08) * (A.speed / 100); carry = 0
        acc = acc + 1
        local dc, lc = dotCol(), lineCol()
        local maxd = A.lineMax
        for i = 1, N do
            local p = pts[i]
            local s = dotSize(p.t)
            local r = s / 2
            p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
            -- bounce off the very edge of the window
            if p.x < r then p.x = r; p.vx = math.abs(p.vx) elseif p.x > W - r then p.x = W - r; p.vx = -math.abs(p.vx) end
            if p.y < r then p.y = r; p.vy = math.abs(p.vy) elseif p.y > H - r then p.y = H - r; p.vy = -math.abs(p.vy) end
            local d = dots[i]
            d.Position = UDim2.fromOffset(p.x, p.y); d.Size = UDim2.fromOffset(s, s); d.BackgroundColor3 = dc
        end
        for _, pr in ipairs(lines) do
            local a, b = pts[pr.i], pts[pr.j]
            local dx, dy = b.x - a.x, b.y - a.y
            local d2 = dx * dx + dy * dy
            local l = pr.l
            if d2 < maxd * maxd then
                local d = math.sqrt(d2)
                l.Visible = true
                l.Size = UDim2.fromOffset(d, 1); l.Position = UDim2.fromOffset((a.x + b.x) / 2, (a.y + b.y) / 2)
                l.Rotation = math.deg(math.atan2(dy, dx))
                l.BackgroundColor3 = lc; l.BackgroundTransparency = 1 - (1 - d / maxd) * 0.8
            elseif l.Visible then l.Visible = false end
        end
    end)
end
function A.build() A.destroy(); if A.mode == "net" then A.buildNet() else A.buildTri() end end
function A.apply(on, mode)
    if mode then A.mode = mode end
    if on and Library.Lite then on = false; Library:Notify({Title = "wallpaper", Text = "disabled in lite mode", Duration = 3}) end
    A.on = on and true or false
    if not on then
        A.destroy()
        if Win.BgImage and not (X.LW and X.LW.on) then Win.BgImage.Visible = true end
        return
    end
    A.build()
    if Win.BgImage then Win.BgImage.Visible = false end
end
function A.recolor(c)
    A.color = c; CFG.triColor = c; saveCFG()
end
function A.setDotColor(c) A.dotColor = c; CFG.netDotColor = c; saveCFG() end
function A.setLineColor(c) A.lineColor = c; CFG.netLineColor = c; saveCFG() end
end)()

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
X.NOIR = {loaded = false, loading = false}
function X.NOIR.env() return (getgenv and getgenv()) or _G end
function X.NOIR.state() return X.NOIR.env().__NoirSkinsState end
-- the skin changer is NOT bundled (keeps this script small and fast): it is read from a file in the executor workspace
-- or downloaded from the link below the first time you switch it on
function X.NOIR.fetch()
    for _, f in ipairs({"Noir_Skinchanger.lua", "PiddleSkins/Noir_Skinchanger.lua", "Piddle/Noir_Skinchanger.lua"}) do
        local ok, body = pcall(function() if type(isfile) == "function" and isfile(f) then return readfile(f) end end)
        if ok and type(body) == "string" and #body > 10000 then return body end
    end
    local urls = {}
    if type(CFG.noirUrl) == "string" and CFG.noirUrl ~= "" then urls[#urls + 1] = CFG.noirUrl end
    urls[#urls + 1] = "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/main/Noir_Skinchanger.lua"
    urls[#urls + 1] = "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/master/Noir_Skinchanger.lua"
    for _, u in ipairs(urls) do
        local body = httpGetBody(u)
        if type(body) == "string" and #body > 10000 then return body end
    end
end
function X.NOIR.load(cb)
    if X.NOIR.loaded then if cb then pcall(cb) end return end
    if X.NOIR.loading then return end
    X.NOIR.loading = true
    task.spawn(function()
        local body = X.NOIR.fetch()
        if not body then
            X.NOIR.loading = false
            Library:Notify({Title = "skins", Text = "Noir_Skinchanger.lua not found: put it in your executor workspace folder or upload it to the repo (main branch)", Duration = 8})
            return
        end
        local ls = loadstring or load
        local ok, err = pcall(function()
            local fn, e = ls(body, "=Noir_Skinchanger")
            if not fn then error(e) end
            fn()
        end)
        X.NOIR.loading = false
        if not ok then Library:Notify({Title = "skins", Text = "skin changer failed to start: " .. tostring(err), Duration = 7}); return end
        X.NOIR.loaded = true
        for _ = 1, 60 do if X.NOIR.state() then break end; task.wait(0.25) end
        if cb then pcall(cb) end
    end)
end
function X.NOIR.setEnabled(v)
    if v then X.NOIR.load(function() local st = X.NOIR.state(); if st then st.enabled = true end end)
    else local st = X.NOIR.state(); if st then st.enabled = false end end
end
function X.NOIR.setBelt(v)
    local function apply() local st = X.NOIR.state(); if st then st.knifeBelt = v; if v then st.enabled = true end end end
    if v then X.NOIR.load(apply) else apply() end
end
function X.NOIR.destroy()
    local g = X.NOIR.env()
    if g.__NoirSkinsDestroy then pcall(g.__NoirSkinsDestroy) end
    X.NOIR.loaded = false
end
SkinSec:AddLabel({Name="needs Noir_Skinchanger.lua in the executor workspace folder (or a link). skins are picked on the Changer page in the game inventory"})
SkinSec:AddToggle({Name="skin changer", Default=CFG.noirSkins==true, Callback=function(v) CFG.noirSkins=v; saveCFG(); X.NOIR.setEnabled(v) end})
SkinSec:AddToggle({Name="knife on belt", Default=CFG.noirBelt==true, Callback=function(v) CFG.noirBelt=v; saveCFG(); X.NOIR.setBelt(v) end})
SkinSec:AddTextbox({Name="skin changer link (optional)", Placeholder="raw link to Noir_Skinchanger.lua", Default=CFG.noirUrl or "", Callback=function(v) CFG.noirUrl=tostring(v or ""); saveCFG() end})
SkinSec:AddButton({Name="unload skin changer", Callback=function() X.NOIR.destroy() end})
if CFG.noirSkins then task.delay(3, function() X.NOIR.setEnabled(true); if CFG.noirBelt then X.NOIR.setBelt(true) end end) end
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
        source = (CFG.tracerSource == "gun shot") and "gun shot" or "bullet object",
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
        local nowT = os.clock()
        if not extra.cb and G._lastBuild and nowT - G._lastBuild < 0.08 and G._lastTo and (G._lastTo - b).Magnitude < 3 then return end
        G._lastBuild, G._lastTo = nowT, b
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
    G.shot = function(a, b, i, m)
        if G.source == "gun shot" then return spawnFromTo(a, b, i, m) end
    end

    local function checkBullet(obj)
        if not G.on or G.source ~= "bullet object" then return end
        if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
        local nm = obj.Name:lower()
        if not (nm:find("bullet", 1, true) or nm:find("projectile", 1, true)) then return end
        task.defer(function()
            pcall(function()
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if not part or not part.Parent then return end
                local origin = part.Position
                local myChar = LP.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local mine = myRoot and (myRoot.Position - origin).Magnitude < 14
                if not mine and not G.others then return end
                local v = part.AssemblyLinearVelocity
                local dir = (v.Magnitude > 5) and v.Unit or part.CFrame.LookVector
                local hit = workspace:Raycast(origin, dir * 700, getRayParams())
                local dest = hit and hit.Position or origin + dir * 300
                spawnFromTo(origin, dest, G.impact, G.muzzle)
            end)
        end)
    end
    workspace.DescendantAdded:Connect(checkBullet)

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
                    if not target or not G.on or G.source ~= "gun shot" then return end
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

    sec:AddToggle({Name = "bullet tracers", Default = G.on, Callback = function(v) G.on = v == true; CFG.bulletTracerOn = G.on; saveCFG() end})
    sec:AddDropdown({Name = "tracer source", Values = {"bullet object", "gun shot"}, Default = G.source, Callback = function(v)
        if v == "bullet object" or v == "gun shot" then G.source = v; CFG.tracerSource = v; saveCFG() end
    end})
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
    sec:AddButton({Name = "preview tracer", Callback = function() task.spawn(function() pcall(function()
        if G.preview then return end
    end) end) end})
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
    pcall(function()
        if type(replicatesignal) == "function" then replicatesignal(LocalPlayer.Kill) end
    end)
    pcall(function() ch:BreakJoints() end)
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
    end
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
local MusicSec = MusicTab:AddSection({Name="player", Side="Left"})
local LibSec = MusicTab:AddSection({Name="library", Side="Right"})
local bgSound=Instance.new("Sound"); bgSound.Name="PiddleMusic"; bgSound.Volume=CFG.musicVolume/100; bgSound.Looped=(CFG.musicLoop~=false); bgSound.Parent=SoundService
X.MP = {tracks={}, idx=0, files={}, token=0}
do
local MP = X.MP
local GH = "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/"
MP.tracks = {
    {name="Just the Way You Are", kind="url", src=GH.."main/just%20the%20way%20you%20are.mp3", cover=GH.."refs/heads/main/IMG_6060f36c-e46a-4fc6-b04a-8d7acbea0a03.jpg"},
    {name="Chill", kind="id", src="rbxassetid://1837879082"},
    {name="Synth", kind="id", src="rbxassetid://1836318003"},
    {name="Trap", kind="id", src="rbxassetid://1837842597"},
    {name="Phonk", kind="id", src="rbxassetid://9046731150"},
}
local custom = type(CFG.customTracks) == "table" and CFG.customTracks or {}
CFG.customTracks = custom
for _, t in ipairs(custom) do
    if type(t) == "table" and t.src and t.kind then table.insert(MP.tracks, {name=t.name or "track", kind=t.kind, src=t.src, custom=true}) end
end

local function hashStr(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + string.byte(s, i)) % 4294967296 end
    return tostring(h)
end
function MP.http(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(function() return req({Url = url, Method = "GET"}) end)
        if ok and res and res.Body and #res.Body > 200 and (res.StatusCode == nil or res.StatusCode == 200) then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body and #body > 200 then return body end
    return nil
end
function MP.asset(url, ext)
    if MP.files[url] then return MP.files[url] end
    if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then return nil end
    local name = "PiddleMusic/" .. hashStr(url) .. ext
    local have = false
    pcall(function() have = type(isfile) == "function" and isfile(name) end)
    if not have then
        local body = MP.http(url)
        if not body or #body > 60000000 then return nil end
        pcall(function() if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("PiddleMusic") then makefolder("PiddleMusic") end end)
        if not pcall(writefile, name, body) then return nil end
    end
    local ok, a = pcall(getcustomasset, name)
    if ok and a then MP.files[url] = a; return a end
    return nil
end

local holder = MusicSec.Holder
local coverBox = New("Frame", {Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = Theme.Row, Parent = holder})
Corner(coverBox, 8)
Stroke(coverBox, Theme.Stroke)
MP.cover = New("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Crop, Parent = coverBox})
Corner(MP.cover, 8)
Connect(coverBox:GetPropertyChangedSignal("AbsoluteSize"), function()
    local w = coverBox.AbsoluteSize.X
    if w > 40 and coverBox.Size.Y.Offset ~= w then coverBox.Size = UDim2.new(1, 0, 0, w) end
end)
MP.title = Label({Size = UDim2.new(1, 0, 0, 18), Text = "not playing", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = holder})
local barBg = New("Frame", {Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.Row, Parent = holder})
Corner(barBg, 4)
MP.fill = New("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = barBg})
Corner(MP.fill, 4)
MP.time = Label({Size = UDim2.new(1, 0, 0, 14), Text = "0:00 / 0:00", TextColor3 = Theme.Dim, TextSize = 10, Parent = holder})
Connect(barBg.InputBegan, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        local w = barBg.AbsoluteSize.X
        if w > 0 and bgSound.TimeLength > 0 then
            local f = math.clamp((i.Position.X - barBg.AbsolutePosition.X) / w, 0, 1)
            bgSound.TimePosition = f * bgSound.TimeLength
        end
    end
end)

local function fmt(s)
    s = math.max(0, math.floor(s or 0))
    return string.format("%d:%02d", s // 60, s % 60)
end
function MP.play(i)
    if #MP.tracks == 0 then return end
    i = ((i - 1) % #MP.tracks) + 1
    MP.idx = i
    local t = MP.tracks[i]
    MP.token = MP.token + 1
    local tk = MP.token
    MP.title.Text = t.name .. " (loading)"
    task.spawn(function()
        local sid
        if t.kind == "url" then sid = MP.asset(t.src, ".mp3") else sid = t.src end
        if MP.token ~= tk then return end
        if not sid then
            MP.title.Text = t.name
            Library:Notify({Title = "music", Text = "can't load this track (executor needs writefile + getcustomasset)", Duration = 5})
            return
        end
        bgSound:Stop()
        bgSound.SoundId = sid
        bgSound.TimePosition = 0
        bgSound:Play()
        MP.title.Text = t.name
    end)
    task.spawn(function()
        local img = ""
        if t.cover then img = MP.asset(t.cover, ".jpg") or "" end
        if MP.token ~= tk then return end
        MP.cover.Image = img
    end)
end

local row = New("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = holder})
local function ctl(text, x, cb)
    local b = New("TextButton", {Size = UDim2.new(0.32, 0, 1, 0), Position = UDim2.new(x, 0, 0, 0), BackgroundColor3 = Theme.Box, Text = text, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 12, AutoButtonColor = true, Parent = row})
    Corner(b, 6)
    Stroke(b, Theme.Stroke)
    Connect(b.MouseButton1Click, function() playSound(Sounds.Click, 0.5); cb() end)
    return b
end
ctl("prev", 0, function() MP.play(MP.idx - 1) end)
MP.playBtn = ctl("play", 0.34, function()
    if bgSound.IsPlaying then bgSound:Pause()
    elseif bgSound.IsPaused then bgSound:Resume()
    elseif bgSound.SoundId == "" then MP.play(MP.idx > 0 and MP.idx or (MP.sel or 1))
    else bgSound:Play() end
end)
ctl("next", 0.68, function() MP.play(MP.idx + 1) end)

MusicSec:AddSlider({Name = "volume", Min = 0, Max = 100, Default = CFG.musicVolume, Callback = function(v) bgSound.Volume = v / 100; CFG.musicVolume = v; saveCFG() end})
MusicSec:AddToggle({Name = "loop track", Default = CFG.musicLoop ~= false, Callback = function(v) bgSound.Looped = v; CFG.musicLoop = v; saveCFG() end})
Connect(bgSound.Ended, function()
    if not bgSound.Looped then MP.play(MP.idx + 1) end
end)

local function names()
    local n = {}
    for _, t in ipairs(MP.tracks) do n[#n + 1] = t.name end
    return n
end
MP.dd = LibSec:AddDropdown({Name = "track", Values = names(), Default = MP.tracks[1].name, Callback = function(v)
    for i, t in ipairs(MP.tracks) do
        if t.name == v then MP.play(i); return end
    end
end})
local newSrc, newName = "", ""
-- ===== music: library discovery (every audio file in the repo), covers, preload =====
local RAWBASE = "https://raw.githubusercontent.com/eruptertelegram-sketch/piddleproject/main/"
local function enc(path) return (path:gsub("[^%w%-%._~/]", function(c) return string.format("%%%02X", string.byte(c)) end)) end
local function norm(s) return (string.lower(s or ""):gsub("[^%w]", "")) end
local function baseName(path) return (path:match("([^/]+)$") or path):gsub("%.%w+$", "") end
local AUDIO = {mp3 = true, ogg = true, wav = true}
local IMAGE = {jpg = true, jpeg = true, png = true, webp = true}
function MP.show(i)
    local t = MP.tracks[i]
    if not t then return end
    MP.sel = i
    MP.shownTok = (MP.shownTok or 0) + 1
    local tok = MP.shownTok
    if MP.idx == 0 then MP.title.Text = t.name end
    task.spawn(function()
        local img = ""
        if t.cover then img = MP.asset(t.cover, ".jpg") or "" end
        if MP.shownTok == tok and (MP.idx == 0 or MP.idx == i) then MP.cover.Image = img end
    end)
end
function MP.discover(notify)
    local paths = {}
    local body = httpGetBody("https://api.github.com/repos/eruptertelegram-sketch/piddleproject/git/trees/main?recursive=1")
    if body then
        pcall(function() local d = HttpService:JSONDecode(body); for _, e in ipairs(d.tree or {}) do if e.type == "blob" then paths[#paths + 1] = e.path end end end)
    end
    if #paths == 0 then
        local b2 = httpGetBody("https://api.github.com/repos/eruptertelegram-sketch/piddleproject/contents/")
        if b2 then pcall(function() for _, f in ipairs(HttpService:JSONDecode(b2)) do if f.type == "file" then paths[#paths + 1] = f.path or f.name end end end) end
    end
    if #paths == 0 then if notify then Library:Notify({Title = "music", Text = "can't reach the library (github)", Duration = 4}) end return end
    local images = {}
    for _, p in ipairs(paths) do
        local ext = string.lower(p:match("%.(%w+)$") or "")
        if IMAGE[ext] then images[norm(baseName(p))] = p end
    end
    local have = {}
    for _, t in ipairs(MP.tracks) do have[norm(t.name)] = true; if t.src then have[norm(baseName(t.src:gsub("%%20", " ")))] = true end end
    local added = 0
    for _, p in ipairs(paths) do
        local ext = string.lower(p:match("%.(%w+)$") or "")
        if AUDIO[ext] then
            local nm = baseName(p)
            if not have[norm(nm)] then
                have[norm(nm)] = true
                local cp = images[norm(nm)]
                table.insert(MP.tracks, {name = nm, kind = "url", src = RAWBASE .. enc(p), cover = cp and (RAWBASE .. enc(cp)) or nil})
                added = added + 1
            end
        end
    end
    pcall(function() MP.dd:SetValues(names()) end)
    if notify or added > 0 then Library:Notify({Title = "music", Text = added > 0 and (added .. " new track(s) added to the library") or "library is up to date", Duration = 3}) end
end
LibSec:AddButton({Name = "refresh library", Callback = function() task.spawn(MP.discover, true) end})
MusicSec:AddToggle({Name = "autoplay on start", Default = CFG.musicAuto == true, Callback = function(v) CFG.musicAuto = v; saveCFG() end})
-- picture + first song are prepared in the background shortly after start (skipped in lite mode)
task.spawn(function()
    task.wait(6)
    MP.show(1)
    if Library.Lite then return end
    task.spawn(MP.discover, false)
    local first = MP.tracks[1]
    if first and first.kind == "url" then MP.asset(first.src, ".mp3") end
    for i = 2, #MP.tracks do
        local t = MP.tracks[i]
        if t.cover then MP.asset(t.cover, ".jpg") end
        task.wait(0.5)
    end
    if CFG.musicAuto and MP.idx == 0 then MP.play(1) end
end)
do
    local oldSel = Win.SelectTab
    Win.SelectTab = function(self, tab)
        oldSel(self, tab)
        if tab and tab.Name == "music" then
            if MP.idx == 0 then MP.show(MP.sel or 1)
            elseif MP.cover.Image == "" and MP.tracks[MP.idx] and MP.tracks[MP.idx].cover then
                local t = MP.tracks[MP.idx]
                task.spawn(function() local img = MP.asset(t.cover, ".jpg"); if img then MP.cover.Image = img end end)
            end
        end
    end
end
LibSec:AddTextbox({Name = "link or asset id", Placeholder = "https://... or 123456", Callback = function(v) newSrc = tostring(v or "") end})
LibSec:AddTextbox({Name = "name (optional)", Placeholder = "my song", Callback = function(v) newName = tostring(v or "") end})
LibSec:AddButton({Name = "add track", Callback = function()
    local s = (newSrc:gsub("^%s+", ""):gsub("%s+$", ""))
    if s == "" then return end
    local kind, srcv
    if s:match("^https?://") then
        kind, srcv = "url", s
    elseif s:match("^rbxassetid://%d+$") then
        kind, srcv = "id", s
    elseif s:match("^%d+$") then
        kind, srcv = "id", "rbxassetid://" .. s
    else
        Library:Notify({Title = "music", Text = "paste a link or an asset id", Duration = 3})
        return
    end
    local nm = newName ~= "" and newName or ((s:match("([^/]+)$") or "track"):gsub("%%20", " "):gsub("%.%w+$", ""))
    table.insert(MP.tracks, {name = nm, kind = kind, src = srcv, custom = true})
    table.insert(custom, {name = nm, kind = kind, src = srcv})
    saveCFG()
    MP.dd:SetValues(names())
    Library:Notify({Title = "music", Text = "added: " .. nm, Duration = 2})
    MP.play(#MP.tracks)
end})
LibSec:AddParagraph("custom music", "A link must point directly to an audio file (mp3/ogg). Links need writefile and getcustomasset in your executor; asset ids work everywhere.")

task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.25)
        if Win.Visible then
            pcall(function()
                local len = bgSound.TimeLength
                local pos = bgSound.TimePosition
                MP.fill.Size = UDim2.fromScale(len > 0 and math.clamp(pos / len, 0, 1) or 0, 1)
                local tm = fmt(pos) .. " / " .. fmt(len)
                if MP.time.Text ~= tm then MP.time.Text = tm end
                local pb = bgSound.IsPlaying and "pause" or "play"
                if MP.playBtn.Text ~= pb then MP.playBtn.Text = pb end
            end)
        end
    end
end)
end

-- ===== MINIGAMES UI (inserted into piddle; uses its helpers: New Corner Stroke Label List Padding Connect Tween Theme) =====
X.MG = {}
X.MG.L = (function()
local L = {}

-- deterministic PRNG (same result on every client). rng(n)->1..n ; rng()->[0,1)
function L.RNG(seed)
    local s = (math.floor(tonumber(seed) or 1) % 2147483646) + 1
    return function(n)
        s = (s * 16807) % 2147483647
        if n then return (s % n) + 1 end
        return s / 2147483647
    end
end

------------------------------------------------------------ MINESWEEPER
local MS = {}
L.MS = MS
function MS.new(n, seed)
    local rng = L.RNG(seed)
    local density = 0.13 + rng() * 0.06
    local total = n * n
    local want = math.max(6, math.floor(total * density))
    local g = {n = n, mine = {}, cnt = {}, st = {}, mines = 0, revealed = 0, dead = false, won = false, flags = 0}
    for i = 1, total do g.mine[i] = false; g.cnt[i] = 0; g.st[i] = 0 end
    local c = math.floor(n / 2)
    local placed, guard = 0, 0
    while placed < want and guard < want * 40 do
        guard = guard + 1
        local x, y = rng(n) - 1, rng(n) - 1
        local i = y * n + x + 1
        if not g.mine[i] and not (math.abs(x - c) <= 1 and math.abs(y - c) <= 1) then
            g.mine[i] = true; placed = placed + 1
        end
    end
    g.mines = placed
    for y = 0, n - 1 do
        for x = 0, n - 1 do
            local i = y * n + x + 1
            if not g.mine[i] then
                local k = 0
                for dy = -1, 1 do for dx = -1, 1 do
                    local nx, ny = x + dx, y + dy
                    if (dx ~= 0 or dy ~= 0) and nx >= 0 and ny >= 0 and nx < n and ny < n and g.mine[ny * n + nx + 1] then k = k + 1 end
                end end
                g.cnt[i] = k
            end
        end
    end
    return g
end
function MS.reveal(g, x, y)
    local n = g.n
    if g.dead or g.won then return end
    local i0 = y * n + x + 1
    if g.st[i0] ~= 0 then return end
    if g.mine[i0] then g.st[i0] = 1; g.dead = true; g.boom = i0; return "boom" end
    local stack, sp = {i0}, 1
    g.st[i0] = 1; g.revealed = g.revealed + 1
    while sp > 0 do
        local i = stack[sp]; stack[sp] = nil; sp = sp - 1
        if g.cnt[i] == 0 then
            local cx, cy = (i - 1) % n, math.floor((i - 1) / n)
            for dy = -1, 1 do for dx = -1, 1 do
                local nx, ny = cx + dx, cy + dy
                if nx >= 0 and ny >= 0 and nx < n and ny < n then
                    local j = ny * n + nx + 1
                    if g.st[j] == 0 and not g.mine[j] then
                        g.st[j] = 1; g.revealed = g.revealed + 1
                        sp = sp + 1; stack[sp] = j
                    end
                end
            end end
        end
    end
    if g.revealed >= n * n - g.mines then g.won = true; return "win" end
    return "ok"
end
function MS.flag(g, x, y)
    local i = y * g.n + x + 1
    if g.dead or g.won then return end
    if g.st[i] == 0 then g.st[i] = 2; g.flags = g.flags + 1
    elseif g.st[i] == 2 then g.st[i] = 0; g.flags = g.flags - 1 end
end
function MS.chord(g, x, y)
    local n = g.n
    local i = y * n + x + 1
    if g.st[i] ~= 1 or g.cnt[i] == 0 then return end
    local f = 0
    for dy = -1, 1 do for dx = -1, 1 do
        local nx, ny = x + dx, y + dy
        if nx >= 0 and ny >= 0 and nx < n and ny < n and g.st[ny * n + nx + 1] == 2 then f = f + 1 end
    end end
    if f ~= g.cnt[i] then return end
    local res
    for dy = -1, 1 do for dx = -1, 1 do
        local nx, ny = x + dx, y + dy
        if nx >= 0 and ny >= 0 and nx < n and ny < n then
            local r = MS.reveal(g, nx, ny)
            if r == "boom" or r == "win" then res = r end
        end
    end end
    return res
end

------------------------------------------------------------ TIC TAC TOE (k in a row)
local TT = {}
L.TT = TT
local DIRS = {{1, 0}, {0, 1}, {1, 1}, {1, -1}}
function TT.new(n) local b = {}; for i = 1, n * n do b[i] = 0 end; return b end
local function at(b, n, x, y) if x < 0 or y < 0 or x >= n or y >= n then return nil end return b[y * n + x + 1] end
-- returns count (incl. cell) and open ends for player p if p stood on (x,y)
local function line(b, n, x, y, p, d)
    local cnt, open = 1, 0
    for s = -1, 1, 2 do
        local cx, cy = x + d[1] * s, y + d[2] * s
        while at(b, n, cx, cy) == p do cnt = cnt + 1; cx = cx + d[1] * s; cy = cy + d[2] * s end
        if at(b, n, cx, cy) == 0 then open = open + 1 end
    end
    return cnt, open
end
function TT.wins(b, n, k, x, y)
    local p = b[y * n + x + 1]
    if p == 0 then return false end
    for _, d in ipairs(DIRS) do
        if line(b, n, x, y, p, d) >= k then return true end
    end
    return false
end
function TT.winLine(b, n, k, x, y)
    local p = b[y * n + x + 1]
    for _, d in ipairs(DIRS) do
        if line(b, n, x, y, p, d) >= k then
            local cells = {y * n + x + 1}
            for s = -1, 1, 2 do
                local cx, cy = x + d[1] * s, y + d[2] * s
                while at(b, n, cx, cy) == p do cells[#cells + 1] = cy * n + cx + 1; cx = cx + d[1] * s; cy = cy + d[2] * s end
            end
            return cells
        end
    end
end
function TT.full(b) for i = 1, #b do if b[i] == 0 then return false end end return true end
local function cellScore(b, n, k, x, y, p)
    local tot = 0
    for _, d in ipairs(DIRS) do
        local c, o = line(b, n, x, y, p, d)
        if c >= k then tot = tot + 1e7
        elseif o > 0 then
            local v = 10 ^ c
            if c == k - 1 and o == 2 then v = v * 8 end
            if o == 1 then v = v * 0.3 end
            tot = tot + v
        end
    end
    return tot
end
local function candidates(b, n, rad)
    local c, any = {}, false
    for y = 0, n - 1 do for x = 0, n - 1 do
        if b[y * n + x + 1] ~= 0 then any = true end
    end end
    if not any then
        local m = math.floor(n / 2)
        return {{m, m}}
    end
    for y = 0, n - 1 do for x = 0, n - 1 do
        if b[y * n + x + 1] == 0 then
            local near = false
            for dy = -rad, rad do for dx = -rad, rad do
                local v = at(b, n, x + dx, y + dy)
                if v and v ~= 0 then near = true end
            end end
            if near then c[#c + 1] = {x, y} end
        end
    end end
    if #c == 0 then
        for y = 0, n - 1 do for x = 0, n - 1 do if b[y * n + x + 1] == 0 then c[#c + 1] = {x, y} end end end
    end
    return c
end
local function heur(b, n, k, x, y, me, opp)
    local ctr = (n - 1) / 2
    return cellScore(b, n, k, x, y, me) + 0.95 * cellScore(b, n, k, x, y, opp) - (math.abs(x - ctr) + math.abs(y - ctr)) * 0.01
end
-- perfect play for tiny boards
local function minimax(b, n, k, turn, me, opp, alpha, beta, depth)
    local best = turn == me and -math.huge or math.huge
    local moved = false
    for i = 1, n * n do
        if b[i] == 0 then
            moved = true
            local x, y = (i - 1) % n, math.floor((i - 1) / n)
            b[i] = turn
            local v
            if TT.wins(b, n, k, x, y) then v = (turn == me) and (10 - depth) or (depth - 10)
            else v = minimax(b, n, k, turn == me and opp or me, me, opp, alpha, beta, depth + 1) end
            b[i] = 0
            if turn == me then if v > best then best = v end; if best > alpha then alpha = best end
            else if v < best then best = v end; if best < beta then beta = best end end
            if beta <= alpha then break end
        end
    end
    if not moved then return 0 end
    return best
end
-- level 1..4 ; returns x,y
function TT.bot(b, n, k, me, level, rng)
    local opp = me == 1 and 2 or 1
    local cands = candidates(b, n, 2)
    -- immediate win / block
    local function findWin(p)
        for _, c in ipairs(cands) do
            b[c[2] * n + c[1] + 1] = p
            local w = TT.wins(b, n, k, c[1], c[2])
            b[c[2] * n + c[1] + 1] = 0
            if w then return c end
        end
    end
    if level == 1 and rng() < 0.4 then
        local all = {}
        for i = 1, n * n do if b[i] == 0 then all[#all + 1] = {(i - 1) % n, math.floor((i - 1) / n)} end end
        local c = all[rng(#all)]; return c[1], c[2]
    end
    local w = findWin(me); if w then return w[1], w[2] end
    local bl = findWin(opp)
    if bl and (level >= 2 or rng() < 0.7) then return bl[1], bl[2] end
    if level == 1 then
        local c = cands[rng(#cands)]; return c[1], c[2]
    end
    if n * n <= 9 and level == 3 and rng() < 0.15 then
        local all = {}
        for i = 1, n * n do if b[i] == 0 then all[#all + 1] = {(i - 1) % n, math.floor((i - 1) / n)} end end
        local c = all[rng(#all)]; return c[1], c[2]
    end
    if n * n <= 9 and level >= 3 then
        local bestV, bm = -math.huge, nil
        for i = 1, 9 do
            if b[i] == 0 then
                local x, y = (i - 1) % n, math.floor((i - 1) / n)
                b[i] = me
                local v = minimax(b, n, k, opp, me, opp, -math.huge, math.huge, 1)
                b[i] = 0
                if v > bestV then bestV = v; bm = {x, y} end
            end
        end
        if bm then return bm[1], bm[2] end
    end
    local scored = {}
    for _, c in ipairs(cands) do scored[#scored + 1] = {c[1], c[2], heur(b, n, k, c[1], c[2], me, opp)} end
    table.sort(scored, function(a, z) return a[3] > z[3] end)
    if level == 2 then
        local pick = scored[rng(math.min(3, #scored))]
        return pick[1], pick[2]
    end
    if level == 3 then return scored[1][1], scored[1][2] end
    -- level 4: 2-ply (my move, their best reply)
    local top = math.min(8, #scored)
    local bestV, bm = -math.huge, scored[1]
    for t = 1, top do
        local s = scored[t]
        b[s[2] * n + s[1] + 1] = me
        local worst = 0
        for _, c in ipairs(candidates(b, n, 1)) do
            local sc = cellScore(b, n, k, c[1], c[2], opp) + 0.5 * cellScore(b, n, k, c[1], c[2], me)
            if sc > worst then worst = sc end
        end
        b[s[2] * n + s[1] + 1] = 0
        local v = s[3] - 0.9 * worst
        if v > bestV then bestV = v; bm = s end
    end
    return bm[1], bm[2]
end

------------------------------------------------------------ BATTLESHIP
local BS = {}
L.BS = BS
BS.N = 10
BS.FLEET = {5, 4, 3, 3, 2}
function BS.place(rng)
    local N = BS.N
    local own, ships = {}, {}
    for i = 1, N * N do own[i] = 0 end
    for sid, len in ipairs(BS.FLEET) do
        local ok = false
        local tries = 0
        while not ok and tries < 500 do
            tries = tries + 1
            local hor = rng(2) == 1
            local x = rng(hor and (N - len + 1) or N) - 1
            local y = rng(hor and N or (N - len + 1)) - 1
            local cells, free = {}, true
            for s = 0, len - 1 do
                local cx, cy = x + (hor and s or 0), y + (hor and 0 or s)
                local i = cy * N + cx + 1
                if own[i] ~= 0 then free = false; break end
                cells[#cells + 1] = i
            end
            if free then
                for _, i in ipairs(cells) do own[i] = sid end
                ships[sid] = {len = len, cells = cells, hits = 0}
                ok = true
            end
        end
    end
    return {own = own, ships = ships, shots = {}, left = #BS.FLEET}
end
-- fire at idx on board 'B' ; returns res (0 miss,1 hit,2 sunk), shipId, over
function BS.fire(B, idx)
    if B.shots[idx] then return nil end
    local sid = B.own[idx]
    if sid == 0 then B.shots[idx] = 1; return 0 end
    B.shots[idx] = 2
    local sh = B.ships[sid]
    sh.hits = sh.hits + 1
    if sh.hits >= sh.len then
        B.left = B.left - 1
        return 2, sid, B.left == 0
    end
    return 1, sid, false
end
-- AI state tracks what the bot knows about the enemy board
function BS.ai()
    local k = {}
    for i = 1, BS.N * BS.N do k[i] = 0 end -- 0 unknown 1 miss 2 hit 3 sunk
    local rem = {}
    for _, l in ipairs(BS.FLEET) do rem[#rem + 1] = l end
    return {k = k, rem = rem}
end
function BS.aiResult(ai, idx, res, cells)
    if res == 0 then ai.k[idx] = 1
    elseif res == 1 then ai.k[idx] = 2
    else
        ai.k[idx] = 2
        for _, i in ipairs(cells or {idx}) do ai.k[i] = 3 end
        for t, l in ipairs(ai.rem) do if l == #(cells or {}) then table.remove(ai.rem, t); break end end
    end
end
function BS.aiShot(ai, level, rng)
    local N = BS.N
    local k = ai.k
    local unknown = {}
    for i = 1, N * N do if k[i] == 0 then unknown[#unknown + 1] = i end end
    local hits = {}
    for i = 1, N * N do if k[i] == 2 then hits[#hits + 1] = i end end
    local function pick(list) return list[rng(#list)] end
    if level == 1 then return pick(unknown) end
    if level <= 3 and #hits > 0 then
        local tgt, line = {}, {}
        for _, h in ipairs(hits) do
            local x, y = (h - 1) % N, math.floor((h - 1) / N)
            for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
                local nx, ny = x + d[1], y + d[2]
                if nx >= 0 and ny >= 0 and nx < N and ny < N then
                    local j = ny * N + nx + 1
                    if k[j] == 0 then
                        tgt[#tgt + 1] = j
                        local ox, oy = x - d[1], y - d[2]
                        if ox >= 0 and oy >= 0 and ox < N and oy < N and k[oy * N + ox + 1] == 2 then line[#line + 1] = j end
                    end
                end
            end
        end
        if level >= 3 and #line > 0 then return pick(line) end
        if #tgt > 0 then return pick(tgt) end
    end
    if level == 2 then return pick(unknown) end
    if level == 3 then
        local par = {}
        for _, i in ipairs(unknown) do local x, y = (i - 1) % N, math.floor((i - 1) / N); if (x + y) % 2 == 0 then par[#par + 1] = i end end
        if #par > 0 then return pick(par) end
        return pick(unknown)
    end
    -- level 4: probability density
    local w = {}
    for i = 1, N * N do w[i] = 0 end
    for _, len in ipairs(ai.rem) do
        for y = 0, N - 1 do for x = 0, N - 1 do
            for o = 0, 1 do
                local ok, cells, hitc = true, {}, 0
                for s = 0, len - 1 do
                    local cx, cy = x + (o == 0 and s or 0), y + (o == 1 and s or 0)
                    if cx >= N or cy >= N then ok = false; break end
                    local v = k[cy * N + cx + 1]
                    if v == 1 or v == 3 then ok = false; break end
                    if v == 2 then hitc = hitc + 1 end
                    cells[#cells + 1] = cy * N + cx + 1
                end
                if ok then
                    local wt = 1 + hitc * 60
                    for _, i in ipairs(cells) do if k[i] == 0 then w[i] = w[i] + wt end end
                end
            end
        end end
    end
    local best, bl = -1, {}
    for _, i in ipairs(unknown) do
        local v = w[i] + (((i - 1) % N + math.floor((i - 1) / N)) % 2 == 0 and 0.01 or 0)
        if v > best + 1e-9 then best = v; bl = {i} elseif math.abs(v - best) < 1e-9 then bl[#bl + 1] = i end
    end
    return pick(bl)
end

return L

end)()
;(function()
local LG = X.MG.L
local MS, TT, BS = LG.MS, LG.TT, LG.BS
local DIFFS = {"easy", "normal", "hard", "impossible"}
local MG = X.MG
MG.diff = 1
MG.open = false

------------------------------------------------------------------ transport (server chat; script users only, hidden from their chat)
local NET = {lobby = "L", inbox = {}, queue = {}, seenId = {}, nonce = tostring(LocalPlayer.UserId)}
local TAG = "[pdl]"
local STRKEYS = {id = true, cells = true, to = true}
local function enc(topic, t)
    local parts = {}
    for k, v in pairs(t) do if k ~= "n" and k ~= "u" then parts[#parts + 1] = k .. "=" .. tostring(v) end end
    return TAG .. topic .. "|" .. table.concat(parts, ";")
end
local function dec(text)
    if string.sub(text, 1, #TAG) ~= TAG then return end
    local topic, rest = string.match(text, "^%[pdl%]([%w]+)|(.*)$")
    if not topic then return end
    local d = {}
    for k, v in string.gmatch(rest, "([%w_]+)=([^;]*)") do
        if STRKEYS[k] then d[k] = v
        elseif v == "true" then d[k] = true
        elseif v == "false" then d[k] = false
        elseif string.match(v, "^%-?%d+$") then d[k] = tonumber(v)
        else d[k] = v end
    end
    return topic, d
end
local function sendChat(text)
    local ok = pcall(function()
        local TCS = game:GetService("TextChatService")
        if TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then error("legacy") end
        local ch = TCS.TextChannels:FindFirstChild("RBXGeneral") or TCS.TextChannels:GetChildren()[1]
        ch:SendAsync(text)
    end)
    if ok then return end
    pcall(function() ReplicatedStorage:FindFirstChild("SayMessageRequest", true):FireServer(text, "All") end)
end
function NET.pub(topic, tbl)
    NET.queue[#NET.queue + 1] = enc(topic, tbl)
    if NET.busy then return end
    NET.busy = true
    task.spawn(function()
        while #NET.queue > 0 and not Library.Unloaded do
            sendChat(table.remove(NET.queue, 1))
            task.wait(1.25)
        end
        NET.busy = false
    end)
end
function NET.poll(topic, since)
    local box = NET.inbox[topic] or {}
    local s = tonumber(since) or 0
    local out = {}
    for i = s + 1, #box do out[#out + 1] = box[i] end
    return out, #box, true
end
local function ingest(plr, text)
    if not plr or plr == LocalPlayer then return end
    local topic, d = dec(text)
    if not d then return end
    d.n = tostring(plr.UserId); d.u = plr.Name; d._time = os.time()
    local box = NET.inbox[topic]
    if not box then box = {}; NET.inbox[topic] = box end
    box[#box + 1] = d
    if #box > 400 then table.remove(box, 1) end
    if topic == NET.lobby and d.t == "who" and MG.hosting and MG.hosting.alive and MG.advertise then MG.advertise() end
end
do
    local TCS
    pcall(function() TCS = game:GetService("TextChatService") end)
    local modern = false
    pcall(function() modern = TCS and TCS.ChatVersion == Enum.ChatVersion.TextChatService end)
    if modern then
        local function onMsg(msg)
            pcall(function()
                if msg.MessageId and NET.seenId[msg.MessageId] then return end
                if msg.MessageId then NET.seenId[msg.MessageId] = true end
                local src = msg.TextSource
                if src and string.sub(msg.Text or "", 1, #TAG) == TAG then ingest(Players:GetPlayerByUserId(src.UserId), msg.Text) end
            end)
        end
        local okSvc = pcall(function() Connect(TCS.MessageReceived, onMsg) end)
        if not okSvc then
            pcall(function()
                for _, ch in ipairs(TCS.TextChannels:GetChildren()) do Connect(ch.MessageReceived, onMsg) end
                Connect(TCS.TextChannels.ChildAdded, function(ch) pcall(function() Connect(ch.MessageReceived, onMsg) end) end)
            end)
        end
        pcall(function()
            local old = TCS.OnIncomingMessage
            TCS.OnIncomingMessage = function(msg)
                local props
                if old then local ok, r = pcall(old, msg); if ok then props = r end end
                if string.sub(msg.Text or "", 1, #TAG) == TAG then
                    props = props or Instance.new("TextChatMessageProperties")
                    props.Text = ""; props.PrefixText = ""
                end
                return props
            end
        end)
    else
        local function hook(p) Connect(p.Chatted, function(m) ingest(p, m) end) end
        for _, p in ipairs(Players:GetPlayers()) do hook(p) end
        Connect(Players.PlayerAdded, hook)
    end
end

------------------------------------------------------------------ style
local PAL = {
    bg = Color3.fromRGB(13, 13, 17), card = Color3.fromRGB(21, 21, 27), card2 = Color3.fromRGB(30, 30, 39), hover = Color3.fromRGB(44, 44, 58),
    line = Color3.fromRGB(40, 40, 52), text = Color3.fromRGB(235, 235, 243), dim = Color3.fromRGB(142, 142, 160), dark = Color3.fromRGB(14, 14, 18),
    good = Color3.fromRGB(96, 214, 128), bad = Color3.fromRGB(240, 98, 104), warn = Color3.fromRGB(255, 196, 84),
}
local DCOL = {Color3.fromRGB(96, 214, 128), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 176, 70), Color3.fromRGB(240, 98, 104)}
local ACC = {ms = Color3.fromRGB(90, 160, 255), ttt = Color3.fromRGB(255, 118, 128), bs = Color3.fromRGB(70, 206, 200), dino = Color3.fromRGB(120, 220, 130)}
local FONT, FONTB = Enum.Font.GothamMedium, Enum.Font.GothamBold
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = o; return c end
local function stroke(o, col, th, tr)
    local s = Instance.new("UIStroke"); s.Color = col or PAL.line; s.Thickness = th or 1; s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function grad(o, c1, c2, rot)
    local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 90; g.Parent = o; return g
end
local function box(parent, size, pos, col, r)
    local f = New("Frame", {Size = size, Position = pos or UDim2.new(), BackgroundColor3 = col or PAL.card, BorderSizePixel = 0, Parent = parent})
    if r then corner(f, r) end
    return f
end
local function txt(parent, t, size, pos, ts, col, align, bold)
    return New("TextLabel", {Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1, Text = t, TextSize = ts or 10, TextColor3 = col or PAL.text,
        Font = bold and FONTB or FONT, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = parent})
end
-- style: "primary" (accent fill) | "ghost" | "danger"
local function button(parent, t, size, pos, cb, style, accent, ts)
    style = style or "ghost"
    local base = style == "primary" and (accent or PAL.text) or PAL.card2
    local over = style == "primary" and base:Lerp(Color3.new(1, 1, 1), 0.18) or (style == "danger" and PAL.bad or PAL.hover)
    local b = New("TextButton", {Size = size, Position = pos or UDim2.new(), BackgroundColor3 = base, Text = t, TextSize = ts or 10, Font = FONTB,
        TextColor3 = style == "primary" and PAL.dark or PAL.text, AutoButtonColor = false, Parent = parent})
    corner(b, 6)
    if style ~= "primary" then stroke(b, PAL.line) end
    Connect(b.MouseEnter, function() if not b:GetAttribute("sel") then Tween(b, TWEEN_FAST, {BackgroundColor3 = over}) end end)
    Connect(b.MouseLeave, function() if not b:GetAttribute("sel") then Tween(b, TWEEN_FAST, {BackgroundColor3 = b:GetAttribute("base") and b:GetAttribute("base") or base}) end end)
    if cb then Connect(b.MouseButton1Click, function() playSound(Sounds.Click, 0.4); cb(b) end) end
    return b
end

local function mkGrip(parent, getSize, setSize, getScale, minW, minH, maxW, maxH)
    local g = New("TextButton", {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, Text = "", ZIndex = 30, Parent = parent})
    for _, p in ipairs({{12, 12}, {8, 12}, {12, 8}, {4, 12}, {12, 4}, {8, 8}}) do
        box(g, UDim2.fromOffset(2, 2), UDim2.fromOffset(p[1], p[2]), PAL.dim, 1).ZIndex = 31
    end
    local rs, sp, ss = false, nil, nil
    Connect(g.InputBegan, function(i) if IsPress(i) then rs = true; sp = i.Position; ss = getSize(); EX.modal(true) end end)
    Connect(UIS.InputChanged, function(i)
        if rs and IsMove(i) then
            local d = (i.Position - sp) / (getScale and getScale() or 1)
            setSize(math.clamp(ss.X + d.X, minW, maxW), math.clamp(ss.Y + d.Y, minH, maxH))
        end
    end)
    Connect(UIS.InputEnded, function(i) if rs and IsPress(i) then rs = false; EX.modal(false) end end)
    return g
end

------------------------------------------------------------------ gui
local gui = New("ScreenGui", {Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1001})
gui.Parent = GetGuiParent()
MG.gui = gui
do
    local old = Library.Unload
    Library.Unload = function(self, ...) MG.dead = true; MG.closeGame(); pcall(function() gui:Destroy() end); return old(self, ...) end
end

-- game window ----------------------------------------------------
local HEADER, FOOT = 36, 36
local gw = New("Frame", {Name = "MGWindow", Size = UDim2.fromOffset(360, 420), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = PAL.bg, Visible = false, Active = true, Parent = gui})
corner(gw, 10); stroke(gw, PAL.line)
local gwHead = box(gw, UDim2.new(1, 0, 0, HEADER), nil, PAL.card2, 10)
box(gwHead, UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 1, -10), PAL.card2, nil)
grad(gwHead, PAL.card2:Lerp(Color3.new(1, 1, 1), 0.04), PAL.card, 90)
local gwStripe = box(gwHead, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), ACC.ttt, nil)
local gwTitle = txt(gwHead, "game", UDim2.new(1, -140, 1, -2), UDim2.fromOffset(14, 0), 13, PAL.text, nil, true)
local gwChip = box(gwHead, UDim2.fromOffset(64, 18), UDim2.new(1, -108, 0.5, -10), DCOL[1], 9)
local gwChipTxt = txt(gwChip, "easy", UDim2.fromScale(1, 1), nil, 9, PAL.dark, Enum.TextXAlignment.Center, true)
local gwClose = button(gwHead, "x", UDim2.fromOffset(24, 22), UDim2.new(1, -34, 0.5, -11), function() MG.closeGame() end, "danger", nil, 11)
local gwCard = box(gw, UDim2.new(1, -12, 1, -(HEADER + FOOT + 4)), UDim2.fromOffset(6, HEADER + 4), PAL.card, 8)
stroke(gwCard, PAL.line, 1, 0.4)
local gwBody = New("Frame", {Size = UDim2.fromOffset(300, 300), Position = UDim2.fromOffset(10, HEADER + 8), BackgroundTransparency = 1, Parent = gw})
local gwScale = New("UIScale", {Scale = 1, Parent = gwBody})
local gwFoot = box(gw, UDim2.new(1, -40, 0, 24), UDim2.new(0, 6, 1, -30), PAL.card, 12)
local gwDot = box(gwFoot, UDim2.fromOffset(8, 8), UDim2.new(0, 10, 0.5, -4), PAL.dim, 4)
local gwStatus = txt(gwFoot, "", UDim2.new(1, -30, 1, 0), UDim2.fromOffset(24, 0), 10, PAL.dim)
gwStatus.TextTruncate = Enum.TextTruncate.AtEnd
MakeDraggable(gwHead, gw, function() return 1 end)

MG.base = Vector2.new(360, 420)
function MG.fit()
    local base = MG.base
    local w, h = gw.Size.X.Offset, gw.Size.Y.Offset
    local sc = math.min((w - 20) / math.max(base.X - 20, 1), (h - (HEADER + FOOT + 12)) / math.max(base.Y - (HEADER + FOOT + 12), 1))
    gwScale.Scale = math.clamp(sc, 0.4, 4)
end
mkGrip(gw, function() return Vector2.new(gw.Size.X.Offset, gw.Size.Y.Offset) end, function(w, h) gw.Size = UDim2.fromOffset(w, h); MG.fit() end, nil, 240, 220, 1100, 1100)
-- every game gives the size of its content; the window adds header/footer
local function setContent(w, h) gw.Size = UDim2.fromOffset(w + 20, h + HEADER + FOOT + 12) end

MG.cur = nil
local function setStatus(t, col)
    gwStatus.Text = t; gwStatus.TextColor3 = col or PAL.dim; gwDot.BackgroundColor3 = col or PAL.dim
end
local function setTitle(name, diff, opp, accent)
    gwTitle.Text = name .. (opp and ("  vs " .. tostring(opp)) or "")
    gwChip.BackgroundColor3 = DCOL[diff] or PAL.dim
    gwChipTxt.Text = DIFFS[diff] or ""
    gwStripe.BackgroundColor3 = accent or PAL.dim
end
local CAS = game:GetService("ContextActionService")
function MG.freeze(on)
    on = on and true or false
    if MG.frozen == on then return end
    MG.frozen = on
    if on then
        pcall(function()
            CAS:BindActionAtPriority("PiddleMGFreeze", function() return Enum.ContextActionResult.Sink end, false, 3000,
                Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down,
                Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.LeftShift)
        end)
    else
        pcall(function() CAS:UnbindAction("PiddleMGFreeze") end)
    end
end
function MG.closeGame()
    MG.freeze(false)
    local c = MG.cur
    MG.cur = nil
    if c then
        pcall(function() if c.destroy then c.destroy() end end)
        if c.ses then c.ses.alive = false; pcall(NET.pub, c.ses.topic, {t = "quit"}) end
    end
    for _, ch in ipairs(gwBody:GetChildren()) do if not ch:IsA("UIScale") then ch:Destroy() end end
    gw.Visible = false
end

------------------------------------------------------------------ online session
-- ses = {topic, role="host"|"guest", opp, oppNonce, seed, diff, game, alive}
local function startPolling(ses, onMsg)
    task.spawn(function()
        local since = 0
        while ses.alive and not MG.dead and not Library.Unloaded do
            local list, cur = NET.poll(ses.topic, since)
            since = cur
            for _, m in ipairs(list) do
                if not ses.oppNonce or m.n == ses.oppNonce then
                    ses.oppNonce = ses.oppNonce or m.n; ses.opp = m.u
                    pcall(onMsg, m)
                end
            end
            task.wait(0.6)
        end
    end)
end
local function newId() return string.lower(string.format("%x%x", math.random(0x1000, 0xffff), math.random(0x1000, 0xffff))) end

local function pill(parent, w, pos)
    local f = box(parent, UDim2.fromOffset(w, 20), pos, PAL.card2, 10)
    local l = txt(f, "", UDim2.fromScale(1, 1), nil, 10, PAL.text, Enum.TextXAlignment.Center, true)
    return f, l
end

------------------------------------------------------------------ MINESWEEPER
local MSIZE = {8, 20, 35, 100}
local NUMCOL = {Color3.fromRGB(96, 165, 255), Color3.fromRGB(96, 214, 128), Color3.fromRGB(240, 98, 104), Color3.fromRGB(176, 130, 255), Color3.fromRGB(255, 176, 70), Color3.fromRGB(70, 210, 210), Color3.fromRGB(225, 225, 235), Color3.fromRGB(150, 150, 165)}
local C_HID, C_HID_ALT, C_OPEN, C_FLAG, C_MINE = Color3.fromRGB(46, 52, 70), Color3.fromRGB(41, 47, 64), Color3.fromRGB(15, 16, 22), Color3.fromRGB(72, 58, 36), Color3.fromRGB(170, 48, 60)
function MG.minesweeper(diff, ses)
    local n = MSIZE[diff]
    local seed = ses and ses.seed or math.random(1, 2000000000)
    local g = MS.new(n, seed)
    local c = math.floor(n / 2)
    MS.reveal(g, c, c)
    local vw = math.min(n, 18)
    local cs = 18
    local ox = math.clamp(c - math.floor(vw / 2), 0, n - vw)
    local oy = ox
    local flagMode, t0, finished = false, os.clock(), false
    local myRes, oppRes
    setContent(vw * cs + 2, vw * cs + 58)
    setTitle("Minesweeper " .. n .. "x" .. n, diff, ses and ses.opp, ACC.ms)
    local pm, pmL = pill(gwBody, 74, UDim2.fromOffset(0, 0))
    local pf, pfL = pill(gwBody, 66, UDim2.fromOffset(80, 0))
    local pt, ptL = pill(gwBody, 62, UDim2.fromOffset(152, 0))
    local fbtn = button(gwBody, "flag: off", UDim2.fromOffset(78, 20), UDim2.new(0, vw * cs + 2 - 78, 0, 0), function(b)
        flagMode = not flagMode
        b.Text = flagMode and "flag: on" or "flag: off"
        b:SetAttribute("sel", flagMode)
        b:SetAttribute("base", flagMode and C_FLAG or nil)
        Tween(b, TWEEN_FAST, {BackgroundColor3 = flagMode and C_FLAG or PAL.card2})
    end, "ghost", nil, 9)
    local board = New("Frame", {Size = UDim2.fromOffset(vw * cs, vw * cs), Position = UDim2.fromOffset(1, 26), BackgroundTransparency = 1, Parent = gwBody})
    local pool = {}
    local function render()
        for j = 0, vw - 1 do
            for i = 0, vw - 1 do
                local b = pool[j * vw + i + 1]
                local gx, gy = ox + i, oy + j
                local idx = gy * n + gx + 1
                local st = g.st[idx]
                if st == 1 then
                    if g.mine[idx] then b.Text = "*"; b.BackgroundColor3 = C_MINE; b.TextColor3 = Color3.new(1, 1, 1)
                    else
                        local k = g.cnt[idx]
                        b.Text = k > 0 and tostring(k) or ""
                        b.TextColor3 = NUMCOL[k] or PAL.text
                        b.BackgroundColor3 = C_OPEN
                    end
                elseif st == 2 then b.Text = "F"; b.TextColor3 = PAL.warn; b.BackgroundColor3 = C_FLAG
                else
                    local alt = (gx + gy) % 2 == 0
                    if g.dead and g.mine[idx] then b.Text = "*"; b.TextColor3 = PAL.bad; b.BackgroundColor3 = C_HID
                    else b.Text = ""; b.BackgroundColor3 = alt and C_HID or C_HID_ALT end
                end
            end
        end
    end
    local function elapsed() return math.floor(os.clock() - t0) end
    local function resolve()
        if not myRes or not ses then return end
        if myRes.ok and not oppRes then setStatus("cleared! waiting for opponent...", PAL.good); return end
        if not oppRes then return end
        local win
        if myRes.ok and not oppRes.ok then win = true
        elseif oppRes.ok and not myRes.ok then win = false
        elseif myRes.ok and oppRes.ok then win = myRes.time <= oppRes.time
        else win = myRes.rev >= oppRes.rev end
        setStatus(win and "you win!" or "you lose", win and PAL.good or PAL.bad)
    end
    local function finish(ok)
        if finished then return end
        finished = true
        myRes = {ok = ok, time = elapsed(), rev = g.revealed}
        if ses then NET.pub(ses.topic, {t = "fin", ok = ok, time = myRes.time, rev = g.revealed}) end
        if not ses then setStatus(ok and ("cleared in " .. myRes.time .. "s!") or "boom! you hit a mine", ok and PAL.good or PAL.bad)
        else
            if not ok then setStatus("boom! waiting for result...", PAL.bad) end
            resolve()
        end
    end
    local function act(i, j, right)
        if finished then return end
        local gx, gy = ox + i, oy + j
        local idx = gy * n + gx + 1
        if right or flagMode then MS.flag(g, gx, gy)
        elseif g.st[idx] == 1 then MS.chord(g, gx, gy)
        else MS.reveal(g, gx, gy) end
        render()
        if g.dead then finish(false) elseif g.won then finish(true) end
    end
    for j = 0, vw - 1 do
        for i = 0, vw - 1 do
            local b = New("TextButton", {Size = UDim2.fromOffset(cs - 1, cs - 1), Position = UDim2.fromOffset(i * cs, j * cs), BackgroundColor3 = C_HID, Text = "", TextSize = 11, Font = FONTB, TextColor3 = PAL.text, AutoButtonColor = false, Parent = board})
            corner(b, 3)
            Connect(b.MouseButton1Click, function() act(i, j, false) end)
            Connect(b.MouseButton2Click, function() act(i, j, true) end)
            pool[j * vw + i + 1] = b
        end
    end
    local pad = New("Frame", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 26 + vw * cs + 6), BackgroundTransparency = 1, Parent = gwBody})
    local step = math.max(1, math.floor(vw / 2))
    local coord = txt(pad, "", UDim2.new(1, -130, 1, 0), nil, 9, PAL.dim)
    local function pan(dx, dy)
        ox = math.clamp(ox + dx * step, 0, n - vw); oy = math.clamp(oy + dy * step, 0, n - vw)
        coord.Text = n > vw and string.format("view  x %d-%d   y %d-%d", ox + 1, ox + vw, oy + 1, oy + vw) or ""
        render()
    end
    if n > vw then
        local px = vw * cs + 2
        button(pad, "<", UDim2.fromOffset(28, 22), UDim2.fromOffset(px - 120, 0), function() pan(-1, 0) end, "ghost", nil, 11)
        button(pad, "^", UDim2.fromOffset(28, 22), UDim2.fromOffset(px - 90, 0), function() pan(0, -1) end, "ghost", nil, 11)
        button(pad, "v", UDim2.fromOffset(28, 22), UDim2.fromOffset(px - 60, 0), function() pan(0, 1) end, "ghost", nil, 11)
        button(pad, ">", UDim2.fromOffset(28, 22), UDim2.fromOffset(px - 30, 0), function() pan(1, 0) end, "ghost", nil, 11)
    end
    pan(0, 0)
    local alive = true
    task.spawn(function()
        while alive and not MG.dead do
            pmL.Text = "mines " .. g.mines
            pfL.Text = "flags " .. g.flags
            ptL.Text = (finished and myRes.time or elapsed()) .. "s"
            task.wait(0.5)
        end
    end)
    local ctl = {ses = ses, destroy = function() alive = false end}
    if ses then
        ctl.onNet = function(m)
            if m.t == "fin" then
                oppRes = {ok = m.ok, time = m.time or 0, rev = m.rev or 0}
                if not myRes then setStatus(m.ok and "opponent cleared the board!" or "opponent hit a mine", PAL.warn) end
                resolve()
            elseif m.t == "quit" then
                oppRes = {ok = false, time = 0, rev = 0}
                if not finished then setStatus("opponent left - you win", PAL.good); finished = true end
            end
        end
        setStatus("race! same board - clear it before the opponent", PAL.dim)
    else
        setStatus("left click: open   right click: flag", PAL.dim)
    end
    return ctl
end

------------------------------------------------------------------ pixel helpers
local function pixels(parent, rows, pal, px, x, y)
    local w = 0
    for _, r in ipairs(rows) do if #r > w then w = #r end end
    local f = New("Frame", {Size = UDim2.fromOffset(w * px, #rows * px), Position = UDim2.fromOffset(x or 0, y or 0), BackgroundTransparency = 1, Parent = parent})
    for r = 1, #rows do
        local row = rows[r]
        local c = 1
        while c <= #row do
            local ch = string.sub(row, c, c)
            if ch ~= "." and pal[ch] then
                local e = c
                while e < #row and string.sub(row, e + 1, e + 1) == ch do e = e + 1 end
                New("Frame", {Size = UDim2.fromOffset((e - c + 1) * px, px), Position = UDim2.fromOffset((c - 1) * px, (r - 1) * px), BackgroundColor3 = pal[ch], BorderSizePixel = 0, Parent = f})
                c = e + 1
            else c = c + 1 end
        end
    end
    return f, w * px, #rows * px
end
local function tweenTo(o, t, props, style) Tween(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) end

------------------------------------------------------------------ TIC TAC TOE
local TSIZE = {{3, 3}, {3, 3}, {3, 3}, {3, 3}}
local C_X, C_O = Color3.fromRGB(255, 118, 128), Color3.fromRGB(100, 170, 255)
local TSTATS = {w = 0, l = 0, d = 0}
function MG.ttt(diff, ses)
    local n, k = TSIZE[diff][1], TSIZE[diff][2]
    local cs = 72
    local b = TT.new(n)
    local rng = LG.RNG(os.time() + math.random(1, 9999))
    local mySide = (ses and ses.role == "guest") and 2 or 1
    local turn, over, alive, lastCell = 1, false, true, nil
    local TOP = 28
    setContent(n * cs + 4, n * cs + TOP + 38)
    setTitle("Tic Tac Toe " .. n .. "x" .. n .. "  /  " .. k .. " in a row", diff, ses and ses.opp, ACC.ttt)
    -- score board
    local function chip(x, w, col)
        local f = box(gwBody, UDim2.fromOffset(w, 22), UDim2.fromOffset(x, 0), PAL.card2, 11)
        stroke(f, col, 1, 0.55)
        return txt(f, "", UDim2.fromScale(1, 1), nil, 10, col, Enum.TextXAlignment.Center, true)
    end
    local bw = n * cs + 4
    local cw = math.floor((bw - 8) / 3)
    local youL = chip(0, cw, mySide == 1 and C_X or C_O)
    local drawL = chip(cw + 4, cw, PAL.dim)
    local oppL = chip((cw + 4) * 2, cw, mySide == 1 and C_O or C_X)
    local function score()
        local opp = ses and "OPP" or "BOT"
        youL.Text = "YOU " .. (mySide == 1 and "X" or "O") .. "  " .. (ses and "" or TSTATS.w)
        drawL.Text = "DRAWS  " .. (ses and "" or TSTATS.d)
        oppL.Text = opp .. " " .. (mySide == 1 and "O" or "X") .. "  " .. (ses and "" or TSTATS.l)
    end
    score()
    local board = box(gwBody, UDim2.fromOffset(n * cs + 4, n * cs + 4), UDim2.fromOffset(0, TOP), PAL.bg, 10)
    stroke(board, PAL.line)
    local cells, marks = {}, {}
    local th = math.max(3, math.floor(cs * 0.09))
    local function mkMark(parent, side, ghost)
        local m = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent})
        local sc = New("UIScale", {Scale = ghost and 1 or 0.2, Parent = m})
        local tr = ghost and 0.65 or 0
        if side == 1 then
            local len = math.floor(cs * 0.6)
            for _, rot in ipairs({45, -45}) do
                local bar = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(len, th), Rotation = rot, BackgroundColor3 = C_X, BackgroundTransparency = tr, BorderSizePixel = 0, Parent = m})
                corner(bar, th)
            end
        else
            local d = math.floor(cs * 0.52)
            local ring = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1, Parent = m})
            corner(ring, d); stroke(ring, C_O, th, tr)
        end
        if not ghost then tweenTo(sc, 0.22, {Scale = 1}, Enum.EasingStyle.Back) end
        return m
    end
    local function status()
        if over then return end
        if turn == mySide then setStatus("your turn  (" .. (mySide == 1 and "X" or "O") .. ")", mySide == 1 and C_X or C_O)
        else setStatus(ses and "opponent's turn..." or "bot is thinking...", PAL.dim) end
    end
    local function winLine(line)
        local first, last = line[1], line[#line]
        for _, i in ipairs(line) do cells[i].BackgroundColor3 = Color3.fromRGB(38, 78, 52); stroke(cells[i], PAL.good, 1, 0.2) end
        local function center(i) local x, y = (i - 1) % n, math.floor((i - 1) / n); return Vector2.new(2 + x * cs + (cs - 3) / 2, 2 + y * cs + (cs - 3) / 2) end
        local a, c = center(first), center(last)
        local mid = (a + c) / 2
        local len = (c - a).Magnitude + cs * 0.55
        local bar = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(mid.X, mid.Y), Size = UDim2.fromOffset(0, 5), Rotation = math.deg(math.atan2(c.Y - a.Y, c.X - a.X)), BackgroundColor3 = PAL.good, BorderSizePixel = 0, ZIndex = 8, Parent = board})
        corner(bar, 3)
        tweenTo(bar, 0.35, {Size = UDim2.fromOffset(len, 5)})
    end
    local function endGame(winner, x, y)
        over = true
        if winner then
            local line = TT.winLine(b, n, k, x, y)
            if line then winLine(line) end
            local me = winner == mySide
            setStatus(me and "you win!" or "you lose", me and PAL.good or PAL.bad)
            if not ses then if me then TSTATS.w = TSTATS.w + 1 else TSTATS.l = TSTATS.l + 1 end end
        else
            setStatus("draw", PAL.warn)
            if not ses then TSTATS.d = TSTATS.d + 1 end
        end
        score()
    end
    local function place(x, y, side)
        local i = y * n + x + 1
        if b[i] ~= 0 or over then return false end
        b[i] = side
        local cell = cells[i]
        for _, ch in ipairs(cell:GetChildren()) do if ch.Name == "Ghost" then ch:Destroy() end end
        marks[i] = mkMark(cell, side, false)
        if lastCell and cells[lastCell] then
            for _, ch in ipairs(cells[lastCell]:GetChildren()) do if ch.Name == "Last" then ch:Destroy() end end
        end
        lastCell = i
        local ls = stroke(cell, side == 1 and C_X or C_O, 1, 0.35); ls.Name = "Last"
        cell.BackgroundColor3 = C_HID_ALT
        if TT.wins(b, n, k, x, y) then endGame(side, x, y)
        elseif TT.full(b) then endGame(nil)
        else turn = side == 1 and 2 or 1; status() end
        return true
    end
    local function botMove()
        task.spawn(function()
            task.wait(0.4)
            if not alive or over or turn == mySide then return end
            local x, y = TT.bot(b, n, k, 2, diff, rng)
            place(x, y, 2)
        end)
    end
    for y = 0, n - 1 do for x = 0, n - 1 do
        local i = y * n + x + 1
        local c = New("TextButton", {Size = UDim2.fromOffset(cs - 3, cs - 3), Position = UDim2.fromOffset(2 + x * cs, 2 + y * cs), BackgroundColor3 = C_HID, Text = "", AutoButtonColor = false, Parent = board})
        corner(c, math.max(5, math.floor(cs / 6)))
        Connect(c.MouseEnter, function()
            if b[i] == 0 and not over and turn == mySide then
                Tween(c, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(58, 66, 90)})
                local g = mkMark(c, mySide, true); g.Name = "Ghost"
            end
        end)
        Connect(c.MouseLeave, function()
            for _, ch in ipairs(c:GetChildren()) do if ch.Name == "Ghost" then ch:Destroy() end end
            if b[i] == 0 and not over then Tween(c, TWEEN_FAST, {BackgroundColor3 = C_HID}) end
        end)
        Connect(c.MouseButton1Click, function()
            if over or turn ~= mySide or b[i] ~= 0 then return end
            place(x, y, mySide)
            if ses then NET.pub(ses.topic, {t = "m", x = x, y = y})
            elseif not over then botMove() end
        end)
        cells[i] = c
    end end
    local ctl = {ses = ses, destroy = function() alive = false end}
    if ses then
        ctl.onNet = function(m)
            if m.t == "m" and type(m.x) == "number" and type(m.y) == "number" then
                if turn ~= mySide and not over then place(m.x, m.y, mySide == 1 and 2 or 1) end
            elseif m.t == "quit" and not over then over = true; setStatus("opponent left - you win", PAL.good) end
        end
    else
        button(gwBody, "new game", UDim2.fromOffset(92, 24), UDim2.new(1, -92, 0, TOP + n * cs + 8), function() MG.start("ttt", diff) end, "primary", ACC.ttt, 10)
    end
    status()
    return ctl
end

------------------------------------------------------------------ BATTLESHIP (manual placement, standard rules)
local C_WATER, C_MISS, C_HIT, C_SUNK, C_SHIP, C_PEND = Color3.fromRGB(24, 40, 66), Color3.fromRGB(46, 70, 104), Color3.fromRGB(232, 122, 52), Color3.fromRGB(190, 56, 68), Color3.fromRGB(104, 122, 152), Color3.fromRGB(200, 190, 90)
local SHIPNAMES = {"Carrier", "Battleship", "Cruiser", "Submarine", "Destroyer"}
function MG.battleship(diff, ses)
    local N = BS.N
    local cs = 18
    local rng = LG.RNG(os.time() + math.random(1, 99999))
    local me = {own = {}, ships = {}, shots = {}, left = 0}
    for i = 1, N * N do me.own[i] = 0 end
    local placed = {}          -- sid -> {x,y,hor}
    local sel, horiz = 1, true
    local known = {}
    for i = 1, N * N do known[i] = 0 end
    local enemySunk = {}       -- list of lengths sunk
    local bot, ai
    if not ses then bot = BS.place(rng); ai = BS.ai() end
    local phase, myTurn, over, alive = "place", false, false, true
    local readyMe, readyOpp = false, false
    local bh = 11 + N * cs
    local SIDE = 112
    setContent(bh + 8 + SIDE, 15 + bh + 17 + bh + 8)
    setTitle("Battleship", diff, ses and ses.opp, ACC.bs)
    local function axes(parent)
        for i = 0, N - 1 do
            txt(parent, tostring(i + 1), UDim2.fromOffset(cs, 10), UDim2.fromOffset(11 + i * cs, 0), 8, PAL.dim, Enum.TextXAlignment.Center)
            txt(parent, string.sub("ABCDEFGHIJ", i + 1, i + 1), UDim2.fromOffset(10, cs), UDim2.fromOffset(0, 11 + i * cs), 8, PAL.dim, Enum.TextXAlignment.Center)
        end
    end
    local eTitle = txt(gwBody, "ENEMY WATERS", UDim2.fromOffset(bh, 12), nil, 9, ACC.bs, nil, true)
    local eHold = New("Frame", {Size = UDim2.fromOffset(bh, bh), Position = UDim2.fromOffset(2, 15), BackgroundTransparency = 1, Parent = gwBody}); axes(eHold)
    local mTitle = txt(gwBody, "YOUR FLEET", UDim2.fromOffset(bh, 12), UDim2.fromOffset(0, 15 + bh + 2), 9, PAL.dim, nil, true)
    local mHold = New("Frame", {Size = UDim2.fromOffset(bh, bh), Position = UDim2.fromOffset(2, 15 + bh + 17), BackgroundTransparency = 1, Parent = gwBody}); axes(mHold)
    local ec, mc = {}, {}
    -- placement helpers ---------------------------------------------------
    local function shipCells(len, x, y, hor)
        local cells = {}
        for s = 0, len - 1 do
            local cx, cy = x + (hor and s or 0), y + (hor and 0 or s)
            if cx >= N or cy >= N or cx < 0 or cy < 0 then return nil end
            cells[#cells + 1] = cy * N + cx + 1
        end
        return cells
    end
    local function canPlace(len, x, y, hor, ignoreSid)
        local cells = shipCells(len, x, y, hor)
        if not cells then return nil end
        for _, i in ipairs(cells) do if me.own[i] ~= 0 and me.own[i] ~= ignoreSid then return nil end end
        return cells
    end
    local function removeShip(sid)
        local sh = me.ships[sid]
        if not sh then return end
        for _, i in ipairs(sh.cells) do me.own[i] = 0 end
        me.ships[sid] = nil; placed[sid] = nil
    end
    local function allPlaced() for sid = 1, #BS.FLEET do if not placed[sid] then return false end end return true end
    local paintMine, paintEnemy, status, sideRefresh
    local function putShip(sid, x, y, hor)
        local cells = canPlace(BS.FLEET[sid], x, y, hor)
        if not cells then return false end
        for _, i in ipairs(cells) do me.own[i] = sid end
        me.ships[sid] = {len = BS.FLEET[sid], cells = cells, hits = 0}
        placed[sid] = {x = x, y = y, hor = hor}
        return true
    end
    local function nextUnplaced()
        for sid = 1, #BS.FLEET do if not placed[sid] then return sid end end
        return nil
    end
    local preview = {}
    local function clearPreview() for _, i in ipairs(preview) do if mc[i] then mc[i].BackgroundColor3 = nil end end preview = {}; paintMine() end
    local function showPreview(x, y)
        paintMine()
        if phase ~= "place" or readyMe or not sel then return end
        local len = BS.FLEET[sel]
        local cells = shipCells(len, x, y, horiz)
        local ok = cells and canPlace(len, x, y, horiz) ~= nil
        local col = ok and Color3.fromRGB(70, 170, 100) or Color3.fromRGB(180, 70, 80)
        for s = 0, len - 1 do
            local cx, cy = x + (horiz and s or 0), y + (horiz and 0 or s)
            if cx < N and cy < N then mc[cy * N + cx + 1].BackgroundColor3 = col end
        end
    end
    -- painting -------------------------------------------------------------
    function paintEnemy()
        for i = 1, N * N do
            local v, c = known[i], ec[i]
            if v == 0 then c.BackgroundColor3 = C_WATER; c.Text = ""
            elseif v == 4 then c.BackgroundColor3 = C_PEND; c.Text = ""
            elseif v == 1 then c.BackgroundColor3 = C_MISS; c.Text = "-"; c.TextColor3 = Color3.fromRGB(170, 195, 230)
            elseif v == 2 then c.BackgroundColor3 = C_HIT; c.Text = "x"; c.TextColor3 = Color3.new(1, 1, 1)
            else c.BackgroundColor3 = C_SUNK; c.Text = "x"; c.TextColor3 = Color3.new(1, 1, 1) end
        end
    end
    function paintMine()
        for i = 1, N * N do
            local sid, c = me.own[i], mc[i]
            local shot = me.shots[i]
            if shot == 2 then
                local sh = me.ships[sid]
                c.BackgroundColor3 = (sh and sh.hits >= sh.len) and C_SUNK or C_HIT
            elseif shot == 1 then c.BackgroundColor3 = C_MISS
            elseif sid ~= 0 then c.BackgroundColor3 = C_SHIP
            else c.BackgroundColor3 = C_WATER end
        end
    end
    -- side panel (fleet list + controls) ------------------------------------
    local side = box(gwBody, UDim2.fromOffset(SIDE, 15 + bh + 17 + bh), UDim2.fromOffset(bh + 8, 0), PAL.bg, 8)
    stroke(side, PAL.line, 1, 0.3)
    txt(side, "FLEET", UDim2.new(1, -8, 0, 14), UDim2.fromOffset(8, 4), 9, ACC.bs, nil, true)
    local shipRows = {}
    for sid, len in ipairs(BS.FLEET) do
        local r = New("TextButton", {Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 20 + (sid - 1) * 27), BackgroundColor3 = PAL.card2, Text = "", AutoButtonColor = false, Parent = side})
        corner(r, 6)
        local strokeObj = stroke(r, PAL.line, 1, 0.4)
        txt(r, SHIPNAMES[sid], UDim2.new(1, -4, 0, 11), UDim2.fromOffset(6, 1), 8, PAL.text, nil, true)
        local blocks = New("Frame", {Size = UDim2.fromOffset(len * 6, 6), Position = UDim2.fromOffset(6, 14), BackgroundTransparency = 1, Parent = r})
        for s = 0, len - 1 do box(blocks, UDim2.fromOffset(5, 6), UDim2.fromOffset(s * 6, 0), C_SHIP, 1) end
        shipRows[sid] = {btn = r, st = strokeObj, blocks = blocks}
        Connect(r.MouseButton1Click, function()
            if phase ~= "place" or readyMe then return end
            if placed[sid] then removeShip(sid); paintMine() end
            sel = sid; sideRefresh()
        end)
    end
    local info = txt(side, "", UDim2.new(1, -12, 0, 40), UDim2.fromOffset(8, 20 + 5 * 27), 8, PAL.dim)
    info.TextWrapped = true; info.TextYAlignment = Enum.TextYAlignment.Top
    function sideRefresh()
        for sid, r in pairs(shipRows) do
            local sh = me.ships[sid]
            local on = sel == sid and phase == "place"
            r.st.Color = on and ACC.bs or PAL.line
            r.st.Transparency = on and 0 or 0.4
            local col = C_SHIP
            if phase ~= "place" then
                col = (sh and sh.hits >= sh.len) and C_SUNK or C_SHIP
            elseif placed[sid] then col = Color3.fromRGB(80, 170, 110) end
            for _, bl in ipairs(r.blocks:GetChildren()) do bl.BackgroundColor3 = col end
        end
        if phase == "place" then
            info.Text = (readyMe and "waiting for opponent..." or ("place the " .. (sel and SHIPNAMES[sel] or "fleet") .. "  (" .. (horiz and "horizontal" or "vertical") .. ").  R rotates.  click a placed ship to move it."))
        else
            local alive_ = 0
            for _, sh in pairs(me.ships) do if sh.hits < sh.len then alive_ = alive_ + 1 end end
            local s = {}
            for _, l in ipairs(enemySunk) do s[#s + 1] = tostring(l) end
            info.Text = "your ships afloat: " .. alive_ .. "\nenemy sunk: " .. (#s > 0 and table.concat(s, ",") or "none")
        end
    end
    function status()
        if over then return end
        if phase == "place" then setStatus(readyMe and "waiting for opponent..." or (allPlaced() and "fleet ready - press ready" or "place your ships"), PAL.dim)
        elseif myTurn then setStatus("your turn - fire at enemy waters", PAL.text)
        else setStatus(ses and "opponent is aiming..." or "enemy is aiming...", PAL.dim) end
        sideRefresh()
    end
    local function lose() over = true; setStatus("your fleet is sunk - you lose", PAL.bad); sideRefresh() end
    local function win() over = true; setStatus("enemy fleet destroyed - you win!", PAL.good); sideRefresh() end
    local function botTurn()
        task.spawn(function()
            task.wait(0.6)
            if not alive or over then return end
            local idx = BS.aiShot(ai, diff, rng)
            local res, sid, done = BS.fire(me, idx)
            BS.aiResult(ai, idx, res, res == 2 and me.ships[sid].cells or nil)
            paintMine()
            if res == 2 then setStatus("enemy sank your " .. SHIPNAMES[sid] .. "!", PAL.bad) elseif res == 1 then setStatus("enemy hit your ship!", PAL.warn) end
            if done then lose() return end
            task.wait(0.9)
            myTurn = true; status()
        end)
    end
    local function applyResult(idx, res, cells, over2)
        if res == 0 then known[idx] = 1
        elseif res == 1 then known[idx] = 2
        else
            for _, i in ipairs(cells or {idx}) do known[i] = 3 end
            enemySunk[#enemySunk + 1] = cells and #cells or 1
        end
        paintEnemy()
        if res == 2 then setStatus("you sank a ship (" .. (cells and #cells or "?") .. ")!", PAL.good) elseif res == 1 then setStatus("hit!", PAL.warn) elseif res == 0 then setStatus("miss", PAL.dim) end
        sideRefresh()
        if over2 then win() end
    end
    local function fireAt(idx)
        if phase ~= "play" or not myTurn or over or known[idx] ~= 0 then return end
        myTurn = false
        if ses then
            known[idx] = 4
            paintEnemy()
            NET.pub(ses.topic, {t = "m", i = idx})
            status()
        else
            local res, sid, done = BS.fire(bot, idx)
            applyResult(idx, res, res == 2 and bot.ships[sid].cells or nil, done)
            if not over then task.delay(0.9, function() if alive and not over then botTurn() end end) end
        end
    end
    for y = 0, N - 1 do for x = 0, N - 1 do
        local i = y * N + x + 1
        local e = New("TextButton", {Size = UDim2.fromOffset(cs - 1, cs - 1), Position = UDim2.fromOffset(11 + x * cs, 11 + y * cs), BackgroundColor3 = C_WATER, Text = "", TextSize = 11, Font = FONTB, AutoButtonColor = false, Parent = eHold})
        corner(e, 3)
        Connect(e.MouseEnter, function() if known[i] == 0 and phase == "play" and myTurn and not over then Tween(e, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(50, 82, 128)}) end end)
        Connect(e.MouseLeave, function() if known[i] == 0 then Tween(e, TWEEN_FAST, {BackgroundColor3 = C_WATER}) end end)
        Connect(e.MouseButton1Click, function() fireAt(i) end)
        ec[i] = e
        local m = New("TextButton", {Size = UDim2.fromOffset(cs - 1, cs - 1), Position = UDim2.fromOffset(11 + x * cs, 11 + y * cs), BackgroundColor3 = C_WATER, Text = "", AutoButtonColor = false, Parent = mHold})
        corner(m, 3)
        Connect(m.MouseEnter, function() if phase == "place" and not readyMe then showPreview(x, y) end end)
        Connect(m.MouseLeave, function() if phase == "place" then paintMine() end end)
        Connect(m.MouseButton1Click, function()
            if phase ~= "place" or readyMe then return end
            local sid = me.own[i]
            if sid ~= 0 and not (sel and not placed[sel]) then removeShip(sid); sel = sid; paintMine(); showPreview(x, y); status(); return end
            if sel and not placed[sel] and putShip(sel, x, y, horiz) then
                sel = nextUnplaced()
                paintMine(); status()
            end
        end)
        mc[i] = m
    end end
    Connect(UIS.InputBegan, function(inp, gp)
        if not alive or UIS:GetFocusedTextBox() then return end
        if inp.KeyCode == Enum.KeyCode.R and phase == "place" and not readyMe then horiz = not horiz; sideRefresh() end
    end)
    local function startPlay()
        phase = "play"
        me.left = #BS.FLEET
        for _, sh in pairs(me.ships) do sh.hits = 0 end
        myTurn = (not ses) or ses.role == "host"
        eTitle.TextColor3 = ACC.bs
        paintMine(); status()
    end
    local barY = 15 + bh + 17 + bh + 6
    local bar = New("Frame", {Size = UDim2.fromOffset(SIDE, 22), Position = UDim2.fromOffset(bh + 8, barY - 6 - 22 - 4 - 0), BackgroundTransparency = 1, Parent = gwBody})
    bar:Destroy()
    local function sideBtn(label, y, cb, style, accent)
        return button(side, label, UDim2.new(1, -12, 0, 22), UDim2.new(0, 6, 0, y), cb, style or "ghost", accent, 9)
    end
    local sy = 20 + 5 * 27 + 44
    sideBtn("rotate (R)", sy, function() if phase == "place" and not readyMe then horiz = not horiz; sideRefresh() end end)
    sideBtn("randomize", sy + 26, function()
        if phase ~= "place" or readyMe then return end
        local R = BS.place(rng)
        me = {own = R.own, ships = R.ships, shots = {}, left = 0}
        for sid = 1, #BS.FLEET do placed[sid] = {} end
        sel = nil; paintMine(); status()
    end)
    sideBtn("clear", sy + 52, function()
        if phase ~= "place" or readyMe then return end
        me = {own = {}, ships = {}, shots = {}, left = 0}
        for i = 1, N * N do me.own[i] = 0 end
        placed = {}; sel = 1; paintMine(); status()
    end)
    sideBtn(ses and "ready" or "start", sy + 78, function()
        if phase ~= "place" or readyMe then return end
        if not allPlaced() then setStatus("place all 5 ships first", PAL.warn); return end
        readyMe = true
        if ses then
            NET.pub(ses.topic, {t = "ready"})
            if readyOpp then startPlay() else status() end
        else startPlay() end
    end, "primary", ACC.bs)
    paintMine(); paintEnemy()
    local ctl = {ses = ses, destroy = function() alive = false end}
    if ses then
        ctl.onNet = function(m)
            if m.t == "ready" then readyOpp = true; if readyMe and phase == "place" then startPlay() end
            elseif m.t == "m" and type(m.i) == "number" and phase == "play" and not over then
                local res, sid, done = BS.fire(me, m.i)
                if res then
                    local cells = res == 2 and table.concat(me.ships[sid].cells, ",") or ""
                    NET.pub(ses.topic, {t = "r", i = m.i, res = res, cells = cells, over = done and true or false})
                    paintMine()
                    if done then lose() else myTurn = true; status() end
                end
            elseif m.t == "r" and type(m.i) == "number" then
                local cells
                if m.cells and m.cells ~= "" then cells = {}; for v in string.gmatch(m.cells, "%d+") do cells[#cells + 1] = tonumber(v) end end
                applyResult(m.i, m.res, cells, m.over)
                if not over then status() end
            elseif m.t == "quit" and not over then over = true; setStatus("opponent left - you win", PAL.good) end
        end
    end
    status()
    return ctl
end

------------------------------------------------------------------ DINO (pixel art)
local DBASE = {240, 300, 360, 430}
local DRAMP = {0.008, 0.012, 0.016, 0.022}
local DMAX = {520, 600, 680, 780}
local DBIRD = {300, 200, 120, 60}
local DINO_BODY = {
    "........#######.", ".......#########", ".......##e######", ".......#########", ".......#########", ".......#####....", ".......#######..",
    "#.....#####.....", "##...######.....", "###.#########.#.", "###############.", ".#############..", "..###########...", "...##########...",
}
local LEG1 = {".....##...###....", ".....##...##.....", ".....##..........", ".....###........."}
local LEG2 = {".....###..##.....", "......##..##.....", "......##..###....", "................."}
local DINO_DUCK = {
    "..........########..", ".........##########.", ".........##e#######.", ".........###########", "#........##########.", "##.....############.",
    "###..##############.", "####################", ".##################.", "..################..", "....##........##....", "....##........##....",
}
local CACT_S = {"..##..", "..##..", "#.##.#", "#.##.#", "######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##.."}
local CACT_L = {"...##...", "...##...", "#..##..#", "#..##..#", "#..##..#", "##.##.##", ".######.", "..####..", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##..."}
local BIRD_UP = {"......##........", "......###.......", "...##.####......", "..###########.#.", "###############.", "..###########...", "....######......", "................"}
local BIRD_DN = {"................", "...........##...", "..###########.#.", "###############.", "..###########...", "....######......", "....###..###....", "....##....##...."}
local CLOUD = {"....####......", "..########....", ".###########..", "##############"}
function MG.dino(diff, ses)
    local W, H, GY = 340, 140, 118
    local rng = LG.RNG(ses and ses.seed or math.random(1, 2000000000))
    setContent(W + 2, H + 38)
    setTitle("Dino Run", diff, ses and ses.opp, ACC.dino)
    local world = New("Frame", {Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = Color3.fromRGB(26, 30, 42), ClipsDescendants = true, Active = true, Parent = gwBody})
    corner(world, 8); stroke(world, PAL.line)
    local sky = grad(world, Color3.fromRGB(30, 36, 58), Color3.fromRGB(16, 18, 26), 90)
    local FG, CACT, BIRD, CLOUDC = ACC.dino, Color3.fromRGB(86, 168, 104), Color3.fromRGB(236, 176, 96), Color3.fromRGB(52, 60, 84)
    local function blk(p, x, y, w, h, col) return New("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col or FG, BorderSizePixel = 0, Parent = p}) end
    -- sky: stars, moon, clouds
    local starRng = LG.RNG(7)
    for _ = 1, 22 do
        local s = blk(world, starRng(W) - 1, starRng(70) - 1, starRng(2), starRng(2), Color3.fromRGB(150, 160, 190))
        s.BackgroundTransparency = 0.3 + starRng() * 0.5
    end
    local moon = blk(world, W - 60, 16, 22, 22, Color3.fromRGB(226, 228, 240)); corner(moon, 11)
    local moonCut = blk(world, W - 52, 12, 20, 20, Color3.fromRGB(24, 27, 40)); corner(moonCut, 10)
    local clouds = {}
    for i = 1, 3 do
        local c = pixels(world, CLOUD, {["#"] = CLOUDC}, 3, i * 120 - 60, 20 + (i % 2) * 22)
        clouds[i] = {f = c, x = i * 120 - 60}
    end
    -- ground
    blk(world, 0, GY, W, 2, PAL.dim)
    blk(world, 0, GY + 2, W, H - GY - 2, Color3.fromRGB(22, 25, 34))
    local dashes = {}
    for i = 1, 14 do dashes[i] = {f = blk(world, 0, GY + 5 + (i % 4) * 4, 6 + (i % 3) * 5, 2, PAL.line), x = (i - 1) * 26 + (i * 7) % 20} end
    local hud = txt(world, "", UDim2.new(1, -12, 0, 14), UDim2.fromOffset(0, 6), 10, PAL.dim, Enum.TextXAlignment.Right, true)
    local msg = txt(world, "press space / tap to start", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 44), 11, PAL.text, Enum.TextXAlignment.Center, true)
    -- dino sprites
    local DX = 30
    local pal = {["#"] = FG, e = Color3.fromRGB(20, 24, 34)}
    local function cat(a, b) local r = {}; for _, v in ipairs(a) do r[#r + 1] = v end; for _, v in ipairs(b) do r[#r + 1] = v end; return r end
    local spr = {}
    spr.run1 = pixels(world, cat(DINO_BODY, LEG1), pal, 2, DX, GY - 36)
    spr.run2 = pixels(world, cat(DINO_BODY, LEG2), pal, 2, DX, GY - 36)
    spr.duck1 = pixels(world, DINO_DUCK, pal, 2, DX, GY - 24)
    spr.dead = pixels(world, cat(DINO_BODY, LEG1), {["#"] = PAL.bad, e = Color3.new(1, 1, 1)}, 2, DX, GY - 36)
    local function show(name) for k, f in pairs(spr) do f.Visible = (k == name) end end
    show("run1")
    local best = tonumber(CFG.dinoHi) or 0
    local st = {run = false, dead = false, y = 0, vy = 0, duck = false, travel = 0, nextSpawn = 380, obs = {}, last = os.clock(), score = 0, air = false}
    local oppScore, oppFin, myFin = nil, nil, false
    local alive = true
    local flashUntil = 0
    local function speedAt() return math.min(DMAX[diff], DBASE[diff] + st.travel * DRAMP[diff]) end
    local function dust(x)
        for i = 1, 3 do
            local d = blk(world, x + i * 4, GY - 4, 4, 4, PAL.dim)
            corner(d, 2)
            tweenTo(d, 0.35, {Position = UDim2.fromOffset(x + i * 4 - 14 - i * 3, GY - 12 - i * 3), BackgroundTransparency = 1})
            task.delay(0.4, function() d:Destroy() end)
        end
    end
    local function spawn()
        local sp = speedAt()
        local sc = math.floor(st.travel / 10)
        local o = {x = W + 20}
        local f = New("Frame", {BackgroundTransparency = 1, Parent = world})
        local bird = sc >= DBIRD[diff] and rng() < 0.28
        if bird then
            local lv = rng(3)
            o.w, o.h, o.kind = 28, 16, "bird"
            o.yb = ({0, 24, 46})[lv]
            o.s1 = pixels(f, BIRD_UP, {["#"] = BIRD}, 2, 0, 0)
            o.s2 = pixels(f, BIRD_DN, {["#"] = BIRD}, 2, 0, 0)
            o.s2.Visible = false
        else
            local r = rng(4)
            o.kind = "cactus"; o.yb = 0
            local cp = {["#"] = CACT}
            if r == 1 then o.w, o.h = 12, 26; pixels(f, CACT_S, cp, 2, 0, 0)
            elseif r == 2 then o.w, o.h = 16, 36; pixels(f, CACT_L, cp, 2, 0, 0)
            elseif r == 3 then o.w, o.h = 30, 26; pixels(f, CACT_S, cp, 2, 0, 0); pixels(f, CACT_S, cp, 2, 18, 0)
            else o.w, o.h = 46, 36; pixels(f, CACT_L, cp, 2, 0, 0); pixels(f, CACT_S, cp, 2, 18, 10); pixels(f, CACT_S, cp, 2, 33, 10) end
        end
        f.Size = UDim2.fromOffset(o.w, o.h)
        f.Position = UDim2.fromOffset(o.x, GY - o.yb - o.h)
        o.f = f
        st.obs[#st.obs + 1] = o
        st.nextSpawn = st.travel + sp * (0.62 + rng() * 0.6) + o.w
    end
    local function sendProgress(final)
        if ses then NET.pub(ses.topic, {t = final and "fin" or "p", s = st.score}) end
    end
    local function resolve()
        if not ses or not oppFin then return end
        if myFin then
            local w = st.score > oppScore
            setStatus(w and "you win!" or "you lose", w and PAL.good or PAL.bad)
        elseif st.run and st.score > oppScore then
            st.run = false; myFin = true
            msg.Text = "you win!"
            setStatus("you beat the opponent's score - you win!", PAL.good)
            sendProgress(true)
        end
    end
    local function die()
        st.dead = true; st.run = false; myFin = true
        show("dead")
        spr.dead.Position = UDim2.fromOffset(DX, GY - st.y - 36)
        msg.Text = "GAME OVER  -  space / tap to restart"
        if st.score > best then best = st.score; CFG.dinoHi = best; saveCFG() end
        sendProgress(true)
        if ses then
            if oppFin then resolve() else setStatus("waiting for opponent to finish... (you: " .. st.score .. ")", PAL.dim) end
            msg.Text = "GAME OVER"
        end
    end
    local function reset()
        for _, o in ipairs(st.obs) do o.f:Destroy() end
        st.obs = {}; st.travel = 0; st.nextSpawn = 380; st.y = 0; st.vy = 0; st.dead = false; st.run = true; st.score = 0; st.duck = false
        msg.Text = ""
        rng = LG.RNG(ses and ses.seed or math.random(1, 2000000000))
        st.last = os.clock()
        show("run1")
    end
    local function jump()
        if not st.run and not st.dead then reset() return end
        if st.dead then if not ses then reset() end return end
        if st.y <= 0.5 then st.vy = 540 end
    end
    Connect(world.InputBegan, function(i) if IsPress(i) then jump() end end)
    Connect(UIS.InputBegan, function(i)
        if not alive or MG.cur == nil or MG.cur.kind ~= "dino" or UIS:GetFocusedTextBox() then return end
        if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.Up or i.KeyCode == Enum.KeyCode.W then jump()
        elseif i.KeyCode == Enum.KeyCode.Down or i.KeyCode == Enum.KeyCode.S then st.duck = true end
    end)
    Connect(UIS.InputEnded, function(i)
        if i.KeyCode == Enum.KeyCode.Down or i.KeyCode == Enum.KeyCode.S then st.duck = false end
    end)
    local duckBtn = button(gwBody, "duck (hold)", UDim2.fromOffset(110, 24), UDim2.fromOffset(1, H + 8), nil, "ghost", nil, 10)
    Connect(duckBtn.InputBegan, function(i) if IsPress(i) then st.duck = true end end)
    Connect(duckBtn.InputEnded, function(i) if IsPress(i) then st.duck = false end end)
    button(gwBody, "jump", UDim2.fromOffset(110, 24), UDim2.fromOffset(W - 109, H + 8), function() jump() end, "primary", ACC.dino, 10)
    local frame = 0
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not alive or MG.dead then conn:Disconnect() return end
        local now = os.clock()
        local dt = math.min(now - st.last, 0.05); st.last = now
        local spNow = st.run and speedAt() or 0
        for _, c in ipairs(clouds) do
            c.x = c.x - (st.run and spNow * 0.12 or 8) * dt
            if c.x < -50 then c.x = W + 20 end
            c.f.Position = UDim2.fromOffset(math.floor(c.x), c.f.Position.Y.Offset)
        end
        if st.run then
            frame = frame + 1
            local sp = spNow
            for _, dsh in ipairs(dashes) do
                dsh.x = dsh.x - sp * dt
                if dsh.x < -24 then dsh.x = dsh.x + W + 48 end
                dsh.f.Position = UDim2.fromOffset(math.floor(dsh.x + 0.5), dsh.f.Position.Y.Offset)
            end
            st.travel = st.travel + sp * dt
            local old = st.score
            st.score = math.floor(st.travel / 10)
            if st.score > 0 and st.score % 100 == 0 and old ~= st.score then flashUntil = now + 0.6 end
            local wasAir = st.y > 0.5
            if st.y > 0 or st.vy > 0 then
                st.vy = st.vy - (st.duck and 3400 or 1800) * dt
                st.y = st.y + st.vy * dt
                if st.y <= 0 then st.y = 0; st.vy = 0; if wasAir then dust(DX) end end
            end
            if st.travel >= st.nextSpawn then spawn() end
            local ducking = st.duck and st.y <= 0.5
            local dw, dh = ducking and 34 or 24, ducking and 18 or 30
            local dx0, dy0 = DX + 4, GY - st.y - dh - (ducking and 2 or 4)
            for idx = #st.obs, 1, -1 do
                local o = st.obs[idx]
                o.x = o.x - sp * dt
                o.f.Position = UDim2.fromOffset(math.floor(o.x + 0.5), GY - o.yb - o.h)
                if o.kind == "bird" then local up = frame % 14 < 7; o.s1.Visible = up; o.s2.Visible = not up end
                if o.x + o.w < -10 then o.f:Destroy(); table.remove(st.obs, idx)
                else
                    local ox0, oy0 = o.x + 2, GY - o.yb - o.h + 2
                    if dx0 < ox0 + o.w - 5 and dx0 + dw > ox0 and dy0 < oy0 + o.h - 5 and dy0 + dh > oy0 then die() end
                end
            end
            if st.run then
                local pose = "run1"
                if st.y > 0.5 then pose = "run1" elseif ducking then pose = "duck1" else pose = (frame % 12 < 6) and "run1" or "run2" end
                show(pose)
                local f = spr[pose]
                f.Position = UDim2.fromOffset(DX, GY - st.y - (ducking and 24 or 36))
            end
            if ses then resolve() end
        end
        hud.TextColor3 = (now < flashUntil and (frame % 6 < 3)) and PAL.warn or PAL.dim
        hud.Text = string.format("HI %05d    %05d%s", best, st.score, (ses and oppScore) and ("    opp " .. string.format("%05d", oppScore)) or "")
    end)
    local ctl = {kind = "dino", ses = ses, destroy = function() alive = false; pcall(function() conn:Disconnect() end) end}
    if ses then
        ctl.onNet = function(m)
            if m.t == "p" then oppScore = m.s or oppScore
            elseif m.t == "fin" then oppScore = m.s or 0; oppFin = true
                if not myFin then setStatus("opponent finished with " .. oppScore .. " - beat it!", PAL.warn) end
                resolve()
            elseif m.t == "quit" then oppFin = true; oppScore = -1; setStatus("opponent left - you win", PAL.good) end
        end
        setStatus("same obstacles for both - higher score wins", PAL.dim)
    else setStatus("space / up: jump    down: duck    tap works too", PAL.dim) end
    return ctl
end

------------------------------------------------------------------ launcher
function MG.start(game, diff, ses)
    MG.closeGame()
    gw.Visible = true
    MG.freeze(true)
    local ctl
    if game == "ms" then ctl = MG.minesweeper(diff, ses)
    elseif game == "ttt" then ctl = MG.ttt(diff, ses)
    elseif game == "bs" then ctl = MG.battleship(diff, ses)
    else ctl = MG.dino(diff, ses) end
    ctl.kind = ctl.kind or game
    MG.cur = ctl
    MG.base = Vector2.new(gw.Size.X.Offset, gw.Size.Y.Offset)
    gwBody.Size = UDim2.fromOffset(MG.base.X - 20, MG.base.Y - (HEADER + FOOT + 12))
    MG.fit()
    if ses then
        ses.alive = true
        ctl.ses = ses
        startPolling(ses, function(m) if MG.cur == ctl and ctl.onNet then ctl.onNet(m) end end)
    end
end

------------------------------------------------------------------ lobby (host / find / join)
MG.lobbies = {}
local GNAMES = {ms = "Minesweeper", ttt = "Tic Tac Toe", bs = "Battleship", dino = "Dino Run"}
function MG.host(game, diff)
    if MG.hosting then MG.hosting.alive = false end
    local id = newId()
    local h = {id = id, alive = true, game = game, diff = diff}
    MG.hosting = h
    local topic = "g" .. id
    MG.setLobbyStatus("hosting " .. GNAMES[game] .. " (" .. DIFFS[diff] .. ") - waiting for a player...", PAL.warn)
    function MG.advertise()
        if os.clock() - (MG.lastAdv or 0) < 2.5 then return end
        MG.lastAdv = os.clock()
        NET.pub(NET.lobby, {t = "adv", id = id, g = game, d = diff})
    end
    MG.advertise()
    task.spawn(function()
        local since = 0
        local t0 = os.clock()
        while h.alive and not MG.dead and not Library.Unloaded and os.clock() - t0 < 600 do
            local list, cur = NET.poll(topic, since); since = cur
            for _, m in ipairs(list) do
                if m.t == "join" and h.alive then
                    h.alive = false; MG.hosting = nil
                    local seed = math.random(1, 2000000000)
                    NET.pub(topic, {t = "start", to = m.n, seed = seed})
                    NET.pub(NET.lobby, {t = "gone", id = id})
                    local ses = {topic = topic, role = "host", opp = m.u, oppNonce = m.n, seed = seed, diff = diff, game = game}
                    MG.setLobbyStatus("")
                    MG.start(game, diff, ses)
                    return
                end
            end
            task.wait(0.5)
        end
        if h.alive then h.alive = false; MG.hosting = nil; NET.pub(NET.lobby, {t = "gone", id = id}); MG.setLobbyStatus("lobby timed out") end
    end)
end
function MG.cancelHost()
    if MG.hosting then NET.pub(NET.lobby, {t = "gone", id = MG.hosting.id}); MG.hosting.alive = false; MG.hosting = nil; MG.setLobbyStatus("hosting cancelled") end
end
function MG.join(lb)
    local topic = "g" .. lb.id
    MG.setLobbyStatus("joining " .. tostring(lb.u) .. "...", PAL.warn)
    NET.pub(topic, {t = "join"})
    task.spawn(function()
        local since, t0 = 0, os.clock()
        while os.clock() - t0 < 25 and not MG.dead do
            local list, cur = NET.poll(topic, since); since = cur
            for _, m in ipairs(list) do
                if m.t == "start" and m.to == NET.nonce then
                    local ses = {topic = topic, role = "guest", opp = lb.u, oppNonce = m.n, seed = m.seed, diff = lb.d, game = lb.g}
                    MG.setLobbyStatus("")
                    MG.start(lb.g, lb.d, ses)
                    return
                end
            end
            task.wait(1)
        end
        MG.setLobbyStatus("host did not answer (left or busy?)")
    end)
end
function MG.refresh()
    if MG.refreshing then return end
    MG.refreshing = true
    MG.setLobbyStatus("searching this server for script users...", PAL.warn)
    NET.pub(NET.lobby, {t = "who"})
    task.spawn(function()
        task.wait(3.5)
        MG.refreshing = false
        local map, order = {}, {}
        local nowT = os.time()
        for _, m in ipairs(NET.inbox[NET.lobby] or {}) do
            if m.id and nowT - (m._time or 0) < 40 then
                if m.t == "adv" then map[m.id] = m elseif m.t == "gone" then map[m.id] = false end
            end
        end
        for _, v in pairs(map) do if v and Players:FindFirstChild(v.u) then order[#order + 1] = v end end
        MG.lobbies = order
        if MG.renderLobbies then MG.renderLobbies() end
    end)
end

------------------------------------------------------------------ slide-out panel (child of the main window root)
local panel = New("Frame", {Name = "MinigamesPanel", Size = UDim2.fromOffset(284, 460), Position = UDim2.fromOffset(300, 200), BackgroundColor3 = PAL.bg, ZIndex = 0, Visible = false, Active = true, Parent = Win.Root})
corner(panel, 10); stroke(panel, PAL.line)
local pHeadBox = box(panel, UDim2.new(1, 0, 0, 46), nil, PAL.card2, 10)
box(pHeadBox, UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 1, -10), PAL.card2, nil)
grad(pHeadBox, PAL.card2:Lerp(Color3.new(1, 1, 1), 0.05), PAL.card, 90)
txt(pHeadBox, "Minigames", UDim2.new(1, -50, 0, 22), UDim2.fromOffset(14, 5), 15, PAL.text, nil, true)
txt(pHeadBox, "pick a difficulty, then a game", UDim2.new(1, -50, 0, 14), UDim2.fromOffset(14, 27), 9, PAL.dim)
box(pHeadBox, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), PAL.line, nil)
local pScroll = New("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -58), Position = UDim2.fromOffset(6, 52), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = PAL.line, ScrollingDirection = Enum.ScrollingDirection.Y, BorderSizePixel = 0, Parent = panel})
List(pScroll, 8)
Padding(pScroll, 0, 2, 4, 14)
local order = 0
local function row(h)
    order = order + 1
    return New("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = order, Parent = pScroll})
end
local function section(title)
    local r = row(14)
    txt(r, string.upper(title), UDim2.new(1, -4, 1, 0), UDim2.fromOffset(4, 0), 9, PAL.dim, nil, true)
end
-- difficulty (segmented control)
section("difficulty")
local seg = row(30)
local segBg = box(seg, UDim2.fromScale(1, 1), nil, PAL.card, 8); stroke(segBg, PAL.line)
local dBtns, descLbls = {}, {}
local function updateDesc()
    descLbls.ms.Text = "field " .. MSIZE[MG.diff] .. "x" .. MSIZE[MG.diff] .. ", random mine count"
    descLbls.ttt.Text = "3x3 board, bot level " .. MG.diff .. "/4 (4 = unbeatable)"
    descLbls.bs.Text = "10x10 fleet battle, bot level " .. MG.diff .. "/4"
    descLbls.dino.Text = "obstacle speed level " .. MG.diff .. "/4"
end
local function selectDiff(d)
    MG.diff = d
    for i, b in ipairs(dBtns) do
        local on = i == d
        b:SetAttribute("sel", on)
        Tween(b, TWEEN_FAST, {BackgroundColor3 = on and DCOL[i] or PAL.card, TextColor3 = on and PAL.dark or PAL.dim})
    end
    if descLbls.ms then updateDesc() end
end
for i, nm in ipairs(DIFFS) do
    local b = New("TextButton", {Size = UDim2.new(0.25, -4, 1, -6), Position = UDim2.new((i - 1) * 0.25, 3, 0, 3), BackgroundColor3 = PAL.card, Text = nm, TextSize = 9, Font = FONTB, TextColor3 = PAL.dim, AutoButtonColor = false, Parent = seg})
    corner(b, 6)
    Connect(b.MouseEnter, function() if not b:GetAttribute("sel") then Tween(b, TWEEN_FAST, {TextColor3 = PAL.text}) end end)
    Connect(b.MouseLeave, function() if not b:GetAttribute("sel") then Tween(b, TWEEN_FAST, {TextColor3 = PAL.dim}) end end)
    Connect(b.MouseButton1Click, function() playSound(Sounds.Click, 0.4); selectDiff(i) end)
    dBtns[i] = b
end
-- games
section("games")
local function gameCard(key, title, badge)
    local c = row(80)
    c.BackgroundTransparency = 0; c.BackgroundColor3 = PAL.card; corner(c, 10); stroke(c, PAL.line)
    local acc = ACC[key]
    box(c, UDim2.fromOffset(3, 34), UDim2.fromOffset(0, 12), acc, 2)
    local bd = box(c, UDim2.fromOffset(36, 36), UDim2.fromOffset(12, 10), acc:Lerp(PAL.bg, 0.78), 10); stroke(bd, acc, 1, 0.55)
    txt(bd, badge, UDim2.fromScale(1, 1), nil, 12, acc, Enum.TextXAlignment.Center, true)
    txt(c, title, UDim2.new(1, -66, 0, 16), UDim2.fromOffset(58, 9), 12, PAL.text, nil, true)
    local d = txt(c, "", UDim2.new(1, -66, 0, 12), UDim2.fromOffset(58, 27), 9, PAL.dim)
    d.TextTruncate = Enum.TextTruncate.AtEnd
    descLbls[key] = d
    button(c, "Play", UDim2.new(0.5, -14, 0, 24), UDim2.fromOffset(12, 50), function() MG.start(key, MG.diff, nil) end, "primary", acc, 10)
    button(c, "Host online", UDim2.new(0.5, -14, 0, 24), UDim2.new(0.5, 2, 0, 50), function() MG.host(key, MG.diff) end, "ghost", nil, 10)
end
gameCard("ms", "Minesweeper", "MS")
gameCard("ttt", "Tic Tac Toe", "XO")
gameCard("bs", "Battleship", "BS")
gameCard("dino", "Dino Run", "DR")
-- lobby
section("online lobby")
local lob = row(0)
lob.AutomaticSize = Enum.AutomaticSize.Y; lob.BackgroundTransparency = 0; lob.BackgroundColor3 = PAL.card; corner(lob, 10); stroke(lob, PAL.line)
List(lob, 6); Padding(lob, 8, 8, 8, 8)
local lr = New("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1, Parent = lob})
button(lr, "Find games", UDim2.new(0.5, -3, 1, 0), nil, function() MG.refresh() end, "primary", Color3.fromRGB(235, 235, 243), 10)
button(lr, "Cancel hosting", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), function() MG.cancelHost() end, "ghost", nil, 10)
local lobbyStatus = txt(lob, "asks players in this server who run the script", UDim2.new(1, 0, 0, 24), nil, 9, PAL.dim)
lobbyStatus.TextWrapped = true; lobbyStatus.LayoutOrder = 2
function MG.setLobbyStatus(t, col) lobbyStatus.Text = t; lobbyStatus.TextColor3 = col or PAL.dim end
local lobbyList = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = lob})
List(lobbyList, 5)
function MG.renderLobbies()
    for _, ch in ipairs(lobbyList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    if #MG.lobbies == 0 then MG.setLobbyStatus("no open games right now"); return end
    MG.setLobbyStatus(#MG.lobbies .. " open game(s)", PAL.good)
    for i, lb in ipairs(MG.lobbies) do
        local f = box(lobbyList, UDim2.new(1, 0, 0, 36), nil, PAL.card2, 8); f.LayoutOrder = i
        local acc = ACC[lb.g] or PAL.dim
        box(f, UDim2.fromOffset(3, 20), UDim2.fromOffset(0, 8), acc, 2)
        txt(f, tostring(lb.u), UDim2.new(1, -76, 0, 14), UDim2.fromOffset(12, 4), 11, PAL.text, nil, true)
        txt(f, (GNAMES[lb.g] or "?") .. "  /  " .. (DIFFS[lb.d] or "?"), UDim2.new(1, -76, 0, 12), UDim2.fromOffset(12, 19), 9, PAL.dim)
        button(f, "Join", UDim2.fromOffset(56, 22), UDim2.new(1, -62, 0.5, -11), function() MG.join(lb) end, "primary", acc, 10)
    end
end
local pClose = button(panel, "x", UDim2.fromOffset(24, 22), UDim2.new(1, -34, 0, 12), function() MG.setOpen(false) end, "danger", nil, 11)
mkGrip(panel, function() return Vector2.new(panel.Size.X.Offset, panel.Size.Y.Offset) end, function(w, h) panel.Size = UDim2.fromOffset(w, h) end, function() return Win.UIScale.Scale end, 230, 280, 540, 800)
selectDiff(1)

local SLIDE_IN = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
function MG.setOpen(v)
    if MG.open == v then return end
    MG.open = v
    local mainW = Win.Main.Size.X.Offset
    local hiddenX = mainW - panel.Size.X.Offset - 6   -- fully tucked behind the main window
    if v then
        panel.Position = UDim2.fromOffset(hiddenX, 200); panel.Visible = true
        Tween(panel, SLIDE_IN, {Position = UDim2.fromOffset(mainW + 6, 200)})
    else
        Tween(panel, SLIDE_OUT, {Position = UDim2.fromOffset(hiddenX, 200)})
        task.delay(0.36, function() if not MG.open then panel.Visible = false end end)
    end
end
end)()

do
local MGTab = Win:AddTab({Name="minigames", Subtitle="sapper, ttt, ships, dino"})
local MGSec = MGTab:AddSection({Name="minigames", Side="Left"})
MGSec:AddButton({Name="open / close panel", Callback=function() X.MG.setOpen(not X.MG.open) end})
MGSec:AddLabel({Name="the panel slides out to the right of this window. pick difficulty, then a game."})
local MGInfo = MGTab:AddSection({Name="online", Side="Right"})
MGInfo:AddLabel({Name="pvp: host a game, other script users in your server press find games and join. moves travel over hidden chat messages."})
local oldSel = Win.SelectTab
Win.SelectTab = function(self, tab)
    oldSel(self, tab)
    if tab == MGTab then X.MG.setOpen(true)
    elseif X.MG.open then X.MG.setOpen(false) end
end
end
-- ===== HOTKEYS: rebindable keys + small HUD =====
X.HK = {binds = {}, hud = nil}
;(function()
local HK = X.HK
local function findToggle(name)
    for _, tab in ipairs(Win.Tabs) do
        for _, sec in ipairs(tab.Sections) do
            for _, el in ipairs(sec.Elements) do
                if el.Type == "Toggle" and el.Name == name then return el end
            end
        end
    end
end
local function parseKey(s)
    s = tostring(s or ""):gsub("%s", "")
    if s == "" then return nil end
    local ok, kc = pcall(function() return Enum.KeyCode[s] or Enum.KeyCode[s:upper()] or Enum.KeyCode[s:sub(1, 1):upper() .. s:sub(2):lower()] end)
    if ok then return kc end
end
local DEFS = {
    {id = "killall",  name = "kill all",        def = "L", act = function() task.spawn(X.killAll, true) end},
    {id = "autoshoot",name = "auto shoot",      def = "X", toggle = "auto shoot"},
    {id = "boxesp",   name = "box esp",         def = "B", toggle = "box esp"},
    {id = "espall",   name = "esp all",         def = "V", toggle = "esp all"},
    {id = "killaura", name = "kill aura",       def = "K", toggle = "kill aura"},
    {id = "aura",     name = "player aura",     def = "U", toggle = "enable aura"},
    {id = "wings",    name = "wings",           def = "Y", toggle = "wings"},
    {id = "fly",      name = "fly",             def = "G", toggle = "fly"},
    {id = "noclip",   name = "noclip",          def = "N", toggle = "noclip"},
    {id = "autogun",  name = "auto get gun",    def = "O", toggle = "auto get gun"},
    {id = "touchfling", name = "touch fling",   def = "T", toggle = "touch fling"},
    {id = "minigames",name = "minigames panel", def = "M", act = function() X.MG.setOpen(not X.MG.open) end, state = function() return X.MG.open end},
    {id = "hud",      name = "hotkey hud",      def = "H", act = function() HK.setHud(not HK.hudOn) end, state = function() return HK.hudOn end},
}
for _, d in ipairs(DEFS) do
    d.key = parseKey(CFG["hk_" .. d.id]) or parseKey(d.def)
    HK.binds[#HK.binds + 1] = d
end
local function stateOf(b)
    if b.toggle then local el = b.toggleEl or findToggle(b.toggle); b.toggleEl = el; return el and el.Value or false end
    if b.state then return b.state() end
    return nil
end
Connect(UIS.InputBegan, function(i, gp)
    if gp or UIS:GetFocusedTextBox() then return end
    for _, b in ipairs(HK.binds) do
        if b.key and i.KeyCode == b.key then
            if b.toggle then
                local el = b.toggleEl or findToggle(b.toggle); b.toggleEl = el
                if el then el:Set(not el.Value) end
            elseif b.act then pcall(b.act) end
        end
    end
end)
-- HUD
local hud = New("Frame", {Name = "PiddleHotkeys", Size = UDim2.fromOffset(176, 24), Position = UDim2.new(0, 12, 0.5, -90), BackgroundColor3 = Theme.Window, BackgroundTransparency = 0.15, Active = true, Visible = false, Parent = X.MG.gui})
Corner(hud, 6); Stroke(hud, Theme.Stroke)
local hh = Label({Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(8, 3), Text = "hotkeys", TextColor3 = Theme.Dim, TextSize = 10, Font = Theme.FontBold, Parent = hud})
MakeDraggable(hh, hud, function() return 1 end)
local rows = {}
local y = 22
local function addRow(keyText, nameText, b)
    local r = {}
    r.key = Label({Size = UDim2.fromOffset(40, 14), Position = UDim2.fromOffset(8, y), Text = keyText, TextColor3 = Theme.Text, TextSize = 10, Font = Theme.FontBold, Parent = hud})
    r.name = Label({Size = UDim2.new(1, -86, 0, 14), Position = UDim2.fromOffset(50, y), Text = nameText, TextColor3 = Theme.Dim, TextSize = 10, Parent = hud})
    r.st = New("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -18, 0, y + 3), BackgroundColor3 = Theme.Dimmer, Visible = (b ~= nil and (b.toggle ~= nil or b.state ~= nil)), Parent = hud})
    Corner(r.st, 4)
    r.b = b
    rows[#rows + 1] = r
    y = y + 15
end
addRow("RShift", "toggle ui", nil)
for _, b in ipairs(HK.binds) do addRow(b.key and b.key.Name or "-", b.name, b) end
local baseW, baseH = 176, y + 6
hud.Size = UDim2.fromOffset(baseW, baseH)
local hudScale = New("UIScale", {Scale = (tonumber(CFG.hkScale) or 100) / 100, Parent = hud})
do
    local g = New("TextButton", {Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, Text = "", ZIndex = 30, Parent = hud})
    for _, p in ipairs({{10, 10}, {6, 10}, {10, 6}}) do New("Frame", {Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(p[1], p[2]), BackgroundColor3 = Theme.Dim, BorderSizePixel = 0, ZIndex = 31, Parent = g}) end
    local rs, sp, s0 = false, nil, 1
    Connect(g.InputBegan, function(i) if IsPress(i) then rs = true; sp = i.Position; s0 = hudScale.Scale; EX.modal(true) end end)
    Connect(UIS.InputChanged, function(i)
        if rs and IsMove(i) then
            local d = i.Position - sp
            hudScale.Scale = math.clamp(s0 + (d.X / baseW + d.Y / baseH) * 0.5, 0.5, 2.5)
        end
    end)
    Connect(UIS.InputEnded, function(i)
        if rs and IsPress(i) then rs = false; EX.modal(false); CFG.hkScale = math.floor(hudScale.Scale * 100 + 0.5); saveCFG() end
    end)
end
HK.hudOn = CFG.hotkeyHud == true
hud.Visible = HK.hudOn
function HK.setHud(v)
    HK.hudOn = v and true or false
    hud.Visible = HK.hudOn
    CFG.hotkeyHud = HK.hudOn; saveCFG()
end
task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.25)
        if HK.hudOn then
            for _, r in ipairs(rows) do
                if r.b then
                    r.key.Text = r.b.key and r.b.key.Name or "-"
                    local s = stateOf(r.b)
                    if s ~= nil then r.st.BackgroundColor3 = s and Color3.fromRGB(90, 220, 120) or Theme.Dimmer; r.name.TextColor3 = s and Theme.Text or Theme.Dim end
                end
            end
        end
    end
end)
-- tab
local HkTab = Win:AddTab({Name = "hotkeys", Subtitle = "keys & hud"})
local HkSec = HkTab:AddSection({Name = "keybinds", Side = "Left"})
HkSec:AddLabel({Name = "type a key name (X, B, F5, Insert ...) and press enter. toggle ui: right shift"})
for _, b in ipairs(HK.binds) do
    HkSec:AddTextbox({Name = b.name, Default = b.key and b.key.Name or "", Placeholder = "key", Callback = function(v)
        local kc = parseKey(v)
        if kc then b.key = kc; CFG["hk_" .. b.id] = kc.Name; saveCFG(); Library:Notify({Title = "hotkey", Text = b.name .. " = " .. kc.Name, Duration = 2})
        else Library:Notify({Title = "hotkey", Text = "unknown key: " .. tostring(v), Duration = 3}) end
    end})
end
local HkInfo = HkTab:AddSection({Name = "hud", Side = "Right"})
HkInfo:AddSlider({Name = "hud size", Min = 50, Max = 250, Default = tonumber(CFG.hkScale) or 100, Callback = function(v) hudScale.Scale = v / 100; CFG.hkScale = v; saveCFG() end})
HkInfo:AddToggle({Name = "show hotkey hud", Default = HK.hudOn, Callback = function(v) HK.setHud(v) end})
HkInfo:AddLabel({Name = "green dot = function is on. drag the hud by its title."})
end)()

local SettingsTab = Win:AddTab({Name="settings", Subtitle="ui config"})
local BgSec = SettingsTab:AddSection({Name="background", Side="Left"})
local bgNames={}; for k in pairs(BG_LIST) do table.insert(bgNames,k) end; table.sort(bgNames)
BgSec:AddDropdown({Name="background", Values=bgNames, Default=CFG.bgName, Callback=function(v)
    CFG.bgName=v; saveCFG()
    local img=BG_LIST[v] or ""
    if img:find("^video:") then
        img=""; X.ANIM.apply(false); X.LW.apply(true)
    elseif img:find("^anim:") then
        local am=img:sub(6); img=""; X.LW.apply(false); X.ANIM.apply(true, am)
    else
        X.LW.apply(false); X.ANIM.apply(false)
    end
    if Win.BgImage then Win.BgImage.Image=img end
    if wmBg then wmBg.Image=img end
end})
BgSec:AddSlider({Name="bg transparency", Min=0, Max=100, Default=40, Callback=function(v)
    if Win.BgImage then Win.BgImage.ImageTransparency=v/100 end
    if wmBg then wmBg.ImageTransparency=math.min(0.8,v/100+0.1) end
end})
BgSec:AddSlider({Name="video dim", Min=0, Max=90, Default=CFG.liveDim or 35, Callback=function(v) X.LW.setDim(v) end})
BgSec:AddButton({Name="reload video", Callback=function() if X.LW.on then X.LW.remove(); X.LW.apply(true) end end})
BgSec:AddSlider({Name="wallpaper density", Min=6, Max=40, Default=X.ANIM.count, Callback=function(v) X.ANIM.count=v; CFG.triCount=v; saveCFG(); if X.ANIM.on then X.ANIM.build() end end})
BgSec:AddSlider({Name="wallpaper speed", Min=20, Max=300, Default=X.ANIM.speed, Callback=function(v) X.ANIM.speed=v; CFG.triSpeed=v; saveCFG() end})
BgSec:AddSlider({Name="line max length", Min=30, Max=400, Default=X.ANIM.lineMax, Callback=function(v) X.ANIM.lineMax=v; CFG.netLineMax=v; saveCFG() end})
BgSec:AddSlider({Name="ball size min", Min=0.1, Max=10, Increment=0.1, Default=X.ANIM.sizeMin, Callback=function(v) X.ANIM.sizeMin=v; CFG.netSizeMin=v; saveCFG() end})
BgSec:AddSlider({Name="ball size max", Min=0.1, Max=10, Increment=0.1, Default=X.ANIM.sizeMax, Callback=function(v) X.ANIM.sizeMax=v; CFG.netSizeMax=v; saveCFG() end})
BgSec:AddColorPicker({Name="dot color", Default=X.ANIM.dotColor or Theme.Accent, Callback=function(c) X.ANIM.setDotColor(c) end})
BgSec:AddColorPicker({Name="line color", Default=X.ANIM.lineColor or Theme.Accent, Callback=function(c) X.ANIM.setLineColor(c) end})
BgSec:AddColorPicker({Name="triangle color", Default=X.ANIM.color or Color3.fromRGB(235,235,245), Callback=function(c) X.ANIM.recolor(c) end})
BgSec:AddSlider({Name="ui scale", Min=50, Max=150, Default=CFG.uiScale, Callback=function(v)
    CFG.uiScale = v
    Win._baseScale = v/100
    if Win.UIScale then Win.UIScale.Scale = v/100 end
    saveCFG()
end})
X.UI = {pend=nil, busy=false}
function X.UI.remap(list, kind)
    local gui = Library.Gui
    if not gui then return end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiObject") then
            local c = d.BackgroundColor3
            for _, pr in ipairs(list) do
                if c == pr[1] then d.BackgroundColor3 = pr[2]; break end
            end
            if kind ~= "line" then
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    local t = d.TextColor3
                    for _, pr in ipairs(list) do
                        if t == pr[1] then d.TextColor3 = pr[2]; break end
                    end
                elseif d:IsA("ScrollingFrame") then
                    local t = d.ScrollBarImageColor3
                    for _, pr in ipairs(list) do
                        if t == pr[1] then d.ScrollBarImageColor3 = pr[2]; break end
                    end
                end
            end
        elseif d:IsA("UIStroke") then
            local tagged = d:GetAttribute("L")
            local c = d.Color
            for _, pr in ipairs(list) do
                if c == pr[1] then
                    if kind == "line" and not tagged then break end
                    if kind == "accent" and tagged and Theme.Accent == Theme.Stroke then break end
                    d.Color = pr[2]; break
                end
            end
        end
    end
end
function X.UI.setAccent(c)
    local old = Theme.Accent
    if old == c then return end
    X.UI.remap({{old, c}}, "accent")
    Theme.Accent = c
end
function X.UI.setLine(c)
    local oldS, oldSoft = Theme.Stroke, Theme.StrokeSoft
    local newSoft = c:Lerp(Theme.Window, 0.45)
    if oldS == c then return end
    X.UI.remap({{oldS, c}, {oldSoft, newSoft}}, "line")
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
SysSec:AddToggle({Name="lite mode (weak executors)", Default=CFG.lite==true, Callback=function(v) CFG.lite=v; Library.Lite=v; saveCFG(); if v then X.ANIM.apply(false); X.LW.apply(false) end end})
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
-- main window can be resized by dragging the corner grip (scales the whole UI)
do
    local g = New("TextButton", {Parent = Win.Main, Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, Text = "", ZIndex = 60})
    for _, p in ipairs({{12, 12}, {8, 12}, {12, 8}, {4, 12}, {12, 4}, {8, 8}}) do
        New("Frame", {Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(p[1], p[2]), BackgroundColor3 = Theme.Dimmer, BorderSizePixel = 0, ZIndex = 61, Parent = g})
    end
    local rs, sp, s0 = false, nil, 1
    Connect(g.InputBegan, function(i) if IsPress(i) then rs = true; sp = i.Position; s0 = Win._baseScale or 1; EX.modal(true) end end)
    Connect(UIS.InputChanged, function(i)
        if rs and IsMove(i) then
            local d = i.Position - sp
            local sc = math.clamp(s0 + (d.X + d.Y) * 0.5 / 460, 0.6, 1.6)
            Win._baseScale = sc
            if Win.UIScale then Win.UIScale.Scale = sc end
            CFG.uiScale = math.floor(sc * 100 + 0.5)
        end
    end)
    Connect(UIS.InputEnded, function(i) if rs and IsPress(i) then rs = false; EX.modal(false); saveCFG() end end)
end

-- pictures that fail to download get re-requested a few times (fixes "broken" images)
task.spawn(function()
    task.wait(2.5)
    for attempt = 1, 4 do
        local pending = false
        for _, im in ipairs({Win.TopImg, Win.BgImage, Win.Logo}) do
            if im and im.Image ~= "" then
                local ok, loaded = pcall(function() return im.IsLoaded end)
                if ok and not loaded then
                    pending = true
                    local img = im.Image
                    im.Image = ""; task.wait(0.1); im.Image = img
                end
            end
        end
        if not pending then break end
        task.wait(3)
    end
end)

-- everything the script changed is rolled back when the UI is unloaded / re-executed
Library.UnloadHooks = Library.UnloadHooks or {}
table.insert(Library.UnloadHooks, function()
    for k, v in pairs(State) do if v == true then State[k] = false end end
    for k in pairs(ESP_FLAGS) do ESP_FLAGS[k] = false end
    KillFx.EyeLaser = false; KillFx.RunKill = false
    for _, k in ipairs({"_beam", "_beam2"}) do if KillFx[k] then pcall(function() KillFx[k]:Destroy() end); KillFx[k] = nil end end
    pcall(function() if State.flyBV then State.flyBV:Destroy() end; if State.flyBG then State.flyBG:Destroy() end end)
    pcall(function() X.NC.restore() end)
    pcall(X.WINGS.destroy); pcall(X.AURA.destroy); pcall(X.AL.disable)
    pcall(function() X.LW.remove() end); pcall(function() X.ANIM.destroy() end)
    pcall(function() X.PV.clear() end); pcall(function() X.BoxESP.destroyAll() end); pcall(function() X.NOIR.destroy() end)
    X.LT = {}
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function() destroySkeleton(p) end)
        pcall(function() if tracers[p] then tracers[p].Visible = false; tracers[p]:Remove(); tracers[p] = nil end end)
        pcall(function()
            local c = p.Character
            if c then
                local h = c:FindFirstChild("PiddleHighlight"); if h then h:Destroy() end
                local t = c:FindFirstChild("PiddleTag"); if t then t:Destroy() end
            end
        end)
    end
end)
do local b=BG_LIST[CFG.bgName]
    if type(b)=="string" and b:find("^video:") then task.delay(1, function() pcall(X.LW.apply, true) end)
    elseif type(b)=="string" and b:find("^anim:") then task.delay(0.5, function() pcall(X.ANIM.apply, true, b:sub(6)) end) end
end
task.delay(0.8, function() Library:Notify({Title="piddle", Text="loaded successfully", Duration=5}) end)
task.delay(2.5, function() Library:Notify({Title="piddle", Text="click watermark to toggle ui", Duration=5}) end)
warn("[PIDDLE] Loaded, hope u enjoy it")