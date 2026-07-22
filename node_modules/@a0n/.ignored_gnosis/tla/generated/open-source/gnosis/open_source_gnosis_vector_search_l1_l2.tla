------------------------------ MODULE open_source_gnosis_vector_search_l1_l2 ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"query", "results", "query: Vector", "l1_memory: Search", "l2_disk: Search", "l1_memory", "l2_disk", "results: Matches"}
ROOTS == {"query: Vector", "l1_memory", "l2_disk"}
TERMINALS == {"l1_memory: Search", "l2_disk: Search", "results: Matches"}
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
  /\ CanFire({"query: Vector"})
  /\ active' = UpdateActive({"query: Vector"}, {"l1_memory: Search", "l2_disk: Search"})
  /\ beta1' = beta1 + (Cardinality({"l1_memory: Search", "l2_disk: Search"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"l1_memory: Search", "l2_disk: Search"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"l1_memory", "l2_disk"})
  /\ \E winner \in {"results: Matches"}:
      /\ active' = UpdateActive({"l1_memory", "l2_disk"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"l1_memory", "l2_disk"}) - 1))
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
