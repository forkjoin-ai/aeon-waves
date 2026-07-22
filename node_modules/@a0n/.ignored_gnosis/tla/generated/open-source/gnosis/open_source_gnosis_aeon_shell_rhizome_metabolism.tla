------------------------------ MODULE open_source_gnosis_aeon_shell_rhizome_metabolism ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"raw_signal", "amygdala_ingest", "hippocampus_ingest", "node_state", "focus_pressure", "decay_pressure", "active_pool", "archive_pool", "world_model"}
ROOTS == {"raw_signal"}
TERMINALS == {"world_model"}
FOLD_TARGETS == {"world_model"}
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
  /\ CanFire({"raw_signal"})
  /\ active' = UpdateActive({"raw_signal"}, {"amygdala_ingest", "hippocampus_ingest"})
  /\ beta1' = beta1 + (Cardinality({"amygdala_ingest", "hippocampus_ingest"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"amygdala_ingest", "hippocampus_ingest"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"amygdala_ingest"})
  /\ active' = UpdateActive({"amygdala_ingest"}, {"node_state"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"node_state"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"hippocampus_ingest"})
  /\ active' = UpdateActive({"hippocampus_ingest"}, {"node_state"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"node_state"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"node_state"})
  /\ active' = UpdateActive({"node_state"}, {"focus_pressure", "decay_pressure"})
  /\ beta1' = beta1 + (Cardinality({"focus_pressure", "decay_pressure"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"focus_pressure", "decay_pressure"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"focus_pressure"})
  /\ \E winner \in {"active_pool"}:
      /\ active' = UpdateActive({"focus_pressure"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"focus_pressure"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_RACE ==
  /\ CanFire({"decay_pressure"})
  /\ \E winner \in {"archive_pool"}:
      /\ active' = UpdateActive({"decay_pressure"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"decay_pressure"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_FOLD ==
  /\ CanFire({"active_pool", "archive_pool"})
  /\ active' = UpdateActive({"active_pool", "archive_pool"}, {"world_model"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"world_model"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_FORK
  \/ Edge_05_RACE
  \/ Edge_06_RACE
  \/ Edge_07_FOLD

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
