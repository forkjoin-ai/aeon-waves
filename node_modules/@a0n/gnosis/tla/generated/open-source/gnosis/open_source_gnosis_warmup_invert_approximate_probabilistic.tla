------------------------------ MODULE open_source_gnosis_warmup_invert_approximate_probabilistic ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query", "unstable_sketch", "maybe_hit", "false_positive", "exact_lookup", "shadow_lookup", "full_scan", "overworked_answer", "answer", "waste_heat"}
ROOTS == {"query"}
TERMINALS == {"waste_heat"}
FOLD_TARGETS == {"overworked_answer"}
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

Edge_01_PROCESS ==
  /\ CanFire({"query"})
  /\ active' = UpdateActive({"query"}, {"unstable_sketch"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"unstable_sketch"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"unstable_sketch"})
  /\ active' = UpdateActive({"unstable_sketch"}, {"maybe_hit", "false_positive"})
  /\ beta1' = beta1 + (Cardinality({"maybe_hit", "false_positive"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"maybe_hit", "false_positive"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"maybe_hit"})
  /\ active' = UpdateActive({"maybe_hit"}, {"exact_lookup"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"exact_lookup"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"false_positive"})
  /\ active' = UpdateActive({"false_positive"}, {"shadow_lookup", "full_scan"})
  /\ beta1' = beta1 + (Cardinality({"shadow_lookup", "full_scan"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shadow_lookup", "full_scan"} \cap FOLD_TARGETS # {})
Edge_05_FOLD ==
  /\ CanFire({"exact_lookup", "shadow_lookup", "full_scan"})
  /\ active' = UpdateActive({"exact_lookup", "shadow_lookup", "full_scan"}, {"overworked_answer"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"overworked_answer"} \cap FOLD_TARGETS # {})
Edge_06_INTERFERE ==
  /\ CanFire({"overworked_answer", "false_positive"})
  /\ active' = UpdateActive({"overworked_answer", "false_positive"}, {"answer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"answer"} \cap FOLD_TARGETS # {})
Edge_07_VENT ==
  /\ CanFire({"answer"})
  /\ active' = UpdateActive({"answer"}, {"waste_heat"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"waste_heat"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_PROCESS
  \/ Edge_04_FORK
  \/ Edge_05_FOLD
  \/ Edge_06_INTERFERE
  \/ Edge_07_VENT

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
