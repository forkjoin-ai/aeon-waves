------------------------------ MODULE open_source_gnosis_examples_transformer_attention ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query", "key", "value", "input", "head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7", "concat_heads", "output_projection", "attention_out", "input: Tensor"}
ROOTS == {"input: Tensor"}
TERMINALS == {"attention_out"}
FOLD_TARGETS == {"concat_heads"}
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
  /\ CanFire({"input: Tensor"})
  /\ active' = UpdateActive({"input: Tensor"}, {"query", "key", "value"})
  /\ beta1' = beta1 + (Cardinality({"query", "key", "value"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"query", "key", "value"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"query"})
  /\ active' = UpdateActive({"query"}, {"head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7"})
  /\ beta1' = beta1 + (Cardinality({"head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_0"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_0"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_1"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_2"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_2"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_3"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_3"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_4"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_4"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_5"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_5"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_6"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_6"} \cap FOLD_TARGETS # {})
Edge_10_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_7"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_7"} \cap FOLD_TARGETS # {})
Edge_11_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_0"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_0"} \cap FOLD_TARGETS # {})
Edge_12_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_1"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_1"} \cap FOLD_TARGETS # {})
Edge_13_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_2"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_2"} \cap FOLD_TARGETS # {})
Edge_14_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_3"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_3"} \cap FOLD_TARGETS # {})
Edge_15_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_4"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_4"} \cap FOLD_TARGETS # {})
Edge_16_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_5"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_5"} \cap FOLD_TARGETS # {})
Edge_17_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_6"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_6"} \cap FOLD_TARGETS # {})
Edge_18_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_7"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_7"} \cap FOLD_TARGETS # {})
Edge_19_FOLD ==
  /\ CanFire({"head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7"})
  /\ active' = UpdateActive({"head_0", "head_1", "head_2", "head_3", "head_4", "head_5", "head_6", "head_7"}, {"concat_heads"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"concat_heads"} \cap FOLD_TARGETS # {})
Edge_20_PROCESS ==
  /\ CanFire({"concat_heads"})
  /\ active' = UpdateActive({"concat_heads"}, {"output_projection"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"output_projection"} \cap FOLD_TARGETS # {})
Edge_21_PROCESS ==
  /\ CanFire({"output_projection"})
  /\ active' = UpdateActive({"output_projection"}, {"attention_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attention_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FORK
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS
  \/ Edge_10_PROCESS
  \/ Edge_11_PROCESS
  \/ Edge_12_PROCESS
  \/ Edge_13_PROCESS
  \/ Edge_14_PROCESS
  \/ Edge_15_PROCESS
  \/ Edge_16_PROCESS
  \/ Edge_17_PROCESS
  \/ Edge_18_PROCESS
  \/ Edge_19_FOLD
  \/ Edge_20_PROCESS
  \/ Edge_21_PROCESS

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
