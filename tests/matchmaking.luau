--!strict
local SDK = require("../src/BloxSDK")
local Errors = require("../src/Core/Errors")
local Validation = require("../src/Core/Validation")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")

--- Fail without exposing request data or credentials.
local function check(value: unknown)
	assert(value, "Matchmaking criteria regression")
end

--- Register offline F1 catalog, permissions, response typing and redaction regressions.
return function(test: (string, () -> ()) -> ())
	test("criteria catalog uses the authenticated READ route and validates computed returns", function()
		local s = Scheduler.new()
		local fake = Fake.new(s.runtime, {
			{
				-- Check route/auth presence without retaining or logging credentials.
				check = function(request)
					check(request.Method == "GET")
					check(
						request.Url
							== "https://lb1.blox-api.com/matchmaking-service/api/matchmaking/criteria-types"
					)
					check(request.Headers.Authorization ~= nil)
				end,
				body = s.json({
					{
						type = "RANGE",
						fieldRequired = true,
						allowedReturns = { "int", "number" },
						description = "Range",
					},
				}),
			},
		})
		local client = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 123,
			levels = { MatchmakingService = "READ" },
		})
		s.run(function()
			local result = client.matchmaking:getCriteriaTypes()
			check(result.ok and #result.value == 1)
			if result.ok then
				local required: boolean = result.value[1].fieldRequired
				local returns: "int" | "number" = result.value[1].allowedReturns[1]
				check(required and returns == "int")
			end
		end)
		check(fake.count() == 1)
		check(not Validation.response("matchmaking.getCriteriaTypes", {
			{ type = "RANGE", fieldRequired = true, allowedReturns = { "string" }, description = "Invalid" },
		}))
		check(not Validation.response("matchmaking.getCriteriaTypes", {
			{ type = "RANGE", allowedReturns = { "int" }, description = "Missing requirement" },
		}))
		client:destroy()
	end)

	test("criteria save errors preserve only known machine codes and redact backend diagnostics", function()
		for _, code in { "criteria_field_invalid", "fields_unavailable" } do
			for _, property in { "code", "errorCode" } do
				local body: { [string]: unknown } = {
					message = "private backend text",
					criteriaIndex = 0,
					fieldName = "PrivateField",
					reason = "unknown_field",
				}
				body[property] = code
				local status = if code == "fields_unavailable" then 503 else 400
				local result = Errors.domain(status, "matchmaking.createGameMode", 1, body)
				check(not result.ok)
				if not result.ok then
					check(result.error.code == code and result.error.status == status)
					check(result.error.body == "[redacted]" and result.error.message == "HTTP request failed")
				end
			end
		end
		local unknown =
			Errors.domain(400, "matchmaking.updateGameMode", 1, { errorCode = "untrusted backend text" })
		check(not unknown.ok and unknown.error.code == nil)
		local otherService = Errors.domain(400, "fields.schema", 1, { errorCode = "criteria_field_invalid" })
		check(not otherService.ok and otherService.error.code == nil)
	end)
end
