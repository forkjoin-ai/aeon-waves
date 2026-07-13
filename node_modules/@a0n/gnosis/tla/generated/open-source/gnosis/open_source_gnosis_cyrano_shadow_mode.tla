------------------------------ MODULE open_source_gnosis_cyrano_shadow_mode ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"user_action", "shadow_agent", "insight", "done", "user_action: Event", "live_ui: View", "shadow_agent: Observer", "insight: Memory", "live_ui", "done: End"}
ROOTS == {"user_action: Event", "shadow_agent", "live_ui", "insight"}
TERMINALS == {"live_ui: View", "shadow_agent: Observer", "insight: Memory", "done: End"}
FOLD_TARGETS == {"done: End"}
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
  /\ CanFire({"user_action: Event"})
  /\ active' = UpdateActive({"user_action: Event"}, {"live_ui: View", "shadow_agent: Observer"})
  /\ beta1' = beta1 + (Cardinality({"live_ui: View", "shadow_agent: Observer"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"live_ui: View", "shadow_agent: Observer"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"shadow_agent"})
  /\ active' = UpdateActive({"shadow_agent"}, {"insight: Memory"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"insight: Memory"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"live_ui", "insight"})
  /\ active' = UpdateActive({"live_ui", "insight"}, {"done: End"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"done: End"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_FOLD

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
