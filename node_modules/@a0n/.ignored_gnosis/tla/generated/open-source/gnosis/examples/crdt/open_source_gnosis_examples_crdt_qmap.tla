------------------------------ MODULE open_source_gnosis_examples_crdt_qmap ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"map", "write_name", "wn", "write_age", "wa", "resolved"}
ROOTS == {"map"}
TERMINALS == {"resolved"}
FOLD_TARGETS == {"resolved"}
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
  /\ CanFire({"map"})
  /\ active' = UpdateActive({"map"}, {"write_name", "write_age"})
  /\ beta1' = beta1 + (Cardinality({"write_name", "write_age"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"write_name", "write_age"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"write_name"})
  /\ active' = UpdateActive({"write_name"}, {"wn"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wn"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"write_age"})
  /\ active' = UpdateActive({"write_age"}, {"wa"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wa"} \cap FOLD_TARGETS # {})
Edge_04_OBSERVE ==
  /\ CanFire({"wn", "wa"})
  /\ active' = UpdateActive({"wn", "wa"}, {"resolved"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"resolved"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_OBSERVE

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
