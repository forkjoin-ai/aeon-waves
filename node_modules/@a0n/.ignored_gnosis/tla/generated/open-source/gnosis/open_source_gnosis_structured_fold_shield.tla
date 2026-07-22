------------------------------ MODULE open_source_gnosis_structured_fold_shield ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "sink", "seed:Scalar { value: \"0\" }", "ready:Delay { ms: \"1\", emit: \"ready-path\" }", "stalled:Delay { ms: \"25\", emit: \"late-path\" }", "ready", "stalled", "sink:Sink"}
ROOTS == {"seed:Scalar { value: \"0\" }", "ready", "stalled"}
TERMINALS == {"ready:Delay { ms: \"1\", emit: \"ready-path\" }", "stalled:Delay { ms: \"25\", emit: \"late-path\" }", "sink:Sink"}
FOLD_TARGETS == {"sink:Sink"}
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
  /\ CanFire({"seed:Scalar { value: \"0\" }"})
  /\ active' = UpdateActive({"seed:Scalar { value: \"0\" }"}, {"ready:Delay { ms: \"1\", emit: \"ready-path\" }", "stalled:Delay { ms: \"25\", emit: \"late-path\" }"})
  /\ beta1' = beta1 + (Cardinality({"ready:Delay { ms: \"1\", emit: \"ready-path\" }", "stalled:Delay { ms: \"25\", emit: \"late-path\" }"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ready:Delay { ms: \"1\", emit: \"ready-path\" }", "stalled:Delay { ms: \"25\", emit: \"late-path\" }"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"ready", "stalled"})
  /\ active' = UpdateActive({"ready", "stalled"}, {"sink:Sink"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink:Sink"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

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
