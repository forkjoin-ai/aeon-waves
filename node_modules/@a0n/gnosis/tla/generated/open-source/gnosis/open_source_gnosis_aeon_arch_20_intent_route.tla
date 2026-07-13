------------------------------ MODULE open_source_gnosis_aeon_arch_20_intent_route ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"user_msg", "classifier", "execution", "user_msg: Text", "classifier: LLM", "tool_a: Action", "tool_b: Action", "fallback: Action", "tool_a", "tool_b", "fallback", "execution: Route"}
ROOTS == {"user_msg: Text", "tool_a", "tool_b", "fallback"}
TERMINALS == {"tool_a: Action", "tool_b: Action", "fallback: Action", "execution: Route"}
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
  /\ CanFire({"user_msg: Text"})
  /\ active' = UpdateActive({"user_msg: Text"}, {"classifier: LLM"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"classifier: LLM"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"classifier: LLM"})
  /\ active' = UpdateActive({"classifier: LLM"}, {"tool_a: Action", "tool_b: Action", "fallback: Action"})
  /\ beta1' = beta1 + (Cardinality({"tool_a: Action", "tool_b: Action", "fallback: Action"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"tool_a: Action", "tool_b: Action", "fallback: Action"} \cap FOLD_TARGETS # {})
Edge_03_RACE ==
  /\ CanFire({"tool_a", "tool_b", "fallback"})
  /\ \E winner \in {"execution: Route"}:
      /\ active' = UpdateActive({"tool_a", "tool_b", "fallback"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"tool_a", "tool_b", "fallback"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_RACE

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
