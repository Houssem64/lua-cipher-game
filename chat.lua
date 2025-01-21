-- chat.lua
local Chat = {
    -- Default configuration
    config = {
        button_radius = 20,
        panel_width = 350,
        slide_speed = 1000,
        button_color = {0.4, 0.6, 1},
        panel_color = {1, 1, 1, 0.9},
        text_color = {0, 0, 0},
    }
}
Chat.__index = Chat

function Chat.new(x, y, config)
    local self = setmetatable({}, Chat)
    
    -- Merge provided config with defaults
    self.config = setmetatable(config or {}, {__index = Chat.config})
    
    -- Initialize state using virtual resolution
    self.gameWidth = 1920
    self.gameHeight = 1080
    
    -- Button properties (positioned relative to virtual resolution)
    self.button = {
        x = self.gameWidth - 60,  -- Position from right edge
        y = 60,  -- Below status bar
        width = 40,
        height = 40,
        radius = self.config.button_radius
    }
    
    -- Chat panel properties
    self.panel = {
        x = self.gameWidth,  -- Start off screen
        target_x = self.gameWidth - self.config.panel_width,
        y = 0,
        width = self.config.panel_width,
        height = self.gameHeight,
        visible = false
    }
    
    -- Chat state
    self.messages = {}
    self.input_text = ""
    self.callback = nil
    
    return self
end

function Chat:update(dt)
    if self.panel.visible then
        -- Slide in
        self.panel.x = math.max(self.panel.target_x, 
            self.panel.x - self.config.slide_speed * dt)
    else
        -- Slide out
        self.panel.x = math.min(self.gameWidth, 
            self.panel.x + self.config.slide_speed * dt)
    end
end

function Chat:draw()
    -- Draw chat button
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius)
        
    -- Draw AI text on button
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AI", 
        self.button.x + 15, 
        self.button.y + 15)

    if self.panel.x < self.gameWidth then
        -- Draw chat panel
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height)
        
        -- Draw messages
        love.graphics.setColor(unpack(self.config.text_color))
        for i, msg in ipairs(self.messages) do
            love.graphics.print(msg, self.panel.x + 10, 30 * i + 10)
        end
        
        -- Draw input box at bottom
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('line', 
            self.panel.x + 10, 
            self.gameHeight - 40, 
            self.panel.width - 20, 
            30)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.input_text, 
            self.panel.x + 15, 
            self.gameHeight - 35)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Chat:mousepressed(x, y)
    -- Check if chat button was clicked using virtual coordinates
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        return true
    end
    return false
end

function Chat:keypressed(key)
    if not self.panel.visible then return false end
    
    if key == "return" and self.input_text ~= "" then
        -- Add user message
        table.insert(self.messages, "You: " .. self.input_text)
        
        -- Call message callback if set
        if self.callback then
            self.callback(self.input_text)
        end
        
        -- Clear input
        self.input_text = ""
        return true
    elseif key == "backspace" then
        self.input_text = self.input_text:sub(1, -2)
        return true
    end
    return false
end

function Chat:textinput(text)
    if self.panel.visible then
        self.input_text = self.input_text .. text
        return true
    end
    return false
end

function Chat:addMessage(text, from)
    table.insert(self.messages, (from or "AI") .. ": " .. text)
end

function Chat:setMessageCallback(callback)
    self.callback = callback
end

return Chat