local SearchItems = {
	{
		title = "LÖVE Documentation",
		url = "search:docs",
		keywords = {"documentation", "api", "reference", "manual", "guide", "help"},
		description = "Official LÖVE documentation and API reference",
		results = {
			{
				title = "Getting Started Guide",
				description = "Learn the basics of LÖVE game development",
				url = "https://love2d.org/wiki/Getting_Started"
			},
			{
				title = "API Reference",
				description = "Complete documentation of LÖVE's API",
				url = "https://love2d.org/wiki/API"
			},
			{
				title = "Tutorials",
				description = "Step-by-step guides for game development",
				url = "https://love2d.org/wiki/Category:Tutorials"
			}
		}
	},
	{
		title = "Game Development",
		url = "search:gamedev",
		keywords = {"games", "development", "tutorials", "examples", "code"},
		description = "Resources for game development with LÖVE",
		results = {
			{
				title = "Example Games",
				description = "Browse and learn from example games",
				url = "https://love2d.org/wiki/Category:Games"
			},
			{
				title = "Game Tutorials",
				description = "Learn game development step by step",
				url = "https://love2d.org/wiki/Category:Tutorials:Games"
			},
			{
				title = "GitHub Examples",
				description = "Example games on GitHub",
				url = "https://github.com/topics/love2d-games"
			}
		}
	},
	{
		title = "Community Resources",
		url = "search:community",
		keywords = {"community", "forum", "discord", "chat", "help", "support"},
		description = "Connect with the LÖVE community",
		results = {
			{
				title = "LÖVE Forums",
				description = "Official community forums",
				url = "https://love2d.org/forums/"
			},
			{
				title = "Discord Server",
				description = "Join the LÖVE Discord community",
				url = "https://discord.gg/love2d"
			},
			{
				title = "Reddit Community",
				description = "LÖVE subreddit for discussions",
				url = "https://reddit.com/r/love2d"
			}
		}
	},
	{
		title = "System Applications",
		url = "search:apps",
		keywords = {"apps", "system", "tools", "applications", "utilities"},
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
