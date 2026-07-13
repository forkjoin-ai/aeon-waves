------------------------------ MODULE open_source_gnosis_gradient_step ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "param", "grad", "update", "sink"}
ROOTS == {"seed"}
TERMINALS == {"sink"}
FOLD_TARGETS == {"update"}
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
  /\ active' = UpdateActive({"seed"}, {"param", "grad"})
  /\ beta1' = beta1 + (Cardinality({"param", "grad"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"param", "grad"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"param", "grad"})
  /\ active' = UpdateActive({"param", "grad"}, {"update"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"update"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"update"})
  /\ active' = UpdateActive({"update"}, {"sink"})
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
