--!strict
local Types = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local Scheduler = {}
export type Job = { at: number, order: number, worker: thread }
export type Scheduler = {
	runtime: Types.Runtime,
	run: (() -> ()) -> (),
	json: (unknown) -> string,
	pending: () -> number,
	time: () -> number,
}
--- Build a deterministic cooperative scheduler; no sleeps, wall clock or HTTP required.
function Scheduler.new(): Scheduler
	local now = 0
	local sequence = 0
	local jobs: { Job } = {}
	local cancelled: { [thread]: boolean } = {}
	local fixtures: { [string]: unknown } = {}
	--- Schedule a coroutine at an absolute virtual instant.
	local function enqueue(worker: thread, at: number)
		sequence += 1
		jobs[#jobs + 1] = { worker = worker, at = at, order = sequence }
	end
	--- Encode a fixture and register its decoded value for the injected codec.
	local function json(value: unknown): string
		local text = Json.encode(value)
		fixtures[text] = value
		return text
	end
	local runtime: Types.Runtime = {
		now = function(): number
			return now
		end,
		unix = function(): number
			return 1700000000 + now
		end,
		random = function(): number
			return 0.5
		end,
		wait = function(seconds: number)
			coroutine.yield(math.max(seconds, 0.000001))
		end,
		spawn = function(callback: () -> ()): thread
			local worker = coroutine.create(callback)
			enqueue(worker, now)
			return worker
		end,
		delay = function(seconds: number, callback: () -> ()): thread
			local worker = coroutine.create(callback)
			enqueue(worker, now + seconds)
			return worker
		end,
		cancel = function(worker: thread)
			cancelled[worker] = true
		end,
		encode = Json.encode,
		decode = function(body: string): unknown
			local value = fixtures[body]
			assert(value ~= nil, "Unregistered JSON fixture")
			return value
		end,
	}
	--- Drain all work in timestamp/insertion order, detecting runaway waits.
	local function run(callback: () -> ())
		runtime.spawn(callback)
		local iterations = 0
		while #jobs > 0 do
			iterations += 1
			assert(iterations < 200000, "Scheduler runaway")
			local selected = 1
			for i = 2, #jobs do
				if
					jobs[i].at < jobs[selected].at
					or (jobs[i].at == jobs[selected].at and jobs[i].order < jobs[selected].order)
				then
					selected = i
				end
			end
			local job = table.remove(jobs, selected)
			assert(job ~= nil, "Scheduler selected a missing job")
			if not cancelled[job.worker] then
				now = math.max(now, job.at)
				local ok, delay = coroutine.resume(job.worker)
				assert(ok, tostring(delay))
				if coroutine.status(job.worker) ~= "dead" then
					assert(type(delay) == "number", "Unexpected coroutine yield")
					enqueue(job.worker, now + delay)
				end
			end
		end
	end
	return {
		runtime = runtime,
		run = run,
		json = json,
		pending = function(): number
			return #jobs
		end,
		time = function(): number
			return now
		end,
	}
end
return Scheduler
