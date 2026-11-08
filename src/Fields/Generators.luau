--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Helpers = require("./Client")
local Scope = require("./Scope")
local Control = require("./Control")
local System = require("./TypeSystem")
local Generators = {}
Generators.__index = Generators
export type Options = { count: number?, idempotencyKey: string? }
export type Client = typeof(setmetatable({} :: { _scope: Scope.Scope }, Generators))
--- Bind player randomness to a trusted server's universe without issuing HTTP.
function Generators.new(state: Helpers.State, universe: string | number): Client
	return setmetatable({ _scope = Scope.new(state, universe) }, Generators)
end
--- Check the published resource-key grammar before encoding a route or request body.
function Generators.validKey(key: unknown): boolean
	return type(key) == "string" and #key <= 100 and string.match(key, "^[A-Za-z][A-Za-z0-9_.%-]*$") ~= nil
end
--- Validate closed roll/preview options without changing caller-owned input.
local function validOptions(options: Options?): boolean
	local raw: any = options or {}
	return Control.object(raw, { "count", "idempotencyKey" })
		and (raw.count == nil or type(raw.count) == "number" and raw.count % 1 == 0 and raw.count >= 1 and raw.count <= 10)
		and (raw.idempotencyKey == nil or Control.key(raw.idempotencyKey))
end
--- Atomically charge all packs, apply grants/pity and permanently replay the saved response.
function Generators.Roll(
	self: Client,
	key: string,
	playerId: number,
	options: Options?,
	callOptions: Core.CallOptions?
): Core.Result<Wire.GeneratorRollResult>
	if not Generators.validKey(key) or not Control.subject(playerId) or not validOptions(options) then
		return System.failure("invalid_request")
	end
	return Scope.call(self._scope, "fields.rollGenerator", {
		body = {
			generator = key,
			playerId = playerId,
			count = if options then options.count else nil,
			idempotencyKey = if options then options.idempotencyKey else nil,
		},
	}, callOptions)
end
--- Generate read-only packs with optional player context; no costs, grants or pity are written.
function Generators.Preview(
	self: Client,
	key: string,
	playerId: number?,
	count: number?,
	callOptions: Core.CallOptions?
): Core.Result<{ Wire.Generated }>
	if
		not Generators.validKey(key)
		or playerId ~= nil and not Control.subject(playerId)
		or not validOptions({ count = count })
	then
		return System.failure("invalid_request")
	end
	return Scope.call(
		self._scope,
		"fields.previewGenerator",
		{ body = { generator = key, playerId = playerId, count = count } },
		callOptions
	)
end
--- Read exact eligible TABLE odds, not generator odds after uniqueness, guarantees or pity.
function Generators.GetOdds(
	self: Client,
	tableKey: string,
	playerId: number?,
	callOptions: Core.CallOptions?
): Core.Result<Wire.RandomOdds>
	if not Generators.validKey(tableKey) or playerId ~= nil and not Control.subject(playerId) then
		return System.failure("invalid_request")
	end
	return Scope.call(
		self._scope,
		"fields.tableOdds",
		{ path = { key = tableKey }, query = { playerId = playerId } },
		callOptions
	)
end
return table.freeze(Generators)
