local DataFrame = require "utils/DataFrame"
local inspect = require "utils/inspect"
foo = DataFrame:new{}

foo:append{task = "task1", method = "method1", time = 5, errors = 3}
foo:append{task = "task1", method = "method1", time = 6, errors = 3}
foo:append{task = "task1", method = "method2", time = 3, errors = 2}
foo:append{task = "task2", method = "method1", time = 5, errors = 3}
foo:append{task = "task2", method = "method1", time = 5, errors = 3}
foo:append{task = "task2", method = "method2", time = 7, errors = 3}
foo:append{task = "task2", method = "method3", time = 8, errors = 3}

print(inspect(foo:group_by({"task", "method"})))

print(foo:sum("time"))
print(foo:sum("errors"))
