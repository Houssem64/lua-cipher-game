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
    
    return self
end

function MainMenu:update(dt)
    if not self.isActive then return end
    
    -- Update video logo
   
end

function MainMenu:draw()
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
    local menuFont = love.graphics.newFont(48)  -- Slightly larger menu font
    love.graphics.setFont(menuFont)
    
    for i, option in ipairs(self.options) do
        if i == self.selectedOption then
            love.graphics.setColor(1, 1, 0, 1)  -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        local optionWidth = menuFont:getWidth(option)
        love.graphics.print(option, 
            (1920 - optionWidth) / 2, 
            1080 * 0.5 + (i-1) * 75)  -- Increased vertical spacing
    end
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
            -- Start game
            self.isActive = false
        elseif self.selectedOption == 3 then
            -- Quit
            love.event.quit()
        end
    end
    
    return true
end

function MainMenu:mousepressed(x, y)
    if not self.isActive then return false end
    
    -- Optional: Add mouse selection logic here if desired
    return true
end

return MainMenu