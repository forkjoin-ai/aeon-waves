------------------------------ MODULE open_source_gnosis_aic_emotional_trigger ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"user_input", "trigger_dictionary", "arousal_spike", "user_input: Text", "trigger_dictionary: DB", "arousal_spike: Alert"}
ROOTS == {"user_input: Text"}
TERMINALS == {"arousal_spike: Alert"}
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
  /\ CanFire({"user_input: Text"})
  /\ active' = UpdateActive({"user_input: Text"}, {"trigger_dictionary: DB"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"trigger_dictionary: DB"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"trigger_dictionary: DB"})
  /\ active' = UpdateActive({"trigger_dictionary: DB"}, {"arousal_spike: Alert"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"arousal_spike: Alert"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS

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
