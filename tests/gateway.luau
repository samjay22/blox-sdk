--!strict
local Config = require("../src/Core/Config")
local Routing = require("../src/Core/Routing")
local Tests = {}
Tests.prefixes = Routing.prefixes
--- Verify gateway normalization and explicitly reject retired direct destinations.
function Tests.register(test: (string, () -> ()) -> ())
	test("batch gateway is normalized and direct service overrides fail closed", function()
		local origins = Config.resolve({ gatewayUrl = "https://GATEWAY.example:0443/" })
		for _, origin in origins do
			assert(origin == "https://gateway.example", "Gateway normalization")
		end
		for _, value in
			{
				"http://bad",
				"https://user:secret@bad",
				"https://bad/path",
				"https://bad?token=secret",
				"https://bad:0",
			}
		do
			local ok, message = pcall(Config.resolve, { gatewayUrl = value })
			assert(not ok and not string.find(tostring(message), "secret", 1, true), "URL validation")
		end
		assert(
			not pcall(
				Config.resolve,
				{ services = { fields = { baseUrl = "https://direct.example" } } } :: Config.Config
			),
			"Direct service overrides must fail"
		)
	end)
end
return table.freeze(Tests)
