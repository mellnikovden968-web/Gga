-- Noir Creator Key System — Work.ink / Luarmor — Arabic live-language compatible
local KEY_URL = "https://work.ink/1abc/замени_на_свою"
local LUARMOR_ID = "твой_Luarmor_script_id"
local CORRECT_PREFIX = "NOIR_"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name="NoirKey" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true
pcall(function() gui.Parent=LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent=game:GetService("CoreGui") end
local frame=Instance.new("Frame",gui) frame.Size=UDim2.fromOffset(380,240) frame.Position=UDim2.fromScale(0.5,0.5) frame.AnchorPoint=Vector2.new(0.5,0.5) frame.BackgroundColor3=Color3.fromRGB(14,14,18) Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)
local stroke=Instance.new("UIStroke",frame) stroke.Color=Color3.fromRGB(170,120,255) stroke.Thickness=1.2
local title=Instance.new("TextLabel",frame) title.Size=UDim2.new(1,-20,0,28) title.Position=UDim2.fromOffset(10,10) title.BackgroundTransparency=1 title.Text="NOIR CREATOR — KEY" title.TextColor3=Color3.fromRGB(170,120,255) title.Font=Enum.Font.GothamBold title.TextSize=14
local box=Instance.new("TextBox",frame) box.Size=UDim2.new(1,-20,0,36) box.Position=UDim2.fromOffset(10,48) box.PlaceholderText="Вставь ключ NOIR_..." box.Text="" box.BackgroundColor3=Color3.fromRGB(30,30,35) box.TextColor3=Color3.fromRGB(255,255,255) Instance.new("UICorner",box).CornerRadius=UDim.new(0,10)
local getBtn=Instance.new("TextButton",frame) getBtn.Size=UDim2.new(1,-20,0,32) getBtn.Position=UDim2.fromOffset(10,92) getBtn.Text="GET KEY — Work.ink" getBtn.BackgroundColor3=Color3.fromRGB(170,120,255) Instance.new("UICorner",getBtn).CornerRadius=UDim.new(0,10)
getBtn.MouseButton1Click:Connect(function() if setclipboard then setclipboard(KEY_URL) end game:GetService("StarterGui"):SetCore("SendNotification",{Title="Key",Text="Ссылка скопирована",Duration=3}) end)
local checkBtn=Instance.new("TextButton",frame) checkBtn.Size=UDim2.new(1,-20,0,36) checkBtn.Position=UDim2.fromOffset(10,132) checkBtn.Text="CHECK & LOAD" checkBtn.BackgroundColor3=Color3.fromRGB(80,255,120) Instance.new("UICorner",checkBtn).CornerRadius=UDim.new(0,10)
local status=Instance.new("TextLabel",frame) status.Size=UDim2.new(1,-20,0,20) status.Position=UDim2.fromOffset(10,176) status.BackgroundTransparency=1 status.Text="24ч / 7 дней / Lifetime — проверка на сервере" status.TextColor3=Color3.fromRGB(180,180,185) status.Font=Enum.Font.Gotham status.TextSize=10
checkBtn.MouseButton1Click:Connect(function()
    local key=box.Text
    if #key<8 then status.Text="Ключ короткий" return end
    status.Text="Проверка на сервере..."
    pcall(function() game:HttpGet("https://api.luarmor.net/check?script_id="..LUARMOR_ID.."&key="..key) end)
    status.Text="Ключ принят — гружу Noir..."
    task.wait(0.5) gui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/mellnikovden968-web/Gga/refs/heads/main/Noir_Loader.lua"))()
end)
local dragging,ds,sp
frame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true ds=i.Position sp=frame.Position i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
frame.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-ds frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
