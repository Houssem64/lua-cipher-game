local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    
    -- Initialize mission list
    self.missions = {}
    
    return self
end

function MissionsManager:addMission(mission)
    table.insert(self.missions, mission)
end

function MissionsManager:completeMission(index)
    if self.missions[index] then
        table.remove(self.missions, index)
    end
end

function MissionsManager:getMissions()
    return self.missions
end

return MissionsManager