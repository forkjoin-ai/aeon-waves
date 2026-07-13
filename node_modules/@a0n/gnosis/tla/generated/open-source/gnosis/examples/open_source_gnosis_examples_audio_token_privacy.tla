------------------------------ MODULE open_source_gnosis_examples_audio_token_privacy ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"raw_mic", "local_patcher", "moss_tokenizer", "semantic_stream", "prosody_stream", "identity_stream", "identity_noise", "public_identity", "public_mesh"}
ROOTS == {"raw_mic"}
TERMINALS == {"public_mesh"}
FOLD_TARGETS == {"public_mesh"}
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
  /\ CanFire({"raw_mic"})
  /\ active' = UpdateActive({"raw_mic"}, {"local_patcher"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"local_patcher"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"local_patcher"})
  /\ active' = UpdateActive({"local_patcher"}, {"moss_tokenizer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"moss_tokenizer"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"moss_tokenizer"})
  /\ active' = UpdateActive({"moss_tokenizer"}, {"semantic_stream", "prosody_stream", "identity_stream"})
  /\ beta1' = beta1 + (Cardinality({"semantic_stream", "prosody_stream", "identity_stream"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"semantic_stream", "prosody_stream", "identity_stream"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"identity_stream"})
  /\ active' = UpdateActive({"identity_stream"}, {"identity_noise"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"identity_noise"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"identity_noise"})
  /\ active' = UpdateActive({"identity_noise"}, {"public_identity"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"public_identity"} \cap FOLD_TARGETS # {})
Edge_06_FOLD ==
  /\ CanFire({"semantic_stream", "prosody_stream", "public_identity"})
  /\ active' = UpdateActive({"semantic_stream", "prosody_stream", "public_identity"}, {"public_mesh"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"public_mesh"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_FORK
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_FOLD

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
