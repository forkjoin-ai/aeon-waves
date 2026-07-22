------------------------------ MODULE open_source_gnosis_examples_crdt_qsequence ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seq", "edit_a", "ea", "edit_b", "eb", "merged"}
ROOTS == {"seq"}
TERMINALS == {"merged"}
FOLD_TARGETS == {"merged"}
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
  /\ CanFire({"seq"})
  /\ active' = UpdateActive({"seq"}, {"edit_a", "edit_b"})
  /\ beta1' = beta1 + (Cardinality({"edit_a", "edit_b"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"edit_a", "edit_b"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"edit_a"})
  /\ active' = UpdateActive({"edit_a"}, {"ea"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ea"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"edit_b"})
  /\ active' = UpdateActive({"edit_b"}, {"eb"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"eb"} \cap FOLD_TARGETS # {})
Edge_04_OBSERVE ==
  /\ CanFire({"ea", "eb"})
  /\ active' = UpdateActive({"ea", "eb"}, {"merged"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merged"} \cap FOLD_TARGETS # {})

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
