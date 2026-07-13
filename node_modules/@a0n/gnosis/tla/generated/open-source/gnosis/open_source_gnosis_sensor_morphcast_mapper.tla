------------------------------ MODULE open_source_gnosis_sensor_morphcast_mapper ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"camera_feed", "morphcast_engine", "emotion_vector", "camera_feed: Video", "morphcast_engine: WebAssembly", "emotion_vector: CVM"}
ROOTS == {"camera_feed: Video"}
TERMINALS == {"emotion_vector: CVM"}
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
  /\ CanFire({"camera_feed: Video"})
  /\ active' = UpdateActive({"camera_feed: Video"}, {"morphcast_engine: WebAssembly"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"morphcast_engine: WebAssembly"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"morphcast_engine: WebAssembly"})
  /\ active' = UpdateActive({"morphcast_engine: WebAssembly"}, {"emotion_vector: CVM"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"emotion_vector: CVM"} \cap FOLD_TARGETS # {})

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
