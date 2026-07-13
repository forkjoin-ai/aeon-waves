------------------------------ MODULE FailureUniversality ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANT BranchCount, Depth

VARIABLES vented, corrupted

vars == <<vented, corrupted>>

Stages == 1..Depth
Branches == 1..BranchCount

RECURSIVE UnionVentedUpTo(_, _)
UnionVentedUpTo(i, stageVented) ==
  IF i = 0 THEN {}
  ELSE UnionVentedUpTo(i - 1, stageVented) \cup stageVented[i]

RECURSIVE SumCardinalityUpTo(_, _)
SumCardinalityUpTo(i, stageSets) ==
  IF i = 0 THEN 0
  ELSE SumCardinalityUpTo(i - 1, stageSets) + Cardinality(stageSets[i])

RemainingBefore(i, stageVented) == Branches \ UnionVentedUpTo(i - 1, stageVented)
RemainingAfter(i, stageVented) == Branches \ UnionVentedUpTo(i, stageVented)

TerminalSurvivors(stageVented) == Branches \ UnionVentedUpTo(Depth, stageVented)
EverCorrupted(stageCorrupted) == UNION { stageCorrupted[i] : i \in Stages }

TotalVented(stageVented) == SumCardinalityUpTo(Depth, stageVented)
TotalRepairDebt(stageCorrupted) == SumCardinalityUpTo(Depth, stageCorrupted)
TotalCost(stageVented, stageCorrupted) == TotalVented(stageVented) + TotalRepairDebt(stageCorrupted)

BeforeOutput == [b \in Branches |-> b]
AfterOutput(stageCorrupted) ==
  [b \in Branches |->
    IF b \in EverCorrupted(stageCorrupted) THEN b + (BranchCount * (Depth + 1)) ELSE b]

RECURSIVE MergeUpTo(_, _, _)
MergeUpTo(i, surviveSet, outputs) ==
  IF i = 0 THEN <<>>
  ELSE MergeUpTo(i - 1, surviveSet, outputs)
       \o IF i \in surviveSet THEN <<outputs[i]>> ELSE <<>>

ProjectedFold(stageVented) ==
  MergeUpTo(BranchCount, TerminalSurvivors(stageVented), BeforeOutput)

ObservedFold(stageVented, stageCorrupted) ==
  MergeUpTo(BranchCount, TerminalSurvivors(stageVented), AfterOutput(stageCorrupted))

WellFormed(stageVented, stageCorrupted) ==
  /\ stageVented \in [Stages -> SUBSET Branches]
  /\ stageCorrupted \in [Stages -> SUBSET Branches]
  /\ \A i \in Stages:
      /\ stageVented[i] \subseteq RemainingBefore(i, stageVented)
      /\ stageCorrupted[i] \subseteq RemainingAfter(i, stageVented)

GlobalZeroWaste ==
  /\ TotalVented(vented) = 0
  /\ TotalRepairDebt(corrupted) = 0

DeterministicCollapse ==
  /\ Cardinality(TerminalSurvivors(vented)) = 1
  /\ ObservedFold(vented, corrupted) = ProjectedFold(vented)

StagePaysWaste(i) ==
  Cardinality(vented[i]) > 0 \/ Cardinality(corrupted[i]) > 0

CanonicalVented ==
  [i \in Stages |-> IF i = 1 THEN Branches \ {1} ELSE {}]

CanonicalCorrupted ==
  [i \in Stages |-> {}]

CanonicalDeterministicCollapse ==
  /\ Cardinality(TerminalSurvivors(CanonicalVented)) = 1
  /\ ObservedFold(CanonicalVented, CanonicalCorrupted) = ProjectedFold(CanonicalVented)

Init ==
  /\ BranchCount > 1
  /\ Depth > 0
  /\ WellFormed(vented, corrupted)

Change ==
  /\ WellFormed(vented', corrupted')

Stutter == UNCHANGED vars

Next == Stutter
Spec == Init /\ [][Next]_vars

InvZeroVentPreservesBranchMassAtAnyDepth ==
  TotalVented(vented) = 0 => Cardinality(TerminalSurvivors(vented)) = BranchCount

InvNoFreeDeterministicCollapseAtAnyDepth ==
  ~ (GlobalZeroWaste /\ DeterministicCollapse)

InvDeterministicCollapseRequiresGlobalWaste ==
  DeterministicCollapse =>
    (TotalVented(vented) > 0 \/ TotalRepairDebt(corrupted) > 0)

InvDeterministicCollapseRequiresPaidStage ==
  DeterministicCollapse => \E i \in Stages: StagePaysWaste(i)

InvDistributedRepairDebtCannotStayFree ==
  TotalRepairDebt(corrupted) > 0 => ~ GlobalZeroWaste

InvVentedEqualsForkWidthGap ==
  TotalVented(vented) = BranchCount - Cardinality(TerminalSurvivors(vented))

InvDeterministicCollapseRequiresVentFloor ==
  DeterministicCollapse => TotalVented(vented) >= BranchCount - 1

InvDeterministicCollapseRequiresCostFloor ==
  DeterministicCollapse => TotalCost(vented, corrupted) >= BranchCount - 1

InvCanonicalWitnessWellFormed ==
  WellFormed(vented, corrupted) => WellFormed(CanonicalVented, CanonicalCorrupted)

InvCanonicalWitnessDeterministicCollapse ==
  WellFormed(vented, corrupted) => CanonicalDeterministicCollapse

InvCanonicalWitnessZeroRepairDebt ==
  WellFormed(vented, corrupted) => TotalRepairDebt(CanonicalCorrupted) = 0

InvCanonicalWitnessAttainsVentFloor ==
  WellFormed(vented, corrupted) =>
    TotalVented(CanonicalVented) = BranchCount - 1

InvCanonicalWitnessAttainsCostFloor ==
  WellFormed(vented, corrupted) =>
    TotalCost(CanonicalVented, CanonicalCorrupted) = BranchCount - 1

=============================================================================
