local SaveSystem = require("modules/save_system")

local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    self.missions = {}
    
    -- Load saved mission progress
    local savedProgress = SaveSystem:load("mission_progress") or {}
    self.savedState = savedProgress
    
    return self
end

function MissionsManager:saveMissionState()
    local progress = {
        completed = {},
        subtasks = {}
    }
    
    -- Save mission completion states
    for _, mission in ipairs(self.missions) do
        if mission.completed then
            progress.completed[tostring(mission.id)] = true
        end
        
        -- Save subtask states
        if mission.subtasks then
            progress.subtasks[tostring(mission.id)] = {}
            for i, subtask in ipairs(mission.subtasks) do
                if subtask.completed then
                    progress.subtasks[tostring(mission.id)][tostring(i)] = true
                end
            end
        end
    end
    
    -- Save to file
    SaveSystem:save(progress, "mission_progress")
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
    
    -- Apply saved state if exists
    if self.savedState then
        -- Apply mission completion
        newMission.completed = self.savedState.completed and self.savedState.completed[tostring(mission.id)] or false
        
        -- Apply subtask completion
        if self.savedState.subtasks and self.savedState.subtasks[tostring(mission.id)] then
            for i, subtask in ipairs(newMission.subtasks) do
                subtask.completed = self.savedState.subtasks[tostring(mission.id)][tostring(i)] or false
            end
        end
        
        -- Calculate progress
        local completedCount = 0
        for _, subtask in ipairs(newMission.subtasks) do
            if subtask.completed then
                completedCount = completedCount + 1
            end
        end
        newMission.progress = completedCount / #newMission.subtasks
        newMission.completedSubtasks = completedCount
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
        local wasNotCompleted = not mission.subtasks[subtaskIndex].completed
        
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
        
        -- Save state after update
        self:saveMissionState()
        
        -- Return if a task was newly completed
        return wasNotCompleted and complete
    end
    return false
end

function MissionsManager:completeMission(id)
    for _, mission in ipairs(self.missions) do
        if mission.id == id then
            mission.completed = true
            mission.progress = 1
            -- Complete all subtasks
            for _, subtask in ipairs(mission.subtasks) do
                subtask.completed = true
            end
            mission.completedSubtasks = #mission.subtasks
            
            -- Save state after completion
            self:saveMissionState()
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

function MissionsManager:resetAllMissions()
    -- Reset all missions and subtasks
    for _, mission in ipairs(self.missions) do
        mission.completed = false
        mission.progress = 0
        mission.completedSubtasks = 0
        
        -- Reset all subtasks
        for _, subtask in ipairs(mission.subtasks) do
            subtask.completed = false
        end
    end
    
    -- Save the reset state
    self:saveMissionState()
end

function MissionsManager:toggleSubtaskComplete(missionId, subtaskIndex)
    local mission = self:getMission(missionId)
    if mission and mission.subtasks[subtaskIndex] then
        -- Toggle subtask completion
        mission.subtasks[subtaskIndex].completed = not mission.subtasks[subtaskIndex].completed
        
        -- Update progress
        local completedCount = 0
        for _, subtask in ipairs(mission.subtasks) do
            if subtask.completed then
                completedCount = completedCount + 1
            end
        end
        
        mission.completedSubtasks = completedCount
        mission.progress = completedCount / #mission.subtasks
        mission.completed = completedCount == #mission.subtasks
        
        -- Save state after update
        self:saveMissionState()
        return mission.subtasks[subtaskIndex].completed
    end
    return false
end

function MissionsManager:resetMission(missionId)
    local mission = self:getMission(missionId)
    if mission then
        -- Reset mission state
        mission.completed = false
        mission.progress = 0
        mission.completedSubtasks = 0
        
        -- Reset all subtasks
        for _, subtask in ipairs(mission.subtasks) do
            subtask.completed = false
        end
        
        -- Save state after reset
        self:saveMissionState()
        return true
    end
    return false
end

return MissionsManager