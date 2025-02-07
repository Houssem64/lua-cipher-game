-- Base resolution constants
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080
local STATUSBAR_HEIGHT = 40

local Desktop = require("desktop")
local StatusBar = require("status_bar")
local WindowManager = require("window_manager")
local NetworkManager = require("modules.network_manager")
local FileSystem = require("filesystem")
local Chat = require 'chat'
local Missions = require("missions")
local MissionsManager = require("missions_manager")
local StoryMissions = require("story_missions")
local MainMenu = require("main_menu")
local MusicApp = require("apps.music_app")

local ReelsApp = require("apps.reelsapp")
local MissionsApp = require("apps.missions_app")
local desktop

local statusBar
local windowManager
local networkManager
local mainMenu  -- Add this line to declare mainMenu globally
local musicApp  -- Add this line to declare musicApp globally
local webBrowser

function love.load()
    -- Enable key repeat for proper input handling
    love.keyboard.setKeyRepeat(true)

    FileSystem:loadState() 
--[[     effect = moonshine(moonshine.effects.filmgrain)
    .chain(moonshine.effects.vignette)
effect.filmgrain.size = 2
 ]]

    -- Initialize main menu first
    mainMenu = MainMenu.new()
    
    love.graphics.setDefaultFilter("nearest", "nearest", 1)


 

    chat = Chat.new(nil, nil, {
        button_color = {0.3, 0.7, 0.9},
        panel_width = 350
    })

    chat:setMessageCallback(function(message)
        chat:addMessage("I received: " .. message)
    end)

    -- Rest of the existing load function remains the same...
    _G.missions = Missions.new(0, 0)
    _G.missionsManager = MissionsManager.new()

    -- Get desktop dimensions for dynamic scaling
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
    screenWidth = desktopWidth
    screenHeight = desktopHeight
    
    -- Set up virtual resolution (target: BASE_WIDTH x BASE_HEIGHT)
    gameWidth = BASE_WIDTH
    gameHeight = BASE_HEIGHT
    
    -- Calculate integer scaling factors for crisp rendering
    scaleX = screenWidth / gameWidth
    scaleY = screenHeight / gameHeight
    scale = math.min(scaleX, scaleY)
    
    -- Ensure scale is an integer for pixel-perfect rendering
    scale = math.floor(scale)
    if scale < 1 then scale = 1 end
    
    -- Calculate the offset to center the game window
    offsetX = math.floor((screenWidth - (gameWidth * scale)) / 2)
    offsetY = math.floor((screenHeight - (gameHeight * scale)) / 2)

-- Initialize mission systems
_G.missions = Missions.new(0, 0)
_G.missionsManager = MissionsManager.new()

-- Load all story missions
for _, missionData in ipairs(StoryMissions.getAllMissions()) do
    _G.missionsManager:addMission(missionData)
end

-- Initialize missions app with tutorial selected
local missionsApp = MissionsApp.new()

--[[ -- Sync missions with display and select tutorial
for _, mission in ipairs(_G.missionsManager:getMissions()) do
    local formattedSubtasks = {}
    for _, subtask in ipairs(mission.subtasks) do
        table.insert(formattedSubtasks, {
            text = subtask.text,
            completed = subtask.completed
        })
    end
    
    -- Add mission to display with proper selection state
    _G.missions:addMission({
        id = mission.id,
        text = mission.text,
        description = mission.description,
        subtasks = formattedSubtasks,
        completed = mission.completed,
        progress = mission.progress,
        subtaskProgress = mission.completedSubtasks and (mission.completedSubtasks / #mission.subtasks) or 0,
        selected = (mission.id == 1)  -- Select tutorial mission
    })
end ]]



-- Debug print mission state
print("Missions initialized:")
print("Panel visible:", _G.missions.panel.visible)
if _G.missions:getMissionById(1) then
    print("Tutorial mission selected:", _G.missions:getMissionById(1).selected)
end


--[[ -- Set progress after syncing
missionsManager:updateProgress(1, 1, true) -- Complete first subtask
missionsManager:updateProgress(1, 2, false) -- Second subtask in progress
missionsManager:completeMission(2)
missionsManager:updateProgress(3, 1, true) -- Complete first subtask
 ]]


    musicApp = MusicApp.new()  -- Create a new instance of MusicApp
    reelsApp = ReelsApp.new()  -- Create a new instance of ReelsApp
    desktop = Desktop:new()

    -- Initialize window manager globally
    _G.windowManager = WindowManager:new()
    windowManager = _G.windowManager  -- Keep local reference
    statusBar = StatusBar:new(networkManager)
    statusBar.windowManager = windowManager
end

function love.update(dt)
    -- Update main menu first
    mainMenu:update(dt)
    
    -- Only update other components if main menu is not active
    if not mainMenu.isActive then
        windowManager:update(dt)
        chat:update(dt)
        _G.missions:update(dt)
        musicApp:update(dt)  -- Update MusicApp
        reelsApp:update(dt)  -- Update ReelsApp
    end


end


function love.draw()
    -- Clear the screen with black bars
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(1, 1, 1)
    
    -- Apply scaling and centering
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    -- Draw game components only if main menu is not active
    if not mainMenu.isActive then
        windowManager:draw()
        statusBar:draw()
        reelsApp:draw()
        musicApp:draw(0, 0, gameWidth, gameHeight)
        chat:draw()
        _G.missions:draw()
      
    end


    -- Always draw main menu (it will handle its own visibility)
    mainMenu:draw()

    love.graphics.pop()
end

function love.keypressed(key)
    -- Always check main menu first
    if mainMenu:keypressed(key) then
        return  -- If main menu handled the key, don't process other inputs
    end
    
    windowManager:keypressed(key)
    chat:keypressed(key)

    if key == "c" then
        -- Get the active mission window from missions manager
        if _G.missionsManager then
            local missionApp = _G.missionsManager:getActiveMissionWindow()
            if missionApp and missionApp.selectedMission then
                -- Complete the first incomplete subtask
                local mission = missionApp.missions[missionApp.selectedMission]
                if mission then
                    for i = 1, #mission.subtasks do
                        if not (missionApp.completedSubtasks[missionApp.selectedMission] and 
                               missionApp.completedSubtasks[missionApp.selectedMission][i]) then
                            missionApp:toggleSubtaskComplete(missionApp.selectedMission, i)
                            break
                        end
                    end
                end
            end
        end
    end


    musicApp:keypressed(key)  -- Pass key events to MusicApp
    reelsApp:keypressed(key)  -- Pass key events to ReelsApp


end

function love.textinput(text)
    -- Only process text input if main menu is not active
    if not mainMenu.isActive then
        if text == "/" then
            print("Main textinput received /") -- Debug print
        end
        windowManager:textinput(text)
        chat:textinput(text)
    end

end

function love.mousepressed(x, y, button)
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    -- Always check main menu first
    if mainMenu:mousepressed(virtualX, virtualY) then
        return  -- If main menu handled the mouse press, don't process other inputs
    end
    
    if not mainMenu.isActive then
        if virtualY <= STATUSBAR_HEIGHT then
            statusBar:mousepressed(virtualX, virtualY, button)
        else
            windowManager:mousepressed(virtualX, virtualY, button)
        end
        chat:mousepressed(virtualX, virtualY)
        _G.missions:mousepressed(virtualX, virtualY)
        musicApp:mousepressed(virtualX, virtualY, button)  -- Pass mouse events to MusicApp
        reelsApp:mousepressed(virtualX, virtualY, button)  -- Pass mouse events to ReelsApp
    end

    
end

function love.mousereleased(x, y, button)
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    windowManager:mousereleased(virtualX, virtualY, button)
end

function love.mousemoved(x, y, dx, dy)
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    local virtualDX = dx / scale
    local virtualDY = dy / scale
    windowManager:mousemoved(virtualX, virtualY, virtualDX, virtualDY)
    mainMenu:mousemoved(virtualX, virtualY)
end