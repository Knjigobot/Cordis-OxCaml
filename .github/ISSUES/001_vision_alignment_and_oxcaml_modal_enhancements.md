---
title: "RFC / Architectural Proposal: Vision Alignment with 88-Page Cordis Specification & Jane Street OxCaml Modal Optimization"
labels: ["rfc", "architecture", "oxcaml-modal", "cordis-core", "effects"]
assignees: []
---

# RFC: Cordis-OxCaml Vision Alignment & Modal OxCaml Maximization

## 1. Executive Summary

This proposal conducts an in-depth audit of **Cordis-OxCaml** against:
1. **Shigma's Original 88-Page Cordiverse Specification** (The foundational treatise on Spatiotemporal Composability, Coeffects, Dynamic Scopes, Intercept/Fork/Join Lifecycles, and Revertible LIFO Effect Disposal).
2. **Jane Street's OxCaml Modal Extension Capabilities** (Unboxed floats `#float`, Local/Global region modes, Linear/Unique types, Delimited Continuations via `Effect.Deep`, and zero-alloc SIMD/Bigarrays).

While `Cordis-OxCaml` successfully achieves sub-microsecond event dispatch, GADT coeffect resolution, and basic LIFO rollback, this document identifies key architectural areas where Cordis-OxCaml can further maximize its potential and align with the full vision.

---

## 2. Alignment Matrix: Cordis Vision vs Current OxCaml Implementation

| Cordis Architectural Feature | 88-Page Vision Requirement | Current OxCaml Status | Proposed Enhancement |
| :--- | :--- | :--- | :--- |
| **Coeffect Spatial Manifold** | Hierarchical coeffect propagation with isolated branch overlays | `Context.t` hashtable lookup with single-parent delegation | **Modal Coeffect Manifold**: Fast immutable radix-tree branching with $O(1)$ structural sharing and unboxed key indexing. |
| **Revertible LIFO Disposal** | Strict inverse causal unwinding with guaranteed atomicity on partial failure | `Scope.add_disposable` LIFO list execution | **Delimited Algebraic Effect Transactions**: Wrap scope mutations in `Effect.Deep` transaction boundaries with automatic rollbacks on unhandled exceptions. |
| **Plugin Hot-Swapping (HMR)** | Homotopic identity $\text{Reload}(P, P') \simeq \text{Load}(P') \circ \text{Unload}(P)$ | `Registry.reload` calls `unregister` then `register` | **State-Preserving In-Place Migration**: Inject state migration functors `migrate : State_{v1} \to State_{v2}` across hot-reload transitions without resetting memory. |
| **Service Dependency DAG** | Declarative gating with topological multi-stage readiness (`Loading` $\to$ `Ready` $\to$ `Active`) | Basic event-driven `internal/service` notifications | **Asynchronous Algebraic Effect Service Scheduler**: Suspend plugin initialization fibers until all injected coeffects are resolved. |
| **Schemastery Type Safety** | Dynamic JSON Schema introspection with Bi-directional Lens transformations | Basic GADT schema combinators in `cordis_system/schema.ml` | **Zero-Copy Modal Schema Deserializer**: Unboxed validation routines compiling schemas directly to branch-free memory validators. |
| **Zero-GC High-Throughput Engine** | Zero GC nursery allocations on high-frequency streaming paths | Heap allocations for closures and polymorphic variants | **OxCaml Jane Street Modal Primitives**: Introduce `#float`, `local_` allocation zones, and unboxed Bigarray SIMD vectorization. |

---

## 3. Detailed Proposals for Future Agent Review

### Proposal A: Jane Street OxCaml Modal Annotations (`local_` & `#float`)
- **Problem**: Context subscriber notifications and effect registration allocate small closure blocks on the minor heap.
- **Solution**: Annotate transient subscriber callbacks with `local_` stack allocations where callbacks do not escape the dynamic scope of the event dispatch.
- **Impact**: Enables 10,000,000+ events/sec with 0 bytes GC nursery pressure.

### Proposal B: Delimited Continuation-Based Fiber Scheduling for Services
- **Problem**: Circular or delayed service dependencies currently require manual ordering or event listening.
- **Solution**: Utilize OCaml 5 `Effect.Deep` delimited continuations:
  ```ocaml
  type _ Effect.t +=
    | Await_Service : string -> Obj.t Effect.t
    | Yield_Fiber : unit -> unit Effect.t
  ```
  When a plugin requests a service during `on_start`, the runtime captures the continuation and suspends the fiber until the dependency is provided.

### Proposal C: Homotopic State Migration in HMR
- **Problem**: Reloading a plugin currently discards its internal dynamic state unless manually persisted into root context.
- **Solution**: Introduce a `MIGRATABLE_PLUGIN` signature with `val extract_state : Context.t -> state_blob` and `val restore_state : Context.t -> state_blob -> unit`.

### Proposal D: Zero-Copy Bigarray Shm & Coeffect Intercept Hooks
- **Problem**: Inter-plugin communication of high-dimensional data (e.g. LLM tensor activations, market tick vectors) requires shared memory efficiency.
- **Solution**: Standardize a `Coeffect_buffer` GADT key backed by unboxed Bigarrays with lifetime bounded by the plugin's `Scope.t`.

---

## 4. Verification & Formal Invariants

All enhancements must maintain the core theorems proved in:
1. `Cordis-OxCaml/THEORY.md` (Simplicial Homotopy Invariance & LIFO Rollbacks).
2. `DSOxCaml/formal/agda/DsPoly.agda` (Polynomial Dependent Lenses).
3. `Fincor/rzk/spatiotemporal.rzk` (2-Simplex Commutativity).

---

*Submitted by Antigravity Agent for automated audit and peer review.*
