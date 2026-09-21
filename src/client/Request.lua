--!strict
--[[ Request.lua -- one call into the server, with the failure path handled once. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local Request = {}

local remote: RemoteFunction? = nil

local function getRemote(): RemoteFunction
	if not remote then
		remote = Net.fn("Request")
	end
	return remote :: RemoteFunction
end

--- Blocking call. Always returns a table with an `ok` field.
function Request.send(action: string, payload: any?)
	local success, result = pcall(function()
		return getRemote():InvokeServer(action, payload)
	end)

	if not success then
		warn("[LARP] request '" .. action .. "' failed: " .. tostring(result))
		return { ok = false, err = "Connection wobbled. Try again." }
	end

	if type(result) ~= "table" then
		return { ok = false, err = "The server said nothing." }
	end

	return result
end

--- Fire-and-forget variant for UI actions where the snapshot is the real reply.
function Request.spawn(action: string, payload: any?, callback: ((any) -> ())?)
	task.spawn(function()
		local result = Request.send(action, payload)
		if callback then
			callback(result)
		end
	end)
end

return Request
