------------------------------ MODULE open_source_gnosis_audio_vad_chunker ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"mic_stream", "vad_gate", "buffer", "stt_engine", "mic_stream: Audio", "vad_gate: Filter", "buffer: Memory", "stt_engine: Speech"}
ROOTS == {"mic_stream: Audio"}
TERMINALS == {"stt_engine: Speech"}
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
  /\ CanFire({"mic_stream: Audio"})
  /\ active' = UpdateActive({"mic_stream: Audio"}, {"vad_gate: Filter"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"vad_gate: Filter"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"vad_gate: Filter"})
  /\ active' = UpdateActive({"vad_gate: Filter"}, {"buffer: Memory"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"buffer: Memory"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"buffer: Memory"})
  /\ active' = UpdateActive({"buffer: Memory"}, {"stt_engine: Speech"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"stt_engine: Speech"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS

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
