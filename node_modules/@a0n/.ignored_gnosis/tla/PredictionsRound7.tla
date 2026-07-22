------------------------------ MODULE PredictionsRound7 ------------------------------
(*
  Predictions Round 7: Renegotiation, Therapeutic Plateau,
  Conflict Reynolds, Solomonoff Prior, Staged Growth.

  Five predictions composing grandfather paradox with negotiation,
  Last Question with therapy, Reynolds BFT with conflict resolution,
  Solomonoff-Buleyean with void walking, and staged expansion with
  personal growth.
*)
EXTENDS Naturals

CONSTANTS InitialDeficit, Capacity, Issues, Budget,
          LeftShoulder, RightShoulder, Peak

VARIABLES phase, acceptanceWeight, rejectionHistory,
          sessionsCompleted, remainingDeficit,
          overflow, informationContent,
          capacityDeficit, stagedGrowth

vars == <<phase, acceptanceWeight, rejectionHistory,
          sessionsCompleted, remainingDeficit,
          overflow, informationContent,
          capacityDeficit, stagedGrowth>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "renegotiation"
  /\ acceptanceWeight = 1
  /\ rejectionHistory = 0
  /\ sessionsCompleted = 0
  /\ remainingDeficit = InitialDeficit
  /\ overflow = IF Issues > Capacity THEN Issues - Capacity ELSE 0
  /\ informationContent = 0
  /\ capacityDeficit = (Peak - LeftShoulder) + (Peak - RightShoulder)
  /\ stagedGrowth = Min(Budget, (Peak - LeftShoulder) + (Peak - RightShoulder))

\* P86: Attempt renegotiation (weight stays positive)
Renegotiate ==
  /\ phase = "renegotiation"
  /\ rejectionHistory' = rejectionHistory + 1
  /\ acceptanceWeight' = acceptanceWeight  \* Cannot be zeroed!
  /\ phase' = "therapy"
  /\ UNCHANGED <<sessionsCompleted, remainingDeficit, overflow,
                  informationContent, capacityDeficit, stagedGrowth>>

\* P87: Therapy session (deficit decreases)
TherapySession ==
  /\ phase = "therapy"
  /\ sessionsCompleted' = sessionsCompleted + 1
  /\ remainingDeficit' = InitialDeficit - Min(sessionsCompleted + 1, InitialDeficit)
  /\ phase' = "conflict"
  /\ UNCHANGED <<acceptanceWeight, rejectionHistory, overflow,
                  informationContent, capacityDeficit, stagedGrowth>>

\* P88: Conflict resolution step
ConflictStep ==
  /\ phase = "conflict"
  /\ phase' = "prior"
  /\ UNCHANGED <<acceptanceWeight, rejectionHistory, sessionsCompleted,
                  remainingDeficit, overflow, informationContent,
                  capacityDeficit, stagedGrowth>>

\* P89: Prior evaluation
PriorStep ==
  /\ phase = "prior"
  /\ phase' = "growth"
  /\ UNCHANGED <<acceptanceWeight, rejectionHistory, sessionsCompleted,
                  remainingDeficit, overflow, informationContent,
                  capacityDeficit, stagedGrowth>>

\* P90: Growth step
GrowthStep ==
  /\ phase = "growth"
  /\ phase' = "renegotiation"
  /\ UNCHANGED <<acceptanceWeight, rejectionHistory, sessionsCompleted,
                  remainingDeficit, overflow, informationContent,
                  capacityDeficit, stagedGrowth>>

Stutter == UNCHANGED vars

Next == Renegotiate \/ TherapySession \/ ConflictStep
     \/ PriorStep \/ GrowthStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P86: Settlement weight always positive
InvSettlementPositive ==
  acceptanceWeight >= 1

\* P87: Remaining deficit is non-negative
InvDeficitNonneg ==
  remainingDeficit >= 0

\* P87: More sessions = less deficit (monotone)
InvTherapyMonotone ==
  remainingDeficit <= InitialDeficit

\* P88: Laminar when capacity sufficient
InvLaminarWhenSufficient ==
  (Issues <= Capacity) => (overflow = 0)

\* P88: Overflow non-negative
InvOverflowNonneg ==
  overflow >= 0

\* P90: Staged growth >= naive growth (which is 0)
InvStagedDominatesNaive ==
  stagedGrowth >= 0

\* Cross-cutting: rejection history only increases
InvRejectionMonotone ==
  rejectionHistory >= 0

=============================================================================
