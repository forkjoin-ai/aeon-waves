# Gnosis Roadmap

Parent: [Gnosis README](./README.md)

This roadmap keeps Gnosis narrow on purpose. The goal is not to accumulate fashionable language features. The goal is to strengthen the parts of Gnosis that already make it distinct: topology-native execution, formal verification, capability-aware deployment, and explicit graph semantics.

## Scope Discipline

- Prefer features that make `FORK`, `RACE`, `FOLD`, `VENT`, and `OBSERVE` easier to reason about.
- Prefer features that improve `gnosis lint`, `gnosis verify`, `gnosis analyze`, the REPL, and the target validator together.
- Reject features that import class-heavy object models, alternate concurrency paradigms, or syntax churn without semantic leverage.
- Keep the surface small enough that the compiler, formatter, test runner, LSP, and TLA bridge can all stay coherent.

## Dependency Order

These items are not independent.

- The effect system should land before richer concurrency guarantees, because concurrency rules need effect visibility.
- ADTs should land before exhaustiveness, `Option`/`Result`, and most useful destructuring forms.
- Quantum and differentiable features should reuse the same value, effect, and verification model instead of bypassing it with special-case semantics.
- UFCS should follow stable name resolution, module boundaries, and formatter support so the alternate call form stays unambiguous.
- Module and tooling work should progress continuously so each new feature ships with reproducible package behavior, diagnostics, formatting, and editor support.

## Effect System

### Why This Is In Scope

Gnosis already infers host requirements such as filesystem, networking, UCAN, and zero-knowledge capabilities. The next step is to move that information from best-effort analysis into the language contract itself.

### Direction

- Make effects explicit in topology signatures and module exports.
- Unify declared capabilities and inferred capabilities into one effect model.
- Treat target validation as a type check, not just a late compatibility warning.
- Keep the first version concrete and operational: filesystem, durable storage, networking, UCAN, ZK, renderer, and neural backends.

### Initial Surface

- Allow topologies and exported nodes to declare required effects.
- Infer missing effects from labels and properties, then report the inferred set alongside declared effects.
- Fail verification when the declared contract is incomplete or incompatible with the target.

### Done When

- `gnosis lint` and `gnosis verify --target <target>` report effect mismatches as first-class diagnostics.
- Module consumers can see the effect contract before executing imported topologies.
- The TLA bridge and SARIF output preserve effect information.

### Non-Goals

- A research-grade algebraic effect handler system in the first iteration.
- Hidden implicit effects that bypass target validation.

## Algebraic Data Types And Exhaustiveness

### Why This Is In Scope

`FOLD` and `OBSERVE` become much more valuable when state spaces are closed and reviewable. Gnosis needs a way to model topology states directly, not through loose property bags and string conventions.

### Direction

- Add sum types for closed state modeling.
- Add product-style value forms only where they support graph semantics cleanly.
- Require exhaustive handling when branching on closed variants.
- Keep the first release biased toward readability over type-system cleverness.

### Initial Surface

- Define tagged variants for domain states such as success, retry, timeout, denied, converged, and conflicted.
- Let `FOLD`, `OBSERVE`, and verification rules match against those variants.
- Report missing cases as compiler errors, not warnings.

### Done When

- A topology can define a closed result type and branch over it without falling back to ad hoc string labels.
- The compiler rejects incomplete matches for closed variants.
- Generated docs and editor tooling show the full shape of each closed type.

### Non-Goals

- Inheritance hierarchies disguised as data modeling.
- Open-ended subtyping as a substitute for explicit states.

## `Option` And `Result` As First-Class Error Values

### Why This Is In Scope

Gnosis should move failure through the graph as data. Ambient exceptions make topology harder to verify, harder to replay, and harder to compose across `RACE` and `FOLD`.

### Direction

- Standardize absence as `Option`.
- Standardize success-or-failure as `Result`.
- Push the language toward explicit error values instead of hidden nulls or thrown exceptions.
- Keep the first release minimal and boring: clear value shapes, clear propagation rules, clear diagnostics.

### Initial Surface

- Provide built-in `Option<T>` and `Result<T, E>` forms.
- Make match and fold behavior understand `Some`/`None` and `Ok`/`Err`.
- Teach the runtime and test runner to preserve error values instead of collapsing them into generic failure text when possible.

### Done When

- Common topology failures can be represented without exceptions.
- Verification can distinguish unhandled `Err` paths from handled ones.
- Examples and standard library helpers prefer `Option` and `Result` over sentinel values.

### Non-Goals

- A full Haskell-style monad vocabulary in the first pass.
- Implicit exception-to-`Result` conversion that hides control flow.

## Structured Concurrency For Topology Execution

### Why This Is In Scope

Gnosis already has explicit concurrency primitives. What it needs now is not goroutines, actors, or channels as separate models. It needs crisp lifetime and cancellation semantics for the model it already has.

### Direction

- Define task lifetime relative to topology structure.
- Make failure propagation deterministic across `FORK`, `RACE`, `FOLD`, and `VENT`.
- Make cancellation observable and verifiable instead of incidental runtime behavior.
- Preserve the graph-native model instead of importing thread-oriented APIs.

### Initial Surface

- `RACE` losers are cancelled by rule, not convention.
- Parent failure cancels child branches unless the topology explicitly shields or vents them.
- Timeouts, deadlines, and cleanup behavior become part of execution semantics.
- Analysis output reports branch lifetime and cancellation behavior in a way the user can inspect.

### Done When

- The engine, test runner, and TLA bridge agree on cancellation semantics.
- Replay and diagnostics show why a branch ended: success, error, timeout, cancellation, or vent.
- Capability-aware validation can reject unsafe concurrent effects on targets that cannot support them.

### Non-Goals

- Adding actors, channels, or goroutines as parallel systems.
- Hidden background work that escapes topology ownership.

## Quantum And Qubit Features

### Why This Is In Scope

Gnosis already presents itself as a quantum topological language. If that claim is going to stay central, the language needs a real, inspectable quantum surface instead of relying only on metaphor and naming.

### Direction

- Add quantum features only where they reinforce topology semantics that Gnosis already owns.
- Model qubits, measurement, entanglement, and collapse as graph-native values and transitions.
- Keep verification front and center so quantum syntax does not become an opaque side channel.
- Prefer a small, formal core over a broad gate catalog.

### Initial Surface

- Introduce explicit qubit and register value forms.
- Define first-class measurement and collapse semantics that align with `OBSERVE`, `RACE`, and `FOLD`.
- Add a minimal gate vocabulary sufficient to express superposition, phase changes, and entanglement.
- Make the compiler and analyzer report quantum state transitions and illegal operations clearly.

### Done When

- Quantum programs can be written without overloading generic property bags or ad hoc runtime labels.
- Verification can reason about legal measurement and collapse paths.
- The runtime, REPL, and docs expose quantum state changes in a way users can inspect and test.

### Non-Goals

- Shipping a full hardware-vendor quantum SDK inside Gnosis.
- Turning the core language into a physics simulator before the semantics are stable.

## Differentiable Programming

### Why This Is In Scope

Gnosis already has a `.gg`-native neural runtime. Differentiable programming is the missing bridge between topology authoring and trainable computation.

### Direction

- Make gradients and parameter updates explicit enough to reason about in topology form.
- Reuse the same closed value shapes, effects, and verification flow as the rest of the language.
- Focus first on differentiable graph execution, not on trying to absorb every machine-learning workflow into the language.
- Keep the feature compatible with CPU, GPU, and WebNN backends without making backend quirks part of the surface syntax.

### Initial Surface

- Introduce a way to mark differentiable values, parameters, and loss-producing nodes.
- Represent forward and backward passes as inspectable topology transitions rather than hidden runtime magic.
- Add gradient-aware analysis and diagnostics so users can see where differentiation stops or becomes invalid.
- Allow modules to publish differentiable topologies with explicit backend and effect requirements.

### Done When

- A Gnosis topology can describe a simple trainable computation end to end.
- The analyzer can explain gradient flow, blocked gradients, and backend constraints.
- The runtime can execute the same topology across supported backends without changing the source model.

### Non-Goals

- Replacing mature training ecosystems wholesale in the first iteration.
- Silent autodiff behavior that cannot be inspected, tested, or verified.

## Modules, Package Management, And Tooling

### Why This Is In Scope

The language surface cannot mature without a real distribution story. `gnosis.mod` exists, but it is still a placeholder compared with what the rest of the language needs.

### Direction

- Turn modules into reproducible, inspectable build units.
- Ship each new language feature with formatter, REPL, LSP, diagnostics, and verification support from the start.
- Make package compatibility visible enough that semver breakage is hard to hide.
- Keep the workflow local-first and auditable.

### Initial Surface

- Expand `gnosis.mod` with lockfile-backed dependency resolution and reproducible fetch behavior.
- Define module exports, imports, and version constraints clearly enough for tooling to reason about public contracts.
- Improve compiler diagnostics, formatter behavior, and editor support as part of the same workstream rather than as afterthoughts.
- Add docs generation for topology signatures, exported effects, and closed data shapes.

### Done When

- A fresh clone can resolve and run a module reproducibly.
- Public module surfaces are visible to the CLI and editor tooling.
- Diagnostics identify the failing topology element, the reason, and the likely fix in plain language.
- Formatting and test behavior stay stable as new syntax lands.

### Non-Goals

- A sprawling ecosystem of half-specified package hooks.
- Tooling that understands only one syntax release behind the compiler.

## Destructuring

### Why This Is In Scope

This is the one ergonomic feature that earns its keep quickly. Gnosis already moves compound values through folds, observations, and runtime labels. Pulling those values apart cleanly would reduce a lot of noise.

### Direction

- Support destructuring only where it clarifies graph logic.
- Make it compose with ADTs, `Option`, `Result`, and closed record-like values.
- Keep the first release intentionally small and unsurprising.

### Initial Surface

- Bind named fields from closed record-like values.
- Bind variant payloads when matching ADTs.
- Support tuple-style unpacking only if the value shape is explicit and formatter-friendly.
- Favor use in `FOLD`, `OBSERVE`, match arms, and local bindings.

### Done When

- Common fold outputs can be unpacked without repetitive property access.
- Match arms can bind variant payloads directly.
- The formatter and LSP can normalize and explain destructuring syntax consistently.

### Non-Goals

- JavaScript-style spread and rest everywhere on day one.
- Deep mutation via destructuring.
- Supporting destructuring before the underlying value shapes are explicit.

## Uniform Function Call Syntax

### Why This Is In Scope

UFCS can make graph-heavy code read more linearly without forcing Gnosis into an object-oriented model. The value is consistency at the call site, not hidden dispatch or runtime magic.

### Direction

- Allow `func(value)` and `value.func()` forms to compile to the same underlying graph.
- Keep resolution explicit and module-aware so UFCS never becomes a name lookup trap.
- Treat UFCS as syntax over existing functions, not as a method system bolted onto the type model.
- Preserve zero-cost lowering: UFCS should not introduce extra dispatch or allocation compared with the canonical function form.

### Initial Surface

- Support UFCS for ordinary topological functions and standard-library helpers where the first argument is the logical receiver.
- Keep precedence and chaining rules narrow enough that the formatter can normalize them reliably.
- Surface resolution errors in plain language when multiple functions could match the same UFCS call.

### Done When

- Linear transformation chains can be written readably without changing runtime behavior.
- The compiler lowers UFCS to the same graph shape as the non-UFCS form.
- The formatter, LSP, and docs generator all understand the syntax and show the resolved function target.

### Non-Goals

- Implicit extension methods that silently rewrite module boundaries.
- Dynamic dispatch semantics disguised as syntax sugar.

## Continuous Harris And Formal Synthesis

### Why This Is In Scope

Gnosis already emits Lean artifacts for spectral stability, countable recurrence, and the queue-family measurable witness surface. The next frontier is not "more proofs somewhere else." It is turning ordinary `.gg` syntax into a compiler-driven measurable Harris package that stays honest about what is and is not certified.

### Current Closure

- The compiler can emit bounded affine queue-family theorem bundles: `*_measurable_observable`, `*_measurable_observable_drift`, and `*_measurable_continuous_harris_certified`.
- State nodes can already declare `observable_kind`, `observable`, `observable_scale`, `observable_offset`, and `drift_gap` for that queue-family bridge.
- Runtime snapshots can surface the resulting `continuousHarris` witness metadata and theorem names directly.

### Direction

- Keep pushing from syntax toward proof synthesis, not from handwritten Lean toward post-hoc documentation.
- Separate what is generic queue-family closure from what is still a schema or a future kernel family.
- Extend the witness surface only when the emitted theorem names, runtime metadata, and docs can all stay aligned.

### Next Surface

- Synthesize measurable small sets from topology syntax instead of hardwiring the queue boundary path.
- Support richer observable/Lyapunov families than the current bounded affine queue witness.
- Move beyond queue-support kernels toward non-queue measurable kernels that still admit explicit Harris/minorization data.

### Done When

- A `.gg` topology with continuous observables can emit a measurable kernel plus its small set, drift witness, minorization data, and Harris certificate without hand-supplied Lean glue.
- The generated theorem family remains specific enough that the runtime can expose exactly what was proved.
- The formal ledger, README tree, and emitted artifacts all describe the same boundary without translation work from the reader.

### Non-Goals

- Claiming arbitrary continuous-state ergodicity from syntax before the small set and minorization data are actually synthesized.
- Treating queue-family closure as if it already covered non-queue measurable kernels.

## Out Of Scope For This Roadmap

- Class-oriented features such as decorators, getters/setters, primary constructors, and extension methods.
- Ownership and borrow checking as a surface-language priority.
- Alternative concurrency models such as actors, channels, and goroutines.
- Dependent types, full proof assistants, or effect-polymorphism research projects.
- AI-oriented syntax tweaks that are not justified by the language model itself.
