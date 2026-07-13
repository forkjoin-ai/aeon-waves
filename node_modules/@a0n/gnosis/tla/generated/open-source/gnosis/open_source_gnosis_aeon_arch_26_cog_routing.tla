------------------------------ MODULE open_source_gnosis_aeon_arch_26_cog_routing ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query", "answer", "query: Text", "fast_lane: SmallLLM", "slow_lane: LargeLLM", "fast_lane", "slow_lane", "answer: Text"}
ROOTS == {"query: Text", "fast_lane", "slow_lane"}
TERMINALS == {"fast_lane: SmallLLM", "slow_lane: LargeLLM", "answer: Text"}
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
  /\ CanFire({"query: Text"})
  /\ active' = UpdateActive({"query: Text"}, {"fast_lane: SmallLLM", "slow_lane: LargeLLM"})
  /\ beta1' = beta1 + (Cardinality({"fast_lane: SmallLLM", "slow_lane: LargeLLM"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_lane: SmallLLM", "slow_lane: LargeLLM"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"fast_lane", "slow_lane"})
  /\ \E winner \in {"answer: Text"}:
      /\ active' = UpdateActive({"fast_lane", "slow_lane"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"fast_lane", "slow_lane"}) - 1))
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
