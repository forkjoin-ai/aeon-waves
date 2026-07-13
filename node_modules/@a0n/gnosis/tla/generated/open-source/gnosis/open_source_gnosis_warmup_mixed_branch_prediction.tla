------------------------------ MODULE open_source_gnosis_warmup_mixed_branch_prediction ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"instruction", "fallback_pipeline", "branch_history", "predictor_model", "speculative_path", "executed_branch", "commit_stage", "next_history"}
ROOTS == {"instruction"}
TERMINALS == {"next_history"}
FOLD_TARGETS == {"next_history"}
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
  /\ CanFire({"instruction"})
  /\ active' = UpdateActive({"instruction"}, {"fallback_pipeline", "branch_history"})
  /\ beta1' = beta1 + (Cardinality({"fallback_pipeline", "branch_history"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fallback_pipeline", "branch_history"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"branch_history"})
  /\ active' = UpdateActive({"branch_history"}, {"predictor_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"predictor_model"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"predictor_model"})
  /\ active' = UpdateActive({"predictor_model"}, {"speculative_path"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"speculative_path"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"instruction"})
  /\ active' = UpdateActive({"instruction"}, {"speculative_path"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"speculative_path"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"fallback_pipeline", "speculative_path"})
  /\ \E winner \in {"executed_branch"}:
      /\ active' = UpdateActive({"fallback_pipeline", "speculative_path"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"fallback_pipeline", "speculative_path"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_PROCESS ==
  /\ CanFire({"executed_branch"})
  /\ active' = UpdateActive({"executed_branch"}, {"commit_stage"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"commit_stage"} \cap FOLD_TARGETS # {})
Edge_07_FOLD ==
  /\ CanFire({"commit_stage", "predictor_model"})
  /\ active' = UpdateActive({"commit_stage", "predictor_model"}, {"next_history"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"next_history"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_RACE
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
