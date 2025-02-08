-- story_missions.lua
local StoryMissions = {
	missions = {
		{
			id = 1,
			text = "Terminal Basics Tutorial",
			description = "Master the essential terminal commands to become proficient in system navigation and file management. Each task will teach you a fundamental terminal operation.",
			reward = {
				badge = "Terminal Master Badge",
				elo = 25
			},
			rank_required = "Script Kiddie",
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
			text = "File Detective",
			description = "Learn advanced file manipulation and search techniques. Master the art of finding and analyzing file contents.",
			reward = {
				badge = "File Operations Expert Badge",
				elo = 35
			},
			rank_required = "Initiate",
			subtasks = {
				"Create a file named 'secret.txt' with some text using 'echo'",
				"Use 'cat secret.txt' to view the file contents",
				"Create another file named 'data.txt'",
				"Use 'grep' to search for text in your files",
				"Try 'find' to locate files in the current directory",
				"Change file permissions using 'chmod'",
				"Practice file manipulation skills"
			}
		},
		{
			id = 3,
			text = "Network Navigator",
			description = "Learn essential networking commands and understand basic network operations.",
			reward = {
				badge = "Network Explorer Badge",
				elo = 45
			},
			rank_required = "Apprentice",
			subtasks = {
				"Test network connectivity using 'ping localhost'",
				"Connect to an FTP server using 'ftp'",
				"Download a file using FTP 'get' command",
				"Upload a file using FTP 'put' command",
				"List FTP server contents using 'ls'",
				"Successfully close the FTP connection"
			}
		},
		{
			id = 4,
			text = "System Administrator",
			description = "Master system administration tasks and elevated privileges operations.",
			reward = {
				badge = "Admin Rights Badge",
				elo = 55
			},
			rank_required = "Hacker",
			subtasks = {
				"Use 'sudo' to run commands as superuser",
				"Create a new directory with restricted permissions",
				"Modify file ownership and permissions",
				"View system information with 'neofetch'",
				"Practice secure file operations"
			}
		},
		{
			id = 5,
			text = "Text Editor Master",
			description = "Learn to create and edit files using various text manipulation commands and the nano editor.",
			reward = {
				badge = "Text Editor Expert Badge",
				elo = 65
			},
			rank_required = "Elite Hacker",
			subtasks = {
				"Create a new file named 'notes.txt' using 'echo Hello > notes.txt'",
				"View the file contents using 'cat notes.txt'",
				"Open notes.txt in nano using 'nano notes.txt'",
				"Add more text and save using Ctrl+O",
				"Exit nano using Ctrl+X",
				"Create another file using echo with multiple lines",
				"Practice file editing with nano's navigation controls"
			}
		}
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