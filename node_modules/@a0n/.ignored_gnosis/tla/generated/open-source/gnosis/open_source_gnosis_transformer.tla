------------------------------ MODULE open_source_gnosis_transformer ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"input_sequence", "qkv_projection", "head_1", "head_2", "head_3", "head_4", "ffn", "multi_head_out", "residual_1", "transformer_out"}
ROOTS == {"input_sequence"}
TERMINALS == {"transformer_out"}
FOLD_TARGETS == {"multi_head_out"}
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
  /\ CanFire({"input_sequence"})
  /\ active' = UpdateActive({"input_sequence"}, {"qkv_projection"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"qkv_projection"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"qkv_projection"})
  /\ active' = UpdateActive({"qkv_projection"}, {"head_1", "head_2", "head_3", "head_4"})
  /\ beta1' = beta1 + (Cardinality({"head_1", "head_2", "head_3", "head_4"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_1", "head_2", "head_3", "head_4"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"head_1", "head_2", "head_3", "head_4"})
  /\ active' = UpdateActive({"head_1", "head_2", "head_3", "head_4"}, {"multi_head_out"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"multi_head_out"} \cap FOLD_TARGETS # {})
Edge_04_INTERFERE ==
  /\ CanFire({"input_sequence", "multi_head_out"})
  /\ active' = UpdateActive({"input_sequence", "multi_head_out"}, {"residual_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"residual_1"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"residual_1"})
  /\ active' = UpdateActive({"residual_1"}, {"ffn"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ffn"} \cap FOLD_TARGETS # {})
Edge_06_INTERFERE ==
  /\ CanFire({"residual_1", "ffn"})
  /\ active' = UpdateActive({"residual_1", "ffn"}, {"transformer_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"transformer_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FOLD
  \/ Edge_04_INTERFERE
  \/ Edge_05_PROCESS
  \/ Edge_06_INTERFERE

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
