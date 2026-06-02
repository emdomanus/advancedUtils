# Advanced Utils

Reusable Roblox utility primitives for complex game projects.

This package is intended to hold generic, game-agnostic infrastructure such as data structures, math helpers, guards, tables, promises, hooks, logging, and id allocation. Game-specific adapters should stay in the game repo.

Lifecycle bootstrapping lives in the standalone `emdomanus/bootstrap` package.

## Package Shape

```luau
local AdvancedUtils = require(ReplicatedStorage.packages.roblox_packages.advanced_utils)

type Hook<T...> = AdvancedUtils.Hook<T...>
```

Current namespaces:

- `core`
- `dataStructures`
- `functional`
- `math`

Core utilities include:

- `AdvancedUtils.core.hook`
- `AdvancedUtils.core.log`
