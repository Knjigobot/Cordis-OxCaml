# Cordis-OxCaml

[![CI](https://github.com/cordiverse/cordis-oxcaml/actions/workflows/ci.yml/badge.svg)](https://github.com/cordiverse/cordis-oxcaml/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![OCaml 5+](https://img.shields.io/badge/OCaml-5.0%2B-orange.svg)](https://ocaml.org)
[![OxCaml Ready](https://img.shields.io/badge/OxCaml-Modal%20Unboxed-green.svg)](https://github.com/janestreet)

**Cordis-OxCaml** is an industrial-grade, mathematically verified meta-framework for **Spatiotemporal Composability** implemented in native **OxCaml** (OCaml 5+ with Jane Street modal extensions and algebraic effects).

Originally created by Shigma (Koishi / Cordiverse) and adopted as the plugin microkernel for **DeepSeek Harness**, Cordis enables modular, self-evolving systems where *"everything is a hot-swappable plugin"*. Cordis-OxCaml brings this paradigm to native compiled systems with sub-microsecond latency, zero-GC quantitative math pipelines, and formal rollback guarantees.

---

## 🏛 System Architecture

```
+-----------------------------------------------------------------------------------------------+
|                                      CORDIS-OXCAML RUNTIME                                     |
+-----------------------------------------------------------------------------------------------+
|   CORDIS_CORE (Microkernel) |   CORDIS_SYSTEM (Developer Framework) |  CORDIS_QUANT (FinTech)  |
|   - Spatial Context         |   - Schemastery (Type-Safe Schemas)   |  - Unboxed Ring Buffer   |
|   - Revertible LIFO Effects |   - Lifecycle-Bound Timers            |  - Stochastic GBM/Jumps  |
|   - Service Locator & GADTs |   - Structured Leveled Logger         |  - Bollinger Bands       |
|   - Revertible Event Bus    |   - DAG Dynamic Manifest Loader       |  - Moving Average Cross  |
|   - Algebraic Effect Handler|   - Native HTTP 1.1 + SSE Daemon      |  - Low-Latency Telemetry |
+-----------------------------+---------------------------------------+--------------------------+
|                       NATIVE PLATFORM & HARDWARE EXECUTION LAYER                              |
|   - OCaml 5 Delimited Control (Effect.Deep)     - Jane Street Unboxed Layouts (#float)        |
|   - First-Class Modules `(module PLUGIN)`       - Zero External Dependencies (Pure Unix)      |
+-----------------------------------------------------------------------------------------------+
```

---

## 🔬 Core Mathematical Guarantees

1. **Spatial Composability (Coeffects)**: Components declare ambient runtime prerequisites via typed GADTs (`Context.get`, `Context.set`) and dynamic services (`Service.provide`).
2. **Temporal Composability (Revertible Effects)**: Side-effects (listeners, timers, hooks, state mutations) are paired with linear disposables. Unloading a plugin executes rollbacks in **strict reverse LIFO order**, ensuring **zero memory leaks or dangling callbacks**.
3. **Simplicial Homotopy Invariance**: Hot-reloading a plugin is homotopic to full atomic teardown followed by clean initialization ($\text{Reload}(P, P') \simeq \text{Load}(P') \circ \text{Unload}(P)$).
4. **Sandbox Fault Isolation**: Uncaught exceptions in plugin lifecycles are trapped, shifting the faulty module into a `Quarantined` state without crashing the host kernel.

---

## 📦 Repository Structure

```
Cordis-OxCaml/
├── cordis_core/                 # Microkernel (Context, Scope, Events, Service, Registry, Effects)
├── cordis_system/               # Subsystems (Schema, Timer, Logger, Loader, Http_server)
├── cordis_quant/                # High-perf quantitative finance extensions (Ring buffers, indicators)
├── examples/                    # 5 runnable examples from basic hello-world to full trading daemon
│   ├── 01_hello_cordis/
│   ├── 02_revertible_effects/
│   ├── 03_dependency_injection/
│   ├── 04_config_schema/
│   └── 05_trading_daemon/
├── test/                        # Complete automated formal verification & unit test suite
├── bin/                         # CLI entrypoint daemon (`cordis start`, `cordis test`)
├── THEORY.md                    # Formal mathematics and category-theoretic proofs
├── MIGRATION.md                 # Migration guide from JavaScript/TypeScript Cordis
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

  (* Unload plugin -> all event hooks automatically removed *)
  unregister ()
```

---

## 💻 Running the Trading Daemon & Live SSE Server

```bash
dune exec examples/05_trading_daemon/main.exe
```

This starts the native zero-dependency HTTP and SSE server on `http://127.0.0.1:8088`, generating real-time tick streams, running Bollinger Band breakout detection and Moving Average crossovers, and broadcasting live events with sub-microsecond latency.

---

## 📜 Attributions & Licensing

Released under the **MIT License**.

Attributions:
* **Cordis Meta-Framework**: Developed by [Shigma](https://github.com/shigma) & [Cordiverse](https://github.com/cordiverse/cordis).
* **DeepSeek Harness**: Runtime architecture by [DeepSeek-AI](https://github.com/deepseek-ai/dsh).
* **OxCaml & Jane Street Tools**: Jane Street Group LLC.
