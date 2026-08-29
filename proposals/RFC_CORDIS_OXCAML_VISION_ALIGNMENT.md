# RFC: Cordis-OxCaml 88-Page Vision Alignment & OxCaml Modal Potential

**Status**: Proposed / Under Review  
**Author**: Antigravity Agent & Cordis-OxCaml Research Group  
**Target Subsystems**: `cordis_core`, `cordis_system`, `llamaml` plugin bridge  

---

## 1. Motivation

The original 88-page architectural specification of Cordis (authored by Shigma in the Cordiverse ecosystem) establishes that an industrial-grade plugin microkernel must satisfy:
1. **Spatial Coeffect Decoupling**: Contexts must support isolated, transparent coeffect overlays without namespace pollution.
2. **Revertible Temporal Disposal**: All side-effects must be strictly revertible via LIFO rollback trails.
3. **Homotopic Zero-Refresh HMR**: Hot Module Replacement must behave as an affine homotopy between system configurations $\text{Reload}(P, P') \simeq \text{Load}(P') \circ \text{Unload}(P)$.

Furthermore, **Jane Street's OxCaml** introduces groundbreaking language-level modal extensions:
- **Unboxed Floats (`#float`)**: Zero memory box overhead in high-performance numeric arrays.
- **Local / Global Modes (`local_`)**: Stack-allocated closures for high-frequency event dispatches that do not escape their callframe.
- **Algebraic Effect Delimited Control (`Effect.Deep`)**: First-class rollback boundaries and coroutine fiber scheduling.

This document serves as the formal specification for upgrading Cordis-OxCaml to fully incorporate these modalities.

---

## 2. Technical Specification

### 2.1 Modal Context & Radix Coeffect Manifold
Currently, `Context.t` stores bindings in dynamic hashtables. We propose transitioning to an immutable radix-trie with copy-on-write path sharing:
```ocaml
module Context = struct
  type 'a key = ..
  type t = {
    scope : Scope.t;
    manifold : Radix_tree.t;
    effects : (unit -> unit) list ref;
  }
end
```
Benefits:
- O(1) branching for `Context.isolate` and child scope derivation.
- Thread-safe, lock-free coeffect snapshots across multicore domains.

### 2.2 Algebraic Effect-Driven Service Resolution
Instead of relying on imperative event listeners for dependency gating, services are resolved using delimited algebraic continuations:
```ocaml
type _ Effect.t +=
  | Require_Service : string -> Obj.t Effect.t
  | Await_Event : string -> Obj.t Effect.t

let get_service_or_suspend (name : string) : 'a =
  perform (Require_Service name)
```
When `on_start` runs, any missing dependency suspends the plugin's execution fiber cleanly until the required service is registered in the context.

### 2.3 Integration with Llamaml Tensor Subsystem
As `llamaml` brings high-throughput LLM inference into the Cordis ecosystem, Cordis-OxCaml provides:
1. **Zero-Copy Tensor Buffers**: Shared Bigarrays managed by Cordis `Scope.t`.
2. **Speculative Decoding Rollbacks**: Delimited continuations in `Effect.Deep` allow the model to speculative branch across multiple token trajectories and revert unselected branches instantly.

---

## 3. Review & Verification

Formal invariants verified in:
- `DSOxCaml/formal/agda/DsPoly.agda`
- `Fincor/rzk/spatiotemporal.rzk`
- `llamaml/formal/agda/LlamamlTensor.agda`
- `llamaml/formal/rzk/LlamamlHomotopy.rzk`
