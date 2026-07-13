------------------------------ MODULE open_source_gnosis_examples_benchmarks_moe_routing_linear ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"pair", "router", "x_pos", "x_neg", "y_pos", "y_neg", "recombine", "prediction"}
ROOTS == {"pair"}
TERMINALS == {"prediction"}
FOLD_TARGETS == {"recombine"}
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
  /\ CanFire({"pair"})
  /\ active' = UpdateActive({"pair"}, {"router"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"router"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"router"})
  /\ active' = UpdateActive({"router"}, {"x_pos", "x_neg", "y_pos", "y_neg"})
  /\ beta1' = beta1 + (Cardinality({"x_pos", "x_neg", "y_pos", "y_neg"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"x_pos", "x_neg", "y_pos", "y_neg"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"x_pos", "x_neg", "y_pos", "y_neg"})
  /\ active' = UpdateActive({"x_pos", "x_neg", "y_pos", "y_neg"}, {"recombine"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"recombine"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"recombine"})
  /\ active' = UpdateActive({"recombine"}, {"prediction"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"prediction"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FOLD
  \/ Edge_04_PROCESS

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
