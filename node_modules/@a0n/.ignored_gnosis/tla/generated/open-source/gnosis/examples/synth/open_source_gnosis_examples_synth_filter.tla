------------------------------ MODULE open_source_gnosis_examples_synth_filter ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"filter_input", "cutoff", "resonance", "integrator_1", "integrator_2", "lowpass", "highpass", "bandpass", "filter_out"}
ROOTS == {"filter_input", "cutoff", "resonance"}
TERMINALS == {"filter_out"}
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
  /\ CanFire({"filter_input"})
  /\ active' = UpdateActive({"filter_input"}, {"integrator_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"integrator_1"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"cutoff"})
  /\ active' = UpdateActive({"cutoff"}, {"integrator_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"integrator_1"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"resonance"})
  /\ active' = UpdateActive({"resonance"}, {"integrator_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"integrator_1"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"integrator_1"})
  /\ active' = UpdateActive({"integrator_1"}, {"integrator_2"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"integrator_2"} \cap FOLD_TARGETS # {})
Edge_05_FORK ==
  /\ CanFire({"integrator_2"})
  /\ active' = UpdateActive({"integrator_2"}, {"lowpass", "highpass", "bandpass"})
  /\ beta1' = beta1 + (Cardinality({"lowpass", "highpass", "bandpass"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lowpass", "highpass", "bandpass"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"lowpass", "highpass", "bandpass"})
  /\ \E winner \in {"filter_out"}:
      /\ active' = UpdateActive({"lowpass", "highpass", "bandpass"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"lowpass", "highpass", "bandpass"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_FORK
  \/ Edge_06_RACE

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
