--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- Generated validation schemas.
local Core = require(script.Parent.Parent.Types.Core)
local Cache = require(script.Parent.Parent.Core.Cache)
local healthResponse: Core.Schema = {
	["fields"] = {
		["status"] = {
			["notBlank"] = false,
			["required"] = true,
			["schema"] = {
				["kind"] = "string",
			} :: Core.Schema,
		},
	},
	["kind"] = "object",
} :: Core.Schema
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actorName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["actorType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ActorType" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idemKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["ipHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "json" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["occurredAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["outcome"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Outcome" } :: Core.Schema,
				},
				["receivedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["resourceId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resourceType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sourceService"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["submittedBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ipHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sourceService"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "GroupBy" } :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Count" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["nextCursor"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = {
							["item"] = { ["kind"] = "string" } :: Core.Schema,
							["kind"] = "nullable",
						} :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["auth"] = {
		["Accept"] = {
			["fields"] = {
				["token"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Access"] = {
			["fields"] = {
				["memberships"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["organization"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
				},
				["universes"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Scope" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccessEvent"] = {
			["fields"] = {
				["action"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["actor"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["target"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccountCreateRequest"] = {
			["fields"] = {
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
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
		["AccountResponse"] = {
			["fields"] = {
				["accountId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AccountType"] = { ["kind"] = "enum", ["values"] = { "SUPER_ADMIN", "USER" } } :: Core.Schema,
		["AccountUpdateRequest"] = {
			["fields"] = {
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ActorRequest"] = {
			["fields"] = {
				["actorId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AddMember"] = {
			["fields"] = {
				["overrides"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["AssignOwner"] = {
			["fields"] = {
				["accountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Create"] = {
			["fields"] = {
				["actorId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["operationId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateOrg"] = {
			["fields"] = {
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CreateUniverse"] = {
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
		["Created"] = {
			["fields"] = {
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["serviceAccountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["CreatedMember"] = {
			["fields"] = {
				["account"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
				},
				["member"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
				},
				["temporaryPassword"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Invitation"] = {
			["fields"] = {
				["acceptedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["revokedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["targetUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Invite"] = {
			["fields"] = {
				["expiresInDays"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["usernameOrEmail"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Issued"] = {
			["fields"] = {
				["acceptPath"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["invitation"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Invitation" } :: Core.Schema,
				},
				["token"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Member"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "MemberStatus" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MemberDetail"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["overrides"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "MemberStatus" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MemberStatus"] = { ["kind"] = "enum", ["values"] = { "ACTIVE", "DISABLED" } } :: Core.Schema,
		["MoveUniverse"] = {
			["fields"] = {
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["NewMember"] = {
			["fields"] = {
				["displayName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Organization"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxMembers"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["maxServiceAccounts"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["maxUniverses"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["slug"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Status" } :: Core.Schema,
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
		["PatchMember"] = {
			["fields"] = {
				["overrides"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "MemberStatus" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PatchOrg"] = {
			["fields"] = {
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["slug"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Status" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PatchUniverse"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Plan"] = {
			["fields"] = {
				["maxMembers"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["maxServiceAccounts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["maxUniverses"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Scope"] = {
			["fields"] = {
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["permissions"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccessLevel"] = {
			["kind"] = "enum",
			["values"] = {
				"ADMIN",
				"READ_WRITE",
				"READ",
			},
		} :: Core.Schema,
		["ServiceAccountCreateRequest"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["lastUsedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["permissions"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["previousKeyExpiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["revokedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rotatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccountStatus" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccountRotateRequest"] = {
			["fields"] = {
				["gracePeriodSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceAccountStatus"] = {
			["kind"] = "enum",
			["values"] = { "ACTIVE", "EXPIRING_SOON", "EXPIRED", "REVOKED" },
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
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ServiceDefinitionResponse"] = {
			["fields"] = {
				["builtIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ServiceAccessLevel" } :: Core.Schema,
				},
				["serviceName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Status"] = { ["kind"] = "enum", ["values"] = { "ACTIVE", "SUSPENDED" } } :: Core.Schema,
		["Template"] = {
			["fields"] = {
				["permissions"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["TenantRole"] = {
			["kind"] = "enum",
			["values"] = {
				"VIEWER",
				"DEVELOPER",
				"ADMIN",
				"OWNER",
			},
		} :: Core.Schema,
		["Token"] = {
			["fields"] = {
				["accessToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ValidationAccountType" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgRole"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["platformOwner"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["role"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "TenantRole" } :: Core.Schema,
				},
				["serviceAccount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["servicePermissions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Transfer"] = {
			["fields"] = {
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Universe"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
		["ValidationAccountType"] = {
			["kind"] = "enum",
			["values"] = { "SUPER_ADMIN", "USER", "UNIVERSE_ACCOUNT" },
		} :: Core.Schema,
	},
	["codes"] = {
		["BulkCode"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkCreateCodesRequest"] = {
			["fields"] = {
				["active"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["length"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["prefix"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["BulkCreateCodesResponse"] = {
			["fields"] = {
				["batchId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["codes"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BulkCode" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CodeDto"] = {
			["fields"] = {
				["active"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["batchId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["pendingRedemptions"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redeemableNow"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["remainingGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timesRedeemed"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CodeRedemptionDto"] = {
			["fields"] = {
				["award"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["codeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redeemedByAccountId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["requestId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "FieldsTransactionResult" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FieldsTransactionResult"] = {
			["fields"] = {
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["results"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["txId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["Op"] = {
			["kind"] = "enum",
			["values"] = {
				"SET",
				"RESET",
				"ADD",
				"MIN",
				"MAX",
				"APPEND",
				"INSERT",
				"REMOVE_AT",
				"REMOVE_VALUE",
				"SET_ADD",
				"SET_REMOVE",
				"MAP_PUT",
				"MAP_REMOVE",
				"MAP_ADD",
			},
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RedeemCodeResponse"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["codeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["redeemedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["redemptionId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "FieldsTransactionResult" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Result"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["op"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Op" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PathSegment" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["award"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxGlobalRedemptions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxRedemptionsPerUser"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["config"] = {
		["ChangeSet"] = {
			["fields"] = {
				["delete"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["expectedVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["set"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "EntryPut" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ChangedKeys"] = {
			["fields"] = {
				["deleted"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["set"] = {
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
		["Entry"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["namespace"] = {
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
				["updatedBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expectedVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["History"] = {
			["fields"] = {
				["changedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["changedBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["changes"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ChangedKeys" } :: Core.Schema,
				},
				["namespace"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["op"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rolledBackTo"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
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
		["Namespace"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["entryCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["namespace"] = {
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
				["updatedBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["Rollback"] = {
			["fields"] = {
				["toVersion"] = {
					["notBlank"] = false,
					["required"] = true,
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
				["namespace"] = {
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
		["StoredEntry"] = {
			["fields"] = {
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["VersionState"] = {
			["fields"] = {
				["entries"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "StoredEntry" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["history"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "History" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["fields"] = {
		["AcquireInput"] = {
			["fields"] = {
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "SessionPlayer" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["serverId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ttlMs"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Action"] = {
			["fields"] = {
				["force"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Alert"] = {
			["fields"] = {
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["firstSeen"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["lastSeen"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rule"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AlertRule" } :: Core.Schema,
				},
				["severity"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AlertSeverity" } :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AlertState" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AlertAcknowledgement"] = {
			["fields"] = {
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "AlertState" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AlertConfigInput"] = {
			["fields"] = {
				["configFailOpenRate"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["pendingAgeSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["pendingSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["stalledSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["transaction5xxRate"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["webhook"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AlertConfigResponse"] = {
			["fields"] = {
				["configFailOpenRate"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["pendingAgeSeconds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["pendingSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["stalledSeconds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["transaction5xxRate"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["webhookConfigured"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["AlertRule"] = {
			["kind"] = "enum",
			["values"] = {
				"OUTBOX_BACKLOG",
				"OUTBOX_FAILED",
				"RECONCILE_MISMATCH",
				"CONFIG_FAIL_OPEN",
				"JOB_FAILED",
				"JOB_STALLED",
				"SCHEDULE_ACTION_FAILED",
				"TRANSACTION_5XX",
			},
		} :: Core.Schema,
		["AlertSeverity"] = { ["kind"] = "enum", ["values"] = { "WARNING", "CRITICAL" } } :: Core.Schema,
		["AlertState"] = { ["kind"] = "enum", ["values"] = { "OPEN", "ACKED", "RESOLVED" } } :: Core.Schema,
		["Batch"] = {
			["fields"] = {
				["fields"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["subjects"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchChangesInput"] = {
			["fields"] = {
				["maxEntries"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlayerChangesInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchChangesResponse"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlayerChangesItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["pollAfterMs"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchItem"] = {
			["fields"] = {
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "FieldView" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BatchResponse"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BatchItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BindingView"] = {
			["fields"] = {
				["binding"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "fields", ["name"] = "LeaderboardBinding" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["settings"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardSettings" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Status" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BoardActualSettings"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BoardAggregation"] = { ["kind"] = "enum", ["values"] = { "LAST", "BEST", "SUM" } } :: Core.Schema,
		["BoardConflict"] = {
			["fields"] = {
				["actual"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardActualSettings" } :: Core.Schema,
				},
				["board"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expected"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardSettings" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["source"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BoardPreviewStatus"] = {
			["kind"] = "enum",
			["values"] = { "COMPATIBLE", "CONFLICT", "ARCHIVED", "MISSING_OR_ARCHIVED" },
		} :: Core.Schema,
		["BoardResetSchedule"] = {
			["kind"] = "enum",
			["values"] = { "NONE", "DAILY", "WEEKLY", "MONTHLY", "SEASONAL" },
		} :: Core.Schema,
		["BoardSettings"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardAggregation" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardSortOrder" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BoardSortOrder"] = { ["kind"] = "enum", ["values"] = { "DESC", "ASC" } } :: Core.Schema,
		["BulkDefinitionCreated"] = {
			["fields"] = {
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["target"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "BulkTarget" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkPreview"] = {
			["fields"] = {
				["matchedCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["samples"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BulkPreviewSample" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["validation"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "OpsValidationResult" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkPreviewInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["target"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "BulkTarget" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["BulkPreviewSample"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ChangesResponse"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["latestSeq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["nextSinceSeq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CommitError"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CommitInput"] = {
			["fields"] = {
				["commitId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CommitPlayer" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["serverId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CommitItem"] = {
			["fields"] = {
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "CommitError" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["versions"] = {
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
		["CommitPlayer"] = {
			["fields"] = {
				["epoch"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CommitResponse"] = {
			["fields"] = {
				["commitId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CommitItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ConsumerReferenceInput"] = {
			["fields"] = {
				["consumerId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fields"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["label"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Counts"] = {
			["fields"] = {
				["definitions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["ledger"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["values"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DayOfWeek"] = {
			["kind"] = "enum",
			["values"] = { "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY" },
		} :: Core.Schema,
		["Definition"] = {
			["fields"] = {
				["bindings"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "fields", ["name"] = "Bindings" } :: Core.Schema,
				},
				["computed"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "fields", ["name"] = "Computed" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["default"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["definitionVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["history"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "History" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Status" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["writeLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "WriteLevel" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DefinitionChange"] = {
			["fields"] = {
				["actor"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["after"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
				},
				["counter"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["references"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FieldReference" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DefinitionInput"] = {
			["fields"] = {
				["bindings"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "Bindings" } :: Core.Schema,
				},
				["computed"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "Computed" } :: Core.Schema,
				},
				["default"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expectedDefinitionVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["history"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "History" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Status" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["writeLevel"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "WriteLevel" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Document"] = {
			["fields"] = {
				["computed"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "boolean" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["data"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["errors"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["versions"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["DocumentInput"] = {
			["fields"] = {
				["data"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["expectedSeq"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Entry"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["afterExists"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["afterHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["afterSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["args"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["beforeExists"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["beforeHash"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["beforeSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["op"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ordinal"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PathSegment" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["refId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["refType"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reversesId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["txId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["versionAfter"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["EnvironmentReplaceInput"] = {
			["fields"] = {
				["expectedResources"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "DefinitionInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["operationId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resources"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "DefinitionInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ExportInput"] = {
			["fields"] = {
				["fields"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["target"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "BulkTarget" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FailurePolicy"] = { ["kind"] = "enum", ["values"] = { "FAIL", "USE_DEFAULT", "CLAMP" } } :: Core.Schema,
		["FieldPage"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FieldView" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["nextCursor"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FieldReference"] = {
			["fields"] = {
				["consumerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["consumerType"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ReferenceConsumerType" } :: Core.Schema,
				},
				["label"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FieldReferenceInput"] = {
			["fields"] = {
				["fields"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["label"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FieldReferences"] = {
			["fields"] = {
				["fieldId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["references"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FieldReference" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FieldView"] = {
			["fields"] = {
				["computed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["isDefault"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
		["FlagBatchEvaluation"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagBatchItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagBatchItem"] = {
			["fields"] = {
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["values"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagEvaluationValue" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagDefinition"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["defaultValue"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rolloutPct"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["rules"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagRule" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["sticky"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["variants"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagVariant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagEvaluateBatchInput"] = {
			["fields"] = {
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["FlagEvaluateInput"] = {
			["fields"] = {
				["context"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["keys"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagEvaluation"] = {
			["fields"] = {
				["values"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagEvaluationValue" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagEvaluationValue"] = {
			["fields"] = {
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["variant"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagInput"] = {
			["fields"] = {
				["defaultValue"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["rolloutPct"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["rules"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagRule" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["sticky"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["variants"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagVariant" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["FlagMatch"] = {
			["fields"] = {
				["field"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["op"] = {
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
		["FlagRule"] = {
			["fields"] = {
				["match"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagMatch" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["rolloutPct"] = {
					["notBlank"] = false,
					["required"] = true,
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
		["FlagVariant"] = {
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
				["weightPct"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Generated"] = {
			["fields"] = {
				["cost"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["picks"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "GeneratorPick" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["pityAfter"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GeneratorPick"] = {
			["fields"] = {
				["durationSeconds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["grants"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["index"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["payload"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "json" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["rolls"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["slot"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["table"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tags"] = {
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
		["GeneratorPreviewInput"] = {
			["fields"] = {
				["count"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["generator"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GeneratorRollInput"] = {
			["fields"] = {
				["count"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["generator"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GeneratorRollResult"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["definitionVersions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["generator"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["results"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Generated" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GeneratorSimulationInput"] = {
			["fields"] = {
				["generator"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["iterations"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["playerId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["GeneratorSimulationResult"] = {
			["fields"] = {
				["appearanceProbabilities"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["entryCounts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["iterations"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["picks"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["pityMode"] = {
					["notBlank"] = false,
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
		["HealthSummary"] = {
			["fields"] = {
				["openAlerts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "OpenAlertCounts" } :: Core.Schema,
				},
				["runningJobs"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["upcomingSchedules"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["History"] = { ["kind"] = "enum", ["values"] = { "LEDGER", "NONE" } } :: Core.Schema,
		["ImportError"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["line"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ImportValidation"] = {
			["fields"] = {
				["dryRun"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["errors"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ImportError" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["records"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Item"] = {
			["fields"] = {
				["attempts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["doneAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["lastError"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["nextAttemptAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["payload"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["queueOrder"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
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
		["JobActionInput"] = {
			["fields"] = {
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["JobEvent"] = {
			["fields"] = {
				["actor"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["event"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["JobFailure"] = {
			["fields"] = {
				["error"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ordinal"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["JobKind"] = {
			["kind"] = "enum",
			["values"] = {
				"BULK",
				"REVERSE",
				"EXPORT",
				"IMPORT",
				"MIGRATION",
				"ROLLBACK",
				"SCHEDULE",
				"ALERT_SCAN",
				"NOTIFY",
			},
		} :: Core.Schema,
		["JobReceipt"] = {
			["fields"] = {
				["attempts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["cancelRequested"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["failed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "JobKind" } :: Core.Schema,
				},
				["phase"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["prepared"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["recurrence"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ScheduleRecurrence" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["snapshotId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "JobState" } :: Core.Schema,
				},
				["succeeded"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["total"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["JobState"] = {
			["kind"] = "enum",
			["values"] = { "QUEUED", "RUNNING", "SUCCEEDED", "CANCELLED", "FAILED" },
		} :: Core.Schema,
		["JobSummary"] = {
			["fields"] = {
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["failed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "JobKind" } :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "JobState" } :: Core.Schema,
				},
				["succeeded"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["total"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["KeyedJobActionInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MaintenanceInput"] = {
			["fields"] = {
				["allowlistUserIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MaintenanceState"] = {
			["fields"] = {
				["allowlistUserIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["message"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["MigrationFailureSample"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MigrationInput"] = {
			["fields"] = {
				["converter"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "Converter" } :: Core.Schema,
				},
				["default"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["expectedDefinitionVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["onFailure"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "FailurePolicy" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MigrationPreview"] = {
			["fields"] = {
				["affectedSubjects"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["canApplyDirectly"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["failureCounts"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["failureSamples"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MigrationFailureSample" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["samples"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MigrationSample" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["unconverted"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MigrationPreviewInput"] = {
			["fields"] = {
				["converter"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "Converter" } :: Core.Schema,
				},
				["default"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["expectedDefinitionVersion"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["onFailure"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "FailurePolicy" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["MigrationSample"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Mismatch"] = {
			["fields"] = {
				["entryId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["expected"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ledgerVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["OpValidationError"] = {
			["fields"] = {
				["code"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["opIndex"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PathSegment" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["OpenAlertCounts"] = {
			["fields"] = {
				["CRITICAL"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["WARNING"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["OpsValidationInput"] = {
			["fields"] = {
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PlayerOperation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["OpsValidationResult"] = {
			["fields"] = {
				["errors"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "OpValidationError" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerChangesInput"] = {
			["fields"] = {
				["sinceSeq"] = {
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
		["PlayerChangesItem"] = {
			["fields"] = {
				["entries"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["hasMore"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["latestSeq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["needsSnapshot"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["nextSinceSeq"] = {
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
		["PlayerEraseInput"] = {
			["fields"] = {
				["confirmUserId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerEraseResult"] = {
			["fields"] = {
				["erased"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["tombstoneId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerRevertInput"] = {
			["fields"] = {
				["ledgerEntryIds"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerSample"] = {
			["fields"] = {
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["values"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlayerSampleResponse"] = {
			["fields"] = {
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlayerSample" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["sampled"] = {
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
		["PlayerSearchPage"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "json" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["nextCursor"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Policy"] = {
			["fields"] = {
				["autoEnabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["retentionDays"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PolicyInput"] = {
			["fields"] = {
				["autoEnabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["retentionDays"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PollInput"] = {
			["fields"] = {
				["cursor"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["serverId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PollResponse"] = {
			["fields"] = {
				["cursor"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["more"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reset"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Presence"] = {
			["fields"] = {
				["online"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["sessionId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["PresenceBatch"] = {
			["fields"] = {
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["PresenceInput"] = {
			["fields"] = {
				["online"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["sessionId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PresenceResponse"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Presence" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Preview"] = {
			["fields"] = {
				["conflicts"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "BoardConflict" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["effectiveSettings"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardSettings" } :: Core.Schema,
				},
				["settings"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardSettings" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "BoardPreviewStatus" } :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["willWiden"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ScoreRange" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PreviewBoardInput"] = {
			["fields"] = {
				["binding"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "LeaderboardBinding" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "Operation" } :: Core.Schema,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
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
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "Operation" } :: Core.Schema,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomAction"] = {
			["fields"] = {
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomDefinition"] = {
			["fields"] = {
				["definition"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "RotationKind" } :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomDefinitionInput"] = {
			["fields"] = {
				["applyNow"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["definition"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["expectedVersion"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomEditorField"] = {
			["fields"] = {
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "fields", ["name"] = "TypeExpr" } :: Core.Schema,
				},
				["validOps"] = {
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
		["RandomErase"] = {
			["fields"] = {
				["confirmUniverseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomHistory"] = {
			["fields"] = {
				["counter"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["data"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RandomOdds"] = {
			["fields"] = {
				["entryProbabilities"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["probabilities"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Receipt"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["productId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["purchaseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["refund"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
				},
				["refundedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robuxSpent"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
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
		["ReceiptInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
				["robuxSpent"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["ReceiptResult"] = {
			["fields"] = {
				["purchaseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RecurrenceType"] = { ["kind"] = "enum", ["values"] = { "NONE", "DAILY", "WEEKLY" } } :: Core.Schema,
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
		["ReferenceBatchInput"] = {
			["fields"] = {
				["consumers"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ConsumerReferenceInput" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ReferenceConsumerType"] = { ["kind"] = "enum", ["values"] = { "GAMEMODE", "CODE" } } :: Core.Schema,
		["RefundInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ReleaseInput"] = {
			["fields"] = {
				["leases"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "SessionLease" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["serverId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RenewInput"] = {
			["fields"] = {
				["leases"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "SessionLease" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["serverId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ttlMs"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RestoreInput"] = {
			["fields"] = {
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["prefix"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RestoreReport"] = {
			["fields"] = {
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RestoreReportItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["restored"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["skipped"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RestoreReportItem"] = {
			["fields"] = {
				["error"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RestoreResponse"] = {
			["fields"] = {
				["failed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["preRestoreSnapshotId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["reports"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RestoreReport" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["restoreId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["restored"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["restoredSubjects"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["skipped"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Result"] = {
			["fields"] = {
				["replayed"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["results"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ResultItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["txId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ResultItem"] = {
			["fields"] = {
				["after"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["before"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["op"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["path"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "PathSegment" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["subject"] = {
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
		["RotationActive"] = {
			["fields"] = {
				["current"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RotationInstance" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["enabled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["next"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RotationInstance" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RotationClaimInput"] = {
			["fields"] = {
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["instanceId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["quantity"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["slot"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RotationClaimResult"] = {
			["fields"] = {
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["instanceId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["quantity"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["remaining"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["slot"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["transaction"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RotationInstance"] = {
			["fields"] = {
				["definitionVersions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["endsAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["result"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Generated" } :: Core.Schema,
				},
				["sequence"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["startsAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RotationKind"] = { ["kind"] = "enum", ["values"] = { "TABLE", "GENERATOR", "ROTATION" } } :: Core.Schema,
		["RotationStock"] = {
			["fields"] = {
				["entryId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["remaining"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["slot"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RuntimeSnapshot"] = {
			["fields"] = {
				["flags"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "FlagDefinition" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["maintenance"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "MaintenanceState" } :: Core.Schema,
				},
				["rotations"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "RotationActive" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleActionResult"] = {
			["fields"] = {
				["done"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["jobId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["key"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ordinal"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["skipReason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["skipped"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "boolean" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["version"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleDefinition"] = {
			["fields"] = {
				["end"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["endActions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = {
							["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
							["kind"] = "array",
						} :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["recurrence"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ScheduleRecurrence" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["restorePrevious"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["start"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startActions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleEdge"] = { ["kind"] = "enum", ["values"] = { "START", "END" } } :: Core.Schema,
		["ScheduleInput"] = {
			["fields"] = {
				["end"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["endActions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["recurrence"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ScheduleRecurrence" } :: Core.Schema,
				},
				["restorePrevious"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["start"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startActions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SchedulePreview"] = {
			["fields"] = {
				["endActions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["requiresExistingConfigResources"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["restorePrevious"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["start"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startActions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "ScheduleAction" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleRecurrence"] = {
			["fields"] = {
				["daysOfWeek"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "DayOfWeek" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["timezone"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "RecurrenceType" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleRun"] = {
			["fields"] = {
				["actions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ScheduleActionResult" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["edge"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ScheduleEdge" } :: Core.Schema,
				},
				["error"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["finishedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["occurrence"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["startedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["status"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ScheduleRunStatus" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["ScheduleRunStatus"] = {
			["kind"] = "enum",
			["values"] = { "RUNNING", "SUCCEEDED", "FAILED", "CANCELLED" },
		} :: Core.Schema,
		["ScheduleSummary"] = {
			["fields"] = {
				["end"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
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
				["phase"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["recurrence"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "ScheduleRecurrence" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["start"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["state"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "JobState" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SchemaResponse"] = {
			["fields"] = {
				["definitions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["schemaVersion"] = {
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
		["ScoreRange"] = {
			["fields"] = {
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
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SessionItem"] = {
			["fields"] = {
				["epoch"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["owner"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["retryAfterMs"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["snapshot"] = {
					["notBlank"] = false,
					["required"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "SessionSnapshot" } :: Core.Schema,
				},
				["status"] = {
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
		["SessionLease"] = {
			["fields"] = {
				["epoch"] = {
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
		["SessionPlayer"] = {
			["fields"] = {
				["steal"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SessionResponse"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "SessionItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SessionSnapshot"] = {
			["fields"] = {
				["fields"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["seq"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["versions"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Snapshot"] = {
			["fields"] = {
				["byteSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["createdAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["createdBy"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["itemCount"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["kind"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["scope"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "SnapshotScope" } :: Core.Schema,
				},
				["subjectId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["SnapshotDeleted"] = {
			["fields"] = {
				["deleted"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SnapshotDetail"] = {
			["fields"] = {
				["items"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "SnapshotItem" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "Snapshot" } :: Core.Schema,
				},
				["nextCursor"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SnapshotInput"] = {
			["fields"] = {
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["scope"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "SnapshotScope" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["SnapshotItem"] = {
			["fields"] = {
				["field"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["subject"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["value"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
		["SnapshotScope"] = { ["kind"] = "enum", ["values"] = { "PLAYER", "UNIVERSE" } } :: Core.Schema,
		["Status"] = { ["kind"] = "enum", ["values"] = { "ACTIVE", "ARCHIVED" } } :: Core.Schema,
		["TransactionInput"] = {
			["fields"] = {
				["conditions"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "Condition" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["idempotencyKey"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ops"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "fields", ["name"] = "Operation" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["ref"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Ref" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["WriteLevel"] = { ["kind"] = "enum", ["values"] = { "READ_WRITE", "ADMIN" } } :: Core.Schema,
	},
	["leaderboards"] = {
		["Aggregation"] = { ["kind"] = "enum", ["values"] = { "BEST", "SUM", "LAST", "MIN", "MAX" } } :: Core.Schema,
		["Board"] = {
			["fields"] = {
				["aggregation"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["currentPeriodId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["periodStartedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "SortOrder" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["MatchInput"] = {
			["fields"] = {
				["matchId"] = {
					["notBlank"] = true,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Aggregation" } :: Core.Schema,
				},
				["clearMaxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["displayName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxDeltaPerSubmit"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minScore"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["resetSchedule"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "ResetSchedule" } :: Core.Schema,
				},
				["sortOrder"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "SortOrder" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["periodId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["startedAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RatingScope"] = {
			["fields"] = {
				["displayName"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["scope"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["RatingScopeLabel"] = {
			["fields"] = {
				["displayName"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
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
		["AccountType"] = { ["kind"] = "enum", ["values"] = { "SUPER_ADMIN", "USER" } } :: Core.Schema,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["bannedBy"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["isExpired"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseRequired"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaComputedReturn"] = { ["kind"] = "enum", ["values"] = { "int", "number" } } :: Core.Schema,
		["CriteriaExplanationResponse"] = {
			["fields"] = {
				["gameModeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["optionalMetadataFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaFieldInfo" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["requiredMetadataFields"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaFieldInfo" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaFieldCoverage"] = {
			["fields"] = {
				["max"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["mean"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["min"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["missing"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["p50"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["p90"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "nullable",
					} :: Core.Schema,
				},
				["present"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaFieldInfo"] = {
			["fields"] = {
				["constraint"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["criteriaType"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
		["CriteriaSimulationEstimate"] = {
			["fields"] = {
				["avgGroupSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["groups"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["unmatchable"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["unmatchablePct"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaSimulationRequest"] = {
			["fields"] = {
				["criteria"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["sampleSize"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaSimulationResponse"] = {
			["fields"] = {
				["estimate"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaSimulationEstimate" } :: Core.Schema,
				},
				["fieldCoverage"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaFieldCoverage" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["sampled"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["warnings"] = {
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
		["CriteriaTypeInfo"] = {
			["fields"] = {
				["allowedReturns"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaComputedReturn" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["description"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fieldRequired"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaType" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["CriteriaValidationError"] = {
			["fields"] = {
				["actualValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["criteriaType"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaType" } :: Core.Schema,
				},
				["expectedConstraint"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["playerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["players"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["isJail"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["matchmakingCriteria"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["bracketSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["fieldName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["groupCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxDifference"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxLatencyDiff"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxPlayers"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["maxValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["minValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["skillRange"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["targetValue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["tolerance"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["type"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "CriteriaType" } :: Core.Schema,
				},
				["weight"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["gameModeNames"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["inQueue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["queuedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["queuedPlayerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["removedCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["success"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["totalPlayersInQueue"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeBreakdown"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUniverseId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserIds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseRequired"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "GameModeQueueInfo" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["totalPlayers"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["places"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["isPermanent"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["notes"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["reason"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "MatchmakingCriteriaDTO" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["placeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseRequired"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "CriteriaValidationError" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["valid"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
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
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["gameModeName"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxMatchSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["oldestEntryAgeSeconds"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["playersNeeded"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["queuedPlayerCount"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseRequired"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
	["party"] = {
		["AccountType"] = { ["kind"] = "enum", ["values"] = { "SUPER_ADMIN", "USER" } } :: Core.Schema,
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
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountId"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["accountType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "ref", ["name"] = "AccountType" } :: Core.Schema,
				},
				["createdTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["email"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["expiresIn"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metadata"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
				},
				["refreshToken"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updatedTime"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["username"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
					["responseRequired"] = false,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["robloxUserId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["id"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["maxSize"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["members"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PartyMemberResponse" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["ownerId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["updatedAt"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["partyId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["timestamp"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updateType"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["userId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["tokenType"] = {
					["notBlank"] = false,
					["required"] = true,
					["responseNullable"] = true,
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
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["updates"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "PartyUpdate" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
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
	["platform"] = {
		["DateRange"] = {
			["fields"] = {
				["from"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["to"] = {
					["notBlank"] = false,
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
		["IncidentInput"] = {
			["fields"] = {
				["message"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["resolved"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["severity"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["Metric"] = {
			["kind"] = "enum",
			["values"] = { "requests", "storage_bytes", "active_players" },
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
		["PlanChange"] = {
			["fields"] = {
				["plan"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlanInput"] = {
			["fields"] = {
				["monthlyLimits"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "number" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["name"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["overagePrices"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "decimal" } :: Core.Schema,
						["kind"] = "map",
					} :: Core.Schema,
				},
				["rateLimit"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "RateLimit" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["PlatformEvent"] = {
			["fields"] = {
				["data"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "json" } :: Core.Schema,
				},
				["eventId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["occurredAt"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["type"] = {
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
		["RateLimit"] = {
			["fields"] = {
				["burst"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["dailyRequests"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["requestsPerSecond"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UsageBatch"] = {
			["fields"] = {
				["batchId"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["events"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "ref", ["name"] = "UsageEvent" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["UsageEvent"] = {
			["fields"] = {
				["at"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["count"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
				["metric"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = { ["kind"] = "ref", ["name"] = "Metric" } :: Core.Schema,
				},
				["orgId"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["service"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["universeId"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "number" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
		["WebhookInput"] = {
			["fields"] = {
				["enabled"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "boolean" } :: Core.Schema,
				},
				["events"] = {
					["notBlank"] = false,
					["required"] = true,
					["schema"] = {
						["item"] = { ["kind"] = "string" } :: Core.Schema,
						["kind"] = "array",
					} :: Core.Schema,
				},
				["secret"] = {
					["notBlank"] = false,
					["required"] = false,
					["responseNullable"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
				["url"] = {
					["notBlank"] = true,
					["required"] = true,
					["schema"] = { ["kind"] = "string" } :: Core.Schema,
				},
			},
			["kind"] = "object",
		} :: Core.Schema,
	},
}
for _, service in definitions do
	service.HealthResponse = healthResponse
end
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
	["auth.acceptInvitation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Accept" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.addMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AddMember" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.addPlace"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlaceCreateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PlaceResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.assignOwner"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AssignOwner" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.cancelSandbox"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ActorRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
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
	["auth.createInvitation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Invite" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Issued" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "NewMember" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CreatedMember" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createOrg"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateOrg" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.createOrgUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateUniverse" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Universe" } :: Core.Schema,
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
	["auth.deleteOrg"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deletePlace"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deletePlaceRest"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.deleteService"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.exchangeScopedToken"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Token" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.finalizeSandbox"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ActorRequest" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getAccessLog"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "AccessEvent" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getCurrentAccount"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getMyAccess"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Access" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getOrg"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.getOrgUniverse"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Universe" } :: Core.Schema,
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
	["auth.health"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.leaveOrg"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.listInvitations"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Invitation" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listMembers"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "MemberDetail" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listOrgUniverses"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Universe" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "auth",
	},
	["auth.listOrgs"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
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
	["auth.listRoleTemplates"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Template" } :: Core.Schema,
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
	["auth.lookupServiceAccount"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.moveUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MoveUniverse" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Universe" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.openApiSpec"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "auth" },
	["auth.patchMember"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PatchMember" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.patchOrg"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PatchOrg" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.patchOrgUniverse"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PatchUniverse" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Universe" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.patchServiceAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceAccountPatchRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.provisionSandbox"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Create" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Created" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.refresh"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefreshRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RefreshResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.removeMember"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.requestReset"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PasswordResetRequestDto" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.revokeInvitation"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "auth" },
	["auth.revokeServiceAccount"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.rotateServiceAccount"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ServiceAccountRotateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ServiceAccountResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.setOrgPlan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Plan" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Organization" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.setRoleTemplate"] = {
		["body"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ServicePermissionResponse" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Template" } :: Core.Schema,
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
	["auth.transferOwnership"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Transfer" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Member" } :: Core.Schema,
		["service"] = "auth",
	},
	["auth.updateCurrentAccount"] = {
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
	["auth.validateToken"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "TokenValidateRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "TokenValidateResponse" } :: Core.Schema,
		["service"] = "auth",
	},
	["codes.bulkCreateCodes"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkCreateCodesRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkCreateCodesResponse" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.createCode"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CreateCodeRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.deleteCode"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "codes" },
	["codes.exportBatch"] = { ["response"] = { ["kind"] = "string" } :: Core.Schema, ["service"] = "codes" },
	["codes.getCode"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "CodeDto" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.listRedemptions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "CodeRedemptionDto" } :: Core.Schema,
			["kind"] = "page",
		} :: Core.Schema,
		["service"] = "codes",
	},
	["codes.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "codes",
	},
	["codes.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
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
	["config.changeEntries"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ChangeSet" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Namespace" } :: Core.Schema,
		["service"] = "config",
	},
	["config.deleteEntry"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "config" },
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
	["config.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "config",
	},
	["config.namespace"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Namespace" } :: Core.Schema,
		["service"] = "config",
	},
	["config.namespaces"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Namespace" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "config",
	},
	["config.putEntry"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EntryPut" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
		["service"] = "config",
	},
	["config.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "config",
	},
	["config.rollback"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Rollback" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Namespace" } :: Core.Schema,
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
	["config.version"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "VersionState" } :: Core.Schema,
		["service"] = "config",
	},
	["fields.ackAlert"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AlertAcknowledgement" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.acquireSessions"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AcquireInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SessionResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.activeRotation"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RotationActive" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.advanceRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomAction" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RotationActive" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.alertConfig"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "AlertConfigResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.alerts"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Alert" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.archive"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Action" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.batch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Batch" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BatchResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.bulk"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.bulkDefinition"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "BulkInput" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.bulkPreview"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkPreviewInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkPreview" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.cancelJob"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "JobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.cancelMigration"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "JobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.cancelSchedule"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "JobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.changes"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ChangesResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.changesBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BatchChangesInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BatchChangesResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.claimRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RotationClaimInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RotationClaimResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.commitSession"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CommitInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CommitResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.create"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "DefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createBulkDefinition"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "BulkInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BulkDefinitionCreated" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createFlag"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FlagInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "FlagDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createRandomTable"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createSchedule"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ScheduleInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.createSnapshot"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "SnapshotInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Snapshot" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.dailyAnalytics"] = {
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.definition"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.definitionReferences"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "FieldReferences" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.definitions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deleteFlag"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "fields" },
	["fields.deleteGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomAction" } :: Core.Schema,
		["response"] = { ["kind"] = "boolean" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deletePlayer"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlayerEraseInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PlayerEraseResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deleteProduct"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "fields" },
	["fields.deleteRandomTable"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomAction" } :: Core.Schema,
		["response"] = { ["kind"] = "boolean" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deleteReferences"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deleteRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomAction" } :: Core.Schema,
		["response"] = { ["kind"] = "boolean" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.deleteSnapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "SnapshotDeleted" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.document"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Document" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.editSchedule"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ScheduleInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.endSchedule"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "JobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.entry"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.environmentResources"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.eraseRandomness"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomErase" } :: Core.Schema,
		["response"] = { ["kind"] = "boolean" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.evaluateFlags"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FlagEvaluateInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "FlagEvaluation" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.evaluateFlagsBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FlagEvaluateBatchInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "FlagBatchEvaluation" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.export"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ExportInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.exportPlayer"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "fields" },
	["fields.field"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "FieldView" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.fields"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "FieldPage" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.flag"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "FlagDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.flags"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "FlagDefinition" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.getGenerator"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.getRandomTable"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.getRotation"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.healthSummary"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthSummary" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.history"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "DefinitionChange" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.import"] = {
		["body"] = { ["kind"] = "string" } :: Core.Schema,
		["response"] = {
			["items"] = {
				{ ["kind"] = "ref", ["name"] = "ImportValidation" } :: Core.Schema,
				{ ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
			},
			["kind"] = "union",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.job"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.jobDownload"] = { ["response"] = { ["kind"] = "string" } :: Core.Schema, ["service"] = "fields" },
	["fields.jobEvents"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "JobEvent" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.jobFailures"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "JobFailure" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.jobFailuresDownload"] = {
		["response"] = { ["kind"] = "string" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.jobs"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "JobSummary" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.leaderboardBindings"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "BindingView" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.ledger"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Entry" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.listGenerators"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.listRandomTables"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.listRotations"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.luau"] = { ["response"] = { ["kind"] = "string" } :: Core.Schema, ["service"] = "fields" },
	["fields.maintenance"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MaintenanceState" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.migrate"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MigrationInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.migrationPreview"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MigrationPreviewInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "MigrationPreview" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.multiTransaction"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "TransactionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.openApiSpec"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "fields" },
	["fields.outbox"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Item" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.playerBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Batch" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "BatchResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.playerClaimHistory"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomHistory" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.playerOverview"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.playerRollHistory"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomHistory" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.pollSessions"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PollInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PollResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.presence"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Presence" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.presenceBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PresenceBatch" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "PresenceResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.previewBoard"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PreviewBoardInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Preview" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.previewGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "GeneratorPreviewInput" } :: Core.Schema,
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Generated" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.product"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.products"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.purchase"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ReceiptInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ReceiptResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.purge"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Counts" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putAlertConfig"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "AlertConfigInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "AlertConfigResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putDocument"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "DocumentInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putMaintenance"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MaintenanceInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "MaintenanceState" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putPresence"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PresenceInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Presence" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putProduct"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ProductInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Product" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putRandomTable"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putReferences"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FieldReferenceInput" } :: Core.Schema,
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomDefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RandomDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.putSnapshotPolicy"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PolicyInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Policy" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.randomDefinitionHistory"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomHistory" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.randomnessFields"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomEditorField" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.randomnessSchema"] = {
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.receipt"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Receipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.receipts"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Receipt" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.reconcile"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Mismatch" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.refund"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RefundInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "ReceiptResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.releaseSessions"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ReleaseInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SessionResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.renewSessions"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RenewInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SessionResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.replaceEnvironmentResources"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "EnvironmentReplaceInput" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.replaceReferencesBatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ReferenceBatchInput" } :: Core.Schema,
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.rerollRotation"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RandomAction" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RotationActive" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.restoreSnapshot"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RestoreInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RestoreResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.retryJob"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "JobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.retryOutbox"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Item" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.reverseBulk"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "KeyedJobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.reverseEntry"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Action" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.reverseTransaction"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Action" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.revertPlayer"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlayerRevertInput" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.rollGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "GeneratorRollInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "GeneratorRollResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.rollbackMigration"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "KeyedJobActionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.rotationHistory"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RandomHistory" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.rotationStock"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RotationStock" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.runtimeSnapshot"] = {
		["response"] = {
			["items"] = {
				{ ["kind"] = "ref", ["name"] = "RuntimeSnapshot" } :: Core.Schema,
				{ ["kind"] = "nil" } :: Core.Schema,
			},
			["kind"] = "union",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.samplePlayers"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PlayerSampleResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.schedule"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.scheduleActions"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ScheduleActionResult" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.scheduleDefinition"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "ScheduleDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.schedulePreview"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "ScheduleInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "SchedulePreview" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.scheduleRuns"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ScheduleRun" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.schedules"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "ScheduleSummary" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.schema"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "SchemaResponse" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.searchPlayers"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "PlayerSearchPage" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.simulateGenerator"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "GeneratorSimulationInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "GeneratorSimulationResult" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.snapshot"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "SnapshotDetail" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.snapshotPolicy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "Policy" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.snapshots"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "Snapshot" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
		["service"] = "fields",
	},
	["fields.tableOdds"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "RandomOdds" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.testWebhook"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "JobReceipt" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.transaction"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "TransactionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Result" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.typescript"] = { ["response"] = { ["kind"] = "string" } :: Core.Schema, ["service"] = "fields" },
	["fields.unarchive"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "Action" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.update"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "DefinitionInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "Definition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.updateFlag"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "FlagInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "FlagDefinition" } :: Core.Schema,
		["service"] = "fields",
	},
	["fields.validateOps"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "OpsValidationInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "OpsValidationResult" } :: Core.Schema,
		["service"] = "fields",
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
	["leaderboards.ratingLabel"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RatingScopeLabel" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "RatingScope" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingMatch"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "MatchInput" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "MatchResult" } :: Core.Schema,
		["service"] = "leaderboards",
	},
	["leaderboards.ratingScopes"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "RatingScope" } :: Core.Schema,
			["kind"] = "cursorPage",
		} :: Core.Schema,
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
	["matchmaking.getCriteriaTypes"] = {
		["response"] = {
			["item"] = { ["kind"] = "ref", ["name"] = "CriteriaTypeInfo" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
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
	["matchmaking.simulateCriteria"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "CriteriaSimulationRequest" } :: Core.Schema,
		["response"] = { ["kind"] = "ref", ["name"] = "CriteriaSimulationResponse" } :: Core.Schema,
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
	["platform.analyticsEconomy"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.analyticsSummary"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.analyticsTimeseries"] = {
		["response"] = {
			["item"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "platform",
	},
	["platform.backfillAnalytics"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "DateRange" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.createIncident"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "IncidentInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.createPlan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlanInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.createWebhook"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "WebhookInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.deleteIncident"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.deletePlan"] = { ["response"] = { ["kind"] = "nil" } :: Core.Schema, ["service"] = "platform" },
	["platform.deleteWebhook"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.gatewayRateLimits"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.healthProxy"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthResponse" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.incidents"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.info"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.ingestUsage"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "UsageBatch" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.invoices"] = {
		["response"] = {
			["item"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "platform",
	},
	["platform.limits"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.liveness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.metrics"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "MetricsResponse" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.openapi"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "platform" },
	["platform.orgPlan"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "platform" },
	["platform.ping"] = {
		["response"] = { ["item"] = { ["kind"] = "string" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.plans"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.publishEvent"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlatformEvent" } :: Core.Schema,
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.putPlan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlanInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.rateLimits"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.readiness"] = {
		["response"] = { ["kind"] = "ref", ["name"] = "HealthComponent" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.redeliverWebhook"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.resetKeyRateLimit"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.resetRateLimits"] = {
		["response"] = { ["kind"] = "nil" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.sandbox"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.setKeyRateLimit"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RateLimit" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.setOrgPlan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlanChange" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.setRateLimits"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "RateLimit" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.status"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.testWebhook"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.updateIncident"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "IncidentInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.updatePlan"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "PlanInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.updateWebhook"] = {
		["body"] = { ["kind"] = "ref", ["name"] = "WebhookInput" } :: Core.Schema,
		["response"] = { ["kind"] = "json" } :: Core.Schema,
		["service"] = "platform",
	},
	["platform.usage"] = {
		["response"] = {
			["item"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "platform",
	},
	["platform.webhook"] = { ["response"] = { ["kind"] = "json" } :: Core.Schema, ["service"] = "platform" },
	["platform.webhookDeliveries"] = {
		["response"] = {
			["item"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "map" } :: Core.Schema,
			["kind"] = "array",
		} :: Core.Schema,
		["service"] = "platform",
	},
	["platform.webhooks"] = {
		["response"] = { ["item"] = { ["kind"] = "json" } :: Core.Schema, ["kind"] = "array" } :: Core.Schema,
		["service"] = "platform",
	},
}
return Cache.freeze({
	definitions = definitions,
	endpoints = endpoints,
}) :: {
	definitions: { [string]: { [string]: Core.Schema } },
	endpoints: { [string]: Core.EndpointSchema },
}
