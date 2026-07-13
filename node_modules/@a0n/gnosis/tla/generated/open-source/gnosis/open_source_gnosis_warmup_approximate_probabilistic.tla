------------------------------ MODULE open_source_gnosis_warmup_approximate_probabilistic ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query", "sketch_gate", "definite_miss", "maybe_hit", "exact_lookup", "answer", "wasted_scan"}
ROOTS == {"query"}
TERMINALS == {"wasted_scan", "answer"}
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
  /\ CanFire({"query"})
  /\ active' = UpdateActive({"query"}, {"sketch_gate"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sketch_gate"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"sketch_gate"})
  /\ active' = UpdateActive({"sketch_gate"}, {"definite_miss", "maybe_hit"})
  /\ beta1' = beta1 + (Cardinality({"definite_miss", "maybe_hit"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"definite_miss", "maybe_hit"} \cap FOLD_TARGETS # {})
Edge_03_VENT ==
  /\ CanFire({"definite_miss"})
  /\ active' = UpdateActive({"definite_miss"}, {"wasted_scan"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wasted_scan"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"maybe_hit"})
  /\ active' = UpdateActive({"maybe_hit"}, {"exact_lookup"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"exact_lookup"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"definite_miss", "exact_lookup"})
  /\ \E winner \in {"answer"}:
      /\ active' = UpdateActive({"definite_miss", "exact_lookup"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"definite_miss", "exact_lookup"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_VENT
  \/ Edge_04_PROCESS
  \/ Edge_05_RACE

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
