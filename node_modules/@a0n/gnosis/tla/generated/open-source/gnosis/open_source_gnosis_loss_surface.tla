------------------------------ MODULE open_source_gnosis_loss_surface ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "prediction", "target", "loss", "sink"}
ROOTS == {"seed"}
TERMINALS == {"sink"}
FOLD_TARGETS == {"loss"}
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
  /\ CanFire({"seed"})
  /\ active' = UpdateActive({"seed"}, {"prediction", "target"})
  /\ beta1' = beta1 + (Cardinality({"prediction", "target"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"prediction", "target"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"prediction", "target"})
  /\ active' = UpdateActive({"prediction", "target"}, {"loss"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"loss"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"loss"})
  /\ active' = UpdateActive({"loss"}, {"sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_PROCESS

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
