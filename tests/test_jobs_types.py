"""Compile the public durable-job helper surface and reject malformed typed callers offline."""
from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class JobsTypesTests(unittest.TestCase):
    """Protect strict builders and receipts independently of generated route fixtures."""

    def test_public_job_types(self) -> None:
        """Reject wrong filters, actions, imports, callback and receipt types at compile time."""
        prelude = '''--!strict
local SDK = require("./src/BloxSDK")
local Types = require("./src/Fields/Types")
local Wire = require("./src/Types/Fields")
--- Compile only; no client, transport or application is started.
return function(client: SDK.Client, receipt: Wire.JobReceipt)
 local target: Types.BulkTarget = {kind="WHERE",where={op="GE",field="Currency.Gems",value=100}}
 local bulk = client.fields:bulkBuilder(123):target(target):reason("Event reward"):idempotencyKey("reward-1")
 bulk.ops:add("Currency.Gems",10):set("Settings",false,{"Sound"})
 local _built = bulk:build()
 local _schedule = client.fields:scheduleClient(123):build({name="Event",start="2026-12-01T12:00:00Z",
   startActions={{kind="ENABLE_FLAG",key="event"}},reason="Event start",idempotencyKey="event-1"})
 local jobs = client.fields:jobClient(123)
 local _import = jobs:buildImport({{subject=7,field="Currency.Gems",op="ADD",delta=1}})
 local _result = jobs:waitFor(receipt.id,{timeout=30,onProgress=function(job: Wire.JobReceipt)
   local _failed: number = job.failed
 end})
 local _health = client.fields:healthClient(123):summary()
 local _failed: number = receipt.failed
'''
        cases = (
            ("", True),
            ('bulk.ops:add("Currency.Gems","10")', False),
            ('local bad: Types.BulkTarget = {kind="SUBJECTS",subjects={"7"}}', False),
            ('local bad: Types.BulkTarget = {kind="WHERE",where={op="SQL",field="X",value=1}}', False),
            ('local bad: Types.BulkTarget = {kind="WHERE",where={op="EXISTS",field="X",value=1}}', False),
            ('local bad: Types.ScheduleAction = {kind="SET_CONFIG",key="x",type="INTEGER",value=1}', False),
            ('local bad: Types.ScheduleAction = {kind="SET_CONFIG",key="x",type="BOOLEAN",value="true"}', False),
            ('local bad: Types.ImportRecord = {subject=7,field="X",op="ADD",delta="1"}', False),
            ('local bad: Types.ImportRecord = {subject=7,field="X",op="RESET"}', False),
            ('jobs:waitFor(receipt.id,{timeout="30"})', False),
            ('jobs:waitFor(receipt.id,{onProgress=function(_job: string) end})', False),
            ('local bad: string = receipt.failed', False),
        )
        with tempfile.TemporaryDirectory(prefix="jobs-types-", dir=ROOT / ".test-build") as temporary:
            path = ROOT / (Path(temporary).name + ".luau")
            try:
                for extra, valid in cases:
                    with self.subTest(extra=extra):
                        path.write_text(prelude + extra + "\nend\n")
                        result = subprocess.run(
                            ["luau-analyze", "-j1", str(path)], capture_output=True, text=True, check=False
                        )
                        output = result.stdout + result.stderr
                        if valid:
                            self.assertEqual(result.returncode, 0, output)
                        else:
                            self.assertNotEqual(result.returncode, 0, extra)
                            self.assertIn("TypeError", output)
            finally:
                path.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
