------------------------------ MODULE open_source_gnosis_warmup_invert_physical_biological ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"body", "circulation", "temperature", "coordination", "fatigue", "readiness", "heat_debt", "strained_state", "cooldown", "performance", "performance: Output"}
ROOTS == {"body", "performance"}
TERMINALS == {"performance: Output", "cooldown"}
FOLD_TARGETS == {"readiness", "strained_state"}
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
  /\ CanFire({"body"})
  /\ active' = UpdateActive({"body"}, {"circulation", "temperature", "coordination", "fatigue"})
  /\ beta1' = beta1 + (Cardinality({"circulation", "temperature", "coordination", "fatigue"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"circulation", "temperature", "coordination", "fatigue"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"circulation", "temperature", "coordination"})
  /\ active' = UpdateActive({"circulation", "temperature", "coordination"}, {"readiness"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"readiness"} \cap FOLD_TARGETS # {})
Edge_03_INTERFERE ==
  /\ CanFire({"temperature", "fatigue"})
  /\ active' = UpdateActive({"temperature", "fatigue"}, {"heat_debt"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"heat_debt"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"readiness", "heat_debt"})
  /\ active' = UpdateActive({"readiness", "heat_debt"}, {"strained_state"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"strained_state"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"strained_state"})
  /\ active' = UpdateActive({"strained_state"}, {"performance: Output"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"performance: Output"} \cap FOLD_TARGETS # {})
Edge_06_VENT ==
  /\ CanFire({"performance"})
  /\ active' = UpdateActive({"performance"}, {"cooldown"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cooldown"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_INTERFERE
  \/ Edge_04_FOLD
  \/ Edge_05_PROCESS
  \/ Edge_06_VENT

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
