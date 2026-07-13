------------------------------ MODULE open_source_gnosis_aeon_arch_15_bg_telemetry ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"tick", "log_sink", "tick: Timer", "cpu_stat: Metric", "mem_stat: Metric", "cpu_stat", "mem_stat", "log_sink: Storage"}
ROOTS == {"tick: Timer", "cpu_stat", "mem_stat"}
TERMINALS == {"cpu_stat: Metric", "mem_stat: Metric", "log_sink: Storage"}
FOLD_TARGETS == {"log_sink: Storage"}
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
  /\ CanFire({"tick: Timer"})
  /\ active' = UpdateActive({"tick: Timer"}, {"cpu_stat: Metric", "mem_stat: Metric"})
  /\ beta1' = beta1 + (Cardinality({"cpu_stat: Metric", "mem_stat: Metric"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cpu_stat: Metric", "mem_stat: Metric"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"cpu_stat", "mem_stat"})
  /\ active' = UpdateActive({"cpu_stat", "mem_stat"}, {"log_sink: Storage"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"log_sink: Storage"} \cap FOLD_TARGETS # {})

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
