# Changelog

All notable changes to **Cordis-OxCaml** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-08-28

### Initial Release: 100% Native OxCaml Spatiotemporal Meta-Framework

#### `cordis_core` (Microkernel)
* **Spatial Context Manifold**: Typed GADT coeffect keys, dynamic string keys, context inheritance, and isolation namespaces.
* **Temporal Revertible Effects**: LIFO unwinding disposables, automatic cascading subtree disposal, active assertion checks.
* **Revertible Event Bus**: Multiple dispatch modes (`emit`, `serial`, `bail`, `waterfall`, `parallel`) with automatic unregistration.
* **Dynamic Service Registry**: Service provision, dynamic resolution, and reactive lifecycle notifications (`internal/service`).
* **First-Class Module Plugin System**: Dynamic registration, dependency gating (`inject`), and sandbox fault isolation (`Quarantined` state).
* **Algebraic Effects**: OCaml 5 `Effect.Deep` integration for transactional rollback.

#### `cordis_system` (Subsystems)
* **Schema (Schemastery in OxCaml)**: Type-safe configuration schemas, range bounds, defaults, and JSON serialization.
* **Timer**: Lifecycle-bound timers (timeout, interval, throttle, debounce, heartbeat) with auto-cancellation upon scope disposal.
* **Logger**: Hierarchical structured leveled logger with ANSI colors and JSON formats.
* **Loader**: Declarative manifest manager, topological DAG dependency sorting, and dynamic hot-reconciler.
* **Http_server**: Zero-dependency native HTTP 1.1 + Server-Sent Events (SSE) server for live streaming and status telemetry.

#### `cordis_quant` (Quantitative & Reactive Pipeline)
* **Ring Buffer**: Zero-allocation sliding window circular buffer with $O(1)$ updates and statistical operations.
* **Market Feed**: Stochastic Geometric Brownian Motion (GBM) + Merton Jump Diffusion generator.
* **Plugins**: Native Cordis Bollinger Bands and Moving Average indicator plugins.

#### Documentation & Examples
* **THEORY.md**: Formal category-theoretic and simplicial homotopy proofs.
* **MIGRATION.md**: Side-by-side migration guide from TypeScript `@cordisjs/core`.
* **5 Standalone Examples**: Hello Cordis, Revertible Effects, Dependency Injection, Schemastery Configs, and Full Trading Daemon.
* **Complete Test Suite**: Formal verification covering all mathematical invariants.
