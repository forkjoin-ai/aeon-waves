------------------------------ MODULE open_source_gnosis_examples_synth_oscillator ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"freq", "phase", "sine", "saw", "square", "triangle", "osc_out"}
ROOTS == {"freq"}
TERMINALS == {"osc_out"}
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
  /\ CanFire({"freq"})
  /\ active' = UpdateActive({"freq"}, {"phase"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"phase"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"phase"})
  /\ active' = UpdateActive({"phase"}, {"sine", "saw", "square", "triangle"})
  /\ beta1' = beta1 + (Cardinality({"sine", "saw", "square", "triangle"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sine", "saw", "square", "triangle"} \cap FOLD_TARGETS # {})
Edge_03_INTERFERE ==
  /\ CanFire({"sine", "saw", "square", "triangle"})
  /\ active' = UpdateActive({"sine", "saw", "square", "triangle"}, {"osc_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"osc_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_INTERFERE

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
