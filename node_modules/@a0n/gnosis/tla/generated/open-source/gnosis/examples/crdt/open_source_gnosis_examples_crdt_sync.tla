------------------------------ MODULE open_source_gnosis_examples_crdt_sync ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"network", "replica_a", "ra", "replica_b", "rb", "replica_c", "rc", "synced_ab", "synced_all"}
ROOTS == {"network"}
TERMINALS == {"synced_all"}
FOLD_TARGETS == {"synced_ab", "synced_all"}
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
  /\ CanFire({"network"})
  /\ active' = UpdateActive({"network"}, {"replica_a", "replica_b", "replica_c"})
  /\ beta1' = beta1 + (Cardinality({"replica_a", "replica_b", "replica_c"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"replica_a", "replica_b", "replica_c"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"replica_a"})
  /\ active' = UpdateActive({"replica_a"}, {"ra"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ra"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"replica_b"})
  /\ active' = UpdateActive({"replica_b"}, {"rb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"rb"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"replica_c"})
  /\ active' = UpdateActive({"replica_c"}, {"rc"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"rc"} \cap FOLD_TARGETS # {})
Edge_05_OBSERVE ==
  /\ CanFire({"ra", "rb"})
  /\ active' = UpdateActive({"ra", "rb"}, {"synced_ab"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"synced_ab"} \cap FOLD_TARGETS # {})
Edge_06_OBSERVE ==
  /\ CanFire({"synced_ab", "rc"})
  /\ active' = UpdateActive({"synced_ab", "rc"}, {"synced_all"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"synced_all"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_OBSERVE
  \/ Edge_06_OBSERVE

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
