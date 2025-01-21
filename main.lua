local Desktop = require("desktop")
local StatusBar = require("status_bar")
local WindowManager = require("window_manager")
local NetworkManager = require("modules.network_manager")
--local debug = require('libraries.lovedebug')








local desktop
local statusBar
local windowManager
local networkManager

function love.load()

 -- Enable antialiasing
 love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
 -- Set up the font with a size that works well for 1080p
 --font = love.graphics.newFont(32)
 --love.graphics.setFont(font)
 
 -- Get the screen dimensions
 screenWidth = love.graphics.getWidth()
 screenHeight = love.graphics.getHeight()
 
 -- Set up virtual resolution scaling
 gameWidth = 1920
 gameHeight = 1080
 
 -- Calculate scaling factors
 scaleX = screenWidth / gameWidth
 scaleY = screenHeight / gameHeight
 scale = math.min(scaleX, scaleY)
 
 -- Calculate the offset to center the game window
 offsetX = (screenWidth - (gameWidth * scale)) / 2
 offsetY = (screenHeight - (gameHeight * scale)) / 2

  
 
    --love.window.setFullscreen(true, "exclusive")

    -- Initialize desktop, window manager, and status bar
   --[[  love.graphics.setDefaultFilter("nearest", "nearest") ]]
    desktop = Desktop:new()
    windowManager = WindowManager:new()
  --  networkManager = NetworkManager:new()
    statusBar = StatusBar:new(networkManager)
    statusBar.windowManager = windowManager

    -- Initialize some sample networks
  --[[   networkManager:addNetwork("Home WiFi", 80, true)
    networkManager:addNetwork("Coffee Shop", 60, false)
    networkManager:addNetwork("Office Network", 100, true) ]]
end

function love.update(dt)
    windowManager:update(dt)
    -- NetworkManager doesn't have an update function in the simplified version
end

--[[ font = love.graphics.newFont("rob.ttf",256)
font:setFilter("nearest", "nearest") ]]

function love.draw()
    
     -- Set up the coordinate system for 1080p
     love.graphics.push()
     love.graphics.translate(offsetX, offsetY)
     love.graphics.scale(scale, scale)
  
   windowManager:draw()
   statusBar:draw()

  

  

   -- networkManager:draw(love.graphics.getWidth() - 200, 0)  -- Adjust position as needed
   love.graphics.pop()
   
end

function love.keypressed(key)
    windowManager:keypressed(key)
--    networkManager:keypressed(key)
end

function love.textinput(text)
    windowManager:textinput(text)
  --  networkManager:textinput(text)
end

function love.mousepressed(x, y, button)
    -- Convert screen coordinates to game coordinates
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    if virtualY <= STATUSBAR_HEIGHT then
        statusBar:mousepressed(virtualX, virtualY, button)
    else
        windowManager:mousepressed(virtualX, virtualY, button)
    end
end

function love.mousereleased(x, y, button)
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    windowManager:mousereleased(virtualX, virtualY, button)
end

function love.mousemoved(x, y, dx, dy)
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    local virtualDX = dx / scale
    local virtualDY = dy / scale
    windowManager:mousemoved(virtualX, virtualY, virtualDX, virtualDY)
end