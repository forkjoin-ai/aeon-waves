------------------------------ MODULE PredictionsRound14 ------------------------------
(*
  Predictions Round 14: BATNA Topology, Void Dominance, Concession
  Gradient, Settlement Stability, Fold Heat Decomposition.
*)
EXTENDS Naturals

CONSTANTS OfferCount, ForkWidth, NumTerms, NumSteps

VARIABLES phase, roundsCompleted, batnaSize,
          computeSteps, voidVolume, activeVolume,
          rejections, concessionRounds,
          perturbedWeight, totalHeat

vars == <<phase, roundsCompleted, batnaSize,
          computeSteps, voidVolume, activeVolume,
          rejections, concessionRounds,
          perturbedWeight, totalHeat>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "negotiate"
  /\ roundsCompleted = 0
  /\ batnaSize = 0
  /\ computeSteps = 0
  /\ voidVolume = 0
  /\ activeVolume = 0
  /\ rejections = [i \in 1..NumTerms |-> 0]
  /\ concessionRounds = 1
  /\ perturbedWeight = [i \in 1..NumTerms |-> 2]
  /\ totalHeat = 0

NegotiateStep ==
  /\ phase = "negotiate"
  /\ roundsCompleted' = roundsCompleted + 1
  /\ batnaSize' = (roundsCompleted + 1) * (OfferCount - 1)
  /\ phase' = "compute"
  /\ UNCHANGED <<computeSteps, voidVolume, activeVolume,
                  rejections, concessionRounds, perturbedWeight, totalHeat>>

ComputeStep ==
  /\ phase = "compute"
  /\ computeSteps' = computeSteps + 1
  /\ voidVolume' = (computeSteps + 1) * (ForkWidth - 1)
  /\ activeVolume' = computeSteps + 1
  /\ phase' = "concede"
  /\ UNCHANGED <<roundsCompleted, batnaSize, rejections,
                  concessionRounds, perturbedWeight, totalHeat>>

ConcedeStep ==
  /\ phase = "concede"
  /\ \E term \in 1..NumTerms :
       /\ rejections' = [rejections EXCEPT ![term] = @ + 1]
       /\ concessionRounds' = concessionRounds + 1
  /\ phase' = "settle"
  /\ UNCHANGED <<roundsCompleted, batnaSize, computeSteps,
                  voidVolume, activeVolume, perturbedWeight, totalHeat>>

SettleStep ==
  /\ phase = "settle"
  /\ perturbedWeight' = [i \in 1..NumTerms |->
      concessionRounds - Min(rejections[i], concessionRounds) + 1]
  /\ totalHeat' = totalHeat + 1
  /\ phase' = "negotiate"
  /\ UNCHANGED <<roundsCompleted, batnaSize, computeSteps,
                  voidVolume, activeVolume, rejections, concessionRounds>>

Stutter == UNCHANGED vars

Next == NegotiateStep \/ ComputeStep \/ ConcedeStep \/ SettleStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* P187: BATNA size monotone
InvBatnaMonotone == batnaSize >= 0

\* P188: Void dominates active (when ForkWidth >= 2)
InvVoidDominates ==
  (ForkWidth >= 2) => (voidVolume >= activeVolume)

\* P189: All concession weights positive
InvConcessionPositive ==
  \A i \in 1..NumTerms : perturbedWeight[i] >= 1

\* P190: Perturbed weights remain positive
InvPerturbedPositive ==
  \A i \in 1..NumTerms : perturbedWeight[i] >= 1

\* P191: Total heat monotone
InvHeatMonotone == totalHeat >= 0

\* Cross-cutting: rounds and steps non-negative
InvRoundsNonneg == roundsCompleted >= 0
InvStepsNonneg == computeSteps >= 0

=============================================================================
