local Terminal = require("apps.terminal")
local TextEditor = require("apps.text_editor")
local FileManager = require("apps.file_manager")
local EmailClient = require("apps.email_client")
local WebBrowser = require("apps.web_browser")
local MissionsApp = require("apps.missions_app")

local Icons = require("modules.icons")

local StatusBar = {}

-- Size constants
STATUSBAR_HEIGHT = 40
local ICON_SPACING = 60
local ICON_SIZE = 30
NETWORK_ICON_SIZE = 25

function StatusBar:new()
    local obj = {
        height = STATUSBAR_HEIGHT,
        width = 1920, -- Set to virtual width (1920 for 1080p)
        backgroundColor = {0.15, 0.15, 0.15},
        textColor = {1, 1, 1},
        activeColor = {0.3, 0.5, 0.7},
        windowManager = nil,
        icons = Icons:new(),
        apps = {
            {name = "Terminal", icon = "terminal", class = Terminal},
            {name = "Files", icon = "files", class = FileManager},
            {name = "Email", icon = "email", class = EmailClient},
            {name = "Text Editor", icon = "text_editor", class = TextEditor},
            {name = "Browser", icon = "browser", class = WebBrowser},
            {name = "Missions", icon = "missions", class = MissionsApp}
        }
    }
    obj.icons:load()

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
    -- Draw background using virtual width
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    -- Draw app icons
    for i, app in ipairs(self.apps) do
        -- Draw highlight if app is open
        if self:isAppOpen(app.name) then
            love.graphics.setColor(self.activeColor)
            love.graphics.rectangle("fill", 8 + (i-1) * ICON_SPACING, 2, ICON_SIZE + 4, ICON_SIZE + 4)
        end
        
        local icon = self.icons:get(app.icon)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(icon, 10 + (i-1) * ICON_SPACING, 3, 0, ICON_SIZE/icon:getWidth(), ICON_SIZE/icon:getHeight())
    end
    
    -- Draw time using virtual coordinates
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf",18)  -- Size for 1080p
    font:setFilter("nearest", "nearest")  -- Set filter to nearest
    love.graphics.setFont(font)
    
    -- Draw time at virtual coordinates
    love.graphics.setColor(self.textColor)
    local timeText = os.date("%H:%M")
    love.graphics.print(timeText, self.width - 100, 10)
    love.graphics.setFont(default_font)
end

function StatusBar:launchApp(app)
    -- Check if the app is already open
    for _, window in ipairs(self.windowManager.windows) do
        if window.appName == app.name then
            -- App is already open, bring it to front and focus it
            self.windowManager:bringToFront(window)
            return
        end
    end

    -- If the app is not open, create a new window with virtual coordinates
    local window = self.windowManager:createWindow(
        app.name,
        math.random(100, 300),  -- Random position within virtual space
        math.random(100, 300),
        1920,  -- Window size in virtual coordinates
        1080,
        app.class:new()
    )
    window.appName = app.name
end

function StatusBar:mousepressed(x, y, button)
    if button == 1 then
        -- Check app icons using virtual coordinates
        for i, app in ipairs(self.apps) do
            if x >= 10 + (i-1) * ICON_SPACING and x <= 10 + (i-1) * ICON_SPACING + ICON_SIZE and
               y >= 3 and y <= 3 + ICON_SIZE then
                self:launchApp(app)
                return
            end
        end
    end
end

function StatusBar:keypressed(key)
    -- Key handling (if needed)
end

function StatusBar:textinput(text)
    -- Text input handling (if needed)
end

function StatusBar:update(dt)
    -- Update logic (if needed)
end

return StatusBar