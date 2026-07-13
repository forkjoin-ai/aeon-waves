------------------------------ MODULE open_source_gnosis_warmup_invert_cache_dns ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"input", "fast_path", "slow_path", "poison_event", "chosen_path", "fallback", "result"}
ROOTS == {"input"}
TERMINALS == {"result"}
FOLD_TARGETS == {"fallback"}
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
  /\ active' = UpdateActive({"input"}, {"fast_path", "slow_path", "poison_event"})
  /\ beta1' = beta1 + (Cardinality({"fast_path", "slow_path", "poison_event"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_path", "slow_path", "poison_event"} \cap FOLD_TARGETS # {})
Edge_02_INTERFERE ==
  /\ CanFire({"poison_event"})
  /\ active' = UpdateActive({"poison_event"}, {"fast_path"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fast_path"} \cap FOLD_TARGETS # {})
Edge_03_RACE ==
  /\ CanFire({"fast_path", "slow_path"})
  /\ \E winner \in {"chosen_path"}:
      /\ active' = UpdateActive({"fast_path", "slow_path"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"fast_path", "slow_path"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_FOLD ==
  /\ CanFire({"chosen_path", "poison_event"})
  /\ active' = UpdateActive({"chosen_path", "poison_event"}, {"fallback"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fallback"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"fallback"})
  /\ active' = UpdateActive({"fallback"}, {"result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_INTERFERE
  \/ Edge_03_RACE
  \/ Edge_04_FOLD
  \/ Edge_05_PROCESS

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
