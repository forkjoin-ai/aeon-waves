------------------------------ MODULE open_source_gnosis_failure_trilemma_keep_multiplicity ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"origin", "left", "right", "survivor_set", "boundary", "keep_multiplicity", "result"}
ROOTS == {"origin"}
TERMINALS == {"result"}
FOLD_TARGETS == {"survivor_set"}
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
  /\ CanFire({"origin"})
  /\ active' = UpdateActive({"origin"}, {"left", "right"})
  /\ beta1' = beta1 + (Cardinality({"left", "right"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"left", "right"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"left", "right"})
  /\ active' = UpdateActive({"left", "right"}, {"survivor_set"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"survivor_set"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"survivor_set"})
  /\ active' = UpdateActive({"survivor_set"}, {"boundary"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"boundary"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"boundary"})
  /\ active' = UpdateActive({"boundary"}, {"keep_multiplicity"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"keep_multiplicity"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"keep_multiplicity"})
  /\ active' = UpdateActive({"keep_multiplicity"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS

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
