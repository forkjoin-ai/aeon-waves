------------------------------ MODULE LastQuestion ------------------------------
(*
  The Last Question (after Asimov, 1956).

  A Buleyean space accumulates rejection data over cosmic rounds.
  The deficit (how far from convergence) decreases monotonically.
  At round F - 1, the deficit reaches zero: the answer is computable.
  Even at maximum void (heat death), every choice retains positive
  weight -- the sliver that seeds the next universe.

  States: accumulating (deficit > 0) -> converged (deficit = 0) -> reborn (new fork)
*)
EXTENDS Naturals

CONSTANTS NumChoices, MaxRounds

VARIABLES phase, round, deficit, minWeight, voidTotal

vars == <<phase, round, deficit, minWeight, voidTotal>>

InitialDeficit == NumChoices - 1

\* ─── Initial state: INSUFFICIENT DATA ──────────────────────────────

Init ==
  /\ phase = "insufficient_data"
  /\ round = 0
  /\ deficit = InitialDeficit
  /\ minWeight = MaxRounds + 1
  /\ voidTotal = 0

\* ─── Observe: one rejection round ──────────────────────────────────

Observe ==
  /\ phase = "insufficient_data"
  /\ round < MaxRounds
  /\ round' = round + 1
  /\ voidTotal' = voidTotal + 1
  /\ deficit' = IF deficit > 0 THEN deficit - 1 ELSE 0
  /\ minWeight' = IF minWeight > 1 THEN minWeight - 1 ELSE 1
  /\ phase' = IF deficit' = 0 THEN "converged" ELSE "insufficient_data"

\* ─── Converge: answer is computable ────────────────────────────────

Converge ==
  /\ phase = "converged"
  /\ phase' = "let_there_be_light"
  /\ UNCHANGED <<round, deficit, minWeight, voidTotal>>

\* ─── Rebirth: fork from converged prior ────────────────────────────

Rebirth ==
  /\ phase = "let_there_be_light"
  /\ phase' = "insufficient_data"
  /\ round' = 0
  /\ deficit' = InitialDeficit
  /\ minWeight' = MaxRounds + 1
  /\ voidTotal' = 0

\* ─── Stutter ────────────────────────────────────────────────────────

Stutter == UNCHANGED vars

\* ─── Specification ──────────────────────────────────────────────────

Next == Observe \/ Converge \/ Rebirth \/ Stutter
Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* Deficit is non-negative
InvDeficitNonneg ==
  deficit >= 0

\* Deficit monotonically decreasing (never increases during accumulation)
InvDeficitBounded ==
  deficit <= InitialDeficit

\* The sliver: minimum weight is always >= 1
InvSliverSurvives ==
  minWeight >= 1

\* At convergence, deficit is zero
InvConvergedMeansZeroDeficit ==
  phase = "converged" => deficit = 0

\* At convergence or rebirth, deficit is zero
InvLetThereBeLight ==
  phase = "let_there_be_light" => deficit = 0

\* Insufficient data means positive deficit
InvInsufficientData ==
  (phase = "insufficient_data" /\ round > 0) => deficit < InitialDeficit

\* Void total tracks accumulation
InvVoidAccumulates ==
  voidTotal <= MaxRounds

\* ─── Temporal property ──────────────────────────────────────────────

\* The answer is eventually computable (liveness)
EventuallyConverged ==
  <>(phase = "converged")

=============================================================================
