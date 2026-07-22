------------------------------ MODULE open_source_gnosis_example ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"raw_codec", "brotli_codec", "input", "winner"}
ROOTS == {"input"}
TERMINALS == {"winner"}
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
  /\ CanFire({"input"})
  /\ active' = UpdateActive({"input"}, {"raw_codec", "brotli_codec"})
  /\ beta1' = beta1 + (Cardinality({"raw_codec", "brotli_codec"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"raw_codec", "brotli_codec"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"raw_codec", "brotli_codec"})
  /\ \E winner \in {"winner"}:
      /\ active' = UpdateActive({"raw_codec", "brotli_codec"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"raw_codec", "brotli_codec"}) - 1))
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
