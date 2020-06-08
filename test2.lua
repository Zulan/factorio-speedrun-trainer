local inspect = require "utils/inspect"

out = {}

out["foo"] = out["foo"] or {}
table.insert(out["foo"], 1)
out["foo"] = out["foo"] or {}
table.insert(out["foo"], 2)
out["bar"] = out["bar"] or {}
table.insert(out["bar"], 1)

print(inspect(out))
