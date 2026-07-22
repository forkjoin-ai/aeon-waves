------------------------------ MODULE open_source_gnosis_examples_synth_lfo ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"lfo_rate", "lfo_depth", "lfo_shape", "lfo_phase", "lfo_scale", "lfo_out", "lfo_scale: Multiply"}
ROOTS == {"lfo_rate", "lfo_depth"}
TERMINALS == {"lfo_scale: Multiply", "lfo_out"}
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
  /\ CanFire({"lfo_rate"})
  /\ active' = UpdateActive({"lfo_rate"}, {"lfo_phase"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lfo_phase"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"lfo_phase"})
  /\ active' = UpdateActive({"lfo_phase"}, {"lfo_shape"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lfo_shape"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"lfo_shape"})
  /\ active' = UpdateActive({"lfo_shape"}, {"lfo_scale: Multiply"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lfo_scale: Multiply"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"lfo_depth"})
  /\ active' = UpdateActive({"lfo_depth"}, {"lfo_scale"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lfo_scale"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"lfo_scale"})
  /\ active' = UpdateActive({"lfo_scale"}, {"lfo_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"lfo_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
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
