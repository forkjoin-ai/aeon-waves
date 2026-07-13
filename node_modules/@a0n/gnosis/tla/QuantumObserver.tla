------------------------------ MODULE QuantumObserver ------------------------------
(*
  The Observer Effect as a Topological Deficit.

  A quantum system in superposition of rootN basis states has
  intrinsic beta1 = rootN - 1 (multiple parallel paths). Measurement
  is a fold: one path survives, rootN - 1 are vented to the void.
  Beta1 drops from rootN - 1 to 0.

  The observer effect is not a mystery. It is a state transition
  with a measurable topological cost: classicalDeficit = rootN - 1.
  Quantum algorithms (Grover, Shor) avoid this deficit by matching
  the intrinsic topology.

  This spec model-checks the transition and its invariants for
  bounded rootN values.
*)
EXTENDS Naturals

CONSTANTS SqrtDomain

VARIABLES phase, rootN, beta1, pathCount, voidGrown

vars == <<phase, rootN, beta1, pathCount, voidGrown>>

\* ─── Initial state: superposition ───────────────────────────────────

Init ==
  /\ rootN \in SqrtDomain
  /\ rootN > 1
  /\ phase = "superposition"
  /\ beta1 = rootN - 1
  /\ pathCount = rootN
  /\ voidGrown = 0

\* ─── Measurement action: fold ───────────────────────────────────────

Measure ==
  /\ phase = "superposition"
  /\ phase' = "measured"
  /\ rootN' = rootN
  /\ beta1' = 0
  /\ pathCount' = 1
  /\ voidGrown' = rootN - 1

\* ─── Reset: prepare a new system (for model checking breadth) ──────

Reset ==
  /\ phase = "measured"
  /\ rootN' \in SqrtDomain
  /\ rootN' > 1
  /\ phase' = "superposition"
  /\ beta1' = rootN' - 1
  /\ pathCount' = rootN'
  /\ voidGrown' = 0

\* ─── Stutter ────────────────────────────────────────────────────────

Stutter == UNCHANGED vars

\* ─── Specification ──────────────────────────────────────────────────

Next == Measure \/ Reset \/ Stutter
Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* In superposition, beta1 = rootN - 1 (the intrinsic topology)
InvSuperpositionBeta1 ==
  phase = "superposition" => beta1 = rootN - 1

\* After measurement, beta1 = 0 (the eigenstate topology)
InvMeasuredBeta1Zero ==
  phase = "measured" => beta1 = 0

\* After measurement, the deficit is exactly rootN - 1
InvDeficitExact ==
  phase = "measured" => voidGrown = rootN - 1

\* Path conservation: surviving paths + vented paths = original rootN
InvPathConservation ==
  pathCount + voidGrown = rootN

\* Void growth: after measurement, void has grown by rootN - 1
InvVoidGrowth ==
  phase = "measured" => voidGrown > 0

\* Beta1 is always non-negative and bounded by rootN - 1
InvBeta1Bounded ==
  beta1 <= rootN - 1

=============================================================================
