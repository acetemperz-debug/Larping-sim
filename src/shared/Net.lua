--!strict
--[[
	Net.lua -- remote plumbing shared by both sides.

	The server creates the folder and its children on first call; the client
	waits for them. Keeping the names in one table stops the two halves of the
	game drifting apart.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.FolderName = "LarpNet"

-- server -> client
Net.Events = {
	"State",      -- full player snapshot
	"Notify",     -- toast popup
	"Feed",       -- a generated social post
	"Milestone",  -- full-screen milestone card
	"Question",   -- podcast question prompt
	"Broadcast",  -- server-wide announcement
	"OpenUI",     -- a kiosk asked the client to open a panel
}

-- client -> server
Net.Functions = {
	"Request",    -- (action: string, payload: table?) -> { ok: boolean, err: string?, ... }
}

local cached: Folder? = nil

function Net.get(): Folder
	if cached then
		return cached
	end

	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(Net.FolderName)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Net.FolderName
			folder.Parent = ReplicatedStorage
		end

		for _, name in ipairs(Net.Events) do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = folder
			end
		end

		for _, name in ipairs(Net.Functions) do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = folder
			end
		end

		cached = folder :: Folder
		return cached :: Folder
	end

	local folder = ReplicatedStorage:WaitForChild(Net.FolderName, 30)
	assert(folder, "LarpNet never replicated -- is the server script running?")
	cached = folder :: Folder
	return cached :: Folder
end

function Net.event(name: string): RemoteEvent
	return Net.get():WaitForChild(name) :: RemoteEvent
end

function Net.fn(name: string): RemoteFunction
	return Net.get():WaitForChild(name) :: RemoteFunction
end

return Net
