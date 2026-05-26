# Advanced Utils

Reusable Roblox utility primitives for complex game projects.

This package is intended to hold generic, game-agnostic infrastructure such as data structures, math helpers, guards, tables, promises, hooks, logging, bootstrap helpers, and id allocation. Game-specific adapters should stay in the game repo.

## Package Shape

```luau
local AdvancedUtils = require(ReplicatedStorage.packages["advanced-utils"])
```

Current namespaces:

- `core`
- `dataStructures`
- `functional`
- `math`

Core utilities include:

- `AdvancedUtils.core.bootstrap`
- `AdvancedUtils.core.hook`
- `AdvancedUtils.core.log`
