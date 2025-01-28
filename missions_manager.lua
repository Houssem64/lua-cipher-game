local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    self.missions = {}
    return self
end

function MissionsManager:addMission(mission)
    local newMission = {
        id = mission.id,
        text = mission.text or mission,
        description = mission.description or "",
        completed = false,
        reward = mission.reward,
        requirements = mission.requirements or {},
        subtasks = {},
        completedSubtasks = 0
    }
    
    -- Initialize subtasks as objects with text and completed state
    for i, subtask in ipairs(mission.subtasks or {}) do
        newMission.subtasks[i] = {
            text = type(subtask) == "table" and subtask.text or subtask,
            completed = type(subtask) == "table" and subtask.completed or false
        }
    end
    
    table.insert(self.missions, newMission)
    return newMission.id
end

function MissionsManager:updateProgress(id, subtaskIndex, complete)
    local mission = nil
    local index = nil
    
    -- Find mission by ID
    for i, m in ipairs(self.missions) do
        if m.id == id then
            mission = m
            index = i
            break
        end
    end
    
    if mission and mission.subtasks[subtaskIndex] then
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

function MissionsManager:completeMission(id)
    for _, mission in ipairs(self.missions) do
        if mission.id == id then
            mission.completed = true
            mission.progress = 1
            break
        end
    end
end

function MissionsManager:getMissions()
    return self.missions
end

function MissionsManager:getMission(id)
    for _, mission in ipairs(self.missions) do
        if mission.id == id then
            return mission
        end
    end
    return nil
end

function MissionsManager:removeMission(id)
    for i, mission in ipairs(self.missions) do
        if mission.id == id then
            table.remove(self.missions, i)
            break
        end
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

function MissionsManager:getSubtasks(id)
    local mission = self:getMission(id)
    if mission then
        return mission.subtasks
    end
    return {}
end

function MissionsManager:getSubtaskProgress(id)
    local mission = self:getMission(id)
    if mission then
        return mission.completedSubtasks / #mission.subtasks
    end
    return 0
end

function MissionsManager:isSubtaskCompleted(missionId, subtaskIndex)
    local mission = self:getMission(missionId)
    if mission and mission.subtasks[subtaskIndex] then
        return mission.subtasks[subtaskIndex].completed
    end
    return false
end

return MissionsManager