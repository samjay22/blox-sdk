#!/usr/bin/env python3
"""Execute the complete test suite against the generated Instance-require package offline."""
from __future__ import annotations
import subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main() -> None:
    """Compile all generated modules and emulate only ModuleScript resolution, not Roblox HTTP."""
    sources={}
    for p in (ROOT/'roblox').rglob('*.luau'):
        key='src/BloxSDK' if p.name=='init.luau' else 'src/'+str(p.relative_to(ROOT/'roblox').with_suffix(''))
        sources[key]=p.read_text()
    for p in (ROOT/'tests').glob('*.luau'):sources['tests/'+p.stem]=p.read_text()
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
local function loadModule(id)
 if values[id] ~= nil then return values[id] end
 local source = assert(sources[id], "Missing projected module")
 local fn = assert(loadstring(source, "@projected/" .. id))
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
for id,source in sources do assert(loadstring(source,"@syntax/"..id), "Projected syntax failure") end
loadModule("tests/run")
-- Exercise the default Roblox adapter without making any network calls.
local scheduler=loadModule("tests/Scheduler").new()
local prefixed={AddPrefix=function() error("Prefix must be applied once") end}
local rawSecret={AddPrefix=function(_,prefix) assert(prefix=="Bearer ","Incorrect Secret prefix");return prefixed end}
local requests=0
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
   assert(string.find(request.Body,'"idemKey":"offline-guid-1"',1,true),"Missing native GUID")
   return {StatusCode=202,Body=scheduler.json({accepted=1,duplicate=0}),Headers={}}
  end
  return {StatusCode=200,Body=scheduler.json({}),Headers={}}
 end,
}
base.game={BindToClose=function(_,callback) table.insert(closeCallbacks,callback) end,GetService=function(_,name)
 if name=="RunService" then return {IsServer=function() return server end} end
 assert(name=="HttpService","Unexpected service lookup")
 return http
end}
base.task={wait=scheduler.runtime.wait,spawn=scheduler.runtime.spawn,delay=scheduler.runtime.delay,cancel=scheduler.runtime.cancel}
local sdk=loadModule("src/BloxSDK")
local client=sdk.new({secretName="SYNTHETIC_SECRET_NAME",universeId=123})
scheduler.run(function() assert(client.data:getSchemaDefaults().ok,"Default adapter request failed") end)
assert(requests==1,"Unexpected HTTP request count")
local writer=client:auditWriter({batchSize=10})
client:withUniverse(123):auditWriter()
assert(#closeCallbacks==1,"Shutdown must be registered once per shared client")
assert(writer:Enqueue({occurredAt="2026-11-05T00:00:00Z",actorType="SYSTEM",actorId="server",action="game.close",resourceType="game",resourceId="123",outcome="SUCCESS"}))
assert(requests==1,"Enqueue must not block or dispatch inline")
scheduler.run(closeCallbacks[1])
assert(requests==2 and writer:Pending()==0 and client._state.destroyed,"BindToClose failed to drain audit queue")
client:destroy()
server=false
local ok=pcall(sdk.new,{key="bsa_"..string.rep("a",8).."_"..string.rep("b",43),universeId=123})
assert(not ok,"Client-side construction must fail")
print("PASS projected HttpService/Secret/GUID adapter, BindToClose audit drain and server-only guard")
''')
    directory=ROOT/'.test-build';directory.mkdir(exist_ok=True)
    script=directory/'projected.luau';script.write_text('\n'.join(parts)+'\n')
    subprocess.run(['luau',str(script)],cwd=ROOT,check=True)
if __name__=='__main__':main()
