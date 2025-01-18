local Desktop = require("desktop")
local StatusBar = require("status_bar")
local WindowManager = require("window_manager")

local desktop
local statusBar
local windowManager

function love.load()
    desktop = Desktop:new()
    windowManager = WindowManager:new()
    statusBar = StatusBar:new()
    statusBar.windowManager = windowManager
end

function love.update(dt)
    windowManager:update(dt)
end

function love.draw()
    desktop:draw()
    windowManager:draw()
    statusBar:draw()
end

function love.mousepressed(x, y, button)
    if y <= statusBar.height then
        statusBar:mousepressed(x, y, button)
    else
        windowManager:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    windowManager:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    windowManager:mousemoved(x, y, dx, dy)
end

function love.textinput(text)
    windowManager:textinput(text)
end

function love.keypressed(key)
    windowManager:keypressed(key)
end