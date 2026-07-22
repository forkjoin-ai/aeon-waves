------------------------------ MODULE open_source_gnosis_failure_trilemma_contagious_zero_vent ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"origin", "left", "right", "global_recovery", "repair_debt", "branch_mass", "result"}
ROOTS == {"origin"}
TERMINALS == {"result"}
FOLD_TARGETS == {"result"}
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
  /\ CanFire({"origin"})
  /\ active' = UpdateActive({"origin"}, {"left", "right"})
  /\ beta1' = beta1 + (Cardinality({"left", "right"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"left", "right"} \cap FOLD_TARGETS # {})
Edge_02_INTERFERE ==
  /\ CanFire({"left", "right"})
  /\ active' = UpdateActive({"left", "right"}, {"global_recovery"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"global_recovery"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"global_recovery"})
  /\ active' = UpdateActive({"global_recovery"}, {"repair_debt"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"repair_debt"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"global_recovery"})
  /\ active' = UpdateActive({"global_recovery"}, {"branch_mass"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"branch_mass"} \cap FOLD_TARGETS # {})
Edge_05_FOLD ==
  /\ CanFire({"repair_debt", "branch_mass"})
  /\ active' = UpdateActive({"repair_debt", "branch_mass"}, {"result"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_INTERFERE
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
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
