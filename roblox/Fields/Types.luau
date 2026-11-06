--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
export type PathSegment = string | number
export type Path = { PathSegment }
export type Numeric = { kind: "int" | "number", min: number?, max: number?, maxDelta: number? }
export type TypeExpr =
	Numeric
	| { kind: "bool" }
	| { kind: "string", minLength: number?, maxLength: number?, pattern: string? }
	| { kind: "enum", values: { string } }
	| { kind: "object", members: { [string]: { type: TypeExpr, default: Core.Json?, optional: boolean? } } }
	| { kind: "list", item: TypeExpr, minSize: number?, maxSize: number? }
	| { kind: "set", item: TypeExpr, maxSize: number? }
	| { kind: "map", key: TypeExpr, value: TypeExpr, maxSize: number?, pruneZero: boolean? }
	| { kind: "nullable", of: TypeExpr }
export type Computed = { expression: string, returns: "int" | "number" }
export type LeaderboardOrder = "DESC" | "ASC"
export type LeaderboardReset = "NONE" | "DAILY" | "WEEKLY" | "MONTHLY" | "SEASONAL"
export type LeaderboardBinding = {
	board: string,
	submit: "VALUE",
	keep: ("LAST" | "BEST")?,
	order: LeaderboardOrder?,
	reset: LeaderboardReset?,
	displayName: string?,
} | {
	board: string,
	submit: "DELTA",
	keep: nil?,
	order: LeaderboardOrder?,
	reset: LeaderboardReset?,
	displayName: string?,
}
export type Bindings = {
	leaderboards: { LeaderboardBinding }?,
	audit: ("NONE" | "ADMIN_ONLY" | "ALL")?,
	runtime: { enabledFlag: string?, maxDeltaConfigKey: string? }?,
}
type OperationShape<S> =
	{
		field: string,
		subject: S?,
		path: Path?,
		op: "SET" | "MIN" | "MAX" | "REMOVE_VALUE",
		value: Core.Json,
	}
	| { field: string, subject: S?, path: Path?, op: "RESET" }
	| { field: string, subject: S?, path: Path?, op: "ADD", delta: number }
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "APPEND" | "SET_ADD" | "SET_REMOVE",
		items: { Core.Json },
	}
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "INSERT",
		index: number,
		items: { Core.Json },
	}
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "REMOVE_AT",
		index: number,
		count: number?,
	}
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "MAP_PUT",
		entries: { [string]: Core.Json },
	}
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "MAP_REMOVE",
		keys: { string },
	}
	| {
		field: string,
		subject: S?,
		path: Path?,
		op: "MAP_ADD",
		key: string,
		delta: number,
	}
export type PlayerOperation = OperationShape<nil>
export type Operation = OperationShape<number>
export type Expectation = { version: number } | { equals: Core.Json } | { exists: boolean }
export type Condition =
	{ field: string, subject: number?, path: Path? }
	& ({ expectedVersion: number } | { equals: Core.Json } | { exists: boolean })
return {}
