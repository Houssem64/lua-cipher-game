local SearchItems = {
	{
		title = "How to Make Games with LÖVE",
		url = "search:tutorial",
		keywords = {"tutorial", "games", "development"},
		description = "Learn game development with LÖVE framework. Step-by-step tutorials for beginners.",
		results = {
			{
				title = "Getting Started Tutorial",
				description = "Basic concepts and your first game window",
				url = "https://love2d.org/wiki/Getting_Started"
			},
			{
				title = "Making Your First Game",
				description = "Create a simple 2D game from scratch",
				url = "https://love2d.org/wiki/Tutorial:Games"
			},
			{
				title = "Physics Tutorial",
				description = "Learn how to add physics to your games",
				url = "https://love2d.org/wiki/Tutorial:Physics"
			}
		}
	},
	{
		title = "LÖVE Documentation",
		url = "search:docs",
		keywords = {"documentation", "api", "reference"},
		description = "Official LÖVE documentation and API reference",
		results = {
			{
				title = "API Reference",
				description = "Complete documentation of LÖVE's API",
				url = "https://love2d.org/wiki/API"
			},
			{
				title = "Configuration Files",
				description = "Learn about conf.lua and game configuration",
				url = "https://love2d.org/wiki/Config_Files"
			},
			{
				title = "Modules Overview",
				description = "Explore all available LÖVE modules",
				url = "https://love2d.org/wiki/Modules"
			}
		}
	},
	{
		title = "Game Development Resources",
		url = "search:resources",
		keywords = {"resources", "assets", "tools"},
		description = "Find resources and tools for game development",
		results = {
			{
				title = "Asset Libraries",
				description = "Free assets and resources for your games",
				url = "https://love2d.org/wiki/Asset_Libraries"
			},
			{
				title = "Development Tools",
				description = "Useful tools for LÖVE development",
				url = "https://love2d.org/wiki/Tools"
			},
			{
				title = "Game Examples",
				description = "Example games with source code",
				url = "https://love2d.org/wiki/Examples"
			}
		}
	},
	{
		title = "System Applications",
		url = "search:apps",
		keywords = {"apps", "system", "tools"},
		description = "Access system applications and tools",
		results = {
			{
				title = "Terminal",
				description = "Command-line interface for system operations",
				url = "app:terminal"
			},
			{
				title = "File Manager",
				description = "Browse and manage your files",
				url = "app:files"
			},
			{
				title = "Email Client",
				description = "Check and send emails",
				url = "app:email"
			}
		}

	}
}

return SearchItems