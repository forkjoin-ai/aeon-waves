------------------------------ MODULE open_source_gnosis_flux_client_sync ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"ui_mutation", "server_sync", "ack", "confirmed_ui", "ui_mutation: Event", "optimistic_update: DOM", "server_sync: WSS", "ack: Network", "optimistic_update", "confirmed_ui: DOM"}
ROOTS == {"ui_mutation: Event", "server_sync", "optimistic_update", "ack"}
TERMINALS == {"optimistic_update: DOM", "server_sync: WSS", "ack: Network", "confirmed_ui: DOM"}
FOLD_TARGETS == {"confirmed_ui: DOM"}
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
  /\ CanFire({"ui_mutation: Event"})
  /\ active' = UpdateActive({"ui_mutation: Event"}, {"optimistic_update: DOM", "server_sync: WSS"})
  /\ beta1' = beta1 + (Cardinality({"optimistic_update: DOM", "server_sync: WSS"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"optimistic_update: DOM", "server_sync: WSS"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"server_sync"})
  /\ active' = UpdateActive({"server_sync"}, {"ack: Network"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ack: Network"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"optimistic_update", "ack"})
  /\ active' = UpdateActive({"optimistic_update", "ack"}, {"confirmed_ui: DOM"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"confirmed_ui: DOM"} \cap FOLD_TARGETS # {})

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
