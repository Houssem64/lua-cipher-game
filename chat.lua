local Chat = {
    config = {
        button_radius = 15,
        panel_width = 400, -- Increased panel width
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
    
    -- Enable key repeat for proper input handling
    love.keyboard.setKeyRepeat(true)
    
    -- Merge provided config with defaults
    self.config = setmetatable(config or {}, {__index = Chat.config})
    
    -- Available commands with subcommands and responses
    self.commands = {
        help = {
            desc = "Show available commands",
            response = "I'm here to assist you with various hacking and security tasks. Here are the available topics:",
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
            response = "Initiating system scan for potential vulnerabilities. This may take a few moments...",
            subcommands = {}
        },
        exploit = {
            desc = "Run exploit tools",
            response = "Preparing exploit toolkit. Please specify your target and desired exploit method.",
            subcommands = {}
        },
        decrypt = {
            desc = "Decrypt secured data",
            response = "Ready to decrypt data. Please provide the encrypted content and any known encryption parameters.",
            subcommands = {}
        },
        clear = {
            desc = "Clear chat history",
            response = "Chat history has been cleared.",
            subcommands = {}
        },
        save = {
            desc = "Save chat history",
            response = "Chat history has been saved successfully.",
            subcommands = {}
        }
    }
    
    -- Initialize dropdown state
    self.dropdown = {
        visible = false,
        selected_command = nil,
        showing_subcommands = false,
        y_offset = 0,
        initialized = true  -- Add flag to track initialization
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
        x = self.gameWidth - 250,  -- Position from right edge
        y =  5,  -- Below status bar, adjusted by y_offset
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
    
    -- Typing animation state
    self.typing = {
        active = false,
        full_text = "",
        current_text = "",
        word_index = 1,
        words = {},
        timer = 0,
        speed = 0.05  -- Time between words
    }
    
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

    -- Update typing animation (letter by letter)
    if self.typing.active then
        self.typing.timer = self.typing.timer + dt
        if self.typing.timer >= self.typing.speed then
            self.typing.timer = 0
            local next_char_pos = #self.typing.current_text + 1
            if next_char_pos <= #self.typing.full_text then
                self.typing.current_text = self.typing.full_text:sub(1, next_char_pos)
                
                -- Update the last message with current text
                if #self.messages > 0 then
                    local timestamp = os.date("%H:%M")
                    self.messages[#self.messages] = string.format("[%s] AI: %s", timestamp, self.typing.current_text)
                end
            else
                self.typing.active = false
                self.siri.state = "idle"
            end
        end
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
    local font = love.graphics.newFont("fonts/FiraCode.ttf", 18)
    font:setFilter("nearest", "nearest")
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
        self.button.x+4 , 
        self.button.y+2 )

    if self.panel.x < self.gameWidth then
        -- Draw chat panel background
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height)
        
        -- Draw animated Siri orb
        local siri_x = self.panel.x + (self.panel.width) / 2
        local siri_y = self.panel.y + 100
        self:drawSiri(siri_x, siri_y)
        
        -- Draw messages
        love.graphics.setColor(unpack(self.config.text_color))
        local message_y = self.panel.y + 200
        for i, msg in ipairs(self.messages) do
            love.graphics.print(msg, self.panel.x + 10, message_y)
            message_y = message_y + 30
        end
        
        -- Draw input box
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.rectangle('fill', 
            self.panel.x + 10, 
            self.panel.y + self.panel.height - 40, 
            self.panel.width - 20, 
            30)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('line', 
            self.panel.x + 10, 
            self.panel.y + self.panel.height - 40, 
            self.panel.width - 20, 
            30)
        
        love.graphics.print(self.input_text, 
            self.panel.x + 15, 
            self.panel.y + self.panel.height - 35)
            
        -- Draw command dropdown if visible
        if self.dropdown and self.dropdown.visible then
            print("Drawing dropdown") -- Debug print
            local dropdown_y = self.panel.y + self.panel.height - 80
            
            -- Draw semi-transparent background behind dropdown
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle('fill',
                self.panel.x,
                0,
                self.panel.width,
                self.gameHeight)
            
            -- Draw dropdown
            love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
            
            if self.dropdown.showing_subcommands and self.dropdown.selected_command then
                local subcommands = self.commands[self.dropdown.selected_command].subcommands
                local height = #subcommands * 30 + 10
                
                -- Draw dropdown background with border
                love.graphics.rectangle('fill',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle('line',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                    
                -- Draw subcommands
                love.graphics.setColor(1, 1, 1)
                for i, subcmd in ipairs(subcommands) do
                    love.graphics.print(subcmd,
                        self.panel.x + 15,
                        dropdown_y - height + (i-1)*30 + 5)
                end
            else
                -- Count commands
                local count = 0
                for _ in pairs(self.commands) do count = count + 1 end
                local height = count * 30 + 10
                
                -- Draw dropdown background with border
                love.graphics.rectangle('fill',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle('line',
                    self.panel.x + 10,
                    dropdown_y - height,
                    self.panel.width - 20,
                    height)
                    
                -- Draw commands
                love.graphics.setColor(1, 1, 1)
                local i = 1
                for cmd, data in pairs(self.commands) do
                    love.graphics.print("/" .. cmd .. " - " .. data.desc,
                        self.panel.x + 15,
                        dropdown_y - height + (i-1)*30 + 5)
                    i = i + 1
                end
            end
        end
    end
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(default_font)
end

function Chat:isSlashPressed()
    return love.keyboard.isDown('slash') or love.keyboard.isDown('/')
end

function Chat:mousepressed(x, y)
    -- Check if chat button was clicked
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        self:hideDropdown() -- Use the hideDropdown function
        return true
    end
    
    -- Handle dropdown clicks if visible
    if self.panel.visible and self.dropdown.visible then
        local dropdown_y = self.panel.y + self.panel.height - 80 + self.dropdown.y_offset
        
        -- Check if click is outside dropdown area
        local count = 0
        for _ in pairs(self.commands) do count = count + 1 end
        local height = self.dropdown.showing_subcommands and 
            (#self.commands[self.dropdown.selected_command].subcommands * 30 + 10) or
            (count * 30 + 10)
            
        if x < self.panel.x + 10 or x > self.panel.x + self.panel.width - 10 or
           y < dropdown_y - height or y > dropdown_y then
            self:hideDropdown()
            return true
        end
        
        if self.dropdown.showing_subcommands and self.dropdown.selected_command then
            -- Handle subcommand clicks
            local subcommands = self.commands[self.dropdown.selected_command].subcommands
            local item_idx = math.floor((y - (dropdown_y - height)) / 30) + 1
            if item_idx <= #subcommands then
                local subcmd = subcommands[item_idx]:match("^([^%s]+)")
                self.input_text = "/" .. self.dropdown.selected_command .. " " .. subcmd
                self:hideDropdown()
                return true
            end
        else
            -- Handle main command clicks
            local item_idx = math.floor((y - (dropdown_y - height)) / 30) + 1
            local i = 1
            for cmd, data in pairs(self.commands) do
                if i == item_idx then
                    self.input_text = "/" .. cmd .. " "
                    if #data.subcommands > 0 then
                        self.dropdown.showing_subcommands = true
                        self.dropdown.selected_command = cmd
                    else
                        self:hideDropdown()
                    end
                    return true
                end
                i = i + 1
            end
        end
    end
    return false
end


function Chat:keypressed(key, scancode, isrepeat)
    if not self.panel.visible then return false end
    
    self:ensureDropdownState()  -- Ensure dropdown state exists
    
    if scancode == "slash" then
        -- Show command dropdown
        print("Slash key pressed") -- Debug print
        self.input_text = "/"
        self.dropdown.visible = true
        self.dropdown.showing_subcommands = false
        self.dropdown.selected_command = nil
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
                else
                    self.dropdown.visible = false
                end
                return true
            end
        end
    elseif key == "backspace" then
        if #self.input_text > 0 then
            self.input_text = self.input_text:sub(1, -2)
            -- Show/hide dropdown based on input
            if self.input_text == "/" then
                self.dropdown.visible = true
                self.dropdown.showing_subcommands = false
                self.dropdown.selected_command = nil
            elseif self.input_text == "" then
                self:hideDropdown()
            end
            return true
        end
    elseif key == "return" then
        -- Process commands
        if self.input_text:sub(1,1) == "/" then
            local cmd = self.input_text:match("^/(%w+)")
            if self.commands[cmd] and self.commands[cmd].response then
                -- Add AI response with typing animation
                self:addMessage(self.commands[cmd].response)
            end
        end

        
        -- Clear input and hide dropdown
        self.input_text = ""
        self.dropdown.visible = false
        
        -- Keep only the latest player message and AI response
        if #self.messages > 2 then
            table.remove(self.messages, 1)
        end
        
        -- Set Siri state to "talking"
        self.siri.state = "talking"
        
        return true
    end
    return false
end


function Chat:textinput(text)
    if not self.panel.visible then return false end
    
    self:ensureDropdownState()  -- Ensure dropdown state exists
    
    -- Handle "/" input
    if text == "/" then
        print("Showing dropdown") -- Debug print
        self.input_text = "/"
        self.dropdown.visible = true
        self.dropdown.showing_subcommands = false
        self.dropdown.selected_command = nil
        return true
    end
    
    -- Handle other text input
    self.input_text = self.input_text .. text
    
    -- Show/hide dropdown based on input
    if self.input_text:sub(1,1) == "/" then
        self.dropdown.visible = true
    else
        self:hideDropdown()
    end
    
    return true
end



function Chat:ensureDropdownState()
    if not self.dropdown or not self.dropdown.initialized then
        self.dropdown = {
            visible = false,
            selected_command = nil,
            showing_subcommands = false,
            y_offset = 0,
            initialized = true
        }
    end
end

function Chat:hideDropdown()
    self.dropdown.visible = false
    self.dropdown.showing_subcommands = false
    self.dropdown.selected_command = nil
end

function Chat:addMessage(text, from)
    -- Process emojis if emoji mode is on
    if self.emoji_mode then
        text = text:gsub(":happy:", "😊")
               :gsub(":sad:", "😢")
               :gsub(":laugh:", "😄")
               :gsub(":heart:", "❤️")
    end
    
    if from then
        -- Add user message immediately
        local timestamp = os.date("%H:%M")
        local message = string.format("[%s] %s: %s", timestamp, from, text)
        table.insert(self.messages, message)
        
        -- If it's a command, get the response
        if text:sub(1,1) == "/" then
            local cmd = text:match("^/(%w+)")
            if self.commands[cmd] and self.commands[cmd].response then
                -- Add AI response with typing animation
                self:addMessage(self.commands[cmd].response)
            end
        end
    else
        -- Start typing animation for AI response
        local timestamp = os.date("%H:%M")
        table.insert(self.messages, string.format("[%s] AI: ", timestamp))
        
        self.typing.full_text = text
        self.typing.current_text = ""
        self.typing.timer = 0
        self.typing.active = true
        self.typing.speed = 0.03  -- Faster speed for letter-by-letter typing
        self.siri.state = "talking"
    end
    
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
    -- Wrap the callback to handle responses
    self.callback = function(text)
        -- Get command response if it's a command
        if text:sub(1,1) == "/" then
            local cmd = text:match("^/(%w+)")
            if self.commands[cmd] and self.commands[cmd].response then
                self:addMessage(self.commands[cmd].response)
                return
            end
        end
        -- For non-commands, add typing animation response
        self:addMessage("I am processing your request...")
    end
end

return Chat