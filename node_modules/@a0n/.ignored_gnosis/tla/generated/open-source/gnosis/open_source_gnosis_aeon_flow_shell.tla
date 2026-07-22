------------------------------ MODULE open_source_gnosis_aeon_flow_shell ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"process_state", "reality_fork_1", "reality_fork_2", "device_1", "device_2", "scored_branch_1", "scored_branch_2", "wisdom_extraction"}
ROOTS == {"process_state", "device_1", "device_2"}
TERMINALS == {"wisdom_extraction"}
FOLD_TARGETS == {"wisdom_extraction"}
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
  /\ CanFire({"process_state"})
  /\ active' = UpdateActive({"process_state"}, {"reality_fork_1", "reality_fork_2"})
  /\ beta1' = beta1 + (Cardinality({"reality_fork_1", "reality_fork_2"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"reality_fork_1", "reality_fork_2"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"reality_fork_1", "device_1"})
  /\ \E winner \in {"scored_branch_1"}:
      /\ active' = UpdateActive({"reality_fork_1", "device_1"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"reality_fork_1", "device_1"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_03_RACE ==
  /\ CanFire({"reality_fork_2", "device_2"})
  /\ \E winner \in {"scored_branch_2"}:
      /\ active' = UpdateActive({"reality_fork_2", "device_2"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"reality_fork_2", "device_2"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_FOLD ==
  /\ CanFire({"scored_branch_1", "scored_branch_2"})
  /\ active' = UpdateActive({"scored_branch_1", "scored_branch_2"}, {"wisdom_extraction"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wisdom_extraction"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE
  \/ Edge_03_RACE
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
