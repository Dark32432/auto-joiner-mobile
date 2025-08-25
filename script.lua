-- AutoJoiner v1 | GUI premium | Feito por Dark

-- ===== Serviços =====
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== Configurações =====
local API_URL = "https://auto-joiner-api.squareweb.app/get_clipboard"
local PLACE_ID = 109983668079237
local USED_JOBIDS_FILE = "used_jobids.json"
local POLL_INTERVAL = 0.1
local KEY_VALUE = "AutoJoinerMobileV1"

-- ===== Estado =====
local autoJoinEnabled = false
local usedJobIds = {}

-- ===== Funções de Persistência =====
pcall(function()
    if isfile and isfile(USED_JOBIDS_FILE) then
        local content = readfile(USED_JOBIDS_FILE)
        usedJobIds = HttpService:JSONDecode(content)
    end
end)

local function saveUsedJobIds()
    pcall(function()
        if writefile then
            writefile(USED_JOBIDS_FILE, HttpService:JSONEncode(usedJobIds))
        end
    end)
end

-- ===== Função de fetch =====
local function getLatestJobId()
    local success, result = pcall(function()
        return game:HttpGet(API_URL)
    end)
    if success and result then
        local jobId = tostring(result):gsub("%s+", "")
        if jobId ~= "" and not usedJobIds[jobId] then
            return jobId
        end
    end
    return nil
end

-- ===== Helpers de GUI =====
local function makeMovable(frame)
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function roundedFrame(parent, size, pos, color, radius)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or Color3.fromRGB(28,28,32)
    f.BorderSizePixel = 0
    f.Parent = parent
    local c = Instance.new("UICorner", f)
    c.CornerRadius = UDim.new(0, radius or 16)
    -- sombra suave
    local shadow = Instance.new("UIStroke", f)
    shadow.Thickness = 2
    shadow.Color = Color3.fromRGB(15,15,15)
    shadow.Transparency = 0.5
    return f
end

local function label(parent, size, pos, text, sizeText, bold, color)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = sizeText or 14
    l.Text = text or ""
    l.TextColor3 = color or Color3.fromRGB(235,235,235)
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local function button(parent, size, pos, text, bgColor)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bgColor or Color3.fromRGB(36,36,42)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.BorderSizePixel = 0
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
    -- hover animado
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = b.BackgroundColor3 + Color3.fromRGB(20,20,20)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = bgColor}):Play()
    end)
    return b
end

local function textbox(parent, size, pos, placeholder)
    local tb = Instance.new("TextBox")
    tb.Size = size
    tb.Position = pos
    tb.BackgroundColor3 = Color3.fromRGB(28,28,32)
    tb.BorderSizePixel = 0
    tb.PlaceholderText = placeholder or ""
    tb.Text = ""
    tb.TextColor3 = Color3.fromRGB(230,230,230)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 15
    tb.ClearTextOnFocus = false
    tb.Parent = parent
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,12)
    tb.Focused:Connect(function()
        TweenService:Create(tb, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,50)}):Play()
    end)
    tb.FocusLost:Connect(function()
        TweenService:Create(tb, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28,28,32)}):Play()
    end)
    return tb
end

-- ===== GUI de Key =====
local function createKeyGUI(onSuccess)
    if PlayerGui:FindFirstChild("KeyGUI") then PlayerGui.KeyGUI:Destroy() end
    local screen = Instance.new("ScreenGui", PlayerGui)
    screen.Name = "KeyGUI"
    screen.ResetOnSpawn = false

    local card = roundedFrame(screen, UDim2.new(0, 380, 0, 180), UDim2.new(0.5, -190, 0.4, -90), Color3.fromRGB(20,20,25))
    makeMovable(card)

    label(card, UDim2.new(1,-24,0,32), UDim2.new(0,12,0,8), "🔑 Coloque a Key abaixo", 16, true)
    local box = textbox(card, UDim2.new(1,-24,0,42), UDim2.new(0,12,0,50), "Coloque a key aqui...")
    local btn = button(card, UDim2.new(0.36,0,0,40), UDim2.new(0.5, -0.18*380, 1, -50), "Desbloquear", Color3.fromRGB(45,160,255))
    local feedback = label(card, UDim2.new(1,-24,0,20), UDim2.new(0,12,1,-28), "", 14, false, Color3.fromRGB(220,80,80))

    local function showError(msg)
        feedback.Text = msg
        TweenService:Create(card, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 3, true),
            {Position = card.Position + UDim2.new(0,6,0,0)}):Play()
        delay(0.22, function() feedback.Text = "" end)
    end

    local function tryUnlock()
        if tostring(box.Text) == KEY_VALUE then
            screen:Destroy()
            onSuccess()
        else
            showError("Key incorreta")
        end
    end

    btn.MouseButton1Click:Connect(tryUnlock)
    box.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)
end

-- ===== GUI AutoJoin =====
local function createAutoJoinGUI()
    if PlayerGui:FindFirstChild("AutoJoinGUI") then PlayerGui.AutoJoinGUI:Destroy() end
    local screen = Instance.new("ScreenGui", PlayerGui)
    screen.Name = "AutoJoinGUI"
    screen.ResetOnSpawn = false

    local main = roundedFrame(screen, UDim2.new(0, 300, 0, 180), UDim2.new(0.5, -150, 0.2, 0), Color3.fromRGB(25,25,30))
    makeMovable(main)

    local title = label(main, UDim2.new(1,0,0,36), UDim2.new(0,12,0,8), "AutoJoiner v1", 20, true)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local statusLabel = label(main, UDim2.new(1,0,0,20), UDim2.new(0,12,0,48), "Status: OFF", 14, false, Color3.fromRGB(200,80,80))
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = button(main, UDim2.new(0, 140, 0, 44), UDim2.new(0.5, -70, 0.7, -22), "Ligar AutoJoin", Color3.fromRGB(160,60,60))

    toggleBtn.MouseButton1Click:Connect(function()
        autoJoinEnabled = not autoJoinEnabled
        if autoJoinEnabled then
            toggleBtn.Text = "Desligar AutoJoin"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
            statusLabel.Text = "Status: ON"
            statusLabel.TextColor3 = Color3.fromRGB(120,240,120)
        else
            toggleBtn.Text = "Ligar AutoJoin"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(160,60,60)
            statusLabel.Text = "Status: OFF"
            statusLabel.TextColor3 = Color3.fromRGB(200,80,80)
        end
    end)

    -- Créditos
    local credit = label(main, UDim2.new(1,0,0,18), UDim2.new(0,12,1,-26), "Made By: Dark", 13, false, Color3.fromRGB(180,180,180))
    credit.TextXAlignment = Enum.TextXAlignment.Left
end

-- ===== Inicia sequence =====
createKeyGUI(function()
    createAutoJoinGUI()
end)

-- ===== Loop AutoJoin =====
spawn(function()
    while true do
        if autoJoinEnabled then
            local jobId = getLatestJobId()
            if jobId then
                usedJobIds[jobId] = true
                saveUsedJobIds()
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LocalPlayer)
                end)
            end
        end
        task.wait(POLL_INTERVAL)
    end
end)
