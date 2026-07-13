------------------------------ MODULE open_source_gnosis_warmup_precompute_prefetch ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"nav_context", "route_predictor", "css_prefetch", "data_prefetch", "font_prefetch", "warmed_bundle", "route_request", "origin_fetch", "route_ready", "route_ready: Ready"}
ROOTS == {"nav_context", "route_request"}
TERMINALS == {"route_ready: Ready"}
FOLD_TARGETS == {"warmed_bundle"}
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
  /\ CanFire({"nav_context"})
  /\ active' = UpdateActive({"nav_context"}, {"route_predictor"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"route_predictor"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"route_predictor"})
  /\ active' = UpdateActive({"route_predictor"}, {"css_prefetch", "data_prefetch", "font_prefetch"})
  /\ beta1' = beta1 + (Cardinality({"css_prefetch", "data_prefetch", "font_prefetch"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"css_prefetch", "data_prefetch", "font_prefetch"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"css_prefetch", "data_prefetch", "font_prefetch"})
  /\ active' = UpdateActive({"css_prefetch", "data_prefetch", "font_prefetch"}, {"warmed_bundle"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"warmed_bundle"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"route_request"})
  /\ active' = UpdateActive({"route_request"}, {"warmed_bundle", "origin_fetch"})
  /\ beta1' = beta1 + (Cardinality({"warmed_bundle", "origin_fetch"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"warmed_bundle", "origin_fetch"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"warmed_bundle", "origin_fetch"})
  /\ \E winner \in {"route_ready: Ready"}:
      /\ active' = UpdateActive({"warmed_bundle", "origin_fetch"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"warmed_bundle", "origin_fetch"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FOLD
  \/ Edge_04_FORK
  \/ Edge_05_RACE

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
