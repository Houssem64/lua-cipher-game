local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    self.missions = {}
    return self
end

function MissionsManager:addMission(mission)
    local newMission = {
        text = mission.text or mission,
        description = mission.description or "",
        completed = false,
        reward = mission.reward,
        requirements = mission.requirements or {},
        subtasks = mission.subtasks or {},
        completedSubtasks = 0
    }
    
    -- Initialize subtasks if provided
    for i, subtask in ipairs(newMission.subtasks) do
        newMission.subtasks[i] = {
            text = subtask,
            completed = false
        }
    end
    
    table.insert(self.missions, newMission)
    return #self.missions
end

function MissionsManager:updateProgress(index, subtaskIndex, complete)
    if self.missions[index] and self.missions[index].subtasks[subtaskIndex] then
        local mission = self.missions[index]
        
        -- Set subtask completion state
        mission.subtasks[subtaskIndex].completed = complete
        
        -- Recalculate completed subtasks count
        mission.completedSubtasks = 0
        for _, subtask in ipairs(mission.subtasks) do
            if subtask.completed then
                mission.completedSubtasks = mission.completedSubtasks + 1
            end
        end
        
        -- Update progress
        mission.progress = mission.completedSubtasks / #mission.subtasks
        
        -- Check if all subtasks are completed
        if mission.completedSubtasks == #mission.subtasks then
            mission.completed = true
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

function MissionsManager:getSubtasks(index)
    if self.missions[index] then
        return self.missions[index].subtasks
    end
    return {}
end

function MissionsManager:getSubtaskProgress(index)
    if self.missions[index] then
        local mission = self.missions[index]
        return mission.completedSubtasks / #mission.subtasks
    end
    return 0
end

function MissionsManager:isSubtaskCompleted(missionIndex, subtaskIndex)
    if self.missions[missionIndex] and self.missions[missionIndex].subtasks[subtaskIndex] then
        return self.missions[missionIndex].subtasks[subtaskIndex].completed
    end
    return false
end


return MissionsManager