-- story_missions.lua
local StoryMissions = {
	missions = {
		{
			id = 1,
			text = "Collect 10 coins",
			description = "Find and collect 10 gold coins",
			reward = "100 XP",
			subtasks = {
				"Find the coin map",
				"Reach the treasure room", 
				"Collect all coins",
                "test"
			}
		}
		-- Add more missions here with incrementing IDs
	}
}

function StoryMissions.getMissionById(id)
	for _, mission in ipairs(StoryMissions.missions) do
		if mission.id == id then
			return mission
		end
	end
	return nil
end

function StoryMissions.getAllMissions()
	return StoryMissions.missions
end

return StoryMissions