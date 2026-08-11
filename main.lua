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
-- 1. CONFIGURATION ENGINE
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
-- 2. CORE ENGINE
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

-- Initialize all services
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
-- 3. ADVANCED UTILITY SYSTEM
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
    
    measure = function(func, label)
        local start = tick()
        local success, result = pcall(func)
        local elapsed = tick() - start
        
        if CONFIG.ENABLE_ANALYTICS then
            table.insert(Engine.Performance, {
                label = label or "unnamed",
                time = elapsed,
                success = success,
                timestamp = tick()
            })
            if #Engine.Performance > 1000 then
                table.remove(Engine.Performance, 1)
            end
        end
        
        return success, result, elapsed
    end,
    
    debounce = function(func, delay, immediate)
        local cooldown = false
        local timer = nil
        local pending = false
        local pendingArgs = nil
        
        return function(...)
            local args = {...}
            
            if immediate and not cooldown then
                func(unpack(args))
            end
            
            if timer then
                timer:Disconnect()
                timer = nil
                pending = true
                pendingArgs = args
                return
            end
            
            if not cooldown then
                cooldown = true
                
                timer = Engine.Services.RunService.Heartbeat:Connect(function()
                    if pending then
                        func(unpack(pendingArgs))
                        pending = false
                        pendingArgs = nil
                    else
                        func(unpack(args))
                    end
                    
                    timer:Disconnect()
                    timer = nil
                    cooldown = false
                end)
            end
        end
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
        
        find = function(t, predicate)
            for k, v in pairs(t) do
                if predicate(k, v) then
                    return v
                end
            end
            return nil
        end,
        
        filter = function(t, predicate)
            local result = {}
            for k, v in pairs(t) do
                if predicate(k, v) then
                    result[k] = v
                end
            end
            return result
        end,
        
        map = function(t, transform)
            local result = {}
            for k, v in pairs(t) do
                result[k] = transform(k, v)
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
    },
    
    string = {
        split = function(str, delimiter)
            local result = {}
            for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
                table.insert(result, match)
            end
            return result
        end,
        
        trim = function(str)
            return str:match("^%s*(.-)%s*$")
        end,
        
        startsWith = function(str, prefix)
            return string.sub(str, 1, #prefix) == prefix
        end,
        
        endsWith = function(str, suffix)
            return string.sub(str, -#suffix) == suffix
        end,
        
        contains = function(str, substring)
            return string.find(str, substring, 1, true) ~= nil
        end
    },
    
    color = {
        hexToRgb = function(hex)
            hex = hex:gsub("#", "")
            local r = tonumber("0x" .. hex:sub(1, 2)) / 255
            local g = tonumber("0x" .. hex:sub(3, 4)) / 255
            local b = tonumber("0x" .. hex:sub(5, 6)) / 255
            return Color3.new(r, g, b)
        end,
        
        rgbToHex = function(color)
            return string.format("#%02x%02x%02x",
                math.floor(color.R * 255),
                math.floor(color.G * 255),
                math.floor(color.B * 255)
            )
        end,
        
        lerp = function(c1, c2, t)
            return Color3.new(
                c1.R + (c2.R - c1.R) * t,
                c1.G + (c2.G - c1.G) * t,
                c1.B + (c2.B - c1.B) * t
            )
        end
    }
}

-- ============================================================================
-- 4. SCRIPT MANAGEMENT SYSTEM
-- ============================================================================

local ScriptManager = {
    _scripts = {},
    _loaded = {},
    _preloading = false,
    _preloadQueue = {},
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
            dependencies = scriptData.dependencies or {},
            executor = scriptData.executor,
            config = {},
            lastLoaded = nil,
            loadCount = 0,
            totalLoadTime = 0,
            _cachedContent = nil,
            _cacheTime = nil,
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
                script._cacheTime = tick()
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
        
        for _, depId in ipairs(script.dependencies) do
            if not self._loaded[depId] then
                local success, err = self:execute(depId)
                if not success then
                    return false, "Dependency failed: " .. err
                end
            end
        end
        
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
            
            table.insert(self._executionHistory, {
                scriptId = scriptId,
                time = loadTime,
                timestamp = tick(),
                success = true
            })
            
            return true, "Loaded successfully in " .. string.format("%.2f", loadTime) .. "s"
        else
            table.insert(self._errors, {
                scriptId = scriptId,
                error = err,
                timestamp = tick()
            })
            
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
    end,
    
    getStats = function(self)
        local totalLoads = 0
        local totalTime = 0
        for id, script in pairs(self._scripts) do
            totalLoads = totalLoads + script.loadCount
            totalTime = totalTime + script.totalLoadTime
        end
        
        return {
            totalScripts = Utility.table.size(self._scripts),
            loadedScripts = Utility.table.size(self._loaded),
            totalLoads = totalLoads,
            averageLoadTime = totalLoads > 0 and totalTime / totalLoads or 0,
            errors = #self._errors
        }
    end
}

-- ============================================================================
-- 5. REGISTER ALL SCRIPTS
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
        silent = { type = "toggle", label = "Silent Aim", default = false },
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
                    if settings then
                        pcall(function()
                            settings().Rendering.QualityLevel = 1
                        end)
                    end
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
-- 6. UI SYSTEM
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
        
        -- Glass Effect
        local glass = Instance.new("Frame")
        glass.Name = "GlassEffect"
        glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        glass.BackgroundTransparency = 0.03
        glass.BorderSizePixel = 0
        glass.Size = UDim2.new(1, 0, 1, 0)
        glass.Parent = frame
        
        -- Shadow
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.4
        shadow.BorderSizePixel = 0
        shadow.Position = UDim2.new(0.01, 0, 0.01, 0)
        shadow.Size = UDim2.new(1, 0, 1, 0)
        shadow.ZIndex = -1
        shadow.Parent = frame
        
        -- Corner
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = frame
        
        -- Border Glow
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
        
        -- Gradient overlay
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 45
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self._theme.background),
            ColorSequenceKeypoint.new(1, self._theme.surface)
        })
        gradient.Parent = frame
        
        self._components.mainFrame = frame
        
        -- Animate entrance
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
        
        -- Logo
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
        
        -- Version badge
        local badge = Instance.new("TextLabel")
        badge.Name = "Badge"
        badge.BackgroundColor3 = self._theme.primary
        badge.BackgroundTransparency = 0.2
        badge.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        badge.Position = UDim2.new(0.12, 0, 0.2, 0)
        badge.Size = UDim2.new(0, 100, 0, 30)
        badge.Text = "v" .. CONFIG.VERSION .. " Build " .. CONFIG.BUILD
        badge.TextColor3 = self._theme.textSecondary
        badge.TextSize = 12
        badge.TextXAlignment = Enum.TextXAlignment.Center
        badge.Parent = header
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 8)
        badgeCorner.Parent = badge
        
        -- Close Button
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
        
        close.MouseEnter:Connect(function()
            Utility.animate(close, {TextColor3 = self._theme.danger}, 0.1)
        end)
        close.MouseLeave:Connect(function()
            Utility.animate(close, {TextColor3 = self._theme.textSecondary}, 0.1)
        end)
        close.MouseButton1Click:Connect(function()
            self._instance:Destroy()
        end)
        
        -- Minimize Button
        local minimize = Instance.new("TextButton")
        minimize.Name = "MinimizeButton"
        minimize.BackgroundTransparency = 1
        minimize.Position = UDim2.new(0.94, 0, 0.15, 0)
        minimize.Size = UDim2.new(0, 45, 0, 45)
        minimize.Text = "─"
        minimize.TextColor3 = self._theme.textSecondary
        minimize.TextSize = 22
        minimize.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        minimize.Parent = header
        
        local isMinimized = false
        minimize.MouseButton1Click:Connect(function()
            isMinimized = not isMinimized
            if isMinimized then
                Utility.animate(self._components.mainFrame, {Size = UDim2.new(0.9, 0, 0.1, 0)}, 0.3)
                for _, child in ipairs(self._components.mainFrame:GetChildren()) do
                    if child.Name ~= "Header" and child.Name ~= "Glow" and child.Name ~= "Shadow" and child.Name ~= "GlassEffect" then
                        child.Visible = false
                    end
                end
            else
                Utility.animate(self._components.mainFrame, {Size = UDim2.new(0.9, 0, 0.94, 0)}, 0.3)
                for _, child in ipairs(self._components.mainFrame:GetChildren()) do
                    if child.Name ~= "Header" and child.Name ~= "Glow" and child.Name ~= "Shadow" and child.Name ~= "GlassEffect" then
                        child.Visible = true
                    end
                end
            end
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
        
        -- Search Box
        local search = Instance.new("TextBox")
        search.Name = "SearchBox"
        search.BackgroundColor3 = self._theme.surfaceHover
        search.BorderSizePixel = 0
        search.Position = UDim2.new(0.05, 0, 0.02, 0)
        search.Size = UDim2.new(0.9, 0, 0.08, 0)
        search.PlaceholderText = "🔍 Search scripts..."
        search.Text = ""
        search.TextColor3 = self._theme.text
        search.TextSize = 14
        search.FontFace = Font.new("rbxasset://fonts/families/Nun
