------------------------------ MODULE open_source_gnosis_warmup_physical_biological ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"body", "circulation", "temperature", "coordination", "heat_loss", "readiness", "performance", "performance: Output"}
ROOTS == {"body"}
TERMINALS == {"performance: Output", "heat_loss"}
FOLD_TARGETS == {"readiness"}
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
  /\ active' = UpdateActive({"body"}, {"circulation", "temperature", "coordination"})
  /\ beta1' = beta1 + (Cardinality({"circulation", "temperature", "coordination"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"circulation", "temperature", "coordination"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"circulation", "temperature", "coordination"})
  /\ active' = UpdateActive({"circulation", "temperature", "coordination"}, {"readiness"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"readiness"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"readiness"})
  /\ active' = UpdateActive({"readiness"}, {"performance: Output"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"performance: Output"} \cap FOLD_TARGETS # {})
Edge_04_VENT ==
  /\ CanFire({"readiness"})
  /\ active' = UpdateActive({"readiness"}, {"heat_loss"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"heat_loss"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_PROCESS
  \/ Edge_04_VENT

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
