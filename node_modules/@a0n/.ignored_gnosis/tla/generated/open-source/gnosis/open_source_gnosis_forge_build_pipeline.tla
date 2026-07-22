------------------------------ MODULE open_source_gnosis_forge_build_pipeline ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"source", "artifact", "source: Source", "lint: Check", "test: Check", "lint", "test", "artifact: Binary"}
ROOTS == {"source: Source", "lint", "test"}
TERMINALS == {"lint: Check", "test: Check", "artifact: Binary"}
FOLD_TARGETS == {"artifact: Binary"}
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
  /\ CanFire({"source: Source"})
  /\ active' = UpdateActive({"source: Source"}, {"lint: Check", "test: Check"})
  /\ beta1' = beta1 + (Cardinality({"lint: Check", "test: Check"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lint: Check", "test: Check"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"lint", "test"})
  /\ active' = UpdateActive({"lint", "test"}, {"artifact: Binary"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"artifact: Binary"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

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
