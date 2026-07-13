------------------------------ MODULE open_source_gnosis_warmup_mixed_materialized_view ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query_request", "base_tables", "view_compiler", "materialized_cache", "fast_query", "slow_query", "chosen_plan", "result"}
ROOTS == {"query_request", "base_tables"}
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
  /\ CanFire({"query_request"})
  /\ active' = UpdateActive({"query_request"}, {"fast_query", "slow_query"})
  /\ beta1' = beta1 + (Cardinality({"fast_query", "slow_query"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_query", "slow_query"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"base_tables"})
  /\ active' = UpdateActive({"base_tables"}, {"view_compiler"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"view_compiler"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"view_compiler"})
  /\ active' = UpdateActive({"view_compiler"}, {"materialized_cache"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"materialized_cache"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"materialized_cache"})
  /\ active' = UpdateActive({"materialized_cache"}, {"fast_query"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_query"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"base_tables"})
  /\ active' = UpdateActive({"base_tables"}, {"slow_query"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"slow_query"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"slow_query", "fast_query"})
  /\ \E winner \in {"chosen_plan"}:
      /\ active' = UpdateActive({"slow_query", "fast_query"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"slow_query", "fast_query"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_PROCESS ==
  /\ CanFire({"chosen_plan"})
  /\ active' = UpdateActive({"chosen_plan"}, {"result"})
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
  \/ Edge_07_PROCESS

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
