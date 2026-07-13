------------------------------ MODULE FailureComposition ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANT BranchCount

VARIABLES vented01, vented12, corrupted01, corrupted12

vars == <<vented01, vented12, corrupted01, corrupted12>>

Branches == 1..BranchCount
Survivors0 == Branches
Survivors1 == Branches \ vented01
Survivors2 == Survivors1 \ vented12

VentedCount01 == Cardinality(vented01)
VentedCount12 == Cardinality(vented12)
RepairDebt01 == Cardinality(corrupted01)
RepairDebt12 == Cardinality(corrupted12)
TotalVented == VentedCount01 + VentedCount12
TotalRepairDebt == RepairDebt01 + RepairDebt12

BeforeOutput == [b \in Branches |-> b]
MidOutput == [b \in Branches |-> IF b \in corrupted01 THEN b + BranchCount ELSE b]
AfterOutput ==
  [b \in Branches |->
    IF b \in corrupted12 THEN MidOutput[b] + BranchCount ELSE MidOutput[b]]

RECURSIVE MergeUpTo(_, _, _)
MergeUpTo(i, surviveSet, outputs) ==
  IF i = 0 THEN <<>>
  ELSE MergeUpTo(i - 1, surviveSet, outputs)
       \o IF i \in surviveSet THEN <<outputs[i]>> ELSE <<>>

ProjectedFold == MergeUpTo(BranchCount, Survivors2, BeforeOutput)
ObservedFold == MergeUpTo(BranchCount, Survivors2, AfterOutput)

StageZeroWaste01 ==
  /\ VentedCount01 = 0
  /\ RepairDebt01 = 0

StageZeroWaste12 ==
  /\ VentedCount12 = 0
  /\ RepairDebt12 = 0

GlobalZeroWaste ==
  /\ StageZeroWaste01
  /\ StageZeroWaste12

StagePaysWaste01 == VentedCount01 > 0 \/ RepairDebt01 > 0
StagePaysWaste12 == VentedCount12 > 0 \/ RepairDebt12 > 0

DeterministicCollapse ==
  /\ Cardinality(Survivors2) = 1
  /\ ObservedFold = ProjectedFold

Init ==
  /\ BranchCount > 1
  /\ vented01 \subseteq Branches
  /\ vented12 \subseteq Survivors1
  /\ corrupted01 \subseteq Survivors1
  /\ corrupted12 \subseteq Survivors2

Change ==
  /\ vented01' \subseteq Branches
  /\ vented12' \subseteq (Branches \ vented01')
  /\ corrupted01' \subseteq (Branches \ vented01')
  /\ corrupted12' \subseteq ((Branches \ vented01') \ vented12')

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

InvStagewiseZeroVentPreservesBranchMass ==
  (VentedCount01 = 0 /\ VentedCount12 = 0) => Cardinality(Survivors2) = BranchCount

InvNoFreePipelineCollapse ==
  ~ (GlobalZeroWaste /\ DeterministicCollapse)

InvPipelineCollapseRequiresGlobalWaste ==
  DeterministicCollapse => (TotalVented > 0 \/ TotalRepairDebt > 0)

InvPipelineCollapseRequiresPaidStage ==
  DeterministicCollapse => (StagePaysWaste01 \/ StagePaysWaste12)

InvContagionCannotStayFreeAcrossPipeline ==
  (RepairDebt01 > 0 \/ RepairDebt12 > 0) => ~ GlobalZeroWaste

=============================================================================
