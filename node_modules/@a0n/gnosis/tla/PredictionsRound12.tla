------------------------------ MODULE PredictionsRound12 ------------------------------
(*
  Predictions Round 12: Empathy Nadir, Stagnation-Learning Duality,
  Diversity Ceiling, Solomonoff-Weight Conservation, Rational Coherence.

  Five compositional predictions using multi-field interactions,
  dualities, and conservation laws.
*)
EXTENDS Naturals

CONSTANTS DimsA, DimsB, Shared, FailurePaths, DecisionStreams,
          Complexity, TotalRounds, NumHypotheses

VARIABLES phase, effectiveDims, empathyNadir,
          currentContext, exploitDeficit,
          diversityLevel, diversityWaste,
          weight, conservationSum,
          boundaryA, boundaryB

vars == <<phase, effectiveDims, empathyNadir,
          currentContext, exploitDeficit,
          diversityLevel, diversityWaste,
          weight, conservationSum,
          boundaryA, boundaryB>>

Min(a, b) == IF a <= b THEN a ELSE b
Ceiling == FailurePaths - DecisionStreams

Init ==
  /\ phase = "empathy"
  /\ effectiveDims = DimsA + DimsB - Shared
  /\ empathyNadir = DimsA + DimsB - Shared - 1
  /\ currentContext = 0
  /\ exploitDeficit = Ceiling - Min(0, Ceiling)
  /\ diversityLevel = 1
  /\ diversityWaste = Ceiling - Min(1, Ceiling)
  /\ weight = TotalRounds - Complexity + 1
  /\ conservationSum = (TotalRounds - Complexity + 1) + Complexity
  /\ boundaryA = [i \in 1..NumHypotheses |-> 0]
  /\ boundaryB = [i \in 1..NumHypotheses |-> 0]

\* P147: Empathy exchange
EmpathyStep ==
  /\ phase = "empathy"
  /\ phase' = "explore"
  /\ UNCHANGED <<effectiveDims, empathyNadir, currentContext,
                  exploitDeficit, diversityLevel, diversityWaste,
                  weight, conservationSum, boundaryA, boundaryB>>

\* P148: Explore step (accumulate context)
ExploreStep ==
  /\ phase = "explore"
  /\ currentContext < Ceiling
  /\ currentContext' = currentContext + 1
  /\ exploitDeficit' = Ceiling - Min(currentContext + 1, Ceiling)
  /\ phase' = "diversity"
  /\ UNCHANGED <<effectiveDims, empathyNadir, diversityLevel,
                  diversityWaste, weight, conservationSum,
                  boundaryA, boundaryB>>

\* P149: Diversity step
DiversityStep ==
  /\ phase = "diversity"
  /\ diversityLevel < Ceiling + 2
  /\ diversityLevel' = diversityLevel + 1
  /\ diversityWaste' = Ceiling - Min(diversityLevel + 1, Ceiling)
  /\ phase' = "solomonoff"
  /\ UNCHANGED <<effectiveDims, empathyNadir, currentContext,
                  exploitDeficit, weight, conservationSum,
                  boundaryA, boundaryB>>

\* P150 + P151: Observation step
ObservationStep ==
  /\ phase = "solomonoff"
  /\ phase' = "empathy"
  /\ UNCHANGED <<effectiveDims, empathyNadir, currentContext,
                  exploitDeficit, diversityLevel, diversityWaste,
                  weight, conservationSum, boundaryA, boundaryB>>

Stutter == UNCHANGED vars

Next == EmpathyStep \/ ExploreStep \/ DiversityStep
     \/ ObservationStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P147: Empathy nadir is positive
InvNadirPositive ==
  empathyNadir >= 1

\* P147: Shared experience reduces nadir (vs raw = DimsA + DimsB - 1)
InvSharedReducesNadir ==
  (Shared > 0) => (empathyNadir < DimsA + DimsB - 1)

\* P148: At ceiling, deficit is zero
InvCeilingZeroDeficit ==
  (currentContext >= Ceiling) => (exploitDeficit = 0)

\* P149: Diversity waste is non-negative
InvWasteNonneg ==
  diversityWaste >= 0

\* P150: Conservation law holds
InvConservation ==
  conservationSum = TotalRounds + 1

\* P150: Weight is positive (the sliver)
InvWeightPositive ==
  weight >= 1

\* P151: Same boundary → same weight (structural invariant)
InvCoherenceStructure ==
  (boundaryA = boundaryB) =>
    (\A i \in 1..NumHypotheses :
      TotalRounds - Min(boundaryA[i], TotalRounds) + 1 =
      TotalRounds - Min(boundaryB[i], TotalRounds) + 1)

=============================================================================
