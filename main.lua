--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                    ██████╗ ███████╗██╗   ██╗███████╗                      ║
    ║                    ╚════██╗╚══███╔╝██║   ██║╚══███╔╝                      ║
    ║                     █████╔╝  ███╔╝ ██║   ██║  ███╔╝                       ║
    ║                    ██╔═══╝  ███╔╝  ██║   ██║ ███╔╝                        ║
    ║                    ███████╗███████╗╚██████╔╝███████╗                      ║
    ║                    ╚══════╝╚══════╝ ╚═════╝ ╚══════╝                      ║
    ║                                                                            ║
    ║                      ULTIMATE LOADER v4.0 PREMIUM                          ║
    ║                   Next-Generation Script Execution System                  ║
    ║                                                                            ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    VERSION = "4.0.0",
    BUILD = "2026.08.10",
    GUI_NAME = "Z3US Ultimate Premium",
    STORAGE_PATH = "Z3US",
    CACHE_EXPIRY = 3600,
    MAX_RETRIES = 5,
    PRELOAD_SCRIPTS = true,
    ENABLE_ANALYTICS = true,
    PERFORMANCE_MODE = true,
    DEBUG_MODE = false,
    
    UI_THEME = {
        primary = Color3.fromRGB(88, 101, 242),
        primaryDark = Color3.fromRGB(66, 76, 181),
        secondary = Color3.fromRGB(114, 137, 218),
        accent = Color3.fromRGB(245, 80, 120),
        success = Color3.fromRGB(87, 187, 138),
        warning = Color3.fromRGB(250, 166, 26),
        danger = Color3.fromRGB(240, 71, 71),
        background = Color3.fromRGB(17, 18, 22),
        surface = Color3.fromRGB(26, 28, 34),
        surfaceHover = Color3.fromRGB(38, 40, 48),
        surfaceActive = Color3.fromRGB(48, 50, 58),
        text = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(148, 155, 164),
        textMuted = Color3.fromRGB(100, 105, 115),
        border = Color3.fromRGB(44, 46, 54),
    },
    
    HOTKEYS = {
        toggleUI = Enum.KeyCode.Insert,
        reloadScripts = Enum.KeyCode.F5,
        quickLoad = Enum.KeyCode.F6,
    }
}

-- ============================================================================
-- CORE ENGINE
-- ============================================================================

local Engine = {
    Services = {},
    Cache = {},
    State = {},
    Analytics = {},
    Performance = {},
    Profiles = {},
    Keybinds = {},
    initialized = false,
    startupTime = tick(),
}

Engine.Services = {
    Players = cloneref(game:GetService("Players")),
    CoreGui = cloneref(game:GetService("CoreGui") or gethui()),
    UserInput = cloneref(game:GetService("UserInputService")),
    RunService = cloneref(game:GetService("RunService")),
    TweenService = cloneref(game:GetService("TweenService")),
    HttpService = cloneref(game:GetService("HttpService")),
    Physics = cloneref(game:GetService("PhysicsService")),
    ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage")),
    MarketplaceService = cloneref(game:GetService("MarketplaceService")),
    GuiService = cloneref(game:GetService("GuiService")),
    SoundService = cloneref(game:GetService("SoundService")),
    Lighting = cloneref(game:GetService("Lighting")),
}

Engine.LocalPlayer = Engine.Services.Players.LocalPlayer

-- ============================================================================
-- UTILITY SYSTEM
-- ============================================================================

local Utility = {
    Cache = {
        _data = {},
        _timestamps = {},
        _predictions = {},
        _hits = 0,
        _misses = 0,
        
        set = function(self, key, value, ttl, predict)
            self._data[key] = value
            self._timestamps[key] = ttl and tick() + ttl or nil
            if predict then
                self._predictions[key] = predict
            end
            return value
        end,
        
        get = function(self, key)
            local data = self._data[key]
            local expiry = self._timestamps[key]
            
            if expiry and tick() > expiry then
                self._data[key] = nil
                self._timestamps[key] = nil
                self._misses = self._misses + 1
                return nil
            end
            
            if data then
                self._hits = self._hits + 1
                if self._predictions[key] then
                    task.spawn(function()
                        self:get(self._predictions[key])
                    end)
                end
                return data
            end
            
            self._misses = self._misses + 1
            return nil
        end,
        
        getStats = function(self)
            return {
                hits = self._hits,
                misses = self._misses,
                hitRate = self._hits / (self._hits + self._misses) * 100
            }
        end,
        
        clear = function(self)
            self._data = {}
            self._timestamps = {}
            self._predictions = {}
            self._hits = 0
            self._misses = 0
        end
    },
    
    http = {
        _mirrors = {},
        
        addMirror = function(self, url, mirrorUrl)
            self._mirrors[url] = mirrorUrl
        end,
        
        get = function(self, url, retries, timeout)
            retries = retries or CONFIG.MAX_RETRIES
            timeout = timeout or 10
            
            for i = 1, retries do
                local success, result = pcall(function()
                    return game:HttpGet(url)
                end)
                
                if success and result and #result > 100 then
                    return result
                end
                
                if self._mirrors[url] and i > 1 then
                    success, result = pcall(function()
                        return game:HttpGet(self._mirrors[url])
                    end)
                    if success and result and #result > 100 then
                        return result
                    end
                end
                
                task.wait(0.5 * i)
            end
            
            return nil
        end,
        
        getCached = function(self, url, ttl)
            ttl = ttl or CONFIG.CACHE_EXPIRY
            local cached = Utility.Cache:get("http_" .. url)
            
            if cached then
                return cached
            end
            
            local result = self:get(url)
            if result then
                Utility.Cache:set("http_" .. url, result, ttl)
            end
            
            return result
        end
    },
    
    animate = function(object, properties, duration, easingStyle, easingDirection)
        duration = duration or 0.3
        easingStyle = easingStyle or Enum.EasingStyle.Quad
        easingDirection = easingDirection or Enum.EasingDirection.Out
        
        local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection, 0, false, 0)
        local tween = Engine.Services.TweenService:Create(object, tweenInfo, properties)
        tween:Play()
        return tween
    end,
    
    table = {
        deepCopy = function(t)
            local copy = {}
            for k, v in pairs(t) do
                if type(v) == "table" then
                    copy[k] = Utility.table.deepCopy(v)
                else
                    copy[k] = v
                end
            end
            return copy
        end,
        
        merge = function(t1, t2)
            local result = Utility.table.deepCopy(t1)
            for k, v in pairs(t2) do
                if type(v) == "table" and type(result[k]) == "table" then
                    result[k] = Utility.table.merge(result[k], v)
                else
                    result[k] = v
                end
            end
            return result
        end,
        
        size = function(t)
            local count = 0
            for _ in pairs(t) do
                count = count + 1
            end
            return count
        end
    }
}

-- ============================================================================
-- SCRIPT MANAGER
-- ============================================================================

local ScriptManager = {
    _scripts = {},
    _loaded = {},
    _preloading = false,
    _executionHistory = {},
    _errors = {},
    
    register = function(self, scriptData)
        local id = scriptData.id or scriptData.name:gsub("%s+", "_"):lower()
        
        self._scripts[id] = {
            id = id,
            name = scriptData.name,
            description = scriptData.description or "",
            url = scriptData.url,
            author = scriptData.author or "Unknown",
            version = scriptData.version or "1.0",
            category = scriptData.category or "Misc",
            options = scriptData.options or {},
            isHeavy = scriptData.isHeavy or false,
            preload = scriptData.preload or false,
            executor = scriptData.executor,
            config = {},
            lastLoaded = nil,
            loadCount = 0,
            totalLoadTime = 0,
            _cachedContent = nil,
            preloaded = false,
            loaded = false,
        }
        
        return self._scripts[id]
    end,
    
    preload = function(self, scriptId)
        local script = self._scripts[scriptId]
        if not script or script.preloaded then return end
        
        script.preloaded = true
        
        task.spawn(function()
            local content = Utility.http.getCached(script.url)
            if content then
                script._cachedContent = content
            end
        end)
    end,
    
    preloadAll = function(self)
        if self._preloading then return end
        self._preloading = true
        
        task.spawn(function()
            for id, script in pairs(self._scripts) do
                if script.preload then
                    self:preload(id)
                    task.wait(0.05)
                end
            end
            self._preloading = false
        end)
    end,
    
    execute = function(self, scriptId, config)
        local script = self._scripts[scriptId]
        if not script then
            return false, "Script not found"
        end
        
        script.config = Utility.table.merge(script.config, config or {})
        
        local content = script._cachedContent or Utility.http.get(script.url)
        if not content then
            return false, "Failed to download script"
        end
        
        local startTime = tick()
        local success, err = pcall(function()
            script.executor(content, script.config)
        end)
        local loadTime = tick() - startTime
        
        if success then
            script.lastLoaded = tick()
            script.loadCount = script.loadCount + 1
            script.totalLoadTime = script.totalLoadTime + loadTime
            self._loaded[scriptId] = true
            script.loaded = true
            
            return true, "Loaded successfully in " .. string.format("%.2f", loadTime) .. "s"
        else
            return false, err
        end
    end,
    
    getInfo = function(self, scriptId)
        return self._scripts[scriptId]
    end,
    
    getAll = function(self, category)
        local result = {}
        for id, script in pairs(self._scripts) do
            if not category or script.category == category then
                result[id] = script
            end
        end
        return result
    end
}

-- ============================================================================
-- REGISTER SCRIPTS
-- ============================================================================

ScriptManager:register({
    name = "Arsenal",
    description = "Advanced Arsenal cheat with aimbot, ESP, and more",
    url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Arsenal%20Beta.lua",
    author = "blackowl1231",
    version = "2.1.0",
    category = "FPS",
    isHeavy = false,
    preload = true,
    options = {
        aimbot = { type = "toggle", label = "Aimbot", default = true },
        esp = { type = "toggle", label = "ESP", default = true },
    },
    executor = function(content, config)
        getgenv().Z3US_CONFIG = config
        loadstring(content)()
    end
})

ScriptManager:register({
    name = "Counterblox",
    description = "Counter-Strike style cheat with advanced features",
    url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Counterblox.lua",
    author = "blackowl1231",
    version = "1.8.5",
    category = "FPS",
    isHeavy = false,
    preload = true,
    options = {
        version = { type = "toggle", label = "Version", values = {"Old", "New"}, default = "Old" },
    },
    executor = function(content, config)
        if config.version == "New" then
            Engine.LocalPlayer:Kick("This script is detected and will get you banned")
        else
            loadstring(content)()
        end
    end
})

ScriptManager:register({
    name = "Rivals",
    description = "Advanced Rivals cheat with smooth aimbot and ESP",
    url = "https://api.jnkie.com/api/v1/luascripts/public/2438cfd42af811d55492e854318eeda24a73aa5d0b11a403ec1f7542abd8f2f0/download",
    author = "jnkie",
    version = "2.0.0",
    category = "FPS",
    isHeavy = true,
    preload = true,
    options = {
        autoload = { type = "toggle", label = "Auto Load", default = true },
        silentload = { type = "toggle", label = "Silent Load", default = false },
        version = { type = "toggle", label = "Version", values = {"V2", "V1"}, default = "V2" },
        performance = { type = "toggle", label = "Performance Mode", default = true },
    },
    executor = function(content, config)
        if config.performance then
            task.spawn(function()
                pcall(function()
                    game:GetService("UserSettings"):GetService("UserGameSettings").GraphicsQuality = 1
                    game:GetService("Lighting").GlobalShadows = false
                    if getgenv then
                        getgenv().FPS_LIMIT = 60
                    end
                end)
            end)
        end
        
        if config.version == "V2" then
            getgenv().autoload = config.autoload
            getgenv().silentload = config.silentload
            getgenv().SCRIPT_KEY = ""
            loadstring(content)()
        else
            task.spawn(function()
                repeat task.wait() until game:IsLoaded()
                repeat task.wait() until Engine.LocalPlayer and Engine.LocalPlayer.Character
                repeat task.wait() until not Engine.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LoadingScreen")
                
                getgenv().autoload = config.autoload
                getgenv().silentload = config.silentload
                getgenv().SCRIPT_KEY = ""
                local v1Content = Utility.http.get("https://api.junkie-development.de/api/v1/luascripts/public/8be52e21a0145a401c446ca7ab2b5df9bd327ea80b0cf1d2fe99e442edd0f9c9/download")
                if v1Content then
                    loadstring(v1Content)()
                end
            end)
        end
    end
})

ScriptManager:register({
    name = "Gunfight Arena",
    description = "Gunfight Arena cheat with perfect aim",
    url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Gunfight%20Arena.lua",
    author = "blackowl1231",
    version = "1.5.0",
    category = "FPS",
    isHeavy = false,
    preload = true,
    options = {},
    executor = function(content, config)
        loadstring(content)()
    end
})

ScriptManager:register({
    name = "Universal",
    description = "Universal script for multiple games",
    url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Universal.lua",
    author = "blackowl1231",
    version = "1.2.5",
    category = "Universal",
    isHeavy = false,
    preload = true,
    options = {},
    executor = function(content, config)
        loadstring(content)()
    end
})

ScriptManager:register({
    name = "Overkill",
    description = "Overkill cheat with key system",
    url = "https://api.jnkie.com/api/v1/luascripts/public/d603ee0150fbdeb809a036562925966619d3e145a77b4d07b222b0612022ab8f/download",
    author = "jnkie",
    version = "1.0.0",
    category = "FPS",
    isHeavy = false,
    preload = true,
    options = {
        key = { type = "string", label = "Key", default = "" },
    },
    executor = function(content, config)
        loadstring(content)()
    end
})

ScriptManager:register({
    name = "Planks",
    description = "Planks game cheat",
    url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/Z3US%20Planks.lua",
    author = "blackowl1231",
    version = "1.0.0",
    category = "Misc",
    isHeavy = false,
    preload = true,
    options = {},
    executor = function(content, config)
        loadstring(content)()
    end
})

ScriptManager:register({
    name = "One Tap",
    description = "One Tap cheat with advanced features",
    url = "https://api.jnkie.com/api/v1/luascripts/public/2548ffbebdf21063cd4083f93a27ac276d44d1cb6503093d9c3290c3dfd954e3/download",
    author = "jnkie",
    version = "1.0.0",
    category = "FPS",
    isHeavy = false,
    preload = true,
    options = {},
    executor = function(content, config)
        getgenv().SCRIPT_KEY = ""
        loadstring(content)()
    end
})

-- ============================================================================
-- UI SYSTEM (COMPLETE)
-- ============================================================================

local UI = {
    _instance = nil,
    _components = {},
    _selectedScript = nil,
    _theme = CONFIG.UI_THEME,
    
    init = function(self)
        self:createInstance()
        self:buildMainFrame()
        self:buildHeader()
        self:buildSidebar()
        self:buildMainContent()
        self:buildFooter()
        self:setupDragging()
        self:setupKeybinds()
        ScriptManager:preloadAll()
        self:showNotification("🚀 Z3US Ultimate v" .. CONFIG.VERSION .. " loaded!")
    end,
    
    createInstance = function(self)
        self._instance = Instance.new("ScreenGui")
        self._instance.Name = CONFIG.GUI_NAME .. " v" .. CONFIG.VERSION
        self._instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self._instance.Parent = Engine.Services.CoreGui
    end,
    
    buildMainFrame = function(self)
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Active = true
        frame.BackgroundColor3 = self._theme.background
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0
        frame.Position = UDim2.new(0.05, 0, 0.03, 0)
        frame.Size = UDim2.new(0.9, 0, 0.94, 0)
        frame.Parent = self._instance
        
        local glass = Instance.new("Frame")
        glass.Name = "GlassEffect"
        glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        glass.BackgroundTransparency = 0.03
        glass.BorderSizePixel = 0
        glass.Size = UDim2.new(1, 0, 1, 0)
        glass.Parent = frame
        
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.4
        shadow.BorderSizePixel = 0
        shadow.Position = UDim2.new(0.01, 0, 0.01, 0)
        shadow.Size = UDim2.new(1, 0, 1, 0)
        shadow.ZIndex = -1
        shadow.Parent = frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = frame
        
        local glow = Instance.new("Frame")
        glow.Name = "Glow"
        glow.BackgroundColor3 = self._theme.primary
        glow.BackgroundTransparency = 0.15
        glow.BorderSizePixel = 0
        glow.Position = UDim2.new(-0.003, 0, -0.003, 0)
        glow.Size = UDim2.new(1.006, 0, 1.006, 0)
        glow.ZIndex = -1
        glow.Parent = frame
        
        local glowCorner = Instance.new("UICorner")
        glowCorner.CornerRadius = UDim.new(0, 18)
        glowCorner.Parent = glow
        
        self._components.mainFrame = frame
        frame.Position = UDim2.new(0.05, 0, -0.5, 0)
        Utility.animate(frame, {Position = UDim2.new(0.05, 0, 0.03, 0)}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        return frame
    end,
    
    buildHeader = function(self)
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.BackgroundColor3 = self._theme.surface
        header.BackgroundTransparency = 0.5
        header.BorderSizePixel = 0
        header.Size = UDim2.new(1, 0, 0, 70)
        header.Parent = self._components.mainFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = header
        
        local logo = Instance.new("TextLabel")
        logo.Name = "Logo"
        logo.BackgroundTransparency = 1
        logo.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        logo.Position = UDim2.new(0.02, 0, 0, 0)
        logo.Size = UDim2.new(0.3, 0, 1, 0)
        logo.Text = "⚡ " .. CONFIG.GUI_NAME
        logo.TextColor3 = self._theme.primary
        logo.TextSize = 28
        logo.TextXAlignment = Enum.TextXAlignment.Left
        logo.Parent = header
        
        local badge = Instance.new("TextLabel")
        badge.Name = "Badge"
        badge.BackgroundColor3 = self._theme.primary
        badge.BackgroundTransparency = 0.2
        badge.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        badge.Position = UDim2.new(0.12, 0, 0.2, 0)
        badge.Size = UDim2.new(0, 100, 0, 30)
        badge.Text = "v" .. CONFIG.VERSION
        badge.TextColor3 = self._theme.textSecondary
        badge.TextSize = 12
        badge.Parent = header
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 8)
        badgeCorner.Parent = badge
        
        local close = Instance.new("TextButton")
        close.Name = "CloseButton"
        close.BackgroundTransparency = 1
        close.Position = UDim2.new(0.97, 0, 0.15, 0)
        close.Size = UDim2.new(0, 45, 0, 45)
        close.Text = "✕"
        close.TextColor3 = self._theme.textSecondary
        close.TextSize = 22
        close.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        close.Parent = header
        close.MouseButton1Click:Connect(function()
            self._instance:Destroy()
        end)
        
        self._components.header = header
    end,
    
    buildSidebar = function(self)
        local sidebar = Instance.new("Frame")
        sidebar.Name = "Sidebar"
        sidebar.BackgroundColor3 = self._theme.surface
        sidebar.BackgroundTransparency = 0.5
        sidebar.BorderSizePixel = 0
        sidebar.Position = UDim2.new(0.01, 0, 0.13, 0)
        sidebar.Size = UDim2.new(0.2, 0, 0.82, 0)
        sidebar.Parent = self._components.mainFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = sidebar
        
        local search = Instance.new("TextBox")
        search.Name = "SearchBox"
        search.BackgroundColor3 = self._theme.surfaceHover
        search.BorderSizePixel = 0
        search.Position = UDim2.new(0.05, 0, 0.02, 0)
        search.Size = UDim2.new(0.9, 0, 0.08, 0)
        search.PlaceholderText = "🔍 Search scripts..."
        search.TextColor3 = self._theme.text
        search.TextSize = 14
        search.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        search.Parent = sidebar
        
        local container = Instance.new("ScrollingFrame")
        container.Name = "ScriptList"
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Position = UDim2.new(0.02, 0, 0.12, 0)
        container.Size = UDim2.new(0.96, 0, 0.85, 0)
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = self._theme.primary
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.Parent = sidebar
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
        
        local canvasHeight = 0
        local scripts = ScriptManager:getAll()
        for id, script in pairs(scripts) do
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = self._theme.surface
            button.BackgroundTransparency = 0.9
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 0, 50)
            button.Text = ""
            button.Parent = container
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = button
            
            local name = Instance.new("TextLabel")
            name.BackgroundTransparency = 1
            name.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            name.Position = UDim2.new(0.05, 0, 0, 0)
            name.Size = UDim2.new(0.8, 0, 1, 0)
            name.Text = script.name
            name.TextColor3 = self._theme.text
            name.TextSize = 16
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = button
            
            button._scriptId = id
            button._scriptName = script.name
            
            button.MouseButton1Click:Connect(function()
                self:selectScript(id)
            end)
            
            canvasHeight = canvasHeight + 55
        end
        container.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
        
        search.Changed:Connect(function()
            local query = search.Text:lower()
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("TextButton") then
                    local name = child._scriptName or ""
                    child.Visible = name:lower():find(query) ~= nil
                end
            end
        end)
    end,
    
    buildMainContent = function(self)
        local content = Instance.new("Frame")
        content.Name = "Content"
        content.BackgroundColor3 = self._theme.surface
        content.BackgroundTransparency = 0.3
        content.BorderSizePixel = 0
        content.Position = UDim2.new(0.225, 0, 0.13, 0)
        content.Size = UDim2.new(0.765, 0, 0.82, 0)
        content.Parent = self._components.mainFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = content
        
        local infoPanel = Instance.new("Frame")
        infoPanel.Name = "InfoPanel"
        infoPanel.BackgroundColor3 = self._theme.background
        infoPanel.BackgroundTransparency = 0.5
        infoPanel.BorderSizePixel = 0
        infoPanel.Position = UDim2.new(0.03, 0, 0.03, 0)
        infoPanel.Size = UDim2.new(0.94, 0, 0.25, 0)
        infoPanel.Parent = content
        
        local infoCorner = Instance.new("UICorner")
        infoCorner.CornerRadius = UDim.new(0, 10)
        infoCorner.Parent = infoPanel
        
        local name = Instance.new("TextLabel")
        name.Name = "ScriptName"
        name.BackgroundTransparency = 1
        name.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        name.Position = UDim2.new(0.03, 0, 0.1, 0)
        name.Size = UDim2.new(0.8, 0, 0.35, 0)
        name.Text = "Select a script"
        name.TextColor3 = self._theme.text
        name.TextSize = 22
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = infoPanel
        
        local desc = Instance.new("TextLabel")
        desc.Name = "ScriptDescription"
        desc.BackgroundTransparency = 1
        desc.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        desc.Position = UDim2.new(0.03, 0, 0.5, 0)
        desc.Size = UDim2.new(0.9, 0, 0.4, 0)
        desc.Text = "Click a script to view details"
        desc.TextColor3 = self._theme.textSecondary
        desc.TextSize = 14
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = infoPanel
        
        local optionsPanel = Instance.new("Frame")
        optionsPanel.Name = "OptionsPanel"
        optionsPanel.BackgroundColor3 = self._theme.background
        optionsPanel.BackgroundTransparency = 0.5
        optionsPanel.BorderSizePixel = 0
        optionsPanel.Position = UDim2.new(0.03, 0, 0.32, 0)
        optionsPanel.Size = UDim2.new(0.94, 0, 0.45, 0)
        optionsPanel.Parent = content
        
        local optionsCorner = Instance.new("UICorner")
        optionsCorner.CornerRadius = UDim.new(0, 10)
        optionsCorner.Parent = optionsPanel
        
        local optionsLabel = Instance.new("TextLabel")
        optionsLabel.Name = "OptionsLabel"
        optionsLabel.BackgroundTransparency = 1
        optionsLabel.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        optionsLabel.Position = UDim2.new(0.03, 0, 0.05, 0)
        optionsLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
        optionsLabel.Text = "⚙️ Options"
        optionsLabel.TextColor3 = self._theme.text
        optionsLabel.TextSize = 16
        optionsLabel.TextXAlignment = Enum.TextXAlignment.Left
        optionsLabel.Parent = optionsPanel
        
        local optionsContainer = Instance.new("Frame")
        optionsContainer.Name = "OptionsContainer"
        optionsContainer.BackgroundTransparency = 1
        optionsContainer.Position = UDim2.new(0.03, 0, 0.3, 0)
        optionsContainer.Size = UDim2.new(0.94, 0, 0.65, 0)
        optionsContainer.Parent = optionsPanel
        
        local loadBtn = Instance.new("TextButton")
        loadBtn.Name = "LoadButton"
        loadBtn.BackgroundColor3 = self._theme.primary
        loadBtn.BorderSizePixel = 0
        loadBtn.Position = UDim2.new(0.35, 0, 0.82, 0)
        loadBtn.Size = UDim2.new(0.3, 0, 0.12, 0)
        loadBtn.Text = "▶ EXECUTE"
        loadBtn.TextColor3 = self._theme.text
        loadBtn.TextSize = 18
        loadBtn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        loadBtn.Parent = content
        
        local loadCorner = Instance.new("UICorner")
        loadCorner.CornerRadius = UDim.new(0, 8)
        loadCorner.Parent = loadBtn
        
        loadBtn.MouseButton1Click:Connect(function()
            self:executeSelected()
        end)
        
        self._components.content = content
        self._components.scriptName = name
        self._components.scriptDesc = desc
        self._components.optionsContainer = optionsContainer
        self._components.loadButton = loadBtn
    end,
    
    buildFooter = function(self)
        local footer = Instance.new("Frame")
        footer.Name = "Footer"
        footer.BackgroundColor3 = self._theme.surface
        footer.BackgroundTransparency = 0.5
        footer.BorderSizePixel = 0
        footer.Position = UDim2.new(0, 0, 0.95, 0)
        footer.Size = UDim2.new(1, 0, 0.05, 0)
        footer.Parent = self._components.mainFrame
        
        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.BackgroundTransparency = 1
        status.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        status.Position = UDim2.new(0.01, 0, 0, 0)
        status.Size = UDim2.new(0.7, 0, 1, 0)
        status.Text = "🟢 Ready"
        status.TextColor3 = self._theme.success
        status.TextSize = 13
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = footer
        
        self._components.statusLabel = status
    end,
    
    showNotification = function(self, message, type)
        local container = self._instance:FindFirstChild("NotificationContainer")
        if not container then
            container = Instance.new("Frame")
            container.Name = "NotificationContainer"
            container.BackgroundTransparency = 1
            container.Position = UDim2.new(0.75, 0, 0.02, 0)
            container.Size = UDim2.new(0.24, 0, 0.3, 0)
            container.Parent = self._instance
        end
        
        local notif = Instance.new("TextLabel")
        notif.BackgroundColor3 = self._theme.surface
        notif.BackgroundTransparency = 0.3
        notif.BorderSizePixel = 0
        notif.Size = UDim2.new(1, 0, 0, 35)
        notif.Text = message
        notif.TextColor3 = self._theme.text
        notif.TextSize = 13
        notif.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        notif.Parent = container
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 6)
        notifCorner.Parent = notif
        
        notif.Position = UDim2.new(0, 0, -0.5, 0)
        Utility.animate(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
        
        task.delay(3, function()
            Utility.animate(notif, {Position = UDim2.new(0, 0, -0.5, 0)}, 0.3)
            task.wait(0.3)
            notif:Destroy()
        end)
    end,
    
    setupDragging = function(self)
        local dragStart = nil
        local dragStartPos = nil
        local isDragging = false
        
        self._components.header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                dragStart = input.Position
                dragStartPos = self._components.mainFrame.Position
            end
        end)
        
        Engine.Services.UserInput.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                local mainFrame = self._components.mainFrame
                mainFrame.Position = UDim2.new(
                    dragStartPos.X.Scale,
                    dragStartPos.X.Offset + delta.X,
                    dragStartPos.Y.Scale,
                    dragStartPos.Y.Offset + delta.Y
                )
            end
        end)
        
        Engine.Services.UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
    end,
    
    setupKeybinds = function(self)
        Engine.Services.UserInput.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == CONFIG.HOTKEYS.toggleUI then
                self._instance.Enabled = not self._instance.Enabled
                self:showNotification(self._instance.Enabled and "UI Shown" or "UI Hidden", "info")
            end
            
            if input.KeyCode == CONFIG.HOTKEYS.reloadScripts then
                self:showNotification("🔄 Reloading...", "info")
                ScriptManager:preloadAll()
                task.wait(0.5)
                self:showNotification("✅ Reloaded!", "success")
            end
        end)
    end,
    
    selectScript = function(self, scriptId)
        local script = ScriptManager:getInfo(scriptId)
        if not script then return end
        
        self._selectedScript = scriptId
        self._components.scriptName.Text = script.name
        self._components.scriptDesc.Text = script.description or "No description"
        
        -- Clear and rebuild options
        local container = self._components.optionsContainer
        for _, child in ipairs(container:GetChildren()) do
            child:Destroy()
        end
        
        if not script.options or next(script.options) == nil then
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Text = "ℹ️ No options available"
            label.TextColor3 = self._theme.textSecondary
            label.TextSize = 14
            label.Parent = container
            return
        end
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
        
        for key, option in pairs(script.options) do
            if option.type == "toggle" then
                local frame = Instance.new("Frame")
                frame.BackgroundTransparency = 1
                frame.Size = UDim2.new(1, 0, 0, 40)
                frame.Parent = container
                
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                label.Position = UDim2.new(0, 0, 0, 0)
                label.Size = UDim2.new(0.6, 0, 1, 0)
                label.Text = option.label or key
                label.TextColor3 = self._theme.text
                label.TextSize = 16
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = frame
                
                local btn = Instance.new("TextButton")
                btn.BackgroundColor3 = option.default and self._theme.success or self._theme.surfaceHover
                btn.BorderSizePixel = 0
                btn.Position = UDim2.new(0.75, 0, 0.1, 0)
                btn.Size = UDim2.new(0.2, 0, 0.8, 0)
                btn.Text = option.default and "ON" or "OFF"
                btn.TextColor3 = self._theme.text
                btn.TextSize = 14
                btn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                btn.Parent = frame
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn
                
                local value = option.default or false
                btn.MouseButton1Click:Connect(function()
                    value = not value
                    btn.Text = value and "ON" or "OFF"
                    btn.BackgroundColor3 = value and self._theme.success or self._theme.surfaceHover
                    local scriptObj = ScriptManager:getInfo(self._selectedScript)
                    if scriptObj then
                        scriptObj.config[key] = value
                    end
                end)
            end
        end
    end,
    
    executeSelected = function(self)
        if not self._selectedScript then
            self:showNotification("⚠️ Select a script first!", "warning")
            return
        end
        
        local script = ScriptManager:getInfo(self._selectedScript)
        if not script then return end
        
        local loadBtn = self._components.loadButton
        local status = self._components.statusLabel
        
        loadBtn.Text = "⏳ LOADING..."
        loadBtn.BackgroundColor3 = self._theme.warning
        status.Text = "🔄 Loading " .. script.name .. "..."
        status.TextColor3 = self._theme.warning
        
        local success, result = ScriptManager:execute(self._selectedScript, script.config)
        
        if success then
            loadBtn.Text = "✓ DONE"
            loadBtn.BackgroundColor3 = self._theme.success
            status.Text = "✅ " .. result
            status.TextColor3 = self._theme.success
            self:showNotification("✅ " .. script.name .. " loaded!", "success")
            
            task.delay(2, function()
                loadBtn.Text = "▶ EXECUTE"
                loadBtn.BackgroundColor3 = self._theme.primary
            end)
        else
            loadBtn.Text = "⚠ RETRY"
            loadBtn.BackgroundColor3 = self._theme.danger
            status.Text = "❌ Error: " .. result
            status.TextColor3 = self._theme.danger
            self:showNotification("❌ Error loading " .. script.name, "danger")
            
            task.delay(2, function()
                loadBtn.Text = "▶ EXECUTE"
                loadBtn.BackgroundColor3 = self._theme.primary
            end)
        end
    end
}

-- ============================================================================
-- INITIALIZE
-- ============================================================================

local success, err = pcall(function()
    UI:init()
end)

if not success then
    warn("[Z3US] Failed to initialize:", err)
    task.wait(1)
    pcall(function()
        UI:init()
    end)
end
