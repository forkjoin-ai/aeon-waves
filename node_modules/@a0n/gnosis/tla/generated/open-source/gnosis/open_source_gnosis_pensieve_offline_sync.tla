------------------------------ MODULE open_source_gnosis_pensieve_offline_sync ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"local_mutation", "remote_queue", "d1_database", "local_mutation: Event", "indexeddb: Storage", "remote_queue: Queue", "d1_database: DB"}
ROOTS == {"local_mutation: Event", "remote_queue"}
TERMINALS == {"indexeddb: Storage", "remote_queue: Queue", "d1_database: DB"}
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
  /\ CanFire({"local_mutation: Event"})
  /\ active' = UpdateActive({"local_mutation: Event"}, {"indexeddb: Storage", "remote_queue: Queue"})
  /\ beta1' = beta1 + (Cardinality({"indexeddb: Storage", "remote_queue: Queue"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"indexeddb: Storage", "remote_queue: Queue"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"remote_queue"})
  /\ active' = UpdateActive({"remote_queue"}, {"d1_database: DB"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"d1_database: DB"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS

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
