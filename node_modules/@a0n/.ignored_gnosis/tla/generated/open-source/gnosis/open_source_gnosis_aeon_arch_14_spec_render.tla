------------------------------ MODULE open_source_gnosis_aeon_arch_14_spec_render ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"intent", "final_ui", "intent: Action", "render_spec: UI", "fetch_data: API", "render_spec", "fetch_data", "final_ui: UI"}
ROOTS == {"intent: Action", "render_spec", "fetch_data"}
TERMINALS == {"render_spec: UI", "fetch_data: API", "final_ui: UI"}
FOLD_TARGETS == {"final_ui: UI"}
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
  /\ CanFire({"intent: Action"})
  /\ active' = UpdateActive({"intent: Action"}, {"render_spec: UI", "fetch_data: API"})
  /\ beta1' = beta1 + (Cardinality({"render_spec: UI", "fetch_data: API"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"render_spec: UI", "fetch_data: API"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"render_spec", "fetch_data"})
  /\ active' = UpdateActive({"render_spec", "fetch_data"}, {"final_ui: UI"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"final_ui: UI"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

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
