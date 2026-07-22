------------------------------ MODULE open_source_gnosis_core_entrainment_engine ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"target_hz", "brainwave_sync", "target_hz: Number", "left_ear: Audio", "right_ear: Audio", "left_ear", "right_ear", "brainwave_sync: Output"}
ROOTS == {"target_hz: Number", "left_ear", "right_ear"}
TERMINALS == {"left_ear: Audio", "right_ear: Audio", "brainwave_sync: Output"}
FOLD_TARGETS == {"brainwave_sync: Output"}
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
  /\ CanFire({"target_hz: Number"})
  /\ active' = UpdateActive({"target_hz: Number"}, {"left_ear: Audio", "right_ear: Audio"})
  /\ beta1' = beta1 + (Cardinality({"left_ear: Audio", "right_ear: Audio"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"left_ear: Audio", "right_ear: Audio"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"left_ear", "right_ear"})
  /\ active' = UpdateActive({"left_ear", "right_ear"}, {"brainwave_sync: Output"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"brainwave_sync: Output"} \cap FOLD_TARGETS # {})

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
