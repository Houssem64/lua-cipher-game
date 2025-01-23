local Chat = {
    config = {
        button_radius = 20,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.4, 0.6, 1},
        panel_color = {1, 1, 1, 0.9},
        text_color = {0, 0, 0},
        avatar_width = 100,
        avatar_height = 150,
    }
}
Chat.__index = Chat



function Chat.new(x, y, config)
    local self = setmetatable({}, Chat)
    
    -- Merge provided config with defaults
    self.config = setmetatable(config or {}, {__index = Chat.config})
    
    -- Initialize state using virtual resolution
    self.gameWidth = 1920
    self.gameHeight = 500
    
    -- Y offset for dynamic positioning
    self.y_offset = 200 or 0  -- Default to 0 if not provided
    
    -- Button properties (positioned relative to virtual resolution)
    self.button = {
        x = self.gameWidth - 60,  -- Position from right edge
        y =  60,  -- Below status bar, adjusted by y_offset
        width = 40,
        height = 40,
        radius = self.config.button_radius
    }
    
    -- Chat panel properties
    self.panel = {
        x = self.gameWidth,  -- Start off screen
        target_x = self.gameWidth - self.config.panel_width,
        y = self.y_offset,  -- Adjusted by y_offset
        width = self.config.panel_width,
        height = self.gameHeight,
        visible = false
    }
    
    -- Chat state
    self.messages = {}  -- Stores the latest player message and AI response
    self.input_text = ""  -- Current input text
    self.callback = nil  -- Callback for sending messages
    
    -- Avatar state
    self.avatar = {
        state = "idle",  -- Current state (idle, thinking, talking, happy, sad)
        timer = 0,  -- Timer for animations
        blink_timer = 0,  -- Timer for blinking
        mouth_open = false,  -- For talking animation
    }
    
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
    
    -- Update avatar animations
    self.avatar.timer = self.avatar.timer + dt
    self.avatar.blink_timer = self.avatar.blink_timer + dt
    
    -- Blinking animation
    if self.avatar.blink_timer > 3 then
        self.avatar.blink_timer = 0
    end
    
    -- Talking animation
    if self.avatar.state == "talking" then
        if self.avatar.timer > 0.2 then
            self.avatar.timer = 0
            self.avatar.mouth_open = not self.avatar.mouth_open
        end
    end
end

function Chat:drawAvatar(x, y)
    local head_radius = 40
    local eye_radius = 5
    local mouth_width = 30
    local mouth_height = 10
    
    -- Draw head
    love.graphics.setColor(1, 0.8, 0.6)  -- Skin color
    love.graphics.circle("fill", x, y, head_radius)
    
    -- Draw eyes
    love.graphics.setColor(0, 0, 0)  -- Black for eyes
    local eye_offset = 15
    local eye_y = y - 15
    love.graphics.circle("fill", x - eye_offset, eye_y, eye_radius)
    love.graphics.circle("fill", x + eye_offset, eye_y, eye_radius)
    
    -- Blinking animation
    if self.avatar.blink_timer > 2.8 then
        love.graphics.setColor(1, 0.8, 0.6)  -- Skin color to "close" eyes
        love.graphics.rectangle("fill", x - eye_offset - eye_radius, eye_y - eye_radius, eye_radius * 2, eye_radius * 2)
        love.graphics.rectangle("fill", x + eye_offset - eye_radius, eye_y - eye_radius, eye_radius * 2, eye_radius * 2)
    end
    
    -- Draw mouth based on state
    if self.avatar.state == "idle" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.arc("line", "open", x, y + 10, mouth_width / 2, 0, math.pi)
    elseif self.avatar.state == "talking" then
        love.graphics.setColor(0, 0, 0)
        if self.avatar.mouth_open then
            love.graphics.rectangle("fill", x - mouth_width / 2, y + 10, mouth_width, mouth_height)
        else
            love.graphics.arc("line", "open", x, y + 10, mouth_width / 2, 0, math.pi)
        end
    elseif self.avatar.state == "happy" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.arc("line", "open", x, y + 10, mouth_width / 2, 0.2, math.pi - 0.2)
    elseif self.avatar.state == "sad" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.arc("line", "open", x, y + 20, mouth_width / 2, math.pi + 0.2, 2 * math.pi - 0.2)
    elseif self.avatar.state == "thinking" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", x, y + 15, 3)
        love.graphics.circle("fill", x - 10, y + 20, 3)
        love.graphics.circle("fill", x + 10, y + 20, 3)
    end
end

function Chat:draw()
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 18)  -- Size for 1080p
    font:setFilter("nearest", "nearest")  -- Set filter to nearest
    love.graphics.setFont(font)

    -- Draw chat button
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius)
        
    -- Draw AI text on button
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AI", 
        self.button.x + 7, 
        self.button.y + 10)

    if self.panel.x < self.gameWidth then
        -- Draw chat panel
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height)
        
        -- Draw animated avatar at the top of the chat panel
        local avatar_x = self.panel.x + (self.panel.width) / 2
        local avatar_y = self.panel.y + 100
        self:drawAvatar(avatar_x, avatar_y)
        
        -- Draw messages (only the latest player message and AI response)
        love.graphics.setColor(unpack(self.config.text_color))
        local message_y = self.panel.y + 200
        for i, msg in ipairs(self.messages) do
            love.graphics.print(msg, self.panel.x + 10, message_y)
            message_y = message_y + 30
        end
        
        -- Draw input box at bottom
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('line', 
            self.panel.x + 10, 
            self.panel.y + self.panel.height - 40, 
            self.panel.width - 20, 
            30)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.input_text, 
            self.panel.x + 15, 
            self.panel.y + self.panel.height - 35)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(default_font)
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
        
        -- Keep only the latest player message and AI response
        if #self.messages > 2 then
            table.remove(self.messages, 1)  -- Remove the oldest message
        end
        
        -- Set avatar state to "talking"
        self.avatar.state = "talking"
        
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
    -- Add AI response
    table.insert(self.messages, (from or "AI") .. ": " .. text)
    
    -- Keep only the latest player message and AI response
    if #self.messages > 2 then
        table.remove(self.messages, 1)  -- Remove the oldest message
    end
    
    -- Set avatar state based on the AI response
    if text:lower():find("happy") then
        self.avatar.state = "happy"
    elseif text:lower():find("sad") then
        self.avatar.state = "sad"
    else
        self.avatar.state = "idle"
    end
end

function Chat:setMessageCallback(callback)
    self.callback = callback
end

return Chat