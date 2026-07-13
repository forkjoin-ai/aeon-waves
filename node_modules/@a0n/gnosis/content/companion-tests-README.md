# Chapter 17 Companion Checks

Back to [Content](./README.md)

The monoidal repair for Chapter 17 has two companion checks.

## Lean

These commands rebuild the local Mathlib workspace and re-run the mechanized laws named in the manuscript:

```bash
cd open-source/gnosis
lake build GnosisProofs
lake env lean GnosisProofs.lean
```

The relevant theorems live in [`GnosisProofs.lean`](../GnosisProofs.lean):

- `tensor_interchange`
- `race_tree_coherence`
- `fold_tree_coherence`
- `c3_deterministic_fold`
- `spectrallyStable_of_nilpotent`
- `spectrallyStable_of_rowMass`
- `supportPath_reachesSmallSet_of_distanceWitness`
- `finiteSmallSetRecurrent_of_distanceWitness`
- `countableSupportPath_reachesSmallSet_of_driftWitness`
- `countableSmallSetRecurrent_of_driftWitness`
- `countableAtomicSmallSetMinorized_one_of_collapse`
- `countableAtomAccessibleAt_of_smallSetRecurrence_and_atomicMinorization`
- `countablePsiIrreducibleAt_of_atomAccessible`
- `countableHarrisPreludeAt_of_components`
- `countableHarrisRecurrentClassAt_of_recurrence_and_prelude`
- `countableGeometricEnvelopeAt_of_harrisPrelude_and_bound`
- `countableAtomAccessible_of_smallSetRecurrence_and_atomicMinorization`
- `countablePsiIrreducibleAtAtom_of_atomAccessible`
- `countableHarrisPreludeAtAtom_of_components`
- `countableHarrisRecurrentClassAtAtom_of_recurrence_and_prelude`
- `countableAtomHittingBoundAtAtom_of_minorization`
- `countableGeometricEnvelopeAtAtom_of_harrisPrelude_and_bound`
- `countableAtomGeometricHitLowerBoundAtAtom_of_minorization`
- `countableQuantitativeGeometricEnvelopeAtAtom_of_components`
- `countableLaminarGeometricStabilityAtAtom_of_components`
- `measurableHarrisPrelude_of_components`
- `measurableHarrisPrelude_of_reversible`
- `measurableHarrisPrelude_of_le_referenceMeasure`
- `measurableSmallSetAccessible_of_irreducible`
- `measurableReferencePositiveAccessible_of_irreducible`
- `measurableHarrisCertified_of_prelude`
- `measurableIrreducible_dirac_of_atomAccessible`
- `measurableHarrisCertified_of_atomAccessible`
- `measurableSmallSetAccessible_of_atomAccessible`
- `measurableContainingAtomAccessible_of_atomAccessible`
- `measurableLaminarCertifiedAtAtom_of_atomAccessible`
- `measurableSmallSetAccessible_of_laminarCertifiedAtAtom`
- `measurableContainingAtomAccessible_of_laminarCertifiedAtAtom`
- `deterministic_pow_eq_deterministic_iterate`
- `measurableAtomAccessible_of_deterministic_hit`
- `nat_iterate_queueStep_hits_atom`
- `natMeasurableAtomAccessible_of_queueStep`
- `natQueueSupportInvariantAtAtom`
- `natQueueSupportSmallSetMinorized`
- `natMeasurableHarrisCertified_of_queueStep`
- `natMeasurableLaminarCertified_of_queueStep`
- `natMeasurableAtomHittingBound_of_queueStep`
- `natMeasurableQuantitativeLaminarCertified_of_queueStep`
- `natMeasurableQuantitativeHarrisCertified_of_queueStep`
- `natMeasurableEventuallyConvergesToAtom_of_queueStep`
- `natMeasurableFiniteTimeHarrisRecurrent_of_queueStep`
- `natQueueWitnessKernel`
- `natMeasurableAtomAccessible_of_queueWitnessKernel`
- `natMeasurableAtomHittingBound_of_queueWitnessKernel`
- `natMeasurableHarrisCertified_of_queueWitnessKernel`
- `natMeasurableLaminarCertified_of_queueWitnessKernel`
- `natMeasurableQuantitativeLaminarCertified_of_queueWitnessKernel`
- `natMeasurableQuantitativeHarrisCertified_of_queueWitnessKernel`
- `measurableContainingAtomHittingBound_of_quantitativeLaminarCertifiedAtAtom`
- `measurableSmallSetHittingBound_of_quantitativeLaminarCertifiedAtAtom`
- `measurableReferencePositiveHittingBound_of_quantitativeLaminarCertifiedAtAtom`
- `measurableQuantitativeHarrisCertified_of_quantitativeLaminarCertifiedAtAtom`
- `measurableReferencePositiveRecurrent_of_harrisCertified`
- `measurableHarrisRecurrent_of_harrisCertified`
- `measurableQuantitativeReferencePositiveRecurrent_of_quantitativeHarrisCertified`
- `measurableReferencePositivePersistent_of_eventualConvergence`
- `measurableReferencePositivePersistent_of_finiteTimeHarrisRecurrent`
- `measurableFiniteTimeGeometricStability_of_finiteTimeHarrisRecurrent`
- `measurableFiniteTimeGeometricEnvelope_of_finiteTimeHarrisRecurrent`
- `measurableHarrisRecurrent_of_finiteTimeHarrisRecurrent`
- `measurableFiniteTimeGeometricErgodic_of_finiteTimeHarrisRecurrent`
- `measurableLevyProkhorovEventuallyZero_of_eventualConvergence`
- `measurableLevyProkhorovEventuallyZero_of_finiteTimeHarrisRecurrent`
- `measurableFiniteTimeLevyProkhorovGeometricErgodic_of_finiteTimeHarrisRecurrent`
- `measurableLevyProkhorovGeometricDecayAfterBurnIn_of_eventualConvergence`
- `measurableLevyProkhorovGeometricDecayAfterBurnIn_of_finiteTimeHarrisRecurrent`
- `measurableLevyProkhorovGeometricErgodic_of_decayAfterBurnIn`
- `measurableLevyProkhorovGeometricErgodic_of_finiteTimeHarrisRecurrent`
- `MeasurableContinuousHarrisWitness`
- `natQueueAffineObservable`
- `natQueueAffineExpectedObservable`
- `natMeasurableLyapunovDriftWitness_of_queueStep_with_gap`
- `natMeasurableContinuousHarrisWitness_of_queueStep_with_gap`
- `measurableFiniteTimeHarrisRecurrent_of_quantitativeHarris_and_convergence`
- `natSmallSetRecurrent_of_stepDown`
- `natSmallSetRecurrent_of_uniformPredecessorMinorization`
- `natSmallSetRecurrent_of_margin_step`
- `certifiedKernel_stable`
- `certifiedKernel_stable_of_drift_certificate`
- `driftAt_coupledArrivalCertificate`
- `coupledArrivalCertificate_negative_drift`
- `coupledCertifiedKernel_stable`
- `tetheredCertifiedKernels_stable`

## Betti

Betti's Lean artifact emission should still pass after the proof workspace changes:

```bash
bun test open-source/gnosis/src/betty/lean.test.ts
```

This confirms that the compiler's generated proof artifact now emits a real `CertifiedKernel` witness that imports the shared proof workspace instead of relying on a local `Unit`/axiom scaffold, that the measurable queue artifact reaches the emitted exact-convergence, post-burn-in geometric-decay, and abstract geometric-ergodicity Lévy-Prokhorov endpoints as well as the earlier Harris-style endpoints, that the queue-family bridge now emits bounded affine `*_measurable_observable`, `*_measurable_observable_drift`, and `*_measurable_continuous_harris_certified` theorems over the queue-support kernel, and that the shared proof surface now also carries the bounded coupled-kernel handoff theorem for inter-app arrival pressure.
