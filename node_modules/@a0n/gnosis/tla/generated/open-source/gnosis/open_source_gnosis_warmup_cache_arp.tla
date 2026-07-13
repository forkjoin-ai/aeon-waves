------------------------------ MODULE open_source_gnosis_warmup_cache_arp ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"input", "fast_path", "slow_path", "chosen_path", "result"}
ROOTS == {"input"}
TERMINALS == {"result"}
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
  /\ CanFire({"input"})
  /\ active' = UpdateActive({"input"}, {"fast_path", "slow_path"})
  /\ beta1' = beta1 + (Cardinality({"fast_path", "slow_path"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_path", "slow_path"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"fast_path", "slow_path"})
  /\ \E winner \in {"chosen_path"}:
      /\ active' = UpdateActive({"fast_path", "slow_path"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"fast_path", "slow_path"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_03_PROCESS ==
  /\ CanFire({"chosen_path"})
  /\ active' = UpdateActive({"chosen_path"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE
  \/ Edge_03_PROCESS

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
