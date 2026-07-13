------------------------------ MODULE open_source_gnosis_aeon_arch_28_emo_resonance ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"input", "affect_state", "input: Multimodal", "facial_cvm: Vision", "vocal_prosody: Audio", "semantic_text: NLP", "facial_cvm", "vocal_prosody", "semantic_text", "affect_state: State"}
ROOTS == {"input: Multimodal", "facial_cvm", "vocal_prosody", "semantic_text"}
TERMINALS == {"facial_cvm: Vision", "vocal_prosody: Audio", "semantic_text: NLP", "affect_state: State"}
FOLD_TARGETS == {"affect_state: State"}
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
  /\ CanFire({"input: Multimodal"})
  /\ active' = UpdateActive({"input: Multimodal"}, {"facial_cvm: Vision", "vocal_prosody: Audio", "semantic_text: NLP"})
  /\ beta1' = beta1 + (Cardinality({"facial_cvm: Vision", "vocal_prosody: Audio", "semantic_text: NLP"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"facial_cvm: Vision", "vocal_prosody: Audio", "semantic_text: NLP"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"facial_cvm", "vocal_prosody", "semantic_text"})
  /\ active' = UpdateActive({"facial_cvm", "vocal_prosody", "semantic_text"}, {"affect_state: State"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"affect_state: State"} \cap FOLD_TARGETS # {})

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
