local NetworkManager = require("modules/network_manager")
local Terminal = require("apps.terminal")
local TextEditor = require("apps.text_editor")
local FileManager = require("apps.file_manager")
local EmailClient = require("apps.email_client")
local Icons = require("modules/icons")

local StatusBar = {}

function StatusBar:new()
    local obj = {
        height = 25,
        backgroundColor = {0.15, 0.15, 0.15},
        textColor = {1, 1, 1},
        activeColor = {0.3, 0.5, 0.7},
        time = os.date("%H:%M"),
        networkManager = NetworkManager:new(),
        openMenus = {},
        windowManager = nil, -- Will be set after creation
        icons = Icons:new(),
        apps = {
            {name = "Terminal", icon = "terminal", class = Terminal},
            {name = "Files", icon = "files", class = FileManager},
            {name = "Email", icon = "email", class = EmailClient},
            {name = "Text Editor", icon = "text_editor", class = TextEditor}
        }
    }
    obj.icons:load()  -- Load the icons immediately after creation
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function StatusBar:isAppOpen(appName)
    for _, window in ipairs(self.windowManager.windows) do
        if window.appName == appName then
            return true
        end
    end
    return false
end

function StatusBar:draw()
    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.height)
    
    -- Draw app icons
    local iconSpacing = 40
    local iconSize = 20
    for i, app in ipairs(self.apps) do
        -- Draw highlight if app is open
        if self:isAppOpen(app.name) then
            love.graphics.setColor(self.activeColor)
            love.graphics.rectangle("fill", 8 + (i-1) * iconSpacing, 2, iconSize + 4, iconSize + 4)
        end
        
        local icon = self.icons:get(app.icon)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(icon, 10 + (i-1) * iconSpacing, 3, 0, iconSize/icon:getWidth(), iconSize/icon:getHeight())
    end
    
    -- Draw time and network status
    love.graphics.setColor(self.textColor)
    local timeText = os.date("%H:%M")
    love.graphics.print(timeText, love.graphics.getWidth() - 50, 5)
    self.networkManager:draw(love.graphics.getWidth() - 100, 0)
end

function StatusBar:launchApp(app)
    local window = self.windowManager:createWindow(
        app.name,
        math.random(100, 300),
        math.random(100, 300),
        400,
        300,
        app.class:new()
    )
    window.appName = app.name
end

function StatusBar:mousepressed(x, y, button)
    if button == 1 then
        -- Check network icon
        if x >= love.graphics.getWidth() - 100 and x <= love.graphics.getWidth() - 85 and
           y >= 5 and y <= 20 then
            self.networkManager:toggle()
            return
        end
        
        -- Check app icons
        local iconSpacing = 40
        local iconSize = 20
        for i, app in ipairs(self.apps) do
            if x >= 10 + (i-1) * iconSpacing and x <= 10 + (i-1) * iconSpacing + iconSize and
               y >= 3 and y <= 3 + iconSize then
                self:launchApp(app)
                return
            end
        end
    end
end

return StatusBar 