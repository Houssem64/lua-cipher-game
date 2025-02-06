-- story_missions.lua
local StoryMissions = {
	missions = {
		{
			id = 1,
			text = "Terminal Basics Tutorial",
			description = "Master the essential terminal commands to become proficient in system navigation and file management. Each task will teach you a fundamental terminal operation.",
			reward = "Terminal Master Badge",
			subtasks = {
				"Use 'pwd' to check your current working directory location",
				"Try 'neofetch' to view detailed system information and ASCII art",
				"Use 'whoami' to check your current user",
				"Create a new directory named 'tutorial' using 'mkdir tutorial'",
				"Navigate into the directory with 'cd tutorial'",
				"Create a test file using 'touch test.txt'",
				"List directory contents with 'ls' to verify your file",
				"Try 'sudo whoami' to see elevated privileges (password: kali)",
				"Use 'help' to explore all available commands"
			}
		},
		{
			id = 2,
			text = "Collect 10 coins",
			description = "Find and collect 10 gold coins",
			reward = "100 XP",
			subtasks = {
				"Find the coin map",
				"Reach the treasure room", 
				"Collect all coins",
				"test"
			}
		},
		{
			id = 3,
			text = "test",
			description = "test",
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