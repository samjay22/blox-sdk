#!/usr/bin/env python3
"""Execute the complete test suite against the generated Instance-require package offline."""
from __future__ import annotations
import subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main() -> None:
    """Check both runtimes with emulated ModuleScript resolution, never live Roblox HTTP."""
    sources={}
    for p in (ROOT/'roblox').rglob('*.luau'):
        key='src/BloxSDK' if p.name=='init.luau' else 'src/'+str(p.relative_to(ROOT/'roblox').with_suffix(''))
        sources[key]=p.read_text()
    for p in (ROOT/'tests').rglob('*.luau'):sources['tests/'+str(p.relative_to(ROOT/'tests').with_suffix(''))]=p.read_text()
    parts=['--!strict','local sources = {}']
    for key,source in sorted(sources.items()):
        assert ']===]' not in source
        parts.append(f'sources["{key}"] = [===[{source}]===]')
    parts.append('''
local nodes = { ["src"] = {} }
local values = {}
for path in sources do
 local parent = nil
 local current = ""
 for part in string.gmatch(path, "[^/]+") do
  current = if current == "" then part else current .. "/" .. part
  local node = nodes[current] or { _id = current }
  nodes[current] = node
  if parent then parent[part] = node; node.Parent = parent end
  parent = node
 end
end
-- BloxSDK's ModuleScript is also the package root and contains the sibling modules.
for name, node in nodes.src do nodes["src/BloxSDK"][name] = node end
for name, node in nodes.src do
 if type(node) == "table" and name ~= "BloxSDK" then node.Parent = nodes["src/BloxSDK"] end
end
local base = getfenv()
-- Lune deliberately omits loadstring; its bundled compiler needs no install or network.
local luneCompiler = if base.loadstring then nil else require("@lune/luau")
local function compileSource(source, name)
 if base.loadstring then return assert(base.loadstring(source, name)) end
 return luneCompiler.load(source, {debugName=name})
end
local function loadModule(id)
 if values[id] ~= nil then return values[id] end
 local source = assert(sources[id], "Missing projected module")
 local fn = compileSource(source, "@projected/" .. id)
 local env = setmetatable({script=nodes[id]}, {__index=base})
 env.require = function(target)
  if type(target) == "table" then return loadModule(target._id) end
  local parts = string.split(string.match(id, "^(.*)/") .. "/" .. target, "/")
  local normalized = {}
  for _,part in parts do
   if part == ".." then table.remove(normalized) elseif part ~= "." then table.insert(normalized,part) end
  end
  return loadModule(table.concat(normalized,"/"))
 end
 setfenv(fn,env)
 local value=fn()
 values[id]=value or true
 return values[id]
end
for id,source in sources do assert(compileSource(source,"@syntax/"..id), "Projected syntax failure") end
loadModule("tests/run")
-- Exercise the default Roblox adapter without making any network calls.
local scheduler=loadModule("tests/Scheduler").new()
local wireJson=loadModule("src/Core/Json")
local prefixed={AddPrefix=function() error("Prefix must be applied once") end}
local rawSecret={AddPrefix=function(_,prefix) assert(prefix=="Bearer ","Incorrect Secret prefix");return prefixed end}
local requests=0
local fieldsMode=false
local presenceStates={}
local server=true
local closeCallbacks={}
local guid=0
local http={
 GenerateGUID=function() guid+=1; return "offline-guid-"..guid end,
 GetSecret=function(_,name) assert(name=="SYNTHETIC_SECRET_NAME","Incorrect Secret lookup");return rawSecret end,
 JSONDecode=function(_,body) return scheduler.runtime.decode(body) end,
 RequestAsync=function(_,request)
  requests+=1
  assert(request.Headers.Authorization==prefixed,"Secret was not preserved as a header object")
  if string.find(request.Url,"/api/audit/events/batch",1,true) then
   assert(request.Url=="https://lb1.blox-api.com/audit-service/api/audit/events/batch","Incorrect native audit gateway route")
   assert(string.find(request.Body,'"idemKey":"offline-guid-1"',1,true),"Missing native GUID")
   return {StatusCode=202,Body=scheduler.json({accepted=1,duplicate=0}),Headers={}}
  end
  if fieldsMode then
   local path="https://lb1.blox-api.com/fields-service/api/fields/universes/123"
   if request.Url==path.."/schema" then
    return {StatusCode=200,Headers={},Body=scheduler.json({universeId=123,schemaVersion=1,definitions={{universeId=123,id="Currency.Gems",type={kind="int",min=0},scope="PLAYER",status="ACTIVE",history="LEDGER",writeLevel="READ_WRITE",definitionVersion=1,description="",createdAt="now",updatedAt="now"}}})}
   elseif request.Url==path.."/players/7/document" then
    return {StatusCode=200,Headers={},Body=scheduler.json({userId=7,seq=0,data={Currency={Gems=0}},versions={["Currency.Gems"]=0}})}
   end
   assert(request.Url==path.."/players/7/presence" and request.Method=="PUT","Unexpected Fields native route")
   local online=string.find(request.Body,'"online":true',1,true)~=nil
   table.insert(presenceStates,online)
   return {StatusCode=200,Headers={},Body=scheduler.json({userId=7,online=online,sessionId="native-session",placeId=1})}
  end
  assert(request.Url=="https://lb1.blox-api.com/fields-service/api/fields/universes/123/schema","Incorrect native Fields gateway route")
  return {StatusCode=200,Body=scheduler.json({universeId=123,schemaVersion=0,definitions=wireJson.array({})}),Headers={}}
 end,
}
local removingListeners = {}
local removalConnections = 0
local players = {PlayerRemoving={Connect=function(_,callback)
 removalConnections+=1
 removingListeners[callback]=true
 return {Disconnect=function() removingListeners[callback]=nil; removalConnections-=1 end}
end}}
base.game={BindToClose=function(_,callback) table.insert(closeCallbacks,callback) end,GetService=function(_,name)
 if name=="RunService" then return {IsServer=function() return server end} end
 if name=="Players" then return players end
 assert(name=="HttpService","Unexpected service lookup")
 return http
end}
base.task={wait=scheduler.runtime.wait,spawn=scheduler.runtime.spawn,delay=scheduler.runtime.delay,cancel=scheduler.runtime.cancel}
local sdk=loadModule("src/BloxSDK")
local client=sdk.new({secretName="SYNTHETIC_SECRET_NAME",universeId=123})
scheduler.run(function() assert(client.fields:schema().ok,"Default adapter request failed") end)
assert(requests==1,"Unexpected HTTP request count")
local writer=client:auditWriter({batchSize=10})
client:withUniverse(123):auditWriter()
client.fields:schemaCache(123)
assert(removalConnections==1,"Audit-first lifecycle must still bind PlayerRemoving")
assert(#closeCallbacks==1,"Shutdown must be registered once per shared client")
assert(writer:enqueue({occurredAt="2026-11-05T00:00:00Z",actorType="SYSTEM",actorId="server",action="game.close",resourceType="game",resourceId="123",outcome="SUCCESS"}))
assert(requests==1,"Enqueue must not block or dispatch inline")
scheduler.run(closeCallbacks[1])
assert(requests==2 and writer:pending()==0 and client._state.destroyed,"BindToClose failed to drain audit queue")
client:destroy()
assert(removalConnections==0,"Client destroy leaked removal connection")
fieldsMode=true
local fieldsClient=sdk.new({secretName="SYNTHETIC_SECRET_NAME",universeId=123})
scheduler.run(function()
 local loaded=fieldsClient.fields:loadProfile(123,7)
 assert(loaded.ok,"Native profile load failed")
 assert(loaded.value:startPresence(1,"native-session").ok,"Native presence acquisition failed")
 assert(#closeCallbacks==2,"Fields must register exactly one additional client shutdown callback")
 closeCallbacks[2]()
end)
assert(#presenceStates==2 and presenceStates[1] and not presenceStates[2],"Fields BindToClose must release presence")
assert(fieldsClient._state.destroyed and scheduler.pending()==0,"Fields tasks survived shutdown")
assert(removalConnections==0,"Fields close leaked player connection")
local leavingClient=sdk.new({secretName="SYNTHETIC_SECRET_NAME",universeId=123})
scheduler.run(function()
 local a=leavingClient.fields:loadProfile(123,7)
 local b=leavingClient.fields:loadProfile(123,7)
 assert(a.ok and b.ok and removalConnections==1,"Native duplicate profile setup failed")
 for callback in removingListeners do callback({UserId=7}) end
 assert(a.value._closed and b.value._closed,"PlayerRemoving did not destroy every handle")
 assert(next(leavingClient._helpers.sync._profiles)==nil,"Departed player leaked registry entries")
 assert(next(leavingClient._helpers.fields.profiles)==nil,"Departed player leaked helper ownership")
 leavingClient:destroy()
end)
assert(removalConnections==0 and scheduler.pending()==0,"PlayerRemoving cleanup leaked work")
print("PASS projected Fields BindToClose flush, session release, PlayerRemoving and profile lifecycle")
server=false
local ok=pcall(sdk.new,{key="bsa_"..string.rep("a",8).."_"..string.rep("b",43),universeId=123})
assert(not ok,"Client-side construction must fail")
local custom=pcall(sdk.new,{runtime=scheduler.runtime,backend=function() error("No HTTP allowed") end})
assert(not custom,"Injected adapters must not bypass the client-side guard")
values["src/BloxSDK"]=nil
local required=pcall(loadModule,"src/BloxSDK")
assert(not required,"Client-side require must fail before construction")
print("PASS projected HttpService/Secret/GUID adapter, BindToClose audit drain and server-only guard")
''')
    directory=ROOT/'.test-build';directory.mkdir(exist_ok=True)
    script=directory/'projected.luau';script.write_text('\n'.join(parts)+'\n')
    subprocess.run(['luau',str(script)],cwd=ROOT,check=True)
    subprocess.run(['lune','run',str(script)],cwd=ROOT,check=True)
if __name__=='__main__':main()
