------------------------------ MODULE StagedExpansion ------------------------------
EXTENDS Naturals

CONSTANTS PeakDomain, ShoulderBudgetDomain, DeficitDomain

VARIABLES k, left, right, deficit

vars == <<k, left, right, deficit>>

Budget == left + right

Init ==
  /\ k \in PeakDomain
  /\ left \in ShoulderBudgetDomain
  /\ right \in ShoulderBudgetDomain
  /\ deficit \in DeficitDomain
  /\ k > 0
  /\ left <= k - 1
  /\ right <= k - 1
  /\ Budget > 0
  /\ Budget <= deficit

Change ==
  /\ k' \in PeakDomain
  /\ left' \in ShoulderBudgetDomain
  /\ right' \in ShoulderBudgetDomain
  /\ deficit' \in DeficitDomain
  /\ k' > 0
  /\ left' <= k' - 1
  /\ right' <= k' - 1
  /\ left' + right' > 0
  /\ left' + right' <= deficit'

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

StagedArea == (1 + left) + k + (1 + right)
StagedEnvelope == 3 * k
StagedWallaceNum == StagedEnvelope - StagedArea
StagedWallaceDen == StagedEnvelope

NaiveArea == 1 + (k + Budget) + 1
NaiveEnvelope == 3 * (k + Budget)
NaiveWallaceNum == NaiveEnvelope - NaiveArea
NaiveWallaceDen == NaiveEnvelope

InvPositiveTopologyDeficit ==
  /\ deficit > 0
  /\ Budget <= deficit

InvFeasibleStagedBudget ==
  /\ Budget <= 2 * (k - 1)
  /\ StagedArea > 0
  /\ StagedArea <= StagedEnvelope

InvSameBudgetFrontierArea ==
  /\ StagedArea = NaiveArea
  /\ StagedArea = k + Budget + 2

InvEnvelopeComparison ==
  /\ StagedEnvelope = 3 * k
  /\ NaiveEnvelope = 3 * (k + Budget)
  /\ StagedEnvelope < NaiveEnvelope

InvStagedWallaceClosedForm ==
  /\ StagedWallaceNum = 2 * (k - 1) - Budget
  /\ StagedWallaceDen = 3 * k

InvNaiveWallaceClosedForm ==
  /\ NaiveWallaceNum = 2 * (k + Budget - 1)
  /\ NaiveWallaceDen = 3 * (k + Budget)

InvStagedFillDominatesNaive ==
  StagedArea * NaiveEnvelope > NaiveArea * StagedEnvelope

InvStagedWallaceBeatsNaive ==
  StagedWallaceNum * NaiveWallaceDen < NaiveWallaceNum * StagedWallaceDen

=============================================================================
