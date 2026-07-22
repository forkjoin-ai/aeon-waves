------------------------------ MODULE open_source_gnosis_warmup_controller_under_redline_tie ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"case", "under_deficit", "redline", "burden", "expand", "constrain", "shed_load", "expand_tie", "constrain_drag", "shed_tie", "decision", "verdict", "decision: Decision { chosen: 'expand', tie_with: 'shed-load' }", "verdict: Result"}
ROOTS == {"case", "decision"}
TERMINALS == {"decision: Decision { chosen: 'expand', tie_with: 'shed-load' }", "verdict: Result"}
FOLD_TARGETS == {"decision: Decision { chosen: 'expand', tie_with: 'shed-load' }"}
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
  /\ CanFire({"case"})
  /\ active' = UpdateActive({"case"}, {"under_deficit"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"under_deficit"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"under_deficit"})
  /\ active' = UpdateActive({"under_deficit"}, {"redline"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"redline"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"redline"})
  /\ active' = UpdateActive({"redline"}, {"burden"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"burden"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"burden"})
  /\ active' = UpdateActive({"burden"}, {"expand", "constrain", "shed_load"})
  /\ beta1' = beta1 + (Cardinality({"expand", "constrain", "shed_load"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"expand", "constrain", "shed_load"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"expand"})
  /\ active' = UpdateActive({"expand"}, {"expand_tie"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"expand_tie"} \cap FOLD_TARGETS # {})
Edge_06_INTERFERE ==
  /\ CanFire({"constrain"})
  /\ active' = UpdateActive({"constrain"}, {"constrain_drag"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"constrain_drag"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"shed_load"})
  /\ active' = UpdateActive({"shed_load"}, {"shed_tie"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shed_tie"} \cap FOLD_TARGETS # {})
Edge_08_FOLD ==
  /\ CanFire({"expand_tie", "constrain_drag", "shed_tie"})
  /\ active' = UpdateActive({"expand_tie", "constrain_drag", "shed_tie"}, {"decision: Decision { chosen: 'expand', tie_with: 'shed-load' }"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"decision: Decision { chosen: 'expand', tie_with: 'shed-load' }"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"decision"})
  /\ active' = UpdateActive({"decision"}, {"verdict: Result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verdict: Result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_FORK
  \/ Edge_05_PROCESS
  \/ Edge_06_INTERFERE
  \/ Edge_07_PROCESS
  \/ Edge_08_FOLD
  \/ Edge_09_PROCESS

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
