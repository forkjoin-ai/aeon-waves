------------------------------ MODULE open_source_gnosis_warmup_structural_amortized ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"write_stream", "memtable", "compaction", "sorted_run", "point_query", "memtable_probe", "sstable_probe", "answer", "answer: Result"}
ROOTS == {"write_stream", "point_query"}
TERMINALS == {"answer: Result"}
FOLD_TARGETS == {"answer: Result"}
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
  /\ active' = UpdateActive({"memtable"}, {"compaction"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compaction"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"compaction"})
  /\ active' = UpdateActive({"compaction"}, {"sorted_run"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sorted_run"} \cap FOLD_TARGETS # {})
Edge_04_FORK ==
  /\ CanFire({"point_query"})
  /\ active' = UpdateActive({"point_query"}, {"memtable_probe", "sstable_probe"})
  /\ beta1' = beta1 + (Cardinality({"memtable_probe", "sstable_probe"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"memtable_probe", "sstable_probe"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"memtable"})
  /\ active' = UpdateActive({"memtable"}, {"memtable_probe"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"memtable_probe"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"sorted_run"})
  /\ active' = UpdateActive({"sorted_run"}, {"sstable_probe"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sstable_probe"} \cap FOLD_TARGETS # {})
Edge_07_FOLD ==
  /\ CanFire({"memtable_probe", "sstable_probe"})
  /\ active' = UpdateActive({"memtable_probe", "sstable_probe"}, {"answer: Result"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"answer: Result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_FORK
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
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
