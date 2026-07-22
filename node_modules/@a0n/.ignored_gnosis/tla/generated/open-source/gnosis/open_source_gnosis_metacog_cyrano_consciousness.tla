------------------------------ MODULE open_source_gnosis_metacog_cyrano_consciousness ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"user_action", "agent_growth", "user_action: Event", "self_evaluator: Logic", "user_feedback: Logic", "self_evaluator", "user_feedback", "agent_growth: State"}
ROOTS == {"user_action: Event", "self_evaluator", "user_feedback"}
TERMINALS == {"self_evaluator: Logic", "user_feedback: Logic", "agent_growth: State"}
FOLD_TARGETS == {"agent_growth: State"}
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
  /\ CanFire({"user_action: Event"})
  /\ active' = UpdateActive({"user_action: Event"}, {"self_evaluator: Logic", "user_feedback: Logic"})
  /\ beta1' = beta1 + (Cardinality({"self_evaluator: Logic", "user_feedback: Logic"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"self_evaluator: Logic", "user_feedback: Logic"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"self_evaluator", "user_feedback"})
  /\ active' = UpdateActive({"self_evaluator", "user_feedback"}, {"agent_growth: State"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"agent_growth: State"} \cap FOLD_TARGETS # {})

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
