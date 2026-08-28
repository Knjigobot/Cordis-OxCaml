# Mathematical Foundations of Spatiotemporal Composability in Cordis-OxCaml

## 1. Introduction & Category-Theoretic Framing

Traditional software frameworks struggle with dynamic runtime adaptation: adding, modifying, or removing capabilities during active execution inevitably produces state leaks, dangling event listeners, or inconsistent distributed state.

**Cordis-OxCaml** formalizes the programming paradigm of **Spatiotemporal Composability** using the dual structures of **Effects** (temporal side-effects) and **Coeffects** (spatial ambient prerequisites), verified via homotopy invariants on simplicial directed spaces.

---

## 2. Spatial Composability (Coeffects & Context Manifolds)

Let $\mathcal{C}$ be the category of execution contexts. A context $C \in \mathcal{C}$ acts as an ambient manifold carrying dynamic services and typed observable coeffects:

$$\Gamma \vdash e : \tau \quad \implies \quad \Gamma \mid \mathcal{S} \vdash e : \tau$$

Where:
* $\Gamma$ is the static typing environment.
* $\mathcal{S}$ is the spatial coeffect bundle (e.g. `service:database`, `coeffect:bollinger`, GADT keys).

### Conservative Extension Invariant
When a plugin $P$ registers a new capability or coeffect into context $C$, it induces an endofunctor:

$$F_P : \mathcal{C} \longrightarrow \mathcal{C}$$

Such that $F_P$ is a **conservative extension**:
1. **Preservation of Existing Invariants**: For any pre-existing coeffect $K \in C$, $F_P(C)(K) = C(K)$.
2. **Orthogonality of Namespaces**: Isolated contexts $C_{\text{iso}}(N)$ satisfy $C_{\text{iso}}(N) \cap C_{\text{iso}}(M) = \emptyset$ for $N \neq M$.

---

## 3. Temporal Composability (Revertible Effects & LIFO Unwinding)

Every side-effect in Cordis-OxCaml is modeled as an arrow in a symmetric monoidal category with reversibility. A side-effect $\alpha$ generated at time $t$ is strictly paired with an inverse $\alpha^{-1}$:

$$\alpha : S_t \longrightarrow S_{t+1}, \quad \alpha^{-1} : S_{t+1} \longrightarrow S_t \quad \text{such that} \quad \alpha^{-1} \circ \alpha = \text{id}_{S_t}$$

### Linear LIFO Unwinding Theorem
Let a plugin scope $S$ accumulate a sequence of effect registrations during its active lifecycle:

$$E = [\alpha_1, \alpha_2, \dots, \alpha_n]$$

Upon scope disposal $\text{dispose}(S)$, the cleanup trajectory is uniquely evaluated in exact reverse topological order:

$$\text{Rollback}(E) = \alpha_n^{-1} \circ \alpha_{n-1}^{-1} \circ \dots \circ \alpha_1^{-1}$$

This guarantees **zero state residue** and total heap cleanliness without requiring process termination.

---

## 4. Simplicial Homotopy & 2-Simplex Commutativity (Rzk Connection)

In simplicial homotopy type theory (formalized in `Fincor/rzk/spatiotemporal.rzk` and `Fincor/rzk/contracts.rzk`), a plugin reload transition $P \to P'$ is a 2-simplex $\sigma \in \Delta^2$:

```
        State S_0
         /     \
        /       \
  Load P         Load P'
      /           \
     v             v
  State S_1 =====> State S_2
       Hot Reload Transition
```

The homotopy commutativity condition requires that reloading $P \to P'$ along the directed 1-simplex $\Delta^1$ is homotopic to full teardown and clean initialization:

$$\text{Reload}(P, P') \simeq \text{Load}(P') \circ \text{Unload}(P)$$

---

## 5. Algebraic Effects and Modal Zero-GC Execution

Cordis-OxCaml leverages OCaml 5's native delimited control (`Effect.Deep`) and Jane Street OxCaml modal types (`#float`, `local_`, `unique`):

* **Delimited Continuations**: Transaction boundaries capture the prompt continuation. If an invariant is violated, the continuation is discarded and the rollback trail executed.
* **Zero-Allocation Ring Buffers**: High-frequency tick streams update in-place within bounded circular buffers ($O(1)$ constant time), bypassing the GC nursery completely.
