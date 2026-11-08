--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local BASE = "https://lb1.blox-api.com/fields-service/api/fields/universes/123"

--- Assert without printing synthetic credentials or payloads.
local function check(value: unknown)
	assert(value, "Fields reference regression")
end

--- Construct an isolated universe-bound client; tests never send network traffic.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	level: Core.Level?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		levels = { FieldsService = level or "ADMIN" },
	}),
		fake
end

--- Build a complete schema response independently of generated endpoint metadata.
local function definition(): Wire.Definition
	return {
		universeId = 123,
		id = "Rating",
		scope = "PLAYER",
		type = { kind = "int" },
		default = 0,
		history = "LEDGER",
		writeLevel = "READ_WRITE",
		status = "ACTIVE",
		definitionVersion = 1,
		description = "",
		createdAt = "now",
		updatedAt = "now",
	}
end

--- Register exact-wire reference, permissions, force and redaction regressions.
return function(test: (string, () -> ()) -> ())
	test("Fields references use typed scoped routes and encode empty fields as an array", function()
		local s = Scheduler.new()
		local result: Wire.FieldReferences = {
			fieldId = "Stats.Rating",
			references = { { consumerType = "GAMEMODE", consumerId = "ranked / 5v5", label = "Ranked 5v5" } },
		}
		local c, f = client(s, {
			{
				body = s.json(result),
				check = function(request)
					check(
						request.Method == "GET"
							and request.Url == BASE .. "/definitions/Stats.Rating/references"
					)
				end,
			},
			{
				status = 204,
				check = function(request)
					check(
						request.Method == "PUT"
							and request.Url == BASE .. "/references/GAMEMODE/ranked%20%2F%205v5"
					)
					local body: any = Decode.decode(request.Body :: string)
					check(
						body.label == "Ranked 5v5" and #body.fields == 2 and body.fields[1] == "Stats.Rating"
					)
				end,
			},
			{
				status = 204,
				check = function(request)
					check(request.Method == "PUT" and request.Url == BASE .. "/references/CODE/welcome")
					check(request.Body == '{"fields":[],"label":"Welcome"}')
				end,
			},
			{
				status = 204,
				check = function(request)
					check(request.Method == "DELETE" and request.Url == BASE .. "/references/CODE/welcome")
					check(request.Body == nil)
				end,
			},
		}, "READ_WRITE")
		s.run(function()
			local references = c.fields:definitionReferences({ path = { id = "Stats.Rating" } })
			check(references.ok and references.value.references[1].consumerType == "GAMEMODE")
			check(c.fields:putReferences({
				path = { consumerType = "GAMEMODE", consumerId = "ranked / 5v5" },
				body = { label = "Ranked 5v5", fields = { "Stats.Rating", "Region" } },
			}).ok)
			check(c.fields:putReferences({
				path = { consumerType = "CODE", consumerId = "welcome" },
				body = { label = "Welcome", fields = {} },
			}).ok)
			check(c.fields:deleteReferences({ path = { consumerType = "CODE", consumerId = "welcome" } }).ok)
			check(f.count() == 4)
			c:destroy()
		end)
	end)
	test(
		"Fields reference payloads validate at the boundary and history exposes audited references",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{
					body = s.json({
						fieldId = "Rating",
						references = { { consumerType = "PARTY", consumerId = "p", label = "Unknown kind" } },
					}),
				},
				{
					body = s.json({
						items = {
							{
								counter = 1,
								field = "Rating",
								actor = "operator",
								reason = "Reviewed dependency",
								createdAt = "now",
								references = {
									{ consumerType = "CODE", consumerId = "welcome", label = "Welcome" },
								},
							},
						},
					}),
				},
			})
			s.run(function()
				local invalid: any =
					{ path = { consumerType = "CODE", consumerId = "welcome" }, body = { label = "Welcome" } }
				check(not c.fields:putReferences(invalid).ok)
				check(not c.fields:deleteReferences({
					path = { universeId = 456, consumerType = "CODE", consumerId = "welcome" },
				}).ok)
				check(f.count() == 0)
				local malformed = c.fields:definitionReferences({ path = { id = "Rating" } })
				check(not malformed.ok and malformed.error.kind == "Network")
				local history = c.fields:history({ path = { id = "Rating" } })
				check(history.ok and history.value.items[1].references ~= nil)
				if history.ok then
					local references = history.value.items[1].references
					check(references ~= nil and references[1].consumerType == "CODE")
				end
				check(f.count() == 2)
				c:destroy()
			end)
		end
	)
	test("Fields reference reads require READ, replacement/deletion WRITE and force ADMIN", function()
		local s = Scheduler.new()
		local c, f =
			client(s, { { body = s.json({ fieldId = "Rating", references = Json.array({}) }) } }, "READ")
		s.run(function()
			check(c.fields:definitionReferences({ path = { id = "Rating" } }).ok)
			check(not c.fields:putReferences({
				path = { consumerType = "CODE", consumerId = "welcome" },
				body = { label = "Welcome", fields = {} },
			}).ok)
			check(
				not c.fields:deleteReferences({ path = { consumerType = "CODE", consumerId = "welcome" } }).ok
			)
			check(f.count() == 1)
			c:destroy()
		end)
		local writer, denied = client(s, {}, "READ_WRITE")
		s.run(function()
			check(not writer.fields:archive({
				path = { id = "Rating" },
				body = { force = true, reason = "Reviewed dependency" },
			}).ok)
			check(not writer.fields:update({
				path = { id = "Rating" },
				query = { force = true },
				body = { reason = "Reviewed dependency" },
			}).ok)
			check(not writer.fields:purge({
				path = { id = "Rating" },
				query = { force = true, purge = true, reason = "Reviewed dependency" },
			}).ok)
			check(denied.count() == 0)
			writer:destroy()
		end)
	end)
	test("Fields forced definition operations preserve force and the existing audit reason", function()
		local s = Scheduler.new()
		local steps: { Fake.Step } = {}
		for _, method in { "POST", "PUT", "DELETE" } do
			table.insert(steps, {
				body = s.json(
					if method == "DELETE" then { definitions = 1, values = 0, ledger = 0 } else definition()
				),
				check = function(request)
					check(request.Method == method)
					if method == "DELETE" then
						check(
							request.Url
								== BASE
									.. "/definitions/Rating?force=true&purge=true&reason=Reviewed%20dependency"
						)
					else
						check(
							request.Url
								== BASE
									.. "/definitions/Rating"
									.. (if method == "POST" then "/archive" else "")
									.. (if method == "POST" then "" else "?force=true")
						)
						local body: any = Decode.decode(request.Body :: string)
						check(body.reason == "Reviewed dependency")
						if method == "POST" then
							check(body.force == true)
						end
					end
				end,
			})
		end
		local c, f = client(s, steps)
		s.run(function()
			check(c.fields:archive({
				path = { id = "Rating" },
				body = { force = true, reason = "Reviewed dependency" },
			}).ok)
			check(c.fields:update({
				path = { id = "Rating" },
				query = { force = true },
				body = { reason = "Reviewed dependency" },
			}).ok)
			check(c.fields:purge({
				path = { id = "Rating" },
				query = { force = true, purge = true, reason = "Reviewed dependency" },
			}).ok)
			check(f.count() == 3)
			c:destroy()
		end)
	end)
	test("Fields field_in_use is a stable conflict code without leaking reference labels", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				status = 409,
				body = s.json({
					code = "field_in_use",
					fieldId = "Rating",
					references = {
						{ consumerType = "CODE", consumerId = "private-code", label = "private label" },
					},
				}),
			},
		})
		s.run(function()
			local result =
				c.fields:archive({ path = { id = "Rating" }, body = { reason = "Retire unused field" } })
			check(not result.ok and result.error.kind == "Conflict" and result.error.code == "field_in_use")
			check(not result.ok and result.error.body == "[redacted]" and result.error.attempts == 1)
			check(f.count() == 1)
			c:destroy()
		end)
	end)
end
