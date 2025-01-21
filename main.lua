local Desktop = require("desktop")
local StatusBar = require("status_bar")
local WindowManager = require("window_manager")
local NetworkManager = require("modules.network_manager")
--local debug = require('libraries.lovedebug')
local push = require ("libraries.push")







local desktop
local statusBar
local windowManager
local networkManager

function love.load()

    local gameWidth, gameHeight = 1280, 720 -- fixed game resolution
    local windowWidth, windowHeight = love.window.getDesktopDimensions()
    push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {        fullscreen = true,
    resizable = true,
    pixelperfect = true,
    stretched = true ,
    canvas= true,
    vsync = true,
    highdpi = true,
            msaa = 0               -- Add this line to disable antialiasing

})



  
 
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
    
   push:start()


   -- Draw your window and other elements here
   desktop:draw()
   windowManager:draw()
   statusBar:draw()

  

  

   -- networkManager:draw(love.graphics.getWidth() - 200, 0)  -- Adjust position as needed
  push:finish()
   
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
    local scaledX, scaledY = push:toGame(x, y)
    
    if scaledY <= statusBar.height then
        statusBar:mousepressed(scaledX, scaledY, button)
    else
        windowManager:mousepressed(scaledX, scaledY, button)
    end
end

function love.mousereleased(x, y, button)
    local scaledX, scaledY = push:toGame(x, y)
    windowManager:mousereleased(scaledX, scaledY, button)
end

function love.mousemoved(x, y, dx, dy)
    local scaledX, scaledY = push:toGame(x, y)
    local scaledDX, scaledDY = push:toGame(dx, dy)
    windowManager:mousemoved(scaledX, scaledY, scaledDX, scaledDY)
end

function love.resize(w, h)
    push:resize(w, h)
    -- Update the game's internal resolution to match the new window size
    local newWidth, newHeight = push:getWidth(), push:getHeight()
    desktop:resize(newWidth, newHeight)
    windowManager:resize(newWidth, newHeight)
    statusBar:resize(newWidth, newHeight)
end