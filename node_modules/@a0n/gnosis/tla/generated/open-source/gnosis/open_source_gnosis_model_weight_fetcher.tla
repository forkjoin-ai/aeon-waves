------------------------------ MODULE open_source_gnosis_model_weight_fetcher ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request_model", "weights", "request_model: Intent", "local_cache: FS", "huggingface: API", "r2_bucket: Storage", "local_cache", "huggingface", "r2_bucket", "weights: Tensor"}
ROOTS == {"request_model: Intent", "local_cache", "huggingface", "r2_bucket"}
TERMINALS == {"local_cache: FS", "huggingface: API", "r2_bucket: Storage", "weights: Tensor"}
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

Edge_01_FORK ==
  /\ CanFire({"request_model: Intent"})
  /\ active' = UpdateActive({"request_model: Intent"}, {"local_cache: FS", "huggingface: API", "r2_bucket: Storage"})
  /\ beta1' = beta1 + (Cardinality({"local_cache: FS", "huggingface: API", "r2_bucket: Storage"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"local_cache: FS", "huggingface: API", "r2_bucket: Storage"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"local_cache", "huggingface", "r2_bucket"})
  /\ \E winner \in {"weights: Tensor"}:
      /\ active' = UpdateActive({"local_cache", "huggingface", "r2_bucket"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"local_cache", "huggingface", "r2_bucket"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE

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
