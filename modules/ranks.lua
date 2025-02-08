local Ranks = {
	ranks = {
		{name = "Script Kiddie", elo_required = 0},
		{name = "Initiate", elo_required = 10},
		{name = "Apprentice", elo_required = 20},
		{name = "Hacker", elo_required = 30},
		{name = "Elite Hacker", elo_required = 1000},
		{name = "Master Hacker", elo_required = 1500},
		{name = "Legendary Hacker", elo_required = 2000}
	}
}

function Ranks:getRankByELO(elo)
	local currentRank = self.ranks[1]
	for _, rank in ipairs(self.ranks) do
		if elo >= rank.elo_required then
			currentRank = rank
		else
			break
		end
	end
	return currentRank
end

function Ranks:getNextRank(elo)
	local currentRank = self:getRankByELO(elo)
	for i, rank in ipairs(self.ranks) do
		if rank.name == currentRank.name and i < #self.ranks then
			return self.ranks[i + 1]
		end
	end
	return nil
end

function Ranks:getProgress(elo)
	local currentRank = self:getRankByELO(elo)
	local nextRank = self:getNextRank(elo)
	
	if not nextRank then
		return 1
	end
	
	local eloInCurrentRank = elo - currentRank.elo_required
	local eloNeededForNext = nextRank.elo_required - currentRank.elo_required
	return eloInCurrentRank / eloNeededForNext
end

return Ranks