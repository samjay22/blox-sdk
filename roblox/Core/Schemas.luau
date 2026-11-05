--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- Generated validation schemas.
local Core = require(script.Parent.Parent.Types.Core)
local Cache = require(script.Parent.Parent.Core.Cache)
local definitions: { [string]: { [string]: Core.Schema } } = {
	["audit"] = {
		["ActorType"] = {
			["kind"] = "enum",
			["values"] = { "USER", "SERVICE_ACCOUNT", "SERVICE", "SYSTEM" },
		} :: Core.Schema,
		["BatchInput"] = {
			["fields"] = {
				["events"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "EventInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Count"] = {
			["fields"] = {
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Event"] = {
			["fields"] = {
				["action"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorType"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ActorType" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idemKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ipHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["occurredAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["outcome"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Outcome" } :: Core.Schema,
				},
				["receivedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resourceId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resourceType"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sourceService"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["submittedBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Submission" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["EventInput"] = {
			["fields"] = {
				["action"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorType"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ActorType" } :: Core.Schema,
				},
				["idemKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ipHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["occurredAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["outcome"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Outcome" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resourceId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resourceType"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GroupBy"] = { ["kind"] = "enum", ["values"] = { "action", "actor", "outcome" } } :: Core.Schema,
		["HealthComponent"] = {
			["fields"] = {
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["service"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MetricsResponse"] = {
			["fields"] = {
				["names"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Outcome"] = { ["kind"] = "enum", ["values"] = { "SUCCESS", "DENIED", "FAILURE" } } :: Core.Schema,
		["Receipt"] = {
			["fields"] = {
				["accepted"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["duplicate"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Retention"] = {
			["fields"] = {
				["days"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RetentionInput"] = {
			["fields"] = {
				["days"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Submission"] = {
			["fields"] = {
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sourceService"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Summary"] = {
			["fields"] = {
				["groupBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "GroupBy" } :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Count" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["nextCursor"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["auth"] = {
		["AccountCreateRequest"] = {
			["fields"] = {
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["password"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccountPromoteRequest"] = {
			["fields"] = {
				["accountType"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccountResponse"] = {
			["fields"] = {
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccountType"] = {
			["kind"] = "enum",
			["values"] = { "SUPER_ADMIN", "ADMIN", "UNIVERSE_ACCOUNT", "PENDING" },
		} :: Core.Schema,
		["AccountUpdateRequest"] = {
			["fields"] = {
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["database"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginRequest"] = {
			["fields"] = {
				["password"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PasswordChangeRequest"] = {
			["fields"] = {
				["currentPassword"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["newPassword"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PasswordResetConfirmDto"] = {
			["fields"] = {
				["newPassword"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["token"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PasswordResetRequestDto"] = {
			["fields"] = {
				["email"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlaceCreateRequest"] = {
			["fields"] = {
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlaceResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshRequest"] = {
			["fields"] = {
				["refreshToken"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccessLevel"] = {
			["kind"] = "enum",
			["values"] = {
				"READ",
				"READ_WRITE",
				"ADMIN",
			},
		} :: Core.Schema,
		["ServiceAccountCreateRequest"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["permissions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionRequest" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccountPatchRequest"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccountResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["lastUsedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["permissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["revokedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceDefinitionCreateRequest"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceDefinitionResponse"] = {
			["fields"] = {
				["builtIn"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceDefinitionUpdateRequest"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServicePermissionRequest"] = {
			["fields"] = {
				["accessLevel"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServicePermissionResponse"] = {
			["fields"] = {
				["accessLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["TokenValidateRequest"] = {
			["fields"] = {
				["token"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["TokenValidateResponse"] = {
			["fields"] = {
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["serviceAccount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseCreateRequest"] = {
			["fields"] = {
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseEnabledRequest"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["places"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["codes"] = {
		["AwardDefinitionDto"] = {
			["fields"] = {
				["operations"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "AwardOperationDto" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AwardOperationDto"] = {
			["fields"] = {
				["operation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AwardOperationType" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AwardOperationType"] = {
			["kind"] = "enum",
			["values"] = { "SET", "INCREMENT", "DECREMENT", "MULTIPLY", "APPEND", "REMOVE" },
		} :: Core.Schema,
		["CodeDto"] = {
			["fields"] = {
				["active"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AwardDefinitionDto" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["redeemableNow"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["remainingGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timesRedeemed"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CodeRedemptionDto"] = {
			["fields"] = {
				["awardSnapshot"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AwardDefinitionDto" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["codeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["dataAfter"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["dataBefore"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redeemedByAccountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["redemptionKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateCodeRequest"] = {
			["fields"] = {
				["active"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AwardDefinitionDto" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["database"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RedeemCodeRequest"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redemptionKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RedeemCodeResponse"] = {
			["fields"] = {
				["awardedData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["codeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redeemedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["redemptionId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UpdateCodeRequest"] = {
			["fields"] = {
				["active"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AwardDefinitionDto" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["config"] = {
		["AttributeMatch"] = {
			["fields"] = {
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Entry"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ValueType" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["EntryPut"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expectedVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ValueType" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Evaluation"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["EvaluationRequest"] = {
			["fields"] = {
				["attributes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["keys"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Flag"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["endsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rolloutPercent"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rules"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Rules" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagPut"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["endsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expectedVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rolloutPercent"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rules"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Rules" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FullState"] = {
			["fields"] = {
				["entries"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["flags"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Flag" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "State" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthComponent"] = {
			["fields"] = {
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["service"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["History"] = {
			["fields"] = {
				["change"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "FullState" } :: Core.Schema,
				},
				["changedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["changedBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MaintenancePut"] = {
			["fields"] = {
				["maintenance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["maintenanceMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MetricsResponse"] = {
			["fields"] = {
				["names"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Rollback"] = {
			["fields"] = {
				["toVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Rules"] = {
			["fields"] = {
				["allowUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["attributes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "AttributeMatch" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["denyUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["minAccountAgeDays"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Snapshot"] = {
			["fields"] = {
				["entries"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["flags"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Flag" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["maintenance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["maintenanceMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["State"] = {
			["fields"] = {
				["maintenance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["maintenanceMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ValueType"] = { ["kind"] = "enum", ["values"] = { "STRING", "NUMBER", "BOOLEAN", "JSON" } } :: Core.Schema,
	},
	["data"] = {
		["AccountType"] = {
			["kind"] = "enum",
			["values"] = { "SUPER_ADMIN", "ADMIN", "UNIVERSE_ACCOUNT", "PENDING" },
		} :: Core.Schema,
		["BatchUserDataSyncItem"] = {
			["fields"] = {
				["dataVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["markOffline"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchUserDataSyncItemResult"] = {
			["fields"] = {
				["action"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["appliedPendingUpdateIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["serverChangesApplied"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["userData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchUserDataSyncRequest"] = {
			["fields"] = {
				["players"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BatchUserDataSyncItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchUserDataSyncResult"] = {
			["fields"] = {
				["failed"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BulkUserDataUpdateFailure" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["synced"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BatchUserDataSyncItemResult" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkUserDataUpdateFailure"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkUserDataUpdateItem"] = {
			["fields"] = {
				["jsonData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkUserDataUpdateRequest"] = {
			["fields"] = {
				["updates"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BulkUserDataUpdateItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkUserDataUpdateResult"] = {
			["fields"] = {
				["failed"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BulkUserDataUpdateFailure" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["updated"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateSchemaRequest"] = {
			["fields"] = {
				["defaults"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["jsonSchema"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["virtualFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "VirtualFieldDefinition" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateUserDataRequest"] = {
			["fields"] = {
				["baseData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["jsonData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DataSnapshotDto"] = {
			["fields"] = {
				["completedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["errorMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["recordCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["schemaVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["triggerType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["database"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginRequest"] = {
			["fields"] = {
				["password"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PendingUpdateDto"] = {
			["fields"] = {
				["appliedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["errorMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["originalData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["requestedData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["retryCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshRequest"] = {
			["fields"] = {
				["refreshToken"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SchemaDefaultsDto"] = {
			["fields"] = {
				["defaults"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["schemaVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SchemaMigrationDto"] = {
			["fields"] = {
				["completedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["errorMessage"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["executedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fromVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["migrationScript"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["recordsProcessed"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["recordsTotal"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["schemaVersionId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["toVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SchemaVersionDto"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["defaults"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["isActive"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["jsonSchema"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["virtualFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "VirtualFieldDefinition" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccessLevel"] = {
			["kind"] = "enum",
			["values"] = {
				"READ",
				"READ_WRITE",
				"ADMIN",
			},
		} :: Core.Schema,
		["ServicePermissionResponse"] = {
			["fields"] = {
				["accessLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UserDataDto"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["jsonData"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["schemaVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["virtualFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["VirtualFieldDefinition"] = {
			["fields"] = {
				["expression"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["economy"] = {
		["Adjustment"] = {
			["fields"] = {
				["currency"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["delta"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AmountInput"] = {
			["fields"] = {
				["amount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["currency"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ref"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Ref" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Balance"] = {
			["fields"] = {
				["balance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["currencyCode"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Batch"] = {
			["fields"] = {
				["codes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Currency"] = {
			["fields"] = {
				["allowNegative"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["decimals"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxBalance"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CurrencyInput"] = {
			["fields"] = {
				["allowNegative"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["decimals"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxBalance"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CurrencyPatch"] = {
			["fields"] = {
				["allowNegative"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["clearMaxBalance"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["decimals"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxBalance"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Entry"] = {
			["fields"] = {
				["balanceAfter"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["counterpartUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["currencyCode"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["delta"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["refId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["refType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestHash"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reversesId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Grant"] = {
			["fields"] = {
				["amount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["currency"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthComponent"] = {
			["fields"] = {
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["service"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ItemGrant"] = {
			["fields"] = {
				["amount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["item"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MetricsResponse"] = {
			["fields"] = {
				["names"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Mismatch"] = {
			["fields"] = {
				["balance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["currencyCode"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ledgerBalance"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Product"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["grants"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Grant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ItemGrant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["robloxProductId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["sku"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ProductInput"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["grants"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Grant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ItemGrant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["sku"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Reason"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ReceiptInput"] = {
			["fields"] = {
				["currencySpentRobux"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["productId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["purchaseId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Ref"] = {
			["fields"] = {
				["id"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Result"] = {
			["fields"] = {
				["entries"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["purchaseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Transfer"] = {
			["fields"] = {
				["amount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "decimal" } :: Core.Schema,
				},
				["currency"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fromUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["toUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["leaderboards"] = {
		["Aggregation"] = { ["kind"] = "enum", ["values"] = { "BEST", "SUM", "LAST", "MIN", "MAX" } } :: Core.Schema,
		["Board"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Aggregation" } :: Core.Schema,
				},
				["archived"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["currentPeriodId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxScore"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minScore"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["periodStartedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["revision"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "SortOrder" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateBoard"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Aggregation" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxScore"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minScore"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "SortOrder" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthComponent"] = {
			["fields"] = {
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["service"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MatchInput"] = {
			["fields"] = {
				["matchId"] = {
					["notBlank"] = true,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["scope"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["teams"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Team" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MatchResult"] = {
			["fields"] = {
				["matchId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RatingChange" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MetricsResponse"] = {
			["fields"] = {
				["names"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PatchBoard"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Aggregation" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "SortOrder" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Period"] = {
			["fields"] = {
				["closedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["periodId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["total"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Rating"] = {
			["fields"] = {
				["deviation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["games"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rating"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["ratingScope"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RatingChange"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["deviation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["games"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RatingConfig"] = {
			["fields"] = {
				["floor"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["initialRating"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["kFactor"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ResetSchedule"] = {
			["kind"] = "enum",
			["values"] = { "NONE", "DAILY", "WEEKLY", "MONTHLY", "SEASONAL" },
		} :: Core.Schema,
		["ScoreBatch"] = {
			["fields"] = {
				["scores"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ScoreInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScoreInput"] = {
			["fields"] = {
				["displayName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["score"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["submissionId"] = {
					["notBlank"] = true,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScoreResult"] = {
			["fields"] = {
				["applied"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["periodId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["score"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["submissionId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SortOrder"] = { ["kind"] = "enum", ["values"] = { "ASC", "DESC" } } :: Core.Schema,
		["Standing"] = {
			["fields"] = {
				["percentile"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rank"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["score"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["total"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Team"] = {
			["fields"] = {
				["placement"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UserIds"] = {
			["fields"] = {
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["matchmaking"] = {
		["AccountType"] = {
			["kind"] = "enum",
			["values"] = { "SUPER_ADMIN", "ADMIN", "UNIVERSE_ACCOUNT", "PENDING" },
		} :: Core.Schema,
		["ApiKeyResponse"] = {
			["fields"] = {
				["apiKey"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "RobloxApiKeyResponse" } :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ApiKeysResponse"] = {
			["fields"] = {
				["apiKeys"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RobloxApiKeyResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BanCheckResponse"] = {
			["fields"] = {
				["isBanned"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BanListResponse"] = {
			["fields"] = {
				["bans"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BannedPlayerResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BanPlayerRequest"] = {
			["fields"] = {
				["expiresInHours"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BanResponse"] = {
			["fields"] = {
				["ban"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "BannedPlayerResponse" } :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BannedPlayerResponse"] = {
			["fields"] = {
				["bannedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["bannedBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["isExpired"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BaseQueueRequest"] = {
			["fields"] = {
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["items"] = {
							{ ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
							{ ["kind"] = "string" } :: Core.Schema,
						},
						["kind"] = "union",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkBanResponse"] = {
			["fields"] = {
				["bannedCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["bans"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BannedPlayerResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["totalRequests"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkQueueStatusRequest"] = {
			["fields"] = {
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkQueueStatusResponse"] = {
			["fields"] = {
				["results"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlayerQueueStatusResponse" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkUnbanResponse"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["totalRequests"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["unbannedCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CleanupResponse"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["removedCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateGameModeRequest"] = {
			["fields"] = {
				["matchmakingCriteria"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaExplanationResponse"] = {
			["fields"] = {
				["gameModeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["optionalMetadataFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaFieldInfo" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["requiredMetadataFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaFieldInfo" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaFieldInfo"] = {
			["fields"] = {
				["constraint"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["criteriaType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["required"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaType"] = {
			["kind"] = "enum",
			["values"] = {
				"RANGE",
				"GROUP_BY",
				"TEAM_TOTAL",
				"THRESHOLD",
				"WEIGHTED",
				"CROSS_GROUP",
				"TEAM_SIZE",
				"LATENCY",
				"REGION",
				"SKILL_BASED",
				"PARTY",
				"BALANCE",
				"LEVEL_RANGE",
				"EXCLUDE",
				"PRIORITY",
				"FILL",
			},
		} :: Core.Schema,
		["CriteriaValidationError"] = {
			["fields"] = {
				["actualValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["criteriaType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaType" } :: Core.Schema,
				},
				["expectedConstraint"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DeleteApiKeyResponse"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GameModeQueueInfo"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlayerInQueueInfo" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GameModeResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["isJail"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["matchmakingCriteria"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["database"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginRequest"] = {
			["fields"] = {
				["password"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MatchmakingCriteriaDTO"] = {
			["fields"] = {
				["allowCrossRegion"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["bracketSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["groupCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxDifference"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxLatencyDiff"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxPlayers"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["skillRange"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["targetValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["tolerance"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaType" } :: Core.Schema,
				},
				["weight"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MultiQueueRequest"] = {
			["fields"] = {
				["gameModeNames"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["items"] = {
							{ ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
							{ ["kind"] = "string" } :: Core.Schema,
						},
						["kind"] = "union",
					} :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerMetadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = {
							["item"] = { ["kind"] = "json" } :: Core.Schema,
							["kind"] = "map",
						} :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["items"] = {
							{ ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
							{ ["kind"] = "string" } :: Core.Schema,
						},
						["kind"] = "union",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MultiQueueResponse"] = {
			["fields"] = {
				["bannedUserIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resolvedGameModes"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["userIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlaceResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerInQueueInfo"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerQueueStatusResponse"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["gameModeNames"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["inQueue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["queuedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["QueueCountResponse"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["queuedPlayerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["QueueFlushResponse"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["removedCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["QueueMetricsResponse"] = {
			["fields"] = {
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["totalPlayersInQueue"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeBreakdown"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "UniverseQueueInfo" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["QueueRequest"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerMetadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = {
							["item"] = { ["kind"] = "json" } :: Core.Schema,
							["kind"] = "map",
						} :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["queuedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["items"] = {
							{ ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
							{ ["kind"] = "string" } :: Core.Schema,
						},
						["kind"] = "union",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["QueueResponse"] = {
			["fields"] = {
				["bannedUserIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resolvedGameMode"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["userIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshRequest"] = {
			["fields"] = {
				["refreshToken"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RemovePlayerQueueRequest"] = {
			["fields"] = {
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["items"] = {
							{ ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
							{ ["kind"] = "string" } :: Core.Schema,
						},
						["kind"] = "union",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RobloxApiKeyRequest"] = {
			["fields"] = {
				["robloxApiKey"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RobloxApiKeyResponse"] = {
			["fields"] = {
				["masked"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["robloxApiKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccessLevel"] = {
			["kind"] = "enum",
			["values"] = {
				"READ",
				"READ_WRITE",
				"ADMIN",
			},
		} :: Core.Schema,
		["ServicePermissionResponse"] = {
			["fields"] = {
				["accessLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SuccessMessage"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UnbanResponse"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseBanListResponse"] = {
			["fields"] = {
				["bans"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BannedPlayerResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseInfoEnvelope"] = {
			["fields"] = {
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universe"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "UniverseInfoResponse" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseInfoResponse"] = {
			["fields"] = {
				["apiKeyConfigured"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["bannedPlayerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["gameModeCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseQueueInfo"] = {
			["fields"] = {
				["gameModes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "GameModeQueueInfo" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["totalPlayers"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniverseResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["places"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UniversesEnvelope"] = {
			["fields"] = {
				["success"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universe"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "UniverseResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UpdateBanRequest"] = {
			["fields"] = {
				["expiresInHours"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UpdateGameModeRequest"] = {
			["fields"] = {
				["matchmakingCriteria"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UpdateRobloxApiKeyRequest"] = {
			["fields"] = {
				["robloxApiKey"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ValidateQueueResponse"] = {
			["fields"] = {
				["errors"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaValidationError" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["WaitEstimateResponse"] = {
			["fields"] = {
				["estimatedWaitSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxMatchSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["oldestEntryAgeSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["playersNeeded"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["queuedPlayerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["party"] = {
		["AccountType"] = {
			["kind"] = "enum",
			["values"] = { "SUPER_ADMIN", "ADMIN", "UNIVERSE_ACCOUNT", "PENDING" },
		} :: Core.Schema,
		["AddMemberRequest"] = {
			["fields"] = {
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requesterId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreatePartyRequest"] = {
			["fields"] = {
				["ownerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DeletePartyRequest"] = {
			["fields"] = {
				["ownerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["HealthResponse"] = {
			["fields"] = {
				["database"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["KickMemberRequest"] = {
			["fields"] = {
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requesterId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LeavePartyRequest"] = {
			["fields"] = {
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginRequest"] = {
			["fields"] = {
				["password"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["LoginResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PartyMemberResponse"] = {
			["fields"] = {
				["joinedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PartyResponse"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["members"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PartyMemberResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["ownerId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PartyUpdate"] = {
			["fields"] = {
				["ownerId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updateType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshRequest"] = {
			["fields"] = {
				["refreshToken"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RefreshResponse"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RemoveMemberRequest"] = {
			["fields"] = {
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requesterId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServerUpdateResponse"] = {
			["fields"] = {
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updates"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PartyUpdate" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccessLevel"] = {
			["kind"] = "enum",
			["values"] = {
				"READ",
				"READ_WRITE",
				"ADMIN",
			},
		} :: Core.Schema,
		["ServicePermissionResponse"] = {
			["fields"] = {
				["accessLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["TransferLeadershipRequest"] = {
			["fields"] = {
				["currentOwnerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["newOwnerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
}
local endpoints: { [string]: Core.EndpointSchema } = {
	["audit.actions"] = {
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "cursorPage" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.append"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EventInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Receipt" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.batch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BatchInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Receipt" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.get"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Event" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.list"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Event" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "audit",
	},
	["audit.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.putRetention"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RetentionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Retention" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.retention"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Retention" } :: Core.Schema,
		["service"] = "audit",
	},
	["audit.summary"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Summary" } :: Core.Schema,
		["service"] = "audit",
	},
	["auth.addPlace"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlaceCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.changePassword"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PasswordChangeRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.confirmReset"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PasswordResetConfirmDto" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AccountCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createAdminAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AccountCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createService"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceDefinitionCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceDefinitionResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createServiceAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceAccountCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UniverseCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createUniverseAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AccountCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.deleteAccount"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deleteAccountRest"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deletePermission"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deletePermissionRest"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.deletePlace"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deletePlaceRest"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deleteService"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deleteUniverse"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deleteUniverseRest"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.enableAccount"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getAccountById"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getAccountByUsername"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getAllAccounts"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getMe"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getPlace"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getServiceAccount"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getUniverses"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "UniverseResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.health"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listPermissions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listPlaces"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listServiceAccounts"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listServices"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ServiceDefinitionResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.login"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "LoginRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "LoginResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.logout"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.patchServiceAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceAccountPatchRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.promoteAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AccountPromoteRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.refresh"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RefreshResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.requestReset"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PasswordResetRequestDto" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.revokeServiceAccount"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.rotateServiceAccount"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.setEnabled"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UniverseEnabledRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.setServiceAccountPermissions"] = {
		["body"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionRequest" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.updateAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AccountUpdateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.updatePlace"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlaceCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.updateService"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceDefinitionUpdateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceDefinitionResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.updateUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UniverseCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.upsertPermission"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServicePermissionRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.validateToken"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "TokenValidateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "TokenValidateResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["codes.createCode"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateCodeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.deleteCode"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "codes" },
	["codes.getCode"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.listRedemptions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "CodeRedemptionDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "codes",
	},
	["codes.redeem"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RedeemCodeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RedeemCodeResponse" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.searchCodes"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "codes",
	},
	["codes.updateCode"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UpdateCodeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
		["service"] = "codes",
	},
	["config.deleteEntry"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "config" },
	["config.deleteFlag"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "config" },
	["config.entries"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "config",
	},
	["config.entry"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
		["service"] = "config",
	},
	["config.evaluate"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EvaluationRequest" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Evaluation" } :: Core.Schema,
			["kind"] = "map",
		} :: Core.Schema,
		["service"] = "config",
	},
	["config.evaluateFlag"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EvaluationRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Evaluation" } :: Core.Schema,
		["service"] = "config",
	},
	["config.flag"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Flag" } :: Core.Schema,
		["service"] = "config",
	},
	["config.flags"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Flag" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "config",
	},
	["config.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "config",
	},
	["config.history"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "History" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "config",
	},
	["config.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "config",
	},
	["config.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "config",
	},
	["config.maintenance"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "State" } :: Core.Schema,
		["service"] = "config",
	},
	["config.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "config",
	},
	["config.putEntry"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EntryPut" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
		["service"] = "config",
	},
	["config.putFlag"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FlagPut" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Flag" } :: Core.Schema,
		["service"] = "config",
	},
	["config.putMaintenance"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MaintenancePut" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "State" } :: Core.Schema,
		["service"] = "config",
	},
	["config.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "config",
	},
	["config.rollback"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Rollback" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "State" } :: Core.Schema,
		["service"] = "config",
	},
	["config.snapshot"] = {
		["response"] = {
			["items"] = {
				{ ["kind"] = "ref", ["name"] = "Snapshot" } :: Core.Schema,
				{ ["kind"] = "nil" } :: Core.Schema,
			},
			["kind"] = "union",
		} :: Core.Schema,
		["service"] = "config",
	},
	["data.bulkUpdateUserData"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkUserDataUpdateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkUserDataUpdateResult" } :: Core.Schema,
		["service"] = "data",
	},
	["data.createManualSnapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.createOrUpdateSchema"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateSchemaRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SchemaVersionDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.createUserData"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateUserDataRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.deleteSnapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.deleteUserData"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "data" },
	["data.getAllSchemaMigrations"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "SchemaMigrationDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getAllSchemaVersions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "SchemaVersionDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getAllUserData"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getAllUserDataForUniverse"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getAllUserDataGroupedByUniverse"] = {
		["response"] = {
			["item"] = {
				["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
				["kind"] = "array",
			} :: Core.Schema,
			["kind"] = "map",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getPendingUpdates"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "PendingUpdateDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getSchemaDefaults"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "SchemaDefaultsDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.getSchemaVersions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "SchemaVersionDto" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getSnapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.getSnapshotsByUniverse"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getUserData"] = {
		["response"] = {
			["items"] = {
				{ ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
				{
					["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
					["kind"] = "array",
				} :: Core.Schema,
			},
			["kind"] = "union",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.getUserDataByRobloxUserId"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "data",
	},
	["data.listSnapshots"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "data",
	},
	["data.login"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "LoginRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "LoginResponse" } :: Core.Schema,
		["service"] = "data",
	},
	["data.logout"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "data",
	},
	["data.refreshToken"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RefreshResponse" } :: Core.Schema,
		["service"] = "data",
	},
	["data.rollbackToSnapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DataSnapshotDto" } :: Core.Schema,
		["service"] = "data",
	},
	["data.syncUserDataBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BatchUserDataSyncRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BatchUserDataSyncResult" } :: Core.Schema,
		["service"] = "data",
	},
	["data.triggerScheduledBackup"] = {
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "data",
	},
	["data.updateUserData"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateUserDataRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "UserDataDto" } :: Core.Schema,
		["service"] = "data",
	},
	["economy.adjust"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Adjustment" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.balance"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Balance" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.balances"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Balance" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.batch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Batch" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Balance" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.createCurrency"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CurrencyInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Currency" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.currencies"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Currency" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.deleteProduct"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.entry"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.grant"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AmountInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.ledger"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.patchCurrency"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CurrencyPatch" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Currency" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.product"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.products"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.putProduct"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ProductInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.receipt"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ReceiptInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.reconcile"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Mismatch" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "economy",
	},
	["economy.refund"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Reason" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.reverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Reason" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.spend"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AmountInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["economy.transfer"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Transfer" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "economy",
	},
	["leaderboards.archive"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.around"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Standing" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.batch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ScoreBatch" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ScoreResult" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.create"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateBoard" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Board" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.get"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Board" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.list"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Board" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.patch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PatchBoard" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Board" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.periodTop"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Standing" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.periods"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Period" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ranks"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UserIds" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Standing" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingConfig"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RatingConfig" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingConfigure"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RatingConfig" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RatingConfig" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingMatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MatchInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "MatchResult" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingTop"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Rating" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingUser"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Rating" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingUsers"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UserIds" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Rating" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.remove"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.rollover"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Board" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.submit"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ScoreInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ScoreResult" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.top"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Standing" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.user"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Standing" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["matchmaking.banPlayer"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BanPlayerRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.bulkBanPlayers"] = {
		["body"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "BanPlayerRequest" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkBanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.bulkUnbanPlayers"] = {
		["body"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkUnbanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.checkApiKeyExists"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.checkApiKeyExistsForCurrentUniverse"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.checkBanStatus"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "BanCheckResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.createApiKey"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RobloxApiKeyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.createGameMode"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateGameModeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "GameModeResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.createOrUpdateApiKey"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RobloxApiKeyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.deleteApiKey"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DeleteApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.deleteApiKeyForCurrentUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "DeleteApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.deleteGameMode"] = {
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.explainCriteria"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "CriteriaExplanationResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.flushQueue"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "QueueFlushResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getAllApiKeys"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeysResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getAllBannedPlayers"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "BanListResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getAllUniverses"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniversesEnvelope" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getApiKeyByUniverseId"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getApiKeyForCurrentUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getBannedPlayer"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "BanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getBannedPlayersByUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseBanListResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getBulkQueueStatus"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkQueueStatusRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkQueueStatusResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getGameModeByName"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "GameModeResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getGameModes"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "GameModeResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getPermanentBans"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseBanListResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getPlayerQueueStatus"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PlayerQueueStatusResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getQueueCount"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "QueueCountResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getQueueMetrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "QueueMetricsResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getTemporaryBans"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseBanListResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getUniverseInfo"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseInfoEnvelope" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getUniverseInfoForCurrentUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UniverseInfoEnvelope" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getWaitEstimate"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "WaitEstimateResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.getWaitEstimateAlias"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "WaitEstimateResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.joinQueue"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "QueueRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "QueueResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.joinQueues"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MultiQueueRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "MultiQueueResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.login"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "LoginRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "LoginResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.logout"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.metrics"] = {
		["response"] = { ["kind"] = "string" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.processMatchmaking"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "SuccessMessage" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.refreshToken"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RefreshResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.removeExpiredBans"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "CleanupResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.removePlayer"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RemovePlayerQueueRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SuccessMessage" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.removePlayerPost"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RemovePlayerQueueRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SuccessMessage" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.unbanPlayer"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "UnbanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.updateApiKey"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UpdateRobloxApiKeyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.updateApiKeyForCurrentUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UpdateRobloxApiKeyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ApiKeyResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.updateBan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UpdateBanRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BanResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.updateGameMode"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UpdateGameModeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "GameModeResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["matchmaking.validateQueue"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "QueueRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ValidateQueueResponse" } :: Core.Schema,
		["service"] = "matchmaking",
	},
	["party.addMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AddMemberRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.createParty"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreatePartyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.deleteParty"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "DeletePartyRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "party",
	},
	["party.getAllParties"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "party",
	},
	["party.getParty"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.getPartyByOwner"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.getUpdates"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ServerUpdateResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.health"] = { ["response"] = { ["kind"] = "string" } :: Core.Schema, ["service"] = "party" },
	["party.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.kickMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "KickMemberRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.leaveParty"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "LeavePartyRequest" } :: Core.Schema,
		["response"] = {
			["items"] = {
				{ ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
				{ ["kind"] = "nil" } :: Core.Schema,
			},
			["kind"] = "union",
		} :: Core.Schema,
		["service"] = "party",
	},
	["party.login"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "LoginRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "LoginResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.logout"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "party",
	},
	["party.refreshToken"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RefreshResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.removeMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RemoveMemberRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
	["party.transferLeadership"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "TransferLeadershipRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PartyResponse" } :: Core.Schema,
		["service"] = "party",
	},
}
return Cache.freeze({
	definitions = definitions,
	endpoints = endpoints,
}) :: {
	definitions: { [string]: { [string]: Core.Schema } },
	endpoints: { [string]: Core.EndpointSchema },
}
