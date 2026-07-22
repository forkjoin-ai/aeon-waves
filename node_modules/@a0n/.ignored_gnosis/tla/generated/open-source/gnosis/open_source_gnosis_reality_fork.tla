------------------------------ MODULE open_source_gnosis_reality_fork ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"primary_reality", "speculative_path_a", "speculative_path_b", "merge_engine", "ui_update", "result_a", "result_b", "winner", "new_reality"}
ROOTS == {"primary_reality"}
TERMINALS == {"ui_update"}
FOLD_TARGETS == {"new_reality"}
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
  /\ CanFire({"primary_reality"})
  /\ active' = UpdateActive({"primary_reality"}, {"speculative_path_a", "speculative_path_b"})
  /\ beta1' = beta1 + (Cardinality({"speculative_path_a", "speculative_path_b"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"speculative_path_a", "speculative_path_b"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"speculative_path_a"})
  /\ active' = UpdateActive({"speculative_path_a"}, {"result_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result_a"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"speculative_path_b"})
  /\ active' = UpdateActive({"speculative_path_b"}, {"result_b"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result_b"} \cap FOLD_TARGETS # {})
Edge_04_RACE ==
  /\ CanFire({"result_a", "result_b"})
  /\ \E winner \in {"winner"}:
      /\ active' = UpdateActive({"result_a", "result_b"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"result_a", "result_b"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_05_FOLD ==
  /\ CanFire({"primary_reality", "winner"})
  /\ active' = UpdateActive({"primary_reality", "winner"}, {"new_reality"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"new_reality"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"new_reality"})
  /\ active' = UpdateActive({"new_reality"}, {"ui_update"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ui_update"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_RACE
  \/ Edge_05_FOLD
  \/ Edge_06_PROCESS

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
