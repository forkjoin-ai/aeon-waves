------------------------------ MODULE open_source_gnosis_examples_synth_envelope ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"gate", "attack", "decay", "sustain", "release", "silence", "env_out", "env_out: Amplitude"}
ROOTS == {"gate"}
TERMINALS == {"silence", "env_out: Amplitude", "env_out"}
FOLD_TARGETS == {}
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

Edge_01_PROCESS ==
  /\ CanFire({"gate"})
  /\ active' = UpdateActive({"gate"}, {"attack"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attack"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"attack"})
  /\ active' = UpdateActive({"attack"}, {"decay"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"decay"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"decay"})
  /\ active' = UpdateActive({"decay"}, {"sustain"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sustain"} \cap FOLD_TARGETS # {})
Edge_04_VENT ==
  /\ CanFire({"sustain"})
  /\ active' = UpdateActive({"sustain"}, {"release"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"release"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"release"})
  /\ active' = UpdateActive({"release"}, {"silence"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"silence"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"attack"})
  /\ active' = UpdateActive({"attack"}, {"env_out: Amplitude"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"env_out: Amplitude"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"decay"})
  /\ active' = UpdateActive({"decay"}, {"env_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"env_out"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"sustain"})
  /\ active' = UpdateActive({"sustain"}, {"env_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"env_out"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"release"})
  /\ active' = UpdateActive({"release"}, {"env_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"env_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_VENT
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS

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
