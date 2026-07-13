------------------------------ MODULE FailureFamilies ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANT BranchCount

VARIABLES vented, corrupted

vars == <<vented, corrupted>>

Branches == 1..BranchCount
Survivors == Branches \ vented
RepairDebt == Cardinality(corrupted)

BeforeOutput == [b \in Branches |-> b]
AfterOutput == [b \in Branches |-> IF b \in corrupted THEN b + BranchCount ELSE b]

RECURSIVE MergeUpTo(_, _, _)
MergeUpTo(i, surviveSet, outputs) ==
  IF i = 0 THEN <<>>
  ELSE MergeUpTo(i - 1, surviveSet, outputs)
       \o IF i \in surviveSet THEN <<outputs[i]>> ELSE <<>>

ProjectedFold == MergeUpTo(BranchCount, Survivors, BeforeOutput)
ObservedFold == MergeUpTo(BranchCount, Survivors, AfterOutput)

Init ==
  /\ BranchCount > 0
  /\ vented \subseteq Branches
  /\ corrupted \subseteq Survivors

Change ==
  /\ vented' \subseteq Branches
  /\ corrupted' \subseteq (Branches \ vented')

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ vented \subseteq Branches
  /\ corrupted \subseteq Survivors

InvBranchIsolatingPreservesDeterministicFold ==
  corrupted = {} => ObservedFold = ProjectedFold

InvBranchIsolatingRepairDebtZero ==
  corrupted = {} => RepairDebt = 0

InvContagiousFailureForcesRepairDebt ==
  corrupted # {} => RepairDebt > 0

InvContagiousFailureBreaksDeterministicFold ==
  corrupted # {} => ObservedFold # ProjectedFold

=============================================================================
