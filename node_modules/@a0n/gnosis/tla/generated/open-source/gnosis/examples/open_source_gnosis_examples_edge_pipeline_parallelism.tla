------------------------------ MODULE open_source_gnosis_examples_edge_pipeline_parallelism ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request_in", "coordinator", "tokenizer", "shard_a", "hidden_state", "shard_b_primary", "shard_b_standby", "logits", "response_out"}
ROOTS == {"request_in"}
TERMINALS == {"response_out"}
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
  /\ CanFire({"request_in"})
  /\ active' = UpdateActive({"request_in"}, {"coordinator"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"coordinator"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"coordinator"})
  /\ active' = UpdateActive({"coordinator"}, {"tokenizer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"tokenizer"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"tokenizer"})
  /\ active' = UpdateActive({"tokenizer"}, {"shard_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shard_a"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"shard_a"})
  /\ active' = UpdateActive({"shard_a"}, {"hidden_state"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"hidden_state"} \cap FOLD_TARGETS # {})
Edge_05_FORK ==
  /\ CanFire({"hidden_state"})
  /\ active' = UpdateActive({"hidden_state"}, {"shard_b_primary", "shard_b_standby"})
  /\ beta1' = beta1 + (Cardinality({"shard_b_primary", "shard_b_standby"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shard_b_primary", "shard_b_standby"} \cap FOLD_TARGETS # {})
Edge_06_RACE ==
  /\ CanFire({"shard_b_primary", "shard_b_standby"})
  /\ \E winner \in {"logits"}:
      /\ active' = UpdateActive({"shard_b_primary", "shard_b_standby"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"shard_b_primary", "shard_b_standby"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_PROCESS ==
  /\ CanFire({"logits"})
  /\ active' = UpdateActive({"logits"}, {"response_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"response_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_FORK
  \/ Edge_06_RACE
  \/ Edge_07_PROCESS

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
