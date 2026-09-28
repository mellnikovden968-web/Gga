local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local guiParent = CoreGui
if type(gethui) == "function" then local ok,v=pcall(gethui); if ok and typeof(v)=="Instance" then guiParent=v end end
pcall(function() local old=guiParent:FindFirstChild("NoirSilentAimUI"); if old then old:Destroy() end end)

local C={base=Color3.fromRGB(8,8,15), surface=Color3.fromRGB(14,14,25), panel=Color3.fromRGB(20,20,34), border=Color3.fromRGB(66,52,110), accent=Color3.fromRGB(120,70,255), accent2=Color3.fromRGB(70,220,220), text=Color3.fromRGB(245,242,255), dim=Color3.fromRGB(157,153,180), off=Color3.fromRGB(38,38,55)}
local function New(class,props)
 local x=Instance.new(class); for k,v in pairs(props or {}) do if k~="Parent" then x[k]=v end end; x.Parent=props and props.Parent; return x
end
local function corner(x,r) New("UICorner",{CornerRadius=UDim.new(0,r or 12),Parent=x}) end
local function stroke(x,col,tr) New("UIStroke",{Color=col or C.border,Transparency=tr or .35,Thickness=1,Parent=x}) end
local function text(parent,value,size,pos,dim)
 return New("TextLabel",{Parent=parent,BackgroundTransparency=1,Text=value,TextColor3=dim and C.dim or C.text,TextSize=size,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Position=pos or UDim2.new(),Size=UDim2.new(1,0,0,size+8)})
end
local gui=New("ScreenGui",{Name="NoirSilentAimUI",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=guiParent})
local scale=New("UIScale",{Parent=gui,Scale=1})
local function rescale()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 scale.Scale=math.min(v.X/1360,v.Y/760,0.80)
end
rescale(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end
local win=New("Frame",{Parent=gui,Name="Window",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1280,690),BackgroundColor3=C.base,BackgroundTransparency=.04,ClipsDescendants=true})
corner(win,30); stroke(win,C.border,.08)
New("UIGradient",{Parent=win,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(17,13,35)),ColorSequenceKeypoint.new(.55,C.base),ColorSequenceKeypoint.new(1,Color3.fromRGB(8,26,30))}),Rotation=18})
local sidebar=New("Frame",{Parent=win,Size=UDim2.fromOffset(250,690),BackgroundColor3=Color3.fromRGB(10,10,20),BackgroundTransparency=.13}); stroke(sidebar,C.border,.55)
local logo=New("TextLabel",{Parent=sidebar,Position=UDim2.fromOffset(35,30),Size=UDim2.fromOffset(92,92),BackgroundColor3=Color3.fromRGB(16,12,34),Text="V",TextColor3=C.text,TextSize=62,Font=Enum.Font.GothamBold}); corner(logo,22); stroke(logo,C.accent,.05)
New("UIGradient",{Parent=logo,Color=ColorSequence.new(C.text,C.accent),Rotation=90})
text(sidebar,"V E L V E T",20,UDim2.fromOffset(35,132)); text(sidebar,"U I  L I B R A R Y",10,UDim2.fromOffset(38,162),true)
local search=New("TextBox",{Parent=sidebar,Position=UDim2.fromOffset(20,205),Size=UDim2.fromOffset(210,48),BackgroundColor3=C.panel,PlaceholderText="  Search features...",Text="",TextColor3=C.text,PlaceholderColor3=C.dim,TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false}); corner(search,12); stroke(search)
local home=New("TextButton",{Parent=sidebar,Position=UDim2.fromOffset(18,278),Size=UDim2.fromOffset(214,58),BackgroundColor3=Color3.fromRGB(49,31,92),Text="⌂    Home                         5",TextColor3=C.text,TextSize=17,Font=Enum.Font.Gotham,AutoButtonColor=false}); corner(home,12); stroke(home,C.accent,.05)
local configsNav=New("TextButton",{Parent=sidebar,Position=UDim2.fromOffset(18,346),Size=UDim2.fromOffset(214,58),BackgroundColor3=Color3.fromRGB(20,20,34),Text="▣    Configs",TextColor3=C.dim,TextSize=17,Font=Enum.Font.Gotham,AutoButtonColor=false})
corner(configsNav,12); stroke(configsNav,C.border,.55)
local status=New("Frame",{Parent=sidebar,Position=UDim2.fromOffset(18,590),Size=UDim2.fromOffset(214,78),BackgroundColor3=C.panel}); corner(status,14); stroke(status)
text(status,"●  Connected",13,UDim2.fromOffset(16,10)); text(status,"Noir Client",16,UDim2.fromOffset(16,35));
local header=New("Frame",{Parent=win,Position=UDim2.fromOffset(250,0),Size=UDim2.new(1,-250,0,110),BackgroundTransparency=1})
local icon=New("TextLabel",{Parent=header,Position=UDim2.fromOffset(36,24),Size=UDim2.fromOffset(62,62),BackgroundColor3=C.panel,Text="⊙",TextColor3=C.accent,TextSize=38,Font=Enum.Font.GothamBold}); corner(icon,16); stroke(icon,C.accent,.25)
text(header,"Noir Silent Aim",30,UDim2.fromOffset(116,23)); text(header,"Murder Mystery 2",16,UDim2.fromOffset(117,61),true)
local function topButton(txt,x,color)
 local b=New("TextButton",{Parent=header,Position=UDim2.new(1,x,0,25),Size=UDim2.fromOffset(43,43),BackgroundColor3=color or C.panel,Text=txt,TextColor3=C.text,TextSize=22,Font=Enum.Font.GothamBold}); corner(b,13); return b
end
local mini=topButton("−",-108,Color3.fromRGB(120,82,22)); local close=topButton("×",-58,Color3.fromRGB(125,35,48)); close.MouseButton1Click:Connect(function() gui:Destroy() end)

local dragging, dragStart, startPos
header.Active=true
header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true; dragStart=input.Position; startPos=win.Position
 end
end)
UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
  local delta=input.Position-dragStart
  local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
  local half=win.AbsoluteSize/2
  local desired=Vector2.new(startPos.X.Scale*view.X+startPos.X.Offset*scale.Scale+delta.X,startPos.Y.Scale*view.Y+startPos.Y.Offset*scale.Scale+delta.Y)
  desired=Vector2.new(math.clamp(desired.X,half.X,view.X-half.X),math.clamp(desired.Y,half.Y,view.Y-half.Y))
  win.Position=UDim2.fromOffset(desired.X/scale.Scale,desired.Y/scale.Scale)
 end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

local restore=New("TextButton",{Parent=gui,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-22,.5,0),Size=UDim2.fromOffset(62,62),BackgroundColor3=C.panel,Text="V",TextColor3=C.text,TextSize=30,Font=Enum.Font.GothamBold,Visible=false,AutoButtonColor=false})
corner(restore,20); stroke(restore,C.accent,.05)
local restoreDragging=false
local restoreMoved=false
local restoreStart
local restorePos
restore.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  restoreDragging=true; restoreMoved=false; restoreStart=input.Position; restorePos=restore.Position
 end
end)
UIS.InputChanged:Connect(function(input)
 if restoreDragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
  local delta=input.Position-restoreStart
  if delta.Magnitude>7 then restoreMoved=true end
  local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
  local x=math.clamp(restorePos.X.Offset*scale.Scale+delta.X,34,view.X-34)
  local y=math.clamp(restorePos.Y.Scale*view.Y+restorePos.Y.Offset*scale.Scale+delta.Y,34,view.Y-34)
  restore.Position=UDim2.fromOffset(x/scale.Scale,y/scale.Scale)
 end
end)
UIS.InputEnded:Connect(function(input)
 if restoreDragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then restoreDragging=false end
end)
mini.MouseButton1Click:Connect(function() win.Visible=false; restore.Visible=true end)
restore.MouseButton1Click:Connect(function() if restoreMoved then restoreMoved=false return end; restore.Visible=false; win.Visible=true end)
local content=New("ScrollingFrame",{Parent=win,Position=UDim2.fromOffset(275,110),Size=UDim2.new(1,-300,1,-130),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=7,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=true,Active=true,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,VerticalScrollBarInset=Enum.ScrollBarInset.Always})
local cols={}
for i=1,2 do cols[i]=New("Frame",{Parent=content,Position=UDim2.new((i-1)*.5,(i-1)*10,0,0),Size=UDim2.new(.5,-10,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y}); New("UIListLayout",{Parent=cols[i],Padding=UDim.new(0,16),SortOrder=Enum.SortOrder.LayoutOrder}) end
local configContent=content:Clone(); configContent.Name="ConfigContent"; configContent.Parent=win; configContent.Visible=false; configContent:ClearAllChildren()
local configCols={}
for i=1,2 do configCols[i]=New("Frame",{Parent=configContent,Position=UDim2.new((i-1)*.5,(i-1)*10,0,0),Size=UDim2.new(.5,-10,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y}); New("UIListLayout",{Parent=configCols[i],Padding=UDim.new(0,16),SortOrder=Enum.SortOrder.LayoutOrder}) end
sidebar.Visible=false
header.Position=UDim2.fromOffset(0,0); header.Size=UDim2.new(1,0,0,105)
content.Position=UDim2.fromOffset(24,112); content.Size=UDim2.new(1,-48,1,-210); content.Visible=false
configContent.Position=content.Position; configContent.Size=content.Size
local visualContent=content:Clone(); visualContent.Name="VisualContent"; visualContent.Parent=win; visualContent.Visible=false; visualContent:ClearAllChildren()
local visualCols={}
for i=1,2 do visualCols[i]=New("Frame",{Parent=visualContent,Position=UDim2.new((i-1)*.5,(i-1)*10,0,0),Size=UDim2.new(.5,-10,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y}); New("UIListLayout",{Parent=visualCols[i],Padding=UDim.new(0,16),SortOrder=Enum.SortOrder.LayoutOrder}) end
local dashboard=New("Frame",{Parent=win,Position=content.Position,Size=content.Size,BackgroundTransparency=1})
local profile=New("Frame",{Parent=dashboard,Position=UDim2.fromOffset(20,22),Size=UDim2.fromOffset(500,180),BackgroundColor3=C.panel,BackgroundTransparency=.08}); corner(profile,22); stroke(profile,C.border,.15)
local avatar=New("ImageLabel",{Parent=profile,Position=UDim2.fromOffset(24,28),Size=UDim2.fromOffset(118,118),BackgroundColor3=C.surface}); corner(avatar,28); stroke(avatar,C.accent,.05)
task.spawn(function() local ok,img=pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size180x180) end); if ok then avatar.Image=img end end)
text(profile,LocalPlayer.DisplayName,25,UDim2.fromOffset(166,38)); text(profile,"@"..LocalPlayer.Name,16,UDim2.fromOffset(167,78),true); text(profile,"Noir Client • Connected",15,UDim2.fromOffset(167,112))
local fpsCard=New("Frame",{Parent=dashboard,Position=UDim2.fromOffset(545,22),Size=UDim2.fromOffset(310,180),BackgroundColor3=C.panel,BackgroundTransparency=.08}); corner(fpsCard,22); stroke(fpsCard,C.border,.15)
text(fpsCard,"FPS",16,UDim2.fromOffset(24,25),true); local fpsText=text(fpsCard,"60",46,UDim2.fromOffset(24,62)); fpsText.TextColor3=Color3.fromRGB(80,235,125)
local pingCard=New("Frame",{Parent=dashboard,Position=UDim2.fromOffset(880,22),Size=UDim2.new(1,-900,0,180),BackgroundColor3=C.panel,BackgroundTransparency=.08}); corner(pingCard,22); stroke(pingCard,C.border,.15)
text(pingCard,"NETWORK LATENCY",16,UDim2.fromOffset(24,25),true); local pingText=text(pingCard,"-- ms",38,UDim2.fromOffset(24,66)); pingText.TextColor3=C.accent2
local infoCard=New("Frame",{Parent=dashboard,Position=UDim2.fromOffset(20,225),Size=UDim2.new(1,-40,1,-245),BackgroundColor3=C.panel,BackgroundTransparency=.16}); corner(infoCard,24); stroke(infoCard,C.border,.18)
text(infoCard,"NOIR SILENT AIM",28,UDim2.fromOffset(28,26)); text(infoCard,"Gun prediction • Knife prediction • Player and object ESP • Preset profiles",16,UDim2.fromOffset(29,68),true)
local frameCounter,lastFps=0,os.clock(); RunService.RenderStepped:Connect(function() frameCounter+=1; local now=os.clock(); if now-lastFps>=1 then fpsText.Text=tostring(math.floor(frameCounter/(now-lastFps)+.5)); frameCounter=0; lastFps=now; local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end); pingText.Text=ok and (tostring(math.floor(v+.5)).." ms") or "-- ms" end end)
local bottom=New("Frame",{Parent=win,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-18),Size=UDim2.fromOffset(650,70),BackgroundColor3=C.panel,BackgroundTransparency=.04}); corner(bottom,22); stroke(bottom,C.border,.1)
local navButtons={}
local navDefs={{"home","⌂  Home"},{"aim","⊙  Aim + Configs"},{"visual","◉  Visuals"}}
for i,d in ipairs(navDefs) do local b=New("TextButton",{Parent=bottom,Position=UDim2.fromOffset(12+(i-1)*209,10),Size=UDim2.fromOffset(202,50),BackgroundColor3=C.surface,Text=d[2],TextColor3=C.dim,TextSize=16,Font=Enum.Font.Gotham,AutoButtonColor=false}); corner(b,15); navButtons[d[1]]=b end
search.Parent=header; search.Position=UDim2.new(1,-370,0,28); search.Size=UDim2.fromOffset(210,46)
local activePage="home"
local function selectPage(page)
 activePage=page; dashboard.Visible=page=="home"; content.Visible=page=="aim"; visualContent.Visible=page=="visual"; configContent.Visible=false
 for name,b in pairs(navButtons) do b.BackgroundColor3=name==page and Color3.fromRGB(58,35,110) or C.surface; b.TextColor3=name==page and C.text or C.dim end
end
for name,b in pairs(navButtons) do b.MouseButton1Click:Connect(function() selectPage(name) end) end
selectPage("home")
local sectionCount=0
local visualSectionCount=0
local configSectionCount=0
local sectionPanels={}
local controls={}
local function refreshCanvas()
 task.defer(function()
  local h=math.max(cols[1].AbsoluteSize.Y,cols[2].AbsoluteSize.Y)+80
  content.CanvasSize=UDim2.fromOffset(0,h)
  local ch=math.max(configCols[1].AbsoluteSize.Y,configCols[2].AbsoluteSize.Y)+80
  configContent.CanvasSize=UDim2.fromOffset(0,ch)
  local vh=math.max(visualCols[1].AbsoluteSize.Y,visualCols[2].AbsoluteSize.Y)+80
  visualContent.CanvasSize=UDim2.fromOffset(0,vh)
 end)
end
search:GetPropertyChangedSignal("Text"):Connect(function()
 local q=string.lower(search.Text or "")
 local counts={aim=0,visual=0}
 for _,entry in ipairs(sectionPanels) do
  local hay=entry.name
  for _,d in ipairs(entry.panel:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") then hay=hay.." "..string.lower(d.Text or "") end end
  local match=q=="" or string.find(hay,q,1,true)~=nil
  entry.panel.Visible=match
  if match then counts[entry.page]=(counts[entry.page] or 0)+1 end
 end
 if q~="" and activePage~="home" and (counts[activePage] or 0)==0 then for _,page in ipairs({"aim","visual"}) do if counts[page]>0 then selectPage(page) break end end end
 refreshCanvas()
end)
local host={}
function host.Notify(title,duration)
 local toast=New("TextLabel",{Parent=gui,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-22,1,-22),Size=UDim2.fromOffset(330,58),BackgroundColor3=C.panel,Text="  "..tostring(title),TextColor3=C.text,TextSize=15,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left}); corner(toast,13); stroke(toast,C.accent,.15); task.delay(duration or 3,function() if toast.Parent then toast:Destroy() end end)
end
function host.CreateTab()
 local tab={}
 function tab:AddSection(name,description)
  local isConfig=name=="NOIR CONFIG"
  local isVisual=name=="Visuals" or name=="Object ESP"
  local col
  local page="aim"
  if isVisual then visualSectionCount+=1; col=visualCols[(visualSectionCount-1)%2+1]; page="visual"
  else sectionCount+=1; col=cols[(sectionCount-1)%2+1] end
  local panel=New("Frame",{Parent=col,Size=UDim2.new(1,0,0,90),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.panel,BackgroundTransparency=.12,ClipsDescendants=true}); corner(panel,22); stroke(panel,C.border,.2)
  table.insert(sectionPanels,{panel=panel,page=page,name=string.lower(name.." "..(description or ""))})
  local bar=New("Frame",{Parent=panel,Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(4,42),BackgroundColor3=C.accent}); corner(bar,4)
  text(panel,name,19,UDim2.fromOffset(24,14)); if description and description~="" then text(panel,description,12,UDim2.fromOffset(24,42),true) end
  local holder=New("Frame",{Parent=panel,Position=UDim2.fromOffset(20,description~="" and 72 or 55),Size=UDim2.new(1,-40,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
  New("UIListLayout",{Parent=holder,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
  New("UIPadding",{Parent=holder,PaddingBottom=UDim.new(0,18)})
  holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCanvas); refreshCanvas()
  local api={}
  local function row(label,h)
   local r=New("Frame",{Parent=holder,Size=UDim2.new(1,0,0,h or 62),BackgroundTransparency=1}); text(r,label,16,UDim2.fromOffset(0,10)); return r
  end
  function api:AddToggle(label,callback)
   local state=false; local r=row(label,62); local pill=New("TextButton",{Parent=r,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,8),Size=UDim2.fromOffset(64,34),BackgroundColor3=C.off,Text="",AutoButtonColor=false}); corner(pill,17); stroke(pill,C.border,.55)
   local dot=New("Frame",{Parent=pill,Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(26,26),BackgroundColor3=Color3.fromRGB(145,145,180)}); corner(dot,13)
   local function set(v) state=v==true; TweenService:Create(pill,TweenInfo.new(.18),{BackgroundColor3=state and C.accent or C.off}):Play(); TweenService:Create(dot,TweenInfo.new(.18),{Position=state and UDim2.fromOffset(34,4) or UDim2.fromOffset(4,4),BackgroundColor3=state and Color3.new(1,1,1) or Color3.fromRGB(145,145,180)}):Play(); callback(state) end
   pill.MouseButton1Click:Connect(function() set(not state) end); return function(v) set(v==nil and not state or v) end
  end
  function api:AddButton(label,callback)
   local b=New("TextButton",{Parent=holder,Size=UDim2.new(1,0,0,48),BackgroundColor3=Color3.fromRGB(52,34,98),Text=label,TextColor3=C.text,TextSize=15,Font=Enum.Font.Gotham}); corner(b,11); stroke(b,C.accent,.25); b.MouseButton1Click:Connect(callback); return b
  end
  function api:AddSlider(label,min,max,default,callback)
   local r=row(label,76); local value=text(r,tostring(default),14,UDim2.new(1,-72,0,10)); value.Size=UDim2.fromOffset(72,22); value.TextXAlignment=Enum.TextXAlignment.Right
   local track=New("Frame",{Parent=r,Position=UDim2.new(0,0,1,-18),Size=UDim2.new(1,0,0,5),BackgroundColor3=C.off}); corner(track,3)
   local fill=New("Frame",{Parent=track,Size=UDim2.fromScale((default-min)/(max-min),1),BackgroundColor3=C.accent}); corner(fill,3)
   local current=default
   local function set(v) current=math.clamp(math.floor((tonumber(v) or default)+.5),min,max); fill.Size=UDim2.fromScale((current-min)/(max-min),1); value.Text=tostring(current); callback(current) end
   local drag=false; track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; set(min+(max-min)*math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)) end end); UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then set(min+(max-min)*math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
   return {SetValue=function(_,v)set(v)end}
  end
  function api:AddDropdown(label,values,callback)
   local r=row(label,64); local idx=1
   local b=New("TextButton",{Parent=r,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,4),Size=UDim2.fromOffset(190,42),BackgroundColor3=C.surface,Text=tostring(values[1] or "None").."  ⌄",TextColor3=C.text,TextSize=14,Font=Enum.Font.Gotham,ZIndex=5}); corner(b,10); stroke(b)
   local popup
   local function close() if popup then popup:Destroy(); popup=nil end end
   local function set(v) local found=table.find(values,v); if found then idx=found end; b.Text=tostring(values[idx] or "None").."  ⌄"; if values[idx]~=nil then callback(values[idx]) end end
   local function open()
    close(); popup=New("ScrollingFrame",{Parent=gui,Position=UDim2.fromOffset(b.AbsolutePosition.X/scale.Scale,(b.AbsolutePosition.Y+b.AbsoluteSize.Y+4)/scale.Scale),Size=UDim2.fromOffset(b.AbsoluteSize.X/scale.Scale,math.min(#values*38,190)),CanvasSize=UDim2.fromOffset(0,#values*38),BackgroundColor3=C.surface,BorderSizePixel=0,ScrollBarThickness=4,ZIndex=50}); corner(popup,10); stroke(popup,C.accent,.2)
    local list=New("UIListLayout",{Parent=popup,SortOrder=Enum.SortOrder.LayoutOrder})
    for _,v in ipairs(values) do local item=New("TextButton",{Parent=popup,Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,Text=tostring(v),TextColor3=C.text,TextSize=14,Font=Enum.Font.Gotham,ZIndex=51}); item.MouseButton1Click:Connect(function() set(v); close() end) end
   end
   b.MouseButton1Click:Connect(function() if popup then close() else open() end end)
   local ctl={}
   function ctl:SetValue(v) set(v) end
   function ctl:Refresh(newValues,selected) values=newValues or {}; idx=1; set(selected or values[1]) end
   return ctl
  end
  function api:AddTextBox(label,callback)
   local r=row(label,72); local box=New("TextBox",{Parent=r,Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,38),BackgroundColor3=C.surface,Text="",PlaceholderText=label,TextColor3=C.text,PlaceholderColor3=C.dim,TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false}); corner(box,9); stroke(box); box.FocusLost:Connect(function()callback(box.Text)end); return {SetValue=function(_,v)box.Text=tostring(v)end}
  end
  function api:AddLabel(label) local r=row(label,44); return r end
  return api
 end
 return tab
end


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local config = {
    enabled = false,
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    maxLead = 0.18,
    horizontalOnly = true,
    targetPart = "HumanoidRootPart",
    alignDirection = true,
    wallCheck = false,
    knifeEnabled = false,
    knifeWallCheck = false,
    knifePrioritizeSheriff = true,
    espOutline = false,
    espOutlineMurderer = false,
    espOutlineSheriff = false,
    espBox = false,
    espBoxMurderer = false,
    espBoxSheriff = false,
    outlineDroppedGun = false,
    outlineTraps = false,
    outlineThrowingKnives = false,
    outlineCoins = false,
    boxDroppedGun = false,
    boxTraps = false,
    boxThrowingKnives = false,
    boxCoins = false,
    prioritizePing = true,
    predictJump = false,
    predictLag = true,
    maxSimulationMs = 180,
    predictionIntervalMs = 72,
    manualPingMs = 80,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    horizontalMultiplier = 100,
    verticalMultiplier = 100,
    showShootButton = false,
    lockShootButton = false,
}

local murderer
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton
local shootGui
local shootBusy = false
local presetName = "default"
local PRESET_FOLDER = "NOIR.CONFIG"
local revertControls = {}
local revertToggleStates = {}
local syncRevertControls
local presetDropdown
local motionPart
local motionPosition
local motionTime
local measuredVelocity = Vector3.zero
local motionSamples = {}
local previousEstimatedVelocity = Vector3.zero
local estimatedAcceleration = Vector3.zero
local lastAutoTune = 0

local function notify(text, time)
    if type(host.Notify) == "function" then
        pcall(host.Notify, "MM2 Silent Aim: " .. tostring(text), time or 3)
    end
end

local function validTarget(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return player ~= LocalPlayer and character ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local roleCache = {}
local ESP_OUTLINE_NAME = "NoirESPOutline"
local ESP_BOX_NAME = "NoirESPBox"
local function clearESPCharacter(character)
    if not character then return end
    local outline = character:FindFirstChild(ESP_OUTLINE_NAME)
    if outline then outline:Destroy() end
    for _, item in ipairs(character:GetDescendants()) do
        if item.Name == ESP_BOX_NAME or item.Name == "NoirESPRole" then item:Destroy() end
    end
end
local function espPlayerRole(player)
    local cached = player and roleCache[player.UserId]
    if cached == "murderer" or cached == "sheriff" or cached == "hero" or cached == "innocent" then return cached end
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("Backpack")
    if (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "murderer" end
    if (character and character:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "sheriff" end
    return "innocent"
end
local function roleColor(role)
    if role == "murderer" then return Color3.fromRGB(255, 55, 65) end
    if role == "sheriff" then return Color3.fromRGB(55, 145, 255) end
    if role == "hero" then return Color3.fromRGB(255, 220, 45) end
    return Color3.fromRGB(65, 235, 105)
end


local function applyESPPlayer(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    clearESPCharacter(character)
    local role = espPlayerRole(player)
    local outlineWanted = config.espOutline or (config.espOutlineMurderer and role == "murderer") or (config.espOutlineSheriff and role == "sheriff")
    local boxWanted = config.espBox or (config.espBoxMurderer and role == "murderer") or (config.espBoxSheriff and role == "sheriff")
    if outlineWanted then
        local highlight = Instance.new("Highlight")
        highlight.Name = ESP_OUTLINE_NAME
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.OutlineColor = roleColor(role)
        highlight.Parent = character
    end
    if boxWanted then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local box = Instance.new("BillboardGui")
            box.Name = ESP_BOX_NAME
            box.Adornee = root
            box.AlwaysOnTop = true
            box.LightInfluence = 0
            box.Size = UDim2.fromOffset(72, 108)
            box.StudsOffset = Vector3.new(0, 0.35, 0)
            box.Parent = root
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.fromScale(1, 1)
            frame.Parent = box
            local line = Instance.new("UIStroke")
            line.Color = roleColor(role)
            line.Thickness = 1.5
            line.Transparency = 0
            line.Parent = frame
            local rounding = Instance.new("UICorner")
            rounding.CornerRadius = UDim.new(0, 4)
            rounding.Parent = frame
        end
    end
end
local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do applyESPPlayer(player) end
end
local function bindESPPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function() task.wait(0.5); applyESPPlayer(player) end)
    if player.Character then applyESPPlayer(player) end
end
for _, player in ipairs(Players:GetPlayers()) do bindESPPlayer(player) end
Players.PlayerAdded:Connect(bindESPPlayer)

local function objectKind(instance)
    local name = string.lower(instance.Name)
    if string.find(name, "coin", 1, true) then return "coin" end
    if string.find(name, "trap", 1, true) then return "trap" end
    if name == "gun" or string.find(name, "droppedgun", 1, true) then return "gun" end
    if string.find(name, "knife", 1, true) and (string.find(name, "throw", 1, true) or not instance:FindFirstAncestorOfClass("Tool")) then return "knife" end
end
local function objectPart(instance)
    if instance:IsA("BasePart") then return instance end
    if instance:IsA("Model") then return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true) end
end
local function objectEnabled(kind, box)
    if box then return kind=="coin" and config.boxCoins or kind=="trap" and config.boxTraps or kind=="gun" and config.boxDroppedGun or kind=="knife" and config.boxThrowingKnives end
    return kind=="coin" and config.outlineCoins or kind=="trap" and config.outlineTraps or kind=="gun" and config.outlineDroppedGun or kind=="knife" and config.outlineThrowingKnives
end
local function refreshObjectESP()
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance.Name == "NoirObjectOutline" or instance.Name == "NoirObjectBox" then instance:Destroy() end
    end
    for _, instance in ipairs(Workspace:GetDescendants()) do
        local kind = objectKind(instance)
        local part = kind and objectPart(instance)
        if part and not Players:GetPlayerFromCharacter(instance:FindFirstAncestorOfClass("Model")) then
            if objectEnabled(kind, false) then
                local h=Instance.new("Highlight"); h.Name="NoirObjectOutline"; h.Adornee=instance; h.FillTransparency=1; h.OutlineTransparency=0; h.OutlineColor=kind=="gun" and Color3.fromRGB(70,170,255) or kind=="coin" and Color3.fromRGB(255,220,50) or Color3.fromRGB(100,255,150); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=instance
            end
            if objectEnabled(kind, true) then
                local box=Instance.new("SelectionBox"); box.Name="NoirObjectBox"; box.Adornee=part; box.SurfaceTransparency=1; box.LineThickness=.04; box.Color3=kind=="gun" and Color3.fromRGB(70,170,255) or kind=="coin" and Color3.fromRGB(255,220,50) or Color3.fromRGB(100,255,150); box.Parent=part
            end
        end
    end
end

local function setTarget(player)
    if not validTarget(player) then player = nil end
    if murderer ~= player then
        murderer = player
        if player then notify("Target: " .. player.Name, 2) end
    end
end

local function findByKnife()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local backpack = player:FindFirstChildOfClass("Backpack")
            if (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then
                return player
            end
        end
    end
end

local function consumeData(data)
    if typeof(data) ~= "table" then return false end
    local foundMurderer
    local rolesChanged = false
    for _, player in ipairs(Players:GetPlayers()) do
        local info = data[player.Name] or data[tostring(player.UserId)]
        local role = typeof(info) == "table" and (info.Role or info.role or info.CurrentRole) or info
        local normalized = string.lower(tostring(role or "innocent"))
        local resolved
        if normalized == "murderer" then resolved = "murderer"; foundMurderer = player
        elseif normalized == "sheriff" then resolved = "sheriff"
        elseif normalized == "hero" then resolved = "hero"
        else resolved = "innocent" end
        if roleCache[player.UserId] ~= resolved then rolesChanged = true; roleCache[player.UserId] = resolved end
    end
    if foundMurderer then setTarget(foundMurderer) end
    if rolesChanged then refreshESP() end
    return foundMurderer ~= nil
end

local function getPlayerDataRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local extras = remotes and remotes:FindFirstChild("Extras")
    local remote = extras and extras:FindFirstChild("GetPlayerData")
    return remote and remote:IsA("RemoteFunction") and remote or nil
end

local function refreshTarget()
    local weaponTarget = findByKnife()
    if weaponTarget then
        setTarget(weaponTarget)
        return
    end
    local remote = getPlayerDataRemote()
    if remote then
        local ok, data = pcall(function() return remote:InvokeServer() end)
        if ok and consumeData(data) then return end
    end
    setTarget(nil)
end

local function updatePing()
    pcall(function()
        local network = Stats:FindFirstChild("Network")
        local items = network and network:FindFirstChild("ServerStatsItem")
        local pingItem = items and items:FindFirstChild("Data Ping")
        if pingItem then
            local measured = pingItem:GetValue() / 1000
            if measured > 0 and measured < 2 then
                cachedPing = cachedPing * 0.7 + measured * 0.3
            end
        end
    end)
end

local PingProfiles = {
    {Ping = 20, Sim = 48, Interval = 70, H = 154, V = 144, X = -5, Y = -14, Z = 0},
    {Ping = 50, Sim = 54, Interval = 66, H = 162, V = 152, X = -6, Y = -14, Z = 0},
    {Ping = 100, Sim = 68, Interval = 60, H = 176, V = 166, X = -8, Y = -15, Z = 0},
    {Ping = 150, Sim = 72, Interval = 64, H = 182, V = 170, X = -9, Y = -12, Z = 0},
    {Ping = 200, Sim = 76, Interval = 70, H = 188, V = 174, X = -10, Y = -11, Z = 0},
    {Ping = 300, Sim = 82, Interval = 76, H = 196, V = 180, X = -12, Y = -10, Z = 0},
}

local function interpolateProfile(ping)
    local a, b = PingProfiles[1], PingProfiles[1]
    if ping >= PingProfiles[#PingProfiles].Ping then
        a, b = PingProfiles[#PingProfiles], PingProfiles[#PingProfiles]
    else
        for index = 1, #PingProfiles - 1 do
            if ping >= PingProfiles[index].Ping and ping <= PingProfiles[index + 1].Ping then
                a, b = PingProfiles[index], PingProfiles[index + 1]
                break
            end
        end
    end
    local span = b.Ping - a.Ping
    local alpha = span > 0 and math.clamp((ping - a.Ping) / span, 0, 1) or 0
    alpha = alpha * alpha * (3 - 2 * alpha)
    local function mix(key) return a[key] + (b[key] - a[key]) * alpha end
    return {
        Sim = math.floor(mix("Sim") + 0.5),
        Interval = math.floor(mix("Interval") + 0.5),
        H = math.floor(mix("H") + 0.5),
        V = math.floor(mix("V") + 0.5),
        X = math.floor(mix("X") + 0.5),
        Y = math.floor(mix("Y") + 0.5),
        Z = math.floor(mix("Z") + 0.5),
    }
end

local function autoTuneForPing()
    if not config.prioritizePing then return end
    local now = os.clock()
    if now - lastAutoTune < 0.4 then return end
    lastAutoTune = now
    local pingMs = math.clamp(math.floor(cachedPing * 1000 + 0.5), 5, 350)
    if config.manualPingMs ~= pingMs then
        config.manualPingMs = pingMs
        local control = revertControls.manualPingMs
        if type(control) == "table" and type(control.SetValue) == "function" then
            pcall(control.SetValue, control, pingMs)
        elseif type(control) == "function" then
            pcall(control, pingMs)
        end
    end
end

local function leadTime()
    local prediction
    if config.adaptive then
        local ping = config.prioritizePing and cachedPing or (config.manualPingMs / 1000)
        prediction = ping + config.extraLead
        if config.predictLag then
            local samplingDelay = math.clamp(config.predictionIntervalMs / 2000, 0, 0.05)
            prediction = prediction + samplingDelay + math.max(0, ping - 0.10) * 0.15
        end
    else
        prediction = config.fixedLead
    end
    return math.clamp(prediction, 0.02, math.min(config.maxLead, config.maxSimulationMs / 1000))
end

local function sampleMotion(part)
    local now = os.clock()
    if motionPart ~= part then
        motionPart = part
        motionSamples = {}
        measuredVelocity = part.AssemblyLinearVelocity
        previousEstimatedVelocity = measuredVelocity
        estimatedAcceleration = Vector3.zero
    end

    local last = motionSamples[#motionSamples]
    if not last or now - last.time >= math.max(0.016, config.predictionIntervalMs / 1000) then
        motionSamples[#motionSamples + 1] = {position = part.Position, time = now}
        while #motionSamples > 8 or (#motionSamples > 2 and now - motionSamples[1].time > 0.35) do
            table.remove(motionSamples, 1)
        end

        if #motionSamples >= 2 then
            local first = motionSamples[1]
            local newest = motionSamples[#motionSamples]
            local delta = newest.time - first.time
            if delta > 0.015 then
                local sampled = (newest.position - first.position) / delta
                if sampled.Magnitude < 150 then
                    local oldVelocity = measuredVelocity
                    measuredVelocity = measuredVelocity:Lerp(sampled, 0.55)
                    local sampleDelta = last and math.max(now - last.time, 0.016) or delta
                    local acceleration = (measuredVelocity - oldVelocity) / sampleDelta
                    if acceleration.Magnitude < 120 then
                        estimatedAcceleration = estimatedAcceleration:Lerp(acceleration, 0.25)
                    else
                        estimatedAcceleration = Vector3.zero
                    end
                    previousEstimatedVelocity = oldVelocity
                end
            end
        end
    end

    motionPosition = part.Position
    motionTime = now
end

local function calculateAim(part)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    local acceleration = Vector3.zero

    if config.predictLag and motionPart == part and #motionSamples >= 2 then
        local disagreement = (assembly - measuredVelocity).Magnitude
        local measuredWeight = math.clamp(0.75 - disagreement / 120, 0.35, 0.75)
        velocity = assembly:Lerp(measuredVelocity, measuredWeight)
        acceleration = estimatedAcceleration
    end

    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local yVelocity = config.predictJump and velocity.Y * vertical or 0
    local predictedVelocity = Vector3.new(
        velocity.X * horizontal,
        yVelocity,
        velocity.Z * horizontal
    )

    local time = leadTime()
    local displacement = predictedVelocity * time

    if config.predictLag then
        local horizontalAcceleration = Vector3.new(acceleration.X, 0, acceleration.Z)
        displacement = displacement + horizontalAcceleration * (0.5 * time * time)
    end

    if config.predictJump then
        local humanoid = part.Parent and part.Parent:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            displacement = displacement + Vector3.new(0, -0.5 * Workspace.Gravity * time * time, 0)
        end
    end

    if displacement.Magnitude > 18 then
        displacement = displacement.Unit * 18
    end

    local offset = Vector3.new(
        part.Size.X * config.offsetX / 100,
        part.Size.Y * config.offsetY / 100,
        part.Size.Z * config.offsetZ / 100
    )
    return part.Position + displacement + offset
end

local function targetPart()
    if not validTarget(murderer) then
        setTarget(findByKnife())
    end
    local character = murderer and murderer.Character
    return character and (
        character:FindFirstChild(config.targetPart)
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )
end

local function playerHasTool(player, toolName)
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end

local function findSheriff()
    for _, player in ipairs(Players:GetPlayers()) do
        if validTarget(player) and playerHasTool(player, "Gun") then return player end
    end
end

local function findNearestKnifeTarget()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, closestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        if validTarget(player) then
            local targetCharacter = player.Character
            local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if not closestDistance or distance < closestDistance then
                    closest, closestDistance = player, distance
                end
            end
        end
    end
    return closest
end

local function knifeTargetPart()
    local player
    if config.knifePrioritizeSheriff then
        player = findSheriff()
    else
        player = findNearestKnifeTarget()
    end
    local character = player and player.Character
    return character and (
        character:FindFirstChild(config.targetPart)
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )
end

local function knifeRemote(remote, args)
    if not config.knifeEnabled or args.n < 1 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if remote.Name ~= "KnifeThrown" then return false end
    local oneArgument = typeof(args[1]) == "CFrame" and (args.n == 1 or typeof(args[2]) ~= "CFrame")
    local twoArguments = typeof(args[1]) == "CFrame" and typeof(args[2]) == "CFrame"
    if not oneArgument and not twoArguments then return false end
    local character = LocalPlayer.Character
    local knife = character and character:FindFirstChild("Knife")
    return knife ~= nil and remote:IsDescendantOf(knife)
end

local function shotRemote(remote, args)
    if not config.enabled or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if typeof(args[1]) ~= "CFrame" or typeof(args[2]) ~= "CFrame" then return false end
    local character = LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun")
    return gun ~= nil and remote:IsDescendantOf(gun)
end

local function targetVisible(part)
    if not config.wallCheck then return true end
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    if not originPart or not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true
    local result = Workspace:Raycast(originPart.Position, part.Position - originPart.Position, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function calculateKnifeAim(part, origin)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    if config.predictLag and motionPart == part and #motionSamples >= 2 then
        velocity = assembly:Lerp(measuredVelocity, 0.65)
    end
    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local predictedVelocity = Vector3.new(
        velocity.X * horizontal,
        config.predictJump and velocity.Y * vertical or 0,
        velocity.Z * horizontal
    )
    local distance = (part.Position - origin).Magnitude
    local travelTime = math.clamp(distance / 200, 0, 0.4)
    local time = math.clamp(leadTime() + travelTime, 0.02, 0.5)
    local offset = Vector3.new(
        part.Size.X * config.offsetX / 100,
        part.Size.Y * config.offsetY / 100,
        part.Size.Z * config.offsetZ / 100
    )
    return part.Position + predictedVelocity * time + offset
end

local function redirect(remote, args)
    local part
    local useWallCheck = false
    local isKnife = false

    if shotRemote(remote, args) then
        part = targetPart()
        useWallCheck = config.wallCheck
    elseif knifeRemote(remote, args) then
        part = knifeTargetPart()
        useWallCheck = config.knifeWallCheck
        isKnife = true
    else
        return
    end

    if not part then return end
    if useWallCheck and not targetVisible(part) then return end

    local singleKnifeArgument = isKnife and (args.n == 1 or typeof(args[2]) ~= "CFrame")
    local origin = args[1].Position
    if singleKnifeArgument then
        local character = LocalPlayer.Character
        local knife = character and character:FindFirstChild("Knife")
        local handle = knife and knife:FindFirstChild("Handle")
        origin = handle and handle.Position or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position) or origin
    end
    local aim = isKnife and calculateKnifeAim(part, origin) or calculateAim(part)
    if singleKnifeArgument then
        args[1] = CFrame.new(aim)
    else
        if config.alignDirection and (aim - origin).Magnitude > 0.01 then
            args[1] = CFrame.lookAt(origin, aim)
        end
        args[2] = CFrame.new(aim)
    end
    redirected = redirected + 1
end

local function findGunRemote()
    local character = LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun")
    if not gun then return nil end
    for _, object in ipairs(gun:GetDescendants()) do
        if object:IsA("RemoteEvent") then return object end
    end
end

local function shootMurderer()
    if shootBusy then return false end
    shootBusy = true
    local success = false
    pcall(function()
        if not validTarget(murderer) then refreshTarget() end
        local part = targetPart()
        local camera = Workspace.CurrentCamera
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not part or not camera or not character or not humanoid then return end
        if not targetVisible(part) then return end

        local autoEquipped = false
        local gun = character:FindFirstChild("Gun")
        if not gun and backpack then
            gun = backpack:FindFirstChild("Gun")
            if gun then
                humanoid:EquipTool(gun)
                autoEquipped = true
                task.wait(0.08)
            end
        end

        local remote = findGunRemote()
        if not remote then
            if autoEquipped then humanoid:UnequipTools() end
            return
        end

        if not config.enabled then
            sampleMotion(part)
            task.wait(math.clamp(config.predictionIntervalMs / 1000, 0.025, 0.07))
            sampleMotion(part)
        end
        local aim = calculateAim(part)
        local handle = gun and gun:FindFirstChild("Handle")
        local origin = handle and handle.Position or camera.CFrame.Position
        remote:FireServer(CFrame.lookAt(origin, aim), CFrame.new(aim))
        success = true

        if autoEquipped then
            task.wait(0.12)
            if humanoid.Parent then humanoid:UnequipTools() end
        end
    end)
    shootBusy = false
    return success
end

local function removeShootButton()
    if shootGui then shootGui:Destroy() shootGui = nil shootButton = nil end
end

local function createShootButton()
    if shootButton then return end
    local parent = CoreGui
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then parent = result end
    end
    if typeof(parent) ~= "Instance" then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    shootGui = Instance.new("ScreenGui")
    shootGui.Name = "MM2ShootMurdererButton"
    shootGui.ResetOnSpawn = false
    shootGui.IgnoreGuiInset = true
    shootGui.Parent = parent

    local button = Instance.new("TextButton")
    button.Name = "ShootMurderer"
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.new(0.5, 0, 0.5, 0)
    button.Size = UDim2.new(0, 200, 0, 75)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 0.9
    button.BorderSizePixel = 0
    button.Text = "Shoot Murderer"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.TextWrapped = true
    button.Font = Enum.Font.Jura
    button.ClipsDescendants = true
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = shootGui
    shootButton = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(20, 20, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 120))
    })
    gradient.Parent = stroke
    task.spawn(function()
        while button.Parent do
            gradient.Rotation = (gradient.Rotation + 1) % 360
            RunService.RenderStepped:Wait()
        end
    end)

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
    ripple.BackgroundTransparency = 1
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Visible = false
    ripple.ZIndex = 4
    ripple.Parent = button
    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = UDim.new(1, 0)
    rippleCorner.Parent = ripple

    local sound = Instance.new("Sound")
    sound.Name = "Sound"
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = button

    local normalSize = UDim2.new(0, 200, 0, 75)
    local pressedSize = UDim2.new(0, 220, 0, 82)
    local pressTween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local dragging = false
    local moved = false
    local dragStart
    local startPosition
    local dragInput

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = not config.lockShootButton
            moved = false
            dragStart = input.Position
            startPosition = button.Position

            TweenService:Create(button, pressTween, {Size = pressedSize, TextSize = 26}):Play()
            sound:Play()
            local absolute = button.AbsolutePosition
            ripple.Position = UDim2.new(0, input.Position.X - absolute.X, 0, input.Position.Y - absolute.Y)
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.45
            ripple.Visible = true
            TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, 300),
                BackgroundTransparency = 1
            }):Play()
        end
    end)
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and not config.lockShootButton then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then moved = true end
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(button, pressTween, {Size = normalSize, TextSize = 24}):Play()
        end
    end)
    button.Activated:Connect(function()
        if not moved then shootMurderer() end
    end)
end

local function setShootButtonVisible(value)
    config.showShootButton = value == true
    if config.showShootButton then createShootButton() else removeShootButton() end
end

local function installHook()
    if hooked then return true end
    if type(hookfunction) ~= "function" then
        notify("hookfunction is unavailable", 6)
        return false
    end
    local wrap = type(newcclosure) == "function" and newcclosure or function(callback) return callback end
    local probe = Instance.new("RemoteEvent")
    local original
    local ok, err = pcall(function()
        original = hookfunction(probe.FireServer, wrap(function(self, ...)
            local args = table.pack(...)
            pcall(redirect, self, args)
            return original(self, table.unpack(args, 1, args.n))
        end))
    end)
    probe:Destroy()
    if not ok then
        notify("Hook failed: " .. tostring(err), 6)
        return false
    end
    hooked = true
    return true
end

local function toggle(value)
    config.enabled = value == true
    if config.enabled then
        if not installHook() then config.enabled = false return end
        task.spawn(refreshTarget)
        notify("Enabled", 2)
    else
        notify("Disabled", 2)
    end
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local gameplay = remotes and remotes:FindFirstChild("Gameplay")
if gameplay then
    local roundEnd = gameplay:FindFirstChild("RoundEndFade")
    if roundEnd and roundEnd:IsA("RemoteEvent") then
        roundEnd.OnClientEvent:Connect(function() murderer = nil end)
    end
    for _, name in ipairs({"Fade", "PlayerDataChanged", "RoleSelect", "RoundStart"}) do
        local event = gameplay:FindFirstChild(name)
        if event and event:IsA("RemoteEvent") then
            event.OnClientEvent:Connect(function(...)
                local found = false
                for index = 1, select("#", ...) do
                    local value = select(index, ...)
                    if typeof(value) == "table" and consumeData(value) then found = true break end
                end
                if not found then task.delay(0.35, refreshTarget) end
            end)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    roleCache[player.UserId] = nil
    if player == murderer then murderer = nil end
end)

task.spawn(function()
    while running do
        local remote = getPlayerDataRemote()
        if remote then
            local ok, data = pcall(function() return remote:InvokeServer() end)
            if ok and typeof(data) == "table" then consumeData(data) end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while running do
        updatePing()
        autoTuneForPing()
        if config.enabled then
            if not validTarget(murderer) then setTarget(findByKnife()) end
            local part = targetPart()
            if part then sampleMotion(part) end
        elseif config.knifeEnabled then
            local part = knifeTargetPart()
            if part then sampleMotion(part) end
        end
        task.wait(math.clamp(config.predictionIntervalMs / 1000, 0.016, 2))
    end
end)

local function cleanPresetName(name)
    name = tostring(name or "default"):gsub("%.preset$", ""):gsub("[^%w_%- ]", "_")
    return name ~= "" and name or "default"
end

local function ensurePresetFolder()
    if type(makefolder) ~= "function" then return end
    if type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, PRESET_FOLDER)
        if ok and exists then return end
    end
    pcall(makefolder, PRESET_FOLDER)
end

local function xorPreset(data)
    local output = table.create(#data)
    for index = 1, #data do
        output[index] = string.char(bit32.bxor(string.byte(data, index), 40))
    end
    return table.concat(output)
end

local function exportRevertConfig()
    return {
        cfg = {
            predict_jump = config.predictJump,
            prediction_ping = config.manualPingMs,
            y_pos_offset = config.offsetY / 100,
            prioritize_your_ping = config.prioritizePing,
            horizontal_multiplier = config.horizontalMultiplier / 100,
            vertical_multiplier = config.verticalMultiplier / 100,
            max_simulation_time = config.maxSimulationMs,
            interval = config.predictionIntervalMs / 10000,
            z_pos_offset = config.offsetZ / 100,
            predict_lag = config.predictLag,
            x_pos_offset = config.offsetX / 100,
        },
        author = LocalPlayer.Name,
        game = "Murder Mystery 2",
        category = "gun",
    }
end

local function applyRevertConfig(data)
    local cfg = typeof(data) == "table" and data.cfg
    if typeof(cfg) ~= "table" then return false end
    if typeof(cfg.predict_jump) == "boolean" then
        config.predictJump = cfg.predict_jump
        if cfg.predict_jump then config.horizontalOnly = false end
    end
    if typeof(cfg.prediction_ping) == "number" then config.manualPingMs = cfg.prediction_ping end
    if typeof(cfg.prioritize_your_ping) == "boolean" then config.prioritizePing = cfg.prioritize_your_ping end
    if typeof(cfg.horizontal_multiplier) == "number" then config.horizontalMultiplier = cfg.horizontal_multiplier * 100 end
    if typeof(cfg.vertical_multiplier) == "number" then config.verticalMultiplier = cfg.vertical_multiplier * 100 end
    if typeof(cfg.max_simulation_time) == "number" then config.maxSimulationMs = cfg.max_simulation_time end
    if typeof(cfg.interval) == "number" then config.predictionIntervalMs = cfg.interval * 10000 end
    if typeof(cfg.x_pos_offset) == "number" then config.offsetX = cfg.x_pos_offset * 100 end
    if typeof(cfg.y_pos_offset) == "number" then config.offsetY = cfg.y_pos_offset * 100 end
    if typeof(cfg.z_pos_offset) == "number" then config.offsetZ = cfg.z_pos_offset * 100 end
    if typeof(cfg.predict_lag) == "boolean" then config.predictLag = cfg.predict_lag end
    return true
end

local presetNames

local function savePreset()
    if type(writefile) ~= "function" then notify("Executor does not support writefile", 4) return end
    ensurePresetFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(exportRevertConfig()) end)
    if ok then
        local wrote, err = pcall(writefile, PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset", xorPreset(encoded))
        if wrote then
            notify("Preset saved: " .. cleanPresetName(presetName), 3)
            if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(presetNames(), cleanPresetName(presetName)) end
        else notify("Preset save failed: " .. tostring(err), 4) end
    else notify("Preset encode failed", 4) end
end

local function loadPreset()
    if type(readfile) ~= "function" then notify("Executor does not support readfile", 4) return end
    local path = PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset"
    local ok, decoded = pcall(function()
        local raw = readfile(path)
        return HttpService:JSONDecode(xorPreset(raw))
    end)
    if ok and applyRevertConfig(decoded) then
        if type(syncRevertControls) == "function" then syncRevertControls() end
        notify("Preset loaded: " .. cleanPresetName(presetName), 3)
    else notify("Preset not found or invalid: " .. cleanPresetName(presetName), 4) end
end

presetNames = function()
    local names = {"default"}
    if type(listfiles) == "function" then
        ensurePresetFolder()
        local folders = {PRESET_FOLDER}
        for _, folder in ipairs(folders) do
            local ok, files = pcall(listfiles, folder)
            if ok and typeof(files) == "table" then
                for _, file in ipairs(files) do
                    local normalized = tostring(file):gsub("\\", "/")
                    local name = normalized:match("([^/]+)%.preset$")
                    if name and not table.find(names, name) then names[#names + 1] = name end
                end
            end
        end
    end
    table.sort(names)
    return names
end

local tab = host.CreateTab("Noir slient aim", "/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
local main = tab:AddSection("Silent Aim", "")
main:AddToggle("Enabled", toggle)
main:AddToggle("Wall Check", function(value) config.wallCheck = value == true end)
local knifeSection = tab:AddSection("Knife Silent Aim", "")
knifeSection:AddToggle("Knife Silent Aim", function(value) config.knifeEnabled = value == true; if config.knifeEnabled then installHook() end end)
knifeSection:AddToggle("Knife Wall Check", function(value) config.knifeWallCheck = value == true end)
knifeSection:AddToggle("Prioritize Sheriff", function(value) config.knifePrioritizeSheriff = value == true end)

local visualSection = tab:AddSection("Visuals", "Outline and Box ESP")
visualSection:AddLabel("OUTLINE • BY PLAYER")
visualSection:AddToggle("Outline Everyone", function(value) config.espOutline = value == true; task.spawn(refreshTarget); refreshESP() end)
visualSection:AddToggle("Outline Murderer Only", function(value) config.espOutlineMurderer = value == true; task.spawn(refreshTarget); refreshESP() end)
visualSection:AddToggle("Outline Sheriff / Hero Only", function(value) config.espOutlineSheriff = value == true; task.spawn(refreshTarget); refreshESP() end)
visualSection:AddLabel("ESP BOX • BY PLAYER")
visualSection:AddToggle("ESP Box Everyone", function(value) config.espBox = value == true; task.spawn(refreshTarget); refreshESP() end)
visualSection:AddToggle("ESP Box Murderer Only", function(value) config.espBoxMurderer = value == true; task.spawn(refreshTarget); refreshESP() end)
visualSection:AddToggle("ESP Box Sheriff / Hero Only", function(value) config.espBoxSheriff = value == true; task.spawn(refreshTarget); refreshESP() end)


local objectVisuals = tab:AddSection("Object ESP", "Dropped items and map objects")
objectVisuals:AddLabel("OUTLINE • BY OBJECT")
objectVisuals:AddToggle("Outline Dropped Gun", function(v) config.outlineDroppedGun=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("Outline Traps", function(v) config.outlineTraps=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("Outline Throwing Knives", function(v) config.outlineThrowingKnives=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("Outline Coins", function(v) config.outlineCoins=v==true; refreshObjectESP() end)
objectVisuals:AddLabel("ESP BOX • BY OBJECT")
objectVisuals:AddToggle("ESP Box Dropped Gun", function(v) config.boxDroppedGun=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("ESP Box Traps", function(v) config.boxTraps=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("ESP Box Throwing Knives", function(v) config.boxThrowingKnives=v==true; refreshObjectESP() end)
objectVisuals:AddToggle("ESP Box Coins", function(v) config.boxCoins=v==true; refreshObjectESP() end)

local shootSection = tab:AddSection("Shoot Murderer", "Mobile shoot button")
shootSection:AddToggle("Show Shoot Murderer Button", setShootButtonVisible)
shootSection:AddToggle("Lock Shoot Murderer Button", function(value)
    config.lockShootButton = value == true
    notify(config.lockShootButton and "Shoot button locked" or "Shoot button unlocked", 2)
end)
shootSection:AddButton("Shoot Murderer Now", shootMurderer)

local revert = tab:AddSection("NOIR CONFIG", "Standalone Silent Aim settings; .preset-compatible")
presetDropdown = revert:AddDropdown("Your Presets", presetNames(), function(value) presetName = cleanPresetName(value) end)
if type(revert.AddTextBox) == "function" then
    revert:AddTextBox("Preset Name", function(value) presetName = cleanPresetName(value) end)
else
    revert:AddDropdown("Preset Name", {"default", "best", "mobile", "custom1", "custom2"}, function(value) presetName = value end)
end
revert:AddButton("Save Preset", savePreset)
revert:AddButton("Load Preset", loadPreset)
revert:AddButton("Refresh Presets", function()
    local names = presetNames()
    if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(names, table.find(names, presetName) and presetName or names[1]) end
    notify("Presets found: " .. tostring(#names - 1), 3)
end)
local function addTrackedToggle(key, label, callback)
    revertToggleStates[key] = false
    local toggle = revert:AddToggle(label, function(value)
        local state = value == true
        revertToggleStates[key] = state
        callback(state)
    end)
    revertControls[key] = toggle
end

local function addTrackedSlider(key, label, minimum, maximum, default, callback)
    local slider = revert:AddSlider(label, minimum, maximum, default, function(value)
        callback(tonumber(value) or default)
    end)
    revertControls[key] = slider
end

addTrackedToggle("prioritizePing", "Prioritize Your Ping", function(value) config.prioritizePing = value end)
addTrackedToggle("predictJump", "Predict Jump", function(value) config.predictJump = value end)
addTrackedToggle("predictLag", "Predict Lag", function(value) config.predictLag = value end)
addTrackedSlider("maxSimulationMs", "Prediction Max Simulation Time", 20, 300, 180, function(value) config.maxSimulationMs = value end)
addTrackedSlider("predictionIntervalMs", "Prediction Interval", 1, 100, 72, function(value) config.predictionIntervalMs = value end)
addTrackedSlider("manualPingMs", "Prediction Ping", 10, 350, 80, function(value) config.manualPingMs = value end)
addTrackedSlider("offsetX", "X Position Offset (%)", -100, 100, 0, function(value) config.offsetX = value end)
addTrackedSlider("offsetY", "Y Position Offset (%)", -100, 100, 0, function(value) config.offsetY = value end)
addTrackedSlider("offsetZ", "Z Position Offset (%)", -100, 100, 0, function(value) config.offsetZ = value end)
addTrackedSlider("horizontalMultiplier", "Prediction Horizontal Multiplier (%)", 0, 400, 100, function(value) config.horizontalMultiplier = value end)
addTrackedSlider("verticalMultiplier", "Prediction Vertical Multiplier (%)", 0, 400, 100, function(value) config.verticalMultiplier = value end)

syncRevertControls = function(syncToggles)
    if syncToggles ~= false then
        for _, key in ipairs({"prioritizePing", "predictJump", "predictLag"}) do
            local desired = config[key] == true
            local toggle = revertControls[key]
            if type(toggle) == "function" and revertToggleStates[key] ~= desired then
                pcall(toggle)
            end
        end
    end
    for _, key in ipairs({
        "maxSimulationMs", "predictionIntervalMs", "manualPingMs",
        "offsetX", "offsetY", "offsetZ", "horizontalMultiplier", "verticalMultiplier"
    }) do
        local control = revertControls[key]
        if type(control) == "table" and type(control.SetValue) == "function" then
            pcall(control.SetValue, control, config[key])
        elseif type(control) == "function" then
            pcall(control, config[key])
        end
    end
end



notify("Lite V3 ready; feature is OFF", 4)
