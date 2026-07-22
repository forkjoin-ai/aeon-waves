------------------------------ MODULE open_source_gnosis_topic_domain_transformer ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"topic_tokens", "topic_embedding", "query", "key", "value", "head_a", "head_b", "head_c", "head_d", "attention_mix", "topic_state", "topic_logits", "topic_distribution"}
ROOTS == {"topic_tokens"}
TERMINALS == {"topic_distribution"}
FOLD_TARGETS == {"attention_mix"}
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
  /\ CanFire({"topic_tokens"})
  /\ active' = UpdateActive({"topic_tokens"}, {"topic_embedding"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"topic_embedding"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"topic_embedding"})
  /\ active' = UpdateActive({"topic_embedding"}, {"query", "key", "value"})
  /\ beta1' = beta1 + (Cardinality({"query", "key", "value"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"query", "key", "value"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"query"})
  /\ active' = UpdateActive({"query"}, {"head_a", "head_b", "head_c", "head_d"})
  /\ beta1' = beta1 + (Cardinality({"head_a", "head_b", "head_c", "head_d"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_a", "head_b", "head_c", "head_d"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_a"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_b"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_b"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_c"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_c"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"key"})
  /\ active' = UpdateActive({"key"}, {"head_d"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_d"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_a"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_b"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_b"} \cap FOLD_TARGETS # {})
Edge_10_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_c"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_c"} \cap FOLD_TARGETS # {})
Edge_11_PROCESS ==
  /\ CanFire({"value"})
  /\ active' = UpdateActive({"value"}, {"head_d"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head_d"} \cap FOLD_TARGETS # {})
Edge_12_FOLD ==
  /\ CanFire({"head_a", "head_b", "head_c", "head_d"})
  /\ active' = UpdateActive({"head_a", "head_b", "head_c", "head_d"}, {"attention_mix"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attention_mix"} \cap FOLD_TARGETS # {})
Edge_13_INTERFERE ==
  /\ CanFire({"attention_mix", "topic_embedding"})
  /\ active' = UpdateActive({"attention_mix", "topic_embedding"}, {"topic_state"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"topic_state"} \cap FOLD_TARGETS # {})
Edge_14_PROCESS ==
  /\ CanFire({"topic_state"})
  /\ active' = UpdateActive({"topic_state"}, {"topic_logits"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"topic_logits"} \cap FOLD_TARGETS # {})
Edge_15_PROCESS ==
  /\ CanFire({"topic_logits"})
  /\ active' = UpdateActive({"topic_logits"}, {"topic_distribution"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"topic_distribution"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FORK
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS
  \/ Edge_10_PROCESS
  \/ Edge_11_PROCESS
  \/ Edge_12_FOLD
  \/ Edge_13_INTERFERE
  \/ Edge_14_PROCESS
  \/ Edge_15_PROCESS

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
