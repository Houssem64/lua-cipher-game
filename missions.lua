-- missions.lua
local Missions = {
    config = {
        button_radius = 20,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.6, 0.4, 1},  -- Purple color for mission button
        panel_color = {1, 1, 1, 0.9},  -- Semi-transparent white
        text_color = {0, 0, 0},        -- Black text
    }
}
Missions.__index = Missions

function Missions.new(x, y, config)
    local self = setmetatable({}, Missions)
    
    -- Merge provided config with defaults
    self.config = setmetatable(config or {}, {__index = Missions.config})
    
    -- Initialize state using virtual resolution
    self.gameWidth = 1920
    self.gameHeight = 500
    
    -- Y offset for dynamic positioning
    self.y_offset = 250 or 0  -- Default to 0 if not provided
    
    -- Mission button properties
    self.button = {
        x = self.gameWidth - 60,  -- Position from right edge
        y = 120,  -- Below chat button
        width = 40,
        height = 40,
        radius = self.config.button_radius
    }
    
    -- Mission panel properties
    self.panel = {
        x = self.gameWidth,  -- Start off screen
        target_x = self.gameWidth - self.config.panel_width,
        y = self.y_offset,  -- Adjusted by y_offset
        width = self.config.panel_width,
        height = self.gameHeight,
        visible = false
    }
    
    -- Mission state
    self.missions = {}  -- Stores the list of missions
    
    return self
end

function Missions:update(dt)
    -- Update mission panel position
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, 
            self.panel.x - self.config.slide_speed * dt)
    else
        self.panel.x = math.min(self.gameWidth, 
            self.panel.x + self.config.slide_speed * dt)
    end
end

function Missions:draw()
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 18)  -- Size for 1080p
    font:setFilter("nearest", "nearest")  -- Set filter to nearest
    love.graphics.setFont(font)

    -- Draw mission button
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius)
        
    -- Draw "M" text on mission button
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("M", 
        self.button.x + 12, 
        self.button.y + 10)

    -- Draw mission panel
    if self.panel.x < self.gameWidth then
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height)
        
        -- Draw mission content
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Missions", 
            self.panel.x + 10, 
            self.panel.y + 10)
        
        -- Draw list of missions
        local mission_y = self.panel.y + 50
        for i, mission in ipairs(self.missions) do
            if mission.completed then
                love.graphics.setColor(0, 1, 0)  -- Green for completed missions
            else
                love.graphics.setColor(unpack(self.config.text_color))  -- Default color
            end
            love.graphics.print(mission.text, self.panel.x + 10, mission_y)
            mission_y = mission_y + 30
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(default_font)
end

function Missions:mousepressed(x, y)
    -- Check if mission button was clicked
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        return true
    end
    return false
end

function Missions:addMission(mission)
    table.insert(self.missions, { text = mission, completed = false })
end

function Missions:completeMission(index)
    if self.missions[index] then
        self.missions[index].completed = true
    end
end

return Missions