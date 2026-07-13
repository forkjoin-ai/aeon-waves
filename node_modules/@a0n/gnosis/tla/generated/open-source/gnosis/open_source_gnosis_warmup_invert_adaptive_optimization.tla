------------------------------ MODULE open_source_gnosis_warmup_invert_adaptive_optimization ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request", "generic_plan", "noisy_telemetry", "policy_model", "drifted_plan", "selected_plan", "oscillation", "final_result"}
ROOTS == {"request"}
TERMINALS == {"final_result"}
FOLD_TARGETS == {"final_result"}
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
  /\ CanFire({"request"})
  /\ active' = UpdateActive({"request"}, {"generic_plan", "noisy_telemetry"})
  /\ beta1' = beta1 + (Cardinality({"generic_plan", "noisy_telemetry"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"generic_plan", "noisy_telemetry"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"noisy_telemetry"})
  /\ active' = UpdateActive({"noisy_telemetry"}, {"policy_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"policy_model"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"policy_model"})
  /\ active' = UpdateActive({"policy_model"}, {"drifted_plan"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"drifted_plan"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"request"})
  /\ active' = UpdateActive({"request"}, {"drifted_plan"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"drifted_plan"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"generic_plan", "drifted_plan"})
  /\ \E winner \in {"selected_plan"}:
      /\ active' = UpdateActive({"generic_plan", "drifted_plan"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"generic_plan", "drifted_plan"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_INTERFERE ==
  /\ CanFire({"selected_plan", "policy_model"})
  /\ active' = UpdateActive({"selected_plan", "policy_model"}, {"oscillation"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"oscillation"} \cap FOLD_TARGETS # {})
Edge_07_FOLD ==
  /\ CanFire({"oscillation", "generic_plan"})
  /\ active' = UpdateActive({"oscillation", "generic_plan"}, {"final_result"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"final_result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_RACE
  \/ Edge_06_INTERFERE
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
