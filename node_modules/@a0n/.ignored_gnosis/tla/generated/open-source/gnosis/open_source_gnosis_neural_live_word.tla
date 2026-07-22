------------------------------ MODULE open_source_gnosis_neural_live_word ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"audio_stream", "live_word_model", "transcript", "audio_stream: Buffer", "live_word_model: WebGPU", "transcript: Text"}
ROOTS == {"audio_stream: Buffer"}
TERMINALS == {"transcript: Text"}
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
  /\ CanFire({"audio_stream: Buffer"})
  /\ active' = UpdateActive({"audio_stream: Buffer"}, {"live_word_model: WebGPU"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"live_word_model: WebGPU"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"live_word_model: WebGPU"})
  /\ active' = UpdateActive({"live_word_model: WebGPU"}, {"transcript: Text"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"transcript: Text"} \cap FOLD_TARGETS # {})

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
