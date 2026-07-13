------------------------------ MODULE open_source_gnosis_wallace_monitor ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "seq_cap", "busy_load", "occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe", "occupancy_deficit", "assembled", "residual", "metrics", "verdict_input", "boundary", "context", "status", "classify", "holds", "violates", "sink"}
ROOTS == {"seed"}
TERMINALS == {"sink"}
FOLD_TARGETS == {"occupancy_deficit", "assembled", "verdict_input", "status"}
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
  /\ CanFire({"seed"})
  /\ active' = UpdateActive({"seed"}, {"seq_cap", "busy_load", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"})
  /\ beta1' = beta1 + (Cardinality({"seq_cap", "busy_load", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"seq_cap", "busy_load", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"seq_cap", "busy_load"})
  /\ active' = UpdateActive({"seq_cap", "busy_load"}, {"occupancy_deficit"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"occupancy_deficit"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"occupancy_deficit"})
  /\ active' = UpdateActive({"occupancy_deficit"}, {"occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"})
  /\ beta1' = beta1 + (Cardinality({"occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"})
  /\ active' = UpdateActive({"occupancy_deficit_probe", "idle_probe", "seq_cap_probe", "busy_probe", "invariant_probe"}, {"assembled"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"assembled"} \cap FOLD_TARGETS # {})
Edge_05_FORK ==
  /\ CanFire({"assembled"})
  /\ active' = UpdateActive({"assembled"}, {"residual", "metrics"})
  /\ beta1' = beta1 + (Cardinality({"residual", "metrics"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"residual", "metrics"} \cap FOLD_TARGETS # {})
Edge_06_FOLD ==
  /\ CanFire({"residual", "metrics"})
  /\ active' = UpdateActive({"residual", "metrics"}, {"verdict_input"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verdict_input"} \cap FOLD_TARGETS # {})
Edge_07_FORK ==
  /\ CanFire({"verdict_input"})
  /\ active' = UpdateActive({"verdict_input"}, {"boundary", "context"})
  /\ beta1' = beta1 + (Cardinality({"boundary", "context"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"boundary", "context"} \cap FOLD_TARGETS # {})
Edge_08_FOLD ==
  /\ CanFire({"boundary", "context"})
  /\ active' = UpdateActive({"boundary", "context"}, {"status"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"status"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"status"})
  /\ active' = UpdateActive({"status"}, {"classify"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"classify"} \cap FOLD_TARGETS # {})
Edge_10_PROCESS ==
  /\ CanFire({"classify"})
  /\ active' = UpdateActive({"classify"}, {"holds"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"holds"} \cap FOLD_TARGETS # {})
Edge_11_PROCESS ==
  /\ CanFire({"classify"})
  /\ active' = UpdateActive({"classify"}, {"violates"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"violates"} \cap FOLD_TARGETS # {})
Edge_12_PROCESS ==
  /\ CanFire({"holds"})
  /\ active' = UpdateActive({"holds"}, {"sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})
Edge_13_PROCESS ==
  /\ CanFire({"violates"})
  /\ active' = UpdateActive({"violates"}, {"sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD
  \/ Edge_03_FORK
  \/ Edge_04_FOLD
  \/ Edge_05_FORK
  \/ Edge_06_FOLD
  \/ Edge_07_FORK
  \/ Edge_08_FOLD
  \/ Edge_09_PROCESS
  \/ Edge_10_PROCESS
  \/ Edge_11_PROCESS
  \/ Edge_12_PROCESS
  \/ Edge_13_PROCESS

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
