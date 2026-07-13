--------------------- MODULE SleepDebtScheduleThreshold ---------------------
EXTENDS Naturals

CONSTANTS ScheduledWakeDomain, RecoveryQuotaDomain, CycleDomain, DebtDomain

VARIABLES scheduledWake, recoveryQuota, cycle, debt, lastAction

vars == <<scheduledWake, recoveryQuota, cycle, debt, lastAction>>

ScheduleSurplus ==
  IF recoveryQuota < scheduledWake THEN scheduledWake - recoveryQuota ELSE 0

Init ==
  /\ scheduledWake \in ScheduledWakeDomain
  /\ recoveryQuota \in RecoveryQuotaDomain
  /\ cycle = 0
  /\ debt = 0
  /\ cycle \in CycleDomain
  /\ debt \in DebtDomain
  /\ lastAction = "init"

AdvanceCycle ==
  /\ cycle + 1 \in CycleDomain
  /\ debt + ScheduleSurplus \in DebtDomain
  /\ scheduledWake' = scheduledWake
  /\ recoveryQuota' = recoveryQuota
  /\ cycle' = cycle + 1
  /\ debt' = debt + ScheduleSurplus
  /\ lastAction' = "advance"

Stutter == UNCHANGED vars

Next == AdvanceCycle \/ Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ scheduledWake \in ScheduledWakeDomain
  /\ recoveryQuota \in RecoveryQuotaDomain
  /\ cycle \in CycleDomain
  /\ debt \in DebtDomain

InvBelowOrAtThresholdKeepsZero ==
  scheduledWake <= recoveryQuota => debt = 0

InvAboveThresholdMatchesCycleSurplus ==
  recoveryQuota < scheduledWake => debt = cycle * ScheduleSurplus

InvAboveThresholdPositivePastFirstCycle ==
  /\ recoveryQuota < scheduledWake
  /\ 0 < cycle
  => 0 < debt

PropAdvanceEnabledWithinBounds ==
  []((cycle + 1 \in CycleDomain /\ debt + ScheduleSurplus \in DebtDomain) =>
      ENABLED AdvanceCycle)

=============================================================================
