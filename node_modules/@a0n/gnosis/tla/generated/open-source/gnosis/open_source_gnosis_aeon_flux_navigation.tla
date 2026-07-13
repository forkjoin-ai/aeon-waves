------------------------------ MODULE open_source_gnosis_aeon_flux_navigation ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"nav_event", "url_parser", "history_manager", "route_matcher", "preloader", "site_renderer", "nav_complete", "app_state"}
ROOTS == {"nav_event"}
TERMINALS == {"app_state"}
FOLD_TARGETS == {"nav_complete"}
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
  /\ CanFire({"nav_event"})
  /\ active' = UpdateActive({"nav_event"}, {"url_parser"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"url_parser"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"url_parser"})
  /\ active' = UpdateActive({"url_parser"}, {"history_manager", "route_matcher"})
  /\ beta1' = beta1 + (Cardinality({"history_manager", "route_matcher"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"history_manager", "route_matcher"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"route_matcher"})
  /\ active' = UpdateActive({"route_matcher"}, {"preloader", "site_renderer"})
  /\ beta1' = beta1 + (Cardinality({"preloader", "site_renderer"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"preloader", "site_renderer"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"preloader", "site_renderer"})
  /\ active' = UpdateActive({"preloader", "site_renderer"}, {"nav_complete"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"nav_complete"} \cap FOLD_TARGETS # {})
Edge_05_INTERFERE ==
  /\ CanFire({"history_manager", "nav_complete"})
  /\ active' = UpdateActive({"history_manager", "nav_complete"}, {"app_state"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"app_state"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FORK
  \/ Edge_04_FOLD
  \/ Edge_05_INTERFERE

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
