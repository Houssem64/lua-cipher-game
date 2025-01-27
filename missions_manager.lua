local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    self.missions = {}
    return self
end

function MissionsManager:addMission(mission)
    table.insert(self.missions, {
        text = mission.text or mission,
        description = mission.description or "",
        progress = 0,
        completed = false,
        reward = mission.reward,
        requirements = mission.requirements or {}
    })
    return #self.missions
end

function MissionsManager:updateProgress(index, progress)
    if self.missions[index] then
        self.missions[index].progress = math.min(1, math.max(0, progress))
        if self.missions[index].progress >= 1 then
            self.missions[index].completed = true
        end
    end
end

function MissionsManager:completeMission(index)
    if self.missions[index] then
        self.missions[index].completed = true
        self.missions[index].progress = 1
    end
end

function MissionsManager:getMissions()
    return self.missions
end

function MissionsManager:getMission(index)
    return self.missions[index]
end

function MissionsManager:removeMission(index)
    if self.missions[index] then
        table.remove(self.missions, index)
    end
end

function MissionsManager:getActiveMissions()
    local active = {}
    for _, mission in ipairs(self.missions) do
        if not mission.completed then
            table.insert(active, mission)
        end
    end
    return active
end

function MissionsManager:getCompletedMissions()
    local completed = {}
    for _, mission in ipairs(self.missions) do
        if mission.completed then
            table.insert(completed, mission)
        end
    end
    return completed
end

return MissionsManager