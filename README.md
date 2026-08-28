# Cordis-OxCaml

[![CI](https://github.com/Knjigobot/Cordis-OxCaml/actions/workflows/ci.yml/badge.svg)](https://github.com/Knjigobot/Cordis-OxCaml/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![OCaml 5+](https://img.shields.io/badge/OCaml-5.0%2B-orange.svg)](https://ocaml.org)
[![OxCaml Ready](https://img.shields.io/badge/OxCaml-Modal%20Unboxed-green.svg)](https://github.com/janestreet)

**Cordis-OxCaml** is an industrial-grade, mathematically verified meta-framework for **Spatiotemporal Composability** implemented in native **OxCaml** (OCaml 5+ with Jane Street modal extensions and algebraic effects).

Originally created by Shigma (Koishi / Cordiverse) and adopted as the plugin microkernel for **DeepSeek Harness**, Cordis enables modular, self-evolving systems where *"everything is a hot-swappable plugin"*. Cordis-OxCaml brings this paradigm to native compiled systems with sub-microsecond latency, zero memory leaks, in-place zero-refresh Hot Module Replacement (HMR), and formal rollback guarantees.

---

## 🏛 System Architecture

```
+-----------------------------------------------------------------------------------------------+
|                                      CORDIS-OXCAML RUNTIME                                     |
+-----------------------------------------------------------------------------------------------+
|   CORDIS_CORE (Pure Microkernel)            |   CORDIS_SYSTEM (Developer Subsystems)         |
|   - Spatial Context Manifold (Coeffects)    |   - Schemastery (Type-Safe Schemas)           |
|   - Revertible LIFO Effect Disposal         |   - Lifecycle-Bound Timers (Timeout/Interval)  |
|   - Dynamic Service Locator & GADTs         |   - Hierarchical Leveled Logger (ANSI/JSON)    |
|   - Revertible Event Bus (Emit/Serial/Bail) |   - Declarative DAG Dependency Loader          |
|   - First-Class Module Plugins & Quarantine |   - In-Place Zero-Refresh HMR Reconciler       |
|   - OCaml 5 Algebraic Effects (Effect.Deep) |   - Zero-Dependency Native HTTP 1.1 + SSE      |
+---------------------------------------------+-------------------------------------------------+
|                       NATIVE PLATFORM & HARDWARE EXECUTION LAYER                              |
|   - OCaml 5 Delimited Control (Effect.Deep)     - Jane Street Unboxed Layouts (#float)        |
|   - First-Class Modules `(module PLUGIN)`       - Zero External Dependencies (Pure Unix)      |
+-----------------------------------------------------------------------------------------------+
```

---

## 🔬 Core Mathematical Guarantees

1. **Spatial Composability (Coeffects)**: Components declare ambient runtime prerequisites via typed GADTs (`Context.get`, `Context.set`) and dynamic services (`Service.provide`).
2. **Temporal Composability (Revertible Effects)**: Side-effects (listeners, timers, hooks, state mutations) are paired with linear disposables. Unloading a plugin executes rollbacks in **strict reverse LIFO order**, ensuring **zero memory leaks or dangling callbacks**.
3. **Simplicial Homotopy Invariance (Zero-Refresh HMR)**: Hot-reloading a plugin is homotopic to full atomic teardown followed by clean initialization ($\text{Reload}(P, P') \simeq \text{Load}(P') \circ \text{Unload}(P)$). No page reload or process restart is ever needed.
4. **Sandbox Fault Isolation**: Uncaught exceptions in plugin lifecycles are trapped, shifting the faulty module into a `Quarantined` state without crashing the host kernel.

---

## 📦 Repository Structure

```
Cordis-OxCaml/
├── cordis_core/                 # Pure Microkernel (Context, Scope, Events, Service, Registry, Effects)
├── cordis_system/               # Subsystems (Schema, Timer, Logger, Loader, Hmr, Http_server)
├── examples/                    # 5 runnable standalone examples
│   ├── 01_hello_cordis/         # Basic plugin and event listener
│   ├── 02_revertible_effects/   # State mutation rollback on unregistration
│   ├── 03_dependency_injection/ # Service dependency gating & dynamic activation
│   ├── 04_config_schema/        # Schemastery config validation & JSON reflection
│   └── 05_hmr_live_reload/      # In-place Zero-Refresh Hot Module Replacement
├── test/                        # Complete automated formal verification test suite
├── bin/                         # CLI entrypoint daemon (`cordis start`, `cordis test`)
├── THEORY.md                    # Formal mathematics and category-theoretic proofs
├── MIGRATION.md                 # Migration guide from TypeScript Cordis
└── cordis-oxcaml.opam           # Opam package definition
```

---

## 🚀 Quickstart

### 1. Build with Dune
```bash
# Build all libraries, executables, and examples
dune build @all

# Run the full test suite
dune runtest
```

### 2. Basic Plugin Example
```ocaml
open Cordis_core
open Cordis_system

module MyPlugin : Registry.PLUGIN = struct
  let name = "telemetry_collector"
  let version = "1.0.0"
  let inject = ["logger"]

  let on_init (ctx : Context.t) = ()

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Plugin active! Registering event hook...";
    ignore (Events.on ctx "system/alert" (fun (msg : string) ->
      Logger.warn log "[ALERT] %s" msg
    ))

  let on_stop (ctx : Context.t) = ()
  let on_dispose (ctx : Context.t) = ()
end

let () =
  let ctx = Context.root in
  let unregister = Registry.register ctx (module MyPlugin) in

  Events.emit ctx "system/alert" "Disk usage at 95%";

  (* Unload plugin -> all event hooks automatically removed in LIFO order *)
  unregister ()
```

---

## 💻 Zero-Refresh In-Place HMR Demonstration

```bash
dune exec examples/05_hmr_live_reload/main.exe
```

Demonstrates in-place dynamic plugin replacement where old hooks and subscriptions are cleanly unwound and new logic is hot-swapped live with zero memory residue and zero process restart.

---

## 📜 Attributions & Licensing

Released under the **MIT License**.

Attributions:
* **Cordis Meta-Framework**: Developed by [Shigma](https://github.com/shigma) & [Cordiverse](https://github.com/cordiverse/cordis).
* **DeepSeek Harness**: Runtime architecture by [DeepSeek-AI](https://github.com/deepseek-ai/dsh).
* **OxCaml & Jane Street Tools**: Jane Street Group LLC.
