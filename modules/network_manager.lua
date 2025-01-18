local NetworkManager = {}

function NetworkManager:new()
    local obj = {
        networks = {
            { name = "WiFi-1", strength = 80, secured = true },
            { name = "WiFi-2", strength = 60, secured = true },
            { name = "OpenNet", strength = 40, secured = false }
        },
        isOpen = false,
        x = 0,
        y = 0,
        width = 200,
        height = 150
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function NetworkManager:draw(x, y)
    -- Draw network icon in status bar
    love.graphics.setColor(1, 1, 1)
    -- Simple network icon
    local iconSize = 15
    love.graphics.rectangle("line", x, y + 5, iconSize, iconSize)
    
    -- Draw network menu if open
    if self.isOpen then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", x, y + 25, self.width, self.height)
        
        love.graphics.setColor(1, 1, 1)
        for i, network in ipairs(self.networks) do
            local yPos = y + 30 + (i-1) * 25
            -- Draw WiFi strength icon
            love.graphics.print(network.name, x + 25, yPos)
            -- Draw signal strength bars
            local barCount = math.floor(network.strength / 20)
            for j = 1, barCount do
                love.graphics.rectangle("fill", x + 150 + (j-1)*5, yPos + 10, 3, -j*2)
            end
            -- Draw lock icon if secured
            if network.secured then
                love.graphics.circle("fill", x + 180, yPos + 5, 2)
            end
        end
    end
end

function NetworkManager:toggle()
    self.isOpen = not self.isOpen
end

return NetworkManager 