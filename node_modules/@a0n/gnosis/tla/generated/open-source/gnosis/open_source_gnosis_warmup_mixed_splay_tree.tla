------------------------------ MODULE open_source_gnosis_warmup_mixed_splay_tree ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"access_request", "access_pattern", "tree_restructure", "adapted_tree", "search_operation", "result"}
ROOTS == {"access_request"}
TERMINALS == {"result"}
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
  /\ CanFire({"access_request"})
  /\ active' = UpdateActive({"access_request"}, {"access_pattern", "search_operation"})
  /\ beta1' = beta1 + (Cardinality({"access_pattern", "search_operation"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"access_pattern", "search_operation"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"access_pattern"})
  /\ active' = UpdateActive({"access_pattern"}, {"tree_restructure"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"tree_restructure"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"tree_restructure"})
  /\ active' = UpdateActive({"tree_restructure"}, {"adapted_tree"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"adapted_tree"} \cap FOLD_TARGETS # {})
Edge_04_INTERFERE ==
  /\ CanFire({"adapted_tree"})
  /\ active' = UpdateActive({"adapted_tree"}, {"search_operation"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"search_operation"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"search_operation"})
  /\ active' = UpdateActive({"search_operation"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_INTERFERE
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
