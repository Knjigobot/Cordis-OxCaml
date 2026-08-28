# Migrating from TypeScript Cordis to Cordis-OxCaml

This guide helps developers migrate existing TypeScript / JavaScript Cordis applications (e.g. from `@cordisjs/core` or Koishi/DeepSeek Harness) to **Cordis-OxCaml**.

---

## 1. Concept Mapping

| TypeScript Cordis (`@cordisjs/core`) | Cordis-OxCaml (`cordis-oxcaml`) | Explanation |
| :--- | :--- | :--- |
| `new Context()` | `Context.root` or `Context.create "name"` | The ambient root execution context manifold. |
| `ctx.plugin(MyPlugin, config)` | `Registry.register ctx (module MyPlugin)` | Plugins are first-class modules satisfying `Registry.PLUGIN`. |
| `ctx.inject = ['db', 'timer']` | `val inject = ["database"; "timer"]` | Explicit declarative dependency injection list. |
| `ctx.on('event', callback)` | `Events.on ctx "event" callback` | Revertible event registration returning a disposable. |
| `ctx.emit('event', ...args)` | `Events.emit ctx "event" payload` | Broadcast event dispatch. |
| `ctx.bail('query', ...args)` | `Events.bail ctx "query" payload` | First-match query dispatch. |
| `ctx.waterfall('pipe', val)` | `Events.waterfall ctx "pipe" val` | Middleware pipeline transformation. |
| `ctx.provide('name', value)` | `Service.provide ctx "name" value` | Register a dynamic service with reactive notifications. |
| `ctx.effect(() => cleanup)` | `Context.effect ctx (fun () -> cleanup)` | Register a side-effect tied to scope lifecycle. |
| `Schema.object({...})` | `Cordis_system.Schema` | Type-safe schema definition with compile-time verification. |
| `ctx.setTimeout(fn, ms)` | `Cordis_system.Timer.timeout ctx sec fn` | Lifecycle-bound timer auto-cancelled on scope disposal. |

---

## 2. Code Comparison: Writing a Plugin

### TypeScript Cordis:
```typescript
import { Context, Service } from 'cordis'

export interface Config {
  threshold: number
}

export class AlertPlugin {
  static inject = ['logger']

  constructor(ctx: Context, config: Config) {
    ctx.on('market/tick', (tick) => {
      if (tick.price > config.threshold) {
        ctx.logger.warn(`Price threshold exceeded: ${tick.price}`)
      }
    })
  }
}
```

### Cordis-OxCaml:
```ocaml
open Cordis_core
open Cordis_system

module AlertPlugin : Registry.PLUGIN = struct
  let name = "alert_plugin"
  let version = "1.0.0"
  let inject = ["logger"]

  let on_init (ctx : Context.t) = ()

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    ignore (Events.on ctx "market/tick" (fun (tick : tick) ->
      if tick.last_price > 100.0 then
        Logger.warn log "Price threshold exceeded: $%.2f" tick.last_price
    ))

  let on_stop (ctx : Context.t) = ()
  let on_dispose (ctx : Context.t) = ()
end
```

---

## 3. Code Comparison: Dynamic Service Registration

### TypeScript Cordis:
```typescript
class DatabaseService extends Service {
  constructor(ctx: Context) {
    super(ctx, 'database')
  }
  query(sql: string) { /* ... */ }
}
ctx.plugin(DatabaseService)
```

### Cordis-OxCaml:
```ocaml
open Cordis_core

type db = { query : string -> string list }

let init_database (ctx : Context.t) =
  let db_instance = { query = (fun sql -> [ "row1"; "row2" ]) } in
  Service.provide ctx "database" db_instance
```

---

## 4. Key Architectural Advantages in OxCaml
1. **Zero Garbage Collection for Math Pipelines**: Jane Street unboxed types (`#float`) and in-place ring buffers mean tick processing creates zero nursery allocations.
2. **Algebraic Effect Rollbacks**: Built-in transactional rollback with OCaml 5 `Effect.Deep`.
3. **True Memory Leak Elimination**: Strong ownership and linear LIFO disposal guarantee that no callbacks or background loops survive scope teardown.
