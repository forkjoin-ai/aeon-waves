------------------------------ MODULE open_source_gnosis_warmup_invert_mixed_jit_compiler ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"execution_request", "interpreter", "noisy_profiler", "overfit_optimizer", "poisoned_cache", "poison_write", "fast_execution", "validator", "chosen_execution", "unstable_execution", "result"}
ROOTS == {"execution_request"}
TERMINALS == {"result"}
FOLD_TARGETS == {"result"}
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
  /\ CanFire({"execution_request"})
  /\ active' = UpdateActive({"execution_request"}, {"interpreter", "noisy_profiler", "poisoned_cache"})
  /\ beta1' = beta1 + (Cardinality({"interpreter", "noisy_profiler", "poisoned_cache"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"interpreter", "noisy_profiler", "poisoned_cache"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"noisy_profiler"})
  /\ active' = UpdateActive({"noisy_profiler"}, {"overfit_optimizer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"overfit_optimizer"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"overfit_optimizer"})
  /\ active' = UpdateActive({"overfit_optimizer"}, {"fast_execution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_execution"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"fast_execution"})
  /\ active' = UpdateActive({"fast_execution"}, {"poison_write"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"poison_write"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"poisoned_cache"})
  /\ active' = UpdateActive({"poisoned_cache"}, {"fast_execution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_execution"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"poisoned_cache"})
  /\ active' = UpdateActive({"poisoned_cache"}, {"validator"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"validator"} \cap FOLD_TARGETS # {})
Edge_07_RACE ==
  /\ CanFire({"interpreter", "fast_execution"})
  /\ \E winner \in {"chosen_execution"}:
      /\ active' = UpdateActive({"interpreter", "fast_execution"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"interpreter", "fast_execution"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_08_INTERFERE ==
  /\ CanFire({"chosen_execution", "validator", "poison_write"})
  /\ active' = UpdateActive({"chosen_execution", "validator", "poison_write"}, {"unstable_execution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"unstable_execution"} \cap FOLD_TARGETS # {})
Edge_09_FOLD ==
  /\ CanFire({"unstable_execution", "interpreter"})
  /\ active' = UpdateActive({"unstable_execution", "interpreter"}, {"result"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_RACE
  \/ Edge_08_INTERFERE
  \/ Edge_09_FOLD

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
