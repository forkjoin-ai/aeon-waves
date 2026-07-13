------------------------------ MODULE PredictionsRound9 ------------------------------
(*
  Predictions Round 9: Democratic Representation, Urban Traffic,
  Software Bug Density, Trust Erosion, Information Cascade Fragility.
*)
EXTENDS Naturals

CONSTANTS Constituencies, Representatives,
          RouteCapacity, RouteDemand,
          TotalRuns, FailedRuns,
          InitialTrust, Betrayals,
          Participants, IndependentObs

VARIABLES phase, currentBetrayals, currentTrust,
          representationDeficit, congestionDeficit,
          bugConfidence, cascadeDeficit, cascadeFragility

vars == <<phase, currentBetrayals, currentTrust,
          representationDeficit, congestionDeficit,
          bugConfidence, cascadeDeficit, cascadeFragility>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "legislature"
  /\ currentBetrayals = 0
  /\ currentTrust = InitialTrust - Min(0, InitialTrust) + 1
  /\ representationDeficit = Constituencies - Representatives
  /\ congestionDeficit = RouteDemand - RouteCapacity
  /\ bugConfidence = TotalRuns - Min(FailedRuns, TotalRuns) + 1
  /\ cascadeDeficit = Participants - IndependentObs
  /\ cascadeFragility = Participants - 1

\* P104: Trust betrayal step (append-only void boundary)
BetrayStep ==
  /\ phase = "legislature"
  /\ currentBetrayals < InitialTrust
  /\ currentBetrayals' = currentBetrayals + 1
  /\ currentTrust' = InitialTrust - Min(currentBetrayals + 1, InitialTrust) + 1
  /\ phase' = "traffic"
  /\ UNCHANGED <<representationDeficit, congestionDeficit,
                  bugConfidence, cascadeDeficit, cascadeFragility>>

\* P101-P105: Cycle through remaining phases
TrafficStep ==
  /\ phase = "traffic"
  /\ phase' = "testing"
  /\ UNCHANGED <<currentBetrayals, currentTrust, representationDeficit,
                  congestionDeficit, bugConfidence, cascadeDeficit,
                  cascadeFragility>>

TestingStep ==
  /\ phase = "testing"
  /\ phase' = "trust"
  /\ UNCHANGED <<currentBetrayals, currentTrust, representationDeficit,
                  congestionDeficit, bugConfidence, cascadeDeficit,
                  cascadeFragility>>

TrustStep ==
  /\ phase = "trust"
  /\ phase' = "cascade"
  /\ UNCHANGED <<currentBetrayals, currentTrust, representationDeficit,
                  congestionDeficit, bugConfidence, cascadeDeficit,
                  cascadeFragility>>

CascadeStep ==
  /\ phase = "cascade"
  /\ phase' = "legislature"
  /\ UNCHANGED <<currentBetrayals, currentTrust, representationDeficit,
                  congestionDeficit, bugConfidence, cascadeDeficit,
                  cascadeFragility>>

Stutter == UNCHANGED vars

Next == BetrayStep \/ TrafficStep \/ TestingStep
     \/ TrustStep \/ CascadeStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P101: Representation deficit non-negative
InvRepDeficitNonneg ==
  representationDeficit >= 0

\* P102: Congestion deficit non-negative
InvCongestionNonneg ==
  congestionDeficit >= 0

\* P103: Bug confidence always positive (the sliver)
InvBugConfidencePositive ==
  bugConfidence >= 1

\* P104: Trust always positive (the sliver)
InvTrustPositive ==
  currentTrust >= 1

\* P104: Betrayals bounded
InvBetrayalsBounded ==
  currentBetrayals <= InitialTrust

\* P105: Cascade fragility positive for nontrivial cascade
InvCascadeFragilityPositive ==
  (Participants >= 2) => (cascadeFragility >= 1)

\* P105: Cascade deficit non-negative
InvCascadeDeficitNonneg ==
  cascadeDeficit >= 0

=============================================================================
