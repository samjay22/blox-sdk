--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Fake = {}
export type Step = {
	status: number?,
	body: string?,
	headers: { [string]: string }?,
	delay: number?,
	fail: boolean?,
	check: ((Types.HttpRequest) -> ())?,
}
export type Fake = { backend: Types.Backend, count: () -> number, remaining: () -> number }
--- Return a deterministic scripted backend. Request headers/bodies are never retained or logged.
function Fake.new(runtime: Types.Runtime, steps: { Step }): Fake
	local index = 0
	local backend: Types.Backend = function(request: Types.HttpRequest): Types.HttpResponse
		index += 1
		local step = steps[index]
		assert(step, "Fake backend script exhausted")
		if step.check then
			step.check(request)
		end
		if step.delay then
			runtime.wait(step.delay)
		end
		if step.fail then
			error("Synthetic network failure")
		end
		return { StatusCode = step.status or 200, Body = step.body or "", Headers = step.headers or {} }
	end
	return {
		backend = backend,
		count = function(): number
			return index
		end,
		remaining = function(): number
			return math.max(0, #steps - index)
		end,
	}
end
return table.freeze(Fake)
