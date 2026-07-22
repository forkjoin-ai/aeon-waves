------------------------------ MODULE open_source_gnosis_examples_torture ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"source", "a1", "a2", "a3", "a4", "b1", "b2", "winner", "void_1", "void_2", "sink", "lost_soul"}
ROOTS == {"source"}
TERMINALS == {"sink"}
FOLD_TARGETS == {"sink"}
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
  /\ CanFire({"source"})
  /\ active' = UpdateActive({"source"}, {"a1", "a2", "a3", "a4"})
  /\ beta1' = beta1 + (Cardinality({"a1", "a2", "a3", "a4"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"a1", "a2", "a3", "a4"} \cap FOLD_TARGETS # {})
Edge_02_INTERFERE ==
  /\ CanFire({"a1", "a2"})
  /\ active' = UpdateActive({"a1", "a2"}, {"b1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"b1"} \cap FOLD_TARGETS # {})
Edge_03_INTERFERE ==
  /\ CanFire({"a3", "a4"})
  /\ active' = UpdateActive({"a3", "a4"}, {"b2"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"b2"} \cap FOLD_TARGETS # {})
Edge_04_RACE ==
  /\ CanFire({"b1", "b2"})
  /\ \E winner \in {"winner"}:
      /\ active' = UpdateActive({"b1", "b2"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"b1", "b2"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_05_PROCESS ==
  /\ CanFire({"a1"})
  /\ active' = UpdateActive({"a1"}, {"void_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"void_1"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"a2"})
  /\ active' = UpdateActive({"a2"}, {"void_2"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"void_2"} \cap FOLD_TARGETS # {})
Edge_07_FOLD ==
  /\ CanFire({"winner", "void_1", "void_2"})
  /\ active' = UpdateActive({"winner", "void_1", "void_2"}, {"sink"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_INTERFERE
  \/ Edge_03_INTERFERE
  \/ Edge_04_RACE
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_FOLD

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
