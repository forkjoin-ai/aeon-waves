------------------------------ MODULE open_source_gnosis_reality_branch_fork ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"base_state", "next_state", "base_state: Graph", "branch_a: Simulation", "branch_b: Simulation", "branch_a", "branch_b", "next_state: Graph"}
ROOTS == {"base_state: Graph", "branch_a", "branch_b"}
TERMINALS == {"branch_a: Simulation", "branch_b: Simulation", "next_state: Graph"}
FOLD_TARGETS == {"next_state: Graph"}
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
  /\ CanFire({"base_state: Graph"})
  /\ active' = UpdateActive({"base_state: Graph"}, {"branch_a: Simulation", "branch_b: Simulation"})
  /\ beta1' = beta1 + (Cardinality({"branch_a: Simulation", "branch_b: Simulation"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"branch_a: Simulation", "branch_b: Simulation"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"branch_a", "branch_b"})
  /\ active' = UpdateActive({"branch_a", "branch_b"}, {"next_state: Graph"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"next_state: Graph"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

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
