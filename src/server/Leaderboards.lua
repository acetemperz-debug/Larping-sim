--!strict
--[[
	Leaderboards.lua

	Five global boards. Four of them are normal simulator fare. The fifth,
	"Money Spent Pretending To Be Rich", is the only one that tells the truth.

	Falls back to ranking whoever is currently in the server when DataStores
	are unavailable (Studio, or an API outage), so the boards are never blank.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Format = require(Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local State = require(script.Parent.State)

local Leaderboards = {}

Leaderboards.Boards = {
	{ id = "followers", title = "MOST FOLLOWERS", subtitle = "Audience size. Not audience quality.", key = "followers", money = false },
	{ id = "cash", title = "MOST CASH", subtitle = "Liquid. Briefly.", key = "cash", money = true },
	{ id = "clout", title = "HIGHEST CLOUT", subtitle = "How rich you look, which is the only metric.", key = "clout", money = false },
	{ id = "sold", title = "MOST COURSES SOLD", subtitle = "Refund rate not shown.", key = "coursesSold", money = false },
	{ id = "spent", title = "MONEY SPENT PRETENDING TO BE RICH", subtitle = "The real scoreboard.", key = "spentLarping", money = true },
}

local stores: { [string]: OrderedDataStore } = {}
local storesOk = true

do
	for _, board in ipairs(Leaderboards.Boards) do
		local success, result = pcall(function()
			return DataStoreService:GetOrderedDataStore("LarpBoard_v1_" .. board.id)
		end)
		if success then
			stores[board.id] = result
		else
			storesOk = false
		end
	end
	if not storesOk then
		warn("[LARP] Ordered DataStores unavailable; leaderboards will show this server only.")
	end
end

local cache: { [string]: { any } } = {}
local registry: { [string]: { Frame } } = {}

--- Pulls the value a board ranks for a given player.
local function valueFor(board, profile, derived): number
	if board.key == "clout" then
		return math.floor(derived.clout)
	elseif board.key == "coursesSold" or board.key == "spentLarping" then
		return math.floor(profile.stats[board.key])
	end
	return math.floor(profile[board.key])
end

function Leaderboards.submit(player: Player)
	local profile = PlayerData.get(player)
	if not profile or not storesOk then
		return
	end

	local derived = State.compute(profile)
	for _, board in ipairs(Leaderboards.Boards) do
		local store = stores[board.id]
		if store then
			local value = valueFor(board, profile, derived)
			pcall(function()
				store:SetAsync(tostring(player.UserId), value)
			end)
		end
	end
end

--- Ranks everyone currently in the server. Used when DataStores are off.
local function localRanking(board)
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.get(player)
		if profile then
			local derived = State.compute(profile)
			table.insert(rows, { name = player.DisplayName, value = valueFor(board, profile, derived) })
		end
	end
	table.sort(rows, function(a, b)
		return a.value > b.value
	end)
	return rows
end

function Leaderboards.refresh()
	for _, board in ipairs(Leaderboards.Boards) do
		local rows = nil

		local store = stores[board.id]
		if store then
			local success, pages = pcall(function()
				return store:GetSortedAsync(false, 10)
			end)
			if success then
				local ok, page = pcall(function()
					return pages:GetCurrentPage()
				end)
				if ok then
					rows = {}
					for _, entry in ipairs(page) do
						local userId = tonumber(entry.key)
						local name = "Unknown Guru"
						if userId then
							local nameOk, resolved = pcall(function()
								return Players:GetNameFromUserIdAsync(userId)
							end)
							if nameOk then
								name = resolved
							end
						end
						table.insert(rows, { name = name, value = entry.value })
					end
				end
			end
		end

		cache[board.id] = rows or localRanking(board)
	end

	Leaderboards.render()
end

--- WorldBuilder calls this so the module knows where to draw.
function Leaderboards.register(boardId: string, frame: Frame)
	registry[boardId] = registry[boardId] or {}
	table.insert(registry[boardId], frame)
end

function Leaderboards.render()
	for _, board in ipairs(Leaderboards.Boards) do
		local rows = cache[board.id] or {}
		for _, frame in ipairs(registry[board.id] or {}) do
			if frame.Parent then
				for _, child in ipairs(frame:GetChildren()) do
					if child:IsA("TextLabel") then
						child:Destroy()
					end
				end

				for index = 1, 10 do
					local row = rows[index]
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 0, 34)
					label.BackgroundTransparency = index % 2 == 0 and 1 or 0.85
					label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					label.BorderSizePixel = 0
					label.Font = Enum.Font.GothamMedium
					label.TextSize = 20
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = index <= 3 and Color3.fromRGB(255, 214, 110) or Color3.fromRGB(235, 235, 240)
					label.LayoutOrder = index

					if row then
						local value = board.money and Format.money(row.value, true) or Format.short(row.value)
						label.Text = string.format("  %d. %s", index, row.name)
						local valueLabel = Instance.new("TextLabel")
						valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
						valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
						valueLabel.BackgroundTransparency = 1
						valueLabel.Font = Enum.Font.GothamBold
						valueLabel.TextSize = 20
						valueLabel.TextXAlignment = Enum.TextXAlignment.Right
						valueLabel.TextColor3 = label.TextColor3
						valueLabel.Text = value .. "  "
						valueLabel.Parent = label
					else
						label.Text = string.format("  %d. —", index)
						label.TextColor3 = Color3.fromRGB(120, 120, 130)
					end

					label.Parent = frame
				end
			end
		end
	end
end

function Leaderboards.start()
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				Leaderboards.submit(player)
			end
			Leaderboards.refresh()
			task.wait(Balance.LeaderboardRefresh)
		end
	end)
end

return Leaderboards
