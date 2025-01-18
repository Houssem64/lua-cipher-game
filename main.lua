local Desktop = require("desktop")
local StatusBar = require("status_bar")
local WindowManager = require("window_manager")
local NetworkManager = require("modules.network_manager")

local desktop
local statusBar
local windowManager
local networkManager

function love.load()
    desktop = Desktop:new()
    windowManager = WindowManager:new()
    networkManager = NetworkManager:new()
    statusBar = StatusBar:new(networkManager)
    statusBar.windowManager = windowManager

    -- Initialize some sample networks
    networkManager:addNetwork("Home WiFi", 80, true)
    networkManager:addNetwork("Coffee Shop", 60, false)
    networkManager:addNetwork("Office Network", 100, true)
end

function love.update(dt)
    windowManager:update(dt)
    -- NetworkManager doesn't have an update function in the simplified version
end

function love.draw()
    desktop:draw()
    windowManager:draw()
    statusBar:draw()


    networkManager:draw(love.graphics.getWidth() - 200, 0)  -- Adjust position as needed

end

function love.keypressed(key)
    windowManager:keypressed(key)
    networkManager:keypressed(key)
end

function love.textinput(text)
    windowManager:textinput(text)
    networkManager:textinput(text)
end

function love.mousepressed(x, y, button)
    if y <= statusBar.height then
        -- Check if the click is on the network icon
        local networkIconX = love.graphics.getWidth() - 200  -- Adjust this value based on your icon's position
        local networkIconWidth = 20  -- Adjust this value based on your icon's width
        
        if x >= networkIconX and x <= networkIconX + networkIconWidth then
            networkManager:toggle()
        else
            statusBar:mousepressed(x, y, button)
        end
    elseif networkManager.isOpen then
        local menuX = love.graphics.getWidth() - 200
        local menuY = 0
        if x >= menuX and x <= love.graphics.getWidth() and y >= menuY and y <= menuY + networkManager.height then
            networkManager:mousepressed(x - menuX, y - menuY, button)
        else
            networkManager:toggle()  -- Close the menu if clicked outside
        end
    else
        windowManager:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    windowManager:mousereleased(x, y, button)
    -- NetworkManager doesn't use mousereleased in the simplified version
end

function love.mousemoved(x, y, dx, dy)
    windowManager:mousemoved(x, y, dx, dy)
    -- NetworkManager doesn't use mousemoved in the simplified version
end