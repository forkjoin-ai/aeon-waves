# Aeon Waves

String Theory Correspondence runtime for the Gnosis formal surface.

Programs are strings. Crossings are tangles. Beta1 is worldsheet genus. Module boundaries are D-branes.

## Purpose and architecture

The package implements executable diagnostic representations corresponding to named Gnosis formal concepts. TypeScript runtime modules consume program or knot-shaped state and emit metrics; the Lean corpus remains the proof authority, while this package is an interpretation layer rather than a proof checker.

## From Lean to TypeScript

This package bridges `StringTheoryCorrespondence.lean` theorems to executable runtime:

- `StringState` ≅ `AlgorithmicKnot` (isomorphism)
- `Worldsheet` genus = program loop count (beta1)
- `PairOfPants` = fork/fold (composeKnots)
- `GaugeEquivalence` = Reidemeister moves (behavior-preserving transforms)
- `Vacuum` = unknot = correct program
- `DBrane` = type boundary (Dirichlet condition on function endpoints)
- `Compactification` = abstraction (hidden internal dimensions)
- `Holography` = void boundary sufficient statistic (AdS/CFT)
- `TDuality` = FoldedKnot ≅ defenseWeight (R ↔ 1/R)

## Theorem Surface

See `open-source/gnosis/lean/Lean/ForkRaceFoldTheorems/StringTheoryCorrespondence.lean`

## Interface and configuration

Consumers use the exported runtime types and evaluators from `src/`. The package has no network or persistence configuration; theorem identifiers and source links are provenance, not runtime-loaded proof objects.

## Operations and verification

Run the package's test and typecheck targets through the repository task runner. When changing a claimed correspondence, verify the named Lean declaration independently and add runtime cases that distinguish the represented metric from the underlying theorem.

## Failure and risk boundaries

Executable agreement on examples does not establish mathematical equivalence. Metaphors such as branes or compactification must not be upgraded into identity claims, and missing or renamed Lean declarations make the documented provenance stale even if TypeScript still compiles.

## Jet-Engine Compressor Cascade

No clean multiplicative stage here. The engines (Turbulence/Oceanography/Astronomy/Geology) are
pure formal-diagnostic evaluators of a single God-Formula (`w = R - min(v, R) + 1`) — there is no
compression/codec, caching/skip, batching, fan-out, dedup, or parallel speedup to multiply. They map
Lean theorems to executable metrics, an OSI **L6 (presentation)** representation transform. If a real
pipeline ever lands here (e.g. a batched/fan-out diagnostic sweep), declare it with the shared cascade
primitive `open-source/aether/src/wasm-simd/compressor-cascade.ts` (`stage`, `overallRatio`, `compose`,
`cascadeReport`) — the OSI keystone is `Gnosis.OSICompressorCascade.osi_is_the_jet_compressor`, whose
overall ratio is the product of per-layer ratios (`Gnosis.MathJetEngine.overallRatio_append`).

## License

MIT
