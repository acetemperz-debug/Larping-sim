--!strict
--[[
	Interactions.lua

	Wires the ProximityPrompts that WorldBuilder generated. Content pads run the
	post immediately; every other kiosk just asks the client to open a panel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local PlayerData = require(script.Parent.PlayerData)
local Content = require(script.Parent.Content)
local Feedback = require(script.Parent.Feedback)

local Interactions = {}

local function openPanel(player: Player, panel: string, payload: string?)
	local remote = Net.get():FindFirstChild("OpenUI") :: RemoteEvent
	remote:FireClient(player, { panel = panel, payload = payload })
end

local function connectPrompt(promptInstance: ProximityPrompt)
	local host = promptInstance.Parent
	if not host or not host:IsA("BasePart") then
		return
	end

	local action = host:GetAttribute("Action")
	if type(action) ~= "string" then
		return
	end
	local payload = host:GetAttribute("Payload")

	promptInstance.Triggered:Connect(function(player)
		local profile = PlayerData.get(player)
		if not profile then
			return
		end

		if action == "content" then
			local result = Content.create(player, profile, tostring(payload))
			if not result.ok then
				Feedback.notify(player, "bad", "Can't post", result.err)
			end
			return
		end

		openPanel(player, action, payload and tostring(payload) or nil)
	end)
end

function Interactions.bind(worldFolder: Instance)
	for _, descendant in ipairs(worldFolder:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			connectPrompt(descendant)
		end
	end

	worldFolder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			connectPrompt(descendant)
		end
	end)
end

return Interactions
