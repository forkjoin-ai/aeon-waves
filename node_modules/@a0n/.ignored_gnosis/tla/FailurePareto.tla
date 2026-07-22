---------------------------- MODULE FailurePareto ----------------------------
EXTENDS Naturals

CONSTANTS LiveBranchDomain

VARIABLE liveBranches

paretoVars == <<liveBranches>>

InitFailurePareto ==
  /\ liveBranches \in LiveBranchDomain
  /\ liveBranches > 1

StutterFailurePareto == UNCHANGED paretoVars

SpecFailurePareto == InitFailurePareto /\ [][StutterFailurePareto]_paretoVars

CollapseGap == liveBranches - 1

KeepPoint ==
  [wallace |-> CollapseGap, buley |-> CollapseGap, vent |-> 0, repair |-> 0]

VentPoint ==
  [wallace |-> 0, buley |-> 0, vent |-> CollapseGap, repair |-> 0]

RepairPoint ==
  [wallace |-> 0, buley |-> CollapseGap, vent |-> 0, repair |-> CollapseGap]

WeaklyDominates(a, b) ==
  /\ a.wallace <= b.wallace
  /\ a.buley <= b.buley
  /\ a.vent <= b.vent
  /\ a.repair <= b.repair

Dominates(a, b) ==
  /\ WeaklyDominates(a, b)
  /\ a # b

InvFailureParetoWellFormed ==
  /\ liveBranches > 1
  /\ CollapseGap = liveBranches - 1
  /\ CollapseGap > 0

InvKeepNondominated ==
  /\ ~Dominates(VentPoint, KeepPoint)
  /\ ~Dominates(RepairPoint, KeepPoint)

InvVentNondominated ==
  /\ ~Dominates(KeepPoint, VentPoint)
  /\ ~Dominates(RepairPoint, VentPoint)

InvRepairNondominated ==
  /\ ~Dominates(KeepPoint, RepairPoint)
  /\ ~Dominates(VentPoint, RepairPoint)

=============================================================================
