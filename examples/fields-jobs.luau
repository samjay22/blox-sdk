--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
--- Trusted game-server/admin-key operation; never let a RemoteEvent select targets or quantities.
return function(client: SDK.Client, universeId: number, eventKey: string): Core.Result<Wire.JobReceipt>
	-- Gateway plus FieldsService ADMIN is required, even for previews and polling.
	-- Provision this separately from the ordinary gameplay READ_WRITE credential.
	local loaded = client.fields:schemaCache(universeId):load()
	if not loaded.ok then
		return loaded
	end
	local grant = client.fields
		:bulkBuilder(universeId)
		:target({ kind = "WHERE", where = { op = "GE", field = "Currency.Gems", value = 100 } })
		:reason("Reviewed seasonal event bonus")
		:idempotencyKey(eventKey)
	grant.ops:add("Currency.Gems", 10)
	local preview = grant:preview()
	if not preview.ok then
		return preview
	end
	-- Preview is not a reservation: schema, runtime limits and membership can change.
	if not preview.value.validation.valid then
		return {
			ok = false,
			error = {
				kind = "Validation",
				message = "Bulk preview rejected",
				endpoint = "fields.bulkPreview",
				attempts = 0,
				code = "invalid_ops",
			},
		}
	end
	local submitted = grant:submit()
	if not submitted.ok then
		return submitted
	end
	local finished = client.fields:jobClient(universeId):waitFor(submitted.value.id, { timeout = 60 })
	-- Timeout stops only this caller's polling; the durable job continues server-side.
	-- A successful Result is a terminal receipt, NOT proof that every item succeeded:
	-- inspect state and failed; query Jobs:failures(id) before deciding on compensation.
	return finished
end
