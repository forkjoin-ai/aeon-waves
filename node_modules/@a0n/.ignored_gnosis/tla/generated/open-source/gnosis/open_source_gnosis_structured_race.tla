------------------------------ MODULE open_source_gnosis_structured_race ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "sink", "seed:Scalar { value: \"0\" }", "fast:Delay { ms: \"1\", emit: \"fast-path\" }", "slow:Delay { ms: \"25\", emit: \"slow-path\" }", "fast", "slow", "sink:Sink"}
ROOTS == {"seed:Scalar { value: \"0\" }", "fast", "slow"}
TERMINALS == {"fast:Delay { ms: \"1\", emit: \"fast-path\" }", "slow:Delay { ms: \"25\", emit: \"slow-path\" }", "sink:Sink"}
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

Edge_01_FORK ==
  /\ CanFire({"seed:Scalar { value: \"0\" }"})
  /\ active' = UpdateActive({"seed:Scalar { value: \"0\" }"}, {"fast:Delay { ms: \"1\", emit: \"fast-path\" }", "slow:Delay { ms: \"25\", emit: \"slow-path\" }"})
  /\ beta1' = beta1 + (Cardinality({"fast:Delay { ms: \"1\", emit: \"fast-path\" }", "slow:Delay { ms: \"25\", emit: \"slow-path\" }"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast:Delay { ms: \"1\", emit: \"fast-path\" }", "slow:Delay { ms: \"25\", emit: \"slow-path\" }"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"fast", "slow"})
  /\ \E winner \in {"sink:Sink"}:
      /\ active' = UpdateActive({"fast", "slow"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"fast", "slow"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE

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
