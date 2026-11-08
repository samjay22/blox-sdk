--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local writer = client:auditWriter({ batchSize = 25 })
local accepted = writer:enqueue({
	occurredAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	actorType = "SYSTEM",
	actorId = "server",
	action = "server.started",
	resourceType = "game",
	resourceId = tostring(game.GameId),
	outcome = "SUCCESS",
})
if not accepted then
	warn("Audit queue rejected event")
end
-- Client shutdown drains this bounded queue; enqueue is not a delivery acknowledgement.
