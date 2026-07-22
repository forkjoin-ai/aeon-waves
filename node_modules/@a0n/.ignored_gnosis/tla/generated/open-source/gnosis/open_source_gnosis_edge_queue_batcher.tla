------------------------------ MODULE open_source_gnosis_edge_queue_batcher ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"trigger", "batch", "warehouse", "trigger: Time", "event1: Log", "event2: Log", "event3: Log", "event1", "event2", "event3", "batch: Array", "warehouse: DB"}
ROOTS == {"trigger: Time", "event1", "event2", "event3"}
TERMINALS == {"event1: Log", "event2: Log", "event3: Log", "warehouse: DB"}
FOLD_TARGETS == {"batch: Array"}
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
  /\ CanFire({"trigger: Time"})
  /\ active' = UpdateActive({"trigger: Time"}, {"event1: Log", "event2: Log", "event3: Log"})
  /\ beta1' = beta1 + (Cardinality({"event1: Log", "event2: Log", "event3: Log"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"event1: Log", "event2: Log", "event3: Log"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"event1", "event2", "event3"})
  /\ active' = UpdateActive({"event1", "event2", "event3"}, {"batch: Array"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"batch: Array"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"batch: Array"})
  /\ active' = UpdateActive({"batch: Array"}, {"warehouse: DB"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"warehouse: DB"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_PROCESS

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
