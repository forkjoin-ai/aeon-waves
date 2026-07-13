------------------------------ MODULE open_source_gnosis_warmup_human_social_entrainment ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"team", "shared_vocab", "rapport", "turn_taking", "alignment", "collaboration", "collaboration: Outcome"}
ROOTS == {"team"}
TERMINALS == {"collaboration: Outcome"}
FOLD_TARGETS == {"alignment"}
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
  /\ CanFire({"team"})
  /\ active' = UpdateActive({"team"}, {"shared_vocab", "rapport", "turn_taking"})
  /\ beta1' = beta1 + (Cardinality({"shared_vocab", "rapport", "turn_taking"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shared_vocab", "rapport", "turn_taking"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"shared_vocab", "rapport", "turn_taking"})
  /\ active' = UpdateActive({"shared_vocab", "rapport", "turn_taking"}, {"alignment"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"alignment"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"alignment"})
  /\ active' = UpdateActive({"alignment"}, {"collaboration: Outcome"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"collaboration: Outcome"} \cap FOLD_TARGETS # {})

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
