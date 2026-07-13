--------------------- MODULE SleepDebtWeightedThreshold ---------------------
EXTENDS Naturals

CONSTANTS
  ScheduledWakeDomain,
  CycleLengthDomain,
  WakeRateDomain,
  RecoveryRateDomain,
  CycleDomain,
  DebtDomain

VARIABLES
  scheduledWake,
  cycleLength,
  wakeBurdenRate,
  recoveryRate,
  cycle,
  debt,
  lastAction

vars ==
  <<scheduledWake, cycleLength, wakeBurdenRate, recoveryRate, cycle, debt, lastAction>>

ThresholdLhs ==
  scheduledWake * (wakeBurdenRate + recoveryRate)

ThresholdRhs ==
  cycleLength * recoveryRate

WeightedSurplus ==
  IF ThresholdRhs < ThresholdLhs THEN ThresholdLhs - ThresholdRhs ELSE 0

Init ==
  /\ scheduledWake \in ScheduledWakeDomain
  /\ cycleLength \in CycleLengthDomain
  /\ wakeBurdenRate \in WakeRateDomain
  /\ recoveryRate \in RecoveryRateDomain
  /\ cycle = 0
  /\ debt = 0
  /\ cycle \in CycleDomain
  /\ debt \in DebtDomain
  /\ lastAction = "init"

AdvanceCycle ==
  /\ cycle + 1 \in CycleDomain
  /\ debt + WeightedSurplus \in DebtDomain
  /\ scheduledWake' = scheduledWake
  /\ cycleLength' = cycleLength
  /\ wakeBurdenRate' = wakeBurdenRate
  /\ recoveryRate' = recoveryRate
  /\ cycle' = cycle + 1
  /\ debt' = debt + WeightedSurplus
  /\ lastAction' = "advance"

Stutter == UNCHANGED vars

Next == AdvanceCycle \/ Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ scheduledWake \in ScheduledWakeDomain
  /\ cycleLength \in CycleLengthDomain
  /\ wakeBurdenRate \in WakeRateDomain
  /\ recoveryRate \in RecoveryRateDomain
  /\ cycle \in CycleDomain
  /\ debt \in DebtDomain

InvNotCrossedKeepsZero ==
  ThresholdLhs <= ThresholdRhs => debt = 0

InvCrossedMatchesCycleSurplus ==
  ThresholdRhs < ThresholdLhs => debt = cycle * WeightedSurplus

InvCrossedPositivePastFirstCycle ==
  /\ ThresholdRhs < ThresholdLhs
  /\ 0 < cycle
  => 0 < debt

PropAdvanceEnabledWithinBounds ==
  []((cycle + 1 \in CycleDomain /\ debt + WeightedSurplus \in DebtDomain) =>
      ENABLED AdvanceCycle)

=============================================================================
