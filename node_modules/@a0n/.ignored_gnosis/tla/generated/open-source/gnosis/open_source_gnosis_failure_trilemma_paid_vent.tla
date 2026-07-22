------------------------------ MODULE open_source_gnosis_failure_trilemma_paid_vent ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"origin", "left", "right", "vented_loss", "survivor_mask", "collapse", "result"}
ROOTS == {"origin"}
TERMINALS == {"result"}
FOLD_TARGETS == {"collapse"}
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
  /\ CanFire({"origin"})
  /\ active' = UpdateActive({"origin"}, {"left", "right"})
  /\ beta1' = beta1 + (Cardinality({"left", "right"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"left", "right"} \cap FOLD_TARGETS # {})
Edge_02_VENT ==
  /\ CanFire({"right"})
  /\ active' = UpdateActive({"right"}, {"vented_loss"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"vented_loss"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"left"})
  /\ active' = UpdateActive({"left"}, {"survivor_mask"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"survivor_mask"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"survivor_mask", "vented_loss"})
  /\ active' = UpdateActive({"survivor_mask", "vented_loss"}, {"collapse"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"collapse"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"collapse"})
  /\ active' = UpdateActive({"collapse"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_VENT
  \/ Edge_03_PROCESS
  \/ Edge_04_FOLD
  \/ Edge_05_PROCESS

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
