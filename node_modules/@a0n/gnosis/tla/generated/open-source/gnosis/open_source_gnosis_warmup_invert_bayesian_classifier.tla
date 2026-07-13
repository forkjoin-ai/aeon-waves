------------------------------ MODULE open_source_gnosis_warmup_invert_bayesian_classifier ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"observation", "eval_informational", "eval_physical", "eval_noise", "class_cache", "class_physical", "class_unknown", "ambiguous_race_result", "anomaly_detected", "ambiguous_race_result: State", "anomaly_detected: Classification"}
ROOTS == {"observation", "ambiguous_race_result"}
TERMINALS == {"ambiguous_race_result: State", "anomaly_detected: Classification"}
FOLD_TARGETS == {"anomaly_detected: Classification"}
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
  /\ CanFire({"observation"})
  /\ active' = UpdateActive({"observation"}, {"eval_informational", "eval_physical", "eval_noise"})
  /\ beta1' = beta1 + (Cardinality({"eval_informational", "eval_physical", "eval_noise"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"eval_informational", "eval_physical", "eval_noise"} \cap FOLD_TARGETS # {})
Edge_02_INTERFERE ==
  /\ CanFire({"eval_informational"})
  /\ active' = UpdateActive({"eval_informational"}, {"class_cache"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_cache"} \cap FOLD_TARGETS # {})
Edge_03_INTERFERE ==
  /\ CanFire({"eval_informational"})
  /\ active' = UpdateActive({"eval_informational"}, {"class_physical"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_physical"} \cap FOLD_TARGETS # {})
Edge_04_INTERFERE ==
  /\ CanFire({"eval_physical"})
  /\ active' = UpdateActive({"eval_physical"}, {"class_physical"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_physical"} \cap FOLD_TARGETS # {})
Edge_05_INTERFERE ==
  /\ CanFire({"eval_physical"})
  /\ active' = UpdateActive({"eval_physical"}, {"class_cache"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_cache"} \cap FOLD_TARGETS # {})
Edge_06_INTERFERE ==
  /\ CanFire({"eval_noise"})
  /\ active' = UpdateActive({"eval_noise"}, {"class_cache"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_cache"} \cap FOLD_TARGETS # {})
Edge_07_INTERFERE ==
  /\ CanFire({"eval_noise"})
  /\ active' = UpdateActive({"eval_noise"}, {"class_physical"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_physical"} \cap FOLD_TARGETS # {})
Edge_08_INTERFERE ==
  /\ CanFire({"eval_noise"})
  /\ active' = UpdateActive({"eval_noise"}, {"class_unknown"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"class_unknown"} \cap FOLD_TARGETS # {})
Edge_09_RACE ==
  /\ CanFire({"class_cache", "class_physical", "class_unknown"})
  /\ \E winner \in {"ambiguous_race_result: State"}:
      /\ active' = UpdateActive({"class_cache", "class_physical", "class_unknown"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"class_cache", "class_physical", "class_unknown"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_10_FOLD ==
  /\ CanFire({"ambiguous_race_result", "eval_noise"})
  /\ active' = UpdateActive({"ambiguous_race_result", "eval_noise"}, {"anomaly_detected: Classification"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"anomaly_detected: Classification"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_INTERFERE
  \/ Edge_03_INTERFERE
  \/ Edge_04_INTERFERE
  \/ Edge_05_INTERFERE
  \/ Edge_06_INTERFERE
  \/ Edge_07_INTERFERE
  \/ Edge_08_INTERFERE
  \/ Edge_09_RACE
  \/ Edge_10_FOLD

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
