------------------------------ MODULE open_source_gnosis_warmup_invert_precompute_prefetch ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"nav_context", "route_predictor", "wrong_css", "wrong_data", "wrong_font", "wrong_bundle", "route_request", "origin_fetch", "route_validator", "first_route", "settled_route", "misroute", "misroute: Candidate"}
ROOTS == {"nav_context", "route_request", "misroute"}
TERMINALS == {"misroute: Candidate", "settled_route"}
FOLD_TARGETS == {"wrong_bundle", "settled_route"}
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
  /\ active' = UpdateActive({"route_predictor"}, {"wrong_css", "wrong_data", "wrong_font"})
  /\ beta1' = beta1 + (Cardinality({"wrong_css", "wrong_data", "wrong_font"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wrong_css", "wrong_data", "wrong_font"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"wrong_css", "wrong_data", "wrong_font"})
  /\ active' = UpdateActive({"wrong_css", "wrong_data", "wrong_font"}, {"wrong_bundle"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wrong_bundle"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"wrong_bundle"})
  /\ active' = UpdateActive({"wrong_bundle"}, {"route_validator"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"route_validator"} \cap FOLD_TARGETS # {})
Edge_05_FORK ==
  /\ CanFire({"route_request"})
  /\ active' = UpdateActive({"route_request"}, {"wrong_bundle", "origin_fetch"})
  /\ beta1' = beta1 + (Cardinality({"wrong_bundle", "origin_fetch"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wrong_bundle", "origin_fetch"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"wrong_bundle", "origin_fetch"})
  /\ \E winner \in {"first_route"}:
      /\ active' = UpdateActive({"wrong_bundle", "origin_fetch"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"wrong_bundle", "origin_fetch"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_INTERFERE ==
  /\ CanFire({"first_route", "route_validator"})
  /\ active' = UpdateActive({"first_route", "route_validator"}, {"misroute: Candidate"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"misroute: Candidate"} \cap FOLD_TARGETS # {})
Edge_08_FOLD ==
  /\ CanFire({"misroute", "origin_fetch"})
  /\ active' = UpdateActive({"misroute", "origin_fetch"}, {"settled_route"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"settled_route"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FOLD
  \/ Edge_04_PROCESS
  \/ Edge_05_FORK
  \/ Edge_06_RACE
  \/ Edge_07_INTERFERE
  \/ Edge_08_FOLD

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
