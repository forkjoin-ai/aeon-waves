------------------------------ MODULE open_source_gnosis_impossible_edge_pipeline_parallelism ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request", "worker_node_1", "worker_node_2", "worker_node_3", "worker_node_4", "activation_1", "activation_2", "activation_3", "response"}
ROOTS == {"request"}
TERMINALS == {"response"}
FOLD_TARGETS == {"activation_1", "activation_2", "activation_3"}
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
  /\ CanFire({"request"})
  /\ active' = UpdateActive({"request"}, {"worker_node_1"})
  /\ beta1' = beta1 + (Cardinality({"worker_node_1"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"worker_node_1"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"worker_node_1"})
  /\ active' = UpdateActive({"worker_node_1"}, {"activation_1"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"activation_1"} \cap FOLD_TARGETS # {})
Edge_03_RACE ==
  /\ CanFire({"activation_1"})
  /\ \E winner \in {"worker_node_2"}:
      /\ active' = UpdateActive({"activation_1"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"activation_1"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_FOLD ==
  /\ CanFire({"worker_node_2"})
  /\ active' = UpdateActive({"worker_node_2"}, {"activation_2"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"activation_2"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"activation_2"})
  /\ \E winner \in {"worker_node_3"}:
      /\ active' = UpdateActive({"activation_2"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"activation_2"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_FOLD ==
  /\ CanFire({"worker_node_3"})
  /\ active' = UpdateActive({"worker_node_3"}, {"activation_3"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"activation_3"} \cap FOLD_TARGETS # {})
Edge_07_RACE ==
  /\ CanFire({"activation_3"})
  /\ \E winner \in {"worker_node_4"}:
      /\ active' = UpdateActive({"activation_3"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"activation_3"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_08_PROCESS ==
  /\ CanFire({"worker_node_4"})
  /\ active' = UpdateActive({"worker_node_4"}, {"response"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"response"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_RACE
  \/ Edge_04_FOLD
  \/ Edge_05_RACE
  \/ Edge_06_FOLD
  \/ Edge_07_RACE
  \/ Edge_08_PROCESS

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
