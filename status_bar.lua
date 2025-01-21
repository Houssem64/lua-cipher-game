local NetworkManager = require("modules/network_manager")
local Terminal = require("apps.terminal")
local TextEditor = require("apps.text_editor")
local FileManager = require("apps.file_manager")
local EmailClient = require("apps.email_client")
local Icons = require("modules/icons")

local StatusBar = {}

-- Size constants
STATUSBAR_HEIGHT = 40
local ICON_SPACING = 60
local ICON_SIZE = 30
NETWORK_ICON_SIZE = 25


function StatusBar:resize(newWidth, newHeight)
    self.width = newWidth
    -- Adjust any other necessary properties
end
function StatusBar:new()
    local obj = {
        height = STATUSBAR_HEIGHT,
        backgroundColor = {0.15, 0.15, 0.15},
        textColor = {1, 1, 1},
        activeColor = {0.3, 0.5, 0.7},
      --  networkManager = NetworkManager:new(),
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

--[[     -- Add some initial networks
    obj.networkManager:addNetwork("WiFi-1", 80, true)
    obj.networkManager:addNetwork("WiFi-2", 60, true)
    obj.networkManager:addNetwork("OpenNet", 40, false)
 ]]
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
    
    -- Draw time 
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont(14)  -- Increased font size
    love.graphics.setFont(font)
   
    
    -- Draw date
    love.graphics.setColor(self.textColor)
    local timeText = os.date("%H:%M")
    love.graphics.print(timeText, love.graphics.getWidth() - 50, 10)
    love.graphics.setFont(default_font)  -- Reset font to default after drawing time text
--[[     -- Draw network status and icon
    local networkStatus, iconColor
    if isConnected then
        networkStatus = "Connected" 
        iconColor = {0.2, 0.8, 0.2} -- Green for connected
    else
        networkStatus = "Not Connected"
        iconColor = {0.5, 0.5, 0.5} -- Gray for disconnected
    end
    love.graphics.setColor(self.textColor)
    love.graphics.print(networkStatus, love.graphics.getWidth() - 300, 15)

    -- Draw network icon
    local iconX = love.graphics.getWidth() - 200
    local iconY = 5

    love.graphics.setColor(iconColor)
    -- Draw a simple WiFi icon
    love.graphics.arc("fill", iconX + NETWORK_ICON_SIZE/2, iconY + NETWORK_ICON_SIZE/2, NETWORK_ICON_SIZE/2, math.pi, 0)
    love.graphics.arc("fill", iconX + NETWORK_ICON_SIZE/2, iconY + NETWORK_ICON_SIZE/2, NETWORK_ICON_SIZE/3, math.pi, 0)
    love.graphics.arc("fill", iconX + NETWORK_ICON_SIZE/2, iconY + NETWORK_ICON_SIZE/2, NETWORK_ICON_SIZE/6, math.pi, 0)
 ]]
   -- self.networkManager:draw(love.graphics.getWidth() - 200, 0)
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

    -- If the app is not open, create a new window
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
--[[         -- Check network icon
        local iconX = love.graphics.getWidth() - 100
        local iconY = 5
        if x >= iconX and x <= iconX + NETWORK_ICON_SIZE and
           y >= iconY and y <= iconY + NETWORK_ICON_SIZE then
            self.networkManager:toggle()
            return
        end
         ]]
        -- Check app icons
        for i, app in ipairs(self.apps) do
            if x >= 10 + (i-1) * ICON_SPACING and x <= 10 + (i-1) * ICON_SPACING + ICON_SIZE and
               y >= 3 and y <= 3 + ICON_SIZE then
                self:launchApp(app)
                return
            end
        end
    end
--[[     -- Pass mouse events to the network manager if its menu is open
    if self.networkManager.isOpen then
        self.networkManager:mousepressed(x, y, button)
    end ]]
end

function StatusBar:keypressed(key)
  --[[   if self.networkManager.isOpen or self.networkManager.passwordPrompt then
        self.networkManager:keypressed(key)
    end ]]
end

function StatusBar:textinput(text)
   --[[  if self.networkManager.passwordPrompt then
        self.networkManager:textinput(text)
    end ]]
end

function StatusBar:update(dt)
    -- Update logic if needed
end

return StatusBar