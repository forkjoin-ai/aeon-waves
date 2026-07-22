------------------------------ MODULE open_source_gnosis_warmup_mixed_cdn_edge ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"client_request", "predictive_engine", "origin_server", "edge_cache", "cache_hit", "cache_miss", "response_plan", "delivered_asset"}
ROOTS == {"predictive_engine", "client_request"}
TERMINALS == {"delivered_asset"}
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

Edge_01_PROCESS ==
  /\ CanFire({"predictive_engine"})
  /\ active' = UpdateActive({"predictive_engine"}, {"origin_server"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"origin_server"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"origin_server"})
  /\ active' = UpdateActive({"origin_server"}, {"edge_cache"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"edge_cache"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"client_request"})
  /\ active' = UpdateActive({"client_request"}, {"cache_hit", "cache_miss"})
  /\ beta1' = beta1 + (Cardinality({"cache_hit", "cache_miss"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cache_hit", "cache_miss"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"edge_cache"})
  /\ active' = UpdateActive({"edge_cache"}, {"cache_hit"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cache_hit"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"origin_server"})
  /\ active' = UpdateActive({"origin_server"}, {"cache_miss"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cache_miss"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"cache_hit", "cache_miss"})
  /\ \E winner \in {"response_plan"}:
      /\ active' = UpdateActive({"cache_hit", "cache_miss"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"cache_hit", "cache_miss"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_PROCESS ==
  /\ CanFire({"response_plan"})
  /\ active' = UpdateActive({"response_plan"}, {"delivered_asset"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"delivered_asset"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_FORK
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
