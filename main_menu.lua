local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    
    -- Initialize main menu state
    self.isActive = true
    self.startClicked = false
    self.selectedOption = 1
    self.options = {"INITIATE HACK", "TERMINATE"}
    


    -- Load video logo
    self.videoLogo = love.graphics.newVideo("logo.ogv")
    self.videoLogo:play()
    
    -- Cyberpunk menu effects
    self.hoveredOption = nil
    self.selectedOption = 1
    self.hoverColor = {0, 1, 0, 1}  -- Matrix green
    self.normalColor = {0.2, 0.8, 0.2, 0.7}  -- Dimmed green
    self.selectedColor = {0, 1, 0.5, 1}  -- Bright cyan
    self.menuScale = 1.0
    self.hoverScale = 1.1
    self.glitchAmount = 0
    
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
    local font =  love.graphics.newFont("fonts/FiraCode.ttf",48)
    font:setFilter("nearest", "nearest", 1)
    love.graphics.setFont(font)
    if not self.isActive then return end
    
    -- Reset color for drawing elements
    love.graphics.setColor(1, 1, 1, 1)

    
    -- Draw video logo (centered on 1920x1080 virtual resolution)
    local videoWidth = self.videoLogo:getWidth()
    local videoHeight = self.videoLogo:getHeight()
    local scale = math.min(1920 / videoWidth, 1080 * 0.4 / videoHeight)  -- Scale to fit width and 40% of height
    love.graphics.draw(self.videoLogo, 
        (1920 - videoWidth * scale) / 2, 
        1080 * 0.1, 
        0, scale, scale)
    
    -- Draw menu options with enhanced visuals
    for i, option in ipairs(self.options) do
        local isHovered = (i == self.hoveredOption)
        local isSelected = (i == self.selectedOption)
        local optionWidth = font:getWidth(option)
        local optionX = (1920 - optionWidth) / 2
        local optionY = 1080 * 0.5 + (i-1) * 75
        
        -- Set scale based on hover/selection
        local scale = self.menuScale
        if isHovered then
            scale = self.hoverScale
        end
        
        -- Draw hover indicator with glitch effect
        if isHovered then
            love.graphics.setColor(self.hoverColor[1], self.hoverColor[2], self.hoverColor[3], 0.3)
            local glitchOffset = math.random(-2, 2) * self.glitchAmount
            love.graphics.rectangle('fill', 
                optionX - 20 + glitchOffset, 
                optionY, 
                optionWidth + 40, 
                font:getHeight())
        end

        
        -- Set text color based on state
        if isHovered then
            love.graphics.setColor(self.hoverColor)
        elseif isSelected then
            love.graphics.setColor(self.selectedColor)
        else
            love.graphics.setColor(self.normalColor)
        end
        
        -- Draw the option text with scaling
        love.graphics.push()
        love.graphics.translate(optionX + optionWidth/2, optionY + font:getHeight()/2)
        love.graphics.scale(scale, scale)
        love.graphics.print(option, -optionWidth/2, -font:getHeight()/2)
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
            -- Set startClicked flag when Start Game is selected
            self.startClicked = true
            self.transitioning = true
        elseif self.selectedOption == 3 then
            love.event.quit()
        end
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
                -- Set startClicked flag when Start Game is clicked
                self.startClicked = true
                self.transitioning = true
            elseif self.selectedOption == 3 then
                love.event.quit()
            end
            self.clickSound:play()

            return true
        end
    end
    
    return true
end

function MainMenu:mousemoved(x, y)
    if not self.isActive then return end
    
    -- Check if the mouse is hovering over a menu option
    local menuFont = love.graphics.newFont("fonts/FiraCode.ttf",48)
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