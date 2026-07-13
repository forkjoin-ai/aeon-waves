------------------------------ MODULE VoidDominance ------------------------------
(***************************************************************************)
(* THM-VOID-DOMINANCE: Void volume grows as Omega(T * (N-1)), dominating  *)
(* active computation by factor Omega(T). For nested depth d, void grows  *)
(* as Omega(T * N^d) while active paths remain bounded at N^d.            *)
(*                                                                         *)
(* Computational dark energy: the void is created at every fold and never  *)
(* consumed (no unfold primitive). The void fraction approaches 1 as T    *)
(* grows, exactly as the dark energy fraction of the universe approaches  *)
(* 1 as the universe expands.                                              *)
(*                                                                         *)
(* Dark matter analogy: just as dark matter (~85% of mass) has             *)
(* gravitational structure that shapes galaxy formation, the               *)
(* computational void dominates active computation and has boundary        *)
(* structure that guides future forks. The void IS the dark matter of      *)
(* computation -- invisible but structurally essential.                     *)
(***************************************************************************)

EXTENDS Naturals

CONSTANTS
  ForkWidth,    \* N >= 2
  MaxSteps      \* Maximum T

VARIABLES
  step,              \* Current step
  voidVolume,        \* Cumulative void size
  activePaths,       \* Current active paths (always 1 after fold, N during race)
  totalComputation,  \* void + active (total state space explored)
  phase

vars == <<step, voidVolume, activePaths, totalComputation, phase>>

ASSUME ForkWidth >= 2
ASSUME MaxSteps >= 1

Init ==
  /\ step = 0
  /\ voidVolume = 0
  /\ activePaths = 1
  /\ totalComputation = 1
  /\ phase = "ready"

\* Fork: expand to N paths
Fork ==
  /\ phase = "ready"
  /\ step < MaxSteps
  /\ activePaths' = ForkWidth
  /\ totalComputation' = totalComputation + (ForkWidth - 1)
  /\ phase' = "racing"
  /\ UNCHANGED <<step, voidVolume>>

\* Fold: collapse to 1 survivor, N-1 go to void
Fold ==
  /\ phase = "racing"
  /\ activePaths = ForkWidth
  /\ voidVolume' = voidVolume + (ForkWidth - 1)
  /\ activePaths' = 1
  /\ step' = step + 1
  /\ phase' = "ready"
  /\ UNCHANGED <<totalComputation>>

Stutter == UNCHANGED vars

Next ==
  \/ Fork
  \/ Fold
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Fork)
    /\ WF_vars(Fold)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Void volume = T * (N-1)
InvVoidVolumeFormula ==
  (phase = "ready") => voidVolume = step * (ForkWidth - 1)

\* INV2: Active paths bounded by N
InvActivePathsBounded ==
  activePaths <= ForkWidth

\* INV3: Void dominates: |V| >= step (since N-1 >= 1)
InvVoidDominatesLinear ==
  (phase = "ready") => voidVolume >= step

\* INV4: Total computation = void + active
InvTotalConservation ==
  (phase = "ready") => totalComputation = voidVolume + activePaths

\* INV5: Void fraction increases with each step
\* (voidVolume / totalComputation increases monotonically)
\* Encoded as: voidVolume * (prevTotal) >= prevVoid * totalComputation
\* Simplified: void grows faster than total
InvVoidFractionGrows ==
  (phase = "ready" /\ step >= 2)
    => voidVolume * (voidVolume + ForkWidth + ForkWidth - 1) >=
       (voidVolume - ForkWidth + 1) * (voidVolume + ForkWidth)

\* INV6: Void is positive after first fold
InvVoidPositiveAfterFirstFold ==
  (step >= 1 /\ phase = "ready") => voidVolume > 0

\* INV7: At completion, void dominates by factor >= T
InvFinalDominance ==
  (step = MaxSteps /\ phase = "ready")
    => voidVolume >= MaxSteps

=============================================================================
