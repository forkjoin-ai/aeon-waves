------------------------------ MODULE open_source_gnosis_examples_transformer_kv_cache ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"new_token", "cached_keys", "cached_values", "fresh_key", "fresh_value", "full_keys", "full_values", "query", "attn", "kv_out", "fresh_key: Projection { role: 'K' }", "fresh_value: Projection { role: 'V' }", "query: Projection { role: 'Q' }", "attn: ScaledDotProduct { causal: 'true' }"}
ROOTS == {"new_token", "cached_keys", "fresh_key", "cached_values", "fresh_value", "query"}
TERMINALS == {"fresh_key: Projection { role: 'K' }", "fresh_value: Projection { role: 'V' }", "query: Projection { role: 'Q' }", "attn: ScaledDotProduct { causal: 'true' }", "kv_out"}
FOLD_TARGETS == {"full_keys", "full_values"}
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
  /\ CanFire({"new_token"})
  /\ active' = UpdateActive({"new_token"}, {"fresh_key: Projection { role: 'K' }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fresh_key: Projection { role: 'K' }"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"new_token"})
  /\ active' = UpdateActive({"new_token"}, {"fresh_value: Projection { role: 'V' }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fresh_value: Projection { role: 'V' }"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"cached_keys", "fresh_key"})
  /\ active' = UpdateActive({"cached_keys", "fresh_key"}, {"full_keys"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"full_keys"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"cached_values", "fresh_value"})
  /\ active' = UpdateActive({"cached_values", "fresh_value"}, {"full_values"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"full_values"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"new_token"})
  /\ active' = UpdateActive({"new_token"}, {"query: Projection { role: 'Q' }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"query: Projection { role: 'Q' }"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"query"})
  /\ active' = UpdateActive({"query"}, {"attn: ScaledDotProduct { causal: 'true' }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attn: ScaledDotProduct { causal: 'true' }"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"full_keys"})
  /\ active' = UpdateActive({"full_keys"}, {"attn"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attn"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"full_values"})
  /\ active' = UpdateActive({"full_values"}, {"attn"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"attn"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"attn"})
  /\ active' = UpdateActive({"attn"}, {"kv_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"kv_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_FOLD
  \/ Edge_04_FOLD
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS

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
