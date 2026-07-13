------------------------------ MODULE open_source_gnosis_warmup_cache_reuse ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request", "index_lookup", "cold_compute", "cache_write", "candidate", "answer", "candidate: Candidate", "answer: Result"}
ROOTS == {"request", "candidate"}
TERMINALS == {"candidate: Candidate", "answer: Result"}
FOLD_TARGETS == {"answer: Result"}
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
  /\ CanFire({"request"})
  /\ active' = UpdateActive({"request"}, {"index_lookup", "cold_compute"})
  /\ beta1' = beta1 + (Cardinality({"index_lookup", "cold_compute"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"index_lookup", "cold_compute"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"index_lookup", "cold_compute"})
  /\ \E winner \in {"candidate: Candidate"}:
      /\ active' = UpdateActive({"index_lookup", "cold_compute"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"index_lookup", "cold_compute"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_03_PROCESS ==
  /\ CanFire({"cold_compute"})
  /\ active' = UpdateActive({"cold_compute"}, {"cache_write"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cache_write"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"candidate", "cache_write"})
  /\ active' = UpdateActive({"candidate", "cache_write"}, {"answer: Result"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"answer: Result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE
  \/ Edge_03_PROCESS
  \/ Edge_04_FOLD

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
