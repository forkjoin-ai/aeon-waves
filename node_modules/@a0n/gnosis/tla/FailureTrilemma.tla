------------------------------ MODULE FailureTrilemma ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANT BranchCount

VARIABLES vented, corrupted

vars == <<vented, corrupted>>

Branches == 1..BranchCount
Survivors == Branches \ vented
VentedCount == Cardinality(vented)
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

ZeroWaste ==
  /\ VentedCount = 0
  /\ RepairDebt = 0

DeterministicCollapse ==
  /\ Cardinality(Survivors) = 1
  /\ ObservedFold = ProjectedFold

Init ==
  /\ BranchCount > 1
  /\ vented \subseteq Branches
  /\ corrupted \subseteq Survivors

Change ==
  /\ vented' \subseteq Branches
  /\ corrupted' \subseteq (Branches \ vented')

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

InvZeroVentPreservesBranchMass ==
  VentedCount = 0 => Cardinality(Survivors) = BranchCount

InvNoFreeDeterministicCollapse ==
  ~ (ZeroWaste /\ DeterministicCollapse)

InvDeterministicSingleSurvivorRequiresWaste ==
  DeterministicCollapse => (VentedCount > 0 \/ RepairDebt > 0)

InvContagiousFailureNotEntropyFree ==
  corrupted # {} => ~ ZeroWaste

InvGlobalContagionPreservesBranchMassAndForcesDebt ==
  (corrupted # {} /\ VentedCount = 0) =>
    /\ Cardinality(Survivors) = BranchCount
    /\ RepairDebt > 0

=============================================================================
