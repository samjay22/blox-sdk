--!strict
-- Minimal typed boundary for the pinned Lune 0.8.9 built-ins; no runtime dependencies.
export type Process = { args: { string }, env: { [string]: string }, exit: (number) -> never }
export type Task = {
	wait: (number) -> number,
	spawn: (() -> ()) -> thread,
	delay: (number, () -> ()) -> thread,
	cancel: (thread) -> (),
}
export type Net = {
	request: (
		{ url: string, method: string, headers: { [string]: string }, body: string? }
	) -> {
		statusCode: number,
		body: string,
		headers: { [string]: string },
	},
}
return {}
