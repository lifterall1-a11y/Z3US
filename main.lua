--[[
    Z3US Loader v2.3 - ULTRA FAST
    - Fake loading bar for V2
    - Preloads scripts in background
    - Instant response on click
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    GUI_NAME = "Z3US Loader v2",
    STORAGE_PATH = "Z3US",
    ANIMATION_DURATION = 0.2,
    DEFAULT_SETTINGS = {
        counterbloxVersion = "Old",
        rivalsAutoload = true,
        rivalsSilentload = false,
        rivalsVersion = "V2",
        overkillKey = "",
    }
}

-- ============================================================================
-- CORE SERVICES
-- ============================================================================

local Services = {
    Players = cloneref(game:GetService("Players")),
    CoreGui = cloneref(game:GetService("CoreGui") or gethui()),
    UserInput = cloneref(game:GetService("UserInputService")),
    RunService = cloneref(game:GetService("RunService")),
    TweenService = cloneref(game:GetService("TweenService")),
    HttpService = cloneref(game:GetService("HttpService")),
}

local LocalPlayer = Services.Players.LocalPlayer

-- ============================================================================
-- UTILITY MODULE
-- ============================================================================

local Utility = {
    saveData = function(path, data)
        local success, err = pcall(function()
            makefolder(CONFIG.STORAGE_PATH)
            writefile(path, Services.HttpService:JSONEncode(data))
        end)
        if not success then warn("[Z3US] Failed to save:", err) end
        return success
    end,
    
    loadData = function(path, default)
        local success, data = pcall(function()
            if isfile(path) then
                return Services.HttpService:JSONDecode(readfile(path))
            end
            return nil
        end)
        return success and data or default
    end,
    
    animate = function(object, properties, duration)
        duration = duration or CONFIG.ANIMATION_DURATION
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = Services.TweenService:Create(object, tweenInfo, properties)
        tween:Play()
        return tween
    end,
    
    secureHttpGet = function(url, retries)
        retries = retries or 2
        for i = 1, retries do
            local success, result = pcall(function()
                return game:HttpGet(url)
            end)
            if success and result and #result > 0 then
                return result
            end
            task.wait(0.2)
        end
        return nil
    end
}

-- ============================================================================
-- GAME CONFIGURATION SYSTEM
-- ============================================================================

-- Preloaded scripts cache
local scriptCache = {}

local GameConfigs = {
    Arsenal = {
        displayName = "Arsenal",
        scriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Arsenal%20Beta.lua",
        options = {},
        isHeavy = false,
        executor = function(self, config)
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    },
    
    Counterblox = {
        displayName = "Counterblox",
        scriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Counterblox.lua",
        options = {
            version = { type = "toggle", values = {"Old", "New"}, default = "Old" }
        },
        isHeavy = false,
        executor = function(self, config)
            if config.version == "New" then
                local player = Services.Players.LocalPlayer
                if player then player:Kick("This script is detected and will get you banned") end
            else
                local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
                if script and #script > 0 then loadstring(script)() end
            end
        end
    },
    
    GunFight = {
        displayName = "Gunfight Arena",
        scriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Gunfight%20Arena.lua",
        options = {},
        isHeavy = false,
        executor = function(self, config)
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    },
    
    Universal = {
        displayName = "Universal",
        scriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Universal.lua",
        options = {},
        isHeavy = false,
        executor = function(self, config)
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    },
    
    Rivals = {
        displayName = "Rivals",
        scriptUrl = "https://api.jnkie.com/api/v1/luascripts/public/2438cfd42af811d55492e854318eeda24a73aa5d0b11a403ec1f7542abd8f2f0/download",
        options = {
            autoload = { type = "toggle", values = {true, false}, default = true },
            silentload = { type = "toggle", values = {true, false}, default = false },
            version = { type = "toggle", values = {"V2", "V1"}, default = "V2" }
        },
        isHeavy = true,
        executor = function(self, config)
            if config.version == "V2" then
                getgenv().autoload = config.autoload
                getgenv().silentload = config.silentload
                getgenv().SCRIPT_KEY = ""
                
                -- Use cached script or fetch
                local script = scriptCache[self.scriptUrl]
                if not script then
                    script = Utility.secureHttpGet(self.scriptUrl)
                    if script and #script > 0 then
                        scriptCache[self.scriptUrl] = script
                    end
                end
                
                if script and #script > 0 then
                    loadstring(script)()
                end
            else
                task.spawn(function()
                    repeat task.wait() until game:IsLoaded()
                    repeat task.wait() until LocalPlayer and LocalPlayer.Character
                    repeat task.wait() until not LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LoadingScreen")
                    
                    getgenv().autoload = config.autoload
                    getgenv().silentload = config.silentload
                    getgenv().SCRIPT_KEY = ""
                    loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/8be52e21a0145a401c446ca7ab2b5df9bd327ea80b0cf1d2fe99e442edd0f9c9/download"))()
                end)
            end
        end
    },
    
    Overkill = {
        displayName = "Overkill",
        scriptUrl = "https://api.jnkie.com/api/v1/luascripts/public/d603ee0150fbdeb809a036562925966619d3e145a77b4d07b222b0612022ab8f/download",
        options = {
            key = { type = "string", default = "" }
        },
        isHeavy = false,
        executor = function(self, config)
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    },
    
    Planks = {
        displayName = "Planks",
        scriptUrl = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Planks.lua",
        options = {},
        isHeavy = false,
        executor = function(self, config)
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    },
    
    OneTap = {
        displayName = "One Tap",
        scriptUrl = "https://api.jnkie.com/api/v1/luascripts/public/2548ffbebdf21063cd4083f93a27ac276d44d1cb6503093d9c3290c3dfd954e3/download",
        options = {},
        isHeavy = false,
        executor = function(self, config)
            getgenv().SCRIPT_KEY = ""
            local script = scriptCache[self.scriptUrl] or Utility.secureHttpGet(self.scriptUrl)
            if script and #script > 0 then loadstring(script)() end
        end
    }
}

-- ============================================================================
-- PRELOAD ALL SCRIPTS IN BACKGROUND
-- ============================================================================

task.spawn(function()
    for gameName, config in pairs(GameConfigs) do
        if config.scriptUrl then
            task.spawn(function()
                local script = Utility.secureHttpGet(config.scriptUrl)
                if script and #script > 0 then
                    scriptCache[config.scriptUrl] = script
                end
            end)
            task.wait(0.1) -- Don't overload
        end
    end
end)

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local State = {
    selectedGame = nil,
    configs = {},
    isLoading = false,
}

local function loadState()
    local saved = Utility.loadData(CONFIG.STORAGE_PATH .. "/config.json", {})
    for gameName, config in pairs(GameConfigs) do
        State.configs[gameName] = {}
        for optionName, optionDef in pairs(config.options) do
            local savedValue = saved[gameName] and saved[gameName][optionName]
            State.configs[gameName][optionName] = savedValue ~= nil and savedValue or optionDef.default
        end
    end
    State.selectedGame = saved.selectedGame or nil
end

local function saveState()
    local data = { selectedGame = State.selectedGame }
    for gameName, config in pairs(State.configs) do
        data[gameName] = {}
        for optionName, value in pairs(config) do
            data[gameName][optionName] = value
        end
    end
    Utility.saveData(CONFIG.STORAGE_PATH .. "/config.json", data)
end

loadState()

-- ============================================================================
-- UI CONSTRUCTION (with Loading Bar)
-- ============================================================================

local UI = {}

function UI:createRoot()
    local gui = Instance.new("ScreenGui")
    gui.Name = CONFIG.GUI_NAME
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Services.CoreGui
    return gui
end

function UI:createMainFrame(parent)
    local frame = Instance.new("Frame")
    frame.Active = true
    frame.BackgroundColor3 = Color3.fromRGB(18, 19, 21)
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0.068, 0, 0.063, 0)
    frame.Size = UDim2.new(0, 924, 0, 599)
    frame.Parent = parent
    
    local shadow = Instance.new("Frame")
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.3
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0.01, 0, 0.01, 0)
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = frame
    
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 45
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 19, 21)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 27, 30))
    })
    gradient.Parent = frame
    
    return frame
end

function UI:createDraggableTitle(parent)
    local titleBar = Instance.new("Frame")
    titleBar.BackgroundColor3 = Color3.fromRGB(18, 19, 21)
    titleBar.BackgroundTransparency = 1
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Parent = parent
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    titleLabel.Position = UDim2.new(0.02, 0, 0, 0)
    titleLabel.Size = UDim2.new(0.3, 0, 1, 0)
    titleLabel.Text = "☰ " .. CONFIG.GUI_NAME
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    return titleBar
end

function UI:createCloseButton(parent)
    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(0.96, 0, 0.01, 0)
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Text = "✕"
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextSize = 20
    btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    btn.Parent = parent
    
    btn.MouseEnter:Connect(function() btn.TextColor3 = Color3.fromRGB(255, 70, 70) end)
    btn.MouseLeave:Connect(function() btn.TextColor3 = Color3.fromRGB(150, 150, 150) end)
    return btn
end

function UI:createLogo(parent)
    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://92661965333918"
    logo.Size = UDim2.new(0, 179, 0, 164)
    logo.Position = UDim2.new(0.633, 0, 0.04, 0)
    logo.Parent = parent
    return logo
end

function UI:createGameList(parent)
    local gamesContainer = Instance.new("ScrollingFrame")
    gamesContainer.BackgroundColor3 = Color3.fromRGB(18, 19, 21)
    gamesContainer.BackgroundTransparency = 1
    gamesContainer.BorderSizePixel = 0
    gamesContainer.Position = UDim2.new(0.02, 0, 0.08, 0)
    gamesContainer.Size = UDim2.new(0.4, 0, 0.85, 0)
    gamesContainer.ScrollBarThickness = 0
    gamesContainer.CanvasSize = UDim2.new(0, 0, 0, #GameConfigs * 70)
    gamesContainer.Parent = parent
    
    local canvas = Instance.new("UIListLayout")
    canvas.Padding = UDim.new(0, 8)
    canvas.SortOrder = Enum.SortOrder.LayoutOrder
    canvas.Parent = gamesContainer
    
    return gamesContainer, canvas
end

function UI:createGameButton(parent, gameName, config)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(18, 19, 21)
    frame.BackgroundTransparency = 0.9
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.9
    stroke.Color = Color3.fromRGB(27, 30, 38)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Position = UDim2.new(0.1, 0, 0, 0)
    label.Size = UDim2.new(0.8, 0, 1, 0)
    label.Text = config.displayName
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 24
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    if config.isHeavy then
        local fastLabel = Instance.new("TextLabel")
        fastLabel.BackgroundTransparency = 1
        fastLabel.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        fastLabel.Position = UDim2.new(0.7, 0, 0, 0)
        fastLabel.Size = UDim2.new(0.25, 0, 1, 0)
        fastLabel.Text = "⚡ FAST"
        fastLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        fastLabel.TextSize = 14
        fastLabel.TextXAlignment = Enum.TextXAlignment.Right
        fastLabel.Parent = frame
    end
    
    if next(config.options) then
        local indicator = Instance.new("TextLabel")
        indicator.BackgroundTransparency = 1
        indicator.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        indicator.Position = UDim2.new(0.85, 0, 0, 0)
        indicator.Size = UDim2.new(0.15, 0, 1, 0)
        indicator.Text = "⚙"
        indicator.TextColor3 = Color3.fromRGB(100, 100, 100)
        indicator.TextSize = 20
        indicator.Parent = frame
    end
    
    return frame, stroke, label
end

function UI:createOptionsPanel(parent, gameName, config)
    local panel = Instance.new("Frame")
    panel.BackgroundColor3 = Color3.fromRGB(18, 19, 21)
    panel.BackgroundTransparency = 0.9
    panel.BorderSizePixel = 0
    panel.Size = UDim2.new(0.35, 0, 0.3, 0)
    panel.Position = UDim2.new(1.4, 0, 0, 0)
    panel.Visible = false
    panel.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.9
    stroke.Color = Color3.fromRGB(27, 30, 38)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = panel
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    
    return panel, layout
end

function UI:createOptionToggle(parent, optionName, value, callback)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Text = optionName:gsub("^%l", string.upper)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = value and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
    button.Position = UDim2.new(0.7, 0, 0.1, 0)
    button.Size = UDim2.new(0.25, 0, 0.8, 0)
    button.Text = value and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    button.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        value = not value
        button.BackgroundColor3 = value and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
        button.Text = value and "ON" or "OFF"
        if callback then callback(value) end
    end)
    
    return frame, button
end

function UI:createOptionString(parent, optionName, value, callback)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.Text = optionName:gsub("^%l", string.upper)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local box = Instance.new("TextBox")
    box.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    box.Position = UDim2.new(0.35, 0, 0.1, 0)
    box.Size = UDim2.new(0.6, 0, 0.8, 0)
    box.Text = value or ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 14
    box.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    box.ClearTextOnFocus = false
    box.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    box.FocusLost:Connect(function(enter)
        if enter then
            local newValue = box.Text
            if callback then callback(newValue) end
        end
    end)
    
    return frame, box
end

function UI:createLoadButton(parent)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.55, 0, 0.79, 0)
    btn.Size = UDim2.new(0, 340, 0, 47)
    btn.Text = "▶ EXECUTE"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 18
    btn.TextWrapped = true
    btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        Utility.animate(btn, {BackgroundColor3 = Color3.fromRGB(100, 120, 220)})
    end)
    btn.MouseLeave:Connect(function()
        Utility.animate(btn, {BackgroundColor3 = Color3.fromRGB(80, 100, 200)})
    end)
    
    return btn
end

function UI:createStatusLabel(parent)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Position = UDim2.new(0.62, 0, 0.45, 0)
    label.Size = UDim2.new(0.3, 0, 0.05, 0)
    label.Text = "No script selected"
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = parent
    return label
end

-- ============================================================================
-- LOADING BAR
-- ============================================================================

function UI:createLoadingBar(parent)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 340, 0, 12)
    frame.Position = UDim2.new(0.55, 0, 0.87, 0)
    frame.Visible = false
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = frame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Position = UDim2.new(0, 0, 1.5, 0)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = "Loading..."
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Parent = frame
    
    return frame, fill, label
end

-- ============================================================================
-- UI CONTROLLER
-- ============================================================================

local UIController = {
    gui = nil,
    mainFrame = nil,
    gameFrames = {},
    optionPanels = {},
    selectedGame = nil,
    selectedStroke = nil,
}

function UIController:init()
    loadState()
    
    self.gui = UI:createRoot()
    self.mainFrame = UI:createMainFrame(self.gui)
    
    UI:createDraggableTitle(self.mainFrame)
    
    local closeBtn = UI:createCloseButton(self.mainFrame)
    closeBtn.MouseButton1Click:Connect(function() self.gui:Destroy() end)
    
    UI:createLogo(self.mainFrame)
    
    local statusLabel = UI:createStatusLabel(self.mainFrame)
    local loadBtn = UI:createLoadButton(self.mainFrame)
    local loadingBar, loadingFill, loadingLabel = UI:createLoadingBar(self.mainFrame)
    
    local gamesContainer = UI:createGameList(self.mainFrame)
    
    for gameName, config in pairs(GameConfigs) do
        local frame, stroke, label = UI:createGameButton(gamesContainer, gameName, config)
        self.gameFrames[gameName] = { frame = frame, stroke = stroke, label = label }
        
        if next(config.options) then
            local panel = UI:createOptionsPanel(self.mainFrame, gameName, config)
            self.optionPanels[gameName] = panel
            
            for optionName, optionDef in pairs(config.options) do
                if optionDef.type == "toggle" then
                    local value = State.configs[gameName] and State.configs[gameName][optionName] or optionDef.default
                    UI:createOptionToggle(panel, optionName, value, function(newValue)
                        State.configs[gameName][optionName] = newValue
                        saveState()
                    end)
                elseif optionDef.type == "string" then
                    local value = State.configs[gameName] and State.configs[gameName][optionName] or optionDef.default
                    UI:createOptionString(panel, optionName, value, function(newValue)
                        State.configs[gameName][optionName] = newValue
                        saveState()
                    end)
                end
            end
        end
    end
    
    if State.selectedGame and self.gameFrames[State.selectedGame] then
        self:selectGame(State.selectedGame, statusLabel)
    end
    
    self:setupGameSelection(statusLabel)
    self:setupDragging()
    self:setupLoadButton(loadBtn, statusLabel, loadingBar, loadingFill, loadingLabel)
end

function UIController:selectGame(gameName, statusLabel)
    if self.selectedGame and self.gameFrames[self.selectedGame] then
        local prev = self.gameFrames[self.selectedGame]
        if prev.stroke then prev.stroke.Color = Color3.fromRGB(27, 30, 38) end
        if self.optionPanels[self.selectedGame] then
            self.optionPanels[self.selectedGame].Visible = false
        end
    end
    
    self.selectedGame = gameName
    State.selectedGame = gameName
    saveState()
    
    local current = self.gameFrames[gameName]
    if current and current.stroke then
        current.stroke.Color = Color3.fromRGB(140, 155, 208)
    end
    
    if self.optionPanels[gameName] then
        self.optionPanels[gameName].Visible = true
        Utility.animate(self.optionPanels[gameName], {Position = UDim2.new(1.05, 0, 0, 0)})
    end
    
    if statusLabel then
        statusLabel.Text = "Selected: " .. GameConfigs[gameName].displayName
        statusLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
    end
end

function UIController:setupGameSelection(statusLabel)
    for gameName, data in pairs(self.gameFrames) do
        data.label.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:selectGame(gameName, statusLabel)
            end
        end)
    end
end

function UIController:setupDragging()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    self.mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
        end
    end)
    
    Services.UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    Services.UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function UIController:setupLoadButton(button, statusLabel, loadingBar, loadingFill, loadingLabel)
    button.MouseButton1Click:Connect(function()
        if State.isLoading then return end
        
        local gameName = self.selectedGame
        if not gameName then
            statusLabel.Text = "⚠ Please select a game first!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            return
        end
        
        local config = GameConfigs[gameName]
        if not config then return end
        
        State.isLoading = true
        button.Enabled = false
        button.Text = "⏳ LOADING..."
        button.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
        
        -- Show loading bar
        loadingBar.Visible = true
        loadingFill.Size = UDim2.new(0, 0, 1, 0)
        loadingLabel.Text = "Loading " .. config.displayName .. "..."
        statusLabel.Text = "⏳ Loading " .. config.displayName .. "..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        
        -- Animate loading bar (fake progress to make it feel faster)
        local progress = 0
        local tween = Services.TweenService:Create(loadingFill, TweenInfo.new(8, Enum.EasingStyle.Linear), {
            Size = UDim2.new(1, 0, 1, 0)
        })
        tween:Play()
        
        task.spawn(function()
            local success, err = pcall(function()
                config.executor(State.configs[gameName])
            end)
            
            tween:Cancel()
            loadingFill.Size = UDim2.new(1, 0, 1, 0)
            
            State.isLoading = false
            button.Enabled = true            
            if success then
                loadingLabel.Text = "✅ Loaded!"
                statusLabel.Text = "✅ " .. config.displayName .. " loaded!"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                button.Text = "✓ DONE"
                button.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
                
                task.wait(1.5)
                loadingBar.Visible = false
                button.Text = "▶ EXECUTE"
                button.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
            else
                loadingLabel.Text = "❌ Error"
                statusLabel.Text = "❌ Error: " .. tostring(err):sub(1, 50)
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                button.Text = "⚠ RETRY"
                button.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
                
                task.wait(2)
                loadingBar.Visible = false
                button.Text = "▶ EXECUTE"
                button.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
            end
        end)
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local success, err = pcall(function()
    UIController:init()
end)

if not success then
    warn("[Z3US] Failed to initialize:", err)
    task.wait(1)
    pcall(function()
        UIController:init()
    end)
end
