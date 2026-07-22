------------------------------ MODULE open_source_gnosis_warmup_invert_human_social_entrainment ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"team", "shared_vocab", "rapport", "interruptions", "mistrust", "misalignment", "collaboration"}
ROOTS == {"team"}
TERMINALS == {"collaboration"}
FOLD_TARGETS == {"misalignment"}
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
  /\ active' = UpdateActive({"team"}, {"shared_vocab", "rapport", "interruptions"})
  /\ beta1' = beta1 + (Cardinality({"shared_vocab", "rapport", "interruptions"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shared_vocab", "rapport", "interruptions"} \cap FOLD_TARGETS # {})
Edge_02_INTERFERE ==
  /\ CanFire({"rapport", "interruptions"})
  /\ active' = UpdateActive({"rapport", "interruptions"}, {"mistrust"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"mistrust"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"shared_vocab", "mistrust"})
  /\ active' = UpdateActive({"shared_vocab", "mistrust"}, {"misalignment"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"misalignment"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"misalignment"})
  /\ active' = UpdateActive({"misalignment"}, {"collaboration"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"collaboration"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_INTERFERE
  \/ Edge_03_FOLD
  \/ Edge_04_PROCESS

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
