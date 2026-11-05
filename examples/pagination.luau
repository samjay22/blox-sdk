--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Codes")
--- Lazily fetch code pages, exposing failures rather than pretending the list is complete.
return function(client: SDK.Client): () -> Core.Result<Types.SearchCodesResultValue>?
	return SDK.pages(function(page: number): Core.Result<Types.SearchCodesResultValue>
		return client.codes:searchCodes({ query = { page = page, size = 100 } })
	end, function(page: Types.SearchCodesResultValue): boolean
		return page.last
	end, 1000)
end
