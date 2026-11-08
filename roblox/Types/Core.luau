--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- Shared boundary contracts; unknown is used for untrusted JSON, never credentials.
export type Null = { __bloxNull: true }
export type Json = Null | boolean | number | string | { Json } | { [string]: Json }
export type ErrorKind =
	"Unauthorized"
	| "Forbidden"
	| "NotFound"
	| "Conflict"
	| "Validation"
	| "RateLimited"
	| "Server"
	| "Network"
	| "Timeout"
	| "CircuitOpen"
	| "Cancelled"
	| "Local"
export type OperationDiagnostic = { opIndex: number, field: string, path: { string | number }, code: string }
export type BloxError = {
	kind: ErrorKind,
	message: string,
	status: number?,
	endpoint: string,
	attempts: number,
	body: string?,
	code: string?,
	path: { string | number }?,
	field: string?,
	opIndex: number?,
	placeId: number?,
	errors: { OperationDiagnostic }?,
	grantPending: boolean?,
}
export type Result<T> =
	{ ok: true, value: T, status: number?, stale: boolean?, etag: string? }
	| { ok: false, error: BloxError }
export type Signal = { cancelled: boolean }
export type CallOptions = {
	deadline: number?,
	priority: ("critical" | "bulk")?,
	retry: number?,
	cacheTtl: number?,
	signal: Signal?,
}
export type Secret = { AddPrefix: (self: Secret, prefix: string) -> Secret }
export type Headers = { [string]: string | Secret }
export type HttpRequest = { Url: string, Method: string, Headers: Headers, Body: string? }
export type HttpResponse = { StatusCode: number, Body: string, Headers: { [string]: string } }
export type Backend = (HttpRequest) -> HttpResponse
export type Runtime = {
	now: () -> number,
	unix: () -> number,
	random: () -> number,
	guid: (() -> string)?,
	wait: (number) -> (),
	spawn: (() -> ()) -> thread,
	delay: (number, () -> ()) -> thread,
	cancel: (thread) -> (),
	encode: (unknown, Schema?, { [string]: Schema }?) -> string,
	decode: (string) -> unknown,
}
export type Level = "READ" | "READ_WRITE" | "ADMIN"
export type ServiceLevels = {
	AuthService: Level?,
	MatchmakingService: Level?,
	PartyService: Level?,
	CodeService: Level?,
	Gateway: Level?,
	AuditService: Level?,
	LeaderboardService: Level?,
	FieldsService: Level?,
	PlatformService: Level?,
}
export type AuthProvider = {
	kind: string,
	universeId: (string | number)?,
	levels: { [string]: Level }?,
	role: string?,
	apply: (Headers) -> (),
	onUnauthorized: (number?, number?, Signal?) -> boolean,
	version: (() -> number)?,
	prepare: ((number?, Signal?) -> ())?,
	ready: ((number?, Signal?) -> Result<any>)?,
	invalidate: ((number?) -> ())?,
	destroy: (() -> ())?,
}
export type Param = { name: string, type: string, required: boolean, scopeDefault: boolean? }
export type Endpoint = {
	id: string,
	method: string,
	path: string,
	service: string,
	serviceName: string,
	minimumLevel: string?,
	requiredRole: string?,
	authKinds: { string },
	idempotent: boolean,
	retryable: boolean,
	cacheable: boolean,
	responseType: string,
	responseFormat: string,
	responseContentType: string?,
	requestFormat: string?,
	idempotencyHeader: boolean?,
	pathParams: { Param },
	queryParams: { Param },
	bodyType: string?,
	bodyRequired: boolean,
	segments: { string },
	idempotencyField: string?,
	idempotencyItems: string?,
	conditional: boolean?,
	optionalKey: boolean?,
}
export type Request = {
	idempotencyKey: string?,
	etag: string?,
	path: { [string]: unknown }?,
	query: { [string]: unknown }?,
	body: unknown?,
}
export type Invoke = (Endpoint, unknown, CallOptions?, (string | number)?) -> Result<any>
export type Event = {
	endpoint: string?,
	status: number?,
	attempt: number?,
	duration: number?,
	host: string?,
	state: string?,
}
export type Hooks = {
	onRequest: ((Event) -> ())?,
	onResponse: ((Event) -> ())?,
	onRetry: ((Event) -> ())?,
	onBreakerChange: ((Event) -> ())?,
	onRateLimited: ((Event) -> ())?,
}
export type Schema = {
	kind: string,
	name: string?,
	item: Schema?,
	items: { Schema }?,
	fields: { [string]: { schema: Schema, required: boolean, notBlank: boolean } }?,
	values: { string }?,
}
export type EndpointSchema = { service: string, body: Schema?, response: Schema }
return {}
