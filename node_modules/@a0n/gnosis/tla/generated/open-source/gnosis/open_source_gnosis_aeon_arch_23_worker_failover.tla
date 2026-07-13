------------------------------ MODULE open_source_gnosis_aeon_arch_23_worker_failover ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"task", "result", "task: Job", "primary: Worker", "secondary: Worker", "primary", "secondary", "result: Output"}
ROOTS == {"task: Job", "primary", "secondary"}
TERMINALS == {"primary: Worker", "secondary: Worker", "result: Output"}
FOLD_TARGETS == {}
EFFECTS == {}
DECLARED_EFFECTS == {}
INFERRED_EFFECTS == {}

VARIABLES active, beta1, payloadPresent, consensusReached
vars == <<active, beta1, payloadPresent, consensusReached>>

Max2(a, b) == IF a > b THEN a ELSE b
CanFire(sourceSet) == sourceSet \subseteq active
UpdateActive(sourceSet, targetSet) == (active \ sourceSet) \cup targetSet

Init ==
  /\ active = ROOTS
  /\ beta1 = 0
  /\ payloadPresent = TRUE
  /\ consensusReached = FALSE

Edge_01_FORK ==
  /\ CanFire({"task: Job"})
  /\ active' = UpdateActive({"task: Job"}, {"primary: Worker", "secondary: Worker"})
  /\ beta1' = beta1 + (Cardinality({"primary: Worker", "secondary: Worker"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"primary: Worker", "secondary: Worker"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"primary", "secondary"})
  /\ \E winner \in {"result: Output"}:
      /\ active' = UpdateActive({"primary", "secondary"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"primary", "secondary"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE

TypeInvariant ==
  /\ active \subseteq NODES
  /\ beta1 \in Nat
  /\ payloadPresent \in BOOLEAN
  /\ consensusReached \in BOOLEAN

NoLostPayloadInvariant == payloadPresent = TRUE
HasFoldTargets == FOLD_TARGETS # {}
EventuallyTerminal == <> (active \cap TERMINALS # {})
EventuallyConsensus == IF HasFoldTargets THEN <> consensusReached ELSE TRUE
DeadlockFree == []<>(ENABLED Next)

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Next)

THEOREM Spec => []NoLostPayloadInvariant

=============================================================================
