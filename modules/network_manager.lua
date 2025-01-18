local NetworkManager = {}

function NetworkManager:new()
    local obj = {
        networks = {},
        connectedNetwork = nil,
        isOpen = false,
        x = 0,
        y = 0,
        width = 200,
        height = 150,
        passwordPrompt = false,
        currentPasswordInput = "",
        selectedNetwork = nil
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function NetworkManager:addNetwork(name, strength, secured)
    table.insert(self.networks, {
        name = name,
        strength = strength,
        secured = secured,
        connected = false
    })
end

function NetworkManager:connectToNetwork(network)
    if network.secured and not self.passwordPrompt then
        self.passwordPrompt = true
        self.selectedNetwork = network
        self.currentPasswordInput = ""
    elseif not network.secured then
        self:finalizeConnection(network)
    end
end

function NetworkManager:finalizeConnection(network)
    if self.connectedNetwork then
        self.connectedNetwork.connected = false
    end
    network.connected = true
    self.connectedNetwork = network
    self.passwordPrompt = false
    self.selectedNetwork = nil
    self.currentPasswordInput = ""
    print("Connected to " .. network.name)
end

function NetworkManager:draw(x, y)
    -- Draw network icon in status bar
    love.graphics.setColor(1, 1, 1)
    local iconSize = 15
    love.graphics.rectangle("line", x, y + 5, iconSize, iconSize)

    -- Draw network menu if open
    if self.isOpen then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", x, y + 25, self.width, self.height)

        love.graphics.setColor(1, 1, 1)
        for i, network in ipairs(self.networks) do
            local yPos = y + 30 + (i-1) * 25
            love.graphics.print(network.name, x + 25, yPos)
            local barCount = math.floor(network.strength / 20)
            for j = 1, barCount do
                love.graphics.rectangle("fill", x + 150 + (j-1)*5, yPos + 10, 3, -j*2)
            end
            if network.secured then
                love.graphics.circle("fill", x + 180, yPos + 5, 2)
            end
            if network.connected then
                love.graphics.print("✓", x + 10, yPos)
            end
        end

        if self.passwordPrompt then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.95)
            love.graphics.rectangle("fill", x, y + self.height, self.width, 70)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Enter password for " .. self.selectedNetwork.name, x + 10, y + self.height + 10)
            love.graphics.rectangle("line", x + 10, y + self.height + 30, 180, 20)
            love.graphics.print(string.rep("*", #self.currentPasswordInput), x + 15, y + self.height + 33)
        end
    end
end

function NetworkManager:toggle()
    self.isOpen = not self.isOpen
    if not self.isOpen then
        self.passwordPrompt = false
        self.selectedNetwork = nil
        self.currentPasswordInput = ""
    end
end

function NetworkManager:mousepressed(x, y, button)
    if self.isOpen and button == 1 then
        for i, network in ipairs(self.networks) do
            local yPos = self.y + 30 + (i-1) * 25
            if x >= self.x and x <= self.x + self.width and y >= yPos and y <= yPos + 20 then
                self:connectToNetwork(network)
                return
            end
        end
    end
end

function NetworkManager:mousereleased(x, y, button)
    -- Not needed for this simplified version
end

function NetworkManager:keypressed(key)
    if self.passwordPrompt then
        if key == "return" then
            self:finalizeConnection(self.selectedNetwork)
        elseif key == "escape" then
            self.passwordPrompt = false
            self.selectedNetwork = nil
            self.currentPasswordInput = ""
        elseif key == "backspace" then
            self.currentPasswordInput = self.currentPasswordInput:sub(1, -2)
        end
    end
end

function NetworkManager:textinput(text)
    if self.passwordPrompt then
        self.currentPasswordInput = self.currentPasswordInput .. text
    end
end

return NetworkManager