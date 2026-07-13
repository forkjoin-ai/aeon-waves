------------------------------ MODULE FailureEntropy ------------------------------
EXTENDS Naturals

CONSTANTS FrontierDomain, VentedDomain, RepairDomain

VARIABLES frontier, vented, repaired

vars == <<frontier, vented, repaired>>

Init ==
  /\ frontier \in FrontierDomain
  /\ vented \in VentedDomain
  /\ repaired \in RepairDomain
  /\ frontier > 0
  /\ vented <= frontier

Change ==
  /\ frontier' \in FrontierDomain
  /\ vented' \in VentedDomain
  /\ repaired' \in RepairDomain
  /\ frontier' > 0
  /\ vented' <= frontier'

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

StructuredFrontier == frontier - vented
DebtFrontier == StructuredFrontier + repaired

EntropyProxy(width) == IF width = 0 THEN 0 ELSE width - 1

InvWellFormed ==
  /\ frontier > 0
  /\ vented <= frontier

InvStructuredFailureConservesMass ==
  frontier = StructuredFrontier + vented

InvStructuredFailureReducesWidth ==
  vented > 0 => StructuredFrontier < frontier

InvStructuredFailureReducesEntropy ==
  /\ vented > 0
  /\ StructuredFrontier > 0
  => EntropyProxy(StructuredFrontier) < EntropyProxy(frontier)

InvSingleSurvivorNeedsFailure ==
  /\ frontier > 1
  /\ StructuredFrontier = 1
  => vented > 0

InvCoupledFailurePreservesWidth ==
  repaired >= vented => frontier <= DebtFrontier

InvCoupledFailurePreservesEntropy ==
  repaired >= vented => EntropyProxy(frontier) <= EntropyProxy(DebtFrontier)

InvCoupledFailureStrictWhenRepairExceedsVented ==
  repaired > vented => EntropyProxy(frontier) < EntropyProxy(DebtFrontier)

=============================================================================
