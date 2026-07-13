------------------------------ MODULE open_source_gnosis_examples_crdt_entanglement ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"doc", "content_layer", "edit_a", "ea", "edit_b", "eb", "content", "presence_layer", "cursor_alice", "ca", "cursor_bob", "cb"}
ROOTS == {"doc"}
TERMINALS == {"cb"}
FOLD_TARGETS == {"content"}
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
  /\ CanFire({"doc"})
  /\ active' = UpdateActive({"doc"}, {"content_layer", "presence_layer"})
  /\ beta1' = beta1 + (Cardinality({"content_layer", "presence_layer"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"content_layer", "presence_layer"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"content_layer"})
  /\ active' = UpdateActive({"content_layer"}, {"edit_a", "edit_b"})
  /\ beta1' = beta1 + (Cardinality({"edit_a", "edit_b"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"edit_a", "edit_b"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"edit_a"})
  /\ active' = UpdateActive({"edit_a"}, {"ea"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ea"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"edit_b"})
  /\ active' = UpdateActive({"edit_b"}, {"eb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"eb"} \cap FOLD_TARGETS # {})
Edge_05_OBSERVE ==
  /\ CanFire({"ea", "eb"})
  /\ active' = UpdateActive({"ea", "eb"}, {"content"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"content"} \cap FOLD_TARGETS # {})
Edge_06_FORK ==
  /\ CanFire({"presence_layer"})
  /\ active' = UpdateActive({"presence_layer"}, {"cursor_alice", "cursor_bob"})
  /\ beta1' = beta1 + (Cardinality({"cursor_alice", "cursor_bob"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cursor_alice", "cursor_bob"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"cursor_alice"})
  /\ active' = UpdateActive({"cursor_alice"}, {"ca"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ca"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"cursor_bob"})
  /\ active' = UpdateActive({"cursor_bob"}, {"cb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cb"} \cap FOLD_TARGETS # {})
Edge_09_INTERFERE ==
  /\ CanFire({"ca"})
  /\ active' = UpdateActive({"ca"}, {"cb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cb"} \cap FOLD_TARGETS # {})
Edge_10_ENTANGLE ==
  /\ CanFire({"content"})
  /\ active' = UpdateActive({"content"}, {"ca"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ca"} \cap FOLD_TARGETS # {})
Edge_11_ENTANGLE ==
  /\ CanFire({"content"})
  /\ active' = UpdateActive({"content"}, {"cb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cb"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FORK
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_OBSERVE
  \/ Edge_06_FORK
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_INTERFERE
  \/ Edge_10_ENTANGLE
  \/ Edge_11_ENTANGLE

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
