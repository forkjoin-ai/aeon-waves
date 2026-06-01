# Aeon Waves

String Theory Correspondence runtime for the Gnosis formal surface.

Programs are strings. Crossings are tangles. Beta1 is worldsheet genus. Module boundaries are D-branes.

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
