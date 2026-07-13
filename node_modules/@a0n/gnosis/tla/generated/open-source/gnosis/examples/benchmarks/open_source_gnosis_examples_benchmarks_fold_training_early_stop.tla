------------------------------ MODULE open_source_gnosis_examples_benchmarks_fold_training_early_stop ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"pair", "left_branch", "right_branch", "recombine", "prediction"}
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

Edge_01_FORK ==
  /\ CanFire({"pair"})
  /\ active' = UpdateActive({"pair"}, {"left_branch", "right_branch"})
  /\ beta1' = beta1 + (Cardinality({"left_branch", "right_branch"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"left_branch", "right_branch"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"left_branch", "right_branch"})
  /\ active' = UpdateActive({"left_branch", "right_branch"}, {"recombine"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"recombine"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"recombine"})
  /\ active' = UpdateActive({"recombine"}, {"prediction"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"prediction"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
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
