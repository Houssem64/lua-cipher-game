-- story_missions.lua
local StoryMissions = {
	missions = {
		{
			id = 1,
			text = "Terminal Introduction",
			description = "Learn the very basics of using a terminal interface. This mission introduces you to the fundamental commands every hacker needs to know.",
			reward = {
				badge = "Terminal Novice Badge",
				elo = 10
			},
			rank_required = "Newbie",
			subtasks = {
				"Type 'whoami' to see your current username",
				"Type 'pwd' to see your current directory location",
				"Use 'ls' to list files in your current directory",
				"Try 'clear' to clean up your terminal screen",
				"Type 'date' to check the current system time",
				"Run 'help' to see available commands"
			}
		},
		{
			id = 2,
			text = "File System Navigation",
			description = "Master navigating through directories and managing files - essential skills for any cybersecurity professional.",
			reward = {
				badge = "File Navigator Badge",
				elo = 15
			},
			rank_required = "Newbie",
			subtasks = {
				"Create a new directory with 'mkdir practice'",
				"Navigate into the directory with 'cd practice'",
				"Create an empty file with 'touch notes.txt'",
				"Navigate back to parent directory with 'cd ..'",
				"Use 'ls -la' to view all files with details",
				"Remove the directory with 'rm -r practice'"
			}
		},
		{
			id = 3,
			text = "Text Manipulation Basics",
			description = "Learn to create, view, and manipulate text files - crucial for editing configuration files and examining system logs.",
			reward = {
				badge = "Text Wizard Badge",
				elo = 20
			},
			rank_required = "Script Kiddie",
			subtasks = {
				"Create a file with content using 'echo \"Hello World\" > hello.txt'",
				"View the file contents with 'cat hello.txt'",
				"Append more text with 'echo \"New line\" >> hello.txt'",
				"View the updated file with 'cat hello.txt'",
				"Use 'grep \"Hello\" hello.txt' to search for text",
				"Count words in the file with 'wc -w hello.txt'"
			}
		},
		{
			id = 4,
			text = "Security Analyst Basics",
			description = "Master essential terminal commands used by security professionals for system reconnaissance and navigation. This is the foundation of all cybersecurity operations.",
			reward = {
				badge = "Security Fundamentals Badge",
				elo = 25
			},
			rank_required = "Script Kiddie",
			subtasks = {
				"Use 'neofetch' to gather target system information",
				"Create a secure directory named 'recon' using 'mkdir recon'",
				"Navigate to the directory with 'cd recon'",
				"Create a log file using 'touch reconnaissance.log'",
				"Use 'ls -la' to verify hidden files and permissions",
				"Try 'sudo whoami' to test for privilege escalation",
				"Run 'netstat -tuln' to view open network ports"
			}
		},
		{
			id = 5,
			text = "User and Permission Management",
			description = "Learn to manage file permissions and understand different user privileges in a system - critical for security hardening.",
			reward = {
				badge = "Permission Master Badge",
				elo = 30
			},
			rank_required = "Initiate",
			subtasks = {
				"Create a test file with 'touch secret.txt'",
				"Change file permissions with 'chmod 600 secret.txt'",
				"Verify permissions with 'ls -la'",
				"Try to change ownership with 'chown root secret.txt'",
				"Use 'sudo' to execute commands with elevated privileges",
				"Check user privilege information with 'id'"
			}
		},
		{
			id = 6,
			text = "Basic Data Encoding",
			description = "Learn how data can be encoded, encrypted, and decoded - fundamental skills for working with secure communications.",
			reward = {
				badge = "Encoder Badge",
				elo = 35
			},
			rank_required = "Initiate",
			subtasks = {
				"Encode text with 'echo \"Secret message\" | base64'",
				"Decode base64 with 'echo \"U2VjcmV0IG1lc3NhZ2UK\" | base64 -d'",
				"Create an MD5 hash with 'echo \"password\" | md5sum'",
				"Use 'echo \"message\" | base64 > encoded.txt' to save encoded text",
				"Decode content from a file with 'base64 -d encoded.txt'"
			}
		},
		{
			id = 7,
			text = "Basic Forensic Investigation",
			description = "Learn digital forensics techniques to discover and analyze data. Essential skills for security audits and incident response.",
			reward = {
				badge = "Digital Forensics Badge",
				elo = 40
			},
			rank_required = "Initiate",
			subtasks = {
				"Create a file named 'credentials.txt' with sample data using 'echo'",
				"Examine file contents using 'cat credentials.txt'",
				"Create a system log file named 'system.log' with sample entries",
				"Use 'grep \"error\" system.log' to search for specific events",
				"Use 'find . -name \"*.log\"' to discover log files",
				"Check file details with 'file credentials.txt'"
			}
		},
		{
			id = 8,
			text = "Network Basics",
			description = "Learn fundamental networking commands to examine connectivity and network configurations.",
			reward = {
				badge = "Network Novice Badge",
				elo = 45
			},
			rank_required = "Apprentice",
			subtasks = {
				"Check your IP address with 'ifconfig' or 'ip addr'",
				"Test connectivity with 'ping example.com'",
				"Check network routes with 'route' or 'ip route'",
				"View active network connections with 'netstat -an'",
				"Trace network path with 'traceroute example.com'",
				"Look up domain information with 'nslookup example.com'"
			}
		},
		{
			id = 9,
			text = "Basic Reconnaissance",
			description = "Learn to gather information about networks and domains using basic reconnaissance tools.",
			reward = {
				badge = "Recon Novice Badge",
				elo = 50
			},
			rank_required = "Apprentice",
			subtasks = {
				"Use 'whois example.com' to retrieve domain registration information",
				"Use 'dig example.com' to query DNS information",
				"Check for open ports with 'nc -zv example.com 80'",
				"Gather HTTP headers with 'curl -I example.com'",
				"Create a recon report file with findings"
			}
		},
		{
			id = 10,
			text = "System Monitoring",
			description = "Learn to monitor system resources and processes to identify abnormal activities.",
			reward = {
				badge = "System Monitor Badge",
				elo = 55
			},
			rank_required = "Hacker",
			subtasks = {
				"View system uptime with 'uptime'",
				"Monitor processes with 'top'",
				"List all processes with 'ps aux'",
				"Check disk usage with 'df -h'",
				"Monitor system memory with 'free -m'",
				"Check CPU information with 'lscpu'"
			}
		},
		{
			id = 11,
			text = "Advanced File Operations",
			description = "Master more complex file manipulations and searches needed for thorough system analysis.",
			reward = {
				badge = "File Guru Badge",
				elo = 60
			},
			rank_required = "Hacker",
			subtasks = {
				"Use 'find / -name \"passwd\" -type f 2>/dev/null' to locate sensitive files",
				"Search for text in multiple files with 'grep -r \"password\" .'",
				"Use 'sort' and 'uniq' to analyze log file data",
				"Compare files with 'diff file1 file2'",
				"Use 'head' and 'tail' to view portions of large files",
				"Create archive with 'tar -czvf archive.tar.gz directory/'"
			}
		},
		{
			id = 12,
			text = "Network Penetration Basics",
			description = "Learn essential network penetration testing techniques to identify vulnerabilities in connected systems.",
			reward = {
				badge = "Network Security Badge",
				elo = 65
			},
			rank_required = "Elite Hacker",
			subtasks = {
				"Perform initial reconnaissance using 'ping targetserver.local'",
				"Port scan with 'nmap -sS targetserver.local'",
				"Connect to an open service using 'nc targetserver.local 21'",
				"Analyze network traffic with 'tcpdump -i eth0'",
				"Discover hosts on network with 'arp -a'",
				"Check for exploitable services with 'nmap -sV targetserver.local'"
			}
		},
		{
			id = 13,
			text = "Shell Scripting Basics",
			description = "Learn to automate tasks by creating basic shell scripts - essential for efficient security operations.",
			reward = {
				badge = "Script Writer Badge",
				elo = 70
			},
			rank_required = "Elite Hacker",
			subtasks = {
				"Create a script file 'scan.sh' with 'touch scan.sh'",
				"Make the script executable with 'chmod +x scan.sh'",
				"Edit script with echo commands to output security information",
				"Add system commands to gather IP and user information",
				"Run the script with './scan.sh'",
				"Create a script that takes command line arguments"
			}
		},
		{
			id = 14,
			text = "Security Configuration",
			description = "Learn to create and modify security configuration files to harden systems.",
			reward = {
				badge = "Security Hardening Badge",
				elo = 75
			},
			rank_required = "Master Hacker",
			subtasks = {
				"Create a firewall configuration file with 'touch firewall.conf'",
				"Add deny rules to block suspicious IP addresses",
				"Create a security policy document in a text file",
				"Set restrictive permissions on configuration files",
				"Create a backup of critical configuration files",
				"Implement defense-in-depth in your configurations"
			}
		},
		{
			id = 15,
			text = "Advanced Threat Detection",
			description = "Master process monitoring and threat detection to identify malicious activities in compromised systems.",
			reward = {
				badge = "Threat Hunter Badge",
				elo = 80
			},
			rank_required = "Master Hacker",
			subtasks = {
				"Use 'ps -aux | grep root' to identify processes running with elevated privileges",
				"Monitor system resource usage with 'top' to detect resource-intensive processes",
				"Run 'netstat -antp' to identify suspicious network connections",
				"Check for unauthorized scheduled tasks with 'crontab -l'",
				"Examine system logs for unusual login attempts",
				"Create an incident response plan document"
			}
		},
		{
			id = 16,
			text = "Advanced Network Analysis",
			description = "Execute comprehensive network security assessments using industry-standard tools and methodologies.",
			reward = {
				badge = "Network Infiltration Badge",
				elo = 85
			},
			rank_required = "Guru",
			subtasks = {
				"Perform comprehensive port scanning with 'nmap -sV -sC targetserver.local'",
				"Capture network traffic with 'tcpdump -i eth0 -w capture.pcap'",
				"Analyze captured packets with specialized tools",
				"Map network infrastructure using 'traceroute' to identify potential entry points",
				"Enumerate all listening services with 'netstat -tuln'",
				"Perform password policy analysis through gathering information"
			}
		},
		{
			id = 17,
			text = "Security Automation",
			description = "Master security automation by creating scripts that automate security scans and vulnerability assessments.",
			reward = {
				badge = "DevSecOps Master Badge",
				elo = 90
			},
			rank_required = "Guru",
			subtasks = {
				"Create an advanced security scanning script",
				"Implement error handling for edge cases in security tools",
				"Add conditional logic to detect different types of security breaches",
				"Create a loop to scan multiple systems or IP ranges",
				"Develop a script that automatically analyzes security log files",
				"Create a reporting mechanism for security findings"
			}
		},
		{
			id = 18,
			text = "Incident Response Master",
			description = "Master advanced incident response procedures and digital forensics techniques to investigate system compromises.",
			reward = {
				badge = "Forensic Analyst Badge",
				elo = 100
			},
			rank_required = "Guru",
			subtasks = {
				"Create a detailed forensic investigation procedure document",
				"Simulate data recovery from corrupted file systems",
				"Create forensic timelines of security incidents using log files",
				"Develop an evidence collection methodology",
				"Implement a comprehensive disaster recovery plan",
				"Create a forensic analysis report template"
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