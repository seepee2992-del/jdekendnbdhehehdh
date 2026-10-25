-- ============================================================
-- BLACKBOX RESEARCH PROJECT - CLIENT SCRIPT
-- ESP / AIMBOT / SPINBOT / BHOP / MULTI-LANG MENU
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- LANGUAGE TABLE
-- ============================================================
local Lang = {
    ru = {
        title = "BLACKBOX",
        esp = "ESP СКВОЗЬ СТЕНЫ",
        aim = "АИМБОТ",
        aim_third = "От 3-го лица (мышь)",
        aim_first = "От 1-го лица (камера)",
        aim_fov = "Радиус FOV",
        aim_smooth = "Плавность",
        spin = "СПИНБОТ (HvH)",
        bhop = "BUNNY HOP",
        close = "ЗАКРЫТЬ",
        lang_label = "ЯЗЫК",
    },
    en = {
        title = "BLACKBOX",
        esp = "ESP WALLHACK",
        aim = "AIMBOT",
        aim_third = "Third Person (Mouse)",
        aim_first = "First Person (Camera)",
        aim_fov = "FOV Radius",
        aim_smooth = "Smoothness",
        spin = "SPINBOT (HvH)",
        bhop = "BUNNY HOP",
        close = "CLOSE",
        lang_label = "LANGUAGE",
    },
    uk = {
        title = "BLACKBOX",
        esp = "ESP КРІЗЬ СТІНИ",
        aim = "АІМБОТ",
        aim_third = "Від 3-ї особи (миша)",
        aim_first = "Від 1-ї особи (камера)",
        aim_fov = "Радіус FOV",
        aim_smooth = "Плавність",
        spin = "СПІНБОТ (HvH)",
        bhop = "BUNNY HOP",
        close = "ЗАКРИТИ",
        lang_label = "МОВА",
    },
    zh = {
        title = "BLACKBOX",
        esp = "ESP 透视",
        aim = "自瞄",
        aim_third = "第三人称 (鼠标)",
        aim_first = "第一人称 (相机)",
        aim_fov = "FOV 半径",
        aim_smooth = "平滑度",
        spin = "旋转机器人 (HvH)",
        bhop = "兔子跳",
        close = "关闭",
        lang_label = "语言",
    },
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    esp = false,
    aimThird = false,
    aimFirst = false,
    spin = false,
    bhop = false,
    aimFov = 120,
    aimSmooth = 0.15,
    currentLang = "ru",
    menuOpen = false,
}

-- ============================================================
-- ESP IMPLEMENTATION
-- ============================================================
local espConnections = {}

local function createESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = char:FindFirstChild("BlackboxESP")
    if old then old:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name = "BlackboxESP"
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.fromRGB(0, 255, 70)
    hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(0, 255, 70)
    hl.OutlineTransparency = 0
    hl.Parent = char

    local conn = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent then
            hl:Destroy()
            if conn then conn:Disconnect() end
            return
        end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            hl.Enabled = false
        else
            hl.Enabled = State.esp
        end
    end)
    table.insert(espConnections, conn)
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.esp then
            createESP(player)
        end
    end)
    if player.Character then
        createESP(player)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)

-- ============================================================
-- AIMBOT IMPLEMENTATION
-- ============================================================
local function getClosestTarget()
    local closest = nil
    local closestDist = State.aimFov
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local refPoint = mousePos

    if State.aimFirst then
        refPoint = center
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local sp = Vector2.new(screenPos.X, screenPos.Y)
        local dist = (sp - refPoint).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = targetPart
        end
    end
    return closest
end

-- Third person aimbot: mouse movement via mousemoverel
local function doThirdPersonAim()
    if not State.aimThird then return end
    local target = getClosestTarget()
    if not target then return end

    local screenPos = Camera:WorldToViewportPoint(target.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local deltaX = screenPos.X - mousePos.X
    local deltaY = screenPos.Y - mousePos.Y

    if mousemoverel then
        mousemoverel(deltaX * State.aimSmooth, deltaY * State.aimSmooth)
    end
end

-- First person aimbot: camera CFrame lerp
local function doFirstPersonAim()
    if not State.aimFirst then return end
    local target = getClosestTarget()
    if not target then return end

    local lookAt = CFrame.new(Camera.CFrame.Position, target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(lookAt, State.aimSmooth)
end

RunService.RenderStepped:Connect(function()
    doThirdPersonAim()
    doFirstPersonAim()
end)

-- ============================================================
-- SPINBOT (HvH) & BUNNY HOP
-- ============================================================
local spinAngle = 0

RunService.RenderStepped:Connect(function(dt)
    if not State.spin then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    spinAngle = spinAngle + dt * 25
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
end)

RunService.Heartbeat:Connect(function()
    if not State.bhop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid.Jump = true
    end
end)

-- ============================================================
-- UI CREATION
-- ============================================================
local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BlackboxMenu"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 520, 0, 400)
    main.Position = UDim2.new(0.5, -260, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Visible = false
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 70)
    stroke.Thickness = 2
    stroke.Parent = main

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(5, 15, 5)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BLACKBOX // RESEARCH PROJECT"
    title.TextColor3 = Color3.fromRGB(0, 255, 70)
    title.TextSize = 18
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 60, 0, 30)
    closeBtn.Position = UDim2.new(1, -70, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(0, 255, 70)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.Code
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn

    -- Language selection panel (initial)
    local langPanel = Instance.new("Frame")
    langPanel.Size = UDim2.new(1, -40, 0, 200)
    langPanel.Position = UDim2.new(0, 20, 0, 100)
    langPanel.BackgroundTransparency = 1
    langPanel.Parent = main

    local langTitle = Instance.new("TextLabel")
    langTitle.Size = UDim2.new(1, 0, 0, 30)
    langTitle.BackgroundTransparency = 1
    langTitle.Text = "SELECT LANGUAGE / ВЫБЕРИТЕ ЯЗЫК"
    langTitle.TextColor3 = Color3.fromRGB(0, 255, 70)
    langTitle.TextSize = 16
    langTitle.Font = Enum.Font.Code
    langTitle.Parent = langPanel

    local langButtons = {}
    local langs = {
        { code = "ru", label = "РУССКИЙ" },
        { code = "en", label = "ENGLISH" },
        { code = "uk", label = "УКРАЇНСЬКА" },
        { code = "zh", label = "中文" },
    }

    for i, l in ipairs(langs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 220, 0, 35)
        btn.Position = UDim2.new(0, 0, 0, 40 + (i - 1) * 45)
        btn.BackgroundColor3 = Color3.fromRGB(10, 25, 10)
        btn.Text = l.label
        btn.TextColor3 = Color3.fromRGB(0, 255, 70)
        btn.TextSize = 14
        btn.Font = Enum.Font.Code
        btn.Parent = langPanel

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn

        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(0, 180, 50)
        s.Parent = btn

        btn.MouseButton1Click:Connect(function()
            State.currentLang = l.code
            langPanel.Visible = false
            buildContent(main)
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        State.menuOpen = false
    end)

    return gui, main
end

-- ============================================================
-- CONTENT BUILDER (after language selection)
-- ============================================================
local contentBuilt = false

function buildContent(main)
    if contentBuilt then return end
    contentBuilt = true
    local t = Lang[State.currentLang]

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -60)
    content.Position = UDim2.new(0, 20, 0, 50)
    content.BackgroundTransparency = 1
    content.Parent = main

    local y = 0

    -- Helper to create toggle row
    local function makeToggle(labelText, stateKey, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.Position = UDim2.new(0, 0, 0, y)
        row.BackgroundColor3 = Color3.fromRGB(5, 12, 5)
        row.BorderSizePixel = 0
        row.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(0, 200, 60)
        lbl.TextSize = 14
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 0, 24)
        btn.Position = UDim2.new(1, -80, 0, 4)
        btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        btn.Text = "OFF"
        btn.TextColor3 = Color3.fromRGB(100, 100, 100)
        btn.TextSize = 12
        btn.Font = Enum.Font.Code
        btn.Parent = row

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 3)
        bc.Parent = btn

        btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            btn.Text = State[stateKey] and "ON" or "OFF"
            btn.TextColor3 = State[stateKey] and Color3.fromRGB(0, 255, 70) or Color3.fromRGB(100, 100, 100)
            if callback then callback(State[stateKey]) end
        end)

        y = y + 38
    end

    -- Helper slider
    local function makeSlider(labelText, minVal, maxVal, defaultVal, stateKey, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.Position = UDim2.new(0, 0, 0, y)
        row.BackgroundColor3 = Color3.fromRGB(5, 12, 5)
        row.BorderSizePixel = 0
        row.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(0, 200, 60)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.2, 0, 1, 0)
        valLbl.Position = UDim2.new(0.5, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(defaultVal)
        valLbl.TextColor3 = Color3.fromRGB(0, 255, 70)
        valLbl.TextSize = 13
        valLbl.Font = Enum.Font.Code
        valLbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0.25, 0, 0, 4)
        bar.Position = UDim2.new(0.72, 0, 0.5, -2)
        bar.BackgroundColor3 = Color3.fromRGB(15, 30, 15)
        bar.BorderSizePixel = 0
        bar.Parent = row

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 255, 70)
        fill.BorderSizePixel = 0
        fill.Parent = bar

        -- Simple click adjustment (left/right halves)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, 0, 1, 0)
        btn.Position = UDim2.new(0.72, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = row

        btn.MouseButton1Click:Connect(function()
            local newVal = State[stateKey] + (maxVal - minVal) * 0.1
            if newVal > maxVal then newVal = minVal end
            State[stateKey] = newVal
            valLbl.Text = tostring(math.floor(newVal))
            fill.Size = UDim2.new((newVal - minVal) / (maxVal - minVal), 0, 1, 0)
            if callback then callback(newVal) end
        end)

        y = y + 45
    end

    -- Populate content
    makeToggle(t.esp, "esp", function(v)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if v then
                    createESP(p)
                else
                    local c = p.Character
                    if c then
                        local old = c:FindFirstChild("BlackboxESP")
                        if old then old:Destroy() end
                    end
                end
            end
        end
    end)

    y = y + 10
    makeToggle(t.aim_third, "aimThird")
    makeToggle(t.aim_first, "aimFirst")
    makeSlider(t.aim_fov, 30, 300, 120, "aimFov")
    makeSlider(t.aim_smooth, 0.05, 0.5, 0.15, "aimSmooth")

    y = y + 10
    makeToggle(t.spin, "spin")
    makeToggle(t.bhop, "bhop")

    -- Language re-select button at bottom
    local langBtn = Instance.new("TextButton")
    langBtn.Size = UDim2.new(0, 120, 0, 28)
    langBtn.Position = UDim2.new(0, 0, 1, -35)
    langBtn.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
    langBtn.Text = "🌐 " .. t.lang_label
    langBtn.TextColor3 = Color3.fromRGB(0, 200, 60)
    langBtn.TextSize = 12
    langBtn.Font = Enum.Font.Code
    langBtn.Parent = content

    local lbc = Instance.new("UICorner")
    lbc.CornerRadius = UDim.new(0, 3)
    lbc.Parent = langBtn

    langBtn.MouseButton1Click:Connect(function()
        -- Destroy content and rebuild language panel
        content:Destroy()
        contentBuilt = false
        local lp = main:FindFirstChild("LangPanel")
        -- Simple approach: rebuild whole menu content
        local oldContent = main:FindFirstChild("ContentFrame")
        if oldContent then oldContent:Destroy() end
        -- Recreate language panel
        local lp2 = Instance.new("Frame")
        lp2.Name = "LangPanel"
        lp2.Size = UDim2.new(1, -40, 0, 200)
        lp2.Position = UDim2.new(0, 20, 0, 100)
        lp2.BackgroundTransparency = 1
        lp2.Parent = main

        local lt = Instance.new("TextLabel")
        lt.Size = UDim2.new(1, 0, 0, 30)
        lt.BackgroundTransparency = 1
        lt.Text = "SELECT LANGUAGE / ВЫБЕРИТЕ ЯЗЫК"
        lt.TextColor3 = Color3.fromRGB(0, 255, 70)
        lt.TextSize = 16
        lt.Font = Enum.Font.Code
        lt.Parent = lp2

        local langs2 = {
            { code = "ru", label = "РУССКИЙ" },
            { code = "en", label = "ENGLISH" },
            { code = "uk", label = "УКРАЇНСЬКА" },
            { code = "zh", label = "中文" },
        }
        for i, l in ipairs(langs2) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 220, 0, 35)
            btn.Position = UDim2.new(0, 0, 0, 40 + (i - 1) * 45)
            btn.BackgroundColor3 = Color3.fromRGB(10, 25, 10)
            btn.Text = l.label
            btn.TextColor3 = Color3.fromRGB(0, 255, 70)
            btn.TextSize = 14
            btn.Font = Enum.Font.Code
            btn.Parent = lp2

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = btn

            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(0, 180, 50)
            s.Parent = btn

            btn.MouseButton1Click:Connect(function()
                State.currentLang = l.code
                lp2:Destroy()
                contentBuilt = false
                buildContent(main)
            end)
        end
    end)
end

-- ============================================================
-- INITIALIZE MENU & INPUT
-- ============================================================
local menuGui, mainFrame = createMenu()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        State.menuOpen = not State.menuOpen
        mainFrame.Visible = State.menuOpen
    end
end)

-- Show menu on load
mainFrame.Visible = true
State.menuOpen = true
