local SaveSystem = require("modules/save_system")
local Ranks = require("modules/ranks")

local MissionsManager = {}
MissionsManager.__index = MissionsManager

function MissionsManager.new()
    local self = setmetatable({}, MissionsManager)
    self.missions = {}
    
    -- Load saved mission progress and ELO
    local savedProgress = SaveSystem:load("mission_progress") or {}
    self.savedState = savedProgress
    self.elo = savedProgress.elo or 0  -- Start with base ELO of 0
    self.currentRank = Ranks:getRankByELO(self.elo)

    
    return self
end

function MissionsManager:saveMissionState()
    local progress = {
        completed = {},
        subtasks = {},
        elo = self.elo
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
        completedSubtasks = 0,
        selected = (mission.id == 1)  -- Select tutorial mission by default
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
        
        -- Update missions display
        if _G.missions then
            _G.missions.panel.visible = true
            
            -- Play subtask completion sound if not already completed
            if wasNotCompleted and _G.missions.completion_sound then
                local sound = _G.missions.completion_sound:clone()
                if sound then
                    sound:setPitch(1.2)
                    sound:setVolume(0.3)
                    sound:play()
                end
            end
            
            -- If mission was just completed, play completion sound and show notification
            if mission.completed and wasNotCompleted then
                if _G.missions.completion_sound then
                    _G.missions.completion_sound:stop()
                    _G.missions.completion_sound:play()
                end
                _G.missions:startNotification()
            end
            
            -- Clear missions and add only the current mission
            _G.missions.missions = {}
            
            local formattedSubtasks = {}
            for i, subtask in ipairs(mission.subtasks) do
                table.insert(formattedSubtasks, {
                    text = subtask.text,
                    completed = subtask.completed
                })
            end
            
            _G.missions:addMission({
                id = mission.id,
                text = mission.text,
                description = mission.description,
                subtasks = formattedSubtasks,
                completed = mission.completed,
                progress = mission.progress,
                subtaskProgress = mission.completedSubtasks / #mission.subtasks,
                selected = true
            })
            
            -- Ensure the mission is selected in the missions app
            local missionWindow = self:getActiveMissionWindow()
            if missionWindow then
                missionWindow.selectedMission = index
            end
        end
        
        -- Save state after update
        self:saveMissionState()
        
        return wasNotCompleted and complete
    end
    return false
end


function MissionsManager:addELO(amount)
    local oldRank = self.currentRank
    self.elo = self.elo + amount
    self.currentRank = Ranks:getRankByELO(self.elo)
    
    -- Check for rank up
    if oldRank and oldRank.name ~= self.currentRank.name then
        if _G.missions then
            _G.missions:startRankUpNotification(self.currentRank.name)
        end
    end
    
    self:saveMissionState()
    return self.currentRank
end

function MissionsManager:getCurrentRank()
    return self.currentRank
end

function MissionsManager:getELO()
    return self.elo
end

function MissionsManager:getRankProgress()
    return Ranks:getProgress(self.elo)
end

function MissionsManager:checkRankRequirement(requiredRank)
    -- Ensure we have a valid currentRank
    if not self.currentRank then
        self.currentRank = Ranks:getRankByELO(self.elo or 0)
    end
    
    local currentRankELO = self.currentRank.elo_required or 0
    local requiredRankELO = 0
    
    for _, rank in ipairs(Ranks.ranks) do
        if rank.name == requiredRank then
            requiredRankELO = rank.elo_required
            break
        end
    end
    
    return currentRankELO >= requiredRankELO
end

function MissionsManager:completeMission(id)
    for _, mission in ipairs(self.missions) do
        if mission.id == id and not mission.completed then
            mission.completed = true
            mission.progress = 1
            -- Complete all subtasks
            for _, subtask in ipairs(mission.subtasks) do
                subtask.completed = true
            end
            mission.completedSubtasks = #mission.subtasks
            
            -- Add ELO reward
            if mission.reward and mission.reward.elo then
                self:addELO(mission.reward.elo)
            else
                -- Default ELO reward if none specified
                self:addELO(25)  -- Default ELO gain per mission
            end
            
            -- Play completion sound and show notification
            if _G.missions then
                if _G.missions.completion_sound then
                    _G.missions.completion_sound:stop()
                    _G.missions.completion_sound:play()
                end
                _G.missions:startNotification()
            end
            
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
        mission.selected = (mission.id == 1)  -- Select tutorial mission
        
        -- Reset all subtasks
        for _, subtask in ipairs(mission.subtasks) do
            subtask.completed = false
        end
    end
    
    -- Reset missions in active window if exists
    local missionWindow = self:getActiveMissionWindow()
    if missionWindow then
        missionWindow:resetMissions()
        -- Re-select tutorial mission
        missionWindow:selectMission(1)
        print("MissionsManager:resetAllMissions - Reset complete, tutorial mission selected")
    end
    
    -- Update missions display
    if _G.missions then
        _G.missions.missions = {}
        _G.missions.panel.visible = true
        
        -- Re-add all missions with proper states
        for _, m in ipairs(self.missions) do
            local formattedSubtasks = {}
            for _, subtask in ipairs(m.subtasks) do
                table.insert(formattedSubtasks, {
                    text = subtask.text,
                    completed = subtask.completed
                })
            end
            
            _G.missions:addMission({
                id = m.id,
                text = m.text,
                description = m.description,
                subtasks = formattedSubtasks,
                completed = m.completed,
                progress = m.progress,
                subtaskProgress = m.completedSubtasks / #m.subtasks,
                selected = (m.id == 1)  -- Select tutorial mission
            })
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
        mission.subtaskProgress = mission.progress -- Add subtask progress tracking
        
        -- If all subtasks are complete and mission wasn't already completed, complete it with ELO reward
        if completedCount == #mission.subtasks and not mission.completed then
            mission.completed = true
            -- Add ELO reward
            if mission.reward and mission.reward.elo then
                self:addELO(mission.reward.elo)
            else
                -- Default ELO reward if none specified
                self:addELO(25)  -- Default ELO gain per mission
            end
        end
        
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

function MissionsManager:getActiveMissionWindow()
    -- First check active window
    if _G.windowManager and _G.windowManager.activeWindow and 
       _G.windowManager.activeWindow.title == "Missions" then
        local app = _G.windowManager.activeWindow.app
        if app then
            print("MissionsManager:getActiveMissionWindow - Found active window")
            print("Selected mission:", app.selectedMission)
            return app
        end
    end
    
    -- Then check all windows
    if _G.windowManager then
        for _, window in ipairs(_G.windowManager.windows) do
            if window.app and window.title == "Missions" then
                local app = window.app
                if app then
                    print("MissionsManager:getActiveMissionWindow - Found window in list")
                    print("Selected mission:", app.selectedMission)
                    return app
                end
            end
        end
    end
    
    print("MissionsManager:getActiveMissionWindow - No mission window found")
    return nil
end


function MissionsManager:handleWindowClose(window)
    if window.title == "Missions" then
        -- Preserve mission state when window is closed
        local missionApp = window.app
        if missionApp and missionApp.selectedMission then
            -- Store both the index and ID
            self.lastSelectedMissionIndex = missionApp.selectedMission
            self.lastSelectedMissionId = missionApp.missions[missionApp.selectedMission].id
        end
    end
end

function MissionsManager:restoreWindowState(window)
    if window.title == "Missions" and self.lastSelectedMissionIndex then
        -- Restore mission selection when window is reopened
        local missionApp = window.app
        if missionApp then
            missionApp:selectMission(self.lastSelectedMissionIndex)
        end
    end
end

return MissionsManager