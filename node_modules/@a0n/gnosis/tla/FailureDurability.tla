------------------------------ MODULE FailureDurability ------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS ReplicaCount, FailureBudget

VARIABLES live, repairDebt, failuresRemaining

vars == <<live, repairDebt, failuresRemaining>>

Replicas == 1..ReplicaCount
LiveCount == Cardinality(live)
QuorumSize == ReplicaCount - FailureBudget

Stable ==
  /\ live = Replicas
  /\ repairDebt = 0
  /\ failuresRemaining = 0

FailReplica(r) ==
  /\ r \in live
  /\ failuresRemaining > 0
  /\ live' = live \ {r}
  /\ repairDebt' = repairDebt + 1
  /\ failuresRemaining' = failuresRemaining - 1

RepairReplica(r) ==
  /\ r \in (Replicas \ live)
  /\ repairDebt > 0
  /\ live' = live \cup {r}
  /\ repairDebt' = repairDebt - 1
  /\ UNCHANGED failuresRemaining

RepairAny == \E r \in (Replicas \ live): RepairReplica(r)

Stutter == UNCHANGED vars

Init ==
  /\ ReplicaCount > 0
  /\ FailureBudget < ReplicaCount
  /\ live = Replicas
  /\ repairDebt = 0
  /\ failuresRemaining = FailureBudget

Next ==
  \/ \E r \in live: FailReplica(r)
  \/ RepairAny
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(RepairAny)

InvWellFormed ==
  /\ live \subseteq Replicas
  /\ repairDebt \in 0..FailureBudget
  /\ failuresRemaining \in 0..FailureBudget

InvReplicaMassConserved ==
  LiveCount + repairDebt = ReplicaCount

InvRepairDebtBounded ==
  repairDebt <= FailureBudget

InvQuorumDurability ==
  LiveCount >= QuorumSize

InvPositiveLive ==
  LiveCount > 0

PropFailureExhaustionLeadsToStable ==
  (failuresRemaining = 0) ~> Stable

=============================================================================
