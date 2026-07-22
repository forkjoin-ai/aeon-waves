------------------------------ MODULE open_source_gnosis_examples_crdt_qset ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"set", "add_branch", "added", "remove_branch", "removed", "resolved"}
ROOTS == {"set"}
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
  /\ CanFire({"set"})
  /\ active' = UpdateActive({"set"}, {"add_branch", "remove_branch"})
  /\ beta1' = beta1 + (Cardinality({"add_branch", "remove_branch"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"add_branch", "remove_branch"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"add_branch"})
  /\ active' = UpdateActive({"add_branch"}, {"added"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"added"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"remove_branch"})
  /\ active' = UpdateActive({"remove_branch"}, {"removed"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"removed"} \cap FOLD_TARGETS # {})
Edge_04_OBSERVE ==
  /\ CanFire({"added", "removed"})
  /\ active' = UpdateActive({"added", "removed"}, {"resolved"})
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
