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
    
    -- Available commands with subcommands
    self.commands = {
        help = {
            desc = "Show available commands",
            subcommands = {
                "network - Network penetration basics",
                "encryption - Encryption and decryption guides",
                "exploits - Common system vulnerabilities",
                "security - System security fundamentals",
                "tools - Available hacking tools",
                "forensics - Digital forensics basics"
            }
        },
        scan = {
            desc = "Scan for vulnerabilities",
            subcommands = {}
        },
        exploit = {
            desc = "Run exploit tools",
            subcommands = {}
        },
        decrypt = {
            desc = "Decrypt secured data",
            subcommands = {}
        },
        clear = {
            desc = "Clear chat history",
            subcommands = {}
        },
        save = {
            desc = "Save chat history",
            subcommands = {}
        }
    }
    
    -- Dropdown menu state
    self.dropdown = {
        visible = false,
        selected_command = nil,
        showing_subcommands = false
    }
    
    -- Additional chat features
    self.emoji_mode = false
    self.text_colors = {
        default = {0, 0, 0},
        blue = {0, 0, 1},
        red = {1, 0, 0},
        green = {0, 1, 0}
    }
    self.current_text_color = "default"
    
    -- Initialize state using virtual resolution
    self.gameWidth = 1920
    self.gameHeight = 500
    
    -- Y offset for dynamic positioning
    self.y_offset = 250 or 0  -- Default to 0 if not provided
    
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
    
    -- Siri animation state
    self.siri = {
        state = "idle",  -- Current state (idle, thinking, talking, happy, sad)
        timer = 0,  -- Timer for animations
        radius = 30,  -- Base radius
        wave_offset = 0,  -- Wave animation offset
        particles = {},  -- Particles for animation
        color = {0.4, 0.6, 1, 0.9}  -- Siri orb color
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
    
    -- Update Siri animations
    self.siri.timer = self.siri.timer + dt
    self.siri.wave_offset = self.siri.wave_offset + dt * 2
    
    -- Update particle animations based on state
    if self.siri.state == "talking" then
        -- Create wave effect
        self.siri.radius = 30 + math.sin(self.siri.timer * 5) * 5
    elseif self.siri.state == "thinking" then
        -- Pulsing effect
        self.siri.radius = 30 + math.sin(self.siri.timer * 2) * 3
    elseif self.siri.state == "happy" then
        -- Expand slightly
        self.siri.radius = 35
    elseif self.siri.state == "sad" then
        -- Contract slightly
        self.siri.radius = 25
    else
        -- Gentle idle animation
        self.siri.radius = 30 + math.sin(self.siri.timer) * 2
    end
end

function Chat:drawSiri(x, y)
    -- Draw main orb
    love.graphics.setColor(unpack(self.siri.color))
    love.graphics.circle('fill', x, y, self.siri.radius)
    
    -- Draw wave effect
    if self.siri.state == "talking" then
        for i = 1, 3 do
            local wave_radius = self.siri.radius + (i * 10)
            local alpha = 0.3 - (i * 0.1)
            love.graphics.setColor(self.siri.color[1], self.siri.color[2], self.siri.color[3], alpha)
            love.graphics.circle('line', x, y, wave_radius + math.sin(self.siri.wave_offset + i) * 3)
        end
    end
    
    -- Draw thinking animation
    if self.siri.state == "thinking" then
        for i = 1, 3 do
            local angle = self.siri.timer * 2 + (i * math.pi / 1.5)
            local dot_x = x + math.cos(angle) * (self.siri.radius + 10)
            local dot_y = y + math.sin(angle) * (self.siri.radius + 10)
            love.graphics.circle('fill', dot_x, dot_y, 3)
        end
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
        
        -- Draw animated Siri orb at the top of the chat panel
        local siri_x = self.panel.x + (self.panel.width) / 2
        local siri_y = self.panel.y + 100
        self:drawSiri(siri_x, siri_y)
        
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
            
        -- Draw command dropdown if visible
        if self.dropdown.visible then
            local dropdown_y = self.panel.y + self.panel.height - 70
            love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
            
            if self.dropdown.showing_subcommands and self.dropdown.selected_command then
                -- Draw subcommands for selected command
                local subcommands = self.commands[self.dropdown.selected_command].subcommands
                local height = #subcommands * 25 + 10
                love.graphics.rectangle('fill',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                    
                love.graphics.setColor(0, 0, 0)
                for i, subcmd in ipairs(subcommands) do
                    love.graphics.print(subcmd,
                        self.panel.x + 15,
                        dropdown_y - height + (i-1)*25 + 5)
                end
            else
                -- Draw main commands
                local height = #self.commands * 25 + 10
                love.graphics.rectangle('fill',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                    
                love.graphics.setColor(0, 0, 0)
                local i = 1
                for cmd, data in pairs(self.commands) do
                    love.graphics.print("/" .. cmd .. " - " .. data.desc,
                        self.panel.x + 15,
                        dropdown_y - height + (i-1)*25 + 5)
                    i = i + 1
                end
            end
        end
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
    
    if key == "/" and self.input_text == "" then
        -- Show command dropdown
        self.dropdown.visible = true
        self.dropdown.showing_subcommands = false
        self.dropdown.selected_command = nil
        self.input_text = "/"
        return true
    elseif key == "tab" and self.input_text:sub(1,1) == "/" then
        -- Command auto-completion
        local partial = self.input_text:sub(2)
        for cmd, data in pairs(self.commands) do
            if cmd:sub(1, #partial) == partial then
                self.input_text = "/" .. cmd .. " "
                -- Show subcommands if available
                if #data.subcommands > 0 then
                    self.dropdown.visible = true
                    self.dropdown.showing_subcommands = true
                    self.dropdown.selected_command = cmd
                end
                return true
            end
        end
    elseif key == "return" and self.input_text ~= "" then
        -- Process commands
        if self.input_text:sub(1,1) == "/" then
            local cmd = self.input_text:match("^/(%w+)")
            if cmd == "emoji" then
                self.emoji_mode = not self.emoji_mode
                table.insert(self.messages, "System: Emoji mode " .. (self.emoji_mode and "enabled" or "disabled"))
            elseif cmd == "color" then
                local color = self.input_text:match("^/color%s+(%w+)")
                if self.text_colors[color] then
                    self.current_text_color = color
                    table.insert(self.messages, "System: Text color changed to " .. color)
                end
            elseif cmd == "mood" then
                local mood = self.input_text:match("^/mood%s+(%w+)")
                if mood then
                    self.avatar.state = mood
                    table.insert(self.messages, "System: AI mood changed to " .. mood)
                end
            else
                -- Add user message
                table.insert(self.messages, "You: " .. self.input_text)
                
                -- Call message callback if set
                if self.callback then
                    self.callback(self.input_text)
                end
            end
        else
            -- Add user message
            table.insert(self.messages, "You: " .. self.input_text)
            
            -- Call message callback if set
            if self.callback then
                self.callback(self.input_text)
            end
        end
        
        -- Clear input
        self.input_text = ""
        
        -- Keep only the latest player message and AI response
        if #self.messages > 2 then
            table.remove(self.messages, 1)  -- Remove the oldest message
        end
        
        -- Set Siri state to "talking"
        self.siri.state = "talking"
        
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
    -- Process emojis if emoji mode is on
    if self.emoji_mode then
        text = text:gsub(":happy:", "😊")
               :gsub(":sad:", "😢")
               :gsub(":laugh:", "😄")
               :gsub(":heart:", "❤️")
    end
    
    -- Add AI response with timestamp
    local timestamp = os.date("%H:%M")
    local message = string.format("[%s] %s: %s", timestamp, from or "AI", text)
    table.insert(self.messages, message)
    
    -- Keep last 5 messages instead of just 2
    while #self.messages > 5 do
        table.remove(self.messages, 1)
    end
    
    -- Set Siri state based on the AI response
    if text:lower():find("happy") or text:lower():find("😊") then
        self.siri.state = "happy"
    elseif text:lower():find("sad") or text:lower():find("😢") then
        self.siri.state = "sad"
    elseif text:lower():find("think") then
        self.siri.state = "thinking"
    else
        self.siri.state = "idle"
    end
end

function Chat:setMessageCallback(callback)
    self.callback = callback
end

return Chat