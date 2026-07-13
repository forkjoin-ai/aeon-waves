------------------------------ MODULE open_source_gnosis_warmup_mixed_jit_compiler ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"execution_request", "interpreter", "profiler", "jit_optimizer", "trace_cache", "cache_write", "fast_execution", "chosen_execution", "commit", "result"}
ROOTS == {"execution_request"}
TERMINALS == {"result"}
FOLD_TARGETS == {"commit"}
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
  /\ active' = UpdateActive({"execution_request"}, {"interpreter", "profiler", "trace_cache"})
  /\ beta1' = beta1 + (Cardinality({"interpreter", "profiler", "trace_cache"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"interpreter", "profiler", "trace_cache"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"profiler"})
  /\ active' = UpdateActive({"profiler"}, {"jit_optimizer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"jit_optimizer"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"jit_optimizer"})
  /\ active' = UpdateActive({"jit_optimizer"}, {"fast_execution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_execution"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"fast_execution"})
  /\ active' = UpdateActive({"fast_execution"}, {"cache_write"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cache_write"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"trace_cache"})
  /\ active' = UpdateActive({"trace_cache"}, {"fast_execution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_execution"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"interpreter", "fast_execution"})
  /\ \E winner \in {"chosen_execution"}:
      /\ active' = UpdateActive({"interpreter", "fast_execution"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"interpreter", "fast_execution"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_FOLD ==
  /\ CanFire({"chosen_execution", "cache_write"})
  /\ active' = UpdateActive({"chosen_execution", "cache_write"}, {"commit"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"commit"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"commit"})
  /\ active' = UpdateActive({"commit"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_RACE
  \/ Edge_07_FOLD
  \/ Edge_08_PROCESS

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
