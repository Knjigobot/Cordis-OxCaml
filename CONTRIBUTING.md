# Contributing to Cordis-OxCaml

We welcome contributions from the community to make Cordis-OxCaml the definitive spatiotemporal composability framework for native, zero-GC, high-performance systems.

---

## 🛠 Development Workflow

### Prerequisites
* OCaml 5.0+ or OxCaml compiler
* Dune 3.10+
* Opam 2.0+

### Setup Local Repository
```bash
git clone https://github.com/cordiverse/cordis-oxcaml.git
cd cordis-oxcaml
opam install . --deps-only --with-test -y
```

### Build & Run Tests
```bash
# Build all libraries and executables
dune build @all

# Run the complete verification test suite
dune runtest
```

---

## 📐 Guidelines for Contributions

1. **Maintain Invariant Guarantees**:
   * Any change to `cordis_core` must preserve the **Linear LIFO Unwinding Theorem** and **Conservative Extension Invariant** (see `THEORY.md`).
   * No side-effect may be registered without a corresponding inverse `disposable`.
2. **Zero Memory Leak Requirement**:
   * When scopes are disposed, all subscriber tables, event listeners, and timers must be completely cleared.
3. **Module Interfaces**:
   * Every `.ml` file in `cordis_core/`, `cordis_system/`, and `cordis_quant/` must be accompanied by an explicit, well-documented `.mli` interface file.
4. **Testing**:
   * Add test cases to `test/` for any new feature or bugfix.
