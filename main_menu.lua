local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    
    -- Initialize main menu state
    self.isActive = true
    self.selectedOption = 1
    self.options = {"Start Game", "Options", "Quit"}
    
    -- Load video logo
    self.videoLogo = love.graphics.newVideo("logo.ogv")
    self.videoLogo:play()
    
    -- Sway effect variables
    self.swayTime = 0
    self.swayAmplitude = 10  -- How far the text sways side-to-side
    self.swaySpeed = 2       -- Speed of the sway animation
    
    -- Hover effect variables
    self.hoveredOption = nil -- Track which option is hovered
    self.hoverColor = {0.1960, 0.80395, 0.1960, 1}  -- Orange color for hovered option
    
    -- Load click sound
    self.clickSound = love.audio.newSource("menuselect.wav", "static")  -- Replace "click.wav" with your sound file
    
    -- Transition variables
    self.transitioning = false  -- Whether a transition is happening
    self.transitionAlpha = 0    -- Alpha value for the transition overlay
    self.transitionSpeed = 2    -- Speed of the fade transition
    
    return self
end

function MainMenu:update(dt)
    if not self.isActive then return end
    
    -- Update sway effect time
    self.swayTime = self.swayTime + dt * self.swaySpeed
    
    -- Update transition
    if self.transitioning then
        self.transitionAlpha = self.transitionAlpha + dt * self.transitionSpeed
        if self.transitionAlpha >= 1 then
            -- Transition complete, switch to the game state
            self.isActive = false
            -- Here, you would typically switch to the game state
            -- For example: gamestate.switch(game)
        end
    end
end

function MainMenu:draw()
    local previousFont = love.graphics.getFont()
    local font =  love.graphics.newFont("joty.otf",48)
    font:setFilter("nearest", "nearest", 1)
    love.graphics.setFont(font)
    if not self.isActive then return end
    
    -- Draw a semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, 1920, 1080)  -- Use virtual game resolution
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw video logo (centered on 1920x1080 virtual resolution)
    local videoWidth = self.videoLogo:getWidth()
    local videoHeight = self.videoLogo:getHeight()
    local scale = math.min(1920 / videoWidth, 1080 * 0.4 / videoHeight)  -- Scale to fit width and 40% of height
    love.graphics.draw(self.videoLogo, 
        (1920 - videoWidth * scale) / 2, 
        1080 * 0.1, 
        0, scale, scale)
    
    -- Draw menu options
    for i, option in ipairs(self.options) do
        -- Calculate sway offset
        local swayOffset = math.sin(self.swayTime + i * 1.5) * self.swayAmplitude
        
        -- Check if the option is hovered
        local isHovered = (i == self.hoveredOption)
        
        -- Set color based on hover
        if isHovered then
            love.graphics.setColor(self.hoverColor)  -- Use hover color
        else
            love.graphics.setColor(1, 1, 1, 1)  -- Default color
        end
        
        -- Draw the option text
        love.graphics.push()
        love.graphics.translate(swayOffset, 0)
        local optionWidth = font:getWidth(option)
        love.graphics.print(option, 
            (1920 - optionWidth) / 2, 
            1080 * 0.5 + (i-1) * 75)  -- Increased vertical spacing
        love.graphics.pop()
    end
    
    -- Draw transition overlay (if transitioning)
    if self.transitioning then
        love.graphics.setColor(0, 0, 0, self.transitionAlpha)
        love.graphics.rectangle('fill', 0, 0, 1920, 1080)
    end
    
    love.graphics.setFont(previousFont)
end

function MainMenu:keypressed(key)
    if not self.isActive then return false end
    
    if key == "up" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then 
            self.selectedOption = #self.options 
        end
    elseif key == "down" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #self.options then 
            self.selectedOption = 1 
        end
    elseif key == "return" or key == "kpenter" then
        if self.selectedOption == 1 then
            -- Start game (begin transition)
            self.transitioning = true
        elseif self.selectedOption == 3 then
            -- Quit
            love.event.quit()
        end
        -- Play click sound
        self.clickSound:play()
    end
    
    return true
end

function MainMenu:mousepressed(x, y)
    if not self.isActive then return false end
    
    -- Check if a menu option was clicked
    local menuFont = love.graphics.newFont(48)
    for i, option in ipairs(self.options) do
        local optionWidth = menuFont:getWidth(option)
        local optionX = (1920 - optionWidth) / 2
        local optionY = 1080 * 0.5 + (i-1) * 75
        local optionHeight = menuFont:getHeight()
        
        if x >= optionX and x <= optionX + optionWidth and
           y >= optionY and y <= optionY + optionHeight then
            self.selectedOption = i
            if self.selectedOption == 1 then
                -- Start game (begin transition)
                self.transitioning = true
            elseif self.selectedOption == 3 then
                -- Quit
                love.event.quit()
            end
            -- Play click sound
            self.clickSound:play()
            return true
        end
    end
    
    return true
end

function MainMenu:mousemoved(x, y)
    if not self.isActive then return end
    
    -- Check if the mouse is hovering over a menu option
    local menuFont = love.graphics.newFont("joty.otf",48)
    self.hoveredOption = nil
    for i, option in ipairs(self.options) do
        local optionWidth = menuFont:getWidth(option)
        local optionX = (1920 - optionWidth) / 2
        local optionY = 1080 * 0.5 + (i-1) * 75
        local optionHeight = menuFont:getHeight()
        
        if x >= optionX and x <= optionX + optionWidth and
           y >= optionY and y <= optionY + optionHeight then
            self.hoveredOption = i
            break
        end
    end
end

return MainMenu