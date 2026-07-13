------------------------------ MODULE open_source_gnosis_warmup_adaptive_optimization ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request", "generic_plan", "profile_collector", "policy_model", "specialized_plan", "chosen_plan", "result", "next_epoch"}
ROOTS == {"request"}
TERMINALS == {"next_epoch"}
FOLD_TARGETS == {"next_epoch"}
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
  /\ active' = UpdateActive({"request"}, {"generic_plan", "profile_collector"})
  /\ beta1' = beta1 + (Cardinality({"generic_plan", "profile_collector"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"generic_plan", "profile_collector"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"profile_collector"})
  /\ active' = UpdateActive({"profile_collector"}, {"policy_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"policy_model"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"policy_model"})
  /\ active' = UpdateActive({"policy_model"}, {"specialized_plan"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"specialized_plan"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"request"})
  /\ active' = UpdateActive({"request"}, {"specialized_plan"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"specialized_plan"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"generic_plan", "specialized_plan"})
  /\ \E winner \in {"chosen_plan"}:
      /\ active' = UpdateActive({"generic_plan", "specialized_plan"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"generic_plan", "specialized_plan"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_PROCESS ==
  /\ CanFire({"chosen_plan"})
  /\ active' = UpdateActive({"chosen_plan"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})
Edge_07_FOLD ==
  /\ CanFire({"result", "policy_model"})
  /\ active' = UpdateActive({"result", "policy_model"}, {"next_epoch"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"next_epoch"} \cap FOLD_TARGETS # {})

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
