------------------------------ MODULE open_source_gnosis_hologram_service ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"user_utterance", "nlp_parse", "generate_hologram_response", "user_utterance: Text", "nlp_parse: NLP", "generate_hologram_response: AI"}
ROOTS == {"user_utterance: Text"}
TERMINALS == {"generate_hologram_response: AI"}
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
  /\ CanFire({"user_utterance: Text"})
  /\ active' = UpdateActive({"user_utterance: Text"}, {"nlp_parse: NLP"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"nlp_parse: NLP"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"nlp_parse: NLP"})
  /\ active' = UpdateActive({"nlp_parse: NLP"}, {"generate_hologram_response: AI"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"generate_hologram_response: AI"} \cap FOLD_TARGETS # {})

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
