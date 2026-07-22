------------------------------ MODULE open_source_gnosis_warmup_invert_cache_reuse ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"request", "poisoned_cache", "cold_compute", "validator", "first_reply", "unstable_reply", "final_answer"}
ROOTS == {"request"}
TERMINALS == {"final_answer"}
FOLD_TARGETS == {"final_answer"}
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
  /\ active' = UpdateActive({"request"}, {"poisoned_cache", "cold_compute"})
  /\ beta1' = beta1 + (Cardinality({"poisoned_cache", "cold_compute"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"poisoned_cache", "cold_compute"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"poisoned_cache"})
  /\ active' = UpdateActive({"poisoned_cache"}, {"validator"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"validator"} \cap FOLD_TARGETS # {})
Edge_03_RACE ==
  /\ CanFire({"poisoned_cache", "cold_compute"})
  /\ \E winner \in {"first_reply"}:
      /\ active' = UpdateActive({"poisoned_cache", "cold_compute"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"poisoned_cache", "cold_compute"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_INTERFERE ==
  /\ CanFire({"first_reply", "validator"})
  /\ active' = UpdateActive({"first_reply", "validator"}, {"unstable_reply"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"unstable_reply"} \cap FOLD_TARGETS # {})
Edge_05_FOLD ==
  /\ CanFire({"unstable_reply", "cold_compute"})
  /\ active' = UpdateActive({"unstable_reply", "cold_compute"}, {"final_answer"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"final_answer"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_RACE
  \/ Edge_04_INTERFERE
  \/ Edge_05_FOLD

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
