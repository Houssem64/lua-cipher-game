-- missions.lua
local Missions = {
    config = {
        button_radius = 20,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.6, 0.4, 1},
        panel_color = {0.95, 0.95, 0.98, 0.95},  -- Lighter background
        text_color = {0.2, 0.2, 0.2},
        panel_border_color = {0.8, 0.8, 0.85},
        panel_radius = 15,
        mission_height = 60,
        mission_padding = 15,
        hover_color = {0.97, 0.97, 1, 0.95},
        progress_bar_color = {0.6, 0.4, 1, 0.8},
        progress_bg_color = {0.9, 0.9, 0.9},
        completed_color = {0.4, 0.8, 0.4},
        header_size = 24,
        mission_size = 18,
        M_size = 18
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
    local header_font = love.graphics.newFont("joty.otf", self.config.header_size)
    local mission_font = love.graphics.newFont("joty.otf", self.config.mission_size)
    local text_size = love.graphics.newFont("joty.otf", self.config.M_size)
    header_font:setFilter("nearest", "nearest")
    mission_font:setFilter("nearest", "nearest")

    -- Draw mission button with glow effect
    love.graphics.setColor(self.config.button_color[1], self.config.button_color[2], 
        self.config.button_color[3], 0.3)
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius + 4)
    
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius)
    
    -- Draw "M" text with shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.print("M", 
        self.button.x + 13, 
        self.button.y + 11)
    love.graphics.setColor(1, 1, 1)
    
    love.graphics.setFont(text_size)
    love.graphics.print("M", 
        self.button.x + 12, 
        self.button.y + 10)

    -- Draw mission panel
    if self.panel.x < self.gameWidth then
        -- Panel background with rounded corners
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
            
        -- Panel border
        love.graphics.setColor(unpack(self.config.panel_border_color))
        love.graphics.rectangle('line', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
        
        -- Header
        love.graphics.setFont(header_font)
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Missions", 
            self.panel.x + 20, 
            self.panel.y + 20)
        
        -- Draw missions list
        love.graphics.setFont(mission_font)
        local mission_y = self.panel.y + 80
        
        for i, mission in ipairs(self.missions) do
            -- Mission background (with hover effect)
            local hover = love.mouse.getY() >= mission_y and 
                         love.mouse.getY() <= mission_y + self.config.mission_height
            
            if hover then
                love.graphics.setColor(unpack(self.config.hover_color))
            else
                love.graphics.setColor(1, 1, 1, 0.5)
            end
            
            love.graphics.rectangle('fill',
                self.panel.x + 10,
                mission_y,
                self.panel.width - 20,
                self.config.mission_height,
                8)
            
            -- Progress bar
            love.graphics.setColor(unpack(self.config.progress_bg_color))
            love.graphics.rectangle('fill',
                self.panel.x + 20,
                mission_y + self.config.mission_height - 12,
                self.panel.width - 40,
                4,
                2)
                
            if mission.completed then
                love.graphics.setColor(unpack(self.config.completed_color))
                love.graphics.rectangle('fill',
                    self.panel.x + 20,
                    mission_y + self.config.mission_height - 12,
                    self.panel.width - 40,
                    4,
                    2)
            else
                love.graphics.setColor(unpack(self.config.progress_bar_color))
                love.graphics.rectangle('fill',
                    self.panel.x + 20,
                    mission_y + self.config.mission_height - 12,
                    (self.panel.width - 40) * (mission.progress or 0),
                    4,
                    2)
            end
            
            -- Mission text
            if mission.completed then
                love.graphics.setColor(unpack(self.config.completed_color))
            else
                love.graphics.setColor(unpack(self.config.text_color))
            end
            
            love.graphics.print(mission.text,
                self.panel.x + 25,
                mission_y + self.config.mission_padding)
                
            mission_y = mission_y + self.config.mission_height + 10
        end
    end
    
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