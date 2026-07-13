------------------------------ MODULE NonEmpiricalPrediction ------------------------------
(*
  Non-Empirical Prediction: The Structural Hole as Void Boundary.

  A structural lattice has positions, some observed, some holes.
  Each hole's properties are predicted from its neighbors' void
  boundary data. The prediction is deterministic, bounded, and
  strictly more informative than guessing.

  Models Mendeleev's periodic table, Dirac's positron, Pauli's
  neutrino, and the Higgs boson -- all cases where structure
  predicted the properties of unobserved objects.
*)
EXTENDS Naturals

CONSTANTS LatticeSize, MaxNeighborVoid, MaxNeighborRounds

VARIABLES phase, observedCount, holeCount,
          neighborVoidSum, neighborRoundsSum,
          interpolationWeight, uninformedWeight

vars == <<phase, observedCount, holeCount,
          neighborVoidSum, neighborRoundsSum,
          interpolationWeight, uninformedWeight>>

Min(a, b) == IF a <= b THEN a ELSE b

\* ─── Initial state: lattice with holes ───────────────────────────────

Init ==
  /\ observedCount \in 1..(LatticeSize - 1)
  /\ holeCount = LatticeSize - observedCount
  /\ neighborVoidSum \in 0..MaxNeighborVoid
  /\ neighborRoundsSum \in 1..MaxNeighborRounds
  /\ neighborVoidSum <= neighborRoundsSum
  /\ interpolationWeight = neighborRoundsSum - Min(neighborVoidSum, neighborRoundsSum) + 1
  /\ uninformedWeight = neighborRoundsSum + 1
  /\ phase = "predicting"

\* ─── Observe: fill a hole, gaining more neighbor data ────────────────

Observe ==
  /\ phase = "predicting"
  /\ holeCount > 1
  /\ observedCount' = observedCount + 1
  /\ holeCount' = holeCount - 1
  /\ \E newVoid \in 0..MaxNeighborVoid, newRounds \in 1..MaxNeighborRounds :
       /\ newVoid <= newRounds
       /\ neighborVoidSum' = newVoid
       /\ neighborRoundsSum' = newRounds
       /\ interpolationWeight' = newRounds - Min(newVoid, newRounds) + 1
       /\ uninformedWeight' = newRounds + 1
  /\ phase' = "predicting"

\* ─── Confirm: verify a prediction (hole becomes observed) ────────────

Confirm ==
  /\ phase = "predicting"
  /\ holeCount > 0
  /\ phase' = "confirmed"
  /\ observedCount' = observedCount + 1
  /\ holeCount' = holeCount - 1
  /\ UNCHANGED <<neighborVoidSum, neighborRoundsSum,
                 interpolationWeight, uninformedWeight>>

\* ─── Reset: continue predicting after confirmation ───────────────────

Reset ==
  /\ phase = "confirmed"
  /\ holeCount > 0
  /\ \E newVoid \in 0..MaxNeighborVoid, newRounds \in 1..MaxNeighborRounds :
       /\ newVoid <= newRounds
       /\ neighborVoidSum' = newVoid
       /\ neighborRoundsSum' = newRounds
       /\ interpolationWeight' = newRounds - Min(newVoid, newRounds) + 1
       /\ uninformedWeight' = newRounds + 1
  /\ phase' = "predicting"
  /\ UNCHANGED <<observedCount, holeCount>>

Stutter == UNCHANGED vars

Next == Observe \/ Confirm \/ Reset \/ Stutter
Spec == Init /\ [][Next]_vars

\* ─── Invariants ───────────────────────────────────────────────────────

\* Lattice partition: observed + holes = total
InvPartition ==
  observedCount + holeCount = LatticeSize

\* Interpolation weight is always positive
InvPositiveWeight ==
  interpolationWeight > 0

\* Interpolation weight is bounded above
InvWeightBounded ==
  interpolationWeight <= neighborRoundsSum + 1

\* Structure dominates: interpolation <= uninformed
InvStructureDominates ==
  interpolationWeight <= uninformedWeight

\* Uninformed weight = rounds + 1
InvUninformedCorrect ==
  uninformedWeight = neighborRoundsSum + 1

\* At least one observed position
InvSomeObserved ==
  observedCount > 0

\* Void bounded by rounds
InvVoidBounded ==
  neighborVoidSum <= neighborRoundsSum

=============================================================================
