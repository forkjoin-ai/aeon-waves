------------------------------ MODULE open_source_gnosis_warmup_invert_structural_amortized ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"write_stream", "memtable", "run_a", "run_b", "compaction_backlog", "point_query", "probe_a", "probe_b", "probe_log", "fragmented_answer", "delayed_answer"}
ROOTS == {"write_stream", "point_query", "compaction_backlog"}
TERMINALS == {"delayed_answer"}
FOLD_TARGETS == {"fragmented_answer"}
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
  /\ CanFire({"write_stream"})
  /\ active' = UpdateActive({"write_stream"}, {"memtable"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"memtable"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"memtable"})
  /\ active' = UpdateActive({"memtable"}, {"run_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"run_a"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"memtable"})
  /\ active' = UpdateActive({"memtable"}, {"run_b"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"run_b"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"point_query"})
  /\ active' = UpdateActive({"point_query"}, {"probe_a", "probe_b", "probe_log"})
  /\ beta1' = beta1 + (Cardinality({"probe_a", "probe_b", "probe_log"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"probe_a", "probe_b", "probe_log"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"run_a"})
  /\ active' = UpdateActive({"run_a"}, {"probe_a"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"probe_a"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"run_b"})
  /\ active' = UpdateActive({"run_b"}, {"probe_b"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"probe_b"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"memtable"})
  /\ active' = UpdateActive({"memtable"}, {"probe_log"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"probe_log"} \cap FOLD_TARGETS # {})
Edge_08_FOLD ==
  /\ CanFire({"probe_a", "probe_b", "probe_log"})
  /\ active' = UpdateActive({"probe_a", "probe_b", "probe_log"}, {"fragmented_answer"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fragmented_answer"} \cap FOLD_TARGETS # {})
Edge_09_INTERFERE ==
  /\ CanFire({"fragmented_answer", "compaction_backlog"})
  /\ active' = UpdateActive({"fragmented_answer", "compaction_backlog"}, {"delayed_answer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"delayed_answer"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_FORK
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_FOLD
  \/ Edge_09_INTERFERE

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
